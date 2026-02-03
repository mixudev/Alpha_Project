--[[
    Alpha Project - Core Services
    Menyimpan referensi ke semua Roblox services yang digunakan
]]

local Services = {}

-- ============================================
-- ROBLOX SERVICES
-- ============================================

Services.Players = game:GetService("Players")
Services.UserInputService = game:GetService("UserInputService")
Services.RunService = game:GetService("RunService")
Services.TweenService = game:GetService("TweenService")
Services.Workspace = game:GetService("Workspace")
Services.ReplicatedStorage = game:GetService("ReplicatedStorage")
Services.CoreGui = game:GetService("CoreGui")
Services.HttpService = game:GetService("HttpService")
Services.TeleportService = game:GetService("TeleportService")

-- ============================================
-- LOCAL PLAYER & CHARACTER SHORTCUTS
-- ============================================

Services.LocalPlayer = Services.Players.LocalPlayer
Services.Character = Services.LocalPlayer.Character or Services.LocalPlayer.CharacterAdded:Wait()
Services.Humanoid = Services.Character:WaitForChild("Humanoid")
Services.HumanoidRootPart = Services.Character:WaitForChild("HumanoidRootPart")
Services.Camera = Services.Workspace.CurrentCamera

-- ============================================
-- HELPER: Get Current Character
-- ============================================

function Services.get_character()
    return Services.LocalPlayer.Character
end

function Services.get_humanoid()
    local char = Services.get_character()
    if not char then return nil end
    return char:FindFirstChild("Humanoid")
end

function Services.get_humanoid_root_part()
    local char = Services.get_character()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- ============================================
-- HTTP CHECK
-- ============================================

function Services.is_http_enabled()
    return Services.HttpService.HttpEnabled
end

if not Services.is_http_enabled() then
    warn("⚠️ HTTP Service is not enabled!")
    warn("ℹ️ Enable it in Game Settings > Security > Allow HTTP Requests")
end

return Services
