class AIRDEF_Radar_Display
{
    idd = 78500;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = "uiNamespace setVariable ['AIRDEF_display', _this select 0];";
    onUnload = "uiNamespace setVariable ['AIRDEF_display', displayNull];";

    class ControlsBackground
    {
        class ScreenBackground: AIRDEF_RscText
        {
            idc = -1;
            x = "safezoneX";
            y = "safezoneY";
            w = "safezoneW";
            h = "safezoneH";
            colorBackground[] = COLOR_CRT_BG;
        };

        class HeaderBar: AIRDEF_RscText
        {
            idc = -1;
            x = "safezoneX";
            y = "safezoneY";
            w = "safezoneW";
            h = "0.045 * safezoneH";
            colorBackground[] = COLOR_CRT_PANEL_BG;
        };

        class LeftPanel: AIRDEF_RscText
        {
            idc = -1;
            x = "safezoneX";
            y = "safezoneY + 0.045 * safezoneH";
            w = "0.180 * safezoneW";
            h = "safezoneH - 0.085 * safezoneH";
            colorBackground[] = COLOR_CRT_PANEL_BG;
        };

        class RightPanel: AIRDEF_RscText
        {
            idc = -1;
            x = "safezoneX + safezoneW - 0.220 * safezoneW";
            y = "safezoneY + 0.045 * safezoneH";
            w = "0.220 * safezoneW";
            h = "safezoneH - 0.085 * safezoneH";
            colorBackground[] = COLOR_CRT_PANEL_BG;
        };

        class BottomBar: AIRDEF_RscText
        {
            idc = -1;
            x = "safezoneX";
            y = "safezoneY + safezoneH - 0.040 * safezoneH";
            w = "safezoneW";
            h = "0.040 * safezoneH";
            colorBackground[] = COLOR_CRT_PANEL_BG;
        };
    };

    class Controls
    {
        // ================= HEADER (NO 'AIR DEFENDER' - CLEAN MILITARY TELEMETRY) =================
        class SystemTime: AIRDEF_RscText
        {
            idc = 78503;
            x = "safezoneX + 0.012 * safezoneW";
            y = "safezoneY + 0.005 * safezoneH";
            w = "0.850 * safezoneW";
            h = "0.035 * safezoneH";
            font = "PuristaBold";
            sizeEx = "0.024 * safezoneH";
            colorText[] = COLOR_CRT_GREEN_BRIGHT;
            text = "СЕТЬ РЛС ПВО | TIME: 00:00:00 UTC | РЛС В СЕТИ: 0 | ТРЕКОВ: 0";
        };

        class CloseBtn: AIRDEF_RscButton
        {
            idc = 78599;
            x = "safezoneX + safezoneW - 0.085 * safezoneW";
            y = "safezoneY + 0.005 * safezoneH";
            w = "0.075 * safezoneW";
            h = "0.035 * safezoneH";
            text = "[X] ВЫХОД";
            action = "(findDisplay 78500) closeDisplay 1;";
        };

        // ================= CENTER MAP RADAR =================
        class RadarMap: AIRDEF_RscMapControl
        {
            idc = 78501;
            x = "safezoneX + 0.180 * safezoneW";
            y = "safezoneY + 0.045 * safezoneH";
            w = "safezoneW - 0.400 * safezoneW";
            h = "safezoneH - 0.085 * safezoneH";
        };

        // ================= LEFT TOOLBAR =================
        class FilterTitle: AIRDEF_RscText
        {
            idc = -1;
            x = "safezoneX + 0.008 * safezoneW";
            y = "safezoneY + 0.055 * safezoneH";
            w = "0.164 * safezoneW";
            h = "0.025 * safezoneH";
            font = "PuristaBold";
            sizeEx = "0.020 * safezoneH";
            colorText[] = COLOR_CRT_GREEN_BRIGHT;
            text = "--- ФИЛЬТРЫ ЦЕЛЕЙ ---";
        };

        class BtnFilterAll: AIRDEF_RscButton
        {
            idc = 78520;
            x = "safezoneX + 0.008 * safezoneW";
            y = "safezoneY + 0.085 * safezoneH";
            w = "0.164 * safezoneW";
            h = "0.032 * safezoneH";
            text = "[*] ВСЕ ЦЕЛИ";
            action = "['FILTER', 'ALL'] call AIRDEF_fnc_uiInteractions;";
        };

