local ATS2 = getgenv().ATS2
local Utils = ATS2.require("modules/Utils.lua")
local Game = ATS2.require("modules/Game.lua")
local Combat = ATS2.require("modules/Combat.lua")
local Scheduler = ATS2.require("modules/Scheduler.lua")
local Config = ATS2.require("modules/Config.lua")

local AutoDungeonBoss = {}

function AutoDungeonBoss.enter(State)
    Utils.debugPrint(State, "Entering dungeon boss:", State.selectedDungeonBossMap)
    return Game.enterDungeonBoss(State.selectedDungeonBossMap)
end

function AutoDungeonBoss.run(State)
    State.currentMode = "dungeon_boss"

    if not Game.isInDungeonBoss() then
        AutoDungeonBoss.enter(State)
        Utils.safeWait(Config.retryDelay)
    end

    while Game.isInDungeonBoss() do
        if Game.isDungeonBossCleared() then
            Utils.debugPrint(State, "Dungeon boss cleared")
            Scheduler.markDungeonBossDone(State)
            Utils.safeWait(Config.afterBossFinishDelay)
            return true
        end

        Combat.clearAllEnemies(State)
        Utils.safeWait(Config.scanDelay)
    end

    Scheduler.markDungeonBossDone(State)
    return true
end

return AutoDungeonBoss