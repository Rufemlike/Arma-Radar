/*
    Author: Arma Radar Team
    File: fn_commandPilot.sqf
    Description:
        Delivers tactical GCI commands to human pilots and flight crews:
        - Radio transmission chime in helmet headset
        - High-contrast cockpit HUD / Hint telemetry card
        - In-cockpit GPS and 2D map navigation marker with course, distance and altitude
        - Auto-tracking loop on moving target for 60 seconds
*/

params [
    ["_aircraft", objNull],
    ["_orderType", "INTERCEPT"],
    ["_targetOrPos", objNull]
];

if (isNull _aircraft) exitWith {};

// Ensure execution on the machine of the pilot/crew
private _crewPlayers = (crew _aircraft) select { isPlayer _x };
if (count _crewPlayers == 0) exitWith {};

// If not local to any player in this aircraft, forward to the pilot
if !(player in _crewPlayers) exitWith {
    if (isMultiplayer) then {
        private _pilot = driver _aircraft;
        private _targetUnit = if (!isNull _pilot && { isPlayer _pilot }) then { _pilot } else { _crewPlayers select 0 };
        [_aircraft, _orderType, _targetOrPos] remoteExec ["AIRDEF_fnc_commandPilot", _targetUnit];
    };
};

// ================= CLIENT-SIDE EXECUTION ON HUMAN PILOT'S MACHINE =================
playSoundUI ["\A3\ui_f\data\sound\CfgNotifications\default.wss", 1.2, 1];

// Clean up previous navigation marker if any
if !(getMarkerColor "AIRDEF_PILOT_GCI_NAV" isEqualTo "") then {
    deleteMarkerLocal "AIRDEF_PILOT_GCI_NAV";
};

