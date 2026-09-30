/*
    Author: Arma Radar Team
    File: fn_radarBoard.sqf
    Description:
        3D Tactical Radar Board System.
        Projects real-time circular radar display onto in-game boards, screens, and monitors
        (e.g. Land_MapBoard_F, Land_TripodScreen_01_large_F, Land_FlatTV_01_F, Land_NoticeBoard_F).
        
        Features:
        - Changes board surface to dark tactical CRT glass.
        - Renders range rings, rotating sweep beam, and contact blips directly on the board plane via Draw3D.
        - Distance-culled: draws only when player is within 15m of the board (0% FPS impact outside).
        - Attaches action [F] Включить терминал РЛС to open full interactive screen.
*/

params [["_board", objNull]];

// Register single board if provided
if (!isNull _board) then {
    if (!(_board isKindOf "CAManBase")) then {
        _board setVariable ["AIRDEF_isRadarBoard", true, true];
        
        // Dark tactical CRT display texture on board surface
        _board setObjectTexture [0, "#(argb,8,8,3)color(0.015,0.035,0.025,1)"];
        
        // Add terminal interaction action to board
        if (hasInterface) then {
            [_board] call AIRDEF_fnc_setupTerminal;
        };
        
        private _boards = missionNamespace getVariable ["AIRDEF_radarBoards", []];
        if !(_board in _boards) then {
            _boards pushBackUnique _board;
            missionNamespace setVariable ["AIRDEF_radarBoards", _boards, true];
        };
    };
};

if (!hasInterface) exitWith {};

