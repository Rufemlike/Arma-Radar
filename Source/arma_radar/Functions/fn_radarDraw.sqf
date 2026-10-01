/*
    Author: Arma Radar Team
    File: fn_radarDraw.sqf
    Description:
        Multi-Radar Network (IADS) Draw Handler.
        Renders:
        - Friendly radars in GREEN CRT with sweeps and coverage rings.
        - Hostile radars in RED as SAM Threat Rings (Зоны угрозы ПВО).
        - Friendly aircraft, DataLink tracks, hostile contacts, and missiles.
        - Intercept vectors and target telemetry connections.
*/

params ["_map"];

private _userSide = playerSide;
if (_userSide in [sideLogic, civilian, sideUnknown]) then {
    if (!isNull player && { (side (group player)) in [west, east, independent] }) then {
        _userSide = side (group player);
    } else {
        _userSide = west;
    };
};

// ================= 1. FRIENDLY RADAR NETWORK (GREEN CRT) =================
// Ensure active selected radar is valid
private _radarObjList = AIRDEF_activeRadars apply { _x select 0 };
if (isNil "AIRDEF_selectedRadar" || { isNull AIRDEF_selectedRadar } || { !(AIRDEF_selectedRadar in _radarObjList) }) then {
    if (count AIRDEF_activeRadars > 0) then {
        AIRDEF_selectedRadar = (AIRDEF_activeRadars select 0) select 0;
    } else {
        AIRDEF_selectedRadar = objNull;
    };
};

// Warning banner if all radars destroyed or none active
if (count AIRDEF_activeRadars == 0) then {
    private _screenCenter = _map ctrlMapScreenToWorld [0.5, 0.45];
    if (count _screenCenter > 0) then {
        private _pulse = 0.75 + 0.25 * sin (time * 6);
        _map drawIcon [
            "#(argb,8,8,3)color(0,0,0,0)",
            [1, 0.2, 0.1, _pulse],
            _screenCenter,
            0, 0, 0,
            "[СВЯЗЬ С РЛС ПОТЕРЯНА — СТАНЦИЯ УНИЧТОЖЕНА ИЛИ ОБЕСТОЧЕНА]",
            0,
            0.038,
            "RobotoCondensed",
            "center"
        ];
    };
};

