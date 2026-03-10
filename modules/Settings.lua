local Settings = {
    -- Aimbot Settings
    aimbotEnabled = false,
    teamCheckEnabled = true,
    visibleCheckEnabled = true,
    noRecoilEnabled = false,
    fastShootEnabled = false,
    fastShootMultiplier = 2.5,
    jumpShotEnabled = false,
    jumpShotKey = Enum.KeyCode.Unknown,
    jumpShotKeyMode = "Toggle",
    
    fovCircleEnabled = true,
    targetLineEnabled = true,
    targetLineColor = Color3.fromRGB(255, 255, 255),
    smoothness = 0.08,
    predictionFactor = 1.0, -- Default to 1.0
    predictionSmoothing = 0.2, -- Smoothing for prediction to avoid jitter
    projectilePredictionEnabled = true,
    projectileSpeed = 1000,
    projectileGravity = 196.2,
    fovSize = 90,
    zoomEnabled = true,
    zoomAmount = 20,
    zoomSmoothness = 0.1,
    targetPriority = "Distance", -- "Distance", "Crosshair", "Balanced"
    aimKey = Enum.UserInputType.MouseButton1,
    aimKeyMode = "Hold", -- "Hold", "Toggle", "Always"
    targetPart = "Head", -- "Head", "Torso", "Legs"
    silentAimKey = Enum.KeyCode.Unknown,
    silentAimKeyMode = "Toggle",

    magicBulletEnabled = false,
    magicBulletHouseCheck = true,
    
    spiderEnabled = false,
    spiderKey = Enum.KeyCode.Unknown,
    spiderKeyMode = "Toggle",

    speedHackEnabled = false,
    speedHackKey = Enum.KeyCode.Unknown,
    speedHackKeyMode = "Toggle",
    
    thirdPersonEnabled = false,
    thirdPersonDistance = 10,
    
    freeCamEnabled = false,
    freeCamKey = Enum.KeyCode.Unknown,
    freeCamKeyMode = "Toggle",

    FullBrightKey = Enum.KeyCode.Unknown,
    FullBrightKeyMode = "Toggle",
    speedMultiplier = 1,
    waterSpeedHackEnabled = false,
    waterSpeedMultiplier = 1,
    godModeEnabled = false,
    hitboxExpanderEnabled = true, -- Changed to true for testing
    hitboxExpanderSize = 5,
    hitboxExpanderShow = false,
    
    -- Anti-Aim Settings
    antiAimEnabled = false,
    antiAimMode = "Spin", -- "Spin", "Jitter", "Static"
    antiAimSpeed = 50,
    antiAimKey = Enum.KeyCode.Unknown,
    antiAimKeyMode = "Toggle",
    
    -- Anti-AFK Settings
    antiAfkEnabled = false,
    antiAfkInterval = 15, -- Minutes
    antiAfkLastActionTime = tick(),
    
    -- Ballistics Settings (Not in GUI as requested)
    ballisticsEnabled = true,
    bulletVelocity = 1000, -- Studs per second
    gravity = 196.2, -- Roblox gravity
    predictionFactor = 0.500, -- For movement prediction
    predictionIterations = 20, -- Iterations for ballistics accuracy
    hitscanVelocityThreshold = 800, -- Above this velocity gravity isn't applied to aiming
    espEnabled = true,
    espDrawTeammates = false,
    espHighlights = false,
    espSkeleton = false,
    espNames = true,
    espDistances = true,
    espWeapons = true,
    espIcons = true,
    espEnemySlots = false,
    espHealthBar = false,
    espHealthBarText = true,
    espHealthBarPosition = "Left",
    espHealthBarAutoScale = true,
    espHealthBarBaseSize = 50,
    espHealthBarBaseWidth = 4,
    espHealthBarBaseDistance = 25,
    espHealthBarMinScale = 0.4,
    espHealthBarMaxScale = 1.0,
    espMaxDistance = 700, --gamemable
    espTextColor = Color3.fromRGB(255, 255, 255),
    espChamsMode = "Default", -- "Default", "Glow", "Metal", "Neon"
    espColor = Color3.fromRGB(255, 255, 255),
    espOutlineColor = Color3.fromRGB(255, 255, 255),
    espSkeletonColor = Color3.fromRGB(255, 255, 255),
    
    -- Bullet Tracer Settings
    bulletTracerEnabled = true,
    bulletTracerColor = Color3.fromRGB(105, 0, 198), -- Viol by default
    bulletTracerDuration = 2, -- Seconds
    bulletTracerThickness = 0.5,
    bulletTracerPhysics = true,

    fullBrightEnabled = false,
    noGrassEnabled = false,
    noFogEnabled = false,

    -- Crosshair Settings
    crosshairEnabled = false,
    crosshairType = "Swastika",
    crosshairColor = Color3.fromRGB(255, 0, 0),
    crosshairSize = 10,
    crosshairThickness = 1,

    -- GUI Settings
    guiVisible = true,
    watermarkEnabled = true,
    toggleKey = Enum.KeyCode.RightShift,
    logoId = "https://raw.githubusercontent.com/nihmadev/Withonium/main/icon.png?cache_bust=1"
}

return Settings
