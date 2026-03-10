local State = require("modules/ESP/State")

local Chams = {}

function Chams.Update(player, character, humanoid, Settings, activeHighlights, maxHighlights)
    if Settings.espEnabled and Settings.espHighlights and character.Parent and humanoid and humanoid.Health > 0 and activeHighlights < maxHighlights then
        if not State.Highlights[player] or not State.Highlights[player].Parent then
            local highlight = Instance.new("Highlight")
            highlight.Name = player.Name
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = State.GetContainer()
            State.Highlights[player] = highlight
            
            
            for _, v in ipairs(character:GetChildren()) do
                if v:IsA("Accessory") then
                    local handle = v:FindFirstChild("Handle")
                    if handle then
                        handle.LocalTransparencyModifier = 0.5
                    end
                end
            end
        end
        
        local h = State.Highlights[player]
        h.Enabled = true
        h.Adornee = character
        
        
        if Settings.espChamsMode == "Glow" then
            h.FillTransparency = 0.5
            h.OutlineTransparency = 0
            h.FillColor = Settings.espColor
            h.OutlineColor = Settings.espColor
        elseif Settings.espChamsMode == "Metal" then
            h.FillTransparency = 0.2
            h.OutlineTransparency = 0.5
            h.FillColor = Settings.espColor:lerp(Color3.fromRGB(150, 150, 150), 0.5)
            h.OutlineColor = Settings.espOutlineColor
        else
            h.FillTransparency = 0.5
            h.OutlineTransparency = 0
            h.FillColor = Settings.espColor
            h.OutlineColor = Settings.espOutlineColor or Color3.new(1, 1, 1)
        end
        return true 
    else
        if State.Highlights[player] then
            State.Highlights[player].Enabled = false
        end
        return false
    end
end

function Chams.Cleanup(player)
    if State.Highlights[player] then
        State.Highlights[player].Enabled = false
    end
end

function Chams.Destroy(player)
    if State.Highlights[player] then
        State.Highlights[player]:Destroy()
        State.Highlights[player] = nil
    end
end

return Chams
