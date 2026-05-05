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
    local camera = Services.get_camera()
    if humanoid and camera then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid
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
    
    local camera = Services.get_camera()
    if not camera then return end
    
    Settings.spectate.spectatingPlayer = targetPlayer
    camera.CameraType = Enum.CameraType.Follow
    camera.CameraSubject = targetHumanoid
    
    -- Monitor for character changes
    Settings.spectate.spectateConnection = targetPlayer.CharacterAdded:Connect(function(newChar)
        local newHumanoid = newChar:FindFirstChild("Humanoid")
        local camera = Services.get_camera()
        if newHumanoid and camera then
            camera.CameraSubject = newHumanoid
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
