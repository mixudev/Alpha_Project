--[[
    Alpha Project - Night Vision
    Membuat map terang seperti night vision (ambient + brightness)
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local NightVisionFeature = {}

local Lighting = nil
local runConn = nil
local originalAmbient = nil
local originalBrightness = nil
local originalOutdoorAmbient = nil

local NV_AMBIENT = Color3.fromRGB(180, 220, 200)
local NV_BRIGHTNESS = 1.2
local NV_OUTDOOR = Color3.fromRGB(140, 180, 160)

local function get_lighting()
    if not Lighting then
        Lighting = game:GetService("Lighting")
    end
    return Lighting
end

local function apply_night_vision()
    local L = get_lighting()
    if not L then return end
    L.Ambient = NV_AMBIENT
    L.Brightness = NV_BRIGHTNESS
    L.OutdoorAmbient = NV_OUTDOOR
end

local function restore_original()
    local L = get_lighting()
    if not L then return end
    if originalAmbient then L.Ambient = originalAmbient end
    if originalBrightness then L.Brightness = originalBrightness end
    if originalOutdoorAmbient then L.OutdoorAmbient = originalOutdoorAmbient end
end

local function enable()
    Settings.features.nightVisionEnabled = true
    local L = get_lighting()
    if L then
        originalAmbient = L.Ambient
        originalBrightness = L.Brightness
        originalOutdoorAmbient = L.OutdoorAmbient
    end
    runConn = Services.RunService.RenderStepped:Connect(function()
        if not Settings.features.nightVisionEnabled then return end
        apply_night_vision()
    end)
    apply_night_vision()
end

local function disable()
    Settings.features.nightVisionEnabled = false
    if runConn then
        runConn:Disconnect()
        runConn = nil
    end
    restore_original()
end

function NightVisionFeature.toggle(enabled)
    if enabled then enable() else disable() end
end

return NightVisionFeature
