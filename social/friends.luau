--[[
    Alpha Project - Friends System
    Load user friends dari Roblox API
]]

local Services = require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = require(script.Parent.Parent:FindFirstChild("config/settings"))
local HttpUtil = require(script.Parent.Parent:FindFirstChild("utils/http"))

local Friends = {}

-- ============================================
-- LOAD MY FRIENDS
-- ============================================

function Friends.load_my_friends()
    if not Services.is_http_enabled() then
        warn("❌ HTTP Service is not enabled")
        return false
    end
    
    local success, result = pcall(function()
        return HttpUtil.get_friends(Services.LocalPlayer.UserId)
    end)
    
    if success and result then
        Settings.friends.myFriends = {}
        for _, friend in ipairs(result) do
            Settings.friends.myFriends[friend.id] = {
                name = friend.name,
                displayName = friend.displayName
            }
        end
        Settings.friends.friendDataLoaded = true
        print("✅ Loaded " .. #result .. " friends")
        return true
    else
        warn("❌ Failed to load friends")
        return false
    end
end

-- ============================================
-- GET MY FRIENDS
-- ============================================

function Friends.get_my_friends()
    return Settings.friends.myFriends
end

-- ============================================
-- IS DATA LOADED
-- ============================================

function Friends.is_loaded()
    return Settings.friends.friendDataLoaded
end

-- ============================================
-- REFRESH
-- ============================================

function Friends.refresh()
    Friends.load_my_friends()
end

return Friends