switch (toUpper _orderType) do {
    // -------------------------------------------------------------
    // 1. INTERCEPT / VECTOR COMMAND
    // -------------------------------------------------------------
    case "INTERCEPT": {
        if (isNull _targetOrPos || !alive _targetOrPos) exitWith {
            systemChat "[GCI/ПВО] Отбой перехвата: цель потеряна.";
        };

        private _fPos = getPosASL _aircraft;
        private _tPos = getPosASL _targetOrPos;
        private _dist = round (_fPos distance _tPos);
        private _bearing = round (_fPos getDir _tPos);
        private _tAlt = round (_tPos select 2);
        private _fSpeed = round (speed _aircraft);
        private _tSpeed = round (speed _targetOrPos);

        // Closure rate & ETA
        private _closureSpeedMs = ((_fSpeed max 100) + (_tSpeed max 0)) / 3.6;
        private _etaSec = round (_dist / (_closureSpeedMs max 10));
        private _etaMin = floor (_etaSec / 60);
        private _etaSecRem = _etaSec % 60;
        private _etaStr = format ["%1:%2", _etaMin, if (_etaSecRem < 10) then {"0" + str _etaSecRem} else {str _etaSecRem}];

        private _tgtName = _targetOrPos getVariable ["AIRDEF_callsign", ""];
        if (_tgtName == "") then { _tgtName = getText (configFile >> "CfgVehicles" >> typeOf _targetOrPos >> "displayName"); };
        if (_tgtName == "") then { _tgtName = "ВОЗДУШНАЯ ЦЕЛЬ"; };

        // Radio text
        systemChat format [
            "[GCI/ПВО] ВНИМАНИЕ! БОЕВОЙ ПРИКАЗ: ПЕРЕХВАТ! Цель: %1 | Курс %2° | Дистанция %3 км | Эшелон %4 м | ETA %5",
            _tgtName, _bearing, round (_dist / 1000), _tAlt, _etaStr
        ];

        // Cockpit HUD Alert
        hintSilent parseText format [
            "<t color='#00FF44' font='PuristaBold' size='1.2'>[КОМАНДА GCI: ПЕРЕХВАТ]</t><br/>" +
            "<t color='#555555'>--------------------------------</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>ЦЕЛЬ: </t><t color='#FF4433' font='PuristaBold'>%1</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>КУРС: </t><t color='#00FF44' font='PuristaBold' size='1.3'> %2°</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>ДИСТАНЦИЯ: </t><t color='#00FF44' font='PuristaBold'>%3 км</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>ЭШЕЛОН ЦЕЛИ: </t><t color='#00FF44' font='PuristaBold'>%4 м</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>СКОРОСТЬ ЦЕЛИ: </t><t color='#00FF44' font='PuristaBold'>%5 км/ч</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>ПОДЛЕТ (ETA): </t><t color='#00FF44' font='PuristaBold'>%6</t><br/>" +
            "<t color='#555555'>--------------------------------</t><br/>" +
            "<t color='#FFCC00' font='PuristaBold'>ПРИКАЗ: ПЕРЕХВАТ И АТАКА!</t>",
            _tgtName, _bearing, round (_dist / 1000), _tAlt, _tSpeed, _etaStr
        ];

        // Create local GPS / map target marker
        private _m = createMarkerLocal ["AIRDEF_PILOT_GCI_NAV", getPosATL _targetOrPos];
        _m setMarkerTypeLocal "mil_destroy";
        _m setMarkerColorLocal "ColorRed";
        _m setMarkerTextLocal format ["[GCI ПЕРЕХВАТ] %1 | КУРС %2° | ДИСТ %3 КМ", _tgtName, _bearing, round (_dist / 1000)];
        _m setMarkerSizeLocal [1.1, 1.1];

        // Tracking loop for pilot's GPS (updates marker position for up to 60 seconds)
        [_targetOrPos, _aircraft] spawn {
            params ["_tgt", "_plane"];
            private _endTime = time + 60;
            while { time < _endTime && { !isNull _tgt } && { alive _tgt } && { alive _plane } } do {
                if !(getMarkerColor "AIRDEF_PILOT_GCI_NAV" isEqualTo "") then {
                    private _curPos = getPosATL _tgt;
                    private _b = round (_plane getDir _tgt);
                    private _d = round ((_plane distance _tgt) / 1000);
                    private _h = round ((getPosASL _tgt) select 2);
                    "AIRDEF_PILOT_GCI_NAV" setMarkerPosLocal _curPos;
                    "AIRDEF_PILOT_GCI_NAV" setMarkerTextLocal format ["[GCI ПЕРЕХВАТ] %1° | %2 КМ | H:%3М", _b, _d, _h];
                };
                sleep 2;
            };
            deleteMarkerLocal "AIRDEF_PILOT_GCI_NAV";
        };
    };

    // -------------------------------------------------------------
    // 2. CAP (COMBAT AIR PATROL)
    // -------------------------------------------------------------
    case "CAP": {
        private _patrolPos = if (_targetOrPos isEqualType objNull) then { getPosATL _targetOrPos } else { _targetOrPos };
        if (isNil "_patrolPos" || { count _patrolPos < 2 }) exitWith {};

        private _fPos = getPosASL _aircraft;
        private _dist = round (_fPos distance _patrolPos);
        private _bearing = round (_fPos getDir _patrolPos);

        systemChat format ["[GCI/ПВО] ПРИКАЗ: ПАТРУЛИРОВАНИЕ (CAP). Ложитесь на курс %1°, дистанция %2 км.", _bearing, round (_dist / 1000)];

        hintSilent parseText format [
            "<t color='#00FF44' font='PuristaBold' size='1.2'>[КОМАНДА GCI: ПАТРУЛЬ (CAP)]</t><br/>" +
            "<t color='#555555'>--------------------------------</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>КУРС НА СЕКТОР: </t><t color='#00FF44' font='PuristaBold' size='1.3'> %1°</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>ДИСТАНЦИЯ: </t><t color='#00FF44' font='PuristaBold'>%2 км</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>РЕКОМЕНД. ЭШЕЛОН: </t><t color='#00FF44' font='PuristaBold'>2500 - 4000 м</t><br/>" +
            "<t color='#555555'>--------------------------------</t><br/>" +
            "<t color='#00FF44' font='PuristaBold'>ПРИКАЗ: ПАТРУЛИРОВАТЬ ВОЗДУШНЫЙ СЕКТОР</t>",
            _bearing, round (_dist / 1000)
        ];

        private _m = createMarkerLocal ["AIRDEF_PILOT_GCI_NAV", _patrolPos];
        _m setMarkerTypeLocal "mil_circle";
        _m setMarkerColorLocal "ColorYellow";
        _m setMarkerTextLocal format ["[GCI ПАТРУЛЬ] СЕКТОР CAP | %1° / %2 КМ", _bearing, round (_dist / 1000)];
        _m setMarkerSizeLocal [1.2, 1.2];

        // Remove marker after 120 seconds or arrival
        [_patrolPos, _aircraft] spawn {
            params ["_pos", "_plane"];
            private _endTime = time + 120;
            while { time < _endTime && { alive _plane } && { (_plane distance2D _pos) > 2000 } } do {
                sleep 3;
            };
            sleep 30;
            deleteMarkerLocal "AIRDEF_PILOT_GCI_NAV";
        };
    };

    // -------------------------------------------------------------
    // 3. RTB (RETURN TO BASE)
    // -------------------------------------------------------------
    case "RTB": {
        // Find nearest friendly airfield or starting position
        private _airports = allAirports;
        private _rtbPos = getPosATL _aircraft;
        if (count _airports > 0) then {
            private _nearest = [_airports, _aircraft] call BIS_fnc_nearestPosition;
            _rtbPos = getAirportPosition _nearest;
        };

        private _dist = round ((getPosASL _aircraft) distance _rtbPos);
        private _bearing = round ((getPosASL _aircraft) getDir _rtbPos);

        systemChat format ["[GCI/ПВО] ПРИКАЗ: ВОЗВРАТ НА БАЗУ (RTB). Курс %1°, дистанция %2 км.", _bearing, round (_dist / 1000)];

        hintSilent parseText format [
            "<t color='#00FF44' font='PuristaBold' size='1.2'>[КОМАНДА GCI: НА БАЗУ (RTB)]</t><br/>" +
            "<t color='#555555'>--------------------------------</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>КУРС НА АЭРОДРОМ: </t><t color='#00FF44' font='PuristaBold' size='1.3'> %1°</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>ДИСТАНЦИЯ: </t><t color='#00FF44' font='PuristaBold'>%2 км</t><br/>" +
            "<t color='#555555'>--------------------------------</t><br/>" +
            "<t color='#00FF44' font='PuristaBold'>ПРИКАЗ: ВОЗВРАЩЕНИЕ НА АЭРОДРОМ</t>",
            _bearing, round (_dist / 1000)
        ];

        private _m = createMarkerLocal ["AIRDEF_PILOT_GCI_NAV", _rtbPos];
        _m setMarkerTypeLocal "mil_end";
        _m setMarkerColorLocal "ColorGreen";
        _m setMarkerTextLocal format ["[GCI АЭРОДРОМ] БАЗА (RTB) | %1° / %2 КМ", _bearing, round (_dist / 1000)];
        _m setMarkerSizeLocal [1.2, 1.2];

        [_rtbPos, _aircraft] spawn {
            params ["_pos", "_plane"];
            private _endTime = time + 180;
            while { time < _endTime && { alive _plane } && { (_plane distance2D _pos) > 1000 } } do {
                sleep 3;
            };
            deleteMarkerLocal "AIRDEF_PILOT_GCI_NAV";
        };
    };
};
