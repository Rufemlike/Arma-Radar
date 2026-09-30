/*
    Author: Arma Radar Team
    File: fn_scanTargets.sqf
    Description:
        Multi-Radar Network (IADS) sensor fusion engine inspired by vanilla Arma 3 sensor configs and Drongo's Air Operations (DAO).
        - Automatically discovers active/static radars via CfgVehicles ActiveRadarSensorComponent, classname keywords, or Zeus/3DEN attributes.
        - Automatically crews unmanned static/autonomous radars (like AN/MPQ-105 / Patriot) so engine active sensors power up.
        - Generates 2D map markers visible on standard Arma 3 map and Zeus map.
        - Detects airborne contacts using radar line-of-sight (terrainIntersectASL), radar target size (RCS), and engine sensors (getSensorTargets).
*/

// Self-contained safety initialization (guarantees variables are never nil)
if (isNil "AIRDEF_radarClasses") then {
    AIRDEF_radarClasses = [
        "Land_Radar_F", "Land_Radar_small_F", "Land_Airfield_Tower_F",
        "Radar_System_01_base_F", "Radar_System_02_base_F",
        "B_Radar_System_01_F", "O_Radar_System_02_F",
        "B_AAA_System_01_F", "B_SAM_System_01_F", "B_SAM_System_02_F", "O_SAM_System_04_F"
    ];
};
if (isNil "AIRDEF_showRings") then { AIRDEF_showRings = true; };
if (isNil "AIRDEF_showSweep") then { AIRDEF_showSweep = true; };
if (isNil "AIRDEF_showVectors") then { AIRDEF_showVectors = true; };
if (isNil "AIRDEF_sweepSpeed") then { AIRDEF_sweepSpeed = 60; };
if (isNil "AIRDEF_filter") then { AIRDEF_filter = "ALL"; };
if (isNil "AIRDEF_radarRange") then { AIRDEF_radarRange = 35000; };
if (isNil "AIRDEF_managedMarkers") then { AIRDEF_managedMarkers = []; };

// Resolve viewer side (handles player, Zeus Game Master, and Curator camera)
private _userSide = playerSide;
if (_userSide in [sideLogic, civilian, sideUnknown]) then {
    if (!isNull player && { (side (group player)) in [west, east, independent] }) then {
        _userSide = side (group player);
    } else {
        _userSide = west;
    };
};

// ================= 1. REFRESH RADAR NETWORKS (FRIENDLY VS HOSTILE) =================
private _foundFriendly = [];
private _foundHostile  = [];

private _onlyCustomRadars      = missionNamespace getVariable ["AIRDEF_onlyCustomRadars", false];
private _autoScanMapRadars     = missionNamespace getVariable ["AIRDEF_autoScanMapRadars", true];
private _autoScanVehicleRadars = missionNamespace getVariable ["AIRDEF_autoScanVehicleRadars", true];
private _rangeMult             = (missionNamespace getVariable ["AIRDEF_radarRangeMultiplier", 1.0]) max 0.05 min 2.0;

private _radarCandidates = [];

