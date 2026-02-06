--[[
    Alpha Project - Connections
    Menampilkan semua koneksi online dan map yang sedang dimainkan
    Bisa undang koneksi ke map ini atau cek map yang sedang dimainkan
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))
local HttpUtil = (Alpha and Alpha.require) and Alpha.require("utils/http") or require(script.Parent.Parent:FindFirstChild("utils/http"))
local ButtonComponent = (Alpha and Alpha.require) and Alpha.require("ui/components/button") or require(script.Parent.Parent:FindFirstChild("ui/components/button"))

local Connections = {}

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

local function get_place_name(placeId)
    if not placeId or placeId == 0 then return "Unknown" end
    local success, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(placeId, Enum.InfoType.Asset)
    end)
    if success and info and info.Name then
        return info.Name
    end
    return "Place " .. tostring(placeId)
end

local function invite_to_game(userId)
    local placeId = game.PlaceId
    local jobId = game.JobId
    if placeId and placeId > 0 then
        pcall(function()
            Services.TeleportService:TeleportToPlaceInstance(placeId, jobId, Services.Players:GetPlayerByUserId(userId))
        end)
    end
end

-- ============================================
-- CREATE CONNECTION ENTRY
-- ============================================

local function create_connection_entry(parent, friendData, layoutOrder)
    local entryFrame = Instance.new("Frame")
    entryFrame.Name = "Connection_" .. tostring(friendData.id)
    entryFrame.Parent = parent
    entryFrame.BackgroundColor3 = Settings.colors.bg_light
    entryFrame.Size = UDim2.new(1, -20, 0, 60)
    entryFrame.LayoutOrder = layoutOrder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = entryFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 150, 200)
    stroke.Thickness = 1
    stroke.Transparency = 0.3
    stroke.Parent = entryFrame

    -- Avatar Icon
    local avatarFrame = Instance.new("ImageLabel")
    avatarFrame.Name = "Avatar"
    avatarFrame.Parent = entryFrame
    avatarFrame.BackgroundColor3 = Settings.colors.bg_medium
    avatarFrame.BorderSizePixel = 0
    avatarFrame.Position = UDim2.new(0, 8, 0.5, -20)
    avatarFrame.Size = UDim2.new(0, 40, 0, 40)
    avatarFrame.Image = HttpUtil.get_headshot_url(friendData.id, 150)
    
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 20)
    avatarCorner.Parent = avatarFrame

    -- Name Label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = entryFrame
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 56, 0, 8)
    nameLabel.Size = UDim2.new(0.5, -60, 0, 20)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = friendData.name or friendData.displayName or ("User " .. tostring(friendData.id))
    nameLabel.TextColor3 = Settings.colors.text_primary
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

    -- Status Label (Online/Offline)
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Parent = entryFrame
    statusLabel.BackgroundTransparency = 1
    statusLabel.Position = UDim2.new(0, 56, 0, 28)
    statusLabel.Size = UDim2.new(0.5, -60, 0, 16)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = "Memuat..."
    statusLabel.TextColor3 = Settings.colors.text_tertiary
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Map Label
    local mapLabel = Instance.new("TextLabel")
    mapLabel.Name = "MapLabel"
    mapLabel.Parent = entryFrame
    mapLabel.BackgroundTransparency = 1
    mapLabel.Position = UDim2.new(0, 56, 0, 44)
    mapLabel.Size = UDim2.new(0.5, -60, 0, 14)
    mapLabel.Font = Enum.Font.Gotham
    mapLabel.Text = ""
    mapLabel.TextColor3 = Settings.colors.text_tertiary
    mapLabel.TextSize = 10
    mapLabel.TextXAlignment = Enum.TextXAlignment.Left
    mapLabel.TextTruncate = Enum.TextTruncate.AtEnd

    -- Invite Button
    local inviteBtn = ButtonComponent.new(entryFrame, "Undang", UDim2.new(0.55, 5, 0.5, -14), function()
        invite_to_game(friendData.id)
    end)
    inviteBtn.Size = UDim2.new(0.2, -5, 0, 28)
    inviteBtn.Position = UDim2.new(0.55, 5, 0.5, -14)

    -- Check Map Button
    local checkBtn = ButtonComponent.new(entryFrame, "Cek Map", UDim2.new(0.76, 5, 0.5, -14), function()
        -- Refresh map info
        task.spawn(function()
            mapLabel.Text = "Memuat..."
            mapLabel.TextColor3 = Settings.colors.status_loading
            local presence = HttpUtil.get_user_presence(friendData.id)
            if presence then
                if presence.userPresenceType == 2 then -- InGame
                    local placeId = presence.placeId or presence.gameId
                    if placeId then
                        local placeName = get_place_name(placeId)
                        mapLabel.Text = "📍 " .. placeName
                        mapLabel.TextColor3 = Settings.colors.status_on
                    else
                        mapLabel.Text = "📍 Bermain"
                        mapLabel.TextColor3 = Settings.colors.status_on
                    end
                elseif presence.userPresenceType == 1 then -- Online
                    mapLabel.Text = "🟢 Online"
                    mapLabel.TextColor3 = Settings.colors.status_on
                else
                    mapLabel.Text = "⚫ Offline"
                    mapLabel.TextColor3 = Settings.colors.status_off
                end
            else
                mapLabel.Text = "❌ Tidak ditemukan"
                mapLabel.TextColor3 = Settings.colors.status_off
            end
        end)
    end)
    checkBtn.Size = UDim2.new(0.2, -5, 0, 28)
    checkBtn.Position = UDim2.new(0.76, 5, 0.5, -14)

    -- Load presence info
    task.spawn(function()
        local presence = HttpUtil.get_user_presence(friendData.id)
        if presence then
            if presence.userPresenceType == 2 then -- InGame
                statusLabel.Text = "🟢 Sedang bermain"
                statusLabel.TextColor3 = Settings.colors.status_on
                local placeId = presence.placeId or presence.gameId
                if placeId then
                    local placeName = get_place_name(placeId)
                    mapLabel.Text = "📍 " .. placeName
                    mapLabel.TextColor3 = Settings.colors.text_secondary
                else
                    mapLabel.Text = "📍 Bermain"
                    mapLabel.TextColor3 = Settings.colors.text_secondary
                end
            elseif presence.userPresenceType == 1 then -- Online
                statusLabel.Text = "🟢 Online"
                statusLabel.TextColor3 = Settings.colors.status_on
                mapLabel.Text = "Tidak bermain"
                mapLabel.TextColor3 = Settings.colors.text_tertiary
            else
                statusLabel.Text = "⚫ Offline"
                statusLabel.TextColor3 = Settings.colors.status_off
                mapLabel.Text = ""
            end
        else
            statusLabel.Text = "⚫ Offline"
            statusLabel.TextColor3 = Settings.colors.status_off
            mapLabel.Text = ""
        end
    end)

    return entryFrame