{
    _x params ["_rObj", "_rPos", "_rRange", "_rName", "_phaseOffset"];
    private _rCenter2D = [_rPos select 0, _rPos select 1, 0];
    private _isSelectedStation = (_rObj isEqualTo AIRDEF_selectedRadar) || { count AIRDEF_activeRadars == 1 };
    private _isEmissionOff = _rObj getVariable ["AIRDEF_radarEmissionOff", false];
    
    if (_isSelectedStation) then {
        // === DETAILED CRT RINGS FOR SELECTED ACTIVE RADAR ONLY ===
        if (AIRDEF_showRings) then {
            private _ringColor100 = if (_isEmissionOff) then { [1, 0.55, 0.15, 0.55] } else { [0, 1, 0.35, 0.85] };
            private _ringColor75  = if (_isEmissionOff) then { [1, 0.55, 0.15, 0.35] } else { [0, 0.85, 0.28, 0.50] };
            private _ringColor50  = if (_isEmissionOff) then { [1, 0.55, 0.15, 0.35] } else { [0, 0.8, 0.25, 0.55] };
            private _ringColor25  = if (_isEmissionOff) then { [1, 0.55, 0.15, 0.25] } else { [0, 0.65, 0.2, 0.45] };
            private _crossColor   = if (_isEmissionOff) then { [1, 0.55, 0.15, 0.25] } else { [0, 0.7, 0.22, 0.35] };

            // Outer boundary (100%)
            _map drawEllipse [_rCenter2D, _rRange, _rRange, 0, _ringColor100, "#(rgb,8,8,3)color(0,0,0,0)"];
            for "_a" from 0 to 350 step 10 do {
                private _p1 = [(_rCenter2D select 0) + (sin _a) * _rRange, (_rCenter2D select 1) + (cos _a) * _rRange, 0];
                private _p2 = [(_rCenter2D select 0) + (sin (_a + 10)) * _rRange, (_rCenter2D select 1) + (cos (_a + 10)) * _rRange, 0];
                _map drawLine [_p1, _p2, _ringColor100];
            };

            // 75% Range ring
            _map drawEllipse [_rCenter2D, _rRange * 0.75, _rRange * 0.75, 0, _ringColor75, "#(rgb,8,8,3)color(0,0,0,0)"];
            for "_a" from 0 to 350 step 15 do {
                private _p1 = [(_rCenter2D select 0) + (sin _a) * (_rRange * 0.75), (_rCenter2D select 1) + (cos _a) * (_rRange * 0.75), 0];
                private _p2 = [(_rCenter2D select 0) + (sin (_a + 15)) * (_rRange * 0.75), (_rCenter2D select 1) + (cos (_a + 15)) * (_rRange * 0.75), 0];
                _map drawLine [_p1, _p2, _ringColor75];
            };

            // 50% Range ring
            _map drawEllipse [_rCenter2D, _rRange * 0.50, _rRange * 0.50, 0, _ringColor50, "#(rgb,8,8,3)color(0,0,0,0)"];
            for "_a" from 0 to 350 step 15 do {
                private _p1 = [(_rCenter2D select 0) + (sin _a) * (_rRange * 0.5), (_rCenter2D select 1) + (cos _a) * (_rRange * 0.5), 0];
                private _p2 = [(_rCenter2D select 0) + (sin (_a + 15)) * (_rRange * 0.5), (_rCenter2D select 1) + (cos (_a + 15)) * (_rRange * 0.5), 0];
                _map drawLine [_p1, _p2, _ringColor50];
            };

            // 25% Range ring
            _map drawEllipse [_rCenter2D, _rRange * 0.25, _rRange * 0.25, 0, _ringColor25, "#(rgb,8,8,3)color(0,0,0,0)"];
            for "_a" from 0 to 350 step 20 do {
                private _p1 = [(_rCenter2D select 0) + (sin _a) * (_rRange * 0.25), (_rCenter2D select 1) + (cos _a) * (_rRange * 0.25), 0];
                private _p2 = [(_rCenter2D select 0) + (sin (_a + 20)) * (_rRange * 0.25), (_rCenter2D select 1) + (cos (_a + 20)) * (_rRange * 0.25), 0];
                _map drawLine [_p1, _p2, _ringColor25];
            };

            // 10% Range ring
            _map drawEllipse [_rCenter2D, _rRange * 0.10, _rRange * 0.10, 0, _crossColor, "#(rgb,8,8,3)color(0,0,0,0)"];
            
            // Cardinal crosshairs (N-S, E-W)
            _map drawLine [
                [(_rCenter2D select 0) - _rRange, _rCenter2D select 1, 0],
                [(_rCenter2D select 0) + _rRange, _rCenter2D select 1, 0],
                _crossColor
            ];
            _map drawLine [
                [_rCenter2D select 0, (_rCenter2D select 1) - _rRange, 0],
                [_rCenter2D select 0, (_rCenter2D select 1) + _rRange, 0],
                _crossColor
            ];
            
            // Range distance labels along the North axis
            {
                private _distFraction = _x;
                private _distKm = round ((_rRange * _distFraction) / 1000);
                private _tickPos = [(_rCenter2D select 0), (_rCenter2D select 1) + (_rRange * _distFraction), 0];
                _map drawIcon [
                    "#(argb,8,8,3)color(0,0,0,0)",
                    if (_isEmissionOff) then { [1, 0.65, 0.2, 0.65] } else { [0, 0.85, 0.25, 0.75] },
                    _tickPos,
                    0, 0, 0,
                    format ["%1 КМ", _distKm],
                    0,
                    0.024,
                    "RobotoCondensed",
                    "center"
                ];
            } forEach [0.25, 0.50, 0.75, 1.0];
            
            private _labelPos = [(_rCenter2D select 0), (_rCenter2D select 1) + _rRange + 400, 0];
            private _labelText = if (_isEmissionOff) then {
                format ["%1 (ЗОНА: %2 КМ) [РАДИОМОЛЧАНИЕ / ВЫКЛЮЧЕН]", _rName, round (_rRange / 1000)]
            } else {
                format ["%1 (ЗОНА: %2 КМ) [АКТИВЕН]", _rName, round (_rRange / 1000)]
            };
            private _labelColor = if (_isEmissionOff) then { [1, 0.6, 0.2, 0.95] } else { [0.2, 1, 0.4, 0.95] };
            
            _map drawIcon [
                "#(argb,8,8,3)color(0,0,0,0)",
                _labelColor,
                _labelPos,
                0, 0, 0,
                _labelText,
                0,
                0.028,
                "RobotoCondensed",
                "center"
            ];
        };
        
        // Rotating sweep beam for selected radar only (active only when emission is ON)
        if (AIRDEF_showSweep && !_isEmissionOff) then {
            private _sweepAngle = ((time * AIRDEF_sweepSpeed) + _phaseOffset) % 360;
            private _endPos = [
                (_rCenter2D select 0) + (sin _sweepAngle) * _rRange,
                (_rCenter2D select 1) + (cos _sweepAngle) * _rRange,
                0
            ];
            _map drawLine [_rCenter2D, _endPos, [0.3, 1, 0.45, 0.85]];
            
            for "_i" from 1 to 3 do {
                private _trailAngle = _sweepAngle - (_i * 2.0);
                private _trailAlpha = 0.38 - (_i * 0.10);
                private _trailPos = [
                    (_rCenter2D select 0) + (sin _trailAngle) * _rRange,
                    (_rCenter2D select 1) + (cos _trailAngle) * _rRange,
                    0
                ];
                _map drawLine [_rCenter2D, _trailPos, [0, 0.75, 0.22, _trailAlpha]];
            };
        };
    } else {
        // === SECONDARY RADAR STATION: CLEAN VISIBLE COVERAGE CIRCLE ===
        if (AIRDEF_showRings) then {
            private _secColor = if (_isEmissionOff) then { [0.9, 0.55, 0.15, 0.50] } else { [0, 0.85, 0.35, 0.55] };
            _map drawEllipse [_rCenter2D, _rRange, _rRange, 0, _secColor, ""];
        };
    };
    
    // Station icon & label (ALWAYS visible for all friendly radars, independent of target filters)
    private _iconColor = if (_isEmissionOff) then {
        [1, 0.6, 0.2, 0.95]
    } else {
        if (_isSelectedStation) then { [0.2, 1, 0.4, 0.95] } else { [0, 0.85, 0.35, 0.85] }
    };
    
    // Station anchor circle
    if (_isSelectedStation) then {
        _map drawEllipse [_rCenter2D, 350, 350, 0, [0.2, 1, 0.4, 0.70 + 0.30 * sin (time * 6)], ""];
    } else {
        _map drawEllipse [_rCenter2D, 220, 220, 0, [0, 0.85, 0.35, 0.45], ""];
    };
    
    private _iconText = if (_isEmissionOff) then {
        format ["[ТИШИНА/ВЫКЛ] %1 (%2 КМ)", _rName, round (_rRange / 1000)]
    } else {
        if (_isSelectedStation) then { 
            format ["[*] %1 (%2 КМ) [ВЫБРАН]", _rName, round (_rRange / 1000)] 
        } else { 
            format ["[РЛС] %1 (%2 КМ) [КЛИК: ВЫБОР]", _rName, round (_rRange / 1000)] 
        }
    };
    _map drawIcon [
        "\A3\ui_f\data\map\markers\nato\b_installation.paa",
        _iconColor,
        _rCenter2D,
        26, 26, 0,
        _iconText,
        0,
        0.026,
        "RobotoCondensed",
        "right"
    ];
} forEach AIRDEF_activeRadars;


