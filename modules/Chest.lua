local ATS2 = getgenv().ATS2
local Utils = ATS2.require("modules/Utils.lua")
local Game = ATS2.require("modules/Game.lua")
local Config = ATS2.require("modules/Config.lua")

local Chest = {}

function Chest.openSelectedChests(State)
    local selected = State.selectedChests or {}
    if #selected == 0 then
        return true
    end

    for _, chestName in ipairs(selected) do
        local chest = Game.getNamedChest(chestName)
        if chest then
            Utils.tpTo(chest)
            Utils.safeWait(0.15)
            Game.openChest(chest)
            Utils.safeWait(Config.chestOpenDelay)
        end
    end

    return true
end

function Chest.openAllChestsFallback()
    local all = Game.getRewardChests()
    for _, chest in ipairs(all) do
        Utils.tpTo(chest)
        Utils.safeWait(0.15)
        Game.openChest(chest)
        Utils.safeWait(0.35)
    end
end

return Chest