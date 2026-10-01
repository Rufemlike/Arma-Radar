/*
    Author: Arma Radar Team
    File: fn_openRadar.sqf
    Description:
        Opens the Air Defender green CRT radar terminal, sets up event handlers and scan loop.
        Centers map on the primary radar network and displays active radar station count.
*/

if (!hasInterface) exitWith {};

disableSerialization;

if (!isNull (findDisplay 78500)) then {
    (findDisplay 78500) closeDisplay 1;
};

// Initial target & radar network scan
[] call AIRDEF_fnc_scanTargets;

createDialog "AIRDEF_Radar_Display";
private _display = findDisplay 78500;
if (isNull _display) exitWith { systemChat "[AIRDEF] Ошибка: Не удалось открыть диалог радара."; };

playSoundUI ["\A3\ui_f\data\sound\RscButton\soundClick.wss", 0.5, 1];

private _map = _display displayCtrl 78501;

// Ensure selected radar is initialized and center on it
private _radars = missionNamespace getVariable ["AIRDEF_activeRadars", []];
private _radarObjList = _radars apply { _x select 0 };
if (isNil "AIRDEF_selectedRadar" || { isNull AIRDEF_selectedRadar } || { !(AIRDEF_selectedRadar in _radarObjList) }) then {
    if (count _radars > 0) then {
        AIRDEF_selectedRadar = (_radars select 0) select 0;
    } else {
        AIRDEF_selectedRadar = objNull;
    };
};

private _centerPos = getPosASL player;
private _radarRange = 25000;
{
    if ((_x select 0) == AIRDEF_selectedRadar) exitWith {
        _centerPos = _x select 1;
        _radarRange = _x select 2;
    };
} forEach _radars;

// Calculate initial map zoom scale so the entire radar coverage circle fits on screen
private _wSize = if (isNil "worldSize" || { worldSize <= 0 }) then { 30000 } else { worldSize };
private _optimalScale = ((_radarRange * 2.3) / _wSize) max 0.15 min 0.95;

_map ctrlMapAnimAdd [0, _optimalScale, _centerPos];
ctrlMapAnimCommit _map;

// Attach Draw event handler for multi-radar circles, sweeps, rings and contacts
_map ctrlAddEventHandler ["Draw", {
    _this call AIRDEF_fnc_radarDraw;
}];

// Mouse click on map (target selection & waypoint assignment)
_map ctrlAddEventHandler ["MouseButtonDown", {
    params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
    
    private _worldPos = _control ctrlMapScreenToWorld [_xPos, _yPos];
    
    if (_button == 0) then {
        ["MAP_CLICK_SELECT", [_worldPos, _xPos, _yPos]] call AIRDEF_fnc_uiInteractions;
    };
    if (_button == 1) then {
        ["MAP_CLICK_COMMAND", [_worldPos, _xPos, _yPos]] call AIRDEF_fnc_uiInteractions;
    };
}];

// Background periodic loop for sensor fusion and UI status updates
[_display] spawn {
    params ["_display"];
    disableSerialization;
    
    private _lastScan = 0;
    
    while {!isNull _display} do {
        if (time - _lastScan >= 0.4) then {
            [] call AIRDEF_fnc_scanTargets;
            _lastScan = time;
        };
        
        // Update header time & active radar network info
        private _ctrlTime = _display displayCtrl 78503;
        if (!isNull _ctrlTime) then {
            private _hour = floor daytime;
            private _min  = floor ((daytime - _hour) * 60);
            private _sec  = floor ((((daytime - _hour) * 60) - _min) * 60);
            private _timeStr = format ["%1:%2:%3", 
                if (_hour < 10) then {"0" + str _hour} else {str _hour},
                if (_min < 10) then {"0" + str _min} else {str _min},
                if (_sec < 10) then {"0" + str _sec} else {str _sec}
            ];
            private _numRadars = count AIRDEF_activeRadars;
            _ctrlTime ctrlSetText format ["СЕТЬ РЛС ПВО | TIME: %1 UTC | РЛС В СЕТИ: %2 | ТРЕКОВ: %3", _timeStr, _numRadars, count AIRDEF_trackCache];
        };
        
        // Update bottom status bar
        private _ctrlStatus = _display displayCtrl 78511;
        if (!isNull _ctrlStatus) then {
            private _allTracks   = count AIRDEF_trackCache;
            private _friendlies  = { (_x select 8) == playerSide && !(_x select 9) } count AIRDEF_trackCache;
            private _hostiles    = { (_x select 8) != playerSide && !(_x select 9) && ((_x select 8) != civilian) } count AIRDEF_trackCache;
            private _missiles    = { (_x select 9) } count AIRDEF_trackCache;
            private _dataLink    = { (_x select 10) } count AIRDEF_trackCache;
            
            private _threatColor = if (_missiles > 0) then {"#FF2222"} else { if (_hostiles > 0) then {"#FFAA00"} else {"#00FF44"} };
            private _threatText  = if (_missiles > 0) then {"ВНИМАНИЕ: ЗАСЕЧЕН ПУСК РАКЕТЫ!"} else { if (_hostiles > 0) then {"ВОЗДУШНАЯ ТРЕВОГА"} else {"НОРМА"} };
            
            _ctrlStatus ctrlSetStructuredText parseText format [
                "<t color='%1' font='RobotoCondensed'>СТАТУС: [%2] | РЛС В СЕТИ: %3 | ВСЕГО: %4 | СОЮЗНЫХ: %5 | ВРАЖЕСКИХ: %6 | DATALINK: %7 | РАКЕТ: %8</t>",
                _threatColor, _threatText, count AIRDEF_activeRadars, _allTracks, _friendlies, _hostiles, _dataLink, _missiles
            ];
        };

        // Update emission button state
        private _btnEmission = _display displayCtrl 78544;
        if (!isNull _btnEmission && { !isNull AIRDEF_selectedRadar }) then {
            private _isOff = AIRDEF_selectedRadar getVariable ["AIRDEF_radarEmissionOff", false];
            _btnEmission ctrlSetText (if (_isOff) then { "[!] РАДИОМОЛЧАНИЕ" } else { "[!] ИЗЛУЧЕНИЕ: ВКЛ" });
            _btnEmission ctrlSetTextColor (if (_isOff) then { [1, 0.3, 0.2, 1] } else { [0.2, 1, 0.4, 1] });
        };
        
        uiSleep 0.1;
    };
};
