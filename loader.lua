local BASE = "https://raw.githubusercontent.com/rainza999/roblox-anime-tactical-simulator/main/"

getgenv().ATS2 = getgenv().ATS2 or {}
getgenv().ATS2.Modules = {}
getgenv().ATS2.LoadedAt = os.time()
getgenv().ATS2.Version = "ATS2-stop-v1"
getgenv().ATS2.StopRequested = false

local Runtime = getgenv().ATS2

function Runtime.stop(reason)
    Runtime.StopRequested = true
    warn("[ATS2] STOP requested:", reason or "no reason")
end

function Runtime.resume()
    Runtime.StopRequested = false
    warn("[ATS2] RESUME requested")
end

function Runtime.isStopped()
    return Runtime.StopRequested == true
end

local function loadRemote(path)
    local url = BASE .. path .. "?t=" .. tostring(os.time())

    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)

    if not ok then
        warn("[ATS2] Failed loading:", path, result)
        return nil
    end

    warn("[ATS2] loaded:", path, "version:", Runtime.Version, "loadedAt:", Runtime.LoadedAt)
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