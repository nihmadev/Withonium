local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer


local function loadWithTimeout(url: string, timeout: number?): ...any
	if type(url) ~= "string" then return false, "URL must be a string" end
	url = url:gsub("^%s*(.-)%s*$", "%1")
	if not url:find("^http") then return false, "Invalid protocol" end

	timeout = timeout or 15
	local requestCompleted = false
	local success, result = false, nil

	local requestThread = task.spawn(function()
		local fetchSuccess, fetchResult
		
		
		local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request
		if requestFunc then
			fetchSuccess, fetchResult = pcall(function()
				local res = requestFunc({
					Url = url,
					Method = "GET"
				})
				if res and res.StatusCode == 200 then
					return res.Body
				end
				error(res and ("HTTP " .. tostring(res.StatusCode)) or "Unknown error!")
			end)
		else
			
			for i = 1, 3 do
				fetchSuccess, fetchResult = pcall(function()
					return game:HttpGet(url)
				end)
				if fetchSuccess and fetchResult and #fetchResult > 0 then break end
				task.wait(1)
			end
		end

		if not fetchSuccess or not fetchResult or #fetchResult == 0 then
			success, result = false, fetchResult or "Empty response"
			requestCompleted = true
			return
		end

		local execSuccess, execResult = pcall(function()
			local f, err = loadstring(fetchResult)
			if f then return f() end
			error(err)
		end)
		success, result = execSuccess, execResult
		requestCompleted = true
	end)

	task.delay(timeout, function()
		if not requestCompleted then
			task.cancel(requestThread)
			success, result = false, "Request timed out"
			requestCompleted = true
		end
	end)

	while not requestCompleted do task.wait() end
	return success, result
end

local function loadLibrary(): any
    	
	local success, result = pcall(function()
		if isfile("WithoniumRTY.lua") then
			local content = readfile("WithoniumRTY.lua")
			local f, err = loadstring(content)
			if f then return f() end
			error(err)
		end
		error("No local file")
	end)

	local success, result = loadWithTimeout("https://raw.githubusercontent.com/nihmadev/Withonium/refs/heads/main/WithoniumRTY.lua")
	if success and result then
		return result
	end
	
	error("Failed to load WithoniumRTY: " .. tostring(result))
end

local WithoniumRTY = loadLibrary()

local function ensureLogo(url: string)
    local fileName = "withonium_logo.png"
    local getAsset = getcustomasset or get_custom_asset or (syn and syn.get_custom_asset)
    
    if not getAsset then 
        warn("[Withonium] getcustomasset not found. Your executor might not support local assets.")
        return nil 
    end

    local success, exists = pcall(function() return isfile(fileName) end)
    if not success or not exists then
        print("[Withonium] Downloading logo...")
        local downloadSuccess = pcall(function()
            local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request
            local body
            if requestFunc then
                local res = requestFunc({
                    Url = url,
                    Method = "GET"
                })
                if res and res.StatusCode == 200 then
                    body = res.Body
                end
            else
                body = game:HttpGet(url)
            end
            
            if body and #body > 0 then
                writefile(fileName, body)
                print("[Withonium] Logo saved to " .. fileName)
                return true
            end
            return false
        end)
        if not downloadSuccess then 
            warn("[Withonium] Failed to download logo.")
            return nil 
        end
    end
    
    local assetId
    local assetSuccess = pcall(function()
        assetId = getAsset(fileName)
    end)
    
    if not assetSuccess or not assetId then
        warn("[Withonium] getcustomasset failed to convert logo.")
        return nil
    end
    
    return assetId
end

local GUI = {
    Window = nil,
    Tabs = {},
    ConfigManager = nil,
    UnloadCallback = nil,
    ConfigName = "shlepa228",
    CurrentTab = "Aimbot",
    
    
    Watermark = {
        Frame = nil,
        Text = nil,
        Avatar = nil
    },
    KeybindList = {
        Frame = nil,
        Container = nil,
        Items = {}
    },
    FrameCount = 0,
    LastWatermarkUpdate = 0,

    
    Elements = {
        Toggles = {}
    },

    
    ScreenGui = nil
}


local function getKeyName(key)
    if not key then return "None" end
    local str = tostring(key)
    str = str:gsub("Enum.KeyCode.", "")
    str = str:gsub("Enum.UserInputType.", "")
    return str
end


local function setKeybind(Key, Settings, SettingName)
    if not Key then return end
    
    
    local success, result = pcall(function() return Enum.KeyCode[Key] end)
    if success and result then
        Settings[SettingName] = result
        return
    end
    
    
    success, result = pcall(function() return Enum.UserInputType[Key] end)
    if success and result then
        Settings[SettingName] = result
    end
end

