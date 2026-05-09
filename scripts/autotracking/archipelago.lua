require("scripts/autotracking/item_mapping")
require("scripts/autotracking/location_mapping")

CUR_INDEX = -1
--SLOT_DATA = nil

ALL_LOCATIONS = {}
SLOT_DATA = {}

MANUAL_CHECKED = true
ROOM_SEED = "default"
TROLL_PLAYER = false

-- Duelist item IDs for counting available duelists
DUELIST_ITEM_IDS = {
    255567,255568,255569,255570,255571,255572,255573,255574,255575,255576,
    255577,255578,255579,255580,255581,255582,255583,255584,255585,255586,
    255587,255588,255589,255590,255591,255592,255593,255594,255595,255596,
    255597,255598,255599,255600,255601,255602,255603,255604,255605,255606,
    255607,255608,255609,255610,255611,255612,255613,255614,255615,255616,
    255617,255618,255619,255620,255621,255622,255623,255624,255625,255626,
    255627,255628,255629,255630,255631,255632,255633,255634,255635,255636,
    255637,255638,255639,255640,255641,255642,255643,255644,255645,255646,
    255647,255648,255649,255651,255652,255653,255654,255655,255656,255657,
    255658,255659
}
DUELIST_ITEM_IDS_SET = {}
for _, id in ipairs(DUELIST_ITEM_IDS) do
    DUELIST_ITEM_IDS_SET[id] = true
end

-- Duelist location IDs for counting defeated duelists (defeated 1 and 2)
DUELIST_LOCATION_IDS_SET = {}
for _, id in ipairs({255567,255568,255569,255570,255571,255572,255573,255574,255575,255576,255577,255578,255579,255580,255581,255582,255583,255584,255585,255586,255587,255588,255589,255590,255591,255592,255593,255594,255595,255596,255597,255598,255599,255600,255601,255602,255603,255604,255605,255606,255607,255608,255609,255610,255611,255612,255613,255614,255615,255616,255617,255618,255619,255620,255621,255622,255623,255624,255625,255626,255627,255628,255629,255630,255631,255632,255633,255634,255635,255636,255637,255638,255639,255640,255641,255642,255643,255644,255645,255646,255647,255648,255649,255651,255652,255653,255654,255655,255656,255657,255658,255659}) do
    DUELIST_LOCATION_IDS_SET[id] = true
end
for _, id in ipairs({511136,511138,511140,511142,511144,511146,511148,511150,511152,511154,511156,511158,511160,511162,511164,511166,511168,511170,511172,511174,511176,511178,511180,511182,511184,511186,511188,511190,511192,511194,511196,511198,511200,511202,511204,511206,511208,511210,511212,511214,511216,511218,511220,511222,511224,511226,511228,511230,511232,511234,511236,511238,511240,511242,511244,511246,511248,511250,511252,511254,511256,511258,511260,511262,511264,511266,511268,511270,511272,511274,511276,511278,511280,511282,511284,511286,511288,511290,511292,511294,511296,511298,511302,511304,511306,511308,511310,511312,511314,511316,511318}) do
    DUELIST_LOCATION_IDS_SET[id] = true
end

function updateDuelistCounters()
    local avail = Tracker:FindObjectForCode("free_duelists_available")
    local defeated = Tracker:FindObjectForCode("free_duelists_defeated")
    if avail then
        local count = 0
        for _, id in ipairs(DUELIST_ITEM_IDS) do
            local item_array = ITEM_MAPPING[id]
            if item_array and item_array[1] then
                local obj = Tracker:FindObjectForCode(item_array[1][1])
                if obj and obj.Active then
                    count = count + 1
                end
            end
        end
        avail.AcquiredCount = count
    end
    if defeated then
        local count = 0
        for id, _ in pairs(DUELIST_LOCATION_IDS_SET) do
            local loc_array = LOCATION_MAPPING[id]
            if loc_array and loc_array[1] then
                local obj = Tracker:FindObjectForCode(loc_array[1])
                if obj and obj.AvailableChestCount ~= nil and obj.AvailableChestCount < obj.ChestCount then
                    count = count + 1
                end
            end
        end
        defeated.AcquiredCount = count
    end
    -- Yami Yugi unlock: activate toggle when free_duelists_defeated >= free_duel_goal
    local goal = 25 -- default fallback
    if SLOT_DATA and SLOT_DATA["g"] and SLOT_DATA["g"]["free_duel_goal"] then
        goal = SLOT_DATA["g"]["free_duel_goal"]
    end
    local defeated_obj = Tracker:FindObjectForCode("free_duelists_defeated")
    local yami = Tracker:FindObjectForCode("yami_yugi")
    if defeated_obj and yami then
        yami.Active = (defeated_obj.AcquiredCount >= goal)
    end
