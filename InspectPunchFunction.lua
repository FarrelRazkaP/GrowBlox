-- =====================================================================
-- GEMBUL PUNCH FUNCTION SCANNER
-- =====================================================================

local CoreGui = game:GetService("CoreGui")
local logLines = {}
local function log(str)
    print(str)
    logLines[#logLines + 1] = tostring(str)
end

log("=========================================")
log("[Gembul Punch Function Scanner]")
log("=========================================")

local gc = getconstants or (debug and debug.getconstants)
local gu = getupvalues or (debug and debug.getupvalues)
local gi = getinfo or (debug and debug.getinfo)
local dec = decompile or (debug and debug.decompile)

local funcs = {}
if type(getgc) == "function" then
    for _, fn in pairs(getgc()) do
        if type(fn) == "function" then
            local info = gi and gi(fn) or {}
            local src = tostring(info.source or "")
            if src:find("IhT5ewUdcA") then
                local line = info.currentline or 0
                table.insert(funcs, { fn = fn, info = info, line = line })
            end
        end
    end
end

-- Sort by line number
table.sort(funcs, function(a, b) return a.line < b.line end)

log(string.format("Found %d functions in IhT5ewUdcA", #funcs))

-- Find functions around lines 450-520 and 1190-1230
for _, entry in ipairs(funcs) do
    local line = entry.line
    if (line >= 480 and line <= 515) or (line >= 1200 and line <= 1235) or (line >= 1 and line <= 80) then
        local fn = entry.fn
        local info = entry.info
        log(string.format("\n--- Function at line %d (name: %s) ---", line, tostring(info.name or "anon")))
        
        if gc then
            local ok, c = pcall(gc, fn)
            if ok and type(c) == "table" then
                local clist = {}
                for i = 1, #c do
                    table.insert(clist, string.format("[%d]=%s", i, tostring(c[i])))
                end
                log("  Constants: " .. table.concat(clist, ", "))
            end
        end

        if gu then
            local ok, u = pcall(gu, fn)
            if ok and type(u) == "table" then
                local ulist = {}
                for i = 1, #u do
                    table.insert(ulist, string.format("[%d]=%s(%s)", i, tostring(u[i]), type(u[i])))
                end
                log("  Upvalues: " .. table.concat(ulist, ", "))
            end
        end

        if dec then
            local okd, code = pcall(dec, fn)
            if okd and type(code) == "string" and #code > 0 then
                log("  Decompiled:\n" .. code)
            end
        end
    end
end

-- Now let's find ANY function in ALL of GC that has `writeu16` or opcode 22 or calls `Net.punch.send`!
log("\n=========================================")
log("--- Finding exact punch index formula ---")
local Net = nil
for _, v in pairs(getgc(true)) do
    if type(v) == "table" and rawget(v, "call") and rawget(v, "on") and rawget(v, "punch") then
        Net = v
        break
    end
end

local realSend = _G.__OrigPunchSend or (Net and Net.punch and Net.punch.send)
local foundPunchCaller = false
if realSend and gu then
    for _, fn in pairs(getgc()) do
        if type(fn) == "function" and fn ~= realSend then
            local ok, ups = pcall(gu, fn)
            if ok and type(ups) == "table" then
                for _, u in pairs(ups) do
                    if u == realSend then
                        local info = gi and gi(fn) or {}
                        log(string.format("\n[DIRECT PUNCH CALLER FOUND!] line %s in %s (name: %s)",
                            tostring(info.currentline), tostring(info.source), tostring(info.name)))
                        if gc then
                            local okc, c = pcall(gc, fn)
                            if okc and type(c) == "table" then
                                local clist = {}
                                for i = 1, #c do table.insert(clist, string.format("[%d]=%s", i, tostring(c[i]))) end
                                log("  Constants: " .. table.concat(clist, ", "))
                            end
                        end
                        if dec then
                            local okd, code = pcall(dec, fn)
                            if okd and type(code) == "string" then log("  Decompiled:\n" .. code) end
                        end
                        foundPunchCaller = true
                    end
                end
            end
        end
    end
end

log("\n=========================================")
log("[Gembul Punch Function Scanner] Complete!")
log("=========================================")

local fullText = table.concat(logLines, "\n")
if setclipboard then pcall(setclipboard, fullText) end

pcall(function()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GembulPunchFuncGui"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 540, 0, 380)
    frame.Position = UDim2.new(0.5, -270, 0.5, -190)
    frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 255, 120)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(20, 40, 30)
    title.Text = "GEMBUL PUNCH FORMULA SCANNER (Copied to Clipboard!)"
    title.TextColor3 = Color3.fromRGB(0, 255, 150)
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
