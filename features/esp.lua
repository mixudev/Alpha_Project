--[[
    Alpha Project - ESP Feature
    Menampilkan nama player dari jarak jauh (Billboard name tags)
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local EspFeature = {}

local espGuis = {}
local espLabels = {}
local espCharConns = {}
local espPlayerAddedConn = nil
local espPlayerRemovingConn = nil
local espColorUpdateConn = nil
local espColorLastUpdate = 0
local ESP_UPDATE_INTERVAL = 0.2

-- Warna berdasarkan jarak: deket = hijau, menengah = kuning, jauh = merah
local COLOR_CLOSE = Color3.fromRGB(100, 255, 150)
local COLOR_MEDIUM = Color3.fromRGB(255, 255, 180)
local COLOR_FAR = Color3.fromRGB(255, 120, 100)
local DIST_CLOSE = 50
local DIST_MEDIUM = 150

-- ============================================
-- CREATE BILLBOARD FOR ONE PLAYER
-- ============================================

local function create_esp_for_player(p)
    if not p or not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if espGuis[p] then
        pcall(function() espGuis[p]:Destroy() end)
        espGuis[p] = nil
        espLabels[p] = nil
    end

    local gui = Instance.new("BillboardGui")
    gui.Name = "AlphaESP_" .. tostring(p.UserId)
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
    label.TextSize = 20
    label.Text = "◆ " .. nameText .. " ◆"
    label.TextColor3 = COLOR_MEDIUM
    label.TextStrokeColor3 = Color3.fromRGB(0, 80, 90)
    label.TextStrokeTransparency = 0.2
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center

    espGuis[p] = gui
    espLabels[p] = label
end

local function remove_esp_for_player(p)
    if espGuis[p] then
        pcall(function() espGuis[p]:Destroy() end)
        espGuis[p] = nil
        espLabels[p] = nil
    end
end

local function update_esp_colors()
    if not Settings.features.espEnabled then return end
    local myChar = Services.LocalPlayer and Services.LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local myPos = myHrp.Position
    for p, label in pairs(espLabels) do
        if label.Parent and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - myPos).Magnitude
                if dist < DIST_CLOSE then
                    label.TextColor3 = COLOR_CLOSE
                elseif dist < DIST_MEDIUM then
                    label.TextColor3 = COLOR_MEDIUM
                else
                    label.TextColor3 = COLOR_FAR
                end
            end
        end
    end
end

local function setup_char_conn(p)
    if espCharConns[p] then
        espCharConns[p]:Disconnect()
        espCharConns[p] = nil
    end
    espCharConns[p] = p.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        if Settings.features.espEnabled then
            create_esp_for_player(p)
        end
    end)
end

-- ============================================
-- ENABLE / DISABLE
-- ============================================

local function enable_esp()
    Settings.features.espEnabled = true
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= Services.LocalPlayer then
            if p.Character then create_esp_for_player(p) end
            setup_char_conn(p)
        end
    end
    espColorLastUpdate = 0
    espColorUpdateConn = Services.RunService.Heartbeat:Connect(function()
        local t = tick()
        if t - espColorLastUpdate >= ESP_UPDATE_INTERVAL then
            espColorLastUpdate = t
            update_esp_colors()
        end
    end)
    espPlayerAddedConn = Services.Players.PlayerAdded:Connect(function(p)
        if p ~= Services.LocalPlayer then
            setup_char_conn(p)
            task.wait(0.1)
            if Settings.features.espEnabled and p.Character then
                create_esp_for_player(p)
            end
        end
    end)
    espPlayerRemovingConn = Services.Players.PlayerRemoving:Connect(function(p)
        remove_esp_for_player(p)
        if espCharConns[p] then
            espCharConns[p]:Disconnect()
            espCharConns[p] = nil
        end
    end)
end

local function disable_esp()
    Settings.features.espEnabled = false
    if espColorUpdateConn then
        espColorUpdateConn:Disconnect()
        espColorUpdateConn = nil
    end
    for p, _ in pairs(espGuis) do
        remove_esp_for_player(p)
    end
    for p, conn in pairs(espCharConns) do
        if conn then conn:Disconnect() end
        espCharConns[p] = nil
    end
    if espPlayerAddedConn then
        espPlayerAddedConn:Disconnect()
        espPlayerAddedConn = nil
    end
    if espPlayerRemovingConn then
        espPlayerRemovingConn:Disconnect()
        espPlayerRemovingConn = nil
    end
end

-- ============================================
-- TOGGLE (Public API)
-- ============================================

function EspFeature.toggle(enabled)
    if enabled then
        enable_esp()
    else
        disable_esp()
    end
end

return EspFeature
