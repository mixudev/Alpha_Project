--[[
    Alpha Project - Section Header Component
    Category header untuk UI sections
]]

local Settings = require(script.Parent.Parent.Parent:FindFirstChild("config/settings"))

local SectionComponent = {}

-- ============================================
-- CREATE SECTION HEADER
-- ============================================

function SectionComponent.new(parent, text, layoutOrder)
    if not parent then return nil end
    
    local header = Instance.new("TextLabel")
    header.Parent = parent
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, -20, 0, 28)
    header.Font = Enum.Font.Gotham
    header.Text = text
    header.TextColor3 = Settings.colors.text_secondary
    header.TextSize = 13
    header.TextXAlignment = Enum.TextXAlignment.Left
    if layoutOrder then header.LayoutOrder = layoutOrder end
    
    return header
end

return SectionComponent
