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

    local infoBtn = ButtonComponent.new(playerFrame, "Info", UDim2.new(0.4, 5, 0.5, -16), function()
        Tracker.show_connection_info(player)
    end)
    infoBtn.Size = UDim2.new(0.18, -5, 0, 32)
    
    local Spectate = (Alpha and Alpha.require) and Alpha.require("player/spectate") or require(script.Parent:FindFirstChild("spectate"))
    local povBtn = ButtonComponent.new(playerFrame, "POV", UDim2.new(0.59, 5, 0.5, -16), function()
        Spectate.start(player)
    end)
    povBtn.Size = UDim2.new(0.18, -5, 0, 32)
    
    local tpBtn = ButtonComponent.new(playerFrame, "TP", UDim2.new(0.78, 5, 0.5, -16), function()
        local character = Services.LocalPlayer.Character
        local targetCharacter = player.Character
        if character and targetCharacter then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart and targetRootPart then
                humanoidRootPart.CFrame = targetRootPart.CFrame
            end
        end
    end)
    tpBtn.Size = UDim2.new(0.18, -5, 0, 32)
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
    popup.Size = UDim2.new(0, 360, 0, 400)
    popup.Position = UDim2.new(0.5, -180, 0.5, -200)
    popup.BackgroundColor3 = Settings.colors.bg_medium
    popup.BorderSizePixel = 0
    popup.Active = true
    popup.Draggable = true
    popup.ZIndex = 1

    local pcorner = Instance.new("UICorner")
    pcorner.CornerRadius = UDim.new(0, 8)
    pcorner.Parent = popup

    local pstroke = Instance.new("UIStroke")
    pstroke.Color = Color3.fromRGB(80, 85, 100)
    pstroke.Thickness = 1
    pstroke.Transparency = 0.3
    pstroke.Parent = popup

    local header = Instance.new("Frame")
    header.Parent = popup
    header.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 64)

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header

    local avatarFrame = Instance.new("ImageLabel")
    avatarFrame.Name = "Avatar"
    avatarFrame.Parent = header
    avatarFrame.BackgroundColor3 = Settings.colors.bg_light
    avatarFrame.BorderSizePixel = 0
    avatarFrame.Position = UDim2.new(0, 10, 0, 10)
    avatarFrame.Size = UDim2.new(0, 44, 0, 44)
    avatarFrame.Image = HttpUtil.get_headshot_url(player.UserId, 150)
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 22)
    avatarCorner.Parent = avatarFrame

    local title = Instance.new("TextLabel")
    title.Parent = header
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -100, 0, 22)
    title.Position = UDim2.new(0, 62, 0, 12)
    title.Font = Enum.Font.GothamBold
    title.Text = player.DisplayName or player.Name
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd

    local userIdLabel = Instance.new("TextLabel")
    userIdLabel.Parent = header
    userIdLabel.BackgroundTransparency = 1
    userIdLabel.Size = UDim2.new(1, -100, 0, 16)
    userIdLabel.Position = UDim2.new(0, 62, 0, 34)
    userIdLabel.Font = Enum.Font.Gotham
    userIdLabel.Text = "ID: " .. tostring(player.UserId)
    userIdLabel.TextColor3 = Color3.fromRGB(160, 165, 180)
    userIdLabel.TextSize = 11
    userIdLabel.TextXAlignment = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = header
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -34, 0, 8)
    closeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.AutoButtonColor = false
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        popupGui:Destroy()
    end)

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = popup
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.Size = UDim2.new(1, -24, 1, -80)
    scrollFrame.Position = UDim2.new(0, 12, 0, 70)
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 95, 105)
    scrollFrame.BorderSizePixel = 0

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Parent = scrollFrame
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, 0, 0, 0)

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Parent = content
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 8)

    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 12)
    end)

    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Parent = content
    loadingLabel.Size = UDim2.new(1, 0, 0, 28)
    loadingLabel.LayoutOrder = 0
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.Font = Enum.Font.Gotham
    loadingLabel.Text = "Memuat..."
    loadingLabel.TextColor3 = Settings.colors.text_tertiary
    loadingLabel.TextSize = 11

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
        loadingLabel.Visible = false

        local layoutOrder = 1
        
        local section1Title = Instance.new("TextLabel")
        section1Title.Parent = content
        section1Title.LayoutOrder = layoutOrder
        layoutOrder = layoutOrder + 1
        section1Title.Size = UDim2.new(1, 0, 0, 20)
        section1Title.BackgroundTransparency = 1
        section1Title.Font = Enum.Font.GothamBold
        section1Title.Text = "Koneksi di map (" .. #inMap .. ")"
        section1Title.TextColor3 = Color3.fromRGB(220, 225, 235)
        section1Title.TextSize = 12
        section1Title.TextXAlignment = Enum.TextXAlignment.Left

        if #inMap == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Parent = content
            emptyLabel.LayoutOrder = layoutOrder
            layoutOrder = layoutOrder + 1
            emptyLabel.Size = UDim2.new(1, 0, 0, 24)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Font = Enum.Font.Gotham
            emptyLabel.Text = "Tidak ada."
            emptyLabel.TextColor3 = Settings.colors.text_tertiary
            emptyLabel.TextSize = 11
        else
            for _, conn in ipairs(inMap) do
                local connFrame = Instance.new("Frame")
                connFrame.Parent = content
                connFrame.LayoutOrder = layoutOrder
                layoutOrder = layoutOrder + 1
                connFrame.BackgroundColor3 = Settings.colors.bg_light
                connFrame.Size = UDim2.new(1, 0, 0, 40)
                connFrame.BorderSizePixel = 0
                local connCorner = Instance.new("UICorner")
                connCorner.CornerRadius = UDim.new(0, 4)
                connCorner.Parent = connFrame
                local connAvatar = Instance.new("ImageLabel")
                connAvatar.Parent = connFrame
                connAvatar.BackgroundColor3 = Settings.colors.bg_medium
                connAvatar.BorderSizePixel = 0
                connAvatar.Position = UDim2.new(0, 6, 0.5, -14)
                connAvatar.Size = UDim2.new(0, 28, 0, 28)
                connAvatar.Image = HttpUtil.get_headshot_url(conn.id, 150)
                local connAvatarCorner = Instance.new("UICorner")
                connAvatarCorner.CornerRadius = UDim.new(0, 14)
                connAvatarCorner.Parent = connAvatar
                local connName = Instance.new("TextLabel")
                connName.Parent = connFrame
                connName.BackgroundTransparency = 1
                connName.Position = UDim2.new(0, 40, 0, 0)
                connName.Size = UDim2.new(1, -46, 0, 40)
                connName.Font = Enum.Font.Gotham
                connName.Text = conn.name
                connName.TextColor3 = Color3.fromRGB(255, 255, 255)
                connName.TextSize = 12
                connName.TextXAlignment = Enum.TextXAlignment.Left
                connName.TextTruncate = Enum.TextTruncate.AtEnd
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
