-- =====================================================================
-- GEMBUL CALLER & WRITER DEEP PROBE
-- =====================================================================

local CoreGui = game:GetService("CoreGui")
local logLines = {}
local function log(str)
    print(str)
    logLines[#logLines + 1] = tostring(str)
end

log("=========================================")
log("[Gembul Caller Probe] Starting Analysis...")
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
    log("[-] ERROR: Net table not found!")
    return
end

local p = Net.punch
local realSend = _G.__OrigPunchSend or p.send

local gc = getconstants or (debug and debug.getconstants)
local gu = getupvalues or (debug and debug.getupvalues)
local gu1 = getupvalue or (debug and debug.getupvalue)
local gi = getinfo or (debug and debug.getinfo)
local dec = decompile or (debug and debug.decompile)

-- 1. Inspect realSend upvalues & constants
log("\n--- [1] Real Net.punch.send (Original) ---")
log("Function: " .. tostring(realSend))
if gu1 then
    for i = 1, 10 do
        local ok, val = pcall(gu1, realSend, i)
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
        end
        if type(val) == "function" and gu then
            local oku, u2 = pcall(gu, val)
            if oku and type(u2) == "table" then
                for ui, uval in pairs(u2) do
                    log(string.format("       Upval[%d] = %s (%s)", ui, tostring(uval), type(uval)))
                end
            end
        end
    end
end

-- 2. Scan GC specifically for Caller #1 and #2 from IhT5ewUdcA
log("\n--- [2] Scanning for Punch Caller Functions in Game Scripts ---")
if type(getgc) == "function" and gu then
    for _, fn in pairs(getgc()) do
        if type(fn) == "function" then
            local info = gi and gi(fn) or {}
            local src = tostring(info.source or "")
            if src:find("IhT5ewUdcA") or src:find("Punch") or src:find("punch") then
                local ok, consts = pcall(gc, fn)
                if ok and type(consts) == "table" then
                    local hasActOrPunch = false
                    for _, c in pairs(consts) do
                        if c == "punch" or c == "act" or c == "send" then
                            hasActOrPunch = true
                            break
                        end
                    end
                    if hasActOrPunch then
                        log(string.format("\n[Found Script Fn] %s line %s (source: %s)", 
                            tostring(info.name or "anonymous"), tostring(info.currentline or "?"), src))
                        local cSample = {}
                        for i = 1, math.min(25, #consts) do
                            table.insert(cSample, string.format("[%d]=%s", i, tostring(consts[i])))
                        end
                        log("  Constants: " .. table.concat(cSample, ", "))
                        
                        -- Upvalues
                        local oku, ups = pcall(gu, fn)
                        if oku and type(ups) == "table" then
                            for ui, uv in pairs(ups) do
                                log(string.format("  Upvalue[%s] = %s (%s)", tostring(ui), tostring(uv), type(uv)))
                            end
                        end

                        -- Decompile if supported
                        if dec then
                            local okd, code = pcall(dec, fn)
                            if okd and type(code) == "string" and #code > 0 then
                                log("  Decompiled:\n" .. code:sub(1, 800))
                            end
                        end
                    end
                end
            end
        end
    end
end

-- 3. Find the script instance named IhT5ewUdcA in game
log("\n--- [3] Locating Script Instance 'IhT5ewUdcA' ---")
for _, obj in pairs(game:GetDescendants()) do
    if obj.Name:find("IhT5ewUdcA") or (obj:IsA("LuaSourceContainer") and obj.Name:find("Punch")) then
        log(string.format("Found Instance: %s (Class: %s, Parent: %s)", 
            obj:GetFullName(), obj.ClassName, tostring(obj.Parent)))
        if dec then
            local okd, code = pcall(dec, obj)
            if okd and type(code) == "string" and #code > 0 then
                log("Decompiled script sample:\n" .. code:sub(1, 1200))
            end
        end
    end
end

-- 4. Test Calling Net.punch.send directly with test inputs
log("\n--- [4] Test Calling realSend with (x, y) vs index ---")
local testCalls = {
    { desc = "number: 100", args = { 100 } },
    { desc = "number: 3050", args = { 3050 } },
    { desc = "table: {x=50, y=30}", args = { { x = 50, y = 30 } } },
    { desc = "two numbers: 50, 30", args = { 50, 30 } },
}

for _, tc in ipairs(testCalls) do
    local ok, err = pcall(realSend, unpack(tc.args))
    log(string.format("  Call %s -> result: ok=%s, err=%s", tc.desc, tostring(ok), tostring(err)))
end

log("\n=========================================")
log("[Gembul Caller Probe] Complete!")
log("=========================================")

local fullText = table.concat(logLines, "\n")
if setclipboard then pcall(setclipboard, fullText) end

pcall(function()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GembulCallerProbeGui"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 520, 0, 360)
    frame.Position = UDim2.new(0.5, -260, 0.5, -180)
    frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 170, 0)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(35, 30, 20)
    title.Text = "GEMBUL CALLER PROBE (Copied to Clipboard!)"
    title.TextColor3 = Color3.fromRGB(255, 200, 50)
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
    close.Text = "Close / Tutup"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Font = Enum.Font.SourceSansBold
    close.TextSize = 13
    close.Parent = frame
    close.MouseButton1Click:Connect(function() sg:Destroy() end)
end)
