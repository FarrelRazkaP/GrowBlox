-- =====================================================================
-- GEMBUL DISASSEMBLE & FORMULA SOLVER
-- =====================================================================

local CoreGui = game:GetService("CoreGui")
local logLines = {}
local function log(str)
    print(str)
    logLines[#logLines + 1] = tostring(str)
end

log("=========================================")
log("[Gembul Disassemble] Analyzing act()...")
log("=========================================")

local gc = getconstants or (debug and debug.getconstants)
local gu = getupvalues or (debug and debug.getupvalues)
local gi = getinfo or (debug and debug.getinfo)
local dis = disassemble or (debug and debug.disassemble)
local dec = decompile or (debug and debug.decompile)

local actFn = nil
if type(getgc) == "function" and gc then
    for _, fn in pairs(getgc()) do
        if type(fn) == "function" then
            local info = gi and gi(fn) or {}
            local src = tostring(info.source or "")
            if src ~= "=loadstring" and not src:find("Gembul") and not src:find("Test") then
                local ok, c = pcall(gc, fn)
                if ok and type(c) == "table" and #c >= 50 then
                    local hasPunchReady, hasWrench = false, false
                    for _, v in pairs(c) do
                        if v == "punchReady" or v == "pressPunch" then hasPunchReady = true end
                        if v == "wrenchTile" or v == "vendOwner" then hasWrench = true end
                    end
                    if hasPunchReady and hasWrench then
                        actFn = fn
                        break
                    end
                end
            end
        end
    end
end

if not actFn then
    log("[-] ERROR: Real act() function not found!")
else
    local info = gi(actFn)
    log(string.format("[+] SUCCESS: act() found at %s line %s", tostring(info.source), tostring(info.currentline)))

    if dis then
        log("\n--- Disassembling act() ---")
        local ok, asm = pcall(dis, actFn)
        if ok and type(asm) == "string" and #asm > 0 then
            log("Disassembly snippet (searching for punch/send):")
            local lines = asm:split("\n")
            local foundSection = false
            for idx, l in ipairs(lines) do
                if l:find("punch") or l:find("send") or l:find("137") or l:find("138") or l:find("j1PKXTgzz") then
                    log(string.format("Line %d: %s", idx, l))
                    for sub = math.max(1, idx - 10), math.min(#lines, idx + 10) do
                        log(string.format("  [%d] %s", sub, lines[sub]))
                    end
                    log("-----------------------------------------")
                    foundSection = true
                end
            end
            if not foundSection then
                log("Asm sample:\n" .. asm:sub(1, 2000))
            end
        else
            log("disassemble returned: " .. tostring(asm))
        end
    else
        log("[-] disassemble not available on this executor.")
    end

    if dec then
        log("\n--- Decompiling act() ---")
        local ok, src = pcall(dec, actFn)
        if ok and type(src) == "string" and #src > 0 then
            log("Decompiled code around punch:")
            local lines = src:split("\n")
            for idx, l in ipairs(lines) do
                if l:find("punch") or l:find("send") or l:find("j1PKXTgzz") then
                    for sub = math.max(1, idx - 5), math.min(#lines, idx + 5) do
                        log(string.format("  [%d] %s", sub, lines[sub]))
                    end
                    log("-----------------------------------------")
                end
            end
        else
            log("decompile returned: " .. tostring(src))
        end
    else
        log("[-] decompile not available on this executor.")
    end
end

-- Net table and real punch.send
local Net = nil
if type(getgc) == "function" then
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "call") and rawget(v, "on") and rawget(v, "punch") then
            Net = v
            break
        end
    end
end

local punchSend = Net and Net.punch and Net.punch.send
log("\nNet.punch.send found: " .. tostring(punchSend ~= nil))

log("\n=========================================")
log("[Gembul Disassemble] Scan Complete!")
log("=========================================")

local fullText = table.concat(logLines, "\n")
if setclipboard then pcall(setclipboard, fullText) end

-- Screen GUI
pcall(function()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GembulDisasmGui"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 560, 0, 420)
    frame.Position = UDim2.new(0.5, -280, 0.5, -210)
    frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 200, 255)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(20, 35, 50)
    title.Text = "GEMBUL PUNCH FORMULA DISASSEMBLY (Copied to Clipboard!)"
    title.TextColor3 = Color3.fromRGB(0, 220, 255)
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
