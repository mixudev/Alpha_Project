-- Alpha Project - Minimalist GUI Menu
-- Local Script untuk Roblox
-- Features: Player List, Settings

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Check if HTTP is enabled
if not game:GetService("HttpService").HttpEnabled then
    warn("⚠️ HTTP Service is not enabled! Global Friend feature will not work.")
    warn("ℹ️ Enable it in Game Settings > Security > Allow HTTP Requests")
end

-- Settings State
local settings = {
    infinityJump = false,
    flyEnabled = false,
    noClipEnabled = false,
	globalFriendEnabled = false
}

local myFriends = {}  -- Menyimpan daftar teman kita
local playerMutualFriends = {}  -- Menyimpan mutual friends per player
local friendDataLoaded = false

-- Connections Storage
local connections = {}
local flyConnection
local noClipConnection

-- ============================================
-- FRIEND SYSTEM FUNCTIONS
-- ============================================

-- Fungsi untuk mendapatkan semua teman kita
local function getMyFriends()
    local success, result = pcall(function()
        local response = HttpService:JSONDecode(
            game:HttpGet("https://friends.roblox.com/v1/users/" .. LocalPlayer.UserId .. "/friends")
        )
        return response.data or {}
    end)
    
    if success then
        myFriends = {}
        for _, friend in ipairs(result) do
            myFriends[friend.id] = {
                name = friend.name,
                displayName = friend.displayName
            }
        end
        friendDataLoaded = true
        print("✅ Loaded " .. #result .. " friends")
    else
        warn("❌ Failed to load friends")
    end
end

-- Fungsi untuk mengecek mutual friends dengan player lain
local function checkMutualFriends(player)
    if not friendDataLoaded then 
        print("⚠️ Friend data not loaded yet")
        return {} 
    end
    if player == LocalPlayer then return {} end
    
    print("🔍 Checking mutual friends with:", player.Name)
    
    local mutuals = {}
    local success, result = pcall(function()
        local response = HttpService:JSONDecode(
            game:HttpGet("https://friends.roblox.com/v1/users/" .. player.UserId .. "/friends")
        )
        return response.data or {}
    end)
    
    if success then
        for _, friend in ipairs(result) do
            if myFriends[friend.id] then
                table.insert(mutuals, {
                    id = friend.id,
                    name = friend.name,
                    displayName = friend.displayName
                })
            end
        end
        print("✅ Found " .. #mutuals .. " mutual friends with " .. player.Name)
    else
        warn("❌ Failed to get friends for:", player.Name)
    end
    
    return mutuals
end

-- ============================================
-- GUI CREATION
-- ============================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AlphaGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Enabled = true
ScreenGui.Parent = CoreGui

-- PASTE FUNGSI showMutualFriendNotification DI SINI
-- Fungsi untuk menampilkan notification mutual friend
local function showMutualFriendNotification(player, mutuals)
    if #mutuals == 0 then return end
    
    -- Cek apakah sudah ada notification untuk player ini
    local notifName = "MutualFriendNotif_" .. player.UserId
    if ScreenGui:FindFirstChild(notifName) then return end
    
    -- Buat notification frame
    local notif = Instance.new("Frame")
    notif.Name = notifName
    notif.Parent = ScreenGui
    notif.Size = UDim2.new(0, 400, 0, 100)
    notif.Position = UDim2.new(0.5, -200, 0, -120)
    notif.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    notif.BorderSizePixel = 0
    notif.ZIndex = 100
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notif
    
    local notifStroke = Instance.new("UIStroke")
    notifStroke.Color = Color3.fromRGB(100, 200, 100)
    notifStroke.Thickness = 2
    notifStroke.Parent = notif
    
    -- Icon/Avatar
    local avatar = Instance.new("ImageLabel")
    avatar.Parent = notif
    avatar.Size = UDim2.new(0, 60, 0, 60)
    avatar.Position = UDim2.new(0, 15, 0.5, -30)
    avatar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    avatar.BorderSizePixel = 0
    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
    
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 8)
    avatarCorner.Parent = avatar
    
    -- Text info
    local textContainer = Instance.new("Frame")
    textContainer.Parent = notif
    textContainer.BackgroundTransparency = 1
    textContainer.Position = UDim2.new(0, 85, 0, 10)
    textContainer.Size = UDim2.new(1, -95, 1, -20)
    
    local playerNameLabel = Instance.new("TextLabel")
    playerNameLabel.Parent = textContainer
    playerNameLabel.BackgroundTransparency = 1
    playerNameLabel.Size = UDim2.new(1, 0, 0, 25)
    playerNameLabel.Font = Enum.Font.GothamBold
    playerNameLabel.Text = player.DisplayName or player.Name
    playerNameLabel.TextColor3 = Color3.fromRGB(240, 240, 250)
    playerNameLabel.TextSize = 16
    playerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    
    local mutualText = "Mutual friend: " .. (mutuals[1].displayName or mutuals[1].name)
    if #mutuals > 1 then
        mutualText = mutualText .. " +" .. (#mutuals - 1) .. " more"
    end
    
    local mutualLabel = Instance.new("TextLabel")
    mutualLabel.Parent = textContainer
    mutualLabel.BackgroundTransparency = 1
    mutualLabel.Position = UDim2.new(0, 0, 0, 25)
    mutualLabel.Size = UDim2.new(1, 0, 0, 20)
    mutualLabel.Font = Enum.Font.Gotham
    mutualLabel.Text = mutualText
    mutualLabel.TextColor3 = Color3.fromRGB(150, 200, 150)
    mutualLabel.TextSize = 13
    mutualLabel.TextXAlignment = Enum.TextXAlignment.Left
    mutualLabel.TextTruncate = Enum.TextTruncate.AtEnd
    
    local connectionLabel = Instance.new("TextLabel")
    connectionLabel.Parent = textContainer
    connectionLabel.BackgroundTransparency = 1
    connectionLabel.Position = UDim2.new(0, 0, 0, 45)
    connectionLabel.Size = UDim2.new(1, 0, 0, 20)
    connectionLabel.Font = Enum.Font.Gotham
    connectionLabel.Text = "🤝 Connected through mutual friends"
    connectionLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    connectionLabel.TextSize = 11
    connectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Animasi masuk
    TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -200, 0, 20)
    }):Play()
    
    -- Auto hide setelah 5 detik
    task.delay(5, function()
        TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -200, 0, -120)
        }):Play()
        
        task.wait(0.3)
        pcall(function() notif:Destroy() end)
    end)
end

-- Main Container (Minimalist)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 500, 0, 400)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 6)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 100, 120)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.5
mainStroke.Parent = MainFrame

