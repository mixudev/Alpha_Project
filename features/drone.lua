--[[
    Alpha Project - Drone / Freecam Feature
    Gerakan smooth dengan lerp (tidak kaku)
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local DroneFeature = {}

local SMOOTH_FACTOR = 0.18
local ROTATE_SMOOTH = 0.25
local SENSITIVITY = 0.35

local active = false
local renderConn = nil
local keysDown = {}
local rotating = false
local leftShiftPressed = false
local rightShiftPressed = false

local originalCameraType, originalCameraSubject, originalFOV
local originalWalkSpeed, originalJumpPower
local characterFrozen = false
local char = nil
local humanoid = nil

-- Speed & rotate (bisa di-set dari UI)
local currentSpeed = 1.0
local currentRotateSpeed = 1.0
local targetCFrame = nil

-- ============================================
-- FREEZE / UNFREEZE CHARACTER
-- ============================================

local function freezeCharacter()
    if not char or characterFrozen then return end
    characterFrozen = true
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end
    if humanoid then
        originalWalkSpeed = humanoid.WalkSpeed
        originalJumpPower = humanoid.JumpPower
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
    end
end

local function unfreezeCharacter()
    if not char or not characterFrozen then return end
    characterFrozen = false
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
        end
    end
    if humanoid then
        humanoid.WalkSpeed = originalWalkSpeed or 16
        humanoid.JumpPower = originalJumpPower or 50
        humanoid.AutoRotate = true
    end
end

-- ============================================
-- ENABLE / DISABLE DRONE
-- ============================================

local function enable_drone()
    if active then return end
    char = Services.get_character()
    humanoid = char and char:FindFirstChild("Humanoid")
    local cam = Services.Camera
    if not cam then return end

    active = true
    Settings.features.droneEnabled = true
    originalCameraType = cam.CameraType
    originalCameraSubject = cam.CameraSubject
    originalFOV = cam.FieldOfView
    targetCFrame = cam.CFrame

    cam.CameraType = Enum.CameraType.Scriptable
    freezeCharacter()

    renderConn = Services.RunService.RenderStepped:Connect(function()
        if not active or not cam then return end
        local finalSpeed = 0.5 * currentSpeed * (leftShiftPressed and 0.3 or 1)
        local finalRotSpeed = 2.5 * currentRotateSpeed * (rightShiftPressed and 2.5 or 1)

        -- Update target dari input
        if keysDown.Left then
            targetCFrame = CFrame.Angles(0, math.rad(finalRotSpeed), 0) * (targetCFrame - targetCFrame.Position) + targetCFrame.Position
        end
        if keysDown.Right then
            targetCFrame = CFrame.Angles(0, -math.rad(finalRotSpeed), 0) * (targetCFrame - targetCFrame.Position) + targetCFrame.Position
        end
        if keysDown.Up then
            local pitch = math.deg(select(1, targetCFrame:ToEulerAnglesYXZ()))
            if pitch - finalRotSpeed/2 > -89 then
                targetCFrame = targetCFrame * CFrame.Angles(math.rad(finalRotSpeed/2), 0, 0)
            end
        end
        if keysDown.Down then
            local pitch = math.deg(select(1, targetCFrame:ToEulerAnglesYXZ()))
            if pitch + finalRotSpeed/2 < 89 then
                targetCFrame = targetCFrame * CFrame.Angles(-math.rad(finalRotSpeed/2), 0, 0)
            end
        end

        if rotating then
            local delta = Services.UserInputService:GetMouseDelta()
            local cf = targetCFrame
            local pitch = math.deg(select(1, cf:ToEulerAnglesYXZ()))
            local newPitch = pitch - delta.Y * SENSITIVITY
            newPitch = math.clamp(newPitch, -89, 89)
            cf = cf * CFrame.Angles(-math.rad(delta.Y * SENSITIVITY), 0, 0)
            cf = CFrame.Angles(0, -math.rad(delta.X * SENSITIVITY), 0) * (cf - cf.Position) + cf.Position
            targetCFrame = cf
            Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        else
            Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end

        -- Movement: update target position
        if keysDown.W then targetCFrame = targetCFrame * CFrame.new(0, 0, -finalSpeed) end
        if keysDown.S then targetCFrame = targetCFrame * CFrame.new(0, 0, finalSpeed) end
        if keysDown.A then targetCFrame = targetCFrame * CFrame.new(-finalSpeed, 0, 0) end
        if keysDown.D then targetCFrame = targetCFrame * CFrame.new(finalSpeed, 0, 0) end
        if keysDown.E then targetCFrame = targetCFrame * CFrame.new(0, finalSpeed, 0) end
        if keysDown.Q then targetCFrame = targetCFrame * CFrame.new(0, -finalSpeed, 0) end

        -- Smooth: lerp camera ke target
        cam.CFrame = cam.CFrame:Lerp(targetCFrame, SMOOTH_FACTOR)
    end)

    -- Input (connect once per enable)
    local inputBeganConn = Services.UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not active then return end
        if input.KeyCode == Enum.KeyCode.W then keysDown.W = true end
        if input.KeyCode == Enum.KeyCode.A then keysDown.A = true end
        if input.KeyCode == Enum.KeyCode.S then keysDown.S = true end
        if input.KeyCode == Enum.KeyCode.D then keysDown.D = true end
        if input.KeyCode == Enum.KeyCode.E then keysDown.E = true end
        if input.KeyCode == Enum.KeyCode.Q then keysDown.Q = true end
        if input.KeyCode == Enum.KeyCode.Left then keysDown.Left = true end
        if input.KeyCode == Enum.KeyCode.Right then keysDown.Right = true end
        if input.KeyCode == Enum.KeyCode.Up then keysDown.Up = true end
        if input.KeyCode == Enum.KeyCode.Down then keysDown.Down = true end
        if input.KeyCode == Enum.KeyCode.LeftShift then leftShiftPressed = true end
        if input.KeyCode == Enum.KeyCode.RightShift then rightShiftPressed = true end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then rotating = true end
    end)
    local inputEndedConn = Services.UserInputService.InputEnded:Connect(function(input)
        if not active then return end
        if input.KeyCode == Enum.KeyCode.W then keysDown.W = false end
        if input.KeyCode == Enum.KeyCode.A then keysDown.A = false end
        if input.KeyCode == Enum.KeyCode.S then keysDown.S = false end
        if input.KeyCode == Enum.KeyCode.D then keysDown.D = false end
        if input.KeyCode == Enum.KeyCode.E then keysDown.E = false end
        if input.KeyCode == Enum.KeyCode.Q then keysDown.Q = false end
        if input.KeyCode == Enum.KeyCode.Left then keysDown.Left = false end
        if input.KeyCode == Enum.KeyCode.Right then keysDown.Right = false end
        if input.KeyCode == Enum.KeyCode.Up then keysDown.Up = false end
        if input.KeyCode == Enum.KeyCode.Down then keysDown.Down = false end
        if input.KeyCode == Enum.KeyCode.LeftShift then leftShiftPressed = false end
        if input.KeyCode == Enum.KeyCode.RightShift then rightShiftPressed = false end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then rotating = false end
    end)
    DroneFeature._inputBeganConn = inputBeganConn
    DroneFeature._inputEndedConn = inputEndedConn
end

local function disable_drone()
    if not active then return end
    active = false
    Settings.features.droneEnabled = false
    keysDown = {}
    rotating = false
    leftShiftPressed = false
    rightShiftPressed = false
    Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default

    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
    if DroneFeature._inputBeganConn then
        DroneFeature._inputBeganConn:Disconnect()
        DroneFeature._inputBeganConn = nil
    end
    if DroneFeature._inputEndedConn then
        DroneFeature._inputEndedConn:Disconnect()
        DroneFeature._inputEndedConn = nil
    end

    local cam = Services.Camera
    if cam then
        cam.CameraType = originalCameraType or Enum.CameraType.Custom
        cam.CameraSubject = originalCameraSubject
        cam.FieldOfView = originalFOV or 70
    end
    unfreezeCharacter()
end

-- ============================================
-- PUBLIC API
-- ============================================

function DroneFeature.toggle(enabled)
    if enabled then
        enable_drone()
    else
        disable_drone()
    end
end

function DroneFeature.set_speed(value)
    currentSpeed = math.clamp(value, 0.1, 5)
end

function DroneFeature.set_rotate_speed(value)
    currentRotateSpeed = math.clamp(value, 0.2, 3)
end

function DroneFeature.get_speed()
    return currentSpeed
end

function DroneFeature.is_active()
    return active
end

return DroneFeature
