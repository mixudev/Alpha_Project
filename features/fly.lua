--[[
    Alpha Project - Fly Feature
    Movement ability dengan velocity control dan animasi terbang
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local FlyFeature = {}

local FLY_SPEEDS = { 28, 58, 98, 160, 250 }
local flyActive = false
local bodyVelocity = nil
local humanoid = nil

local function get_fly_speed()
    local idx = tonumber(Settings.features.flySpeed) or 2
    idx = math.clamp(idx, 1, 5)
    return FLY_SPEEDS[idx]
end

local function get_humanoid()
    local character = Services.LocalPlayer.Character
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

-- ============================================
-- START FLY
-- ============================================

function FlyFeature.start()
    if flyActive then return end
    
    local hrp = Services.get_humanoid_root_part()
    if not hrp then return end
    
    humanoid = get_humanoid()
    if not humanoid then return end
    
    flyActive = true
    Settings.features.flyEnabled = true
    
    -- Set Flying state untuk animasi terbang
    pcall(function()
        humanoid:ChangeState(Enum.HumanoidStateType.Flying)
    end)
    
    -- Create BodyVelocity dengan MaxForce yang lebih optimal
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = hrp
    
    -- Setup movement loop dengan optimasi
    local lastUpdate = 0
    Settings.connections.fly = Services.RunService.Heartbeat:Connect(function()
        if not flyActive then
            FlyFeature.stop()
            return
        end
        
        local currentHrp = Services.get_humanoid_root_part()
        if not currentHrp then
            FlyFeature.stop()
            return
        end
        
        -- Update humanoid reference jika perlu
        if not humanoid or not humanoid.Parent then
            humanoid = get_humanoid()
            if humanoid then
                pcall(function()
                    humanoid:ChangeState(Enum.HumanoidStateType.Flying)
                end)
            end
        end
        
        -- Optimasi: skip jika terlalu cepat (reduce unnecessary updates)
        local now = tick()
        if now - lastUpdate < 0.01 then return end
        lastUpdate = now
        
        local camera = Services.Camera
        local moveVector = Vector3.new(0, 0, 0)
        
        -- WASD + Space + Shift dengan normalisasi untuk gerakan konsisten
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVector = moveVector + camera.CFrame.LookVector
        end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVector = moveVector - camera.CFrame.LookVector
        end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVector = moveVector - camera.CFrame.RightVector
        end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVector = moveVector + camera.CFrame.RightVector
        end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVector = moveVector + Vector3.new(0, 1, 0)
        end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveVector = moveVector - Vector3.new(0, 1, 0)
        end
        
        -- Normalisasi untuk gerakan konsisten di semua arah
        if moveVector.Magnitude > 0 then
            moveVector = moveVector.Unit * get_fly_speed()
        end
        
        -- Smooth velocity update
        if bodyVelocity and bodyVelocity.Parent == currentHrp then
            bodyVelocity.Velocity = moveVector
        end
    end)
    
    table.insert(Settings.connections.all, Settings.connections.fly)
    print("✅ Fly activated")
end

-- ============================================
-- STOP FLY
-- ============================================

function FlyFeature.stop()
    if not flyActive then return end
    
    flyActive = false
    Settings.features.flyEnabled = false
    
    -- Kembalikan ke state normal
    if humanoid then
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
            task.wait(0.1)
            humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        end)
        humanoid = nil
    end
    
    if Settings.connections.fly then
        Settings.connections.fly:Disconnect()
        Settings.connections.fly = nil
    end
    
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    
    print("❌ Fly deactivated")
end

-- ============================================
-- TOGGLE
-- ============================================

function FlyFeature.toggle(enabled)
    if enabled then
        FlyFeature.start()
    else
        FlyFeature.stop()
    end
end

function FlyFeature.set_speed(index)
    local idx = math.clamp(tonumber(index) or 2, 1, 5)
    Settings.features.flySpeed = idx
end

function FlyFeature.get_speed_index()
    return math.clamp(tonumber(Settings.features.flySpeed) or 2, 1, 5)
end

-- ============================================
-- CLEANUP ON CHARACTER RESPAWN
-- ============================================

Services.LocalPlayer.CharacterAdded:Connect(function(character)
    if flyActive then
        task.wait(0.5)
        FlyFeature.start()
    end
end)

return FlyFeature
