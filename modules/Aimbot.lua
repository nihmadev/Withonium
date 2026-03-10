local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- Sub-modules
-- We assume these are in the 'Aimbot' folder relative to this script
-- In a real Roblox environment, this would be require(script.Aimbot.Prediction)
-- but for this file-based structure, we'll use paths that make sense for the loader.
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
    
    -- FreeCam State
    FreeCamActive = false,
    FreeCamPos = Vector3.new(0, 0, 0),
    FreeCamRot = Vector2.new(0, 0),
    OriginalCameraType = nil,
    OriginalCameraCFrame = nil,
    
    -- Smooth Prediction Properties
    LastPredictedDir = nil,
    PredictionSmoothing = 0.2, -- Чем меньше, тем плавнее (0.1 - 0.5)
    
    -- Velocity Averaging
    VelocityHistory = {},
    MaxHistorySize = 5,

    TargetLineLastPos = nil,
}

-- Initialize FOV Circle
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
    line.ZIndex = 10 -- Ensure it's on top
    line.Visible = false
    line.Parent = sg
    Aimbot.TargetLine = line
end

CreateFOVCircle()

-- Interface methods delegating to sub-modules
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
    
    -- Require weapon (Tool) to be equipped for zoom to engage
    local character = LocalPlayer.Character
    local hasWeapon = false
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        hasWeapon = tool ~= nil
    end
    
    -- Initialize BaseFOV if needed
    if not Aimbot.BaseFOV then
        Aimbot.BaseFOV = camera.FieldOfView
    end
    
    -- Determine zoom state
    local isZooming = false
    if Settings.aimKeyMode == "Toggle" then
        isZooming = Aimbot.ToggleActive and hasWeapon
    else
        isZooming = Aimbot.IsInputPressed(Settings.aimKey) and hasWeapon
    end
    
    local smoothness = Settings.zoomSmoothness or 0.1
    
    if isZooming then
        -- Capture BaseFOV right before zooming starts
        if not Aimbot.WasZooming then
            Aimbot.BaseFOV = camera.FieldOfView
            Aimbot.WasZooming = true
        end
        
        local targetFOV = math.max(1, Aimbot.BaseFOV - Settings.zoomAmount)
        camera.FieldOfView = camera.FieldOfView + (targetFOV - camera.FieldOfView) * smoothness
    else
        if Aimbot.WasZooming then
            -- Returning to BaseFOV
            local diff = math.abs(camera.FieldOfView - Aimbot.BaseFOV)
            if diff > 0.5 then
                 camera.FieldOfView = camera.FieldOfView + (Aimbot.BaseFOV - camera.FieldOfView) * smoothness
            else
                 -- Done returning
                 camera.FieldOfView = Aimbot.BaseFOV
                 Aimbot.WasZooming = false
            end
        else
            -- Not zooming, just tracking game FOV
            Aimbot.BaseFOV = camera.FieldOfView
        end
    end
end