// ================= 1.5. AIRPORTS & RECOVERY BASES =================
if (isNil "AIRDEF_discoveredAirports" || { count (missionNamespace getVariable ["AIRDEF_discoveredAirports", []]) == 0 }) then {
    private _airports = [];
    private _wSize = if (isNil "worldSize" || { worldSize <= 0 }) then { 40000 } else { worldSize };
    private _wCenter = [_wSize / 2, _wSize / 2, 0];

    // 1. Named map locations of type "Airport" (covers all standard Arma 3 and modded airbases)
    private _aptLocs = nearestLocations [_wCenter, ["Airport"], _wSize max 40000];
    {
        private _locPos = locationPosition _x;
        private _locText = text _x;
        if (_locText == "") then { _locText = "Аэродром"; };
        _airports pushBack [-1, _locPos, _locText, "AIRPORT"];
    } forEach _aptLocs;

    // 2. Aircraft carriers on the map
    private _carriers = (allMissionObjects "Land_Carrier_01_base_F") + (allMissionObjects "Carrier_01_base_F");
    {
        private _cPos = getPosATL _x;
        private _alreadyAdded = false;
        {
            if ((_x select 1) distance2D _cPos < 800) exitWith { _alreadyAdded = true; };
        } forEach _airports;
        if (!_alreadyAdded) then {
            _airports pushBack [_x, _cPos, "Авианосец (Carrier)", "CARRIER"];
        };
    } forEach _carriers;

    // 3. Helipads / Forward Operating Bases
    private _helipads = nearestObjects [_wCenter, ["Helipad_Base_F", "Land_HelipadCircle_F", "Land_HelipadCivil_F", "Land_HelipadSquare_F"], _wSize max 40000];
    {
        if (_forEachIndex < 12) then {
            private _hPos = getPosATL _x;
            private _alreadyAdded = false;
            {
                if ((_x select 1) distance2D _hPos < 600) exitWith { _alreadyAdded = true; };
            } forEach _airports;
            if (!_alreadyAdded) then {
                _airports pushBack [_x, _hPos, "Вертодром", "HELIPAD"];
            };
        };
    } forEach _helipads;

    AIRDEF_discoveredAirports = _airports;
};

