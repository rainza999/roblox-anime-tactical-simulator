local ATS2 = getgenv().ATS2
local Utils = ATS2.require("modules/Utils.lua")
local Game = ATS2.require("modules/Game.lua")
local Config = ATS2.require("modules/Config.lua")

local Combat = {}

function Combat.getAliveEnemies()
    local results = {}
    for _, enemy in ipairs(Game.getEnemies()) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            table.insert(results, enemy)
        end
    end
    return results
end

function Combat.getClosestEnemy()
    local char = game.Players.LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end

    local best = nil
    local bestDist = math.huge

    for _, enemy in ipairs(Combat.getAliveEnemies()) do
        local ehrp = enemy:FindFirstChild("HumanoidRootPart")
        if ehrp then
            local dist = (root.Position - ehrp.Position).Magnitude
            if dist < bestDist then
                best = enemy
                bestDist = dist
            end
        end
    end

    return best
end

function Combat.clearAllEnemies(State)
    Game.enableAutoAttack()
    task.wait(0.2)

    while true do
        local enemies = Combat.getAliveEnemies()
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