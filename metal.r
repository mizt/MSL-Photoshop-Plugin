#include "PIGeneral.r"
#include "PIUtilities.r"

#define vendorName           "mizt"
#define plugInName           "Metal"
#define plugInSuiteID        'sdk1'
#define plugInClassID        plugInSuiteID
#define plugInEventID        plugInClassID
#define plugInUniqueID       "9bfb4a70-027f-11e9-b568-0800200c9a66"


resource 'PiPL' ( 16000, plugInName, purgeable )
{
    {
        Kind { Filter },
        Name { plugInName },
        Category { vendorName },
        Version { (latestFilterVersion << 16 ) | latestFilterSubVersion },
        
        Component { ComponentNumber, plugInName },        
        CodeMacIntel64 { "PluginMain" },
        SupportedModes
        {
            noBitmap, doesSupportGrayScale,
            noIndexedColor, doesSupportRGBColor,
            doesSupportCMYKColor, doesSupportHSLColor,
            doesSupportHSBColor, doesSupportMultichannel,
            doesSupportDuotone, doesSupportLABColor
        },
        
        HasTerminology
        {
            plugInClassID,
            plugInEventID,
            16000,
            plugInUniqueID
        },
        
        EnableInfo { "in (PSHOP_ImageMode, RGBMode )" },
        
        PlugInMaxSize { 2000000, 2000000 },
        
        FilterLayerSupport {doesSupportFilterLayers},
        
    }
};

