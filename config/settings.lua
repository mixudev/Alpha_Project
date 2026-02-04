--[[
    Alpha Project - Settings & Configuration
    Menyimpan semua config, settings, dan state global
]]

local Settings = {}

-- ============================================
-- FEATURE SETTINGS
-- ============================================

Settings.features = {
    infinityJump = false,
    flyEnabled = false,
    noClipEnabled = false,
    espEnabled = false,
    infinityZoomEnabled = false,
}

-- ============================================
-- AUDIO SETTINGS
-- ============================================

Settings.audio = {
    currentVolume = 1.0,
    volumeLevels = {1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0},
    currentVolumeIndex = 1,
}

-- ============================================
-- SPECTATE DATA
-- ============================================

Settings.spectate = {
    spectatingPlayer = nil,
    spectateConnection = nil,
}

-- ============================================
-- PLAYER JOIN TIMES (untuk "time on map")
-- ============================================

Settings.playerJoinTimes = {}

-- ============================================
-- UI STATE
-- ============================================

Settings.ui = {
    currentPage = nil,
    minimized = false,
    mainFrameVisible = true,
}

-- ============================================
-- COLLISION STATE (untuk noclip restore)
-- ============================================

Settings.collision = {
    originalCollisionState = {},        -- {[part] = canCollideValue}
}

-- ============================================
-- CONNECTIONS STORAGE
-- ============================================

Settings.connections = {
    all = {},                           -- Array dari semua connections untuk cleanup
    fly = nil,
    noClip = nil,
    infinityJump = nil,
    playerRefresh = nil,
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function Settings.reset_feature(featureName)
    if Settings.features[featureName] then
        Settings.features[featureName] = false
    end
end

function Settings.reset_all_features()
    for key, _ in pairs(Settings.features) do
        Settings.features[key] = false
    end
end

function Settings.clear_connections()
    for _, conn in ipairs(Settings.connections.all) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    Settings.connections.all = {}
end

-- ============================================
-- COLORS (Theme)
-- ============================================

Settings.colors = {
    -- Main Theme
    bg_dark = Color3.fromRGB(20, 20, 25),
    bg_medium = Color3.fromRGB(22, 22, 28),
    bg_light = Color3.fromRGB(25, 25, 32),
    
    -- Text
    text_primary = Color3.fromRGB(240, 240, 250),
    text_secondary = Color3.fromRGB(220, 220, 230),
    text_tertiary = Color3.fromRGB(180, 180, 200),
    
    -- Status Colors
    status_on = Color3.fromRGB(120, 200, 150),
    status_off = Color3.fromRGB(180, 120, 120),
    status_loading = Color3.fromRGB(200, 200, 120),
    
    -- Accents
    accent_friend = Color3.fromRGB(100, 200, 100),
    accent_error = Color3.fromRGB(240, 140, 140),
    accent_hover = Color3.fromRGB(30, 30, 38),
}

-- ============================================
-- UI SIZES (Standardized)
-- ============================================

Settings.sizes = {
    main_width = 500,
    main_height = 400,
    sidebar_width = 140,
    toggle_height = 42,
    button_height = 32,
    corner_radius = 6,
    margin = 15,
    padding = 10,
}

-- ============================================
-- API ENDPOINTS
-- ============================================

Settings.api = {
    -- Keep minimal endpoints (no social/friends features).
    roblox_base = "https://www.roblox.com",
    headshot_api = "https://www.roblox.com/headshot-thumbnail/image?userId=%s&width=150&height=150&format=png",
    http_enabled = game:GetService("HttpService").HttpEnabled,
}

return Settings
