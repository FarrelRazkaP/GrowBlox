-- =====================================================================
-- GEMBUL DIRECT TILE BREAKER & FORMULA SOLVER
-- Automatic Player Position Tracking + Direct Break
-- =====================================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local logLines = {}
local function log(str)
    print(str)
    logLines[#logLines + 1] = tostring(str)
end

log("=========================================")
log("[Gembul Direct Solver] Scanning GC...")
log("=========================================")

local Net = nil
local World = nil
local StateFn = nil

if type(getgc) == "function" then
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            if not Net and rawget(v, "call") and rawget(v, "on") and rawget(v, "punch") then
                Net = v
            end
            if not World and rawget(v, "fg") and rawget(v, "bg") and rawget(v, "w") == 100 and rawget(v, "h") == 60 then
                World = v
            end
            if not StateFn and type(rawget(v, "state")) == "function" then
                local ok, s = pcall(rawget(v, "state"))
                if ok and type(s) == "table" and type(s.x) == "number" and type(s.y) == "number" then
                    StateFn = rawget(v, "state")
                end
            end
            if Net and World and StateFn then break end
        end
    end
end

if not Net or not Net.punch or not Net.punch.send then
    log("[-] ERROR: Net.punch.send not found!")
    return
end

local punchSend = _G.__OrigPunchSend or Net.punch.send
log("[+] Net.punch.send: READY")
log("[+] World: " .. (World and "FOUND (100x60)" or "NOT FOUND"))
log("[+] StateFn (Player Position): " .. (StateFn and "FOUND" or "NOT FOUND"))

local function getPlayerPos()
    if StateFn then
        local ok, s = pcall(StateFn)
        if ok and type(s) == "table" and type(s.x) == "number" then
            return math.floor(s.x), math.floor(s.y)
        end
    end
    -- Fallback to Character
    local char = LocalPlayer.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
    if hrp then
        -- In GrowBlox default camera scale
        return math.round(hrp.Position.X / 3.2), math.round(-hrp.Position.Y / 3.2)
    end
    return 61, 47
end

local function tileAt(layer, x, y)
    if World and World[layer] and World[layer][y] then
        return World[layer][y][x] or 0
    end
    return 0
end

local px, py = getPlayerPos()
log(string.format("[+] Current Player Position: x=%d, y=%d", px, py))

-- Check surrounding blocks
log("Checking surrounding tiles (fg):")
log(string.format("  Below feet (%d, %d): ID = %d", px, py + 1, tileAt("fg", px, py + 1)))
log(string.format("  Under head (%d, %d): ID = %d", px, py, tileAt("fg", px, py)))
log(string.format("  To Right   (%d, %d): ID = %d", px + 1, py, tileAt("fg", px + 1, py)))
log(string.format("  To Left    (%d, %d): ID = %d", px - 1, py, tileAt("fg", px - 1, py)))

-- 5 Primary Candidate Formulas
local formulas = {
    { name = "F1: (y-1)*100 + x", fn = function(x, y) return (y - 1) * 100 + x end },
    { name = "F2: (y-1)*100 + (x-1)", fn = function(x, y) return (y - 1) * 100 + (x - 1) end },
    { name = "F3: y*100 + x", fn = function(x, y) return y * 100 + x end },
    { name = "F4: (x-1)*60 + y", fn = function(x, y) return (x - 1) * 60 + y end },
    { name = "F5: bit32(x, y<<8)", fn = function(x, y) return bit32.bor(x, bit32.lshift(y, 8)) end },
}

-- Screen GUI
local sg = Instance.new("ScreenGui")
sg.Name = "GembulDirectSolverGui"
sg.ResetOnSpawn = false
sg.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 560, 0, 440)
frame.Position = UDim2.new(0.5, -280, 0.5, -220)
frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(0, 255, 150)
frame.Active = true
frame.Draggable = true
frame.Parent = sg

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundColor3 = Color3.fromRGB(25, 40, 35)
title.Text = "GEMBUL DIRECT TILE BREAKER"
title.TextColor3 = Color3.fromRGB(0, 255, 150)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 13
title.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 1, -150)
box.Position = UDim2.new(0, 10, 0, 40)
box.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
box.TextColor3 = Color3.fromRGB(220, 220, 220)
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.MultiLine = true
box.ClearTextOnFocus = false
box.TextEditable = false
box.Font = Enum.Font.Code
box.TextSize = 11
box.Text = table.concat(logLines, "\n")
box.Parent = frame

local function updateUI()
    box.Text = table.concat(logLines, "\n")
end

local function executeTest(fIdx, targetDesc, dx, dy)
    local curX, curY = getPlayerPos()
    local tx = curX + dx
    local ty = curY + dy
    local f = formulas[fIdx]
    local val = f.fn(tx, ty)
    local beforeId = tileAt("fg", tx, ty)

    log(string.format("\n[ATTACK] Formula: %s | Target: %s (%d, %d)", f.name, targetDesc, tx, ty))
    log(string.format("  Initial Tile ID: %d | Computed Net Index: %d", beforeId, val))
    log("  Sending 3 rapid punch packets to server...")
    updateUI()

    task.spawn(function()
        for hit = 1, 3 do
            pcall(punchSend, val)
            if Net.act and Net.act.send then
                pcall(Net.act.send, { kind = 6, x = tx + 0.5, y = ty + 0.5 })
            end
            task.wait(0.18)
        end

        task.wait(0.3)
        local afterId = tileAt("fg", tx, ty)
        log(string.format("  Result: Before=%d, After=%d", beforeId, afterId))
        if beforeId ~= 0 and afterId == 0 then
            log("  >>> SUCCESS! BLOCK BROKE! " .. f.name .. " IS THE WINNING FORMULA! <<<")
            if setclipboard then pcall(setclipboard, f.name) end
        end
        updateUI()
    end)
