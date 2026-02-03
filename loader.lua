--[[
    Alpha Project - Main Loader
    Entry point untuk seluruh aplikasi
    Support untuk local script & remote loadstring
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- ============================================
-- DETECT EXECUTION MODE
-- ============================================

local isRemote = false
local baseUrl = "https://raw.githubusercontent.com/mixudev/Alpha_Project/main"
local ScriptFolder = nil

if script and script.Parent then
    -- Local execution (script in workspace/serverscriptservice)
    isRemote = false
    ScriptFolder = script.Parent
else
    -- Remote execution (loadstring)
    isRemote = true
end

print("🔍 Execution Mode:", isRemote and "REMOTE" or "LOCAL")

-- ============================================
-- MODULE LOADER (Support Both Modes)
-- ============================================

local cache = {}

local function require_module(path)
    -- Check cache first
    if cache[path] then
        return cache[path]
    end
    
    local module
    
    if isRemote then
        -- Remote: Load from GitHub (use game:HttpGet when available)
        local url = baseUrl .. "/" .. path .. ".lua"
        local success, content = pcall(function()
            -- prefer game:HttpGet for compatibility in many executors
            if type(game.HttpGet) == "function" then
                return game:HttpGet(url)
            else
                return HttpService:GetAsync(url)
            end
        end)

        -- fallback: try ghproxy if direct fetch failed
        if not success or not content or #tostring(content) < 5 then
            local proxyUrl = "https://ghproxy.com/" .. url
            local ok2, res2 = pcall(function()
                if type(game.HttpGet) == "function" then
                    return game:HttpGet(proxyUrl)
                else
                    return HttpService:GetAsync(proxyUrl)
                end
            end)
            if ok2 and res2 and #tostring(res2) > 5 then
                success = true
                content = res2
            else
                warn("❌ Failed to load from GitHub (both direct and proxy):", url)
                warn("   Error:", content)
                return nil
            end
        end

        -- Strip UTF-8 BOM if present
        if type(content) == "string" and content:sub(1,3) == "\239\187\191" then
            content = content:sub(4)
        end

        -- Execute the code
        local fn, err = loadstring(content, path)
        if not fn then
            warn("❌ Failed to parse module:", path)
            warn("   Error:", err)
            return nil
        end

        local okExec, resultExec = pcall(fn)
        if not okExec then
            warn("❌ Module execution error:", path)
            warn("   Error:", resultExec)
            return nil
        end
        module = resultExec
    else
        -- Local: Load from script parent
        local moduleName = path:gsub("/", ".")
        local part = ScriptFolder
        
        for segment in path:gmatch("[^/]+") do
            part = part:FindFirstChild(segment)
            if not part then
                warn("❌ Module not found:", path)
                return nil
            end
        end
        
        module = require(part)
    end
    
    cache[path] = module
    return module
end

-- ============================================
-- LOAD MODULES (Sequential)
-- ============================================

local function load_all()
    print("🚀 Loading Alpha Project...")
    
    if not HttpService.HttpEnabled and isRemote then
        warn("⚠️ HTTP Service is not enabled!")
        warn("ℹ️ Enable it in Game Settings > Security > Allow HTTP Requests")
        return false
    end
    
    -- 1. Core + Config
    print("📦 Loading Config & Core...")
    local Config = require_module("config/settings")
    local CoreServices = require_module("core/services")
    local CoreConnections = require_module("core/connections")
    
    if not Config or not CoreServices then
        warn("❌ Failed to load Core modules")
        return false
    end
    
    print("✅ Config & Core loaded")
    
    -- 2. Utils (Tween, HTTP, Time)
    print("📦 Loading Utils...")
    local TweenUtil = require_module("utils/tween")
    local HttpUtil = require_module("utils/http")
    local TimeUtil = require_module("utils/time")
    
    if not TweenUtil or not HttpUtil then
        warn("❌ Failed to load Utils")
        return false
    end
    
    print("✅ Utils loaded")
    
    -- 3. UI Components
    print("📦 Loading UI Components...")
    local UIComponents = require_module("ui/components/main")
    
    if not UIComponents then
        warn("❌ Failed to load UI Components")
        return false
    end
    
    print("✅ UI Components loaded")
    
    -- 4. UI Pages
    print("📦 Loading UI Main...")
    local UIMain = require_module("ui/main")
    local UISidebar = require_module("ui/sidebar")
    local UIPages = require_module("ui/pages")
    
    if not UIMain then
        warn("❌ Failed to load UI Main")
        return false
    end
    
    print("✅ UI Main loaded")
    
    -- 5. Player System
    print("📦 Loading Player System...")
    local PlayerList = require_module("player/list")
    local PlayerSpectate = require_module("player/spectate")
    local PlayerInfoPopup = require_module("player/info_popup")
    
    print("✅ Player System loaded")
    
    -- 6. Social System
    print("📦 Loading Social System...")
    local Friends = require_module("social/friends")
    local MutualChecker = require_module("social/mutual_checker")
    local Notification = require_module("social/notification")
    
    print("✅ Social System loaded")
    
    -- 7. Features
    print("📦 Loading Features...")
    local FlyFeature = require_module("features/fly")
    local NoClipFeature = require_module("features/noclip")
    local InfinityJump = require_module("features/infinity_jump")
    local GlobalFriend = require_module("features/global_friend")
    
    print("✅ Features loaded")
    
    -- ============================================
    -- Initialize Main UI
    -- ============================================
    
    print("🎨 Creating UI...")
    local UIStructure = UIMain.create()
    if not UIStructure then
        warn("❌ Failed to create main UI")
        return false
    end
    
    print("✅ UI Created")
    print("✅✅✅ Alpha Project Loaded Successfully! ✅✅✅")
    print("📌 Press RIGHT CTRL to toggle menu")
    print("🔗 Execution Mode:", isRemote and "REMOTE (GitHub)" or "LOCAL")
    
    -- ============================================
    -- Return Public API
    -- ============================================
    
    return {
        Config = Config,
        CoreServices = CoreServices,
        UIMain = UIMain,
        PlayerList = PlayerList,
        Friends = Friends,
        FlyFeature = FlyFeature,
        NoClipFeature = NoClipFeature,
    }
end

-- ============================================
-- START
-- ============================================

local success, result = pcall(load_all)

if not success then
    warn("❌ CRITICAL ERROR:", result)
    warn("⚠️ Check if HTTP is enabled and GitHub URL is correct")
else
    return result
end
