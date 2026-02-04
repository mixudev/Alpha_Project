--[[
    Alpha Project - Notifikasi Koneksi
    Popup notifikasi perubahan koneksi kita: pindah area, nyawa hilang.
    Hanya untuk koneksi (teman), tampil di atas seperti admin Roblox.
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))
local HttpUtil = (Alpha and Alpha.require) and Alpha.require("utils/http") or require(script.Parent.Parent:FindFirstChild("utils/http"))
local TweenUtil = (Alpha and Alpha.require) and Alpha.require("utils/tween") or require(script.Parent.Parent:FindFirstChild("utils/tween"))

local NotifikasiFeature = {}

local checkConn = nil
local playerAddedConn = nil
local playerRemovingConn = nil
local CHECK_INTERVAL = 0.5
local lastCheck = 0
local lastPos = {}
local lastHealth = {}
local MOVE_THRESHOLD = 45
local DISPLAY_TIME = 4.5

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

local function show_notification(title, text, icon)
    local gui = Services.CoreGui:FindFirstChild("AlphaGUI")
    if not gui then gui = Instance.new("ScreenGui") gui.Name = "AlphaNotifGui" gui.Parent = Services.CoreGui gui.DisplayOrder = 200 end
    local existing = gui:FindFirstChild("AlphaNotif")
    if existing then existing:Destroy() end

    local frame = Instance.new("Frame")
    frame.Name = "AlphaNotif"
    frame.Parent = gui
    frame.Size = UDim2.new(0, 320, 0, 0)
    frame.Position = UDim2.new(0.5, -160, 0, -80)
    frame.BackgroundColor3 = Color3.fromRGB(28, 32, 38)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.ZIndex = 200

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 160, 145)
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = frame

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Parent = frame
    iconLbl.Position = UDim2.new(0, 14, 0, 14)
    iconLbl.Size = UDim2.new(0, 36, 0, 36)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text = icon or "◆"
    iconLbl.TextColor3 = Color3.fromRGB(0, 220, 200)
    iconLbl.TextSize = 22
    iconLbl.Font = Enum.Font.GothamBold

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Parent = frame
    titleLbl.Position = UDim2.new(0, 58, 0, 12)
    titleLbl.Size = UDim2.new(1, -70, 0, 22)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(240, 245, 250)
    titleLbl.TextSize = 14
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local textLbl = Instance.new("TextLabel")
    textLbl.Parent = frame
    textLbl.Position = UDim2.new(0, 58, 0, 34)
    textLbl.Size = UDim2.new(1, -70, 0, 28)
    textLbl.BackgroundTransparency = 1
    textLbl.Text = text
    textLbl.TextColor3 = Color3.fromRGB(200, 210, 220)
    textLbl.TextSize = 12
    textLbl.Font = Enum.Font.Gotham
    textLbl.TextXAlignment = Enum.TextXAlignment.Left
    textLbl.TextWrapped = true

    frame.Size = UDim2.new(0, 320, 0, 72)
    frame.Position = UDim2.new(0.5, -160, 0, -72)
    local TweenService = Services.TweenService
    TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -160, 0, 18)
    }):Play()

    task.delay(DISPLAY_TIME, function()
        if frame.Parent then
            TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -160, 0, -80)
            }):Play()
            task.delay(0.35, function()
                pcall(function() frame:Destroy() end)
            end)
        end
    end)
end

local function check_friends()
    if not Settings.features.notifikasiEnabled then return end
    local t = tick()
    if t - lastCheck < CHECK_INTERVAL then return end
    lastCheck = t
    local friends = get_friends_in_game()
    for _, p in ipairs(friends) do
        local char = p.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            local pos = hrp and hrp.Position or nil
            local health = hum and hum.Health or nil
            local name = p.DisplayName or p.Name
            if lastPos[p] and pos and (pos - lastPos[p]).Magnitude > MOVE_THRESHOLD then
                show_notification("Koneksi pindah", name .. " pindah ke area baru", "📍")
            end
            if lastHealth[p] ~= nil and health ~= nil then
                if health <= 0 and lastHealth[p] > 0 then
                    show_notification("Koneksi", name .. " nyawanya hilang", "💔")
                elseif health < lastHealth[p] and health > 0 then
                    show_notification("Koneksi", name .. " terkena damage", "⚠")
                end
            end
            lastPos[p] = pos
            lastHealth[p] = health
        else
            lastPos[p] = nil
            lastHealth[p] = nil
        end
    end
    for p, _ in pairs(lastPos) do
        local found = false
        for _, f in ipairs(friends) do if f == p then found = true break end end
        if not found then lastPos[p] = nil lastHealth[p] = nil end
    end
end

local function enable()
    Settings.features.notifikasiEnabled = true
    ensure_friends_loaded(function()
        if not Settings.features.notifikasiEnabled then return end
        lastPos = {}
        lastHealth = {}
        lastCheck = 0
        checkConn = Services.RunService.Heartbeat:Connect(check_friends)
        playerAddedConn = Services.Players.PlayerAdded:Connect(function()
            if Settings.features.notifikasiEnabled then ensure_friends_loaded(function() end) end
        end)
        playerRemovingConn = Services.Players.PlayerRemoving:Connect(function(p)
            lastPos[p] = nil
            lastHealth[p] = nil
        end)
        show_notification("Notifikasi", "Notifikasi siap. Perubahan koneksi akan ditampilkan di sini.", "🔔")
    end)
end

local function disable()
    Settings.features.notifikasiEnabled = false
    if checkConn then checkConn:Disconnect() checkConn = nil end
    if playerAddedConn then playerAddedConn:Disconnect() playerAddedConn = nil end
    if playerRemovingConn then playerRemovingConn:Disconnect() playerRemovingConn = nil end
    lastPos = {}
    lastHealth = {}
end

function NotifikasiFeature.toggle(enabled)
    if enabled then enable() else disable() end
end

return NotifikasiFeature
