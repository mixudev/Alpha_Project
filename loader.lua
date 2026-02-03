--[[
    Alpha Project - Main Loader
    Entry point untuk seluruh aplikasi
    Menginisialisasi modules dan start main script
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- PATH HELPER
-- ============================================

local ScriptFolder = script.Parent
local function require_module(path)
    local module = ScriptFolder:FindFirstChild(path)
    if not module then
        warn("❌ Module not found:", path)
        return nil
    end
    return require(module)
end

-- ============================================
-- LOAD MODULES (Sequential)
-- ============================================

local function load_all()
    print("🚀 Loading Alpha Project...")
    
    -- 1. Core + Config
    local Config = require_module("config/settings")
    local CoreServices = require_module("core/services")
    local CoreConnections = require_module("core/connections")
    
    print("✅ Config & Core loaded")
    
    -- 2. Utils (Tween, HTTP, Time)
    local TweenUtil = require_module("utils/tween")
    local HttpUtil = require_module("utils/http")
    local TimeUtil = require_module("utils/time")
    
    print("✅ Utils loaded")
    
    -- 3. UI Components
    local UIComponents = require_module("ui/components/main")
    
    print("✅ UI Components loaded")
    
    -- 4. UI Pages
    local UIMain = require_module("ui/main")
    local UISidebar = require_module("ui/sidebar")
    local UIPages = require_module("ui/pages")
    
    print("✅ UI Main loaded")
    
    -- 5. Player System
    local PlayerList = require_module("player/list")
    local PlayerSpectate = require_module("player/spectate")
    local PlayerInfoPopup = require_module("player/info_popup")
    
    print("✅ Player System loaded")
    
    -- 6. Social System
    local Friends = require_module("social/friends")
    local MutualChecker = require_module("social/mutual_checker")
    local Notification = require_module("social/notification")
    
    print("✅ Social System loaded")
    
    -- 7. Features
    local FlyFeature = require_module("features/fly")
    local NoClipFeature = require_module("features/noclip")
    local InfinityJump = require_module("features/infinity_jump")
    local GlobalFriend = require_module("features/global_friend")
    
    print("✅ Features loaded")
    
    -- ============================================
    -- Initialize Main UI
    -- ============================================
    
    local ScreenGui = UIMain.create()
    if not ScreenGui then
        warn("❌ Failed to create main UI")
        return
    end
    
    print("✅ UI Created")
    print("✅ Alpha Project Loaded Successfully!")
    print("📌 Press RIGHT CTRL to toggle menu")
    
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
else
    return result
end
