--[[
    Alpha Project - Working Version
    Ultra simple, no external calls, tested format
]]

local print = print
local warn = warn

print("Loading Alpha...")

-- Check HTTP
local HttpService = game:GetService("HttpService")
if not HttpService.HttpEnabled then
    warn("HTTP not enabled!")
    return
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("No LocalPlayer!")
    return
end

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

print("Services loaded")

-- Settings
local config = {
    fly = false,
    noclip = false,
    jump = false,
}

local bodyVel = nil
local stepConn = nil
local heartbeatConn = nil
local jumpConn = nil

-- Helper functions
local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHRP()
    local char = GetCharacter()
    if char then return char:FindFirstChild("HumanoidRootPart") end
    return nil
end

local function GetHumanoid()
    local char = GetCharacter()
    if char then return char:FindFirstChild("Humanoid") end
    return nil
end

-- Fly
local function FlyOn()
    if config.fly then return end
    config.fly = true
    
    local hrp = GetHRP()
    if not hrp then return end
    
    bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(40000, 40000, 40000)
    bodyVel.Velocity = Vector3.new(0, 0, 0)
    bodyVel.Parent = hrp
    
    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not config.fly then
            if bodyVel then bodyVel:Destroy() end
            if heartbeatConn then heartbeatConn:Disconnect() end
            return
        end
        
        local hrp = GetHRP()
        if not hrp then return end
        
        local vel = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - Vector3.new(0, 1, 0) end
        
        bodyVel.Velocity = vel * 50
    end)
    
    print("✅ Fly ON")
end

local function FlyOff()
    config.fly = false
    if heartbeatConn then heartbeatConn:Disconnect() end
    if bodyVel then bodyVel:Destroy() end
    print("❌ Fly OFF")
end

-- No Clip
local function NoclipOn()
    if config.noclip then return end
    config.noclip = true
    
    stepConn = RunService.Stepped:Connect(function()
        local char = GetCharacter()
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
    
    print("✅ NoClip ON")
end

local function NoclipOff()
    config.noclip = false
    if stepConn then stepConn:Disconnect() end
    
    local char = GetCharacter()
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
    print("❌ NoClip OFF")
end

-- Infinity Jump
local function JumpOn()
    if config.jump then return end
    config.jump = true
    
    jumpConn = UserInputService.JumpRequest:Connect(function()
        local hum = GetHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
    
    print("✅ Jump ON")
end

local function JumpOff()
    config.jump = false
    if jumpConn then jumpConn:Disconnect() end
    print("❌ Jump OFF")
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AlphaGUI"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Parent = gui
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
frame.BorderSizePixel = 0
frame.Position = UDim2.new(0.3, 0, 0.2, 0)
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(100, 100, 120)
stroke.Thickness = 1
stroke.Parent = frame

-- Title
local title = Instance.new("TextLabel")
title.Parent = frame
title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
title.BorderSizePixel = 0
title.Size = UDim2.new(1, 0, 0, 30)
title.Font = Enum.Font.Gotham
title.Text = "🚀 Alpha"
title.TextColor3 = Color3.fromRGB(220, 220, 230)
title.TextSize = 14

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 6)
titleCorner.Parent = title

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Parent = title
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
closeBtn.BorderSizePixel = 0
closeBtn.Position = UDim2.new(1, -25, 0.5, -10)
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Font = Enum.Font.Gotham
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(200, 100, 100)
closeBtn.TextSize = 12
closeBtn.AutoButtonColor = false

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Content
local content = Instance.new("Frame")
content.Parent = frame
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 0, 0, 30)
content.Size = UDim2.new(1, 0, 1, -30)

local list = Instance.new("UIListLayout")
list.Parent = content
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 5)

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 8)
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.Parent = content

-- Button Helper
local function MakeButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Font = Enum.Font.Gotham
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(240, 240, 250)
    btn.TextSize = 12
    btn.AutoButtonColor = false
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Buttons
MakeButton(content, "Fly", function()
    if config.fly then FlyOff() else FlyOn() end
end).LayoutOrder = 1

MakeButton(content, "NoClip", function()
    if config.noclip then NoclipOff() else NoclipOn() end
end).LayoutOrder = 2

MakeButton(content, "Infinity Jump", function()
    if config.jump then JumpOff() else JumpOn() end
end).LayoutOrder = 3

-- Toggle Icon
local toggleIcon = Instance.new("TextButton")
toggleIcon.Name = "ToggleIcon"
toggleIcon.Parent = gui
toggleIcon.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
toggleIcon.BorderSizePixel = 0
toggleIcon.Size = UDim2.new(0, 50, 0, 50)
toggleIcon.Position = UDim2.new(0, 10, 0.5, -25)
toggleIcon.Text = "🚀"
toggleIcon.TextColor3 = Color3.fromRGB(220, 220, 230)
toggleIcon.TextSize = 24
toggleIcon.Font = Enum.Font.GothamBold
toggleIcon.AutoButtonColor = false
toggleIcon.ZIndex = 10

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleIcon

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(100, 100, 120)
toggleStroke.Thickness = 1
toggleStroke.Parent = toggleIcon

toggleIcon.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- Keyboard
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightControl then
        frame.Visible = not frame.Visible
    end
end)

-- Character respawn
LocalPlayer.CharacterAdded:Connect(function()
    if config.fly then
        task.wait(0.3)
        FlyOn()
    end
end)

print("✅✅✅ Alpha Ready! ✅✅✅")
print("Press RIGHT CTRL to toggle menu")
