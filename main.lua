local ATS2 = getgenv().ATS2
local State = ATS2.require("modules/State.lua")
local Utils = ATS2.require("modules/Utils.lua")
local Lock = ATS2.require("modules/ControllerLock.lua")
local Scheduler = ATS2.require("modules/Scheduler.lua")
local AutoRaid = ATS2.require("modules/AutoRaid.lua")
local AutoDungeonBoss = ATS2.require("modules/AutoDungeonBoss.lua")
local UI = ATS2.require("modules/UI.lua")

local Main = {}

local function shouldStop()
    return ATS2 and ATS2.isStopped and ATS2.isStopped()
end

local function mainLoop()
    warn("[ATS2] mainLoop start version:", ATS2.Version)

    while State.running do
        if shouldStop() then
            State.currentMode = "stopped"
            State.stopReason = "global stop requested"
            warn("[ATS2] mainLoop STOP")
            break
        end

        local wantBoss = Scheduler.shouldRunDungeonBoss(State)

        if wantBoss then
            if Lock.tryAcquire(State, "DungeonBoss", "Boss window open") then
                Utils.debugPrint(State, "Boss window active @", Utils.getClockString())

                local ok, err = pcall(function()
                    AutoDungeonBoss.run(State)
                end)

                if not ok then
                    warn("[ATS2] AutoDungeonBoss error:", err)
                end

                Lock.release(State, "DungeonBoss")
            end

        elseif State.autoRaid then
            if Lock.tryAcquire(State, "Raid", "Normal raid loop") then
                local ok, err = pcall(function()
                    AutoRaid.run(State)
                end)

                if not ok then
                    warn("[ATS2] AutoRaid error:", err)
                end

                Lock.release(State, "Raid")
            end
        else
            State.currentMode = "idle"
            Utils.safeWait(0.5)
        end

        Utils.safeWait(State.tickRate or 0.25)
    end

    State.running = false
    warn("[ATS2] mainLoop exited")
end

function Main.init()
    if State.running then
        warn("[ATS2] already running")
        return
    end

    if ATS2 and ATS2.resume then
        ATS2.resume()
    end

    State.running = true
    UI.init()
    Utils.debugPrint(State, "Main init done", ATS2.Version)

    task.spawn(function()
        mainLoop()
    end)
end

function Main.stop(reason)
    State.stopReason = reason or "manual stop"
    if ATS2 and ATS2.stop then
        ATS2.stop(State.stopReason)
    else
        State.running = false
    end
end

return Main