        class BtnFilterFriendly: AIRDEF_RscButton
        {
            idc = 78521;
            x = "safezoneX + 0.008 * safezoneW";
            y = "safezoneY + 0.122 * safezoneH";
            w = "0.164 * safezoneW";
            h = "0.032 * safezoneH";
            text = "[+] СОЮЗНИКИ";
            action = "['FILTER', 'FRIENDLY'] call AIRDEF_fnc_uiInteractions;";
        };

        class BtnFilterHostile: AIRDEF_RscButton
        {
            idc = 78522;
            x = "safezoneX + 0.008 * safezoneW";
            y = "safezoneY + 0.159 * safezoneH";
            w = "0.164 * safezoneW";
            h = "0.032 * safezoneH";
            text = "[!] ПРОТИВНИК";
            action = "['FILTER', 'HOSTILE'] call AIRDEF_fnc_uiInteractions;";
        };

        class BtnFilterMissile: AIRDEF_RscButton
        {
            idc = 78523;
            x = "safezoneX + 0.008 * safezoneW";
            y = "safezoneY + 0.196 * safezoneH";
            w = "0.164 * safezoneW";
            h = "0.032 * safezoneH";
            text = "[^] РАКЕТЫ";
            action = "['FILTER', 'MISSILES'] call AIRDEF_fnc_uiInteractions;";
        };

        class BtnFilterDatalink: AIRDEF_RscButton
        {
            idc = 78524;
            x = "safezoneX + 0.008 * safezoneW";
            y = "safezoneY + 0.245 * safezoneH";
            w = "0.164 * safezoneW";
            h = "0.035 * safezoneH";
            text = "[~] DATALINK";
            action = "['FILTER', 'DATALINK'] call AIRDEF_fnc_uiInteractions;";
        };

        class OptTitle: AIRDEF_RscText
        {
            idc = -1;
            x = "safezoneX + 0.008 * safezoneW";
            y = "safezoneY + 0.305 * safezoneH";
            w = "0.164 * safezoneW";
            h = "0.025 * safezoneH";
            font = "PuristaBold";
            sizeEx = "0.020 * safezoneH";
            colorText[] = COLOR_CRT_GREEN_BRIGHT;
            text = "--- СЛОИ ДИСПЛЕЯ ---";
        };

        class BtnToggleRings: AIRDEF_RscButton
        {
            idc = 78540;
            x = "safezoneX + 0.008 * safezoneW";
            y = "safezoneY + 0.335 * safezoneH";
            w = "0.164 * safezoneW";
            h = "0.035 * safezoneH";
            text = "КОЛЬЦА: ВКЛ";
            action = "['TOGGLE', 'RINGS'] call AIRDEF_fnc_uiInteractions;";
        };

        class BtnToggleSweep: AIRDEF_RscButton
        {
            idc = 78541;
            x = "safezoneX + 0.008 * safezoneW";
            y = "safezoneY + 0.375 * safezoneH";
            w = "0.164 * safezoneW";
            h = "0.035 * safezoneH";
            text = "ЛУЧ РЛС: ВКЛ";
            action = "['TOGGLE', 'SWEEP'] call AIRDEF_fnc_uiInteractions;";
        };

        class BtnToggleVectors: AIRDEF_RscButton
        {
            idc = 78542;
            x = "safezoneX + 0.008 * safezoneW";
            y = "safezoneY + 0.415 * safezoneH";
            w = "0.164 * safezoneW";
            h = "0.035 * safezoneH";
            text = "ВЕКТОРЫ: ВКЛ";
            action = "['TOGGLE', 'VECTORS'] call AIRDEF_fnc_uiInteractions;";
        };

        class BtnCenterRadar: AIRDEF_RscButton
        {
            idc = 78543;
            x = "safezoneX + 0.008 * safezoneW";
            y = "safezoneY + 0.455 * safezoneH";
            w = "0.164 * safezoneW";
            h = "0.035 * safezoneH";
            text = "ЦЕНТРИРОВАТЬ РЛС";
            action = "['CENTER_RADAR', 0] call AIRDEF_fnc_uiInteractions;";
        };

        // ================= RIGHT SIDEBAR =================
        class TargetHeader: AIRDEF_RscText
        {
            idc = -1;
            x = "safezoneX + safezoneW - 0.212 * safezoneW";
            y = "safezoneY + 0.055 * safezoneH";
            w = "0.204 * safezoneW";
            h = "0.025 * safezoneH";
            font = "PuristaBold";
            sizeEx = "0.020 * safezoneH";
            colorText[] = COLOR_CRT_GREEN_BRIGHT;
            text = "--- ФОРМУЛЯР ЦЕЛИ ---";
        };

