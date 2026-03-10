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
