--[[
    Alpha Project - Global Friend Detector
    Highlight players with mutual friends
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local GlobalFriend = {}

-- ============================================
-- GLOBAL FRIEND STATE
-- ============================================

local globalFriendActive = false

-- ============================================
-- START GLOBAL FRIEND
-- ============================================

function GlobalFriend.start()
    if globalFriendActive then return end
    
    globalFriendActive = true
    Settings.features.globalFriendEnabled = true
    
    print("✅ Global Friend Detector activated")
end

-- ============================================
-- STOP GLOBAL FRIEND
-- ============================================

function GlobalFriend.stop()
    if not globalFriendActive then return end
    
    globalFriendActive = false
    Settings.features.globalFriendEnabled = false
    
    print("❌ Global Friend Detector deactivated")
end

-- ============================================
-- TOGGLE
-- ============================================

function GlobalFriend.toggle(enabled)
    if enabled then
        GlobalFriend.start()
    else
        GlobalFriend.stop()
    end
end

-- ============================================
-- CHECK STATUS
-- ============================================

function GlobalFriend.is_enabled()
    return globalFriendActive
end

return GlobalFriend
