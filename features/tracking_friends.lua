--[[
    Alpha Project - Tracking Friends
    Scanner UI: lingkaran + avatar koneksi + garis arah. Hanya teman di map.
    Tetap scan sampai ketemu (jauh pun tetap tampil di tepi layar).
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))
local HttpUtil = (Alpha and Alpha.require) and Alpha.require("utils/http") or require(script.Parent.Parent:FindFirstChild("utils/http"))

local TrackingFriendsFeature = {}

local screenGui = nil
local indicators = {}
local updateConn = nil
local playerAddedConn = nil
local playerRemovingConn = nil
local UPDATE_INTERVAL = 0.12
local lastUpdate = 0

local CIRCLE_SIZE = 44
local LINE_THICKNESS = 2
local MARGIN = 60
local COLOR_LINE = Color3.fromRGB(0, 200, 180)
local COLOR_RING = Color3.fromRGB(0, 180, 160)

-- Icon dari folder (GitHub raw). Di Roblox strict mungkin tidak load; fallback pakai bentuk.
local SCANNER_ICON_URL = "https://raw.githubusercontent.com/mixudev/Alpha_Project/main/icon/favicon.png"

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

local function clamp_to_screen(v2, viewSize)
    local cx, cy = viewSize.X / 2, viewSize.Y / 2
    local x, y = v2.X, v2.Y
    local dx, dy = x - cx, y - cy
    if dx == 0 and dy == 0 then return Vector2.new(cx, cy) end
    local maxLen = math.min(cx, cy) - MARGIN
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= maxLen then return Vector2.new(x, y) end
    local scale = maxLen / len
    return Vector2.new(cx + dx * scale, cy + dy * scale)
end