private _isRtbPending = (missionNamespace getVariable ["AIRDEF_pendingOrder", ""]) == "RTB";

private _defaultAptIcon = getText (configFile >> "CfgMarkers" >> "loc_Airport" >> "icon");
if (_defaultAptIcon == "") then {
    _defaultAptIcon = getText (configFile >> "CfgLocationTypes" >> "Airport" >> "texture");
};
if (_defaultAptIcon == "") then {
    _defaultAptIcon = "\A3\ui_f\data\map\markers\nato\b_air.paa";
};

private _defaultHeliIcon = getText (configFile >> "CfgMarkers" >> "loc_Heliport" >> "icon");
if (_defaultHeliIcon == "") then {
    _defaultHeliIcon = "\A3\ui_f\data\map\markers\nato\b_air.paa";
};

{
    _x params ["_aptObj", "_aptPos", "_aptName", ["_aptType", "AIRPORT"]];
    private _aptPos2D = [_aptPos select 0, _aptPos select 1, 0];
    private _iconPath = if (_aptType == "HELIPAD") then { _defaultHeliIcon } else { _defaultAptIcon };

    if (_isRtbPending) then {
        // Highlight airports during RTB selection mode: compact tactical bracket
        private _pulse = 0.70 + 0.30 * sin (time * 8);
        private _highlightColor = [0.2, 1, 0.95, _pulse];

        _map drawEllipse [_aptPos2D, 500, 500, 0, _highlightColor, ""];
        _map drawEllipse [_aptPos2D, 300, 300, 0, [0.2, 1, 0.95, _pulse * 0.6], ""];

        _map drawIcon [
            _iconPath,
            _highlightColor,
            _aptPos2D,
            30, 30, 0,
            format [" [ВПП: КЛИК ДЛЯ ПОСАДКИ] %1", _aptName],
            0,
            0.028,
            "RobotoCondensed",
            "right"
        ];
    } else {
        // Normal clean tactical airfield icon
        _map drawIcon [
            _iconPath,
            [0.2, 0.85, 0.70, 0.85],
            _aptPos2D,
            24, 24, 0,
            format [" [ВПП] %1", _aptName],
            0,
            0.024,
            "RobotoCondensed",
            "right"
        ];
    };
} forEach (missionNamespace getVariable ["AIRDEF_discoveredAirports", []]);

