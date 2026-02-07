--[[
    Alpha Project - Notifikasi Koneksi
    Popup notifikasi: koneksi join, koneksi sama join/sudah di map, checkpoint, nyawa, dll.
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
local lastLeaderstats = {}
local cachedCheckpointParts = {}
local lastCheckpointScan = 0
local CHECKPOINT_CACHE_INTERVAL = 3
local CHECKPOINT_Y_STEP = 50
local CHECKPOINT_NEAR_DIST = 85
local DISPLAY_TIME = 4.5
local GAP_BETWEEN_NOTIF = 0.5
local notification_queue = {}
local notification_showing = false

local CHECKPOINT_KEYWORDS = {
    "check", "finish", "goal", "end", "save", "spawn", "flag", "zone", "stage", "level",
    "teleport", "portal", "pad", "point", "gate", "start", "respawn", "pole", "line",
    "reach", "complete", "win", "final", "spot", "mark", "area", "region", "ring", "plate"
}

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

local function show_notification_internal(title, text, icon, on_done)
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
    frame.Size = UDim2.new(0, 340, 0, 88)
    frame.Position = UDim2.new(0.5, -170, 0, -88)
    frame.BackgroundColor3 = Color3.fromRGB(28, 32, 38)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = false
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
    local titleStr = (title and tostring(title) ~= "") and tostring(title) or "Notifikasi"
    local textStr = (text and tostring(text) ~= "") and tostring(text) or "—"

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Parent = frame
    iconLbl.AnchorPoint = Vector2.new(0, 0.5)
    iconLbl.Position = UDim2.new(0, 14, 0.5, 0)
    iconLbl.Size = UDim2.new(0, 40, 0, 40)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text = iconStr
    iconLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLbl.TextSize = 26
    iconLbl.Font = Enum.Font.SourceSansBold
    iconLbl.ZIndex = 202
    iconLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    iconLbl.TextStrokeTransparency = 0.6

    -- Konten (judul + isi) ditengah vertikal
    local contentFrame = Instance.new("Frame")
    contentFrame.Parent = frame
    contentFrame.AnchorPoint = Vector2.new(0, 0.5)
    contentFrame.Position = UDim2.new(0, 62, 0.5, 0)
    contentFrame.Size = UDim2.new(1, -74, 0, 56)
    contentFrame.BackgroundTransparency = 1

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Parent = contentFrame
    titleLbl.Position = UDim2.new(0, 0, 0, 0)
    titleLbl.Size = UDim2.new(1, 0, 0, 24)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = titleStr
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.TextSize = 16
    titleLbl.Font = Enum.Font.SourceSansBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
    titleLbl.ZIndex = 202
    titleLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLbl.TextStrokeTransparency = 0.6

    local textLbl = Instance.new("TextLabel")
    textLbl.Parent = contentFrame
    textLbl.Position = UDim2.new(0, 0, 0, 26)
    textLbl.Size = UDim2.new(1, 0, 0, 30)
    textLbl.BackgroundTransparency = 1
    textLbl.Text = textStr
    textLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLbl.TextSize = 14
    textLbl.Font = Enum.Font.SourceSans
    textLbl.TextXAlignment = Enum.TextXAlignment.Left
    textLbl.TextYAlignment = Enum.TextYAlignment.Top
    textLbl.TextWrapped = true
    textLbl.ZIndex = 202
    textLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLbl.TextStrokeTransparency = 0.6

    local TweenService = Services.TweenService
    TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -170, 0, 18)
    }):Play()

    task.delay(DISPLAY_TIME, function()
        if frame.Parent then
            TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -170, 0, -88)
            }):Play()
            task.delay(0.35, function()
                pcall(function() frame:Destroy() end)
                if on_done then on_done() end
            end)
        else
            if on_done then on_done() end
        end
    end)
end

local function process_notification_queue()
    if notification_showing or #notification_queue == 0 then return end
    local item = table.remove(notification_queue, 1)
    if not item then return end
    notification_showing = true
    show_notification_internal(item[1], item[2], item[3], function()
        notification_showing = false
        task.delay(GAP_BETWEEN_NOTIF, process_notification_queue)
    end)
end

local function show_notification(title, text, icon)
    table.insert(notification_queue, { title or "Notifikasi", text or "—", icon or "◆" })
    process_notification_queue()
end

local function name_has_checkpoint_keyword(str)
    if not str or #str == 0 then return false end
    local lower = str:gsub("%s+", ""):lower()
    for _, kw in ipairs(CHECKPOINT_KEYWORDS) do
        if lower:find(kw:lower(), 1, true) then return true end
    end
    return false
end

local function is_checkpoint_part(part)
    if not part then return false end
    if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then
        if name_has_checkpoint_keyword(part.Name) then return true end
        if part.Parent and name_has_checkpoint_keyword(part.Parent.Name) then return true end
    end
    return false
