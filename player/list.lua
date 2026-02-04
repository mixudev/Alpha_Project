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

-- Warna border untuk koneksi (hijau toska)
local BORDER_TOSKA = Color3.fromRGB(0, 200, 180)

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
    playerFrame.BackgroundColor3 = Settings.colors.bg_light
    playerFrame.Size = UDim2.new(1, -20, 0, 42)
    playerFrame.LayoutOrder = layoutOrder
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = playerFrame
    
    -- Border hijau toska untuk koneksi (teman di map)
    if isFriend then
        local stroke = Instance.new("UIStroke")
        stroke.Color = BORDER_TOSKA
        stroke.Thickness = 2
        stroke.Transparency = 0
        stroke.Parent = playerFrame
    end
    
    -- Player Name Label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = playerFrame
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 12, 0, 0)
    nameLabel.Size = UDim2.new(0.35, 0, 1, 0)
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.Text = player.DisplayName or player.Name
    nameLabel.TextColor3 = Settings.colors.text_secondary
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Info Button
    local infoBtn = ButtonComponent.new(playerFrame, "- Info -", UDim2.new(0.37, 5, 0.5, -16), function()
        pcall(function()
            InfoPopup.show(player)
        end)
    end)
    infoBtn.Size = UDim2.new(0.2, -5, 0, 32)
    
    -- POV Button
    local povBtn = ButtonComponent.new(playerFrame, "- POV -", UDim2.new(0.58, 5, 0.5, -16), function()
        Spectate.start(player)
    end)
    povBtn.Size = UDim2.new(0.2, -5, 0, 32)
    
    -- TP Button
    local tpBtn = ButtonComponent.new(playerFrame, "🚀 TP", UDim2.new(0.79, 5, 0.5, -16), function()
        local targetHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local myHrp = Services.get_humanoid_root_part()
        
        if targetHrp and myHrp then
            myHrp.CFrame = targetHrp.CFrame + Vector3.new(0, 3, 0)
        end
    end)
    tpBtn.Size = UDim2.new(0.2, -5, 0, 32)
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
