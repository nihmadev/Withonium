local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Hitboxes = {
    lastHitboxUpdate = 0,
    OriginalProperties = {}, 
    ModifiedParts = {} 
}

function Hitboxes.UpdateHitboxes(Aimbot, Settings, Utils, ESP)
    if not Settings or not ESP then return end
    
    local now = tick()
    if now - Hitboxes.lastHitboxUpdate < 0.15 then return end 
    Hitboxes.lastHitboxUpdate = now
    
    local function restorePart(part)
        if not part then return end
        local props = Hitboxes.OriginalProperties[part]
        if props then
            pcall(function()
                part.Size = props.Size
                part.Transparency = props.Transparency
                part.CanCollide = props.CanCollide
                part.CanTouch = props.CanTouch
                part.Massless = props.Massless
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
    
    local size = Settings.hitboxExpanderSize or 5
    local targetSize = Vector3.new(size, size, size)
    
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Middle") or character:FindFirstChild("Torso")
            
            
            if not rootPart or (rootPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude > 500 then
                continue 
            end

            local parts = Utils.getAllBodyParts(character, Settings.targetPart)
            
            for _, part in ipairs(parts) do
                if part.Name == "HumanoidRootPart" then continue end
                
                if not Hitboxes.OriginalProperties[part] then
                    Hitboxes.OriginalProperties[part] = {
                        Size = part.Size,
                        Transparency = part.Transparency,
                        CanCollide = part.CanCollide,
                        CanTouch = part.CanTouch,
                        Massless = part.Massless
                    }
                end
                
                
                if part.Size ~= targetSize then
                    part.Size = targetSize
                    part.CanCollide = false 
                    part.CanTouch = true 
                    part.Massless = true 
                end

                
                if Settings.hitboxExpanderShow then
                    part.Transparency = 0.8
                    
                    
                    local selection = part:FindFirstChild("HitboxVisual")
                    if not selection then
                        selection = Instance.new("SelectionBox")
                        selection.Name = "HitboxVisual"
                        selection.LineThickness = 0.02
                        selection.Adornee = part
                        selection.Color3 = Color3.fromRGB(255, 255, 255) 
                        selection.Transparency = 0.7
                        selection.Parent = part
                    end
                    selection.Visible = true
                else
                    local selection = part:FindFirstChild("HitboxVisual")
                    if selection then selection.Visible = false end
                    part.Transparency = Hitboxes.OriginalProperties[part].Transparency
                end
            end
        end
    end
    
    
    
    local count = 0
    for part, props in pairs(Hitboxes.OriginalProperties) do
        count = count + 1
        
        if count % 3 == 0 or count > 50 then 
            local char = part and part.Parent
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            
            if not part or not char or not char.Parent or not humanoid or humanoid.Health <= 0 then
                restorePart(part)
            end
        end
    end
end

return Hitboxes
