--[[
    Alpha Project - ESP (Enemy See-Through)
    Melihat player dari jarak jauh dengan nama mereka
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local ESP = {}

-- ============================================
-- VARIABLES
-- ============================================

ESP.espBoxes = {}      -- {[player] = {box, label, connection}}
ESP.espConnection = nil

-- ============================================
-- CREATE ESP BOX
-- ============================================

function ESP.create_esp_box(player)
    if not player or not player.Character then return end
    if ESP.espBoxes[player] then return end
    
    local char = player.Character
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end
    
    -- ============================================
    -- CREATE BILLBOARD GUI
    -- ============================================
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AlphaESP_" .. player.Name
    billboard.Parent = hrp
    billboard.Size = UDim2.new(4, 0, 5, 0)
    billboard.MaxDistance = 500  -- Terlihat hingga 500 stud
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    
    -- ============================================
    -- BOX FRAME
    -- ============================================
    
    local boxFrame = Instance.new("Frame")
    boxFrame.Name = "ESPBox"
    boxFrame.Parent = billboard
    boxFrame.BackgroundTransparency = 0.7
    boxFrame.BackgroundColor3 = Color3.fromRGB(100, 200, 100)  -- Green untuk friendly
    boxFrame.BorderSizePixel = 2
    boxFrame.BorderColor3 = Color3.fromRGB(100, 255, 100)
    boxFrame.Size = UDim2.new(1, 0, 1, 0)
    
    -- Ubah warna berdasarkan team
    if player.Team then
        if player.Team == Services.Players.LocalPlayer.Team then
            boxFrame.BackgroundColor3 = Color3.fromRGB(100, 200, 100)  -- Green = friendly
            boxFrame.BorderColor3 = Color3.fromRGB(100, 255, 100)
        else
            boxFrame.BackgroundColor3 = Color3.fromRGB(200, 100, 100)  -- Red = enemy
            boxFrame.BorderColor3 = Color3.fromRGB(255, 100, 100)
        end
    end
    
    -- ============================================
    -- NAME LABEL
    -- ============================================
    
    local label = Instance.new("TextLabel")
    label.Name = "NameLabel"
    label.Parent = boxFrame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, -0.3, 0)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Font = Enum.Font.GothamBold
    label.Text = player.DisplayName or player.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.TextScaled = true
    label.TextStrokeTransparency = 0.5
    
    -- ============================================
    -- HEALTH INFO
    -- ============================================
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Parent = boxFrame
    healthLabel.BackgroundTransparency = 1
    healthLabel.Position = UDim2.new(0, 0, 1, 0)
    healthLabel.Size = UDim2.new(1, 0, 0, 18)
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    healthLabel.TextSize = 12
    healthLabel.TextScaled = true
    
    -- ============================================
    -- STORE DATA
    -- ============================================
    
    ESP.espBoxes[player] = {
        billboard = billboard,
        label = label,
        healthLabel = healthLabel,
        boxFrame = boxFrame,
    }
    
    -- ============================================
    -- UPDATE HEALTH INFO
    -- ============================================
    
    local updateConnection
    updateConnection = humanoid.HealthChanged:Connect(function()
        if ESP.espBoxes[player] and ESP.espBoxes[player].healthLabel then
            local health = math.floor(humanoid.Health)
            local maxHealth = math.floor(humanoid.MaxHealth)
            ESP.espBoxes[player].healthLabel.Text = string.format("❤ %d/%d HP", health, maxHealth)
            
            -- Ubah warna berdasarkan health
            if health > maxHealth * 0.5 then
                ESP.espBoxes[player].healthLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            elseif health > maxHealth * 0.25 then
                ESP.espBoxes[player].healthLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            else
                ESP.espBoxes[player].healthLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
        end
    end)
    
    -- Cleanup jika player hilang
    local charDestroyedConnection
    charDestroyedConnection = char.Humanoid.Died:Connect(function()
        ESP.remove_esp_box(player)
    end)
    
    if ESP.espBoxes[player] then
        ESP.espBoxes[player].updateConnection = updateConnection
        ESP.espBoxes[player].charDestroyedConnection = charDestroyedConnection
    end
    
    print("✨ ESP box created for:", player.Name)
end

-- ============================================
-- REMOVE ESP BOX
-- ============================================

function ESP.remove_esp_box(player)
    if not ESP.espBoxes[player] then return end
    
    local box = ESP.espBoxes[player]
    
    -- Disconnect events
    if box.updateConnection then
        pcall(function() box.updateConnection:Disconnect() end)
    end
    if box.charDestroyedConnection then
        pcall(function() box.charDestroyedConnection:Disconnect() end)
    end
    
    -- Destroy GUI
    if box.billboard then
        pcall(function() box.billboard:Destroy() end)
    end
    
    ESP.espBoxes[player] = nil
    print("✨ ESP box removed for:", player.Name)
end

-- ============================================
-- ENABLE ESP
-- ============================================

function ESP.enable()
    if Settings.features.espEnabled then return end
    
    Settings.features.espEnabled = true
    
    -- Create ESP boxes untuk semua player yang ada
    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= Services.Players.LocalPlayer then
            ESP.create_esp_box(player)
        end
    end
    
    -- Listen untuk player baru
    ESP.espConnection = Services.Players.PlayerAdded:Connect(function(player)
        wait(0.5)  -- Tunggu character load
        if Settings.features.espEnabled then
            ESP.create_esp_box(player)
        end
    end)
    
    -- Listen untuk character respawn
    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= Services.Players.LocalPlayer then
            player.CharacterAdded:Connect(function()
                wait(0.3)
                if Settings.features.espEnabled then
                    ESP.create_esp_box(player)
                end
            end)
        end
    end
    
    print("🎯 ESP enabled!")
end

-- ============================================
-- DISABLE ESP
-- ============================================

function ESP.disable()
    if not Settings.features.espEnabled then return end
    
    Settings.features.espEnabled = false
    
    -- Disconnect main connection
    if ESP.espConnection then
        pcall(function() ESP.espConnection:Disconnect() end)
        ESP.espConnection = nil
    end
    
    -- Remove semua ESP boxes
    for player, _ in pairs(ESP.espBoxes) do
        ESP.remove_esp_box(player)
    end
    
    print("🎯 ESP disabled!")
end

-- ============================================
-- TOGGLE ESP
-- ============================================

function ESP.toggle()
    if Settings.features.espEnabled then
        ESP.disable()
    else
        ESP.enable()
    end
end

return ESP
