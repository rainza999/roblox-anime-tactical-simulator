local ATS2 = getgenv().ATS2
local function shouldStop()
    return ATS2 and ATS2.isStopped and ATS2.isStopped()
end

local Game = ATS2.require("modules/Game.lua")
local Config = ATS2.require("modules/Config.lua")

local Combat = {}

local function getTargetDistanceFromPlayer(target)
    local char = game.Players.LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hrp = target and target:FindFirstChild("HumanoidRootPart")
    if not root or not hrp then
        return math.huge
    end
    return (root.Position - hrp.Position).Magnitude
end

local function getEnemyName(enemy)
    if not enemy then
        return "nil"
    end
    return enemy.Name or enemy:GetFullName()
end

function Combat.refreshAutoAttack(State)
    if not State.lastAutoAttackAt or (tick() - State.lastAutoAttackAt >= (Config.autoAttackRefresh or 2.0)) then
        warn("[ATS2/Combat] refresh auto attack | version:", ATS2.Version)
        Game.enableAutoAttack()
        State.lastAutoAttackAt = tick()
    end
end

function Combat.getClosestEnemy(State)
    local best = nil
    local bestDist = math.huge

    for _, enemy in ipairs(Game.getEnemies(State)) do
        local dist = getTargetDistanceFromPlayer(enemy)
        if dist < bestDist then
            best = enemy
            bestDist = dist
        end
    end

    if best then
        warn("[ATS2/Combat] getClosestEnemy =>", getEnemyName(best), "| dist:", math.floor(bestDist))
    else
        warn("[ATS2/Combat] getClosestEnemy => nil")
    end

    return best
end

function Combat.waitUntilDeadOrGone(target, timeout, State)
    local started = tick()
    warn("[ATS2/Combat] waitUntilDeadOrGone start | target:", getEnemyName(target), "| version:", ATS2.Version)

    while tick() - started < (timeout or 8) do
        Combat.refreshAutoAttack(State)

        if not target or not target.Parent then
            warn("[ATS2/Combat] target gone:", getEnemyName(target))
            return true
        end

        local hum = target:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            warn("[ATS2/Combat] target dead:", getEnemyName(target))
            return true
        end

        task.wait(0.15)
    end

    warn("[ATS2/Combat] waitUntilDeadOrGone timeout | target:", getEnemyName(target))
    return false
end

function Combat.getNearestEnemy(enemies)
    local player = game:GetService("Players").LocalPlayer
    local char = player and player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not root then
        warn("[ATS2/Combat] getNearestEnemy => no player root")
        return nil
    end

    local best = nil
    local bestDist = math.huge

    for _, enemy in ipairs(enemies) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        local hrp = enemy:FindFirstChild("HumanoidRootPart")

        if hum and hum.Health > 0 and hrp then
            local dist = (root.Position - hrp.Position).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = enemy
            end
        end
    end

    if best then
        warn("[ATS2/Combat] getNearestEnemy =>", best.Name, "| dist:", math.floor(bestDist))
    else
        warn("[ATS2/Combat] getNearestEnemy => nil (no alive enemies)")
    end

    return best
end

function Combat.clearAllEnemies(State)
    warn("[ATS2/Combat] clearAllEnemies start | version:", ATS2.Version)

    local currentTarget = nil
    local stopDistance = Config.attackStopDistance or 6
    local repathDelay = Config.attackRepathDelay or 0.12
    local lastMoveAt = 0

    while true do
        if shouldStop() then
            warn("[ATS2/Combat] STOP break")
            return false
        end

        Combat.refreshAutoAttack(State)

        local enemies = Game.getEnemies(State)
        if #enemies == 0 then
            warn("[ATS2/Combat] no enemies found")
            return true
        end

        local hum = currentTarget and currentTarget:FindFirstChildOfClass("Humanoid")
        local deadOrInvalid = (not currentTarget)
            or (not currentTarget.Parent)
            or (not hum)
            or (hum.Health <= 0)

        if deadOrInvalid then
            local oldName = currentTarget and currentTarget.Name or "nil"
            currentTarget = Combat.getNearestEnemy(enemies)
            local newName = currentTarget and currentTarget.Name or "nil"
            warn("[ATS2/Combat] retarget | old:", oldName, "-> new:", newName)
        end

        hum = currentTarget and currentTarget:FindFirstChildOfClass("Humanoid")
        if not currentTarget or not hum or hum.Health <= 0 then
            currentTarget = Combat.getNearestEnemy(enemies)
        end

        hum = currentTarget and currentTarget:FindFirstChildOfClass("Humanoid")
        if currentTarget and hum and hum.Health > 0 then
            local dist = getTargetDistanceFromPlayer(currentTarget)

            if dist > stopDistance then
                if tick() - lastMoveAt >= repathDelay then
                    Game.attackTarget(currentTarget)
                    lastMoveAt = tick()
                end
            else
                -- ถึงระยะแล้ว ไม่ต้องสั่งเดินซ้ำ
                -- ปล่อยให้ auto attack ทำงานไป
            end
        end

        task.wait(0.03)
    end
end

return Combat