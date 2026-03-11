local ActorBypass = {}

local function log(msg)
    pcall(function()
        local formatted = "[ActorBypass] " .. tostring(msg)
        warn(formatted)
        if rconsoleprint then rconsoleprint(formatted .. "\n") end
    end)
end

function ActorBypass.Init(Settings)
    log("Initializing Actor Bypass for Trident Survival...")
    
    local hasGetActors = getactors ~= nil
    local hasRunOnActor = run_on_actor ~= nil
    
    if not (hasGetActors and hasRunOnActor) then
        log("Executor does not support getactors/run_on_actor. Using basic synchronization.")
        return
    end

    
    
    
    local function injectToActor(actor)
        if not actor or not actor:IsA("Actor") then return end
        
        
        if actor:FindFirstChild("Withonium_Injected") then return end
        local marker = Instance.new("BoolValue")
        marker.Name = "Withonium_Injected"
        marker.Parent = actor

        log("Injecting to actor: " .. actor.Name)
        
        local payload = [[
            local actor = ...
            local function log(msg)
                pcall(function() warn("[Actor:" .. actor.Name .. "] " .. tostring(msg)) end)
            end
            
            log("Payload active.")
            
            
            
            
            
            
            
            
            task.spawn(function()
                while task.wait(5) do
                    
                end
            end)
        ]]
        
        task.spawn(function()
            local success, err = pcall(function()
                run_on_actor(actor, payload)
            end)
            if not success then
                log("Injection failed for " .. actor.Name .. ": " .. tostring(err))
            end
        end)
    end

    
    for _, actor in ipairs(getactors()) do
        injectToActor(actor)
    end

    
    game.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Actor") then
            task.wait(0.5) 
            injectToActor(descendant)
        end
    end)

    log("Actor Bypass successfully initialized.")
end

return ActorBypass
