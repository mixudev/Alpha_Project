--[[
    Alpha Project - Tracker
    List koneksi kita + player dengan koneksi sama (shared). Info: koneksi di map + 5 koneksi.
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))
local HttpUtil = (Alpha and Alpha.require) and Alpha.require("utils/http") or require(script.Parent.Parent:FindFirstChild("utils/http"))
local ButtonComponent = (Alpha and Alpha.require) and Alpha.require("ui/components/button") or require(script.Parent.Parent:FindFirstChild("ui/components/button"))

local Tracker = {}

local BORDER_DIRECT = Color3.fromRGB(0, 180, 165)
local BORDER_SHARED = Color3.fromRGB(180, 140, 40)
local BG_SECTION = Color3.fromRGB(28, 32, 38)
local ACCENT_CYAN = Color3.fromRGB(0, 200, 185)

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

-- Player dengan koneksi sama = di server yang punya teman yang sama dengan kita (belum teman kita)
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
-- ENTRY ROW (tampilan lebih menarik)
-- ============================================

local function create_entry(parent, player, layoutOrder, isDirect)
    local borderColor = isDirect and BORDER_DIRECT or BORDER_SHARED
    local playerFrame = Instance.new("Frame")
    playerFrame.Name = player.Name
    playerFrame.Parent = parent
    playerFrame.BackgroundColor3 = Settings.colors.bg_light
    playerFrame.Size = UDim2.new(1, -20, 0, 48)
    playerFrame.LayoutOrder = layoutOrder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = playerFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = borderColor
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = playerFrame

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Parent = playerFrame
    iconLabel.BackgroundTransparency = 1
    iconLabel.Position = UDim2.new(0, 14, 0, 0)
    iconLabel.Size = UDim2.new(0, 48, 1, 0)
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Text = isDirect and "◆" or "◇"
    iconLabel.TextColor3 = borderColor
    iconLabel.TextSize = 18
    iconLabel.TextXAlignment = Enum.TextXAlignment.Left

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = playerFrame
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 56, 0, 0)
    nameLabel.Size = UDim2.new(0.45, -60, 1, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = player.DisplayName or player.Name
    nameLabel.TextColor3 = Settings.colors.text_primary
    nameLabel.TextSize = 14
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local infoBtn = ButtonComponent.new(playerFrame, "Info", UDim2.new(0.55, 8, 0.5, -16), function()
        Tracker.show_connection_info(player)
    end)
    infoBtn.Size = UDim2.new(0.38, -16, 0, 32)
end

-- ============================================
-- SECTION CARD (header menarik)
-- ============================================

local function create_section_card(parent, title, icon, layoutOrder)
    local card = Instance.new("Frame")
    card.Name = "Section_" .. (icon or title)
    card.Parent = parent
    card.BackgroundColor3 = BG_SECTION
    card.BorderSizePixel = 0
    card.Size = UDim2.new(1, -20, 0, 44)
    card.LayoutOrder = layoutOrder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = ACCENT_CYAN
    stroke.Thickness = 1
    stroke.Transparency = 0.6
    stroke.Parent = card

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Parent = card
    iconLbl.BackgroundTransparency = 1
    iconLbl.Position = UDim2.new(0, 14, 0, 0)
    iconLbl.Size = UDim2.new(0, 32, 1, 0)
    iconLbl.Font = Enum.Font.GothamBold
    iconLbl.Text = icon or "•"
    iconLbl.TextColor3 = ACCENT_CYAN
    iconLbl.TextSize = 18
    iconLbl.TextXAlignment = Enum.TextXAlignment.Left

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Parent = card
    titleLbl.BackgroundTransparency = 1
    titleLbl.Position = UDim2.new(0, 50, 0, 0)
    titleLbl.Size = UDim2.new(1, -60, 1, 0)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = title
    titleLbl.TextColor3 = Settings.colors.text_primary
    titleLbl.TextSize = 14
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
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
    popup.Size = UDim2.new(0, 400, 0, 360)
    popup.Position = UDim2.new(0.5, -200, 0.5, -180)
    popup.BackgroundColor3 = Color3.fromRGB(24, 28, 34)
    popup.BorderSizePixel = 0
    popup.Active = true
    popup.Draggable = true
    popup.ZIndex = 1

    local pcorner = Instance.new("UICorner")
    pcorner.CornerRadius = UDim.new(0, 12)
    pcorner.Parent = popup

    local pstroke = Instance.new("UIStroke")
    pstroke.Color = ACCENT_CYAN
    pstroke.Thickness = 2
    pstroke.Transparency = 0.4
    pstroke.Parent = popup

    local header = Instance.new("Frame")
    header.Parent = popup
    header.BackgroundColor3 = Color3.fromRGB(30, 36, 44)
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 52)
    local hcorner = Instance.new("UICorner")
    hcorner.CornerRadius = UDim.new(0, 12)
    hcorner.Parent = header
    local hstroke = Instance.new("UIStroke")
    hstroke.Color = Color3.fromRGB(0, 160, 150)
    hstroke.Thickness = 1
    hstroke.Transparency = 0.6
    hstroke.Parent = header

    local title = Instance.new("TextLabel")
    title.Parent = header
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -55, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.Font = Enum.Font.GothamBold
    title.Text = "◆ " .. (player.DisplayName or player.Name)
    title.TextColor3 = Settings.colors.text_primary
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = header
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -44, 0.5, -18)
    closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
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

    local content = Instance.new("Frame")
    content.Parent = popup
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, -28, 0, 292)
    content.Position = UDim2.new(0, 14, 0, 58)

    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Parent = content
    loadingLabel.Size = UDim2.new(1, 0, 0, 36)
    loadingLabel.Position = UDim2.new(0, 0, 0, 0)
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
                    table.insert(inMap, other.DisplayName or other.Name)
                end
            end
        end
        -- Hanya 5 koneksi (bukan 10)
        local koneksi5 = {}
        for i = 1, math.min(5, #(friends or {})) do
            local f = friends[i]
            table.insert(koneksi5, f.name or f.displayName or ("User " .. tostring(f.id)))
        end

        loadingLabel.Visible = false

        local y = 0
        local function add_section(titleText, lines)
            local sect = Instance.new("TextLabel")
            sect.Parent = content
            sect.Position = UDim2.new(0, 0, 0, y)
            sect.Size = UDim2.new(1, 0, 0, 24)
            sect.BackgroundTransparency = 1
            sect.Font = Enum.Font.GothamBold
            sect.Text = titleText
            sect.TextColor3 = ACCENT_CYAN
            sect.TextSize = 13
            sect.TextXAlignment = Enum.TextXAlignment.Left
            y = y + 28
            local text = #lines > 0 and table.concat(lines, ", ") or "Tidak ada."
            local body = Instance.new("TextLabel")
            body.Parent = content
            body.Position = UDim2.new(0, 0, 0, y)
            body.Size = UDim2.new(1, 0, 0, 40)
            body.BackgroundTransparency = 1
            body.Font = Enum.Font.Gotham
            body.Text = text
            body.TextColor3 = Settings.colors.text_tertiary
            body.TextSize = 12
            body.TextXAlignment = Enum.TextXAlignment.Left
            body.TextYAlignment = Enum.TextYAlignment.Top
            body.TextWrapped = true
            body.AutomaticSize = Enum.AutomaticSize.Y
            y = y + 48
        end
        add_section("Koneksi di map ini:", inMap)
        add_section("Koneksi (5):", koneksi5)
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

        -- Section: Koneksi kita (langsung)
        layoutOrder = layoutOrder + 1
        create_section_card(scrollContent, "Koneksi kita (di map)", "◆", layoutOrder)
        local direct = get_direct_connections()
        for _, p in ipairs(direct) do
            layoutOrder = layoutOrder + 1
            create_entry(scrollContent, p, layoutOrder, true)
        end
        if #direct == 0 then
            layoutOrder = layoutOrder + 1
            local empty = Instance.new("TextLabel")
            empty.Parent = scrollContent
            empty.LayoutOrder = layoutOrder
            empty.Size = UDim2.new(1, -20, 0, 36)
            empty.BackgroundTransparency = 1
            empty.Font = Enum.Font.Gotham
            empty.Text = "Tidak ada koneksi di map ini."
            empty.TextColor3 = Settings.colors.text_tertiary
            empty.TextSize = 12
        end

        -- Section: Player dengan koneksi sama (shared)
        layoutOrder = layoutOrder + 1
        create_section_card(scrollContent, "Player dengan koneksi sama (belum teman kita)", "◇", layoutOrder)
        get_shared_connections(function(shared)
            for _, p in ipairs(shared) do
                layoutOrder = layoutOrder + 1
                create_entry(scrollContent, p, layoutOrder, false)
            end
            if #shared == 0 then
                layoutOrder = layoutOrder + 1
                local empty = Instance.new("TextLabel")
                empty.Parent = scrollContent
                empty.LayoutOrder = layoutOrder
                empty.Size = UDim2.new(1, -20, 0, 36)
                empty.BackgroundTransparency = 1
                empty.Font = Enum.Font.Gotham
                empty.Text = "Tidak ada."
                empty.TextColor3 = Settings.colors.text_tertiary
                empty.TextSize = 12
            end
        end)
    end)
end

return Tracker
