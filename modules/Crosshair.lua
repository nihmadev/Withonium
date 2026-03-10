local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Crosshair = {
    MainFrame = nil,
    ScreenGui = nil,
    Segments = {},
    Enabled = false,
    CurrentType = "Default",
    Rotation = 0
}

function Crosshair.GetCenter()
    return UserInputService:GetMouseLocation()
end

function Crosshair.Clear()
    if Crosshair.MainFrame then
        Crosshair.MainFrame:Destroy()
        Crosshair.MainFrame = nil
    end
    Crosshair.Segments = {}
end

function Crosshair.Init()
    local gui_parent = nil
    pcall(function()
        if gethui then gui_parent = gethui()
        elseif game:GetService("CoreGui") then gui_parent = game:GetService("CoreGui")
        else gui_parent = LocalPlayer:WaitForChild("PlayerGui") end
    end)

    if not gui_parent then return end

    local sg = Instance.new("ScreenGui")
    sg.Name = "WithoniumCrosshair"
    sg.DisplayOrder = 1000
    sg.IgnoreGuiInset = true
    sg.Parent = gui_parent
    Crosshair.ScreenGui = sg
end

function Crosshair.CreateSegment(parent, size, pos, rotation)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.new(1, 1, 1) 
    frame.BorderSizePixel = 0
    frame.Active = false
    frame.Selectable = false
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = size
    frame.Position = pos
    frame.Rotation = rotation or 0
    frame.Parent = parent
    return frame
end

function Crosshair.Update(Settings)
    if not Settings.crosshairEnabled then
        if Crosshair.Enabled then
            Crosshair.Clear()
            Crosshair.Enabled = false
            UserInputService.MouseIconEnabled = true
        end
        return
    end

    Crosshair.Enabled = true
    UserInputService.MouseIconEnabled = false

    local mousePos = Crosshair.GetCenter()
    local color = Settings.crosshairColor or Color3.fromRGB(255, 0, 0)
    local size = Settings.crosshairSize or 10
    local thickness = Settings.crosshairThickness or 1
    local type = Settings.crosshairType or "Default"

    if not Crosshair.MainFrame or Crosshair.CurrentType ~= type then
        Crosshair.Clear()
        Crosshair.CurrentType = type
        
        Crosshair.MainFrame = Instance.new("Frame")
        Crosshair.MainFrame.BackgroundTransparency = 1
        Crosshair.MainFrame.Size = UDim2.new(0, 0, 0, 0)
        Crosshair.MainFrame.Parent = Crosshair.ScreenGui

        if type == "Default" then
            
            table.insert(Crosshair.Segments, Crosshair.CreateSegment(Crosshair.MainFrame, UDim2.new(0, thickness, 0, size * 2), UDim2.new(0, 0, 0, 0)))
            
            table.insert(Crosshair.Segments, Crosshair.CreateSegment(Crosshair.MainFrame, UDim2.new(0, size * 2, 0, thickness), UDim2.new(0, 0, 0, 0)))
        elseif type == "X" then
            
            table.insert(Crosshair.Segments, Crosshair.CreateSegment(Crosshair.MainFrame, UDim2.new(0, thickness, 0, size * 2), UDim2.new(0, 0, 0, 0), 45))
            
            table.insert(Crosshair.Segments, Crosshair.CreateSegment(Crosshair.MainFrame, UDim2.new(0, thickness, 0, size * 2), UDim2.new(0, 0, 0, 0), -45))
        elseif type == "Swastika" then
            
            for i = 1, 8 do
                table.insert(Crosshair.Segments, Crosshair.CreateSegment(Crosshair.MainFrame, UDim2.new(0, size, 0, thickness), UDim2.new(0, 0, 0, 0)))
            end
        end
    end

    
    Crosshair.MainFrame.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)

    
    if type == "Swastika" then
        Crosshair.Rotation = (Crosshair.Rotation + 2) % 360
        Crosshair.MainFrame.Rotation = Crosshair.Rotation
        
        local halfSize = size / 2
        
        
        Crosshair.Segments[1].Position = UDim2.new(0, halfSize, 0, 0)
        Crosshair.Segments[1].Size = UDim2.new(0, size, 0, thickness)
        Crosshair.Segments[2].Position = UDim2.new(0, size, 0, halfSize)
        Crosshair.Segments[2].Size = UDim2.new(0, thickness, 0, size)
        
        
        Crosshair.Segments[3].Position = UDim2.new(0, 0, 0, halfSize)
        Crosshair.Segments[3].Size = UDim2.new(0, thickness, 0, size)
        Crosshair.Segments[4].Position = UDim2.new(0, -halfSize, 0, size)
        Crosshair.Segments[4].Size = UDim2.new(0, size, 0, thickness)
        
        
        Crosshair.Segments[5].Position = UDim2.new(0, -halfSize, 0, 0)
        Crosshair.Segments[5].Size = UDim2.new(0, size, 0, thickness)
        Crosshair.Segments[6].Position = UDim2.new(0, -size, 0, -halfSize)
        Crosshair.Segments[6].Size = UDim2.new(0, thickness, 0, size)
        
        
        Crosshair.Segments[7].Position = UDim2.new(0, 0, 0, -halfSize)
        Crosshair.Segments[7].Size = UDim2.new(0, thickness, 0, size)
        Crosshair.Segments[8].Position = UDim2.new(0, halfSize, 0, -size)
        Crosshair.Segments[8].Size = UDim2.new(0, size, 0, thickness)
    end

    
    for _, segment in ipairs(Crosshair.Segments) do
        segment.BackgroundColor3 = color
        if type ~= "Swastika" then
            if type == "Default" then
                if segment.Size.X.Offset > segment.Size.Y.Offset then
                    segment.Size = UDim2.new(0, size * 2, 0, thickness)
                else
                    segment.Size = UDim2.new(0, thickness, 0, size * 2)
                end
            elseif type == "X" then
                segment.Size = UDim2.new(0, thickness, 0, size * 2.5) 
            end
        end
    end
end

function Crosshair.Unload()
    Crosshair.Clear()
    if Crosshair.ScreenGui then
        Crosshair.ScreenGui:Destroy()
        Crosshair.ScreenGui = nil
    end
    UserInputService.MouseIconEnabled = true
end

return Crosshair
