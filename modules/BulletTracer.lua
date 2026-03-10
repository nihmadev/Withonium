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
