/*
    Author: Arma Radar Team
    File: fn_setupTerminal.sqf
    Description:
        Attaches interactive "Enter Radar Terminal" action to physical world objects
        (laptops, desks, radar consoles, vehicles, map boards, or buildings).
*/

params [["_obj", objNull]];

if (isNull _obj) exitWith {};
if (_obj isKindOf "CAManBase") exitWith {}; // Humans can never be terminals
if (!hasInterface) exitWith {}; // Only clients with UI need addAction
if (_obj getVariable ["AIRDEF_terminalActionAdded", false]) exitWith {};

_obj setVariable ["AIRDEF_terminalActionAdded", true];

_obj addAction [
    "<t color='#00FF44' font='PuristaBold'>[РАДАР ПВО / УВД] Войти в терминал</t>",
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        [] spawn AIRDEF_fnc_openRadar;
    },
    nil,
    6,
    true,
    true,
    "",
    "alive _target && { alive _this } && { _this distance _target <= 3.5 } && {
        private _tSide = _target getVariable ['AIRDEF_terminalSide', 'ANY'];
        if (_tSide in ['ANY', '']) exitWith { true };
        private _pSide = side (group _this);
        switch (toUpper _tSide) do {
            case 'WEST':        { _pSide == west };
            case 'EAST':        { _pSide == east };
            case 'INDEPENDENT': { _pSide == independent };
            case 'IND':         { _pSide == independent };
            default             { true };
        };
    }",
    3.5
];
