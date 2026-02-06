--[[
    Alpha Project - Infinity Zoom Feature
    Zoom kamera bisa dari jarak sangat jauh (tanpa batas MaxZoom default)
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local InfinityZoomFeature = {}

local DEFAULT_MAX_ZOOM = 128
local DEFAULT_MIN_ZOOM = 0.5
local INFINITY_MAX_ZOOM = 1000000
local INFINITY_MIN_ZOOM = 0.5

local zoomConnection = nil
local zoomChangedConnection = nil
local minZoomConnection = nil

-- ============================================
-- APPLY ZOOM LIMIT
-- ============================================

local function apply_zoom_limits(minZ, maxZ)
    local cam = Services.Camera
    if cam then
        if maxZ ~= nil then pcall(function() cam.MaxZoom = maxZ end) end
        if minZ ~= nil then pcall(function() if cam.MinZoom ~= nil then cam.MinZoom = minZ end end) end
    end
end

-- ============================================
-- ENABLE / DISABLE
-- ============================================

local function enable_infinity_zoom()
    Settings.features.infinityZoomEnabled = true
    apply_zoom_limits(INFINITY_MIN_ZOOM, INFINITY_MAX_ZOOM)
    local cam = Services.Camera
    if not cam then return end
    if zoomChangedConnection then zoomChangedConnection:Disconnect() end
    zoomChangedConnection = cam:GetPropertyChangedSignal("MaxZoom"):Connect(function()
        if Settings.features.infinityZoomEnabled and cam.MaxZoom ~= INFINITY_MAX_ZOOM then
            cam.MaxZoom = INFINITY_MAX_ZOOM
        end
    end)
    if minZoomConnection then minZoomConnection:Disconnect() end
    pcall(function()
        if cam.MinZoom ~= nil then
            minZoomConnection = cam:GetPropertyChangedSignal("MinZoom"):Connect(function()
                if Settings.features.infinityZoomEnabled and cam.MinZoom > INFINITY_MIN_ZOOM then
                    pcall(function() cam.MinZoom = INFINITY_MIN_ZOOM end)
                end
            end)
        end
    end)
    if zoomConnection then zoomConnection:Disconnect() end
    zoomConnection = Services.RunService.RenderStepped:Connect(function()
        if not Settings.features.infinityZoomEnabled then return end
        local c = Services.Camera
        if c then
            if c.MaxZoom ~= INFINITY_MAX_ZOOM then pcall(function() c.MaxZoom = INFINITY_MAX_ZOOM end) end
            if c.MinZoom ~= nil and c.MinZoom > INFINITY_MIN_ZOOM then pcall(function() c.MinZoom = INFINITY_MIN_ZOOM end) end
        end
    end)
end

local function disable_infinity_zoom()
    Settings.features.infinityZoomEnabled = false
    if zoomConnection then zoomConnection:Disconnect() zoomConnection = nil end
    if zoomChangedConnection then zoomChangedConnection:Disconnect() zoomChangedConnection = nil end
    if minZoomConnection then minZoomConnection:Disconnect() minZoomConnection = nil end
    apply_zoom_limits(DEFAULT_MIN_ZOOM, DEFAULT_MAX_ZOOM)
end

-- ============================================
-- TOGGLE (Public API)
-- ============================================

function InfinityZoomFeature.toggle(enabled)
    if enabled then
        enable_infinity_zoom()
    else
        disable_infinity_zoom()
    end
end

return InfinityZoomFeature
