local State = require("modules/ESP/State")

local Labels = {}

function Labels.Update(player, character, rootPart, humanoid, Settings, distance, isWithinDistance)
    if Settings.espEnabled and isWithinDistance and (Settings.espNames or Settings.espDistances or Settings.espWeapons) and character and rootPart and humanoid and humanoid.Health > 0 and character.Parent then
        if not State.Labels[player] or not State.Labels[player].Parent then
            local bbg = Instance.new("BillboardGui")
            bbg.Name = "ESP_Label"
            bbg.AlwaysOnTop = true
            bbg.LightInfluence = 0
            bbg.Active = false
            bbg.Size = UDim2.new(0, 250, 0, 150)
            bbg.StudsOffset = Vector3.new(0, 3, 0)
            bbg.Parent = State.GetContainer()
            
            local container = Instance.new("Frame")
            container.Name = "Container"
            container.BackgroundTransparency = 1
            container.Size = UDim2.new(1, 0, 1, 0)
            container.Parent = bbg
            
            local layout = Instance.new("UIListLayout")
            layout.Parent = container
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 2)
            
            local enemySlotsFrame = Instance.new("Frame")
            enemySlotsFrame.Name = "EnemySlotsFrame"
            enemySlotsFrame.BackgroundTransparency = 1
            enemySlotsFrame.Size = UDim2.new(1, 0, 0, 45)
            enemySlotsFrame.LayoutOrder = 0
            enemySlotsFrame.Parent = container

            local uiScale = Instance.new("UIScale")
            uiScale.Name = "UIScale"
            uiScale.Parent = enemySlotsFrame

            local slotsLayout = Instance.new("UIListLayout")
            slotsLayout.Parent = enemySlotsFrame
            slotsLayout.FillDirection = Enum.FillDirection.Horizontal
            slotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            slotsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
            slotsLayout.Padding = UDim.new(0, 4)

            for i = 1, 6 do
                local slot = Instance.new("Frame")
                slot.Name = "Slot" .. i
                slot.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                slot.BackgroundTransparency = 0.5
                slot.BorderSizePixel = 1
                slot.Size = UDim2.new(0, 32, 0, 32)
                slot.Parent = enemySlotsFrame

                local icon = Instance.new("ImageLabel")
                icon.Name = "Icon"
                icon.BackgroundTransparency = 1
                icon.Size = UDim2.new(1, -4, 1, -4)
                icon.Position = UDim2.new(0, 2, 0, 2)
                icon.ScaleType = Enum.ScaleType.Fit
                icon.ZIndex = 3
                icon.Parent = slot

                local name = Instance.new("TextLabel")
                name.Name = "Name"
                name.BackgroundTransparency = 1
                name.Position = UDim2.new(0.5, 0, 1, 2)
                name.AnchorPoint = Vector2.new(0.5, 0)
                name.Size = UDim2.new(1, 10, 0, 10)
                name.Font = Enum.Font.Gotham
                name.TextColor3 = Color3.new(1, 1, 1)
                name.TextSize = 8
                name.TextStrokeTransparency = 0
                name.ZIndex = 3
                name.Parent = slot
            end
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "NameLabel"
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size = UDim2.new(1, 0, 0, 20)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextColor3 = Settings.espTextColor
            nameLabel.TextSize = 14
            nameLabel.TextStrokeTransparency = 0
            nameLabel.LayoutOrder = 1
            nameLabel.ZIndex = 2
            nameLabel.Parent = container
            
            local distLabel = Instance.new("TextLabel")
            distLabel.Name = "DistLabel"
            distLabel.BackgroundTransparency = 1
            distLabel.Size = UDim2.new(1, 0, 0, 15)
            distLabel.Font = Enum.Font.Gotham
            distLabel.TextColor3 = Settings.espTextColor
            distLabel.TextSize = 12
            distLabel.TextStrokeTransparency = 0
            distLabel.LayoutOrder = 2
            distLabel.ZIndex = 2
            distLabel.Parent = container

            local weaponFrame = Instance.new("Frame")
            weaponFrame.Name = "WeaponFrame"
            weaponFrame.BackgroundTransparency = 1
            weaponFrame.Size = UDim2.new(1, 0, 0, 22)
            weaponFrame.LayoutOrder = 3
            weaponFrame.Parent = container
            
            local weaponLayout = Instance.new("UIListLayout")
            weaponLayout.Parent = weaponFrame
            weaponLayout.FillDirection = Enum.FillDirection.Horizontal
            weaponLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            weaponLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            weaponLayout.Padding = UDim.new(0, 6)

            local weaponIcon = Instance.new("ImageLabel")
            weaponIcon.Name = "WeaponIcon"
            weaponIcon.BackgroundTransparency = 1
            weaponIcon.Size = UDim2.new(0, 18, 0, 18)
            weaponIcon.ZIndex = 2
            weaponIcon.ScaleType = Enum.ScaleType.Fit
            weaponIcon.Parent = weaponFrame

            local weaponLabel = Instance.new("TextLabel")
            weaponLabel.Name = "WeaponLabel"
            weaponLabel.BackgroundTransparency = 1
            weaponLabel.Size = UDim2.new(0, 0, 1, 0)
            weaponLabel.AutomaticSize = Enum.AutomaticSize.X
            weaponLabel.Font = Enum.Font.GothamMedium
            weaponLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            weaponLabel.TextSize = 12
            weaponLabel.TextStrokeTransparency = 0
            weaponLabel.ZIndex = 2
            weaponLabel.Parent = weaponFrame
            
            State.Labels[player] = bbg
        end
        
        local bbg = State.Labels[player]
        bbg.Enabled = true
        bbg.Adornee = rootPart
        
        local container = bbg:FindFirstChild("Container")
        if container then
            local enemySlotsFrame = container:FindFirstChild("EnemySlotsFrame")
            if enemySlotsFrame then
                local uiScale = enemySlotsFrame:FindFirstChild("UIScale")
                if uiScale then
                    local baseDist = 60
                    local scale = math.clamp(baseDist / math.max(distance, 1), 0.5, 1.2)
                    uiScale.Scale = scale
                end
            end

            local nameLabel = container:FindFirstChild("NameLabel")
            local distLabel = container:FindFirstChild("DistLabel")
            local weaponFrame = container:FindFirstChild("WeaponFrame")
            
            if Settings.espNames and nameLabel then
                nameLabel.Visible = true
                nameLabel.Text = player.DisplayName or player.Name
                nameLabel.TextColor3 = Settings.espTextColor
            elseif nameLabel then
                nameLabel.Visible = false
            end
            
            if Settings.espDistances and distLabel then
                distLabel.Visible = true
                distLabel.Text = string.format("[%d studs]", math.floor(distance))
                distLabel.TextColor3 = Settings.espTextColor
            elseif distLabel then
                distLabel.Visible = false
            end

            if Settings.espWeapons and weaponFrame then
                local weaponLabel = weaponFrame:FindFirstChild("WeaponLabel")
                local weaponIcon = weaponFrame:FindFirstChild("WeaponIcon")
                local tool = character:FindFirstChildWhichIsA("Tool")
                
                weaponFrame.Visible = true
                if weaponLabel then
                    weaponLabel.Text = tool and tool.Name or "None"
                end
                
                if weaponIcon then
                    if Settings.espIcons and tool and tool.TextureId ~= "" then
                        weaponIcon.Visible = true
                        weaponIcon.Image = tool.TextureId
                    else
                        weaponIcon.Visible = false
                    end
                end
            elseif weaponFrame then
                weaponFrame.Visible = false
            end

            if Settings.espEnemySlots and enemySlotsFrame then
                enemySlotsFrame.Visible = true
                local items = {}
                
                -- Optimization: only update slots if visible and character changed or every few frames
                -- We can use a simple tick() check on the bbg itself
                local lastItemUpdate = bbg:GetAttribute("LastItemUpdate") or 0
                local now = tick()
                
                if now - lastItemUpdate > 1 then
                    bbg:SetAttribute("LastItemUpdate", now)
                    
                    -- Get equipped tool
                    local equipped = character:FindFirstChildWhichIsA("Tool")
                    if equipped then
                        table.insert(items, equipped)
                    end
                    
                    -- Get backpack items
                    local backpack = player:FindFirstChild("Backpack")
                    if backpack then
                        local backpackChildren = backpack:GetChildren()
                        for j = 1, #backpackChildren do
                            local item = backpackChildren[j]
                            if item:IsA("Tool") and #items < 6 then
                                table.insert(items, item)
                            end
                        end
                    end
                    
                    for i = 1, 6 do
                        local slot = enemySlotsFrame:FindFirstChild("Slot" .. i)
                        if slot then
                            local item = items[i]
                            local icon = slot:FindFirstChild("Icon")
                            local name = slot:FindFirstChild("Name")
                            
                            if item then
                                slot.Visible = true
                                if icon then
                                    if item.TextureId ~= "" then
                                        icon.Visible = true
                                        icon.Image = item.TextureId
                                    else
                                        icon.Visible = false
                                    end
                                end
                                if name then
                                    name.Text = item.Name
                                end
                            else
                                slot.Visible = false
                            end
                        end
                    end
                end
            elseif enemySlotsFrame then
                enemySlotsFrame.Visible = false
            end
        end
    else
        if State.Labels[player] then
            State.Labels[player].Enabled = false
        end
    end
end

function Labels.Cleanup(player)
    if State.Labels[player] then
        State.Labels[player].Enabled = false
    end
end

function Labels.Destroy(player)
    if State.Labels[player] then
        State.Labels[player]:Destroy()
        State.Labels[player] = nil
    end
end

return Labels
