--[[
    Alpha Project - Fly Feature
    Movement ability dengan velocity control
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local FlyFeature = {}

local FLY_SPEEDS = { 40, 80, 150, 300, 500 }
local flyActive = false
local bodyVelocity = nil
local bodyGyro = nil
local flyAnimation = nil

local function get_fly_speed()
    local idx = tonumber(Settings.features.flySpeed) or 2
    idx = math.clamp(idx, 1, 5)
    return FLY_SPEEDS[idx]
end

-- ============================================
-- ANIMATION HELPERS
-- ============================================

local function stop_all_animations(humanoid)
    if not humanoid then return end
    pcall(function()
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
    end)
end

local function get_fly_anim_id(humanoid)
    -- Deteksi R6 atau R15
    if humanoid.RigType == Enum.HumanoidRigType.R15 then
        return "rbxassetid://507767714" -- R15 Fly/Hover (Gaya keren)
    else
        return "rbxassetid://180436148" -- R6 Fall/Fly
    end
end

-- ============================================
-- START FLY
-- ============================================

function FlyFeature.start()
    if flyActive then return end
    
    local char = Services.get_character()
    local hrp = Services.get_humanoid_root_part()
    local humanoid = Services.get_humanoid()
    if not hrp or not humanoid then return end
    
    flyActive = true
    Settings.features.flyEnabled = true
    
    -- Setup Animation
    pcall(function()
        stop_all_animations(humanoid)
        
        local anim = Instance.new("Animation")
        anim.AnimationId = get_fly_anim_id(humanoid)
        
        local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
        flyAnimation = animator:LoadAnimation(anim)
        flyAnimation.Priority = Enum.AnimationPriority.Action
        flyAnimation.Looped = true
        flyAnimation:Play(0.1)
    end)
    
    -- Physics Setup
    humanoid.PlatformStand = true
    
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = hrp
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.D = 100
    bodyGyro.P = 10000
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp
    
    -- Setup movement loop
    Settings.connections.fly = Services.RunService.Heartbeat:Connect(function()
        if not flyActive or not Services.get_humanoid_root_part() then
            FlyFeature.stop()
            return
        end
        
        local camera = Services.Camera
        local moveVector = Vector3.new(0, 0, 0)
        
        -- WASD + Space + Shift
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector = moveVector - Vector3.new(0, 1, 0) end
        
        bodyVelocity.Velocity = moveVector * get_fly_speed()
        
        -- Update Orientation
        if moveVector.Magnitude > 0 then
            bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + moveVector)
        else
            bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + camera.CFrame.LookVector)
        end
        
        -- Bersihkan animasi game yang mencoba override (setiap beberapa frame)
        if math.random(1, 10) == 1 then
            pcall(function()
                for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                    if track ~= flyAnimation then
                        track:Stop(0)
                    end
                end
            end)
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
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        stop_all_animations(humanoid)
    end
    
    if flyAnimation then
        pcall(function() flyAnimation:Stop() end)
        flyAnimation = nil
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
