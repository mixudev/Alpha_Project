--[[
    Alpha Project - Security / Exploit Test
    Daftar test keamanan map: RemoteEvent, Admin, Ban, Announcement, Bindable, loadstring, dll.
    Setiap test dijalankan dan hasil/error ditampilkan; hasil bisa di-copy.
]]

local Alpha = rawget(_G, "Alpha")
local Services = (Alpha and Alpha.require) and Alpha.require("core/services") or require(script.Parent.Parent:FindFirstChild("core/services"))
local Settings = (Alpha and Alpha.require) and Alpha.require("config/settings") or require(script.Parent.Parent:FindFirstChild("config/settings"))

local SecurityFeature = {}

local function get_full_path(inst)
    local path = {}
    local p = inst
    while p and p ~= game do
        table.insert(path, 1, p.Name)
        p = p.Parent
    end
    return table.concat(path, ".")
end

-- Daftar test: id, name (singkat untuk tombol), category (untuk pengelompokan menu Test)
local TEST_LIST = {
    { id = "remotes", name = "RemoteEvent / RemoteFunction", short = "Remote", category = "remote" },
    { id = "bindable", name = "Bindable di ReplicatedStorage", short = "Bindable", category = "remote" },
    { id = "loadstring", name = "loadstring", short = "loadstring", category = "env" },
    { id = "getfenv", name = "getfenv / setfenv", short = "getfenv", category = "env" },
    { id = "http", name = "HttpEnabled", short = "HTTP", category = "env" },
    { id = "executor", name = "Executor", short = "Executor", category = "env" },
    { id = "scripts_rep", name = "Script di ReplicatedStorage", short = "Script Rep", category = "scripts" },
    { id = "modules_rep", name = "ModuleScript di ReplicatedStorage", short = "Module Rep", category = "scripts" },
    { id = "admin", name = "Remote Admin/Command", short = "Admin", category = "suspicious" },
    { id = "ban", name = "Remote Ban/Kick", short = "Ban", category = "suspicious" },
    { id = "announcement", name = "Remote Announce/Broadcast", short = "Announce", category = "suspicious" },
    { id = "item", name = "Item / Unlock", short = "Item", category = "suspicious" },
}

local CATEGORY_LABELS = {
    remote = "Remote & Bindable",
    env = "Environment",
    scripts = "Scripts",
    suspicious = "Remote Mencurigakan",
}

function SecurityFeature.get_test_list()
    return TEST_LIST
end

function SecurityFeature.get_categories()
    return CATEGORY_LABELS
end

-- Jalankan satu test saja; return { id, name, status, detail, error }
function SecurityFeature.run_single_test(test_id)
    local test_def
    for _, t in ipairs(TEST_LIST) do
        if t.id == test_id then test_def = t break end
    end
    local name = test_def and test_def.name or test_id
    local status, detail, err = "OK", "", nil
    local ok, a, b, c = pcall(run_single, test_id)
    if ok then
        status, detail, err = a, b or "", c
    else
        status = "ERROR"
        detail = tostring(a or "Unknown error")
        err = a
    end
    return {
        id = test_id,
        name = name,
        status = status,
        detail = detail,
        error = err,
    }
end

