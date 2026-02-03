--[[
    Alpha Project - Toggle Component
    Reusable toggle button with ON/OFF state
]]

local Services = require(script.Parent.Parent.Parent:FindFirstChild("core/services"))
local Settings = require(script.Parent.Parent.Parent:FindFirstChild("config/settings"))
local TweenUtil = require(script.Parent.Parent.Parent:FindFirstChild("utils/tween"))

local ToggleComponent = {}

-- ============================================
-- CREATE TOGGLE
-- ============================================

function ToggleComponent.new(parent, text, layoutOrder, callback)
    if not parent then return nil end
    
    -- Main Frame
    local toggle = Instance.new("TextButton")
    toggle.Name = text .. "Toggle"
    toggle.Parent = parent
    toggle.BackgroundColor3 = Settings.colors.bg_light
    toggle.BorderSizePixel = 0
    toggle.Size = UDim2.new(1, -20, 0, Settings.sizes.toggle_height)
    toggle.Font = Enum.Font.Gotham
    toggle.Text = ""
    toggle.AutoButtonColor = false
    if layoutOrder then toggle.LayoutOrder = layoutOrder end
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Settings.sizes.corner_radius)
    corner.Parent = toggle
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Parent = toggle
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Settings.colors.text_secondary
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Status Label
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Parent = toggle
    status.BackgroundTransparency = 1
    status.Position = UDim2.new(0.7, 0, 0, 0)
    status.Size = UDim2.new(0.3, -15, 1, 0)
    status.Font = Enum.Font.Gotham
    status.Text = "OFF"
    status.TextColor3 = Settings.colors.status_off
    status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Right
    
    -- State
    local isEnabled = false
    
    -- ============================================
    -- HOVER EFFECTS
    -- ============================================
    
    toggle.MouseEnter:Connect(function()
        TweenUtil.color(toggle, Settings.colors.accent_hover)
    end)
    
    toggle.MouseLeave:Connect(function()
        TweenUtil.color(toggle, Settings.colors.bg_light)
    end)
    
    -- ============================================
    -- CLICK HANDLER
    -- ============================================
    
    toggle.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        status.Text = isEnabled and "ON" or "OFF"
        status.TextColor3 = isEnabled and Settings.colors.status_on or Settings.colors.status_off
        
        if callback then
            callback(isEnabled)
        end
    end)
    
    -- ============================================
    -- PUBLIC API
    -- ============================================
    
    local api = {
        toggle = toggle,
        status = status,
        set_enabled = function(enabled)
            isEnabled = enabled
            status.Text = enabled and "ON" or "OFF"
            status.TextColor3 = enabled and Settings.colors.status_on or Settings.colors.status_off
            if callback then callback(enabled) end
        end,
        get_enabled = function()
            return isEnabled
        end,
    }
    
    return api
end

return ToggleComponent
