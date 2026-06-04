function EzModModerationFrame_SetTab(self, tab)
    PanelTemplates_SetTab(self, tab)
    if tab == 1 then
        EzModModerationPanel:Show()
        EzModChatRulesPanel:Hide()
        self.TitleText:SetText(EZMOD_TEXT_MODERATION_TITLE)
    elseif tab == 2 then
        EzModChatRulesPanel:Show()
        EzModModerationPanel:Hide()
        self.TitleText:SetText(EZMOD_TEXT_CHAT_RULES_TITLE)
    end
end


function EzModModerationFrame_OnLoad(self)
    self.numTabs = 2
    table.insert(UISpecialFrames, self:GetName())
end

