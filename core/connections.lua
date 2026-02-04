--[[
    Alpha Project - Core Connections Management
    Handle semua event connections dan cleanup
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent:FindFirstChild("services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local Connections = {}

-- ============================================
-- CHARACTER RESPAWN HANDLER
-- ============================================

function Connections.setup_character_respawn()
    Services.LocalPlayer.CharacterAdded:Connect(function(newChar)
        Services.Character = newChar
        Services.Humanoid = newChar:WaitForChild("Humanoid")
        Services.HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
        
        print("📌 Character respawned")
        
        -- Trigger character-dependent modules to reinitialize
        -- (akan dipanggil dari module-module terkait)
    end)
end

-- ============================================
-- PLAYER JOIN/LEAVE HANDLER (Basic)
-- ============================================

function Connections.setup_player_events()
    Settings.playerJoinTimes[Services.LocalPlayer] = tick()
    
    Services.Players.PlayerAdded:Connect(function(p)
        Settings.playerJoinTimes[p] = tick()
        
        -- Check mutual friends when player joins
        if Settings.friends.friendDataLoaded then
            task.delay(0.5, function()
                local MutualChecker = (Alpha and Alpha.require) and Alpha.require("social/mutual_checker") or require(script.Parent.Parent:FindFirstChild("social/mutual_checker"))
                local Notification = (Alpha and Alpha.require) and Alpha.require("social/notification") or require(script.Parent.Parent:FindFirstChild("social/notification"))
                
                if MutualChecker and Notification then
                    MutualChecker.check(p)
                    
                    -- Show notification if friend and global friend enabled
                    if MutualChecker.has_mutual(p) and Settings.features.globalFriendEnabled then
                        Notification.show_mutual_friend(p)
                    end
                end
            end)
        end
    end)
    
    Services.Players.PlayerRemoving:Connect(function(p)
        Settings.playerJoinTimes[p] = nil
        Settings.friends.playerMutualFriends[p] = nil
        Settings.esp.espGuis[p] = nil
        Settings.esp.espCharConns[p] = nil
    end)
end

-- ============================================
-- CLEANUP ALL CONNECTIONS
-- ============================================

function Connections.cleanup_all()
    print("🧹 Cleaning up all connections...")
    
    for _, conn in ipairs(Settings.connections.all) do
        if conn then
            pcall(function() conn:Disconnect() end)
        end
    end
    Settings.connections.all = {}
    
    -- Cleanup specific connections
    if Settings.connections.fly then
        pcall(function() Settings.connections.fly:Disconnect() end)
        Settings.connections.fly = nil
    end
    
    if Settings.connections.noClip then
        pcall(function() Settings.connections.noClip:Disconnect() end)
        Settings.connections.noClip = nil
    end
    
    if Settings.connections.infinityJump then
        pcall(function() Settings.connections.infinityJump:Disconnect() end)
        Settings.connections.infinityJump = nil
    end
    
    if Settings.connections.godMode then
        pcall(function() Settings.connections.godMode:Disconnect() end)
        Settings.connections.godMode = nil
    end
    
    print("✅ All connections cleaned up")
end

-- ============================================
-- REGISTER CONNECTION (untuk tracking)
-- ============================================

function Connections.register(conn)
    if conn then
        table.insert(Settings.connections.all, conn)
    end
    return conn
end

-- ============================================
-- INITIALIZE
-- ============================================

function Connections.init()
    Connections.setup_character_respawn()
    Connections.setup_player_events()
    print("✅ Core connections initialized")
end

return Connections
