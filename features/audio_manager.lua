--[[
    Alpha Project - Audio Manager
    Mengatur volume seluruh suara di map secara agresif (Musik, SFX, Ambient).
    Mengecualikan suara Voice Chat / Mic agar tetap terdengar.
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local AudioManager = {}

local originalVolumes = {} -- {[Instance] = originalVolume}
local isUpdating = {}      -- {[Instance] = boolean} to prevent feedback loops
local currentVolumeScale = 1.0

-- ============================================
-- VOICE DETECTION (Jangan di-mute)
-- ============================================

local function is_voice_sound(sound)
    if not sound:IsA("Sound") then return false end
    
    local name = sound.Name:lower()
    local parent = sound.Parent
    
    -- 1. Nama umum voice chat
    if name:find("voice") or name:find("mic") or name:find("talk") or name:find("speech") then
        return true
    end
    
    -- 2. Suara di dalam Head (biasanya voice chat)
    if parent and parent.Name == "Head" and parent.Parent:FindFirstChildOfClass("Humanoid") then
        return true
    end
    
    -- 3. Check SoundGroup
    if sound.SoundGroup and (sound.SoundGroup.Name:lower():find("voice") or sound.SoundGroup.Name:lower():find("mic")) then
        return true
    end

    return false
end

-- ============================================
-- CORE LOGIC
-- ============================================

function AudioManager.apply_to_instance(inst)
    if not inst:IsA("Sound") and not inst:IsA("SoundGroup") then return end
    if inst:IsA("Sound") and is_voice_sound(inst) then return end
    
    -- Mencegah loop jika kita yang merubah volumenya
    if isUpdating[inst] then return end
    
    pcall(function()
        if not originalVolumes[inst] then
            originalVolumes[inst] = inst.Volume
            
            -- Pantau perubahan volume dari script game
            inst:GetPropertyChangedSignal("Volume"):Connect(function()
                if isUpdating[inst] then return end
                
                local target = originalVolumes[inst] * currentVolumeScale
                -- Jika script game mencoba merubah volume
                if math.abs(inst.Volume - target) > 0.001 then
                    originalVolumes[inst] = inst.Volume
                    -- Paksa kembali ke skala kita secara instan
                    AudioManager.apply_to_instance(inst)
                end
            end)
        end
        
        -- Set volume dengan flag isUpdating aktif
        isUpdating[inst] = true
        inst.Volume = originalVolumes[inst] * currentVolumeScale
        task.delay(0.05, function() isUpdating[inst] = nil end)
    end)
end

function AudioManager.set_volume(scale)
    currentVolumeScale = math.clamp(scale, 0, 1)
    Settings.audio.currentVolume = currentVolumeScale
    
    local targetServices = {
        Services.Workspace,
        game:GetService("SoundService"),
        game:GetService("Players"),
        game:GetService("ReplicatedStorage"),
        game:GetService("Lighting"),
        game:GetService("StarterGui")
    }
    
    for _, service in ipairs(targetServices) do
        for _, d in ipairs(service:GetDescendants()) do
            if d:IsA("Sound") or d:IsA("SoundGroup") then
                AudioManager.apply_to_instance(d)
            end
        end
    end
end

-- ============================================
-- INITIALIZATION
-- ============================================

local function init()
    local targetServices = {
        Services.Workspace,
        game:GetService("SoundService"),
        game:GetService("Players"),
        game:GetService("ReplicatedStorage"),
        game:GetService("Lighting"),
        game:GetService("StarterGui")
    }
    
    for _, service in ipairs(targetServices) do
        -- Pantau suara baru yang muncul secara dinamis
        service.DescendantAdded:Connect(function(d)
            if d:IsA("Sound") or d:IsA("SoundGroup") then
                task.wait(0.2) -- Tunggu script game inisialisasi volume aslinya
                AudioManager.apply_to_instance(d)
            end
        end)
    end
    
    -- Terapkan volume awal
    AudioManager.set_volume(Settings.audio.currentVolume or 1.0)
end

task.spawn(init)

return AudioManager
