--[[
    Alpha Project - Player List
    Display all players dengan buttons (POV, Info, TP)
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))
local Spectate = (Alpha and Alpha.require) and Alpha.require("player/spectate") or require(script.Parent:FindFirstChild("spectate"))
local InfoPopup = (Alpha and Alpha.require) and Alpha.require("player/info_popup") or require(script.Parent:FindFirstChild("info_popup"))
local ButtonComponent = (Alpha and Alpha.require) and Alpha.require("ui/components/button") or require(script.Parent.Parent:FindFirstChild("ui/components/button"))
local HttpUtil = (Alpha and Alpha.require) and Alpha.require("utils/http") or require(script.Parent.Parent:FindFirstChild("utils/http"))

local PlayerList = {}

-- Warna tema koneksi (hijau toska) - border, bg, dan text selaras
local BORDER_TOSKA = Color3.fromRGB(0, 200, 180)
local BG_TOSKA = Color3.fromRGB(28, 48, 46)
local TEXT_TOSKA = Color3.fromRGB(180, 255, 240)
local BTN_TOSKA = Color3.fromRGB(35, 65, 60)
local BTN_TOSKA_HOVER = Color3.fromRGB(45, 85, 78)

-- ============================================
-- CREATE PLAYER LIST
-- ============================================

function PlayerList.create(scrollContent)
    if not scrollContent then return end
    
    -- Clear existing
    for _, child in pairs(scrollContent:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- "Back to Self" button
    local backFrame = Instance.new("Frame")
    backFrame.Parent = scrollContent
    backFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    backFrame.Size = UDim2.new(1, -20, 0, 36)
    backFrame.LayoutOrder = 0
    
    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(0, 6)
    backCorner.Parent = backFrame
    
    local backBtn = Instance.new("TextButton")
    backBtn.Parent = backFrame
    backBtn.BackgroundTransparency = 1
    backBtn.Size = UDim2.new(1, 0, 1, 0)
    backBtn.Font = Enum.Font.Gotham
    backBtn.Text = "🔙 Back to Self"
    backBtn.TextColor3 = Settings.colors.text_primary
    backBtn.TextSize = 13
    
    backBtn.MouseButton1Click:Connect(function()
        Spectate.stop()
    end)
    
    -- Load friends sekali (untuk koneksi di map)
    if next(Settings.friendIds) == nil and HttpUtil and Services.LocalPlayer then
        task.spawn(function()
            local friends = HttpUtil.get_friends(Services.LocalPlayer.UserId)
            for _, f in ipairs(friends or {}) do
                if f.id then Settings.friendIds[f.id] = true end
            end
            PlayerList.create(scrollContent)
        end)
    end
    
    -- Urutkan: koneksi (teman) di atas, sisanya di bawah
    local players = Services.Players:GetPlayers()
    local friendsFirst, others = {}, {}
    for _, p in ipairs(players) do
        if p ~= Services.LocalPlayer then
            if Settings.friendIds and Settings.friendIds[p.UserId] then
                table.insert(friendsFirst, p)
            else
                table.insert(others, p)
            end
        end
    end
    local order = 1
    for _, player in ipairs(friendsFirst) do
        PlayerList.create_player_entry(scrollContent, player, order, true)
        order = order + 1
    end
    for _, player in ipairs(others) do
        PlayerList.create_player_entry(scrollContent, player, order, false)
        order = order + 1
    end
end

-- ============================================
-- CREATE PLAYER ENTRY
-- ============================================

function PlayerList.create_player_entry(scrollContent, player, layoutOrder, isFriend)
    local playerFrame = Instance.new("Frame")
    playerFrame.Name = player.Name
    playerFrame.Parent = scrollContent
    playerFrame.BackgroundColor3 = isFriend and BG_TOSKA or Settings.colors.bg_light
    playerFrame.Size = UDim2.new(1, -20, 0, 42)
    playerFrame.LayoutOrder = layoutOrder
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = playerFrame
    
    if isFriend then
        local stroke = Instance.new("UIStroke")
        stroke.Color = BORDER_TOSKA
        stroke.Thickness = 2
        stroke.Transparency = 0
        stroke.Parent = playerFrame
    end
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = playerFrame
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 12, 0, 0)
    nameLabel.Size = UDim2.new(0.35, 0, 1, 0)
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.Text = player.DisplayName or player.Name
    nameLabel.TextColor3 = isFriend and TEXT_TOSKA or Settings.colors.text_secondary
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local function make_btn(text, pos, cb)
        if isFriend then
            local btn = Instance.new("TextButton")
            btn.Parent = playerFrame
            btn.Position = pos
            btn.Size = UDim2.new(0.2, -5, 0, 32)
            btn.BackgroundColor3 = BTN_TOSKA
            btn.TextColor3 = TEXT_TOSKA
            btn.Text = text
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = btn
            btn.MouseEnter:Connect(function() btn.BackgroundColor3 = BTN_TOSKA_HOVER end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3 = BTN_TOSKA end)
            btn.MouseButton1Click:Connect(function() pcall(cb) end)
            return btn
        end
        local btn = ButtonComponent.new(playerFrame, text, pos, cb)
        btn.Size = UDim2.new(0.2, -5, 0, 32)
        return btn
    end
    
    make_btn("- Info -", UDim2.new(0.37, 5, 0.5, -16), function()
        InfoPopup.show(player)
    end)
    make_btn("- POV -", UDim2.new(0.58, 5, 0.5, -16), function()
        Spectate.start(player)
    end)
    make_btn("🚀 TP", UDim2.new(0.79, 5, 0.5, -16), function()
        local targetHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local myHrp = Services.get_humanoid_root_part()
        if targetHrp and myHrp then
            myHrp.CFrame = targetHrp.CFrame + Vector3.new(0, 3, 0)
        end
    end)
end

-- ============================================
-- AUTO REFRESH
-- ============================================

function PlayerList.setup_auto_refresh(page)
    Settings.connections.playerRefresh = Services.RunService.Heartbeat:Connect(function()
        if Settings.ui.currentPage == page and page.Visible then
            if not page:GetAttribute("LastUpdate") or 
               (tick() - page:GetAttribute("LastUpdate")) > 2 then
                page:SetAttribute("LastUpdate", tick())
                PlayerList.create(page:FindFirstChild("UIListLayout").Parent)
            end
        end
    end)
end

return PlayerList
