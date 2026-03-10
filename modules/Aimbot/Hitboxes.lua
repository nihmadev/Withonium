local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Hitboxes = {
    lastHitboxUpdate = 0,
    OriginalProperties = setmetatable({}, {__mode = "k"}), -- Weak table for automatic cleanup
    CleanupIndex = 1
}

function Hitboxes.UpdateHitboxes(Aimbot, Settings, Utils, ESP)
    if not Settings or not ESP then return end
    
    local now = tick()
    if now - Hitboxes.lastHitboxUpdate < 0.2 then return end 
    Hitboxes.lastHitboxUpdate = now
    
    local function restorePart(part)
        if not part then return end
        local props = Hitboxes.OriginalProperties[part]
        if props then
            pcall(function()
                if part.Parent then
                    part.Size = props.Size
                    part.Transparency = props.Transparency
                    part.CanCollide = props.CanCollide
                    part.CanTouch = props.CanTouch
                    part.Massless = props.Massless
                end
                local visual = part:FindFirstChild("HitboxVisual")
                if visual then visual:Destroy() end
            end)
            Hitboxes.OriginalProperties[part] = nil
        end
    end

    if not Settings.hitboxExpanderEnabled then
        if next(Hitboxes.OriginalProperties) then
            for part, _ in pairs(Hitboxes.OriginalProperties) do
                restorePart(part)
            end
        end
        return
    end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local size = Settings.hitboxExpanderSize or 5
    local targetSize = Vector3.new(size, size, size)
    local camPos = camera.CFrame.Position
    local maxDist = Settings.espMaxDistance or 500
    
    -- Main loop
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
            
            if not rootPart or (rootPart.Position - camPos).Magnitude > maxDist then
                continue 
            end

            local parts = Utils.getAllBodyParts(character, Settings.targetPart or "Head")
            
            for _, part in ipairs(parts) do
                if not part or not part:IsA("BasePart") or part.Name == "HumanoidRootPart" then continue end
                
                if not Hitboxes.OriginalProperties[part] then
                    Hitboxes.OriginalProperties[part] = {
                        Size = part.Size,
                        Transparency = part.Transparency,
                        CanCollide = part.CanCollide,
                        CanTouch = part.CanTouch,
                        Massless = part.Massless
                    }
                end
                
                -- Only apply if different to avoid constant property setting (lag source)
                if part.Size ~= targetSize then
                    pcall(function()
                        part.Size = targetSize
                        part.CanCollide = false 
                        part.CanTouch = true 
                        part.Massless = true 
                    end)
                end

                if Settings.hitboxExpanderShow then
                    if part.Transparency ~= 0.8 then
                        part.Transparency = 0.8
                    end
                    
                    local selection = part:FindFirstChild("HitboxVisual")
                    if not selection then
                        selection = Instance.new("SelectionBox")
                        selection.Name = "HitboxVisual"
                        selection.LineThickness = 0.01
                        selection.Adornee = part
                        selection.Color3 = Color3.fromRGB(255, 255, 255) 
                        selection.Transparency = 0.8
                        selection.Parent = part
                    end
                    selection.Visible = true
                else
                    local selection = part:FindFirstChild("HitboxVisual")
                    if selection then selection.Visible = false end
                    
                    local orig = Hitboxes.OriginalProperties[part]
                    if orig and part.Transparency ~= orig.Transparency then
                        part.Transparency = orig.Transparency
                    end
                end
            end
        end
    end
    
    -- Incremental Cleanup (Robust)
    local count = 0
    for part, props in pairs(Hitboxes.OriginalProperties) do
        count = count + 1
        if count % 5 == 0 then -- Check every 5th part
            if not part or not part.Parent or not part.Parent.Parent then
                restorePart(part)
            else
                local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
                if not humanoid or humanoid.Health <= 0 then
                    restorePart(part)
                end
            end
        end
    end
end

return Hitboxes

return Hitboxes
