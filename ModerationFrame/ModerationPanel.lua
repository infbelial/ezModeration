local maxMuteTime = 24 * 60
local consecutiveMultipier = 2

local COLLAPSED_BUTTON_HEIGHT = 40
local EXPANDED_BUTTON_HEIGHT = 80

function EzModModerationPanel_OnLoad(self)
    StaticPopupDialogs["EZMODERATION_UNMUTE"] = {
	    text = EZMOD_TEXT_UNMUTE_CONFIRM,
	    button1 = YES,
	    button2 = NO,
	    OnAccept = function()
            SendChatMessage(string.format(".unmute %s", ezMod.playerData.name), "GUILD");
        end,
	    hideOnEscape = 1,
	    timeout = 0,
	    exclusive = 1,
	    whileDead = 1,
    }
end


function EzModModerationPanel_OnHide(self)
    self.input.search:SetText("")
    ezMod:ResetPlayerData()
end


function EzModModerationPanel_LoadingStart()
    EzModStatus.preview:SetText(EZMOD_TEXT_LOADING)
    EzModStatus.currentMute:SetText(EZMOD_TEXT_LOADING)
end


function EzModModerationPanel_NewSearch(name)
    local self = EzModModerationPanel
    self.input.search:SetText(name)

    ezMod:ResetPlayerData()
    ezMod:SendRequest(name)

    EzModModerationPanel_LoadingStart()
    EzModChatHistory_Update()
    EzModMuteHistory_ResetSelection()
    EzModMuteHistory_Update()
end


function EzModModerationPanel_Update()
    EzModStatus_Update()
    EzModChatHistory_Update()
    EzModMuteHistory_ResetSelection()
    EzModMuteHistory_Update()
end


local function MakeIdDigits(id)
    local firstDigset = math.floor(id / 1000)
    local secondDigset = id % 1000
    return firstDigset, secondDigset
end


------------------- INPUT -------------------
function EzModInputSearch_OnLoad(self)
    self:SetAutoFocus(false)
end


function EzModInputSearch_OnEnterPressed(self)
    ezMod:ResetPlayerData()
    
    if self:GetText() ~= "" then
        ezMod:SendRequest(self:GetText())
        EzModModerationPanel_LoadingStart()
    else
        EzModStatus_Update()
    end

    EzModChatHistory_Update()
    EzModMuteHistory_ResetSelection()
    EzModMuteHistory_Update()
    self:ClearFocus()
end


function EzModInputRuleSelect_Init(self)
    for i = 1, #ezMod.rules.list do
        local entry = ezMod.rules.list[i]
        local info  = UIDropDownMenu_CreateInfo()

        info.text = string.format("%s %s", entry.ruleNum, entry.descShort)
        info.value = i
        info.func = function() 
            UIDropDownMenu_SetSelectedID(self, i, false)
            EzModStatus_Update()
        end
        UIDropDownMenu_AddButton(info);
    end
end


function EzModInputRuleSelect_OnLoad(self)
    UIDropDownMenu_SetWidth(self, 228)
    UIDropDownMenu_SetSelectedID(self, 1, false)
end


function EzModInputRuleSelect_OnShow(self)
    UIDropDownMenu_Initialize(self, EzModInputRuleSelect_Init)
    UIDropDownMenu_Refresh(self, false, 1)
end


function EzModInputMuteButton_OnClick()
    local i = UIDropDownMenu_GetSelectedID(EzModInputRuleSelect)
    local rule = ezMod.rules.list[i]
    SendChatMessage(string.format(".mutenew %s %s", ezMod.playerData.name, rule.ruleNum), "GUILD")
    TakeScreenshot()
end


function EzModUnmuteButton_OnClick()
    StaticPopup_Show("EZMODERATION_UNMUTE")
end


------------------- STATUS -------------------

function EzModStatus_UpdateError()
    if ezMod.error ~= nil then
        EzModStatus.preview:SetText(ezMod.error)
    end
end


