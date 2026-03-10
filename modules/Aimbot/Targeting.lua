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
                    
                    
                    
                    local targetPos = bestPart.Position
                    local originalPart = bestPart
                    
                    
                    if Settings.hitboxExpanderEnabled and rootPart then
                        local partName = bestPart.Name:lower()
                        if partName:find("head") then
                            
                            targetPos = rootPart.Position + Vector3.new(0, 2.2, 0)
                        elseif partName:find("torso") or partName:find("middle") or partName:find("center") then
                            
                            targetPos = rootPart.Position
                        end
                    end

                    local pos, onScreen = camera:WorldToViewportPoint(targetPos)
                    
                    local baseFov = Settings.fovSize or 90
                    local currentFov = baseFov
                    
                    if onScreen then
                        local screenDistance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                        local worldDistance = (targetPos - camera.CFrame.Position).Magnitude
                        
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
                                
                                local stableFalling = isFalling

                                bestTarget = {
                                    player = player,
                                    targetPart = originalPart,
                                    aimPosition = targetPos, 
                                    rootPart = rootPart,
                                    velocity = targetVel,
                                    rawVelocity = rawVel, 
                                    lastPosition = targetPos,
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