function GUI.Init(Settings, Utils, UnloadCallback, ConfigManager, ItemSpawner)
    GUI.ConfigManager = ConfigManager
    GUI.UnloadCallback = UnloadCallback
    
    
    local gui_parent = nil
    pcall(function()
        if gethui then gui_parent = gethui()
        elseif game:GetService("CoreGui") then gui_parent = game:GetService("CoreGui")
        else gui_parent = LocalPlayer:WaitForChild("PlayerGui") end
    end)

    if gui_parent then
        GUI.ScreenGui = Instance.new("ScreenGui")
        GUI.ScreenGui.Name = "WithoniumExternal"
        GUI.ScreenGui.ResetOnSpawn = false
        GUI.ScreenGui.DisplayOrder = 100
        GUI.ScreenGui.Parent = gui_parent
        GUI.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global 

        
        GUI.Watermark.Frame = Instance.new("Frame")
        GUI.Watermark.Frame.Name = "Watermark"
        GUI.Watermark.Frame.Parent = GUI.ScreenGui
        GUI.Watermark.Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        GUI.Watermark.Frame.Position = UDim2.new(0, 10, 0, 10)
        GUI.Watermark.Frame.Size = UDim2.new(0, 0, 0, 26)
        GUI.Watermark.Frame.AutomaticSize = Enum.AutomaticSize.X
        GUI.Watermark.Frame.Visible = Settings.watermarkEnabled
        
        local WMCorner = Instance.new("UICorner")
        WMCorner.CornerRadius = UDim.new(0, 6)
        WMCorner.Parent = GUI.Watermark.Frame
        
        local WMPadding = Instance.new("UIPadding")
        WMPadding.PaddingLeft = UDim.new(0, 6)
        WMPadding.PaddingRight = UDim.new(0, 8)
        WMPadding.Parent = GUI.Watermark.Frame

        local WMList = Instance.new("UIListLayout")
        WMList.FillDirection = Enum.FillDirection.Horizontal
        WMList.VerticalAlignment = Enum.VerticalAlignment.Center
        WMList.Padding = UDim.new(0, 8)
        WMList.Parent = GUI.Watermark.Frame

        GUI.Watermark.Avatar = Instance.new("ImageLabel")
        GUI.Watermark.Avatar.Name = "Avatar"
        GUI.Watermark.Avatar.BackgroundTransparency = 1
        GUI.Watermark.Avatar.Size = UDim2.new(0, 18, 0, 18)
        GUI.Watermark.Avatar.Parent = GUI.Watermark.Frame
        GUI.Watermark.Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
        
        local AvatarCorner = Instance.new("UICorner")
        AvatarCorner.CornerRadius = UDim.new(1, 0)
        AvatarCorner.Parent = GUI.Watermark.Avatar

        GUI.Watermark.Text = Instance.new("TextLabel")
        GUI.Watermark.Text.Name = "Text"
        GUI.Watermark.Text.BackgroundTransparency = 1
        GUI.Watermark.Text.Font = Enum.Font.GothamMedium
        GUI.Watermark.Text.TextColor3 = Color3.new(1, 1, 1)
        GUI.Watermark.Text.TextSize = 13
        GUI.Watermark.Text.Size = UDim2.new(0, 0, 1, 0)
        GUI.Watermark.Text.AutomaticSize = Enum.AutomaticSize.X
        GUI.Watermark.Text.Text = "Withonium | Initializing..."
        GUI.Watermark.Text.Parent = GUI.Watermark.Frame

        
        GUI.KeybindList.Frame = Instance.new("Frame")
        GUI.KeybindList.Frame.Name = "KeybindList"
        GUI.KeybindList.Frame.Parent = GUI.ScreenGui
        GUI.KeybindList.Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        GUI.KeybindList.Frame.Position = UDim2.new(0, 10, 0, 42)
        GUI.KeybindList.Frame.Size = UDim2.new(0, 220, 0, 0)
        GUI.KeybindList.Frame.AutomaticSize = Enum.AutomaticSize.Y
        GUI.KeybindList.Frame.Visible = Settings.watermarkEnabled
        
        local KBCorner = Instance.new("UICorner")
        KBCorner.CornerRadius = UDim.new(0, 6)
        KBCorner.Parent = GUI.KeybindList.Frame
        
        local KBStroke = Instance.new("UIStroke")
        KBStroke.Color = Color3.fromRGB(45, 45, 45)
        KBStroke.Thickness = 1
        KBStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        KBStroke.Parent = GUI.KeybindList.Frame
        
        local KBList = Instance.new("UIListLayout")
        KBList.Padding = UDim.new(0, 4)
        KBList.Parent = GUI.KeybindList.Frame

        local KBPadding = Instance.new("UIPadding")
        KBPadding.PaddingLeft = UDim.new(0, 8)
        KBPadding.PaddingRight = UDim.new(0, 8)
        KBPadding.PaddingTop = UDim.new(0, 6)
        KBPadding.PaddingBottom = UDim.new(0, 6)
        KBPadding.Parent = GUI.KeybindList.Frame

        local KBHeader = Instance.new("TextLabel")
        KBHeader.Name = "Header"
        KBHeader.BackgroundTransparency = 1
        KBHeader.Size = UDim2.new(1, 0, 0, 24)
        KBHeader.Font = Enum.Font.GothamBold
        KBHeader.Text = "Keybinds"
        KBHeader.TextColor3 = Color3.new(1, 1, 1)
        KBHeader.TextSize = 14
        KBHeader.Parent = GUI.KeybindList.Frame

        GUI.KeybindList.Container = Instance.new("Frame")
        GUI.KeybindList.Container.Name = "Items"
        GUI.KeybindList.Container.BackgroundTransparency = 1
        GUI.KeybindList.Container.Size = UDim2.new(1, 0, 0, 0)
        GUI.KeybindList.Container.AutomaticSize = Enum.AutomaticSize.Y
        GUI.KeybindList.Container.Parent = GUI.KeybindList.Frame
        
        local ItemsLayout = Instance.new("UIListLayout")
        ItemsLayout.Padding = UDim.new(0, 2)
        ItemsLayout.Parent = GUI.KeybindList.Container
    end
    
    GUI.Window = WithoniumRTY:CreateWindow({
        Name = "Withonium",
        LoadingTitle = "Withonium",
        LoadingSubtitle = "by nihmadev",
        Icon = "https://github.com/nihmadev/Withonium/raw/main/icon.png",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "Withonium",
            FileName = GUI.ConfigName
        },
        Discord = {
            Enabled = false,
            Invite = "noinvitelink",
            RememberJoins = true
        },
        KeySystem = false
    })

    
    local AimbotTab = GUI.Window:CreateTab("Aimbot", 9134785384)
    local AimbotMain, AimbotSide = AimbotTab:Split(0.5)
    
    AimbotMain:CreateSection("Silent Aim")
    GUI.Elements.Toggles["aimbotEnabled"] = AimbotMain:CreateToggle({
        Name = "Aimbot Enabled",
        CurrentValue = Settings.aimbotEnabled,
        Flag = "aimbotEnabled",
        Callback = function(Value) Settings.aimbotEnabled = Value end
    })
    GUI.Elements.Toggles["multiPointEnabled"] = AimbotMain:CreateToggle({
        Name = "MultiPoint",
        CurrentValue = Settings.multiPointEnabled,
        Flag = "multiPointEnabled",
        Callback = function(Value) Settings.multiPointEnabled = Value end
    })
    GUI.Elements.Toggles["teamCheckEnabled"] = AimbotMain:CreateToggle({
        Name = "Team Check",
        CurrentValue = Settings.teamCheckEnabled,
        Flag = "teamCheckEnabled",
        Callback = function(Value) Settings.teamCheckEnabled = Value end
    })
    GUI.Elements.Toggles["silentAimEnabled"] = AimbotMain:CreateToggle({
        Name = "Silent Aim",
        CurrentValue = Settings.silentAimEnabled,
        Flag = "silentAimEnabled",
        Callback = function(Value) Settings.silentAimEnabled = Value end
    })
    AimbotMain:CreateKeybind({
        Name = "Silent Aim Key",
        CurrentKeybind = getKeyName(Settings.silentAimKey),
        HoldToInteract = (Settings.silentAimKeyMode == "Hold"),
        CallOnChange = true,
        Flag = "silentAimKey",
        Callback = function(Key) setKeybind(Key, Settings, "silentAimKey") end
    })
    AimbotMain:CreateDropdown({
        Name = "Silent Aim Mode",
        Options = {"Hold", "Toggle", "Always"},
        CurrentOption = {Settings.silentAimKeyMode},
        Flag = "silentAimKeyMode",
        Callback = function(Option) Settings.silentAimKeyMode = Option[1] end
    })

    AimbotMain:CreateSection("Magic Bullets")
    GUI.Elements.Toggles["magicBulletEnabled"] = AimbotMain:CreateToggle({
        Name = "Magic Bullet",
        CurrentValue = Settings.magicBulletEnabled,
        Flag = "magicBulletEnabled",
        Callback = function(Value) Settings.magicBulletEnabled = Value end
    })
    GUI.Elements.Toggles["magicBulletHouseCheck"] = AimbotMain:CreateToggle({
        Name = "Ignore Objects",
        CurrentValue = not Settings.magicBulletHouseCheck,
        Flag = "magicBulletHouseCheck",
        Callback = function(Value) Settings.magicBulletHouseCheck = not Value end
    })
    GUI.Elements.Toggles["visibleCheckEnabled"] = AimbotMain:CreateToggle({
        Name = "Visible Check",
        CurrentValue = Settings.visibleCheckEnabled,
        Flag = "visibleCheckEnabled",
        Callback = function(Value) Settings.visibleCheckEnabled = Value end
    })

    AimbotMain:CreateSection("Combat")
    GUI.Elements.Toggles["fastShootEnabled"] = AimbotMain:CreateToggle({
        Name = "Fast Shoot",
        CurrentValue = Settings.fastShootEnabled,
        Flag = "fastShootEnabled",
        Callback = function(Value) Settings.fastShootEnabled = Value end
    })
    AimbotMain:CreateSlider({
        Name = "Fast Shoot Multiplier",
        Range = {1, 5},
        Increment = 0.5,
        CurrentValue = Settings.fastShootMultiplier or 2.5,
        Flag = "fastShootMultiplier",
        Callback = function(Value) Settings.fastShootMultiplier = Value end
    })
    GUI.Elements.Toggles["noRecoilEnabled"] = AimbotMain:CreateToggle({
        Name = "No Recoil",
        CurrentValue = Settings.noRecoilEnabled,
        Flag = "noRecoilEnabled",
        Callback = function(Value) Settings.noRecoilEnabled = Value end
    })
    GUI.Elements.Toggles["jumpShotEnabled"] = AimbotMain:CreateToggle({
        Name = "Jump Shot",
        CurrentValue = Settings.jumpShotEnabled,
        Flag = "jumpShotEnabled",
        Callback = function(Value) Settings.jumpShotEnabled = Value end
    })
    AimbotMain:CreateKeybind({
        Name = "Jump Shot Key",
        CurrentKeybind = getKeyName(Settings.jumpShotKey),
        HoldToInteract = false,
        CallOnChange = true,
        Flag = "jumpShotKey",
        Callback = function(Key) setKeybind(Key, Settings, "jumpShotKey") end
    })

    AimbotSide:CreateSection("Zoom")
    GUI.Elements.Toggles["zoomEnabled"] = AimbotSide:CreateToggle({
        Name = "Zoom Enabled",
        CurrentValue = Settings.zoomEnabled,
        Flag = "zoomEnabled",
        Callback = function(Value) Settings.zoomEnabled = Value end
    })
    AimbotSide:CreateSlider({
        Name = "Zoom Amount",
        Range = {5, 60},
        Increment = 1,
        CurrentValue = Settings.zoomAmount,
        Flag = "zoomAmount",
        Callback = function(Value) Settings.zoomAmount = Value end
    })

    AimbotSide:CreateSection("Anti-Aim")
    GUI.Elements.Toggles["antiAimEnabled"] = AimbotSide:CreateToggle({
        Name = "Anti-Aim Enabled",
        CurrentValue = Settings.antiAimEnabled,
        Flag = "antiAimEnabled",
        Callback = function(Value) Settings.antiAimEnabled = Value end
    })
    AimbotSide:CreateKeybind({
        Name = "Anti-Aim Key",
        CurrentKeybind = getKeyName(Settings.antiAimKey),
        HoldToInteract = false,
        CallOnChange = true,
        Flag = "antiAimKey",
        Callback = function(Key) setKeybind(Key, Settings, "antiAimKey") end
    })
    AimbotSide:CreateDropdown({
        Name = "Anti-Aim Mode",
        Options = {"Spin", "Jitter", "Static"},
        CurrentOption = {Settings.antiAimMode},
        Flag = "antiAimMode",
        Callback = function(Option) Settings.antiAimMode = Option[1] end
    })
    AimbotSide:CreateSlider({
        Name = "Spin Speed",
        Range = {1, 100},
        Increment = 1,
        CurrentValue = Settings.antiAimSpeed,
        Flag = "antiAimSpeed",
        Callback = function(Value) Settings.antiAimSpeed = Value end
    })

    AimbotSide:CreateSection("Prediction")
    GUI.Elements.Toggles["ballisticsEnabled"] = AimbotSide:CreateToggle({
        Name = "Ballistics",
        CurrentValue = Settings.ballisticsEnabled,
        Flag = "ballisticsEnabled",
        Callback = function(Value) Settings.ballisticsEnabled = Value end
    })
    GUI.Elements.Toggles["projectilePredictionEnabled"] = AimbotSide:CreateToggle({
        Name = "Prediction",
        CurrentValue = Settings.projectilePredictionEnabled,
        Flag = "projectilePredictionEnabled",
        Callback = function(Value) Settings.projectilePredictionEnabled = Value end
    })
    AimbotSide:CreateSlider({
        Name = "Prediction Factor",
        Range = {0.1, 2.0},
        Increment = 0.1,
        CurrentValue = Settings.predictionFactor,
        Flag = "predictionFactor",
        Callback = function(Value) Settings.predictionFactor = Value end
    })
    AimbotSide:CreateSlider({
        Name = "Prediction Smooth",
        Range = {0.05, 1.0},
        Increment = 0.05,
        CurrentValue = Settings.predictionSmoothing,
        Flag = "predictionSmoothing",
        Callback = function(Value) Settings.predictionSmoothing = Value end
    })

    AimbotSide:CreateSection("Settings")
    GUI.Elements.Toggles["fovCircleEnabled"] = AimbotSide:CreateToggle({
        Name = "FOV Circle",
        CurrentValue = Settings.fovCircleEnabled,
        Flag = "fovCircleEnabled",
        Callback = function(Value) Settings.fovCircleEnabled = Value end
    })
    GUI.Elements.Toggles["targetLineEnabled"] = AimbotSide:CreateToggle({
        Name = "Target Line",
        CurrentValue = Settings.targetLineEnabled,
        Flag = "targetLineEnabled",
        Callback = function(Value) Settings.targetLineEnabled = Value end
    })
    AimbotSide:CreateColorPicker({
        Name = "Target Line Color",
        Color = Settings.targetLineColor,
        Flag = "targetLineColor",
        Callback = function(Value) Settings.targetLineColor = Value end
    })
    AimbotSide:CreateKeybind({
        Name = "Aim Key",
        CurrentKeybind = getKeyName(Settings.aimKey),
        HoldToInteract = (Settings.aimKeyMode == "Hold"),
        CallOnChange = true,
        Flag = "aimKey",
        Callback = function(Key) setKeybind(Key, Settings, "aimKey") end
    })
    AimbotSide:CreateDropdown({
        Name = "Aim Mode",
        Options = {"Hold", "Toggle", "Always"},
        CurrentOption = {Settings.aimKeyMode},
        Flag = "aimKeyMode",
        Callback = function(Option) Settings.aimKeyMode = Option[1] end
    })
    AimbotSide:CreateSlider({
        Name = "Smoothness",
        Range = {0.01, 1.0},
        Increment = 0.01,
        CurrentValue = Settings.smoothness,
        Flag = "smoothness",
        Callback = function(Value) Settings.smoothness = Value end
    })
    AimbotSide:CreateSlider({
        Name = "FOV Size",
        Range = {10, 800},
        Increment = 1,
        CurrentValue = Settings.fovSize,
        Flag = "fovSize",
        Callback = function(Value) Settings.fovSize = Value end
    })
    AimbotSide:CreateDropdown({
        Name = "Target Priority",
        Options = {"Distance", "Crosshair", "Balanced"},
        CurrentOption = {Settings.targetPriority},
        Flag = "targetPriority",
        Callback = function(Option) Settings.targetPriority = Option[1] end
    })
    AimbotSide:CreateDropdown({
        Name = "Target Part",
        Options = {"Head", "Torso", "Legs"},
        CurrentOption = {Settings.targetPart},
        Flag = "targetPart",
        Callback = function(Option) Settings.targetPart = Option[1] end
    })

    
    local VisualsTab = GUI.Window:CreateTab("Visuals", 9134780101)
    local VisualsMain, VisualsSide = VisualsTab:Split(0.5)
    
    VisualsMain:CreateSection("ESP")
    GUI.Elements.Toggles["espEnabled"] = VisualsMain:CreateToggle({
        Name = "ESP Enabled",
        CurrentValue = Settings.espEnabled,
        Flag = "espEnabled",
        Callback = function(Value) Settings.espEnabled = Value end
    })
    GUI.Elements.Toggles["espDrawTeammates"] = VisualsMain:CreateToggle({
        Name = "Draw Teammates",
        CurrentValue = Settings.espDrawTeammates,
        Flag = "espDrawTeammates",
        Callback = function(Value) Settings.espDrawTeammates = Value end
    })
    VisualsMain:CreateSlider({
        Name = "Max Distance",
        Range = {0, 2000},
        Increment = 10,
        CurrentValue = Settings.espMaxDistance,
        Flag = "espMaxDistance",
        Callback = function(Value) Settings.espMaxDistance = Value end
    })

    VisualsMain:CreateSection("Chams")
    GUI.Elements.Toggles["espHighlights"] = VisualsMain:CreateToggle({
        Name = "Chams",
        CurrentValue = Settings.espHighlights,
        Flag = "espHighlights",
        Callback = function(Value) Settings.espHighlights = Value end
    })
    VisualsMain:CreateDropdown({
        Name = "Chams Mode",
        Options = {"Default", "Glow", "Metal"},
        CurrentOption = {Settings.espChamsMode},
        Flag = "espChamsMode",
        Callback = function(Option) Settings.espChamsMode = Option[1] end
    })
    VisualsMain:CreateColorPicker({
        Name = "Fill Color",
        Color = Settings.espColor,
        Flag = "espColor",
        Callback = function(Value) Settings.espColor = Value end
    })
    VisualsMain:CreateColorPicker({
        Name = "Outline Color",
        Color = Settings.espOutlineColor,
        Flag = "espOutlineColor",
        Callback = function(Value) Settings.espOutlineColor = Value end
    })

    VisualsMain:CreateSection("Overlay")
    GUI.Elements.Toggles["espSkeleton"] = VisualsMain:CreateToggle({
        Name = "Skeleton",
        CurrentValue = Settings.espSkeleton,
        Flag = "espSkeleton",
        Callback = function(Value) Settings.espSkeleton = Value end
    })
    VisualsMain:CreateColorPicker({
        Name = "Skeleton Color",
        Color = Settings.espSkeletonColor,
        Flag = "espSkeletonColor",
        Callback = function(Value) Settings.espSkeletonColor = Value end
    })

    VisualsSide:CreateSection("Crosshair")
    GUI.Elements.Toggles["crosshairEnabled"] = VisualsSide:CreateToggle({
        Name = "Crosshair Enabled",
        CurrentValue = Settings.crosshairEnabled,
        Flag = "crosshairEnabled",
        Callback = function(Value) 
            Settings.crosshairEnabled = Value 
            if ConfigManager then ConfigManager.Save("autoload", Settings) end
        end
    })
    VisualsSide:CreateDropdown({
        Name = "Crosshair Type",
        Options = {"Default", "Swastika", "X"},
        CurrentOption = {Settings.crosshairType},
        Flag = "crosshairType",
        Callback = function(Option) 
            Settings.crosshairType = Option[1] 
            if ConfigManager then ConfigManager.Save("autoload", Settings) end
        end
    })
    VisualsSide:CreateColorPicker({
        Name = "Crosshair Color",
        Color = Settings.crosshairColor,
        Flag = "crosshairColor",
        Callback = function(Value) 
            Settings.crosshairColor = Value 
            if ConfigManager then ConfigManager.Save("autoload", Settings) end
        end
    })
    VisualsSide:CreateSlider({
        Name = "Crosshair Size",
        Range = {1, 100},
        Increment = 1,
        CurrentValue = Settings.crosshairSize,
        Flag = "crosshairSize",
        Callback = function(Value) 
            Settings.crosshairSize = Value 
            if ConfigManager then ConfigManager.Save("autoload", Settings) end
        end
    })
    VisualsSide:CreateSlider({
        Name = "Crosshair Thickness",
        Range = {1, 10},
        Increment = 1,
        CurrentValue = Settings.crosshairThickness,
        Flag = "crosshairThickness",
        Callback = function(Value) 
            Settings.crosshairThickness = Value 
            if ConfigManager then ConfigManager.Save("autoload", Settings) end
        end
    })
    GUI.Elements.Toggles["espNames"] = VisualsSide:CreateToggle({
        Name = "Show Names",
        CurrentValue = Settings.espNames,
        Flag = "espNames",
        Callback = function(Value) Settings.espNames = Value end
    })
    GUI.Elements.Toggles["espDistances"] = VisualsSide:CreateToggle({
        Name = "Show Distance",
        CurrentValue = Settings.espDistances,
        Flag = "espDistances",
        Callback = function(Value) Settings.espDistances = Value end
    })
    GUI.Elements.Toggles["espWeapons"] = VisualsSide:CreateToggle({
        Name = "Show Weapon",
        CurrentValue = Settings.espWeapons,
        Flag = "espWeapons",
        Callback = function(Value) Settings.espWeapons = Value end
    })
    GUI.Elements.Toggles["espIcons"] = VisualsSide:CreateToggle({
        Name = "Show Icons",
        CurrentValue = Settings.espIcons,
        Flag = "espIcons",
        Callback = function(Value) Settings.espIcons = Value end
    })
    GUI.Elements.Toggles["espEnemySlots"] = VisualsSide:CreateToggle({
        Name = "Enemy Slots",
        CurrentValue = Settings.espEnemySlots,
        Flag = "espEnemySlots",
        Callback = function(Value) Settings.espEnemySlots = Value end
    })
    GUI.Elements.Toggles["espHealthBar"] = VisualsSide:CreateToggle({
        Name = "Healthbar",
        CurrentValue = Settings.espHealthBar,
        Flag = "espHealthBar",
        Callback = function(Value) Settings.espHealthBar = Value end
    })

    VisualsSide:CreateSection("Bullet Tracer")
    GUI.Elements.Toggles["bulletTracerEnabled"] = VisualsSide:CreateToggle({
        Name = "Enabled",
        CurrentValue = Settings.bulletTracerEnabled,
        Flag = "bulletTracerEnabled",
        Callback = function(Value) Settings.bulletTracerEnabled = Value end
    })
    VisualsSide:CreateColorPicker({
        Name = "Tracer Color",
        Color = Settings.bulletTracerColor,
        Flag = "bulletTracerColor",
        Callback = function(Value) Settings.bulletTracerColor = Value end
    })
    VisualsSide:CreateSlider({
        Name = "Duration",
        Range = {0.1, 10},
        Increment = 0.1,
        CurrentValue = Settings.bulletTracerDuration,
        Flag = "bulletTracerDuration",
        Callback = function(Value) Settings.bulletTracerDuration = Value end
    })
    GUI.Elements.Toggles["bulletTracerPhysics"] = VisualsSide:CreateToggle({
        Name = "Use Physics",
        CurrentValue = Settings.bulletTracerPhysics,
        Flag = "bulletTracerPhysics",
        Callback = function(Value) Settings.bulletTracerPhysics = Value end
    })
    GUI.Elements.Toggles["espHealthBarText"] = VisualsSide:CreateToggle({
        Name = "Healthbar Text",
        CurrentValue = Settings.espHealthBarText,
        Flag = "espHealthBarText",
        Callback = function(Value) Settings.espHealthBarText = Value end
    })
    VisualsSide:CreateDropdown({
        Name = "Healthbar Pos",
        Options = {"Left", "Right", "Bottom", "Top"},
        CurrentOption = {Settings.espHealthBarPosition},
        Flag = "espHealthBarPosition",
        Callback = function(Option) Settings.espHealthBarPosition = Option[1] end
    })
    VisualsSide:CreateColorPicker({
        Name = "Text Color",
        Color = Settings.espTextColor,
        Flag = "espTextColor",
        Callback = function(Value) Settings.espTextColor = Value end
    })

    VisualsSide:CreateSection("World")
    GUI.Elements.Toggles["fullBrightEnabled"] = VisualsSide:CreateToggle({
        Name = "FullBright",
        CurrentValue = Settings.fullBrightEnabled,
        Flag = "fullBrightEnabled",
        Callback = function(Value) Settings.fullBrightEnabled = Value end
    })
    VisualsSide:CreateKeybind({
        Name = "FullBright Key",
        CurrentKeybind = getKeyName(Settings.FullBrightKey),
        HoldToInteract = false,
        CallOnChange = true,
        Flag = "FullBrightKey",
        Callback = function(Key) setKeybind(Key, Settings, "FullBrightKey") end
    })

    
    local PlayerTab = GUI.Window:CreateTab("Player", 10747373176)
    local PlayerMain, PlayerSide = PlayerTab:Split(0.5)
    
    PlayerMain:CreateSection("Helpers")
    GUI.Elements.Toggles["godModeEnabled"] = PlayerMain:CreateToggle({
        Name = "God Mode",
        CurrentValue = Settings.godModeEnabled,
        Flag = "godModeEnabled",
        Callback = function(Value) Settings.godModeEnabled = Value end
    })
    GUI.Elements.Toggles["spiderEnabled"] = PlayerMain:CreateToggle({
        Name = "Spider",
        CurrentValue = Settings.spiderEnabled,
        Flag = "spiderEnabled",
        Callback = function(Value) Settings.spiderEnabled = Value end
    })
    PlayerMain:CreateKeybind({
        Name = "Spider Key",
        CurrentKeybind = getKeyName(Settings.spiderKey),
        HoldToInteract = false,
        CallOnChange = true,
        Flag = "spiderKey",
        Callback = function(Key) setKeybind(Key, Settings, "spiderKey") end
    })
    
    GUI.Elements.Toggles["speedHackEnabled"] = PlayerMain:CreateToggle({
        Name = "SpeedHack",
        CurrentValue = Settings.speedHackEnabled,
        Flag = "speedHackEnabled",
        Callback = function(Value) Settings.speedHackEnabled = Value end
    })
    PlayerMain:CreateKeybind({
        Name = "Speed Key",
        CurrentKeybind = getKeyName(Settings.speedHackKey),
        HoldToInteract = false,
        CallOnChange = true,
        Flag = "speedHackKey",
        Callback = function(Key) setKeybind(Key, Settings, "speedHackKey") end
    })
    PlayerMain:CreateSlider({
        Name = "Speed Multiplier",
        Range = {1, 3},
        Increment = 0.1,
        CurrentValue = Settings.speedMultiplier,
        Flag = "speedMultiplier",
        Callback = function(Value) Settings.speedMultiplier = Value end
    })

    GUI.Elements.Toggles["waterSpeedHackEnabled"] = PlayerMain:CreateToggle({
        Name = "Water Speed",
        CurrentValue = Settings.waterSpeedHackEnabled,
        Flag = "waterSpeedHackEnabled",
        Callback = function(Value) Settings.waterSpeedHackEnabled = Value end
    })
    PlayerMain:CreateSlider({
        Name = "Water Speed Multi",
        Range = {1, 10},
        Increment = 0.5,
        CurrentValue = Settings.waterSpeedMultiplier,
        Flag = "waterSpeedMultiplier",
        Callback = function(Value) Settings.waterSpeedMultiplier = Value end
    })

    PlayerMain:CreateSection("Visuals")
    GUI.Elements.Toggles["noGrassEnabled"] = PlayerMain:CreateToggle({
        Name = "No Grass",
        CurrentValue = Settings.noGrassEnabled,
        Flag = "noGrassEnabled",
        Callback = function(Value) Settings.noGrassEnabled = Value end
    })
    GUI.Elements.Toggles["noFogEnabled"] = PlayerMain:CreateToggle({
        Name = "No Fog",
        CurrentValue = Settings.noFogEnabled,
        Flag = "noFogEnabled",
        Callback = function(Value) Settings.noFogEnabled = Value end
    })
    GUI.Elements.Toggles["thirdPersonEnabled"] = PlayerMain:CreateToggle({
        Name = "Third Person",
        CurrentValue = Settings.thirdPersonEnabled,
        Flag = "thirdPersonEnabled",
        Callback = function(Value) Settings.thirdPersonEnabled = Value end
    })
    PlayerMain:CreateSlider({
        Name = "TP Distance",
        Range = {5, 25},
        Increment = 1,
        CurrentValue = Settings.thirdPersonDistance,
        Flag = "thirdPersonDistance",
        Callback = function(Value) Settings.thirdPersonDistance = Value end
    })
    GUI.Elements.Toggles["freeCamEnabled"] = PlayerMain:CreateToggle({
        Name = "FreeCam",
        CurrentValue = Settings.freeCamEnabled,
        Flag = "freeCamEnabled",
        Callback = function(Value) Settings.freeCamEnabled = Value end
    })
    PlayerMain:CreateKeybind({
        Name = "FreeCam Key",
        CurrentKeybind = getKeyName(Settings.freeCamKey),
        HoldToInteract = false,
        CallOnChange = true,
        Flag = "freeCamKey",
        Callback = function(Key) setKeybind(Key, Settings, "freeCamKey") end
    })

    PlayerSide:CreateSection("Hitbox")
    GUI.Elements.Toggles["hitboxExpanderEnabled"] = PlayerSide:CreateToggle({
        Name = "Hitbox Expander",
        CurrentValue = Settings.hitboxExpanderEnabled,
        Flag = "hitboxExpanderEnabled",
        Callback = function(Value) Settings.hitboxExpanderEnabled = Value end
    })
    GUI.Elements.Toggles["hitboxExpanderShow"] = PlayerSide:CreateToggle({
        Name = "Hitbox Visible",
        CurrentValue = Settings.hitboxExpanderShow,
        Flag = "hitboxExpanderShow",
        Callback = function(Value) Settings.hitboxExpanderShow = Value end
    })
    PlayerSide:CreateSlider({
        Name = "Expander Size",
        Range = {1, 30},
        Increment = 1,
        CurrentValue = Settings.hitboxExpanderSize,
        Flag = "hitboxExpanderSize",
        Callback = function(Value) Settings.hitboxExpanderSize = Value end
    })

    PlayerSide:CreateSection("Anti-AFK")
    GUI.Elements.Toggles["antiAfkEnabled"] = PlayerSide:CreateToggle({
        Name = "Anti-AFK Enabled",
        CurrentValue = Settings.antiAfkEnabled,
        Flag = "antiAfkEnabled",
        Callback = function(Value) 
            Settings.antiAfkEnabled = Value 
            if Value then
                Settings.antiAfkLastActionTime = tick()
            end
        end
    })
    PlayerSide:CreateSlider({
        Name = "Interval (Min)",
        Range = {1, 60},
        Increment = 1,
        CurrentValue = Settings.antiAfkInterval,
        Flag = "antiAfkInterval",
        Callback = function(Value) Settings.antiAfkInterval = Value end
    })
    
    if ItemSpawner then
        PlayerSide:CreateSection("Item Spawner")
        
        local spawnerWindow = nil
        
        local function createSpawnerWindow()
            if spawnerWindow then return spawnerWindow end
            
            local frame = Instance.new("Frame")
            frame.Name = "ItemSpawnerWindow"
            frame.Size = UDim2.new(0, 500, 0, 400)
            frame.Position = UDim2.new(0.5, -250, 0.5, -200)
            frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            frame.BorderSizePixel = 0
            frame.Visible = false
            frame.Parent = GUI.ScreenGui
            
            local fCorner = Instance.new("UICorner")
            fCorner.CornerRadius = UDim.new(0, 10)
            fCorner.Parent = frame
            
            local fStroke = Instance.new("UIStroke")
            fStroke.Color = Color3.fromRGB(50, 50, 50)
            fStroke.Thickness = 1
            fStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            fStroke.Parent = frame
            
            
            local dragging, dragInput, dragStart, startPos
            local function update(input)
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragStart = input.Position
                    startPos = frame.Position
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then dragging = false end
                    end)
                end
            end)
            frame.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    if dragging then update(input) end
                end
            end)
            
            
            local header = Instance.new("TextLabel")
            header.Size = UDim2.new(1, -40, 0, 40)
            header.Position = UDim2.new(0, 15, 0, 0)
            header.BackgroundTransparency = 1
            header.Text = "Item Spawner"
            header.TextColor3 = Color3.new(1, 1, 1)
            header.Font = Enum.Font.GothamBold
            header.TextSize = 16
            header.TextXAlignment = Enum.TextXAlignment.Left
            header.Parent = frame
            
            local closeBtn = Instance.new("TextButton")
            closeBtn.Size = UDim2.new(0, 30, 0, 30)
            closeBtn.Position = UDim2.new(1, -35, 0, 5)
            closeBtn.BackgroundTransparency = 1
            closeBtn.Text = "✕"
            closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            closeBtn.Font = Enum.Font.GothamBold
            closeBtn.TextSize = 16
            closeBtn.Parent = frame
            closeBtn.MouseButton1Click:Connect(function()
                frame.Visible = false
            end)
            
            
            local searchContainer = Instance.new("Frame")
            searchContainer.Size = UDim2.new(1, -30, 0, 36)
            searchContainer.Position = UDim2.new(0, 15, 0, 45)
            searchContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            searchContainer.BorderSizePixel = 0
            searchContainer.Parent = frame
            
            local searchCorner = Instance.new("UICorner")
            searchCorner.CornerRadius = UDim.new(0, 6)
            searchCorner.Parent = searchContainer
            
            local searchIcon = Instance.new("ImageLabel")
            searchIcon.Size = UDim2.new(0, 16, 0, 16)
            searchIcon.Position = UDim2.new(0, 10, 0.5, -8)
            searchIcon.BackgroundTransparency = 1
            searchIcon.Image = "rbxassetid://3926305904"
            searchIcon.ImageRectOffset = Vector2.new(964, 320)
            searchIcon.ImageRectSize = Vector2.new(36, 36)
            searchIcon.ImageColor3 = Color3.fromRGB(150, 150, 150)
            searchIcon.Parent = searchContainer
            
            local search = Instance.new("TextBox")
            search.Size = UDim2.new(1, -40, 1, 0)
            search.Position = UDim2.new(0, 35, 0, 0)
            search.BackgroundTransparency = 1
            search.TextColor3 = Color3.new(1, 1, 1)
            search.PlaceholderText = "Search items..."
            search.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
            search.Font = Enum.Font.Gotham
            search.TextSize = 14
            search.TextXAlignment = Enum.TextXAlignment.Left
            search.Parent = searchContainer
            
            local scroll = Instance.new("ScrollingFrame")
            scroll.Size = UDim2.new(1, -30, 1, -100)
            scroll.Position = UDim2.new(0, 15, 0, 90)
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel = 0
            scroll.ScrollBarThickness = 2
            scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
            scroll.Parent = frame
            
            local grid = Instance.new("UIGridLayout")
            grid.CellSize = UDim2.new(0, 85, 0, 85)
            grid.CellPadding = UDim2.new(0, 8, 0, 8)
            grid.Parent = scroll
            
            local function populate(filter)
                
                for _, v in ipairs(scroll:GetChildren()) do
                    if v:IsA("Frame") or v:IsA("ImageButton") then v:Destroy() end
                end
                
                local items = ItemSpawner.Items
                for _, item in ipairs(items) do
                    if not filter or item.Name:lower():find(filter:lower()) then
                        local btn = Instance.new("ImageButton")
                        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        btn.BorderSizePixel = 0
                        btn.Image = item.Icon
                        btn.Parent = scroll
                        
                        local btnCorner = Instance.new("UICorner")
                        btnCorner.CornerRadius = UDim.new(0, 6)
                        btnCorner.Parent = btn
                        
                        local title = Instance.new("TextLabel")
                        title.Size = UDim2.new(1, -10, 0, 20)
                        title.Position = UDim2.new(0, 5, 1, -25)
                        title.BackgroundTransparency = 1
                        title.TextColor3 = Color3.new(1,1,1)
                        title.Text = item.Name
                        title.TextSize = 11
                        title.Font = Enum.Font.GothamMedium
                        title.TextTruncate = Enum.TextTruncate.AtEnd
                        title.Parent = btn
                        
                        btn.MouseButton1Click:Connect(function()
                            local success = ItemSpawner.Give(item)
                            
                            
                            local originalColor = btn.BackgroundColor3
                            if success then
                                btn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
                            else
                                btn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
                            end
                            task.wait(0.3)
                            btn.BackgroundColor3 = originalColor
                        end)
                    end
                end
                
                
                local count = 0
                for _, v in ipairs(scroll:GetChildren()) do
                     if v:IsA("ImageButton") then count = count + 1 end
                end
                local rows = math.ceil(count / 5) 
                scroll.CanvasSize = UDim2.new(0, 0, 0, rows * 95)
            end
            
            search:GetPropertyChangedSignal("Text"):Connect(function()
                populate(search.Text)
            end)
            
            populate()
            
            return frame
        end

        PlayerSide:CreateButton({
            Name = "Open Item Spawner",
            Callback = function()
                local win = createSpawnerWindow()
                win.Visible = not win.Visible
            end
        })
        
        PlayerSide:CreateButton({
            Name = "Refresh Item List",
            Callback = function()
                ItemSpawner.ScanItems()
                local win = createSpawnerWindow()
                
                
                win:Destroy()
                spawnerWindow = nil
                local newWin = createSpawnerWindow()
                newWin.Visible = true
            end
        })
    end
    local SettingsTab = GUI.Window:CreateTab("Settings", 7072721682)
    local MainSettings, ConfigsSide = SettingsTab:Split(0.5)

    MainSettings:CreateSection("Config Creation")
    MainSettings:CreateInput({
        Name = "New Config Name",
        PlaceholderText = "shlepa228",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text) GUI.ConfigName = Text end
    })
    
    local function UpdateConfigList()
    end
    MainSettings:CreateButton({
         Name = "Save Current as New Config",
         Callback = function()
             if GUI.ConfigManager then
                 GUI.ConfigManager.Save(GUI.ConfigName, Settings)
                 GUI.UpdateConfigList(ConfigsSide, Settings)
                 GUI.Window:Notify({
                     Title = "Config Saved",
                     Content = "Configuration " .. GUI.ConfigName .. " has been successfully saved.",
                     Duration = 5,
                     Image = 4483362458
                 })
             	end
         end
     })
 
    GUI.UpdateConfigList(ConfigsSide, Settings)

    MainSettings:CreateSection("KeybinsList & Watermark")
    GUI.Elements.Toggles["watermarkEnabled"] = MainSettings:CreateToggle({
        Name = "Watermark",
        CurrentValue = Settings.watermarkEnabled,
        Flag = "watermarkEnabled",
        Callback = function(Value) 
            Settings.watermarkEnabled = Value 
            if GUI.Watermark.Frame then GUI.Watermark.Frame.Visible = Value end
            if GUI.KeybindList.Frame then GUI.KeybindList.Frame.Visible = Value end
        end
    })
    MainSettings:CreateKeybind({
        Name = "Menu Toggle",
        CurrentKeybind = getKeyName(Settings.toggleKey),
        HoldToInteract = false,
        CallOnChange = true,
        Flag = "toggleKey",
        Callback = function(Key) setKeybind(Key, Settings, "toggleKey") end
    })

    MainSettings:CreateSection("System")
    MainSettings:CreateButton({
        Name = "Unload Script",
        Callback = function()
            if GUI.UnloadCallback then
                GUI.UnloadCallback()
            end
            GUI.Window:Destroy()
        end
    })
