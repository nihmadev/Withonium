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
    -- Safe check for Decoration property
    if Terrain then
        local success, val = pcall(function() return Terrain.Decoration end)
        if success then
            Visuals.HasDecorationProperty = true
            Visuals.OriginalDecoration = val
        end
    end

    -- Store Atmosphere settings
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

    -- Store current settings as normal
    Visuals.NormalSettings = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient
    }

    -- Watch for changes in Lighting
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
                -- If disabled, update NormalSettings so we know what to restore to
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

    -- Watch Atmosphere
    task.spawn(function()
        while task.wait(1) do
            if not Visuals.Connections or #Visuals.Connections == 0 then break end -- Correct cleanup check
            local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmosphere and Visuals.NoFogEnabled then
                if atmosphere.Density ~= 0 then atmosphere.Density = 0 end
                if atmosphere.Haze ~= 0 then atmosphere.Haze = 0 end
            end
        end
    end)

    -- Watch Terrain for No Grass
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
    -- FullBright logic
    if Settings.fullBrightEnabled ~= Visuals.Enabled then
        Visuals.Enabled = Settings.fullBrightEnabled
        
        if Visuals.Enabled then
            -- Apply FullBright
            Lighting.Brightness = Visuals.FullBrightSettings.Brightness
            Lighting.ClockTime = Visuals.FullBrightSettings.ClockTime
            Lighting.FogEnd = Visuals.FullBrightSettings.FogEnd
            Lighting.FogStart = 0
            Lighting.GlobalShadows = Visuals.FullBrightSettings.GlobalShadows
            Lighting.Ambient = Visuals.FullBrightSettings.Ambient
        else
            -- Restore Normal (or apply No Fog if active)
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

    -- No Fog logic (handles Atmosphere and Fog properties)
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

    -- No Grass logic (Terrain decoration and potentially models)
    if Settings.noGrassEnabled ~= Visuals.NoGrassEnabled then
        Visuals.NoGrassEnabled = Settings.noGrassEnabled
        
        if Visuals.HasDecorationProperty then
            Terrain.Decoration = not Visuals.NoGrassEnabled
        end
        
        -- Optimized: Only search once when toggled
        task.spawn(function()
            pcall(function()
                local grassNames = {"Grass", "TallGrass", "Shrub", "Bush"}
                local targetTransparency = Visuals.NoGrassEnabled and 1 or 0
                
                -- Optimization: only process parts directly to avoid double processing
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
                        
                        -- If not found by name, check parent model name
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
    
    -- Restore lighting on unload
    Lighting.Brightness = Visuals.NormalSettings.Brightness
    Lighting.ClockTime = Visuals.NormalSettings.ClockTime
    Lighting.FogEnd = Visuals.NormalSettings.FogEnd
    Lighting.GlobalShadows = Visuals.NormalSettings.GlobalShadows
    Lighting.Ambient = Visuals.NormalSettings.Ambient

    -- Restore grass
    if Terrain and Visuals.HasDecorationProperty then
        Terrain.Decoration = Visuals.OriginalDecoration
    end
end

return Visuals
