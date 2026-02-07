--[[
    Alpha Project - Camera User
    Navigasi POV user dengan tombol kiri/kanan untuk switch user.
    Tampilkan username dan nama di bawah saat aktif.
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local CameraUserFeature = {}

local active = false
local currentIndex = 1
local playersList = {}
local navGui = nil
local spectateConn = nil

local function get_all_players()
    local list = {}
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= Services.LocalPlayer and p.Character then
            table.insert(list, p)
        end
    end
    return list
end

local function update_players_list()
    playersList = get_all_players()
    if currentIndex > #playersList then
        currentIndex = math.max(1, #playersList)
    end
end

local function spectate_player(player)
    if not player or not player.Character then return end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    Services.Camera.CameraType = Enum.CameraType.Follow
    Services.Camera.CameraSubject = humanoid
    
    if spectateConn then spectateConn:Disconnect() end
    spectateConn = player.CharacterAdded:Connect(function(newChar)
        local newHum = newChar:FindFirstChild("Humanoid")
        if newHum then Services.Camera.CameraSubject = newHum end
    end)
end

local function create_nav_gui()
    if navGui then navGui:Destroy() end
    
    navGui = Instance.new("ScreenGui")
    navGui.Name = "AlphaCameraUserNav"
    navGui.Parent = Services.CoreGui
    navGui.DisplayOrder = 150
    navGui.ResetOnSpawn = false
    
    local navFrame = Instance.new("Frame")
    navFrame.Parent = navGui
    navFrame.Size = UDim2.new(0, 400, 0, 80)
    navFrame.Position = UDim2.new(0.5, -200, 1, -100)
    navFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    navFrame.BorderSizePixel = 0
    
    local navCorner = Instance.new("UICorner")
    navCorner.CornerRadius = UDim.new(0, 12)
    navCorner.Parent = navFrame
    
    local navStroke = Instance.new("UIStroke")
    navStroke.Color = Color3.fromRGB(0, 160, 145)
    navStroke.Thickness = 2
    navStroke.Transparency = 0.3
    navStroke.Parent = navFrame
    
    local leftBtn = Instance.new("TextButton")
    leftBtn.Parent = navFrame
    leftBtn.Size = UDim2.new(0, 50, 0, 50)
    leftBtn.Position = UDim2.new(0, 20, 0.5, -25)
    leftBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
    leftBtn.BorderSizePixel = 0
    leftBtn.Font = Enum.Font.GothamBold
    leftBtn.Text = "◀"
    leftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    leftBtn.TextSize = 24
    leftBtn.AutoButtonColor = false
    local leftCorner = Instance.new("UICorner")
    leftCorner.CornerRadius = UDim.new(0, 8)
    leftCorner.Parent = leftBtn
    
    local rightBtn = Instance.new("TextButton")
    rightBtn.Parent = navFrame
    rightBtn.Size = UDim2.new(0, 50, 0, 50)
    rightBtn.Position = UDim2.new(1, -70, 0.5, -25)
    rightBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
    rightBtn.BorderSizePixel = 0
    rightBtn.Font = Enum.Font.GothamBold
    rightBtn.Text = "▶"
    rightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    rightBtn.TextSize = 24
    rightBtn.AutoButtonColor = false
    local rightCorner = Instance.new("UICorner")
    rightCorner.CornerRadius = UDim.new(0, 8)
    rightCorner.Parent = rightBtn
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = navFrame
    nameLabel.Size = UDim2.new(1, -140, 0, 30)
    nameLabel.Position = UDim2.new(0, 70, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = "—"
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 16
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    
    local userLabel = Instance.new("TextLabel")
    userLabel.Parent = navFrame
    userLabel.Size = UDim2.new(1, -140, 0, 20)
    userLabel.Position = UDim2.new(0, 70, 0, 40)
    userLabel.BackgroundTransparency = 1
    userLabel.Font = Enum.Font.Gotham
    userLabel.Text = "—"
    userLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    userLabel.TextSize = 12
    userLabel.TextXAlignment = Enum.TextXAlignment.Center
    
    local function update_display()
        if #playersList == 0 then
            nameLabel.Text = "Tidak ada player"
            userLabel.Text = ""
            return
        end
        local p = playersList[currentIndex]
        if p then
            nameLabel.Text = p.DisplayName or p.Name
            userLabel.Text = "@" .. p.Name .. " (" .. currentIndex .. "/" .. #playersList .. ")"
            spectate_player(p)
        end
    end
    
    leftBtn.MouseButton1Click:Connect(function()
        if #playersList == 0 then return end
        currentIndex = currentIndex - 1
        if currentIndex < 1 then currentIndex = #playersList end
        update_display()
    end)
    
    rightBtn.MouseButton1Click:Connect(function()
        if #playersList == 0 then return end
        currentIndex = currentIndex + 1
        if currentIndex > #playersList then currentIndex = 1 end
        update_display()
    end)
    
    local function refresh_loop()
        while active do
            update_players_list()
            update_display()
            task.wait(1)
        end
    end
    
    task.spawn(refresh_loop)
    update_display()
end

local function destroy_nav_gui()
    if navGui then navGui:Destroy() navGui = nil end
    if spectateConn then spectateConn:Disconnect() spectateConn = nil end
    local humanoid = Services.get_humanoid()
    if humanoid then
        Services.Camera.CameraType = Enum.CameraType.Custom
        Services.Camera.CameraSubject = humanoid
    end
end

function CameraUserFeature.toggle(enabled)
    active = enabled
    Settings.features.cameraUserEnabled = enabled
    if enabled then
        update_players_list()
        create_nav_gui()
    else
        destroy_nav_gui()
    end
end

return CameraUserFeature
