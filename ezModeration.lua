SLASH_EZMOD1 = "/ezmod"
SLASH_EZMOD2 = "/ezm"

SlashCmdList["EZMOD"] = function(msg)
    if msg == "show" or msg == "" then
        ShowUIPanel(EzModModerationFrame)
    elseif msg == "hide" then
        HideUIPanel(EzModModerationFrame)
    elseif msg == "rules" then
        ShowUIPanel(EzModModerationFrame)
        EzModModerationFrame_SetTab(EzModModerationFrame, 2)
    else
        if msg:sub(1, 3) == "mod" then
            EzModModerationPanel_NewSearch(msg:sub(5))
        else
            print(EZMOD_TEXT_USAGE)
        end
    end
end

local addon = CreateFrame("Frame", nil, UIParent)

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("CHAT_MSG_ADDON")
addon:RegisterEvent("ADDON_LOADED")

addon:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        ezMod:SendMessage(string.format("INIT:%d;", ezMod.rules.version))
    elseif event == "ADDON_LOADED" then
        local name = ...
        if name == "ezModeration" then
            ezMod:Init()
            EzModChatRulesPanel_Update()
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        
        if prefix == "ezMod" then
            ezMod:HandleMessage(message)
        end
    end
end)

