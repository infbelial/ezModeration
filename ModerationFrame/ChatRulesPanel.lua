function EzModChatRulesPanel_OnLoad(self)
    -- workaround, this is loaded last, so we can call it here
    EzModModerationFrame_SetTab(self:GetParent(), 1)
end

function EzModChatRulesPanel_Update()
    local content = EzModChatRulesContent
    local children = { content:GetChildren() }

    local previous = nil

    local i = 1
    while i <= #ezMod.rules.list do
        local ruleFrame = children and children[i] or nil
        if ruleFrame == nil then
            ruleFrame = CreateFrame("Frame", "EzModChatRule"..tostring(i), content, "EzModChatRuleTemplate")
            if previous then
                ruleFrame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -5)        
            else
                ruleFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -4)
            end
        end

        local entry = ezMod.rules.list[i]
        local header = string.format("%s %s", entry.ruleNum, entry.descShort)
        local details = entry.descDetails
        if entry.publicOnly then
            details = string.format("%s\n|cFFFFD100%s|r.", details, EZMOD_TEXT_PUBLIC_MUTE)
        end
        local warning = "Нет"
        if entry.warning then
            warning = "Да"
        end

        ruleFrame.name:SetText(header)
        ruleFrame.details:SetText(details)
        ruleFrame.details:SetWidth(660)
        ruleFrame.baseTime:SetText(string.format("%s: |cFFFFD100%d минут|r", EZMOD_TEXT_BASIC_MUTE_TIME, entry.penaltyTime))
        ruleFrame.warning:SetText(string.format("%s: |cFFFFD100%s|r", EZMOD_TEXT_WARNING, warning))
        
        local height = ruleFrame.name:GetHeight() + ruleFrame.details:GetHeight() + ruleFrame.baseTime:GetHeight() + ruleFrame.warning:GetHeight() + 5 * 5
        ruleFrame:SetHeight(height)

        previous = ruleFrame
        i = i + 1
    end

    -- in case rule got deleted, ig
    if children then
        while i <= #children do
            children[i]:Hide()
            i = i + 1
        end
    end
end