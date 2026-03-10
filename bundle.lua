task.wait(1)
local _modules = {}
local _cache = {}

local old_require = require
local _require
local function require_proxy(p)
if typeof(p) == 'string' then
return _require(p)
end
return old_require(p)
end
local require = require_proxy

_modules["modules/Aimbot"] = function()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")





local Prediction = require("modules/Aimbot/Prediction")
local Targeting = require("modules/Aimbot/Targeting")
local Input = require("modules/Aimbot/Input")
local Exploits = require("modules/Aimbot/Exploits")
local Hitboxes = require("modules/Aimbot/Hitboxes")
local Hooks = require("modules/Aimbot/Hooks")

local Aimbot = {
    CurrentTarget = nil,
    IsAiming = false,
    TargetPosition = nil,
    FOVCircle = nil,
    FOVScreenGui = nil,
    SilentTarget = nil,
    LastCacheTick = 0,
    ToggleActive = false,
    LastKeyState = false,
    
    
    FreeCamActive = false,
    FreeCamPos = Vector3.new(0, 0, 0),
    FreeCamRot = Vector2.new(0, 0),
    OriginalCameraType = nil,
    OriginalCameraCFrame = nil,
    
    
    LastPredictedDir = nil,
    PredictionSmoothing = 0.2, 
    
    
    VelocityHistory = {},
    MaxHistorySize = 5,

    TargetLineLastPos = nil,
}


local function CreateFOVCircle()
    local gui_parent = nil
    pcall(function()
        if gethui then gui_parent = gethui()
        elseif game:GetService("CoreGui") then gui_parent = game:GetService("CoreGui")
        else gui_parent = LocalPlayer:WaitForChild("PlayerGui") end
    end)

    if not gui_parent then return end

    local sg = Instance.new("ScreenGui")
    sg.Name = "WithoniumFOV"
    sg.DisplayOrder = 999
    sg.IgnoreGuiInset = true
    sg.Parent = gui_parent
    Aimbot.FOVScreenGui = sg

    local circle = Instance.new("Frame")
    circle.Name = "FOVCircle"
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = 0
    circle.Active = false
    circle.Selectable = false
    circle.Visible = false
    circle.Parent = sg

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Transparency = 0.5
    stroke.Parent = circle

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle

    Aimbot.FOVCircle = circle

    local line = Instance.new("Frame")
    line.Name = "TargetLine"
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BorderSizePixel = 0
    line.Active = false
    line.Selectable = false
    line.BackgroundColor3 = Color3.new(1, 1, 1)
    line.ZIndex = 10 
    line.Visible = false
    line.Parent = sg
    Aimbot.TargetLine = line
end

CreateFOVCircle()


function Aimbot.GetProjectilePrediction(target, Settings, Ballistics, customOrigin)
    return Prediction.GetProjectilePrediction(target, Settings, Ballistics, customOrigin)
end

function Aimbot.IsInputPressed(key)
    return Input.IsInputPressed(key)
end

function Aimbot.GetSilentTarget(Settings, Utils)
    return Aimbot.SilentTarget
end

function Aimbot.FindTarget(Settings, Utils)
    return Targeting.FindTarget(Settings, Utils, Aimbot)
end

function Aimbot.InitHooks(Settings, Utils, Ballistics, BulletTracer)
    return Hooks.InitHooks(Aimbot, Settings, Utils, Ballistics, BulletTracer)
end

function Aimbot.ApplyNoRecoil(Settings)
    return Exploits.ApplyNoRecoil(Settings)
end

function Aimbot.ApplyFastShoot(Settings)
    return Exploits.ApplyFastShoot(Settings)
end

function Aimbot.ApplyJumpShot(Settings)
    return Exploits.ApplyJumpShot(Settings)
end

function Aimbot.ApplySpider(Settings)
    return Exploits.ApplySpider(Settings)
end

function Aimbot.ApplySpeedHack(Settings, deltaTime)
    return Exploits.ApplySpeedHack(Settings, deltaTime)
end

function Aimbot.ApplyWaterSpeedHack(Settings, deltaTime)
    return Exploits.ApplyWaterSpeedHack(Settings, deltaTime)
end

function Aimbot.ApplyFreeCam(Settings)
    return Exploits.ApplyFreeCam(Aimbot, Settings)
end

function Aimbot.ApplyThirdPerson(Settings)
    return Exploits.ApplyThirdPerson(Settings)
end

function Aimbot.ApplyGodMode(Settings)
    return Exploits.ApplyGodMode(Settings)
end

function Aimbot.ApplyAntiAFK(Settings)
    return Exploits.ApplyAntiAFK(Settings)
end

function Aimbot.ApplyAntiAim(Settings)
    return Exploits.ApplyAntiAim(Settings)
end

function Aimbot.UpdateHitboxes(Settings, Utils, ESP)
    return Hitboxes.UpdateHitboxes(Aimbot, Settings, Utils, ESP)
end

function Aimbot.ApplyZoom(Settings)
    if not Settings.zoomEnabled then return end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    
    local character = LocalPlayer.Character
    local hasWeapon = false
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        hasWeapon = tool ~= nil
    end
    
    
    if not Aimbot.BaseFOV then
        Aimbot.BaseFOV = camera.FieldOfView
    end
    
    
    local isZooming = false
    if Settings.aimKeyMode == "Toggle" then
        isZooming = Aimbot.ToggleActive and hasWeapon
    else
        isZooming = Aimbot.IsInputPressed(Settings.aimKey) and hasWeapon
    end
    
    local smoothness = Settings.zoomSmoothness or 0.1
    
    if isZooming then
        
        if not Aimbot.WasZooming then
            Aimbot.BaseFOV = camera.FieldOfView
            Aimbot.WasZooming = true
        end
        
        local targetFOV = math.max(1, Aimbot.BaseFOV - Settings.zoomAmount)
        camera.FieldOfView = camera.FieldOfView + (targetFOV - camera.FieldOfView) * smoothness
    else
        if Aimbot.WasZooming then
            
            local diff = math.abs(camera.FieldOfView - Aimbot.BaseFOV)
            if diff > 0.5 then
                 camera.FieldOfView = camera.FieldOfView + (Aimbot.BaseFOV - camera.FieldOfView) * smoothness
            else
                 
                 camera.FieldOfView = Aimbot.BaseFOV
                 Aimbot.WasZooming = false
            end
        else
            
            Aimbot.BaseFOV = camera.FieldOfView
        end
    end
end

function Aimbot.Update(deltaTime, Settings, Utils, Ballistics, ESP)
    if not Settings then return end
    
    Aimbot.UpdateHitboxes(Settings, Utils, ESP)
    
    
    local currentFrameTarget = Aimbot.FindTarget(Settings, Utils)
    
    
    if Settings.silentAimEnabled then
        Aimbot.SilentTarget = currentFrameTarget
    else
        Aimbot.SilentTarget = nil
    end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    
    local isPressed = false
    if Settings.aimKey then
        isPressed = Aimbot.IsInputPressed(Settings.aimKey)
    end
    
    local shouldAim = false
    if Settings.aimbotEnabled then
        local mode = Settings.aimKeyMode or "Hold"
        if mode == "Hold" then
            shouldAim = isPressed
        elseif mode == "Toggle" then
            if isPressed and not Aimbot.LastKeyState then
                Aimbot.ToggleActive = not Aimbot.ToggleActive
            end
            shouldAim = Aimbot.ToggleActive
        elseif mode == "Always" then
            shouldAim = true
        end
    else
        Aimbot.ToggleActive = false
    end
    Aimbot.LastKeyState = isPressed

    
    local isSilentPressed = false
    if Settings.silentAimKey then
        isSilentPressed = Aimbot.IsInputPressed(Settings.silentAimKey)
    end

    local shouldSilentAim = false
    if Settings.silentAimEnabled then
        local silentMode = Settings.silentAimKeyMode or "Always"
        if silentMode == "Hold" then
            shouldSilentAim = isSilentPressed
        elseif silentMode == "Toggle" then
            if isSilentPressed and not Aimbot.LastSilentKeyState then
                Aimbot.SilentToggleActive = not Aimbot.SilentToggleActive
            end
            shouldSilentAim = Aimbot.SilentToggleActive
        elseif silentMode == "Always" then
            shouldSilentAim = true
        end
    else
        Aimbot.SilentToggleActive = false
    end
    Aimbot.LastSilentKeyState = isSilentPressed
    Aimbot.IsSilentAiming = shouldSilentAim
    
    
    if Settings.magicBulletEnabled then
        Aimbot.CurrentTarget = currentFrameTarget
    end
    
    if shouldAim or shouldSilentAim then
        local target = currentFrameTarget
        if target and target.targetPart then
            
            if Aimbot.CurrentTarget and Aimbot.CurrentTarget.player ~= target.player then
                Aimbot.LastPredictedDir = nil
                Aimbot.VelocityHistory = {}
            end
            
            
            table.insert(Aimbot.VelocityHistory, target.velocity)
            if #Aimbot.VelocityHistory > (Aimbot.MaxHistorySize or 5) then
                table.remove(Aimbot.VelocityHistory, 1)
            end
            
            local avgVelocity = Vector3.new(0, 0, 0)
            for _, v in ipairs(Aimbot.VelocityHistory) do
                avgVelocity = avgVelocity + v
            end
            avgVelocity = avgVelocity / #Aimbot.VelocityHistory
            
            
            local originalVelocity = target.velocity
            target.velocity = avgVelocity
            
            Aimbot.CurrentTarget = target
            
            if shouldAim then
                Aimbot.IsAiming = true
                
                
                 local character = LocalPlayer.Character
                 local origin = camera.CFrame.Position
                 if character and character:FindFirstChild("HumanoidRootPart") then
                     
                     origin = character.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0)
                 end
     
                 local predictedDir = Aimbot.GetProjectilePrediction(target, Settings, Ballistics, origin)
                
                
                target.velocity = originalVelocity
                
                
                local pSmoothing = Settings.predictionSmoothing or 0.2
                if Aimbot.LastPredictedDir and pSmoothing > 0 then
                    predictedDir = Aimbot.LastPredictedDir:Lerp(predictedDir, math.clamp(1 - pSmoothing, 0.01, 1))
                end
                Aimbot.LastPredictedDir = predictedDir
                
                Aimbot.TargetPosition = origin + (predictedDir * 10)
                
                local currentCFrame = camera.CFrame
                
                local upVector = Vector3.new(0, 1, 0)
                if math.abs(predictedDir:Dot(upVector)) > 0.99 then
                    upVector = Vector3.new(0, 0, 1) 
                end
                
                local targetCFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + predictedDir, upVector)
                
                
                local smoothnessFactor = Settings.smoothness or 0.5
                
                local safeDeltaTime = math.min(deltaTime, 0.1)
                
                
                local alpha = math.clamp(safeDeltaTime * (smoothnessFactor * 120), 0, 1)
                
                if smoothnessFactor < 1 then
                    camera.CFrame = currentCFrame:Lerp(targetCFrame, alpha)
                else
                    camera.CFrame = targetCFrame
                end
            else
                Aimbot.IsAiming = false
                target.velocity = originalVelocity 
            end
        else
            
            Aimbot.CurrentTarget = nil
            Aimbot.IsAiming = false
            Aimbot.TargetPosition = nil
            Aimbot.LastPredictedDir = nil
            Aimbot.VelocityHistory = {} 
        end
    else
        
        Aimbot.CurrentTarget = nil
        Aimbot.IsAiming = false
        Aimbot.TargetPosition = nil
        Aimbot.LastPredictedDir = nil 
        Aimbot.VelocityHistory = {}
    end

    Aimbot.ApplyNoRecoil(Settings)
    Aimbot.ApplyFastShoot(Settings)
    Aimbot.ApplyJumpShot(Settings)
    Aimbot.ApplySpider(Settings)
    Aimbot.ApplySpeedHack(Settings, deltaTime)
    Aimbot.ApplyWaterSpeedHack(Settings, deltaTime)
    Aimbot.ApplyFreeCam(Settings)
    Aimbot.ApplyThirdPerson(Settings)
    Aimbot.ApplyGodMode(Settings)
    Aimbot.ApplyAntiAFK(Settings)
    Aimbot.ApplyZoom(Settings)
    
    
    
    Aimbot.ApplyAntiAim(Settings)

    
    if Aimbot.FOVCircle then
        local enabled = Settings.fovCircleEnabled
        Aimbot.FOVCircle.Visible = enabled
        
        if enabled then
            local radius = Settings.fovSize or 90
            local mousePos = UserInputService:GetMouseLocation()
            
            Aimbot.FOVCircle.Size = UDim2.new(0, radius * 2, 0, radius * 2)
            
            Aimbot.FOVCircle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
        end
    end

    
    if Aimbot.TargetLine then
        local target = currentFrameTarget
        local showLine = Settings.targetLineEnabled and target ~= nil and target.targetPart ~= nil
        
        if showLine then
            local camera = workspace.CurrentCamera
            if camera then
                local targetPos, onScreen = camera:WorldToViewportPoint(target.targetPart.Position)
                
                if onScreen and targetPos.Z > 0 then
                    
                    local visualPart = target.targetPart
                    pcall(function()
                        local char = Utils.getCharacter(target.player)
                        if char then
                            
                            visualPart = char:FindFirstChild("Head") 
                                or char:FindFirstChild("UpperTorso") 
                                or char:FindFirstChild("Torso") 
                                or char:FindFirstChild("HumanoidRootPart")
                                or char:FindFirstChild("Middle")
                                or char:FindFirstChild("Center")
                                or char:FindFirstChild("Chest")
                                or target.targetPart
                        end
                    end)
                    
                    
                    local success, visualPos = pcall(function() return visualPart.Position end)
                    if not success or not visualPos then
                        visualPos = target.targetPart.Position
                    end
                    
                    
                    local screenPos, visualOnScreen = camera:WorldToViewportPoint(visualPos)
                    
                    
                    local startPos = UserInputService:GetMouseLocation()
                    
                    
                    
                    
                    local endPos = Vector2.new(screenPos.X, screenPos.Y)
                    
                    
                    if Aimbot.TargetLineLastPos and typeof(Aimbot.TargetLineLastPos) == "Vector2" then
                        endPos = Aimbot.TargetLineLastPos:Lerp(endPos, 0.9) 
                    end
                    Aimbot.TargetLineLastPos = endPos
                    
                    local diff = endPos - startPos
                    local dist = diff.Magnitude
                    local radius = Settings.fovSize or 90
                    
                    
                    if dist > 1 and dist <= (radius * 2.0) then
                        
                        
                        local midPoint = (startPos + endPos) / 2
                        local angle = math.atan2(diff.Y, diff.X)
                        local thickness = Settings.crosshairThickness or 1
                        
                        Aimbot.TargetLine.Visible = true
                        Aimbot.TargetLine.Size = UDim2.new(0, dist, 0, thickness)
                        Aimbot.TargetLine.Position = UDim2.new(0, midPoint.X, 0, midPoint.Y)
                        Aimbot.TargetLine.Rotation = math.deg(angle)
                        Aimbot.TargetLine.BackgroundColor3 = Settings.targetLineColor or Color3.new(1, 1, 1)
                    else
                        Aimbot.TargetLine.Visible = false
                        Aimbot.TargetLineLastPos = nil
                    end
                else
                    Aimbot.TargetLine.Visible = false
                    Aimbot.TargetLineLastPos = nil
                end
            else
                Aimbot.TargetLine.Visible = false
                Aimbot.TargetLineLastPos = nil
            end
        else
            Aimbot.TargetLine.Visible = false
            Aimbot.TargetLineLastPos = nil
        end
    end
end

function Aimbot.Remove()
    if Aimbot.FreeCamActive then
        local camera = workspace.CurrentCamera
        if camera then
            camera.CameraType = Aimbot.OriginalCameraType or Enum.CameraType.Custom
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        Aimbot.FreeCamActive = false
        
        
        local character = LocalPlayer.Character
        if character and Exploits.OriginalCollision then
            for part, originalValue in pairs(Exploits.OriginalCollision) do
                if part and part.Parent then
                    part.CanCollide = originalValue
                end
            end
            Exploits.OriginalCollision = nil
        end
    end

    if Aimbot.FOVScreenGui then
        Aimbot.FOVScreenGui:Destroy()
        Aimbot.FOVScreenGui = nil
        Aimbot.FOVCircle = nil
        Aimbot.TargetLine = nil
    end
    
    
    if Hitboxes.OriginalProperties then
        for part, props in pairs(Hitboxes.OriginalProperties) do
            if part and part.Parent then
                part.Size = props.Size
                part.Transparency = props.Transparency
                part.CanCollide = props.CanCollide
                local visual = part:FindFirstChild("HitboxVisual")
                if visual then visual:Destroy() end
            end
        end
        Hitboxes.OriginalProperties = {}
    end
    
    
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.AutoRotate = true end
    
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local rootJoint = rootPart:FindFirstChild("RootJoint") or (character:FindFirstChild("LowerTorso") and character.LowerTorso:FindFirstChild("Root"))
        if rootJoint then
            rootJoint.Transform = CFrame.new()
        end
    end
end

return Aimbot

end

_modules["modules/Ballistics"] = function()
local Ballistics = {}


local VELOCITY_NAMES = {"MuzzleVelocity", "Velocity", "Speed", "ProjectileSpeed", "BulletSpeed", "ShootVelocity", "ProjectileVelocity"}
local GRAVITY_NAMES = {"Gravity", "BulletGravity", "Drop", "ProjectileGravity", "BulletDrop", "ProjectileDrop", "Acceleration"}

function Ballistics.GetWeaponFromTool(tool)
    if not tool then return nil end
    
    local stats = {
        velocity = nil,
        gravity = nil
    }
    
    
    for _, name in ipairs(VELOCITY_NAMES) do
        local val = tool:GetAttribute(name)
        if val and type(val) == "number" and val > 0 then
            stats.velocity = val
            break
        end
    end
    
    for _, name in ipairs(GRAVITY_NAMES) do
        local val = tool:GetAttribute(name)
        if val and type(val) == "number" then
            stats.gravity = val
            break
        end
    end
    
    
    if not stats.velocity or not stats.gravity then
        for _, v in ipairs(tool:GetChildren()) do
            if v:IsA("ValueBase") then
                local vName = v.Name
                if not stats.velocity then
                    for _, name in ipairs(VELOCITY_NAMES) do
                        if vName == name then
                            stats.velocity = v.Value
                            break
                        end
                    end
                end
                if not stats.gravity then
                    for _, name in ipairs(GRAVITY_NAMES) do
                        if vName == name then
                            stats.gravity = v.Value
                            break
                        end
                    end
                end
            end
        end
    end
    
    
    if not stats.velocity or not stats.gravity then
        local config = tool:FindFirstChild("Settings") or tool:FindFirstChild("Config") or tool:FindFirstChild("Configuration") or tool:FindFirstChild("GunSettings")
        if config then
            if config:IsA("ModuleScript") then
                local success, moduleData = pcall(require, config)
                if success and type(moduleData) == "table" then
                    if not stats.velocity then
                        for _, name in ipairs(VELOCITY_NAMES) do
                            if moduleData[name] and type(moduleData[name]) == "number" then
                                stats.velocity = moduleData[name]
                                break
                            end
                        end
                    end
                    if not stats.gravity then
                        for _, name in ipairs(GRAVITY_NAMES) do
                            if moduleData[name] and type(moduleData[name]) == "number" then
                                stats.gravity = moduleData[name]
                                break
                            end
                        end
                    end
                end
            else
                for _, v in ipairs(config:GetChildren()) do
                    if v:IsA("ValueBase") then
                        local vName = v.Name
                        if not stats.velocity then
                            for _, name in ipairs(VELOCITY_NAMES) do
                                if vName == name then
                                    stats.velocity = v.Value
                                    break
                                end
                            end
                        end
                        if not stats.gravity then
                            for _, name in ipairs(GRAVITY_NAMES) do
                                if vName == name then
                                    stats.gravity = v.Value
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    
    if not stats.velocity or not stats.gravity then
        local fastCastData = tool:FindFirstChild("FastCastSettings")
        if fastCastData and fastCastData:IsA("ModuleScript") then
            local success, fcSettings = pcall(require, fastCastData)
            if success and type(fcSettings) == "table" then
                stats.velocity = stats.velocity or fcSettings.Velocity or fcSettings.MuzzleVelocity
                stats.gravity = stats.gravity or fcSettings.Gravity or fcSettings.Acceleration
            end
        end
    end

    
    if not stats.velocity or not stats.gravity then
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("ValueBase") then
                local name = v.Name:lower()
                if not stats.velocity and (name:find("velocity") or name:find("muzzle") or (name:find("speed") and not name:find("walk"))) then
                    if type(v.Value) == "number" and v.Value > 1 then
                        stats.velocity = v.Value
                    end
                elseif not stats.gravity and (name:find("gravity") or name:find("drop") or name:find("accel")) then
                    if type(v.Value) == "number" then
                        stats.gravity = v.Value
                    end
                end
            end
            if stats.velocity and stats.gravity then break end
        end
    end

    
    if stats.velocity and type(stats.velocity) == "number" then
        if stats.velocity <= 0 then stats.velocity = nil end
    end
    
    if stats.gravity and type(stats.gravity) == "number" then
        
        stats.gravity = math.abs(stats.gravity)
    end

    return (stats.velocity or stats.gravity) and stats or nil
end

function Ballistics.GetConfig()
    local player = game:GetService("Players").LocalPlayer
    local tool = player and player.Character and player.Character:FindFirstChildWhichIsA("Tool")
    
    
    if tool then
        local dynamicStats = Ballistics.GetWeaponFromTool(tool)
        if dynamicStats then
            return {
                velocity = dynamicStats.velocity or 1000,
                gravity = dynamicStats.gravity or 196.2
            }
        end
    end
    
    
    
    
    
    return nil
end

return Ballistics

end

_modules["modules/BulletTracer"] = function()
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local BulletTracer = {}


