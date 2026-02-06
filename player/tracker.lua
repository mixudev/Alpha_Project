--[[
    Alpha Project - Tracker
    List koneksi kita + koneksi sama (sugest). Info: koneksi di map + 5 koneksi.
    Desain sama dengan halaman lain (Players/Settings).
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))
local HttpUtil = (Alpha and Alpha.require) and Alpha.require("utils/http") or require(script.Parent.Parent:FindFirstChild("utils/http"))
local ButtonComponent = (Alpha and Alpha.require) and Alpha.require("ui/components/button") or require(script.Parent.Parent:FindFirstChild("ui/components/button"))

local Tracker = {}

local BORDER_DIRECT = Color3.fromRGB(0, 130, 115)
local BORDER_SHARED = Color3.fromRGB(130, 100, 0)

-- ============================================
-- HELPERS
-- ============================================

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

local function get_direct_connections()
    local list = {}
    local friendIds = Settings.friendIds or {}
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= Services.LocalPlayer and friendIds[p.UserId] then
            table.insert(list, p)
        end
    end
    return list
end

local function get_shared_connections(callback)
    local direct = get_direct_connections()
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

-- ============================================
-- ENTRY ROW (sama style dengan Players list)
-- ============================================

local function create_entry(parent, player, layoutOrder, isDirect)
    local playerFrame = Instance.new("Frame")
    playerFrame.Name = player.Name
    playerFrame.Parent = parent
    playerFrame.BackgroundColor3 = Settings.colors.bg_light
    playerFrame.Size = UDim2.new(1, -20, 0, 42)
    playerFrame.LayoutOrder = layoutOrder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = playerFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = isDirect and BORDER_DIRECT or BORDER_SHARED
    stroke.Thickness = 1
    stroke.Transparency = 0
    stroke.Parent = playerFrame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = playerFrame
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 12, 0, 0)
    nameLabel.Size = UDim2.new(0.5, -20, 1, 0)
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.Text = player.DisplayName or player.Name
    nameLabel.TextColor3 = Settings.colors.text_secondary
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local infoBtn = ButtonComponent.new(playerFrame, "Info", UDim2.new(0.55, 5, 0.5, -16), function()
        Tracker.show_connection_info(player)
    end)
    infoBtn.Size = UDim2.new(0.4, -15, 0, 32)
end

-- Section label (sama seperti Section di halaman lain)
local function section_label(parent, text, layoutOrder)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = parent
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -20, 0, 28)
    lbl.LayoutOrder = layoutOrder
    lbl.Font = Enum.Font.Gotham
    lbl.Text = text
    lbl.TextColor3 = Settings.colors.text_secondary
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

-- ============================================
-- INFO POPUP: Koneksi di map + Koneksi (5)
-- ============================================