local function create_indicator_for_friend(p, parent)
    if indicators[p] then return indicators[p] end

    local container = Instance.new("Frame")
    container.Name = "Track_" .. p.UserId
    container.Parent = parent
    container.Size = UDim2.new(0, CIRCLE_SIZE + 20, 0, CIRCLE_SIZE + 20)
    container.Position = UDim2.new(0, 0, 0, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1

    local line = Instance.new("Frame")
    line.Name = "Line"
    line.Parent = container
    line.BackgroundColor3 = COLOR_LINE
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0, 0.5)
    line.Position = UDim2.new(0, 0, 0, 0)
    line.Size = UDim2.new(0, 0, 0, LINE_THICKNESS)
    line.Rotation = 0

    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.Parent = container
    circle.Size = UDim2.new(0, CIRCLE_SIZE, 0, CIRCLE_SIZE)
    circle.Position = UDim2.new(0.5, -CIRCLE_SIZE/2, 0.5, -CIRCLE_SIZE/2)
    circle.BackgroundColor3 = Color3.fromRGB(25, 35, 33)
    circle.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLOR_RING
    stroke.Thickness = 2
    stroke.Parent = circle

    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.Parent = circle
    avatar.Size = UDim2.new(1, -6, 1, -6)
    avatar.Position = UDim2.new(0, 3, 0, 3)
    avatar.BackgroundTransparency = 1
    avatar.BorderSizePixel = 0
    avatar.Image = HttpUtil.get_headshot_url(p.UserId, 96)
    avatar.ScaleType = Enum.ScaleType.Crop

    local avCorner = Instance.new("UICorner")
    avCorner.CornerRadius = UDim.new(1, 0)
    avCorner.Parent = avatar

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Parent = container
    nameLabel.Size = UDim2.new(1, 10, 0, 18)
    nameLabel.Position = UDim2.new(0.5, 0, 0.5, CIRCLE_SIZE/2 + 4)
    nameLabel.AnchorPoint = Vector2.new(0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = p.DisplayName or p.Name
    nameLabel.TextColor3 = Color3.fromRGB(220, 255, 245)
    nameLabel.TextSize = 11
    nameLabel.TextStrokeTransparency = 0.5

    indicators[p] = { container = container, line = line, circle = circle }
    return indicators[p]
end

local function remove_indicator(p)
    if indicators[p] then
        pcall(function() indicators[p].container:Destroy() end)
        indicators[p] = nil
    end
end

local function update_indicators()
    if not screenGui or not screenGui.Parent or not Settings.features.trackingFriendsEnabled then return end
    local cam = Services.Camera
    if not cam then return end
    local viewSize = cam.ViewportSize
    local center = Vector2.new(viewSize.X / 2, viewSize.Y / 2)
    local myChar = Services.LocalPlayer and Services.LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    local friends = get_friends_in_game()
    local seen = {}
    for _, p in ipairs(friends) do
        seen[p] = true
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        local pos2d = cam:WorldToViewportPoint(hrp and hrp.Position or myHrp.Position)
        local clamped = clamp_to_screen(Vector2.new(pos2d.X, pos2d.Y), viewSize)
        local ind = create_indicator_for_friend(p, screenGui)
        ind.container.Position = UDim2.new(0, clamped.X, 0, clamped.Y)

        local dx = clamped.X - center.X
        local dy = clamped.Y - center.Y
        local len = math.sqrt(dx * dx + dy * dy)
        local angle = math.deg(math.atan2(-dy, dx)) - 90
        ind.line.Position = UDim2.new(0, center.X - clamped.X, 0, center.Y - clamped.Y)
        ind.line.Size = UDim2.new(0, math.max(0, len - CIRCLE_SIZE/2), 0, LINE_THICKNESS)
        ind.line.Rotation = angle
    end
    for p, _ in pairs(indicators) do
        if not seen[p] then
            remove_indicator(p)
        end
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

local function enable_tracking()
    Settings.features.trackingFriendsEnabled = true
    ensure_friends_loaded(function()
        if not Settings.features.trackingFriendsEnabled then return end
        if screenGui then pcall(function() screenGui:Destroy() end) end
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "AlphaTrackingFriends"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.DisplayOrder = 5
        screenGui.Parent = Services.CoreGui

        local centerRing = Instance.new("Frame")
        centerRing.Name = "ScannerCenter"
        centerRing.Parent = screenGui
        centerRing.AnchorPoint = Vector2.new(0.5, 0.5)
        centerRing.Size = UDim2.new(0, 36, 0, 36)
        centerRing.Position = UDim2.new(0.5, 0, 0.5, 0)
        centerRing.BackgroundColor3 = Color3.fromRGB(20, 35, 32)
        centerRing.BorderSizePixel = 0
        local centerCorner = Instance.new("UICorner")
        centerCorner.CornerRadius = UDim.new(1, 0)
        centerCorner.Parent = centerRing
        local centerStroke = Instance.new("UIStroke")
        centerStroke.Color = COLOR_RING
        centerStroke.Thickness = 2
        centerStroke.Parent = centerRing
        local centerIcon = Instance.new("ImageLabel")
        centerIcon.Name = "Icon"
        centerIcon.Parent = centerRing
        centerIcon.Size = UDim2.new(1, -8, 1, -8)
        centerIcon.Position = UDim2.new(0, 4, 0, 4)
        centerIcon.BackgroundTransparency = 1
        centerIcon.Image = SCANNER_ICON_URL
        centerIcon.ScaleType = Enum.ScaleType.Fit
        local centerFallback = Instance.new("TextLabel")
        centerFallback.Name = "Fallback"
        centerFallback.Parent = centerRing
        centerFallback.Size = UDim2.new(1, 0, 1, 0)
        centerFallback.BackgroundTransparency = 1
        centerFallback.Text = "◎"
        centerFallback.TextColor3 = COLOR_RING
        centerFallback.TextSize = 22
        centerFallback.Font = Enum.Font.GothamBold
        centerFallback.ZIndex = 0
        centerIcon.ZIndex = 1
        pcall(function()
            game:GetService("ContentProvider"):PreloadAsync({ centerIcon })
        end)

        lastUpdate = 0
        updateConn = Services.RunService.Heartbeat:Connect(function()
            local t = tick()
            if t - lastUpdate >= UPDATE_INTERVAL then
                lastUpdate = t
                update_indicators()
            end
        end)
        playerAddedConn = Services.Players.PlayerAdded:Connect(function()
            if Settings.features.trackingFriendsEnabled then
                ensure_friends_loaded(function() end)
            end
        end)
        playerRemovingConn = Services.Players.PlayerRemoving:Connect(function(p)
            remove_indicator(p)
        end)
        update_indicators()
    end)
end

local function disable_tracking()
    Settings.features.trackingFriendsEnabled = false
    if updateConn then updateConn:Disconnect() updateConn = nil end
    if playerAddedConn then playerAddedConn:Disconnect() playerAddedConn = nil end
    if playerRemovingConn then playerRemovingConn:Disconnect() playerRemovingConn = nil end
    for p, _ in pairs(indicators) do
        remove_indicator(p)
    end
    if screenGui then
        pcall(function() screenGui:Destroy() end)
        screenGui = nil
    end
end

function TrackingFriendsFeature.toggle(enabled)
    if enabled then
        enable_tracking()
    else
        disable_tracking()
    end
end

return TrackingFriendsFeature
