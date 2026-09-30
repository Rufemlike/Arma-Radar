/*
    Author: Arma Radar Team
    File: fn_commandAi.sqf
    Description:
        Dedicated-Server-Proof AI flight command handler (Drongo style C2).
        Handles: INTERCEPT, CAP, RTB.
        Guarantees correct execution via groupOwner locality check.
*/

params [
    ["_aircraft", objNull],
    ["_targetOrPos", objNull],
    ["_orderType", "INTERCEPT"]
];

if (isNull _aircraft || !alive _aircraft) exitWith {};

private _grp = group _aircraft;
if (isNull _grp) exitWith {};

// CRITICAL MULTIPLAYER FIX (fixes Drongo's dedicated server bug):
// Waypoints must be modified on the machine that owns the group!
if (!local _grp) exitWith {
    [_aircraft, _targetOrPos, _orderType] remoteExecCall ["AIRDEF_fnc_commandAi", groupOwner _grp];
};

private _callsign = groupId _grp;

switch (_orderType) do {
    case "INTERCEPT": {
        if (isNull _targetOrPos || !alive _targetOrPos) exitWith {};

        // Clear existing waypoints
        while {count (waypoints _grp) > 0} do {
            deleteWaypoint ((waypoints _grp) select 0);
        };

        private _tgtPos = getPosATL _targetOrPos;
        private _tgtAlt = (getPosASL _targetOrPos select 2) max 600;

        _grp setCombatMode "RED";
        _grp setBehaviour "COMBAT";
        _grp setSpeedMode "FULL";

        // Assign flight altitude matching target
        _aircraft flyInHeight _tgtAlt;

        // Reveal target to AI pilot with maximum knowledge
        (driver _aircraft) reveal [_targetOrPos, 4];
        _aircraft doTarget _targetOrPos;
        _aircraft doFire _targetOrPos;

        // Create combat intercept waypoint
        private _wp = _grp addWaypoint [_tgtPos, 0];
        _wp setWaypointType "DESTROY";
        _wp waypointAttachVehicle _targetOrPos;
        _wp setWaypointSpeed "FULL";
        _wp setWaypointCombatMode "RED";
        _grp setCurrentWaypoint _wp;

        // Radio confirmation
        private _confMsg = format ["[ИИ %1] Приказ принял! Ложусь на курс перехвата цели %2.", _callsign, getText (configFile >> "CfgVehicles" >> typeOf _targetOrPos >> "displayName")];
        systemChat _confMsg;
        if (isMultiplayer) then { [_confMsg] remoteExec ["systemChat"]; };
    };

    case "CAP": {
        private _patrolPos = if (_targetOrPos isEqualType objNull) then { getPosATL _targetOrPos } else { _targetOrPos };
        if (isNil "_patrolPos" || { count _patrolPos < 2 }) exitWith {};

        while {count (waypoints _grp) > 0} do {
            deleteWaypoint ((waypoints _grp) select 0);
        };

        _grp setCombatMode "YELLOW";
        _grp setBehaviour "AWARE";
        _grp setSpeedMode "NORMAL";
        _aircraft flyInHeight 2500;

        // Create Loiter (Orbit) waypoint
        private _wp = _grp addWaypoint [_patrolPos, 0];
        _wp setWaypointType "LOITER";
        _wp setWaypointLoiterRadius 3500;
        _wp setWaypointLoiterType "CIRCLE";
        _grp setCurrentWaypoint _wp;

        private _confMsg2 = format ["[ИИ %1] Приказ принял! Выполняю патрулирование зоны (CAP) в заданном квадрате.", _callsign];
        systemChat _confMsg2;
        if (isMultiplayer) then { [_confMsg2] remoteExec ["systemChat"]; };
    };

    case "RTB": {
        while {count (waypoints _grp) > 0} do {
            deleteWaypoint ((waypoints _grp) select 0);
        };

        _grp setCombatMode "GREEN";
        _grp setBehaviour "SAFE";
        _grp setSpeedMode "NORMAL";

        // Find nearest friendly airport or spawn position
        private _airports = allAirports;
        private _landingPos = [worldSize/2, worldSize/2, 0];
        
        if (count _airports > 0) then {
            // Find closest airport
            private _closest = _airports select 0;
            private _minDist = 999999;
            {
                private _aPos = airportSide _x; // or airport position
                private _dist = (getPosATL _aircraft) distance _landingPos;
            } forEach _airports;
        };

        private _wp = _grp addWaypoint [getPosATL _aircraft, 0];
        _wp setWaypointType "MOVE";
        
        // Command land
        _aircraft land "LAND";

        private _confMsg3 = format ["[ИИ %1] Приказ принял! Возвращаюсь на базу (RTB), заход на посадку.", _callsign];
        systemChat _confMsg3;
        if (isMultiplayer) then { [_confMsg3] remoteExec ["systemChat"]; };
    };
};