-- Title Bar (Minimalist)
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 40)

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 6)
titleBarCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = TitleBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.Size = UDim2.new(0.5, 0, 1, 0)
TitleLabel.Font = Enum.Font.Gotham
TitleLabel.Text = "Alpha Project"
TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = TitleBar
MinimizeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Position = UDim2.new(1, -60, 0.5, -10)
MinimizeButton.Size = UDim2.new(0, 22, 0, 22)
MinimizeButton.Font = Enum.Font.Gotham
MinimizeButton.Text = "─"
MinimizeButton.TextColor3 = Color3.fromRGB(200, 200, 210)
MinimizeButton.TextSize = 14
MinimizeButton.AutoButtonColor = false

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = MinimizeButton

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = TitleBar
CloseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(1, -30, 0.5, -10)
CloseButton.Size = UDim2.new(0, 22, 0, 22)
CloseButton.Font = Enum.Font.Gotham
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(220, 120, 120)
CloseButton.TextSize = 16
CloseButton.AutoButtonColor = false

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = CloseButton

-- Content Area with Sidebar
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = MainFrame
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 0, 0, 40)
ContentContainer.Size = UDim2.new(1, 0, 1, -40)

-- Sidebar (Minimalist)
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Parent = ContentContainer
Sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Sidebar.BorderSizePixel = 0
Sidebar.Size = UDim2.new(0, 140, 1, 0)

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 6)
sidebarCorner.Parent = Sidebar

local SidebarList = Instance.new("UIListLayout")
SidebarList.Parent = Sidebar
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Padding = UDim.new(0, 4)

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 8)
SidebarPadding.PaddingLeft = UDim.new(0, 8)
SidebarPadding.PaddingRight = UDim.new(0, 8)
SidebarPadding.Parent = Sidebar

-- Main Content Area
local MainContent = Instance.new("Frame")
MainContent.Name = "MainContent"
MainContent.Parent = ContentContainer
MainContent.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainContent.BorderSizePixel = 0
MainContent.Position = UDim2.new(0, 140, 0, 0)
MainContent.Size = UDim2.new(1, -140, 1, 0)

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 6)
contentCorner.Parent = MainContent

-- Sidebar Navigation Buttons (Minimalist)
local function createNavButton(text, icon, layoutOrder, callback)
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.Parent = Sidebar
    button.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    button.BorderSizePixel = 0
    button.Size = UDim2.new(1, 0, 0, 40)
    button.Font = Enum.Font.Gotham
    button.Text = icon .. "  " .. text
    button.TextColor3 = Color3.fromRGB(180, 180, 190)
    button.TextSize = 13
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.AutoButtonColor = false
    button.LayoutOrder = layoutOrder
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.Parent = button
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    button.MouseEnter:Connect(function()
        if not button:GetAttribute("Active") then
            TweenService:Create(button, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(28, 28, 35)
            }):Play()
        end
    end)
    
    button.MouseLeave:Connect(function()
        if not button:GetAttribute("Active") then
            TweenService:Create(button, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(22, 22, 28)
            }):Play()
        end
    end)
    
    button.MouseButton1Click:Connect(function()
        -- Deactivate all buttons
        for _, child in pairs(Sidebar:GetChildren()) do
            if child:IsA("TextButton") and child:GetAttribute("Active") then
                child:SetAttribute("Active", false)
                TweenService:Create(child, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromRGB(22, 22, 28)
                }):Play()
                child.TextColor3 = Color3.fromRGB(180, 180, 190)
            end
        end
        
        -- Activate clicked button
        button:SetAttribute("Active", true)
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        }):Play()
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        callback()
    end)
    
    return button
end

-- Content Pages
local currentPage = nil
local function showPage(page)
    if currentPage then
        currentPage.Visible = false
    end
    currentPage = page
    if page then
        page.Visible = true
    end
end

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Parent = MainContent
    page.BackgroundTransparency = 1
    page.Size = UDim2.new(1, 0, 1, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 6
    page.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 110)
    page.BorderSizePixel = 0
    page.Visible = false
    
    local pageList = Instance.new("UIListLayout")
    pageList.Parent = page
    pageList.SortOrder = Enum.SortOrder.LayoutOrder
    pageList.Padding = UDim.new(0, 10)
    
    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingTop = UDim.new(0, 15)
    pagePadding.PaddingLeft = UDim.new(0, 15)
    pagePadding.PaddingRight = UDim.new(0, 15)
    pagePadding.PaddingBottom = UDim.new(0, 15)
    pagePadding.Parent = page
    
    pageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pageList.AbsoluteContentSize.Y + 30)
    end)
    
    return page
end

-- Helper function to create toggle (Minimalist)
local function createToggle(parent, text, position, callback)
    local toggle = Instance.new("TextButton")
    toggle.Name = text .. "Toggle"
    toggle.Parent = parent
    toggle.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    toggle.BorderSizePixel = 0
    toggle.Size = UDim2.new(1, -20, 0, 42)
    toggle.Font = Enum.Font.Gotham
    toggle.Text = ""
    toggle.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = toggle
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Parent = toggle
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Parent = toggle
    status.BackgroundTransparency = 1
    status.Position = UDim2.new(0.7, 0, 0, 0)
    status.Size = UDim2.new(0.3, -15, 1, 0)
    status.Font = Enum.Font.Gotham
    status.Text = "OFF"
    status.TextColor3 = Color3.fromRGB(180, 120, 120)
    status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Right
    
    local isEnabled = false
    toggle.MouseEnter:Connect(function()
        TweenService:Create(toggle, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        }):Play()
    end)
    
    toggle.MouseLeave:Connect(function()
        TweenService:Create(toggle, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(25, 25, 32)
        }):Play()
    end)
    
    toggle.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        status.Text = isEnabled and "ON" or "OFF"
        status.TextColor3 = isEnabled and Color3.fromRGB(120, 200, 150) or Color3.fromRGB(180, 120, 120)
        callback(isEnabled)
    end)
    
    return toggle, status
end

-- Helper function to create button (Minimalist)
local function createButton(parent, text, position, callback)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    button.BorderSizePixel = 0
    button.Position = position
    button.Size = UDim2.new(0, 0, 0, 32)
    button.Font = Enum.Font.Gotham
    button.Text = text
    button.TextColor3 = Color3.fromRGB(240, 240, 250)
    button.TextSize = 12
    button.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        }):Play()
    end)
    
    button.MouseButton1Click:Connect(callback)
    
    return button
end

-- Helper function to create section header (Minimalist)
local function createSectionHeader(parent, text, layoutOrder)
    local header = Instance.new("TextLabel")
    header.Parent = parent
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, -20, 0, 28)
    header.Font = Enum.Font.Gotham
    header.Text = text
    header.TextColor3 = Color3.fromRGB(200, 200, 210)
    header.TextSize = 13
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.LayoutOrder = layoutOrder
    
    return header
end

-- ============================================
-- PLAYER LIST PAGE
-- ============================================

local playerPage = createPage("Player")
local playerScrollContent = Instance.new("Frame")
playerScrollContent.Name = "PlayerScrollContent"
playerScrollContent.Parent = playerPage
playerScrollContent.BackgroundTransparency = 1
playerScrollContent.Size = UDim2.new(1, 0, 0, 0)

-- Spectating variables
local spectatingPlayer = nil
local spectateConnection = nil

-- Player join time tracking (for "time on map")
local playerJoinTimes = {}
for _, p in ipairs(Players:GetPlayers()) do
    playerJoinTimes[p] = tick()
