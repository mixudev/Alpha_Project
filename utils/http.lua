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
-- GET REQUEST
-- ============================================

function HttpUtil.get(url)
    if not Services.is_http_enabled() then
        warn("❌ HTTP Service is not enabled")
        return nil, "HTTP disabled"
    end
    
    local success, response = pcall(function()
        return Services.HttpService:GetAsync(url)
    end)
    
    if success then
        return response
    else
        warn("❌ HTTP GET failed:", response)
        return nil, response
    end
end

-- ============================================
-- GET + DECODE JSON
-- ============================================

function HttpUtil.get_json(url)
    local response = HttpUtil.get(url)
    if not response then
        return nil
    end
    
    local success, decoded = pcall(function()
        return HttpUtil.decode(response)
    end)
    
    if success then
        return decoded
    else
        warn("❌ JSON decode failed:", decoded)
        return nil
    end
end

-- ============================================
-- ROBLOX API: Get Friends
-- ============================================

function HttpUtil.get_friends(userId)
    local url = string.format("https://friends.roblox.com/v1/users/%d/friends", userId)
    local response = HttpUtil.get_json(url)
    
    if response and response.data then
        return response.data
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
    local url = string.format("https://users.roblox.com/v1/users/%d", userId)
    local response = HttpUtil.get_json(url)
    return response
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
