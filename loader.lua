--[[
    Alpha Project - Main Loader
    Entry point untuk seluruh aplikasi
    Support untuk local script & remote loadstring
    Version: 1.0.3
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
    local Tracker = require_module("player/tracker")
    
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
    local NotifikasiFeature = require_module("features/notifikasi")
    local NightVisionFeature = require_module("features/night_vision")
    local ChamsFeature = require_module("features/chams")
    local SecurityFeature = require_module("features/security")
    
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
    local function on_close_requested(doClose)
        local CoreGui = CoreServices.CoreGui or game:GetService("CoreGui")
        local confirmGui = Instance.new("ScreenGui")
        confirmGui.Name = "AlphaCloseConfirm"
        confirmGui.ResetOnSpawn = false
        confirmGui.DisplayOrder = 300
        confirmGui.Parent = CoreGui
        local box = Instance.new("Frame")
        box.Size = UDim2.new(0, 320, 0, 140)
        box.Position = UDim2.new(0.5, -160, 0.5, -70)
        box.BackgroundColor3 = Config.colors.bg_medium
        box.BorderSizePixel = 0
        box.Parent = confirmGui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = box
        local stroke = Instance.new("UIStroke")
        stroke.Color = Config.colors.text_tertiary
        stroke.Thickness = 1
        stroke.Transparency = 0.6
        stroke.Parent = box
        local msg = Instance.new("TextLabel")
        msg.Parent = box
        msg.Size = UDim2.new(1, -24, 0, 50)
        msg.Position = UDim2.new(0, 12, 0, 16)
        msg.BackgroundTransparency = 1
        msg.Font = Enum.Font.Gotham
        msg.Text = "Yakin tutup? Semua fitur akan dimatikan."
        msg.TextColor3 = Config.colors.text_primary
        msg.TextSize = 14
        msg.TextWrapped = true
        msg.TextXAlignment = Enum.TextXAlignment.Center
        local function destroy_confirm()
            pcall(function() confirmGui:Destroy() end)
        end
        local function yes_close()
            pcall(function() FlyFeature.toggle(false) end)
            pcall(function() NoClipFeature.toggle(false) end)
            pcall(function() InfinityJump.toggle(false) end)
            pcall(function() EspFeature.toggle(false) end)
            pcall(function() InfinityZoomFeature.toggle(false) end)
            pcall(function() TrackingFriendsFeature.toggle(false) end)
            pcall(function() NotifikasiFeature.toggle(false) end)
            pcall(function() AntiAfkFeature.toggle(false) end)
            pcall(function() DroneFeature.toggle(false) end)
            pcall(function() NightVisionFeature.toggle(false) end)
            pcall(function() ChamsFeature.toggle(false) end)
            pcall(function() PlayerSpectate.stop() end)
            Config.reset_all_features()
            destroy_confirm()
            doClose()
        end
        local noBtn = Instance.new("TextButton")
        noBtn.Parent = box
        noBtn.Size = UDim2.new(0.4, -16, 0, 36)
        noBtn.Position = UDim2.new(0.08, 0, 0, 88)
        noBtn.BackgroundColor3 = Config.colors.bg_light
        noBtn.BorderSizePixel = 0
        noBtn.Font = Enum.Font.GothamBold
        noBtn.Text = "Tidak"
        noBtn.TextColor3 = Config.colors.text_secondary
        noBtn.TextSize = 13
        noBtn.MouseButton1Click:Connect(destroy_confirm)
        local noCorner = Instance.new("UICorner")
        noCorner.CornerRadius = UDim.new(0, 6)
        noCorner.Parent = noBtn
        local yesBtn = Instance.new("TextButton")
        yesBtn.Parent = box
        yesBtn.Size = UDim2.new(0.4, -16, 0, 36)
        yesBtn.Position = UDim2.new(0.52, 0, 0, 88)
        yesBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
        yesBtn.BorderSizePixel = 0
        yesBtn.Font = Enum.Font.GothamBold
        yesBtn.Text = "Ya, tutup"
        yesBtn.TextColor3 = Config.colors.text_primary
        yesBtn.TextSize = 13
        yesBtn.MouseButton1Click:Connect(yes_close)
        local yesCorner = Instance.new("UICorner")
        yesCorner.CornerRadius = UDim.new(0, 6)
        yesCorner.Parent = yesBtn
    end
    local UIStructure = UIMain.create({ onCloseRequested = on_close_requested })
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
    local trackerPage = UIPages.create("Tracker", UIStructure.content)
    local securityPage = UIPages.create("Security", UIStructure.content)
    local testPage = UIPages.create("Test", UIStructure.content)
    local utilityPage = UIPages.create("Utility", UIStructure.content)
    local infoPage = UIPages.create("Info", UIStructure.content)

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

    local function render_tracker()
        Config.ui.currentPage = UIPages.show(Config.ui.currentPage, trackerPage)
        pcall(function() Tracker.create(trackerPage) end)
    end

    local function render_security()
        Config.ui.currentPage = UIPages.show(Config.ui.currentPage, securityPage)
        pcall(function()
            for _, c in pairs(securityPage:GetChildren()) do
                if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
            end
            local Section = UIComponents.Section
            Section.new(securityPage, "🛡️ Security", 1)
            local testBtn = Instance.new("TextButton")
            testBtn.Parent = securityPage
            testBtn.LayoutOrder = 2
            testBtn.Size = UDim2.new(1, -20, 0, 42)
            testBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 100)
            testBtn.BorderSizePixel = 0
            testBtn.Font = Enum.Font.GothamBold
            testBtn.Text = "Scan"
            testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            testBtn.TextSize = 14
            testBtn.AutoButtonColor = false
            local testCorner = Instance.new("UICorner")
            testCorner.CornerRadius = UDim.new(0, 6)
            testCorner.Parent = testBtn
            local resultBox = Instance.new("ScrollingFrame")
            resultBox.Name = "SecurityResultBox"
            resultBox.Parent = securityPage
            resultBox.LayoutOrder = 3
            resultBox.Size = UDim2.new(1, -20, 0, 180)
            resultBox.BackgroundColor3 = Config.colors.bg_light
            resultBox.BorderSizePixel = 0
            resultBox.ScrollBarThickness = 6
            resultBox.CanvasSize = UDim2.new(0, 0, 0, 0)
            local resultCorner = Instance.new("UICorner")
            resultCorner.CornerRadius = UDim.new(0, 6)
            resultCorner.Parent = resultBox
            local resultPadding = Instance.new("UIPadding")
            resultPadding.PaddingTop = UDim.new(0, 8)
            resultPadding.PaddingLeft = UDim.new(0, 8)
            resultPadding.PaddingRight = UDim.new(0, 8)
            resultPadding.PaddingBottom = UDim.new(0, 8)
            resultPadding.Parent = resultBox
            local resultList = Instance.new("UIListLayout")
            resultList.Parent = resultBox
            resultList.SortOrder = Enum.SortOrder.LayoutOrder
            resultList.Padding = UDim.new(0, 6)
            local copyBtn = Instance.new("TextButton")
            copyBtn.Parent = securityPage
            copyBtn.LayoutOrder = 4
            copyBtn.Size = UDim2.new(1, -20, 0, 36)
            copyBtn.BackgroundColor3 = Config.colors.bg_light
            copyBtn.BorderSizePixel = 0
            copyBtn.Font = Enum.Font.GothamBold
            copyBtn.Text = "📋 Copy Hasil"
            copyBtn.TextColor3 = Config.colors.text_primary
            copyBtn.TextSize = 12
            copyBtn.Visible = false
            copyBtn.AutoButtonColor = false
            local copyCorner = Instance.new("UICorner")
            copyCorner.CornerRadius = UDim.new(0, 6)
            copyCorner.Parent = copyBtn
            local summaryContainer = Instance.new("Frame")
            summaryContainer.Name = "SecuritySummary"
            summaryContainer.Parent = securityPage
            summaryContainer.LayoutOrder = 5
            summaryContainer.Size = UDim2.new(1, -20, 0, 0)
            summaryContainer.BackgroundTransparency = 1
            summaryContainer.Visible = false
            summaryContainer.AutomaticSize = Enum.AutomaticSize.Y
            local summaryLayout = Instance.new("UIListLayout")
            summaryLayout.Parent = summaryContainer
            summaryLayout.SortOrder = Enum.SortOrder.LayoutOrder
            summaryLayout.Padding = UDim.new(0, 6)
            local summaryTitle = Instance.new("TextLabel")
            summaryTitle.Parent = summaryContainer
            summaryTitle.LayoutOrder = 0
            summaryTitle.Size = UDim2.new(1, 0, 0, 22)
            summaryTitle.BackgroundTransparency = 1
            summaryTitle.Font = Enum.Font.GothamBold
            summaryTitle.Text = "Ringkasan"
            summaryTitle.TextColor3 = Config.colors.text_primary
            summaryTitle.TextSize = 13
            summaryTitle.TextXAlignment = Enum.TextXAlignment.Left
            local lastResultsText = ""
            testBtn.MouseButton1Click:Connect(function()
                testBtn.Text = "Scanning..."
                for _, c in pairs(resultBox:GetChildren()) do
                    if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
                end
                task.spawn(function()
                    local results = SecurityFeature.run_tests()
                    lastResultsText = ""
                    local order = 0
                    for _, r in ipairs(results) do
                        local status = r.status or "OK"
                        local detail = r.detail or ""
                        if r.error then
                            detail = detail .. (detail ~= "" and "\n" or "") .. "Error: " .. tostring(r.error)
                        end
                        lastResultsText = lastResultsText .. "[" .. status .. "] " .. (r.name or r.id) .. "\n" .. detail .. "\n\n"
                        local line = Instance.new("TextLabel")
                        line.Parent = resultBox
                        line.LayoutOrder = order
                        order = order + 1
                        line.Size = UDim2.new(1, -16, 0, 0)
                        line.AutomaticSize = Enum.AutomaticSize.Y
                        line.BackgroundTransparency = 1
                        line.Font = Enum.Font.Gotham
                        line.Text = "[" .. status .. "] " .. (r.name or r.id) .. "\n" .. detail
                        line.TextColor3 = (status == "FATAL" or status == "ERROR") and Color3.fromRGB(220, 100, 100)
                            or (status == "WARNING" and Color3.fromRGB(220, 180, 80))
                            or (status == "INFO" and Config.colors.text_tertiary)
                            or Config.colors.text_secondary
                        line.TextSize = 11
                        line.TextXAlignment = Enum.TextXAlignment.Left
                        line.TextYAlignment = Enum.TextYAlignment.Top
                        line.TextWrapped = true
                    end
                    task.defer(function()
                        resultBox.CanvasSize = UDim2.new(0, 0, 0, math.max(180, resultList.AbsoluteContentSize.Y + 16))
                    end)
                    copyBtn.Visible = true
                    testBtn.Text = "Scan"
                    -- Ringkasan: hapus item lama (kecuali title & layout)
                    for _, c in pairs(summaryContainer:GetChildren()) do
                        if c ~= summaryTitle and not c:IsA("UIListLayout") then c:Destroy() end
                    end
                    local statusToLabel = {
                        FATAL = "rawan disusupi",
                        ERROR = "error saat pengetesan",
                        WARNING = "perlu diperhatikan",
                        INFO = "informatif",
                        OK = "tertutup / aman",
                    }
                    for i, r in ipairs(results) do
                        local status = r.status or "OK"
                        local label = statusToLabel[status] or "—"
                        local shortName = (r.name or r.id):gsub("^Test ", ""):gsub(" %/ .*", "")
                        local line = Instance.new("TextLabel")
                        line.Parent = summaryContainer
                        line.LayoutOrder = i
                        line.Size = UDim2.new(1, 0, 0, 18)
                        line.BackgroundTransparency = 1
                        line.Font = Enum.Font.Gotham
                        line.Text = "• " .. shortName .. ": " .. label
                        line.TextColor3 = (status == "FATAL" or status == "ERROR") and Color3.fromRGB(220, 100, 100)
                            or (status == "WARNING" and Color3.fromRGB(220, 180, 80))
                            or Config.colors.text_secondary
                        line.TextSize = 11
                        line.TextXAlignment = Enum.TextXAlignment.Left
                        line.TextWrapped = true
                    end
                    summaryContainer.Visible = true
                end)
            end)
            copyBtn.MouseButton1Click:Connect(function()
                if lastResultsText and #lastResultsText > 0 then
                    pcall(function()
                        if setclipboard then setclipboard(lastResultsText) end
                    end)
                    pcall(function()
                        local uis = game:GetService("UserInputService")
                        if uis and uis.SetClipboard then uis:SetClipboard(lastResultsText) end
                    end)
                end
            end)
        end)
    end

    local function render_test()
        Config.ui.currentPage = UIPages.show(Config.ui.currentPage, testPage)
        pcall(function()
            for _, c in pairs(testPage:GetChildren()) do
                if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
            end
            local TweenService = game:GetService("TweenService")
            local Section = UIComponents.Section
            local categories = SecurityFeature.get_categories()
            local testList = SecurityFeature.get_test_list()
            local layoutOrder = 1

            local function button_press_effect(btn, origColor)
                origColor = origColor or btn.BackgroundColor3
                TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(90, 100, 120) }):Play()
                task.delay(0.15, function()
                    if btn.Parent then TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = origColor }):Play() end
                end)
            end

            local function show_test_notif(success, message, detail)
                local icon = success and "✓" or "✗"
                pcall(function() NotifikasiFeature.show(message, detail or "", icon) end)
            end

            Section.new(testPage, "🧪 Test Exploitasi", layoutOrder)
            layoutOrder = layoutOrder + 1
            local desc = Instance.new("TextLabel")
            desc.Parent = testPage
            desc.LayoutOrder = layoutOrder
            layoutOrder = layoutOrder + 1
            desc.Size = UDim2.new(1, -20, 0, 40)
            desc.BackgroundTransparency = 1
            desc.Font = Enum.Font.Gotham
            desc.Text = "Test manual satu per satu. Pilih target (Ban), isi pesan (Announce), lalu jalankan. Setiap test mengirim notifikasi berhasil/gagal."
            desc.TextColor3 = Config.colors.text_tertiary
            desc.TextSize = 11
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.TextYAlignment = Enum.TextYAlignment.Top
            desc.TextWrapped = true

            local resultBox = Instance.new("ScrollingFrame")
            resultBox.Name = "TestResultBox"
            resultBox.Size = UDim2.new(1, -20, 0, 180)
            resultBox.BackgroundColor3 = Config.colors.bg_light
            resultBox.BorderSizePixel = 0
            resultBox.ScrollBarThickness = 6
            resultBox.CanvasSize = UDim2.new(0, 0, 0, 0)
            local resultListLayout = Instance.new("UIListLayout")
            resultListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            resultListLayout.Padding = UDim.new(0, 6)
            local resultPadding = Instance.new("UIPadding")
            resultPadding.PaddingTop = UDim.new(0, 8)
            resultPadding.PaddingLeft = UDim.new(0, 8)
            resultPadding.PaddingRight = UDim.new(0, 8)
            resultPadding.PaddingBottom = UDim.new(0, 8)
            local lastTestResultsText = ""
            local function append_result(r)
                local status = r.status or "OK"
                local detail = r.detail or ""
                if r.error then detail = detail .. (detail ~= "" and "\n" or "") .. "Error: " .. tostring(r.error) end
                lastTestResultsText = lastTestResultsText .. "[" .. status .. "] " .. (r.name or r.id) .. "\n" .. detail .. "\n\n"
                local line = Instance.new("TextLabel")
                line.Parent = resultBox
                line.LayoutOrder = #resultBox:GetChildren() - 2
                line.Size = UDim2.new(1, -16, 0, 0)
                line.AutomaticSize = Enum.AutomaticSize.Y
                line.BackgroundTransparency = 1
                line.Font = Enum.Font.Gotham
                line.Text = "[" .. status .. "] " .. (r.name or r.id) .. "\n" .. detail
                line.TextColor3 = (status == "FATAL" or status == "ERROR") and Color3.fromRGB(220, 100, 100)
                    or (status == "WARNING" and Color3.fromRGB(220, 180, 80))
                    or (status == "INFO" and Config.colors.text_tertiary)
                    or Config.colors.text_secondary
                line.TextSize = 11
                line.TextXAlignment = Enum.TextXAlignment.Left
                line.TextYAlignment = Enum.TextYAlignment.Top
                line.TextWrapped = true
                task.defer(function()
                    if resultBox.Parent then
                        resultBox.CanvasSize = UDim2.new(0, 0, 0, math.max(180, resultListLayout.AbsoluteContentSize.Y + 16))
                    end
                end)
            end

            local function make_simple_button(parent, order, label, onClick)
                local btn = Instance.new("TextButton")
                btn.Parent = parent
                btn.LayoutOrder = order
                btn.Size = UDim2.new(1, -20, 0, 36)
                btn.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
                btn.BorderSizePixel = 0
                btn.Font = Enum.Font.GothamBold
                btn.Text = label
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.TextSize = 12
                btn.AutoButtonColor = false
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 6)
                corner.Parent = btn
                btn.MouseButton1Click:Connect(function()
                    button_press_effect(btn)
                    if onClick then onClick() end
                end)
                return btn
            end

            local categoryOrder = { "remote", "env", "scripts", "suspicious" }
            for _, catId in ipairs(categoryOrder) do
                local catLabel = categories[catId]
                if catLabel then
                Section.new(testPage, catLabel, layoutOrder)
                layoutOrder = layoutOrder + 1
                for _, t in ipairs(testList) do
                    if t.category == catId then
                    if t.id == "ban" then
                        Section.new(testPage, "Target player (untuk Test Ban)", layoutOrder)
                        layoutOrder = layoutOrder + 1
                        local players = SecurityFeature.get_players_list()
                        local selectedPlayer = (#players > 0) and players[1].player or nil
                        local row = Instance.new("Frame")
                        row.Parent = testPage
                        row.LayoutOrder = layoutOrder
                        layoutOrder = layoutOrder + 1
                        row.Size = UDim2.new(1, -20, 0, 32)
                        row.BackgroundTransparency = 1
                        local rowList = Instance.new("UIListLayout")
                        rowList.Parent = row
                        rowList.FillDirection = Enum.FillDirection.Horizontal
                        rowList.Padding = UDim.new(0, 6)
                        rowList.VerticalAlignment = Enum.VerticalAlignment.Center
                        for _, p in ipairs(players) do
                            local pBtn = Instance.new("TextButton")
                            pBtn.Parent = row
                            pBtn.Size = UDim2.new(0, 0, 0, 28)
                            pBtn.AutomaticSize = Enum.AutomaticSize.X
                            pBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 60)
                            pBtn.BorderSizePixel = 0
                            pBtn.Font = Enum.Font.Gotham
                            pBtn.Text = " " .. p.name .. " "
                            pBtn.TextColor3 = Config.colors.text_secondary
                            pBtn.TextSize = 11
                            local pCorner = Instance.new("UICorner")
                            pCorner.CornerRadius = UDim.new(0, 4)
                            pCorner.Parent = pBtn
                            pBtn.MouseButton1Click:Connect(function()
                                selectedPlayer = p.player
                                button_press_effect(pBtn, Color3.fromRGB(45, 50, 60))
                                show_test_notif(true, "Target dipilih", p.name)
                            end)
                        end
                        make_simple_button(testPage, layoutOrder, "Test Ban (ke target terpilih)", function()
                            resultBox.Parent = testPage
                            if not selectedPlayer then
                                show_test_notif(false, "Test Ban gagal", "Pilih player dulu.")
                                return
                            end
                            local out = SecurityFeature.execute_test_ban(selectedPlayer)
                            show_test_notif(out.success, out.message, out.detail)
                            append_result({ id = "ban", name = "Test Ban", status = out.success and "OK" or "FAIL", detail = out.detail })
                        end)
                        layoutOrder = layoutOrder + 1
                    elseif t.id == "announcement" then
                        local announceBox = Instance.new("TextBox")
                        announceBox.Parent = testPage
                        announceBox.LayoutOrder = layoutOrder
                        layoutOrder = layoutOrder + 1
                        announceBox.Size = UDim2.new(1, -20, 0, 36)
                        announceBox.BackgroundColor3 = Config.colors.bg_light
                        announceBox.BorderSizePixel = 0
                        announceBox.Font = Enum.Font.Gotham
                        announceBox.PlaceholderText = "Masukkan pesan untuk Announce..."
                        announceBox.Text = ""
                        announceBox.TextColor3 = Config.colors.text_primary
                        announceBox.TextSize = 12
                        announceBox.ClearTextOnFocus = false
                        local abCorner = Instance.new("UICorner")
                        abCorner.CornerRadius = UDim.new(0, 6)
                        abCorner.Parent = announceBox
                        local announcePadding = Instance.new("UIPadding")
                        announcePadding.PaddingLeft = UDim.new(0, 10)
                        announcePadding.PaddingRight = UDim.new(0, 10)
                        announcePadding.Parent = announceBox
                        make_simple_button(testPage, layoutOrder, "Kirim Announce (pesan di atas)", function()
                            resultBox.Parent = testPage
                            local out = SecurityFeature.execute_test_announce(announceBox.Text)
                            show_test_notif(out.success, out.message, out.detail)
                            append_result({ id = "announcement", name = "Test Announce", status = out.success and "OK" or "FAIL", detail = out.detail })
                        end)
                        layoutOrder = layoutOrder + 1
                    elseif t.id == "item" then
                        make_simple_button(testPage, layoutOrder, "Test Item (get/unlock semua)", function()
                            resultBox.Parent = testPage
                            local out = SecurityFeature.execute_test_item()
                            show_test_notif(out.success, out.message, out.detail)
                            append_result({ id = "item", name = "Test Item", status = out.success and "OK" or "FAIL", detail = out.detail })
                        end)
                        layoutOrder = layoutOrder + 1
                    else
                        local testDef = t
                        make_simple_button(testPage, layoutOrder, t.short or t.name, function()
                            resultBox.Parent = testPage
                            local out
                            if testDef.id == "remotes" then out = SecurityFeature.execute_test_remotes()
                            elseif testDef.id == "bindable" then out = SecurityFeature.execute_test_bindable()
                            elseif testDef.id == "loadstring" then out = SecurityFeature.execute_test_loadstring()
                            elseif testDef.id == "getfenv" then out = SecurityFeature.execute_test_getfenv()
                            elseif testDef.id == "http" then out = SecurityFeature.execute_test_http()
                            elseif testDef.id == "admin" then out = SecurityFeature.execute_test_admin()
                            else
                                local r = SecurityFeature.run_single_test(testDef.id)
                                append_result(r)
                                show_test_notif((r.status == "OK" or r.status == "INFO"), r.name, r.detail)
                                return
                            end
                            if out then
                                show_test_notif(out.success, out.message, out.detail)
                                append_result({ id = testDef.id, name = testDef.name, status = out.success and "OK" or "FAIL", detail = out.detail })
                            end
                        end)
                        layoutOrder = layoutOrder + 1
                    end
                end
                end
            end

            Section.new(testPage, "Jalankan Semua (scan)", layoutOrder)
            layoutOrder = layoutOrder + 1
            local testAllBtn = Instance.new("TextButton")
            testAllBtn.Parent = testPage
            testAllBtn.LayoutOrder = layoutOrder
            layoutOrder = layoutOrder + 1
            testAllBtn.Size = UDim2.new(1, -20, 0, 42)
            testAllBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 120)
            testAllBtn.BorderSizePixel = 0
            testAllBtn.Font = Enum.Font.GothamBold
            testAllBtn.Text = "▶ Test Semua (scan)"
            testAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            testAllBtn.TextSize = 14
            testAllBtn.AutoButtonColor = false
            local testAllCorner = Instance.new("UICorner")
            testAllCorner.CornerRadius = UDim.new(0, 6)
            testAllCorner.Parent = testAllBtn
            testAllBtn.MouseButton1Click:Connect(function()
                button_press_effect(testAllBtn, Color3.fromRGB(0, 100, 120))
                resultBox.Parent = testPage
                for _, c in pairs(resultBox:GetChildren()) do
                    if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
                end
                lastTestResultsText = ""
                testAllBtn.Text = "Scanning..."
                task.spawn(function()
                    local results = SecurityFeature.run_tests()
                    for _, r in ipairs(results) do append_result(r) end
                    testAllBtn.Text = "▶ Test Semua (scan)"
                    pcall(function() NotifikasiFeature.show("Scan selesai", #results .. " test dijalankan. Lihat hasil di bawah.", "✓") end)
                end)
            end)

            resultBox.Parent = testPage
            resultBox.LayoutOrder = layoutOrder
            resultListLayout.Parent = resultBox
            resultPadding.Parent = resultBox
            layoutOrder = layoutOrder + 1
            local copyTestBtn = Instance.new("TextButton")
            copyTestBtn.Parent = testPage
            copyTestBtn.LayoutOrder = layoutOrder
            copyTestBtn.Size = UDim2.new(1, -20, 0, 36)
            copyTestBtn.BackgroundColor3 = Config.colors.bg_light
            copyTestBtn.BorderSizePixel = 0
            copyTestBtn.Font = Enum.Font.GothamBold
            copyTestBtn.Text = "📋 Copy Hasil"
            copyTestBtn.TextColor3 = Config.colors.text_primary
            copyTestBtn.TextSize = 12
            copyTestBtn.Visible = true
            copyTestBtn.AutoButtonColor = false
            local copyTestCorner = Instance.new("UICorner")
            copyTestCorner.CornerRadius = UDim.new(0, 6)
            copyTestCorner.Parent = copyTestBtn
            copyTestBtn.MouseButton1Click:Connect(function()
                button_press_effect(copyTestBtn, Config.colors.bg_light)
                if lastTestResultsText and #lastTestResultsText > 0 then
                    pcall(function() if setclipboard then setclipboard(lastTestResultsText) end end)
                    pcall(function()
                        local uis = game:GetService("UserInputService")
                        if uis and uis.SetClipboard then uis:SetClipboard(lastTestResultsText) end
                    end)
                    pcall(function() NotifikasiFeature.show("Copy", "Hasil disalin ke clipboard.", "📋") end)
                end
            end)
        end)
    end

    local function render_utility()
        Config.ui.currentPage = UIPages.show(Config.ui.currentPage, utilityPage)
    end

    local function render_info()
        Config.ui.currentPage = UIPages.show(Config.ui.currentPage, infoPage)
    end

    UISidebar.create_nav_button(UIStructure.sidebar, "Players", "👥", 1, render_players)
    UISidebar.create_nav_button(UIStructure.sidebar, "Settings", "⚙️", 2, render_settings)
    UISidebar.create_nav_button(UIStructure.sidebar, "Drone", "📷", 3, render_drone)
    UISidebar.create_nav_button(UIStructure.sidebar, "Tracker", "🔗", 4, render_tracker)
    UISidebar.create_nav_button(UIStructure.sidebar, "Security", "🛡️", 5, render_security)
    UISidebar.create_nav_button(UIStructure.sidebar, "Test", "🧪", 6, render_test)
    UISidebar.create_nav_button(UIStructure.sidebar, "Utility", "🔧", 7, render_utility)
    UISidebar.create_nav_button(UIStructure.sidebar, "Info", "ℹ️", 8, render_info)

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

        Toggle.new(settingsPage, "ESP", 6, function(enabled)
            pcall(function() EspFeature.toggle(enabled) end)
        end)

        Toggle.new(settingsPage, "Infinity Zoom", 7, function(enabled)
            pcall(function() InfinityZoomFeature.toggle(enabled) end)
        end)

        Toggle.new(settingsPage, "ESP Koneksi", 8, function(enabled)
            pcall(function() TrackingFriendsFeature.toggle(enabled) end)
        end)

        Section.new(settingsPage, "🛡️ Lainnya", 9)
        Toggle.new(settingsPage, "Anti-AFK", 10, function(enabled)
            pcall(function() AntiAfkFeature.toggle(enabled) end)
        end)
    end

    -- Utility page: Night Vision + Chams + Notifikasi + Volume Map
    do
        local Section = UIComponents.Section
        local Toggle = UIComponents.Toggle
        Section.new(utilityPage, "🔧 Visual Utility", 1)
        local chamsTitle = Instance.new("TextLabel")
        chamsTitle.Name = "ChamsTitle"
        chamsTitle.Parent = utilityPage
        chamsTitle.LayoutOrder = 2
        chamsTitle.BackgroundTransparency = 1
        chamsTitle.Size = UDim2.new(1, -20, 0, 24)
        chamsTitle.Font = Enum.Font.GothamBold
        chamsTitle.Text = "Chams — highlight pemain tembus dinding (terlihat dari jauh)"
        chamsTitle.TextColor3 = Config.colors.text_primary
        chamsTitle.TextSize = 12
        chamsTitle.TextXAlignment = Enum.TextXAlignment.Left
        chamsTitle.TextWrapped = true
        Toggle.new(utilityPage, "Chams", 3, function(enabled)
            pcall(function() ChamsFeature.toggle(enabled) end)
        end)

        Section.new(utilityPage, "🔔 Notifikasi", 4)
        Toggle.new(utilityPage, "Notifikasi", 5, function(enabled)
            pcall(function() NotifikasiFeature.toggle(enabled) end)
        end)

        Section.new(utilityPage, "🔊 Audio", 6)
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
            volToggle.Parent = utilityPage
            volToggle.BackgroundColor3 = Config.colors.bg_light
            volToggle.BorderSizePixel = 0
            volToggle.Size = UDim2.new(1, -20, 0, Config.sizes.toggle_height)
            volToggle.LayoutOrder = 7
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
            volLabel.Text = "Volume Map"
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

    -- Info page: Rejoin + User di Map paling atas, lalu pembuat GUI + detail server
    do
        local Section = UIComponents.Section
        local Settings = Config
        local Players = CoreServices.Players
        local RunService = CoreServices.RunService
        local Lighting = CoreServices.Workspace:FindFirstChildOfClass("Lighting") or game:GetService("Lighting")
        local placeId = game.PlaceId or 0
        local jobId = game.JobId or "N/A"
        local maxPlayers = Players.MaxPlayers
        local numPlayers = #Players:GetPlayers()

        local function add_info_row(parent, label, value, order)
            local row = Instance.new("Frame")
            row.Parent = parent
            row.BackgroundColor3 = Settings.colors.bg_light
            row.BorderSizePixel = 0
            row.Size = UDim2.new(1, -20, 0, 32)
            row.LayoutOrder = order
            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 4)
            rowCorner.Parent = row
            local lbl = Instance.new("TextLabel")
            lbl.Parent = row
            lbl.BackgroundTransparency = 1
            lbl.Position = UDim2.new(0, 12, 0, 0)
            lbl.Size = UDim2.new(0.4, 0, 1, 0)
            lbl.Font = Enum.Font.Gotham
            lbl.Text = label
            lbl.TextColor3 = Settings.colors.text_tertiary
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            local val = Instance.new("TextLabel")
            val.Parent = row
            val.BackgroundTransparency = 1
            val.Position = UDim2.new(0.45, 0, 0, 0)
            val.Size = UDim2.new(0.55, -12, 1, 0)
            val.Font = Enum.Font.GothamBold
            val.Text = tostring(value)
            val.TextColor3 = Settings.colors.text_primary
            val.TextSize = 12
            val.TextXAlignment = Enum.TextXAlignment.Right
            val.TextTruncate = Enum.TextTruncate.AtEnd
        end

        local creatorBox = Instance.new("Frame")
        creatorBox.Name = "CreatorBox"
        creatorBox.Parent = infoPage
        creatorBox.BackgroundColor3 = Settings.colors.bg_light
        creatorBox.BorderSizePixel = 0
        creatorBox.Size = UDim2.new(1, -20, 0, 90)
        creatorBox.LayoutOrder = 1
        local creatorCorner = Instance.new("UICorner")
        creatorCorner.CornerRadius = UDim.new(0, Settings.sizes.corner_radius)
        creatorCorner.Parent = creatorBox
        local creatorStroke = Instance.new("UIStroke")
        creatorStroke.Color = Settings.colors.text_tertiary
        creatorStroke.Thickness = 1
        creatorStroke.Transparency = 0.7
        creatorStroke.Parent = creatorBox
        local creatorTitle = Instance.new("TextLabel")
        creatorTitle.Parent = creatorBox
        creatorTitle.BackgroundTransparency = 1
        creatorTitle.Position = UDim2.new(0, 15, 0, 10)
        creatorTitle.Size = UDim2.new(1, -30, 0, 22)
        creatorTitle.Font = Enum.Font.GothamBold
        creatorTitle.Text = "Alpha Project"
        creatorTitle.TextColor3 = Settings.colors.text_primary
        creatorTitle.TextSize = 16
        creatorTitle.TextXAlignment = Enum.TextXAlignment.Left
        local creatorName = Instance.new("TextLabel")
        creatorName.Parent = creatorBox
        creatorName.BackgroundTransparency = 1
        creatorName.Position = UDim2.new(0, 15, 0, 34)
        creatorName.Size = UDim2.new(1, -30, 0, 20)
        creatorName.Font = Enum.Font.Gotham
        creatorName.Text = "Lazuardi Mandegar"
        creatorName.TextColor3 = Settings.colors.text_secondary
        creatorName.TextSize = 14
        creatorName.TextXAlignment = Enum.TextXAlignment.Left
        local creatorRole = Instance.new("TextLabel")
        creatorRole.Parent = creatorBox
        creatorRole.BackgroundTransparency = 1
        creatorRole.Position = UDim2.new(0, 15, 0, 54)
        creatorRole.Size = UDim2.new(1, -30, 0, 18)
        creatorRole.Font = Enum.Font.Gotham
        creatorRole.Text = "Developer · GUI & Script"
        creatorRole.TextColor3 = Settings.colors.text_tertiary
        creatorRole.TextSize = 12
        creatorRole.TextXAlignment = Enum.TextXAlignment.Left

        Section.new(infoPage, "Detail Server", 2)
        add_info_row(infoPage, "User di Map", numPlayers .. " / " .. maxPlayers, 3)
        local gameName = game.Name or "—"
        pcall(function()
            if placeId and placeId > 0 then
                local info = game:GetService("MarketplaceService"):GetProductInfo(placeId, Enum.InfoType.Asset)
                if info and info.Name then gameName = info.Name end
            end
        end)
        local creatorType = tostring(game.CreatorType or "Unknown")
        local creatorId = tostring(game.CreatorId or "—")
        local isStudio = RunService:IsStudio()
        local env = isStudio and "Studio" or "Live"
        add_info_row(infoPage, "Nama Game", game.Name or "—", 4)
        add_info_row(infoPage, "Place ID", placeId, 5)
        add_info_row(infoPage, "Job ID", jobId, 6)
        add_info_row(infoPage, "Creator Type", creatorType, 7)
        add_info_row(infoPage, "Creator ID", creatorId, 8)
        add_info_row(infoPage, "Lingkungan", env, 9)
        if Lighting then
            add_info_row(infoPage, "Clock Time", string.format("%.1f", Lighting.ClockTime or 0), 10)
        end
        -- Tombol Copy (Place ID, Job ID)
        local function copy_to_clipboard(text)
            local s = tostring(text)
            local ok = pcall(function()
                if setclipboard then setclipboard(s) return true end
            end)
            if not ok then
                pcall(function()
                    local uis = game:GetService("UserInputService")
                    if uis and uis.SetClipboard then uis:SetClipboard(s) end
                end)
            end
        end
        local copyRow = Instance.new("Frame")
        copyRow.Parent = infoPage
        copyRow.BackgroundTransparency = 1
        copyRow.Size = UDim2.new(1, -20, 0, 40)
        copyRow.LayoutOrder = 11
        local copyPlaceBtn = Instance.new("TextButton")
        copyPlaceBtn.Parent = copyRow
        copyPlaceBtn.Size = UDim2.new(0.48, 0, 0, 36)
        copyPlaceBtn.Position = UDim2.new(0, 0, 0, 0)
        copyPlaceBtn.BackgroundColor3 = Settings.colors.bg_light
        copyPlaceBtn.BorderSizePixel = 0
        copyPlaceBtn.Font = Enum.Font.GothamBold
        copyPlaceBtn.Text = "📋 Copy Place ID"
        copyPlaceBtn.TextColor3 = Settings.colors.text_primary
        copyPlaceBtn.TextSize = 12
        copyPlaceBtn.AutoButtonColor = false
        local c1 = Instance.new("UICorner")
        c1.CornerRadius = UDim.new(0, 6)
        c1.Parent = copyPlaceBtn
        copyPlaceBtn.MouseButton1Click:Connect(function()
            copy_to_clipboard(placeId)
        end)
        local copyJobBtn = Instance.new("TextButton")
        copyJobBtn.Parent = copyRow
        copyJobBtn.Size = UDim2.new(0.48, 0, 0, 36)
        copyJobBtn.Position = UDim2.new(0.52, 0, 0, 0)
        copyJobBtn.BackgroundColor3 = Settings.colors.bg_light
        copyJobBtn.BorderSizePixel = 0
        copyJobBtn.Font = Enum.Font.GothamBold
        copyJobBtn.Text = "📋 Copy Job ID"
        copyJobBtn.TextColor3 = Settings.colors.text_primary
        copyJobBtn.TextSize = 12
        copyJobBtn.AutoButtonColor = false
        local c2 = Instance.new("UICorner")
        c2.CornerRadius = UDim.new(0, 6)
        c2.Parent = copyJobBtn
        copyJobBtn.MouseButton1Click:Connect(function()
            copy_to_clipboard(jobId)
        end)
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
                    if not playersPage:GetAttribute("LastUpdate") or (tick() - playersPage:GetAttribute("LastUpdate")) > 4 then
                        playersPage:SetAttribute("LastUpdate", tick())
                        PlayerList.create(playersPage)
                    end
                end
            end)
        end
    end)
    
    print("✅ UI Created")
    print("✅✅✅ Alpha Project Loaded Successfully! ✅✅✅")
    print("📌 Version: 1.0.3")
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