if (_onlyCustomRadars) then {
    // Mode A: STRICT 3DEN / SCRIPT ONLY. Only use objects explicitly marked as radar
    {
        if (alive _x) then {
            if ((_x getVariable ["AIRDEF_isRadar", false]) || { (_x getVariable ["AIRDEF_radarRange", -1]) > 0 }) then {
                _radarCandidates pushBackUnique _x;
            };
        };
    } forEach (allMissionObjects "All");
} else {
    // Mode B: COMPREHENSIVE SCAN (3DEN custom + optional map structures + optional vehicle sensors)
    private _allCandidates = [];

    // 1. Explicit 3DEN custom radars (always included)
    {
        if (alive _x && { (_x getVariable ["AIRDEF_isRadar", false]) || { (_x getVariable ["AIRDEF_radarRange", -1]) > 0 } }) then {
            _radarCandidates pushBackUnique _x;
        };
    } forEach (allMissionObjects "All");

    // 2. Map radar structures (if enabled)
    if (_autoScanMapRadars) then {
        private _wSize = if (isNil "worldSize" || { worldSize <= 0 }) then { 40000 } else { worldSize };
        private _wCenter = [_wSize / 2, _wSize / 2, 0];
        private _mapRadars = nearestObjects [_wCenter, AIRDEF_radarClasses, _wSize max 40000];
        {
            if (alive _x) then { _radarCandidates pushBackUnique _x; };
        } forEach _mapRadars;
    };

    // 3. Vehicles & static weapons with active radar sensors (if enabled)
    if (_autoScanVehicleRadars) then {
        {
            private _veh = _x;
            if (alive _veh && { !(_veh in _radarCandidates) }) then {
                private _type = typeOf _veh;
                private _typeLower = toLower _type;
                private _dispName = toLower (getText (configFile >> "CfgVehicles" >> _type >> "displayName"));

                private _cfgRadarRange = getNumber (configFile >> "CfgVehicles" >> _type >> "Components" >> "SensorsManagerComponent" >> "Components" >> "ActiveRadarSensorComponent" >> "AirTarget" >> "maxRange");
                if (_cfgRadarRange <= 0) then {
                    _cfgRadarRange = getNumber (configFile >> "CfgVehicles" >> _type >> "Turrets" >> "MainTurret" >> "Components" >> "SensorsManagerComponent" >> "Components" >> "ActiveRadarSensorComponent" >> "AirTarget" >> "maxRange");
                };

                private _isRadarObj = (_cfgRadarRange > 0);

                if (!_isRadarObj && { _type in AIRDEF_radarClasses }) then { _isRadarObj = true; };

                if (!_isRadarObj) then {
                    {
                        if (_typeLower find _x != -1 || _dispName find _x != -1) exitWith { _isRadarObj = true; };
                    } forEach ["radar", "рлс", "радар", "mpq", "sam", "fansong", "tinshield", "spoonrest", "straightflush", "barlock", "nebo", "kasta", "96l6", "30n6", "64n6", "tps"];
                };

                if (!_isRadarObj && { _veh isKindOf "AllVehicles" } && { isVehicleRadarOn _veh isEqualTo true }) then {
                    _isRadarObj = true;
                };

                if (_isRadarObj) then {
                    _radarCandidates pushBackUnique _veh;
                };
            };
        } forEach (vehicles + (allMissionObjects "StaticWeapon"));
    };
};

// Activate autonomous static weapons and sensors
{
    private _veh = _x;
    if (count (crew _veh) == 0 && { unitIsUav _veh || (_veh isKindOf "StaticWeapon") }) then {
        createVehicleCrew _veh;
        _veh setAutonomous true;
    };
    if (_veh isKindOf "AllVehicles") then {
        if !(isVehicleRadarOn _veh isEqualTo true) then {
            _veh setVehicleRadar 1;
        };
        _veh setVehicleReceiveRemoteTargets true;
        _veh setVehicleReportRemoteTargets true;
    };
} forEach _radarCandidates;

