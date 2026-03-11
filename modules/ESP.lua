local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")


local State = require("modules/ESP/State")
local Skeleton = require("modules/ESP/Skeleton")
local Chams = require("modules/ESP/Chams")
local Labels = require("modules/ESP/Labels")
local Healthbars = require("modules/ESP/Healthbars")
local GlobalEnemySlots = require("modules/ESP/GlobalEnemySlots")

local ESP = {
    Data = State.Data,
    Highlights = State.Highlights,
    Labels = State.Labels,
    Skeletons = State.Skeletons,
    Healthbars = State.Healthbars,
    Container = State.Container,
    PlayersWithDist = {}, 
    PlayerDataPool = {}, 
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

function ESP.Update(Settings, deltaTime, Utils, Aimbot)
    local now = tick()
    if now - ESP.LastUpdate < 0.033 then return end 
    ESP.LastUpdate = now

    local Camera = workspace.CurrentCamera
    if not Camera then return end
    
    local screenCenter = Utils.getScreenCenter()
    local bestTargetPlayer = nil
    local bestTargetChar = nil
    local bestTargetItems = nil
    local minScreenDist = 60
    
    local activeHighlights = 0
    local maxHighlights = 15 
    
    
    local playersWithDist = ESP.PlayersWithDist
    local pool = ESP.PlayerDataPool
    
    
    for i = 1, #playersWithDist do
        local data = playersWithDist[i]
        data.Player = nil
        data.Character = nil
        data.RootPart = nil
        table.insert(pool, data)
        playersWithDist[i] = nil
    end
    
    local allPlayers = Players:GetPlayers()
    
    
    for player, _ in pairs(State.Data) do
        if not Players:GetPlayerByUserId(player.UserId) then
            ESP.Remove(player)
        end
    end

    for i = 1, #allPlayers do
        local player = allPlayers[i]
        if player == LocalPlayer then continue end
        
        local character = Utils.getCharacter(player)
        local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Middle") or character:FindFirstChild("Head") or character:FindFirstChildOfClass("BasePart"))
        
        if not rootPart and character then
            rootPart = Utils.getBodyPart(character, "Torso") or Utils.getBodyPart(character, "Head")
        end
        
        local dist = 999999
        if rootPart then
            dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
        end
        
        
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
        
        
        local isTeammate = false
        if player and LocalPlayer then
            
            if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                isTeammate = true
            end
            
            
            if not isTeammate and player.TeamColor and LocalPlayer.TeamColor then
                if player.TeamColor == LocalPlayer.TeamColor then
                    isTeammate = true
                end
            end
            
            
            if isTeammate and player.Neutral and LocalPlayer.Neutral then
                if player.Neutral == true and LocalPlayer.Neutral == true then
                    isTeammate = false
                end
            end
            
            
            if not isTeammate and character and LocalPlayer.Character then
                local playerTeamAttr = character:GetAttribute("Team") or character:GetAttribute("team") or character:GetAttribute("TeamID")
                local localTeamAttr = LocalPlayer.Character:GetAttribute("Team") or LocalPlayer.Character:GetAttribute("team") or LocalPlayer.Character:GetAttribute("TeamID")
                
                if playerTeamAttr and localTeamAttr and playerTeamAttr == localTeamAttr then
                    isTeammate = true
                end
            end
        end
        
        
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

        
        if State.Data[player] and State.Data[player].LastCharacter ~= character then
            ESP.Remove(player)
        end
        
        State.Create(player)
        State.Data[player].LastCharacter = character
        
        local humanoid = character:FindFirstChild("Humanoid")
        
        
        if Chams.Update(player, character, humanoid, Settings, activeHighlights, maxHighlights) then
            activeHighlights = activeHighlights + 1
        end

        
        if Settings.espEnabled and Settings.espSkeleton and character and humanoid and humanoid.Health > 0 and character.Parent then
            Skeleton.Draw(player, character, Settings)
        else
            Skeleton.Cleanup(player)
        end

        
        Labels.Update(player, character, rootPart, humanoid, Settings, distance, isWithinDistance)

        
        Healthbars.Update(player, character, rootPart, humanoid, Settings, isWithinDistance)
        
        
        if Settings.espEnemySlots and character and rootPart then
            local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            if onScreen and pos.Z > 0 then
                local screenDist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                if screenDist < minScreenDist then
                    minScreenDist = screenDist
                    bestTargetPlayer = player
                    bestTargetChar = character
                    
                    
                    local items = {}
                    local equipped = character:FindFirstChildWhichIsA("Tool")
                    if equipped then table.insert(items, equipped) end
                    local backpack = player:FindFirstChild("Backpack")
                    if backpack then
                        local children = backpack:GetChildren()
                        for j = 1, #children do
                            local item = children[j]
                            if item:IsA("Tool") and item ~= equipped and #items < 12 then
                                table.insert(items, item)
                            end
                        end
                    end
                    bestTargetItems = items
                end
            end
        end
    end
    
    
    if GlobalEnemySlots then
        GlobalEnemySlots.Update(Settings, bestTargetPlayer, bestTargetChar, bestTargetItems)
    end
end

return ESP
