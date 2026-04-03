local ATS2 = getgenv().ATS2
local Utils = ATS2.require("modules/Utils.lua")
local Game = ATS2.require("modules/Game.lua")
local Combat = ATS2.require("modules/Combat.lua")
local Chest = ATS2.require("modules/Chest.lua")
local Config = ATS2.require("modules/Config.lua")

local AutoRaid = {}

function AutoRaid.enter(State)
    Utils.debugPrint(State, "Entering raid:", State.selectedRaidMap, State.selectedRaidLevel)
    return Game.enterRaid(State.selectedRaidMap, State.selectedRaidLevel)
end

function AutoRaid.run(State)
    State.currentMode = "raid"

    if not Game.isInRaid() then
        AutoRaid.enter(State)
        Utils.safeWait(Config.retryDelay)
    end

    while Game.isInRaid() do
        if Game.isRaidCleared() then
            Utils.debugPrint(State, "Raid cleared, opening selected chests...")
            Utils.safeWait(Config.postClearDelay)
            Chest.openSelectedChests(State)
            Utils.safeWait(Config.afterRaidFinishDelay)
            return true
        end

        Combat.clearAllEnemies(State)
        Utils.safeWait(Config.scanDelay)
    end

    return true
end

return AutoRaid