--[[
    Alpha Project - Player Info Popup
    Show detailed player information
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))
local TimeUtil = (Alpha and Alpha.require) and Alpha.require("utils/time") or require(script.Parent.Parent:FindFirstChild("utils/time"))
local HttpUtil = (Alpha and Alpha.require) and Alpha.require("utils/http") or require(script.Parent.Parent:FindFirstChild("utils/http"))

local InfoPopup = {}

-- Format umur akun dalam hari, bulan, tahun (Indonesia)
local function format_account_age_id(days)
    if not days or days < 0 then return "N/A" end
    local years = math.floor(days / 365)
    local rem = days % 365
    local months = math.floor(rem / 30)
    local dayCount = rem % 30
    local parts = {}
    if years > 0 then table.insert(parts, years .. " tahun") end
    if months > 0 then table.insert(parts, months .. " bulan") end
    table.insert(parts, dayCount .. " hari")
    return table.concat(parts, " ")
end

-- ============================================
-- SHOW PLAYER INFO
-- ============================================

function InfoPopup.show(player)
    if not player then return end
    
    local existingGui = Services.CoreGui:FindFirstChild("AlphaPlayerInfoGui")
    if existingGui then existingGui:Destroy() end
    
    local popupGui = Instance.new("ScreenGui")
    popupGui.Name = "AlphaPlayerInfoGui"
    popupGui.ResetOnSpawn = false
    popupGui.DisplayOrder = 100
    popupGui.Parent = Services.CoreGui
    
    -- ============================================
    -- MAIN POPUP FRAME (draggable, di depan menu)
    -- ============================================
    
    local popup = Instance.new("Frame")
    popup.Name = "AlphaPlayerInfo"
    popup.Parent = popupGui
    popup.Size = UDim2.new(0, 420, 0, 450)
    popup.Position = UDim2.new(0.5, -210, 0.5, -225)
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
    
    -- ============================================
    -- HEADER
    -- ============================================
    
    local header = Instance.new("Frame")
    header.Parent = popup
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 50)
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Parent = header
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.Font = Enum.Font.GothamBold
    title.Text = player.DisplayName or player.Name
    title.TextColor3 = Settings.colors.text_primary
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Parent = header
    subtitle.BackgroundTransparency = 1
    subtitle.Size = UDim2.new(1, -50, 0, 20)
    subtitle.Position = UDim2.new(0, 15, 0, 28)
    subtitle.Font = Enum.Font.Gotham
    subtitle.Text = "--- Player Information ---"
    subtitle.TextColor3 = Settings.colors.text_tertiary
    subtitle.TextSize = 12
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Close Button
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
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        pcall(function() popupGui:Destroy() end)
    end)
    
    -- ============================================
    -- CONTENT AREA
    -- ============================================
    
    local content = Instance.new("ScrollingFrame")
    content.Parent = popup
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0, 0, 0, 50)
    content.Size = UDim2.new(1, 0, 1, -50)
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 6
    content.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 110)
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local contentList = Instance.new("UIListLayout")
    contentList.Parent = content
    contentList.SortOrder = Enum.SortOrder.LayoutOrder
    contentList.Padding = UDim.new(0, 8)
    
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 15)
    contentPadding.PaddingLeft = UDim.new(0, 20)
    contentPadding.PaddingRight = UDim.new(0, 20)
    contentPadding.PaddingBottom = UDim.new(0, 15)
    contentPadding.Parent = content
    
    contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 30)
    end)
    
    -- ============================================
    -- HELPER: CREATE INFO ITEM
    -- ============================================
    
    local function create_info_item(label, value, layoutOrder)
        local item = Instance.new("Frame")
        item.Parent = content
        item.BackgroundColor3 = Settings.colors.bg_light
        item.BorderSizePixel = 0
        item.Size = UDim2.new(1, 0, 0, 36)
        item.LayoutOrder = layoutOrder
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 6)
        itemCorner.Parent = item
        
        local itemLabel = Instance.new("TextLabel")
        itemLabel.Parent = item
        itemLabel.BackgroundTransparency = 1
        itemLabel.Position = UDim2.new(0, 12, 0, 0)
        itemLabel.Size = UDim2.new(0.4, 0, 1, 0)
        itemLabel.Font = Enum.Font.Gotham
        itemLabel.Text = label
        itemLabel.TextColor3 = Settings.colors.text_tertiary
        itemLabel.TextSize = 12
        itemLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local itemValue = Instance.new("TextLabel")
        itemValue.Parent = item
        itemValue.BackgroundTransparency = 1
        itemValue.Position = UDim2.new(0.45, 0, 0, 0)
        itemValue.Size = UDim2.new(0.55, -12, 1, 0)
        itemValue.Font = Enum.Font.GothamBold
        itemValue.Text = tostring(value)
        itemValue.TextColor3 = Settings.colors.text_primary
        itemValue.TextSize = 12
        itemValue.TextXAlignment = Enum.TextXAlignment.Right
        itemValue.TextTruncate = Enum.TextTruncate.AtEnd
        
        return item
    end
    
    -- ============================================
    -- POPULATE INFO (basic + async API data)
    -- ============================================
    
    local order = 1
    create_info_item("Username", player.Name, order) order = order + 1
    create_info_item("Display Name", player.DisplayName or "N/A", order) order = order + 1
    create_info_item("User ID", tostring(player.UserId), order) order = order + 1
    create_info_item("Status", "In Game", order) order = order + 1

    -- Umur akun (hari, bulan, tahun) & tanggal daftar
    pcall(function()
        if player.AccountAge then
            create_info_item("Umur Akun", format_account_age_id(player.AccountAge), order) order = order + 1
            create_info_item("Tanggal Daftar", TimeUtil.get_first_join_date(player.AccountAge), order) order = order + 1
        end
    end)

    -- Team
    pcall(function()
        if player.Team and player.Team.Name then
            create_info_item("Team", player.Team.Name, order) order = order + 1
        end
    end)

    -- Koneksi (Friends count) - async
    task.spawn(function()
        local count = HttpUtil.get_friends_count(player.UserId)
        if count ~= nil and popup.Parent then
            create_info_item("Koneksi (Friends)", tostring(count) .. " teman", order) order = order + 1
        end
    end)

    -- Map/Game yang dibuat - async
    task.spawn(function()
        local games = HttpUtil.get_user_created_games(player.UserId, 10)
        if not popup.Parent then return end
        if games and #games > 0 then
            create_info_item("Game/Map Dibuat", tostring(#games) .. " game", order) order = order + 1
            -- Section daftar game
            local section = Instance.new("Frame")
            section.Parent = content
            section.BackgroundColor3 = Settings.colors.bg_light
            section.BorderSizePixel = 0
            section.Size = UDim2.new(1, 0, 0, 0)
            section.LayoutOrder = order
            order = order + 1
            local secCorner = Instance.new("UICorner")
            secCorner.CornerRadius = UDim.new(0, 6)
            secCorner.Parent = section
            local secTitle = Instance.new("TextLabel")
            secTitle.Parent = section
            secTitle.BackgroundTransparency = 1
            secTitle.Position = UDim2.new(0, 12, 0, 8)
            secTitle.Size = UDim2.new(1, -24, 0, 22)
            secTitle.Font = Enum.Font.GothamBold
            secTitle.Text = "🎮 Game/Map yang dibuat"
            secTitle.TextColor3 = Settings.colors.text_secondary
            secTitle.TextSize = 12
            secTitle.TextXAlignment = Enum.TextXAlignment.Left
            local list = Instance.new("Frame")
            list.Parent = section
            list.BackgroundTransparency = 1
            list.Position = UDim2.new(0, 0, 0, 34)
            list.Size = UDim2.new(1, 0, 0, 0)
            local listLayout = Instance.new("UIListLayout")
            listLayout.Parent = list
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Padding = UDim.new(0, 4)
            local listPad = Instance.new("UIPadding")
            listPad.PaddingLeft = UDim.new(0, 12)
            listPad.PaddingRight = UDim.new(0, 12)
            listPad.PaddingBottom = UDim.new(0, 8)
            listPad.Parent = list
            for i, game in ipairs(games) do
                if i > 5 then break end
                local row = Instance.new("Frame")
                row.Parent = list
                row.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
                row.BorderSizePixel = 0
                row.Size = UDim2.new(1, 0, 0, 26)
                row.LayoutOrder = i
                local rowCorner = Instance.new("UICorner")
                rowCorner.CornerRadius = UDim.new(0, 4)
                rowCorner.Parent = row
                local nameLbl = Instance.new("TextLabel")
                nameLbl.Parent = row
                nameLbl.BackgroundTransparency = 1
                nameLbl.Position = UDim2.new(0, 8, 0, 0)
                nameLbl.Size = UDim2.new(0.7, 0, 1, 0)
                nameLbl.Font = Enum.Font.Gotham
                nameLbl.Text = game.name or "Unknown"
                nameLbl.TextColor3 = Settings.colors.text_primary
                nameLbl.TextSize = 11
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                local visits = game.placeVisits or 0
                local visitsText = visits >= 1000000 and string.format("%.1fM", visits/1000000) or (visits >= 1000 and string.format("%.1fK", visits/1000) or tostring(visits))
                local visLbl = Instance.new("TextLabel")
                visLbl.Parent = row
                visLbl.BackgroundTransparency = 1
                visLbl.Position = UDim2.new(0.7, 0, 0, 0)
                visLbl.Size = UDim2.new(0.3, -8, 1, 0)
                visLbl.Font = Enum.Font.Gotham
                visLbl.Text = "▶ " .. visitsText
                visLbl.TextColor3 = Settings.colors.text_tertiary
                visLbl.TextSize = 10
                visLbl.TextXAlignment = Enum.TextXAlignment.Right
            end
            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                list.Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y)
                section.Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y + 42)
            end)
            list.Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y)
            section.Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y + 42)
        end
    end)

    print("📋 Player info opened:", player.Name)
end

return InfoPopup
