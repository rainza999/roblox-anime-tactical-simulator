warn("### CHEST MODULE LOADED ###")
local ATS2 = getgenv().ATS2
local Game = ATS2.require("modules/Game.lua")

local Chest = {}

function Chest.openSelected(State)
    local chests = Game.getRewardChests()

    if #chests == 0 then
        warn("[ATS2] no chests to open")
        return false
    end

    for _, chest in ipairs(chests) do
        warn("[ATS2] opening chest:", chest.Name)
        Game.openChest(chest)
        task.wait(0.15)
    end

    return true
end

return Chest