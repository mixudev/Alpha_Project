--[[
    Alpha Project - Fly Feature
    Movement ability dengan velocity control
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local FlyFeature = {}

local FLY_SPEEDS = { 50, 100, 200, 400, 800 }
local flyActive = false
local bodyVelocity = nil
local bodyGyro = nil

local currentVelocity = Vector3.new(0, 0, 0)
local smoothness = 0.15 -- Nilai rendah = lebih licin/smooth

local function get_fly_speed()
    local idx = tonumber(Settings.features.flySpeed) or 2
    idx = math.clamp(idx, 1, 5)
    return FLY_SPEEDS[idx]
end

-- ============================================
-- START FLY
-- ============================================

function FlyFeature.start()
    -- Bersihkan state lama jika ada
    if flyActive then
        FlyFeature.stop()
    end
    
    local char = Services.get_character()
    local hrp = Services.get_humanoid_root_part()
    local humanoid = Services.get_humanoid()
    if not hrp or not humanoid then return end
    
    flyActive = true
    Settings.features.flyEnabled = true
    
    -- Movement Setup
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = hrp
    
    -- Rotation Setup
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.D = 500
    bodyGyro.P = 3000
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp
    
    currentVelocity = Vector3.new(0, 0, 0)
    
    -- Loop pergerakan
    Settings.connections.fly = Services.RunService.RenderStepped:Connect(function(dt)
        if not flyActive or not Services.get_humanoid_root_part() then
            FlyFeature.stop()
            return
        end
        
        local camera = Services.Camera
        local hrp = Services.get_humanoid_root_part()
        local moveDirection = Vector3.new(0, 0, 0)
        
        -- Input Detection
        local uis = Services.UserInputService
        if uis:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
        
        -- Target Velocity & Smoothing
        local targetVelocity = moveDirection * get_fly_speed()
        currentVelocity = currentVelocity:Lerp(targetVelocity, smoothness)
        bodyVelocity.Velocity = currentVelocity
        
        -- Banking / Miring Logic (Efek Pesawat/Superhero)
        local targetCFrame = camera.CFrame
        if moveDirection.Magnitude > 0 then
            -- Hitung rotasi berdasarkan arah gerakan
            local lookAt = CFrame.new(hrp.Position, hrp.Position + moveDirection)
            
            -- Tambahkan efek miring (Tilt)
            local tiltAngle = 0
            local sideSpeed = moveDirection:Dot(camera.CFrame.RightVector)
            tiltAngle = math.rad(-sideSpeed * 30) -- Miring ke samping saat belok
            
            targetCFrame = lookAt * CFrame.Angles(math.rad(-20), 0, tiltAngle) -- Menunduk sedikit saat maju
        end
        
        -- Smooth Rotation Interpolation
        bodyGyro.CFrame = bodyGyro.CFrame:Lerp(targetCFrame, 0.1)
    end)
    
    -- Pastikan tangan dan kaki diam
    pcall(function()
        humanoid.PlatformStand = true
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
    end)
    
    table.insert(Settings.connections.all, Settings.connections.fly)
end

-- ============================================
-- STOP FLY
-- ============================================

function FlyFeature.stop()
    if not flyActive then return end
    
    flyActive = false
    Settings.features.flyEnabled = false
    
    local humanoid = Services.get_humanoid()
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    
    if Settings.connections.fly then
        pcall(function() Settings.connections.fly:Disconnect() end)
        Settings.connections.fly = nil
    end
    
    if bodyVelocity then pcall(function() bodyVelocity:Destroy() end) bodyVelocity = nil end
    if bodyGyro then pcall(function() bodyGyro:Destroy() end) bodyGyro = nil end
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
