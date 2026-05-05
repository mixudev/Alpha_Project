--[[
    Alpha Project - Audio Manager
    Mengatur volume seluruh suara di map secara cerdas (Musik, SFX, Aksi, dll).
    Mengecualikan suara Voice Chat / Mic agar tetap terdengar.
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local AudioManager = {}

local originalVolumes = {} -- {[Sound] = originalVolume}
local currentVolumeScale = 1.0

-- Deteksi apakah suara tersebut adalah Voice Chat / Mic pemain
local function is_voice_sound(sound)
    if not sound:IsA("Sound") then return false end
    
    local name = sound.Name:lower()
    local parent = sound.Parent
    
    -- 1. Berdasarkan nama umum voice chat
    if name:find("voice") or name:find("mic") or name:find("talk") or name:find("speech") then
        return true
    end
    
    -- 2. Suara di bawah karakter (biasanya voice chat atau sound effect karakter spesifik)
    -- Kita coba lebih spesifik: biasanya di dalam Head
    if parent and parent.Name == "Head" and parent.Parent:FindFirstChild("Humanoid") then
        return true
    end
    
    -- 3. Check SoundGroup
    if sound.SoundGroup and (sound.SoundGroup.Name:lower():find("voice") or sound.SoundGroup.Name:lower():find("mic")) then
        return true
    end

    return false
end

-- Terapkan volume berdasarkan scale saat ini
function AudioManager.apply_to_sound(sound)
    if not sound:IsA("Sound") then return end
    if is_voice_sound(sound) then return end
    
    pcall(function()
        -- Simpan volume asli jika belum tercatat
        if not originalVolumes[sound] then
            originalVolumes[sound] = sound.Volume
            
            -- Pantau jika script map merubah volume asli
            sound:GetPropertyChangedSignal("Volume"):Connect(function()
                local target = originalVolumes[sound] * currentVolumeScale
                -- Jika perubahan volumenya signifikan dan bukan dilakukan oleh kita
                if math.abs(sound.Volume - target) > 0.001 then
                    originalVolumes[sound] = sound.Volume
                end
            end)
        end
        
        -- Set ke volume yang diskalakan
        sound.Volume = originalVolumes[sound] * currentVolumeScale
    end)
end

-- Fungsi utama untuk merubah volume seluruh map
function AudioManager.set_volume(scale)
    currentVolumeScale = math.clamp(scale, 0, 1)
    Settings.audio.currentVolume = currentVolumeScale
    
    -- Target lokasi suara yang umum
    local targetServices = {
        Services.Workspace,
        game:GetService("SoundService"),
        game:GetService("Players"),
        game:GetService("ReplicatedStorage") -- Beberapa game menaruh suara di sini untuk di-clone
    }
    
    for _, service in ipairs(targetServices) do
        for _, d in ipairs(service:GetDescendants()) do
            AudioManager.apply_to_sound(d)
        end
    end
end

-- Listener untuk suara yang baru ditambahkan (dynamic sounds)
local function init()
    local targetServices = {
        Services.Workspace,
        game:GetService("SoundService"),
        game:GetService("Players"),
        game:GetService("ReplicatedStorage")
    }
    
    for _, service in ipairs(targetServices) do
        service.DescendantAdded:Connect(function(d)
            if d:IsA("Sound") then
                task.wait(0.1) -- Beri jeda agar script map selesai inisialisasi volumenya
                AudioManager.apply_to_sound(d)
            end
        end)
    end
    
    -- Initial apply
    AudioManager.set_volume(Settings.audio.currentVolume)
end

task.spawn(init)

return AudioManager