end
Players.PlayerAdded:Connect(function(p)
    playerJoinTimes[p] = tick()
	-- Check mutual friends jika Global Friend aktif
    if settings.globalFriendEnabled and friendDataLoaded and p ~= LocalPlayer then
        spawn(function()
            task.wait(1)  -- Tunggu sebentar
            local mutuals = checkMutualFriends(p)
            playerMutualFriends[p] = mutuals
            
            if #mutuals > 0 then
                showMutualFriendNotification(p, mutuals)
            end
            
            -- Refresh player list jika sedang dibuka
            if currentPage == playerPage and playerPage.Visible then
                updatePlayerList()
            end
        end)
    end
end)
Players.PlayerRemoving:Connect(function(p)
    playerJoinTimes[p] = nil
	playerMutualFriends[p] = nil
end)

local function stopSpectating()
    spectatingPlayer = nil
    -- Disconnect any running spectate updater
    if spectateConnection then
        spectateConnection:Disconnect()
        spectateConnection = nil
    end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        Camera.CameraType = Enum.CameraType.Custom
        Camera.CameraSubject = LocalPlayer.Character.Humanoid
    end
end

local playerList = Instance.new("UIListLayout")
playerList.Parent = playerScrollContent
playerList.SortOrder = Enum.SortOrder.LayoutOrder
playerList.Padding = UDim.new(0, 8)

playerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    playerScrollContent.Size = UDim2.new(1, 0, 0, playerList.AbsoluteContentSize.Y)
end)

