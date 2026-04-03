local State = {
    running = false,

    autoRaid = true,
    autoDungeonBoss = false,

    selectedRaidMap = "Jujutsu Highschool",
    selectedRaidLevel = "Nightmare",

    selectedDungeonBossMap = "Map4",

    selectedChests = {
        "Golds",
        "Specials",
    },

    bossWindows = {
        intervalMinutes = 10,
        durationMinutes = 5,
    },

    currentMode = "idle",
    inInstance = false,
    instanceType = nil,

    lastBossWindowKey = nil,
    bossDoneInCurrentWindow = false,

    debug = true,
    tickRate = 0.2,

    -- เพิ่ม
    raidHasSeenEnemies = false,
    raidEnteredAt = 0,
    lastAutoAttackAt = 0,
    raidEmptySince = nil,
    raidNoEnemyConfirmedAt = nil,
}

return State