local function run_single(id)
    if id == "remotes" then
        local list = {}
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                table.insert(list, get_full_path(obj) .. " [RemoteEvent]")
            elseif obj:IsA("RemoteFunction") then
                table.insert(list, get_full_path(obj) .. " [RemoteFunction]")
            end
        end
        if #list > 0 then
            return "FATAL", #list .. " item. Client bisa fire/invoke dengan argumen arbitrer.\n" .. table.concat(list, "\n"), nil
        end
        return "OK", "Tidak ditemukan.", nil
    end

    if id == "bindable" then
        local list = {}
        for _, obj in pairs(game:GetDescendants()) do
            if (obj:IsA("BindableEvent") or obj:IsA("BindableFunction")) and obj:IsDescendantOf(game:GetService("ReplicatedStorage")) then
                table.insert(list, get_full_path(obj))
            end
        end
        if #list > 0 then
            return "FATAL", #list .. " item.\n" .. table.concat(list, "\n"), nil
        end
        return "OK", "Tidak ada.", nil
    end

    if id == "loadstring" then
        if type(loadstring) == "function" then
            return "FATAL", "Tersedia. Nonaktifkan di Game Settings.", nil
        end
        return "OK", "Tidak tersedia (aman).", nil
    end

    if id == "getfenv" then
        local hasGet = type(getfenv) == "function"
        local hasSet = type(setfenv) == "function"
        if hasGet or hasSet then
            return "WARNING", "Tersedia. Dapat dipakai untuk hook/read state.", nil
        end
        return "OK", "Tidak tersedia.", nil
    end

    if id == "scripts_rep" then
        local list = {}
        for _, obj in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if obj:IsA("LuaSourceContainer") then
                table.insert(list, get_full_path(obj))
            end
        end
        if #list > 0 then
            return "WARNING", #list .. " item.\n" .. table.concat(list, "\n"), nil
        end
        return "OK", "Tidak ada.", nil
    end

    if id == "modules_rep" then
        local list = {}
        for _, obj in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if obj:IsA("ModuleScript") then
                table.insert(list, get_full_path(obj))
            end
        end
        if #list > 0 then
            return "WARNING", #list .. " item.\n" .. table.concat(list, "\n"), nil
        end
        return "OK", "Tidak ada.", nil
    end

    if id == "admin" then
        local keywords = { "Admin", "Command", "Execute", "Script" }
        local list = {}
        for _, obj in pairs(game:GetDescendants()) do
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                local path = get_full_path(obj)
                for _, kw in ipairs(keywords) do
                    if path:find(kw, 1, true) then
                        table.insert(list, path)
                        break
                    end
                end
            end
        end
        if #list > 0 then
            return "WARNING", "Ditemukan " .. #list .. " remote mencurigakan (Admin/Command/Execute/Script):\n" .. table.concat(list, "\n"), nil
        end
        return "OK", "Tidak ada yang mencurigakan.", nil
    end

    if id == "ban" then
        local keywords = { "Ban", "Kick", "Punish", "Moderate" }
        local list = {}
        for _, obj in pairs(game:GetDescendants()) do
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                local path = get_full_path(obj)
                for _, kw in ipairs(keywords) do
                    if path:find(kw, 1, true) then
                        table.insert(list, path)
                        break
                    end
                end
            end
        end
        if #list > 0 then
            return "WARNING", "Ditemukan " .. #list .. " remote (Ban/Kick/Punish):\n" .. table.concat(list, "\n"), nil
        end
        return "OK", "Tidak ada.", nil
    end

    if id == "announcement" then
        local keywords = { "Announce", "Broadcast", "Message", "Notify", "Chat" }
        local list = {}
        for _, obj in pairs(game:GetDescendants()) do
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                local path = get_full_path(obj)
                for _, kw in ipairs(keywords) do
                    if path:find(kw, 1, true) then
                        table.insert(list, path)
                        break
                    end
                end
            end
        end
        if #list > 0 then
            return "INFO", #list .. " remote (Announce/Broadcast/Message):\n" .. table.concat(list, "\n"), nil
        end
        return "OK", "Tidak ada.", nil
    end

    if id == "item" then
        local keywords = { "Item", "GetItem", "GiveItem", "Unlock", "Open", "Give", "Add", "Purchase", "Buy" }
        local list = {}
        for _, obj in pairs(game:GetDescendants()) do
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                local path = get_full_path(obj)
                for _, kw in ipairs(keywords) do
                    if path:find(kw, 1, true) then
                        table.insert(list, path)
                        break
                    end
                end
            end
        end
        if #list > 0 then
            return "WARNING", #list .. " remote (Item/Unlock):\n" .. table.concat(list, "\n"), nil
        end
        return "OK", "Tidak ada.", nil
    end

    if id == "http" then
        local ok = pcall(function() return game:GetService("HttpService").HttpEnabled end)
        if ok and game:GetService("HttpService").HttpEnabled then
            return "INFO", "Aktif. Client bisa HTTP request.", nil
        end
        return "INFO", "Nonaktif.", nil
    end

    if id == "executor" then
        local t = {}
        if type(syn) == "table" then table.insert(t, "Synapse") end
        if type(getexecutorname) == "function" then table.insert(t, "getexecutorname") end
        if type(getrenv) == "function" then table.insert(t, "getrenv") end
        return "INFO", #t > 0 and table.concat(t, ", ") or "Standard", nil
    end

    return "OK", "—", nil
