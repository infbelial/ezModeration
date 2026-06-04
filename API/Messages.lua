function ezMod:SendMessage(msg)
    --print("[EZMOD] SEND: ", msg)
    SendAddonMessage("ezMod", msg, "WHISPER", GetUnitName("player"))
end


function ezMod:SendRequest(name)
    self.playerData.name = name
    self.error = nil
    self:SendMessage(format("SEARCH:%s;", name))
end


-- Read digits and if 'term' is specified check for terminal symbol at the end of the number
local function ReadNumber(view, term)
    local startpos, endpos = view.str:find("[-+]?%d*%.?%d+", view.startpos)
    if not startpos or startpos ~= view.startpos then
        return nil
    end

    local result = view.str:sub(startpos, endpos)
    view.startpos = endpos + 1

    if term then
        local startpos, endpos = view.str:find(term, view.startpos)
        if startpos ~= view.startpos then
            return nil
        end
        view.startpos = endpos + 1
    end

    return tonumber(result)
end


-- Reads till terminal symbol 'term' is found
local function ReadIdentifier(view, term)
    local startpos = view.startpos
    local termstartpos, termendpos = view.str:find(term, view.startpos)
    if not termstartpos then
        return nil
    end

    local result = view.str:sub(startpos, termstartpos - 1)
    view.startpos = termendpos + 1
    return result, termstartpos
end


local function HandleClick(self)
    if self.value == "EZMOD_MODERATE" then
        EzModModerationPanel_NewSearch(UIDROPDOWNMENU_INIT_MENU.name)
        ShowUIPanel(EzModModerationFrame)
    elseif self.value == "EZMOD_TELEPORT" then
        SendChatMessage(string.format(".goname %s", UIDROPDOWNMENU_INIT_MENU.name), "GUILD")
    end
end

local function EnableModerateButton()
    UnitPopupButtons['EZMOD_MODERATE'] = { text = "Модерировать", dist = 0 }	

    tinsert(UnitPopupMenus["PARTY"],    #UnitPopupMenus["PARTY"] - 1,   "EZMOD_MODERATE")
	tinsert(UnitPopupMenus["FRIEND"],   #UnitPopupMenus["FRIEND"] - 1,  "EZMOD_MODERATE")
	tinsert(UnitPopupMenus["SELF"],     #UnitPopupMenus["SELF"] - 1,    "EZMOD_MODERATE")
	tinsert(UnitPopupMenus["PLAYER"],   #UnitPopupMenus["PLAYER"] - 1,  "EZMOD_MODERATE")
end

local function EnableTeleportButton()
    UnitPopupButtons['EZMOD_TELEPORT'] = { text = "Телепортироваться", dist = 0 }	

    tinsert(UnitPopupMenus["PARTY"],    #UnitPopupMenus["PARTY"] - 1,   "EZMOD_TELEPORT")
	tinsert(UnitPopupMenus["FRIEND"],   #UnitPopupMenus["FRIEND"] - 1,  "EZMOD_TELEPORT")
	tinsert(UnitPopupMenus["SELF"],     #UnitPopupMenus["SELF"] - 1,    "EZMOD_TELEPORT")
	tinsert(UnitPopupMenus["PLAYER"],   #UnitPopupMenus["PLAYER"] - 1,  "EZMOD_TELEPORT")
end


function ezMod:HandleInit(msg)
    local access = ReadNumber(msg, ";")
    if access > 0 then
        EnableModerateButton()
        hooksecurefunc("UnitPopup_OnClick", HandleClick) 
    end
    if access > 1 then
        EnableTeleportButton()
    end
    return true
end


function ezMod:HandleRules(msg)
    local version = ReadNumber(msg, ";")
    if version == nil then
        return false
    end

    local list = C_ezAPI.getBucketData("RULES")
    local map = {}
    for i = 1, #list do
        local rule = list[i]
        map[rule.id] = rule
    end

    ezMod.rules.list = list
    ezMod.rules.map = map
    ezMod.rules.version = version

    EzModChatRulesPanel_Update()
    return true
end


function ezMod:HandleSearchResult(msg)
    local name = ReadIdentifier(msg, ";")
    if name == nil then
        return false
    end

    local playerData = ezMod.playerData

    -- response is too late
    if playerData.name ~= name then
        return true
    end

    local result                = C_ezAPI.getBucketData("SEARCH_RESULT")
    playerData.lastMutes        = result.lastMutes
    playerData.chatHistory      = result.chatHistory
    playerData.muteHistory      = result.muteHistory
    playerData.currentMuteId    = result.currentMuteId
    playerData.currentMuteTimer = result.currentMuteTimer
    EzModModerationPanel_Update()
    return true
end


function ezMod:HandleError(msg)
    local type = ReadIdentifier(msg, ",")
    local name = ReadIdentifier(msg, ",")
    local error = msg.str:sub(msg.startpos, -2)
    if type == nil or name == nil then
        return false
    end

    -- frame already closed or moderated player changed
    if self.playerData.name ~= name then
        return true
    end

    ezMod.error = error
    if type == "MUTE" then
        EzModStatus_UpdateError()
    else
        EzModStatus_Update()
    end
    return true
end


local handlers =
{
    ["INIT"]            = ezMod.HandleInit,
    ["RULES"]           = ezMod.HandleRules,
    ["SEARCH_RESULT"]   = ezMod.HandleSearchResult,
    ["ERROR"]           = ezMod.HandleError,
}


function ezMod:HandleMessage(message)

    --print("[EZMOD] RECV: ", message)

    local handled = false

    local pos = string.find(message, ":")
    local cmd = message
    local args = message

    if pos then
        cmd = string.sub(message, 1, pos - 1)
        args = string.sub(message, pos + 1)
    end

    local handler = handlers[cmd]

    if handler then
        view = { str = args, startpos = 1, endpos = #args }
        handled = handler(self, view)
    end
    
    if not handled then
        print("[EZMOD] Unhandled message: ", message)
    end
end