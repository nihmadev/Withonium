local Settings = {
    
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
    predictionFactor = 1.0, 
    predictionSmoothing = 0.2, 
    projectilePredictionEnabled = true,
    projectileSpeed = 1000,
    projectileGravity = 196.2,
    fovSize = 90,
    zoomEnabled = true,
    zoomAmount = 20,
    zoomSmoothness = 0.1,
    targetPriority = "Distance", 
    aimKey = Enum.UserInputType.MouseButton1,
    aimKeyMode = "Hold", 
    targetPart = "Head", 
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
    hitboxExpanderEnabled = true, 
    hitboxExpanderSize = 5,
    hitboxExpanderShow = false,
    
    
    antiAimEnabled = false,
    antiAimMode = "Spin", 
    antiAimSpeed = 50,
    antiAimKey = Enum.KeyCode.Unknown,
    antiAimKeyMode = "Toggle",
    
    
    antiAfkEnabled = false,
    antiAfkInterval = 15, 
    antiAfkLastActionTime = tick(),
    
    
    ballisticsEnabled = true,
    bulletVelocity = 1000, 
    gravity = 196.2, 
    predictionFactor = 0.500, 
    predictionIterations = 20, 
    hitscanVelocityThreshold = 800, 
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
    espMaxDistance = 700, 
    espTextColor = Color3.fromRGB(255, 255, 255),
    espChamsMode = "Default", 
    espColor = Color3.fromRGB(255, 255, 255),
    espOutlineColor = Color3.fromRGB(255, 255, 255),
    espSkeletonColor = Color3.fromRGB(255, 255, 255),
    
    
    bulletTracerEnabled = true,
    bulletTracerColor = Color3.fromRGB(105, 0, 198), 
    bulletTracerDuration = 2, 
    bulletTracerThickness = 0.5,
    bulletTracerPhysics = true,

    fullBrightEnabled = false,
    noGrassEnabled = false,
    noFogEnabled = false,

    
    crosshairEnabled = false,
    crosshairType = "Swastika",
    crosshairColor = Color3.fromRGB(255, 0, 0),
    crosshairSize = 10,
    crosshairThickness = 1,

    
    guiVisible = true,
    watermarkEnabled = true,
    toggleKey = Enum.KeyCode.RightShift,
    logoId = "https://raw.githubusercontent.com/nihmadev/Withonium/main/icon.png?cache_bust=1"
}

return Settings