function EzModStatus_Update()
    local self = EzModStatus
    local playerData = ezMod.playerData

    self.currentMute:SetText("|cFF00FF00Нет|r")
    self.unmuteButton:Hide()

    if ezMod.error ~= nil then
        EzModStatus_UpdateError()
    elseif playerData.name == "" then
        self.preview:SetText("Введите имя для поиска")
    else
        local i = UIDropDownMenu_GetSelectedID(EzModInputRuleSelect)
        local rule = ezMod.rules.list[i]
        local consecutiveViolations = playerData.lastMutes[rule.id]

        -- 1 - Warning / first violation
        -- 2 - Repeated violation
        -- N - Repeated violation #(N - 1)

        -- TODO: warning time is a config value, probable should send it to the client
        local muteTimeMinutes = 1
        local muteType = "Предупреждение"

        -- consecutiveViolations == 0 should never happen
        if consecutiveViolations == nil then
            if not rule.warning then
                muteTimeMinutes = rule.penaltyTime
                muteType = "Первое нарушение"
            end
        else
            -- So if we have consecutiveViolations it mean that player was already muted once
            -- Here it doesn't matter was it warning or not - type will be "repeated violation" or "repeated violation #N"
            if consecutiveViolations == 1 then
                muteType = "Повторное нарушение"
            else
                muteType = string.format("Повторное нарушение #%d", consecutiveViolations)
            end

            -- however for time, if first was warning we should use nominal time, otherwise increase it
            local newNonWarningViolationCount = consecutiveViolations
            if not rule.warning then
                nonWarningViolations = consecutiveViolations + 1
            end

            -- TODO: multipier is also a config value
            muteTimeMinutes = rule.penaltyTime * (consecutiveMultipier ^ (newNonWarningViolationCount))
        end

        -- however, maxMuteTime is hardcoded, so whatever, ig
        if muteTimeMinutes > maxMuteTime then
            muteTimeMinutes = maxMuteTime
        end

        self.preview:SetText(string.format("%s\n%d |4минута:минуты:минут;", muteType, muteTimeMinutes))

        local timeInSeconds = ezMod.playerData.currentMuteTimer
        if timeInSeconds > 0 then
            local hours = math.floor(timeInSeconds / 3600)
            local minutes = math.floor((timeInSeconds % 3600) / 60)
            local mute = ezMod:GetMuteInfo(ezMod.playerData.currentMuteId)
            local ruleStr = ""
            local rule = ezMod.rules.map[mute.violationId]
            if rule then
                ruleStr = string.format(", пункт %s", rule.ruleNum)
            end

            local firstDigset, secondDigset = MakeIdDigits(mute.id)

            if hours > 0 then
                muteStatus = string.format("|cFFFF0000%u |4час:часа:часов; %u |4минута:минуты:минут;%s, ID: %d-%d|r", hours, minutes, ruleStr, firstDigset, secondDigset)
            else
                muteStatus = string.format("|cFFFF0000%u |4минута:минуты:минут;%s, ID: %d-%d|r", minutes, ruleStr, firstDigset, secondDigset)
            end
            self.currentMute:SetText(muteStatus)
            self.unmuteButton:Show()
        end
    end
end


------------------- CHAT HISTORY -------------------
function EzModChatHistory_Update()
    local self = EzModChatHistory;
    local content = self.content

    content:Clear()

    local history = ezMod.playerData.chatHistory

    for i=1, #history do
        local msg = history[i]
        local dateStr = date("%m/%d %H:%M", msg.date)
        content:AddMessage(string.format("[%s] [%s]: %s", dateStr, msg.channel, msg.text))
    end

    local scrollBar = content.scrollBar
    
    local max = content:GetNumMessages()
    local min = math.min(content:GetNumLinesDisplayed(), max)

    scrollBar:SetMinMaxValues(min, max)
    scrollBar:SetValueStep(1)
    scrollBar:SetValue(max)

    EzModChatHistory_UpdateButtons()
end


function EzModChatHistory_OnLoad(self)
    self:SetFading(false)
    self:SetInsertMode("BOTTOM")
    self:SetMaxLines(300)

    self.SetVerticalScroll = function(self, value)
        self:SetScrollOffset(select(2, self.scrollBar:GetMinMaxValues()) - value)
        EzModChatHistory_UpdateButtons()
    end

    self.scrollBar:SetValueStep(1)
end


function EzModChatHistory_OnScroll(self, delta)
    local scrollBar = self.scrollBar
    local newValue = scrollBar:GetValue() - delta

    local min, max = scrollBar:GetMinMaxValues()
    newValue = math.max(min, math.min(max, newValue))
    scrollBar:SetValue(newValue)
end

function EzModChatHistory_UpdateButtons()
    local self = EzModChatHistory;
    local scrollBar = self.content.scrollBar

    local min, max = scrollBar:GetMinMaxValues()
    local value = scrollBar:GetValue()

    local downButton = _G[scrollBar:GetName().."ScrollDownButton"]
    local upButton = _G[scrollBar:GetName().."ScrollUpButton"]

    if value == max then
        downButton:Disable()
    else
        downButton:Enable()
    end
    if value == min then
        upButton:Disable()
    else
        upButton:Enable()
    end

    if downButton:IsEnabled() == 0 and upButton:IsEnabled() == 0 then
        _G[scrollBar:GetName().."ThumbTexture"]:Hide()
    else
        _G[scrollBar:GetName().."ThumbTexture"]:Show()
    end
