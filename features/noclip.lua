--[[
    Alpha Project - No Clip Feature
    Phase through objects dengan toggle CanCollide
]]

local Services = require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = require(script.Parent.Parent:FindFirstChild("config/settings"))

local NoClipFeature = {}

-- ============================================
-- NO CLIP STATE
-- ============================================

local noClipActive = false
local originalCollisionState = {}

-- ============================================
-- SAVE COLLISION STATE
-- ============================================

local function save_collision_state(character)
    if not character then return end
    
    originalCollisionState = {}
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            originalCollisionState[part] = part.CanCollide
        end
    end
end

-- ============================================
-- RESTORE COLLISION STATE
-- ============================================

local function restore_collision_state(character)
    if not character then return end
    
    for part, canCollide in pairs(originalCollisionState) do
        if part.Parent and part:IsA("BasePart") then
            pcall(function()
                part.CanCollide = canCollide
            end)
        end
    end
    
    -- Restore new parts
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and not originalCollisionState[part] then
            if part.Name ~= "Handle" and not part:FindFirstAncestorOfClass("Accessory") then
                pcall(function()
                    part.CanCollide = true
                end)
            end
        end
    end
    
    originalCollisionState = {}
end

-- ============================================
-- START NO CLIP
-- ============================================

function NoClipFeature.start()
    if noClipActive then return end
    
    local character = Services.get_character()
    if not character then return end
    
    noClipActive = true
    Settings.features.noClipEnabled = true
    
    -- Save state before disabling collision
    save_collision_state(character)
    
    -- Disable collision loop
    Settings.connections.noClip = Services.RunService.Stepped:Connect(function()
        local char = Services.get_character()
        if not char then return end
        
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
    
    table.insert(Settings.connections.all, Settings.connections.noClip)
    print("✅ No Clip activated")
end

-- ============================================
-- STOP NO CLIP
-- ============================================

function NoClipFeature.stop()
    if not noClipActive then return end
    
    noClipActive = false
    Settings.features.noClipEnabled = false
    
    if Settings.connections.noClip then
        Settings.connections.noClip:Disconnect()
        Settings.connections.noClip = nil
    end
    
    local character = Services.get_character()
    if character then
        restore_collision_state(character)
    end
    
    print("❌ No Clip deactivated")
end

-- ============================================
-- TOGGLE
-- ============================================

function NoClipFeature.toggle(enabled)
    if enabled then
        NoClipFeature.start()
    else
        NoClipFeature.stop()
    end
end

-- ============================================
-- CLEANUP ON CHARACTER RESPAWN
-- ============================================

Services.LocalPlayer.CharacterAdded:Connect(function(character)
    if noClipActive then
        task.wait(0.1)
        save_collision_state(character)
    end
end)

return NoClipFeature
