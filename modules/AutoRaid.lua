local ATS2 = getgenv().ATS2
local Game = ATS2.require("modules/Game.lua")
local Combat = ATS2.require("modules/Combat.lua")
local Chest = ATS2.require("modules/Chest.lua")

local AutoRaid = {}

function AutoRaid.run(State)
    warn("[ATS2/AutoRaid] run start version:", ATS2.Version)
    warn("[AutoRaid] map =", State.raidMap, "level =", State.raidLevel)

    if not Game.isInRaid() then
        Game.enterRaid(State.raidMap, State.raidLevel)

        local ok = Game.waitUntilInRaid(15)
        if not ok then
            warn("[AutoRaid] timed out waiting for raid instance")
            return false
        end

        Game.waitForFirstEnemies(8, State)
    end

    while Game.isInRaid() do
        if Game.isRaidCleared and Game.isRaidCleared(State, State) then
            task.wait(0.5)
            Chest.openSelected(State)
            return true
        end

        Combat.clearAllEnemies(State)
        task.wait(0.2)
    end

    return true
end

return AutoRaid