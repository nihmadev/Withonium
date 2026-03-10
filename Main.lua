local function log(msg)
    pcall(function()
        warn("[LOG] " .. tostring(msg))
        if rconsoleprint then rconsoleprint("[LOG] " .. tostring(msg) .. "\n") end
    end)
end

log("Initializing core engine...")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

local Main = {
    Connections = {},
    Modules = {}
}

function Main.Init(Modules)
    Main.Modules = Modules
    local Settings = Modules.Settings
    local Utils = Modules.Utils
    local ESP = Modules.ESP
    local Aimbot = Modules.Aimbot
    local GUI = Modules.GUI
    local ConfigManager = Modules.ConfigManager
    local Ballistics = Modules.Ballistics
    local Visuals = Modules.Visuals
    local BulletTracer = Modules.BulletTracer
    local Crosshair = Modules.Crosshair
    local ItemSpawner = Modules.ItemSpawner

    
    task.spawn(function()
        
        if ConfigManager then
            pcall(function()
                ConfigManager.Init()
                ConfigManager.Load("autoload", Settings)
            end)
        end

        
        if Visuals then
            pcall(function() Visuals.Init(Settings) end)
        end

        
        if Crosshair then
            pcall(function() Crosshair.Init() end)
        end

        
        if ItemSpawner then
             pcall(function() ItemSpawner.ScanItems() end)
        end

        
        local success_gui, err_gui = pcall(function()
            GUI.Init(Settings, Utils, function()
                Main.Unload()
            end, ConfigManager, ItemSpawner)
        end)
        if not success_gui then
            log("View error: " .. tostring(err_gui))
        end

        log("Finalizing engine...")
    end)

    
    UserInputService.MouseIconEnabled = Settings.guiVisible



    
    local function handleKeybind(input, isBegan, processed)
        if processed then return end
        local keyCode = input.KeyCode
        local inputType = input.UserInputType
        
        
        if UserInputService:GetFocusedTextBox() then return end
        
        local keybinds = {
            {Key = Settings.silentAimKey, Mode = Settings.silentAimKeyMode, Setting = "silentAimEnabled", Name = "Silent Aim"},
            {Key = Settings.spiderKey, Mode = Settings.spiderKeyMode, Setting = "spiderEnabled", Name = "Spider"},
            {Key = Settings.speedHackKey, Mode = Settings.speedHackKeyMode, Setting = "speedHackEnabled", Name = "Speed"},
            {Key = Settings.freeCamKey, Mode = Settings.freeCamKeyMode, Setting = "freeCamEnabled", Name = "FreeCam"},
            {Key = Settings.jumpShotKey, Mode = Settings.jumpShotKeyMode, Setting = "jumpShotEnabled", Name = "Jump Shot"},
            {Key = Settings.FullBrightKey, Mode = Settings.FullBrightKeyMode, Setting = "fullBrightEnabled", Name = "FullBright"},
            {Key = Settings.antiAimKey, Mode = Settings.antiAimKeyMode, Setting = "antiAimEnabled", Name = "Anti-Aim"}
        }
        
        local updated = false
        for _, bind in ipairs(keybinds) do
            if bind.Key ~= Enum.KeyCode.Unknown and (keyCode == bind.Key or inputType == bind.Key) then
                if bind.Mode == "Toggle" then
                    if isBegan then
                        Settings[bind.Setting] = not Settings[bind.Setting]
                        updated = true
                        log("Toggled " .. bind.Name .. ": " .. tostring(Settings[bind.Setting]))
                    end
                elseif bind.Mode == "Hold" then
                    if Settings[bind.Setting] ~= isBegan then
                        Settings[bind.Setting] = isBegan
                        updated = true
                        log(bind.Name .. " (Hold): " .. tostring(isBegan))
                    end
                elseif bind.Mode == "Always" then
                    if not Settings[bind.Setting] then
                        Settings[bind.Setting] = true
                        updated = true
                        log(bind.Name .. " set to Always Active")
                    end
                end
            end
        end
        
        
        if updated and Settings.guiVisible and GUI then
            if GUI.UpdateToggles then
                GUI.UpdateToggles(Settings)
            end
        end
    end

    
    table.insert(Main.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and (input.KeyCode == Settings.toggleKey or input.UserInputType == Settings.toggleKey) then
            if GUI and GUI.ToggleVisible then
                GUI.ToggleVisible(Settings)
            else
                Settings.guiVisible = not Settings.guiVisible
            end
            
            pcall(function()
                if Settings.guiVisible then
                    UserInputService.MouseIconEnabled = true
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                else
                    UserInputService.MouseIconEnabled = false
                    
                    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                end
            end)
        end
        
        handleKeybind(input, true, processed)
    end))

    table.insert(Main.Connections, UserInputService.InputEnded:Connect(function(input, processed)
        handleKeybind(input, false, processed)
    end))

    
    local lastGuiUpdate = 0
    local lastVisualsUpdate = 0
    local lastErrorTime = 0
    
    RunService:BindToRenderStep("WithoniumUpdate", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
        
        local success_aim, err_aim = pcall(function()
            Aimbot.Update(deltaTime, Settings, Utils, Ballistics, ESP)
        end)
        if not success_aim then 
            if tick() - lastErrorTime > 5 then
                lastErrorTime = tick()
                log("Aimbot update error: " .. tostring(err_aim)) 
            end
        end

        
        
        local success_esp, err_esp = pcall(function()
            ESP.Update(Settings, deltaTime, Utils)
        end)
        if not success_esp then 
            if tick() - lastErrorTime > 5 then
                lastErrorTime = tick()
                log("ESP update error: " .. tostring(err_esp)) 
            end
        end
        
        local now = tick()
        
        
        if now - lastVisualsUpdate > 0.5 then
            lastVisualsUpdate = now
            if Visuals then
                pcall(function() Visuals.Update(Settings) end)
            end
        end

        
        if Crosshair then
            pcall(function() Crosshair.Update(Settings) end)
        end
        
        
        if GUI and GUI.UpdateWatermark then
            pcall(function() GUI.UpdateWatermark(Settings) end)
        end
        
        
        if now - lastGuiUpdate > 0.1 then
            lastGuiUpdate = now
            if GUI then
                pcall(function()
                    if GUI.UpdateKeybindList then
                        GUI.UpdateKeybindList(Settings)
                    end
                end)
            end
        end
    end)

    
    task.spawn(function()
        task.wait(1) 
        log("Activating hooks...")
        pcall(function()
            Aimbot.InitHooks(Settings, Utils, Ballistics, BulletTracer)
        end)
    end)

    
    table.insert(Main.Connections, Players.PlayerRemoving:Connect(function(player)
        ESP.Remove(player)
    end))
end

function Main.Unload()
    local Settings = Main.Modules.Settings
    local ConfigManager = Main.Modules.ConfigManager

    
    if ConfigManager and Settings then
        ConfigManager.Save("autoload", Settings)
    end

    RunService:UnbindFromRenderStep("WithoniumUpdate")
    for _, conn in ipairs(Main.Connections) do
        if conn then conn:Disconnect() end
    end
    
    if Main.Modules.GUI and Main.Modules.GUI.ScreenGui then
        Main.Modules.GUI.ScreenGui:Destroy()
    end

    if Main.Modules.ESP then
        pcall(function()
            if Main.Modules.ESP.Data then
                for player, _ in pairs(Main.Modules.ESP.Data) do
                    pcall(function() Main.Modules.ESP.Remove(player) end)
                end
            end
            if Main.Modules.ESP.Container then
                Main.Modules.ESP.Container:Destroy()
            end
        end)
    end

    if Main.Modules.Aimbot then
        Main.Modules.Aimbot.Remove()
    end

    if Main.Modules.Visuals then
        Main.Modules.Visuals.Unload()
    end

    if Main.Modules.Crosshair then
        Main.Modules.Crosshair.Unload()
    end

    
    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

return Main
