/*
    Author: Arma Radar Team
    File: fn_uiInteractions.sqf
    Description:
        Handles UI button clicks, filter switches, zoom levels, target selection
        and telemetry information display on the right sidebar.
*/

disableSerialization;

params ["_actionType", "_param"];

private _display = findDisplay 78500;
if (isNull _display) exitWith {};

switch (_actionType) do {
    // ================= MAP CLICK: SELECT TARGET OR FRIENDLY =================
    case "MAP_CLICK_SELECT": {
        private _worldPos = if (_param isEqualType []) then { _param select 0 } else { _param };
        private _clickScreenX = if (_param isEqualType [] && { count _param > 1 }) then { _param select 1 } else { -1 };
        private _clickScreenY = if (_param isEqualType [] && { count _param > 2 }) then { _param select 2 } else { -1 };
        
        private _map = _display displayCtrl 78501;
        private _closestTrack = [];
        private _minDist = 999999;
        
        // 1. Check aircraft & missile contacts
        {
            private _tPos = _x select 2;
            private _dist = 999999;
            
            if (_clickScreenX >= 0 && !isNull _map) then {
                private _sPos = _map ctrlMapWorldToScreen _tPos;
                if (count _sPos > 0) then {
                    private _dx = (_sPos select 0) - _clickScreenX;
                    private _dy = (_sPos select 1) - _clickScreenY;
                    _dist = sqrt (_dx * _dx + _dy * _dy);
                };
            } else {
                _dist = _worldPos distance2D _tPos;
            };
            
            if (_dist < _minDist) then {
                _minDist = _dist;
                _closestTrack = _x;
            };
        } forEach (missionNamespace getVariable ["AIRDEF_trackCache", []]);
        
        // Exact pixel click tolerance: ~0.024 in screen space (~30-35 pixels)
        private _isContactHit = if (_clickScreenX >= 0) then {
            _minDist <= 0.024
        } else {
            private _curScale = if (!isNull _map) then { ctrlMapScale _map } else { 0.1 };
            _minDist <= ((_curScale * 5000) max 300)
        };
        
        if (count _closestTrack > 0 && _isContactHit) then {
            _closestTrack params [
                "_id", "_obj", "_pos", "_timeSeen", "_speedKmh", "_altM", "_dir", "_name", "_side", "_isMissile", "_isDataLink", "_fuel", "_damage"
            ];
            
            playSoundUI ["\A3\ui_f\data\sound\RscButton\soundClick.wss", 0.5, 1];
            
            private _userSide = playerSide;
            if (_userSide in [sideLogic, civilian, sideUnknown]) then {
                if (!isNull player && { (side (group player)) in [west, east, independent] }) then {
                    _userSide = side (group player);
                } else {
                    _userSide = west;
                };
            };
            
            private _isFriendly = (_side == _userSide || [_userSide, _side] call BIS_fnc_sideIsFriendly);
            
            if (_isFriendly && !_isMissile) then {
                AIRDEF_selectedUnit = _obj;
            } else {
                AIRDEF_targetUnit = _obj;
            };
            
            private _ctrlInfo = _display displayCtrl 78510;
            if (!isNull _ctrlInfo) then {
                private _sideColor = if (_isMissile) then {"#FF2222"} else { if (_isFriendly) then {"#00FF44"} else {"#FF5533"} };
                private _sideStr   = if (_isMissile) then {"УГРОЗА (РАКЕТА)"} else { if (_isFriendly) then {"СОЮЗНИК (IFF)"} else {"ПРОТИВНИК / ЦЕЛЬ"} };
                private _pilotName = if (!isNull _obj && { count (crew _obj) > 0 }) then { name (driver _obj) } else { "Н/Д" };
                private _fuelPercent = round (_fuel * 100);
                private _dmgPercent  = round (_damage * 100);
                
                private _distFromMe = round ((_pos distance (getPosASL player)) / 1000);
                
                private _html = format [
                    "<t color='%1' font='PuristaBold' size='1.1'>[%2]</t><br/>" +
                    "<t color='#FFFFFF' font='PuristaBold'>ИМЯ/ТИП: </t><t color='#00FF44'>%3</t><br/>" +
                    "<t color='#FFFFFF' font='PuristaBold'>ПИЛОТ: </t><t color='#00FF44'>%4</t><br/>" +
                    "<t color='#555555'>--------------------------------</t><br/>" +
                    "<t color='#FFFFFF'>ВЫСОТА: </t><t color='#00FF44'>%5 м</t><br/>" +
                    "<t color='#FFFFFF'>СКОРОСТЬ: </t><t color='#00FF44'>%6 км/ч</t><br/>" +
                    "<t color='#FFFFFF'>КУРС: </t><t color='#00FF44'>%7°</t><br/>" +
                    "<t color='#FFFFFF'>ДИСТАНЦИЯ: </t><t color='#00FF44'>%8 км</t><br/>" +
                    "<t color='#555555'>--------------------------------</t><br/>" +
                    "<t color='#FFFFFF'>ТОПЛИВО: </t><t color='#00FF44'>%9%%</t><br/>" +
                    "<t color='#FFFFFF'>УРОН: </t><t color='%10'>%11%%</t><br/>" +
                    "<t color='#FFFFFF'>ИСТОЧНИК: </t><t color='#00FF44'>%12</t>",
                    _sideColor, _sideStr, _name, _pilotName, _altM, _speedKmh, _dir, _distFromMe,
                    _fuelPercent, if (_dmgPercent > 30) then {"#FF2222"} else {"#00FF44"}, _dmgPercent,
                    if (_isDataLink) then {"DATALINK СЕТЬ"} else {"НАЗЕМНАЯ РЛС"}
                ];
                _ctrlInfo ctrlSetStructuredText parseText _html;
            };
        } else {
            // 2. Check if a radar station icon was clicked
            private _closestRadar = [];
            private _minRadarDist = 999999;
            {
                private _rPos = _x select 1;
                private _dist = 999999;
                if (_clickScreenX >= 0 && !isNull _map) then {
                    private _sPos = _map ctrlMapWorldToScreen _rPos;
                    if (count _sPos > 0) then {
                        private _dx = (_sPos select 0) - _clickScreenX;
                        private _dy = (_sPos select 1) - _clickScreenY;
                        _dist = sqrt (_dx * _dx + _dy * _dy);
                    };
                } else {
                    _dist = _worldPos distance2D _rPos;
                };
                if (_dist < _minRadarDist) then {
                    _minRadarDist = _dist;
                    _closestRadar = _x;
                };
            } forEach (missionNamespace getVariable ["AIRDEF_activeRadars", []]);
            
            private _isRadarHit = if (_clickScreenX >= 0) then { _minRadarDist <= 0.024 } else { _minRadarDist <= 500 };
            
            if (count _closestRadar > 0 && _isRadarHit) then {
                _closestRadar params ["_rObj", "_rPos", "_rRange", "_rName"];
                playSoundUI ["\A3\ui_f\data\sound\RscButton\soundClick.wss", 0.5, 1];
                AIRDEF_selectedRadar = _rObj;
                
                private _ctrlInfo = _display displayCtrl 78510;
                if (!isNull _ctrlInfo) then {
                    private _html = format [
                        "<t color='#00FF44' font='PuristaBold' size='1.1'>[АКТИВНЫЙ ПОСТ РЛС]</t><br/>" +
                        "<t color='#FFFFFF' font='PuristaBold'>ПОЗЫВНОЙ: </t><t color='#00FF44'>%1</t><br/>" +
                        "<t color='#555555'>--------------------------------</t><br/>" +
                        "<t color='#FFFFFF'>ТИП: </t><t color='#00FF44'>%2</t><br/>" +
                        "<t color='#FFFFFF'>РАДИУС ЗОНЫ: </t><t color='#00FF44'>%3 КМ</t><br/>" +
                        "<t color='#FFFFFF'>СТАТУС: </t><t color='#00FF44'>АКТИВЕН / ИЗЛУЧЕНИЕ</t><br/>" +
                        "<t color='#555555'>--------------------------------</t><br/>" +
                        "<t color='#888888'>Кольца дальности и луч переключены на этот пост РЛС.</t>",
                        _rName, getText (configFile >> "CfgVehicles" >> typeOf _rObj >> "displayName"), round (_rRange / 1000)
                    ];
                    _ctrlInfo ctrlSetStructuredText parseText _html;
                };
            };
        };
    };

    // ================= RIGHT CLICK: QUICK COMMAND =================
    case "MAP_CLICK_COMMAND": {
        private _worldPos = _param;
        if (!isNull AIRDEF_selectedUnit && { alive AIRDEF_selectedUnit }) then {
            [AIRDEF_selectedUnit, _worldPos, "CAP"] call AIRDEF_fnc_commandAi;
            playSoundUI ["\A3\ui_f\data\sound\RscButton\soundClick.wss", 0.5, 1];
        };
    };

    // ================= FILTERS =================
    case "FILTER": {
        AIRDEF_filter = _param;
        playSoundUI ["\A3\ui_f\data\sound\RscButton\soundClick.wss", 0.5, 1];
        systemChat format ["[AIRDEF] Фильтр отображения: %1", _param];
    };

    // ================= CYCLE / RE-CENTER RADAR =================
    case "CENTER_RADAR": {
        private _radars = missionNamespace getVariable ["AIRDEF_activeRadars", []];
        if (count _radars > 0) then {
            // Find current radar index
            private _curIdx = -1;
            {
                if ((_x select 0) == (missionNamespace getVariable ["AIRDEF_selectedRadar", objNull])) exitWith {
                    _curIdx = _forEachIndex;
                };
            } forEach _radars;
            
            // Cycle to next radar
            private _nextIdx = (_curIdx + 1) % (count _radars);
            private _targetRadar = _radars select _nextIdx;
            AIRDEF_selectedRadar = _targetRadar select 0;
            
            private _centerPos = _targetRadar select 1;
            private _radarRange = _targetRadar select 2;
            private _rName = _targetRadar select 3;
            
            private _map = _display displayCtrl 78501;
            if (!isNull _map) then {
                private _wSize = if (isNil "worldSize" || { worldSize <= 0 }) then { 30000 } else { worldSize };
                private _optimalScale = ((_radarRange * 2.3) / _wSize) max 0.15 min 0.95;
                _map ctrlMapAnimAdd [0.4, _optimalScale, _centerPos];
                ctrlMapAnimCommit _map;
            };
            
            systemChat format ["[AIRDEF] Активный радар: %1 (%2 км)", _rName, round (_radarRange / 1000)];
            playSoundUI ["\A3\ui_f\data\sound\RscButton\soundClick.wss", 0.5, 1];
        };
    };

    // ================= TOGGLES =================
    case "TOGGLE": {
        switch (_param) do {
            case "RINGS": {
                AIRDEF_showRings = !AIRDEF_showRings;
                private _btn = _display displayCtrl 78540;
                _btn ctrlSetText (if (AIRDEF_showRings) then {"КОЛЬЦА: ВКЛ"} else {"КОЛЬЦА: ВЫКЛ"});
            };
            case "SWEEP": {
                AIRDEF_showSweep = !AIRDEF_showSweep;
                private _btn = _display displayCtrl 78541;
                _btn ctrlSetText (if (AIRDEF_showSweep) then {"ЛУЧ РЛС: ВКЛ"} else {"ЛУЧ РЛС: ВЫКЛ"});
            };
            case "VECTORS": {
                AIRDEF_showVectors = !AIRDEF_showVectors;
                private _btn = _display displayCtrl 78542;
                _btn ctrlSetText (if (AIRDEF_showVectors) then {"ВЕКТОРЫ: ВКЛ"} else {"ВЕКТОРЫ: ВЫКЛ"});
            };
        };
        playSoundUI ["\A3\ui_f\data\sound\RscButton\soundClick.wss", 0.5, 1];
    };

    // ================= C2 ACTIONS =================
    case "ACTION": {
        switch (_param) do {
            case "VECTOR": {
                [AIRDEF_selectedUnit, AIRDEF_targetUnit] call AIRDEF_fnc_vectorIntercept;
            };
            case "INTERCEPT_AI": {
                if (isNull AIRDEF_selectedUnit || isNull AIRDEF_targetUnit) exitWith {
                    systemChat "[AIRDEF] Выберите союзный борт и цель для перехвата.";
                };
                [AIRDEF_selectedUnit, AIRDEF_targetUnit, "INTERCEPT"] call AIRDEF_fnc_commandAi;
            };
            case "CAP_AI": {
                if (isNull AIRDEF_selectedUnit) exitWith {
                    systemChat "[AIRDEF] Выберите союзный борт для назначения патруля.";
                };
                private _pos = if (!isNull AIRDEF_targetUnit) then { getPosATL AIRDEF_targetUnit } else { screenToWorld [0.5, 0.5] };
                [AIRDEF_selectedUnit, _pos, "CAP"] call AIRDEF_fnc_commandAi;
            };
            case "RTB": {
                if (isNull AIRDEF_selectedUnit) exitWith {
                    systemChat "[AIRDEF] Выберите союзный борт для приказа возврата на базу.";
                };
                [AIRDEF_selectedUnit, objNull, "RTB"] call AIRDEF_fnc_commandAi;
            };
            case "CLEAR": {
                AIRDEF_selectedUnit = objNull;
                AIRDEF_targetUnit   = objNull;
                private _ctrlInfo = _display displayCtrl 78510;
                if (!isNull _ctrlInfo) then {
                    _ctrlInfo ctrlSetStructuredText parseText "<t color='#00FF44' font='PuristaMedium'>ВЫБОР СБРОШЕН.<br/><br/>Кликните левой кнопкой мыши по отметке на радаре для захвата данных.</t>";
                };
                playSoundUI ["\A3\ui_f\data\sound\RscButton\soundClick.wss", 0.5, 1];
            };
        };
    };
};