function BulletTracer.DrawSegment(startPos, endPos, color, duration, thickness, parent)
    local dist = (endPos - startPos).Magnitude
    if dist < 0.05 then return end
    
    
    local actualThickness = thickness * 0.6
    
    local part = Instance.new("Part")
    part.Name = "TracerSegment"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Shape = Enum.PartType.Cylinder 
    part.Color = color
    part.Size = Vector3.new(dist, actualThickness, actualThickness) 
    
    
    part.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(dist/2, 0, 0)
    part.Transparency = 0
    part.Parent = parent
    
    
    task.spawn(function()
        local startTime = tick()
        while part and part.Parent do
            local elapsed = tick() - startTime
            if elapsed >= duration then break end
            
            part.Transparency = elapsed / duration
            task.wait()
        end
        if part and part.Parent then
            part:Destroy()
        end
    end)
end


function BulletTracer.Create(origin, direction, velocity, gravity, settings)
    if not settings or not settings.bulletTracerEnabled then return end
    
    local color = settings.bulletTracerColor or Color3.fromRGB(255, 0, 0)
    local duration = settings.bulletTracerDuration or 2
    local thickness = settings.bulletTracerThickness or 0.1
    local usePhysics = settings.bulletTracerPhysics
    
    
    local folder = workspace:FindFirstChild("BulletTracers")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "BulletTracers"
        folder.Parent = workspace
    end
    
    
    local dirUnit = direction.Unit
    if dirUnit.X ~= dirUnit.X then 
        return 
    end
    
    
    if not usePhysics or not gravity or gravity == 0 then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local char = Players.LocalPlayer.Character
        if char then
             raycastParams.FilterDescendantsInstances = {char, folder}
        else
             raycastParams.FilterDescendantsInstances = {folder}
        end
        
        local rayResult = workspace:Raycast(origin, dirUnit * 1000, raycastParams)
        local endPos = rayResult and rayResult.Position or (origin + dirUnit * 1000)
        
        BulletTracer.DrawSegment(origin, endPos, color, duration, thickness, folder)
        return
    end
    
    
    local currentPos = origin
    local currentVel = dirUnit * velocity
    local stepTime = 0.03 
    local maxTime = 4.0   
    local gVec = Vector3.new(0, -gravity, 0)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local char = Players.LocalPlayer.Character
    if char then
        raycastParams.FilterDescendantsInstances = {char, folder}
    else
        raycastParams.FilterDescendantsInstances = {folder}
    end
    
    for t = 0, maxTime, stepTime do
        
        
        local nextPos = currentPos + (currentVel * stepTime) + (0.5 * gVec * (stepTime * stepTime))
        local segmentDir = nextPos - currentPos
        
        
        local rayResult = workspace:Raycast(currentPos, segmentDir, raycastParams)
        if rayResult then
            BulletTracer.DrawSegment(currentPos, rayResult.Position, color, duration, thickness, folder)
            break
        end
        
        
        BulletTracer.DrawSegment(currentPos, nextPos, color, duration, thickness, folder)
        
        
        currentPos = nextPos
        currentVel = currentVel + (gVec * stepTime)
        
        
        if currentPos.Y < -500 or (currentPos - origin).Magnitude > 5000 then break end
    end
end

return BulletTracer

end

_modules["modules/ConfigManager"] = function()
local HttpService = game:GetService("HttpService")

local ConfigManager = {
    Folder = "Withonium/Configs"
}

function ConfigManager.Init()
    local success, err = pcall(function()
        if not isfolder("Withonium") then
            makefolder("Withonium")
        
        end
        if not isfolder(ConfigManager.Folder) then
            makefolder(ConfigManager.Folder)
        end
    end)
    return success
end

function ConfigManager.Serialize(settings)
    local serialized = {}
    for k, v in pairs(settings) do
        if typeof(v) == "Color3" then
            serialized[k] = {Type = "Color3", Value = {v.R, v.G, v.B}}
        elseif typeof(v) == "EnumItem" then
            serialized[k] = {Type = "EnumItem", Enum = tostring(v.EnumType), Value = v.Name}
        elseif type(v) == "table" and k == "crosshairSettings" then
            
            serialized[k] = v
        elseif type(v) ~= "function" and type(v) ~= "table" then
            serialized[k] = v
        end
    end
    return HttpService:JSONEncode(serialized)
end

function ConfigManager.Deserialize(json, settings)
    local data = HttpService:JSONDecode(json)
    for k, v in pairs(data) do
        if type(v) == "table" and v.Type then
            if v.Type == "Color3" then
                settings[k] = Color3.new(v.Value[1], v.Value[2], v.Value[3])
            elseif v.Type == "EnumItem" then
                local enumType = v.Enum:gsub("Enum.", "")
                pcall(function()
                    settings[k] = Enum[enumType][v.Value]
                end)
            end
        else
            settings[k] = v
        end
    end
end

function ConfigManager.Save(name, settings)
    ConfigManager.Init()
    local success, err = pcall(function()
        local path = ConfigManager.Folder .. "/" .. name .. ".json"
        local json = ConfigManager.Serialize(settings)
        writefile(path, json)
    end)
    return success
end

function ConfigManager.Load(name, settings)
    local success, result = pcall(function()
        local path = ConfigManager.Folder .. "/" .. name .. ".json"
        if isfile(path) then
            local json = readfile(path)
            ConfigManager.Deserialize(json, settings)
            return true
        
        end
        return false
    end)
    return success and result
end

function ConfigManager.List()
    ConfigManager.Init()
    local success, result = pcall(function()
        local files = listfiles(ConfigManager.Folder)
        local configs = {}
        for _, file in ipairs(files) do
            
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
        return configs
    end)
    return success and result or {}
end

function ConfigManager.Delete(name)
    local path = ConfigManager.Folder .. "/" .. name .. ".json"
    if isfile(path) then
        delfile(path)
    end
end

return ConfigManager

end

_modules["modules/Crosshair"] = function()
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Crosshair = {
    MainFrame = nil,
    ScreenGui = nil,
    Segments = {},
    Enabled = false,
    CurrentType = "Default",
    Rotation = 0
}

function Crosshair.GetCenter()
    return UserInputService:GetMouseLocation()
end

function Crosshair.Clear()
    if Crosshair.MainFrame then
        Crosshair.MainFrame:Destroy()
        Crosshair.MainFrame = nil
    end
    Crosshair.Segments = {}
end

function Crosshair.Init()
    local gui_parent = nil
    pcall(function()
        if gethui then gui_parent = gethui()
        elseif game:GetService("CoreGui") then gui_parent = game:GetService("CoreGui")
        else gui_parent = LocalPlayer:WaitForChild("PlayerGui") end
    end)

    if not gui_parent then return end

    local sg = Instance.new("ScreenGui")
    sg.Name = "WithoniumCrosshair"
    sg.DisplayOrder = 1000
    sg.IgnoreGuiInset = true
    sg.Parent = gui_parent
    Crosshair.ScreenGui = sg
end

function Crosshair.CreateSegment(parent, size, pos, rotation)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.new(1, 1, 1) 
    frame.BorderSizePixel = 0
    frame.Active = false
    frame.Selectable = false
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = size
    frame.Position = pos
    frame.Rotation = rotation or 0
    frame.Parent = parent
    return frame
end

function Crosshair.Update(Settings)
    if not Settings.crosshairEnabled then
        if Crosshair.Enabled then
            Crosshair.Clear()
            Crosshair.Enabled = false
            UserInputService.MouseIconEnabled = true
        end
        return
    end

    Crosshair.Enabled = true
    UserInputService.MouseIconEnabled = false

    local mousePos = Crosshair.GetCenter()
    local color = Settings.crosshairColor or Color3.fromRGB(255, 0, 0)
    local size = Settings.crosshairSize or 10
    local thickness = Settings.crosshairThickness or 1
    local type = Settings.crosshairType or "Default"

    if not Crosshair.MainFrame or Crosshair.CurrentType ~= type then
        Crosshair.Clear()
        Crosshair.CurrentType = type
        
        Crosshair.MainFrame = Instance.new("Frame")
        Crosshair.MainFrame.BackgroundTransparency = 1
        Crosshair.MainFrame.Size = UDim2.new(0, 0, 0, 0)
        Crosshair.MainFrame.Parent = Crosshair.ScreenGui

        if type == "Default" then
            
            table.insert(Crosshair.Segments, Crosshair.CreateSegment(Crosshair.MainFrame, UDim2.new(0, thickness, 0, size * 2), UDim2.new(0, 0, 0, 0)))
            
            table.insert(Crosshair.Segments, Crosshair.CreateSegment(Crosshair.MainFrame, UDim2.new(0, size * 2, 0, thickness), UDim2.new(0, 0, 0, 0)))
        elseif type == "X" then
            
            table.insert(Crosshair.Segments, Crosshair.CreateSegment(Crosshair.MainFrame, UDim2.new(0, thickness, 0, size * 2), UDim2.new(0, 0, 0, 0), 45))
            
            table.insert(Crosshair.Segments, Crosshair.CreateSegment(Crosshair.MainFrame, UDim2.new(0, thickness, 0, size * 2), UDim2.new(0, 0, 0, 0), -45))
        elseif type == "Swastika" then
            
            for i = 1, 8 do
                table.insert(Crosshair.Segments, Crosshair.CreateSegment(Crosshair.MainFrame, UDim2.new(0, size, 0, thickness), UDim2.new(0, 0, 0, 0)))
            end
        end
    end

    
    Crosshair.MainFrame.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)

    
    if type == "Swastika" then
        Crosshair.Rotation = (Crosshair.Rotation + 2) % 360
        Crosshair.MainFrame.Rotation = Crosshair.Rotation
        
        local halfSize = size / 2
        
        
        Crosshair.Segments[1].Position = UDim2.new(0, halfSize, 0, 0)
        Crosshair.Segments[1].Size = UDim2.new(0, size, 0, thickness)
        Crosshair.Segments[2].Position = UDim2.new(0, size, 0, halfSize)
        Crosshair.Segments[2].Size = UDim2.new(0, thickness, 0, size)
        
        
        Crosshair.Segments[3].Position = UDim2.new(0, 0, 0, halfSize)
        Crosshair.Segments[3].Size = UDim2.new(0, thickness, 0, size)
        Crosshair.Segments[4].Position = UDim2.new(0, -halfSize, 0, size)
        Crosshair.Segments[4].Size = UDim2.new(0, size, 0, thickness)
        
        
        Crosshair.Segments[5].Position = UDim2.new(0, -halfSize, 0, 0)
        Crosshair.Segments[5].Size = UDim2.new(0, size, 0, thickness)
        Crosshair.Segments[6].Position = UDim2.new(0, -size, 0, -halfSize)
        Crosshair.Segments[6].Size = UDim2.new(0, thickness, 0, size)
        
        
        Crosshair.Segments[7].Position = UDim2.new(0, 0, 0, -halfSize)
        Crosshair.Segments[7].Size = UDim2.new(0, thickness, 0, size)
        Crosshair.Segments[8].Position = UDim2.new(0, halfSize, 0, -size)
        Crosshair.Segments[8].Size = UDim2.new(0, size, 0, thickness)
    end

    
    for _, segment in ipairs(Crosshair.Segments) do
        segment.BackgroundColor3 = color
        if type ~= "Swastika" then
            if type == "Default" then
                if segment.Size.X.Offset > segment.Size.Y.Offset then
                    segment.Size = UDim2.new(0, size * 2, 0, thickness)
                else
                    segment.Size = UDim2.new(0, thickness, 0, size * 2)
                end
            elseif type == "X" then
                segment.Size = UDim2.new(0, thickness, 0, size * 2.5) 
            end
        end
    end
end

function Crosshair.Unload()
    Crosshair.Clear()
    if Crosshair.ScreenGui then
        Crosshair.ScreenGui:Destroy()
        Crosshair.ScreenGui = nil
    end
    UserInputService.MouseIconEnabled = true
end

return Crosshair

end

_modules["modules/ESP"] = function()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")


local State = require("modules/ESP/State")
local Skeleton = require("modules/ESP/Skeleton")
local Chams = require("modules/ESP/Chams")
local Labels = require("modules/ESP/Labels")
local Healthbars = require("modules/ESP/Healthbars")

local ESP = {
    Data = State.Data,
    Highlights = State.Highlights,
    Labels = State.Labels,
    Skeletons = State.Skeletons,
    Healthbars = State.Healthbars,
    Container = State.Container,
    PlayersWithDist = {}, 
    PlayerDataPool = {}, 
    LastUpdate = 0
}

function ESP.Create(player)
    State.Create(player)
end

function ESP.Remove(player)
    pcall(function() Chams.Destroy(player) end)
    pcall(function() Labels.Destroy(player) end)
    pcall(function() Skeleton.Destroy(player) end)
    pcall(function() Healthbars.Destroy(player) end)
    if State.Data then
        State.Data[player] = nil
    end
end

function ESP.Update(Settings, deltaTime, Utils)
    local now = tick()
    if now - ESP.LastUpdate < 0.033 then return end 
    ESP.LastUpdate = now

    local Camera = workspace.CurrentCamera
    if not Camera then return end
    
    local activeHighlights = 0
    local maxHighlights = 15 
    
    
    local playersWithDist = ESP.PlayersWithDist
    local pool = ESP.PlayerDataPool
    
    
    for i = 1, #playersWithDist do
        local data = playersWithDist[i]
        data.Player = nil
        data.Character = nil
        data.RootPart = nil
        table.insert(pool, data)
        playersWithDist[i] = nil
    end
    
    local allPlayers = Players:GetPlayers()
    
    
    for player, _ in pairs(State.Data) do
        if not Players:GetPlayerByUserId(player.UserId) then
            ESP.Remove(player)
        end
    end

    for i = 1, #allPlayers do
        local player = allPlayers[i]
        if player == LocalPlayer then continue end
        
        local character = Utils.getCharacter(player)
        local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Middle"))
        
        local dist = 999999
        if rootPart then
            dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
        end
        
        
        local data = table.remove(pool) or {}
        data.Player = player
        data.Distance = dist
        data.Character = character
        data.RootPart = rootPart
        
        table.insert(playersWithDist, data)
    end
    
    table.sort(playersWithDist, function(a, b)
        return a.Distance < b.Distance
    end)

    local maxDistStuds = Settings.espMaxDistance or 700
    
    for i = 1, #playersWithDist do
        local data = playersWithDist[i]
        local player = data.Player
        local character = data.Character
        local rootPart = data.RootPart
        local distance = data.Distance
        
        
        local isTeammate = false
        if player and LocalPlayer then
            
            if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                isTeammate = true
            end
            
            
            if not isTeammate and player.TeamColor and LocalPlayer.TeamColor then
                if player.TeamColor == LocalPlayer.TeamColor then
                    isTeammate = true
                end
            end
            
            
            if isTeammate and player.Neutral and LocalPlayer.Neutral then
                if player.Neutral == true and LocalPlayer.Neutral == true then
                    isTeammate = false
                end
            end
            
            
            if not isTeammate and character and LocalPlayer.Character then
                local playerTeamAttr = character:GetAttribute("Team") or character:GetAttribute("team") or character:GetAttribute("TeamID")
                local localTeamAttr = LocalPlayer.Character:GetAttribute("Team") or LocalPlayer.Character:GetAttribute("team") or LocalPlayer.Character:GetAttribute("TeamID")
                
                if playerTeamAttr and localTeamAttr and playerTeamAttr == localTeamAttr then
                    isTeammate = true
                end
            end
            
            
            if not isTeammate and character and LocalPlayer.Character then
                local function getMainColor(char)
                    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
                    if torso and torso:IsA("BasePart") then
                        return torso.Color
                    end
                    return nil
                end
                
                local playerColor = getMainColor(character)
                local localColor = getMainColor(LocalPlayer.Character)
                
                if playerColor and localColor then
                    local colorDiff = (playerColor.R - localColor.R)^2 + (playerColor.G - localColor.G)^2 + (playerColor.B - localColor.B)^2
                    if colorDiff < 0.01 then 
                        isTeammate = true
                    end
                end
            end
        end
        
        
        if not Settings.espDrawTeammates and isTeammate then
            Chams.Cleanup(player)
            Labels.Cleanup(player)
            Skeleton.Cleanup(player)
            Healthbars.Cleanup(player)
            continue
        end
        
        if not rootPart or not character then 
            ESP.Remove(player)
            continue 
        end

        local isWithinDistance = distance <= maxDistStuds
        
        if not isWithinDistance then
            Chams.Cleanup(player)
            Labels.Cleanup(player)
            Skeleton.Cleanup(player)
            Healthbars.Cleanup(player)
            continue
        end

        
        if State.Data[player] and State.Data[player].LastCharacter ~= character then
            ESP.Remove(player)
        end
        
        State.Create(player)
        State.Data[player].LastCharacter = character
        
        local humanoid = character:FindFirstChild("Humanoid")
        
        
        if Chams.Update(player, character, humanoid, Settings, activeHighlights, maxHighlights) then
            activeHighlights = activeHighlights + 1
        end

        
        if Settings.espEnabled and Settings.espSkeleton and character and humanoid and humanoid.Health > 0 and character.Parent then
            Skeleton.Draw(player, character, Settings)
        else
            Skeleton.Cleanup(player)
        end

        
        Labels.Update(player, character, rootPart, humanoid, Settings, distance, isWithinDistance)

        
        Healthbars.Update(player, character, rootPart, humanoid, Settings, isWithinDistance)
    end
end

return ESP

end

_modules["modules/GUI"] = function()
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer


local function loadWithTimeout(url: string, timeout: number?): ...any
	if type(url) ~= "string" then return false, "URL must be a string" end
	url = url:gsub("^%s*(.-)%s*$", "%1")
	if not url:find("^http") then return false, "Invalid protocol" end

	timeout = timeout or 15
	local requestCompleted = false
	local success, result = false, nil

	local requestThread = task.spawn(function()
		local fetchSuccess, fetchResult
		
		
		local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request
		if requestFunc then
			fetchSuccess, fetchResult = pcall(function()
				local res = requestFunc({
					Url = url,
					Method = "GET"
				})
				if res and res.StatusCode == 200 then
					return res.Body
				end
				error(res and ("HTTP " .. tostring(res.StatusCode)) or "Unknown error!")
			end)
		else
			
			for i = 1, 3 do
				fetchSuccess, fetchResult = pcall(function()
					return game:HttpGet(url)
				end)
				if fetchSuccess and fetchResult and #fetchResult > 0 then break end
				task.wait(1)
			end
		end

		if not fetchSuccess or not fetchResult or #fetchResult == 0 then
			success, result = false, fetchResult or "Empty response"
			requestCompleted = true
			return
		end

		local execSuccess, execResult = pcall(function()
			local f, err = loadstring(fetchResult)
			if f then return f() end
			error(err)
		end)
		success, result = execSuccess, execResult
		requestCompleted = true
	end)

	task.delay(timeout, function()
		if not requestCompleted then
			task.cancel(requestThread)
			success, result = false, "Request timed out"
			requestCompleted = true
		end
	end)

	while not requestCompleted do task.wait() end
	return success, result
end

local function loadLibrary(): any
    	
	local success, result = pcall(function()
		if isfile("WithoniumRTY.lua") then
			local content = readfile("WithoniumRTY.lua")
			local f, err = loadstring(content)
			if f then return f() end
			error(err)
		end
		error("No local file")
	end)

	local success, result = loadWithTimeout("https://raw.githubusercontent.com/nihmadev/Withonium/refs/heads/main/WithoniumRTY.lua")
	if success and result then
		return result
	end
	
	error("Failed to load WithoniumRTY: " .. tostring(result))
end

local WithoniumRTY = loadLibrary()

local function ensureLogo(url: string)
    local fileName = "withonium_logo.png"
    local getAsset = getcustomasset or get_custom_asset or (syn and syn.get_custom_asset)
    
    if not getAsset then 
        warn("[Withonium] getcustomasset not found. Your executor might not support local assets.")
        return nil 
    end

    local success, exists = pcall(function() return isfile(fileName) end)
    if not success or not exists then
        print("[Withonium] Downloading logo...")
        local downloadSuccess = pcall(function()
            local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request
            local body
            if requestFunc then
                local res = requestFunc({
                    Url = url,
                    Method = "GET"
                })
                if res and res.StatusCode == 200 then
                    body = res.Body
                end
            else
                body = game:HttpGet(url)
            end
            
            if body and #body > 0 then
                writefile(fileName, body)
                print("[Withonium] Logo saved to " .. fileName)
                return true
            end
            return false
        end)
        if not downloadSuccess then 
            warn("[Withonium] Failed to download logo.")
            return nil 
        end
    end
    
    local assetId
    local assetSuccess = pcall(function()
        assetId = getAsset(fileName)
    end)
    
    if not assetSuccess or not assetId then
        warn("[Withonium] getcustomasset failed to convert logo.")
        return nil
    end
    
    return assetId
end

local GUI = {
    Window = nil,
    Tabs = {},
    ConfigManager = nil,
    UnloadCallback = nil,
    ConfigName = "shlepa228",
    CurrentTab = "Aimbot",
    
    
    Watermark = {
        Frame = nil,
        Text = nil,
        Avatar = nil
    },
    KeybindList = {
        Frame = nil,
        Container = nil,
        Items = {}
    },
    FrameCount = 0,
    LastWatermarkUpdate = 0,

    
    Elements = {
        Toggles = {}
    },

    
    ScreenGui = nil
}


local function getKeyName(key)
    if not key then return "None" end
    local str = tostring(key)
    str = str:gsub("Enum.KeyCode.", "")
    str = str:gsub("Enum.UserInputType.", "")
    return str
end


local function setKeybind(Key, Settings, SettingName)
    if not Key then return end
    
    
    local success, result = pcall(function() return Enum.KeyCode[Key] end)
    if success and result then
        Settings[SettingName] = result
        return
    end
    
    
    success, result = pcall(function() return Enum.UserInputType[Key] end)
    if success and result then
        Settings[SettingName] = result
    end
end

