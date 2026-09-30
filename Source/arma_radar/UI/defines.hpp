// UI Constants
#define CT_STATIC           0
#define CT_BUTTON           1
#define CT_EDIT             2
#define CT_SLIDER           3
#define CT_COMBO            4
#define CT_LISTBOX          5
#define CT_TOOLBOX          6
#define CT_CHECKBOXES       7
#define CT_PROGRESS         8
#define CT_HTML             9
#define CT_STATIC_SKEW      10
#define CT_ACTIVETEXT       11
#define CT_TREE             12
#define CT_STRUCTURED_TEXT  13
#define CT_CONTEXT_MENU     14
#define CT_CONTROLS_GROUP   15
#define CT_SHORTCUTBUTTON   16
#define CT_XKEYDESC         40
#define CT_XBUTTON          41
#define CT_XLISTBOX         42
#define CT_XSLIDER          43
#define CT_XCOMBO           44
#define CT_ANIMATED_TEXTURE 45
#define CT_OBJECT           80
#define CT_OBJECT_ZOOM      81
#define CT_OBJECT_ABSOLUTE  82
#define CT_OBJECT_DIRECTION 83
#define CT_MAP              100
#define CT_MAP_MAIN         101
#define CT_LINEBREAK        98
#define CT_USER             99

#define ST_LEFT             0x00
#define ST_RIGHT            0x01
#define ST_CENTER           0x02
#define ST_DOWN             0x04
#define ST_UP               0x08
#define ST_VCENTER          0x0C
#define ST_SINGLE           0x00
#define ST_MULTI            0x10
#define ST_TITLE_BAR        0x20
#define ST_PICTURE          0x30
#define ST_FRAME            0x40
#define ST_BACKGROUND       0x50
#define ST_GROUP_BOX        0x60
#define ST_GROUP_BOX2       0x70
#define ST_HUD_BACKGROUND   0x80
#define ST_TILE_PICTURE     0x90
#define ST_WITH_RECT        0xA0
#define ST_LINE             0xB0

#define GUI_GRID_W          (0.025)
#define GUI_GRID_H          (0.04)

// Green CRT Palette
#define COLOR_CRT_GREEN        {0, 1, 0.25, 1}
#define COLOR_CRT_GREEN_DIM    {0, 0.45, 0.12, 0.8}
#define COLOR_CRT_GREEN_BRIGHT {0.2, 1, 0.4, 1}
#define COLOR_CRT_BG           {0.01, 0.03, 0.015, 0.97}
#define COLOR_CRT_PANEL_BG     {0.02, 0.06, 0.03, 0.92}
#define COLOR_CRT_BORDER       {0, 0.7, 0.2, 1}
#define COLOR_CRT_HOSTILE      {1, 0.25, 0.2, 1}
#define COLOR_CRT_MISSILE      {1, 0.85, 0.1, 1}

// Base classes from A3_UI_F
class RscText;
class RscStructuredText;
class RscButton;
class RscMapControl;

class AIRDEF_RscText: RscText
{
    colorBackground[] = {0, 0, 0, 0};
    colorText[] = COLOR_CRT_GREEN;
    font = "PuristaMedium";
    sizeEx = "0.020 * safezoneH";
    shadow = 0;
};

class AIRDEF_RscStructuredText: RscStructuredText
{
    colorText[] = COLOR_CRT_GREEN;
    class Attributes
    {
        font = "PuristaMedium";
        color = "#00FF44";
        align = "left";
        shadow = 0;
    };
    size = "0.019 * safezoneH";
    shadow = 0;
};

