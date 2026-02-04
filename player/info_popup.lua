--[[
    Alpha Project - Player Info Popup
    Show detailed player information
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))
local TweenUtil = (Alpha and Alpha.require) and Alpha.require("utils/tween") or require(script.Parent.Parent:FindFirstChild("utils/tween"))
local TimeUtil = (Alpha and Alpha.require) and Alpha.require("utils/time") or require(script.Parent.Parent:FindFirstChild("utils/time"))

local InfoPopup = {}

-- ============================================
-- SHOW PLAYER INFO
-- ============================================

function InfoPopup.show(player)
    if not player then return end
    
    local ScreenGui = Services.CoreGui:FindFirstChild("AlphaGUI")
    if not ScreenGui then return end
    
    -- Remove existing popup
    local existing = ScreenGui:FindFirstChild("AlphaPlayerInfo")
    if existing then existing:Destroy() end
    
    -- ============================================
    -- MAIN POPUP FRAME
    -- ============================================
    
    local popup = Instance.new("Frame")
    popup.Name = "AlphaPlayerInfo"
    popup.Parent = ScreenGui
    popup.Size = UDim2.new(0, 420, 0, 450)
    popup.Position = UDim2.new(0.5, -210, 0.5, -225)
    popup.BackgroundColor3 = Settings.colors.bg_medium
    popup.BorderSizePixel = 0
    popup.ZIndex = 20
    
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
        pcall(function() popup:Destroy() end)
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
    -- POPULATE INFO
    -- ============================================
    
    local order = 1
    create_info_item("Username", player.Name, order) order = order + 1
    create_info_item("Display Name", player.DisplayName or "N/A", order) order = order + 1
    create_info_item("User ID", tostring(player.UserId), order) order = order + 1
    create_info_item("Status", "In Game", order) order = order + 1
    
    if Settings.friends.playerMutualFriends[player] == true then
        create_info_item("Status", "🤝 Friend", order) order = order + 1
    end
    
    print("📋 Player info opened:", player.Name)
end

return InfoPopup
