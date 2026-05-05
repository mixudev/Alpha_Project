--[[
    Alpha Project - WalkSpeed Feature
    Mengatur kecepatan jalan pemain secara profesional.
    Mendeteksi kecepatan default map untuk menghindari konflik.
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local WalkSpeedFeature = {}

local baseSpeed = 16
local connection = nil
local speedActive = false

-- Function to detect base speed
local function detect_base_speed()
    local humanoid = Services.get_humanoid()
    if humanoid and not speedActive then
        local current = humanoid.WalkSpeed
        -- Jika speed sangat rendah atau 0 (misal sedang stun/cutscene), jangan anggap base speed permanen
        -- Dan jangan anggap speed yang sangat tinggi (di atas 50) sebagai base, 
        -- karena mungkin itu hasil exploit lain atau power-up sementara.
        if current > 1 and current < 50 then 
            baseSpeed = current
        end
    end
    return baseSpeed
end

-- Initialize base speed (aggressive detection at start)
task.spawn(function()
    for i = 1, 10 do
        detect_base_speed()
        task.wait(0.5)
    end
end)

function WalkSpeedFeature.apply()
    local humanoid = Services.get_humanoid()
    if not humanoid then return end
    
    if speedActive then
        humanoid.WalkSpeed = Settings.features.walkSpeedValue
    end
end

function WalkSpeedFeature.start()
    if speedActive then return end
    
    -- Detect base speed one last time before overriding
    detect_base_speed()
    
    speedActive = true
    Settings.features.walkSpeedEnabled = true
    
    -- Loop untuk memastikan speed tetap (antisipasi script map yang reset speed)
    connection = Services.RunService.Stepped:Connect(function()
        if not speedActive then 
            if connection then 
                connection:Disconnect() 
                connection = nil
            end
            return 
        end
        
        local humanoid = Services.get_humanoid()
        if humanoid then
            -- Professional check: only set if different to avoid unnecessary overhead
            -- but frequent enough to beat game scripts.
            if humanoid.WalkSpeed ~= Settings.features.walkSpeedValue then
                humanoid.WalkSpeed = Settings.features.walkSpeedValue
            end
        end
    end)
    
    if connection then
        table.insert(Settings.connections.all, connection)
    end
    
    print("✅ WalkSpeed activated:", Settings.features.walkSpeedValue, "(Base was:", baseSpeed .. ")")
end

function WalkSpeedFeature.stop()
    if not speedActive then return end
    
    speedActive = false
    Settings.features.walkSpeedEnabled = false
    
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    -- Kembalikan ke base speed map
    local humanoid = Services.get_humanoid()
    if humanoid then
        humanoid.WalkSpeed = baseSpeed
    end
    
    print("❌ WalkSpeed deactivated. Restored to:", baseSpeed)
end

function WalkSpeedFeature.toggle(enabled)
    if enabled then
        WalkSpeedFeature.start()
    else
        WalkSpeedFeature.stop()
    end
end

function WalkSpeedFeature.set_speed(value)
    local val = tonumber(value) or 16
    Settings.features.walkSpeedValue = val
    if speedActive then
        WalkSpeedFeature.apply()
    end
end

function WalkSpeedFeature.get_base_speed()
    return baseSpeed
end

-- Handle Respawn
Services.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.5) -- Tunggu script map selesai inisialisasi speed
    detect_base_speed()
    if speedActive then
        WalkSpeedFeature.start() -- Restart loop for new character
    end
end)

-- Background monitor to update base speed when feature is OFF
task.spawn(function()
    while true do
        task.wait(5)
        if not speedActive then
            detect_base_speed()
        end
    end
end)

return WalkSpeedFeature
