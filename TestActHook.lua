-- =====================================================================
-- GEMBUL ACT HOOK & AUTO FAST BREAK TEST (V2 - Strict Game Matching)
-- =====================================================================

local CoreGui = game:GetService("CoreGui")
local logLines = {}
local function log(str)
    print(str)
    logLines[#logLines + 1] = tostring(str)
end

log("=========================================")
log("[Gembul Act Hook] Scanning for game act()...")
log("=========================================")

local gc = getconstants or (debug and debug.getconstants)
local gu = getupvalues or (debug and debug.getupvalues)
local gi = getinfo or (debug and debug.getinfo)

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
title.Text = "GEMBUL ACT HOOK - FAST BREAK TEST"
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
box.Text = "Scanning GC...\n"
box.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(1, -20, 0, 30)
close.Position = UDim2.new(0, 10, 1, -40)
close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
close.Text = "Tutup / Close (Lalu coba Pukul 1 block Tanah di Game!)"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Font = Enum.Font.SourceSansBold
close.TextSize = 13
close.Parent = frame
close.MouseButton1Click:Connect(function() sg:Destroy() end)

local function updateUI()
    box.Text = table.concat(logLines, "\n")
end

-- Filter out own loadstring and ensure we find the 154-constant game function
local actFn = nil
local candidates = {}

if type(getgc) == "function" and gc then
    for _, fn in pairs(getgc()) do
        if type(fn) == "function" then
            local info = gi and gi(fn) or {}
            local src = tostring(info.source or "")
            if src ~= "=loadstring" and not src:find("TestActHook") then
                local ok, c = pcall(gc, fn)
                if ok and type(c) == "table" and #c >= 50 then
                    local hasPunchReady, hasWrench, hasFrozen = false, false, false
                    for _, v in pairs(c) do
                        if v == "punchReady" or v == "pressPunch" then hasPunchReady = true end
                        if v == "wrenchTile" or v == "reachesDoor" or v == "vendOwner" then hasWrench = true end
                        if v == "Frozen" or v == "door_shut" then hasFrozen = true end
                    end
                    if hasPunchReady and hasWrench and hasFrozen then
                        actFn = fn
                        break
                    end
                end
            end
        end
    end
end

if not actFn then
    log("[-] ERROR: Game act() function not found (strict match)!")
    updateUI()
    return
end

local info = gi and gi(actFn) or {}
log(string.format("[+] SUCCESS: Real Game act() found!\n  Source: %s\n  Line: %s\n  Params: %s", 
    tostring(info.source or "unknown"), tostring(info.currentline or "?"), tostring(info.nparams or "?")))

local isBursting = false
if hookfunction then
    local origAct = nil
    origAct = hookfunction(actFn, function(...)
        local args = { ... }
        local str = string.format("[PUNCH DETECTED!] Args (%d): ", #args)
        for i, a in ipairs(args) do
            str = str .. string.format("[%d]=%s (%s) ", i, tostring(a), type(a))
        end
        print(str)
        log(str)
        updateUI()
        if setclipboard then pcall(setclipboard, str) end

        -- Execute the player's original click
        local ret = origAct(...)

        -- AUTO FAST BREAK BURST: Send remaining hits to break the block!
        if not isBursting and #args >= 1 then
            isBursting = true
            task.spawn(function()
                for burst = 1, 4 do
                    task.wait(0.18)
                    pcall(origAct, unpack(args))
                end
                isBursting = false
            end)
        end

        return ret
    end)
    log("[+] HOOK RESMI GAME BERHASIL AKTIF!")
    log("[+] Silakan PUKUL 1 BLOCK TANAH (Dirt) sekarang!")
    log("[+] Hook akan otomatis memberondong pukulan sampai pecah!")
else
    log("[-] Executor tidak mendukung hookfunction!")
end

log("=========================================")
updateUI()
