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

-- Daftar test yang akan dijalankan (nama + deskripsi)
local TEST_LIST = {
    { id = "remotes", name = "Test RemoteEvent / RemoteFunction", desc = "Mendeteksi semua Remote yang bisa di-fire client dengan data arbitrer." },
    { id = "bindable", name = "Test Bindable di ReplicatedStorage", desc = "BindableEvent/BindableFunction di ReplicatedStorage bisa di-Invoke dari client." },
    { id = "loadstring", name = "Test loadstring", desc = "Apakah loadstring tersedia (risiko eksekusi kode dinamis)." },
    { id = "getfenv", name = "Test getfenv / setfenv", desc = "Fungsi env bisa dipakai untuk hook/read state." },
    { id = "scripts_rep", name = "Test Script di ReplicatedStorage", desc = "Script/LocalScript di ReplicatedStorage bisa terbaca client." },
    { id = "modules_rep", name = "Test ModuleScript di ReplicatedStorage", desc = "ModuleScript di ReplicatedStorage bisa di-require client." },
    { id = "admin", name = "Test Admin", desc = "Mencari Remote yang namanya mengarah ke sistem admin (Admin, Command, dll)." },
    { id = "ban", name = "Test Ban User", desc = "Mencari Remote yang mungkin untuk ban/kick user." },
    { id = "announcement", name = "Test Announcement", desc = "Mencari Remote yang mungkin untuk broadcast/announce." },
    { id = "http", name = "Test HttpEnabled", desc = "Apakah HTTP request dari client diizinkan." },
    { id = "executor", name = "Info Executor", desc = "Lingkungan executor (syn, getexecutorname, dll)." },
}

function SecurityFeature.get_test_list()
    return TEST_LIST
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

return SecurityFeature