// Top pulsing banner during RTB selection
if (_isRtbPending) then {
    private _screenTop = _map ctrlMapScreenToWorld [0.5, 0.08];
    if (count _screenTop > 0) then {
        private _bannerPulse = 0.8 + 0.2 * sin (time * 6);
        _map drawIcon [
            "#(argb,8,8,3)color(0,0,0,0)",
            [0.2, 1, 0.95, _bannerPulse],
            _screenTop,
            0, 0, 0,
            "[РЕЖИМ RTB: КЛИКНИТЕ АЭРОДРОМ ИЛИ БАЗУ ДЛЯ ВОЗВРАТА]",
            0,
            0.034,
            "RobotoCondensed",
            "center"
        ];
    };
};


// ================= 2. HOSTILE RADARS (RED SAM THREAT RINGS) =================
{
    _x params ["_rObj", "_rPos", "_rRange", "_rName"];
    private _rCenter2D = [_rPos select 0, _rPos select 1, 0];
    
    if (AIRDEF_showRings) then {
        // Red threat ring of enemy SAM / radar
        _map drawEllipse [_rCenter2D, _rRange, _rRange, 0, [1, 0.25, 0.15, 0.40], ""];
        _map drawEllipse [_rCenter2D, _rRange * 0.5, _rRange * 0.5, 0, [1, 0.25, 0.15, 0.20], ""];
        
        private _labelPos = [(_rCenter2D select 0), (_rCenter2D select 1) + _rRange, 0];
        _map drawIcon [
            "#(argb,8,8,3)color(0,0,0,0)",
            [1, 0.3, 0.2, 0.75],
            _labelPos,
            0, 0, 0,
            format ["ЗОНА ПВО ВРАГА: %1 (%2 КМ)", _rName, round (_rRange / 1000)],
            0,
            0.026,
            "RobotoCondensed",
            "center"
        ];
    };
    
    if (AIRDEF_filter in ["ALL", "HOSTILE"]) then {
        _map drawIcon [
            "\A3\ui_f\data\map\markers\nato\o_installation.paa",
            [1, 0.3, 0.2, 0.9],
            _rCenter2D,
            20, 20, 0,
            format ["[!] %1", _rName],
            0,
            0.026,
            "RobotoCondensed",
            "right"
        ];
    };
} forEach AIRDEF_hostileRadars;


// ================= 3. TARGET TRACKS & CONTACTS =================
private _lastFrameTime = missionNamespace getVariable ["AIRDEF_lastDrawFrameTime", time - 0.016];
private _frameDelta = (time - _lastFrameTime) max 0.001 min 1.0;
missionNamespace setVariable ["AIRDEF_lastDrawFrameTime", time];

private _sweepSpeed = missionNamespace getVariable ["AIRDEF_sweepSpeed", 60];
private _revPeriod = (360 / (_sweepSpeed max 10)) max 4.0;