end

-- Controls
local ctl = Instance.new("Frame")
ctl.Size = UDim2.new(1, -20, 0, 70)
ctl.Position = UDim2.new(0, 10, 1, -105)
ctl.BackgroundTransparency = 1
ctl.Parent = frame

-- Button 1: Test F1 on Feet
local b1 = Instance.new("TextButton")
b1.Size = UDim2.new(0.31, 0, 0, 30)
b1.Position = UDim2.new(0, 0, 0, 0)
b1.BackgroundColor3 = Color3.fromRGB(35, 75, 110)
b1.Text = "1. Test F1 (Feet)"
b1.TextColor3 = Color3.fromRGB(255, 255, 255)
b1.Font = Enum.Font.SourceSansBold
b1.TextSize = 12
b1.Parent = ctl
b1.MouseButton1Click:Connect(function() executeTest(1, "Feet", 0, 1) end)

-- Button 2: Test F2 on Feet
local b2 = Instance.new("TextButton")
b2.Size = UDim2.new(0.31, 0, 0, 30)
b2.Position = UDim2.new(0.34, 0, 0, 0)
b2.BackgroundColor3 = Color3.fromRGB(35, 75, 110)
b2.Text = "2. Test F2 (Feet)"
b2.TextColor3 = Color3.fromRGB(255, 255, 255)
b2.Font = Enum.Font.SourceSansBold
b2.TextSize = 12
b2.Parent = ctl
b2.MouseButton1Click:Connect(function() executeTest(2, "Feet", 0, 1) end)

-- Button 3: Test F3 on Feet
local b3 = Instance.new("TextButton")
b3.Size = UDim2.new(0.31, 0, 0, 30)
b3.Position = UDim2.new(0.68, 0, 0, 0)
b3.BackgroundColor3 = Color3.fromRGB(35, 75, 110)
b3.Text = "3. Test F3 (Feet)"
b3.TextColor3 = Color3.fromRGB(255, 255, 255)
b3.Font = Enum.Font.SourceSansBold
b3.TextSize = 12
b3.Parent = ctl
b3.MouseButton1Click:Connect(function() executeTest(3, "Feet", 0, 1) end)

-- Button 4: Test F1 on Right Tile
local b4 = Instance.new("TextButton")
b4.Size = UDim2.new(0.31, 0, 0, 30)
b4.Position = UDim2.new(0, 0, 0, 35)
b4.BackgroundColor3 = Color3.fromRGB(80, 50, 110)
b4.Text = "4. Test F1 (Right)"
b4.TextColor3 = Color3.fromRGB(255, 255, 255)
b4.Font = Enum.Font.SourceSansBold
b4.TextSize = 12
b4.Parent = ctl
b4.MouseButton1Click:Connect(function() executeTest(1, "Right", 1, 0) end)

-- Button 5: Test F2 on Right Tile
local b5 = Instance.new("TextButton")
b5.Size = UDim2.new(0.31, 0, 0, 30)
b5.Position = UDim2.new(0.34, 0, 0, 35)
b5.BackgroundColor3 = Color3.fromRGB(80, 50, 110)
b5.Text = "5. Test F2 (Right)"
b5.TextColor3 = Color3.fromRGB(255, 255, 255)
b5.Font = Enum.Font.SourceSansBold
b5.TextSize = 12
b5.Parent = ctl
b5.MouseButton1Click:Connect(function() executeTest(2, "Right", 1, 0) end)

-- Button 6: Test F3 on Right Tile
local b6 = Instance.new("TextButton")
b6.Size = UDim2.new(0.31, 0, 0, 30)
b6.Position = UDim2.new(0.68, 0, 0, 35)
b6.BackgroundColor3 = Color3.fromRGB(80, 50, 110)
b6.Text = "6. Test F3 (Right)"
b6.TextColor3 = Color3.fromRGB(255, 255, 255)
b6.Font = Enum.Font.SourceSansBold
b6.TextSize = 12
b6.Parent = ctl
b6.MouseButton1Click:Connect(function() executeTest(3, "Right", 1, 0) end)

local close = Instance.new("TextButton")
close.Size = UDim2.new(1, -20, 0, 26)
close.Position = UDim2.new(0, 10, 1, -30)
close.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
close.Text = "Close / Tutup"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Font = Enum.Font.SourceSansBold
close.TextSize = 12
close.Parent = frame
close.MouseButton1Click:Connect(function() sg:Destroy() end)

log("\n[+] Siap! Klik salah satu tombol di bawah untuk langsung menembakkan pukulan ke block!")
updateUI()