local function updatePlayerList()
    for _, child in pairs(playerScrollContent:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Back to Self button (Minimalist)
    local backFrame = Instance.new("Frame")
    backFrame.Parent = playerScrollContent
    backFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    backFrame.Size = UDim2.new(1, -20, 0, 36)
    backFrame.LayoutOrder = 0
    
    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(0, 4)
    backCorner.Parent = backFrame
    
    local backBtn = Instance.new("TextButton")
    backBtn.Parent = backFrame
    backBtn.BackgroundTransparency = 1
    backBtn.Size = UDim2.new(1, 0, 1, 0)
    backBtn.Font = Enum.Font.Gotham
    backBtn.Text = "🔙 Back to Self"
    backBtn.TextColor3 = Color3.fromRGB(240, 240, 250)
    backBtn.TextSize = 13
    backBtn.MouseButton1Click:Connect(function()
        stopSpectating()
    end)
    
    local players = Players:GetPlayers()
    local myPos = nil
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        myPos = LocalPlayer.Character.HumanoidRootPart.Position
    end
    
    for i, player in ipairs(players) do
        if player ~= LocalPlayer then
            local playerFrame = Instance.new("Frame")
            playerFrame.Name = player.Name
            playerFrame.Parent = playerScrollContent
            playerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
            playerFrame.Size = UDim2.new(1, -20, 0, 42)
            playerFrame.LayoutOrder = i
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = playerFrame

			local hasMutual = playerMutualFriends[player] and #playerMutualFriends[player] > 0
			if hasMutual and settings.globalFriendEnabled then
				local mutualStroke = Instance.new("UIStroke")
				mutualStroke.Color = Color3.fromRGB(100, 200, 100)
				mutualStroke.Thickness = 2
				mutualStroke.Transparency = 0
				mutualStroke.Parent = playerFrame
			end
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Parent = playerFrame
            nameLabel.BackgroundTransparency = 1
            nameLabel.Position = UDim2.new(0, 12, 0, 0)
            nameLabel.Size = UDim2.new(0.35, 0, 1, 0)
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.Text = player.DisplayName or player.Name
            nameLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
            nameLabel.TextSize = 13
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            -- Info Button (shows details about player) - Sebelah kiri POV
            local infoBtn = createButton(playerFrame, "- Info -", UDim2.new(0.37, 5, 0.5, -16), function()
                -- Popup
                local popupName = "AlphaPlayerInfo"
                local existing = ScreenGui:FindFirstChild(popupName)
                if existing then existing:Destroy() end

                -- Main Popup Frame
                local popup = Instance.new("Frame")
                popup.Name = popupName
                popup.Parent = ScreenGui
                popup.Size = UDim2.new(0, 420, 0, 450) -- Lebih besar untuk menampung data
                popup.Position = UDim2.new(0.5, -210, 0.5, -225) -- Sesuaikan posisi
                popup.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
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

                -- Header Bar
                local header = Instance.new("Frame")
                header.Parent = popup
                header.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
                header.BorderSizePixel = 0
                header.Size = UDim2.new(1, 0, 0, 50)
                
                local headerCorner = Instance.new("UICorner")
                headerCorner.CornerRadius = UDim.new(0, 10)
                headerCorner.Parent = header

                local headerStroke = Instance.new("UIStroke")
                headerStroke.Color = Color3.fromRGB(60, 60, 80)
                headerStroke.Thickness = 1
                headerStroke.Transparency = 0.5
                headerStroke.Parent = header

                -- Title
                local title = Instance.new("TextLabel")
                title.Parent = header
                title.BackgroundTransparency = 1
                title.Size = UDim2.new(1, -50, 1, 0)
                title.Position = UDim2.new(0, 15, 0, 0)
                title.Font = Enum.Font.GothamBold
                title.Text = player.DisplayName or player.Name
                title.TextColor3 = Color3.fromRGB(240, 240, 250)
                title.TextSize = 16
                title.TextXAlignment = Enum.TextXAlignment.Left

                -- Player Name Subtitle
                local subtitle = Instance.new("TextLabel")
                subtitle.Parent = header
                subtitle.BackgroundTransparency = 1
                subtitle.Size = UDim2.new(1, -50, 0, 20)
                subtitle.Position = UDim2.new(0, 15, 0, 28)
                subtitle.Font = Enum.Font.Gotham
                subtitle.Text = "---  Player Information  ---"
                subtitle.TextColor3 = Color3.fromRGB(180, 180, 200)
                subtitle.TextSize = 12
                subtitle.TextXAlignment = Enum.TextXAlignment.Left

                -- Close Button
                local close = Instance.new("TextButton")
                close.Parent = header
                close.Size = UDim2.new(0, 32, 0, 32)
                close.Position = UDim2.new(1, -40, 0.5, -16)
                close.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                close.BorderSizePixel = 0
                close.Text = "×"
                close.TextColor3 = Color3.fromRGB(240, 140, 140)
                close.Font = Enum.Font.GothamBold
                close.TextSize = 20
                close.AutoButtonColor = false
                
                local closeCorner = Instance.new("UICorner")
                closeCorner.CornerRadius = UDim.new(0, 6)
                closeCorner.Parent = close

                close.MouseEnter:Connect(function()
                    TweenService:Create(close, TweenInfo.new(0.15), {
                        BackgroundColor3 = Color3.fromRGB(50, 35, 35)
                    }):Play()
                end)
                
                close.MouseLeave:Connect(function()
                    TweenService:Create(close, TweenInfo.new(0.15), {
                        BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                    }):Play()
                end)
                
                close.MouseButton1Click:Connect(function()
                    pcall(function() popup:Destroy() end)
                end)

                -- Content Area
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

                -- Info Items Container
                local infoContainer = Instance.new("Frame")
                infoContainer.Parent = content
                infoContainer.BackgroundTransparency = 1
                infoContainer.Size = UDim2.new(1, 0, 0, 0)
                infoContainer.LayoutOrder = 1

                local infoList = Instance.new("UIListLayout")
                infoList.Parent = infoContainer
                infoList.SortOrder = Enum.SortOrder.LayoutOrder
                infoList.Padding = UDim.new(0, 10)

                infoList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    infoContainer.Size = UDim2.new(1, 0, 0, infoList.AbsoluteContentSize.Y)
                end)

                -- Function to create info item
                local function createInfoItem(label, value, layoutOrder)
                    local item = Instance.new("Frame")
                    item.Parent = infoContainer
                    item.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
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
                    itemLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
                    itemLabel.TextSize = 12
                    itemLabel.TextXAlignment = Enum.TextXAlignment.Left

                    local itemValue = Instance.new("TextLabel")
                    itemValue.Parent = item
                    itemValue.BackgroundTransparency = 1
                    itemValue.Position = UDim2.new(0.45, 0, 0, 0)
                    itemValue.Size = UDim2.new(0.55, -12, 1, 0)
                    itemValue.Font = Enum.Font.GothamBold
                    itemValue.Text = value
                    itemValue.TextColor3 = Color3.fromRGB(240, 240, 250)
                    itemValue.TextSize = 12
                    itemValue.TextXAlignment = Enum.TextXAlignment.Right

                    return item
                end

                -- Function to format account age
                local function formatAccountAge(days)
                    if not days or days < 0 then return "N/A" end
                    
                    local years = math.floor(days / 365)
                    local remainingAfterYears = days % 365
                    local months = math.floor(remainingAfterYears / 30)
                    local remainingDays = remainingAfterYears % 30
                    
                    local parts = {}
                    if years > 0 then
                        table.insert(parts, years .. (years == 1 and " year" or " years"))
                    end
                    if months > 0 then
                        table.insert(parts, months .. (months == 1 and " month" or " months"))
                    end
                    if remainingDays > 0 or #parts == 0 then
                        table.insert(parts, remainingDays .. (remainingDays == 1 and " day" or " days"))
                    end
                    
                    return table.concat(parts, " ")
                end
                
                -- Function to get first join date
                local function getFirstJoinDate(accountAgeDays)
                    if not accountAgeDays then return "N/A" end
                    local currentTime = os.time()
                    local joinTimestamp = currentTime - (accountAgeDays * 86400) -- 86400 seconds in a day
                    local joinDate = os.date("%d/%m/%Y", joinTimestamp)
                    return joinDate
                end

                -- Fill info
                spawn(function()
                    local order = 1
                    createInfoItem("Username", player.Name, order) order = order + 1
                    createInfoItem("Display Name", player.DisplayName or "N/A", order) order = order + 1
                    createInfoItem("User ID", tostring(player.UserId), order) order = order + 1

                    -- Get Friends Count
                    spawn(function()
                        pcall(function()
                            local success, friendsData = pcall(function()
                                return HttpService:JSONDecode(
                                    game:HttpGet("https://friends.roblox.com/v1/users/" .. player.UserId .. "/friends/count")
                                )
                            end)
                            
                            if success and friendsData and friendsData.count then
                                createInfoItem("Friends", tostring(friendsData.count) .. " friends", order)
                                order = order + 1
                            end
                        end)
                    end)

                    -- Get Created Games
                    spawn(function()
                        pcall(function()
                            local success, gamesData = pcall(function()
                                return HttpService:JSONDecode(
                                    game:HttpGet("https://games.roblox.com/v2/users/" .. player.UserId .. "/games?accessFilter=2&limit=10&sortOrder=Asc")
                                )
                            end)
                            
                            if success and gamesData and gamesData.data then
                                local gameCount = #gamesData.data
                                createInfoItem("Created Games", tostring(gameCount) .. " games", order)
                                order = order + 1
                                
                                -- Jika ada games, tampilkan list games
                                if gameCount > 0 then
                                    -- Create games list section
                                    local gamesSection = Instance.new("Frame")
                                    gamesSection.Parent = content
                                    gamesSection.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
                                    gamesSection.BorderSizePixel = 0
                                    gamesSection.Size = UDim2.new(1, 0, 0, 0)
                                    gamesSection.LayoutOrder = order
                                    order = order + 1
                                    
                                    local gamesSectionCorner = Instance.new("UICorner")
                                    gamesSectionCorner.CornerRadius = UDim.new(0, 6)
                                    gamesSectionCorner.Parent = gamesSection
                                    
                                    local gamesHeader = Instance.new("TextLabel")
                                    gamesHeader.Parent = gamesSection
                                    gamesHeader.BackgroundTransparency = 1
                                    gamesHeader.Position = UDim2.new(0, 12, 0, 8)
                                    gamesHeader.Size = UDim2.new(1, -24, 0, 24)
                                    gamesHeader.Font = Enum.Font.GothamBold
                                    gamesHeader.Text = "🎮 Created Games"
                                    gamesHeader.TextColor3 = Color3.fromRGB(200, 200, 210)
                                    gamesHeader.TextSize = 12
                                    gamesHeader.TextXAlignment = Enum.TextXAlignment.Left
                                    
                                    local gamesList = Instance.new("Frame")
                                    gamesList.Parent = gamesSection
                                    gamesList.BackgroundTransparency = 1
                                    gamesList.Position = UDim2.new(0, 0, 0, 32)
                                    gamesList.Size = UDim2.new(1, 0, 0, 0)
                                    
                                    local gamesListLayout = Instance.new("UIListLayout")
                                    gamesListLayout.Parent = gamesList
                                    gamesListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                                    gamesListLayout.Padding = UDim.new(0, 4)
                                    
                                    local gamesListPadding = Instance.new("UIPadding")
                                    gamesListPadding.PaddingLeft = UDim.new(0, 12)
                                    gamesListPadding.PaddingRight = UDim.new(0, 12)
                                    gamesListPadding.PaddingBottom = UDim.new(0, 8)
                                    gamesListPadding.Parent = gamesList
                                    
                                    -- Add each game
                                    for i, game in ipairs(gamesData.data) do
                                        if i <= 5 then -- Limit to 5 games
                                            local gameItem = Instance.new("Frame")
                                            gameItem.Parent = gamesList
                                            gameItem.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
                                            gameItem.BorderSizePixel = 0
                                            gameItem.Size = UDim2.new(1, 0, 0, 28)
                                            
                                            local gameItemCorner = Instance.new("UICorner")
                                            gameItemCorner.CornerRadius = UDim.new(0, 4)
                                            gameItemCorner.Parent = gameItem
                                            
                                            local gameName = Instance.new("TextLabel")
                                            gameName.Parent = gameItem
                                            gameName.BackgroundTransparency = 1
                                            gameName.Position = UDim2.new(0, 8, 0, 0)
                                            gameName.Size = UDim2.new(0.7, 0, 1, 0)
                                            gameName.Font = Enum.Font.Gotham
                                            gameName.Text = game.name or "Unknown Game"
                                            gameName.TextColor3 = Color3.fromRGB(220, 220, 230)
                                            gameName.TextSize = 11
                                            gameName.TextXAlignment = Enum.TextXAlignment.Left
                                            gameName.TextTruncate = Enum.TextTruncate.AtEnd
                                            
                                            local gamePlays = Instance.new("TextLabel")
                                            gamePlays.Parent = gameItem
                                            gamePlays.BackgroundTransparency = 1
                                            gamePlays.Position = UDim2.new(0.7, 0, 0, 0)
                                            gamePlays.Size = UDim2.new(0.3, -8, 1, 0)
                                            gamePlays.Font = Enum.Font.Gotham
                                            
                                            -- Format play count
                                            local plays = game.placeVisits or 0
                                            local playsText = ""
                                            if plays >= 1000000 then
                                                playsText = string.format("%.1fM", plays / 1000000)
                                            elseif plays >= 1000 then
                                                playsText = string.format("%.1fK", plays / 1000)
                                            else
                                                playsText = tostring(plays)
                                            end
                                            
                                            gamePlays.Text = "▶ " .. playsText
                                            gamePlays.TextColor3 = Color3.fromRGB(150, 150, 170)
                                            gamePlays.TextSize = 10
                                            gamePlays.TextXAlignment = Enum.TextXAlignment.Right
                                        end
                                    end
                                    
                                    gamesListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                                        gamesList.Size = UDim2.new(1, 0, 0, gamesListLayout.AbsoluteContentSize.Y)
                                        gamesSection.Size = UDim2.new(1, 0, 0, gamesListLayout.AbsoluteContentSize.Y + 40)
                                    end)
                                end
                            end
                        end)
                    end)

					-- Mutual Friends Section
					if settings.globalFriendEnabled and playerMutualFriends[player] and #playerMutualFriends[player] > 0 then
						local mutuals = playerMutualFriends[player]
						
						createInfoItem("Mutual Friends", tostring(#mutuals) .. " connection" .. (#mutuals > 1 and "s" or ""), order)
						order = order + 1
						
						-- Mutual friends list section
						local mutualSection = Instance.new("Frame")
						mutualSection.Parent = content
						mutualSection.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
						mutualSection.BorderSizePixel = 0
						mutualSection.Size = UDim2.new(1, 0, 0, 0)
						mutualSection.LayoutOrder = order
						order = order + 1
						
						local mutualSectionCorner = Instance.new("UICorner")
						mutualSectionCorner.CornerRadius = UDim.new(0, 6)
						mutualSectionCorner.Parent = mutualSection
						
						local mutualHeader = Instance.new("TextLabel")
						mutualHeader.Parent = mutualSection
						mutualHeader.BackgroundTransparency = 1
						mutualHeader.Position = UDim2.new(0, 12, 0, 8)
						mutualHeader.Size = UDim2.new(1, -24, 0, 24)
						mutualHeader.Font = Enum.Font.GothamBold
						mutualHeader.Text = "🤝 Mutual Friends"
						mutualHeader.TextColor3 = Color3.fromRGB(150, 200, 150)
						mutualHeader.TextSize = 12
						mutualHeader.TextXAlignment = Enum.TextXAlignment.Left
						
						local mutualList = Instance.new("Frame")
						mutualList.Parent = mutualSection
						mutualList.BackgroundTransparency = 1
						mutualList.Position = UDim2.new(0, 0, 0, 32)
						mutualList.Size = UDim2.new(1, 0, 0, 0)
						
						local mutualListLayout = Instance.new("UIListLayout")
						mutualListLayout.Parent = mutualList
						mutualListLayout.SortOrder = Enum.SortOrder.LayoutOrder
						mutualListLayout.Padding = UDim.new(0, 4)
						
						local mutualListPadding = Instance.new("UIPadding")
						mutualListPadding.PaddingLeft = UDim.new(0, 12)
						mutualListPadding.PaddingRight = UDim.new(0, 12)
						mutualListPadding.PaddingBottom = UDim.new(0, 8)
						mutualListPadding.Parent = mutualList
						
						-- Add each mutual friend
						for idx, mutual in ipairs(mutuals) do
							if idx <= 10 then  -- Limit to 10
								local mutualItem = Instance.new("Frame")
								mutualItem.Parent = mutualList
								mutualItem.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
								mutualItem.BorderSizePixel = 0
								mutualItem.Size = UDim2.new(1, 0, 0, 28)
								
								local mutualItemCorner = Instance.new("UICorner")
								mutualItemCorner.CornerRadius = UDim.new(0, 4)
								mutualItemCorner.Parent = mutualItem
								
								local mutualName = Instance.new("TextLabel")
								mutualName.Parent = mutualItem
								mutualName.BackgroundTransparency = 1
								mutualName.Position = UDim2.new(0, 8, 0, 0)
								mutualName.Size = UDim2.new(1, -16, 1, 0)
								mutualName.Font = Enum.Font.Gotham
								mutualName.Text = "👤 " .. (mutual.displayName or mutual.name)
								mutualName.TextColor3 = Color3.fromRGB(200, 200, 220)
								mutualName.TextSize = 11
								mutualName.TextXAlignment = Enum.TextXAlignment.Left
								mutualName.TextTruncate = Enum.TextTruncate.AtEnd
							end
						end
						
						mutualListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
							mutualList.Size = UDim2.new(1, 0, 0, mutualListLayout.AbsoluteContentSize.Y)
							mutualSection.Size = UDim2.new(1, 0, 0, mutualListLayout.AbsoluteContentSize.Y + 40)
						end)
					end
                    
                    pcall(function()
                        if player.AccountAge then
                            createInfoItem("Account Age", formatAccountAge(player.AccountAge), order) order = order + 1
                            createInfoItem("First Join Date", getFirstJoinDate(player.AccountAge), order) order = order + 1
                        end
                    end)
                    
                    pcall(function()
                        if player.Team then 
                            createInfoItem("Team", tostring(player.Team.Name), order) order = order + 1
                        end
                    end)
                end)
            end)
            infoBtn.Size = UDim2.new(0.2, -5, 0, 32)
            
            -- View POV Button (Camera Spectate)
            local viewBtn = createButton(playerFrame, "- POV -", UDim2.new(0.58, 5, 0.5, -16), function()
                -- Follow-mode spectate: set camera subject to target humanoid so
                -- the local camera behaves like your own (can move/rotate freely)
                if not player then return end

                -- Clean previous spectate connection if present
                if spectateConnection then
                    spectateConnection:Disconnect()
                    spectateConnection = nil
                end

                -- If character & humanoid available, set CameraSubject to it
                local function startFollowMode(char)
                    if not char then return end
                    local hum = char:FindFirstChild("Humanoid")
                    if hum and hum:IsA("Humanoid") then
                        spectatingPlayer = player
                        -- Allow player camera control while focused on target
                        Camera.CameraType = Enum.CameraType.Custom
                        Camera.CameraSubject = hum
                        -- Optionally nudge camera to target position briefly
                        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
                        if hrp then
                            pcall(function()
                                Camera.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0), hrp.Position + hrp.CFrame.LookVector * 5)
                            end)
                        end
                    end
                end

                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    startFollowMode(player.Character)
                else
                    -- Wait for character then start follow mode
                    local charConn
                    charConn = player.CharacterAdded:Connect(function(char)
                        if charConn then charConn:Disconnect() charConn = nil end
                        task.wait(0.1)
                        if player == spectatingPlayer then return end -- don't override if already spectating
                        startFollowMode(char)
                    end)
                end
            end)
            viewBtn.Size = UDim2.new(0.2, -5, 0, 32)
            
            -- Teleport Button - Kanan
            local tpBtn = createButton(playerFrame, "🚀 TP", UDim2.new(0.79, 5, 0.5, -16), function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = player.Character.HumanoidRootPart
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                    end
                end
            end)
            tpBtn.Size = UDim2.new(0.2, -5, 0, 32)
        end
    end