{
    _x params [
        "_id", "_obj", "_pos", "_timeSeen", "_speedKmh", "_altM", "_dir", "_name", "_side", "_isMissile", "_isDataLink"
    ];

    private _isFriendlyTrack = (_side == _userSide || [_userSide, _side] call BIS_fnc_sideIsFriendly);

    private _displayTarget = true;
    switch (AIRDEF_filter) do {
        case "FRIENDLY": { _displayTarget = (_isFriendlyTrack && !_isMissile); };
        case "HOSTILE":  { _displayTarget = (!_isFriendlyTrack && !_isMissile); };
        case "MISSILES": { _displayTarget = _isMissile; };
        case "DATALINK": { _displayTarget = _isDataLink; };
        default          { _displayTarget = true; };
    };

    if (_displayTarget) then {
        private _realPosASL = if (!isNull _obj) then { getPosASL _obj } else { _pos };
        
        // 1. Check if ANY active friendly radar swept across this target in the last frame
        private _wasSwept = false;
        {
            _x params ["_rObj", "_rPos", "_rRange", "_rName", "_phaseOffset"];
            if (!(_rObj getVariable ["AIRDEF_radarEmissionOff", false]) && { (_realPosASL distance2D _rPos) <= _rRange }) then {
                private _currSweep = ((time * _sweepSpeed) + _phaseOffset) % 360;
                private _prevSweep = (((time - _frameDelta) * _sweepSpeed) + _phaseOffset) % 360;
                private _deltaAngle = (_currSweep - _prevSweep + 360) % 360;
                
                if (_deltaAngle > 0 && _deltaAngle < 90) then {
                    private _bearing = _rPos getDir _realPosASL;
                    if (((_bearing - _prevSweep + 360) % 360) <= _deltaAngle) then {
                        _wasSwept = true;
                    };
                };
            };
            if (_wasSwept) exitWith {};
        } forEach AIRDEF_activeRadars;

        // 2. Retrieve persistent plot data: [_drawnPos, _drawnDir, _drawnSpeed, _drawnAlt, _lastSweepTime, _trailHistory]
        private _plotData = if (!isNull _obj) then { _obj getVariable ["AIRDEF_plotData", []] } else { [] };
        private _drawnPos = _realPosASL;
        private _drawnDir = if (!isNull _obj) then { getDir _obj } else { _dir };
        private _drawnSpeed = if (!isNull _obj) then { round (speed _obj) } else { _speedKmh };
        private _drawnAlt = round (_realPosASL select 2);
        private _lastSweepTime = time;
        private _trailHistory = [];

        if (count _plotData > 0) then {
            _plotData params ["_pPos", "_pDir", "_pSpd", "_pAlt", "_pSwTime", "_pHist"];
            _drawnPos = _pPos;
            _drawnDir = _pDir;
            _drawnSpeed = _pSpd;
            _drawnAlt = _pAlt;
            _lastSweepTime = _pSwTime;
            _trailHistory = _pHist;
        };

        private _continuous = missionNamespace getVariable ["AIRDEF_continuousUpdate", false];

        if (_isFriendlyTrack && !_isMissile) then {
            // Friendly aircraft transmit live GPS coordinates via IFF transponder & DataLink
            _drawnPos = _realPosASL;
            _drawnDir = if (!isNull _obj) then { getDir _obj } else { _dir };
            _drawnSpeed = if (!isNull _obj) then { round (speed _obj) } else { _speedKmh };
            _drawnAlt = round (_realPosASL select 2);
            if (_wasSwept || _continuous) then {
                _lastSweepTime = time;
            };
            if (!isNull _obj) then {
                _obj setVariable ["AIRDEF_plotData", [_drawnPos, _drawnDir, _drawnSpeed, _drawnAlt, _lastSweepTime, _trailHistory], false];
            };
        } else {
            // Hostiles & missiles: update either when radar beam sweeps across them, OR continuously if continuous mode is enabled!
            if (_wasSwept || _continuous || count _plotData == 0) then {
                if (_drawnPos distance2D _realPosASL > 30) then {
                    _trailHistory pushBack [_drawnPos, _drawnDir, _lastSweepTime];
                    if (count _trailHistory > 4) then {
                        _trailHistory deleteAt 0;
                    };
                };
                _drawnPos = _realPosASL;
                _drawnDir = if (!isNull _obj) then { getDir _obj } else { _dir };
                _drawnSpeed = if (!isNull _obj) then { round (speed _obj) } else { _speedKmh };
                _drawnAlt = round (_realPosASL select 2);
                _lastSweepTime = time;

                if (!isNull _obj) then {
                    _obj setVariable ["AIRDEF_plotData", [_drawnPos, _drawnDir, _drawnSpeed, _drawnAlt, _lastSweepTime, _trailHistory], false];
                };
            };
        };

        // 3. Phosphor Persistence & Decay Calculation
        private _timeSinceSweep = (time - _lastSweepTime) max 0;
        private _phosphorAlpha = if (_continuous) then { 1.0 } else {
            if (_timeSinceSweep <= _revPeriod) then {
                // Decay from 1.0 down to 0.40 over one antenna revolution
                (1.0 - ((_timeSinceSweep / _revPeriod) * 0.60)) max 0.40
            } else {
                // Target lost / shielded behind terrain: gradual fadeout into darkness
                (0.40 - (((_timeSinceSweep - _revPeriod) / 12) * 0.40)) max 0.05
            }
        };

        private _drawPos2D = [_drawnPos select 0, _drawnPos select 1, 0];

        // 4. Draw Phosphor Trail (Historical breadcrumbs from previous sweeps)
        if (count _trailHistory > 0 && !_isFriendlyTrack) then {
            private _trailCount = count _trailHistory;
            for "_t" from 0 to (_trailCount - 1) do {
                private _histEntry = _trailHistory select _t;
                _histEntry params ["_hPos", "_hDir", "_hTime"];
                private _hAge = time - _hTime;
                if (_hAge < 35) then {
                    private _stepIdx = (_trailCount - 1) - _t; // 0 = previous sweep, 1 = 2 sweeps ago...
                    private _histAlpha = (0.50 - (_stepIdx * 0.11)) max 0.08;
                    private _dotSize = (10 - (_stepIdx * 2)) max 4;
                    private _dotColor = if (_isMissile) then {
                        [1, 0.35, 0.15, _histAlpha]
                    } else {
                        if (_isDataLink) then { [0.2, 0.7, 0.9, _histAlpha] } else { [1, 0.4, 0.25, _histAlpha] }
                    };
                    _map drawIcon [
                        "\A3\ui_f\data\map\markers\military\dot_CA.paa",
                        _dotColor,
                        [_hPos select 0, _hPos select 1, 0],
                        _dotSize, _dotSize, 0,
                        "", 0, 0, "", "center"
                    ];
                };
            };
        };

        // 5. Draw Primary Target Icon
        if (_isMissile) then {
            // 5.1. MISSILE TRACK
            private _isFlash = (_timeSinceSweep < 0.25);
            private _mColor = [1, 0.2, 0.1, if (_isFlash) then { 1.0 } else { _phosphorAlpha }];
            private _mSize = if (_isFlash) then { 26 } else { 22 };

            _map drawIcon [
                "\A3\ui_f\data\map\markers\nato\o_art.paa",
                _mColor,
                _drawPos2D,
                _mSize, _mSize, _drawnDir,
                format ["!РАКЕТА! %1 KM/H | H:%2M", _drawnSpeed, _drawnAlt],
                0,
                0.030,
                "RobotoCondensed",
                "right"
            ];

            if (AIRDEF_showVectors) then {
                private _vecLen = (_drawnSpeed / 3.6) * 15;
                private _vecEnd = [(_drawPos2D select 0) + (sin _drawnDir) * _vecLen, (_drawPos2D select 1) + (cos _drawnDir) * _vecLen, 0];
                _map drawLine [_drawPos2D, _vecEnd, [1, 0.2, 0.1, 0.75]];
            };
        } else {
            if (_isFriendlyTrack) then {
                // 5.2. FRIENDLY AIRCRAFT (IFF & DATALINK)
                private _isRotary = if (!isNull _obj) then { _obj isKindOf "Helicopter" } else { false };
                private _iconPath = if (_isRotary) then { "\A3\ui_f\data\map\markers\nato\b_air.paa" } else { "\A3\ui_f\data\map\markers\nato\b_plane.paa" };
                
                // Friendly pulses to 1.0 on sweep, otherwise stays at a solid 0.88
                private _fAlpha = if (_timeSinceSweep < 0.3) then { 1.0 } else { 0.88 };
                private _fColor = [0.2, 1, 0.45, _fAlpha];

                _map drawIcon [
                    _iconPath,
                    _fColor,
                    _drawPos2D,
                    24, 24, _drawnDir,
                    format ["%1 [H:%2 SPD:%3]", _name, _drawnAlt, _drawnSpeed],
                    0,
                    0.028,
                    "RobotoCondensed",
                    "right"
                ];

                if (AIRDEF_showVectors && _drawnSpeed > 20) then {
                    private _vecLen = (_drawnSpeed / 3.6) * 30;
                    private _vecEnd = [(_drawPos2D select 0) + (sin _drawnDir) * _vecLen, (_drawPos2D select 1) + (cos _drawnDir) * _vecLen, 0];
                    _map drawLine [_drawPos2D, _vecEnd, [0.2, 1, 0.45, 0.6]];
                };
            } else {
                // 5.3. HOSTILE / UNKNOWN CONTACT (PRIMARY RADAR)
                private _isFlash = (_timeSinceSweep < 0.25);
                private _hColor = if (_isDataLink) then {
                    [0.2, 0.85, 1, if (_isFlash) then { 1.0 } else { _phosphorAlpha }]
                } else {
                    [1, 0.3, 0.2, if (_isFlash) then { 1.0 } else { _phosphorAlpha }]
                };

                private _iconPath = "\A3\ui_f\data\map\markers\nato\o_plane.paa";
                private _prefix = if (_isDataLink) then { "[DL]" } else { "[TGT]" };
                private _hSize = if (_isFlash) then { 25 } else { 22 };

                _map drawIcon [
                    _iconPath,
                    _hColor,
                    _drawPos2D,
                    _hSize, _hSize, _drawnDir,
                    format ["%1 %2 [H:%3 SPD:%4]", _prefix, _name, _drawnAlt, _drawnSpeed],
                    0,
                    0.027,
                    "RobotoCondensed",
                    "right"
                ];

                if (AIRDEF_showVectors && _drawnSpeed > 20) then {
                    private _vecLen = (_drawnSpeed / 3.6) * 20;
                    private _vecEnd = [(_drawPos2D select 0) + (sin _drawnDir) * _vecLen, (_drawPos2D select 1) + (cos _drawnDir) * _vecLen, 0];
                    _map drawLine [_drawPos2D, _vecEnd, [_hColor select 0, _hColor select 1, _hColor select 2, 0.45]];
                };
            };
        };
    };
} forEach AIRDEF_trackCache;


