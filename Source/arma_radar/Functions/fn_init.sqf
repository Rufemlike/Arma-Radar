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

// Ensure preInit settings are registered
[] call AIRDEF_fnc_preInit;

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
            if (missionNamespace getVariable ["AIRDEF_requireTerminal", false]) then {
                private _nearTerminals = (nearestObjects [player, ["All"], 4]) select {
                    (_x getVariable ["AIRDEF_isTerminal", false]) && { alive _x }
                };
                if (count _nearTerminals == 0) exitWith {
                    systemChat "[AIRDEF] Доступ к РЛС открыт только через физический терминал на базе!";
                };
                [] spawn AIRDEF_fnc_openRadar;
            } else {
                [] spawn AIRDEF_fnc_openRadar;
            };
        };
        true
    }, {}, [19, [true, false, false]]] call CBA_fnc_addKeybind;
};

// ================= BACKGROUND RADAR DISCOVERY & MAP MARKERS LOOP =================
// Continuously scans for placed radars (in Zeus, 3DEN or scripts) every 2 seconds,
// auto-activates unmanned radars, maintains coverage markers, and hooks terminal actions.
[] spawn {
    while {true} do {
        try {
            [] call AIRDEF_fnc_scanTargets;

            // Auto-setup terminals for objects marked with AIRDEF_isTerminal
            if (hasInterface) then {
                private _terminals = (allMissionObjects "All") select {
                    (_x getVariable ["AIRDEF_isTerminal", false]) && { !(_x getVariable ["AIRDEF_terminalActionAdded", false]) }
                };
                {
                    [_x] call AIRDEF_fnc_setupTerminal;
                } forEach _terminals;
            };
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

        // 3. Configure Radar Terminal on the fly in Zeus
        private _actTerminal = [
            "AIRDEF_configTerminal",
            "Air Defender: Сделать терминалом РЛС",
            "\A3\ui_f\data\map\markers\nato\b_installation.paa",
            {
                params ["_position", ["_objects", []]];
                if (count _objects == 0) exitWith {};
                private _target = _objects select 0;
                private _isTerm = _target getVariable ["AIRDEF_isTerminal", false];
                private _curSide = _target getVariable ["AIRDEF_terminalSide", "ANY"];
                private _sideIndex = switch (toUpper _curSide) do {
                    case "WEST": { 1 };
                    case "EAST": { 2 };
                    case "INDEPENDENT": { 3 };
                    case "IND": { 3 };
                    default { 0 };
                };

                [
                    "Настройка терминала доступа к РЛС",
                    [
                        ["CHECKBOX", ["Сделать терминалом", "Игроки смогут подойти к этому объекту и открыть радар"], !_isTerm],
                        ["COMBO", ["Сторона доступа", "Какая сторона сможет пользоваться этим терминалом"], [["ANY", "WEST", "EAST", "INDEPENDENT"], ["Любая сторона (Свободно)", "WEST (Синие)", "EAST (Красные)", "INDEPENDENT (Зеленые)"], _sideIndex]]
                    ],
                    {
                        params ["_dialogValues", "_args"];
                        private _enableTerm = _dialogValues select 0;
                        private _sideChoice = _dialogValues select 1;
                        private _obj = _args select 0;

                        _obj setVariable ["AIRDEF_isTerminal", _enableTerm, true];
                        _obj setVariable ["AIRDEF_terminalSide", _sideChoice, true];
                        if (_enableTerm) then {
                            [_obj] remoteExec ["AIRDEF_fnc_setupTerminal", 0, true];
                            systemChat format ["[AIRDEF] Объект '%1' теперь терминал доступа к РЛС (%2)", typeOf _obj, _sideChoice];
                        } else {
                            systemChat format ["[AIRDEF] Терминал '%1' деактивирован", typeOf _obj];
                        };
                    },
                    {},
                    [_target]
                ] call zen_dialog_fnc_create;
            },
            {
                params ["_position", ["_objects", []]];
                count _objects > 0
            },
            []
        ] call zen_context_menu_fnc_createAction;

        [_actTerminal, [], 0] call zen_context_menu_fnc_addAction;
    };
};
