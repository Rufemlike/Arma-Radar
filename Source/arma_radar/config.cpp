class CfgPatches
{
    class arma_radar
    {
        name = "Air Defender Radar System";
        author = "Arma Radar Team";
        url = "";
        units[] = {
            "AIRDEF_RadarEmitter_West",
            "AIRDEF_RadarEmitter_East",
            "AIRDEF_RadarEmitter_Indep"
        };
        weapons[] = {};
        requiredVersion = 1.98;
        requiredAddons[] = {
            "A3_UI_F",
            "A3_Data_F",
            "A3_Functions_F",
            "A3_Static_F",
            "3DEN"
        };
    };
};

// ================= NATIVE ACTIVE RADAR EMITTER VEHICLES =================
// Used to provide active radar emission in the Arma 3 Jets DLC Sensor Overhaul for any object
// (allows aircraft RWR to detect radar emission and anti-radiation missiles like AGM-88 HARM / Kh-31 to lock on)
class CfgVehicles
{
    class LandVehicle;
    class StaticWeapon: LandVehicle
    {
        class Components;
        class Turrets;
        class HitPoints;
    };

    class AIRDEF_RadarEmitter_Base: StaticWeapon
    {
        scope = 1;
        displayName = "Air Defender Radar Emitter";
        model = "\A3\Weapons_F\empty.p3d";
        icon = "iconStaticObject";
        picture = "pictureStaticObject";
        vehicleClass = "Autonomous";
        isUav = 1;
        hasDriver = 0;
        hasGunner = 0;
        hasCommander = 0;
        threat[] = {0, 0, 1};
        cost = 1000000;
        radarTarget = 1;
        radarTargetSize = 2.5;
        visualTarget = 0;
        irTarget = 1;
        irTargetSize = 1.5;
        armor = 80;
        class Turrets {};
        class HitPoints {};
        class Components: Components
        {
            class SensorsManagerComponent
            {
                class Components
                {
                    class ActiveRadarSensorComponent
                    {
                        componentType = "ActiveRadarSensorComponent";
                        class AirTarget
                        {
                            minRange = 50;
                            maxRange = 60000;
                            objectDistanceLimitCoef = -1;
                            viewDistanceLimitCoef = -1;
                        };
                        class GroundTarget
                        {
                            minRange = 50;
                            maxRange = 40000;
                            objectDistanceLimitCoef = -1;
                            viewDistanceLimitCoef = -1;
                        };
                        typeRecognitionDistance = 35000;
                        angleRangeHorizontal = 360;
                        angleRangeVertical = 100;
                        groundNoiseDistanceCoef = -1;
                        maxGroundNoiseDistance = -1;
                        minSpeedThreshold = 0;
                        maxSpeedThreshold = 0;
                        aimDown = 0;
                        minTrackableSpeed = -1e+010;
                        maxTrackableSpeed = 1e+010;
                        minTrackableATL = -1e+010;
                        maxTrackableATL = 1e+010;
                        allowsMarking = 1;
                    };
                };
            };
        };
    };

    class AIRDEF_RadarEmitter_West: AIRDEF_RadarEmitter_Base
    {
        scope = 1;
        side = 1;
        faction = "BLU_F";
        crew = "B_UAV_AI";
    };

    class AIRDEF_RadarEmitter_East: AIRDEF_RadarEmitter_Base
    {
        scope = 1;
        side = 0;
        faction = "OPF_F";
        crew = "O_UAV_AI";
    };

    class AIRDEF_RadarEmitter_Indep: AIRDEF_RadarEmitter_Base
    {
        scope = 1;
        side = 2;
        faction = "IND_F";
        crew = "I_UAV_AI";
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
                    class AIRDEF_IsRadarBoard
                    {
                        displayName = "Сделать тактической доской РЛС";
                        tooltip = "На поверхности этого объекта (доски, экрана, монитора) будет в 3D отображаться живая карта радара с лучом и метками";
                        property = "AIRDEF_isRadarBoard_prop";
                        control = "Checkbox";
                        expression = "if (_value isEqualTo true || {_value isEqualTo 1}) then { _this setVariable ['AIRDEF_isRadarBoard', true, true]; if (hasInterface) then { [_this] call AIRDEF_fnc_radarBoard; }; } else { _this setVariable ['AIRDEF_isRadarBoard', false, true]; };";
                        defaultValue = "false";
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
        class AIRDEF_fnc_radarBoard     { allowedTargets = 0; jip = 1; };
        class systemChat                { allowedTargets = 0; jip = 0; };
    };
    class Commands
    {
        mode = 2;
        class setVehicleRadar           { allowedTargets = 0; jip = 0; };
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
