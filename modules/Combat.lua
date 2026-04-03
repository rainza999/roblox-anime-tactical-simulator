local ATS2 = getgenv().ATS2
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

function Combat.clearAllEnemies(State)
    while true do
        Combat.refreshAutoAttack(State)

        local enemies = Game.getEnemies(State)
        if #enemies == 0 then
            return true
        end

        local target = Combat.getClosestEnemy(State)
        if target then
            Game.attackTarget(target)
            Combat.waitUntilDeadOrGone(target, 10, State)
        else
            task.wait(0.2)
        end
    end
end

return Combat