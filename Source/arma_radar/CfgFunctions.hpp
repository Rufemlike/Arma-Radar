class CfgFunctions
{
    class AIRDEF
    {
        tag = "AIRDEF";
        class Radar
        {
            file = "arma_radar\Functions";
            class preInit { preInit = 1; };
            class init { postInit = 1; };
            class openRadar {};
            class radarDraw {};
            class scanTargets {};
            class vectorIntercept {};
            class commandAi {};
            class uiInteractions {};
            class setupTerminal {};
        };
    };
};
