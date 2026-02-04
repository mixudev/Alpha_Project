--[[
    Alpha Project - Main UI Frame
    Creates main window, title bar, content area, dan toggle icon
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))
local TweenUtil = (Alpha and Alpha.require) and Alpha.require("utils/tween") or require(script.Parent.Parent:FindFirstChild("utils/tween"))

local UIMain = {}

-- ============================================
-- CREATE MAIN GUI STRUCTURE
-- ============================================

function UIMain.create()
    -- Main ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AlphaGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Enabled = true
    ScreenGui.Parent = Services.CoreGui
    
    -- ============================================
    -- MAIN FRAME
    -- ============================================
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Settings.colors.bg_dark
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
    MainFrame.Size = UDim2.new(0, Settings.sizes.main_width, 0, Settings.sizes.main_height)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Visible = true
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, Settings.sizes.corner_radius)
    mainCorner.Parent = MainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(100, 100, 120)
    mainStroke.Thickness = 1
    mainStroke.Transparency = 0.5
    mainStroke.Parent = MainFrame
    
    -- ============================================
    -- TITLE BAR
    -- ============================================
    
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Parent = MainFrame
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    TitleBar.BorderSizePixel = 0
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    
    local titleBarCorner = Instance.new("UICorner")
    titleBarCorner.CornerRadius = UDim.new(0, Settings.sizes.corner_radius)
    titleBarCorner.Parent = TitleBar
    
    -- Title Label
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
    
    -- ============================================
    -- MINIMIZE BUTTON
    -- ============================================
    
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.Parent = TitleBar
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Position = UDim2.new(1, -60, 0.5, -10)
    MinimizeButton.Size = UDim2.new(0, 22, 0, 22)
    MinimizeButton.Font = Enum.Font.Gotham
    MinimizeButton.Text = "─"
    MinimizeButton.TextColor3 = Settings.colors.text_secondary
    MinimizeButton.TextSize = 14
    MinimizeButton.AutoButtonColor = false
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 4)
    minCorner.Parent = MinimizeButton
    
    -- ============================================
    -- CLOSE BUTTON
    -- ============================================
    
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
    
    -- ============================================
    -- CONTENT CONTAINER
    -- ============================================
    
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Parent = MainFrame
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Position = UDim2.new(0, 0, 0, 40)
    ContentContainer.Size = UDim2.new(1, 0, 1, -40)
    
    -- ============================================
    -- SIDEBAR
    -- ============================================
    
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Parent = ContentContainer
    Sidebar.BackgroundColor3 = Settings.colors.bg_medium
    Sidebar.BorderSizePixel = 0
    Sidebar.Size = UDim2.new(0, Settings.sizes.sidebar_width, 1, 0)
    
    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, Settings.sizes.corner_radius)
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
    
    -- ============================================
    -- MAIN CONTENT AREA
    -- ============================================
    
    local MainContent = Instance.new("Frame")
    MainContent.Name = "MainContent"
    MainContent.Parent = ContentContainer
    MainContent.BackgroundColor3 = Settings.colors.bg_dark
    MainContent.BorderSizePixel = 0
    MainContent.Position = UDim2.new(0, Settings.sizes.sidebar_width, 0, 0)
    MainContent.Size = UDim2.new(1, -Settings.sizes.sidebar_width, 1, 0)
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, Settings.sizes.corner_radius)
    contentCorner.Parent = MainContent
    
    -- ============================================
    -- TOGGLE ICON (bisa digeser, icon menu profesional)
    -- ============================================
    
    local ToggleIcon = Instance.new("TextButton")
    ToggleIcon.Name = "ToggleIcon"
    ToggleIcon.Parent = ScreenGui
    ToggleIcon.BackgroundColor3 = Settings.colors.bg_dark
    ToggleIcon.BorderSizePixel = 0
    ToggleIcon.Size = UDim2.new(0, 50, 0, 50)
    ToggleIcon.Position = UDim2.new(0, 10, 0.5, -25)
    ToggleIcon.Text = "☰"
    ToggleIcon.TextColor3 = Settings.colors.text_secondary
    ToggleIcon.TextSize = 26
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
    
    -- Drag: geser icon
    local iconDragging = false
    local iconDragStart = nil
    local iconStartPos = nil
    ToggleIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            iconDragging = false
            iconDragStart = input.Position
            iconStartPos = ToggleIcon.Position
        end
    end)
    ToggleIcon.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if iconDragStart and (input.Position - iconDragStart).Magnitude > 6 then
                iconDragging = true
            end
        end
    end)
    Services.UserInputService.InputChanged:Connect(function(input)
        if not iconDragging or not iconStartPos or not iconDragStart then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - iconDragStart
            ToggleIcon.Position = UDim2.new(
                iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X,
                iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y
            )
        end
    end)
    ToggleIcon.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not iconDragging and iconStartPos then
                MainFrame.Visible = not MainFrame.Visible
                if MainFrame.Visible then
                    TweenUtil.color(toggleStroke, Color3.fromRGB(150, 150, 160))
                else
                    TweenUtil.fade(toggleStroke, 0.7, 0.2)
                end
            end
            iconDragging = false
            iconDragStart = nil
            iconStartPos = nil
        end
    end)
    
    -- ============================================
    -- BUTTON INTERACTIONS
    -- ============================================
    
    -- Minimize Click
    MinimizeButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)
    
    -- Close Click
    CloseButton.MouseButton1Click:Connect(function()
        pcall(function() ScreenGui:Destroy() end)
    end)
    
    -- Toggle Icon Hover
    ToggleIcon.MouseEnter:Connect(function()
        TweenUtil.color(ToggleIcon, Color3.fromRGB(30, 30, 35))
    end)
    
    ToggleIcon.MouseLeave:Connect(function()
        TweenUtil.color(ToggleIcon, Settings.colors.bg_dark)
    end)
    
    -- Minimize Hover
    MinimizeButton.MouseEnter:Connect(function()
        TweenUtil.color(MinimizeButton, Color3.fromRGB(40, 40, 45))
    end)
    
    MinimizeButton.MouseLeave:Connect(function()
        TweenUtil.color(MinimizeButton, Color3.fromRGB(30, 30, 35))
    end)
    
    -- Close Hover
    CloseButton.MouseEnter:Connect(function()
        TweenUtil.color(CloseButton, Color3.fromRGB(50, 35, 35))
    end)
    
    CloseButton.MouseLeave:Connect(function()
        TweenUtil.color(CloseButton, Color3.fromRGB(30, 30, 35))
    end)
    
    -- ============================================
    -- RIGHT CTRL TOGGLE
    -- ============================================
    
    Services.UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.RightControl then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)
    
    -- ============================================
    -- RETURN STRUCTURE
    -- ============================================
    
    return {
        screen_gui = ScreenGui,
        main_frame = MainFrame,
        sidebar = Sidebar,
        content = MainContent,
        title_bar = TitleBar,
        close_btn = CloseButton,
        minimize_btn = MinimizeButton,
        toggle_icon = ToggleIcon,
    }
end

return UIMain