end

function SecurityFeature.run_tests()
    local results = {}
    for _, test in ipairs(TEST_LIST) do
        local status, detail, err = "OK", "", nil
        local ok, a, b, c = pcall(run_single, test.id)
        if ok then
            status, detail, err = a, b or "", c
        else
            status = "ERROR"
            detail = tostring(a or "Unknown error")
            err = a
        end
        table.insert(results, {
            id = test.id,
            name = test.name,
            status = status,
            detail = detail,
            error = err,
        })
    end
    return results
end

-- ========== Eksekusi tes manual (untuk menu Test) ==========
-- Return: { success, message, detail } untuk notifikasi

local function get_remotes_by_keywords(keywords)
    local list = {}
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local path = get_full_path(obj)
            for _, kw in ipairs(keywords) do
                if path:find(kw, 1, true) then
                    table.insert(list, { obj = obj, path = path })
                    break
                end
            end
        end
    end
    return list
end

-- Test Ban: pilih player, fire remote Ban/Kick dengan target player
function SecurityFeature.execute_test_ban(player)
    local list = get_remotes_by_keywords({ "Ban", "Kick", "Punish", "Moderate" })
    if #list == 0 then
        return { success = false, message = "Test Ban gagal", detail = "Tidak ada remote Ban/Kick ditemukan." }
    end
    local target = player
    if type(player) == "table" and player.UserId then
        target = player
    elseif type(player) == "number" then
        target = player
    elseif type(player) == "string" then
        local plr = Services.Players:FindFirstChild(player)
        target = plr or player
    end
    local fired, errCount = 0, 0
    for _, item in ipairs(list) do
        local ok, err = pcall(function()
            if item.obj:IsA("RemoteEvent") then
                item.obj:FireServer(target)
            else
                item.obj:InvokeServer(target)
            end
        end)
        if ok then fired = fired + 1 else errCount = errCount + 1 end
    end
    if fired > 0 then
        return { success = true, message = "Test Ban berhasil", detail = fired .. " remote di-fire ke target." }
    end
    return { success = false, message = "Test Ban gagal", detail = "Semua remote error (" .. errCount .. ")." }
end

