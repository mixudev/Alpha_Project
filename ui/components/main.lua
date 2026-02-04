--[[
    Alpha Project - UI Components (Main)
    Central exports untuk semua UI components
]]

local Components = {}

-- ============================================
-- REQUIRE COMPONENTS (loadstring-safe)
-- ============================================

local Alpha = rawget(_G, "Alpha")

local Toggle = (Alpha and Alpha.require) and Alpha.require("ui/components/toggle") or require(script.Parent:FindFirstChild("toggle"))
local Button = (Alpha and Alpha.require) and Alpha.require("ui/components/button") or require(script.Parent:FindFirstChild("button"))
local Section = (Alpha and Alpha.require) and Alpha.require("ui/components/section") or require(script.Parent:FindFirstChild("section"))

-- ============================================
-- EXPORT ALL COMPONENTS
-- ============================================

Components.Toggle = Toggle
Components.Button = Button
Components.Section = Section

return Components