function Tracker.show_connection_info(player)
    if not player then return end

    local existingGui = Services.CoreGui:FindFirstChild("AlphaTrackerInfoGui")
    if existingGui then existingGui:Destroy() end

    local popupGui = Instance.new("ScreenGui")
    popupGui.Name = "AlphaTrackerInfoGui"
    popupGui.ResetOnSpawn = false
    popupGui.DisplayOrder = 100
    popupGui.Parent = Services.CoreGui

    local popup = Instance.new("Frame")
    popup.Name = "AlphaTrackerInfo"
    popup.Parent = popupGui
    popup.Size = UDim2.new(0, 450, 0, 500)
    popup.Position = UDim2.new(0.5, -225, 0.5, -250)
    popup.BackgroundColor3 = Settings.colors.bg_medium
    popup.BorderSizePixel = 0
    popup.Active = true
    popup.Draggable = true
    popup.ZIndex = 1

    local pcorner = Instance.new("UICorner")
    pcorner.CornerRadius = UDim.new(0, 12)
    pcorner.Parent = popup

    local pstroke = Instance.new("UIStroke")
    pstroke.Color = Color3.fromRGB(100, 100, 120)
    pstroke.Thickness = 2
    pstroke.Transparency = 0.2
    pstroke.Parent = popup

    -- Header dengan avatar
    local header = Instance.new("Frame")
    header.Parent = popup
    header.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 100)

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header

    -- Avatar besar di header
    local avatarFrame = Instance.new("ImageLabel")
    avatarFrame.Name = "Avatar"
    avatarFrame.Parent = header
    avatarFrame.BackgroundColor3 = Settings.colors.bg_light
    avatarFrame.BorderSizePixel = 0
    avatarFrame.Position = UDim2.new(0, 20, 0, 20)
    avatarFrame.Size = UDim2.new(0, 60, 0, 60)
    avatarFrame.Image = HttpUtil.get_headshot_url(player.UserId, 150)
    
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 30)
    avatarCorner.Parent = avatarFrame

    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Color = Color3.fromRGB(100, 150, 200)
    avatarStroke.Thickness = 2
    avatarStroke.Transparency = 0.3
    avatarStroke.Parent = avatarFrame

    -- Nama dan info di header
    local title = Instance.new("TextLabel")
    title.Parent = header
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -100, 0, 30)
    title.Position = UDim2.new(0, 90, 0, 20)
    title.Font = Enum.Font.GothamBold
    title.Text = player.DisplayName or player.Name
    title.TextColor3 = Settings.colors.text_primary
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left

    local userIdLabel = Instance.new("TextLabel")
    userIdLabel.Parent = header
    userIdLabel.BackgroundTransparency = 1
    userIdLabel.Size = UDim2.new(1, -100, 0, 20)
    userIdLabel.Position = UDim2.new(0, 90, 0, 50)
    userIdLabel.Font = Enum.Font.Gotham
    userIdLabel.Text = "User ID: " .. tostring(player.UserId)
    userIdLabel.TextColor3 = Settings.colors.text_tertiary
    userIdLabel.TextSize = 12
    userIdLabel.TextXAlignment = Enum.TextXAlignment.Left

    local accountAgeLabel = Instance.new("TextLabel")
    accountAgeLabel.Name = "AccountAgeLabel"
    accountAgeLabel.Parent = header
    accountAgeLabel.BackgroundTransparency = 1
    accountAgeLabel.Size = UDim2.new(1, -100, 0, 18)
    accountAgeLabel.Position = UDim2.new(0, 90, 0, 70)
    accountAgeLabel.Font = Enum.Font.Gotham
    accountAgeLabel.Text = "Memuat info..."
    accountAgeLabel.TextColor3 = Settings.colors.text_tertiary
    accountAgeLabel.TextSize = 11
    accountAgeLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Load user info
    task.spawn(function()
        local userInfo = HttpUtil.get_user_info(player.UserId)
        if userInfo and userInfo.created then
            local createdDate = DateTime.fromUnixTimestamp(userInfo.created):ToLocalTime()
            local now = DateTime.now()
            local ageDays = math.floor((now.UnixTimestamp - userInfo.created) / 86400)
            accountAgeLabel.Text = "Akun dibuat: " .. tostring(ageDays) .. " hari lalu"
        end
    end)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = header
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -40, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 40)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Settings.colors.status_off
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 22
    closeBtn.AutoButtonColor = false
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        popupGui:Destroy()
    end)

    -- Content area dengan scroll
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = popup
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.Size = UDim2.new(1, -24, 1, -120)
    scrollFrame.Position = UDim2.new(0, 12, 0, 108)
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 110)
    scrollFrame.BorderSizePixel = 0

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Parent = scrollFrame
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, 0, 0, 0)

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Parent = content
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 12)

    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
    end)

    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Parent = content
    loadingLabel.Size = UDim2.new(1, 0, 0, 40)
    loadingLabel.LayoutOrder = 0
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.Font = Enum.Font.Gotham
    loadingLabel.Text = "Memuat koneksi..."
    loadingLabel.TextColor3 = Settings.colors.text_tertiary
    loadingLabel.TextSize = 13

    task.spawn(function()
        local friends = HttpUtil.get_friends(player.UserId)
        local inMap = {}
        local currentUserIds = {}
        for _, p in ipairs(Services.Players:GetPlayers()) do
            currentUserIds[p.UserId] = true
        end
        for _, f in ipairs(friends or {}) do
            local uid = f.id
            if uid and currentUserIds[uid] then
                local other = Services.Players:GetPlayerByUserId(uid)
                if other then
                    table.insert(inMap, {id = uid, name = other.DisplayName or other.Name, player = other})
                end
            end
        end
        local koneksi5 = {}
        for i = 1, math.min(5, #(friends or {})) do
            local f = friends[i]
            table.insert(koneksi5, {id = f.id, name = f.name or f.displayName or ("User " .. tostring(f.id))})
        end

        loadingLabel.Visible = false

        local layoutOrder = 1
        
        -- Section: Koneksi di map ini
        local section1Title = Instance.new("TextLabel")
        section1Title.Parent = content
        section1Title.LayoutOrder = layoutOrder
        layoutOrder = layoutOrder + 1
        section1Title.Size = UDim2.new(1, 0, 0, 24)
        section1Title.BackgroundTransparency = 1
        section1Title.Font = Enum.Font.GothamBold
        section1Title.Text = "🔗 Koneksi di map ini (" .. #inMap .. ")"
        section1Title.TextColor3 = Settings.colors.text_primary
        section1Title.TextSize = 14
        section1Title.TextXAlignment = Enum.TextXAlignment.Left

        if #inMap == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Parent = content
            emptyLabel.LayoutOrder = layoutOrder
            layoutOrder = layoutOrder + 1
            emptyLabel.Size = UDim2.new(1, 0, 0, 30)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Font = Enum.Font.Gotham
            emptyLabel.Text = "Tidak ada koneksi di map ini."
            emptyLabel.TextColor3 = Settings.colors.text_tertiary
            emptyLabel.TextSize = 12
        else
            for _, conn in ipairs(inMap) do
                local connFrame = Instance.new("Frame")
                connFrame.Parent = content
                connFrame.LayoutOrder = layoutOrder
                layoutOrder = layoutOrder + 1
                connFrame.BackgroundColor3 = Settings.colors.bg_light
                connFrame.Size = UDim2.new(1, 0, 0, 50)
                connFrame.BorderSizePixel = 0

                local connCorner = Instance.new("UICorner")
                connCorner.CornerRadius = UDim.new(0, 6)
                connCorner.Parent = connFrame

                local connStroke = Instance.new("UIStroke")
                connStroke.Color = Color3.fromRGB(0, 130, 115)
                connStroke.Thickness = 1
                connStroke.Transparency = 0.3
                connStroke.Parent = connFrame

                local connAvatar = Instance.new("ImageLabel")
                connAvatar.Parent = connFrame
                connAvatar.BackgroundColor3 = Settings.colors.bg_medium
                connAvatar.BorderSizePixel = 0
                connAvatar.Position = UDim2.new(0, 8, 0.5, -17)
                connAvatar.Size = UDim2.new(0, 34, 0, 34)
                connAvatar.Image = HttpUtil.get_headshot_url(conn.id, 150)
                
                local connAvatarCorner = Instance.new("UICorner")
                connAvatarCorner.CornerRadius = UDim.new(0, 17)
                connAvatarCorner.Parent = connAvatar

                local connName = Instance.new("TextLabel")
                connName.Parent = connFrame
                connName.BackgroundTransparency = 1
                connName.Position = UDim2.new(0, 50, 0, 8)
                connName.Size = UDim2.new(1, -58, 0, 20)
                connName.Font = Enum.Font.GothamBold
                connName.Text = conn.name
                connName.TextColor3 = Settings.colors.text_primary
                connName.TextSize = 13
                connName.TextXAlignment = Enum.TextXAlignment.Left
                connName.TextTruncate = Enum.TextTruncate.AtEnd

                local connStatus = Instance.new("TextLabel")
                connStatus.Parent = connFrame
                connStatus.BackgroundTransparency = 1
                connStatus.Position = UDim2.new(0, 50, 0, 28)
                connStatus.Size = UDim2.new(1, -58, 0, 16)
                connStatus.Font = Enum.Font.Gotham
                connStatus.Text = "🟢 Sedang bermain"
                connStatus.TextColor3 = Settings.colors.status_on
                connStatus.TextSize = 11
                connStatus.TextXAlignment = Enum.TextXAlignment.Left
            end
        end

        -- Section: Koneksi (5)
        local section2Title = Instance.new("TextLabel")
        section2Title.Parent = content
        section2Title.LayoutOrder = layoutOrder
        layoutOrder = layoutOrder + 1
        section2Title.Size = UDim2.new(1, 0, 0, 24)
        section2Title.BackgroundTransparency = 1
        section2Title.Font = Enum.Font.GothamBold
        section2Title.Text = "👥 Koneksi lainnya (" .. #koneksi5 .. ")"
        section2Title.TextColor3 = Settings.colors.text_primary
        section2Title.TextSize = 14
        section2Title.TextXAlignment = Enum.TextXAlignment.Left

        if #koneksi5 == 0 then
            local emptyLabel2 = Instance.new("TextLabel")
            emptyLabel2.Parent = content
            emptyLabel2.LayoutOrder = layoutOrder
            layoutOrder = layoutOrder + 1
            emptyLabel2.Size = UDim2.new(1, 0, 0, 30)
            emptyLabel2.BackgroundTransparency = 1
            emptyLabel2.Font = Enum.Font.Gotham
            emptyLabel2.Text = "Tidak ada koneksi."
            emptyLabel2.TextColor3 = Settings.colors.text_tertiary
            emptyLabel2.TextSize = 12
        else
            for _, conn in ipairs(koneksi5) do
                local connFrame = Instance.new("Frame")
                connFrame.Parent = content
                connFrame.LayoutOrder = layoutOrder
                layoutOrder = layoutOrder + 1
                connFrame.BackgroundColor3 = Settings.colors.bg_light
                connFrame.Size = UDim2.new(1, 0, 0, 50)
                connFrame.BorderSizePixel = 0

                local connCorner = Instance.new("UICorner")
                connCorner.CornerRadius = UDim.new(0, 6)
                connCorner.Parent = connFrame

                local connStroke = Instance.new("UIStroke")
                connStroke.Color = Color3.fromRGB(130, 100, 0)
                connStroke.Thickness = 1
                connStroke.Transparency = 0.3
                connStroke.Parent = connFrame

                local connAvatar = Instance.new("ImageLabel")
                connAvatar.Parent = connFrame
                connAvatar.BackgroundColor3 = Settings.colors.bg_medium
                connAvatar.BorderSizePixel = 0
                connAvatar.Position = UDim2.new(0, 8, 0.5, -17)
                connAvatar.Size = UDim2.new(0, 34, 0, 34)
                connAvatar.Image = HttpUtil.get_headshot_url(conn.id, 150)
                
                local connAvatarCorner = Instance.new("UICorner")
                connAvatarCorner.CornerRadius = UDim.new(0, 17)
                connAvatarCorner.Parent = connAvatar

                local connName = Instance.new("TextLabel")
                connName.Parent = connFrame
                connName.BackgroundTransparency = 1
                connName.Position = UDim2.new(0, 50, 0, 8)
                connName.Size = UDim2.new(1, -58, 0, 20)
                connName.Font = Enum.Font.GothamBold
                connName.Text = conn.name
                connName.TextColor3 = Settings.colors.text_primary
                connName.TextSize = 13
                connName.TextXAlignment = Enum.TextXAlignment.Left
                connName.TextTruncate = Enum.TextTruncate.AtEnd

                -- Check presence
                task.spawn(function()
                    local presence = HttpUtil.get_user_presence(conn.id)
                    local connStatus = Instance.new("TextLabel")
                    connStatus.Parent = connFrame
                    connStatus.BackgroundTransparency = 1
                    connStatus.Position = UDim2.new(0, 50, 0, 28)
                    connStatus.Size = UDim2.new(1, -58, 0, 16)
                    connStatus.Font = Enum.Font.Gotham
                    connStatus.TextSize = 11
                    connStatus.TextXAlignment = Enum.TextXAlignment.Left
                    
                    if presence then
                        if presence.userPresenceType == 2 then
                            connStatus.Text = "🟢 Sedang bermain"
                            connStatus.TextColor3 = Settings.colors.status_on
                        elseif presence.userPresenceType == 1 then
                            connStatus.Text = "⚪ Online"
                            connStatus.TextColor3 = Settings.colors.text_secondary
                        else
                            connStatus.Text = "⚫ Offline"
                            connStatus.TextColor3 = Settings.colors.status_off
                        end
                    else
                        connStatus.Text = "⚫ Offline"
                        connStatus.TextColor3 = Settings.colors.status_off
                    end
                end)
            end
        end
    end)
end

-- ============================================
-- CREATE TRACKER LIST
-- ============================================

function Tracker.create(scrollContent)
    if not scrollContent then return end

    for _, child in pairs(scrollContent:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    ensure_friends_loaded(function()
        local layoutOrder = 0

        layoutOrder = 1
        section_label(scrollContent, "Koneksi kita (di map)", layoutOrder)
        layoutOrder = layoutOrder + 1
        local direct = get_direct_connections()
        for _, p in ipairs(direct) do
            create_entry(scrollContent, p, layoutOrder, true)
            layoutOrder = layoutOrder + 1
        end
        if #direct == 0 then
            local empty = Instance.new("TextLabel")
            empty.Parent = scrollContent
            empty.LayoutOrder = layoutOrder
            empty.Size = UDim2.new(1, -20, 0, 32)
            empty.BackgroundTransparency = 1
            empty.Font = Enum.Font.Gotham
            empty.Text = "Tidak ada koneksi di map ini."
            empty.TextColor3 = Settings.colors.text_tertiary
            empty.TextSize = 12
            layoutOrder = layoutOrder + 1
        end

        section_label(scrollContent, "Koneksi sama (sugest)", layoutOrder)
        layoutOrder = layoutOrder + 1
        get_shared_connections(function(shared)
            for _, p in ipairs(shared) do
                create_entry(scrollContent, p, layoutOrder, false)
                layoutOrder = layoutOrder + 1
            end
            if #shared == 0 then
                local empty = Instance.new("TextLabel")
                empty.Parent = scrollContent
                empty.LayoutOrder = layoutOrder
                empty.Size = UDim2.new(1, -20, 0, 32)
                empty.BackgroundTransparency = 1
                empty.Font = Enum.Font.Gotham
                empty.Text = "Tidak ada."
                empty.TextColor3 = Settings.colors.text_tertiary
                empty.TextSize = 12
                layoutOrder = layoutOrder + 1
            end
        end)
    end)
end

return Tracker