end

-- ============================================
-- SECTION LABEL
-- ============================================

local function section_label(parent, text, layoutOrder)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = parent
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -20, 0, 28)
    lbl.LayoutOrder = layoutOrder
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = text
    lbl.TextColor3 = Settings.colors.text_primary
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

-- ============================================
-- CREATE CONNECTIONS LIST
-- ============================================

function Connections.create(scrollContent)
    if not scrollContent then return end

    for _, child in pairs(scrollContent:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    ensure_friends_loaded(function()
        local layoutOrder = 0

        layoutOrder = layoutOrder + 1
        section_label(scrollContent, "Koneksi Online", layoutOrder)
        layoutOrder = layoutOrder + 1

        task.spawn(function()
            local friends = HttpUtil.get_friends(Services.LocalPlayer.UserId)
            
            if not friends or #friends == 0 then
                local empty = Instance.new("TextLabel")
                empty.Parent = scrollContent
                empty.LayoutOrder = layoutOrder
                empty.Size = UDim2.new(1, -20, 0, 40)
                empty.BackgroundTransparency = 1
                empty.Font = Enum.Font.Gotham
                empty.Text = "Tidak ada koneksi."
                empty.TextColor3 = Settings.colors.text_tertiary
                empty.TextSize = 12
                return
            end

            -- Tampilkan semua friends, presence akan di-load secara async di entry
            local hasOnline = false
            for _, friend in ipairs(friends) do
                if friend.id then
                    -- Buat entry untuk semua friends
                    create_connection_entry(scrollContent, friend, layoutOrder)
                    layoutOrder = layoutOrder + 1
                    hasOnline = true
                end
            end

            if not hasOnline then
                local empty = Instance.new("TextLabel")
                empty.Parent = scrollContent
                empty.LayoutOrder = layoutOrder
                empty.Size = UDim2.new(1, -20, 0, 40)
                empty.BackgroundTransparency = 1
                empty.Font = Enum.Font.Gotham
                empty.Text = "Tidak ada koneksi online."
                empty.TextColor3 = Settings.colors.text_tertiary
                empty.TextSize = 12
            end
        end)
    end)
end

return Connections
