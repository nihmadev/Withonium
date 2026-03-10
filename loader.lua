-- Withonium Loader (Single File Version)
local function log(msg)
    pcall(function()
        warn("[LOG] " .. tostring(msg))
        if rconsoleprint then rconsoleprint("[LOG] " .. tostring(msg) .. "\n") end
    end)
end

log("Loader started")
local GITHUB_USER = "allahbobax"
local GITHUB_REPO = "Withonium"
local BRANCH = "main"
local FILE_PATH = "bundle.lua"

local url = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", GITHUB_USER, GITHUB_REPO, BRANCH, FILE_PATH)
log("Fetching data...")

local success, content = pcall(function() return game:HttpGet(url, true) end)
if success then
    log("Data fetched, processing...")
    local func, err = loadstring(content)
    if func then
        log("Executing...")
        func()
    else
        log("Parsing error: " .. tostring(err))
    end
else
    log("Fetch failed. Connection blocked.")
end