// Categorize radars (Friendly vs Hostile) and apply individual ranges
{
    private _rObj = _x;
    if (alive _rObj) then {
        private _rPos = getPosASL _rObj;

        // 1. Determine Side (Friend or Foe)
        private _sideVar = _rObj getVariable ["AIRDEF_radarSide", "AUTO"];
        private _rSide = sideUnknown;

        switch (toUpper str _sideVar) do {
            case """WEST""":        { _rSide = west; };
            case "WEST":            { _rSide = west; };
            case """BLUFOR""":      { _rSide = west; };
            case "BLUFOR":          { _rSide = west; };
            case """EAST""":        { _rSide = east; };
            case "EAST":            { _rSide = east; };
            case """OPFOR""":       { _rSide = east; };
            case "OPFOR":           { _rSide = east; };
            case """IND""":         { _rSide = independent; };
            case "IND":             { _rSide = independent; };
            case """INDEPENDENT""": { _rSide = independent; };
            case "INDEPENDENT":     { _rSide = independent; };
            case """ALL""":         { _rSide = _userSide; };
            case "ALL":             { _rSide = _userSide; };
            default                 { _rSide = side _rObj; };
        };

        // If side is undetermined or civilian, check vehicle config side
        if (_rSide in [civilian, sideUnknown, sideEmpty]) then {
            private _cfgSide = getNumber (configFile >> "CfgVehicles" >> (typeOf _rObj) >> "side");
            switch (_cfgSide) do {
                case 1: { _rSide = west; };
                case 0: { _rSide = east; };
                case 2: { _rSide = independent; };
                default {
                    private _nearUnits = (_rPos nearEntities [["CAManBase", "AllVehicles"], 350]) select { (side _x) in [west, east, independent] };
                    if (count _nearUnits > 0) then {
                        _rSide = side (_nearUnits select 0);
                    } else {
                        _rSide = _userSide;
                    };
                };
            };
        };

        private _isFriendly = (_rSide == _userSide) || { [_rSide, _userSide] call BIS_fnc_sideIsFriendly };

        // 2. Determine Individual Range
        private _customRange = _rObj getVariable ["AIRDEF_radarRange", -1];
        private _baseRange = if (_customRange > 0) then {
            _customRange
        } else {
            private _type = typeOf _rObj;
            private _cfgR = getNumber (configFile >> "CfgVehicles" >> _type >> "Components" >> "SensorsManagerComponent" >> "Components" >> "ActiveRadarSensorComponent" >> "AirTarget" >> "maxRange");
            if (_cfgR <= 0) then {
                _cfgR = getNumber (configFile >> "CfgVehicles" >> _type >> "Turrets" >> "MainTurret" >> "Components" >> "SensorsManagerComponent" >> "Components" >> "ActiveRadarSensorComponent" >> "AirTarget" >> "maxRange");
            };
            if (_cfgR > 0) then {
                _cfgR
            } else {
                switch (true) do {
                    case (_type in ["Land_Radar_F", "Radar_System_01_base_F", "Radar_System_02_base_F", "B_Radar_System_01_F", "O_Radar_System_02_F"]): { 35000 };
                    case (_type in ["Land_Radar_small_F", "Land_Airfield_Tower_F"]): { 15000 };
                    case (_rObj isKindOf "StaticWeapon"): { 32000 };
                    default { 25000 };
                };
            };
        };

        // Scale by map range multiplier
        private _rRange = round (_baseRange * _rangeMult);

        // 3. Determine Name
        private _rName = _rObj getVariable ["AIRDEF_radarName", ""];
        if (_rName == "") then { _rName = vehicleVarName _rObj; };
        if (_rName == "") then {
            _rName = getText (configFile >> "CfgVehicles" >> typeOf _rObj >> "displayName");
            if (_rName == "") then { _rName = if (_isFriendly) then {"ПОСТ РЛС"} else {"РЛС ПРОТИВНИКА"}; };
        };

        private _phase = (round ((_rPos select 0) + (_rPos select 1))) % 360;

        if (_isFriendly) then {
            _foundFriendly pushBack [_rObj, _rPos, _rRange, _rName, _phase];
        } else {
            _foundHostile pushBack [_rObj, _rPos, _rRange, _rName, _phase];
        };
    };
} forEach _radarCandidates;

// Fallback: if no radar object on map, create field station at player
if (count _foundFriendly == 0) then {
    private _basePos = getPosASL player;
    private _fallbackRange = round (15000 * _rangeMult);
    _foundFriendly pushBack [player, _basePos, _fallbackRange, "ПОЛЕВОЙ ПОСТ РЛС", 0];
};

AIRDEF_activeRadars  = _foundFriendly;
AIRDEF_hostileRadars = _foundHostile;


// ================= 1.3. UPDATE 2D MAP & ZEUS COVERAGE MARKERS =================
// Generates clear coverage circle markers on standard Arma map and Zeus map (identical to Drongo's DAO)
private _activeMarkerIds = [];

