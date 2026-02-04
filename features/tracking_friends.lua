--[[
    Alpha Project - ESP Koneksi
    Sama seperti ESP tapi hanya menampilkan koneksi (teman) kita.
    Realtime scan sampai kedetect, ringan (throttle update).
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))
local HttpUtil = (Alpha and Alpha.require) and Alpha.require("utils/http") or require(script.Parent.Parent:FindFirstChild("utils/http"))

local TrackingFriendsFeature = {}

local espGuis = {}
local espLabels = {}
local espCharConns = {}
local playerAddedConn = nil
local playerRemovingConn = nil
local scanConn = nil
local SCAN_INTERVAL = 0.2
local lastScan = 0

local COLOR_KONEKSI = Color3.fromRGB(0, 220, 200)
local COLOR_STROKE = Color3.fromRGB(0, 80, 90)

local function get_friends_in_game()
    local list = {}
    local friendIds = Settings.friendIds or {}
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= Services.LocalPlayer and friendIds[p.UserId] then
            table.insert(list, p)
        end
    end
    return list
end

local function create_esp_for_friend(p)
    if not p or not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if espGuis[p] then
        pcall(function() espGuis[p]:Destroy() end)
        espGuis[p] = nil
        espLabels[p] = nil
    end

    local gui = Instance.new("BillboardGui")
    gui.Name = "AlphaESP_Koneksi_" .. tostring(p.UserId)
    gui.Adornee = hrp
    gui.AlwaysOnTop = true
    gui.Size = UDim2.new(0, 160, 0, 40)
    gui.StudsOffset = Vector3.new(0, 2.5, 0)
    gui.MaxDistance = 10000
    gui.Parent = Services.CoreGui

    local nameText = p.DisplayName or p.Name
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Parent = gui
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Oswald
    label.TextSize = 18
    label.Text = "◆ " .. nameText .. " ◆"
    label.TextColor3 = COLOR_KONEKSI
    label.TextStrokeColor3 = COLOR_STROKE
    label.TextStrokeTransparency = 0.2
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center

    espGuis[p] = gui
    espLabels[p] = label
end

local function remove_esp_for_friend(p)
    if espGuis[p] then
        pcall(function() espGuis[p]:Destroy() end)
        espGuis[p] = nil
        espLabels[p] = nil
    end
end

local function setup_char_conn(p)
    if espCharConns[p] then
        espCharConns[p]:Disconnect()
        espCharConns[p] = nil
    end
    espCharConns[p] = p.CharacterAdded:Connect(function()
        task.wait(0.1)
        if Settings.features.trackingFriendsEnabled and Settings.friendIds and Settings.friendIds[p.UserId] then
            create_esp_for_friend(p)
        end
    end)
end

local function scan_and_update()
    if not Settings.features.trackingFriendsEnabled then return end
    local t = tick()
    if t - lastScan < SCAN_INTERVAL then return end
    lastScan = t
    local friends = get_friends_in_game()
    local seen = {}
    for _, p in ipairs(friends) do
        seen[p] = true
        if p.Character then
            create_esp_for_friend(p)
        end
        setup_char_conn(p)
    end
    for p, _ in pairs(espGuis) do
        if not seen[p] then
            remove_esp_for_friend(p)
            if espCharConns[p] then
                espCharConns[p]:Disconnect()
                espCharConns[p] = nil
            end
        end
    end
end

local function ensure_friends_loaded(callback)
    if next(Settings.friendIds or {}) ~= nil then
        if callback then callback() end
        return
    end
    task.spawn(function()
        local friends = HttpUtil.get_friends(Services.LocalPlayer.UserId)
        for _, f in ipairs(friends or {}) do
            if f.id then Settings.friendIds[f.id] = true end
        end
        if callback then callback() end
    end)
end

local function enable()
    Settings.features.trackingFriendsEnabled = true
    ensure_friends_loaded(function()
        if not Settings.features.trackingFriendsEnabled then return end
        lastScan = 0
        scanConn = Services.RunService.Heartbeat:Connect(scan_and_update)
        playerAddedConn = Services.Players.PlayerAdded:Connect(function()
            if Settings.features.trackingFriendsEnabled then
                ensure_friends_loaded(function() end)
            end
        end)
        playerRemovingConn = Services.Players.PlayerRemoving:Connect(function(p)
            remove_esp_for_friend(p)
            if espCharConns[p] then
                espCharConns[p]:Disconnect()
                espCharConns[p] = nil
            end
        end)
        scan_and_update()
    end)
end

local function disable()
    Settings.features.trackingFriendsEnabled = false
    if scanConn then scanConn:Disconnect() scanConn = nil end
    if playerAddedConn then playerAddedConn:Disconnect() playerAddedConn = nil end
    if playerRemovingConn then playerRemovingConn:Disconnect() playerRemovingConn = nil end
    for p, _ in pairs(espGuis) do
        remove_esp_for_friend(p)
        if espCharConns[p] then espCharConns[p]:Disconnect() espCharConns[p] = nil end
    end
end

function TrackingFriendsFeature.toggle(enabled)
    if enabled then enable() else disable() end
end

return TrackingFriendsFeature
