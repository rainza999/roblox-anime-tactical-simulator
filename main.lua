local ATS2 = getgenv().ATS2

local State = ATS2.require("modules/State.lua")
local Utils = ATS2.require("modules/Utils.lua")
local Lock = ATS2.require("modules/ControllerLock.lua")
local Scheduler = ATS2.require("modules/Scheduler.lua")
local AutoRaid = ATS2.require("modules/AutoRaid.lua")
local AutoDungeonBoss = ATS2.require("modules/AutoDungeonBoss.lua")
local UI = ATS2.require("modules/UI.lua")

local Main = {}

local function mainLoop()
    while State.running do
        local wantBoss = Scheduler.shouldRunDungeonBoss(State)

        if wantBoss then
            if Lock.tryAcquire(State, "DungeonBoss", "Boss window open") then
                Utils.debugPrint(State, "Boss window active @", Utils.getClockString())
                pcall(function()
                    AutoDungeonBoss.run(State)
                end)
                Lock.release(State, "DungeonBoss")
            end
        elseif State.autoRaid then
            if Lock.tryAcquire(State, "Raid", "Normal raid loop") then
                pcall(function()
                    AutoRaid.run(State)
                end)
                Lock.release(State, "Raid")
            end
        else
            State.currentMode = "idle"
            Utils.safeWait(0.5)
        end

        Utils.safeWait(State.tickRate)
    end
end

function Main.init()
    if State.running then
        warn("[ATS2] already running")
        return
    end

    State.running = true
    UI.init()

    Utils.debugPrint(State, "Main init done")

    task.spawn(function()
        mainLoop()
    end)
end

return Main