class AIRDEF_RscButton: RscButton
{
    style = 2; // ST_CENTER
    font = "PuristaBold";
    sizeEx = "0.019 * safezoneH";
    colorText[] = {0.2, 1, 0.45, 1};
    colorDisabled[] = {0, 0.3, 0.1, 0.5};
    colorBackground[] = {0.02, 0.07, 0.035, 0.9};
    colorBackgroundDisabled[] = {0, 0, 0, 0.5};
    colorBackgroundActive[] = {0.04, 0.32, 0.14, 1};
    colorFocused[] = {0.03, 0.24, 0.10, 1};
    colorShadow[] = {0, 0, 0, 0};
    colorBorder[] = {0, 0.8, 0.25, 0.9};
    borderSize = 0.0015;
    soundEnter[] = {"\A3\ui_f\data\sound\RscButton\soundEnter", 0.09, 1};
    soundPush[] = {"\A3\ui_f\data\sound\RscButton\soundPush", 0.09, 1};
    soundClick[] = {"\A3\ui_f\data\sound\RscButton\soundClick", 0.09, 1};
    soundEscape[] = {"\A3\ui_f\data\sound\RscButton\soundEscape", 0.09, 1};
    shadow = 0;
    offsetX = 0;
    offsetY = 0;
    offsetPressedX = 0.001;
    offsetPressedY = 0.001;
};

// Inherits from RscMapControl to guarantee all engine properties exist
class AIRDEF_RscMapControl: RscMapControl
{
    drawObjects = 0;
    showMarkers = 0;
    showTasks = 0;
    showCountourInterval = 0;
    font = "EtelkaMonospacePro";
    sizeEx = 0.03;
    scaleMin = 0.001;
    scaleMax = 1.0;
    scaleDefault = 0.15;
    
    // Custom vector green CRT color mapping
    colorBackground[] = {0.008, 0.025, 0.012, 1};
    colorText[] = COLOR_CRT_GREEN;
    colorSea[] = {0.004, 0.015, 0.008, 1};
    colorForest[] = {0.012, 0.035, 0.018, 0.4};
    colorForestBorder[] = {0, 0.4, 0.15, 0.5};
    colorRocks[] = {0.01, 0.03, 0.015, 0.5};
    colorRocksBorder[] = {0, 0.35, 0.1, 0.4};
    colorLevels[] = {0, 0.5, 0.18, 0.35};
    colorMainCountlines[] = {0, 0.7, 0.25, 0.6};
    colorCountlines[] = {0, 0.4, 0.15, 0.3};
    colorMainCountlinesWater[] = {0, 0.5, 0.2, 0.5};
    colorCountlinesWater[] = {0, 0.35, 0.15, 0.3};
    colorMainRoads[] = {0, 0.6, 0.2, 0.7};
    colorMainRoadsFill[] = {0, 0.4, 0.12, 0.5};
    colorRoads[] = {0, 0.45, 0.15, 0.5};
    colorRoadsFill[] = {0, 0.3, 0.1, 0.4};
    colorTracks[] = {0, 0.35, 0.1, 0.3};
    colorTracksFill[] = {0, 0.25, 0.08, 0.2};
    colorGrid[] = {0, 0.35, 0.12, 0.45};
    colorGridMap[] = {0, 0.4, 0.15, 0.5};
    
    colorTrails[] = {0, 0.3, 0.1, 0.3};
    colorTrailsFill[] = {0, 0.2, 0.08, 0.2};
    colorPowerLines[] = {0, 0.5, 0.15, 0.5};
    colorRailWay[] = {0, 0.5, 0.18, 0.6};
    colorNames[] = {0, 0.8, 0.3, 0.75};
    colorInactive[] = {0, 0.2, 0.08, 0.5};
    colorOutside[] = {0, 0, 0, 1};
    
    fontLabel = "PuristaMedium";
    sizeExLabel = 0.022;
    fontGrid = "EtelkaMonospacePro";
    sizeExGrid = 0.020;
    fontUnits = "PuristaMedium";
    sizeExUnits = 0.022;
    fontNames = "PuristaMedium";
    sizeExNames = 0.022;
    fontInfo = "PuristaMedium";
    sizeExInfo = 0.020;
    fontLevel = "PuristaMedium";
    sizeExLevel = 0.020;
    
    maxSatelliteAlpha = 0;
};
