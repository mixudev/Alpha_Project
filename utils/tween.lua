--[[
    Alpha Project - Tween Utility
    Helper untuk smooth animations/tweens
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))

local TweenUtil = {}

-- ============================================
-- STANDARD TWEEN INFO PRESETS
-- ============================================

TweenUtil.presets = {
    fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    normal = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    
    -- Special
    smooth_in = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    smooth_out = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
}

-- ============================================
-- CREATE TWEEN
-- ============================================

function TweenUtil.tween(instance, tweenInfo, properties)
    if not instance or not tweenInfo or not properties then
        return nil
    end
    
    local tween = Services.TweenService:Create(instance, tweenInfo, properties)
    return tween
end

-- ============================================
-- PLAY TWEEN
-- ============================================

function TweenUtil.play(instance, tweenInfo, properties)
    local tween = TweenUtil.tween(instance, tweenInfo, properties)
    if tween then
        tween:Play()
    end
    return tween
end

-- ============================================
-- QUICK TWEEN (fast preset)
-- ============================================

function TweenUtil.quick(instance, properties)
    return TweenUtil.play(instance, TweenUtil.presets.fast, properties)
end

-- ============================================
-- SMOOTH TWEEN (slow preset)
-- ============================================

function TweenUtil.smooth(instance, properties)
    return TweenUtil.play(instance, TweenUtil.presets.slow, properties)
end

-- ============================================
-- COLOR TWEEN
-- ============================================

function TweenUtil.color(instance, targetColor, duration)
    duration = duration or 0.15
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    return TweenUtil.play(instance, tweenInfo, {BackgroundColor3 = targetColor})
end

-- ============================================
-- FADE (Transparency)
-- ============================================

function TweenUtil.fade(instance, targetTransparency, duration)
    duration = duration or 0.3
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    return TweenUtil.play(instance, tweenInfo, {BackgroundTransparency = targetTransparency})
end

-- ============================================
-- POSITION TWEEN
-- ============================================

function TweenUtil.position(instance, targetPosition, duration)
    duration = duration or 0.3
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    return TweenUtil.play(instance, tweenInfo, {Position = targetPosition})
end

-- ============================================
-- SIZE TWEEN
-- ============================================

function TweenUtil.size(instance, targetSize, duration)
    duration = duration or 0.3
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    return TweenUtil.play(instance, tweenInfo, {Size = targetSize})
end

return TweenUtil