end

if Highlight then
    HIGHLIGHT_LEVEL= {
        [0] = Highlight.Unspecified,
        [10] = Highlight.NoPriority,
        [20] = Highlight.Avoid,
        [30] = Highlight.Priority,
        [40] = Highlight.None,
        [100] = Highlight.None, --Filler
        [101] = Highlight.Priority, --Progression
        [102] = Highlight.NoPriority, --Useful
        [104] = Highlight.Avoid, --Trap
    }
end

Troll_Lookup = {
    ["solarcell"] = true,
    ["earthor"] = true,
}

function dump_table(o, depth)
    if depth == nil then
        depth = 0
    end
    if type(o) == 'table' then
        local tabs = ('\t'):rep(depth)
        local tabs2 = ('\t'):rep(depth + 1)
        local s = '{\n'
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. tabs2 .. '[' .. k .. '] = ' .. dump_table(v, depth + 1) .. ',\n'
        end
        return s .. tabs .. '}'
    else
        return tostring(o)
    end
end

function LocationHandler(location)
    if MANUAL_CHECKED then
        local custom_storage_item = Tracker:FindObjectForCode("manual_location_storage").ItemState
        if not custom_storage_item then
            return
        end
        if Archipelago.PlayerNumber == -1 then -- not connected
            if ROOM_SEED ~= "default" then -- seed is from previous connection
                ROOM_SEED = "default"
                custom_storage_item.MANUAL_LOCATIONS["default"] = {}
            else -- seed is default
            end
        end
        local full_path = location.FullID
        if not custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED] then
            custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED] = {}
        end
        if location.AvailableChestCount < location.ChestCount then --add to list
            custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED][full_path] = location.AvailableChestCount
        else --remove from list of set back to max chestcount
            custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED][full_path] = nil
        end
    end
    ForceUpdate()
end

function ForceUpdate()
    local update = Tracker:FindObjectForCode("update")
    if update == nil then
        return
    end
    update.Active = not update.Active
end

function onClearHandler(slot_data)
    local clear_timer = os.clock()
    
    ScriptHost:RemoveWatchForCode("StateChange")
    Tracker.BulkUpdate = true
    local ok, err = pcall(onClear, slot_data)
    if ok then
        local handlerName = "AP onClearHandler"
        local function frameCallback()
            ScriptHost:AddWatchForCode("StateChange", "*", StateChanged)
            ScriptHost:RemoveOnFrameHandler(handlerName)
            Tracker.BulkUpdate = false
            ForceUpdate()
            print(string.format("Time taken total: %.2f", os.clock() - clear_timer))
        end
        ScriptHost:AddOnFrameHandler(handlerName, frameCallback)
    else
        Tracker.BulkUpdate = false
        print("Error: onClear failed:")
        print(err)
    end
end

