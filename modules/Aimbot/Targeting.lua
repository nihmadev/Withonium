local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Targeting = {
    SharedRaycastParams = RaycastParams.new(),
    SharedFilter = {}
}

-- Initialize shared params
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
        
        -- Team Check: пропускаем союзников (множество методов проверки)
        local isTeammate = false
        if Settings.teamCheckEnabled then
            -- Метод 1: Проверка через Team объект
            if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                isTeammate = true
            end
            
            -- Метод 2: Проверка через TeamColor
            if not isTeammate and player.TeamColor and LocalPlayer.TeamColor then
                if player.TeamColor == LocalPlayer.TeamColor then
                    isTeammate = true
                end
            end
            
            -- Метод 3: Проверка через Neutral
            if isTeammate and player.Neutral and LocalPlayer.Neutral then
                if player.Neutral == true and LocalPlayer.Neutral == true then
                    isTeammate = false
                end
            end
            
            -- Метод 4: Проверка через атрибуты персонажа (для кастомных систем команд)
            if not isTeammate and character and LocalPlayer.Character then
                local playerTeamAttr = character:GetAttribute("Team") or character:GetAttribute("team") or character:GetAttribute("TeamID")
                local localTeamAttr = LocalPlayer.Character:GetAttribute("Team") or LocalPlayer.Character:GetAttribute("team") or LocalPlayer.Character:GetAttribute("TeamID")
                
                if playerTeamAttr and localTeamAttr and playerTeamAttr == localTeamAttr then
                    isTeammate = true
                end
            end
            
            -- Метод 5: Проверка через цвет модели (некоторые игры красят персонажей в цвет команды)
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
                    if colorDiff < 0.01 then -- Очень похожие цвета
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
                -- Smart Hitbox selection: if primary part isn't visible, try others
                if not targetObj then targetObj = character:FindFirstChild("Head") end
                
                local isVisible = false
                local bestPart = targetObj
                
                if Settings.visibleCheckEnabled then
                    -- Если включены магические пули с игнором объектов, цель считается видимой всегда
                    if Settings.magicBulletEnabled and not Settings.magicBulletHouseCheck then
                        isVisible = true
                    else
                        isVisible = Utils.isPartVisible(targetObj, character)
                        
                        if not isVisible and Settings.targetPart ~= "Torso" then
                            -- Try Torso as fallback
                            local torso = Utils.getBodyPart(character, "Torso")
                            if torso and Utils.isPartVisible(torso, character) then
                                isVisible = true
                                bestPart = torso
                            end
                        end
                        
                        if not isVisible then
                            -- Multipoint visibility check for higher registration (90% target)
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
                        
                        -- Magic Bullet logic (house check)
                        if not isVisible and Settings.magicBulletEnabled then
                            if Settings.magicBulletHouseCheck then
                                -- Only allow if it's NOT a house (e.g. just a hill/wall)
                                local cam = workspace.CurrentCamera
                                if cam then
                                    local camPos = cam.CFrame.Position
                                    local direction = (targetObj.Position - camPos)
                                    local params = Targeting.SharedRaycastParams
                                    
                                    -- Optimized: reuse filter table
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
                                    -- Если луч ни во что не врезался ИЛИ врезался в НЕ дом — цель "видна" для магик пули
                                    if not rayResult or not Utils.isHouse(rayResult.Instance) then
                                        isVisible = true
                                    end
                                end
                            else
                                -- Если проверка домов выключена, то для аимбота цель всегда "видима"
                                isVisible = true
                            end
                        end
                    end
                else
                    isVisible = true
                end

                if isVisible then
                    local pos, onScreen = camera:WorldToViewportPoint(bestPart.Position)
                    
                    -- Improved FOV check: if we're already aiming at someone, allow a slightly larger FOV
                    -- to prevent flickering and sudden camera resets (the "180 spin" issue).
                    local baseFov = Settings.fovSize or 90
                    local currentFov = baseFov
                    
                    if Aimbot and Aimbot.CurrentTarget and Aimbot.CurrentTarget.player == player then
                        currentFov = currentFov * 1.5 -- 50% buffer for sticky aim
                    end
                    
                    if onScreen then
                        local screenDistance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                        local worldDistance = (bestPart.Position - camera.CFrame.Position).Magnitude
                        
                        -- Ограничение по дистанции из настроек ESP
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

                            -- Sticky Target: if we're already aiming at this person, give them a score bonus
                            -- to prevent switching to someone else unless they're much closer/better.
                            if Aimbot and Aimbot.CurrentTarget and Aimbot.CurrentTarget.player == player then
                                score = score * 0.6 -- 40% priority bonus for current target
                            end

                            if score < bestScore then
                                bestScore = score
                                local humanoidState = humanoid:GetState()
                                local isFalling = (humanoidState == Enum.HumanoidStateType.Freefall or humanoidState == Enum.HumanoidStateType.Jumping)
                                -- Дополнительная проверка: если он "падает", но скорость по Y почти нулевая, 
                                -- то скорее всего это ошибка стейта или он стоит на краю.
                                if isFalling and math.abs(rootPart.Velocity.Y) < 1.5 then
                                    isFalling = false
                                end
                                
                                -- Stabilize velocity for prediction (mix with MoveDirection if possible)
                                local rawVel = rootPart.Velocity
                                local targetVel = rawVel
                                
                                -- 1. Use MoveDirection for much more stable XZ velocity
                                if humanoid.MoveDirection.Magnitude > 0.01 then
                                    local moveDir = humanoid.MoveDirection
                                    local speed = humanoid.WalkSpeed or 16
                                    
                                    -- 2. Suppression of small Y jitter to prevent jitter on slopes/stairs
                                    local yVel = rawVel.Y
                                    if math.abs(yVel) < 3.5 and not isFalling then
                                        yVel = 0
                                    end
                                    targetVel = Vector3.new(moveDir.X * speed, yVel, moveDir.Z * speed)
                                else
                                    -- If standing still or not using MoveDirection, stabilize raw velocity
                                    local vx = (math.abs(rawVel.X) < 1.0) and 0 or rawVel.X
                                    local vy = (math.abs(rawVel.Y) < 3.5 and not isFalling) and 0 or rawVel.Y
                                    local vz = (math.abs(rawVel.Z) < 1.0) and 0 or rawVel.Z
                                    targetVel = Vector3.new(vx, vy, vz)
                                end
                                
                                -- 3. Final smoothing for target velocity
                                if Aimbot and Aimbot.CurrentTarget and Aimbot.CurrentTarget.player == player then
                                    local lastVel = Aimbot.CurrentTarget.velocity
                                    if lastVel then
                                        targetVel = lastVel:Lerp(targetVel, 0.4) -- Smooth transition
                                    end
                                end

                                -- Stable freefalling state to prevent vertical jitter
                                local stableFalling = isFalling
                                if Aimbot and Aimbot.CurrentTarget and Aimbot.CurrentTarget.player == player then
                                    -- If target was falling last frame, we require more evidence to say they stopped
                                    -- (Prevents jitter on small bumps/slopes)
                                    if Aimbot.CurrentTarget.isFreefalling and not isFalling then
                                        -- If they still have significant downward velocity, keep treating them as falling
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
                                    rawVelocity = rawVel, -- Keep raw for debugging/advanced use
                                    lastPosition = bestPart.Position,
                                    distance = screenDistance,
                                    worldDistance = worldDistance,
                                    isFreefalling = stableFalling,
                                    isVisible = isVisible -- Store visibility for Hooks
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
