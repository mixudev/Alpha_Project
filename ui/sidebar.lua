--[[
    Alpha Project - Sidebar Navigation
    Creates nav buttons dan handles page switching
]]

local Alpha = rawget(_G, "Alpha")
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))
local TweenUtil = (Alpha and Alpha.require) and Alpha.require("utils/tween") or require(script.Parent.Parent:FindFirstChild("utils/tween"))

local UISidebar = {}

-- ============================================
-- CREATE NAV BUTTON
-- ============================================

function UISidebar.create_nav_button(sidebar, text, icon, layoutOrder, callback)
    if not sidebar then return nil end
    
    local button = Instance.new("TextButton")
    button.Name = text .. "NavButton"
    button.Parent = sidebar
    button.BackgroundColor3 = Settings.colors.bg_medium
    button.BorderSizePixel = 0
    button.Size = UDim2.new(1, 0, 0, 40)
    button.Font = Enum.Font.Gotham
    button.Text = icon .. "  " .. text
    button.TextColor3 = Settings.colors.text_tertiary
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
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        if not button:GetAttribute("Active") then
            TweenUtil.color(button, Settings.colors.accent_hover)
        end
    end)
    
    button.MouseLeave:Connect(function()
        if not button:GetAttribute("Active") then
            TweenUtil.color(button, Settings.colors.bg_medium)
        end
    end)
    
    -- Click handler
    button.MouseButton1Click:Connect(function()
        -- Deactivate all buttons
        for _, child in pairs(sidebar:GetChildren()) do
            if child:IsA("TextButton") and child:GetAttribute("Active") then
                child:SetAttribute("Active", false)
                TweenUtil.color(child, Settings.colors.bg_medium)
                child.TextColor3 = Settings.colors.text_tertiary
            end
        end
        
        -- Activate clicked button
        button:SetAttribute("Active", true)
        TweenUtil.color(button, Color3.fromRGB(35, 35, 45))
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        if callback then
            callback()
        end
    end)
    
    return button
end

-- ============================================
-- SET ACTIVE BUTTON
-- ============================================

function UISidebar.set_active(sidebar, buttonName)
    for _, child in pairs(sidebar:GetChildren()) do
        if child:IsA("TextButton") then
            if child.Name == buttonName then
                child:SetAttribute("Active", true)
                TweenUtil.color(child, Color3.fromRGB(35, 35, 45))
                child.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                child:SetAttribute("Active", false)
                TweenUtil.color(child, Settings.colors.bg_medium)
                child.TextColor3 = Settings.colors.text_tertiary
            end
        end
    end
end

return UISidebar
