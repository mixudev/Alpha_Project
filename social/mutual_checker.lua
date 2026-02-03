--[[
    Alpha Project - Mutual Friends Checker
    Check mutual friends antara LocalPlayer dan player lain
]]

local Services = require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = require(script.Parent.Parent:FindFirstChild("config/settings"))
local HttpUtil = require(script.Parent.Parent:FindFirstChild("utils/http"))
local Friends = require(script.Parent:FindFirstChild("friends"))

local MutualChecker = {}

-- ============================================
-- CHECK MUTUAL FRIENDS
-- ============================================

function MutualChecker.check(player)
    if not Friends.is_loaded() then
        print("⚠️ Friend data not loaded yet")
        return {}
    end
    
    if player == Services.LocalPlayer then
        return {}
    end
    
    print("🔍 Checking mutual friends with:", player.Name)
    
    local mutuals = {}
    local success, result = pcall(function()
        return HttpUtil.get_friends(player.UserId)
    end)
    
    if success and result then
        local myFriends = Friends.get_my_friends()
        
        for _, friend in ipairs(result) do
            if myFriends[friend.id] then
                table.insert(mutuals, {
                    id = friend.id,
                    name = friend.name,
                    displayName = friend.displayName
                })
            end
        end
        
        Settings.friends.playerMutualFriends[player] = mutuals
        print("✅ Found " .. #mutuals .. " mutual friends with " .. player.Name)
    else
        warn("❌ Failed to get friends for:", player.Name)
    end
    
    return mutuals
end

-- ============================================
-- GET MUTUAL FRIENDS FOR PLAYER
-- ============================================

function MutualChecker.get(player)
    if not player then return {} end
    return Settings.friends.playerMutualFriends[player] or {}
end

-- ============================================
-- HAS MUTUAL FRIENDS
-- ============================================

function MutualChecker.has_mutual(player)
    if not player then return false end
    local mutuals = MutualChecker.get(player)
    return #mutuals > 0
end

return MutualChecker
