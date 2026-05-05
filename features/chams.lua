--[[
    Alpha Project - Chams
    Highlight karakter player tembus dinding (Highlight instance)
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local ChamsFeature = {}

local highlights = {}
local charConns = {}
local playerAddedConn = nil
local playerRemovingConn = nil
local updateConn = nil
local lastUpdate = 0
local CHAMS_UPDATE_INTERVAL = 0.15

local FILL_COLOR = Color3.fromRGB(0, 200, 180)
local OUTLINE_COLOR = Color3.fromRGB(0, 120, 110)
local FILL_TRANSPARENCY = 0.7
local OUTLINE_TRANSPARENCY = 0.2

local function add_highlight(player)
    if not player or player == Services.LocalPlayer then return end
    if highlights[player] then return end
    local char = player.Character
    if not char then return end
    
    local hl = Instance.new("Highlight")
    hl.Name = "AlphaChams_" .. player.Name
    hl.FillColor = FILL_COLOR
    hl.OutlineColor = OUTLINE_COLOR
    hl.FillTransparency = FILL_TRANSPARENCY
    hl.OutlineTransparency = OUTLINE_TRANSPARENCY
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = char
    hl.Parent = Services.CoreGui
    
    highlights[player] = hl
end

local function remove_highlight(player)
    if highlights[player] then
        pcall(function() highlights[player]:Destroy() end)
        highlights[player] = nil
    end
    if charConns[player] then
        charConns[player]:Disconnect()
        charConns[player] = nil
    end
end

local function update_all()
    if not Settings.features.chamsEnabled then return end
    local t = tick()
    if t - lastUpdate < CHAMS_UPDATE_INTERVAL then return end
    lastUpdate = t
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= Services.LocalPlayer and p.Character then
            add_highlight(p)
        end
    end
end

local function setup_char_conn(player)
    if charConns[player] then
        charConns[player]:Disconnect()
        charConns[player] = nil
    end
    charConns[player] = player.CharacterAdded:Connect(function()
        task.wait(0.1)
        if Settings.features.chamsEnabled then
            add_highlight(player)
        end
    end)
end

local function enable()
    Settings.features.chamsEnabled = true
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= Services.LocalPlayer then
            add_highlight(p)
            setup_char_conn(p)
        end
    end
    playerAddedConn = Services.Players.PlayerAdded:Connect(function(p)
        if Settings.features.chamsEnabled then setup_char_conn(p) add_highlight(p) end
    end)
    playerRemovingConn = Services.Players.PlayerRemoving:Connect(function(p)
        remove_highlight(p)
    end)
    updateConn = Services.RunService.Heartbeat:Connect(update_all)
end

local function disable()
    Settings.features.chamsEnabled = false
    if updateConn then updateConn:Disconnect() updateConn = nil end
    if playerAddedConn then playerAddedConn:Disconnect() playerAddedConn = nil end
    if playerRemovingConn then playerRemovingConn:Disconnect() playerRemovingConn = nil end
    for p, _ in pairs(highlights) do
        remove_highlight(p)
    end
end

function ChamsFeature.toggle(enabled)
    if enabled then enable() else disable() end
end

return ChamsFeature