end


------------------- MUTE HISTORY -------------------
function EzModMuteHistory_OnLoad(self)
    self.update = EzModMuteHistory_Update;
    HybridScrollFrame_CreateButtons(self, "EzModMuteHistoryEntryTemplate", 0, 0)
    self.update()
end


function EzModMuteHistory_ResetSelection()
    EzModMuteHistoryContent.selection = nil
end


function EzModMuteHistory_Update()
    local numMutes = 0
    if ezMod.playerData.muteHistory then
        numMutes = #ezMod.playerData.muteHistory
    end

    local scrollFrame = EzModMuteHistoryContent
    local offset = HybridScrollFrame_GetOffset(scrollFrame);
    local buttons = scrollFrame.buttons
    local numButtons = #buttons

    local muteIndex = 0
    local displayedHeight = 0
    local extraHeight = scrollFrame.largeButtonHeight or 40

    local selectionId = scrollFrame.selection

    for i = 1, numButtons do
        muteIndex = i + offset
        if (muteIndex > numMutes) then
            buttons[i]:Hide();
        else
            EzModMuteHistory_DisplayMute(buttons[i], muteIndex, selectionId)
            displayedHeight = displayedHeight + buttons[i]:GetHeight();
        end
    end

    local totalHeight = 40 * numMutes + (extraHeight - 40)

    HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight)
end


function EzModMuteHistory_DisplayMute(button, muteIndex, selectionId)

    local mute = ezMod.playerData.muteHistory[muteIndex]
    
    local rules = ezMod.rules.map

    button.index = muteIndex

    if mute.id ~= button.id then
        local date = date("%Y-%m-%d %H:%M", mute.date)
        local firstDigset, secondDigset = MakeIdDigits(mute.id)

        local rule = nil
        if mute.violationId then
            rule = rules[mute.violationId]
        end

        local muteType = ""
        if rule ~= nil then
            if mute.consecutive == 1 then
                if rule.warning then
                    muteType = "Предупреждение "
                else
                    muteType = "Первое нарушение "
                end
            elseif mute.consecutive == 2 then
                muteType = "Повторное нарушение "
            elseif mute.consecutive ~= 0 then -- technically 0 shouldn't happen then rule exist
                muteType = string.format("Повторное нарушение #%d ", mute.consecutive - 1)
            end
        end

        local active = ""
        if ezMod.playerData.currentMuteId == mute.id then
            active = " |cFFFF0000(Активен)|r"
        end

        button.header:SetText(string.format("[%s] %s%d мин%s, |cFFFFFFFF%s|r, от: |cFFFFFFFF%s|r, ID: %03d-%03d", date, muteType, mute.time, active, mute.muteChar, mute.mutedBy, firstDigset, secondDigset))

        local reason = mute.reason
        if rule then
            reason = string.format("%s %s", rule.ruleNum, mute.reason)
        end
        button.reason:SetText(reason)
        button.id = mute.id
    end
    if selectionId ~= nil and button.id == selectionId then
        button.selected = true
        button.highlight:Show()
    else
        button.selected = false
        button.highlight:Hide()
    end
    button:Show()
end


local function AdjustSelection()
    local scrollFrame = EzModMuteHistoryContent
    local scrollBar = EzModMuteHistoryContentScrollBar

	local selectedButton
	for _, button in next, scrollFrame.buttons do
		if button.selected then
			selectedButton = button;
			break;
		end
	end	
	
	if selectedButton then
		local newHeight;
		if selectedButton:GetTop() > scrollFrame:GetTop() then
    		newHeight = scrollBar:GetValue() + scrollFrame:GetTop() - selectedButton:GetTop()
		elseif selectedButton:GetBottom() < scrollFrame:GetBottom() then
			if selectedButton:GetHeight() > scrollFrame:GetHeight() then
				newHeight = scrollBar:GetValue() + scrollFrame:GetTop() - selectedButton:GetTop()
			else
				newHeight = scrollBar:GetValue() + scrollFrame:GetBottom() - selectedButton:GetBottom()
			end
		end
		if newHeight then
			local _, maxVal = scrollBar:GetMinMaxValues()
			newHeight = min(newHeight, maxVal)
			scrollBar:SetValue(newHeight)			
		end
	end
end


function EzModMuteHistoryEntry_OnClick(self)
    local scrollFrame = EzModMuteHistoryContent
    if self.selected then
        scrollFrame.selection = nil
        self.highlight:Hide()
    else
        scrollFrame.selection = self.id
        self.highlight:Show()
    end
    EzModMuteHistory_Update()
    AdjustSelection()
end

