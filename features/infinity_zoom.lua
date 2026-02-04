--[[
    Alpha Project - Infinity Zoom
    Zoom camera dari jarak jauh tanpa batas
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local InfinityZoom = {}

-- ============================================
-- VARIABLES
-- ============================================

InfinityZoom.isEnabled = false
InfinityZoom.zoomConnection = nil
InfinityZoom.originalFOV = 70
InfinityZoom.currentZoomLevel = 0
InfinityZoom.maxZoomLevel = 120  -- Max zoom distance
InfinityZoom.scrollSpeed = 5  -- Zoom speed

-- ============================================
-- ENABLE INFINITY ZOOM
-- ============================================

function InfinityZoom.enable()
    if Settings.features.infinityZoomEnabled then return end
    
    Settings.features.infinityZoomEnabled = true
    
    local camera = Services.Workspace.CurrentCamera
    local localPlayer = Services.Players.LocalPlayer
    
    if not camera then return end
    
    InfinityZoom.originalFOV = camera.FieldOfView
    
    -- ============================================
    -- MOUSE WHEEL EVENT
    -- ============================================
    
    InfinityZoom.zoomConnection = Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Scroll up = zoom in
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local scrollDirection = input.Position.Z
            
            if scrollDirection > 0 then
                -- Zoom in
                InfinityZoom.currentZoomLevel = math.min(InfinityZoom.currentZoomLevel + InfinityZoom.scrollSpeed, InfinityZoom.maxZoomLevel)
            else
                -- Zoom out
                InfinityZoom.currentZoomLevel = math.max(InfinityZoom.currentZoomLevel - InfinityZoom.scrollSpeed, 0)
            end
            
            -- Update camera
            InfinityZoom.update_zoom()
        end
        
        -- Shift + Scroll untuk adjust speed
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            -- Shift aktif, adjust scroll speed
            InfinityZoom.scrollSpeed = 10
        end
    end)
    
    -- Reset scroll speed
    Services.UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            InfinityZoom.scrollSpeed = 5
        end
    end)
    
    -- Camera update loop
    Services.RunService.RenderStepped:Connect(function()
        if not Settings.features.infinityZoomEnabled then return end
        
        InfinityZoom.update_zoom()
    end)
    
    print("🔭 Infinity Zoom enabled!")
    print("💡 Gunakan mouse scroll untuk zoom in/out")
    print("💡 Tahan Shift untuk zoom lebih cepat")
end

-- ============================================
-- UPDATE ZOOM
-- ============================================

function InfinityZoom.update_zoom()
    if not Settings.features.infinityZoomEnabled then return end
    
    local camera = Services.Workspace.CurrentCamera
    local localPlayer = Services.Players.LocalPlayer
    
    if not camera or not localPlayer.Character then return end
    
    local humanoidRootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Camera position jauh dari player
    local lookDirection = (camera.Focus.Position - humanoidRootPart.Position).Unit
    
    if lookDirection.Magnitude == 0 then
        lookDirection = humanoidRootPart.CFrame.LookVector
    end
    
    -- Set camera position dengan zoom level
    camera.CFrame = CFrame.new(
        humanoidRootPart.Position + lookDirection * (InfinityZoom.currentZoomLevel + 5),
        humanoidRootPart.Position + Vector3.new(0, 5, 0)
    )
    
    -- Adjust FOV berdasarkan zoom
    local zoomFOV = InfinityZoom.originalFOV + (InfinityZoom.currentZoomLevel * 0.3)
    camera.FieldOfView = math.min(zoomFOV, 120)
end

-- ============================================
-- DISABLE INFINITY ZOOM
-- ============================================

function InfinityZoom.disable()
    if not Settings.features.infinityZoomEnabled then return end
    
    Settings.features.infinityZoomEnabled = false
    
    -- Disconnect
    if InfinityZoom.zoomConnection then
        pcall(function() InfinityZoom.zoomConnection:Disconnect() end)
        InfinityZoom.zoomConnection = nil
    end
    
    -- Reset camera
    local camera = Services.Workspace.CurrentCamera
    if camera then
        camera.FieldOfView = InfinityZoom.originalFOV
    end
    
    InfinityZoom.currentZoomLevel = 0
    
    print("🔭 Infinity Zoom disabled!")
end

-- ============================================
-- TOGGLE INFINITY ZOOM
-- ============================================

function InfinityZoom.toggle()
    if Settings.features.infinityZoomEnabled then
        InfinityZoom.disable()
    else
        InfinityZoom.enable()
    end
end

return InfinityZoom
