-- Gembul Dex / Game Structure Inspector for GrowBlox (Deep GC Scanner)
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
log("[Gembul Deep Inspector] Scanning Runtime Heap & Modules...")
log("=========================================")

-- 1. Find Net table via getgc
local foundNet = nil
local foundItemDB = nil
local foundWorld = nil

if type(getgc) == "function" then
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then ok, objects = pcall(getgc) end
    if ok and type(objects) == "table" then
        log("  getgc returned " .. #objects .. " objects. Inspecting...")
        for _, v in pairs(objects) do
            if type(v) == "table" then
                -- Check for Net
                if not foundNet and rawget(v, "call") and rawget(v, "on") and rawget(v, "worldTag") then
                    foundNet = v
                end
                -- Check for ItemDB
                if not foundItemDB and rawget(v, 2) and type(rawget(v, 2)) == "table" and rawget(rawget(v, 2), "hits") then
                    foundItemDB = v
                end
                -- Check for World
                if not foundWorld and rawget(v, "fg") and rawget(v, "bg") and rawget(v, "w") and rawget(v, "h") then
                    foundWorld = v
                end
            end
            if foundNet and foundItemDB and foundWorld then break end
        end
    else
        log("  getgc failed: " .. tostring(objects))
    end
else
    log("  getgc is not available on this executor!")
end

if foundNet then
    log("\n[!] SUCCESS: Found Runtime Net Table!")
    for k, v in pairs(foundNet) do
        local vt = type(v)
        if vt == "table" then
            local items = {}
            for subK, subV in pairs(v) do
                items[#items + 1] = tostring(subK) .. "=" .. tostring(subV)
                if #items >= 15 then items[#items + 1] = "..."; break end
            end
            log("  Net." .. tostring(k) .. " = { " .. table.concat(items, ", ") .. " }")
        else
            log("  Net." .. tostring(k) .. " (" .. vt .. ")")
        end
    end

    if foundNet.punch and type(foundNet.punch) == "table" then
        log("\n--- Net.punch Details ---")
        for pk, pv in pairs(foundNet.punch) do
            log("  Net.punch." .. tostring(pk) .. " = " .. tostring(pv) .. " (" .. type(pv) .. ")")
            if type(pv) == "function" and getupvalues then
                local ups = getupvalues(pv)
                for ui, uv in pairs(ups) do
                    log("    Upvalue[" .. ui .. "] = " .. tostring(uv) .. " (" .. type(uv) .. ")")
                end
            end
        end
    end

    if foundNet.CALLS and type(foundNet.CALLS) == "table" then
        log("\n--- Net.CALLS (RemoteFunctions) ---")
        for ck, cv in pairs(foundNet.CALLS) do
            log("  CALL: " .. tostring(ck) .. " -> " .. tostring(cv))
        end
    end

    if foundNet.EVENTS and type(foundNet.EVENTS) == "table" then
        log("\n--- Net.EVENTS (RemoteEvents) ---")
        for ek, ev in pairs(foundNet.EVENTS) do
            log("  EVENT: " .. tostring(ek) .. " -> " .. tostring(ev))
        end
    end
else
    log("\n[-] Net table not found in GC!")
end

if foundItemDB then
    log("\n[!] Found ItemDB in GC! Total items sampled: " .. (foundItemDB[2] and ("Dirt hits=" .. tostring(foundItemDB[2].hits)) or "OK"))
end

if foundWorld then
    log("\n[!] Found World in GC! Size: " .. tostring(foundWorld.w) .. "x" .. tostring(foundWorld.h))
end

log("\n=========================================")
log("[Gembul Deep Inspector] Scan Complete!")
log("=========================================")

local fullText = table.concat(logLines, "\n")

if setclipboard then pcall(setclipboard, fullText)
elseif toclipboard then pcall(toclipboard, fullText) end

pcall(function()
    local oldGui = CoreGui:FindFirstChild("GembulScanGui")
    if oldGui then oldGui:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "GembulScanGui"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 520, 0, 360)
    frame.Position = UDim2.new(0.5, -260, 0.5, -180)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BorderSizePixel = 0
    frame.Parent = sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 36)
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "  Hasil Deep GC Scan (Sudah Ter-Copy ke Clipboard)"
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
