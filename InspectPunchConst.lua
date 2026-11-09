-- =====================================================================
-- GEMBUL PUNCH CONSTANT SEARCH
-- =====================================================================

local CoreGui = game:GetService("CoreGui")
local logLines = {}
local function log(str)
    print(str)
    logLines[#logLines + 1] = tostring(str)
end

log("=========================================")
log("[Gembul Punch Constant Search]")
log("=========================================")

local gc = getconstants or (debug and debug.getconstants)
local gu = getupvalues or (debug and debug.getupvalues)
local gi = getinfo or (debug and debug.getinfo)
local dec = decompile or (debug and debug.decompile)

local found = 0
if type(getgc) == "function" and gc then
    for _, fn in pairs(getgc()) do
        if type(fn) == "function" then
            local ok, c = pcall(gc, fn)
            if ok and type(c) == "table" then
                local hasPunch = false
                local hasSend = false
                for _, val in pairs(c) do
                    if val == "punch" or val == "Punch" then hasPunch = true end
                    if val == "send" or val == "Send" then hasSend = true end
                end
                if hasPunch then
                    found = found + 1
                    local info = gi and gi(fn) or {}
                    log(string.format("\n[Match #%d] %s line %s (source: %s, hasSend: %s)", 
                        found, tostring(info.name or "anon"), tostring(info.currentline or "?"), 
                        tostring(info.source or "unknown"), tostring(hasSend)))
                    
                    local clist = {}
                    for i = 1, math.min(30, #c) do
                        table.insert(clist, string.format("[%d]=%s", i, tostring(c[i])))
                    end
                    log("  Constants: " .. table.concat(clist, ", "))

                    if gu then
                        local oku, u = pcall(gu, fn)
                        if oku and type(u) == "table" then
                            local ulist = {}
                            for i = 1, math.min(10, #u) do
                                table.insert(ulist, string.format("[%d]=%s(%s)", i, tostring(u[i]), type(u[i])))
                            end
                            log("  Upvalues: " .. table.concat(ulist, ", "))
                        end
                    end

                    if dec then
                        local okd, code = pcall(dec, fn)
                        if okd and type(code) == "string" and #code > 0 then
                            log("  Decompiled:\n" .. code:sub(1, 1000))
                        end
                    end
                end
            end
        end
        if found >= 10 then break end
    end
end

log(string.format("\nTotal matches with 'punch' in constants: %d", found))

-- ALSO: Let's test hitting a tile near player with candidate formulas!
log("\n--- [2] Live Tile Hit Test ---")
local Net = nil
for _, v in pairs(getgc(true)) do
    if type(v) == "table" and rawget(v, "call") and rawget(v, "on") and rawget(v, "punch") then
        Net = v
        break
    end
end

local realSend = _G.__OrigPunchSend or (Net and Net.punch and Net.punch.send)
log("realSend available: " .. tostring(realSend ~= nil))

log("\n=========================================")
log("[Gembul Punch Constant Search] Complete!")
log("=========================================")

local fullText = table.concat(logLines, "\n")
if setclipboard then pcall(setclipboard, fullText) end

pcall(function()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GembulPunchConstGui"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 540, 0, 380)
    frame.Position = UDim2.new(0.5, -270, 0.5, -190)
    frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 200, 255)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(20, 35, 45)
    title.Text = "GEMBUL PUNCH CONSTANT SEARCH (Copied to Clipboard!)"
    title.TextColor3 = Color3.fromRGB(0, 220, 255)
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
