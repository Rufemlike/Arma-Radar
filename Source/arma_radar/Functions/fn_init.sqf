/*
    Author: Arma Radar Team
    File: fn_init.sqf
    Description:
        Global initialization for Air Defender Radar System.
        Supports multi-radar network, CBA keybinds, and Zeus Enhanced (ZEN) context actions.
*/

if (isDedicated) exitWith {};

// List of all active friendly radars (providing detection and green rings)
AIRDEF_activeRadars  = [];
// List of discovered hostile/threat radars (providing red warning threat rings)
AIRDEF_hostileRadars = [];

// Default radar classes to automatically discover
AIRDEF_radarClasses = [
    "Land_Radar_F",
    "Land_Radar_small_F",
    "Land_Airfield_Tower_F",
    "Radar_System_01_base_F",
    "Radar_System_02_base_F",
    "B_Radar_System_01_F",
    "O_Radar_System_02_F",
    "B_AAA_System_01_F",
    "B_SAM_System_01_F",
    "B_SAM_System_02_F",
    "O_SAM_System_04_F"
];

// Settings
if (isNil "AIRDEF_filter") then { AIRDEF_filter = "ALL"; };
if (isNil "AIRDEF_showRings") then { AIRDEF_showRings = true; };
if (isNil "AIRDEF_showSweep") then { AIRDEF_showSweep = true; };
if (isNil "AIRDEF_showVectors") then { AIRDEF_showVectors = true; };
if (isNil "AIRDEF_sweepSpeed") then { AIRDEF_sweepSpeed = 60; };

// State storage
AIRDEF_selectedUnit = objNull;
AIRDEF_targetUnit   = objNull;
AIRDEF_trackCache   = [];

// Register CBA keybind if CBA is loaded
if (isClass (configFile >> "CfgPatches" >> "cba_main")) then {
    ["Air Defender Radar", "AIRDEF_openKey", ["Открыть радар ПВО/УВД", "Открыть полноэкранный терминал диспетчера ПВО"], {
        if (dialog) then {
            if (!isNull (uiNamespace getVariable ["AIRDEF_display", displayNull])) then {
                (findDisplay 78500) closeDisplay 1;
            };
        } else {
            [] spawn AIRDEF_fnc_openRadar;
        };
        true
    }, {}, [19, [true, false, false]]] call CBA_fnc_addKeybind;
};

// ================= BACKGROUND RADAR DISCOVERY & MAP MARKERS LOOP =================
// Continuously scans for placed radars (in Zeus, 3DEN or scripts) every 2 seconds,
// auto-activates unmanned radars, and maintains 2D map & Zeus coverage markers.
[] spawn {
    while {true} do {
        try {
            [] call AIRDEF_fnc_scanTargets;
        } catch {};
        sleep 2;
    };
};

// ================= ZEUS ENHANCED (ZEN) INTEGRATION =================
// If Zeus Enhanced is loaded, add right-click context menu options to rename planes and configure radars on the fly!
if (isClass (configFile >> "CfgPatches" >> "zen_context_menu")) then {
    [] spawn {
        waitUntil { !isNil "zen_context_menu_fnc_createAction" && !isNil "zen_context_menu_fnc_addAction" && !isNil "zen_dialog_fnc_create" };
        
        // 1. Rename Aircraft callsign on the fly in Zeus
        private _actCallsign = [
            "AIRDEF_setCallsign",
            "Air Defender: Задать позывной борта",
            "\A3\ui_f\data\map\markers\nato\b_air.paa",
            {
                params ["_position", ["_objects", []]];
                if (count _objects == 0) exitWith {};
                private _target = _objects select 0;
                private _curName = _target getVariable ["AIRDEF_callsign", ""];
                [
                    "Позывной борта для радара ПВО",
                    [
                        ["EDIT", ["Позывной борта:", "Отобразится на диспетчерском радаре (например: Борт-101, Сокол-1)"], _curName]
                    ],
                    {
                        params ["_dialogValues", "_args"];
                        private _newCallsign = _dialogValues select 0;
                        private _veh = _args select 0;
                        _veh setVariable ["AIRDEF_callsign", _newCallsign, true];
                        systemChat format ["[AIRDEF] Задан позывной борта: %1", _newCallsign];
                    },
                    {},
                    [_target]
                ] call zen_dialog_fnc_create;
            },
            {
                params ["_position", ["_objects", []]];
                count _objects > 0 && { (_objects select 0) isKindOf "Air" }
            },
            []
        ] call zen_context_menu_fnc_createAction;

        [_actCallsign, [], 0] call zen_context_menu_fnc_addAction;

        // 2. Configure Radar Station on the fly in Zeus
        private _actRadar = [
            "AIRDEF_configRadar",
            "Air Defender: Настроить пост РЛС",
            "\A3\ui_f\data\map\markers\nato\b_installation.paa",
            {
                params ["_position", ["_objects", []]];
                if (count _objects == 0) exitWith {};
                private _target = _objects select 0;
                private _curRange = _target getVariable ["AIRDEF_radarRange", 35000];
                private _curName = _target getVariable ["AIRDEF_radarName", "Пост РЛС"];
                [
                    "Настройка поста РЛС",
                    [
                        ["CHECKBOX", ["Активная станция РЛС", "Включить этот объект в сеть радаров"], true],
                        ["SLIDER", ["Дальность зоны (км)", "Радиус зоны обнаружения"], [5, 100, _curRange / 1000, 0]],
                        ["EDIT", ["Позывной станции:", "Название на экране"], _curName]
                    ],
                    {
                        params ["_dialogValues", "_args"];
                        private _isActive = _dialogValues select 0;
                        private _rangeKm = _dialogValues select 1;
                        private _rName = _dialogValues select 2;
                        private _obj = _args select 0;
                        
                        _obj setVariable ["AIRDEF_isRadar", _isActive, true];
                        _obj setVariable ["AIRDEF_radarRange", _rangeKm * 1000, true];
                        _obj setVariable ["AIRDEF_radarName", _rName, true];
                        systemChat format ["[AIRDEF] Пост РЛС '%1' настроен: %2 км", _rName, _rangeKm];
                    },
                    {},
                    [_target]
                ] call zen_dialog_fnc_create;
            },
            {
                params ["_position", ["_objects", []]];
                count _objects > 0 && {
                    private _tgt = _objects select 0;
                    (_tgt isKindOf "AllVehicles") || (_tgt isKindOf "StaticWeapon") || ((typeOf _tgt) in AIRDEF_radarClasses)
                }
            },
            []
        ] call zen_context_menu_fnc_createAction;

        [_actRadar, [], 0] call zen_context_menu_fnc_addAction;
    };
};