{
    _x params ["_rObj", "_rPos", "_rRange", "_rName"];
    private _objId = netId _rObj;
    if (_objId == "") then {
        _objId = format ["pos_%1_%2", round (_rPos select 0), round (_rPos select 1)];
    } else {
        _objId = (_objId splitString ":") joinString "_";
    };
    
    private _ringMrk = format ["AIRDEF_mrk_ring_%1", _objId];
    private _iconMrk = format ["AIRDEF_mrk_icon_%1", _objId];
    
    _activeMarkerIds pushBack _ringMrk;
    _activeMarkerIds pushBack _iconMrk;
    
    // Outer coverage ring (ELLIPSE Border)
    if (getMarkerColor _ringMrk == "") then {
        createMarkerLocal [_ringMrk, _rPos];
        _ringMrk setMarkerShapeLocal "ELLIPSE";
        _ringMrk setMarkerBrushLocal "Border";
        _ringMrk setMarkerColorLocal "ColorWEST";
    };
    _ringMrk setMarkerPosLocal _rPos;
    _ringMrk setMarkerSizeLocal [_rRange, _rRange];
    
    // Transmitter icon and label
    if (getMarkerColor _iconMrk == "") then {
        createMarkerLocal [_iconMrk, _rPos];
        _iconMrk setMarkerTypeLocal "b_installation";
        _iconMrk setMarkerColorLocal "ColorWEST";
    };
    _iconMrk setMarkerPosLocal _rPos;
    _iconMrk setMarkerTextLocal (format ["%1 (%2 КМ)", _rName, round (_rRange / 1000)]);
} forEach _foundFriendly;

{
    _x params ["_rObj", "_rPos", "_rRange", "_rName"];
    private _objId = netId _rObj;
    if (_objId == "") then {
        _objId = format ["pos_%1_%2", round (_rPos select 0), round (_rPos select 1)];
    } else {
        _objId = (_objId splitString ":") joinString "_";
    };
    
    private _ringMrk = format ["AIRDEF_mrk_ring_%1", _objId];
    private _iconMrk = format ["AIRDEF_mrk_icon_%1", _objId];
    
    _activeMarkerIds pushBack _ringMrk;
    _activeMarkerIds pushBack _iconMrk;
    
    if (getMarkerColor _ringMrk == "") then {
        createMarkerLocal [_ringMrk, _rPos];
        _ringMrk setMarkerShapeLocal "ELLIPSE";
        _ringMrk setMarkerBrushLocal "Border";
        _ringMrk setMarkerColorLocal "ColorEAST";
    };
    _ringMrk setMarkerPosLocal _rPos;
    _ringMrk setMarkerSizeLocal [_rRange, _rRange];
    
    if (getMarkerColor _iconMrk == "") then {
        createMarkerLocal [_iconMrk, _rPos];
        _iconMrk setMarkerTypeLocal "o_installation";
        _iconMrk setMarkerColorLocal "ColorEAST";
    };
    _iconMrk setMarkerPosLocal _rPos;
    _iconMrk setMarkerTextLocal (format ["ЗОНА ПВО: %1 (%2 КМ)", _rName, round (_rRange / 1000)]);
} forEach _foundHostile;

// Cleanup removed / destroyed radar markers
{
    if !(_x in _activeMarkerIds) then {
        deleteMarkerLocal _x;
    };
} forEach AIRDEF_managedMarkers;
AIRDEF_managedMarkers = _activeMarkerIds;


// ================= 2. SENSOR FUSION & TARGET TRACKING =================
private _newTracks = [];
private _trackedObjects = [];

// 2.1. Friendly aircraft (Always tracked via IFF transponder)
private _allAir = vehicles select { alive _x && (_x isKindOf "Air") };
private _friendlyAir = _allAir select { (side _x) == _userSide || [_userSide, side _x] call BIS_fnc_sideIsFriendly };

{
    private _veh = _x;
    private _pos = getPosASL _veh;
    private _speedKmh = round (speed _veh);
    private _altM = round (_pos select 2);
    private _dir = round (getDir _veh);
    
    // Callsign resolution
    private _callsign = _veh getVariable ["AIRDEF_callsign", ""];
    if (_callsign == "") then {
        private _grp = group _veh;
        if (!isNull _grp) then {
            private _grpId = groupId _grp;
            if (_grpId != "") then { _callsign = _grpId; };
        };
    };
    if (_callsign == "") then { _callsign = vehicleVarName _veh; };
    if (_callsign == "") then {
        private _drv = driver _veh;
        if (!isNull _drv && { alive _drv }) then { _callsign = name _drv; };
    };
    if (_callsign == "") then {
        _callsign = getText (configFile >> "CfgVehicles" >> typeOf _veh >> "displayName");
    };
    
    _newTracks pushBack [
        netId _veh,
        _veh,
        _pos,
        time,
        _speedKmh,
        _altM,
        _dir,
        _callsign,
        _userSide,
        false, // isMissile
        false, // isDataLink
        fuel _veh,
        damage _veh
    ];
    _trackedObjects pushBack _veh;
} forEach _friendlyAir;

