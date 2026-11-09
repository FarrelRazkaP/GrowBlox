-- =====================================================================
-- GEMBUL ACT & PUNCH INSPECTOR
-- =====================================================================

local CoreGui = game:GetService("CoreGui")
local logLines = {}
local function log(str)
    print(str)
    logLines[#logLines + 1] = tostring(str)
end

log("=========================================")
log("[Gembul Act Inspector] Deep Analyzing...")
log("=========================================")

local gc = getconstants or (debug and debug.getconstants)
local gu = getupvalues or (debug and debug.getupvalues)
local gi = getinfo or (debug and debug.getinfo)
local dec = decompile or (debug and debug.decompile)

local targetFns = {}
if type(getgc) == "function" then
    for _, fn in pairs(getgc()) do
        if type(fn) == "function" then
            local info = gi and gi(fn) or {}
            local src = tostring(info.source or "")
            if src:find("VuL3pV8m4") or src:find("kFxDpQ8oQtP") then
                local line = info.currentline or 0
                if line >= 2880 and line <= 3250 then
                    table.insert(targetFns, { fn = fn, info = info, line = line })
                end
            end
        end
    end
end

table.sort(targetFns, function(a, b) return a.line < b.line end)
log(string.format("Found %d function(s) in VuL3pV8m4 between lines 2880-3250", #targetFns))

for _, item in ipairs(targetFns) do
    local fn = item.fn
    local info = item.info
    local line = item.line
    log(string.format("\n=========================================\n[Function] %s line %d (source: %s)", 
        tostring(info.name or "anon"), line, tostring(info.source)))

    if gc then
        local ok, c = pcall(gc, fn)
        if ok and type(c) == "table" then
            log(string.format("Total constants: %d", #c))
            local clist = {}
            for i = 1, #c do
                table.insert(clist, string.format("[%d]=%s", i, tostring(c[i])))
            end
            log("Constants:\n  " .. table.concat(clist, "\n  "))
        end
    end

    if gu then
        local ok, u = pcall(gu, fn)
        if ok and type(u) == "table" then
            log(string.format("Total upvalues: %d", #u))
            for i = 1, #u do
                log(string.format("  Upvalue[%d] = %s (%s)", i, tostring(u[i]), type(u[i])))
            end
        end
    end

    if dec then
        local okd, code = pcall(dec, fn)
        if okd and type(code) == "string" and #code > 0 then
            log("\n--- Decompiled Code ---\n" .. code)
        end
    end
end

log("\n=========================================")
log("[Gembul Act Inspector] Complete!")
log("=========================================")

local fullText = table.concat(logLines, "\n")
if setclipboard then pcall(setclipboard, fullText) end

pcall(function()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GembulActGui"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 560, 0, 400)
    frame.Position = UDim2.new(0.5, -280, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 120, 0)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(40, 25, 15)
    title.Text = "GEMBUL ACT INSPECTOR (Copied to Clipboard!)"
    title.TextColor3 = Color3.fromRGB(255, 160, 50)
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
