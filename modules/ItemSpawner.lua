local ItemSpawner = {
    Items = {},
    Remotes = {},
    Icons = {},
    Initialized = false
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterPack = game:GetService("StarterPack")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- Logging function
function ItemSpawner.Log(msg)
    local formatted = "[Spawner] " .. tostring(msg)
    warn(formatted)
    if rconsoleprint then
        rconsoleprint(formatted .. "\n")
    end
end

-- Utility to find remotes
local function findRemotes(root)
    local found = {}
    local function scan(parent)
        for _, v in ipairs(parent:GetChildren()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                local name = v.Name:lower()
                -- Expanded keywords list
                if name:find("craft") or name:find("buy") or name:find("reward") or 
                   name:find("claim") or name:find("give") or name:find("item") or 
                   name:find("shop") or name:find("purchase") or name:find("equip") or 
                   name:find("inventory") or name:find("add") or name:find("pickup") or
                   name:find("get") or name:find("take") then
                    table.insert(found, v)
                end
            end
            if v:IsA("Folder") or v:IsA("Model") or v:IsA("ScreenGui") or v:IsA("Tool") or v:IsA("Backpack") then
                scan(v)
            end
        end
    end
    scan(root)
    return found
end

-- Scan for items in common locations
function ItemSpawner.ScanItems()
    ItemSpawner.Items = {}
    local locations = {ReplicatedStorage, Lighting, Workspace, StarterPack}
    
    for _, loc in ipairs(locations) do
        for _, v in ipairs(loc:GetDescendants()) do
            if v:IsA("Tool") or (v:IsA("ModuleScript") and v.Name:lower():find("item")) then
                -- Check if it has an icon
                local icon = "rbxassetid://0" -- Placeholder
                if v:IsA("Tool") and v.TextureId ~= "" then
                    icon = v.TextureId
                end
                
                -- Avoid duplicates if possible
                local exists = false
                for _, existing in ipairs(ItemSpawner.Items) do
                    if existing.Name == v.Name then exists = true break end
                end
                
                if not exists then
                    table.insert(ItemSpawner.Items, {
                        Name = v.Name,
                        Object = v,
                        Icon = icon,
                        Type = v.ClassName
                    })
                end
            end
        end
    end
    ItemSpawner.Log("Scanned " .. #ItemSpawner.Items .. " items.")
    return ItemSpawner.Items
end

-- Try to give item using safer methods
function ItemSpawner.Give(item)
    ItemSpawner.Log("Attempting to give: " .. item.Name)
    
    -- 1. Search for remotes in all relevant places
    local searchRoots = {ReplicatedStorage, Lighting, Workspace, StarterGui, LocalPlayer.PlayerGui}
    local remotes = {}
    for _, root in ipairs(searchRoots) do
        local found = findRemotes(root)
        for _, r in ipairs(found) do table.insert(remotes, r) end
    end
    
    -- Also look inside the item itself if it's a tool
    if item.Object then
        local itemRemotes = findRemotes(item.Object)
        for _, r in ipairs(itemRemotes) do table.insert(remotes, r) end
    end
    
    ItemSpawner.Log("Found " .. #remotes .. " potential remotes.")

    -- Sort remotes by "safety" keywords
    table.sort(remotes, function(a, b)
        local aName = a.Name:lower()
        local bName = b.Name:lower()
        local aSafe = aName:find("reward") or aName:find("claim") or aName:find("craft") or aName:find("buy")
        local bSafe = bName:find("reward") or bName:find("claim") or bName:find("craft") or bName:find("buy")
        if aSafe and not bSafe then return true end
        return false
    end)
    
    local remoteSuccessCount = 0
    
    -- Limit attempts to avoid crash/kick if too many remotes
    local maxRemotes = 10 
    local count = 0
    
    for _, remote in ipairs(remotes) do
        count = count + 1
        if count > maxRemotes then break end
        
        pcall(function()
            local args = {
                {item.Name},                -- Try name only
                {item.Object},              -- Try object only
                {item.Name, 1},             -- Try name + amount
                {item.Object, 1},           -- Try object + amount
                {"Craft", item.Name},       -- Try action + name
                {"Buy", item.Name},         -- Try action + name
                {item.Name, "Free"},        -- Try name + cost
                {item.Name, true},          -- Try name + bool
                {item.Object, true},        -- Try object + bool
                -- Inventory/Equip specific patterns
                {"Equip", item.Name},
                {"Equip", item.Object},
                {"Add", item.Name},
                {"Add", item.Object},
                -- Table wrap pattern (common in some frameworks)
                {{Name = item.Name, Amount = 1}},
                {{item.Name}},
            }
            
            -- ItemSpawner.Log("Firing " .. remote.Name .. "...")
            
            for _, argSet in ipairs(args) do
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(unpack(argSet))
                    task.wait(0.05) -- Throttle slightly
                elseif remote:IsA("RemoteFunction") then
                    task.spawn(function() remote:InvokeServer(unpack(argSet)) end)
                    task.wait(0.05) -- Throttle slightly
                end
            end
            remoteSuccessCount = remoteSuccessCount + 1
            task.wait(0.1) -- Throttle between remotes
        end)
    end
    
    -- 2. Direct Interaction (Touch / Click / Proximity)
    local physicalSuccess = false
    if item.Object and item.Object.Parent then
        -- TouchInterest
        if item.Object:FindFirstChild("Handle") then
            local handle = item.Object.Handle
            if handle:FindFirstChild("TouchInterest") then
                ItemSpawner.Log("Triggering TouchInterest on " .. item.Name)
                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, handle, 0)
                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, handle, 1)
                physicalSuccess = true
            end
        end
        
        -- ClickDetector
        local cd = item.Object:FindFirstChildWhichIsA("ClickDetector", true)
        if cd then
            ItemSpawner.Log("Triggering ClickDetector on " .. item.Name)
            fireclickdetector(cd)
            physicalSuccess = true
        end
        
        -- ProximityPrompt
        local pp = item.Object:FindFirstChildWhichIsA("ProximityPrompt", true)
        if pp then
            ItemSpawner.Log("Triggering ProximityPrompt on " .. item.Name)
            fireproximityprompt(pp)
            physicalSuccess = true
        end
    end
    
    -- 3. Client-Side Clone (Disabled by default to prevent client crashes/loops)
    -- This was causing the "Argument 2 missing" spam in ObjectHealthDisplayer because the cloned tool wasn't fully initialized by the server
    -- if item.Object:IsA("Tool") then
    --     ItemSpawner.Log("Attempting client-side clone for " .. item.Name)
    --     local clone = item.Object:Clone()
    --     clone.Parent = LocalPlayer.Backpack
    -- end
    
    if remoteSuccessCount > 0 or physicalSuccess then
        ItemSpawner.Log("Give sequence finished for " .. item.Name)
        return true
    else
        ItemSpawner.Log("Give sequence failed (no valid targets) for " .. item.Name)
        return false
    end
end

return ItemSpawner
