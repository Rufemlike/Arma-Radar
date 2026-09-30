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
        AIRDEF_selectedRadar = player;
    };
};

{
    _x params ["_rObj", "_rPos", "_rRange", "_rName", "_phaseOffset"];
    private _rCenter2D = [_rPos select 0, _rPos select 1, 0];
    private _isSelectedStation = (_rObj isEqualTo AIRDEF_selectedRadar) || { count AIRDEF_activeRadars == 1 };
    
    if (_isSelectedStation) then {
        // === DETAILED CRT RINGS FOR SELECTED ACTIVE RADAR ONLY ===
        if (AIRDEF_showRings) then {
            // Outer boundary (100%)
            _map drawEllipse [_rCenter2D, _rRange, _rRange, 0, [0, 1, 0.35, 0.85], "#(rgb,8,8,3)color(0,0,0,0)"];
            for "_a" from 0 to 350 step 10 do {
                private _p1 = [(_rCenter2D select 0) + (sin _a) * _rRange, (_rCenter2D select 1) + (cos _a) * _rRange, 0];
                private _p2 = [(_rCenter2D select 0) + (sin (_a + 10)) * _rRange, (_rCenter2D select 1) + (cos (_a + 10)) * _rRange, 0];
                _map drawLine [_p1, _p2, [0, 1, 0.35, 0.9]];
            };

            // 75% Range ring
            _map drawEllipse [_rCenter2D, _rRange * 0.75, _rRange * 0.75, 0, [0, 0.85, 0.28, 0.50], "#(rgb,8,8,3)color(0,0,0,0)"];
            for "_a" from 0 to 350 step 15 do {
                private _p1 = [(_rCenter2D select 0) + (sin _a) * (_rRange * 0.75), (_rCenter2D select 1) + (cos _a) * (_rRange * 0.75), 0];
                private _p2 = [(_rCenter2D select 0) + (sin (_a + 15)) * (_rRange * 0.75), (_rCenter2D select 1) + (cos (_a + 15)) * (_rRange * 0.75), 0];
                _map drawLine [_p1, _p2, [0, 0.85, 0.28, 0.55]];
            };

            // 50% Range ring
            _map drawEllipse [_rCenter2D, _rRange * 0.50, _rRange * 0.50, 0, [0, 0.8, 0.25, 0.55], "#(rgb,8,8,3)color(0,0,0,0)"];
            for "_a" from 0 to 350 step 15 do {
                private _p1 = [(_rCenter2D select 0) + (sin _a) * (_rRange * 0.5), (_rCenter2D select 1) + (cos _a) * (_rRange * 0.5), 0];
                private _p2 = [(_rCenter2D select 0) + (sin (_a + 15)) * (_rRange * 0.5), (_rCenter2D select 1) + (cos (_a + 15)) * (_rRange * 0.5), 0];
                _map drawLine [_p1, _p2, [0, 0.8, 0.25, 0.6]];
            };

            // 25% Range ring
            _map drawEllipse [_rCenter2D, _rRange * 0.25, _rRange * 0.25, 0, [0, 0.65, 0.2, 0.45], "#(rgb,8,8,3)color(0,0,0,0)"];
            for "_a" from 0 to 350 step 20 do {
                private _p1 = [(_rCenter2D select 0) + (sin _a) * (_rRange * 0.25), (_rCenter2D select 1) + (cos _a) * (_rRange * 0.25), 0];
                private _p2 = [(_rCenter2D select 0) + (sin (_a + 20)) * (_rRange * 0.25), (_rCenter2D select 1) + (cos (_a + 20)) * (_rRange * 0.25), 0];
                _map drawLine [_p1, _p2, [0, 0.65, 0.2, 0.50]];
            };

            // 10% Range ring (close-in reference)
            _map drawEllipse [_rCenter2D, _rRange * 0.10, _rRange * 0.10, 0, [0, 0.55, 0.18, 0.40], "#(rgb,8,8,3)color(0,0,0,0)"];
            for "_a" from 0 to 350 step 30 do {
                private _p1 = [(_rCenter2D select 0) + (sin _a) * (_rRange * 0.1), (_rCenter2D select 1) + (cos _a) * (_rRange * 0.1), 0];
                private _p2 = [(_rCenter2D select 0) + (sin (_a + 30)) * (_rRange * 0.1), (_rCenter2D select 1) + (cos (_a + 30)) * (_rRange * 0.1), 0];
                _map drawLine [_p1, _p2, [0, 0.55, 0.18, 0.45]];
            };
            
            // Cardinal crosshairs (N-S, E-W)
            _map drawLine [
                [(_rCenter2D select 0) - _rRange, _rCenter2D select 1, 0],
                [(_rCenter2D select 0) + _rRange, _rCenter2D select 1, 0],
                [0, 0.7, 0.22, 0.35]
            ];
            _map drawLine [
                [_rCenter2D select 0, (_rCenter2D select 1) - _rRange, 0],
                [_rCenter2D select 0, (_rCenter2D select 1) + _rRange, 0],
                [0, 0.7, 0.22, 0.35]
            ];
            
            // Range distance labels along the North axis
            {
                private _distFraction = _x;
                private _distKm = round ((_rRange * _distFraction) / 1000);
                private _tickPos = [(_rCenter2D select 0), (_rCenter2D select 1) + (_rRange * _distFraction), 0];
                _map drawIcon [
                    "#(argb,8,8,3)color(0,0,0,0)",
                    [0, 0.85, 0.25, 0.75],
                    _tickPos,
                    0, 0, 0,
                    format ["%1 КМ", _distKm],
                    0,
                    0.024,
                    "EtelkaMonospacePro",
                    "center"
                ];
            } forEach [0.25, 0.50, 0.75, 1.0];
            
            private _labelPos = [(_rCenter2D select 0), (_rCenter2D select 1) + _rRange + 400, 0];
            _map drawIcon [
                "#(argb,8,8,3)color(0,0,0,0)",
                [0.2, 1, 0.4, 0.95],
                _labelPos,
                0, 0, 0,
                format ["%1 (ЗОНА: %2 КМ) [АКТИВЕН]", _rName, round (_rRange / 1000)],
                0,
                0.028,
                "EtelkaMonospaceProBold",
                "center"
            ];
        };
        
        // Rotating sweep beam for selected radar only
        if (AIRDEF_showSweep) then {
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
        // === SECONDARY RADAR STATION: CLEAN FAINT OUTLINE ONLY ===
        if (AIRDEF_showRings) then {
            _map drawEllipse [_rCenter2D, _rRange, _rRange, 0, [0, 0.7, 0.25, 0.25], ""];
        };
    };
    
    // Station icon & label
    if (AIRDEF_filter in ["ALL", "FRIENDLY", "DATALINK"]) then {
        private _iconColor = if (_isSelectedStation) then { [0.2, 1, 0.4, 0.95] } else { [0.1, 0.65, 0.25, 0.75] };
        private _iconText  = if (_isSelectedStation) then { format ["[*] %1", _rName] } else { format ["[РЛС] %1", _rName] };
        _map drawIcon [
            "\A3\ui_f\data\map\markers\nato\b_installation.paa",
            _iconColor,
            _rCenter2D,
            22, 22, 0,
            _iconText,
            0,
            0.026,
            "EtelkaMonospaceProBold",
            "right"
        ];
    };
} forEach AIRDEF_activeRadars;


// ================= 1.5. AIRPORTS & RECOVERY BASES =================
if (isNil "AIRDEF_discoveredAirports" || { count (missionNamespace getVariable ["AIRDEF_discoveredAirports", []]) == 0 }) then {
    private _airports = [];

    // 1. Engine airports (allAirports)
    {
        private _apt = _x;
        private _pos = if (_apt isEqualType 0) then { getAirportPosition _apt } else { getPosATL _apt };
        if (count _pos >= 2 && { !(_pos isEqualTo [0,0,0]) }) then {
            private _name = "";
            private _locs = nearestLocations [_pos, ["Airport", "NameCityCapital", "NameCity", "NameVillage", "NameLocal"], 3000];
            if (count _locs > 0) then {
                private _locText = text (_locs select 0);
                if (_locText != "") then {
                    _name = format ["Аэродром %1", _locText];
                };
            };
            if (_name == "") then {
                _name = if (_apt isEqualType 0) then { format ["Аэродром #%1", _apt] } else { getText (configFile >> "CfgVehicles" >> typeOf _apt >> "displayName") };
            };
            _airports pushBack [_apt, _pos, _name, "AIRPORT"];
        };
    } forEach allAirports;

    // 2. Named map locations of type "Airport" (if not already close to an existing entry)
    private _wSize = if (isNil "worldSize" || { worldSize <= 0 }) then { 40000 } else { worldSize };
    private _aptLocs = nearestLocations [[_wSize / 2, _wSize / 2, 0], ["Airport"], _wSize max 40000];
    {
        private _locPos = locationPosition _x;
        private _locText = text _x;
        if (_locText == "") then { _locText = "Аэродром"; };
        private _alreadyAdded = false;
        {
            if ((_x select 1) distance2D _locPos < 1500) exitWith { _alreadyAdded = true; };
        } forEach _airports;

        if (!_alreadyAdded) then {
            _airports pushBack [-1, _locPos, _locText, "AIRPORT"];
        };
    } forEach _aptLocs;

    // 3. Aircraft carriers on the map
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

    AIRDEF_discoveredAirports = _airports;
};

private _isRtbPending = (missionNamespace getVariable ["AIRDEF_pendingOrder", ""]) == "RTB";

{
    _x params ["_aptObj", "_aptPos", "_aptName", "_aptType"];
    private _aptPos2D = [_aptPos select 0, _aptPos select 1, 0];

    if (_isRtbPending) then {
        // Highlight airports during RTB selection mode
        private _pulse = 0.65 + 0.35 * sin (time * 8);
        private _highlightColor = [0.2, 1, 0.95, _pulse];

        // Pulsing selection rings around airport
        _map drawEllipse [_aptPos2D, 1200, 1200, 0, _highlightColor, ""];
        _map drawEllipse [_aptPos2D, 1600, 1600, 0, [0.2, 1, 0.95, _pulse * 0.4], ""];

        _map drawIcon [
            "\A3\ui_f\data\map\mapcontrol\Airport_ca.paa",
            _highlightColor,
            _aptPos2D,
            28, 28, 0,
            format ["[ВПП: КЛИК ДЛЯ ВЫБОРА] %1", _aptName],
            0,
            0.030,
            "EtelkaMonospaceProBold",
            "right"
        ];
    } else {
        // Normal clean tactical airfield icon
        _map drawIcon [
            "\A3\ui_f\data\map\mapcontrol\Airport_ca.paa",
            [0.2, 0.85, 0.7, 0.75],
            _aptPos2D,
            22, 22, 0,
            format ["[ВПП] %1", _aptName],
            0,
            0.024,
            "EtelkaMonospacePro",
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
            "EtelkaMonospaceProBold",
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
            "EtelkaMonospacePro",
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
            "EtelkaMonospaceProBold",
            "right"
        ];
    };
} forEach AIRDEF_hostileRadars;


// ================= 3. TARGET TRACKS & CONTACTS =================
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
        private _drawPos = [_pos select 0, _pos select 1, 0];

        // 3.1. MISSILE TRACK
        if (_isMissile) then {
            private _pulseAlpha = 0.5 + 0.5 * abs (sin (time * 10));
            private _missileColor = [1, 0.2, 0.1, _pulseAlpha];

            _map drawIcon [
                "\A3\ui_f\data\map\markers\nato\o_art.paa",
                _missileColor,
                _drawPos,
                24, 24, _dir,
                format ["!РАКЕТА! %1 KM/H | H:%2M", _speedKmh, _altM],
                0,
                0.030,
                "EtelkaMonospaceProBold",
                "right"
            ];

            if (AIRDEF_showVectors) then {
                private _vecLen = (_speedKmh / 3.6) * 15;
                private _vecEnd = [(_drawPos select 0) + (sin _dir) * _vecLen, (_drawPos select 1) + (cos _dir) * _vecLen, 0];
                _map drawLine [_drawPos, _vecEnd, [1, 0.2, 0.1, 0.75]];
            };
        } else {
            // 3.2. FRIENDLY AIRCRAFT (IFF)
            if (_isFriendlyTrack) then {
                private _isRotary = if (!isNull _obj) then { _obj isKindOf "Helicopter" } else { false };
                private _iconPath = if (_isRotary) then { "\A3\ui_f\data\map\markers\nato\b_air.paa" } else { "\A3\ui_f\data\map\markers\nato\b_plane.paa" };
                private _fColor = [0.2, 1, 0.45, 0.95];

                _map drawIcon [
                    _iconPath,
                    _fColor,
                    _drawPos,
                    24, 24, _dir,
                    format ["%1 [H:%2 SPD:%3]", _name, _altM, _speedKmh],
                    0,
                    0.028,
                    "EtelkaMonospacePro",
                    "right"
                ];

                if (AIRDEF_showVectors && _speedKmh > 20) then {
                    private _vecLen = (_speedKmh / 3.6) * 30;
                    private _vecEnd = [(_drawPos select 0) + (sin _dir) * _vecLen, (_drawPos select 1) + (cos _dir) * _vecLen, 0];
                    _map drawLine [_drawPos, _vecEnd, [0.2, 1, 0.45, 0.6]];
                };
            } else {
                // 3.3. HOSTILE / UNKNOWN / DATALINK CONTACT
                private _decayAge = time - _timeSeen;
                private _alpha = (1 - (_decayAge / 10)) max 0.25;
                
                private _hColor = if (_isDataLink) then {
                    [0.2, 0.85, 1, _alpha]
                } else {
                    [1, 0.3, 0.2, _alpha]
                };

                private _iconPath = "\A3\ui_f\data\map\markers\nato\o_plane.paa";
                private _prefix = if (_isDataLink) then { "[DL]" } else { "[TGT]" };

                _map drawIcon [
                    _iconPath,
                    _hColor,
                    _drawPos,
                    22, 22, _dir,
                    format ["%1 %2 [H:%3 SPD:%4]", _prefix, _name, _altM, _speedKmh],
                    0,
                    0.027,
                    "EtelkaMonospacePro",
                    "right"
                ];

                if (AIRDEF_showVectors && _speedKmh > 20) then {
                    private _vecLen = (_speedKmh / 3.6) * 20;
                    private _vecEnd = [(_drawPos select 0) + (sin _dir) * _vecLen, (_drawPos select 1) + (cos _dir) * _vecLen, 0];
                    _map drawLine [_drawPos, _vecEnd, [_hColor select 0, _hColor select 1, _hColor select 2, 0.45]];
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
            "EtelkaMonospaceProBold",
            "center"
        ];
    };
};
