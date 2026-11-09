-- =====================================================================
-- GEMBUL SCRIPT DECOMPILER
-- Decompiles the real game script instance directly
-- =====================================================================

local CoreGui = game:GetService("CoreGui")
local logLines = {}
local function log(str)
    print(str)
    logLines[#logLines + 1] = tostring(str)
end

log("=========================================")
log("[Gembul Decompiler] Locating Script...")
log("=========================================")

local gi = getinfo or (debug and debug.getinfo)
local gc = getconstants or (debug and debug.getconstants)
local dec = decompile or (debug and debug.decompile)

-- 1. Find act function to get the current script name
local actFn = nil
local scriptLeafName = nil
local scriptFullName = nil

if type(getgc) == "function" and gc then
    for _, fn in pairs(getgc()) do
        if type(fn) == "function" then
            local info = gi and gi(fn) or {}
            local src = tostring(info.source or "")
            if src ~= "=loadstring" and not src:find("Gembul") and not src:find("Test") and not src:find("Inspect") then
                local ok, c = pcall(gc, fn)
                if ok and type(c) == "table" and #c >= 50 then
                    local hasPunchReady, hasWrench = false, false
                    for _, v in pairs(c) do
                        if v == "punchReady" or v == "pressPunch" then hasPunchReady = true end
                        if v == "wrenchTile" or v == "vendOwner" then hasWrench = true end
                    end
                    if hasPunchReady and hasWrench then
                        actFn = fn
                        scriptFullName = src:gsub("^=", "")
                        local parts = scriptFullName:split(".")
                        scriptLeafName = parts[#parts]
                        break
                    end
                end
            end
        end
    end
end

log("Target script: " .. tostring(scriptFullName) .. " (leaf: " .. tostring(scriptLeafName) .. ")")

-- 2. Find the Script Instance in the game hierarchy
local scriptInstance = nil
if scriptLeafName then
    for _, obj in pairs(game:GetDescendants()) do
        if obj.Name == scriptLeafName then
            scriptInstance = obj
            break
        end
    end
end

-- Fallback search in PlayerScripts
if not scriptInstance then
    local ps = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerScripts")
    if ps then
        for _, obj in pairs(ps:GetDescendants()) do
            if obj:IsA("LuaSourceContainer") then
                if scriptLeafName and obj.Name == scriptLeafName then
                    scriptInstance = obj
                    break
                end
            end
        end
    end
end

if not scriptInstance then
    log("[-] ERROR: Script Instance not found in DataModel. Scanning all LocalScripts...")
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("LocalScript") and obj.Name ~= "RbxCharacterSounds" and not obj.Name:find("Chat") then
            log("  Found LocalScript: " .. obj:GetFullName())
            if not scriptInstance then scriptInstance = obj end
        end
    end
end

if scriptInstance and dec then
    log("[+] Found Script Instance: " .. scriptInstance:GetFullName())
    log("Decompiling script now (this may take 1-2 seconds)...")
    local ok, code = pcall(dec, scriptInstance)
    if ok and type(code) == "string" and #code > 0 then
        log(string.format("Decompile successful! Total code length: %d chars.", #code))
        
        -- Search for punch.send in the decompiled code
        local lines = code:split("\n")
        log(string.format("Total lines: %d", #lines))
        
        local matchCount = 0
        for i, line in ipairs(lines) do
            if line:find("punch") or line:find("send") or line:find("punchReady") then
                matchCount = matchCount + 1
                if matchCount <= 5 then
                    log(string.format("\n--- Match #%d at Line %d ---", matchCount, i))
                    for sub = math.max(1, i - 5), math.min(#lines, i + 8) do
                        log(string.format("%4d: %s", sub, lines[sub]))
                    end
                end
            end
        end
        if matchCount == 0 then
            log("Sample around line 2913:")
            for sub = math.max(1, 2900), math.min(#lines, 2950) do
                log(string.format("%4d: %s", sub, lines[sub]))
            end
        end
    else
        log("[-] decompile failed: " .. tostring(code))
    end
else
    log("[-] Cannot decompile: instance=" .. tostring(scriptInstance ~= nil) .. ", dec=" .. tostring(dec ~= nil))
end

log("\n=========================================")
log("[Gembul Decompiler] Complete!")
log("=========================================")

local fullText = table.concat(logLines, "\n")
if setclipboard then pcall(setclipboard, fullText) end

pcall(function()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GembulDecompGui"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 580, 0, 440)
    frame.Position = UDim2.new(0.5, -290, 0.5, -220)
    frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 255, 180)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(20, 40, 35)
    title.Text = "GEMBUL SCRIPT DECOMPILER (Copied to Clipboard!)"
    title.TextColor3 = Color3.fromRGB(0, 255, 180)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 13
    title.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 1, -80)
    box.Position = UDim2.new(0, 10, 0, 35)
    box.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
    box.TextColor3 = Color3.fromRGB(220, 220, 220)
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.MultiLine = true
    box.ClearTextOnFocus = false
    box.TextEditable = false
    box.Font = Enum.Font.Code
    box.TextSize = 11
    box.Text = fullText
    box.Parent = frame

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(1, -20, 0, 30)
    close.Position = UDim2.new(0, 10, 1, -40)
    close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    close.Text = "Close / Tutup"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Font = Enum.Font.SourceSansBold
    close.TextSize = 13
    close.Parent = frame
    close.MouseButton1Click:Connect(function() sg:Destroy() end)
end)
