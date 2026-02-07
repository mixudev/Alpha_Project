--[[
    Alpha Project - Track User
    Panah navigasi (kompas) di atas untuk mengarahkan ke user yang di-track.
    UI detail: username, jarak, lokasi, dll.
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local TrackUserFeature = {}

local trackedPlayer = nil
local compassGui = nil
local detailGui = nil
local updateConn = nil

local function get_distance(pos1, pos2)
    if not pos1 or not pos2 then return 0 end
    return math.floor((pos1 - pos2).Magnitude)
end

local function get_direction(from, to)
    if not from or not to then return 0 end
    local camera = Services.Camera
    local camCF = camera.CFrame
    local toTarget = (to - from)
    local toTargetCF = CFrame.lookAt(Vector3.new(0, 0, 0), toTarget)
    local relativeCF = camCF:ToObjectSpace(toTargetCF)
    local _, _, _, _, _, _, _, _, _, _, _, m12, m13 = relativeCF:GetComponents()
    local angle = math.atan2(m13, m12)
    return math.deg(angle)
end

local function create_compass()
    if compassGui then compassGui:Destroy() end
    
    compassGui = Instance.new("ScreenGui")
    compassGui.Name = "AlphaTrackCompass"
    compassGui.Parent = Services.CoreGui
    compassGui.DisplayOrder = 149
    compassGui.ResetOnSpawn = false
    
    local compassFrame = Instance.new("Frame")
    compassFrame.Parent = compassGui
    compassFrame.Size = UDim2.new(0, 200, 0, 200)
    compassFrame.Position = UDim2.new(0.5, -100, 0, 20)
    compassFrame.BackgroundTransparency = 1
    
    local compassBg = Instance.new("ImageLabel")
    compassBg.Parent = compassFrame
    compassBg.Size = UDim2.new(1, 0, 1, 0)
    compassBg.BackgroundTransparency = 1
    compassBg.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    compassBg.ImageTransparency = 1
    
    local compassCircle = Instance.new("Frame")
    compassCircle.Parent = compassFrame
    compassCircle.Size = UDim2.new(0, 180, 0, 180)
    compassCircle.Position = UDim2.new(0.5, -90, 0.5, -90)
    compassCircle.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    compassCircle.BorderSizePixel = 0
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(0, 90)
    circleCorner.Parent = compassCircle
    local circleStroke = Instance.new("UIStroke")
    circleStroke.Color = Color3.fromRGB(0, 160, 145)
    circleStroke.Thickness = 3
    circleStroke.Transparency = 0.2
    circleStroke.Parent = compassCircle
    
    local arrow = Instance.new("Frame")
    arrow.Name = "Arrow"
    arrow.Parent = compassFrame
    arrow.Size = UDim2.new(0, 0, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    arrow.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local arrowBody = Instance.new("Frame")
    arrowBody.Parent = arrow
    arrowBody.Size = UDim2.new(0, 6, 0, 50)
    arrowBody.Position = UDim2.new(0.5, -3, 0.5, -25)
    arrowBody.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    arrowBody.BorderSizePixel = 0
    local arrowBodyCorner = Instance.new("UICorner")
    arrowBodyCorner.CornerRadius = UDim.new(0, 3)
    arrowBodyCorner.Parent = arrowBody
    
    local arrowHead = Instance.new("Frame")
    arrowHead.Parent = arrow
    arrowHead.Size = UDim2.new(0, 0, 0, 0)
    arrowHead.BackgroundTransparency = 1
    arrowHead.AnchorPoint = Vector2.new(0.5, 0.5)
    arrowHead.Position = UDim2.new(0.5, 0, 0.5, -50)
    
    local arrowHead1 = Instance.new("Frame")
    arrowHead1.Parent = arrowHead
    arrowHead1.Size = UDim2.new(0, 20, 0, 20)
    arrowHead1.Position = UDim2.new(0.5, -10, 0.5, -10)
    arrowHead1.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    arrowHead1.BorderSizePixel = 0
    arrowHead1.Rotation = 45
    
    local function create_marker(text, angle)
        local marker = Instance.new("TextLabel")
        marker.Parent = compassCircle
        marker.Size = UDim2.new(0, 20, 0, 20)
        marker.BackgroundTransparency = 1
        marker.Font = Enum.Font.GothamBold
        marker.Text = text
        marker.TextColor3 = Color3.fromRGB(255, 255, 255)
        marker.TextSize = 14
        local rad = math.rad(angle)
        local radius = 70
        marker.Position = UDim2.new(0.5, math.sin(rad) * radius - 10, 0.5, -math.cos(rad) * radius - 10)
        return marker
    end
    
    create_marker("N", 0)
    create_marker("E", 90)
    create_marker("S", 180)
    create_marker("W", 270)
    
    local function update_arrow()
        if not trackedPlayer or not trackedPlayer.Character then
            arrow.Visible = false
            return
        end
        local hrp = trackedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            arrow.Visible = false
            return
        end
        local myHrp = Services.get_humanoid_root_part()
        if not myHrp then
            arrow.Visible = false
            return
        end
        
        arrow.Visible = true
        local camera = Services.Camera
        local camCF = camera.CFrame
        local toTarget = (hrp.Position - myHrp.Position)
        local forward = camCF.LookVector
        local right = camCF.RightVector
        local up = camCF.UpVector
        local relativeRight = toTarget:Dot(right)
        local relativeForward = toTarget:Dot(forward)
        local angle = math.deg(math.atan2(relativeRight, relativeForward))
        arrow.Rotation = angle
    end
    
    updateConn = Services.RunService.Heartbeat:Connect(function()
        if trackedPlayer then update_arrow() end
    end)
    
    update_arrow()
end

local function create_detail_ui()
    if detailGui then detailGui:Destroy() end
    
    detailGui = Instance.new("ScreenGui")
    detailGui.Name = "AlphaTrackDetail"
    detailGui.Parent = Services.CoreGui
    detailGui.DisplayOrder = 148
    detailGui.ResetOnSpawn = false
    
    local detailFrame = Instance.new("Frame")
    detailFrame.Parent = detailGui
    detailFrame.Size = UDim2.new(0, 320, 0, 180)
    detailFrame.Position = UDim2.new(1, -340, 0, 20)
    detailFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    detailFrame.BorderSizePixel = 0
    
    local detailCorner = Instance.new("UICorner")
    detailCorner.CornerRadius = UDim.new(0, 12)
    detailCorner.Parent = detailFrame
    
    local detailStroke = Instance.new("UIStroke")
    detailStroke.Color = Color3.fromRGB(0, 160, 145)
    detailStroke.Thickness = 2
    detailStroke.Transparency = 0.3
    detailStroke.Parent = detailFrame
    
    local header = Instance.new("Frame")
    header.Parent = detailFrame
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
    header.BorderSizePixel = 0
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = header
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "📍 Tracking User"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = header
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 11)
    closeBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 40)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.AutoButtonColor = false
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        TrackUserFeature.stop()
    end)
    
    local content = Instance.new("ScrollingFrame")
    content.Parent = detailFrame
    content.Size = UDim2.new(1, -20, 1, -60)
    content.Position = UDim2.new(0, 10, 0, 55)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Parent = content
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 8)
    
    local function create_info_row(label, value, order)
        local row = Instance.new("Frame")
        row.Parent = content
        row.LayoutOrder = order
        row.Size = UDim2.new(1, 0, 0, 24)
        row.BackgroundTransparency = 1
        
        local labelLbl = Instance.new("TextLabel")
        labelLbl.Parent = row
        labelLbl.Size = UDim2.new(0.4, 0, 1, 0)
        labelLbl.BackgroundTransparency = 1
        labelLbl.Font = Enum.Font.Gotham
        labelLbl.Text = label .. ":"
        labelLbl.TextColor3 = Color3.fromRGB(180, 185, 200)
        labelLbl.TextSize = 12
        labelLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local valueLbl = Instance.new("TextLabel")
        valueLbl.Name = "Value"
        valueLbl.Parent = row
        valueLbl.Size = UDim2.new(0.6, 0, 1, 0)
        valueLbl.Position = UDim2.new(0.4, 0, 0, 0)
        valueLbl.BackgroundTransparency = 1
        valueLbl.Font = Enum.Font.GothamBold
        valueLbl.Text = value or "—"
        valueLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueLbl.TextSize = 12
        valueLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        return valueLbl
    end
    
    local nameRow = create_info_row("Nama", "", 1)
    local userRow = create_info_row("Username", "", 2)
    local distRow = create_info_row("Jarak", "", 3)
    local posRow = create_info_row("Lokasi", "", 4)
    local healthRow = create_info_row("Health", "", 5)
    
    local function update_detail()
        if not trackedPlayer or not trackedPlayer.Character then
            nameRow.Text = "—"
            userRow.Text = "—"
            distRow.Text = "—"
            posRow.Text = "—"
            healthRow.Text = "—"
            return
        end
        
        nameRow.Text = trackedPlayer.DisplayName or trackedPlayer.Name
        userRow.Text = "@" .. trackedPlayer.Name
        
        local hrp = trackedPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHrp = Services.get_humanoid_root_part()
        if hrp and myHrp then
            local dist = get_distance(myHrp.Position, hrp.Position)
            distRow.Text = dist .. " stud"
            posRow.Text = string.format("X:%.0f Y:%.0f Z:%.0f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
        else
            distRow.Text = "—"
            posRow.Text = "—"
        end
        
        local hum = trackedPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            healthRow.Text = string.format("%.0f / %.0f", hum.Health, hum.MaxHealth)
        else
            healthRow.Text = "—"
        end
        
        content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
    end
    
    local detailUpdateConn = Services.RunService.Heartbeat:Connect(function()
        if trackedPlayer then update_detail() end
    end)
    
    update_detail()
end

function TrackUserFeature.start(player)
    if not player then return end
    trackedPlayer = player
    Settings.features.trackedUser = player
    create_compass()
    create_detail_ui()
end

function TrackUserFeature.stop()
    trackedPlayer = nil
    Settings.features.trackedUser = nil
    if compassGui then compassGui:Destroy() compassGui = nil end
    if detailGui then detailGui:Destroy() detailGui = nil end
    if updateConn then updateConn:Disconnect() updateConn = nil end
end

function TrackUserFeature.get_tracked()
    return trackedPlayer
end

return TrackUserFeature
