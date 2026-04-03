local ATS2 = getgenv().ATS2
local State = ATS2.require("modules/State.lua")

local UI = {}

function UI.init()
    print("[ATS2/UI] init")

    -- TODO:
    -- Toggle: Auto Raid
    -- Dropdown: Raid Map
    -- Dropdown: Raid Level
    -- Multi-select or ordered list: Selected Chests
    -- Toggle: Auto Dungeon Boss
    -- Dropdown: Dungeon Boss Map
end

function UI.setRaidMap(v)
    State.selectedRaidMap = v
end

function UI.setRaidLevel(v)
    State.selectedRaidLevel = v
end

function UI.setDungeonBossMap(v)
    State.selectedDungeonBossMap = v
end

function UI.setSelectedChests(list)
    State.selectedChests = list
end

return UI