// 2.2. Radar Detection (DAO Line of Sight + RCS model + Engine Sensors)
private _untrackedAir = _allAir select { !(_x in _trackedObjects) };

{
    private _tgt = _x;
    if (alive _tgt && !isTouchingGround _tgt) then {
        private _tgtPos = getPosASL _tgt;
        private _altATL = (getPosATL _tgt) select 2;
        
        // Aircraft above tree line (> 15m) can be detected by radar
        if (_altATL > 15) then {
            private _detected = false;
            private _rcs = getNumber (configFile >> "CfgVehicles" >> (typeOf _tgt) >> "radarTargetSize");
            if (_rcs <= 0) then { _rcs = 1.0; };
            
            {
                _x params ["_rObj", "_rPos", "_rRange"];
                private _dist = _tgtPos distance2D _rPos;
                private _effectiveRange = _rRange * (_rcs max 0.25 min 1.5);
                
                if (_dist <= _effectiveRange) then {
                    // Check terrain obstruction
                    private _sensorPos = [_rPos select 0, _rPos select 1, (_rPos select 2) + 8];
                    if !(terrainIntersectASL [_sensorPos, _tgtPos]) then {
                        _detected = true;
                    };
                };
                if (_detected) exitWith {};
            } forEach AIRDEF_activeRadars;
            
            if (_detected) then {
                private _speedKmh = round (speed _tgt);
                private _altM = round (_tgtPos select 2);
                private _dir = round (getDir _tgt);
                
                private _type = _tgt getVariable ["AIRDEF_callsign", ""];
                if (_type == "") then { _type = vehicleVarName _tgt; };
                if (_type == "") then { _type = getText (configFile >> "CfgVehicles" >> typeOf _tgt >> "displayName"); };
                
                private _tgtSide = side _tgt;
                
                _newTracks pushBack [
                    netId _tgt,
                    _tgt,
                    _tgtPos,
                    time,
                    _speedKmh,
                    _altM,
                    _dir,
                    _type,
                    _tgtSide,
                    false, // isMissile
                    false, // isDataLink
                    fuel _tgt,
                    damage _tgt
                ];
                _trackedObjects pushBack _tgt;
            };
        };
    };
} forEach _untrackedAir;

// 2.3. Missile Tracking
private _missiles = (allMissionObjects "MissileBase") + (allMissionObjects "RocketBase");
private _hadNewMissile = false;

{
    private _missile = _x;
    if (alive _missile) then {
        private _vel = velocity _missile;
        private _speedMs = vectorMagnitude _vel;
        private _mPos = getPosASL _missile;
        private _alt = _mPos select 2;
        
        if (_speedMs > 50 && _alt > 10) then {
            private _inRadarCoverage = false;
            {
                _x params ["_rObj", "_rPos", "_rRange"];
                if ((_mPos distance2D _rPos) <= _rRange) exitWith {
                    _inRadarCoverage = true;
                };
            } forEach AIRDEF_activeRadars;
            
            if (_inRadarCoverage) then {
                private _speedKmh = round (_speedMs * 3.6);
                private _dir = round ((_vel select 0) atan2 (_vel select 1));
                if (_dir < 0) then { _dir = _dir + 360; };
                
                _newTracks pushBack [
                    netId _missile,
                    _missile,
                    _mPos,
                    time,
                    _speedKmh,
                    round _alt,
                    _dir,
                    "!РАКЕТА!",
                    east,
                    true, // isMissile
                    false,
                    1,
                    0
                ];
                _hadNewMissile = true;
            };
        };
    };
} forEach _missiles;

if (_hadNewMissile && { (time - (missionNamespace getVariable ["AIRDEF_lastAlertSound", 0])) > 4 }) then {
    playSound "Alarm";
    AIRDEF_lastAlertSound = time;
};

AIRDEF_trackCache = _newTracks;
