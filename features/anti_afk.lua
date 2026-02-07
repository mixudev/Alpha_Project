--[[
    Alpha Project - Anti-AFK
    Mencegah deteksi AFK: VirtualUser (simulasi input) + nudge karakter.
    Interval cukup sering agar tidak terdeteksi idle.
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local AntiAfkFeature = {}

local INTERVAL = 25
local running = false

local function do_virtual_user()
    local ok, vu = pcall(function()
        return game:GetService("VirtualUser")
    end)
    if ok and vu then
        pcall(function()
            vu:CaptureFocus()
        end)
        task.wait(0.1)
        pcall(function()
            vu:ClickButton2(Vector2.new(0, 0))
        end)
        return true
    end
    return false
end

local function nudge_character()
    local hrp = Services.get_humanoid_root_part()
    if not hrp then return end
    local cf = hrp.CFrame
    hrp.CFrame = cf * CFrame.new(0.08, 0, 0)
    task.wait(0.08)
    if hrp and hrp.Parent then
        hrp.CFrame = cf
    end
end

local function tick_anti_afk()
    do_virtual_user()
    pcall(nudge_character)
end

local function loop()
    while running and Settings.features.antiAfkEnabled do
        task.wait(INTERVAL)
        if not Settings.features.antiAfkEnabled then break end
        pcall(tick_anti_afk)
    end
    running = false
end

function AntiAfkFeature.toggle(enabled)
    Settings.features.antiAfkEnabled = enabled
    if enabled and not running then
        running = true
        task.spawn(loop)
        tick_anti_afk()
    else
        running = false
    end
end

return AntiAfkFeature
