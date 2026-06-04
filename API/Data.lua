local dummyPlayerData =
{
    lastMutes = {},
    chatHistory = {},
    muteHistory = {},
}

ezMod = 
{
    rules = nil,
    error = nil,
    playerData = {},
}


function ezMod:Init()
    --ezModCache = nil
    self:InitCache()
    self:ResetPlayerData()
end


function ezMod:InitCache()
    if ezModCache == nil then
        ezModCache = {}
        ezModCache.rules = {}
        ezModCache.rules.list = {}
        ezModCache.rules.map = {}
        ezModCache.rules.version = 0
    end

    ezMod.rules = ezModCache.rules
end


function ezMod:ResetPlayerData()
    local playerData = self.playerData
    playerData.name             = ""
    playerData.currentMuteId    = 0
    playerData.currentMuteTimer = 0
    -- premature optimisation but whatever, just staying in tune with the 20 year old client
    -- however, what is not an optimisation is that it should not be nil
    playerData.lastMutes        = dummyPlayerData.lastMutes
    playerData.chatHistory      = dummyPlayerData.chatHistory
    playerData.muteHistory      = dummyPlayerData.muteHistory
end


function ezMod:GetMuteInfo(id)
    local muteHistory = self.playerData.muteHistory
    for i = 1, #muteHistory do
        local mute = muteHistory[i]
        if mute.id == id then
            return mute
        end
    end
    return nil
end
