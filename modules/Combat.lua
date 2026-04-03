local ATS2 = getgenv().ATS2
local Game = ATS2.require("modules/Game.lua")
local Config = ATS2.require("modules/Config.lua")

local Combat = {}

function Combat.getClosestEnemy()
    local char = game.Players.LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end

    local best, bestDist = nil, math.huge

    for _, enemy in ipairs(Game.getEnemies()) do
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dist = (root.Position - hrp.Position).Magnitude
            if dist < bestDist then
                best = enemy
                bestDist = dist
            end
        end
    end

    return best
end

function Combat.refreshAutoAttack(State)
    if not State.lastAutoAttackAt or (tick() - State.lastAutoAttackAt >= (Config.autoAttackRefresh or 2.0)) then
        Game.enableAutoAttack()
        State.lastAutoAttackAt = tick()
    end
end

function Combat.clearAllEnemies(State)
    while true do
        Combat.refreshAutoAttack(State)

        local enemies = Game.getEnemies()
        if #enemies == 0 then
            return true
        end

        local target = Combat.getClosestEnemy()
        if target then
            Game.attackTarget(target)
            task.wait(Config.attackDelay or 0.08)
        else
            task.wait(0.15)
        end
    end
end

return Combat