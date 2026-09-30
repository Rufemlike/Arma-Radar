class CfgFunctions
{
    class AIRDEF
    {
        tag = "AIRDEF";
        class Radar
        {
            file = "arma_radar\Functions";
            class init { postInit = 1; };
            class openRadar {};
            class radarDraw {};
            class scanTargets {};
            class vectorIntercept {};
            class commandAi {};
            class uiInteractions {};
        };
    };
};