function Aimbot.Update(deltaTime, Settings, Utils, Ballistics, ESP)
    if not Settings then return end
    
    Aimbot.UpdateHitboxes(Settings, Utils, ESP)
    
    -- Cache target for current frame to avoid multiple expensive searches
    local currentFrameTarget = Aimbot.FindTarget(Settings, Utils)
    
    -- Обновляем цель для Silent Aim один раз за кадр, чтобы не лагало в хуках
    if Settings.silentAimEnabled then
        Aimbot.SilentTarget = currentFrameTarget
    else
        Aimbot.SilentTarget = nil
    end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    -- Main Aimbot State
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

    -- Silent Aim State (independent from main aimbot)
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
    
    -- Update CurrentTarget for Magic Bullets even if not aiming
    if Settings.magicBulletEnabled then
        Aimbot.CurrentTarget = currentFrameTarget
    end
    
    if shouldAim or shouldSilentAim then
        local target = currentFrameTarget
        if target and target.targetPart then
            -- Reset smoothing and history if target changed
            if Aimbot.CurrentTarget and Aimbot.CurrentTarget.player ~= target.player then
                Aimbot.LastPredictedDir = nil
                Aimbot.VelocityHistory = {}
            end
            
            -- Velocity Averaging: Reduces jitter from physics noise
            table.insert(Aimbot.VelocityHistory, target.velocity)
            if #Aimbot.VelocityHistory > (Aimbot.MaxHistorySize or 5) then
                table.remove(Aimbot.VelocityHistory, 1)
            end
            
            local avgVelocity = Vector3.new(0, 0, 0)
            for _, v in ipairs(Aimbot.VelocityHistory) do
                avgVelocity = avgVelocity + v
            end
            avgVelocity = avgVelocity / #Aimbot.VelocityHistory
            
            -- Temporarily override target velocity with averaged one
            local originalVelocity = target.velocity
            target.velocity = avgVelocity
            
            Aimbot.CurrentTarget = target
            
            if shouldAim then
                Aimbot.IsAiming = true
                
                -- Use a much more stable origin (HumanoidRootPart is better than Head/Camera for prediction)
                 local character = LocalPlayer.Character
                 local origin = camera.CFrame.Position
                 if character and character:FindFirstChild("HumanoidRootPart") then
                     -- Stable origin: RootPart position + standard offset for eyes
                     origin = character.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0)
                 end
     
                 local predictedDir = Aimbot.GetProjectilePrediction(target, Settings, Ballistics, origin)
                
                -- Restore original velocity just in case
                target.velocity = originalVelocity
                
                -- Smooth Prediction: Prevents jitter when target is moving erratically
                local pSmoothing = Settings.predictionSmoothing or 0.2
                if Aimbot.LastPredictedDir and pSmoothing > 0 then
                    predictedDir = Aimbot.LastPredictedDir:Lerp(predictedDir, math.clamp(1 - pSmoothing, 0.01, 1))
                end
                Aimbot.LastPredictedDir = predictedDir
                
                Aimbot.TargetPosition = origin + (predictedDir * 10)
                
                local currentCFrame = camera.CFrame
                -- Safety check for lookAt to prevent "spinning" when looking straight up/down
                local upVector = Vector3.new(0, 1, 0)
                if math.abs(predictedDir:Dot(upVector)) > 0.99 then
                    upVector = Vector3.new(0, 0, 1) -- Use forward as up if looking vertically
                end
                
                local targetCFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + predictedDir, upVector)
                
                -- Improved Smoothness: use an exponential factor for better feel
                local smoothnessFactor = Settings.smoothness or 0.5
                -- Limit deltaTime to prevent huge jumps after lag spikes
                local safeDeltaTime = math.min(deltaTime, 0.1)
                
                -- Adjust alpha to be more responsive but still smooth
                local alpha = math.clamp(safeDeltaTime * (smoothnessFactor * 120), 0, 1)
                
                if smoothnessFactor < 1 then
                    camera.CFrame = currentCFrame:Lerp(targetCFrame, alpha)
                else
                    camera.CFrame = targetCFrame
                end
            else
                Aimbot.IsAiming = false
                target.velocity = originalVelocity -- Restore for other uses
            end
        else
            -- Reset state when target is lost
            Aimbot.CurrentTarget = nil
            Aimbot.IsAiming = false
            Aimbot.TargetPosition = nil
            Aimbot.LastPredictedDir = nil
            Aimbot.VelocityHistory = {} -- Clear history
        end
    else
        -- Reset state when aiming stops
        Aimbot.CurrentTarget = nil
        Aimbot.IsAiming = false
        Aimbot.TargetPosition = nil
        Aimbot.LastPredictedDir = nil -- Reset smoothing when not aiming
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
    
    -- Anti-Aim should be applied early or late depending on preference, 
    -- but here we ensure it doesn't break the aimbot by running it after calculations.
    Aimbot.ApplyAntiAim(Settings)

    -- Update FOV Circle
    if Aimbot.FOVCircle then
        local enabled = Settings.fovCircleEnabled
        Aimbot.FOVCircle.Visible = enabled
        
        if enabled then
            local radius = Settings.fovSize or 90
            local mousePos = UserInputService:GetMouseLocation()
            
            Aimbot.FOVCircle.Size = UDim2.new(0, radius * 2, 0, radius * 2)
            -- GetMouseLocation is relative to screen, and ScreenGui is IgnoreGuiInset = true, so this is correct
            Aimbot.FOVCircle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
        end
    end

    -- Update Target Line
    if Aimbot.TargetLine then
        local target = currentFrameTarget
        local showLine = Settings.targetLineEnabled and target ~= nil and target.targetPart ~= nil
        
        if showLine then
            local camera = workspace.CurrentCamera
            if camera then
                local targetPos, onScreen = camera:WorldToViewportPoint(target.targetPart.Position)
                
                if onScreen and targetPos.Z > 0 then
                    -- Get the visual center of the target (Head or Torso) for the line
                    local visualPart = target.targetPart
                    pcall(function()
                        local char = Utils.getCharacter(target.player)
                        if char then
                            -- Prioritize Head -> Torso -> Center for visual line to avoid pointing at feet
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
                    
                    -- Safety check for visualPart and its Position
                    local success, visualPos = pcall(function() return visualPart.Position end)
                    if not success or not visualPos then
                        visualPos = target.targetPart.Position
                    end
                    
                    -- Use the raw position from WorldToViewportPoint for the line to avoid prediction offsets
                    local screenPos, visualOnScreen = camera:WorldToViewportPoint(visualPos)
                    
                    -- Get precise start (center) and end (target) positions in Screen Space
                    local startPos = UserInputService:GetMouseLocation()
                    
                    -- Use WorldToViewportPoint directly. Since ScreenGui.IgnoreGuiInset is true, 
                    -- (0,0) is the top-left of the window, which matches WorldToViewportPoint.
                    -- Adding GuiInset here was causing the line to point lower (e.g. at legs).
                    local endPos = Vector2.new(screenPos.X, screenPos.Y)
                    
                    -- Remove heavy Lerp to prevent the line from lagging behind the head/torso
                    if Aimbot.TargetLineLastPos and typeof(Aimbot.TargetLineLastPos) == "Vector2" then
                        endPos = Aimbot.TargetLineLastPos:Lerp(endPos, 0.9) -- High responsiveness
                    end
                    Aimbot.TargetLineLastPos = endPos
                    
                    local diff = endPos - startPos
                    local dist = diff.Magnitude
                    local radius = Settings.fovSize or 90
                    
                    -- Show line if it's within a reasonable distance from center
                    if dist > 1 and dist <= (radius * 2.0) then
                        -- CALCULATE MIDPOINT: This is crucial for Frame rotation without Drawing lib
                        -- Frames rotate around their center (AnchorPoint 0.5, 0.5)
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
        
        -- Restore collision if needed
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
    
    -- Restore hitboxes
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
    
    -- Restore Anti-Aim state
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
