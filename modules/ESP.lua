local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Sub-modules
local State = require("modules/ESP/State")
local Skeleton = require("modules/ESP/Skeleton")
local Chams = require("modules/ESP/Chams")
local Labels = require("modules/ESP/Labels")
local Healthbars = require("modules/ESP/Healthbars")

local ESP = {
    Data = State.Data,
    Highlights = State.Highlights,
    Labels = State.Labels,
    Skeletons = State.Skeletons,
    Healthbars = State.Healthbars,
    Container = State.Container,
    PlayersWithDist = {}, -- Reuse this table to reduce garbage collection
    PlayerDataPool = {}, -- Pool for player data tables
    LastUpdate = 0
}

function ESP.Create(player)
    State.Create(player)
end

function ESP.Remove(player)
    pcall(function() Chams.Destroy(player) end)
    pcall(function() Labels.Destroy(player) end)
    pcall(function() Skeleton.Destroy(player) end)
    pcall(function() Healthbars.Destroy(player) end)
    if State.Data then
        State.Data[player] = nil
    end
end

function ESP.Update(Settings, deltaTime, Utils)
    local now = tick()
    if now - ESP.LastUpdate < 0.033 then return end -- Max ~30 FPS for ESP updates (enough for smoothness)
    ESP.LastUpdate = now

    local Camera = workspace.CurrentCamera
    if not Camera then return end
    
    local activeHighlights = 0
    local maxHighlights = 15 -- Reduce limit for better performance
    
    -- Clear the list but keep the pool of tables
    local playersWithDist = ESP.PlayersWithDist
    local pool = ESP.PlayerDataPool
    
    -- Move all current tables back to pool and clear references
    for i = 1, #playersWithDist do
        local data = playersWithDist[i]
        data.Player = nil
        data.Character = nil
        data.RootPart = nil
        table.insert(pool, data)
        playersWithDist[i] = nil
    end
    
    local allPlayers = Players:GetPlayers()
    
    -- Cleanup ESP.Data for players who are no longer in the game
    for player, _ in pairs(State.Data) do
        if not Players:GetPlayerByUserId(player.UserId) then
            ESP.Remove(player)
        end
    end

    for i = 1, #allPlayers do
        local player = allPlayers[i]
        if player == LocalPlayer then continue end
        
        local character = Utils.getCharacter(player)
        local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Middle"))
        
        local dist = 999999
        if rootPart then
            dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
        end
        
        -- Get table from pool or create new if pool is empty
        local data = table.remove(pool) or {}
        data.Player = player
        data.Distance = dist
        data.Character = character
        data.RootPart = rootPart
        
        table.insert(playersWithDist, data)
    end
    
    table.sort(playersWithDist, function(a, b)
        return a.Distance < b.Distance
    end)

    local maxDistStuds = Settings.espMaxDistance or 700
    
    for i = 1, #playersWithDist do
        local data = playersWithDist[i]
        local player = data.Player
        local character = data.Character
        local rootPart = data.RootPart
        local distance = data.Distance
        
        -- Team Check: проверяем является ли игрок тиммейтом (множество методов)
        local isTeammate = false
        if player and LocalPlayer then
            -- Метод 1: Проверка через Team объект
            if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                isTeammate = true
            end
            
            -- Метод 2: Проверка через TeamColor
            if not isTeammate and player.TeamColor and LocalPlayer.TeamColor then
                if player.TeamColor == LocalPlayer.TeamColor then
                    isTeammate = true
                end
            end
            
            -- Метод 3: Проверка через Neutral
            if isTeammate and player.Neutral and LocalPlayer.Neutral then
                if player.Neutral == true and LocalPlayer.Neutral == true then
                    isTeammate = false
                end
            end
            
            -- Метод 4: Проверка через атрибуты персонажа (для кастомных систем команд)
            if not isTeammate and character and LocalPlayer.Character then
                local playerTeamAttr = character:GetAttribute("Team") or character:GetAttribute("team") or character:GetAttribute("TeamID")
                local localTeamAttr = LocalPlayer.Character:GetAttribute("Team") or LocalPlayer.Character:GetAttribute("team") or LocalPlayer.Character:GetAttribute("TeamID")
                
                if playerTeamAttr and localTeamAttr and playerTeamAttr == localTeamAttr then
                    isTeammate = true
                end
            end
            
            -- Метод 5: Проверка через цвет модели (некоторые игры красят персонажей в цвет команды)
            if not isTeammate and character and LocalPlayer.Character then
                local function getMainColor(char)
                    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
                    if torso and torso:IsA("BasePart") then
                        return torso.Color
                    end
                    return nil
                end
                
                local playerColor = getMainColor(character)
                local localColor = getMainColor(LocalPlayer.Character)
                
                if playerColor and localColor then
                    local colorDiff = (playerColor.R - localColor.R)^2 + (playerColor.G - localColor.G)^2 + (playerColor.B - localColor.B)^2
                    if colorDiff < 0.01 then -- Очень похожие цвета
                        isTeammate = true
                    end
                end
            end
        end
        
        -- Если Draw Teammates выключен и это тиммейт - очищаем ESP и пропускаем
        if not Settings.espDrawTeammates and isTeammate then
            Chams.Cleanup(player)
            Labels.Cleanup(player)
            Skeleton.Cleanup(player)
            Healthbars.Cleanup(player)
            continue
        end
        
        if not rootPart or not character then 
            ESP.Remove(player)
            continue 
        end

        local isWithinDistance = distance <= maxDistStuds
        
        if not isWithinDistance then
            Chams.Cleanup(player)
            Labels.Cleanup(player)
            Skeleton.Cleanup(player)
            Healthbars.Cleanup(player)
            continue
        end

        -- Reset visuals if character changed (respawn)
        if State.Data[player] and State.Data[player].LastCharacter ~= character then
            ESP.Remove(player)
        end
        
        State.Create(player)
        State.Data[player].LastCharacter = character
        
        local humanoid = character:FindFirstChild("Humanoid")
        
        -- Highlights (Chams)
        if Chams.Update(player, character, humanoid, Settings, activeHighlights, maxHighlights) then
            activeHighlights = activeHighlights + 1
        end

        -- Skeleton
        if Settings.espEnabled and Settings.espSkeleton and character and humanoid and humanoid.Health > 0 and character.Parent then
            Skeleton.Draw(player, character, Settings)
        else
            Skeleton.Cleanup(player)
        end

        -- Labels
        Labels.Update(player, character, rootPart, humanoid, Settings, distance, isWithinDistance)

        -- Healthbar
        Healthbars.Update(player, character, rootPart, humanoid, Settings, isWithinDistance)
    end
end

return ESP
