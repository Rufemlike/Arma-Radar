/*
    Author: Arma Radar Team
    File: fn_vectorIntercept.sqf
    Description:
        Computes GCI intercept vector solution and transmits tactical vectoring
        to human pilots or displays tactical data.
        Safe against singleplayer/multiplayer network DLL crashes.
*/

params [
    ["_friendly", objNull],
    ["_target", objNull]
];

if (isNull _friendly || !alive _friendly) exitWith {
    systemChat "[AIRDEF] Ошибка: Сначала выберите союзный борт (левым кликом).";
    playSoundUI ["\A3\ui_f\data\sound\RscButton\soundEscape.wss", 0.5, 1];
};

if (isNull _target || !alive _target) exitWith {
    systemChat "[AIRDEF] Ошибка: Выберите воздушную цель для наведения на перехват.";
    playSoundUI ["\A3\ui_f\data\sound\RscButton\soundEscape.wss", 0.5, 1];
};

if (_friendly isEqualTo _target) exitWith {
    systemChat "[AIRDEF] Ошибка: Выбранный борт и цель совпадают. Выберите вражескую метку.";
    playSoundUI ["\A3\ui_f\data\sound\RscButton\soundEscape.wss", 0.5, 1];
};

private _fPos = getPosASL _friendly;
private _tPos = getPosASL _target;

private _dist = round (_fPos distance _tPos);
private _bearing = round (_fPos getDir _tPos);
private _fAlt = round (_fPos select 2);
private _tAlt = round (_tPos select 2);
private _fSpeed = round (speed _friendly);
private _tSpeed = round (speed _target);

// Estimated time to intercept (ETA in seconds)
private _closureSpeedMs = ((_fSpeed max 100) + (_tSpeed max 0)) / 3.6;
private _etaSec = round (_dist / (_closureSpeedMs max 10));
private _etaMin = floor (_etaSec / 60);
private _etaSecRem = _etaSec % 60;
private _etaStr = format ["%1:%2", _etaMin, if (_etaSecRem < 10) then {"0" + str _etaSecRem} else {str _etaSecRem}];

private _pilot = driver _friendly;
private _callsign = _friendly getVariable ["AIRDEF_callsign", ""];
if (_callsign == "") then {
    private _grp = group _friendly;
    if (!isNull _grp) then { _callsign = groupId _grp; };
};
if (_callsign == "") then { _callsign = getText (configFile >> "CfgVehicles" >> typeOf _friendly >> "displayName"); };

private _tgtName = _target getVariable ["AIRDEF_callsign", ""];
if (_tgtName == "") then { _tgtName = getText (configFile >> "CfgVehicles" >> typeOf _target >> "displayName"); };
if (_tgtName == "") then { _tgtName = "ВОЗДУШНАЯ ЦЕЛЬ"; };

// Radio message string
private _msg = format [
    "[GCI/ПВО] %1, ЦЕЛЬ: %2 | КУРС %3° | ДАЛЬНОСТЬ %4 КМ | ВЫСОТА %5 М | ETA %6 | ПЕРЕХВАТ РАЗРЕШАЮ!",
    _callsign, _tgtName, _bearing, round (_dist / 1000), _tAlt, _etaStr
];

// Display in operator console
systemChat _msg;
playSoundUI ["\A3\ui_f\data\sound\RscButton\soundClick.wss", 0.5, 1];

// Transmit to pilot safely (handling singleplayer vs multiplayer without steamworks DLL proxy crash)
if (!isNull _pilot && { isPlayer _pilot }) then {
    if (_pilot isEqualTo player) then {
        hint parseText format [
            "<t color='#00FF44' font='EtelkaMonospaceProBold' size='1.2'>[ПРИКАЗ ДИСПЕТЧЕРА GCI]</t><br/>" +
            "<t color='#FFFFFF' font='EtelkaMonospacePro'>КУРС НАВЕДЕНИЯ: <t color='#00FF44'>%1°</t><br/>" +
            "ДИСТАНЦИЯ: <t color='#00FF44'>%2 км</t><br/>" +
            "ЭШЕЛОН ЦЕЛИ: <t color='#00FF44'>%3 м</t><br/>" +
            "РАСЧЕТНОЕ ВРЕМЯ: <t color='#00FF44'>%4</t></t>",
            _bearing, round (_dist / 1000), _tAlt, _etaStr
        ];
    } else {
        if (isMultiplayer) then {
            [_msg] remoteExec ["systemChat", _pilot];
        };
    };
};
