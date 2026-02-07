--[[
    Alpha Project - Track User
    Kompas horizontal di atas untuk mengarahkan ke user yang di-track.
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local TrackUserFeature = {}

local trackedPlayer = nil
local compassGui = nil
local updateConn = nil

local function get_direction_angle(from, to)
    if not from or not to then return 0 end
    local camera = Services.Camera
    local camCF = camera.CFrame
    local toTarget = (to - from)
    local forward = camCF.LookVector
    local right = camCF.RightVector
    local relativeRight = toTarget:Dot(right)
    local relativeForward = toTarget:Dot(forward)
    local angle = math.deg(math.atan2(relativeRight, relativeForward))
    return angle
end

local function normalize_angle(angle)
    while angle < 0 do angle = angle + 360 end
    while angle >= 360 do angle = angle - 360 end
    return angle
end

local function create_compass()
    if compassGui then compassGui:Destroy() end
    
    compassGui = Instance.new("ScreenGui")
    compassGui.Name = "AlphaTrackCompass"
    compassGui.Parent = Services.CoreGui
    compassGui.DisplayOrder = 149
    compassGui.ResetOnSpawn = false
    
    local compassBar = Instance.new("Frame")
    compassBar.Parent = compassGui
    compassBar.Size = UDim2.new(1, -40, 0, 60)
    compassBar.Position = UDim2.new(0, 20, 0, 10)
    compassBar.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    compassBar.BackgroundTransparency = 0.3
    compassBar.BorderSizePixel = 0
    
    local compassCorner = Instance.new("UICorner")
    compassCorner.CornerRadius = UDim.new(0, 8)
    compassCorner.Parent = compassBar
    
    local compassStroke = Instance.new("UIStroke")
    compassStroke.Color = Color3.fromRGB(0, 160, 145)
    compassStroke.Thickness = 2
    compassStroke.Transparency = 0.5
    compassStroke.Parent = compassBar
    
    local compassContent = Instance.new("Frame")
    compassContent.Parent = compassBar
    compassContent.Size = UDim2.new(1, -20, 1, 0)
    compassContent.Position = UDim2.new(0, 10, 0, 0)
    compassContent.BackgroundTransparency = 1
    compassContent.ClipsDescendants = true
    
    local centerIndicator = Instance.new("Frame")
    centerIndicator.Name = "CenterIndicator"
    centerIndicator.Parent = compassContent
    centerIndicator.Size = UDim2.new(0, 0, 0, 0)
    centerIndicator.BackgroundTransparency = 1
    centerIndicator.AnchorPoint = Vector2.new(0.5, 0)
    centerIndicator.Position = UDim2.new(0.5, 0, 0, 0)
    
    local triangle = Instance.new("Frame")
    triangle.Parent = centerIndicator
    triangle.Size = UDim2.new(0, 0, 0, 0)
    triangle.BackgroundTransparency = 1
    triangle.AnchorPoint = Vector2.new(0.5, 0)
    triangle.Position = UDim2.new(0.5, 0, 0, 0)
    
    local triangleShape = Instance.new("Frame")
    triangleShape.Parent = triangle
    triangleShape.Size = UDim2.new(0, 0, 0, 0)
    triangleShape.BackgroundTransparency = 1
    triangleShape.AnchorPoint = Vector2.new(0.5, 0)
    triangleShape.Position = UDim2.new(0.5, 0, 0, 0)
    
    local triangleTop = Instance.new("Frame")
    triangleTop.Parent = triangleShape
    triangleTop.Size = UDim2.new(0, 10, 0, 10)
    triangleTop.Position = UDim2.new(0.5, -5, 0, 0)
    triangleTop.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    triangleTop.BorderSizePixel = 0
    triangleTop.Rotation = 45
    
    local triangleBody = Instance.new("Frame")
    triangleBody.Parent = triangleShape
    triangleBody.Size = UDim2.new(0, 2, 0, 8)
    triangleBody.Position = UDim2.new(0.5, -1, 0, 5)
    triangleBody.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    triangleBody.BorderSizePixel = 0
    
    local markersContainer = Instance.new("Frame")
    markersContainer.Parent = compassContent
    markersContainer.Size = UDim2.new(1, 0, 1, 0)
    markersContainer.BackgroundTransparency = 1
    
    local function create_tick(x, isMajor)
        local tick = Instance.new("Frame")
        tick.Parent = markersContainer
        tick.Size = UDim2.new(0, isMajor and 2 or 1, 0, isMajor and 12 or 6)
        tick.Position = UDim2.new(0, x - (isMajor and 1 or 0.5), 0, isMajor and 0 or 6)
        tick.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        tick.BorderSizePixel = 0
        tick.BackgroundTransparency = 0.3
    end
    
    local function create_marker(text, x, isCardinal)
        local marker = Instance.new("TextLabel")
        marker.Parent = markersContainer
        marker.Size = UDim2.new(0, 30, 0, 20)
        marker.Position = UDim2.new(0, x - 15, 0, 15)
        marker.BackgroundTransparency = 1
        marker.Font = Enum.Font.GothamBold
        marker.Text = text
        marker.TextColor3 = Color3.fromRGB(255, 255, 255)
        marker.TextSize = isCardinal and 14 or 11
        marker.TextXAlignment = Enum.TextXAlignment.Center
    end
    
    local compassWidth = compassContent.AbsoluteSize.X
    local centerX = compassWidth / 2
    
    local cardinals = {
        {text = "N", angle = 0},
        {text = "NE", angle = 45},
        {text = "E", angle = 90},
        {text = "SE", angle = 135},
        {text = "S", angle = 180},
        {text = "SW", angle = 225},
        {text = "W", angle = 270},
        {text = "NW", angle = 315}
    }
    
    local degrees = {}
    for i = 0, 360, 15 do
        table.insert(degrees, i)
    end
    
    local function update_compass_display()
        if not trackedPlayer or not trackedPlayer.Character then
            triangle.Visible = false
            return
        end
        
        local hrp = trackedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            triangle.Visible = false
            return
        end
        
        local myHrp = Services.get_humanoid_root_part()
        if not myHrp then
            triangle.Visible = false
            return
        end
        
        triangle.Visible = true
        local angle = get_direction_angle(myHrp.Position, hrp.Position)
        angle = normalize_angle(angle)
        
        local camera = Services.Camera
        local camYaw = math.deg(math.atan2(-camera.CFrame.LookVector.X, -camera.CFrame.LookVector.Z))
        camYaw = normalize_angle(camYaw)
        
        local relativeAngle = normalize_angle(angle - camYaw)
        local offsetX = (relativeAngle / 360) * compassWidth
        
        if offsetX > compassWidth / 2 then
            offsetX = offsetX - compassWidth
        elseif offsetX < -compassWidth / 2 then
            offsetX = offsetX + compassWidth
        end
        
        local finalX = centerX + offsetX
        finalX = math.clamp(finalX, 0, compassWidth)
        
        triangle.Position = UDim2.new(0, finalX - 6, 0, 0)
    end
    
    local function rebuild_markers()
        markersContainer:ClearAllChildren()
        
        compassWidth = compassContent.AbsoluteSize.X
        centerX = compassWidth / 2
        
        local camera = Services.Camera
        local lookVector = camera.CFrame.LookVector
        local camYaw = math.deg(math.atan2(-lookVector.X, -lookVector.Z))
        camYaw = normalize_angle(camYaw)
        
        local visibleRange = 180
        local startAngle = normalize_angle(camYaw - visibleRange / 2)
        local endAngle = normalize_angle(camYaw + visibleRange / 2)
        
        for _, deg in ipairs(degrees) do
            local worldAngle = normalize_angle(deg)
            local relativeAngle = normalize_angle(worldAngle - camYaw)
            
            if relativeAngle > 180 then
                relativeAngle = relativeAngle - 360
            end
            
            if math.abs(relativeAngle) <= visibleRange / 2 then
                local x = centerX + (relativeAngle / visibleRange) * compassWidth
                
                local isMajor = (deg % 45 == 0)
                create_tick(x, isMajor)
                
                if isMajor then
                    local cardText = ""
                    for _, card in ipairs(cardinals) do
                        if card.angle == deg then
                            cardText = card.text
                            break
                        end
                    end
                    if cardText ~= "" then
                        create_marker(cardText, x, true)
                    end
                elseif deg % 15 == 0 then
                    create_marker(tostring(deg), x, false)
                end
            end
        end
    end
    
    local function update_compass_display()
        if not trackedPlayer or not trackedPlayer.Character then
            triangle.Visible = false
            return
        end
        
        local hrp = trackedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            triangle.Visible = false
            return
        end
        
        local myHrp = Services.get_humanoid_root_part()
        if not myHrp then
            triangle.Visible = false
            return
        end
        
        triangle.Visible = true
        local angle = get_direction_angle(myHrp.Position, hrp.Position)
        angle = normalize_angle(angle)
        
        local camera = Services.Camera
        local lookVector = camera.CFrame.LookVector
        local camYaw = math.deg(math.atan2(-lookVector.X, -lookVector.Z))
        camYaw = normalize_angle(camYaw)
        
        local relativeAngle = normalize_angle(angle - camYaw)
        if relativeAngle > 180 then
            relativeAngle = relativeAngle - 360
        end
        
        local visibleRange = 180
        local offsetX = (relativeAngle / visibleRange) * compassWidth
        local finalX = centerX + offsetX
        
        if math.abs(relativeAngle) <= visibleRange / 2 then
            finalX = math.clamp(finalX, 0, compassWidth)
            triangle.Position = UDim2.new(0, finalX - 5, 0, 0)
            triangle.Visible = true
        else
            triangle.Visible = false
        end
    end
    
    local lastRebuild = 0
    updateConn = Services.RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastRebuild > 0.05 then
            rebuild_markers()
            lastRebuild = now
        end
        if trackedPlayer then
            update_compass_display()
        end
    end)
    
    rebuild_markers()
    update_compass_display()
end

function TrackUserFeature.start(player)
    if not player then return end
    trackedPlayer = player
    Settings.features.trackedUser = player
    create_compass()
end

function TrackUserFeature.stop()
    trackedPlayer = nil
    Settings.features.trackedUser = nil
    if compassGui then compassGui:Destroy() compassGui = nil end
    if updateConn then updateConn:Disconnect() updateConn = nil end
end

function TrackUserFeature.get_tracked()
    return trackedPlayer
end

return TrackUserFeature
