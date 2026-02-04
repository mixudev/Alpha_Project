--[[
    Alpha Project - HTTP Utility
    Helper untuk Roblox API calls (friends, games, etc)
]]

local Services = require(script.Parent.Parent:FindFirstChild("core/services"))

local HttpUtil = {}

-- ============================================
-- JSON ENCODE/DECODE
-- ============================================

function HttpUtil.encode(data)
    return Services.HttpService:JSONEncode(data)
end

function HttpUtil.decode(json)
    return Services.HttpService:JSONDecode(json)
end



-- ============================================
-- ROBLOX API: Get Friends
-- ============================================

function HttpUtil.get_friends(userId)
    if not Services.is_http_enabled() then
        warn("❌ HTTP Service is not enabled")
        return {}
    end
    
    local url = string.format("https://friends.roblox.com/v1/users/%d/friends", userId)
    
    local success, response = pcall(function()
        return Services.HttpService:GetAsync(url)
    end)
    
    if not success then
        warn("❌ HTTP GET failed:", response)
        return {}
    end
    
    local decoded = pcall(function()
        return HttpUtil.decode(response)
    end)
    
    if decoded and decoded.data then
        return decoded.data
    end
    return {}
end

-- ============================================
-- ROBLOX API: Get Player Avatar
-- ============================================

function HttpUtil.get_headshot_url(userId, size)
    size = size or 150
    return string.format(
        "https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=%d&height=%d&format=png",
        userId, size, size
    )
end

-- ============================================
-- ROBLOX API: Get User Info (from CreatorAPI)
-- ============================================

function HttpUtil.get_user_info(userId)
    if not Services.is_http_enabled() then
        warn("❌ HTTP Service is not enabled")
        return nil
    end
    
    local url = string.format("https://users.roblox.com/v1/users/%d", userId)
    
    local success, response = pcall(function()
        return Services.HttpService:GetAsync(url)
    end)
    
    if not success then
        warn("❌ HTTP GET failed:", response)
        return nil
    end
    
    local decoded = pcall(function()
        return HttpUtil.decode(response)
    end)
    
    return decoded
end

-- ============================================
-- SAFE PCALL WRAPPER
-- ============================================

function HttpUtil.safe_call(callback)
    local success, result = pcall(callback)
    if success then
        return result
    else
        warn("❌ HTTP Utility error:", result)
        return nil
    end
end

return HttpUtil
