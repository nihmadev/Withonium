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
    
    -- Shared objects for better performance
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

    -- Custom raycast function to ignore terrain and handle recursion
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

            -- Use workspace:Raycast directly, we'll bypass it with insideHook
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

    -- NEW TRACER STRATEGY: Input-based Loop (More reliable than hooking Raycast)
    game:GetService("RunService").RenderStepped:Connect(function()
        if not Settings.bulletTracerEnabled or not BulletTracer then return end
        
        -- Check Input (LMB or Console Trigger)
        local isShooting = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or 
                           UserInputService:IsGamepadButtonDown(Enum.KeyCode.ButtonR2)
        if not isShooting then return end
        
        -- Debounce (approx 10 shots per second max to prevent lag, or use weapon stats)
        local now = tick()
        if now - lastTracerTick < 0.08 then return end
        lastTracerTick = now
        
        -- Get Tool/Weapon
        local char = LocalPlayer.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        -- if not tool then return end -- REMOVED: Allow tracing even without tool (ViewModel support)
        
        -- Determine Origin
        local origin = nil
        
        -- 1. Try Muzzle/FirePoint attachments
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
        
        -- 2. Fallback to Camera or Head
        if not origin then
            local cam = workspace.CurrentCamera
            if cam then
                origin = cam.CFrame.Position + (cam.CFrame.LookVector * 1) + (cam.CFrame.RightVector * 0.5) + (cam.CFrame.UpVector * -0.5) -- Offset for right hand
            elseif char.Head then
                origin = char.Head.Position
            end
        end
        
        if not origin then return end
        
        -- Determine Direction/Target
        local direction
        local velocity = 1000
        local gravity = 196.2
        
        -- Ballistics
        local stats = Ballistics.GetWeaponFromTool(tool)
        if stats then
            velocity = stats.velocity or velocity
            gravity = stats.gravity or gravity
        end
        
        -- If Silent Aiming, trace to target
        if Aimbot.IsSilentAiming and Aimbot.SilentTarget and Aimbot.SilentTarget.targetPart then
            local target = Aimbot.SilentTarget
             -- Prediction
            local predDir = Aimbot.GetProjectilePrediction(target, Settings, Ballistics, origin)
            if predDir then
                direction = predDir
            else
                direction = (target.targetPart.Position - origin).Unit
            end
        else
            -- Trace to Mouse/Crosshair
            local mouse = LocalPlayer:GetMouse()
            local hit = mouse.Hit.Position
            direction = (hit - origin).Unit
        end
        
        -- Create Tracer
        pcall(function()
            BulletTracer.Create(origin, direction, velocity, gravity, Settings)
        end)
    end)

    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        -- 1. Instant checkcaller to bypass our own calls
        if checkcaller() then
            return oldNamecall(self, ...)
        end

        -- 2. Fetch method once and avoid further logic if not needed
        local method = getnamecallmethod()
        
        -- 3. Recursion and validity protection
        if insideHook or not self then
            return oldNamecall(self, ...)
        end

        -- 4. JumpShot logic (minimal overhead, specific self check)
        if method == "GetState" and Settings.jumpShotEnabled then
            if self == currentHumanoid and self.Parent then
                return Enum.HumanoidStateType.Landed
            end
        end

        -- 5. Silent Aim & Bullet Tracer Interception (only for workspace calls)
        if (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhiteList") and self == workspace then
            -- Exclude Camera/Popper scripts to prevent errors and spam
            local callingScript = getcallingscript and getcallingscript()
            if callingScript then
                 local scriptName = callingScript.Name
                 if scriptName == "Popper" or scriptName == "CameraModule" or scriptName == "ZoomController" or scriptName == "Poppercam" or scriptName == "ObjectHealthDisplayer" then
                     return oldNamecall(self, ...)
                 end
            end

            local args = {...}
            
            -- Weapon Check Throttling
            local now = os.clock()
            if now - lastWeaponCheck > 0.1 then
                lastWeaponCheck = now
                insideHook = true
                
                -- Safe Ballistics Check
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
                
                -- Verify origin from local player (Increased limit to 500)
                if typeof(origin) == "Vector3" and cam and (origin - cam.CFrame.Position).Magnitude < 500 then
                    -- Detect if user is actually shooting to prevent spam from crosshair/aim-assist raycasts
                    local isShooting = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or 
                                       UserInputService:IsGamepadButtonDown(Enum.KeyCode.ButtonR2)
                    
                    -- 1. Silent Aim & Magic Bullet logic
                    local target = (Aimbot.IsSilentAiming and Aimbot.SilentTarget) or (Settings.magicBulletEnabled and Aimbot.CurrentTarget)
                    
                    if target and target.targetPart and target.targetPart.Parent then
                        local originPos = origin
                        local targetPart = target.targetPart
                        local targetChar = Utils.getCharacter(target.player)
                        
                        -- General prediction
                        local predictedDir = Aimbot.GetProjectilePrediction(target, Settings, Ballistics, originPos)
                        
                        -- Perfect hit point: center of targetPart
                        local hitPos = targetPart.Position
                        local normal = Vector3.new(0, 1, 0)
                        
                        local magicDir = (hitPos - originPos).Unit * 99999
                        
                        if Settings.magicBulletEnabled and targetChar then
                            -- MAGIC BULLET: Bypass everything to hit the target
                            if method == "Raycast" then
                                -- Use specific part for maximum precision
                                sharedRaycastParams.FilterDescendantsInstances = {targetPart}
                                local result = customRaycastIgnoringTerrain(originPos, magicDir, sharedRaycastParams, 99999)
                                if result then return result end
                            else
                                -- Legacy methods - direct return
                                return targetPart, hitPos, normal, targetPart.Material
                            end
                            
                        elseif Aimbot.IsSilentAiming then
                            -- SILENT AIM: Use prediction
                            local silentDir = predictedDir * 99999
                            
                            if method == "Raycast" then
                                -- For Silent Aim, we still use the target character as include to bypass teammates/etc.
                                -- but we only return if it's a hit.
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
