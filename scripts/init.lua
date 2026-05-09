Tracker:AddMaps("maps/maps.json")
Tracker:AddLayouts("layouts/settings_popup.json")
Tracker:AddLayouts("layouts/items.json")
Tracker:AddLayouts("layouts/tabs.json")
Tracker:AddLayouts("layouts/tracker.json")
Tracker:AddLayouts("layouts/broadcast.json")

require("scripts/logic/logic_helper")
require("scripts/logic/base_logic")
require("scripts/logic/graph_logic/logic_main")

require("scripts/items_import")
require("scripts/layouts_import")
require("scripts/locations_import")

require("scripts/luaitems")
require("scripts/watches")

if PopVersion and PopVersion >= "0.26.0" then
    require("scripts/autotracking")
end

function StateChanged(code, state)
end

function OnFrameHandler()
    ScriptHost:RemoveOnFrameHandler("load handler")
    ScriptHost:AddWatchForCode("StateChanged", "*", StateChanged)
    ScriptHost:AddOnLocationSectionChangedHandler("location_section_change_handler", LocationHandler)
    CreateLuaManualStorageItem("manual_location_storage")
    ForceUpdate()
end
ScriptHost:AddOnFrameHandler("load handler", OnFrameHandler)