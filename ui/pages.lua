--[[
    Alpha Project - Page Management
    Creates scrollable pages untuk setiap content area
]]

local Alpha = rawget(_G, "Alpha")
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local UIPages = {}

-- ============================================
-- CREATE PAGE
-- ============================================

function UIPages.create(name, parent)
    if not parent then return nil end
    
    -- ScrollingFrame
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Parent = parent
    page.BackgroundTransparency = 1
    page.Size = UDim2.new(1, 0, 1, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 6
    page.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 110)
    page.BorderSizePixel = 0
    page.Visible = false
    
    -- Layout
    local pageList = Instance.new("UIListLayout")
    pageList.Parent = page
    pageList.SortOrder = Enum.SortOrder.LayoutOrder
    pageList.Padding = UDim.new(0, Settings.sizes.padding)
    
    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingTop = UDim.new(0, Settings.sizes.margin)
    pagePadding.PaddingLeft = UDim.new(0, Settings.sizes.margin)
    pagePadding.PaddingRight = UDim.new(0, Settings.sizes.margin)
    pagePadding.PaddingBottom = UDim.new(0, Settings.sizes.margin)
    pagePadding.Parent = page
    
    -- Auto update canvas size
    pageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pageList.AbsoluteContentSize.Y + 30)
    end)
    
    return page
end

-- ============================================
-- SHOW PAGE
-- ============================================

function UIPages.show(currentPage, newPage)
    if currentPage then
        currentPage.Visible = false
    end
    if newPage then
        newPage.Visible = true
    end
    return newPage
end

return UIPages
