--[[
    Alpha Project - Standalone Entry Point
    Simplified version para remote loading (loadstring)
    Features: Fly, NoClip, Infinity Jump, Menu
]]

-- ============================================
-- SERVICES
-- ============================================

local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Camera = Workspace.CurrentCamera

-- ============================================
-- CHECK HTTP
-- ============================================

if not HttpService.HttpEnabled then
    warn("❌ HTTP Service is NOT enabled!")
    warn("Enable: Game Settings > Security > Allow HTTP Requests")
    return
end

print("✅ [Alpha] HTTP enabled")

-- ============================================
-- SETTINGS
-- ============================================

local Settings = {
    fly = false,
    noClip = false,
    infinityJump = false,
}

local Connections = {
    fly = nil,
    noClip = nil,
    infinityJump = nil,
}

-- ============================================
-- COLOR THEME
-- ============================================

local Colors = {
    bg_dark = Color3.fromRGB(20, 20, 25),
    bg_medium = Color3.fromRGB(22, 22, 28),
    bg_light = Color3.fromRGB(25, 25, 32),
    text_primary = Color3.fromRGB(240, 240, 250),
    text_secondary = Color3.fromRGB(220, 220, 230),
    text_tertiary = Color3.fromRGB(180, 180, 200),
    on = Color3.fromRGB(120, 200, 150),
    off = Color3.fromRGB(180, 120, 120),
}

-- ============================================
-- HELPER: TWEEN
-- ============================================

local function tween_color(obj, color, speed)
    speed = speed or 0.15
    local tweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    TweenService:Create(obj, tweenInfo, {BackgroundColor3 = color}):Play()
end

-- ============================================
-- HELPER: GET CURRENT CHARACTER
-- ============================================

local function get_hrp()
    if not LocalPlayer.Character then return nil end
    return LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function get_humanoid()
    if not LocalPlayer.Character then return nil end
    return LocalPlayer.Character:FindFirstChild("Humanoid")
end

-- ============================================
-- FLY FEATURE
-- ============================================

local function enable_fly()
    if Settings.fly then return end
    Settings.fly = true
    
    local hrp = get_hrp()
    if not hrp then return end
    
    local bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(40000, 40000, 40000)
    bodyVel.Velocity = Vector3.new(0, 0, 0)
    bodyVel.Parent = hrp
    
    Connections.fly = RunService.Heartbeat:Connect(function()
        if not Settings.fly or not get_hrp() then
            if bodyVel then bodyVel:Destroy() end
            Connections.fly:Disconnect()
            Connections.fly = nil
            return
        end
        
        local moveVec = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec = moveVec + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec = moveVec - Vector3.new(0, 1, 0) end
        
        bodyVel.Velocity = moveVec * 50
    end)
    
    print("✅ [Alpha] Fly enabled")
end

local function disable_fly()
    Settings.fly = false
    if Connections.fly then
        Connections.fly:Disconnect()
        Connections.fly = nil
    end
    local hrp = get_hrp()
    if hrp then
        for _, v in pairs(hrp:GetChildren()) do
            if v:IsA("BodyVelocity") then v:Destroy() end
        end
    end
    print("❌ [Alpha] Fly disabled")
end

-- ============================================
-- NO CLIP FEATURE
-- ============================================

local function enable_noclip()
    if Settings.noClip then return end
    Settings.noClip = true
    
    Connections.noClip = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
    
    print("✅ [Alpha] NoClip enabled")
end

local function disable_noclip()
    Settings.noClip = false
    if Connections.noClip then
        Connections.noClip:Disconnect()
        Connections.noClip = nil
    end
    
    local char = LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    print("❌ [Alpha] NoClip disabled")
end

-- ============================================
-- INFINITY JUMP FEATURE
-- ============================================

