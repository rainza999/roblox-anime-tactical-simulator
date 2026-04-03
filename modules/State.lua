local State = {
    running = false,

    autoRaid = true,
    autoDungeonBoss = false,

    selectedRaidMap = "Map1",
    selectedRaidLevel = "Normal",

    selectedDungeonBossMap = "Map4",

    selectedChests = {
        -- เรียงลำดับกล่องที่อยากเปิด
        -- เช่น "Chest1", "Chest3", "Chest2"
    },

    bossWindows = {
        -- เปิด 5 นาที ทุก 10 นาที
        -- ถ้าอยากเปลี่ยนทีหลังไปปรับ Scheduler
        intervalMinutes = 10,
        durationMinutes = 5,
    },

    currentMode = "idle", -- idle / raid / dungeon_boss
    inInstance = false,
    instanceType = nil,   -- raid / dungeon_boss / nil

    lastBossWindowKey = nil,
    bossDoneInCurrentWindow = false,

    debug = true,
    tickRate = 0.2,
}

return State