        class TargetInfoText: AIRDEF_RscStructuredText
        {
            idc = 78510;
            x = "safezoneX + safezoneW - 0.212 * safezoneW";
            y = "safezoneY + 0.085 * safezoneH";
            w = "0.204 * safezoneW";
            h = "0.380 * safezoneH";
            colorBackground[] = {0.01, 0.04, 0.02, 0.6};
            text = "<t color='#00FF44' font='PuristaMedium'>НЕТ ВЫБРАННОЙ ЦЕЛИ.<br/><br/>Кликните левой кнопкой мыши по отметке на радаре для захвата данных.</t>";
        };

        class C2Header: AIRDEF_RscText
        {
            idc = -1;
            x = "safezoneX + safezoneW - 0.212 * safezoneW";
            y = "safezoneY + 0.485 * safezoneH";
            w = "0.204 * safezoneW";
            h = "0.025 * safezoneH";
            font = "PuristaBold";
            sizeEx = "0.020 * safezoneH";
            colorText[] = COLOR_CRT_GREEN_BRIGHT;
            text = "--- УПРАВЛЕНИЕ (C2 / GCI) ---";
        };

        class BtnVectorIntercept: AIRDEF_RscButton
        {
            idc = 78550;
            x = "safezoneX + safezoneW - 0.212 * safezoneW";
            y = "safezoneY + 0.515 * safezoneH";
            w = "0.204 * safezoneW";
            h = "0.034 * safezoneH";
            text = "[1] ВЕКТОРЕНИЕ (РАДИО)";
            action = "['ACTION', 'VECTOR'] call AIRDEF_fnc_uiInteractions;";
        };

        class BtnScramble: AIRDEF_RscButton
        {
            idc = 78551;
            x = "safezoneX + safezoneW - 0.212 * safezoneW";
            y = "safezoneY + 0.555 * safezoneH";
            w = "0.204 * safezoneW";
            h = "0.034 * safezoneH";
            text = "[2] ПРИКАЗ: ПЕРЕХВАТ";
            action = "['ACTION', 'INTERCEPT_AI'] call AIRDEF_fnc_uiInteractions;";
        };

        class BtnPatrolCAP: AIRDEF_RscButton
        {
            idc = 78552;
            x = "safezoneX + safezoneW - 0.212 * safezoneW";
            y = "safezoneY + 0.595 * safezoneH";
            w = "0.204 * safezoneW";
            h = "0.034 * safezoneH";
            text = "[3] ПРИКАЗ: ПАТРУЛЬ (CAP)";
            action = "['ACTION', 'CAP_AI'] call AIRDEF_fnc_uiInteractions;";
        };

        class BtnOrderRTB: AIRDEF_RscButton
        {
            idc = 78553;
            x = "safezoneX + safezoneW - 0.212 * safezoneW";
            y = "safezoneY + 0.635 * safezoneH";
            w = "0.204 * safezoneW";
            h = "0.034 * safezoneH";
            text = "[4] ПРИКАЗ: НА БАЗУ (RTB)";
            tooltip = "Отправить борт на базу. После нажатия кликните на карте нужный аэродром или базу союзников.";
            action = "['ACTION', 'RTB'] call AIRDEF_fnc_uiInteractions;";
        };

        class BtnClearSelection: AIRDEF_RscButton
        {
            idc = 78554;
            x = "safezoneX + safezoneW - 0.212 * safezoneW";
            y = "safezoneY + 0.675 * safezoneH";
            w = "0.204 * safezoneW";
            h = "0.034 * safezoneH";
            text = "СБРОС ВЫБОРА";
            action = "['ACTION', 'CLEAR'] call AIRDEF_fnc_uiInteractions;";
        };

        // ================= BOTTOM STATUS BAR =================
        class BottomStatusBar: AIRDEF_RscStructuredText
        {
            idc = 78511;
            x = "safezoneX + 0.010 * safezoneW";
            y = "safezoneY + safezoneH - 0.035 * safezoneH";
            w = "safezoneW - 0.020 * safezoneW";
            h = "0.030 * safezoneH";
            text = "<t color='#00FF44' font='PuristaMedium'>СТАТУС: [НОРМА] | РЛС В СЕТИ: 0 | ВСЕГО: 0 | СОЮЗНЫХ: 0 | ВРАЖЕСКИХ: 0 | DATALINK: 0 | РАКЕТ: 0</t>";
        };
    };
};
