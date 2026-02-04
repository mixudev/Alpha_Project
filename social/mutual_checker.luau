--[[
    Alpha Project - Mutual Friends Checker
    Check mutual friends berdasarkan data lokal
    Cek apakah player lain ada di dalam daftar friends lokal
]]

local Services = require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = require(script.Parent.Parent:FindFirstChild("config/settings"))
local Friends = require(script.Parent:FindFirstChild("friends"))

local MutualChecker = {}

-- ============================================
-- CHECK MUTUAL FRIENDS (Local Data Only)
-- ============================================

function MutualChecker.check(player)
    if not Friends.is_loaded() then
        print("⚠️ Friend data not loaded yet")
        return false
    end
    
    if player == Services.LocalPlayer then
        return false
    end
    
    -- Cek apakah player ada di dalam myFriends
    local myFriends = Friends.get_my_friends()
    local isFriend = myFriends[player.UserId] ~= nil
    
    if isFriend then
        print("✅ " .. player.Name .. " adalah teman kami!")
        Settings.friends.playerMutualFriends[player] = true
    else
        Settings.friends.playerMutualFriends[player] = false
    end
    
    return isFriend
end

-- ============================================
-- GET MUTUAL STATUS
-- ============================================

function MutualChecker.get(player)
    if not player then return false end
    return Settings.friends.playerMutualFriends[player] or false
end

-- ============================================
-- HAS MUTUAL FRIENDS
-- ============================================

function MutualChecker.has_mutual(player)
    if not player then return false end
    return MutualChecker.get(player) == true
end

return MutualChecker
