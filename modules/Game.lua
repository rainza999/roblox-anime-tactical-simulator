local ATS2 = getgenv().ATS2
local Utils = ATS2.require("modules/Utils.lua")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

local Game = {}

Game.RaidPods = {
    Pod_01 = Workspace:WaitForChild("Raids_Entering"):WaitForChild("Pod_01"),
}

Game.RaidMapAlias = {
    ["Jujutsu Highschool"] = "Worlds_Jujutsu Highschool",
}

Game.RaidDifficultyAlias = {
    ["Nightmare"] = "Diffculty_Nightmare",
    ["Hard"] = "Diffculty_Hard",
    ["Normal"] = "Diffculty_Normal",
    ["Easy"] = "Diffculty_Easy",
}

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getRoot()
    local char = getCharacter()
    return char:WaitForChild("HumanoidRootPart")
end

local function getParty()
    return ReplicatedStorage
        :WaitForChild("Shared")
        :WaitForChild("Parties")
        :WaitForChild("RainFatherReal")
end

local function getRaidLobbyRemote()
    return ReplicatedStorage
        :WaitForChild("Remotes")
        :WaitForChild("Gameplays")
        :WaitForChild("RaidsLobbies")
end

local function getRaidStartRemote()
    return ReplicatedStorage
        :WaitForChild("Remotes")
        :WaitForChild("Systems")
        :WaitForChild("RaidsEvent")
end

local function getByteNetReliable()
    return ReplicatedStorage:WaitForChild("ByteNetReliable")
end

local function isEnemyModel(obj)
    if not obj or not obj:IsA("Model") then
        return false
    end

    local hum = obj:FindFirstChildOfClass("Humanoid")
    local hrp = obj:FindFirstChild("HumanoidRootPart")

    return hum ~= nil and hrp ~= nil
end

local function findActiveTargetFolder()
    local clients = Workspace
        :WaitForChild("Worlds")
        :WaitForChild("Targets")
        :WaitForChild("Clients")

    local candidates = {}

    for _, obj in ipairs(clients:GetChildren()) do
        if obj:IsA("Folder") or obj:IsA("Model") then
            if string.match(obj.Name, "^Raids") or string.match(obj.Name, "^BossFight") then
                table.insert(candidates, obj)
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.Name < b.Name
    end)

    return candidates[1]
end

local function findActiveRaidVisual()
    local visuals = Workspace:FindFirstChild("Raids_Visual")
    if not visuals then
        return nil
    end

    for _, obj in ipairs(visuals:GetChildren()) do
        if string.find(obj.Name, "_Server_") then
            return obj
        end
    end

    return nil
end

-- =========================
-- LOBBY / RAID ENTRY
-- =========================

function Game.goToChallengesLobby()
    local args = {
        buffer.fromstring("\005\005\000Lobby")
    }
    getByteNetReliable():FireServer(unpack(args))
    return true
end

function Game.teleportToRaidPod(podName)
    podName = podName or "Pod_01"

    local pod = Game.RaidPods[podName]
    if not pod then
        warn("[Game] pod not found:", podName)
        return false
    end

    local center = pod:FindFirstChild("Centers")
    if center and center:IsA("BasePart") then
        return Utils.tpTo(center.CFrame)
    end

    if pod:IsA("Model") then
        return Utils.tpTo(pod:GetPivot())
    end

    return false
end

function Game.stepIntoRaidPod(podName)
    podName = podName or "Pod_01"

    local pod = Game.RaidPods[podName]
    if not pod then
        return false
    end

    local root = getRoot()
    if not root then
        return false
    end

    local center = pod:FindFirstChild("Centers")
    if center and center:IsA("BasePart") then
        root.CFrame = center.CFrame + (center.CFrame.LookVector * 2)
        return true
    end

    if pod:IsA("Model") then
        root.CFrame = pod:GetPivot()
        return true
    end

    return false
end

function Game.selectRaidMap(mapName)
    local mapped = Game.RaidMapAlias[mapName] or mapName
    local args = {
        getParty(),
        mapped
    }
    getRaidLobbyRemote():FireServer(unpack(args))
    return true
end

function Game.selectRaidDifficulty(diffName)
    local mapped = Game.RaidDifficultyAlias[diffName] or diffName
    local args = {
        getParty(),
        mapped
    }
    getRaidLobbyRemote():FireServer(unpack(args))
    return true
end

function Game.startRaid(mapName, diffName)
    local args = {
        mapName,
        diffName
    }
    getRaidStartRemote():FireServer(unpack(args))
    return true
end

function Game.enterRaid(mapName, levelName)
    Game.goToChallengesLobby()
    task.wait(1.0)

    Game.teleportToRaidPod("Pod_01")
    task.wait(0.4)

    Game.stepIntoRaidPod("Pod_01")
    task.wait(0.8)

    Game.selectRaidMap(mapName)
    task.wait(0.3)

    Game.selectRaidDifficulty(levelName)
    task.wait(0.3)

    Game.startRaid(mapName, levelName)
    task.wait(2.0)

    return true
end

-- =========================
-- AUTO ATTACK
-- =========================

function Game.enableAutoAttack()
    local args = {
        buffer.fromstring("\016\000")
    }
    getByteNetReliable():FireServer(unpack(args))
    return true
end

-- =========================
-- INSTANCE CHECK
-- =========================

function Game.isInRaid()
    return findActiveTargetFolder() ~= nil
end

function Game.isInDungeonBoss()
    return false
end

function Game.isInAnyInstance()
    return Game.isInRaid() or Game.isInDungeonBoss()
end

-- =========================
-- ENEMIES
-- =========================

function Game.getEnemies()
    local folder = findActiveTargetFolder()
    if not folder then
        return {}
    end

    local results = {}
    for _, obj in ipairs(folder:GetChildren()) do
        if isEnemyModel(obj) then
            table.insert(results, obj)
        end
    end

    return results
end

function Game.attackTarget(target)
    if not target then
        return false
    end

    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false
    end

    Utils.tpTo(hrp.CFrame)
    return true
end

function Game.isRaidCleared()
    local enemies = Game.getEnemies()
    if #enemies > 0 then
        return false
    end

    local rewards = Game.getRewardChests()
    return #rewards > 0
end

-- =========================
-- CHESTS
-- =========================

function Game.getRewardChests()
    local visual = findActiveRaidVisual()
    if not visual then
        return {}
    end

    local rewards = visual:FindFirstChild("Configs")
    rewards = rewards and rewards:FindFirstChild("Others")
    rewards = rewards and rewards:FindFirstChild("Rewards")
    if not rewards then
        return {}
    end

    local results = {}

    local golds = rewards:FindFirstChild("Golds")
    if golds then
        table.insert(results, golds)
    end

    local specials = rewards:FindFirstChild("Specials")
    if specials then
        table.insert(results, specials)
    end

    return results
end

function Game.getNamedChest(name)
    local all = Game.getRewardChests()
    for _, chest in ipairs(all) do
        if chest.Name == name then
            return chest
        end
    end
    return nil
end

function Game.openChest(chest)
    if not chest then
        return false
    end

    local targetPart = chest:IsA("BasePart") and chest or chest:FindFirstChildWhichIsA("BasePart", true)
    if not targetPart then
        return false
    end

    Utils.tpTo(targetPart.CFrame)
    task.wait(0.2)

    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.08)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)

    return true
end

function Game.leaveCurrentInstance()
    return true
end

return Game