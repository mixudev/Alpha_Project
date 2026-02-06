--[[
    Alpha Project - Security / Exploit Test
    Test keamanan map: RemoteEvent/RemoteFunction, Bindable, loadstring, env, dll.
    Berdasarkan prinsip Roblox: Never trust the client. Admin system sering pakai
    RemoteEvent/RemoteFunction; exploit bisa fire dengan argumen arbitrer.
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

local function run_tests()
    local results = {}
    local function add(severity, name, detail)
        table.insert(results, { severity = severity, name = name, detail = detail or "" })
    end

    -- 1. RemoteEvent & RemoteFunction (client bisa FireServer/InvokeServer dengan data arbitrer)
    do
        local count = 0
        local list = {}
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                count = count + 1
                table.insert(list, get_full_path(obj) .. " [RemoteEvent]")
            elseif obj:IsA("RemoteFunction") then
                count = count + 1
                table.insert(list, get_full_path(obj) .. " [RemoteFunction]")
            end
        end
        if count > 0 then
            add("FATAL", "RemoteEvent/RemoteFunction terpapar", count .. " item. Client bisa fire/invoke dengan argumen arbitrer.\n" .. table.concat(list, "\n"))
        else
            add("INFO", "RemoteEvent/RemoteFunction", "Tidak ditemukan (aman dari eksposur client).")
        end
    end

    -- 2. BindableEvent / BindableFunction (bisa dipanggil dari client jika di ReplicatedStorage)
    do
        local bindables = {}
        for _, obj in pairs(game:GetDescendants()) do
            if (obj:IsA("BindableEvent") or obj:IsA("BindableFunction")) and obj:IsDescendantOf(game:GetService("ReplicatedStorage")) then
                table.insert(bindables, get_full_path(obj))
            end
        end
        if #bindables > 0 then
            add("FATAL", "Bindable di ReplicatedStorage", #bindables .. " item. Client bisa Invoke/Fire.\n" .. table.concat(bindables, "\n"))
        else
            add("INFO", "Bindable di ReplicatedStorage", "Tidak ada.")
        end
    end

    -- 3. loadstring (sering dimatikan di production; kalau ada = risiko)
    do
        local ok = pcall(function() return type(loadstring) == "function" end)
        if ok and type(loadstring) == "function" then
            add("FATAL", "loadstring tersedia", "Executor bisa eksekusi kode dinamis. Nonaktifkan di Game Settings.")
        else
            add("INFO", "loadstring", "Tidak tersedia (aman).")
        end
    end

    -- 4. getfenv / setfenv (deprecated tapi exploit bisa pakai)
    do
        local hasGet = pcall(function() return type(getfenv) == "function" end)
        local hasSet = pcall(function() return type(setfenv) == "function" end)
        if hasGet or hasSet then
            add("WARNING", "getfenv/setfenv", "Tersedia. Dapat dipakai untuk hook/read state.")
        else
            add("INFO", "getfenv/setfenv", "Tidak tersedia.")
        end
    end

    -- 5. CoreGui (client bisa baca/ubah UI)
    do
        local ok, _ = pcall(function() return game:GetService("CoreGui"):GetChildren() end)
        if ok then
            add("WARNING", "Akses CoreGui", "Client bisa enumerate CoreGui. Normal di client.")
        end
    end

    -- 6. Script di ReplicatedStorage (kode bisa terbaca)
    do
        local scripts = {}
        for _, obj in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if obj:IsA("LuaSourceContainer") then
                table.insert(scripts, get_full_path(obj))
            end
        end
        if #scripts > 0 then
            add("WARNING", "Script/LocalScript di ReplicatedStorage", #scripts .. " item. Source bisa terbaca client.\n" .. table.concat(scripts, "\n"))
        else
            add("INFO", "Script di ReplicatedStorage", "Tidak ada.")
        end
    end

    -- 7. ModuleScript di ReplicatedStorage (sama)
    do
        local mods = {}
        for _, obj in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if obj:IsA("ModuleScript") then
                table.insert(mods, get_full_path(obj))
            end
        end
        if #mods > 0 then
            add("WARNING", "ModuleScript di ReplicatedStorage", #mods .. " item. Require() bisa dipanggil client.\n" .. table.concat(mods, "\n"))
        end
    end

    -- 8. HttpEnabled (untuk request dari client)
    do
        local ok = pcall(function() return game:GetService("HttpService").HttpEnabled end)
        if ok and game:GetService("HttpService").HttpEnabled then
            add("INFO", "HttpEnabled", "Aktif. Client bisa HTTP request.")
        else
            add("INFO", "HttpEnabled", "Nonaktif.")
        end
    end

    -- 9. Synapse / executor check (hanya info)
    do
        local info = "Lingkungan: "
        if type(syn) == "table" then info = info .. "Synapse " end
        if type(getexecutorname) == "function" then info = info .. "getexecutorname ada " end
        if type(getrenv) == "function" then info = info .. "getrenv ada " end
        add("INFO", "Executor", info)
    end

    return results
end

function SecurityFeature.run_tests()
    return run_tests()
end

return SecurityFeature