end

-- Auto refresh player list
local playerRefreshConnection = RunService.Heartbeat:Connect(function()
    if currentPage == playerPage and playerPage.Visible then
        -- Update every 2 seconds
        if not playerPage:GetAttribute("LastUpdate") or (tick() - playerPage:GetAttribute("LastUpdate")) > 2 then
            playerPage:SetAttribute("LastUpdate", tick())
            updatePlayerList()
        end
    end
end)
table.insert(connections, playerRefreshConnection)

-- ============================================
-- LOCAL SETTINGS PAGE
-- ============================================

local settingsPage = createPage("Settings")
local settingsScrollContent = Instance.new("Frame")
settingsScrollContent.Name = "SettingsScrollContent"
settingsScrollContent.Parent = settingsPage
settingsScrollContent.BackgroundTransparency = 1
settingsScrollContent.Size = UDim2.new(1, 0, 0, 0)

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.Parent = settingsScrollContent
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Padding = UDim.new(0, 10)

settingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    settingsScrollContent.Size = UDim2.new(1, 0, 0, settingsLayout.AbsoluteContentSize.Y)
end)

-- Infinity Jump
-- Infinity Jump
createSectionHeader(settingsScrollContent, "⚡ Movement", 1)

-- Variable to store infinity jump connection
local infinityJumpConnection = nil

