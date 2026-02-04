--[[
    Alpha Project - Button Component
    Reusable button with hover effects
]]

local Alpha = rawget(_G, "Alpha")
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent.Parent:FindFirstChild("config/settings"))
local TweenUtil = (Alpha and Alpha.require) and Alpha.require("utils/tween") or require(script.Parent.Parent.Parent:FindFirstChild("utils/tween"))

local ButtonComponent = {}

-- ============================================
-- CREATE BUTTON
-- ============================================

function ButtonComponent.new(parent, text, position, callback)
    if not parent then return nil end
    
    -- Main Button
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    button.BorderSizePixel = 0
    if position then button.Position = position end
    button.Size = UDim2.new(0, 0, 0, Settings.sizes.button_height)
    button.Font = Enum.Font.Gotham
    button.Text = text
    button.TextColor3 = Settings.colors.text_primary
    button.TextSize = 12
    button.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Settings.sizes.corner_radius)
    corner.Parent = button
    
    -- ============================================
    -- HOVER EFFECTS
    -- ============================================
    
    button.MouseEnter:Connect(function()
        TweenUtil.color(button, Color3.fromRGB(50, 50, 60))
    end)
    
    button.MouseLeave:Connect(function()
        TweenUtil.color(button, Color3.fromRGB(40, 40, 50))
    end)
    
    -- ============================================
    -- CLICK HANDLER
    -- ============================================
    
    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)
    
    return button
end

return ButtonComponent
