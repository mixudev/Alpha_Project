--[[
    Alpha Project - Notifikasi Koneksi
    Popup notifikasi: koneksi join, koneksi sama join/sudah di map, pindah area, nyawa, dll.
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))
local HttpUtil = (Alpha and Alpha.require) and Alpha.require("utils/http") or require(script.Parent.Parent:FindFirstChild("utils/http"))

local NotifikasiFeature = {}

local checkConn = nil
local playerAddedConn = nil
local playerRemovingConn = nil
local CHECK_INTERVAL = 1
local lastCheck = 0
local lastPos = {}
local lastHealth = {}
local lastCheckpointY = {}
local lastCheckpointPart = {}
local cachedCheckpointParts = {}
local lastCheckpointScan = 0
local CHECKPOINT_CACHE_INTERVAL = 4
local MOVE_THRESHOLD = 45
local CHECKPOINT_Y_STEP = 80
local CHECKPOINT_NEAR_DIST = 14
local DISPLAY_TIME = 4.5
local CHECKPOINT_NAMES = { "Checkpoint", "Finish", "Goal", "End", "FinishLine", "CheckPoint" }

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

-- Koneksi sama = di server, teman dari teman kita (bukan teman kita)
local function get_shared_connections(callback)
    local direct = get_friends_in_game()
    local inServer = {}
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= Services.LocalPlayer then
            inServer[p.UserId] = p
        end
    end
    local friendIds = Settings.friendIds or {}
    local sharedSet = {}
    local count = 0
    local total = #direct
    local called = false
    if total == 0 then
        if callback then callback({}) end
        return
    end
    for _, friend in ipairs(direct) do
        task.spawn(function()
            local friends = HttpUtil.get_friends(friend.UserId)
            for _, f in ipairs(friends or {}) do
                local uid = f.id
                if uid and inServer[uid] and not friendIds[uid] then
                    sharedSet[inServer[uid]] = true
                end
            end
            count = count + 1
            if count >= total and callback and not called then
                called = true
                local list = {}
                for p, _ in pairs(sharedSet) do
                    table.insert(list, p)
                end
                callback(list)
            end
        end)
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

local function show_notification(title, text, icon)
    local gui = Services.CoreGui:FindFirstChild("AlphaNotifGui")
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "AlphaNotifGui"
        gui.Parent = Services.CoreGui
        gui.DisplayOrder = 200
    end
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

    local iconStr = (icon and tostring(icon) ~= "" and tostring(icon)) or "◆"
    local iconLbl = Instance.new("TextLabel")
    iconLbl.Parent = frame
    iconLbl.Position = UDim2.new(0, 14, 0, 14)
    iconLbl.Size = UDim2.new(0, 36, 0, 36)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text = iconStr
    iconLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLbl.TextSize = 24
    iconLbl.Font = Enum.Font.GothamBold

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Parent = frame
    titleLbl.Position = UDim2.new(0, 58, 0, 10)
    titleLbl.Size = UDim2.new(1, -70, 0, 22)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = tostring(title or "")
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.TextSize = 14
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local textLbl = Instance.new("TextLabel")
    textLbl.Parent = frame
    textLbl.Position = UDim2.new(0, 58, 0, 32)
    textLbl.Size = UDim2.new(1, -70, 0, 36)
    textLbl.BackgroundTransparency = 1
    textLbl.Text = tostring(text or "")
    textLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLbl.TextSize = 12
    textLbl.Font = Enum.Font.Gotham
    textLbl.TextXAlignment = Enum.TextXAlignment.Left
    textLbl.TextYAlignment = Enum.TextYAlignment.Top
    textLbl.TextWrapped = true

    frame.Size = UDim2.new(0, 320, 0, 76)
    frame.Position = UDim2.new(0.5, -160, 0, -76)
    local TweenService = Services.TweenService
    TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -160, 0, 18)
    }):Play()

    task.delay(DISPLAY_TIME, function()
        if frame.Parent then
            TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -160, 0, -76)
            }):Play()
            task.delay(0.35, function()
                pcall(function() frame:Destroy() end)
            end)
        end
    end)
end

