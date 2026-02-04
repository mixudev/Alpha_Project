--[[
    Alpha Project - Infinity Jump Feature
    Allow jumping multiple times in mid-air
]]

local Services = require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = require(script.Parent.Parent:FindFirstChild("config/settings"))

local InfinityJump = {}

-- ============================================
-- INFINITY JUMP STATE
-- ============================================

local infinityJumpActive = false

-- ============================================
-- START INFINITY JUMP
-- ============================================

function InfinityJump.start()
    if infinityJumpActive then return end
    
    infinityJumpActive = true
    Settings.features.infinityJump = true
    
    -- Connect to JumpRequest
    Settings.connections.infinityJump = Services.UserInputService.JumpRequest:Connect(function()
        if infinityJumpActive then
            local humanoid = Services.get_humanoid()
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
    
    table.insert(Settings.connections.all, Settings.connections.infinityJump)
    print("✅ Infinity Jump activated")
end

-- ============================================
-- STOP INFINITY JUMP
-- ============================================

function InfinityJump.stop()
    if not infinityJumpActive then return end
    
    infinityJumpActive = false
    Settings.features.infinityJump = false
    
    if Settings.connections.infinityJump then
        Settings.connections.infinityJump:Disconnect()
        Settings.connections.infinityJump = nil
    end
    
    print("❌ Infinity Jump deactivated")
end

-- ============================================
-- TOGGLE
-- ============================================

function InfinityJump.toggle(enabled)
    if enabled then
        InfinityJump.start()
    else
        InfinityJump.stop()
    end
end

-- ============================================
-- CLEANUP ON CHARACTER RESPAWN
-- ============================================

Services.LocalPlayer.CharacterAdded:Connect(function(character)
    if infinityJumpActive then
        task.wait(0.5)
        InfinityJump.start()
    end
end)

return InfinityJump
