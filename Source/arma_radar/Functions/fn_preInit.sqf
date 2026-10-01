/*
    Author: Arma Radar Team
    File: fn_preInit.sqf
    Description:
        Pre-Initialization for Air Defender Radar System.
        Executes at game launch, in Main Menu, in Eden Editor, and before mission start.
        Registers CBA settings so they appear in Eden Editor's Addon Options and in-game pause menu.
*/

// Default fallback values
if (isNil "AIRDEF_onlyCustomRadars") then { AIRDEF_onlyCustomRadars = false; };
if (isNil "AIRDEF_autoScanMapRadars") then { AIRDEF_autoScanMapRadars = true; };
if (isNil "AIRDEF_autoScanVehicleRadars") then { AIRDEF_autoScanVehicleRadars = true; };
if (isNil "AIRDEF_radarRangeMultiplier") then { AIRDEF_radarRangeMultiplier = 1.0; };
if (isNil "AIRDEF_requireTerminal") then { AIRDEF_requireTerminal = false; };
if (isNil "AIRDEF_filter") then { AIRDEF_filter = "ALL"; };
if (isNil "AIRDEF_showRings") then { AIRDEF_showRings = true; };
if (isNil "AIRDEF_showSweep") then { AIRDEF_showSweep = true; };
if (isNil "AIRDEF_showVectors") then { AIRDEF_showVectors = true; };
if (isNil "AIRDEF_sweepSpeed") then { AIRDEF_sweepSpeed = 60; };
if (isNil "AIRDEF_continuousUpdate") then { AIRDEF_continuousUpdate = false; };

// Register CBA settings if CBA is available
if (isClass (configFile >> "CfgPatches" >> "cba_main") || !isNil "CBA_fnc_addSetting") then {
    // 1. Only use explicitly configured radars from 3DEN / Zeus
    [
        "AIRDEF_onlyCustomRadars",
        "CHECKBOX",
        ["Только назначенные РЛС (3DEN/Zeus)", "Использовать ТОЛЬКО объекты, которым явно включен статус РЛС в 3DEN или через Зевса. Случайные вышки карты и техника игнорируются."],
        "Air Defender Radar",
        false,
        false // Editable by player and mission maker (not locked/grayed out)
    ] call CBA_fnc_addSetting;

    // 2. Auto-scan map radar structures
    [
        "AIRDEF_autoScanMapRadars",
        "CHECKBOX",
        ["Автопоиск РЛС-сооружений карты", "Автоматически находить на карте радарные вышки (Land_Radar_F, башни аэродромов)"],
        "Air Defender Radar",
        true,
        false
    ] call CBA_fnc_addSetting;

    // 3. Auto-scan vehicle/SAM radars
    [
        "AIRDEF_autoScanVehicleRadars",
        "CHECKBOX",
        ["Автопоиск РЛС техники и ЗРК", "Автоматически использовать сенсоры активной техники и комплексов ПВО (Patriot, SAM, Radar System)"],
        "Air Defender Radar",
        true,
        false
    ] call CBA_fnc_addSetting;

    // 4. Global radar range multiplier (for small maps)
    [
        "AIRDEF_radarRangeMultiplier",
        "SLIDER",
        ["Множитель дальности РЛС (Масштаб карты)", "Масштабирование дальности всех радаров. Для маленьких карт установите 0.2 - 0.5 (20%-50% дальности)"],
        "Air Defender Radar",
        [0.1, 1.5, 1.0, 2],
        false
    ] call CBA_fnc_addSetting;

    // 5. Require physical terminal
    [
        "AIRDEF_requireTerminal",
        "CHECKBOX",
        ["Доступ к РЛС только через терминалы", "Если включено — радар открывается только при физическом подходе к объекту-терминалу на базе"],
        "Air Defender Radar",
        false,
        false
    ] call CBA_fnc_addSetting;

    // 6. Continuous target update mode (Live vs Sweep)
    [
        "AIRDEF_continuousUpdate",
        "CHECKBOX",
        ["Непрерывное обновление целей (Live)", "Если включено, отметки целей на экране двигаются непрерывно в реальном времени. Если выключено — положение целей обновляется только при проходе сканирующего луча РЛС."],
        "Air Defender Radar",
        false,
        false
    ] call CBA_fnc_addSetting;
};