local function is_checkpoint_part(part)
    if not part or not part:IsA("BasePart") then return false end
    local name = (part.Name or ""):gsub("%s+", "")
    for _, cp in ipairs(CHECKPOINT_NAMES) do
        if name:lower():find((cp:gsub("%s+", "")):lower(), 1, true) then
            return true
        end
    end
    return false
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
            if pos and pos.Y then
                local lastY = lastCheckpointY[p] or pos.Y
                if pos.Y - lastY >= CHECKPOINT_Y_STEP then
                    lastCheckpointY[p] = math.floor(pos.Y / CHECKPOINT_Y_STEP) * CHECKPOINT_Y_STEP
                    show_notification("Checkpoint", name .. " mencapai ketinggian baru (+" .. CHECKPOINT_Y_STEP .. " stud)", "🏁")
                elseif pos.Y < lastY - 20 then
                    lastCheckpointY[p] = pos.Y
                end
            end
            if pos then
                if t - lastCheckpointScan > CHECKPOINT_CACHE_INTERVAL then
                    cachedCheckpointParts = {}
                    for _, desc in pairs(Services.Workspace:GetDescendants()) do
                        if desc:IsA("BasePart") and is_checkpoint_part(desc) then
                            table.insert(cachedCheckpointParts, desc)
                        end
                    end
                    lastCheckpointScan = t
                end
                for _, desc in ipairs(cachedCheckpointParts) do
                    if desc.Parent and (pos - desc.Position).Magnitude <= CHECKPOINT_NEAR_DIST then
                        local key = tostring(desc)
                        if not lastCheckpointPart[p] then lastCheckpointPart[p] = {} end
                        if not lastCheckpointPart[p][key] then
                            lastCheckpointPart[p][key] = true
                            show_notification("Checkpoint", name .. " mencapai: " .. (desc.Name or "Checkpoint"), "🏁")
                        end
                    end
                end
            end
            if lastHealth[p] ~= nil and health ~= nil then
                if health <= 0 and lastHealth[p] > 0 then
                    show_notification("Koneksi", name .. " nyawanya hilang", "💔")
                elseif health < lastHealth[p] and health > 0 then
                    show_notification("Koneksi", name .. " terkena damage", "⚠️")
                end
            end
            lastPos[p] = pos
            lastHealth[p] = health
        else
            lastPos[p] = nil
            lastHealth[p] = nil
            lastCheckpointY[p] = nil
            lastCheckpointPart[p] = nil
        end
    end
    for p, _ in pairs(lastPos) do
        local found = false
        for _, f in ipairs(friends) do if f == p then found = true break end end
        if not found then lastPos[p] = nil lastHealth[p] = nil lastCheckpointY[p] = nil lastCheckpointPart[p] = nil end
    end
end

local function on_player_added(player)
    if not Settings.features.notifikasiEnabled then return end
    if player == Services.LocalPlayer then return end
    local name = player.DisplayName or player.Name
    local friendIds = Settings.friendIds or {}
    if friendIds[player.UserId] then
        show_notification("Koneksi join", name .. " masuk server", "👋")
        player.CharacterAdded:Connect(function()
            if Settings.features.notifikasiEnabled then
                show_notification("Koneksi respawn", name .. " respawn", "🔄")
            end
        end)
        return
    end
    task.spawn(function()
        get_shared_connections(function(shared)
            if not Settings.features.notifikasiEnabled then return end
            for _, p in ipairs(shared) do
                if p == player then
                    show_notification("Koneksi sama join", name .. " masuk server", "◇")
                    break
                end
            end
        end)
    end)
end

local function enable()
    Settings.features.notifikasiEnabled = true
    ensure_friends_loaded(function()
        if not Settings.features.notifikasiEnabled then return end
        lastPos = {}
        lastHealth = {}
        lastCheck = 0
        checkConn = Services.RunService.Heartbeat:Connect(check_friends)
        playerAddedConn = Services.Players.PlayerAdded:Connect(on_player_added)
        playerRemovingConn = Services.Players.PlayerRemoving:Connect(function(p)
            if p ~= Services.LocalPlayer then
                local friendIds = Settings.friendIds or {}
                if friendIds[p.UserId] then
                    show_notification("Koneksi left", (p.DisplayName or p.Name) .. " keluar dari server", "👋")
                end
            end
            lastPos[p] = nil
            lastHealth[p] = nil
            lastCheckpointY[p] = nil
            lastCheckpointPart[p] = nil
        end)
        show_notification("Notifikasi aktif", "Koneksi join/left, checkpoint, damage, respawn & pindah area akan ditampilkan di sini.", "🔔")
        -- Koneksi / koneksi sama yang sudah di map (sudah join sebelum kita) — setelah notif siap
        task.delay(DISPLAY_TIME + 0.5, function()
            if not Settings.features.notifikasiEnabled then return end
            local friends = get_friends_in_game()
            if #friends > 0 then
                local names = {}
                for _, p in ipairs(friends) do
                    table.insert(names, p.DisplayName or p.Name)
                end
                show_notification("Koneksi di map", table.concat(names, ", ") .. " sudah di map", "◆")
            end
            get_shared_connections(function(shared)
                if not Settings.features.notifikasiEnabled or #shared == 0 then return end
                local names = {}
                for _, p in ipairs(shared) do
                    table.insert(names, p.DisplayName or p.Name)
                end
                show_notification("Koneksi sama di map", table.concat(names, ", ") .. " sudah di map", "◇")
            end)
        end)
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