local infJumpToggle, infJumpStatus = createToggle(settingsScrollContent, "Infinity Jump", UDim2.new(0, 0, 0, 0), function(enabled)
    settings.infinityJump = enabled
    
    if enabled then
        -- Disconnect previous connection if exists
        if infinityJumpConnection then
            infinityJumpConnection:Disconnect()
            infinityJumpConnection = nil
        end
        
        -- Create new connection
        infinityJumpConnection = UserInputService.JumpRequest:Connect(function()
            if settings.infinityJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        
        -- Also add to connections array for cleanup on script destroy
        table.insert(connections, infinityJumpConnection)
    else
        -- Disconnect when disabled
        if infinityJumpConnection then
            infinityJumpConnection:Disconnect()
            infinityJumpConnection = nil
        end
        
        -- Ensure character can't jump in mid-air after disabling
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local humanoid = LocalPlayer.Character.Humanoid
            if humanoid:GetState() == Enum.HumanoidStateType.Jumping or 
               humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                -- Let them land naturally
                humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
            end
        end
    end
end)
infJumpToggle.LayoutOrder = 2

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function(character)
    -- Reapply infinity jump if it was enabled
    if settings.infinityJump and infinityJumpConnection then
        infinityJumpConnection:Disconnect()
        infinityJumpConnection = nil
        
        task.wait(0.5) -- Wait for character to fully load
        
        infinityJumpConnection = UserInputService.JumpRequest:Connect(function()
            if settings.infinityJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

-- Audio Controls (Toggle-style)
createSectionHeader(settingsScrollContent, "🔊 Audio", 2)

local currentVolume = 1.0
local volumeLevels = {1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0}
local currentVolumeIndex = 1

local function applyVolume(vol)
    currentVolume = vol
    for _, s in pairs(Workspace:GetDescendants()) do 
        if s:IsA("Sound") then 
            pcall(function() s.Volume = currentVolume end) 
        end 
    end
end

-- Apply volume to future sounds
Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("Sound") then
        pcall(function() desc.Volume = currentVolume end)
    end
end)

-- Audio toggle (cycle through volume levels)
local audioToggle = Instance.new("TextButton")
audioToggle.Name = "AudioToggle"
audioToggle.Parent = settingsScrollContent
audioToggle.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
audioToggle.BorderSizePixel = 0
audioToggle.Size = UDim2.new(1, -20, 0, 42)
audioToggle.Font = Enum.Font.Gotham
audioToggle.Text = ""
audioToggle.AutoButtonColor = false
audioToggle.LayoutOrder = 3

local audioCorner = Instance.new("UICorner")
audioCorner.CornerRadius = UDim.new(0, 4)
audioCorner.Parent = audioToggle

local audioLabel = Instance.new("TextLabel")
audioLabel.Name = "Label"
audioLabel.Parent = audioToggle
audioLabel.BackgroundTransparency = 1
audioLabel.Position = UDim2.new(0, 12, 0, 0)
audioLabel.Size = UDim2.new(0.7, 0, 1, 0)
audioLabel.Font = Enum.Font.Gotham
audioLabel.Text = "Map Volume"
audioLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
audioLabel.TextSize = 13
audioLabel.TextXAlignment = Enum.TextXAlignment.Left

local audioStatus = Instance.new("TextLabel")
audioStatus.Name = "Status"
audioStatus.Parent = audioToggle
audioStatus.BackgroundTransparency = 1
audioStatus.Position = UDim2.new(0.7, 0, 0, 0)
audioStatus.Size = UDim2.new(0.3, -15, 1, 0)
audioStatus.Font = Enum.Font.Gotham
audioStatus.Text = tostring(math.floor(currentVolume * 100)) .. "%"
audioStatus.TextColor3 = Color3.fromRGB(120, 200, 150)
audioStatus.TextSize = 13
audioStatus.TextXAlignment = Enum.TextXAlignment.Right

audioToggle.MouseEnter:Connect(function()
    TweenService:Create(audioToggle, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    }):Play()
end)

audioToggle.MouseLeave:Connect(function()
    TweenService:Create(audioToggle, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    }):Play()
end)

audioToggle.MouseButton1Click:Connect(function()
    currentVolumeIndex = currentVolumeIndex + 1
    if currentVolumeIndex > #volumeLevels then currentVolumeIndex = 1 end
    applyVolume(volumeLevels[currentVolumeIndex])
    audioStatus.Text = tostring(math.floor(volumeLevels[currentVolumeIndex] * 100)) .. "%"
    if volumeLevels[currentVolumeIndex] == 0 then
        audioStatus.TextColor3 = Color3.fromRGB(180, 120, 120)
    else
        audioStatus.TextColor3 = Color3.fromRGB(120, 200, 150)
    end
end)

