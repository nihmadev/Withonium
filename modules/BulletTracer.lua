local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local BulletTracer = {}

-- Function to draw a single segment (straight line)
function BulletTracer.DrawSegment(startPos, endPos, color, duration, thickness, parent)
    local dist = (endPos - startPos).Magnitude
    if dist < 0.05 then return end
    
    -- Adjust thickness for rounder/smaller look (User requested smaller)
    local actualThickness = thickness * 0.6
    
    local part = Instance.new("Part")
    part.Name = "TracerSegment"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Shape = Enum.PartType.Cylinder -- Round shape
    part.Color = color
    part.Size = Vector3.new(dist, actualThickness, actualThickness) -- X is length for Cylinder
    -- Align X axis (Cylinder length) with the direction (LookVector is -Z, so rotate 90 deg Y)
    -- And move center forward by dist/2
    part.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(dist/2, 0, 0)
    part.Transparency = 0
    part.Parent = parent
    
    -- Smooth fade out
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

-- Main function to create a bullet tracer
function BulletTracer.Create(origin, direction, velocity, gravity, settings)
    if not settings or not settings.bulletTracerEnabled then return end
    
    local color = settings.bulletTracerColor or Color3.fromRGB(255, 0, 0)
    local duration = settings.bulletTracerDuration or 2
    local thickness = settings.bulletTracerThickness or 0.1
    local usePhysics = settings.bulletTracerPhysics
    
    -- Folder for tracers to keep workspace clean
    local folder = workspace:FindFirstChild("BulletTracers")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "BulletTracers"
        folder.Parent = workspace
    end
    
    -- Normalize direction just in case
    local dirUnit = direction.Unit
    if dirUnit.X ~= dirUnit.X then -- NaN check
        return 
    end
    
    -- If no physics or gravity is zero, draw a simple straight line
    if not usePhysics or not gravity or gravity == 0 then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        -- Exclude local player and the tracers themselves
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
    
    -- Physics-based curved tracer
    local currentPos = origin
    local currentVel = dirUnit * velocity
    local stepTime = 0.03 -- 30ms steps for smooth curve
    local maxTime = 4.0   -- Max 4 seconds flight
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
        -- Standard projectile motion: p = p0 + v0*t + 0.5*g*t^2
        -- But we do it iteratively for easier collision detection
        local nextPos = currentPos + (currentVel * stepTime) + (0.5 * gVec * (stepTime * stepTime))
        local segmentDir = nextPos - currentPos
        
        -- Check for collision during this segment
        local rayResult = workspace:Raycast(currentPos, segmentDir, raycastParams)
        if rayResult then
            BulletTracer.DrawSegment(currentPos, rayResult.Position, color, duration, thickness, folder)
            break
        end
        
        -- Draw the segment
        BulletTracer.DrawSegment(currentPos, nextPos, color, duration, thickness, folder)
        
        -- Update for next step
        currentPos = nextPos
        currentVel = currentVel + (gVec * stepTime)
        
        -- Optimization: stop if it goes too far or too low
        if currentPos.Y < -500 or (currentPos - origin).Magnitude > 5000 then break end
    end
end

return BulletTracer
