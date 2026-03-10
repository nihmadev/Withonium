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
