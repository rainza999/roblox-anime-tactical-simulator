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
        :WaitForChild(LocalPlayer.Name)
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

local function getPartyRemote()
    return ReplicatedStorage
        :WaitForChild("Remotes")
        :WaitForChild("Misc")
        :WaitForChild("Parties")
end

local function getByteNetReliable()
    return ReplicatedStorage:WaitForChild("ByteNetReliable")
end

function Game.getTargetFolders()
    local clients = workspace.Worlds.Targets.Clients
    local results = {}

    for _, obj in ipairs(clients:GetChildren()) do
        if obj.Name:match("^Raids") or obj.Name:match("^BossFight") then
            table.insert(results, obj)
        end
    end

    return results
end

function Game.goToChallengesLobby()
    warn("[ATS2] step1 goToChallengesLobby")
    getByteNetReliable():FireServer(buffer.fromstring("\005\005\000Lobby"))
    return true
end

function Game.teleportToRaidPod(podName)
    podName = podName or "Pod_01"
    local pod = Game.RaidPods[podName]
    if not pod then
        warn("[ATS2] teleportToRaidPod failed: no pod", podName)
        return false
    end

    warn("[ATS2] step2 teleportToRaidPod", pod:GetFullName())

    if pod:IsA("Model") then
        return Utils.tpTo(pod.WorldPivot)
    end

    local center = pod:FindFirstChild("Centers")
    if center and center:IsA("BasePart") then
        return Utils.tpTo(center.CFrame)
    end

    return false
end

function Game.stepIntoRaidPod(podName)
    podName = podName or "Pod_01"
    local pod = Game.RaidPods[podName]
    if not pod then
        warn("[ATS2] stepIntoRaidPod failed: no pod", podName)
        return false
    end

    local root = getRoot()

    if pod:IsA("Model") then
        root.CFrame = pod.WorldPivot
        return true
    end

    local center = pod:FindFirstChild("Centers")
    if center and center:IsA("BasePart") then
        root.CFrame = center.CFrame
        return true
    end

    return false
end

function Game.selectRaidMap(mapName)
    local mapped = Game.RaidMapAlias[mapName] or mapName
    local party = getParty()

    warn("[ATS2] step3 selectRaidMap", "party=", party and party.Name, "map=", mapped)

    getRaidLobbyRemote():FireServer(party, mapped)
    return true
end

function Game.selectRaidDifficulty(diffName)
    local mapped = Game.RaidDifficultyAlias[diffName] or diffName
    local party = getParty()

    warn("[ATS2] step4 selectRaidDifficulty", "party=", party and party.Name, "diff=", mapped)

    getRaidLobbyRemote():FireServer(party, mapped)
    return true
end

function Game.startRaid(mapName, diffName)
    warn("[ATS2] step5 startRaid", mapName, diffName)
    getRaidStartRemote():FireServer(mapName, diffName)
    return true
end

function Game.confirmRaidLobby()
    warn("[ATS2] step6 confirmRaidLobby")
    local args = {
        Instance.new("Folder"),
        true
    }
    getRaidLobbyRemote():FireServer(unpack(args))
    return true
end

function Game.disableParty()
    warn("[ATS2] step7 disableParty")
    getPartyRemote():FireServer("Disabled")
    return true
end

function Game.enterRaid(mapName, levelName)
    warn("### GAME.ENTERRAID NEW ###", mapName, levelName)
    warn("[ATS2] Entering raid:", mapName, levelName)

    Game.goToChallengesLobby()
    task.wait(1.2)

    Game.teleportToRaidPod("Pod_01")
    task.wait(0.5)

    Game.stepIntoRaidPod("Pod_01")
    task.wait(1.0)

    Game.selectRaidMap(mapName)
    task.wait(0.35)

    Game.selectRaidDifficulty(levelName)
    task.wait(0.35)

    Game.startRaid(mapName, levelName)
    task.wait(0.35)

    Game.confirmRaidLobby()
    task.wait(0.2)

    Game.disableParty()
    task.wait(0.5)

    return true
