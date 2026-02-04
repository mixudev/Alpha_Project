--[[
    Alpha Project - Infinity Zoom Feature
    Zoom kamera bisa dari jarak sangat jauh (tanpa batas MaxZoom default)
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local InfinityZoomFeature = {}

local DEFAULT_MAX_ZOOM = 128
local INFINITY_MAX_ZOOM = 100000

local zoomConnection = nil
local zoomChangedConnection = nil

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
    local cam = Services.Camera
    if not cam then return end
    -- Re-apply saat game/script lain mengubah MaxZoom
    if zoomChangedConnection then zoomChangedConnection:Disconnect() end
    zoomChangedConnection = cam:GetPropertyChangedSignal("MaxZoom"):Connect(function()
        if Settings.features.infinityZoomEnabled and cam.MaxZoom ~= INFINITY_MAX_ZOOM then
            cam.MaxZoom = INFINITY_MAX_ZOOM
        end
    end)
    -- Juga paksa setiap frame (banyak game override di camera script)
    if zoomConnection then zoomConnection:Disconnect() end
    zoomConnection = Services.RunService.RenderStepped:Connect(function()
        if not Settings.features.infinityZoomEnabled then return end
        local c = Services.Camera
        if c and c.MaxZoom ~= INFINITY_MAX_ZOOM then
            c.MaxZoom = INFINITY_MAX_ZOOM
        end
    end)
end

local function disable_infinity_zoom()
    Settings.features.infinityZoomEnabled = false
    if zoomConnection then
        zoomConnection:Disconnect()
        zoomConnection = nil
    end
    if zoomChangedConnection then
        zoomChangedConnection:Disconnect()
        zoomChangedConnection = nil
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
