class CfgPatches
{
    class arma_radar
    {
        name = "Air Defender Radar System";
        author = "Arma Radar Team";
        url = "";
        units[] = {};
        weapons[] = {};
        requiredVersion = 1.98;
        requiredAddons[] = {
            "A3_UI_F",
            "A3_Data_F",
            "A3_Functions_F",
            "3DEN"
        };
    };
};

#include "UI\defines.hpp"
#include "UI\radar_display.hpp"
#include "CfgFunctions.hpp"

// CBA Extended Event Handlers for Settings Pre-Initialization
class Extended_PreInit_EventHandlers
{
    class arma_radar
    {
        init = "call AIRDEF_fnc_preInit";
    };
};

// ================= EDEN EDITOR CUSTOM ATTRIBUTES =================
class Cfg3DEN
{
    class Object
    {
        class AttributeCategories
        {
            class AIRDEF_RadarCategory
            {
                displayName = "Air Defender Radar System";
                collapsed = 0;
                class Attributes
                {
                    class AIRDEF_IsTerminal
                    {
                        displayName = "Сделать терминалом доступа к РЛС";
                        tooltip = "Игроки смогут подойти к этому объекту и открыть экран радара через меню действий";
                        property = "AIRDEF_isTerminal_prop";
                        control = "Checkbox";
                        expression = "if (_value isEqualTo true || {_value isEqualTo 1}) then { _this setVariable ['AIRDEF_isTerminal', true, true]; if (hasInterface) then { [_this] call AIRDEF_fnc_setupTerminal; }; } else { _this setVariable ['AIRDEF_isTerminal', false, true]; };";
                        defaultValue = "false";
                    };
                    class AIRDEF_TerminalSide
                    {
                        displayName = "Сторона доступа к терминалу";
                        tooltip = "Какая сторона имеет доступ к этому терминалу РЛС";
                        property = "AIRDEF_terminalSide_prop";
                        control = "Combo";
                        defaultValue = "'ANY'";
                        expression = "if (!isNil '_value' && {!(_value isEqualTo '')}) then { _this setVariable ['AIRDEF_terminalSide', _value, true]; };";
                        class Values
                        {
                            class AnySide
                            {
                                name = "Любая сторона (Свободный доступ)";
                                data = "ANY";
                                value = "ANY";
                                default = 1;
                            };
                            class West
                            {
                                name = "Только WEST (Синие / BLUFOR)";
                                data = "WEST";
                                value = "WEST";
                            };
                            class East
                            {
                                name = "Только EAST (Красные / OPFOR)";
                                data = "EAST";
                                value = "EAST";
                            };
                            class Indep
                            {
                                name = "Только INDEPENDENT (Зеленые / Guerrilla)";
                                data = "INDEPENDENT";
                                value = "INDEPENDENT";
                            };
                        };
                    };
                    class AIRDEF_IsRadar
                    {
                        displayName = "Сделать станцией РЛС";
                        tooltip = "Отметьте, чтобы этот объект стал активным постом РЛС";
                        property = "AIRDEF_isRadar_prop";
                        control = "Checkbox";
                        expression = "if (_value isEqualTo true || {_value isEqualTo 1}) then { _this setVariable ['AIRDEF_isRadar', true, true]; } else { _this setVariable ['AIRDEF_isRadar', false, true]; };";
                        defaultValue = "false";
                    };
                    class AIRDEF_RadarSide
                    {
                        displayName = "Сторона РЛС";
                        tooltip = "Принадлежность радара к стороне. Вражеские радары отображаются красными зонами угрозы ПВО!";
                        property = "AIRDEF_radarSide_prop";
                        control = "Combo";
                        defaultValue = "'AUTO'";
                        expression = "if (!isNil '_value' && {!(_value isEqualTo '')}) then { _this setVariable ['AIRDEF_radarSide', _value, true]; };";
                        class Values
                        {
                            class Auto
                            {
                                name = "Авто (по фракции/экипажу)";
                                data = "AUTO";
                                value = "AUTO";
                                default = 1;
                            };
                            class West
                            {
                                name = "WEST (Синие / BLUFOR)";
                                data = "WEST";
                                value = "WEST";
                            };
                            class East
                            {
                                name = "EAST (Красные / OPFOR)";
                                data = "EAST";
                                value = "EAST";
                            };
                            class Indep
                            {
                                name = "INDEPENDENT (Зеленые / Guerrilla)";
                                data = "INDEPENDENT";
                                value = "INDEPENDENT";
                            };
                            class AllSides
                            {
                                name = "ДЛЯ ВСЕХ (Общий радар)";
                                data = "ALL";
                                value = "ALL";
                            };
                        };
                    };
                    class AIRDEF_RadarRange
                    {
                        displayName = "Дальность РЛС (в метрах)";
                        tooltip = "Радиус обнаружения для этой РЛС (например: 5000, 10000, 25000). 0 = паспортная дальность из конфига сенсоров";
                        property = "AIRDEF_radarRange_prop";
                        control = "Edit";
                        expression = "private _val = if (_value isEqualType 0) then {_value} else {parseNumber _value}; if (_val > 0) then { _this setVariable ['AIRDEF_radarRange', _val, true]; };";
                        defaultValue = "'0'";
                    };
                    class AIRDEF_RadarName
                    {
                        displayName = "Название / Позывной поста РЛС";
                        tooltip = "Название станции, которое будет отображаться на экране радара";
                        property = "AIRDEF_radarName_prop";
                        control = "Edit";
                        expression = "if (!(_value isEqualTo '')) then { _this setVariable ['AIRDEF_radarName', _value, true]; };";
                        defaultValue = "''";
                    };
                    class AIRDEF_AirCallsign
                    {
                        displayName = "Позывной борта (Авиация)";
                        tooltip = "Позывной самолета/вертолета на диспетчерском радаре (например: Борт-101, Сокол-1)";
                        property = "AIRDEF_callsign_prop";
                        control = "Edit";
                        expression = "if (!(_value isEqualTo '')) then { _this setVariable ['AIRDEF_callsign', _value, true]; };";
                        defaultValue = "''";
                    };
                };
            };
        };
    };
};

// Whitelist remote execution functions for multiplayer stability
class CfgRemoteExec
{
    class Functions
    {
        mode = 2;
        jip = 1;
        class AIRDEF_fnc_commandPilot   { allowedTargets = 0; jip = 0; };
        class AIRDEF_fnc_commandAi      { allowedTargets = 0; jip = 0; };
        class AIRDEF_fnc_setupTerminal  { allowedTargets = 0; jip = 1; };
        class systemChat                { allowedTargets = 0; jip = 0; };
    };
};

class CfgSounds
{
    sounds[] = {};
    class readouts_click_01
    {
        name = "readouts_click_01";
        sound[] = {"\A3\ui_f\data\sound\RscButton\soundClick.wss", 0.7, 1};
        titles[] = {};
    };
    class readouts_alarm_01
    {
        name = "readouts_alarm_01";
        sound[] = {"\A3\ui_f\data\sound\CfgNotifications\default.wss", 1.0, 1};
        titles[] = {};
    };
};
