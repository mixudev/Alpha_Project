--[[
    Alpha Project - Fly Feature
    Movement ability dengan velocity control yang robust
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
local smoothness = 0.15

local function get_fly_speed()
    local idx = tonumber(Settings.features.flySpeed) or 2
    idx = math.clamp(idx, 1, 5)
    return FLY_SPEEDS[idx]
end

-- ============================================
-- PHYSICS OBJECT MANAGEMENT
-- ============================================

local function ensure_physics_objects(hrp)
    if not hrp then return end
    
    if not bodyVelocity or not bodyVelocity.Parent or bodyVelocity.Parent ~= hrp then
        if bodyVelocity then pcall(function() bodyVelocity:Destroy() end) end
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "AlphaFlyVelocity"
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = hrp
    end
    
    if not bodyGyro or not bodyGyro.Parent or bodyGyro.Parent ~= hrp then
        if bodyGyro then pcall(function() bodyGyro:Destroy() end) end
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "AlphaFlyGyro"
        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.D = 400
        bodyGyro.P = 4000
        bodyGyro.CFrame = hrp.CFrame
        bodyGyro.Parent = hrp
    end
end

-- ============================================
-- START FLY
-- ============================================

function FlyFeature.start()
    -- Clean up previous instance to avoid duplicate loops
    FlyFeature.stop()
    
    local hrp = Services.get_humanoid_root_part()
    local humanoid = Services.get_humanoid()
    if not hrp or not humanoid then 
        -- Jika belum ada character, kita tetap set flyActive=true 
        -- agar saat CharacterAdded terpanggil, dia akan memulainya.
        flyActive = true
        Settings.features.flyEnabled = true
        return 
    end
    
    flyActive = true
    Settings.features.flyEnabled = true
    currentVelocity = Vector3.new(0, 0, 0)
    
    ensure_physics_objects(hrp)
    
    -- Main Loop
    local connection = Services.RunService.Heartbeat:Connect(function()
        if not flyActive then return end
        
        local currentHrp = Services.get_humanoid_root_part()
        local currentHumanoid = Services.get_humanoid()
        local camera = Services.get_camera()
        
        if not currentHrp or not currentHumanoid or not camera then
            return 
        end
        
        -- Maintain objects
        ensure_physics_objects(currentHrp)
        
        -- Input handling
        local moveDirection = Vector3.new(0, 0, 0)
        local uis = Services.UserInputService
        
        -- Standard movement keys
        if uis:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camera.CFrame.RightVector end
        
        -- Vertical movement
        if uis:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
        
        -- Normalization to prevent diagonal speed boost
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
        end
        
        -- Velocity Calculation
        local targetVelocity = moveDirection * get_fly_speed()
        currentVelocity = currentVelocity:Lerp(targetVelocity, smoothness)
        
        if bodyVelocity then
            bodyVelocity.Velocity = currentVelocity
        end
        
        -- Rotation / Orientation Logic
        if bodyGyro then
            local targetCFrame = camera.CFrame
            if moveDirection.Magnitude > 0 then
                -- Look towards movement direction
                local lookAt = CFrame.new(currentHrp.Position, currentHrp.Position + moveDirection)
                -- Banking/Tilt effect
                local sideSpeed = moveDirection:Dot(camera.CFrame.RightVector)
                local tiltAngle = math.rad(-sideSpeed * 25)
                targetCFrame = lookAt * CFrame.Angles(math.rad(-10), 0, tiltAngle)
            end
            bodyGyro.CFrame = bodyGyro.CFrame:Lerp(targetCFrame, 0.15)
        end
        
        -- Enforce state to prevent conflicts
        currentHumanoid.PlatformStand = true
        currentHumanoid.AutoRotate = false
        if currentHumanoid.Sit then
            currentHumanoid.Sit = false
        end
        
        -- Stop standard animations
        for _, track in ipairs(currentHumanoid:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
    end)
    
    Settings.connections.fly = connection
    table.insert(Settings.connections.all, connection)
end

-- ============================================
-- STOP FLY
-- ============================================

function FlyFeature.stop()
    flyActive = false
    Settings.features.flyEnabled = false
    
    -- Disconnect heartbeat
    if Settings.connections.fly then
        Settings.connections.fly:Disconnect()
        Settings.connections.fly = nil
    end
    
    -- Clean up physics objects
    local hrp = Services.get_humanoid_root_part()
    local humanoid = Services.get_humanoid()
    
    if humanoid then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    
    if hrp then
        for _, v in ipairs(hrp:GetChildren()) do
            if v.Name == "AlphaFlyVelocity" or v.Name == "AlphaFlyGyro" then
                v:Destroy()
            end
        end
    end
    
    if bodyVelocity then pcall(function() bodyVelocity:Destroy() end) bodyVelocity = nil end
    if bodyGyro then pcall(function() bodyGyro:Destroy() end) bodyGyro = nil end
end

-- ============================================
-- PUBLIC API
-- ============================================

function FlyFeature.toggle(enabled)
    if enabled then
        FlyFeature.start()
    else
        FlyFeature.stop()
    end
end

function FlyFeature.set_speed(index)
    Settings.features.flySpeed = math.clamp(tonumber(index) or 2, 1, 5)
end

function FlyFeature.get_speed_index()
    return math.clamp(tonumber(Settings.features.flySpeed) or 2, 1, 5)
end

-- Respawn handling: re-initiate fly if it was active
Services.LocalPlayer.CharacterAdded:Connect(function()
    if flyActive then
        task.wait(0.5) -- Wait for character to settle
        if flyActive then -- Check again in case it was toggled off during wait
            FlyFeature.start()
        end
    end
end)

return FlyFeature
