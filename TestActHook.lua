-- =====================================================================
-- GEMBUL ACT HOOK & RAPID HIT TEST
-- =====================================================================

local CoreGui = game:GetService("CoreGui")
local logLines = {}
local function log(str)
    print(str)
    logLines[#logLines + 1] = tostring(str)
end

log("=========================================")
log("[Gembul Act Hook] Analyzing act function...")
log("=========================================")

local gc = getconstants or (debug and debug.getconstants)
local gu = getupvalues or (debug and debug.getupvalues)
local gu1 = getupvalue or (debug and debug.getupvalue)
local su = setupvalue or (debug and debug.setupvalue)
local gi = getinfo or (debug and debug.getinfo)

local actFn = nil
if type(getgc) == "function" then
    for _, fn in pairs(getgc()) do
        if type(fn) == "function" then
            local info = gi and gi(fn) or {}
            local src = tostring(info.source or "")
            if src:find("VuL3pV8m4") and (info.currentline == 2913 or tostring(info.name) == "act") then
                actFn = fn
                break
            end
        end
    end
end

if not actFn then
    log("[-] ERROR: act line 2913 not found in GC!")
    return
end

local actInfo = gi(actFn)
log(string.format("[+] SUCCESS: act found! params=%d, is_vararg=%s, line=%d", 
    actInfo.nparams or 0, tostring(actInfo.is_vararg), actInfo.currentline or 0))

-- Inspect function upvalues of act
if gu then
    log("\n--- Function Upvalues in act ---")
    local ok, ups = pcall(gu, actFn)
    if ok and type(ups) == "table" then
        for i, val in pairs(ups) do
            if type(val) == "function" then
                local uinfo = gi and gi(val) or {}
                log(string.format("  Upvalue[%d] = %s line %s (source: %s)", 
                    i, tostring(uinfo.name or "anon"), tostring(uinfo.currentline or "?"), tostring(uinfo.source or "")))
                if gc then
                    local okc, c = pcall(gc, val)
                    if okc and type(c) == "table" then
                        local cs = {}
                        for ci = 1, math.min(15, #c) do table.insert(cs, string.format("[%d]=%s", ci, tostring(c[ci]))) end
                        log("     Constants: " .. table.concat(cs, ", "))
                    end
                end
            end
        end
    end
end

-- Hook act function live
log("\n--- Installing Live Hook on act ---")
_G.__GembulActLogs = {}
local isRapidPunching = false

-- Use hookfunction / replaceclosure or wrap
local hookInstalled = false
if hookfunction then
    local origAct = nil
    origAct = hookfunction(actFn, function(...)
        local args = { ... }
        local str = string.format("[ACT CALLED!] Args (%d): ", #args)
        for i, a in ipairs(args) do
            str = str .. string.format("arg[%d]=%s (%s) ", i, tostring(a), type(a))
        end
        print(str)
        table.insert(_G.__GembulActLogs, str)
        if setclipboard then pcall(setclipboard, str) end

        -- Execute original punch
        local ret = origAct(...)

        -- TEST RAPID PUNCH: if player punches, send 2 extra hits immediately!
        if not isRapidPunching and #args >= 2 then
            isRapidPunching = true
            task.spawn(function()
                for burst = 1, 4 do
                    task.wait(0.18)
                    pcall(origAct, unpack(args))
                end
                isRapidPunching = false
            end)
        end

        return ret
    end)
    hookInstalled = true
    log("[+] hookfunction successfully installed on act!")
else
    log("[-] hookfunction not available on this executor, scanning for callers...")
end

log("\n=========================================")
log("[Gembul Act Hook] Ready! Now punch ANY block in-game!")
log("=========================================")

local fullText = table.concat(logLines, "\n")
if setclipboard then pcall(setclipboard, fullText) end

pcall(function()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GembulActHookGui"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 520, 0, 340)
    frame.Position = UDim2.new(0.5, -260, 0.5, -170)
    frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(50, 255, 120)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(20, 45, 30)
    title.Text = "GEMBUL ACT HOOK (Active! Sekarang Pukul 1 Block di Game!)"
    title.TextColor3 = Color3.fromRGB(50, 255, 120)
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
    close.Text = "Tutup (Lalu coba Pukul 1 block Tanah/Dirt di game!)"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Font = Enum.Font.SourceSansBold
    close.TextSize = 13
    close.Parent = frame
    close.MouseButton1Click:Connect(function() sg:Destroy() end)
end)
