local State = require("modules/ESP/State")

local Healthbars = {}

function Healthbars.Update(player, character, rootPart, humanoid, Settings, isWithinDistance)
    if Settings.espEnabled and isWithinDistance and Settings.espHealthBar and character and rootPart and humanoid and humanoid.Health > 0 and character.Parent then
        if not State.Healthbars[player] or not State.Healthbars[player].Parent then
            local bbg = Instance.new("BillboardGui")
            bbg.Name = "ESP_Healthbar"
            bbg.AlwaysOnTop = true
            bbg.LightInfluence = 0
            bbg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            bbg.Parent = State.GetContainer()
            
            local bg = Instance.new("Frame")
            bg.Name = "Background"
            bg.BackgroundColor3 = Color3.new(0, 0, 0)
            bg.BackgroundTransparency = 0.5
            bg.BorderSizePixel = 0
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.Parent = bbg
            
            local fill = Instance.new("Frame")
            fill.Name = "Fill"
            fill.BorderSizePixel = 0
            fill.ZIndex = 2
            fill.Parent = bg
            
            local text = Instance.new("TextLabel")
            text.Name = "HealthText"
            text.BackgroundTransparency = 1
            text.Font = Enum.Font.GothamBold
            text.TextColor3 = Color3.new(1, 1, 1)
            text.TextStrokeTransparency = 0
            text.TextSize = 10
            text.ZIndex = 3
            text.Parent = bg
            
            State.Healthbars[player] = bbg
        end
        
        local bbg = State.Healthbars[player]
        bbg.Enabled = true
        bbg.Adornee = rootPart
        
        local bg = bbg:FindFirstChild("Background")
        local fill = bg and bg:FindFirstChild("Fill")
        local text = bg and bg:FindFirstChild("HealthText")
        
        if bg and fill and text then
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local position = Settings.espHealthBarPosition or "Left"
            
            local autoScale = (Settings.espHealthBarAutoScale == nil) and true or Settings.espHealthBarAutoScale
            local cam = workspace.CurrentCamera
            local distance = (cam and rootPart) and (cam.CFrame.Position - rootPart.Position).Magnitude or 1
            local baseDistance = Settings.espHealthBarBaseDistance or 25
            local minScale = Settings.espHealthBarMinScale or 0.4
            local maxScale = Settings.espHealthBarMaxScale or 1.0
            local fovFactor = cam and (70 / cam.FieldOfView) or 1
            local scale = 1
            if autoScale then
                scale = math.clamp((baseDistance / math.max(distance, 1)) * fovFactor, minScale, maxScale)
            end
            
            local baseLength = Settings.espHealthBarBaseSize or 50
            local baseThickness = Settings.espHealthBarBaseWidth or 4
            local lengthPx = math.max(1, math.floor(baseLength * scale + 0.5))
            local thicknessPx = math.max(1, math.floor(baseThickness * scale + 0.5))
            
            -- Health Color (Green -> Red)
            local color = Color3.fromHSV(healthPercent * 0.3, 1, 1)
            fill.BackgroundColor3 = color
            
            -- Text Update
            if Settings.espHealthBarText then
                text.Visible = true
                text.Text = math.floor(humanoid.Health)
            else
                text.Visible = false
            end
            
            -- Layout logic based on position
            if position == "Left" then
                bbg.Size = UDim2.new(0, thicknessPx, 0, lengthPx)
                bbg.StudsOffset = Vector3.new(-2.5, 0, 0)
                fill.Size = UDim2.new(1, 0, healthPercent, 0)
                fill.Position = UDim2.new(0, 0, 1 - healthPercent, 0)
                text.Size = UDim2.new(1, 0, 0, 10)
                text.Position = UDim2.new(0, 0, 0, -12)
            elseif position == "Right" then
                bbg.Size = UDim2.new(0, thicknessPx, 0, lengthPx)
                bbg.StudsOffset = Vector3.new(2.5, 0, 0)
                fill.Size = UDim2.new(1, 0, healthPercent, 0)
                fill.Position = UDim2.new(0, 0, 1 - healthPercent, 0)
                text.Size = UDim2.new(1, 0, 0, 10)
                text.Position = UDim2.new(0, 0, 0, -12)
            elseif position == "Bottom" then
                bbg.Size = UDim2.new(0, lengthPx, 0, thicknessPx)
                bbg.StudsOffset = Vector3.new(0, -3.5, 0)
                fill.Size = UDim2.new(healthPercent, 0, 1, 0)
                fill.Position = UDim2.new(0, 0, 0, 0)
                text.Size = UDim2.new(0, 20, 1, 0)
                text.Position = UDim2.new(1, 2, 0, 0)
                text.TextXAlignment = Enum.TextXAlignment.Left
            elseif position == "Top" then
                bbg.Size = UDim2.new(0, lengthPx, 0, thicknessPx)
                bbg.StudsOffset = Vector3.new(0, 3.5, 0)
                fill.Size = UDim2.new(healthPercent, 0, 1, 0)
                fill.Position = UDim2.new(0, 0, 0, 0)
                text.Size = UDim2.new(0, 20, 1, 0)
                text.Position = UDim2.new(1, 2, 0, 0)
                text.TextXAlignment = Enum.TextXAlignment.Left
            end
        end
    else
        if State.Healthbars[player] then
            State.Healthbars[player].Enabled = false
        end
    end
end

function Healthbars.Cleanup(player)
    if State.Healthbars[player] then
        State.Healthbars[player].Enabled = false
    end
end

function Healthbars.Destroy(player)
    if State.Healthbars[player] then
        State.Healthbars[player]:Destroy()
        State.Healthbars[player] = nil
    end
end

return Healthbars