function GUI.Init(Settings, Utils, UnloadCallback, ConfigManager, ItemSpawner)
    GUI.ConfigManager = ConfigManager
    GUI.UnloadCallback = UnloadCallback
    
    
    local gui_parent = nil
    pcall(function()
        if gethui then gui_parent = gethui()
        elseif game:GetService("CoreGui") then gui_parent = game:GetService("CoreGui")
        else gui_parent = LocalPlayer:WaitForChild("PlayerGui") end
    end)

    if gui_parent then
        GUI.ScreenGui = Instance.new("ScreenGui")
        GUI.ScreenGui.Name = "WithoniumExternal"
        GUI.ScreenGui.ResetOnSpawn = false
        GUI.ScreenGui.DisplayOrder = 100
        GUI.ScreenGui.Parent = gui_parent
        GUI.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global 

        
        GUI.Watermark.Frame = Instance.new("Frame")
        GUI.Watermark.Frame.Name = "Watermark"
        GUI.Watermark.Frame.Parent = GUI.ScreenGui
        GUI.Watermark.Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        GUI.Watermark.Frame.Position = UDim2.new(0, 10, 0, 10)
        GUI.Watermark.Frame.Size = UDim2.new(0, 0, 0, 26)
        GUI.Watermark.Frame.AutomaticSize = Enum.AutomaticSize.X
        GUI.Watermark.Frame.Visible = Settings.watermarkEnabled
        
        local WMCorner = Instance.new("UICorner")
        WMCorner.CornerRadius = UDim.new(0, 6)
        WMCorner.Parent = GUI.Watermark.Frame
        
        local WMPadding = Instance.new("UIPadding")
        WMPadding.PaddingLeft = UDim.new(0, 6)
        WMPadding.PaddingRight = UDim.new(0, 8)
        WMPadding.Parent = GUI.Watermark.Frame

        local WMList = Instance.new("UIListLayout")
        WMList.FillDirection = Enum.FillDirection.Horizontal
        WMList.VerticalAlignment = Enum.VerticalAlignment.Center
        WMList.Padding = UDim.new(0, 8)
        WMList.Parent = GUI.Watermark.Frame

        GUI.Watermark.Avatar = Instance.new("ImageLabel")
        GUI.Watermark.Avatar.Name = "Avatar"
        GUI.Watermark.Avatar.BackgroundTransparency = 1
        GUI.Watermark.Avatar.Size = UDim2.new(0, 18, 0, 18)
        GUI.Watermark.Avatar.Parent = GUI.Watermark.Frame
        GUI.Watermark.Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
        
        local AvatarCorner = Instance.new("UICorner")
        AvatarCorner.CornerRadius = UDim.new(1, 0)
        AvatarCorner.Parent = GUI.Watermark.Avatar

        GUI.Watermark.Text = Instance.new("TextLabel")
        GUI.Watermark.Text.Name = "Text"
        GUI.Watermark.Text.BackgroundTransparency = 1
        GUI.Watermark.Text.Font = Enum.Font.GothamMedium
        GUI.Watermark.Text.TextColor3 = Color3.new(1, 1, 1)
        GUI.Watermark.Text.TextSize = 13
        GUI.Watermark.Text.Size = UDim2.new(0, 0, 1, 0)
        GUI.Watermark.Text.AutomaticSize = Enum.AutomaticSize.X
        GUI.Watermark.Text.Text = "Withonium | Initializing..."
        GUI.Watermark.Text.Parent = GUI.Watermark.Frame

        
        GUI.KeybindList.Frame = Instance.new("Frame")
        GUI.KeybindList.Frame.Name = "KeybindList"
        GUI.KeybindList.Frame.Parent = GUI.ScreenGui
        GUI.KeybindList.Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        GUI.KeybindList.Frame.Position = UDim2.new(0, 10, 0, 42)
        GUI.KeybindList.Frame.Size = UDim2.new(0, 220, 0, 0)
        GUI.KeybindList.Frame.AutomaticSize = Enum.AutomaticSize.Y
        GUI.KeybindList.Frame.Visible = Settings.watermarkEnabled
        
        local KBCorner = Instance.new("UICorner")
        KBCorner.CornerRadius = UDim.new(0, 6)
        KBCorner.Parent = GUI.KeybindList.Frame
        
        local KBStroke = Instance.new("UIStroke")
        KBStroke.Color = Color3.fromRGB(45, 45, 45)
        KBStroke.Thickness = 1
        KBStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        KBStroke.Parent = GUI.KeybindList.Frame
        
        local KBList = Instance.new("UIListLayout")
        KBList.Padding = UDim.new(0, 4)
        KBList.Parent = GUI.KeybindList.Frame

        local KBPadding = Instance.new("UIPadding")
        KBPadding.PaddingLeft = UDim.new(0, 8)
        KBPadding.PaddingRight = UDim.new(0, 8)
        KBPadding.PaddingTop = UDim.new(0, 6)
        KBPadding.PaddingBottom = UDim.new(0, 6)
        KBPadding.Parent = GUI.KeybindList.Frame

        local KBHeader = Instance.new("TextLabel")
        KBHeader.Name = "Header"
        KBHeader.BackgroundTransparency = 1
        KBHeader.Size = UDim2.new(1, 0, 0, 24)
        KBHeader.Font = Enum.Font.GothamBold
        KBHeader.Text = "Keybinds"
        KBHeader.TextColor3 = Color3.new(1, 1, 1)
        KBHeader.TextSize = 14
        KBHeader.Parent = GUI.KeybindList.Frame

        GUI.KeybindList.Container = Instance.new("Frame")
        GUI.KeybindList.Container.Name = "Items"
        GUI.KeybindList.Container.BackgroundTransparency = 1
        GUI.KeybindList.Container.Size = UDim2.new(1, 0, 0, 0)
        GUI.KeybindList.Container.AutomaticSize = Enum.AutomaticSize.Y
        GUI.KeybindList.Container.Parent = GUI.KeybindList.Frame
        
        local ItemsLayout = Instance.new("UIListLayout")
        ItemsLayout.Padding = UDim.new(0, 2)
        ItemsLayout.Parent = GUI.KeybindList.Container
    end
    
    GUI.Window = WithoniumRTY:CreateWindow({
        Name = "Withonium",
        LoadingTitle = "Withonium",
        LoadingSubtitle = "by nihmadev",
        Icon = "https://github.com/nihmadev/Withonium/raw/main/icon.png",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "Withonium",
            FileName = GUI.ConfigName
        },
        Discord = {
            Enabled = false,
            Invite = "noinvitelink",
            RememberJoins = true
        },
        KeySystem = false
    })

    
    local AimbotTab = GUI.Window:CreateTab("Aimbot", 9134785384)
    local AimbotMain, AimbotSide = AimbotTab:Split(0.5)
    
    AimbotMain:CreateSection("Silent Aim")
    GUI.Elements.Toggles["aimbotEnabled"] = AimbotMain:CreateToggle({
        Name = "Aimbot Enabled",
        CurrentValue = Settings.aimbotEnabled,
        Flag = "aimbotEnabled",
        Callback = function(Value) Settings.aimbotEnabled = Value end
    })
    GUI.Elements.Toggles["teamCheckEnabled"] = AimbotMain:CreateToggle({
        Name = "Team Check",
        CurrentValue = Settings.teamCheckEnabled,
        Flag = "teamCheckEnabled",
        Callback = function(Value) Settings.teamCheckEnabled = Value end
    })
    GUI.Elements.Toggles["silentAimEnabled"] = AimbotMain:CreateToggle({
        Name = "Silent Aim",
        CurrentValue = Settings.silentAimEnabled,
        Flag = "silentAimEnabled",
        Callback = function(Value) Settings.silentAimEnabled = Value end
    })
    AimbotMain:CreateKeybind({
        Name = "Silent Aim Key",
        CurrentKeybind = getKeyName(Settings.silentAimKey),
        HoldToInteract = (Settings.silentAimKeyMode == "Hold"),
        CallOnChange = true,
        Flag = "silentAimKey",
        Callback = function(Key) setKeybind(Key, Settings, "silentAimKey") end
    })
    AimbotMain:CreateDropdown({
        Name = "Silent Aim Mode",
        Options = {"Hold", "Toggle", "Always"},
        CurrentOption = {Settings.silentAimKeyMode},
        Flag = "silentAimKeyMode",
        Callback = function(Option) Settings.silentAimKeyMode = Option[1] end
    })

    AimbotMain:CreateSection("Magic Bullets")
    GUI.Elements.Toggles["magicBulletEnabled"] = AimbotMain:CreateToggle({
        Name = "Magic Bullet",
        CurrentValue = Settings.magicBulletEnabled,
        Flag = "magicBulletEnabled",
        Callback = function(Value) Settings.magicBulletEnabled = Value end
    })
    GUI.Elements.Toggles["magicBulletHouseCheck"] = AimbotMain:CreateToggle({
        Name = "Ignore Objects",
        CurrentValue = not Settings.magicBulletHouseCheck,
        Flag = "magicBulletHouseCheck",
        Callback = function(Value) Settings.magicBulletHouseCheck = not Value end
    })
    GUI.Elements.Toggles["visibleCheckEnabled"] = AimbotMain:CreateToggle({
        Name = "Visible Check",
        CurrentValue = Settings.visibleCheckEnabled,
        Flag = "visibleCheckEnabled",
        Callback = function(Value) Settings.visibleCheckEnabled = Value end
    })

    AimbotMain:CreateSection("Combat")
    GUI.Elements.Toggles["fastShootEnabled"] = AimbotMain:CreateToggle({
        Name = "Fast Shoot",
        CurrentValue = Settings.fastShootEnabled,
        Flag = "fastShootEnabled",
        Callback = function(Value) Settings.fastShootEnabled = Value end
    })
    AimbotMain:CreateSlider({
        Name = "Fast Shoot Multiplier",
        Range = {1, 5},
        Increment = 0.5,
        CurrentValue = Settings.fastShootMultiplier or 2.5,
        Flag = "fastShootMultiplier",
        Callback = function(Value) Settings.fastShootMultiplier = Value end
    })
    GUI.Elements.Toggles["noRecoilEnabled"] = AimbotMain:CreateToggle({
        Name = "No Recoil",
        CurrentValue = Settings.noRecoilEnabled,
        Flag = "noRecoilEnabled",
        Callback = function(Value) Settings.noRecoilEnabled = Value end
    })
    GUI.Elements.Toggles["jumpShotEnabled"] = AimbotMain:CreateToggle({
        Name = "Jump Shot",
        CurrentValue = Settings.jumpShotEnabled,
        Flag = "jumpShotEnabled",
        Callback = function(Value) Settings.jumpShotEnabled = Value end
    })
    AimbotMain:CreateKeybind({
        Name = "Jump Shot Key",
        CurrentKeybind = getKeyName(Settings.jumpShotKey),
        HoldToInteract = false,
        CallOnChange = true,
        Flag = "jumpShotKey",
        Callback = function(Key) setKeybind(Key, Settings, "jumpShotKey") end
    })

    AimbotSide:CreateSection("Zoom")
    GUI.Elements.Toggles["zoomEnabled"] = AimbotSide:CreateToggle({
        Name = "Zoom Enabled",
        CurrentValue = Settings.zoomEnabled,
        Flag = "zoomEnabled",
        Callback = function(Value) Settings.zoomEnabled = Value end
    })
    AimbotSide:CreateSlider({
        Name = "Zoom Amount",
        Range = {5, 60},
        Increment = 1,
        CurrentValue = Settings.zoomAmount,
        Flag = "zoomAmount",
        Callback = function(Value) Settings.zoomAmount = Value end
    })

    AimbotSide:CreateSection("Anti-Aim")
    GUI.Elements.Toggles["antiAimEnabled"] = AimbotSide:CreateToggle({
        Name = "Anti-Aim Enabled",
        CurrentValue = Settings.antiAimEnabled,
        Flag = "antiAimEnabled",
        Callback = function(Value) Settings.antiAimEnabled = Value end
    })
    AimbotSide:CreateKeybind({
        Name = "Anti-Aim Key",
        CurrentKeybind = getKeyName(Settings.antiAimKey),
        HoldToInteract = false,
        CallOnChange = true,
        Flag = "antiAimKey",
        Callback = function(Key) setKeybind(Key, Settings, "antiAimKey") end
    })
    AimbotSide:CreateDropdown({
        Name = "Anti-Aim Mode",
        Options = {"Spin", "Jitter", "Static"},
        CurrentOption = {Settings.antiAimMode},
        Flag = "antiAimMode",
        Callback = function(Option) Settings.antiAimMode = Option[1] end
    })
    AimbotSide:CreateSlider({
        Name = "Spin Speed",
        Range = {1, 100},
        Increment = 1,
        CurrentValue = Settings.antiAimSpeed,
        Flag = "antiAimSpeed",
        Callback = function(Value) Settings.antiAimSpeed = Value end
    })

    AimbotSide:CreateSection("Prediction")
    GUI.Elements.Toggles["ballisticsEnabled"] = AimbotSide:CreateToggle({
        Name = "Ballistics",
        CurrentValue = Settings.ballisticsEnabled,
        Flag = "ballisticsEnabled",
        Callback = function(Value) Settings.ballisticsEnabled = Value end
    })
    GUI.Elements.Toggles["projectilePredictionEnabled"] = AimbotSide:CreateToggle({
        Name = "Prediction",
        CurrentValue = Settings.projectilePredictionEnabled,
        Flag = "projectilePredictionEnabled",
        Callback = function(Value) Settings.projectilePredictionEnabled = Value end
    })
    AimbotSide:CreateSlider({
        Name = "Prediction Factor",
        Range = {0.1, 2.0},
        Increment = 0.1,
        CurrentValue = Settings.predictionFactor,
        Flag = "predictionFactor",
        Callback = function(Value) Settings.predictionFactor = Value end
    })
    AimbotSide:CreateSlider({
        Name = "Prediction Smooth",
        Range = {0.05, 1.0},
        Increment = 0.05,
        CurrentValue = Settings.predictionSmoothing,
        Flag = "predictionSmoothing",
        Callback = function(Value) Settings.predictionSmoothing = Value end
    })

    AimbotSide:CreateSection("Settings")
    GUI.Elements.Toggles["fovCircleEnabled"] = AimbotSide:CreateToggle({
        Name = "FOV Circle",
        CurrentValue = Settings.fovCircleEnabled,
        Flag = "fovCircleEnabled",
        Callback = function(Value) Settings.fovCircleEnabled = Value end
    })
    GUI.Elements.Toggles["targetLineEnabled"] = AimbotSide:CreateToggle({
        Name = "Target Line",
        CurrentValue = Settings.targetLineEnabled,
        Flag = "targetLineEnabled",
        Callback = function(Value) Settings.targetLineEnabled = Value end
    })
    AimbotSide:CreateColorPicker({
        Name = "Target Line Color",
        Color = Settings.targetLineColor,
        Flag = "targetLineColor",
        Callback = function(Value) Settings.targetLineColor = Value end
    })
    AimbotSide:CreateKeybind({
        Name = "Aim Key",
        CurrentKeybind = getKeyName(Settings.aimKey),
        HoldToInteract = (Settings.aimKeyMode == "Hold"),
        CallOnChange = true,
        Flag = "aimKey",
        Callback = function(Key) setKeybind(Key, Settings, "aimKey") end
    })
    AimbotSide:CreateDropdown({
        Name = "Aim Mode",
        Options = {"Hold", "Toggle", "Always"},
        CurrentOption = {Settings.aimKeyMode},
        Flag = "aimKeyMode",
        Callback = function(Option) Settings.aimKeyMode = Option[1] end
    })
    AimbotSide:CreateSlider({
        Name = "Smoothness",
        Range = {0.01, 1.0},
        Increment = 0.01,
        CurrentValue = Settings.smoothness,
        Flag = "smoothness",
        Callback = function(Value) Settings.smoothness = Value end
    })
    AimbotSide:CreateSlider({
        Name = "FOV Size",
        Range = {10, 800},
        Increment = 1,
        CurrentValue = Settings.fovSize,
        Flag = "fovSize",
        Callback = function(Value) Settings.fovSize = Value end
    })
    AimbotSide:CreateDropdown({
        Name = "Target Priority",
        Options = {"Distance", "Crosshair", "Balanced"},
        CurrentOption = {Settings.targetPriority},
        Flag = "targetPriority",
        Callback = function(Option) Settings.targetPriority = Option[1] end
    })
    AimbotSide:CreateDropdown({
        Name = "Target Part",
        Options = {"Head", "Torso", "Legs"},
        CurrentOption = {Settings.targetPart},
        Flag = "targetPart",
        Callback = function(Option) Settings.targetPart = Option[1] end
    })

    
    local VisualsTab = GUI.Window:CreateTab("Visuals", 9134780101)
    local VisualsMain, VisualsSide = VisualsTab:Split(0.5)
    
    VisualsMain:CreateSection("ESP")
    GUI.Elements.Toggles["espEnabled"] = VisualsMain:CreateToggle({
        Name = "ESP Enabled",
        CurrentValue = Settings.espEnabled,
        Flag = "espEnabled",
        Callback = function(Value) Settings.espEnabled = Value end
    })
    GUI.Elements.Toggles["espDrawTeammates"] = VisualsMain:CreateToggle({
        Name = "Draw Teammates",
        CurrentValue = Settings.espDrawTeammates,
        Flag = "espDrawTeammates",
        Callback = function(Value) Settings.espDrawTeammates = Value end
    })
    VisualsMain:CreateSlider({
        Name = "Max Distance",
        Range = {0, 2000},
        Increment = 10,
        CurrentValue = Settings.espMaxDistance,
        Flag = "espMaxDistance",
        Callback = function(Value) Settings.espMaxDistance = Value end
    })

    VisualsMain:CreateSection("Chams")
    GUI.Elements.Toggles["espHighlights"] = VisualsMain:CreateToggle({
        Name = "Chams",
        CurrentValue = Settings.espHighlights,
        Flag = "espHighlights",
        Callback = function(Value) Settings.espHighlights = Value end
    })
    VisualsMain:CreateDropdown({
        Name = "Chams Mode",
        Options = {"Default", "Glow", "Metal"},
        CurrentOption = {Settings.espChamsMode},
        Flag = "espChamsMode",
        Callback = function(Option) Settings.espChamsMode = Option[1] end
    })
    VisualsMain:CreateColorPicker({
        Name = "Fill Color",
        Color = Settings.espColor,
        Flag = "espColor",
        Callback = function(Value) Settings.espColor = Value end
    })
    VisualsMain:CreateColorPicker({
        Name = "Outline Color",
        Color = Settings.espOutlineColor,
        Flag = "espOutlineColor",
        Callback = function(Value) Settings.espOutlineColor = Value end
    })

    VisualsMain:CreateSection("Overlay")
    GUI.Elements.Toggles["espSkeleton"] = VisualsMain:CreateToggle({
        Name = "Skeleton",
        CurrentValue = Settings.espSkeleton,
        Flag = "espSkeleton",
        Callback = function(Value) Settings.espSkeleton = Value end
    })
    VisualsMain:CreateColorPicker({
        Name = "Skeleton Color",
        Color = Settings.espSkeletonColor,
        Flag = "espSkeletonColor",
        Callback = function(Value) Settings.espSkeletonColor = Value end
    })

    VisualsSide:CreateSection("Crosshair")
    GUI.Elements.Toggles["crosshairEnabled"] = VisualsSide:CreateToggle({
        Name = "Crosshair Enabled",
        CurrentValue = Settings.crosshairEnabled,
        Flag = "crosshairEnabled",
        Callback = function(Value) 
            Settings.crosshairEnabled = Value 
            if ConfigManager then ConfigManager.Save("autoload", Settings) end
        end
    })
    VisualsSide:CreateDropdown({
        Name = "Crosshair Type",
        Options = {"Default", "Swastika", "X"},
        CurrentOption = {Settings.crosshairType},
        Flag = "crosshairType",
        Callback = function(Option) 
            Settings.crosshairType = Option[1] 
            if ConfigManager then ConfigManager.Save("autoload", Settings) end
        end
    })
    VisualsSide:CreateColorPicker({
        Name = "Crosshair Color",
        Color = Settings.crosshairColor,
        Flag = "crosshairColor",
        Callback = function(Value) 
            Settings.crosshairColor = Value 
            if ConfigManager then ConfigManager.Save("autoload", Settings) end
        end
    })
    VisualsSide:CreateSlider({
        Name = "Crosshair Size",
        Range = {1, 100},
        Increment = 1,
        CurrentValue = Settings.crosshairSize,
        Flag = "crosshairSize",
        Callback = function(Value) 
            Settings.crosshairSize = Value 
            if ConfigManager then ConfigManager.Save("autoload", Settings) end
        end
    })
    VisualsSide:CreateSlider({
        Name = "Crosshair Thickness",
        Range = {1, 10},
        Increment = 1,
        CurrentValue = Settings.crosshairThickness,
        Flag = "crosshairThickness",
        Callback = function(Value) 
            Settings.crosshairThickness = Value 
            if ConfigManager then ConfigManager.Save("autoload", Settings) end
        end
    })
    GUI.Elements.Toggles["espNames"] = VisualsSide:CreateToggle({
        Name = "Show Names",
        CurrentValue = Settings.espNames,
        Flag = "espNames",
        Callback = function(Value) Settings.espNames = Value end
    })
    GUI.Elements.Toggles["espDistances"] = VisualsSide:CreateToggle({
        Name = "Show Distance",
        CurrentValue = Settings.espDistances,
        Flag = "espDistances",
        Callback = function(Value) Settings.espDistances = Value end
    })
    GUI.Elements.Toggles["espWeapons"] = VisualsSide:CreateToggle({
        Name = "Show Weapon",
        CurrentValue = Settings.espWeapons,
        Flag = "espWeapons",
        Callback = function(Value) Settings.espWeapons = Value end
    })
    GUI.Elements.Toggles["espIcons"] = VisualsSide:CreateToggle({
        Name = "Show Icons",
        CurrentValue = Settings.espIcons,
        Flag = "espIcons",
        Callback = function(Value) Settings.espIcons = Value end
    })
    GUI.Elements.Toggles["espEnemySlots"] = VisualsSide:CreateToggle({
        Name = "Enemy Slots",
        CurrentValue = Settings.espEnemySlots,
        Flag = "espEnemySlots",
        Callback = function(Value) Settings.espEnemySlots = Value end
    })
    GUI.Elements.Toggles["espHealthBar"] = VisualsSide:CreateToggle({
        Name = "Healthbar",
        CurrentValue = Settings.espHealthBar,
        Flag = "espHealthBar",
        Callback = function(Value) Settings.espHealthBar = Value end
    })

    VisualsSide:CreateSection("Bullet Tracer")
    GUI.Elements.Toggles["bulletTracerEnabled"] = VisualsSide:CreateToggle({
        Name = "Enabled",
        CurrentValue = Settings.bulletTracerEnabled,
        Flag = "bulletTracerEnabled",
        Callback = function(Value) Settings.bulletTracerEnabled = Value end
    })
    VisualsSide:CreateColorPicker({
        Name = "Tracer Color",
        Color = Settings.bulletTracerColor,
        Flag = "bulletTracerColor",
        Callback = function(Value) Settings.bulletTracerColor = Value end
    })
    VisualsSide:CreateSlider({
        Name = "Duration",
        Range = {0.1, 10},
        Increment = 0.1,
        CurrentValue = Settings.bulletTracerDuration,
        Flag = "bulletTracerDuration",
        Callback = function(Value) Settings.bulletTracerDuration = Value end
    })
    GUI.Elements.Toggles["bulletTracerPhysics"] = VisualsSide:CreateToggle({
        Name = "Use Physics",
        CurrentValue = Settings.bulletTracerPhysics,
        Flag = "bulletTracerPhysics",
        Callback = function(Value) Settings.bulletTracerPhysics = Value end
    })
    GUI.Elements.Toggles["espHealthBarText"] = VisualsSide:CreateToggle({
        Name = "Healthbar Text",
        CurrentValue = Settings.espHealthBarText,
        Flag = "espHealthBarText",
        Callback = function(Value) Settings.espHealthBarText = Value end
    })
    VisualsSide:CreateDropdown({
        Name = "Healthbar Pos",
        Options = {"Left", "Right", "Bottom", "Top"},
        CurrentOption = {Settings.espHealthBarPosition},
        Flag = "espHealthBarPosition",
        Callback = function(Option) Settings.espHealthBarPosition = Option[1] end
    })
    VisualsSide:CreateColorPicker({
        Name = "Text Color",
        Color = Settings.espTextColor,
        Flag = "espTextColor",
        Callback = function(Value) Settings.espTextColor = Value end
    })

    VisualsSide:CreateSection("World")
    GUI.Elements.Toggles["fullBrightEnabled"] = VisualsSide:CreateToggle({
        Name = "FullBright",
        CurrentValue = Settings.fullBrightEnabled,
        Flag = "fullBrightEnabled",
        Callback = function(Value) Settings.fullBrightEnabled = Value end
    })
    VisualsSide:CreateKeybind({
        Name = "FullBright Key",
        CurrentKeybind = getKeyName(Settings.FullBrightKey),
        HoldToInteract = false,
        CallOnChange = true,
        Flag = "FullBrightKey",
        Callback = function(Key) setKeybind(Key, Settings, "FullBrightKey") end
    })

    
    local PlayerTab = GUI.Window:CreateTab("Player", 10747373176)
    local PlayerMain, PlayerSide = PlayerTab:Split(0.5)
    
    PlayerMain:CreateSection("Helpers")
    GUI.Elements.Toggles["godModeEnabled"] = PlayerMain:CreateToggle({
        Name = "God Mode",
        CurrentValue = Settings.godModeEnabled,
        Flag = "godModeEnabled",
        Callback = function(Value) Settings.godModeEnabled = Value end
    })
    GUI.Elements.Toggles["spiderEnabled"] = PlayerMain:CreateToggle({
        Name = "Spider",
        CurrentValue = Settings.spiderEnabled,
        Flag = "spiderEnabled",
        Callback = function(Value) Settings.spiderEnabled = Value end
    })
    PlayerMain:CreateKeybind({
        Name = "Spider Key",
        CurrentKeybind = getKeyName(Settings.spiderKey),
        HoldToInteract = false,
        CallOnChange = true,
        Flag = "spiderKey",
        Callback = function(Key) setKeybind(Key, Settings, "spiderKey") end
    })
    
    GUI.Elements.Toggles["speedHackEnabled"] = PlayerMain:CreateToggle({
        Name = "SpeedHack",
        CurrentValue = Settings.speedHackEnabled,
        Flag = "speedHackEnabled",
        Callback = function(Value) Settings.speedHackEnabled = Value end
    })
    PlayerMain:CreateKeybind({
        Name = "Speed Key",
        CurrentKeybind = getKeyName(Settings.speedHackKey),
        HoldToInteract = false,
        CallOnChange = true,
        Flag = "speedHackKey",
        Callback = function(Key) setKeybind(Key, Settings, "speedHackKey") end
    })
    PlayerMain:CreateSlider({
        Name = "Speed Multiplier",
        Range = {1, 3},
        Increment = 0.1,
        CurrentValue = Settings.speedMultiplier,
        Flag = "speedMultiplier",
        Callback = function(Value) Settings.speedMultiplier = Value end
    })

    GUI.Elements.Toggles["waterSpeedHackEnabled"] = PlayerMain:CreateToggle({
        Name = "Water Speed",
        CurrentValue = Settings.waterSpeedHackEnabled,
        Flag = "waterSpeedHackEnabled",
        Callback = function(Value) Settings.waterSpeedHackEnabled = Value end
    })
    PlayerMain:CreateSlider({
        Name = "Water Speed Multi",
        Range = {1, 10},
        Increment = 0.5,
        CurrentValue = Settings.waterSpeedMultiplier,
        Flag = "waterSpeedMultiplier",
        Callback = function(Value) Settings.waterSpeedMultiplier = Value end
    })

    PlayerMain:CreateSection("Visuals")
    GUI.Elements.Toggles["noGrassEnabled"] = PlayerMain:CreateToggle({
        Name = "No Grass",
        CurrentValue = Settings.noGrassEnabled,
        Flag = "noGrassEnabled",
        Callback = function(Value) Settings.noGrassEnabled = Value end
    })
    GUI.Elements.Toggles["noFogEnabled"] = PlayerMain:CreateToggle({
        Name = "No Fog",
        CurrentValue = Settings.noFogEnabled,
        Flag = "noFogEnabled",
        Callback = function(Value) Settings.noFogEnabled = Value end
    })
    GUI.Elements.Toggles["thirdPersonEnabled"] = PlayerMain:CreateToggle({
        Name = "Third Person",
        CurrentValue = Settings.thirdPersonEnabled,
        Flag = "thirdPersonEnabled",
        Callback = function(Value) Settings.thirdPersonEnabled = Value end
    })
    PlayerMain:CreateSlider({
        Name = "TP Distance",
        Range = {5, 25},
        Increment = 1,
        CurrentValue = Settings.thirdPersonDistance,
        Flag = "thirdPersonDistance",
        Callback = function(Value) Settings.thirdPersonDistance = Value end
    })
    GUI.Elements.Toggles["freeCamEnabled"] = PlayerMain:CreateToggle({
        Name = "FreeCam",
        CurrentValue = Settings.freeCamEnabled,
        Flag = "freeCamEnabled",
        Callback = function(Value) Settings.freeCamEnabled = Value end
    })
    PlayerMain:CreateKeybind({
        Name = "FreeCam Key",
        CurrentKeybind = getKeyName(Settings.freeCamKey),
        HoldToInteract = false,
        CallOnChange = true,
        Flag = "freeCamKey",
        Callback = function(Key) setKeybind(Key, Settings, "freeCamKey") end
    })

    PlayerSide:CreateSection("Hitbox")
    GUI.Elements.Toggles["hitboxExpanderEnabled"] = PlayerSide:CreateToggle({
        Name = "Hitbox Expander",
        CurrentValue = Settings.hitboxExpanderEnabled,
        Flag = "hitboxExpanderEnabled",
        Callback = function(Value) Settings.hitboxExpanderEnabled = Value end
    })
    GUI.Elements.Toggles["hitboxExpanderShow"] = PlayerSide:CreateToggle({
        Name = "Hitbox Visible",
        CurrentValue = Settings.hitboxExpanderShow,
        Flag = "hitboxExpanderShow",
        Callback = function(Value) Settings.hitboxExpanderShow = Value end
    })
    PlayerSide:CreateSlider({
        Name = "Expander Size",
        Range = {1, 30},
        Increment = 1,
        CurrentValue = Settings.hitboxExpanderSize,
        Flag = "hitboxExpanderSize",
        Callback = function(Value) Settings.hitboxExpanderSize = Value end
    })

    PlayerSide:CreateSection("Anti-AFK")
    GUI.Elements.Toggles["antiAfkEnabled"] = PlayerSide:CreateToggle({
        Name = "Anti-AFK Enabled",
        CurrentValue = Settings.antiAfkEnabled,
        Flag = "antiAfkEnabled",
        Callback = function(Value) 
            Settings.antiAfkEnabled = Value 
            if Value then
                Settings.antiAfkLastActionTime = tick()
            end
        end
    })
    PlayerSide:CreateSlider({
        Name = "Interval (Min)",
        Range = {1, 60},
        Increment = 1,
        CurrentValue = Settings.antiAfkInterval,
        Flag = "antiAfkInterval",
        Callback = function(Value) Settings.antiAfkInterval = Value end
    })
    
    if ItemSpawner then
        PlayerSide:CreateSection("Item Spawner")
        
        local spawnerWindow = nil
        
        local function createSpawnerWindow()
            if spawnerWindow then return spawnerWindow end
            
            local frame = Instance.new("Frame")
            frame.Name = "ItemSpawnerWindow"
            frame.Size = UDim2.new(0, 500, 0, 400)
            frame.Position = UDim2.new(0.5, -250, 0.5, -200)
            frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            frame.BorderSizePixel = 0
            frame.Visible = false
            frame.Parent = GUI.ScreenGui
            
            local fCorner = Instance.new("UICorner")
            fCorner.CornerRadius = UDim.new(0, 10)
            fCorner.Parent = frame
            
            local fStroke = Instance.new("UIStroke")
            fStroke.Color = Color3.fromRGB(50, 50, 50)
            fStroke.Thickness = 1
            fStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            fStroke.Parent = frame
            
            
            local dragging, dragInput, dragStart, startPos
            local function update(input)
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragStart = input.Position
                    startPos = frame.Position
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then dragging = false end
                    end)
                end
            end)
            frame.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    if dragging then update(input) end
                end
            end)
            
            
            local header = Instance.new("TextLabel")
            header.Size = UDim2.new(1, -40, 0, 40)
            header.Position = UDim2.new(0, 15, 0, 0)
            header.BackgroundTransparency = 1
            header.Text = "Item Spawner"
            header.TextColor3 = Color3.new(1, 1, 1)
            header.Font = Enum.Font.GothamBold
            header.TextSize = 16
            header.TextXAlignment = Enum.TextXAlignment.Left
            header.Parent = frame
            
            local closeBtn = Instance.new("TextButton")
            closeBtn.Size = UDim2.new(0, 30, 0, 30)
            closeBtn.Position = UDim2.new(1, -35, 0, 5)
            closeBtn.BackgroundTransparency = 1
            closeBtn.Text = "✕"
            closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            closeBtn.Font = Enum.Font.GothamBold
            closeBtn.TextSize = 16
            closeBtn.Parent = frame
            closeBtn.MouseButton1Click:Connect(function()
                frame.Visible = false
            end)
            
            
            local searchContainer = Instance.new("Frame")
            searchContainer.Size = UDim2.new(1, -30, 0, 36)
            searchContainer.Position = UDim2.new(0, 15, 0, 45)
            searchContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            searchContainer.BorderSizePixel = 0
            searchContainer.Parent = frame
            
            local searchCorner = Instance.new("UICorner")
            searchCorner.CornerRadius = UDim.new(0, 6)
            searchCorner.Parent = searchContainer
            
            local searchIcon = Instance.new("ImageLabel")
            searchIcon.Size = UDim2.new(0, 16, 0, 16)
            searchIcon.Position = UDim2.new(0, 10, 0.5, -8)
            searchIcon.BackgroundTransparency = 1
            searchIcon.Image = "rbxassetid://3926305904"
            searchIcon.ImageRectOffset = Vector2.new(964, 320)
            searchIcon.ImageRectSize = Vector2.new(36, 36)
            searchIcon.ImageColor3 = Color3.fromRGB(150, 150, 150)
            searchIcon.Parent = searchContainer
            
            local search = Instance.new("TextBox")
            search.Size = UDim2.new(1, -40, 1, 0)
            search.Position = UDim2.new(0, 35, 0, 0)
            search.BackgroundTransparency = 1
            search.TextColor3 = Color3.new(1, 1, 1)
            search.PlaceholderText = "Search items..."
            search.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
            search.Font = Enum.Font.Gotham
            search.TextSize = 14
            search.TextXAlignment = Enum.TextXAlignment.Left
            search.Parent = searchContainer
            
            local scroll = Instance.new("ScrollingFrame")
            scroll.Size = UDim2.new(1, -30, 1, -100)
            scroll.Position = UDim2.new(0, 15, 0, 90)
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel = 0
            scroll.ScrollBarThickness = 2
            scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
            scroll.Parent = frame
            
            local grid = Instance.new("UIGridLayout")
            grid.CellSize = UDim2.new(0, 85, 0, 85)
            grid.CellPadding = UDim2.new(0, 8, 0, 8)
            grid.Parent = scroll
            
            local function populate(filter)
                
                for _, v in ipairs(scroll:GetChildren()) do
                    if v:IsA("Frame") or v:IsA("ImageButton") then v:Destroy() end
                end
                
                local items = ItemSpawner.Items
                for _, item in ipairs(items) do
                    if not filter or item.Name:lower():find(filter:lower()) then
                        local btn = Instance.new("ImageButton")
                        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        btn.BorderSizePixel = 0
                        btn.Image = item.Icon
                        btn.Parent = scroll
                        
                        local btnCorner = Instance.new("UICorner")
                        btnCorner.CornerRadius = UDim.new(0, 6)
                        btnCorner.Parent = btn
                        
                        local title = Instance.new("TextLabel")
                        title.Size = UDim2.new(1, -10, 0, 20)
                        title.Position = UDim2.new(0, 5, 1, -25)
                        title.BackgroundTransparency = 1
                        title.TextColor3 = Color3.new(1,1,1)
                        title.Text = item.Name
                        title.TextSize = 11
                        title.Font = Enum.Font.GothamMedium
                        title.TextTruncate = Enum.TextTruncate.AtEnd
                        title.Parent = btn
                        
                        btn.MouseButton1Click:Connect(function()
                            local success = ItemSpawner.Give(item)
                            
                            
                            local originalColor = btn.BackgroundColor3
                            if success then
                                btn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
                            else
                                btn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
                            end
                            task.wait(0.3)
                            btn.BackgroundColor3 = originalColor
                        end)
                    end
                end
                
                
                local count = 0
                for _, v in ipairs(scroll:GetChildren()) do
                     if v:IsA("ImageButton") then count = count + 1 end
                end
                local rows = math.ceil(count / 5) 
                scroll.CanvasSize = UDim2.new(0, 0, 0, rows * 95)
            end
            
            search:GetPropertyChangedSignal("Text"):Connect(function()
                populate(search.Text)
            end)
            
            populate()
            
            return frame
        end

        PlayerSide:CreateButton({
            Name = "Open Item Spawner",
            Callback = function()
                local win = createSpawnerWindow()
                win.Visible = not win.Visible
            end
        })
        
        PlayerSide:CreateButton({
            Name = "Refresh Item List",
            Callback = function()
                ItemSpawner.ScanItems()
                local win = createSpawnerWindow()
                
                
                win:Destroy()
                spawnerWindow = nil
                local newWin = createSpawnerWindow()
                newWin.Visible = true
            end
        })
    end
    local SettingsTab = GUI.Window:CreateTab("Settings", 7072721682)
    local MainSettings, ConfigsSide = SettingsTab:Split(0.5)

    MainSettings:CreateSection("Config Creation")
    MainSettings:CreateInput({
        Name = "New Config Name",
        PlaceholderText = "shlepa228",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text) GUI.ConfigName = Text end
    })
    
    local function UpdateConfigList()
    end
    MainSettings:CreateButton({
         Name = "Save Current as New Config",
         Callback = function()
             if GUI.ConfigManager then
                 GUI.ConfigManager.Save(GUI.ConfigName, Settings)
                 GUI.UpdateConfigList(ConfigsSide, Settings)
                 GUI.Window:Notify({
                     Title = "Config Saved",
                     Content = "Configuration " .. GUI.ConfigName .. " has been successfully saved.",
                     Duration = 5,
                     Image = 4483362458
                 })
             	end
         end
     })
 
    GUI.UpdateConfigList(ConfigsSide, Settings)

    MainSettings:CreateSection("KeybinsList & Watermark")
    GUI.Elements.Toggles["watermarkEnabled"] = MainSettings:CreateToggle({
        Name = "Watermark",
        CurrentValue = Settings.watermarkEnabled,
        Flag = "watermarkEnabled",
        Callback = function(Value) 
            Settings.watermarkEnabled = Value 
            if GUI.Watermark.Frame then GUI.Watermark.Frame.Visible = Value end
            if GUI.KeybindList.Frame then GUI.KeybindList.Frame.Visible = Value end
        end
    })
    MainSettings:CreateKeybind({
        Name = "Menu Toggle",
        CurrentKeybind = getKeyName(Settings.toggleKey),
        HoldToInteract = false,
        CallOnChange = true,
        Flag = "toggleKey",
        Callback = function(Key) setKeybind(Key, Settings, "toggleKey") end
    })

    MainSettings:CreateSection("System")
    MainSettings:CreateButton({
        Name = "Unload Script",
        Callback = function()
            if GUI.UnloadCallback then
                GUI.UnloadCallback()
            end
            GUI.Window:Destroy()
        end
    })
