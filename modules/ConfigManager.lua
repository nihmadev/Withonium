local HttpService = game:GetService("HttpService")

local ConfigManager = {
    Folder = "Withonium/Configs"
}

function ConfigManager.Init()
    local success, err = pcall(function()
        if not isfolder("Withonium") then
            makefolder("Withonium")
        
        end
        if not isfolder(ConfigManager.Folder) then
            makefolder(ConfigManager.Folder)
        end
    end)
    return success
end

function ConfigManager.Serialize(settings)
    local serialized = {}
    for k, v in pairs(settings) do
        if typeof(v) == "Color3" then
            serialized[k] = {Type = "Color3", Value = {v.R, v.G, v.B}}
        elseif typeof(v) == "EnumItem" then
            serialized[k] = {Type = "EnumItem", Enum = tostring(v.EnumType), Value = v.Name}
        elseif type(v) == "table" and k == "crosshairSettings" then
            -- Special case for crosshair settings table if it exists
            serialized[k] = v
        elseif type(v) ~= "function" and type(v) ~= "table" then
            serialized[k] = v
        end
    end
    return HttpService:JSONEncode(serialized)
end

function ConfigManager.Deserialize(json, settings)
    local data = HttpService:JSONDecode(json)
    for k, v in pairs(data) do
        if type(v) == "table" and v.Type then
            if v.Type == "Color3" then
                settings[k] = Color3.new(v.Value[1], v.Value[2], v.Value[3])
            elseif v.Type == "EnumItem" then
                local enumType = v.Enum:gsub("Enum.", "")
                pcall(function()
                    settings[k] = Enum[enumType][v.Value]
                end)
            end
        else
            settings[k] = v
        end
    end
end

function ConfigManager.Save(name, settings)
    ConfigManager.Init()
    local success, err = pcall(function()
        local path = ConfigManager.Folder .. "/" .. name .. ".json"
        local json = ConfigManager.Serialize(settings)
        writefile(path, json)
    end)
    return success
end

function ConfigManager.Load(name, settings)
    local success, result = pcall(function()
        local path = ConfigManager.Folder .. "/" .. name .. ".json"
        if isfile(path) then
            local json = readfile(path)
            ConfigManager.Deserialize(json, settings)
            return true
        
        end
        return false
    end)
    return success and result
end

function ConfigManager.List()
    ConfigManager.Init()
    local success, result = pcall(function()
        local files = listfiles(ConfigManager.Folder)
        local configs = {}
        for _, file in ipairs(files) do
            -- Extract filename without path and extension
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
        return configs
    end)
    return success and result or {}
end

function ConfigManager.Delete(name)
    local path = ConfigManager.Folder .. "/" .. name .. ".json"
    if isfile(path) then
        delfile(path)
    end
end

return ConfigManager
