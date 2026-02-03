--[[
    Alpha Project - Test Version
    Ultra minimal - hanya test jika bisa load
]]

print("============================================")
print("✅ [ALPHA TEST] Script loaded!")
print("============================================")
print("HTTP Enabled:", game:GetService("HttpService").HttpEnabled)
print("LocalPlayer:", game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.Name or "NONE")
print("Time:", os.date("%Y-%m-%d %H:%M:%S"))
print("============================================")

local LocalPlayer = game:GetService("Players").LocalPlayer
if LocalPlayer then
    print("✅ Ready to execute features!")
end
