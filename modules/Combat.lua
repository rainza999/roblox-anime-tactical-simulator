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

function Combat.refreshAutoAttack(State)
    if not State.lastAutoAttackAt or (tick() - State.lastAutoAttackAt >= (Config.autoAttackRefresh or 2.0)) then
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

    return best
end

function Combat.waitUntilDeadOrGone(target, timeout, State)
    local started = tick()

    while tick() - started < (timeout or 8) do
        Combat.refreshAutoAttack(State)

        if not target or not target.Parent then
            return true
        end

        local hum = target:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            return true
        end

        task.wait(0.15)
    end

    return false
end

function Combat.getNearestEnemy(enemies)
    local root = game:GetService("Players").LocalPlayer.Character
        and game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if not root then
        return nil
    end

    local best = nil
    local bestDist = math.huge

    for _, enemy in ipairs(enemies) do
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dist = (root.Position - hrp.Position).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = enemy
            end
        end
    end

    return best
end

function Combat.clearAllEnemies(State)
    warn("[ATS2/Combat] clearAllEnemies start version:", ATS2.Version)
    while true do
        if shouldStop() then
            warn("[ATS2/Combat] STOP break")
            return false
        end
        Combat.refreshAutoAttack(State)

        local enemies = Game.getEnemies(State)
        if #enemies == 0 then
            return true
        end

        -- ถ้า target เดิมตายหรือหาย → หาใหม่ทันที
        if not currentTarget 
        or not currentTarget.Parent 
        or not currentTarget:FindFirstChildOfClass("Humanoid")
        or currentTarget:FindFirstChildOfClass("Humanoid").Health <= 0 then

            currentTarget = Combat.getNearestEnemy(enemies)
        end

        if currentTarget then
            Game.attackTarget(currentTarget)
        end

        task.wait() -- ⚡ 1 frame (เร็วสุด)
    end
end

return Combat