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
