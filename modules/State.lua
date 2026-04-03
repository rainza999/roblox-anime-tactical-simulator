local State = {
    running = false,
    debug = true,

    tickRate = 0.25,

    autoRaid = true,
    autoDungeonBoss = false,

    currentMode = "idle",

    raidMap = "Jujutsu Highschool",
    raidLevel = "Nightmare",

    selectedChests = { "Golds", "Specials" },

    stopReason = nil,
    killSwitchEnabled = true,

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