-- Initialize volume
applyVolume(volumeLevels[currentVolumeIndex])

-- Fly
createSectionHeader(settingsScrollContent, "🚁 Flight & Movement", 5)
local flyToggle, flyStatus = createToggle(settingsScrollContent, "Fly", UDim2.new(0, 0, 0, 0), function(enabled)
    settings.flyEnabled = enabled
    if enabled then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        flyConnection = RunService.Heartbeat:Connect(function()
            if not settings.flyEnabled or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                if bodyVelocity then bodyVelocity:Destroy() end
                return
            end
            
            local camera = Workspace.CurrentCamera
            local moveVector = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveVector = moveVector + camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveVector = moveVector - camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveVector = moveVector - camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveVector = moveVector + camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveVector = moveVector + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveVector = moveVector - Vector3.new(0, 1, 0)
            end
            
            bodyVelocity.Velocity = moveVector * 50
        end)
        table.insert(connections, flyConnection)
    else
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            for _, v in pairs(LocalPlayer.Character.HumanoidRootPart:GetChildren()) do
                if v:IsA("BodyVelocity") then
                    v:Destroy()
                end
            end
        end
    end
end)
flyToggle.LayoutOrder = 6

-- No Clip (with proper restore)
local originalCollisionState = {} -- Store original CanCollide values

local function saveCollisionState(character)
    originalCollisionState = {}
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                originalCollisionState[part] = part.CanCollide
            end
        end
    end
end

local function restoreCollisionState(character)
    if character then
        for part, canCollide in pairs(originalCollisionState) do
            if part.Parent and part:IsA("BasePart") then
                pcall(function()
                    part.CanCollide = canCollide
                end)
            end
        end
        -- Also restore any parts that might have been created after saving state
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and not originalCollisionState[part] then
                -- New part, use default collision (most parts should collide)
                if part.Name ~= "Handle" and not part:FindFirstAncestorOfClass("Accessory") then
                    pcall(function()
                        part.CanCollide = true
                    end)
                end
            end
        end
    end
    originalCollisionState = {} -- Clear saved state
end

local noClipToggle, noClipStatus = createToggle(settingsScrollContent, "No Clip", UDim2.new(0, 0, 0, 0), function(enabled)
    settings.noClipEnabled = enabled
    if enabled then
        -- Save current collision state before enabling
        if LocalPlayer.Character then
            saveCollisionState(LocalPlayer.Character)
        end
        
        noClipConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
        table.insert(connections, noClipConnection)
    else
        -- Disable no clip
        if noClipConnection then
            noClipConnection:Disconnect()
            noClipConnection = nil
        end
        
        -- Restore original collision state
        if LocalPlayer.Character then
            restoreCollisionState(LocalPlayer.Character)
        end
    end
end)
noClipToggle.LayoutOrder = 7

-- Re-save collision state on character respawn
LocalPlayer.CharacterAdded:Connect(function(character)
    if settings.noClipEnabled then
        -- If no clip is enabled, save new character's state
        task.wait(0.1) -- Wait for character to fully load
        saveCollisionState(character)
    end
end)

-- ============================================
-- ESP (Name tags) Setup
-- ============================================

local espEnabled = false
local espGuis = {}
local espCharConns = {}
local espPlayerAddedConn
local espPlayerRemovingConn

local function createESPForPlayer(p)
    if not p or not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    -- destroy any existing
    if espGuis[p] then pcall(function() espGuis[p]:Destroy() end) espGuis[p] = nil end

    local gui = Instance.new("BillboardGui")
    gui.Name = "AlphaESP_" .. tostring(p.UserId)
    gui.Adornee = hrp
    gui.AlwaysOnTop = true
    gui.Size = UDim2.new(0, 160, 0, 40)
    gui.StudsOffset = Vector3.new(0, 2.5, 0)
    gui.Parent = CoreGui

    local label = Instance.new("TextLabel")
    label.Parent = gui
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 20
    label.Text = p.DisplayName or p.Name
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextStrokeTransparency = 0.7
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center

    espGuis[p] = gui
end

function removeESPForPlayer(p)
    if espGuis[p] then
        pcall(function() espGuis[p]:Destroy() end)
        espGuis[p] = nil
    end
end

local function setupCharConn(p)
    if espCharConns[p] then
        espCharConns[p]:Disconnect()
        espCharConns[p] = nil
    end
    espCharConns[p] = p.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        if espEnabled then createESPForPlayer(p) end
    end)
end

local function enableESP()
    espEnabled = true
    -- Create for existing players
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if p.Character then createESPForPlayer(p) end
            setupCharConn(p)
        end
    end
    -- Listen for new players
    espPlayerAddedConn = Players.PlayerAdded:Connect(function(p)
        if p ~= LocalPlayer then
            setupCharConn(p)
            task.wait(0.1)
            if espEnabled and p.Character then createESPForPlayer(p) end
        end
    end)
    espPlayerRemovingConn = Players.PlayerRemoving:Connect(function(p)
        removeESPForPlayer(p)
        if espCharConns[p] then espCharConns[p]:Disconnect() espCharConns[p] = nil end
    end)
end

local function disableESP()
    espEnabled = false
    for p, _ in pairs(espGuis) do removeESPForPlayer(p) end
    for p, conn in pairs(espCharConns) do if conn then conn:Disconnect() espCharConns[p] = nil end end
    if espPlayerAddedConn then espPlayerAddedConn:Disconnect() espPlayerAddedConn = nil end
    if espPlayerRemovingConn then espPlayerRemovingConn:Disconnect() espPlayerRemovingConn = nil end
end

-- ESP toggle in settings
createSectionHeader(settingsScrollContent, "🔍 ESP", 8)
local espToggle, espStatus = createToggle(settingsScrollContent, "ESP", UDim2.new(0,0,0,0), function(enabled)
    if enabled then
        enableESP()
    else
        disableESP()
    end
end)
espToggle.LayoutOrder = 9

-- God Mode
createSectionHeader(settingsScrollContent, "🛡️ Protection", 9)
local godModeEnabled = false
local godModeConnection = nil

local godToggle, godStatus = createToggle(settingsScrollContent, "God Mode", UDim2.new(0,0,0,0), function(enabled)
    godModeEnabled = enabled
    if enabled then
        godModeConnection = RunService.Heartbeat:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum.Health < hum.MaxHealth then
                    hum.Health = hum.MaxHealth
                end
                -- Prevent death
                hum.MaxHealth = math.huge
                hum.Health = math.huge
            end
        end)
        table.insert(connections, godModeConnection)
    else
        if godModeConnection then
            godModeConnection:Disconnect()
            godModeConnection = nil
        end
        -- Restore normal health
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            hum.MaxHealth = 100
            hum.Health = 100
        end
    end
end)
godToggle.LayoutOrder = 10

-- Reapply god mode on character respawn
LocalPlayer.CharacterAdded:Connect(function(character)
    if godModeEnabled then
        task.wait(0.1)
        local hum = character:WaitForChild("Humanoid")
        hum.MaxHealth = math.huge
        hum.Health = math.huge
    end
end)

