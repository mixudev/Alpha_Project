--[[
    Alpha Project - UI Components (Main)
    Central exports untuk semua UI components
]]

local Components = {}

-- ============================================
-- REQUIRE COMPONENTS
-- ============================================

local Toggle = require(script.Parent:FindFirstChild("toggle"))
local Button = require(script.Parent:FindFirstChild("button"))
local Section = require(script.Parent:FindFirstChild("section"))

-- ============================================
-- EXPORT ALL COMPONENTS
-- ============================================

Components.Toggle = Toggle
Components.Button = Button
Components.Section = Section

return Components
