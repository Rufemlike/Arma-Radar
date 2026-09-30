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
                    class AIRDEF_IsRadar
                    {
                        displayName = "Сделать станцией РЛС";
                        tooltip = "Отметьте, чтобы этот объект стал активным постом РЛС";
                        property = "AIRDEF_isRadar_prop";
                        control = "Checkbox";
                        expression = "if (_value isEqualTo true || {_value isEqualTo 1}) then { _this setVariable ['AIRDEF_isRadar', true, true]; };";
                        defaultValue = "false";
                    };
                    class AIRDEF_RadarSide
                    {
                        displayName = "Сторона РЛС (WEST / EAST / IND)";
                        tooltip = "Принадлежность радара: WEST (Синие), EAST (Красные), INDEPENDENT (Зеленые). Вражеские радары отображаются красными зонами угрозы ПВО!";
                        property = "AIRDEF_radarSide_prop";
                        control = "Edit";
                        expression = "if (!(_value isEqualTo '')) then { _this setVariable ['AIRDEF_radarSide', toUpper (str _value), true]; };";
                        defaultValue = "''";
                    };
                    class AIRDEF_RadarRange
                    {
                        displayName = "Дальность РЛС (в метрах)";
                        tooltip = "Радиус зоны обнаружения (например: 25000 для 25 км, 35000 для 35 км)";
                        property = "AIRDEF_radarRange_prop";
                        control = "Edit";
                        expression = "if (!(_value isEqualTo '')) then { _this setVariable ['AIRDEF_radarRange', parseNumber (str _value), true]; };";
                        defaultValue = "''";
                    };
                    class AIRDEF_RadarName
                    {
                        displayName = "Название / Позывной поста РЛС";
                        tooltip = "Название станции, которое будет отображаться на экране радара";
                        property = "AIRDEF_radarName_prop";
                        control = "Edit";
                        expression = "if (!(_value isEqualTo '')) then { _this setVariable ['AIRDEF_radarName', str _value, true]; };";
                        defaultValue = "''";
                    };
                    class AIRDEF_AirCallsign
                    {
                        displayName = "Позывной борта (Авиация)";
                        tooltip = "Позывной самолета/вертолета на диспетчерском радаре (например: Борт-101, Сокол-1)";
                        property = "AIRDEF_callsign_prop";
                        control = "Edit";
                        expression = "if (!(_value isEqualTo '')) then { _this setVariable ['AIRDEF_callsign', str _value, true]; };";
                        defaultValue = "''";
                    };
                };
            };
        };
    };
};

class CfgVehicles
{
    class Man;
    class CAManBase: Man
    {
        class UserActions
        {
            class OpenAirDefenderRadar
            {
                displayName = "<t color='#00FF44'>[РАДАР ПВО / УВД] Открыть терминал</t>";
                displayNameDefault = "<t color='#00FF44'>[РАДАР] Открыть</t>";
                position = "";
                radius = 5;
                onlyForPlayer = 1;
                condition = "alive player && (player isKindOf 'CAManBase') && (missionNamespace getVariable ['AIRDEF_enabled', true])";
                statement = "[] spawn AIRDEF_fnc_openRadar;";
                priority = 0.5;
            };
        };
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
