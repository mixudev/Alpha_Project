--[[
    Alpha Project - Main Loader
    Entry point untuk seluruh aplikasi
    Support untuk local script & remote loadstring
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- ============================================
-- DETECT EXECUTION MODE
-- ============================================

local isRemote = false
local baseUrl = "https://raw.githubusercontent.com/mixudev/Alpha_Project/main"
local ScriptFolder = nil

if script and script.Parent then
    -- Local execution (script in workspace/serverscriptservice)
    isRemote = false
    ScriptFolder = script.Parent
else
    -- Remote execution (loadstring)
    isRemote = true
end

print("🔍 Execution Mode:", isRemote and "REMOTE" or "LOCAL")

-- ============================================
-- MODULE LOADER (Support Both Modes)
-- ============================================

local cache = {}

local function require_module(path)
    -- Check cache first
    if cache[path] then
        return cache[path]
    end
    
    local module
    
    if isRemote then
        -- Remote: try multiple extensions (.lua, .luau)
        local triedUrls = {}
        local content = nil
        local success = false
        for _, ext in ipairs({".lua", ".luau"}) do
            local url = baseUrl .. "/" .. path .. ext
            table.insert(triedUrls, url)

            local ok, res = pcall(function()
                if type(game.HttpGet) == "function" then
                    return game:HttpGet(url)
                else
                    return HttpService:GetAsync(url)
                end
            end)

            if ok and res and #tostring(res) > 5 then
                success = true
                content = res
                break
            end

            -- try proxy for this url
            local proxyUrl = "https://ghproxy.com/" .. url
            local ok2, res2 = pcall(function()
                if type(game.HttpGet) == "function" then
                    return game:HttpGet(proxyUrl)
                else
                    return HttpService:GetAsync(proxyUrl)
                end
            end)

            if ok2 and res2 and #tostring(res2) > 5 then
                success = true
                content = res2
                break
            end
        end

        if not success then
            warn("❌ Failed to load from GitHub (tried):")
            for _, u in ipairs(triedUrls) do warn("   ", u) end
            return nil
        end

        -- Strip UTF-8 BOM if present
        if type(content) == "string" and content:sub(1,3) == "\239\187\191" then
            content = content:sub(4)
        end

        -- Execute the code
        local fn, err = loadstring(content, path)
        if not fn then
            warn("❌ Failed to parse module:", path)
            warn("   Error:", err)
            return nil
        end

        local okExec, resultExec = pcall(fn)
        if not okExec then
            warn("❌ Module execution error:", path)
            warn("   Error:", resultExec)
            return nil
        end
        module = resultExec
    else
        -- Local: Load from script parent
        local moduleName = path:gsub("/", ".")
        local part = ScriptFolder
        
        for segment in path:gmatch("[^/]+") do
            part = part:FindFirstChild(segment)
            if not part then
                warn("❌ Module not found:", path)
                return nil
            end
        end
        
        module = require(part)
    end
    
    cache[path] = module
    return module
end

-- ============================================
-- GLOBAL MODULE ACCESS (for loadstring modules)
-- ============================================
-- Many modules can't rely on `script.Parent` when executed via loadstring.
-- Expose a stable global API so modules can do: Alpha.require("core/services")

do
    local g = _G or getfenv and getfenv(0) or {}
    g.Alpha = g.Alpha or {}
    g.Alpha.require = require_module
    g.Alpha.isRemote = isRemote
    g.Alpha.baseUrl = baseUrl
end

-- ============================================
-- LOAD MODULES (Sequential)
-- ============================================

local function load_all()
    print("🚀 Loading Alpha Project...")
    
    -- IMPORTANT:
    -- In executor mode, `HttpService.HttpEnabled` can be false while `game:HttpGet()`
    -- still works. So don't hard-fail here; modules will use the shared HTTP utility
    -- which tries executor-friendly methods first.
    if isRemote and not HttpService.HttpEnabled then
        warn("⚠️ HttpService.HttpEnabled = false (remote mode).")
        warn("ℹ️ If you're in Studio, enable HTTP Requests; if you're in executor, this can be normal.")
    end
    
    -- 1. Core + Config
    print("📦 Loading Config & Core...")
    local Config = require_module("config/settings")
    local CoreServices = require_module("core/services")
    
    if not Config or not CoreServices then
        warn("❌ Failed to load Core modules")
        return false
    end
    
    print("✅ Config & Core loaded")
    
    -- 2. Utils (Tween, Time)
    print("📦 Loading Utils...")
    local TweenUtil = require_module("utils/tween")
    local TimeUtil = require_module("utils/time")
    
    if not TweenUtil then
        warn("❌ Failed to load Utils")
        return false
    end
    
    print("✅ Utils loaded")
    
    -- 3. UI Components
    print("📦 Loading UI Components...")
    local UIComponents = require_module("ui/components/main")
    
    if not UIComponents then
        warn("❌ Failed to load UI Components")
        return false
    end
    
    print("✅ UI Components loaded")
    
    -- 4. UI Pages
    print("📦 Loading UI Main...")
    local UIMain = require_module("ui/main")
    local UISidebar = require_module("ui/sidebar")
    local UIPages = require_module("ui/pages")
    
    if not UIMain then
        warn("❌ Failed to load UI Main")
        return false
    end
    
    print("✅ UI Main loaded")
    
    -- 5. Player System
    print("📦 Loading Player System...")
    local PlayerList = require_module("player/list")
    local PlayerSpectate = require_module("player/spectate")
    local PlayerInfoPopup = require_module("player/info_popup")
    
    print("✅ Player System loaded")
    
    -- 6. Features (NO social/connection features)
    print("📦 Loading Features...")
    local FlyFeature = require_module("features/fly")
    local NoClipFeature = require_module("features/noclip")
    local InfinityJump = require_module("features/infinity_jump")
    local EspFeature = require_module("features/esp")
    local InfinityZoomFeature = require_module("features/infinity_zoom")
    local DroneFeature = require_module("features/drone")
    local AntiAfkFeature = require_module("features/anti_afk")
    local TrackingFriendsFeature = require_module("features/tracking_friends")
    
    print("✅ Features loaded")

    -- Player join times (untuk info popup "Waktu di Map")
    do
        local Players = CoreServices.Players
        for _, p in ipairs(Players:GetPlayers()) do
            Config.playerJoinTimes[p] = tick()
        end
        Players.PlayerAdded:Connect(function(p)
            Config.playerJoinTimes[p] = tick()
        end)
        Players.PlayerRemoving:Connect(function(p)
            Config.playerJoinTimes[p] = nil
        end)
    end
    
    -- ============================================
    -- Initialize Main UI
    -- ============================================
    
    print("🎨 Creating UI...")
    local UIStructure = UIMain.create()
    if not UIStructure then
        warn("❌ Failed to create main UI")
        return false
    end

    -- ============================================
    -- BUILD PAGES + SIDEBAR
    -- ============================================
    local playersPage = UIPages.create("Players", UIStructure.content)
    local settingsPage = UIPages.create("Settings", UIStructure.content)
    local dronePage = UIPages.create("Drone", UIStructure.content)

    local function render_players()
        Config.ui.currentPage = UIPages.show(Config.ui.currentPage, playersPage)
        pcall(function() PlayerList.create(playersPage) end)
    end

    local function render_settings()
        Config.ui.currentPage = UIPages.show(Config.ui.currentPage, settingsPage)
    end

    local function render_drone()
        Config.ui.currentPage = UIPages.show(Config.ui.currentPage, dronePage)
    end

    UISidebar.create_nav_button(UIStructure.sidebar, "Players", "👥", 1, render_players)
    UISidebar.create_nav_button(UIStructure.sidebar, "Settings", "⚙️", 2, render_settings)
    UISidebar.create_nav_button(UIStructure.sidebar, "Drone", "📷", 3, render_drone)

    -- Default
    render_players()
    UISidebar.set_active(UIStructure.sidebar, "PlayersNavButton")

    -- Settings UI content (only local features)
    do
        local Section = UIComponents.Section
        local Toggle = UIComponents.Toggle

        Section.new(settingsPage, "⚡ Movement", 1)

        Toggle.new(settingsPage, "Infinity Jump", 2, function(enabled)
            pcall(function() InfinityJump.toggle(enabled) end)
        end)

        Toggle.new(settingsPage, "Fly", 3, function(enabled)
            pcall(function() FlyFeature.toggle(enabled) end)
        end)

        Toggle.new(settingsPage, "No Clip", 4, function(enabled)
            pcall(function() NoClipFeature.toggle(enabled) end)
        end)

        Section.new(settingsPage, "🔍 ESP & Camera", 5)

        Toggle.new(settingsPage, "ESP (lihat player dari jauh)", 6, function(enabled)
            pcall(function() EspFeature.toggle(enabled) end)
        end)

        Toggle.new(settingsPage, "Infinity Zoom", 7, function(enabled)
            pcall(function() InfinityZoomFeature.toggle(enabled) end)
        end)

        Toggle.new(settingsPage, "Tracking Friends (scanner koneksi)", 8, function(enabled)
            pcall(function() TrackingFriendsFeature.toggle(enabled) end)
        end)

        Section.new(settingsPage, "🛡️ Lainnya", 9)
        Toggle.new(settingsPage, "Anti-AFK", 10, function(enabled)
            pcall(function() AntiAfkFeature.toggle(enabled) end)
        end)

        Section.new(settingsPage, "🔊 Audio", 11)
        -- Volume Map: satu tombol atur semua suara di map (model, angin, dll)
        do
            local volLevels = {1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0}
            local volIndex = 1
            local function apply_volume(vol)
                Config.audio.currentVolume = vol
                for _, d in pairs(CoreServices.Workspace:GetDescendants()) do
                    if d:IsA("Sound") then
                        pcall(function() d.Volume = vol end)
                    end
                end
            end
            CoreServices.Workspace.DescendantAdded:Connect(function(d)
                if d:IsA("Sound") then
                    pcall(function() d.Volume = Config.audio.currentVolume end)
                end
            end)
            local volToggle = Instance.new("TextButton")
            volToggle.Name = "VolumeMapToggle"
            volToggle.Parent = settingsPage
            volToggle.BackgroundColor3 = Config.colors.bg_light
            volToggle.BorderSizePixel = 0
            volToggle.Size = UDim2.new(1, -20, 0, Config.sizes.toggle_height)
            volToggle.LayoutOrder = 12
            volToggle.Font = Enum.Font.Gotham
            volToggle.Text = ""
            volToggle.AutoButtonColor = false
            local volCorner = Instance.new("UICorner")
            volCorner.CornerRadius = UDim.new(0, Config.sizes.corner_radius)
            volCorner.Parent = volToggle
            local volLabel = Instance.new("TextLabel")
            volLabel.Parent = volToggle
            volLabel.BackgroundTransparency = 1
            volLabel.Position = UDim2.new(0, 12, 0, 0)
            volLabel.Size = UDim2.new(0.7, 0, 1, 0)
            volLabel.Font = Enum.Font.Gotham
            volLabel.Text = "Volume Map (semua suara)"
            volLabel.TextColor3 = Config.colors.text_secondary
            volLabel.TextSize = 13
            volLabel.TextXAlignment = Enum.TextXAlignment.Left
            local volStatus = Instance.new("TextLabel")
            volStatus.Parent = volToggle
            volStatus.BackgroundTransparency = 1
            volStatus.Position = UDim2.new(0.7, 0, 0, 0)
            volStatus.Size = UDim2.new(0.3, -15, 1, 0)
            volStatus.Font = Enum.Font.Gotham
            volStatus.Text = tostring(math.floor(volLevels[volIndex] * 100)) .. "%"
            volStatus.TextColor3 = Config.colors.status_on
            volStatus.TextSize = 13
            volStatus.TextXAlignment = Enum.TextXAlignment.Right
            volToggle.MouseButton1Click:Connect(function()
                volIndex = volIndex + 1
                if volIndex > #volLevels then volIndex = 1 end
                local v = volLevels[volIndex]
                apply_volume(v)
                volStatus.Text = tostring(math.floor(v * 100)) .. "%"
                volStatus.TextColor3 = (v == 0 and Config.colors.status_off or Config.colors.status_on)
            end)
            apply_volume(volLevels[volIndex])
        end
    end

    -- Drone page: keterangan + toggle + speed
    do
        local Section = UIComponents.Section
        local Toggle = UIComponents.Toggle
        local Settings = Config

        Section.new(dronePage, "📷 Drone / Freecam", 1)
        local desc = Instance.new("TextLabel")
        desc.Parent = dronePage
        desc.BackgroundTransparency = 1
        desc.Size = UDim2.new(1, -20, 0, 80)
        desc.LayoutOrder = 2
        desc.Font = Enum.Font.Gotham
        desc.Text = "Kamera bebas dengan gerakan smooth.\nWASD = jalan | E/Q = naik/turun | Panah = putar | Klik kanan = putar mouse.\nLeft Shift = pelan | Right Shift = putar cepat."
        desc.TextColor3 = Settings.colors.text_tertiary
        desc.TextSize = 12
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top
        desc.TextWrapped = true

        Toggle.new(dronePage, "Drone Aktif", 3, function(enabled)
            pcall(function() DroneFeature.toggle(enabled) end)
        end)

        Section.new(dronePage, "Speed", 4)
        local speedRow = Instance.new("TextButton")
        speedRow.Name = "SpeedRow"
        speedRow.Parent = dronePage
        speedRow.BackgroundColor3 = Settings.colors.bg_light
        speedRow.BorderSizePixel = 0
        speedRow.Size = UDim2.new(1, -20, 0, Settings.sizes.toggle_height)
        speedRow.LayoutOrder = 5
        speedRow.Font = Enum.Font.Gotham
        speedRow.Text = ""
        speedRow.AutoButtonColor = false
        local speedCorner = Instance.new("UICorner")
        speedCorner.CornerRadius = UDim.new(0, Settings.sizes.corner_radius)
        speedCorner.Parent = speedRow
        local speedLabel = Instance.new("TextLabel")
        speedLabel.Parent = speedRow
        speedLabel.BackgroundTransparency = 1
        speedLabel.Position = UDim2.new(0, 12, 0, 0)
        speedLabel.Size = UDim2.new(0.6, 0, 1, 0)
        speedLabel.Font = Enum.Font.Gotham
        speedLabel.Text = "Speed"
        speedLabel.TextColor3 = Settings.colors.text_secondary
        speedLabel.TextSize = 13
        speedLabel.TextXAlignment = Enum.TextXAlignment.Left
        local speedVal = Instance.new("TextLabel")
        speedVal.Parent = speedRow
        speedVal.Name = "SpeedValue"
        speedVal.BackgroundTransparency = 1
        speedVal.Position = UDim2.new(0.6, 0, 0, 0)
        speedVal.Size = UDim2.new(0.4, -15, 1, 0)
        speedVal.Font = Enum.Font.GothamBold
        speedVal.Text = "1.0x"
        speedVal.TextColor3 = Settings.colors.status_on
        speedVal.TextSize = 13
        speedVal.TextXAlignment = Enum.TextXAlignment.Right
        local speeds = {0.5, 1.0, 1.5, 2.0, 2.5, 3.0}
        local speedIdx = 2
        local function update_speed()
            local s = speeds[speedIdx]
            DroneFeature.set_speed(s)
            speedVal.Text = string.format("%.1fx", s)
        end
        speedRow.MouseButton1Click:Connect(function()
            speedIdx = speedIdx + 1
            if speedIdx > #speeds then speedIdx = 1 end
            update_speed()
        end)
        update_speed()
    end

    -- Auto refresh player list (when Players page visible)
    pcall(function()
        if Config.connections and CoreServices and CoreServices.RunService then
            if Config.connections.playerRefresh then
                pcall(function() Config.connections.playerRefresh:Disconnect() end)
                Config.connections.playerRefresh = nil
            end
            Config.connections.playerRefresh = CoreServices.RunService.Heartbeat:Connect(function()
                if Config.ui.currentPage == playersPage and playersPage.Visible then
                    if not playersPage:GetAttribute("LastUpdate") or (tick() - playersPage:GetAttribute("LastUpdate")) > 2 then
                        playersPage:SetAttribute("LastUpdate", tick())
                        PlayerList.create(playersPage)
                    end
                end
            end)
        end
    end)
    
    print("✅ UI Created")
    print("✅✅✅ Alpha Project Loaded Successfully! ✅✅✅")
    print("📌 Press RIGHT CTRL to toggle menu")
    print("🔗 Execution Mode:", isRemote and "REMOTE (GitHub)" or "LOCAL")
    
    -- ============================================
    -- Return Public API
    -- ============================================
    
    return {
        Config = Config,
        CoreServices = CoreServices,
        UIMain = UIMain,
        PlayerList = PlayerList,
        FlyFeature = FlyFeature,
        NoClipFeature = NoClipFeature,
        InfinityJump = InfinityJump,
    }
end

-- ============================================
-- START
-- ============================================

local success, result = pcall(load_all)

if not success then
    warn("❌ CRITICAL ERROR:", result)
    warn("⚠️ Check if HTTP is enabled and GitHub URL is correct")
else
    return result
end