// ================= 4. SELECTION & INTERCEPT VECTORS =================
if (!isNull AIRDEF_selectedUnit && { alive AIRDEF_selectedUnit }) then {
    private _selPos = getPosASL AIRDEF_selectedUnit;
    _map drawEllipse [_selPos, 700, 700, 0, [0.2, 1, 0.5, 0.85], ""];
    _map drawEllipse [_selPos, 850, 850, 0, [0.2, 1, 0.5, 0.5], ""];
};

if (!isNull AIRDEF_targetUnit && { alive AIRDEF_targetUnit }) then {
    private _tgtPos = getPosASL AIRDEF_targetUnit;
    private _tgtPlot = AIRDEF_targetUnit getVariable ["AIRDEF_plotData", []];
    if (count _tgtPlot > 0) then {
        _tgtPos = _tgtPlot select 0;
    };

    _map drawEllipse [_tgtPos, 700, 700, 0, [1, 0.2, 0.1, 0.9], ""];
    _map drawEllipse [_tgtPos, 850, 850, 0, [1, 0.2, 0.1, 0.5], ""];

    if (!isNull AIRDEF_selectedUnit && { alive AIRDEF_selectedUnit }) then {
        private _fPos = getPosASL AIRDEF_selectedUnit;
        _map drawLine [_fPos, _tgtPos, [1, 0.9, 0.1, 0.85]];

        private _dist = round (_fPos distance _tgtPos);
        private _bearing = round (_fPos getDir _tgtPos);
        private _midPos = [((_fPos select 0) + (_tgtPos select 0)) / 2, ((_fPos select 1) + (_tgtPos select 1)) / 2, 0];

        _map drawIcon [
            "#(argb,8,8,3)color(0,0,0,0)",
            [1, 0.9, 0.2, 0.9],
            _midPos,
            0, 0, 0,
            format ["КУРС: %1° | ДИСТ: %2 КМ", _bearing, round (_dist / 1000)],
            0,
            0.030,
            "RobotoCondensed",
            "center"
        ];
    };
};
