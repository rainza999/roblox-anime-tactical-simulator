local ATS2 = getgenv().ATS2
local Utils = ATS2.require("modules/Utils.lua")

local Scheduler = {}

function Scheduler.getWindowInfo(State)
    local minute = Utils.getMinuteOfHour()
    local interval = State.bossWindows.intervalMinutes or 10
    local duration = State.bossWindows.durationMinutes or 5

    local bucketStart = math.floor(minute / interval) * interval
    local elapsed = minute - bucketStart
    local isOpen = elapsed < duration

    local hour = tonumber(os.date("%H"))
    local key = string.format("%02d:%02d", hour, bucketStart)

    return {
        minute = minute,
        hour = hour,
        bucketStart = bucketStart,
        elapsed = elapsed,
        isOpen = isOpen,
        key = key,
    }
end

function Scheduler.shouldRunDungeonBoss(State)
    if not State.autoDungeonBoss then
        return false
    end

    local info = Scheduler.getWindowInfo(State)

    if not info.isOpen then
        return false
    end

    if State.lastBossWindowKey ~= info.key then
        State.lastBossWindowKey = info.key
        State.bossDoneInCurrentWindow = false
    end

    if State.bossDoneInCurrentWindow then
        return false
    end

    return true
end

function Scheduler.markDungeonBossDone(State)
    local info = Scheduler.getWindowInfo(State)
    State.lastBossWindowKey = info.key
    State.bossDoneInCurrentWindow = true
end

return Scheduler