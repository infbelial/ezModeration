SLASH_EZMOD1 = "/ezmod"
SLASH_EZMOD2 = "/ezm"

SlashCmdList["EZMOD"] = function(msg)
    ShowUIPanel(EzModModerationFrame)
    EzModModerationPanel_NewSearch(msg)
end

local addon = CreateFrame("Frame", nil, UIParent)

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("CHAT_MSG_ADDON")
addon:RegisterEvent("ADDON_LOADED")

local function ShowWarning()
    StaticPopupDialogs["EZMODERATION_ADDON_WARNING"] = {
	    text = EZMOD_TEXT_ADDON_WARNING,
	    button1 = OKAY,
	    button2 = nil,
	    OnAccept = function() end,
	    hideOnEscape = 1,
	    timeout = 0,
	    exclusive = 1,
	    whileDead = 1,
    }
    StaticPopup_Show("EZMODERATION_ADDON_WARNING")
end


addon:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        ezMod:SendMessage(string.format("INIT:%d;", ezMod.rules.version))
    elseif event == "ADDON_LOADED" then
        local name = ...
        if name == "ezModeration" then
            ezMod:Init()
            EzModChatRulesPanel_Update()
        elseif name == "SMARTModeration2" then
            ShowWarning()
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        
        if prefix == "ezMod" then
            ezMod:HandleMessage(message)
        end
    end
end)

