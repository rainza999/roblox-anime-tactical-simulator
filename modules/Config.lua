local Config = {
    retryDelay = 1.0,
    scanDelay = 0.2,
    attackDelay = 0.08,
    postClearDelay = 0.5,
    chestOpenDelay = 0.4,
    afterRaidFinishDelay = 1.0,
    afterBossFinishDelay = 1.0,

    waitInstanceTimeout = 20,
    waitEnemiesTimeout = 15,

    autoAttackRefresh = 2.0,

    -- อันนี้สำคัญ
    clearEmptyGrace = 5.0,      -- ไม่มีมอนต่อเนื่อง 5 วิ ค่อยเริ่มคิดว่าอาจจบ
    rewardAppearTimeout = 8.0,  -- หลังไม่มีมอนแล้ว รอ reward โผล่ได้อีก 8 วิ
}

return Config