// Start 3D Drawing loop if not already active
if (isNil "AIRDEF_radarBoardDraw3D") then {
    AIRDEF_radarBoardDraw3D = addMissionEventHandler ["Draw3D", {
        private _boards = missionNamespace getVariable ["AIRDEF_radarBoards", []];
        if (count _boards == 0) exitWith {};
        
        private _playerPos = getPosASL player;
        private _userSide = playerSide;
        if (_userSide in [sideLogic, civilian, sideUnknown]) then {
            if (!isNull player && { (side (group player)) in [west, east, independent] }) then {
                _userSide = side (group player);
            } else {
                _userSide = west;
            };
        };
        
        // Find reference radar station (selected or primary)
        private _refRadar = if (!isNil "AIRDEF_selectedRadar" && { !isNull AIRDEF_selectedRadar }) then {
            private _found = [];
            { if ((_x select 0) isEqualTo AIRDEF_selectedRadar) exitWith { _found = _x; }; } forEach AIRDEF_activeRadars;
            _found
        } else {
            if (count AIRDEF_activeRadars > 0) then { AIRDEF_activeRadars select 0 } else { [] };
        };
        
        if (count _refRadar == 0) exitWith {};
        _refRadar params ["_rObj", "_rPos", "_rRange", "_rName", "_phaseOffset"];
        
        private _sweepSpeed = missionNamespace getVariable ["AIRDEF_sweepSpeed", 60];
        private _sweepAngle = ((time * _sweepSpeed) + _phaseOffset) % 360;
        
        private _isEmissionOff = _rObj getVariable ["AIRDEF_radarEmissionOff", false];

        {
            private _b = _x;
            if (!isNull _b && { alive _b } && { _b getVariable ["AIRDEF_isRadarBoard", false] } && { (_playerPos distance (getPosASL _b)) <= 15 }) then {
                // Calculate 3D board plane geometry
                private _bType = typeOf _b;
                private _centerOffset = [0, 0.05, 0.2];
                private _boardW = 1.35;
                private _boardH = 0.90;
                
                switch (true) do {
                    case (_b isKindOf "Land_TripodScreen_01_large_F"): {
                        _centerOffset = [0, 0.02, 1.55];
                        _boardW = 1.95;
                        _boardH = 1.35;
                    };
                    case (_b isKindOf "Land_FlatTV_01_F"): {
                        _centerOffset = [0, 0.03, 0];
                        _boardW = 1.10;
                        _boardH = 0.65;
                    };
                    case (_b isKindOf "Land_NoticeBoard_F"): {
                        _centerOffset = [0, 0.03, 0];
                        _boardW = 1.30;
                        _boardH = 0.85;
                    };
                    default {
                        _centerOffset = [0, 0.05, 0.2];
                        _boardW = 1.35;
                        _boardH = 0.90;
                    };
                };
                
                private _c3D = _b modelToWorldVisual _centerOffset;
                private _bDir = vectorDir _b;
                private _bUp = vectorUp _b;
                private _bRight = _bDir vectorCrossProduct _bUp;
                
                // Normal offset (2 cm in front of surface to prevent Z-fighting)
                private _dispCenter = _c3D vectorAdd (_bDir vectorMultiply 0.02);
                private _dispRadius = (_boardW min _boardH) * 0.45;
                
                private _ringColor1 = if (_isEmissionOff) then { [1, 0.55, 0.15, 0.70] } else { [0, 0.85, 0.3, 0.75] };
                private _ringColor2 = if (_isEmissionOff) then { [0.8, 0.45, 0.12, 0.45] } else { [0, 0.65, 0.22, 0.45] };
                private _crossColor = if (_isEmissionOff) then { [0.8, 0.45, 0.12, 0.35] } else { [0, 0.6, 0.2, 0.35] };

                // 1. Draw Range Rings (100% and 50%)
                for "_a" from 0 to 330 step 30 do {
                    private _rad1 = _a * (pi / 180);
                    private _rad2 = (_a + 30) * (pi / 180);
                    private _p1 = _dispCenter vectorAdd (_bRight vectorMultiply ((sin _rad1) * _dispRadius)) vectorAdd (_bUp vectorMultiply ((cos _rad1) * _dispRadius));
                    private _p2 = _dispCenter vectorAdd (_bRight vectorMultiply ((sin _rad2) * _dispRadius)) vectorAdd (_bUp vectorMultiply ((cos _rad2) * _dispRadius));
                    drawLine3D [_p1, _p2, _ringColor1];
                    
                    private _p1Half = _dispCenter vectorAdd (_bRight vectorMultiply ((sin _rad1) * (_dispRadius * 0.5))) vectorAdd (_bUp vectorMultiply ((cos _rad1) * (_dispRadius * 0.5)));
                    private _p2Half = _dispCenter vectorAdd (_bRight vectorMultiply ((sin _rad2) * (_dispRadius * 0.5))) vectorAdd (_bUp vectorMultiply ((cos _rad2) * (_dispRadius * 0.5)));
                    drawLine3D [_p1Half, _p2Half, _ringColor2];
                };
                
                // Crosshairs
                drawLine3D [
                    _dispCenter vectorAdd (_bRight vectorMultiply (-_dispRadius)),
                    _dispCenter vectorAdd (_bRight vectorMultiply _dispRadius),
                    _crossColor
                ];
                drawLine3D [
                    _dispCenter vectorAdd (_bUp vectorMultiply (-_dispRadius)),
                    _dispCenter vectorAdd (_bUp vectorMultiply _dispRadius),
                    _crossColor
                ];
                
                // 2. Rotating Radar Sweep Beam (active only when emission is ON)
                if (!_isEmissionOff) then {
                    private _sweepRad = _sweepAngle * (pi / 180);
                    private _beamEnd = _dispCenter vectorAdd (_bRight vectorMultiply ((sin _sweepRad) * _dispRadius)) vectorAdd (_bUp vectorMultiply ((cos _sweepRad) * _dispRadius));
                    drawLine3D [_dispCenter, _beamEnd, [0.3, 1, 0.45, 0.95]];
                };
                
                // Top Station Header Label
                private _topLabelPos = _dispCenter vectorAdd (_bUp vectorMultiply (_dispRadius + 0.06));
                private _topColor = if (_isEmissionOff) then { [1, 0.6, 0.2, 0.95] } else { [0.2, 1, 0.4, 0.95] };
                private _topText = if (_isEmissionOff) then {
                    format ["[%1] - %2 КМ [РАДИОМОЛЧАНИЕ]", _rName, round (_rRange / 1000)]
                } else {
                    format ["[%1] - %2 КМ", _rName, round (_rRange / 1000)]
                };
                drawIcon3D [
                    "#(argb,8,8,3)color(0,0,0,0)",
                    _topColor,
                    _topLabelPos,
                    0, 0, 0,
                    _topText,
                    0,
                    0.024,
                    "EtelkaMonospaceProBold",
                    "center"
                ];
                
                // 3. Contacts & Aircraft
                {
                    _x params ["_id", "_obj", "_tPos", "_timeSeen", "_speedKmh", "_altM", "_dir", "_name", "_side", "_isMissile", "_isDataLink"];
                    
                    private _plotData = if (!isNull _obj) then { _obj getVariable ["AIRDEF_plotData", []] } else { [] };
                    private _drawWorldPos = if (count _plotData > 0) then { _plotData select 0 } else { _tPos };
                    private _drawnSpeed = if (count _plotData > 0) then { _plotData select 2 } else { _speedKmh };
                    private _drawnAlt = if (count _plotData > 0) then { _plotData select 3 } else { _altM };
                    private _drawnDir = if (count _plotData > 0) then { _plotData select 1 } else { _dir };
                    
                    private _dx = (_drawWorldPos select 0) - (_rPos select 0);
                    private _dy = (_drawWorldPos select 1) - (_rPos select 1);
                    private _dist = sqrt (_dx * _dx + _dy * _dy);
                    
                    if (_dist <= _rRange) then {
                        private _u = (_dx / _rRange) * _dispRadius;
                        private _v = (_dy / _rRange) * _dispRadius;
                        private _tgt3D = _dispCenter vectorAdd (_bRight vectorMultiply _u) vectorAdd (_bUp vectorMultiply _v);
                        
                        private _isFriendly = (_side == _userSide || [_userSide, _side] call BIS_fnc_sideIsFriendly);
                        
                        private _icon = if (_isMissile) then {
                            "\A3\ui_f\data\map\markers\nato\o_art.paa"
                        } else {
                            if (_isFriendly) then {
                                if (!isNull _obj && { _obj isKindOf "Helicopter" }) then { "\A3\ui_f\data\map\markers\nato\b_air.paa" } else { "\A3\ui_f\data\map\markers\nato\b_plane.paa" }
                            } else {
                                "\A3\ui_f\data\map\markers\nato\o_plane.paa"
                            }
                        };
                        
                        private _color = if (_isMissile) then {
                            [1, 0.2, 0.1, 0.95]
                        } else {
                            if (_isFriendly) then { [0.2, 1, 0.45, 0.95] } else { [1, 0.3, 0.2, 0.95] }
                        };
                        
                        private _txt = if (_isMissile) then {
                            format ["!КР! %1", _drawnSpeed]
                        } else {
                            format ["%1 [%2]", _name, _drawnAlt]
                        };
                        
                        drawIcon3D [
                            _icon,
                            _color,
                            _tgt3D,
                            0.6, 0.6, _drawnDir,
                            _txt,
                            0,
                            0.020,
                            "EtelkaMonospacePro",
                            "right"
                        ];
                    };
                } forEach (missionNamespace getVariable ["AIRDEF_trackCache", []]);
            };
        } forEach _boards;
    }];
};