end

function Game.enableAutoAttack()
    getByteNetReliable():FireServer(buffer.fromstring("\016\000"))
    return true
end

function Game.getRaidFolders()
    local clients = workspace.Worlds.Targets.Clients
    local results = {}

    for _, obj in ipairs(clients:GetChildren()) do
        if obj.Name:match("^Raids") then
            table.insert(results, obj)
        end
    end

    return results
end

function Game.getBossFightFolders()
    local clients = workspace.Worlds.Targets.Clients
    local results = {}

    for _, obj in ipairs(clients:GetChildren()) do
        if obj.Name:match("^BossFight") then
            table.insert(results, obj)
        end
    end

    return results
end

function Game.isInRaid()
    return #Game.getRaidFolders() > 0
end

function Game.getEnemies(State)
    local folders = Game.getRaidFolders()
    local results = {}
    local seen = {}

    for _, folder in ipairs(folders) do
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Humanoid") and obj.Health > 0 then
                local model = obj.Parent
                local hrp = model and model:FindFirstChild("HumanoidRootPart")

                if model and hrp and not seen[model] then
                    seen[model] = true
                    table.insert(results, model)
                end
            end
        end
    end

    if State and State.debug then
        print("[Game.getEnemies] folders =", #folders)
        print("[Game.getEnemies] enemies =", #results)
        for _, enemy in ipairs(results) do
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            print(" - enemy:", enemy:GetFullName(), "hp:", hum and hum.Health)
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

    local root = getCharacter():FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end

    root.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
    return true
end

function Game.waitUntilInRaid(timeout)
    local started = tick()
    while tick() - started < (timeout or 20) do
        if Game.isInRaid() then
            warn("[ATS2] raid instance detected")
            return true
        end
        task.wait(0.25)
    end
    warn("[ATS2] timed out waiting for raid instance")
    return false
end

function Game.waitForFirstEnemies(timeout, State)
    local started = tick()
    while tick() - started < (timeout or 15) do
        local enemies = Game.getEnemies(State)
        if #enemies > 0 then
            warn("[ATS2] first enemies detected:", #enemies)
            return true
        end
        task.wait(0.25)
    end
    warn("[ATS2] no enemies seen yet, will continue polling")
    return false
end

local function findActiveRaidVisual()
    local visuals = Workspace:FindFirstChild("Raids_Visual")
    if not visuals then return nil end

    for _, obj in ipairs(visuals:GetChildren()) do
        if obj.Name:find("_Server_") then
            return obj
        end
    end

    return nil
end

function Game.getRewardChests()
    local visual = findActiveRaidVisual()
    if not visual then
        warn("[ATS2] no raid visual found")
        return {}
    end

    local rewards = visual:FindFirstChild("Configs")
    rewards = rewards and rewards:FindFirstChild("Others")
    rewards = rewards and rewards:FindFirstChild("Rewards")

    if not rewards then
        warn("[ATS2] no rewards folder")
        return {}
    end

    local results = {}

    local golds = rewards:FindFirstChild("Golds")
    local specials = rewards:FindFirstChild("Specials")

    if golds then table.insert(results, golds) end
    if specials then table.insert(results, specials) end

    warn("[ATS2] reward chests:", #results)

    return results
end

function Game.openChest(chest)
    if not chest then return false end

    local part = chest:IsA("BasePart") and chest 
        or chest:FindFirstChildWhichIsA("BasePart", true)

    if not part then
        warn("[ATS2] no part in chest:", chest:GetFullName())
        return false
    end

    local root = getRoot()

    -- วาร์ปไปหน้ากล่อง
    root.CFrame = part.CFrame * CFrame.new(0, 0, 3)

    task.wait(0.1)

    -- กด E
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)

    warn("[ATS2] opened chest:", chest.Name)

    return true
end
return Game