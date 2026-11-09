-- =====================================================================
-- GEMBUL PUNCH DEEP PROBE
-- Menemukan struktur argumen Net.punch.send dan fungsi pemanggilnya
-- =====================================================================

local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local logLines = {}

local function log(str)
    print(str)
    logLines[#logLines + 1] = tostring(str)
end

log("=========================================")
log("[Gembul Punch Probe] Starting Analysis...")
log("=========================================")

local Net = nil
if type(getgc) == "function" then
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "call") and rawget(v, "on") and rawget(v, "punch") then
            Net = v
            break
        end
    end
end

if not Net then
    log("[-] ERROR: Net table not found in GC!")
    return
end

log("[+] SUCCESS: Net table located!")
local p = Net.punch

local gc = getconstants or (debug and debug.getconstants)
local gu = getupvalues or (debug and debug.getupvalues)
local gu1 = getupvalue or (debug and debug.getupvalue)
local gi = getinfo or (debug and debug.getinfo)

-- 1. Inspect reader
if p.reader and gc then
    log("\n--- [1] Net.punch.reader Constants ---")
    local ok, c = pcall(gc, p.reader)
    if ok and type(c) == "table" then
        for i, val in pairs(c) do log(string.format("  [%d] %s (%s)", i, tostring(val), type(val))) end
    end
end

-- 2. Inspect send
if p.send and gc then
    log("\n--- [2] Net.punch.send Constants ---")
    local ok, c = pcall(gc, p.send)
    if ok and type(c) == "table" then
        for i, val in pairs(c) do log(string.format("  [%d] %s (%s)", i, tostring(val), type(val))) end
    end
end

-- 3. Inspect send Upvalue[1] (ByteNet Serializer/Writer)
if p.send and gu1 then
    log("\n--- [3] Net.punch.send Upvalues ---")
    for i = 1, 10 do
        local ok, val = pcall(gu1, p.send, i)
        if not ok or val == nil then break end
        log(string.format("  Upvalue[%d] = %s (%s)", i, tostring(val), type(val)))
        if type(val) == "function" and gc then
            log(string.format("    -> Constants of Upvalue[%d]:", i))
            local ok2, c2 = pcall(gc, val)
            if ok2 and type(c2) == "table" then
                for ci, cval in pairs(c2) do
                    log(string.format("       [%d] %s (%s)", ci, tostring(cval), type(cval)))
                end
            end
        elseif type(val) == "table" then
            log(string.format("    -> Table keys of Upvalue[%d]:", i))
            local count = 0
            for tk, tv in pairs(val) do
                count = count + 1
                if count <= 15 then
                    log(string.format("       %s = %s", tostring(tk), tostring(tv)))
                end
            end
        end
    end
end

-- 4. Hook Net.punch.send to catch real arguments live
log("\n--- [4] Setting up live Net.punch.send Hook ---")
if p.send then
    local origSend = p.send
    _G.__OrigPunchSend = origSend
    p.send = function(...)
        local args = { ... }
        local str = "[PUNCH SENT!] "
        for idx, arg in ipairs(args) do
            if type(arg) == "table" then
                local tblStr = "{"
                for k, v in pairs(arg) do
                    tblStr = tblStr .. tostring(k) .. "=" .. tostring(v) .. ", "
                end
                tblStr = tblStr .. "}"
                str = str .. string.format("arg[%d]=%s ", idx, tblStr)
            else
                str = str .. string.format("arg[%d]=%s ", idx, tostring(arg))
            end
        end
        print(str)
        log(str)
        if setclipboard then pcall(setclipboard, str) end
        return origSend(...)
    end
    log("[+] Hook installed! Punch ANY block in-game to see live arguments in console/clipboard.")
end

-- 5. Scan GC for game functions that call Net.punch or punch opcode (22)
log("\n--- [5] Scanning GC for Game Punch Callers ---")
local foundCallers = 0
if type(getgc) == "function" and gu then
    for _, fn in pairs(getgc()) do
        if type(fn) == "function" and fn ~= p.send and fn ~= p.reader then
            local ok, ups = pcall(gu, fn)
            if ok and type(ups) == "table" then
                local hasPunchSend = false
                for _, u in pairs(ups) do
                    if u == p.send or u == p or u == Net then
                        hasPunchSend = true
                        break
                    end
                end
                if hasPunchSend then
                    foundCallers = foundCallers + 1
                    local info = gi and gi(fn) or {}
                    log(string.format("  [Caller #%d] %s (source: %s, line: %s)", 
                        foundCallers, tostring(fn), tostring(info.source or "unknown"), tostring(info.currentline or "?")))
                    if gc then
                        local okc, c = pcall(gc, fn)
                        if okc and type(c) == "table" then
                            local sample = {}
                            for i = 1, math.min(10, #c) do table.insert(sample, tostring(c[i])) end
                            log("    Constants: " .. table.concat(sample, ", "))
                        end
                    end
                end
            end
        end
        if foundCallers >= 5 then break end
    end
end
log("Found " .. tostring(foundCallers) .. " caller function(s) referencing Net.punch.")

log("\n=========================================")
log("[Gembul Punch Probe] Scan Complete!")
log("=========================================")

local fullText = table.concat(logLines, "\n")
if setclipboard then pcall(setclipboard, fullText) end

-- Screen notification
pcall(function()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GembulPunchProbeGui"
    sg.ResetOnSpawn = false
    local parent = CoreGui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    sg.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 480, 0, 320)
    frame.Position = UDim2.new(0.5, -240, 0.5, -160)
    frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 200, 255)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(30, 34, 44)
    title.Text = "GEMBUL PUNCH PROBE RESULT (Copied to Clipboard!)"
    title.TextColor3 = Color3.fromRGB(0, 255, 180)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 14
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
    close.Text = "Close / Tutup (Sekarang coba Pukul 1 block di game!)"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Font = Enum.Font.SourceSansBold
    close.TextSize = 13
    close.Parent = frame
    close.MouseButton1Click:Connect(function() sg:Destroy() end)
end)
