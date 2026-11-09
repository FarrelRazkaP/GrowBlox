-- Gembul Dex / Game Structure Inspector for GrowBlox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

print("=========================================")
print("[Gembul Inspector] Scanning GrowBlox Structure...")
print("=========================================")

-- 1. Scan ReplicatedStorage Remotes & Folders
print("\n--- [1] WorldRemotes List ---")
local wr = ReplicatedStorage:FindFirstChild("WorldRemotes")
if wr then
    for _, rem in ipairs(wr:GetChildren()) do
        print("  Remote: " .. rem.Name .. " (" .. rem.ClassName .. ")")
    end
else
    print("  WorldRemotes not found in ReplicatedStorage!")
end

-- 2. Scan Shared.Net
print("\n--- [2] Shared.Net Inspection ---")
local shared = ReplicatedStorage:FindFirstChild("Shared")
if shared then
    local netMod = shared:FindFirstChild("Net")
    if netMod and netMod:IsA("ModuleScript") then
        local ok, Net = pcall(require, netMod)
        if ok and type(Net) == "table" then
            print("  Successfully required Shared.Net!")
            for k, v in pairs(Net) do
                local vType = type(v)
                if vType == "table" then
                    local subKeys = {}
                    for sk, sv in pairs(v) do subKeys[#subKeys + 1] = tostring(sk) .. " (" .. type(sv) .. ")" end
                    print("    Net." .. tostring(k) .. " = table { " .. table.concat(subKeys, ", ") .. " }")
                else
                    print("    Net." .. tostring(k) .. " (" .. vType .. ")")
                end
            end
            if Net.CALLS and type(Net.CALLS) == "table" then
                print("  Net.CALLS:")
                for ck, cv in pairs(Net.CALLS) do
                    print("    CALL: " .. tostring(ck) .. " -> " .. tostring(cv))
                end
            end
            if Net.EVENTS and type(Net.EVENTS) == "table" then
                print("  Net.EVENTS:")
                for ek, ev in pairs(Net.EVENTS) do
                    print("    EVENT: " .. tostring(ek) .. " -> " .. tostring(ev))
                end
            end
        else
            print("  Failed to require Shared.Net: " .. tostring(Net))
        end
    else
        print("  Shared.Net ModuleScript not found!")
    end
end

-- 3. Scan PlayerScripts
print("\n--- [3] PlayerScripts List ---")
if LocalPlayer then
    local ps = LocalPlayer:FindFirstChild("PlayerScripts")
    if ps then
        for _, s in ipairs(ps:GetChildren()) do
            print("  Script: " .. s.Name .. " (" .. s.ClassName .. ")")
        end
    end
end

print("\n=========================================")
print("[Gembul Inspector] Scan Complete!")
print("=========================================")
