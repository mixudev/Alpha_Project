--[[
    Alpha Project - Infinity Zoom Feature
    Zoom kamera bisa dari jarak sangat jauh (tanpa batas MaxZoom default)
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local InfinityZoomFeature = {}

local DEFAULT_MAX_ZOOM = 128
local INFINITY_MAX_ZOOM = 10000

local zoomConnection = nil

-- ============================================
-- APPLY ZOOM LIMIT
-- ============================================

local function apply_max_zoom(value)
    local cam = Services.Camera
    if cam then
        cam.MaxZoom = value
    end
end

-- ============================================
-- ENABLE / DISABLE
-- ============================================

local function enable_infinity_zoom()
    Settings.features.infinityZoomEnabled = true
    apply_max_zoom(INFINITY_MAX_ZOOM)
    -- Keep applying every frame in case game/camera resets it
    if zoomConnection then zoomConnection:Disconnect() end
    zoomConnection = Services.RunService.RenderStepped:Connect(function()
        if not Settings.features.infinityZoomEnabled then return end
        local cam = Services.Camera
        if cam and cam.MaxZoom ~= INFINITY_MAX_ZOOM then
            cam.MaxZoom = INFINITY_MAX_ZOOM
        end
    end)
end

local function disable_infinity_zoom()
    Settings.features.infinityZoomEnabled = false
    if zoomConnection then
        zoomConnection:Disconnect()
        zoomConnection = nil
    end
    apply_max_zoom(DEFAULT_MAX_ZOOM)
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