end

function GUI.UpdateConfigList(ConfigsSide, Settings)
    if ConfigsSide.Clear then
        ConfigsSide:Clear()
    end
    
    ConfigsSide:CreateSection("Config Actions")
    
    
    ConfigsSide:CreateButton({
        Name = "Load Selected",
        Callback = function()
            if GUI.ConfigName and GUI.ConfigName ~= "" then
                GUI.ConfigManager.Load(GUI.ConfigName, Settings)
                GUI.UpdateToggles(Settings)
                GUI.Window:Notify({
                    Title = "Config Loaded",
                    Content = "Configuration " .. GUI.ConfigName .. " has been successfully loaded.",
                    Duration = 5,
                    Image = 4483362458
                })
            else
                GUI.Window:Notify({
                    Title = "Error",
                    Content = "Please select a config first.",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end
    })
    
    ConfigsSide:CreateButton({
        Name = "Delete Selected",
        Callback = function()
            if GUI.ConfigName and GUI.ConfigName ~= "" then
                local configToDelete = GUI.ConfigName
                GUI.ConfigManager.Delete(configToDelete)
                GUI.ConfigName = ""
                GUI.UpdateConfigList(ConfigsSide, Settings)
                GUI.Window:Notify({
                    Title = "Config Deleted",
                    Content = "Configuration " .. configToDelete .. " has been deleted.",
                    Duration = 5,
                    Image = 4483362458
                })
            else
                GUI.Window:Notify({
                    Title = "Error",
                    Content = "Please select a config first.",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end
    })
    
    ConfigsSide:CreateSection("Available Configs")
    
    if GUI.ConfigManager then
        local configs = GUI.ConfigManager.List()
        if type(configs) == "table" then
            for _, name in pairs(configs) do    
                local ConfigButton = ConfigsSide:CreateButton({
                    Name = (GUI.ConfigName == name and "► " or "") .. name,
                    Callback = function()
                        GUI.ConfigName = name
                        GUI.UpdateConfigList(ConfigsSide, Settings)
                    end
                })
            end
        end
    end
end

function GUI.ToggleVisible(Settings)
    pcall(function()
        if GUI.Window.Toggle then
            GUI.Window:Toggle()
        end
    end)
end
function GUI.UpdateToggles(Settings)
    pcall(function()
        for flag, toggle in pairs(GUI.Elements.Toggles) do
            if toggle and toggle.Set then
                local value = Settings[flag]
                if flag == "magicBulletHouseCheck" then
                    value = not value
                end
                toggle:Set(value)
            end
        end
    end)
end

function GUI.UpdateWatermark(Settings)
    if not GUI.Watermark.Frame or not GUI.Watermark.Text then return end
    
    GUI.Watermark.Frame.Visible = Settings.watermarkEnabled
    if not Settings.watermarkEnabled then return end
    
    GUI.FrameCount = (GUI.FrameCount or 0) + 1
    local now = tick()
    if now - GUI.LastWatermarkUpdate < 1 then return end
    
    local deltaTime = now - GUI.LastWatermarkUpdate
    local fps = math.floor(GUI.FrameCount / deltaTime)
    GUI.LastWatermarkUpdate = now
    GUI.FrameCount = 0
    
    local ping = 0
    local playerName = LocalPlayer.DisplayName or LocalPlayer.Name
    
    pcall(function()
        local stats = game:GetService("Stats")
        if stats:FindFirstChild("Network") and stats.Network:FindFirstChild("ServerStatsItem") then
            ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
        end
    end)
    
    GUI.Watermark.Text.Text = string.format("Withonium | %s | %dms | %dfps", playerName, ping, fps)
end

function GUI.UpdateKeybindList(Settings)
    if not GUI.KeybindList.Frame or not GUI.KeybindList.Container then return end
    
    local container = GUI.KeybindList.Container
    local itemIndex = 0
    
    local function getOrCreateItem(name)
        itemIndex = itemIndex + 1
        local item = GUI.KeybindList.Items[itemIndex]
        
        if not item then
            item = {}
            item.Frame = Instance.new("Frame")
            item.Frame.BackgroundTransparency = 1
            item.Frame.Size = UDim2.new(1, 0, 0, 20)
            item.Frame.Parent = container
            
            item.NameLabel = Instance.new("TextLabel")
            item.NameLabel.BackgroundTransparency = 1
            item.NameLabel.Size = UDim2.new(0.4, 0, 1, 0)
            item.NameLabel.Font = Enum.Font.Gotham
            item.NameLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            item.NameLabel.TextSize = 13
            item.NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            item.NameLabel.Parent = item.Frame
            
            item.StatusLabel = Instance.new("TextLabel")
            item.StatusLabel.BackgroundTransparency = 1
            item.StatusLabel.Position = UDim2.new(1, 0, 0, 0)
            item.StatusLabel.AnchorPoint = Vector2.new(1, 0)
            item.StatusLabel.Size = UDim2.new(0.6, 0, 1, 0)
            item.StatusLabel.Font = Enum.Font.GothamMedium
            item.StatusLabel.TextSize = 12
            item.StatusLabel.TextXAlignment = Enum.TextXAlignment.Right
            item.StatusLabel.Parent = item.Frame
            
            GUI.KeybindList.Items[itemIndex] = item
        end
        
        item.Frame.Visible = true
        return item
    end
    
    local hasItems = false
    local keybindList = {
        {Name = "Aimbot", Key = Settings.aimKey, Active = Settings.aimbotEnabled},
        {Name = "Silent Aim", Key = Settings.silentAimKey, Active = Settings.silentAimEnabled},
        {Name = "Spider", Key = Settings.spiderKey, Active = Settings.spiderEnabled},
        {Name = "Speed", Key = Settings.speedHackKey, Active = Settings.speedHackEnabled},
        {Name = "Jump Shot", Key = Settings.jumpShotKey, Active = Settings.jumpShotEnabled},
        {Name = "FreeCam", Key = Settings.freeCamKey, Active = Settings.freeCamEnabled},
        {Name = "Anti-Aim", Key = Settings.antiAimKey, Active = Settings.antiAimEnabled},
        {Name = "FullBright", Key = Settings.FullBrightKey, Active = Settings.fullBrightEnabled}
    }

    for _, bind in ipairs(keybindList) do
        if bind.Key and bind.Key ~= Enum.KeyCode.Unknown then
            local item = getOrCreateItem(bind.Name)
            item.NameLabel.Text = bind.Name
            item.StatusLabel.Text = string.format("[%s] [%s]", getKeyName(bind.Key), bind.Active and "Active" or "Disabled")
            item.StatusLabel.TextColor3 = bind.Active and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(100, 100, 100)
            hasItems = true
        end
    end
    
    for i = itemIndex + 1, #GUI.KeybindList.Items do
        GUI.KeybindList.Items[i].Frame.Visible = false
    end
    
    GUI.KeybindList.Frame.Visible = Settings.watermarkEnabled and hasItems
end

function GUI.SwitchTab(tabName, Settings) end

return GUI
