--[[
    Alpha Project - Anti-AFK
    Nudge minimal periodik agar tidak terdeteksi AFK. Ringan (satu thread + wait).
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local AntiAfkFeature = {}

local INTERVAL = 50
local running = false

local function nudge()
    local hrp = Services.get_humanoid_root_part()
    if not hrp then return end
    local cf = hrp.CFrame
    hrp.CFrame = cf * CFrame.new(0.01, 0, 0)
    task.wait(0.05)
    if hrp and hrp.Parent then
        hrp.CFrame = cf
    end
end

local function loop()
    while running and Settings.features.antiAfkEnabled do
        task.wait(INTERVAL)
        if not Settings.features.antiAfkEnabled then break end
        pcall(nudge)
    end
    running = false
end

function AntiAfkFeature.toggle(enabled)
    Settings.features.antiAfkEnabled = enabled
    if enabled and not running then
        running = true
        task.spawn(loop)
    else
        running = false
    end
end

return AntiAfkFeature
