local ATS2 = getgenv().ATS2
local Utils = ATS2.require("modules/Utils.lua")
local Game = ATS2.require("modules/Game.lua")
local Config = ATS2.require("modules/Config.lua")

local Combat = {}

function Combat.getAliveEnemies()
    local results = {}
    for _, enemy in ipairs(Game.getEnemies()) do
        if Utils.isAliveModel(enemy) then
            table.insert(results, enemy)
        end
    end
    return results
end

function Combat.getClosestEnemy()
    local player = game.Players.LocalPlayer
    local char = player and player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local enemies = Combat.getAliveEnemies()
    local best, bestDist = nil, math.huge

    for _, enemy in ipairs(enemies) do
        local ehrp = Utils.getHumanoidRootPart(enemy)
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
    while true do
        local enemies = Combat.getAliveEnemies()
        if #enemies == 0 then
            return true
        end

        local target = Combat.getClosestEnemy()
        if not target then
            Utils.safeWait(Config.scanDelay)
        else
            Utils.tpTo(target)
            Game.attackTarget(target)
            Utils.safeWait(Config.attackDelay)
        end
    end
end

return Combat