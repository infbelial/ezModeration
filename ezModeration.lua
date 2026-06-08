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

local original = nil

-- logic copied from previous adddon
local function HandleNameClick(link, text, button)
	local linkType = string.sub(link, 1, string.find(link, ':') - 1)
	
	if IsAltKeyDown() then
		if linkType == 'player' then
			local name = strsplit(':', string.sub(link, 8))
			if name and name:len() > 0 then
				local begin = name:find('%s[^%s]+$')
				if begin then
					name = name:sub(begin + 1)
				end
                ShowUIPanel(EzModModerationFrame)
                EzModModerationPanel_NewSearch(name)
			end
		end
	else
		original(link, text, button)
	end
end


addon:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        ezMod:SendMessage(string.format("INIT:%d;", ezMod.rules.version))
    elseif event == "ADDON_LOADED" then
        local name = ...
        if name == "ezModeration" then
            ezMod:Init()
            EzModChatRulesPanel_Update()
            original = SetItemRef
            SetItemRef = HandleNameClick
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

