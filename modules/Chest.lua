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
            Game.openChest(chest)
            task.wait(Config.chestOpenDelay or 0.4)
        end
    end

    return true
end

return Chest