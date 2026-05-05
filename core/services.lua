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

function Services.get_camera()
    return Services.Workspace.CurrentCamera
end

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

-- NOTE:
-- In Roblox Studio, HttpEnabled must be true for HttpService:GetAsync().
-- In many executors, `game:HttpGet()` (and/or exploit request functions) may work
-- even when HttpEnabled is false. So we treat "HTTP available" as:
-- - HttpService.HttpEnabled OR
-- - game:HttpGet exists OR
-- - syn.request / http_request / request exists

local function has_executor_http()
    if type(game) == "userdata" and type(game.HttpGet) == "function" then
        return true
    end
    if type(syn) == "table" and type(syn.request) == "function" then
        return true
    end
    if type(http_request) == "function" then
        return true
    end
    if type(request) == "function" then
        return true
    end
    return false
end

-- Keep old name for compatibility with existing modules.
function Services.is_http_enabled()
    return Services.HttpService.HttpEnabled or has_executor_http()
end

-- More explicit helper.
function Services.can_http()
    return Services.is_http_enabled()
end

if not Services.can_http() then
    warn("⚠️ HTTP is not available (HttpEnabled OFF and no executor HTTP)!")
    warn("ℹ️ Studio: enable Game Settings > Security > Allow HTTP Requests")
end

return Services
