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

function Game.isInRaid()
    return #Game.getTargetFolders() > 0
end

function Game.getEnemies(State)
    local folders = Game.getTargetFolders()
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

    local dest = hrp.CFrame * CFrame.new(0, 0, 3)
    Utils.tpTo(dest)
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

return Game