end

function GUI.UpdateConfigList(ConfigsSide, Settings)
    if ConfigsSide.Clear then
        ConfigsSide:Clear()
    end
    
    ConfigsSide:CreateSection("Config Actions")
    
    
    ConfigsSide:CreateButton({
        Name = "Load Selected",
        Callback = function()
            if GUI.ConfigName and GUI.ConfigName ~= "" then
                GUI.ConfigManager.Load(GUI.ConfigName, Settings)
                GUI.UpdateToggles(Settings)
                GUI.Window:Notify({
                    Title = "Config Loaded",
                    Content = "Configuration " .. GUI.ConfigName .. " has been successfully loaded.",
                    Duration = 5,
                    Image = 4483362458
                })
            else
                GUI.Window:Notify({
                    Title = "Error",
                    Content = "Please select a config first.",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end
    })
    
    ConfigsSide:CreateButton({
        Name = "Delete Selected",
        Callback = function()
            if GUI.ConfigName and GUI.ConfigName ~= "" then
                local configToDelete = GUI.ConfigName
                GUI.ConfigManager.Delete(configToDelete)
                GUI.ConfigName = ""
                GUI.UpdateConfigList(ConfigsSide, Settings)
                GUI.Window:Notify({
                    Title = "Config Deleted",
                    Content = "Configuration " .. configToDelete .. " has been deleted.",
                    Duration = 5,
                    Image = 4483362458
                })
            else
                GUI.Window:Notify({
                    Title = "Error",
                    Content = "Please select a config first.",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end
    })
    
    ConfigsSide:CreateSection("Available Configs")
    
    if GUI.ConfigManager then
        local configs = GUI.ConfigManager.List()
        if type(configs) == "table" then
            for _, name in pairs(configs) do    
                local ConfigButton = ConfigsSide:CreateButton({
                    Name = (GUI.ConfigName == name and "► " or "") .. name,
                    Callback = function()
                        GUI.ConfigName = name
                        GUI.UpdateConfigList(ConfigsSide, Settings)
                    end
                })
            end
        end
    end
end

function GUI.ToggleVisible(Settings)
    pcall(function()
        if GUI.Window.Toggle then
            GUI.Window:Toggle()
        end
    end)
end
function GUI.UpdateToggles(Settings)
    pcall(function()
        for flag, toggle in pairs(GUI.Elements.Toggles) do
            if toggle and toggle.Set then
                local value = Settings[flag]
                if flag == "magicBulletHouseCheck" then
                    value = not value
                end
                toggle:Set(value)
            end
        end
    end)
end

function GUI.UpdateWatermark(Settings)
    if not GUI.Watermark.Frame or not GUI.Watermark.Text then return end
    
    GUI.Watermark.Frame.Visible = Settings.watermarkEnabled
    if not Settings.watermarkEnabled then return end
    
    GUI.FrameCount = (GUI.FrameCount or 0) + 1
    local now = tick()
    if now - GUI.LastWatermarkUpdate < 1 then return end
    
    local deltaTime = now - GUI.LastWatermarkUpdate
    local fps = math.floor(GUI.FrameCount / deltaTime)
    GUI.LastWatermarkUpdate = now
    GUI.FrameCount = 0
    
    local ping = 0
    local playerName = LocalPlayer.DisplayName or LocalPlayer.Name
    
    pcall(function()
        local stats = game:GetService("Stats")
        if stats:FindFirstChild("Network") and stats.Network:FindFirstChild("ServerStatsItem") then
            ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
        end
    end)
    
    GUI.Watermark.Text.Text = string.format("Withonium | %s | %dms | %dfps", playerName, ping, fps)
end

function GUI.UpdateKeybindList(Settings)
    if not GUI.KeybindList.Frame or not GUI.KeybindList.Container then return end
    
    local container = GUI.KeybindList.Container
    local itemIndex = 0
    
    local function getOrCreateItem(name)
        itemIndex = itemIndex + 1
        local item = GUI.KeybindList.Items[itemIndex]
        
        if not item then
            item = {}
            item.Frame = Instance.new("Frame")
            item.Frame.BackgroundTransparency = 1
            item.Frame.Size = UDim2.new(1, 0, 0, 20)
            item.Frame.Parent = container
            
            item.NameLabel = Instance.new("TextLabel")
            item.NameLabel.BackgroundTransparency = 1
            item.NameLabel.Size = UDim2.new(0.4, 0, 1, 0)
            item.NameLabel.Font = Enum.Font.Gotham
            item.NameLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            item.NameLabel.TextSize = 13
            item.NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            item.NameLabel.Parent = item.Frame
            
            item.StatusLabel = Instance.new("TextLabel")
            item.StatusLabel.BackgroundTransparency = 1
            item.StatusLabel.Position = UDim2.new(1, 0, 0, 0)
            item.StatusLabel.AnchorPoint = Vector2.new(1, 0)
            item.StatusLabel.Size = UDim2.new(0.6, 0, 1, 0)
            item.StatusLabel.Font = Enum.Font.GothamMedium
            item.StatusLabel.TextSize = 12
            item.StatusLabel.TextXAlignment = Enum.TextXAlignment.Right
            item.StatusLabel.Parent = item.Frame
            
            GUI.KeybindList.Items[itemIndex] = item
        end
        
        item.Frame.Visible = true
        return item
    end
    
    local hasItems = false
    local keybindList = {
        {Name = "Aimbot", Key = Settings.aimKey, Active = Settings.aimbotEnabled},
        {Name = "Silent Aim", Key = Settings.silentAimKey, Active = Settings.silentAimEnabled},
        {Name = "Spider", Key = Settings.spiderKey, Active = Settings.spiderEnabled},
        {Name = "Speed", Key = Settings.speedHackKey, Active = Settings.speedHackEnabled},
        {Name = "Jump Shot", Key = Settings.jumpShotKey, Active = Settings.jumpShotEnabled},
        {Name = "FreeCam", Key = Settings.freeCamKey, Active = Settings.freeCamEnabled},
        {Name = "Anti-Aim", Key = Settings.antiAimKey, Active = Settings.antiAimEnabled},
        {Name = "FullBright", Key = Settings.FullBrightKey, Active = Settings.fullBrightEnabled}
    }

    for _, bind in ipairs(keybindList) do
        if bind.Key and bind.Key ~= Enum.KeyCode.Unknown then
            local item = getOrCreateItem(bind.Name)
            item.NameLabel.Text = bind.Name
            item.StatusLabel.Text = string.format("[%s] [%s]", getKeyName(bind.Key), bind.Active and "Active" or "Disabled")
            item.StatusLabel.TextColor3 = bind.Active and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(100, 100, 100)
            hasItems = true
        end
    end
    
    for i = itemIndex + 1, #GUI.KeybindList.Items do
        GUI.KeybindList.Items[i].Frame.Visible = false
    end
    
    GUI.KeybindList.Frame.Visible = Settings.watermarkEnabled and hasItems
end

function GUI.SwitchTab(tabName, Settings) end

return GUI

end

_modules["modules/ItemSpawner"] = function()
local ItemSpawner = {
    Items = {},
    Remotes = {},
    Icons = {},
    Initialized = false
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterPack = game:GetService("StarterPack")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer


function ItemSpawner.Log(msg)
    local formatted = "[Spawner] " .. tostring(msg)
    warn(formatted)
    if rconsoleprint then
        rconsoleprint(formatted .. "\n")
    end
end


local function findRemotes(root)
    local found = {}
    local function scan(parent)
        for _, v in ipairs(parent:GetChildren()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                local name = v.Name:lower()
                
                if name:find("craft") or name:find("buy") or name:find("reward") or 
                   name:find("claim") or name:find("give") or name:find("item") or 
                   name:find("shop") or name:find("purchase") or name:find("equip") or 
                   name:find("inventory") or name:find("add") or name:find("pickup") or
                   name:find("get") or name:find("take") then
                    table.insert(found, v)
                end
            end
            if v:IsA("Folder") or v:IsA("Model") or v:IsA("ScreenGui") or v:IsA("Tool") or v:IsA("Backpack") then
                scan(v)
            end
        end
    end
    scan(root)
    return found
end


function ItemSpawner.ScanItems()
    ItemSpawner.Items = {}
    local locations = {ReplicatedStorage, Lighting, Workspace, StarterPack}
    
    for _, loc in ipairs(locations) do
        for _, v in ipairs(loc:GetDescendants()) do
            if v:IsA("Tool") or (v:IsA("ModuleScript") and v.Name:lower():find("item")) then
                
                local icon = "rbxassetid://0" 
                if v:IsA("Tool") and v.TextureId ~= "" then
                    icon = v.TextureId
                end
                
                
                local exists = false
                for _, existing in ipairs(ItemSpawner.Items) do
                    if existing.Name == v.Name then exists = true break end
                end
                
                if not exists then
                    table.insert(ItemSpawner.Items, {
                        Name = v.Name,
                        Object = v,
                        Icon = icon,
                        Type = v.ClassName
                    })
                end
            end
        end
    end
    ItemSpawner.Log("Scanned " .. #ItemSpawner.Items .. " items.")
    return ItemSpawner.Items
end


function ItemSpawner.Give(item)
    ItemSpawner.Log("Attempting to give: " .. item.Name)
    
    
    local searchRoots = {ReplicatedStorage, Lighting, Workspace, StarterGui, LocalPlayer.PlayerGui}
    local remotes = {}
    for _, root in ipairs(searchRoots) do
        local found = findRemotes(root)
        for _, r in ipairs(found) do table.insert(remotes, r) end
    end
    
    
    if item.Object then
        local itemRemotes = findRemotes(item.Object)
        for _, r in ipairs(itemRemotes) do table.insert(remotes, r) end
    end
    
    ItemSpawner.Log("Found " .. #remotes .. " potential remotes.")

    
    table.sort(remotes, function(a, b)
        local aName = a.Name:lower()
        local bName = b.Name:lower()
        local aSafe = aName:find("reward") or aName:find("claim") or aName:find("craft") or aName:find("buy")
        local bSafe = bName:find("reward") or bName:find("claim") or bName:find("craft") or bName:find("buy")
        if aSafe and not bSafe then return true end
        return false
    end)
    
    local remoteSuccessCount = 0
    
    
    local maxRemotes = 10 
    local count = 0
    
    for _, remote in ipairs(remotes) do
        count = count + 1
        if count > maxRemotes then break end
        
        pcall(function()
            local args = {
                {item.Name},                
                {item.Object},              
                {item.Name, 1},             
                {item.Object, 1},           
                {"Craft", item.Name},       
                {"Buy", item.Name},         
                {item.Name, "Free"},        
                {item.Name, true},          
                {item.Object, true},        
                
                {"Equip", item.Name},
                {"Equip", item.Object},
                {"Add", item.Name},
                {"Add", item.Object},
                
                {{Name = item.Name, Amount = 1}},
                {{item.Name}},
            }
            
            
            
            for _, argSet in ipairs(args) do
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(unpack(argSet))
                    task.wait(0.05) 
                elseif remote:IsA("RemoteFunction") then
                    task.spawn(function() remote:InvokeServer(unpack(argSet)) end)
                    task.wait(0.05) 
                end
            end
            remoteSuccessCount = remoteSuccessCount + 1
            task.wait(0.1) 
        end)
    end
    
    
    local physicalSuccess = false
    if item.Object and item.Object.Parent then
        
        if item.Object:FindFirstChild("Handle") then
            local handle = item.Object.Handle
            if handle:FindFirstChild("TouchInterest") then
                ItemSpawner.Log("Triggering TouchInterest on " .. item.Name)
                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, handle, 0)
                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, handle, 1)
                physicalSuccess = true
            end
        end
        
        
        local cd = item.Object:FindFirstChildWhichIsA("ClickDetector", true)
        if cd then
            ItemSpawner.Log("Triggering ClickDetector on " .. item.Name)
            fireclickdetector(cd)
            physicalSuccess = true
        end
        
        
        local pp = item.Object:FindFirstChildWhichIsA("ProximityPrompt", true)
        if pp then
            ItemSpawner.Log("Triggering ProximityPrompt on " .. item.Name)
            fireproximityprompt(pp)
            physicalSuccess = true
        end
    end
    
    
    
    
    
    
    
    
    
    if remoteSuccessCount > 0 or physicalSuccess then
        ItemSpawner.Log("Give sequence finished for " .. item.Name)
        return true
    else
        ItemSpawner.Log("Give sequence failed (no valid targets) for " .. item.Name)
        return false
    end
end

return ItemSpawner

end

_modules["modules/Settings"] = function()
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

end

_modules["modules/Utils"] = function()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Utils = {
    SharedRaycastParams = RaycastParams.new(),
    SharedFilterTable = {},
    BodyPartsCache = {}
}


Utils.SharedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
Utils.SharedRaycastParams.IgnoreWater = true

function Utils.getCharacter(player)
    if not player then return nil end
    
    
    if player.Character then return player.Character end
    
    
    
    if game.PlaceId == 13253735473 or game.PlaceId == 8130299583 then
        local renv = getrenv and getrenv()
        if renv and renv._G then
            
            if renv._G.Character and renv._G.Character.character then
                if player == Players.LocalPlayer then
                    return renv._G.Character.character
                end
            end
        end
        
        
        local ignorePlayers = workspace:FindFirstChild("Ignore") and workspace.Ignore:FindFirstChild("Players")
        if ignorePlayers then
            local char = ignorePlayers:FindFirstChild(player.Name)
            if char and char:IsA("Model") then return char end
        end
    end
    
    return nil
end

function Utils.getScreenCenter()
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize / 2 or Vector2.new(0, 0)
end

function Utils.getBodyPart(character, partName)
    if not character then return nil end
    
    if partName == "Head" then
        return character:FindFirstChild("Head")
    elseif partName == "Torso" then
        
        
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Middle")
    elseif partName == "Legs" then
        return character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg") or character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")
    end
    return character:FindFirstChild("Head")
end

function Utils.getAllBodyParts(character, partName)
    
    local parts = Utils.BodyPartsCache
    for k in pairs(parts) do parts[k] = nil end
    
    if not character then return parts end
    
    if partName == "Head" then
        local p = character:FindFirstChild("Head")
        if p then table.insert(parts, p) end
    elseif partName == "Torso" then
        local p1 = character:FindFirstChild("UpperTorso")
        local p2 = character:FindFirstChild("LowerTorso")
        local p3 = character:FindFirstChild("Torso")
        if p1 then table.insert(parts, p1) end
        if p2 then table.insert(parts, p2) end
        if p3 then table.insert(parts, p3) end
    elseif partName == "Legs" then
        for _, n in ipairs({"Left Leg", "Right Leg", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg"}) do
            local p = character:FindFirstChild(n)
            if p then table.insert(parts, p) end
        end
    end
    return parts
end

function Utils.isPartVisible(part, character)
    if not part or not character then return false end
    
    local camera = workspace.CurrentCamera
    if not camera then return false end
    
    local origin = camera.CFrame.Position
    local destination = part.Position
    local direction = (destination - origin)
    
    if direction.Magnitude < 0.1 then return true end
    
    
    local params = Utils.SharedRaycastParams
    local filter = Utils.SharedFilterTable
    
    
    for k in pairs(filter) do filter[k] = nil end
    
    
    if typeof(character) == "Instance" then
        table.insert(filter, character)
    end
    
    local localChar = Utils.getCharacter(LocalPlayer)
    if localChar then
        table.insert(filter, localChar)
    end
    
    if LocalPlayer.Character and LocalPlayer.Character ~= localChar then
        table.insert(filter, LocalPlayer.Character)
    end
    
    
    table.insert(filter, camera)
    local ignore = workspace:FindFirstChild("Ignore")
    if ignore then table.insert(filter, ignore) end
    
    params.FilterDescendantsInstances = filter
    
    
    local currentOrigin = origin + (direction.Unit * 0.1)
    local currentDirection = (destination - currentOrigin)
    
    for i = 1, 3 do 
        local result = workspace:Raycast(currentOrigin, currentDirection, params)
        if not result then return true end
        
        local hit = result.Instance
        local canPierce = false
        
        
        if hit.Transparency > 0.7 or not hit.CanCollide then
            canPierce = true
        else
            
            local name = hit.Name:lower()
            if name:find("grass") or name:find("leaf") or name:find("cloud") or name:find("effect") or name:find("particle") then
                canPierce = true
            end
        end
        
        if canPierce then
            table.insert(filter, hit)
            params.FilterDescendantsInstances = filter
            currentOrigin = result.Position + (direction.Unit * 0.01)
            currentDirection = (destination - currentOrigin)
            if currentDirection.Magnitude < 0.05 then return true end
        else
            return false
        end
    end
    
    return false
end

function Utils.isHouse(part)
    if not part or not part:IsA("BasePart") then return false end
    if not part.CanCollide then return false end
    
    local name = part.Name:lower()
    local parent = part.Parent
    local parentName = parent and parent.Name:lower() or ""
    
    
    if name:find("wall") or name:find("roof") or name:find("door") or 
       name:find("house") or name:find("building") or name:find("struct") or 
       parentName:find("house") or parentName:find("building") or parentName:find("struct") then
        return true
    end
    
    
    if parent and (parent:IsA("Folder") or parent:IsA("Model")) then
        if parentName:find("build") or parentName:find("house") or parentName:find("base") then
            return true
        end
    end
    
    return false
end

function Utils.MakeDraggable(topbarobject, object)
    local Dragging = nil
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    local function Update(input)
        local Delta = input.Position - DragStart
        local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        object.Position = pos
    end

    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            Update(input)
        end
    end)
end

return Utils

end

_modules["modules/Visuals"] = function()
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

local Visuals = {
    Connections = {},
    NormalSettings = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient
    },
    FullBrightSettings = {
        Brightness = 1,
        ClockTime = 12,
        FogEnd = 786543,
        GlobalShadows = false,
        Ambient = Color3.fromRGB(178, 178, 178)
    },
    Enabled = false,
    NoFogEnabled = false,
    NoGrassEnabled = false,
    OriginalDecoration = false,
    HasDecorationProperty = false,
    OriginalAtmosphere = {
        Density = 0.3,
        Offset = 0.2,
        Glare = 0,
        Haze = 0,
        Visible = true
    }
}

function Visuals.Init(Settings)
    
    if Terrain then
        local success, val = pcall(function() return Terrain.Decoration end)
        if success then
            Visuals.HasDecorationProperty = true
            Visuals.OriginalDecoration = val
        end
    end

    
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        Visuals.OriginalAtmosphere = {
            Density = atmosphere.Density,
            Offset = atmosphere.Offset,
            Glare = atmosphere.Glare,
            Haze = atmosphere.Haze,
            Visible = true
        }
    end

    
    Visuals.NormalSettings = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient
    }

    
    local function setupWatcher(property, targetValue)
        local connection = Lighting:GetPropertyChangedSignal(property):Connect(function()
            if Visuals.Enabled then
                if Lighting[property] ~= targetValue then
                    Lighting[property] = targetValue
                end
            elseif Visuals.NoFogEnabled and (property == "FogEnd" or property == "FogStart") then
                if Lighting[property] ~= 1000000 then
                    Lighting[property] = 1000000
                end
            else
                
                Visuals.NormalSettings[property] = Lighting[property]
            end
        end)
        table.insert(Visuals.Connections, connection)
    end

    setupWatcher("Brightness", Visuals.FullBrightSettings.Brightness)
    setupWatcher("ClockTime", Visuals.FullBrightSettings.ClockTime)
    setupWatcher("FogEnd", 1000000)
    setupWatcher("FogStart", 1000000)
    setupWatcher("GlobalShadows", Visuals.FullBrightSettings.GlobalShadows)
    setupWatcher("Ambient", Visuals.FullBrightSettings.Ambient)

    
    task.spawn(function()
        while task.wait(1) do
            if not Visuals.Connections or #Visuals.Connections == 0 then break end 
            local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmosphere and Visuals.NoFogEnabled then
                if atmosphere.Density ~= 0 then atmosphere.Density = 0 end
                if atmosphere.Haze ~= 0 then atmosphere.Haze = 0 end
            end
        end
    end)

    
    if Terrain and Visuals.HasDecorationProperty then
        local connection = Terrain:GetPropertyChangedSignal("Decoration"):Connect(function()
            if Visuals.NoGrassEnabled then
                if Terrain.Decoration ~= false then
                    Terrain.Decoration = false
                end
            else
                Visuals.OriginalDecoration = Terrain.Decoration
            end
        end)
        table.insert(Visuals.Connections, connection)
    end
end

function Visuals.Update(Settings)
    
    if Settings.fullBrightEnabled ~= Visuals.Enabled then
        Visuals.Enabled = Settings.fullBrightEnabled
        
        if Visuals.Enabled then
            
            Lighting.Brightness = Visuals.FullBrightSettings.Brightness
            Lighting.ClockTime = Visuals.FullBrightSettings.ClockTime
            Lighting.FogEnd = Visuals.FullBrightSettings.FogEnd
            Lighting.FogStart = 0
            Lighting.GlobalShadows = Visuals.FullBrightSettings.GlobalShadows
            Lighting.Ambient = Visuals.FullBrightSettings.Ambient
        else
            
            Lighting.Brightness = Visuals.NormalSettings.Brightness
            Lighting.ClockTime = Visuals.NormalSettings.ClockTime
            Lighting.GlobalShadows = Visuals.NormalSettings.GlobalShadows
            Lighting.Ambient = Visuals.NormalSettings.Ambient
            
            if Settings.noFogEnabled then
                Lighting.FogEnd = 1000000
                Lighting.FogStart = 0
            else
                Lighting.FogEnd = Visuals.NormalSettings.FogEnd
            end
        end
    end

    
    if Settings.noFogEnabled ~= Visuals.NoFogEnabled then
        Visuals.NoFogEnabled = Settings.noFogEnabled
        
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if Visuals.NoFogEnabled then
            Lighting.FogEnd = 1000000
            Lighting.FogStart = 1000000
            if atmosphere then
                atmosphere.Density = 0
                atmosphere.Haze = 0
                atmosphere.Glare = 0
            end
        else
            Lighting.FogEnd = Visuals.NormalSettings.FogEnd
            Lighting.FogStart = 0
            if atmosphere and Visuals.OriginalAtmosphere then
                atmosphere.Density = Visuals.OriginalAtmosphere.Density
                atmosphere.Haze = Visuals.OriginalAtmosphere.Haze
                atmosphere.Glare = Visuals.OriginalAtmosphere.Glare
            end
        end
    end

    
    if Settings.noGrassEnabled ~= Visuals.NoGrassEnabled then
        Visuals.NoGrassEnabled = Settings.noGrassEnabled
        
        if Visuals.HasDecorationProperty then
            Terrain.Decoration = not Visuals.NoGrassEnabled
        end
        
        
        task.spawn(function()
            pcall(function()
                local grassNames = {"Grass", "TallGrass", "Shrub", "Bush"}
                local targetTransparency = Visuals.NoGrassEnabled and 1 or 0
                
                
                local allDescendants = workspace:GetDescendants()
                for i = 1, #allDescendants do
                    local v = allDescendants[i]
                    if v:IsA("BasePart") then
                        local name = v.Name:lower()
                        local isGrass = false
                        for j = 1, #grassNames do
                            if name:find(grassNames[j]:lower()) then
                                isGrass = true
                                break
                            end
                        end
                        
                        
                        if not isGrass then
                            local parent = v.Parent
                            if parent and parent:IsA("Model") then
                                local pName = parent.Name:lower()
                                for j = 1, #grassNames do
                                    if pName:find(grassNames[j]:lower()) then
                                        isGrass = true
                                        break
                                    end
                                end
                            end
                        end
                        
                        if isGrass then
                            v.Transparency = targetTransparency
                        end
                    end
                end
            end)
        end)
    end
end

function Visuals.Unload()
    for _, conn in ipairs(Visuals.Connections) do
        conn:Disconnect()
    end
    Visuals.Connections = {}
    
    
    Lighting.Brightness = Visuals.NormalSettings.Brightness
    Lighting.ClockTime = Visuals.NormalSettings.ClockTime
    Lighting.FogEnd = Visuals.NormalSettings.FogEnd
    Lighting.GlobalShadows = Visuals.NormalSettings.GlobalShadows
    Lighting.Ambient = Visuals.NormalSettings.Ambient

    
    if Terrain and Visuals.HasDecorationProperty then
        Terrain.Decoration = Visuals.OriginalDecoration
    end
end

return Visuals

end

_modules["modules/Aimbot/Exploits"] = function()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Exploits = {
    LastRecoilUpdate = 0,
    LastFastShootUpdate = 0,
    LastGodUpdate = 0,
    LastFreeCamUpdate = 0,
    LastTool = nil,
    LastRecoilTool = nil,
    OriginalFireRates = {}
}

function Exploits.ApplyFastShoot(Settings)
    local character = LocalPlayer.Character
    if not character then return end

    local tool = character:FindFirstChildOfClass("Tool")
    
    if not Settings.fastShootEnabled then 
        
        if next(Exploits.OriginalFireRates) ~= nil then
            for obj, originalValue in pairs(Exploits.OriginalFireRates) do
                if typeof(obj) == "Instance" and obj.Parent then
                    if obj:IsA("ValueBase") then
                        obj.Value = originalValue
                    end
                elseif type(obj) == "string" and obj:find("Attr_") then
                    
                end
            end
            
            
            if tool then
                for name, originalValue in pairs(Exploits.OriginalFireRates) do
                    if type(name) == "string" and name:find("Attr_") then
                        local attrName = name:sub(6)
                        tool:SetAttribute(attrName, originalValue)
                    end
                end
            end
            Exploits.OriginalFireRates = {}
            Exploits.LastTool = nil
        end
        return 
    end
    
    if not tool then return end

    
    if Exploits.LastTool == tool then return end
    Exploits.LastTool = tool

    
    local multiplier = Settings.fastShootMultiplier or 2.5

    
    local rateKeywords = {"firerate", "rpm", "speed", "shotspersecond", "bulletspersecond", "rateoffire"}
    local delayKeywords = {"delay", "cooldown", "interval", "waittime", "recovery", "between", "nextshot"}
    local burstKeywords = {"burst", "burstcount", "burstamount", "burstsize", "burstinterval", "burstrate", "shotsperclick"}
    local modeKeywords = {"mode", "firemode", "shootmode", "automatic", "auto", "isauto", "isautomatic", "autofire", "type"}

    
    local attributes = tool:GetAttributes()
    for name, val in pairs(attributes) do
        local lowerName = name:lower()
        local attrKey = "Attr_" .. name

        
        local isRate = false
        for _, kw in ipairs(rateKeywords) do
            if lowerName:find(kw) then isRate = true break end
        end
        
        
        local isDelay = false
        for _, kw in ipairs(delayKeywords) do
            if lowerName:find(kw) then isDelay = true break end
        end

        
        local isBurst = false
        for _, kw in ipairs(burstKeywords) do
            if lowerName:find(kw) then isBurst = true break end
        end

        
        local isMode = false
        for _, kw in ipairs(modeKeywords) do
            if lowerName:find(kw) then isMode = true break end
        end

        if not Exploits.OriginalFireRates[attrKey] then
            Exploits.OriginalFireRates[attrKey] = val
        end

        if isRate and typeof(val) == "number" then
            tool:SetAttribute(name, val * multiplier)
        elseif isDelay and typeof(val) == "number" then
            tool:SetAttribute(name, math.max(val / multiplier, 0.001)) 
        elseif isBurst then
            if typeof(val) == "number" then
                if lowerName:find("count") or lowerName:find("amount") or lowerName:find("size") then
                    tool:SetAttribute(name, 1) 
                else
                    tool:SetAttribute(name, 0) 
                end
            end
        elseif isMode then
            if typeof(val) == "boolean" then
                tool:SetAttribute(name, true) 
            elseif typeof(val) == "string" then
                tool:SetAttribute(name, "Automatic") 
            end
        end
    end

    
    local function checkValues(container)
        for _, v in ipairs(container:GetChildren()) do
            local name = v.Name:lower()

            
            local isRate = false
            for _, kw in ipairs(rateKeywords) do
                if name:find(kw) then isRate = true break end
            end
            
            
            local isDelay = false
            for _, kw in ipairs(delayKeywords) do
                if name:find(kw) then isDelay = true break end
            end

            
            local isBurst = false
            for _, kw in ipairs(burstKeywords) do
                if name:find(kw) then isBurst = true break end
            end

            
            local isMode = false
            for _, kw in ipairs(modeKeywords) do
                if name:find(kw) then isMode = true break end
            end

            if not Exploits.OriginalFireRates[v] then
                if v:IsA("ValueBase") then
                    Exploits.OriginalFireRates[v] = v.Value
                end
            end

            if isRate and (v:IsA("NumberValue") or v:IsA("IntValue")) then
                v.Value = v.Value * multiplier
            elseif isDelay and (v:IsA("NumberValue") or v:IsA("IntValue")) then
                v.Value = math.max(v.Value / multiplier, 0.001)
            elseif isBurst then
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    if name:find("count") or name:find("amount") or name:find("size") then
                        v.Value = 1
                    else
                        v.Value = 0
                    end
                end
            elseif isMode then
                if v:IsA("BoolValue") then
                    v.Value = true
                elseif v:IsA("StringValue") then
                    v.Value = "Automatic"
                end
            end

            
            if v.Name == "Settings" or v.Name == "Config" or v.Name == "GunSettings" or v.Name == "Stats" then
                checkValues(v)
            end
        end
    end
    checkValues(tool)
end

function Exploits.ApplyNoRecoil(Settings)
    if not Settings.noRecoilEnabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end

    
    
    
    
    if Exploits.LastRecoilTool == tool then return end
    Exploits.LastRecoilTool = tool
    
    
    local attributes = tool:GetAttributes()
    for name, _ in pairs(attributes) do
        local lowerName = name:lower()
        if lowerName:find("recoil") or lowerName:find("shake") or lowerName:find("sway") or lowerName:find("spread") then
            local val = tool:GetAttribute(name)
            if typeof(val) == "number" then
                tool:SetAttribute(name, 0)
            elseif typeof(val) == "Vector3" then
                tool:SetAttribute(name, Vector3.new(0, 0, 0))
            elseif typeof(val) == "Vector2" then
                tool:SetAttribute(name, Vector2.new(0, 0))
            end
        end
    end

    
    
    local function checkValues(container)
        for _, v in ipairs(container:GetChildren()) do
            if v:IsA("NumberValue") or v:IsA("Vector3Value") or v:IsA("Vector2Value") or v:IsA("IntValue") then
                local name = v.Name:lower()
                if name:find("recoil") or name:find("shake") or name:find("sway") or name:find("spread") then
                    if v:IsA("Vector3Value") then
                        v.Value = Vector3.new(0, 0, 0)
                    elseif v:IsA("Vector2Value") then
                        v.Value = Vector2.new(0, 0)
                    else
                        v.Value = 0
                    end
                end
            elseif v.Name == "Settings" or v.Name == "Config" or v.Name == "GunSettings" then
                checkValues(v)
            end
        end
    end
    checkValues(tool)

    
    local camera = workspace.CurrentCamera
    if camera then
        for _, v in ipairs(camera:GetChildren()) do
            if v.Name:lower():find("shake") or v.Name:lower():find("recoil") then
                if v:IsA("NumberValue") or v:IsA("Vector3Value") then
                    if v:IsA("Vector3Value") then
                        v.Value = Vector3.new(0, 0, 0)
                    else
                        v.Value = 0
                    end
                end
            end
        end
    end
end

function Exploits.ApplyJumpShot(Settings)
    if not Settings.jumpShotEnabled then return end
    
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
            humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        end
    end
end

function Exploits.ApplySpider(Settings)
    if not Settings.spiderEnabled then return end
    
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if rootPart and humanoid and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {character}
        
        local camera = workspace.CurrentCamera
        local lookVector = camera and camera.CFrame.LookVector or rootPart.CFrame.LookVector
        local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
        
        local directions = {
            flatLook
        }
        
        local nearWall = false
        for _, dir in ipairs(directions) do
            local rayResult = workspace:Raycast(rootPart.Position, dir * 1.8, params)
            if rayResult then
                nearWall = true
                break
            end
        end
        
        if nearWall then
            rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 35, rootPart.Velocity.Z)
        end
    end
end

function Exploits.ApplySpeedHack(Settings, deltaTime)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if humanoid and rootPart then
        local multiplier = Settings.speedMultiplier or 1
        if Settings.speedHackEnabled and multiplier > 1 then
            local moveDir = humanoid.MoveDirection
            if moveDir.Magnitude > 0 then
                
                local dt = deltaTime or 0.016
                local extraSpeed = (multiplier - 1) * 16
                local offset = moveDir * (extraSpeed * dt)
                
                
                rootPart.CFrame = CFrame.new(rootPart.Position + offset) * rootPart.CFrame.Rotation
            end
            
            
            if humanoid.WalkSpeed > 16.1 then
                humanoid.WalkSpeed = 16
            end
        elseif not Settings.speedHackEnabled and humanoid.WalkSpeed > 16.1 then
            humanoid.WalkSpeed = 16
        end
    end
end

function Exploits.ApplyWaterSpeedHack(Settings, deltaTime)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if humanoid and rootPart then
        local state = humanoid:GetState()
        if Settings.waterSpeedHackEnabled and state == Enum.HumanoidStateType.Swimming then
            local multiplier = Settings.waterSpeedMultiplier or 1
            if multiplier > 1 then
                local moveDir = humanoid.MoveDirection
                if moveDir.Magnitude > 0 then
                    local dt = deltaTime or 0.016
                    local waterBoost = (multiplier - 1) * 16
                    local offset = moveDir * (waterBoost * dt)
                    
                    
                    
                    local currentRot = rootPart.CFrame.Rotation
                    rootPart.CFrame = CFrame.new(rootPart.Position + offset) * currentRot
                end
            end
        end
    end
end

function Exploits.ApplyFreeCam(Aimbot, Settings)
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    if Settings.freeCamEnabled then
        if not Aimbot.FreeCamActive then
            Aimbot.FreeCamActive = true
            Aimbot.OriginalCameraType = camera.CameraType
            Aimbot.OriginalCameraCFrame = camera.CFrame
            Aimbot.FreeCamPos = camera.CFrame.Position
            
            local x, y, z = camera.CFrame:ToEulerAnglesYXZ()
            Aimbot.FreeCamRot = Vector2.new(math.deg(x), math.deg(y))
            
            camera.CameraType = Enum.CameraType.Scriptable
            
            
            local character = LocalPlayer.Character
            if character then
                Exploits.OriginalCollision = {}
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        Exploits.OriginalCollision[part] = part.CanCollide
                        part.CanCollide = false
                    end
                end
            	end
        end
        
        local baseSpeed = 0.5
        local moveSpeed = baseSpeed * (Settings.speedMultiplier or 1)
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveSpeed = moveSpeed * 3
        end
        
        local moveVector = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + Vector3.new(0, 0, -1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector + Vector3.new(0, 0, 1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector + Vector3.new(-1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Vector3.new(1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveVector = moveVector + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector = moveVector + Vector3.new(0, -1, 0) end
        
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local delta = UserInputService:GetMouseDelta()
            local sensitivity = 0.5
            Aimbot.FreeCamRot = Aimbot.FreeCamRot + Vector2.new(-delta.Y * sensitivity, -delta.X * sensitivity)
            Aimbot.FreeCamRot = Vector2.new(math.clamp(Aimbot.FreeCamRot.X, -89, 89), Aimbot.FreeCamRot.Y)
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        else
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
        
        local rotation = CFrame.Angles(0, math.rad(Aimbot.FreeCamRot.Y), 0) * CFrame.Angles(math.rad(Aimbot.FreeCamRot.X), 0, 0)
        Aimbot.FreeCamPos = Aimbot.FreeCamPos + (rotation * moveVector) * moveSpeed
        
        camera.CFrame = CFrame.new(Aimbot.FreeCamPos) * rotation
        
        
        if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCurrentPosition and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    else
        if Aimbot.FreeCamActive then
            Aimbot.FreeCamActive = false
            camera.CameraType = Aimbot.OriginalCameraType or Enum.CameraType.Custom
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            
            
            local character = LocalPlayer.Character
            if character and Exploits.OriginalCollision then
                for part, originalValue in pairs(Exploits.OriginalCollision) do
                    if part and part.Parent then
                        part.CanCollide = originalValue
                    end
                end
                Exploits.OriginalCollision = nil
            end
        end
    end
end

function Exploits.ApplyThirdPerson(Settings)
    if Settings.thirdPersonEnabled then
        local distance = Settings.thirdPersonDistance or 10
        LocalPlayer.CameraMaxZoomDistance = distance
        LocalPlayer.CameraMinZoomDistance = distance
        
        
        if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
            pcall(function() LocalPlayer.CameraMode = Enum.CameraMode.Classic end)
        end
    else
        
        if LocalPlayer.CameraMaxZoomDistance == (Settings.thirdPersonDistance or 10) then
            LocalPlayer.CameraMaxZoomDistance = 128
            LocalPlayer.CameraMinZoomDistance = 0.5
        end
    end
end

function Exploits.ApplyGodMode(Settings)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if not character or not humanoid then return end

    if Settings.godModeEnabled then
        if humanoid:GetStateEnabled(Enum.HumanoidStateType.Dead) then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        end
        
        
        local now = tick()
        if now - Exploits.LastGodUpdate >= 2 then
            Exploits.LastGodUpdate = now
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("TouchTransmitter") and not part:FindFirstAncestorWhichIsA("Tool") then
                    part:Destroy()
                end
            end
        end

        if humanoid.Health > 0 and humanoid.Health < 20 then
            humanoid.Health = 100
        end
    else
        if not humanoid:GetStateEnabled(Enum.HumanoidStateType.Dead) then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        end
    end
end

function Exploits.ApplyAntiAFK(Settings)
    if not Settings.antiAfkEnabled then return end
    
    local now = tick()
    if now - Settings.antiAfkLastActionTime >= (Settings.antiAfkInterval * 60) then
        Settings.antiAfkLastActionTime = now
        
        task.spawn(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
            task.wait(0.2)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
            
            task.wait(0.2)
            
            
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.S, false, game)
            task.wait(0.2)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.S, false, game)
            
            task.wait(0.2)
            
            
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            
            
            task.wait(0.5)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end
end

function Exploits.ApplyAntiAim(Settings)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if not Settings.antiAimEnabled then 
        if humanoid then humanoid.AutoRotate = true end
        
        
        if rootPart then
            local rootJoint = rootPart:FindFirstChild("RootJoint") or (character:FindFirstChild("LowerTorso") and character.LowerTorso:FindFirstChild("Root"))
            if rootJoint then
                rootJoint.Transform = CFrame.new()
            end
        end
        return 
    end
    
    if not rootPart or not humanoid then return end
    
    
    if humanoid.AutoRotate then humanoid.AutoRotate = false end
    
    local speed = Settings.antiAimSpeed or 50
    local mode = Settings.antiAimMode or "Spin"
    
    
    local aaAngle = 0
    if mode == "Spin" then
        
        aaAngle = math.rad((tick() * (speed * 10)) % 360)
    elseif mode == "Jitter" then
        
        aaAngle = math.rad((tick() * 1000 % 200 < 100) and 90 or -90)
    elseif mode == "Static" then
        
        aaAngle = math.rad(180)
    end

    
    
    local camera = workspace.CurrentCamera
    local lookVector = camera.CFrame.LookVector
    local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
    
    
    local targetRotation = CFrame.new(Vector3.new(), flatLook) * CFrame.Angles(0, aaAngle, 0)
    rootPart.CFrame = CFrame.new(rootPart.Position) * targetRotation.Rotation

    
    
    local rootJoint = rootPart:FindFirstChild("RootJoint") or (character:FindFirstChild("LowerTorso") and character.LowerTorso:FindFirstChild("Root"))
    
    if rootJoint then
        
        
        rootJoint.Transform = CFrame.Angles(0, -aaAngle, 0)
    end
end
 
return Exploits

end

_modules["modules/Aimbot/Hitboxes"] = function()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Hitboxes = {
    lastHitboxUpdate = 0,
    OriginalProperties = {}, 
    ModifiedParts = {} 
}

function Hitboxes.UpdateHitboxes(Aimbot, Settings, Utils, ESP)
    if not Settings or not ESP then return end
    
    local now = tick()
    if now - Hitboxes.lastHitboxUpdate < 0.15 then return end 
    Hitboxes.lastHitboxUpdate = now
    
    local function restorePart(part)
        if not part then return end
        local props = Hitboxes.OriginalProperties[part]
        if props then
            pcall(function()
                part.Size = props.Size
                part.Transparency = props.Transparency
                part.CanCollide = props.CanCollide
                part.CanTouch = props.CanTouch
                part.Massless = props.Massless
                local visual = part:FindFirstChild("HitboxVisual")
                if visual then visual:Destroy() end
            end)
            Hitboxes.OriginalProperties[part] = nil
        end
    end

    if not Settings.hitboxExpanderEnabled then
        if next(Hitboxes.OriginalProperties) then
            for part, _ in pairs(Hitboxes.OriginalProperties) do
                restorePart(part)
            end
        end
        return
    end
    
    local size = Settings.hitboxExpanderSize or 5
    local targetSize = Vector3.new(size, size, size)
    
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Middle") or character:FindFirstChild("Torso")
            
            
            if not rootPart or (rootPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude > 500 then
                continue 
            end

            local parts = Utils.getAllBodyParts(character, Settings.targetPart)
            
            for _, part in ipairs(parts) do
                if part.Name == "HumanoidRootPart" then continue end
                
                if not Hitboxes.OriginalProperties[part] then
                    Hitboxes.OriginalProperties[part] = {
                        Size = part.Size,
                        Transparency = part.Transparency,
                        CanCollide = part.CanCollide,
                        CanTouch = part.CanTouch,
                        Massless = part.Massless
                    }
                end
                
                
                if part.Size ~= targetSize then
                    part.Size = targetSize
                    part.CanCollide = false 
                    part.CanTouch = true 
                    part.Massless = true 
                end

                
                if Settings.hitboxExpanderShow then
                    part.Transparency = 0.8
                    
                    
                    local selection = part:FindFirstChild("HitboxVisual")
                    if not selection then
                        selection = Instance.new("SelectionBox")
                        selection.Name = "HitboxVisual"
                        selection.LineThickness = 0.02
                        selection.Adornee = part
                        selection.Color3 = Color3.fromRGB(255, 255, 255) 
                        selection.Transparency = 0.7
                        selection.Parent = part
                    end
                    selection.Visible = true
                else
                    local selection = part:FindFirstChild("HitboxVisual")
                    if selection then selection.Visible = false end
                    part.Transparency = Hitboxes.OriginalProperties[part].Transparency
                end
            end
        end
    end
    
    
    
    local count = 0
    for part, props in pairs(Hitboxes.OriginalProperties) do
        count = count + 1
        
        if count % 3 == 0 or count > 50 then 
            local char = part and part.Parent
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            
            if not part or not char or not char.Parent or not humanoid or humanoid.Health <= 0 then
                restorePart(part)
            end
        end
    end
end

return Hitboxes

end

_modules["modules/Aimbot/Hooks"] = function()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Hooks = {
    IsInitialized = false
}

function Hooks.InitHooks(Aimbot, Settings, Utils, Ballistics, BulletTracer)
    if Hooks.IsInitialized then return end
    Hooks.IsInitialized = true
    
    local oldNamecall
    local insideHook = false
    
    
    local currentCharacter = nil
    local currentHumanoid = nil
    local currentTool = nil
    local isWeaponCache = false
    local lastWeaponCheck = 0
    local lastTracerTick = 0
    local sharedRaycastParams = RaycastParams.new()
    sharedRaycastParams.FilterType = Enum.RaycastFilterType.Include
    sharedRaycastParams.IgnoreWater = true
    
    LocalPlayer.CharacterAdded:Connect(function(char)
        currentCharacter = char
        currentHumanoid = char:WaitForChild("Humanoid", 5)
    end)
    currentCharacter = LocalPlayer.Character
    currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")

    
    local function customRaycastIgnoringTerrain(origin, direction, params, maxDistance)
        if insideHook then return nil end
        insideHook = true
        
        local remainingDistance = maxDistance or direction.Magnitude
        local currentOrigin = origin
        local unitDirection = direction.Unit
        local epsilon = 0.01

        local result = nil
        while remainingDistance > 0 do
            local segmentLength = math.min(remainingDistance, 5000)
            local segmentDirection = unitDirection * segmentLength

            
            local success, r = pcall(function() 
                return workspace:Raycast(currentOrigin, segmentDirection, params) 
            end)
            
            if success and r then
                if r.Instance ~= workspace.Terrain then
                    result = r
                    break
                else
                    local advance = (r.Position - currentOrigin).Magnitude + epsilon
                    currentOrigin = r.Position + unitDirection * epsilon
                    remainingDistance = remainingDistance - advance
                end
            else
                break
            end
        end

        insideHook = false
        return result
    end

    
    game:GetService("RunService").RenderStepped:Connect(function()
        if not Settings.bulletTracerEnabled or not BulletTracer then return end
        
        
        local isShooting = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or 
                           UserInputService:IsGamepadButtonDown(Enum.KeyCode.ButtonR2)
        if not isShooting then return end
        
        
        local now = tick()
        if now - lastTracerTick < 0.08 then return end
        lastTracerTick = now
        
        
        local char = LocalPlayer.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        
        
        
        local origin = nil
        
        
        if tool then
            local handle = tool:FindFirstChild("Handle")
            if handle then
                local muzzle = handle:FindFirstChild("Muzzle") or handle:FindFirstChild("FirePoint") or tool:FindFirstChild("Muzzle", true) or handle:FindFirstChild("FlashPoint")
                if muzzle and (muzzle:IsA("Attachment") or muzzle:IsA("BasePart")) then
                    origin = muzzle.WorldPosition or muzzle.Position
                else
                    origin = handle.Position
                end
            end
        end
        
        
        if not origin then
            local cam = workspace.CurrentCamera
            if cam then
                origin = cam.CFrame.Position + (cam.CFrame.LookVector * 1) + (cam.CFrame.RightVector * 0.5) + (cam.CFrame.UpVector * -0.5) 
            elseif char.Head then
                origin = char.Head.Position
            end
        end
        
        if not origin then return end
        
        
        local direction
        local velocity = 1000
        local gravity = 196.2
        
        
        local stats = Ballistics.GetWeaponFromTool(tool)
        if stats then
            velocity = stats.velocity or velocity
            gravity = stats.gravity or gravity
        end
        
        
        if Aimbot.IsSilentAiming and Aimbot.SilentTarget and Aimbot.SilentTarget.targetPart then
            local target = Aimbot.SilentTarget
             
            local predDir = Aimbot.GetProjectilePrediction(target, Settings, Ballistics, origin)
            if predDir then
                direction = predDir
            else
                direction = (target.targetPart.Position - origin).Unit
            end
        else
            
            local mouse = LocalPlayer:GetMouse()
            local hit = mouse.Hit.Position
            direction = (hit - origin).Unit
        end
        
        
        pcall(function()
            BulletTracer.Create(origin, direction, velocity, gravity, Settings)
        end)
    end)

    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        
        if checkcaller() then
            return oldNamecall(self, ...)
        end

        
        local method = getnamecallmethod()
        
        
        if insideHook or not self then
            return oldNamecall(self, ...)
        end

        
        if method == "GetState" and Settings.jumpShotEnabled then
            if self == currentHumanoid and self.Parent then
                return Enum.HumanoidStateType.Landed
            end
        end

        
        if (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhiteList") and self == workspace then
            
            local callingScript = getcallingscript and getcallingscript()
            if callingScript then
                 local scriptName = callingScript.Name
                 if scriptName == "Popper" or scriptName == "CameraModule" or scriptName == "ZoomController" or scriptName == "Poppercam" or scriptName == "ObjectHealthDisplayer" then
                     return oldNamecall(self, ...)
                 end
            end

            local args = {...}
            
            
            local now = os.clock()
            if now - lastWeaponCheck > 0.1 then
                lastWeaponCheck = now
                insideHook = true
                
                
                local success, result = pcall(function()
                    local char = currentCharacter or LocalPlayer.Character
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    if tool and Ballistics then
                         return Ballistics.GetWeaponFromTool(tool)
                    end
                    return false
                end)
                
                isWeaponCache = success and result or false
                insideHook = false
            end
            
            if isWeaponCache then
                local cam = workspace.CurrentCamera
                local origin, direction
                
                if method == "Raycast" then
                    origin = args[1]
                    direction = args[2]
                else
                    local ray = args[1]
                    if typeof(ray) == "Ray" then
                        origin = ray.Origin
                        direction = ray.Direction
                    end
                end
                
                
                if typeof(origin) == "Vector3" and cam and (origin - cam.CFrame.Position).Magnitude < 500 then
                    
                    local isShooting = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or 
                                       UserInputService:IsGamepadButtonDown(Enum.KeyCode.ButtonR2)
                    
                    
                    local target = (Aimbot.IsSilentAiming and Aimbot.SilentTarget) or (Settings.magicBulletEnabled and Aimbot.CurrentTarget)
                    
                    if target and target.targetPart and target.targetPart.Parent then
                        local originPos = origin
                        local targetPart = target.targetPart
                        local targetChar = Utils.getCharacter(target.player)
                        
                        
                        local predictedDir = Aimbot.GetProjectilePrediction(target, Settings, Ballistics, originPos)
                        
                        
                        local hitPos = targetPart.Position
                        local normal = Vector3.new(0, 1, 0)
                        
                        local magicDir = (hitPos - originPos).Unit * 99999
                        
                        if Settings.magicBulletEnabled and targetChar then
                            
                            if method == "Raycast" then
                                
                                sharedRaycastParams.FilterDescendantsInstances = {targetPart}
                                local result = customRaycastIgnoringTerrain(originPos, magicDir, sharedRaycastParams, 99999)
                                if result then return result end
                            else
                                
                                return targetPart, hitPos, normal, targetPart.Material
                            end
                            
                        elseif Aimbot.IsSilentAiming then
                            
                            local silentDir = predictedDir * 99999
                            
                            if method == "Raycast" then
                                
                                
                                sharedRaycastParams.FilterDescendantsInstances = {targetChar}
                                local result = customRaycastIgnoringTerrain(originPos, silentDir, sharedRaycastParams, 99999)
                                if result then return result end
                            else
                                return targetPart, hitPos, normal, targetPart.Material
                            end
                        end
                    end
                end
            end
        end
        
        return oldNamecall(self, ...)
    end))
end

return Hooks

end

_modules["modules/Aimbot/Input"] = function()
local UserInputService = game:GetService("UserInputService")
local Input = {}

function Input.IsInputPressed(key)
    if not key then return false end
    if key.EnumType == Enum.KeyCode then
        return UserInputService:IsKeyDown(key)
    elseif key.EnumType == Enum.UserInputType then
        if key.Name:match("MouseButton") then
            return UserInputService:IsMouseButtonPressed(key)
        end
    end
    return false
end

return Input

end

_modules["modules/Aimbot/Prediction"] = function()
local Prediction = {}

function Prediction.GetProjectilePrediction(target, Settings, Ballistics, customOrigin)
    local camera = workspace.CurrentCamera
    local origin = customOrigin or (camera and camera.CFrame.Position) or Vector3.new(0, 0, 0)
    
    local targetPos = target.targetPart.Position
    local targetVelocity = target.velocity or Vector3.new(0, 0, 0)
    
    local v = Settings.projectileSpeed or 1000
    local g = Settings.projectileGravity or 196.2
    
    
    if Settings.ballisticsEnabled and Ballistics then
        local config = Ballistics.GetConfig()
        if config then
            v = config.velocity or v
            g = math.abs(config.gravity or g)
        end
    end
    
    
    v = math.max(v, 1)
    
    if not Settings.projectilePredictionEnabled then
        return (targetPos - origin).Unit
    end
    
    local toTarget = targetPos - origin
    local dist = toTarget.Magnitude
    
    
    if dist < 0.5 then
        return toTarget.Unit
    end
    
    local hitscanThreshold = Settings.hitscanVelocityThreshold or 1500
    local targetG = workspace.Gravity or 196.2
    
    
    if v >= hitscanThreshold then
        local t = dist / v
        local lead = targetVelocity * t
        
        
        local targetFall = Vector3.new(0, 0, 0)
        if target.isFreefalling then
            targetFall = Vector3.new(0, 0.5 * targetG * (t * t), 0)
        end
        
        local aimPoint = targetPos + lead - targetFall
        return (aimPoint - origin).Unit
    end
    
    
    
    local t = dist / v
    local solvedDir = toTarget.Unit
    local iterations = Settings.predictionIterations or 10
    
    for i = 1, iterations do
        
        local futurePos = targetPos + (targetVelocity * t)
        if target.isFreefalling then
            futurePos = futurePos - Vector3.new(0, 0.5 * targetG * t * t, 0)
        end
        
        local delta = futurePos - origin
        local r = Vector3.new(delta.X, 0, delta.Z).Magnitude
        local h = delta.Y
        
        
        
        
        
        local g_r2 = g * r * r
        local v2 = v * v
        local a = g_r2 / (2 * v2)
        local b = -r
        local c = h + a
        
        local discriminant = b * b - 4 * a * c
        
        if discriminant >= 0 then
            
            local sqrtD = math.sqrt(discriminant)
            local tanTheta1 = (-b - sqrtD) / (2 * a)
            local tanTheta2 = (-b + sqrtD) / (2 * a)
            
            
            
            
            local tanTheta = math.min(tanTheta1, tanTheta2)
            
            
            
            local horizDir = Vector3.new(delta.X, 0, delta.Z).Unit
            if r < 0.001 then horizDir = Vector3.new(1,0,0) end 
            
            
            
            local vx = v / math.sqrt(1 + tanTheta * tanTheta)
            local vy = vx * tanTheta
            
            local launchVelocity = horizDir * vx + Vector3.new(0, vy, 0)
            solvedDir = launchVelocity.Unit
            
            
            
            local newT = r / vx
             if newT < 0 then newT = 0 end 
            
            if math.abs(newT - t) < 0.001 then
                t = newT
                break
            end
            t = newT
        else
            
            
            
             break
        end
    end

    return solvedDir
end

return Prediction

end

_modules["modules/Aimbot/Targeting"] = function()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Targeting = {
    SharedRaycastParams = RaycastParams.new(),
    SharedFilter = {}
}


Targeting.SharedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
Targeting.SharedRaycastParams.IgnoreWater = true

function Targeting.FindTarget(Settings, Utils, Aimbot)
    local bestTarget = nil
    local bestScore = math.huge
    local camera = workspace.CurrentCamera
    local screenCenter = Utils.getScreenCenter()
    
    local allPlayers = Players:GetPlayers()
    for i = 1, #allPlayers do
        local player = allPlayers[i]
        local character = Utils.getCharacter(player)
        
        
        local isTeammate = false
        if Settings.teamCheckEnabled then
            
            if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                isTeammate = true
            end
            
            
            if not isTeammate and player.TeamColor and LocalPlayer.TeamColor then
                if player.TeamColor == LocalPlayer.TeamColor then
                    isTeammate = true
                end
            end
            
            
            if isTeammate and player.Neutral and LocalPlayer.Neutral then
                if player.Neutral == true and LocalPlayer.Neutral == true then
                    isTeammate = false
                end
            end
            
            
            if not isTeammate and character and LocalPlayer.Character then
                local playerTeamAttr = character:GetAttribute("Team") or character:GetAttribute("team") or character:GetAttribute("TeamID")
                local localTeamAttr = LocalPlayer.Character:GetAttribute("Team") or LocalPlayer.Character:GetAttribute("team") or LocalPlayer.Character:GetAttribute("TeamID")
                
                if playerTeamAttr and localTeamAttr and playerTeamAttr == localTeamAttr then
                    isTeammate = true
                end
            end
            
            
            if not isTeammate and character and LocalPlayer.Character then
                local function getMainColor(char)
                    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
                    if torso and torso:IsA("BasePart") then
                        return torso.Color
                    end
                    return nil
                end
                
                local playerColor = getMainColor(character)
                local localColor = getMainColor(LocalPlayer.Character)
                
                if playerColor and localColor then
                    local colorDiff = (playerColor.R - localColor.R)^2 + (playerColor.G - localColor.G)^2 + (playerColor.B - localColor.B)^2
                    if colorDiff < 0.01 then 
                        isTeammate = true
                    end
                end
            end
        end
        
        if player ~= LocalPlayer and character and not isTeammate then
            local humanoid = character:FindFirstChild("Humanoid")
            local targetObj = Utils.getBodyPart(character, Settings.targetPart)
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if humanoid and humanoid.Health > 0 and rootPart then
                
                if not targetObj then targetObj = character:FindFirstChild("Head") end
                
                local isVisible = false
                local bestPart = targetObj
                
                if Settings.visibleCheckEnabled then
                    
                    if Settings.magicBulletEnabled and not Settings.magicBulletHouseCheck then
                        isVisible = true
                    else
                        isVisible = Utils.isPartVisible(targetObj, character)
                        
                        if not isVisible and Settings.targetPart ~= "Torso" then
                            
                            local torso = Utils.getBodyPart(character, "Torso")
                            if torso and Utils.isPartVisible(torso, character) then
                                isVisible = true
                                bestPart = torso
                            end
                        end
                        
                        if not isVisible then
                            
                            local size = targetObj.Size * 0.4
                            local points = {
                                targetObj.Position + Vector3.new(size.X, size.Y, size.Z),
                                targetObj.Position + Vector3.new(-size.X, size.Y, size.Z),
                                targetObj.Position + Vector3.new(size.X, -size.Y, size.Z),
                                targetObj.Position + Vector3.new(size.X, size.Y, -size.Z)
                            }
                            
                            for _, p in ipairs(points) do
                                local tempPart = {Position = p}
                                if Utils.isPartVisible(tempPart, character) then
                                    isVisible = true
                                    break
                                end
                            end
                        end
                        
                        
                        if not isVisible and Settings.magicBulletEnabled then
                            if Settings.magicBulletHouseCheck then
                                
                                local cam = workspace.CurrentCamera
                                if cam then
                                    local camPos = cam.CFrame.Position
                                    local direction = (targetObj.Position - camPos)
                                    local params = Targeting.SharedRaycastParams
                                    
                                    
                                    local filter = Targeting.SharedFilter
                                    for k in pairs(filter) do filter[k] = nil end
                                    
                                    table.insert(filter, character)
                                    
                                    local localChar = Utils.getCharacter(LocalPlayer)
                                    if localChar then table.insert(filter, localChar) end
                                    if LocalPlayer.Character and LocalPlayer.Character ~= localChar then
                                        table.insert(filter, LocalPlayer.Character)
                                    end
                                    table.insert(filter, cam)
                                    
                                    params.FilterDescendantsInstances = filter
                                    
                                    local rayResult = workspace:Raycast(camPos, direction, params)
                                    
                                    if not rayResult or not Utils.isHouse(rayResult.Instance) then
                                        isVisible = true
                                    end
                                end
                            else
                                
                                isVisible = true
                            end
                        end
                    end
                else
                    isVisible = true
                end

                if isVisible then
                    local pos, onScreen = camera:WorldToViewportPoint(bestPart.Position)
                    
                    
                    
                    local baseFov = Settings.fovSize or 90
                    local currentFov = baseFov
                    
                    if Aimbot and Aimbot.CurrentTarget and Aimbot.CurrentTarget.player == player then
                        currentFov = currentFov * 1.5 
                    end
                    
                    if onScreen then
                        local screenDistance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                        local worldDistance = (bestPart.Position - camera.CFrame.Position).Magnitude
                        
                        
                        local maxDistStuds = Settings.espMaxDistance or 700
                        if worldDistance <= maxDistStuds and screenDistance < currentFov then
                            local score = 0
                            local priority = Settings.targetPriority or "Distance"
                            
                            if priority == "Distance" then
                                score = worldDistance
                            elseif priority == "Crosshair" then
                                score = screenDistance
                            elseif priority == "Balanced" then
                                score = worldDistance * (1 + (screenDistance / (Settings.fovSize or 90)))
                            end

                            
                            
                            if Aimbot and Aimbot.CurrentTarget and Aimbot.CurrentTarget.player == player then
                                score = score * 0.6 
                            end

                            if score < bestScore then
                                bestScore = score
                                local humanoidState = humanoid:GetState()
                                local isFalling = (humanoidState == Enum.HumanoidStateType.Freefall or humanoidState == Enum.HumanoidStateType.Jumping)
                                
                                
                                if isFalling and math.abs(rootPart.Velocity.Y) < 1.5 then
                                    isFalling = false
                                end
                                
                                
                                local rawVel = rootPart.Velocity
                                local targetVel = rawVel
                                
                                
                                if humanoid.MoveDirection.Magnitude > 0.01 then
                                    local moveDir = humanoid.MoveDirection
                                    local speed = humanoid.WalkSpeed or 16
                                    
                                    
                                    local yVel = rawVel.Y
                                    if math.abs(yVel) < 3.5 and not isFalling then
                                        yVel = 0
                                    end
                                    targetVel = Vector3.new(moveDir.X * speed, yVel, moveDir.Z * speed)
                                else
                                    
                                    local vx = (math.abs(rawVel.X) < 1.0) and 0 or rawVel.X
                                    local vy = (math.abs(rawVel.Y) < 3.5 and not isFalling) and 0 or rawVel.Y
                                    local vz = (math.abs(rawVel.Z) < 1.0) and 0 or rawVel.Z
                                    targetVel = Vector3.new(vx, vy, vz)
                                end
                                
                                
                                if Aimbot and Aimbot.CurrentTarget and Aimbot.CurrentTarget.player == player then
                                    local lastVel = Aimbot.CurrentTarget.velocity
                                    if lastVel then
                                        targetVel = lastVel:Lerp(targetVel, 0.4) 
                                    end
                                end

                                
                                local stableFalling = isFalling
                                if Aimbot and Aimbot.CurrentTarget and Aimbot.CurrentTarget.player == player then
                                    
                                    
                                    if Aimbot.CurrentTarget.isFreefalling and not isFalling then
                                        
                                        if rawVel.Y < -5.0 then
                                            stableFalling = true
                                        end
                                    end
                                end

                                bestTarget = {
                                    player = player,
                                    targetPart = bestPart,
                                    rootPart = rootPart,
                                    velocity = targetVel,
                                    rawVelocity = rawVel, 
                                    lastPosition = bestPart.Position,
                                    distance = screenDistance,
                                    worldDistance = worldDistance,
                                    isFreefalling = stableFalling,
                                    isVisible = isVisible 
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    
    return bestTarget
end

return Targeting

end

_modules["modules/ESP/Chams"] = function()
local State = require("modules/ESP/State")

local Chams = {}

function Chams.Update(player, character, humanoid, Settings, activeHighlights, maxHighlights)
    if Settings.espEnabled and Settings.espHighlights and character.Parent and humanoid and humanoid.Health > 0 and activeHighlights < maxHighlights then
        if not State.Highlights[player] or not State.Highlights[player].Parent then
            local highlight = Instance.new("Highlight")
            highlight.Name = player.Name
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = State.GetContainer()
            State.Highlights[player] = highlight
            
            
            for _, v in ipairs(character:GetChildren()) do
                if v:IsA("Accessory") then
                    local handle = v:FindFirstChild("Handle")
                    if handle then
                        handle.LocalTransparencyModifier = 0.5
                    end
                end
            end
        end
        
        local h = State.Highlights[player]
        h.Enabled = true
        h.Adornee = character
        
        
        if Settings.espChamsMode == "Glow" then
            h.FillTransparency = 0.5
            h.OutlineTransparency = 0
            h.FillColor = Settings.espColor
            h.OutlineColor = Settings.espColor
        elseif Settings.espChamsMode == "Metal" then
            h.FillTransparency = 0.2
            h.OutlineTransparency = 0.5
            h.FillColor = Settings.espColor:lerp(Color3.fromRGB(150, 150, 150), 0.5)
            h.OutlineColor = Settings.espOutlineColor
        else
            h.FillTransparency = 0.5
            h.OutlineTransparency = 0
            h.FillColor = Settings.espColor
            h.OutlineColor = Settings.espOutlineColor or Color3.new(1, 1, 1)
        end
        return true 
    else
        if State.Highlights[player] then
            State.Highlights[player].Enabled = false
        end
        return false
    end
end

function Chams.Cleanup(player)
    if State.Highlights[player] then
        State.Highlights[player].Enabled = false
    end
end

function Chams.Destroy(player)
    if State.Highlights[player] then
        State.Highlights[player]:Destroy()
        State.Highlights[player] = nil
    end
end

return Chams

end

_modules["modules/ESP/Healthbars"] = function()
local State = require("modules/ESP/State")

local Healthbars = {}

function Healthbars.Update(player, character, rootPart, humanoid, Settings, isWithinDistance)
    if Settings.espEnabled and isWithinDistance and Settings.espHealthBar and character and rootPart and humanoid and humanoid.Health > 0 and character.Parent then
        if not State.Healthbars[player] or not State.Healthbars[player].Parent then
            local bbg = Instance.new("BillboardGui")
            bbg.Name = "ESP_Healthbar"
            bbg.AlwaysOnTop = true
            bbg.LightInfluence = 0
            bbg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            bbg.Parent = State.GetContainer()
            
            local bg = Instance.new("Frame")
            bg.Name = "Background"
            bg.BackgroundColor3 = Color3.new(0, 0, 0)
            bg.BackgroundTransparency = 0.5
            bg.BorderSizePixel = 0
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.Parent = bbg
            
            local fill = Instance.new("Frame")
            fill.Name = "Fill"
            fill.BorderSizePixel = 0
            fill.ZIndex = 2
            fill.Parent = bg
            
            local text = Instance.new("TextLabel")
            text.Name = "HealthText"
            text.BackgroundTransparency = 1
            text.Font = Enum.Font.GothamBold
            text.TextColor3 = Color3.new(1, 1, 1)
            text.TextStrokeTransparency = 0
            text.TextSize = 10
            text.ZIndex = 3
            text.Parent = bg
            
            State.Healthbars[player] = bbg
        end
        
        local bbg = State.Healthbars[player]
        bbg.Enabled = true
        bbg.Adornee = rootPart
        
        local bg = bbg:FindFirstChild("Background")
        local fill = bg and bg:FindFirstChild("Fill")
        local text = bg and bg:FindFirstChild("HealthText")
        
        if bg and fill and text then
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local position = Settings.espHealthBarPosition or "Left"
            
            local autoScale = (Settings.espHealthBarAutoScale == nil) and true or Settings.espHealthBarAutoScale
            local cam = workspace.CurrentCamera
            local distance = (cam and rootPart) and (cam.CFrame.Position - rootPart.Position).Magnitude or 1
            local baseDistance = Settings.espHealthBarBaseDistance or 25
            local minScale = Settings.espHealthBarMinScale or 0.4
            local maxScale = Settings.espHealthBarMaxScale or 1.0
            local fovFactor = cam and (70 / cam.FieldOfView) or 1
            local scale = 1
            if autoScale then
                scale = math.clamp((baseDistance / math.max(distance, 1)) * fovFactor, minScale, maxScale)
            end
            
            local baseLength = Settings.espHealthBarBaseSize or 50
            local baseThickness = Settings.espHealthBarBaseWidth or 4
            local lengthPx = math.max(1, math.floor(baseLength * scale + 0.5))
            local thicknessPx = math.max(1, math.floor(baseThickness * scale + 0.5))
            
            
            local color = Color3.fromHSV(healthPercent * 0.3, 1, 1)
            fill.BackgroundColor3 = color
            
            
            if Settings.espHealthBarText then
                text.Visible = true
                text.Text = math.floor(humanoid.Health)
            else
                text.Visible = false
            end
            
            
            if position == "Left" then
                bbg.Size = UDim2.new(0, thicknessPx, 0, lengthPx)
                bbg.StudsOffset = Vector3.new(-2.5, 0, 0)
                fill.Size = UDim2.new(1, 0, healthPercent, 0)
                fill.Position = UDim2.new(0, 0, 1 - healthPercent, 0)
                text.Size = UDim2.new(1, 0, 0, 10)
                text.Position = UDim2.new(0, 0, 0, -12)
            elseif position == "Right" then
                bbg.Size = UDim2.new(0, thicknessPx, 0, lengthPx)
                bbg.StudsOffset = Vector3.new(2.5, 0, 0)
                fill.Size = UDim2.new(1, 0, healthPercent, 0)
                fill.Position = UDim2.new(0, 0, 1 - healthPercent, 0)
                text.Size = UDim2.new(1, 0, 0, 10)
                text.Position = UDim2.new(0, 0, 0, -12)
            elseif position == "Bottom" then
                bbg.Size = UDim2.new(0, lengthPx, 0, thicknessPx)
                bbg.StudsOffset = Vector3.new(0, -3.5, 0)
                fill.Size = UDim2.new(healthPercent, 0, 1, 0)
                fill.Position = UDim2.new(0, 0, 0, 0)
                text.Size = UDim2.new(0, 20, 1, 0)
                text.Position = UDim2.new(1, 2, 0, 0)
                text.TextXAlignment = Enum.TextXAlignment.Left
            elseif position == "Top" then
                bbg.Size = UDim2.new(0, lengthPx, 0, thicknessPx)
                bbg.StudsOffset = Vector3.new(0, 3.5, 0)
                fill.Size = UDim2.new(healthPercent, 0, 1, 0)
                fill.Position = UDim2.new(0, 0, 0, 0)
                text.Size = UDim2.new(0, 20, 1, 0)
                text.Position = UDim2.new(1, 2, 0, 0)
                text.TextXAlignment = Enum.TextXAlignment.Left
            end
        end
    else
        if State.Healthbars[player] then
            State.Healthbars[player].Enabled = false
        end
    end
end

function Healthbars.Cleanup(player)
    if State.Healthbars[player] then
        State.Healthbars[player].Enabled = false
    end
end

function Healthbars.Destroy(player)
    if State.Healthbars[player] then
        State.Healthbars[player]:Destroy()
        State.Healthbars[player] = nil
    end
end

return Healthbars

end

_modules["modules/ESP/Labels"] = function()
local State = require("modules/ESP/State")

local Labels = {}

function Labels.Update(player, character, rootPart, humanoid, Settings, distance, isWithinDistance)
    if Settings.espEnabled and isWithinDistance and (Settings.espNames or Settings.espDistances or Settings.espWeapons) and character and rootPart and humanoid and humanoid.Health > 0 and character.Parent then
        if not State.Labels[player] or not State.Labels[player].Parent then
            local bbg = Instance.new("BillboardGui")
            bbg.Name = "ESP_Label"
            bbg.AlwaysOnTop = true
            bbg.LightInfluence = 0
            bbg.Active = false
            bbg.Size = UDim2.new(0, 250, 0, 150)
            bbg.StudsOffset = Vector3.new(0, 3, 0)
            bbg.Parent = State.GetContainer()
            
            local container = Instance.new("Frame")
            container.Name = "Container"
            container.BackgroundTransparency = 1
            container.Size = UDim2.new(1, 0, 1, 0)
            container.Parent = bbg
            
            local layout = Instance.new("UIListLayout")
            layout.Parent = container
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 2)
            
            local enemySlotsFrame = Instance.new("Frame")
            enemySlotsFrame.Name = "EnemySlotsFrame"
            enemySlotsFrame.BackgroundTransparency = 1
            enemySlotsFrame.Size = UDim2.new(1, 0, 0, 45)
            enemySlotsFrame.LayoutOrder = 0
            enemySlotsFrame.Parent = container

            local uiScale = Instance.new("UIScale")
            uiScale.Name = "UIScale"
            uiScale.Parent = enemySlotsFrame

            local slotsLayout = Instance.new("UIListLayout")
            slotsLayout.Parent = enemySlotsFrame
            slotsLayout.FillDirection = Enum.FillDirection.Horizontal
            slotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            slotsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
            slotsLayout.Padding = UDim.new(0, 4)

            for i = 1, 6 do
                local slot = Instance.new("Frame")
                slot.Name = "Slot" .. i
                slot.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                slot.BackgroundTransparency = 0.5
                slot.BorderSizePixel = 1
                slot.Size = UDim2.new(0, 32, 0, 32)
                slot.Parent = enemySlotsFrame

                local icon = Instance.new("ImageLabel")
                icon.Name = "Icon"
                icon.BackgroundTransparency = 1
                icon.Size = UDim2.new(1, -4, 1, -4)
                icon.Position = UDim2.new(0, 2, 0, 2)
                icon.ScaleType = Enum.ScaleType.Fit
                icon.ZIndex = 3
                icon.Parent = slot

                local name = Instance.new("TextLabel")
                name.Name = "Name"
                name.BackgroundTransparency = 1
                name.Position = UDim2.new(0.5, 0, 1, 2)
                name.AnchorPoint = Vector2.new(0.5, 0)
                name.Size = UDim2.new(1, 10, 0, 10)
                name.Font = Enum.Font.Gotham
                name.TextColor3 = Color3.new(1, 1, 1)
                name.TextSize = 8
                name.TextStrokeTransparency = 0
                name.ZIndex = 3
                name.Parent = slot
            end
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "NameLabel"
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size = UDim2.new(1, 0, 0, 20)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextColor3 = Settings.espTextColor
            nameLabel.TextSize = 14
            nameLabel.TextStrokeTransparency = 0
            nameLabel.LayoutOrder = 1
            nameLabel.ZIndex = 2
            nameLabel.Parent = container
            
            local distLabel = Instance.new("TextLabel")
            distLabel.Name = "DistLabel"
            distLabel.BackgroundTransparency = 1
            distLabel.Size = UDim2.new(1, 0, 0, 15)
            distLabel.Font = Enum.Font.Gotham
            distLabel.TextColor3 = Settings.espTextColor
            distLabel.TextSize = 12
            distLabel.TextStrokeTransparency = 0
            distLabel.LayoutOrder = 2
            distLabel.ZIndex = 2
            distLabel.Parent = container

            local weaponFrame = Instance.new("Frame")
            weaponFrame.Name = "WeaponFrame"
            weaponFrame.BackgroundTransparency = 1
            weaponFrame.Size = UDim2.new(1, 0, 0, 22)
            weaponFrame.LayoutOrder = 3
            weaponFrame.Parent = container
            
            local weaponLayout = Instance.new("UIListLayout")
            weaponLayout.Parent = weaponFrame
            weaponLayout.FillDirection = Enum.FillDirection.Horizontal
            weaponLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            weaponLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            weaponLayout.Padding = UDim.new(0, 6)

            local weaponIcon = Instance.new("ImageLabel")
            weaponIcon.Name = "WeaponIcon"
            weaponIcon.BackgroundTransparency = 1
            weaponIcon.Size = UDim2.new(0, 18, 0, 18)
            weaponIcon.ZIndex = 2
            weaponIcon.ScaleType = Enum.ScaleType.Fit
            weaponIcon.Parent = weaponFrame

            local weaponLabel = Instance.new("TextLabel")
            weaponLabel.Name = "WeaponLabel"
            weaponLabel.BackgroundTransparency = 1
            weaponLabel.Size = UDim2.new(0, 0, 1, 0)
            weaponLabel.AutomaticSize = Enum.AutomaticSize.X
            weaponLabel.Font = Enum.Font.GothamMedium
            weaponLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            weaponLabel.TextSize = 12
            weaponLabel.TextStrokeTransparency = 0
            weaponLabel.ZIndex = 2
            weaponLabel.Parent = weaponFrame
            
            State.Labels[player] = bbg
        end
        
        local bbg = State.Labels[player]
        bbg.Enabled = true
        bbg.Adornee = rootPart
        
        local container = bbg:FindFirstChild("Container")
        if container then
            local enemySlotsFrame = container:FindFirstChild("EnemySlotsFrame")
            if enemySlotsFrame then
                local uiScale = enemySlotsFrame:FindFirstChild("UIScale")
                if uiScale then
                    local baseDist = 60
                    local scale = math.clamp(baseDist / math.max(distance, 1), 0.5, 1.2)
                    uiScale.Scale = scale
                end
            end

            local nameLabel = container:FindFirstChild("NameLabel")
            local distLabel = container:FindFirstChild("DistLabel")
            local weaponFrame = container:FindFirstChild("WeaponFrame")
            
            if Settings.espNames and nameLabel then
                nameLabel.Visible = true
                nameLabel.Text = player.DisplayName or player.Name
                nameLabel.TextColor3 = Settings.espTextColor
            elseif nameLabel then
                nameLabel.Visible = false
            end
            
            if Settings.espDistances and distLabel then
                distLabel.Visible = true
                distLabel.Text = string.format("[%d studs]", math.floor(distance))
                distLabel.TextColor3 = Settings.espTextColor
            elseif distLabel then
                distLabel.Visible = false
            end

            if Settings.espWeapons and weaponFrame then
                local weaponLabel = weaponFrame:FindFirstChild("WeaponLabel")
                local weaponIcon = weaponFrame:FindFirstChild("WeaponIcon")
                local tool = character:FindFirstChildWhichIsA("Tool")
                
                weaponFrame.Visible = true
                if weaponLabel then
                    weaponLabel.Text = tool and tool.Name or "None"
                end
                
                if weaponIcon then
                    if Settings.espIcons and tool and tool.TextureId ~= "" then
                        weaponIcon.Visible = true
                        weaponIcon.Image = tool.TextureId
                    else
                        weaponIcon.Visible = false
                    end
                end
            elseif weaponFrame then
                weaponFrame.Visible = false
            end

            if Settings.espEnemySlots and enemySlotsFrame then
                enemySlotsFrame.Visible = true
                local items = {}
                
                
                
                local lastItemUpdate = bbg:GetAttribute("LastItemUpdate") or 0
                local now = tick()
                
                if now - lastItemUpdate > 1 then
                    bbg:SetAttribute("LastItemUpdate", now)
                    
                    
                    local equipped = character:FindFirstChildWhichIsA("Tool")
                    if equipped then
                        table.insert(items, equipped)
                    end
                    
                    
                    local backpack = player:FindFirstChild("Backpack")
                    if backpack then
                        local backpackChildren = backpack:GetChildren()
                        for j = 1, #backpackChildren do
                            local item = backpackChildren[j]
                            if item:IsA("Tool") and #items < 6 then
                                table.insert(items, item)
                            end
                        end
                    end
                    
                    for i = 1, 6 do
                        local slot = enemySlotsFrame:FindFirstChild("Slot" .. i)
                        if slot then
                            local item = items[i]
                            local icon = slot:FindFirstChild("Icon")
                            local name = slot:FindFirstChild("Name")
                            
                            if item then
                                slot.Visible = true
                                if icon then
                                    if item.TextureId ~= "" then
                                        icon.Visible = true
                                        icon.Image = item.TextureId
                                    else
                                        icon.Visible = false
                                    end
                                end
                                if name then
                                    name.Text = item.Name
                                end
                            else
                                slot.Visible = false
                            end
                        end
                    end
                end
            elseif enemySlotsFrame then
                enemySlotsFrame.Visible = false
            end
        end
    else
        if State.Labels[player] then
            State.Labels[player].Enabled = false
        end
    end
end

function Labels.Cleanup(player)
    if State.Labels[player] then
        State.Labels[player].Enabled = false
    end
end

function Labels.Destroy(player)
    if State.Labels[player] then
        State.Labels[player]:Destroy()
        State.Labels[player] = nil
    end
end

return Labels

end

_modules["modules/ESP/Skeleton"] = function()
local State = require("modules/ESP/State")

local Skeleton = {}

local R15_BONES = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

local R6_BONES = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

function Skeleton.Draw(player, character, Settings)
    if not State.Skeletons[player] then
        State.Skeletons[player] = {}
    end

    local skeleton = State.Skeletons[player]
    local isR15 = character:FindFirstChild("UpperTorso") ~= nil
    local bones = isR15 and R15_BONES or R6_BONES

    
    if #skeleton > #bones then
        for i = #bones + 1, #skeleton do
            skeleton[i]:Destroy()
            skeleton[i] = nil
        end
    end

    for i, bonePair in ipairs(bones) do
        local part1 = character:FindFirstChild(bonePair[1])
        local part2 = character:FindFirstChild(bonePair[2])

        if part1 and part2 then
            if not skeleton[i] then
                local line = Instance.new("LineHandleAdornment")
                line.Name = "BoneLine_" .. i
                line.Length = 0
                line.Thickness = 2
                line.ZIndex = 10
                line.AlwaysOnTop = true
                line.Transparency = 0
                line.Parent = State.GetContainer()
                skeleton[i] = line
            end

            local line = skeleton[i]
            local p1 = part1.Position
            local p2 = part2.Position
            local dist = (p1 - p2).Magnitude

            line.Visible = true
            line.Color3 = Settings.espSkeletonColor
            line.Transparency = 0
            line.Adornee = part1
            line.CFrame = CFrame.lookAt(Vector3.new(0, 0, 0), part1.CFrame:PointToObjectSpace(p2))
            line.Length = dist
        else
            if skeleton[i] then
                skeleton[i].Visible = false
            end
        end
    end
end

function Skeleton.Cleanup(player)
    if State.Skeletons[player] then
        for _, line in pairs(State.Skeletons[player]) do
            line.Visible = false
        end
    end
end

function Skeleton.Destroy(player)
    if State.Skeletons[player] then
        for _, line in pairs(State.Skeletons[player]) do
            line:Destroy()
        end
        State.Skeletons[player] = nil
    end
end

return Skeleton

end

_modules["modules/ESP/State"] = function()
local CoreGui = game:GetService("CoreGui")

local State = {
    Data = {},
    Highlights = {},
    Labels = {},
    Skeletons = {},
    Healthbars = {},
    Container = nil
}

function State.GetContainer()
    if not State.Container or not State.Container.Parent then
        local success, folder = pcall(function()
            local f = Instance.new("Folder")
            f.Name = "WithoniumESP"
            f.Parent = (gethui and gethui()) or CoreGui
            return f
        end)
        if success then
            State.Container = folder
        end
    end
    return State.Container
end

function State.Create(player)
    if not State.Data[player] then
        State.Data[player] = {
            LastCharacter = nil
        }
    end
end

return State

end

_require = function(p)
if _cache[p] then return _cache[p] end
if _modules[p] then
local s, r = pcall(_modules[p])
if s then
_cache[p] = r
return r
else
error('Err: ' .. tostring(r))
end
end
error('Not found: ' .. tostring(p))
end

local Modules = {
["Settings"] = _require("modules/Settings"),
["Utils"] = _require("modules/Utils"),
["ESP"] = _require("modules/ESP"),
["Aimbot"] = _require("modules/Aimbot"),
["GUI"] = _require("modules/GUI"),
["Visuals"] = _require("modules/Visuals"),
["Crosshair"] = _require("modules/Crosshair"),
["Ballistics"] = _require("modules/Ballistics"),
["BulletTracer"] = _require("modules/BulletTracer"),
["ConfigManager"] = _require("modules/ConfigManager"),
["ItemSpawner"] = _require("modules/ItemSpawner")
}

local Main = (function()
local function log(msg)
    pcall(function()
        warn("[LOG] " .. tostring(msg))
        if rconsoleprint then rconsoleprint("[LOG] " .. tostring(msg) .. "\n") end
    end)
end

log("Initializing core engine...")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

local Main = {
    Connections = {},
    Modules = {}
}

function Main.Init(Modules)
    Main.Modules = Modules
    local Settings = Modules.Settings
    local Utils = Modules.Utils
    local ESP = Modules.ESP
    local Aimbot = Modules.Aimbot
    local GUI = Modules.GUI
    local ConfigManager = Modules.ConfigManager
    local Ballistics = Modules.Ballistics
    local Visuals = Modules.Visuals
    local BulletTracer = Modules.BulletTracer
    local Crosshair = Modules.Crosshair
    local ItemSpawner = Modules.ItemSpawner

    -- Async initialization to prevent hanging
    task.spawn(function()
        -- Initialize ConfigManager
        if ConfigManager then
            pcall(function()
                ConfigManager.Init()
                ConfigManager.Load("autoload", Settings)
            end)
        end

        -- Initialize Visuals
        if Visuals then
            pcall(function() Visuals.Init(Settings) end)
        end

        -- Initialize Crosshair
        if Crosshair then
            pcall(function() Crosshair.Init() end)
        end

        -- Initialize ItemSpawner
        if ItemSpawner then
             pcall(function() ItemSpawner.ScanItems() end)
        end

        -- Initialize GUI
        local success_gui, err_gui = pcall(function()
            GUI.Init(Settings, Utils, function()
                Main.Unload()
            end, ConfigManager, ItemSpawner)
        end)
        if not success_gui then
            log("View error: " .. tostring(err_gui))
        end

        log("Finalizing engine...")
    end)

    -- Set initial cursor state
    UserInputService.MouseIconEnabled = Settings.guiVisible



    -- Function Keybind Handling
    local function handleKeybind(input, isBegan, processed)
        if processed then return end
        local keyCode = input.KeyCode
        local inputType = input.UserInputType
        
        -- Ignore input if typing in a TextBox
        if UserInputService:GetFocusedTextBox() then return end
        
        local keybinds = {
            {Key = Settings.silentAimKey, Mode = Settings.silentAimKeyMode, Setting = "silentAimEnabled", Name = "Silent Aim"},
            {Key = Settings.spiderKey, Mode = Settings.spiderKeyMode, Setting = "spiderEnabled", Name = "Spider"},
            {Key = Settings.speedHackKey, Mode = Settings.speedHackKeyMode, Setting = "speedHackEnabled", Name = "Speed"},
            {Key = Settings.freeCamKey, Mode = Settings.freeCamKeyMode, Setting = "freeCamEnabled", Name = "FreeCam"},
            {Key = Settings.jumpShotKey, Mode = Settings.jumpShotKeyMode, Setting = "jumpShotEnabled", Name = "Jump Shot"},
            {Key = Settings.FullBrightKey, Mode = Settings.FullBrightKeyMode, Setting = "fullBrightEnabled", Name = "FullBright"},
            {Key = Settings.antiAimKey, Mode = Settings.antiAimKeyMode, Setting = "antiAimEnabled", Name = "Anti-Aim"}
        }
        
        local updated = false
        for _, bind in ipairs(keybinds) do
            if bind.Key ~= Enum.KeyCode.Unknown and (keyCode == bind.Key or inputType == bind.Key) then
                if bind.Mode == "Toggle" then
                    if isBegan then
                        Settings[bind.Setting] = not Settings[bind.Setting]
                        updated = true
                        log("Toggled " .. bind.Name .. ": " .. tostring(Settings[bind.Setting]))
                    end
                elseif bind.Mode == "Hold" then
                    if Settings[bind.Setting] ~= isBegan then
                        Settings[bind.Setting] = isBegan
                        updated = true
                        log(bind.Name .. " (Hold): " .. tostring(isBegan))
                    end
                elseif bind.Mode == "Always" then
                    if not Settings[bind.Setting] then
                        Settings[bind.Setting] = true
                        updated = true
                        log(bind.Name .. " set to Always Active")
                    end
                end
            end
        end
        
        -- Refresh GUI if state changed and it's visible
        if updated and Settings.guiVisible and GUI then
            if GUI.UpdateToggles then
                GUI.UpdateToggles(Settings)
            end
        end
    end

    -- Toggle GUI Visibility
    table.insert(Main.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and (input.KeyCode == Settings.toggleKey or input.UserInputType == Settings.toggleKey) then
            if GUI and GUI.ToggleVisible then
                GUI.ToggleVisible(Settings)
            else
                Settings.guiVisible = not Settings.guiVisible
            end
            
            pcall(function()
                if Settings.guiVisible then
                    UserInputService.MouseIconEnabled = true
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                else
                    UserInputService.MouseIconEnabled = false
                    -- Restore mouse behavior for FPS games
                    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                end
            end)
        end
        -- We handle processed ourselves for function keybinds (except for toggleKey)
        handleKeybind(input, true, processed)
    end))

    table.insert(Main.Connections, UserInputService.InputEnded:Connect(function(input, processed)
        handleKeybind(input, false, processed)
    end))

    -- Main Loop
    local lastGuiUpdate = 0
    local lastVisualsUpdate = 0
    local lastErrorTime = 0
    
    RunService:BindToRenderStep("WithoniumUpdate", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
        -- Aimbot must run every frame for smoothness
        local success_aim, err_aim = pcall(function()
            Aimbot.Update(deltaTime, Settings, Utils, Ballistics, ESP)
        end)
        if not success_aim then 
            if tick() - lastErrorTime > 5 then
                lastErrorTime = tick()
                log("Aimbot update error: " .. tostring(err_aim)) 
            end
        end

        -- ESP can run at slightly lower frequency (e.g. 30-60 FPS)
        -- Throttling is handled inside ESP.Update itself now
        local success_esp, err_esp = pcall(function()
            ESP.Update(Settings, deltaTime, Utils)
        end)
        if not success_esp then 
            if tick() - lastErrorTime > 5 then
                lastErrorTime = tick()
                log("ESP update error: " .. tostring(err_esp)) 
            end
        end
        
        local now = tick()
        
        -- Visuals (FullBright etc) don't need to check every frame
        if now - lastVisualsUpdate > 0.5 then
            lastVisualsUpdate = now
            if Visuals then
                pcall(function() Visuals.Update(Settings) end)
            end
        end

        -- Crosshair update
        if Crosshair then
            pcall(function() Crosshair.Update(Settings) end)
        end
        
        -- Watermark update must be called every frame to count FPS correctly
        if GUI and GUI.UpdateWatermark then
            pcall(function() GUI.UpdateWatermark(Settings) end)
        end
        
        -- Other GUI elements update (Keybinds) - very slow if done every frame
        if now - lastGuiUpdate > 0.1 then
            lastGuiUpdate = now
            if GUI then
                pcall(function()
                    if GUI.UpdateKeybindList then
                        GUI.UpdateKeybindList(Settings)
                    end
                end)
            end
        end
    end)

    -- Initialize Hooks LAST to ensure everything else is ready
    task.spawn(function()
        task.wait(1) -- Extra safety delay
        log("Activating hooks...")
        pcall(function()
            Aimbot.InitHooks(Settings, Utils, Ballistics, BulletTracer)
        end)
    end)

    -- Cleanup on player removing
    table.insert(Main.Connections, Players.PlayerRemoving:Connect(function(player)
        ESP.Remove(player)
    end))
end

function Main.Unload()
    local Settings = Main.Modules.Settings
    local ConfigManager = Main.Modules.ConfigManager

    -- Auto-save settings
    if ConfigManager and Settings then
        ConfigManager.Save("autoload", Settings)
    end

    RunService:UnbindFromRenderStep("WithoniumUpdate")
    for _, conn in ipairs(Main.Connections) do
        if conn then conn:Disconnect() end
    end
    
    if Main.Modules.GUI and Main.Modules.GUI.ScreenGui then
        Main.Modules.GUI.ScreenGui:Destroy()
    end

    if Main.Modules.ESP then
        pcall(function()
            if Main.Modules.ESP.Data then
                for player, _ in pairs(Main.Modules.ESP.Data) do
                    pcall(function() Main.Modules.ESP.Remove(player) end)
                end
            end
            if Main.Modules.ESP.Container then
                Main.Modules.ESP.Container:Destroy()
            end
        end)
    end

    if Main.Modules.Aimbot then
        Main.Modules.Aimbot.Remove()
    end

    if Main.Modules.Visuals then
        Main.Modules.Visuals.Unload()
    end

    if Main.Modules.Crosshair then
        Main.Modules.Crosshair.Unload()
    end

    -- Restore mouse
    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

return Main

end)()

if Main and Main.Init then
pcall(function() Main.Init(Modules) end)
end