--[[
    Alpha Project - Spectate/POV System
    Follow-mode camera spectating
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local Spectate = {}

-- ============================================
-- STOP SPECTATING
-- ============================================

function Spectate.stop()
    Settings.spectate.spectatingPlayer = nil
    
    if Settings.spectate.spectateConnection then
        Settings.spectate.spectateConnection:Disconnect()
        Settings.spectate.spectateConnection = nil
    end
    
    local humanoid = Services.get_humanoid()
    if humanoid then
        Services.Camera.CameraType = Enum.CameraType.Custom
        Services.Camera.CameraSubject = humanoid
    end
    
    print("📹 Spectate stopped")
end

-- ============================================
-- START SPECTATING PLAYER
-- ============================================

function Spectate.start(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        return
    end
    
    local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if not targetHumanoid then return end
    
    -- Stop previous spectate
    if Settings.spectate.spectateConnection then
        Spectate.stop()
    end
    
    Settings.spectate.spectatingPlayer = targetPlayer
    Services.Camera.CameraType = Enum.CameraType.Follow
    Services.Camera.CameraSubject = targetHumanoid
    
    -- Monitor for character changes
    Settings.spectate.spectateConnection = targetPlayer.CharacterAdded:Connect(function(newChar)
        local newHumanoid = newChar:FindFirstChild("Humanoid")
        if newHumanoid then
            Services.Camera.CameraSubject = newHumanoid
        end
    end)
    
    print("📹 Spectating:", targetPlayer.Name)
end

-- ============================================
-- TOGGLE SPECTATE
-- ============================================

function Spectate.toggle(targetPlayer, enabled)
    if enabled then
        Spectate.start(targetPlayer)
    else
        Spectate.stop()
    end
end

-- ============================================
-- GET SPECTATING PLAYER
-- ============================================

function Spectate.get_spectating_player()
    return Settings.spectate.spectatingPlayer
end

return Spectate
