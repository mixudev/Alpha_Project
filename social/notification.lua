--[[
    Alpha Project - Mutual Friend Notification
    Show popup when player dengan mutual friends join
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))
local TweenUtil = (Alpha and Alpha.require) and Alpha.require("utils/tween") or require(script.Parent.Parent:FindFirstChild("utils/tween"))
local HttpUtil = (Alpha and Alpha.require) and Alpha.require("utils/http") or require(script.Parent.Parent:FindFirstChild("utils/http"))

local Notification = {}

-- ============================================
-- SHOW NOTIFICATION
-- ============================================

function Notification.show_mutual_friend(player)
    if not player then return end
    
    local isFriend = Settings.friends.playerMutualFriends[player] == true
    if not isFriend then return end
    
    local ScreenGui = Services.CoreGui:FindFirstChild("AlphaGUI")
    if not ScreenGui then return end
    
    -- Check if already showing
    local notifName = "MutualFriendNotif_" .. player.UserId
    if ScreenGui:FindFirstChild(notifName) then return end
    
    -- ============================================
    -- MAIN NOTIFICATION FRAME
    -- ============================================
    
    local notif = Instance.new("Frame")
    notif.Name = notifName
    notif.Parent = ScreenGui
    notif.Size = UDim2.new(0, 400, 0, 100)
    notif.Position = UDim2.new(0.5, -200, 0, -120)
    notif.BackgroundColor3 = Settings.colors.bg_light
    notif.BorderSizePixel = 0
    notif.ZIndex = 100
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notif
    
    local notifStroke = Instance.new("UIStroke")
    notifStroke.Color = Settings.colors.accent_friend
    notifStroke.Thickness = 2
    notifStroke.Parent = notif
    
    -- ============================================
    -- AVATAR
    -- ============================================
    
    local avatar = Instance.new("ImageLabel")
    avatar.Parent = notif
    avatar.Size = UDim2.new(0, 60, 0, 60)
    avatar.Position = UDim2.new(0, 15, 0.5, -30)
    avatar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    avatar.BorderSizePixel = 0
    avatar.Image = HttpUtil.get_headshot_url(player.UserId)
    
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 8)
    avatarCorner.Parent = avatar
    
    -- ============================================
    -- TEXT CONTAINER
    -- ============================================
    
    local textContainer = Instance.new("Frame")
    textContainer.Parent = notif
    textContainer.BackgroundTransparency = 1
    textContainer.Position = UDim2.new(0, 85, 0, 10)
    textContainer.Size = UDim2.new(1, -95, 1, -20)
    
    -- Player Name
    local playerNameLabel = Instance.new("TextLabel")
    playerNameLabel.Parent = textContainer
    playerNameLabel.BackgroundTransparency = 1
    playerNameLabel.Size = UDim2.new(1, 0, 0, 25)
    playerNameLabel.Font = Enum.Font.GothamBold
    playerNameLabel.Text = player.DisplayName or player.Name
    playerNameLabel.TextColor3 = Settings.colors.text_primary
    playerNameLabel.TextSize = 16
    playerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    
    -- Friend Status Text
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = textContainer
    statusLabel.BackgroundTransparency = 1
    statusLabel.Position = UDim2.new(0, 0, 0, 25)
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = "🤝 Your friend"
    statusLabel.TextColor3 = Settings.colors.status_on
    statusLabel.TextSize = 13
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
    
    -- Connection Text
    local connectionLabel = Instance.new("TextLabel")
    connectionLabel.Parent = textContainer
    connectionLabel.BackgroundTransparency = 1
    connectionLabel.Position = UDim2.new(0, 0, 0, 45)
    connectionLabel.Size = UDim2.new(1, 0, 0, 20)
    connectionLabel.Font = Enum.Font.Gotham
    connectionLabel.Text = "🤝 Connected through mutual friends"
    connectionLabel.TextColor3 = Settings.colors.text_tertiary
    connectionLabel.TextSize = 11
    connectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- ============================================
    -- ANIMATION
    -- ============================================
    
    TweenUtil.position(notif, UDim2.new(0.5, -200, 0, 20), 0.5)
    
    -- Auto hide after 5 seconds
    task.delay(5, function()
        TweenUtil.position(notif, UDim2.new(0.5, -200, 0, -120), 0.3)
        task.wait(0.3)
        pcall(function() notif:Destroy() end)
    end)
    
    print("📬 Notification shown for:", player.Name)
end

return Notification
