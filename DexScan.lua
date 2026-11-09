-- Gembul Dex / Game Structure Inspector for GrowBlox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

print("=========================================")
print("[Gembul Inspector] Scanning GrowBlox Structure...")
print("=========================================")

-- 1. Scan ReplicatedStorage Remotes & Folders
print("\n--- [1] ReplicatedStorage Children ---")
for _, child in ipairs(ReplicatedStorage:GetChildren()) do
    local info = child.Name .. " (" .. child.ClassName .. ")"
    if child:IsA("Folder") or child:IsA("Configuration") or child:IsA("Model") then
        local subs = {}
        for _, sub in ipairs(child:GetChildren()) do
            subs[#subs + 1] = sub.Name .. " [" .. sub.ClassName .. "]"
        end
        info = info .. " -> Sub: " .. table.concat(subs, ", ")
    end
    print("  " .. info)
end

-- 2. Scan PlayerScripts & PlayerGui
print("\n--- [2] LocalPlayer Scripts ---")
if LocalPlayer then
    local ps = LocalPlayer:FindFirstChild("PlayerScripts")
    if ps then
        print("  [PlayerScripts]:")
        for _, s in ipairs(ps:GetDescendants()) do
            if s:IsA("LocalScript") or s:IsA("ModuleScript") then
                print("    - " .. s:GetFullName():gsub("Players%." .. LocalPlayer.Name .. "%.", ""))
            end
        end
    end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        print("  [PlayerGui Scripts]:")
        for _, s in ipairs(pg:GetDescendants()) do
            if s:IsA("LocalScript") or s:IsA("ModuleScript") then
                print("    - " .. s:GetFullName():gsub("Players%." .. LocalPlayer.Name .. "%.", ""))
            end
        end
    end
end

-- 3. Scan StarterPlayerScripts
print("\n--- [3] StarterPlayerScripts ---")
local sp = game:GetService("StarterPlayer")
local sps = sp and sp:FindFirstChild("StarterPlayerScripts")
if sps then
    for _, s in ipairs(sps:GetDescendants()) do
        if s:IsA("LocalScript") or s:IsA("ModuleScript") then
            print("    - " .. s.Name .. " [" .. s.ClassName .. "]")
        end
    end
end

-- 4. Check Shared Modules & Remotes
print("\n--- [4] Shared Net & Remotes Check ---")
local shared = ReplicatedStorage:FindFirstChild("Shared")
if shared then
    print("  Shared found! Children:")
    for _, c in ipairs(shared:GetChildren()) do
        print("    - " .. c.Name .. " [" .. c.ClassName .. "]")
    end
end

local wr = ReplicatedStorage:FindFirstChild("WorldRemotes")
if wr then
    print("  WorldRemotes found! Children:")
    for _, c in ipairs(wr:GetChildren()) do
        print("    - " .. c.Name .. " [" .. c.ClassName .. "]")
    end
end

print("\n=========================================")
print("[Gembul Inspector] Scan Complete!")
print("=========================================")
