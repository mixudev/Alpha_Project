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
    popup.Size = UDim2.new(0, 400, 0, 360)
    popup.Position = UDim2.new(0.5, -200, 0.5, -180)
    popup.BackgroundColor3 = Settings.colors.bg_medium
    popup.BorderSizePixel = 0
    popup.Active = true
    popup.Draggable = true
    popup.ZIndex = 1

    local pcorner = Instance.new("UICorner")
    pcorner.CornerRadius = UDim.new(0, 10)
    pcorner.Parent = popup

    local pstroke = Instance.new("UIStroke")
    pstroke.Color = Color3.fromRGB(100, 100, 120)
    pstroke.Thickness = 1
    pstroke.Transparency = 0.3
    pstroke.Parent = popup

    local header = Instance.new("Frame")
    header.Parent = popup
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 48)

    local title = Instance.new("TextLabel")
    title.Parent = header
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.Font = Enum.Font.GothamBold
    title.Text = player.DisplayName or player.Name
    title.TextColor3 = Settings.colors.text_primary
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = header
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -16)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Settings.colors.status_off
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 20
    closeBtn.AutoButtonColor = false
    closeBtn.MouseButton1Click:Connect(function()
        popupGui:Destroy()
    end)

    local content = Instance.new("Frame")
    content.Parent = popup
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, -24, 0, 298)
    content.Position = UDim2.new(0, 12, 0, 52)

    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Parent = content
    loadingLabel.Size = UDim2.new(1, 0, 0, 30)
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
            sect.Size = UDim2.new(1, 0, 0, 22)
            sect.BackgroundTransparency = 1
            sect.Font = Enum.Font.GothamBold
            sect.Text = titleText
            sect.TextColor3 = Settings.colors.text_primary
            sect.TextSize = 13
            sect.TextXAlignment = Enum.TextXAlignment.Left
            y = y + 24
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
