warn("### AUTORAID FILE NEW BUILD 15:10 ###")
local ATS2 = getgenv().ATS2
local Game = ATS2.require("modules/Game.lua")
local Combat = ATS2.require("modules/Combat.lua")
local Chest = ATS2.require("modules/Chest.lua")

local AutoRaid = {}

function AutoRaid.run(State)
    warn("[ATS2/AutoRaid] run start version:", ATS2.Version)
    warn("[AutoRaid] map =", State.raidMap, "level =", State.raidLevel)
    warn("### AUTORAID.RUN NEW ###", State.raidMap, State.raidLevel)
    if not Game.isInRaid() then
        Game.enterRaid(State.raidMap, State.raidLevel)

        local ok = Game.waitUntilInRaid(15)
        if not ok then
            warn("[AutoRaid] timed out waiting for raid instance")
            return false
        end
    end

    -- 🔥 phase 1: เคลียร์มอน
    while true do
        local enemies = Game.getEnemies(State)

        if #enemies == 0 then
            warn("[AutoRaid] no enemies left")
            break
        end

        Combat.clearAllEnemies(State)
        task.wait()
    end

    -- 🔥 phase 2: รอกล่อง (สำคัญมาก)
    warn("[AutoRaid] waiting for reward chests")

    local started = tick()
    local chestOpened = false

    while tick() - started < 10 do
        local chests = Game.getRewardChests()

        if #chests > 0 then
            warn("[AutoRaid] chests found:", #chests)

            Chest.openSelected(State)
            chestOpened = true
            break
        end

        task.wait(0.2)
    end

    if not chestOpened then
        warn("[AutoRaid] no chests found after timeout")
    end

    return true
end

return AutoRaid