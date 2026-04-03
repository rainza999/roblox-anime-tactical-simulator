local ATS2 = getgenv().ATS2
local function shouldStop()
    return ATS2 and ATS2.isStopped and ATS2.isStopped()
end

local Utils = ATS2.require("modules/Utils.lua")
local Game = ATS2.require("modules/Game.lua")
local Combat = ATS2.require("modules/Combat.lua")
local Chest = ATS2.require("modules/Chest.lua")
local Config = ATS2.require("modules/Config.lua")

local AutoRaid = {}

function AutoRaid.enter(State)
    State.raidHasSeenEnemies = false
    State.raidEmptySince = nil
    State.raidEnteredAt = tick()
    State.lastAutoAttackAt = 0

    Utils.debugPrint(State, "Entering raid:", State.selectedRaidMap, State.selectedRaidLevel)
    Game.enterRaid(State.selectedRaidMap, State.selectedRaidLevel)

    local okInstance = Game.waitUntilInRaid(Config.waitInstanceTimeout)
    if not okInstance then
        warn("[AutoRaid] timed out waiting for raid instance")
        return false
    end

    -- รอให้มอนโผล่ก่อน
    local okEnemies = Game.waitForFirstEnemies(Config.waitEnemiesTimeout)
    if okEnemies then
        State.raidHasSeenEnemies = true
    else
        warn("[AutoRaid] no enemies seen yet, will continue polling")
    end

    -- เปิด auto attack หลังเข้า instance แล้ว
    Game.enableAutoAttack()
    State.lastAutoAttackAt = tick()

    return true
end

function AutoRaid.run(State)
    warn("[ATS2/AutoRaid] run start version:", ATS2.Version)

    if shouldStop() then
        return false
    end
    State.currentMode = "raid"

    warn("[AutoRaid] map =", State.raidMap, "level =", State.raidLevel)
    if not Game.isInRaid() then
        local ok = AutoRaid.enter(State)
        if not ok then
            task.wait(Config.retryDelay or 1)
            return false
        end
    end

    while Game.isInRaid() do
        if Game.isRaidCleared(State, Config) then
            Utils.debugPrint(State, "Raid cleared, opening chests...")
            task.wait(Config.postClearDelay or 0.5)
            Chest.openSelectedChests(State)
            task.wait(Config.afterRaidFinishDelay or 1.0)
            return true
        end

        Combat.clearAllEnemies(State)
        task.wait(Config.scanDelay or 0.2)
    end

    return false
end

return AutoRaid