-- Global Friend
createSectionHeader(settingsScrollContent, "👥 Social", 11)
local globalFriendToggle, globalFriendStatus = createToggle(settingsScrollContent, "Global Friend Detector", UDim2.new(0,0,0,0), function(enabled)
    settings.globalFriendEnabled = enabled
    
    if enabled then
        -- Load friend data jika belum
        if not friendDataLoaded then
            globalFriendStatus.Text = "Loading..."
            globalFriendStatus.TextColor3 = Color3.fromRGB(200, 200, 120)
            
            spawn(function()
                getMyFriends()
                
                if friendDataLoaded then
                    -- Scan semua player yang ada
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            spawn(function()
                                local mutuals = checkMutualFriends(player)
                                playerMutualFriends[player] = mutuals
                                
                                if #mutuals > 0 then
                                    showMutualFriendNotification(player, mutuals)
                                end
                            end)
                        end
                    end
                    
                    globalFriendStatus.Text = "ON"
                    globalFriendStatus.TextColor3 = Color3.fromRGB(120, 200, 150)
                    
                    -- Refresh player list untuk update border
                    if currentPage == playerPage then
                        updatePlayerList()
                    end
                else
                    globalFriendStatus.Text = "Failed"
                    globalFriendStatus.TextColor3 = Color3.fromRGB(200, 120, 120)
                end
            end)
        else
            globalFriendStatus.Text = "ON"
            globalFriendStatus.TextColor3 = Color3.fromRGB(120, 200, 150)
            
            -- Refresh player list
            if currentPage == playerPage then
                updatePlayerList()
            end
        end
    else
        globalFriendStatus.Text = "OFF"
        globalFriendStatus.TextColor3 = Color3.fromRGB(180, 120, 120)
        
        -- Refresh player list untuk remove border
        if currentPage == playerPage then
            updatePlayerList()
        end
    end
end)
globalFriendToggle.LayoutOrder = 12

-- Tambahkan button test di settings page
local testBtn = createButton(settingsScrollContent, "🧪 Test Notification", UDim2.new(0, 0, 0, 0), function()
    print("Testing notification...")
    local dummyPlayer = LocalPlayer
    local dummyMutuals = {
        {id = 1, name = "TestFriend1", displayName = "Test Friend"},
        {id = 2, name = "TestFriend2", displayName = "Another Friend"}
    }
    showMutualFriendNotification(dummyPlayer, dummyMutuals)
end)
testBtn.Size = UDim2.new(1, -20, 0, 42)
testBtn.LayoutOrder = 13


-- ============================================
-- NAVIGATION BUTTONS
-- ============================================

local playerNavBtn = createNavButton("Players", "👥", 1, function()
    showPage(playerPage)
    updatePlayerList()
end)

local settingsNavBtn = createNavButton("Settings", "⚙️", 2, function()
    showPage(settingsPage)
end)

-- Default page
showPage(playerPage)
playerNavBtn:SetAttribute("Active", true)
playerNavBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
playerNavBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- ============================================
-- TOGGLE ICON (Must be created before Close & Minimize)
-- ============================================

local minimized = false
local MinimizedIcon = nil

-- Toggle Icon (Fixed at Center Left)
local ToggleIcon = Instance.new("TextButton")
ToggleIcon.Name = "ToggleIcon"
ToggleIcon.Parent = ScreenGui
ToggleIcon.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ToggleIcon.BorderSizePixel = 0
ToggleIcon.Size = UDim2.new(0, 50, 0, 50)
ToggleIcon.Position = UDim2.new(0, 10, 0.5, -25) -- Center left
ToggleIcon.Text = "🚀"
ToggleIcon.TextColor3 = Color3.fromRGB(220, 220, 230)
ToggleIcon.TextSize = 24
ToggleIcon.Font = Enum.Font.GothamBold
ToggleIcon.AutoButtonColor = false
ToggleIcon.Active = true
ToggleIcon.ZIndex = 10
ToggleIcon.Visible = true

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = ToggleIcon

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(150, 150, 160)
toggleStroke.Thickness = 1
toggleStroke.Transparency = 0.5
toggleStroke.Parent = ToggleIcon

-- Toggle functionality
ToggleIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    minimized = not MainFrame.Visible
    
    if MainFrame.Visible then
        -- GUI shown
        TweenService:Create(toggleStroke, TweenInfo.new(0.2), {
            Transparency = 0.3
        }):Play()
        
        -- Hide minimized icon if exists
        if MinimizedIcon then
            MinimizedIcon.Visible = false
        end
    else
        -- GUI hidden
        TweenService:Create(toggleStroke, TweenInfo.new(0.2), {
            Transparency = 0.7
        }):Play()
    end
end)

-- Hover effects
ToggleIcon.MouseEnter:Connect(function()
    TweenService:Create(ToggleIcon, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    }):Play()
    TweenService:Create(toggleStroke, TweenInfo.new(0.2), {
        Transparency = 0.3
    }):Play()
end)

ToggleIcon.MouseLeave:Connect(function()
    TweenService:Create(ToggleIcon, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    }):Play()
    TweenService:Create(toggleStroke, TweenInfo.new(0.2), {
        Transparency = 0.5
    }):Play()
end)

-- ============================================
-- CLOSE & MINIMIZE
-- ============================================

MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        -- Hide main frame (toggle icon at center left will handle restore)
        MainFrame.Visible = false
        
        -- Update toggle icon state
        TweenService:Create(toggleStroke, TweenInfo.new(0.2), {
            Transparency = 0.7
        }):Play()
    else
        -- Restore main frame
        MainFrame.Visible = true
        TweenService:Create(toggleStroke, TweenInfo.new(0.2), {
            Transparency = 0.3
        }):Play()
        MinimizeButton.Text = "─"
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    -- Destroy the entire GUI from Roblox
    pcall(function()
        ScreenGui:Destroy()
    end)
end)

-- Hover effects
MinimizeButton.MouseEnter:Connect(function()
    TweenService:Create(MinimizeButton, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    }):Play()
end)

MinimizeButton.MouseLeave:Connect(function()
    TweenService:Create(MinimizeButton, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    }):Play()
end)

CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(50, 35, 35)
    }):Play()
end)

CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    }):Play()
end)

-- Toggle menu dengan Right Control (also updates icon state)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
        
        if MainFrame.Visible then
            TweenService:Create(toggleStroke, TweenInfo.new(0.2), {
                Transparency = 0.3
            }):Play()
        else
            TweenService:Create(toggleStroke, TweenInfo.new(0.2), {
                Transparency = 0.7
            }):Play()
        end
    end
end)

-- Character respawn handling
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
end)

print("✅ Alpha Project Menu Loaded Successfully!")
print("📌 Press RIGHT CTRL to toggle menu")
print("📌 Or click the toggle button on the left side")
print("Features:")
print("   - Player List (View POV & Teleport)")
print("   - Settings (Infinity Jump, Fly, No Clip, etc.)")
print("MainFrame Visible:", MainFrame.Visible)
print("ToggleIcon Visible:", ToggleIcon.Visible)

