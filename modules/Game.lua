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
    return getCharacter():WaitForChild("HumanoidRootPart")
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

local function getTargetFolders()
    local clients = Workspace
        :WaitForChild("Worlds")
        :WaitForChild("Targets")
        :WaitForChild("Clients")

    local results = {}

    for _, obj in ipairs(clients:GetChildren()) do
        if (obj:IsA("Folder") or obj:IsA("Model")) and (obj.Name:match("^Raids") or obj.Name:match("^BossFight")) then
            table.insert(results, obj)
        end
    end

    return results
end

local function chooseBestTargetFolder()
    local folders = getTargetFolders()
    if #folders == 0 then
        return nil
    end

    local bestFolder = nil
    local bestCount = -1

    for _, folder in ipairs(folders) do
        local count = 0
        for _, child in ipairs(folder:GetChildren()) do
            if isEnemyModel(child) then
                count = count + 1
            end
        end

        if count > bestCount then
            bestCount = count
            bestFolder = folder
        end
    end

    if bestFolder then
        return bestFolder
    end

    return folders[1]
end

local function findActiveRaidVisual()
    local visuals = Workspace:FindFirstChild("Raids_Visual")
    if not visuals then
        return nil
    end

    for _, obj in ipairs(visuals:GetChildren()) do
        if obj.Name:find("_Server_") then
            return obj
        end
    end

    return nil
end

function Game.goToChallengesLobby()
    getByteNetReliable():FireServer(buffer.fromstring("\005\005\000Lobby"))
    return true
end

function Game.teleportToRaidPod(podName)
    podName = podName or "Pod_01"
    local pod = Game.RaidPods[podName]
    if not pod then
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
    getRaidLobbyRemote():FireServer(getParty(), mapped)
    return true
end

function Game.selectRaidDifficulty(diffName)
    local mapped = Game.RaidDifficultyAlias[diffName] or diffName
    getRaidLobbyRemote():FireServer(getParty(), mapped)
    return true
end

function Game.startRaid(mapName, diffName)
    getRaidStartRemote():FireServer(mapName, diffName)
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
    task.wait(0.35)

    Game.selectRaidDifficulty(levelName)
    task.wait(0.35)

    Game.startRaid(mapName, levelName)
    return true
end

function Game.enableAutoAttack()
    getByteNetReliable():FireServer(buffer.fromstring("\016\000"))
    return true
end

function Game.isInRaid()
    return chooseBestTargetFolder() ~= nil
end

function Game.getEnemies()
    local folder = chooseBestTargetFolder()
    if not folder then
        return {}
    end

    local results = {}
    for _, obj in ipairs(folder:GetChildren()) do
        if isEnemyModel(obj) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(results, obj)
            end
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

    -- ขยับไปข้างหน้ามอนนิดนึง ไม่ทับกลางตัว
    local cf = hrp.CFrame * CFrame.new(0, 0, 3)
    Utils.tpTo(cf)
    return true
end

function Game.waitUntilInRaid(timeout)
    local started = tick()
    while tick() - started < (timeout or 20) do
        if Game.isInRaid() then
            return true
        end
        task.wait(0.25)
    end
    return false
end

function Game.waitForFirstEnemies(timeout)
    local started = tick()
    while tick() - started < (timeout or 15) do
        if #Game.getEnemies() > 0 then
            return true
        end
        task.wait(0.25)
    end
    return false
end

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
    local specials = rewards:FindFirstChild("Specials")

    if golds then table.insert(results, golds) end
    if specials then table.insert(results, specials) end

    return results
end

function Game.isRaidCleared(State, Config)
    local enemies = Game.getEnemies()

    -- ยังไม่เคยเห็นมอน ห้ามถือว่าเคลียร์
    if not State.raidHasSeenEnemies then
        if #enemies > 0 then
            State.raidHasSeenEnemies = true
            State.raidEmptySince = nil
            State.raidNoEnemyConfirmedAt = nil
        end
        return false
    end

    -- ยังมีมอนอยู่ = ยังไม่จบ
    if #enemies > 0 then
        State.raidEmptySince = nil
        State.raidNoEnemyConfirmedAt = nil
        return false
    end

    -- ไม่มีมอน เริ่มจับเวลา
    if not State.raidEmptySince then
        State.raidEmptySince = tick()
        return false
    end

    -- ยังว่างไม่ถึง grace period => ยังไม่จบ เผื่อมี wave ใหม่
    if tick() - State.raidEmptySince < (Config.clearEmptyGrace or 5.0) then
        return false
    end

    -- ยืนยันแล้วว่าไม่มีมอนจริง
    if not State.raidNoEnemyConfirmedAt then
        State.raidNoEnemyConfirmedAt = tick()
    end

    -- ถ้ามี reward แล้ว = จบจริง
    if #Game.getRewardChests() > 0 then
        return true
    end

    -- ยังไม่มี reward ก็รออีกนิด เผื่อเกม spawn reward ช้า
    if tick() - State.raidNoEnemyConfirmedAt < (Config.rewardAppearTimeout or 8.0) then
        return false
    end

    return false
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
    task.wait(0.25)

    local vim = game:GetService("VirtualInputManager")
    vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.08)
    vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)

    return true
end

function Game.getNamedChest(name)
    for _, chest in ipairs(Game.getRewardChests()) do
        if chest.Name == name then
            return chest
        end
    end
    return nil
end

return Game