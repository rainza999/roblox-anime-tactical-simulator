local ATS2 = getgenv().ATS2
local Utils = ATS2.require("modules/Utils.lua")

local Game = {}

-- =========================
-- TODO: ปรับ path จริงตรงนี้
-- =========================

function Game.getRaidLobbyEntry(mapName, levelName)
    -- return portal / npc / button / remote params
    -- TODO
    return {
        map = mapName,
        level = levelName,
    }
end

function Game.getDungeonBossLobbyEntry(mapName)
    -- TODO
    return {
        map = mapName,
    }
end

function Game.enterRaid(mapName, levelName)
    -- TODO: ยิง remote / กดปุ่ม / interact
    warn("[Game.enterRaid] TODO:", mapName, levelName)
    return true
end

function Game.enterDungeonBoss(mapName)
    -- TODO
    warn("[Game.enterDungeonBoss] TODO:", mapName)
    return true
end

function Game.leaveCurrentInstance()
    -- TODO
    warn("[Game.leaveCurrentInstance] TODO")
    return true
end

function Game.isInRaid()
    -- TODO
    return false
end

function Game.isInDungeonBoss()
    -- TODO
    return false
end

function Game.isInAnyInstance()
    return Game.isInRaid() or Game.isInDungeonBoss()
end

function Game.getEnemies()
    -- TODO: คืน list model มอนใน instance ปัจจุบัน
    return {}
end

function Game.attackTarget(target)
    -- TODO: ยิง remote ตี / equip / click
    warn("[Game.attackTarget] TODO:", target and target.Name)
    return true
end

function Game.getRewardChests()
    -- TODO: คืนกล่องในฉากหลังเคลียร์ raid
    return {}
end

function Game.openChest(chest)
    -- TODO
    warn("[Game.openChest] TODO:", chest and chest.Name)
    return true
end

function Game.isRaidCleared()
    -- TODO: มอนหมด / มีผลลัพธ์ / มีกล่องโผล่
    return false
end

function Game.isDungeonBossCleared()
    -- TODO
    return false
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

return Game