end

local function is_checkpoint_model(obj)
    if not obj or not obj:IsA("Model") then return false end
    return name_has_checkpoint_keyword(obj.Name)
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
                        if is_checkpoint_part(desc) then
                            table.insert(cachedCheckpointParts, desc)
                        elseif is_checkpoint_model(desc) then
                            local posModel = nil
                            local ok, pivot = pcall(function() return desc:GetPivot() end)
                            if ok and pivot and pivot.Position then posModel = pivot.Position end
                            if not posModel and desc.PrimaryPart then posModel = desc.PrimaryPart.Position end
                            if not posModel then
                                local ok2, cf, sz = pcall(function() return desc:GetBoundingBox() end)
                                if ok2 and cf and cf.Position then posModel = cf.Position end
                            end
                            if posModel then
                                table.insert(cachedCheckpointParts, { position = posModel, displayName = desc.Name or "Checkpoint", key = "M_" .. desc.Name .. tostring(desc) })
                            end
                        end
                    end
                    lastCheckpointScan = t
                end
                for _, item in ipairs(cachedCheckpointParts) do
                    local checkPos = item.Position or (item.position)
                    if checkPos and (pos - checkPos).Magnitude <= CHECKPOINT_NEAR_DIST then
                        local key = item.key or tostring(item)
                        local label = item.displayName or item.Name or "Checkpoint"
                        if not lastCheckpointPart[p] then lastCheckpointPart[p] = {} end
                        if not lastCheckpointPart[p][key] then
                            lastCheckpointPart[p][key] = true
                            show_notification("Checkpoint", name .. " mencapai: " .. label, "🏁")
                        end
                    end
                end
                -- Checkpoint via leaderstats (Stage, Level, Checkpoint, Zone, dll.)
                local stats = p:FindFirstChild("leaderstats") or p:FindFirstChild("Leaderstats")
                if stats then
                    if not lastLeaderstats[p] then lastLeaderstats[p] = {} end
                    for _, child in ipairs(stats:GetChildren()) do
                        if (child:IsA("IntValue") or child:IsA("NumberValue")) and child.Name then
                            local val = child.Value
                            local last = lastLeaderstats[p][child.Name]
                            if last ~= nil and val > last then
                                show_notification("Checkpoint", name .. " " .. child.Name .. ": " .. tostring(last) .. " → " .. tostring(val), "🏁")
                            end
                            lastLeaderstats[p][child.Name] = val
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
            lastLeaderstats[p] = nil
        end
    end
    for p, _ in pairs(lastPos) do
        local found = false
        for _, f in ipairs(friends) do if f == p then found = true break end end
        if not found then lastPos[p] = nil lastHealth[p] = nil lastCheckpointY[p] = nil lastCheckpointPart[p] = nil lastLeaderstats[p] = nil end
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
        show_notification("Koneksi: Masuk server", "Notifikasi koneksi aktif. Join/left, checkpoint, damage akan ditampilkan di sini.", "🔔")
        -- Koneksi di map / koneksi sama di map — tampilkan selalu (dengan retry jika belum ada data)
        local function show_koneksi_di_map()
            if not Settings.features.notifikasiEnabled then return end
            local friends = get_friends_in_game()
            if #friends > 0 then
                local names = {}
                for _, p in ipairs(friends) do
                    table.insert(names, p.DisplayName or p.Name)
                end
                show_notification("Koneksi di map", table.concat(names, ", ") .. " sudah di map", "◆")
            else
                show_notification("Koneksi di map", "Tidak ada koneksi di map saat ini.", "◆")
            end
            get_shared_connections(function(shared)
                if not Settings.features.notifikasiEnabled then return end
                if #shared > 0 then
                    local names = {}
                    for _, p in ipairs(shared) do
                        table.insert(names, p.DisplayName or p.Name)
                    end
                    show_notification("Koneksi sama di map", table.concat(names, ", ") .. " sudah di map", "◇")
                else
                    show_notification("Koneksi sama di map", "Tidak ada koneksi sama di map.", "◇")
                end
            end)
        end
        task.delay(DISPLAY_TIME + 0.5, function()
            local hadFriendIds = next(Settings.friendIds or {}) ~= nil
            show_koneksi_di_map()
            -- Retry sekali (kalau HTTP lambat, friendIds baru terisi)
            task.delay(6, function()
                if not Settings.features.notifikasiEnabled then return end
                if not hadFriendIds and next(Settings.friendIds or {}) ~= nil then
                    show_koneksi_di_map()
                end
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

-- Tampilkan notifikasi dari luar (untuk menu Test, dll.)
function NotifikasiFeature.show(title, text, icon)
    show_notification(title or "Notifikasi", text or "—", icon or "◆")
end

return NotifikasiFeature
