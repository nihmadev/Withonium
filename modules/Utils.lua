local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Utils = {
    SharedRaycastParams = RaycastParams.new(),
    SharedFilterTable = {},
    BodyPartsCache = {}
}

-- Initialize shared params
Utils.SharedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
Utils.SharedRaycastParams.IgnoreWater = true

function Utils.getCharacter(player)
    if not player then return nil end
    
    -- Standard Roblox Character
    if player.Character then return player.Character end
    
    -- Support for games with custom characters (Trident Survival, etc.)
    -- PlaceId for Trident Survival
    if game.PlaceId == 13253735473 or game.PlaceId == 8130299583 then
        local renv = getrenv and getrenv()
        if renv and renv._G then
            -- Check for various character storage locations
            if renv._G.Character and renv._G.Character.character then
                if player == Players.LocalPlayer then
                    return renv._G.Character.character
                end
            end
        end
        
        -- Fallback: check workspace for a model with player name if standard Character is nil
        local ignorePlayers = workspace:FindFirstChild("Ignore") and workspace.Ignore:FindFirstChild("Players")
        if ignorePlayers then
            local char = ignorePlayers:FindFirstChild(player.Name)
            if char and char:IsA("Model") then return char end
        end
    end
    
    return nil
end

function Utils.getScreenCenter()
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize / 2 or Vector2.new(0, 0)
end

function Utils.getBodyPart(character, partName)
    if not character then return nil end
    
    if partName == "Head" then
        return character:FindFirstChild("Head")
    elseif partName == "Torso" then
        -- Prefer actual Torso parts for Hitbox Expander stability, as HumanoidRootPart can break physics
        -- Trident Survival uses "Middle"
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Middle")
    elseif partName == "Legs" then
        return character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg") or character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")
    end
    return character:FindFirstChild("Head")
end

function Utils.getAllBodyParts(character, partName)
    -- Reuse table from cache to avoid allocations
    local parts = Utils.BodyPartsCache
    for k in pairs(parts) do parts[k] = nil end
    
    if not character then return parts end
    
    if partName == "Head" then
        local p = character:FindFirstChild("Head")
        if p then table.insert(parts, p) end
    elseif partName == "Torso" then
        local p1 = character:FindFirstChild("UpperTorso")
        local p2 = character:FindFirstChild("LowerTorso")
        local p3 = character:FindFirstChild("Torso")
        if p1 then table.insert(parts, p1) end
        if p2 then table.insert(parts, p2) end
        if p3 then table.insert(parts, p3) end
    elseif partName == "Legs" then
        for _, n in ipairs({"Left Leg", "Right Leg", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg"}) do
            local p = character:FindFirstChild(n)
            if p then table.insert(parts, p) end
        end
    end
    return parts
end

function Utils.isPartVisible(part, character)
    if not part or not character then return false end
    
    local camera = workspace.CurrentCamera
    if not camera then return false end
    
    local origin = camera.CFrame.Position
    local destination = part.Position
    local direction = (destination - origin)
    
    if direction.Magnitude < 0.1 then return true end
    
    -- Reuse shared params and filter table
    local params = Utils.SharedRaycastParams
    local filter = Utils.SharedFilterTable
    
    -- Clear filter table
    for k in pairs(filter) do filter[k] = nil end
    
    -- Add target character and local character to filter
    if typeof(character) == "Instance" then
        table.insert(filter, character)
    end
    
    local localChar = Utils.getCharacter(LocalPlayer)
    if localChar then
        table.insert(filter, localChar)
    end
    
    if LocalPlayer.Character and LocalPlayer.Character ~= localChar then
        table.insert(filter, LocalPlayer.Character)
    end
    
    -- Add camera and standard ignore folders
    table.insert(filter, camera)
    local ignore = workspace:FindFirstChild("Ignore")
    if ignore then table.insert(filter, ignore) end
    
    params.FilterDescendantsInstances = filter
    
    -- Pierce through transparent/non-collidable objects
    local currentOrigin = origin + (direction.Unit * 0.1)
    local currentDirection = (destination - currentOrigin)
    
    for i = 1, 3 do -- Limit pierces to 3 for performance
        local result = workspace:Raycast(currentOrigin, currentDirection, params)
        if not result then return true end
        
        local hit = result.Instance
        local canPierce = false
        
        -- Check if we should pierce this object
        if hit.Transparency > 0.7 or not hit.CanCollide then
            canPierce = true
        else
            -- Check for common names that should be ignored
            local name = hit.Name:lower()
            if name:find("grass") or name:find("leaf") or name:find("cloud") or name:find("effect") or name:find("particle") then
                canPierce = true
            end
        end
        
        if canPierce then
            table.insert(filter, hit)
            params.FilterDescendantsInstances = filter
            currentOrigin = result.Position + (direction.Unit * 0.01)
            currentDirection = (destination - currentOrigin)
            if currentDirection.Magnitude < 0.05 then return true end
        else
            return false
        end
    end
    
    return false
end

function Utils.isHouse(part)
    if not part or not part:IsA("BasePart") then return false end
    if not part.CanCollide then return false end
    
    local name = part.Name:lower()
    local parent = part.Parent
    local parentName = parent and parent.Name:lower() or ""
    
    -- Heuristics for houses/buildings (more specific)
    if name:find("wall") or name:find("roof") or name:find("door") or 
       name:find("house") or name:find("building") or name:find("struct") or 
       parentName:find("house") or parentName:find("building") or parentName:find("struct") then
        return true
    end
    
    -- Many games put buildings in specific folders
    if parent and (parent:IsA("Folder") or parent:IsA("Model")) then
        if parentName:find("build") or parentName:find("house") or parentName:find("base") then
            return true
        end
    end
    
    return false
end

function Utils.MakeDraggable(topbarobject, object)
    local Dragging = nil
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    local function Update(input)
        local Delta = input.Position - DragStart
        local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        object.Position = pos
    end

    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            Update(input)
        end
    end)
end

return Utils
