--[[
    Alpha Project - Fly Feature
    Movement ability dengan velocity control
]]

local Services = require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = require(script.Parent.Parent:FindFirstChild("config/settings"))

local FlyFeature = {}

-- ============================================
-- FLY STATE
-- ============================================

local flyActive = false
local bodyVelocity = nil

-- ============================================
-- START FLY
-- ============================================

function FlyFeature.start()
    if flyActive then return end
    
    local hrp = Services.get_humanoid_root_part()
    if not hrp then return end
    
    flyActive = true
    Settings.features.flyEnabled = true
    
    -- Create BodyVelocity
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = hrp
    
    -- Setup movement loop
    Settings.connections.fly = Services.RunService.Heartbeat:Connect(function()
        if not flyActive or not Services.get_humanoid_root_part() then
            FlyFeature.stop()
            return
        end
        
        local camera = Services.Camera
        local moveVector = Vector3.new(0, 0, 0)
        
        -- WASD + Space + Shift
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
        
        bodyVelocity.Velocity = moveVector * 50
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
