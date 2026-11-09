-- Gembul Dex / Game Structure Inspector for GrowBlox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local logLines = {}
local function log(str)
    print(str)
    logLines[#logLines + 1] = tostring(str)
end

log("=========================================")
log("[Gembul Inspector] Scanning GrowBlox Structure...")
log("=========================================")

-- 1. Scan ReplicatedStorage Remotes & Folders
log("\n--- [1] WorldRemotes List ---")
local wr = ReplicatedStorage:FindFirstChild("WorldRemotes")
if wr then
    for _, rem in ipairs(wr:GetChildren()) do
        log("  Remote: " .. rem.Name .. " (" .. rem.ClassName .. ")")
    end
else
    log("  WorldRemotes not found in ReplicatedStorage!")
end

-- 2. Scan Shared.Net
log("\n--- [2] Shared.Net Inspection ---")
local shared = ReplicatedStorage:FindFirstChild("Shared")
if shared then
    local netMod = shared:FindFirstChild("Net")
    if netMod and netMod:IsA("ModuleScript") then
        local ok, Net = pcall(require, netMod)
        if ok and type(Net) == "table" then
            log("  Successfully required Shared.Net!")
            for k, v in pairs(Net) do
                local vType = type(v)
                if vType == "table" then
                    local subKeys = {}
                    for sk, sv in pairs(v) do subKeys[#subKeys + 1] = tostring(sk) .. " (" .. type(sv) .. ")" end
                    log("    Net." .. tostring(k) .. " = table { " .. table.concat(subKeys, ", ") .. " }")
                else
                    log("    Net." .. tostring(k) .. " (" .. vType .. ")")
                end
            end
            if Net.CALLS and type(Net.CALLS) == "table" then
                log("  Net.CALLS:")
                for ck, cv in pairs(Net.CALLS) do
                    log("    CALL: " .. tostring(ck) .. " -> " .. tostring(cv))
                end
            end
            if Net.EVENTS and type(Net.EVENTS) == "table" then
                log("  Net.EVENTS:")
                for ek, ev in pairs(Net.EVENTS) do
                    log("    EVENT: " .. tostring(ek) .. " -> " .. tostring(ev))
                end
            end
        else
            log("  Failed to require Shared.Net: " .. tostring(Net))
        end
    else
        log("  Shared.Net ModuleScript not found!")
    end
end

-- 3. Scan PlayerScripts
log("\n--- [3] PlayerScripts List ---")
if LocalPlayer then
    local ps = LocalPlayer:FindFirstChild("PlayerScripts")
    if ps then
        for _, s in ipairs(ps:GetChildren()) do
            log("  Script: " .. s.Name .. " (" .. s.ClassName .. ")")
        end
    end
end

log("\n=========================================")
log("[Gembul Inspector] Scan Complete!")
log("=========================================")

local fullText = table.concat(logLines, "\n")

-- Otomatis salin ke clipboard
if setclipboard then
    pcall(setclipboard, fullText)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Gembul Inspector",
            Text = "Hasil scan sudah disalin ke Clipboard! Tinggal Paste (Ctrl+V) di chat.",
            Duration = 5,
        })
    end)
elseif toclipboard then
    pcall(toclipboard, fullText)
end

-- Tampilkan UI popup sederhana di layar
pcall(function()
    local oldGui = CoreGui:FindFirstChild("GembulScanGui")
    if oldGui then oldGui:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "GembulScanGui"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 480, 0, 320)
    frame.Position = UDim2.new(0.5, -240, 0.5, -160)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BorderSizePixel = 0
    frame.Parent = sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 36)
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "  Hasil Scan Dex / Remotes (Sudah Ter-Copy ke Clipboard)"
    title.TextSize = 14
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 36, 0, 36)
    close.Position = UDim2.new(1, -36, 0, 0)
    close.Text = "X"
    close.TextColor3 = Color3.fromRGB(255, 100, 100)
    close.BackgroundTransparency = 1
    close.Font = Enum.Font.SourceSansBold
    close.TextSize = 16
    close.Parent = frame
    close.MouseButton1Click:Connect(function() sg:Destroy() end)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 1, -56)
    box.Position = UDim2.new(0, 10, 0, 46)
    box.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    box.TextColor3 = Color3.fromRGB(200, 255, 200)
    box.Text = fullText
    box.TextSize = 12
    box.Font = Enum.Font.Code
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.MultiLine = true
    box.Parent = frame
end)
