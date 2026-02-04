--[[
    Alpha Project - HTTP Utility
    Helper untuk Roblox API calls (friends, games, etc)
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))

local HttpUtil = {}

-- ============================================
-- LOW LEVEL HTTP (Executor/Studio compatible)
-- ============================================

local function executor_request(method, url, headers, body)
    -- syn.request (Synapse & some others)
    if type(syn) == "table" and type(syn.request) == "function" then
        return syn.request({
            Url = url,
            Method = method or "GET",
            Headers = headers,
            Body = body,
        })
    end
    -- http_request (KRNL / others)
    if type(http_request) == "function" then
        return http_request({
            Url = url,
            Method = method or "GET",
            Headers = headers,
            Body = body,
        })
    end
    -- request (some executors)
    if type(request) == "function" then
        return request({
            Url = url,
            Method = method or "GET",
            Headers = headers,
            Body = body,
        })
    end
    return nil
end

function HttpUtil.get(url)
    -- 1) Executor-friendly: game:HttpGet
    if type(game) == "userdata" and type(game.HttpGet) == "function" then
        return game:HttpGet(url)
    end

    -- 2) Studio / in-game with HttpEnabled
    if Services.HttpService and Services.HttpService.HttpEnabled then
        return Services.HttpService:GetAsync(url)
    end

    -- 3) Executor request fallback
    local res = executor_request("GET", url)
    if res then
        -- many executors return {StatusCode=200, Body="..."}
        if type(res) == "table" then
            return res.Body or res.body or res.ResponseBody or res.responseBody
        end
        return res
    end

    error("HTTP not available for GET: " .. tostring(url))
end

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
    if not Services.can_http() then
        warn("❌ HTTP not available")
        return {}
    end
    
    local url = string.format("https://friends.roblox.com/v1/users/%d/friends", userId)
    
    local success, response = pcall(function()
        return HttpUtil.get(url)
    end)
    
    if not success then
        warn("❌ HTTP GET failed:", response)
        return {}
    end
    
    local okDecode, decoded = pcall(function()
        return HttpUtil.decode(response)
    end)
    if okDecode and type(decoded) == "table" and decoded.data then
        return decoded.data or {}
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
    if not Services.can_http() then
        warn("❌ HTTP not available")
        return nil
    end
    
    local url = string.format("https://users.roblox.com/v1/users/%d", userId)
    
    local success, response = pcall(function()
        return HttpUtil.get(url)
    end)
    
    if not success then
        warn("❌ HTTP GET failed:", response)
        return nil
    end
    
    local okDecode, decoded = pcall(function()
        return HttpUtil.decode(response)
    end)
    if okDecode then
        return decoded
    end
    return nil
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
