local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Hitboxes = {
    lastHitboxUpdate = 0,
    OriginalProperties = setmetatable({}, {__mode = "k"}), 
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
                    
                    if part:IsA("Part") then
                        part.Shape = props.Shape or Enum.PartType.Block
                    end
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
    
    local size = Settings.hitboxExpanderSize or 5
    local targetSize = Vector3.new(size, size, size)
    local maxDist = Settings.espMaxDistance or 500
    local camPos = workspace.CurrentCamera.CFrame.Position
    
    local allPlayers = Players:GetPlayers()
    for i = 1, #allPlayers do
        local player = allPlayers[i]
        if player == LocalPlayer then continue end
        
        local character = player.Character
        if not character then continue end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        if not rootPart then continue end
        
        if (rootPart.Position - camPos).Magnitude > maxDist then
            continue 
        end

        local parts = Utils.getAllBodyParts(character, Settings.targetPart or "Head")
        
        for j = 1, #parts do
            local part = parts[j]
            if not part or part.Name == "HumanoidRootPart" then continue end
            
            if not Hitboxes.OriginalProperties[part] then
                Hitboxes.OriginalProperties[part] = {
                    Size = part.Size,
                    Transparency = part.Transparency,
                    CanCollide = part.CanCollide,
                    CanTouch = part.CanTouch,
                    Massless = part.Massless,
                    Shape = part:IsA("Part") and part.Shape or nil
                }
            end
            
            -- РЕГИСТРАЦИЯ УРОНА (МАКСИМУМ)
            -- 1. Используем Ball/Sphere для хитбокса, если это обычный Part. 
            -- Сферические хитбоксы регают урон намного лучше под любым углом.
            if part:IsA("Part") and part.Shape ~= Enum.PartType.Ball then
                part.Shape = Enum.PartType.Ball
            end

            -- 2. Принудительные свойства для коллизий лучей (Raycast/Projectiles)
            if part.Size ~= targetSize then
                part.Size = targetSize
                part.CanCollide = false 
                part.CanTouch = true  -- Важно для Touch-based урона
                part.Massless = true
                
                -- Отключаем CanQuery для физики, но оставляем для Raycast (в некоторых играх это помогает)
                -- Но чаще всего стандартного CanTouch достаточно.
            end

            -- ВИЗУАЛИЗАЦИЯ (СТАБИЛЬНЫЙ СКИН)
            if Settings.hitboxExpanderShow then
                -- Устанавливаем 80% прозрачность для основной части (скин персонажа)
                if part.Transparency ~= 0.8 then
                    part.Transparency = 0.8
                end
                
                -- Проблема "белой обводки" у 50/50 игроков:
                -- У некоторых игроков части - это MeshPart, у других - обычные Parts.
                -- SelectionBox на огромном хитбоксе выглядит как пустой квадрат.
                -- Решение: Делаем обводку максимально тонкой или убираем, если она мешает "скину".
                local visual = part:FindFirstChild("HitboxVisual")
                if not visual then
                    visual = Instance.new("SelectionBox")
                    visual.Name = "HitboxVisual"
                    visual.LineThickness = 0.005 -- Почти невидимая нить
                    visual.Adornee = part
                    visual.Color3 = Color3.fromRGB(255, 255, 255)
                    visual.Transparency = 0.9 -- Делаем обводку почти незаметной, чтобы видеть только скин
                    visual.Parent = part
                end
                visual.Visible = true
            else
                local visual = part:FindFirstChild("HitboxVisual")
                if visual then visual.Visible = false end
                
                local orig = Hitboxes.OriginalProperties[part]
                if orig and part.Transparency ~= orig.Transparency then
                    part.Transparency = orig.Transparency
                end
            end
        end
    end
    
    -- Инкрементальная очистка
    local partsInCache = {}
    local k = 0
    for part, _ in pairs(Hitboxes.OriginalProperties) do
        k = k + 1
        partsInCache[k] = part
    end
    
    local cleanupBatchSize = 10
    local startIndex = Hitboxes.CleanupIndex or 1
    if startIndex > #partsInCache then startIndex = 1 end
    
    for i = startIndex, math.min(startIndex + cleanupBatchSize, #partsInCache) do
        local part = partsInCache[i]
        if part then
            local char = part.Parent
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if not char or not char.Parent or not humanoid or humanoid.Health <= 0 then
                restorePart(part)
            end
        end
    end
    Hitboxes.CleanupIndex = startIndex + cleanupBatchSize
end

return Hitboxes
