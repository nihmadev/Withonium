local ActorBypass = {}

local function log(msg)
    pcall(function()
        local formatted = "[ActorBypass] " .. tostring(msg)
        warn(formatted)
        if rconsoleprint then rconsoleprint(formatted .. "\n") end
    end)
end

function ActorBypass.Init(Settings)
    log("Initializing Legacy Actor Bypass (Extraction Method)...")
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    
    if not PlayerGui then
        log("PlayerGui not found, bypass might fail.")
        return
    end

    local function bypassActor(actor)
        if not actor or not actor:IsA("Actor") then return end
        
        log("Bypassing Actor: " .. actor.Name)
        
        -- Transfer all children from Actor to PlayerGui to "de-isolate" them
        for _, child in ipairs(actor:GetChildren()) do
            pcall(function()
                if child:IsA("LocalScript") or child:IsA("ModuleScript") then
                    -- Reset script state if possible to ensure it runs in new context
                    local wasDisabled = child.Disabled
                    child.Disabled = true
                    child.Parent = PlayerGui
                    task.wait()
                    child.Disabled = wasDisabled
                else
                    child.Parent = PlayerGui
                end
            end)
        end
        
        -- Clean up the now empty actor
        task.wait()
        actor:Destroy()
        log("Actor " .. actor.Name .. " has been successfully bypassed.")
    end

    -- Initial scan of PlayerGui for existing Actors
    for _, child in ipairs(PlayerGui:GetChildren()) do
        if child:IsA("Actor") then
            bypassActor(child)
        end
    end

    -- Monitor for new Actors being added to PlayerGui
    PlayerGui.ChildAdded:Connect(function(child)
        if child:IsA("Actor") then
            task.wait() -- Minimal wait to let children populate
            bypassActor(child)
        end
    end)

    -- Also monitor LocalPlayer just in case
    LocalPlayer.ChildAdded:Connect(function(child)
        if child:IsA("Actor") then
            task.wait()
            bypassActor(child)
        end
    end)

    log("Legacy Actor Bypass active.")
end

return ActorBypass
