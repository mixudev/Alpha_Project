--[[
    Alpha Project - Bootstrap
    Simplified entry point untuk remote loading
    All dependencies handled locally
]]

local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================
-- ERROR HANDLER
-- ============================================

local function safe_print(msg)
    print("[AlphaProject] " .. tostring(msg))
end

local function safe_warn(msg)
    warn("[AlphaProject] ⚠️ " .. tostring(msg))
end

safe_print("🚀 Bootstrap starting...")

-- ============================================
-- HTTP CHECK
-- ============================================

if not HttpService.HttpEnabled then
    safe_warn("HTTP Service is NOT enabled!")
    safe_warn("Enable it in Game Settings > Security > Allow HTTP Requests")
    return false
end

safe_print("✅ HTTP Service enabled")

-- ============================================
-- BASE MODULES (Inline - No Dependencies)
-- ============================================

-- Settings
local Settings = {
    colors = {
        bg_dark = Color3.fromRGB(20, 20, 25),
        bg_medium = Color3.fromRGB(22, 22, 28),
        bg_light = Color3.fromRGB(25, 25, 32),
        text_primary = Color3.fromRGB(240, 240, 250),
        text_secondary = Color3.fromRGB(220, 220, 230),
        text_tertiary = Color3.fromRGB(180, 180, 200),
        status_on = Color3.fromRGB(120, 200, 150),
        status_off = Color3.fromRGB(180, 120, 120),
        status_loading = Color3.fromRGB(200, 200, 120),
        accent_friend = Color3.fromRGB(100, 200, 100),
        accent_error = Color3.fromRGB(240, 140, 140),
        accent_hover = Color3.fromRGB(30, 30, 38),
    },
    features = {
        infinityJump = false,
        flyEnabled = false,
        noClipEnabled = false,
        globalFriendEnabled = false,
        espEnabled = false,
        godModeEnabled = false,
    }
}

safe_print("✅ Settings initialized")

-- ============================================
-- CREATE MAIN GUI
-- ============================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AlphaGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Enabled = true
ScreenGui.Parent = CoreGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Settings.colors.bg_dark
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

-- Title Bar
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
TitleLabel.TextColor3 = Settings.colors.text_secondary
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = TitleBar
CloseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(1, -30, 0.5, -10)
CloseButton.Size = UDim2.new(0, 22, 0, 22)
CloseButton.Font = Enum.Font.Gotham
CloseButton.Text = "×"
CloseButton.TextColor3 = Settings.colors.status_off
CloseButton.TextSize = 16
CloseButton.AutoButtonColor = false

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    pcall(function() ScreenGui:Destroy() end)
end)

-- Toggle Icon
local ToggleIcon = Instance.new("TextButton")
ToggleIcon.Name = "ToggleIcon"
ToggleIcon.Parent = ScreenGui
ToggleIcon.BackgroundColor3 = Settings.colors.bg_dark
ToggleIcon.BorderSizePixel = 0
ToggleIcon.Size = UDim2.new(0, 50, 0, 50)
ToggleIcon.Position = UDim2.new(0, 10, 0.5, -25)
ToggleIcon.Text = "🚀"
ToggleIcon.TextColor3 = Settings.colors.text_secondary
ToggleIcon.TextSize = 24
ToggleIcon.Font = Enum.Font.GothamBold
ToggleIcon.AutoButtonColor = false
ToggleIcon.Active = true
ToggleIcon.ZIndex = 10

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = ToggleIcon

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(150, 150, 160)
toggleStroke.Thickness = 1
toggleStroke.Transparency = 0.5
toggleStroke.Parent = ToggleIcon

ToggleIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Content Area (Simple)
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundColor3 = Settings.colors.bg_dark
ContentFrame.BorderSizePixel = 0
ContentFrame.Position = UDim2.new(0, 0, 0, 40)
ContentFrame.Size = UDim2.new(1, 0, 1, -40)

local contentLabel = Instance.new("TextLabel")
contentLabel.Parent = ContentFrame
contentLabel.BackgroundTransparency = 1
contentLabel.Size = UDim2.new(1, 0, 1, 0)
contentLabel.Font = Enum.Font.Gotham
contentLabel.Text = "✅ Bootstrap Loaded!\n\n📌 Modules loading...\n\n🔧 Press RIGHT CTRL to toggle"
contentLabel.TextColor3 = Settings.colors.text_secondary
contentLabel.TextSize = 14
contentLabel.TextYAlignment = Enum.TextYAlignment.Center
contentLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Toggle with RIGHT CTRL
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

safe_print("✅ Bootstrap GUI created successfully!")
safe_print("📌 Press RIGHT CTRL to toggle menu")

return {
    gui = ScreenGui,
    settings = Settings,
}
