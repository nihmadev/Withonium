local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GlobalEnemySlots = {
    Frame = nil,
    Slots = {},
    LastUpdate = 0,
    Initialized = false
}

function GlobalEnemySlots.Init(GUI)
    if GlobalEnemySlots.Initialized then return end
    if not GUI or not GUI.ScreenGui then return end
    
    local frame = Instance.new("Frame")
    frame.Name = "GlobalEnemySlots"
    frame.BackgroundTransparency = 1
    
    
    
    frame.Position = UDim2.new(0.5, 0, 1, -125) 
    frame.AnchorPoint = Vector2.new(0.5, 1)
    frame.Size = UDim2.new(0, 350, 0, 120)
    frame.Visible = false
    frame.Parent = GUI.ScreenGui
    
    local layout = Instance.new("UIGridLayout")
    layout.Parent = frame
    layout.CellPadding = UDim2.new(0, 6, 0, 6)
    layout.CellSize = UDim2.new(0, 52, 0, 52) 
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    for i = 1, 12 do
        local slot = Instance.new("Frame")
        slot.Name = "Slot" .. i
        slot.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        slot.BackgroundTransparency = 0.4
        slot.BorderSizePixel = 1
        slot.Parent = frame
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(80, 80, 80)
        stroke.Thickness = 1
        stroke.Parent = slot
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = slot

        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(1, -10, 1, -10)
        icon.Position = UDim2.new(0, 5, 0, 5)
        icon.ScaleType = Enum.ScaleType.Fit
        icon.ZIndex = 2
        icon.Parent = slot
        
        local name = Instance.new("TextLabel")
        name.Name = "Name"
        name.BackgroundTransparency = 1
        name.Position = UDim2.new(0.5, 0, 1, -3)
        name.AnchorPoint = Vector2.new(0.5, 1)
        name.Size = UDim2.new(1, -6, 0, 12)
        name.Font = Enum.Font.GothamMedium
        name.TextColor3 = Color3.new(1, 1, 1)
        name.TextSize = 8
        name.TextStrokeTransparency = 0.5
        name.ZIndex = 3
        name.Parent = slot
        
        GlobalEnemySlots.Slots[i] = {
            Frame = slot,
            Icon = icon,
            Name = name
        }
    end
    
    GlobalEnemySlots.Frame = frame
    GlobalEnemySlots.Initialized = true
end

function GlobalEnemySlots.Update(Settings, Utils, Aimbot)
    if not Settings.espEnabled or not Settings.espEnemySlots or not GlobalEnemySlots.Frame then
        if GlobalEnemySlots.Frame then GlobalEnemySlots.Frame.Visible = false end
        return
    end
    
    
    local target = Aimbot.FindTarget(Settings, Utils)
    if not target or not target.player then
        GlobalEnemySlots.Frame.Visible = false
        return
    end
    
    local player = target.player
    local character = Utils.getCharacter(player)
    if not character then
        GlobalEnemySlots.Frame.Visible = false
        return
    end
    
    GlobalEnemySlots.Frame.Visible = true
    
    local now = tick()
    if now - GlobalEnemySlots.LastUpdate < 0.2 then return end 
    GlobalEnemySlots.LastUpdate = now
    
    local items = {}
    
    
    local equipped = character:FindFirstChildWhichIsA("Tool")
    if equipped then
        table.insert(items, equipped)
    end
    
    
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        local children = backpack:GetChildren()
        for i = 1, #children do
            local item = children[i]
            if item:IsA("Tool") and item ~= equipped and #items < 12 then
                table.insert(items, item)
            end
        end
    end
    
    for i = 1, 12 do
        local slot = GlobalEnemySlots.Slots[i]
        local item = items[i]
        
        if item then
            slot.Frame.Visible = true
            if item.TextureId ~= "" then
                slot.Icon.Visible = true
                slot.Icon.Image = item.TextureId
            else
                slot.Icon.Visible = false
            end
            slot.Name.Text = item.Name
        else
            slot.Frame.Visible = false
        end
    end
end

return GlobalEnemySlots