function preOnClear()
    PLAYER_ID = Archipelago.PlayerNumber or -1
	TEAM_NUMBER = Archipelago.TeamNumber or 0
    if Archipelago.PlayerNumber > -1 then
        for key, _ in pairs(Troll_Lookup) do
            if string.find(string.lower(Archipelago:GetPlayerAlias(PLAYER_ID)), key, 1, true) ~= nil then
                TROLL_PLAYER = true
                break
            end
        end
        if #ALL_LOCATIONS > 0 then
            ALL_LOCATIONS = {}
        end
        for _, value in pairs(Archipelago.MissingLocations) do
            table.insert(ALL_LOCATIONS, #ALL_LOCATIONS + 1, value)
        end
        for _, value in pairs(Archipelago.CheckedLocations) do
            table.insert(ALL_LOCATIONS, #ALL_LOCATIONS + 1, value)
        end
        HINTS_ID = "_read_hints_"..TEAM_NUMBER.."_"..PLAYER_ID
        Archipelago:SetNotify({HINTS_ID})
        Archipelago:Get({HINTS_ID})
    end

    local seed_base = (Archipelago.Seed or tostring(#ALL_LOCATIONS)).."_"..Archipelago.TeamNumber.."_"..Archipelago.PlayerNumber
    if ROOM_SEED == "default" or ROOM_SEED ~= seed_base then
        ROOM_SEED = seed_base
        for _, custom_item_code in pairs({"manual_location_storage"}) do
            local custom_storage_item = Tracker:FindObjectForCode(custom_item_code).ItemState
            if custom_storage_item then
                if #custom_storage_item.MANUAL_LOCATIONS > 10 then
                    custom_storage_item.MANUAL_LOCATIONS[custom_storage_item.MANUAL_LOCATIONS_ORDER[1]] = nil
                    table.remove(custom_storage_item.MANUAL_LOCATIONS_ORDER, 1)
                end
                if custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED] == nil then
                    custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED] = {}
                    table.insert(custom_storage_item.MANUAL_LOCATIONS_ORDER, ROOM_SEED)
                end
            end
        end
    end
end

function onClear(slot_data)
    MANUAL_CHECKED = false
    local custom_storage_item = Tracker:FindObjectForCode("manual_location_storage").ItemState
    if custom_storage_item == nil then
        CreateLuaManualStorageItem("manual_location_storage")
        custom_storage_item = Tracker:FindObjectForCode("manual_location_storage").ItemState
    end
    
    preOnClear()
    
    ScriptHost:RemoveWatchForCode("StateChanged")
    ScriptHost:RemoveOnLocationSectionHandler("location_section_change_handler")
    CUR_INDEX = -1
    -- reset locations
    for _, location_array in pairs(LOCATION_MAPPING) do
        for _, location in pairs(location_array) do
            if location then
                local location_obj = Tracker:FindObjectForCode(location)
                if location_obj then
                    if location:sub(1, 1) == "@" then
                        if custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED][location_obj.FullID] then
                            location_obj.AvailableChestCount = custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED][location_obj.FullID]
                        else
                            location_obj.AvailableChestCount = location_obj.ChestCount
                        end
                    else
                        location_obj.Active = false
                    end
                end
            end
        end
    end
    -- reset items
    for _, item_array in pairs(ITEM_MAPPING) do
        for _, item_pair in pairs(item_array) do
            item_code = item_pair[1]
            item_type = item_pair[2]
            local item_obj = Tracker:FindObjectForCode(item_code)
            if item_obj then
                if item_obj.Type == "toggle" then
                    item_obj.Active = false
                elseif item_obj.Type == "progressive" then
                    item_obj.CurrentStage = 0
                elseif item_obj.Type == "consumable" then
                    if item_obj.MinCount then
                        item_obj.AcquiredCount = item_obj.MinCount
                    else
                        item_obj.AcquiredCount = 0
                    end
                elseif item_obj.Type == "progressive_toggle" then
                    item_obj.CurrentStage = 0
                    item_obj.Active = false
                end
            end
        end
    end
    PLAYER_ID = Archipelago.PlayerNumber or -1
    TEAM_NUMBER = Archipelago.TeamNumber or 0
    SLOT_DATA = slot_data
    
    if Archipelago.PlayerNumber > -1 then
        if #ALL_LOCATIONS > 0 then
            ALL_LOCATIONS = {}
        end
        for _, value in pairs(Archipelago.MissingLocations) do
            table.insert(ALL_LOCATIONS, #ALL_LOCATIONS + 1, value)
        end
        for _, value in pairs(Archipelago.CheckedLocations) do
            table.insert(ALL_LOCATIONS, #ALL_LOCATIONS + 1, value)
        end
        HINTS_ID = "_read_hints_"..TEAM_NUMBER.."_"..PLAYER_ID
        Archipelago:SetNotify({HINTS_ID})
        Archipelago:Get({HINTS_ID})
    end
    ScriptHost:AddOnFrameHandler("load handler", OnFrameHandler)
    MANUAL_CHECKED = true
    updateDuelistCounters()
end

function onItem(index, item_id, item_name, player_number)
    if index <= CUR_INDEX then
        return
    end
    local is_local = player_number == Archipelago.PlayerNumber
    CUR_INDEX = index;
    local item = ITEM_MAPPING[item_id]
    if not item or not item[1] then
        return
    end
    for _, item_pair in pairs(item) do
        item_code = item_pair[1]
        item_type = item_pair[2]
        local item_obj = Tracker:FindObjectForCode(item_code)
        if item_obj then
            if item_obj.Type == "toggle" then
                item_obj.Active = true
            elseif item_obj.Type == "progressive" then
                if item_obj.Active == true then
                    item_obj.CurrentStage = item_obj.CurrentStage + 1
                else
                    item_obj.Active = true
                end
            elseif item_obj.Type == "consumable" then
                item_obj.AcquiredCount = item_obj.AcquiredCount + item_obj.Increment * (tonumber(item_pair[3]) or 1)
            elseif item_obj.Type == "progressive_toggle" then
                if item_obj.Active then
                    item_obj.CurrentStage = item_obj.CurrentStage + 1
                else
                    item_obj.Active = true
                end
            end
        else
            print(string.format("onItem: could not find object for code %s", item_code[1]))
        end
    end
    if DUELIST_ITEM_IDS_SET[item_id] then
        updateDuelistCounters()
    end
end

--called when a location gets cleared
function onLocation(location_id, location_name)
    MANUAL_CHECKED = false
    local location_array = LOCATION_MAPPING[location_id]
    if not location_array or not location_array[1] then
        print(string.format("onLocation: could not find location mapping for id %s", location_id))
        return
    end
    for _, location in pairs(location_array) do
        local location_obj = Tracker:FindObjectForCode(location)
        if location_obj then
            if location:sub(1, 1) == "@" then
                location_obj.AvailableChestCount = location_obj.AvailableChestCount - 1
            else
                location_obj.Active = true
            end
        else
            print(string.format("onLocation: could not find location_object for code %s", location))
        end
    end
    MANUAL_CHECKED = true
    if DUELIST_LOCATION_IDS_SET[location_id] then
        updateDuelistCounters()
    end
end

function OnNotify(key, value, old_value)
    print("OnNotify", key, value, old_value)
    if value ~= old_value and key == HINTS_ID then
        Tracker.BulkUpdate = true
        for _, hint in ipairs(value) do
            if hint.finding_player == Archipelago.PlayerNumber then
                if hint.status == 0 then
                    UpdateHints(hint.location, 100+hint.item_flags)
                else
                    UpdateHints(hint.location, hint.status)
                end
            end
        end
        Tracker.BulkUpdate = false
    end
end

function OnNotifyLaunch(key, value)
    if key == HINTS_ID then
        Tracker.BulkUpdate = true
        for _, hint in ipairs(value) do
            if hint.finding_player == Archipelago.PlayerNumber then
                if hint.status == 0 then
                    UpdateHints(hint.location, 100+hint.item_flags)
                else
                    UpdateHints(hint.location, hint.status)
                end
            end
        end
        Tracker.BulkUpdate = false
    end
end

function UpdateHints(locationID, status)
    if Highlight then
        local location_table = LOCATION_MAPPING[locationID]
        for _, location in ipairs(location_table) do
            if location:sub(1, 1) == "@" then
                local obj = Tracker:FindObjectForCode(location)
                if obj then
                    if TROLL_PLAYER and HIGHLIGHT_LEVEL[status] == Highlight.Avoid then
                        obj.Highlight = HIGHLIGHT_LEVEL[30]
                    else
                        obj.Highlight = HIGHLIGHT_LEVEL[status]
                    end
                else
                    print(string.format("No object found for code: %s", location))
                end
            end
        end
    end
end


ScriptHost:AddWatchForCode("yami_yugi_unlock_watch", "free_duelists_defeated", function()
    local goal = 25 -- default fallback
    if SLOT_DATA and SLOT_DATA["g"] and SLOT_DATA["g"]["free_duel_goal"] then
        goal = SLOT_DATA["g"]["free_duel_goal"]
    end
    local defeated_obj = Tracker:FindObjectForCode("free_duelists_defeated")
    local yami = Tracker:FindObjectForCode("yami_yugi")
    if defeated_obj and yami then
        yami.Active = (defeated_obj.AcquiredCount >= goal)
    end
end)

Archipelago:AddClearHandler("clear handler", onClearHandler)
Archipelago:AddItemHandler("item handler", onItem)
Archipelago:AddLocationHandler("location handler", onLocation)
Archipelago:AddSetReplyHandler("notify handler", OnNotify)
Archipelago:AddRetrievedHandler("notify launch handler", OnNotifyLaunch)