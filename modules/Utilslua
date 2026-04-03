local Utils = {}

function Utils.debugPrint(State, ...)
    if State and State.debug then
        print("[ATS2]", ...)
    end
end

function Utils.safeWait(t)
    task.wait(t or 0.1)
end

function Utils.nowUnix()
    return os.time()
end

function Utils.getMinuteOfHour()
    return tonumber(os.date("%M"))
end

function Utils.getClockString()
    return os.date("%H:%M:%S")
end

function Utils.findFirstDescendantByName(parent, name)
    if not parent then return nil end
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj.Name == name then
            return obj
        end
    end
    return nil
end

function Utils.findAllDescendantsByName(parent, name)
    local results = {}
    if not parent then return results end

    for _, obj in ipairs(parent:GetDescendants()) do
        if obj.Name == name then
            table.insert(results, obj)
        end
    end

    return results
end

function Utils.getHumanoidRootPart(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("RootPart")
        or model.PrimaryPart
end

function Utils.tpTo(target)
    local player = game.Players.LocalPlayer
    local char = player and player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    if typeof(target) == "CFrame" then
        root.CFrame = target
        return true
    end

    if typeof(target) == "Vector3" then
        root.CFrame = CFrame.new(target)
        return true
    end

    if typeof(target) == "Instance" then
        if target:IsA("BasePart") then
            root.CFrame = target.CFrame
            return true
        end

        local hrp = Utils.getHumanoidRootPart(target)
        if hrp then
            root.CFrame = hrp.CFrame
            return true
        end
    end

    return false
end

function Utils.isAliveModel(model)
    if not model then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        return hum.Health > 0
    end

    local hp = model:GetAttribute("Health")
    if type(hp) == "number" then
        return hp > 0
    end

    return true
end

return Utils