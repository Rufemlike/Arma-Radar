/*
    Author: Arma Radar Team
    File: fn_commandPilot.sqf
    Description:
        Delivers tactical GCI commands to human pilots and flight crews:
        - Radio transmission chime in helmet headset
        - High-contrast cockpit HUD / Hint telemetry card
        - In-cockpit GPS and 2D map navigation marker with course, distance and altitude
        - Auto-tracking loop on moving target for 60 seconds
        - 100% crash-proof multiplayer execution (uses primitive types and local crew filter)
*/

params [
    ["_aircraft", objNull],
    ["_orderType", "INTERCEPT"],
    ["_navPos", [0, 0, 0]],
    ["_targetName", "ЦЕЛЬ"],
    ["_bearing", 0],
    ["_distKm", 0],
    ["_altM", 0],
    ["_speedKmh", 0],
    ["_etaStr", "--:--"],
    ["_targetNetId", ""]
];

if (isNull _aircraft || !hasInterface) exitWith {};

// CRITICAL GUARD: Only execute on the machine where local player is in the crew of this aircraft!
// This completely eliminates any recursion, object-target remoteExec bugs, or CTD.
if !(player in (crew _aircraft)) exitWith {};

// Play chime on pilot's headset
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
        // Radio text
        systemChat format [
            "[GCI/ПВО] ВНИМАНИЕ! БОЕВОЙ ПРИКАЗ: ПЕРЕХВАТ! Цель: %1 | Курс %2° | Дистанция %3 км | Эшелон %4 м | ETA %5",
            _targetName, _bearing, _distKm, _altM, _etaStr
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
            _targetName, _bearing, _distKm, _altM, _speedKmh, _etaStr
        ];

        // Create local GPS / map target marker
        private _markerPos = if (_navPos isEqualTo [0,0,0]) then { getPosATL _aircraft } else { _navPos };
        private _m = createMarkerLocal ["AIRDEF_PILOT_GCI_NAV", _markerPos];
        _m setMarkerTypeLocal "mil_destroy";
        _m setMarkerColorLocal "ColorRed";
        _m setMarkerTextLocal format ["[GCI ПЕРЕХВАТ] %1 | КУРС %2° | ДИСТ %3 КМ", _targetName, _bearing, _distKm];
        _m setMarkerSizeLocal [1.1, 1.1];

        // Tracking loop for pilot's GPS (updates marker position for up to 60 seconds)
        [_targetNetId, _navPos, _aircraft] spawn {
            params ["_netId", "_fallbackPos", "_plane"];
            private _tgt = if (_netId != "") then { objectFromNetId _netId } else { objNull };
            private _endTime = time + 60;
            while { time < _endTime && { alive _plane } } do {
                if !(getMarkerColor "AIRDEF_PILOT_GCI_NAV" isEqualTo "") then {
                    private _curPos = if (!isNull _tgt && { alive _tgt }) then { getPosATL _tgt } else { _fallbackPos };
                    private _b = round (_plane getDir _curPos);
                    private _d = round ((_plane distance _curPos) / 1000);
                    private _h = round ((getPosASL _curPos) select 2);
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
        systemChat format ["[GCI/ПВО] ПРИКАЗ: ПАТРУЛИРОВАНИЕ (CAP). Ложитесь на курс %1°, дистанция %2 км.", _bearing, _distKm];

        hintSilent parseText format [
            "<t color='#00FF44' font='PuristaBold' size='1.2'>[КОМАНДА GCI: ПАТРУЛЬ (CAP)]</t><br/>" +
            "<t color='#555555'>--------------------------------</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>СЕКТОР: </t><t color='#00FF44' font='PuristaBold'>%1</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>КУРС НА СЕКТОР: </t><t color='#00FF44' font='PuristaBold' size='1.3'> %2°</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>ДИСТАНЦИЯ: </t><t color='#00FF44' font='PuristaBold'>%3 км</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>РЕКОМЕНД. ЭШЕЛОН: </t><t color='#00FF44' font='PuristaBold'>2500 - 4000 м</t><br/>" +
            "<t color='#555555'>--------------------------------</t><br/>" +
            "<t color='#00FF44' font='PuristaBold'>ПРИКАЗ: ПАТРУЛИРОВАТЬ ВОЗДУШНЫЙ СЕКТОР</t>",
            _targetName, _bearing, _distKm
        ];

        private _m = createMarkerLocal ["AIRDEF_PILOT_GCI_NAV", _navPos];
        _m setMarkerTypeLocal "mil_circle";
        _m setMarkerColorLocal "ColorYellow";
        _m setMarkerTextLocal format ["[GCI ПАТРУЛЬ] СЕКТОР %1 | %2° / %3 КМ", _targetName, _bearing, _distKm];
        _m setMarkerSizeLocal [1.2, 1.2];

        [_navPos, _aircraft] spawn {
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
        systemChat format ["[GCI/ПВО] ПРИКАЗ: ВОЗВРАТ НА БАЗУ (RTB). База: '%1'. Курс %2°, дистанция %3 км.", _targetName, _bearing, _distKm];

        hintSilent parseText format [
            "<t color='#00FFFF' font='PuristaBold' size='1.2'>[КОМАНДА GCI: НА БАЗУ (RTB)]</t><br/>" +
            "<t color='#555555'>--------------------------------</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>БАЗА ПОСАДКИ: </t><t color='#00FFFF' font='PuristaBold'>%1</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>КУРС НА ВПП: </t><t color='#00FF44' font='PuristaBold' size='1.3'> %2°</t><br/>" +
            "<t color='#FFFFFF' font='PuristaMedium'>ДИСТАНЦИЯ: </t><t color='#00FF44' font='PuristaBold'>%3 км</t><br/>" +
            "<t color='#555555'>--------------------------------</t><br/>" +
            "<t color='#00FF44' font='PuristaBold'>ПРИКАЗ: ЗАХОД НА ПОСАДКУ</t>",
            _targetName, _bearing, _distKm
        ];

        private _m = createMarkerLocal ["AIRDEF_PILOT_GCI_NAV", _navPos];
        _m setMarkerTypeLocal "mil_end";
        _m setMarkerColorLocal "ColorCyan";
        _m setMarkerTextLocal format ["[GCI RTB] %1 | КУРС %2° | ДИСТ %3 КМ", _targetName, _bearing, _distKm];
        _m setMarkerSizeLocal [1.2, 1.2];

        [_navPos, _aircraft] spawn {
            params ["_pos", "_plane"];
            private _endTime = time + 180;
            while { time < _endTime && { alive _plane } && { (_plane distance2D _pos) > 1000 } } do {
                sleep 3;
            };
            deleteMarkerLocal "AIRDEF_PILOT_GCI_NAV";
        };
    };
};
