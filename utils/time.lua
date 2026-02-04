--[[
    Alpha Project - Time Utility
    Helper untuk time formatting dan calculations
]]

local TimeUtil = {}

-- ============================================
-- ACCOUNT AGE FORMATTER
-- ============================================

function TimeUtil.format_account_age(days)
    if not days or days < 0 then return "N/A" end
    
    local years = math.floor(days / 365)
    local remainingAfterYears = days % 365
    local months = math.floor(remainingAfterYears / 30)
    local remainingDays = remainingAfterYears % 30
    
    local parts = {}
    if years > 0 then
        table.insert(parts, years .. (years == 1 and " year" or " years"))
    end
    if months > 0 then
        table.insert(parts, months .. (months == 1 and " month" or " months"))
    end
    if remainingDays > 0 or #parts == 0 then
        table.insert(parts, remainingDays .. (remainingDays == 1 and " day" or " days"))
    end
    
    return table.concat(parts, " ")
end

-- ============================================
-- GET FIRST JOIN DATE
-- ============================================

function TimeUtil.get_first_join_date(accountAgeDays)
    if not accountAgeDays then return "N/A" end
    
    local currentTime = os.time()
    local joinTimestamp = currentTime - (accountAgeDays * 86400) -- 86400 seconds in a day
    local joinDate = os.date("%d/%m/%Y", joinTimestamp)
    
    return joinDate
end

-- ============================================
-- ELAPSED TIME ON MAP
-- ============================================

function TimeUtil.get_time_on_map(joinTime)
    if not joinTime then return "N/A" end
    
    local elapsed = tick() - joinTime
    local seconds = math.floor(elapsed % 60)
    local minutes = math.floor((elapsed / 60) % 60)
    local hours = math.floor(elapsed / 3600)
    
    if hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, seconds)
    else
        return string.format("%ds", seconds)
    end
end

-- ============================================
-- FORMAT TIMESTAMP
-- ============================================

function TimeUtil.format_timestamp(timestamp, format)
    format = format or "%H:%M:%S"
    return os.date(format, timestamp)
end

-- ============================================
-- PRETTY DATE
-- ============================================

function TimeUtil.pretty_date(timestamp)
    return os.date("%d %B %Y", timestamp)
end

return TimeUtil