local function enable_infinity_jump()
    if Settings.infinityJump then return end
    Settings.infinityJump = true
    
    Connections.infinityJump = UserInputService.JumpRequest:Connect(function()
        if Settings.infinityJump then
            local hum = get_humanoid()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
    
    print("✅ [Alpha] Infinity Jump enabled")
end

local function disable_infinity_jump()
    Settings.infinityJump = false
    if Connections.infinityJump then
        Connections.infinityJump:Disconnect()
        Connections.infinityJump = nil
    end
    print("❌ [Alpha] Infinity Jump disabled")
end

-- ============================================
-- TOGGLE HELPER
-- ============================================

local function create_toggle(parent, text, callback)
    local toggle = Instance.new("TextButton")
    toggle.Parent = parent
    toggle.BackgroundColor3 = Colors.bg_light
    toggle.BorderSizePixel = 0
    toggle.Size = UDim2.new(1, -20, 0, 42)
    toggle.Font = Enum.Font.Gotham
    toggle.Text = ""
    toggle.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = toggle
    
    local label = Instance.new("TextLabel")
    label.Parent = toggle
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Colors.text_secondary
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local status = Instance.new("TextLabel")
    status.Parent = toggle
    status.BackgroundTransparency = 1
    status.Position = UDim2.new(0.7, 0, 0, 0)
    status.Size = UDim2.new(0.3, -15, 1, 0)
    status.Font = Enum.Font.Gotham
    status.Text = "OFF"
    status.TextColor3 = Colors.off
    status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Right
    
    local isOn = false
    
    toggle.MouseEnter:Connect(function()
        tween_color(toggle, Colors.accent_hover)
    end)
    
    toggle.MouseLeave:Connect(function()
        tween_color(toggle, Colors.bg_light)
    end)
    
    toggle.MouseButton1Click:Connect(function()
        isOn = not isOn
        status.Text = isOn and "ON" or "OFF"
        status.TextColor3 = isOn and Colors.on or Colors.off
        callback(isOn)
    end)
    
    return toggle, status
end

-- ============================================
-- CREATE GUI
-- ============================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AlphaGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Colors.bg_dark
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 500, 0, 300)
MainFrame.Active = true
MainFrame.Draggable = true

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 6)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 100, 120)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.5
mainStroke.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 40)

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 6)
titleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = TitleBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.Size = UDim2.new(0.5, 0, 1, 0)
TitleLabel.Font = Enum.Font.Gotham
TitleLabel.Text = "🚀 Alpha Project"
TitleLabel.TextColor3 = Colors.text_secondary
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TitleBar
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
CloseBtn.BorderSizePixel = 0
CloseBtn.Position = UDim2.new(1, -30, 0.5, -10)
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Font = Enum.Font.Gotham
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Colors.off
CloseBtn.TextSize = 16
CloseBtn.AutoButtonColor = false

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 4)
closeBtnCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Content
local Content = Instance.new("ScrollingFrame")
Content.Parent = MainFrame
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 0, 0, 40)
Content.Size = UDim2.new(1, 0, 1, -40)
Content.ScrollBarThickness = 6
Content.CanvasSize = UDim2.new(0, 0, 0, 0)

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 15)
contentPadding.PaddingLeft = UDim.new(0, 15)
contentPadding.PaddingRight = UDim.new(0, 15)
contentPadding.PaddingBottom = UDim.new(0, 15)
contentPadding.Parent = Content

local contentList = Instance.new("UIListLayout")
contentList.Parent = Content
contentList.SortOrder = Enum.SortOrder.LayoutOrder
contentList.Padding = UDim.new(0, 10)

contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 30)
end)

-- Section Header
local header = Instance.new("TextLabel")
header.Parent = Content
header.BackgroundTransparency = 1
header.Size = UDim2.new(1, 0, 0, 28)
header.Font = Enum.Font.Gotham
header.Text = "⚡ Movement Features"
header.TextColor3 = Colors.text_secondary
header.TextSize = 13
header.TextXAlignment = Enum.TextXAlignment.Left
header.LayoutOrder = 1

-- Toggles
local flyToggle, flyStatus = create_toggle(Content, "Fly", function(enabled)
    if enabled then enable_fly() else disable_fly() end
end)
flyToggle.LayoutOrder = 2

local noclipToggle, noclipStatus = create_toggle(Content, "No Clip", function(enabled)
    if enabled then enable_noclip() else disable_noclip() end
end)
noclipToggle.LayoutOrder = 3

local jumpToggle, jumpStatus = create_toggle(Content, "Infinity Jump", function(enabled)
    if enabled then enable_infinity_jump() else disable_infinity_jump() end
end)
jumpToggle.LayoutOrder = 4

-- Toggle Icon
local ToggleIcon = Instance.new("TextButton")
ToggleIcon.Name = "ToggleIcon"
ToggleIcon.Parent = ScreenGui
ToggleIcon.BackgroundColor3 = Colors.bg_dark
ToggleIcon.BorderSizePixel = 0
ToggleIcon.Size = UDim2.new(0, 50, 0, 50)
ToggleIcon.Position = UDim2.new(0, 10, 0.5, -25)
ToggleIcon.Text = "🚀"
ToggleIcon.TextColor3 = Colors.text_secondary
ToggleIcon.TextSize = 24
ToggleIcon.Font = Enum.Font.GothamBold
ToggleIcon.AutoButtonColor = false
ToggleIcon.ZIndex = 10

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = ToggleIcon

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(150, 150, 160)
toggleStroke.Thickness = 1
toggleStroke.Parent = ToggleIcon

ToggleIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Keyboard Toggle
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Character Respawn Handler
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    if Settings.fly then
        task.wait(0.5)
        enable_fly()
    end
    if Settings.infinityJump then
        task.wait(0.5)
        enable_infinity_jump()
    end
end)

print("✅✅✅ [Alpha] Standalone loaded successfully! ✅✅✅")
print("📌 Press RIGHT CTRL to toggle menu")
print("🎮 Features: Fly | No Clip | Infinity Jump")
print("🔧 Ready to use!")