-- Test Announce: masukkan pesan, fire remote Announce/Broadcast
function SecurityFeature.execute_test_announce(text)
    local list = get_remotes_by_keywords({ "Announce", "Broadcast", "Message", "Notify", "Chat" })
    if #list == 0 then
        return { success = false, message = "Test Announce gagal", detail = "Tidak ada remote Announce/Broadcast." }
    end
    local msg = (text and #tostring(text) > 0) and tostring(text) or "[Test] Pesan uji"
    local fired, errCount = 0, 0
    for _, item in ipairs(list) do
        local ok = pcall(function()
            if item.obj:IsA("RemoteEvent") then
                item.obj:FireServer(msg)
            else
                item.obj:InvokeServer(msg)
            end
        end)
        if ok then fired = fired + 1 else errCount = errCount + 1 end
    end
    if fired > 0 then
        return { success = true, message = "Pesan terkirim", detail = fired .. " remote di-fire." }
    end
    return { success = false, message = "Test Announce gagal", detail = "Semua remote error." }
end

-- Test Item: fire remote GetItem/GiveItem/Unlock/Open agar item terbuka
function SecurityFeature.execute_test_item()
    local list = get_remotes_by_keywords({ "Item", "GetItem", "GiveItem", "Unlock", "Open", "Give", "Add", "Purchase", "Buy" })
    if #list == 0 then
        return { success = false, message = "Test Item gagal", detail = "Tidak ada remote Item/Unlock ditemukan." }
    end
    local fired, errCount = 0, 0
    for _, item in ipairs(list) do
        local ok = pcall(function()
            if item.obj:IsA("RemoteEvent") then
                item.obj:FireServer()
            else
                item.obj:InvokeServer()
            end
        end)
        if ok then fired = fired + 1 else errCount = errCount + 1 end
    end
    if fired > 0 then
        return { success = true, message = "Test Item berhasil", detail = fired .. " remote di-fire. Cek inventory/game." }
    end
    return { success = false, message = "Test Item gagal", detail = "Semua remote error (" .. errCount .. ")." }
end

-- Test Remote: fire semua RemoteEvent, invoke semua RemoteFunction
function SecurityFeature.execute_test_remotes()
    local fired, invoked, errCount = 0, 0, 0
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local ok = pcall(function() obj:FireServer() end)
            if ok then fired = fired + 1 else errCount = errCount + 1 end
        elseif obj:IsA("RemoteFunction") then
            local ok = pcall(function() obj:InvokeServer() end)
            if ok then invoked = invoked + 1 else errCount = errCount + 1 end
        end
    end
    local total = fired + invoked
    if total > 0 then
        return { success = true, message = "Test Remote berhasil", detail = "Fire: " .. fired .. ", Invoke: " .. invoked .. (errCount > 0 and (", Error: " .. errCount) or "") }
    end
    return { success = false, message = "Test Remote gagal", detail = "Tidak ada remote atau semua error." }
end

-- Test Bindable: fire/invoke Bindable di ReplicatedStorage
function SecurityFeature.execute_test_bindable()
    local fired, errCount = 0, 0
    local rs = game:GetService("ReplicatedStorage")
    for _, obj in pairs(game:GetDescendants()) do
        if (obj:IsA("BindableEvent") or obj:IsA("BindableFunction")) and obj:IsDescendantOf(rs) then
            local ok = pcall(function()
                if obj:IsA("BindableEvent") then obj:Fire() else obj:Invoke() end
            end)
            if ok then fired = fired + 1 else errCount = errCount + 1 end
        end
    end
    if fired > 0 then
        return { success = true, message = "Test Bindable berhasil", detail = fired .. " di-fire." }
    end
    return { success = false, message = "Test Bindable gagal", detail = "Tidak ada atau semua error." }
end

-- Test loadstring
function SecurityFeature.execute_test_loadstring()
    local ok, res = pcall(function()
        if type(loadstring) ~= "function" then return nil end
        return loadstring("return 1")()
    end)
    if ok and res == 1 then
        return { success = true, message = "loadstring terbuka", detail = "Kode dinamis dapat dijalankan." }
    end
    return { success = false, message = "loadstring tertutup", detail = ok and "Aman." or tostring(res) }
end

-- Test getfenv/setfenv
function SecurityFeature.execute_test_getfenv()
    local ok, res = pcall(function()
        if type(getfenv) ~= "function" then return nil end
        return getfenv(0)
    end)
    if ok and res and type(res) == "table" then
        return { success = true, message = "getfenv terbuka", detail = "Dapat dipakai untuk hook/read state." }
    end
    return { success = false, message = "getfenv tertutup", detail = ok and "Aman." or tostring(res) }
end

-- Test HTTP
function SecurityFeature.execute_test_http()
    local ok, enabled = pcall(function()
        return game:GetService("HttpService").HttpEnabled
    end)
    if ok and enabled then
        return { success = true, message = "HTTP aktif", detail = "Client bisa HTTP request." }
    end
    return { success = false, message = "HTTP nonaktif", detail = "Aman." }
end

-- Test Admin: fire remote Admin/Command dengan argumen kosong atau test
function SecurityFeature.execute_test_admin()
    local list = get_remotes_by_keywords({ "Admin", "Command", "Execute", "Script" })
    if #list == 0 then
        return { success = false, message = "Test Admin gagal", detail = "Tidak ada remote Admin/Command." }
    end
    local fired = 0
    for _, item in ipairs(list) do
        local ok = pcall(function()
            if item.obj:IsA("RemoteEvent") then
                item.obj:FireServer()
            else
                item.obj:InvokeServer()
            end
        end)
        if ok then fired = fired + 1 end
    end
    if fired > 0 then
        return { success = true, message = "Test Admin terkirim", detail = fired .. " remote di-fire." }
    end
    return { success = false, message = "Test Admin gagal", detail = "Semua remote error." }
end

-- Daftar pemain untuk dropdown Test Ban
function SecurityFeature.get_players_list()
    local list = {}
    for _, p in ipairs(Services.Players:GetPlayers()) do
        table.insert(list, { name = p.DisplayName or p.Name, userId = p.UserId, player = p })
    end
    return list
end

return SecurityFeature
