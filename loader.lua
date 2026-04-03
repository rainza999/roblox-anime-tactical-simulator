local BASE = "https://raw.githubusercontent.com/rainza999/roblox-anime-tactical-simulator/main/"

getgenv().ATS2 = getgenv().ATS2 or {}
getgenv().ATS2.Modules = {}
getgenv().ATS2.LoadedAt = os.time()

local Runtime = getgenv().ATS2

local function loadRemote(path)
    local url = BASE .. path .. "?t=" .. tostring(os.time())
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)

    if not ok then
        warn("[ATS2] Failed loading:", path, result)
        return nil
    end

    return result
end

Runtime.require = function(path)
    if Runtime.Modules[path] then
        return Runtime.Modules[path]
    end

    local mod = loadRemote(path)
    Runtime.Modules[path] = mod
    return mod
end

local Main = Runtime.require("main.lua")
if Main and Main.init then
    Main.init()
end