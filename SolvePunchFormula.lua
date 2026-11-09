-- =====================================================================
-- GEMBUL FORMULA SOLVER & LIVE TILE BREAKER
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
log("[Gembul Solver] Initializing...")
log("=========================================")

local gc = getconstants or (debug and debug.getconstants)
local gi = getinfo or (debug and debug.getinfo)
local dec = decompile or (debug and debug.decompile)

-- 1. Locate Net table
local Net = nil
if type(getgc) == "function" then
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "call") and rawget(v, "on") and rawget(v, "punch") then
            Net = v
            break
        end
    end
end

if not Net or not Net.punch or not Net.punch.send then
    log("[-] ERROR: Net.punch.send not found!")
    return
end

local punchSend = _G.__OrigPunchSend or Net.punch.send
log("[+] SUCCESS: Net.punch.send is ready!")

-- 2. Search for ModuleScript gpyFVVfSt to decompile
local targetModule = nil
for _, obj in pairs(game:GetDescendants()) do
    if obj:IsA("ModuleScript") and (obj.Name == "gpyFVVfSt" or obj.Name:find("gpyF")) then
        targetModule = obj
        break
    end
end

if not targetModule then
    -- Search by parent names
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("ModuleScript") and (obj.Name == "wNclre5LNi2" or obj.Name == "IllxqxY20bB" or obj.Name == "duRBT5mgmRPF") then
            log("Found parent module: " .. obj:GetFullName())
            targetModule = obj:FindFirstChild("gpyFVVfSt") or obj
        end
    end
end

if targetModule and dec then
    log("[+] Found ModuleScript: " .. targetModule:GetFullName())
    log("Decompiling module now...")
    local ok, code = pcall(dec, targetModule)
    if ok and type(code) == "string" and #code > 0 then
        log("Decompile successful! Searching for 'punch' in code...")
        local lines = code:split("\n")
        local foundCount = 0
        for i, l in ipairs(lines) do
            if l:find("punch") or l:find("send") or l:find("punchReady") then
                foundCount = foundCount + 1
                if foundCount <= 4 then
                    log(string.format("\n--- Line %d ---", i))
                    for sub = math.max(1, i - 4), math.min(#lines, i + 6) do
                        log(string.format("%4d: %s", sub, lines[sub]))
                    end
                end
            end
        end
    else
        log("[-] decompile failed: " .. tostring(code))
    end
else
    log("[-] ModuleScript instance not found or decompile unavailable.")
end

-- 3. Live Break Test Helper
-- Get tile coordinates in front of player
local function getTargetTile()
    -- Try reading position from game Refs or character
    local char = LocalPlayer.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
    local pos = hrp and hrp.Position
    -- Default or fallback
    local tx = pos and math.floor(pos.X / 3.2) or 50
    local ty = pos and math.floor(-pos.Y / 3.2) or 30
    return tx, ty
end

local function testFormula(name, fn)
    log("\n[TESTING] " .. name)
    -- Target a block near player
    local char = LocalPlayer.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
    local px, py = 50, 30
    if hrp then
        -- GrowBlox tiles are roughly 1 unit in 2D coordinates or 32 pixels
        -- Let's inspect character position in world
        px = math.round(hrp.Position.X / 3.2)
        py = math.round(-hrp.Position.Y / 3.2)
    end

    -- Test multiple offset tiles around player (under feet, left, right)
    local offsets = {
        { dx = 0, dy = 1, desc = "Below feet" },
        { dx = 1, dy = 0, desc = "Right" },
        { dx = -1, dy = 0, desc = "Left" },
        { dx = 0, dy = 2, desc = "2 Below" }
    }

    for _, off in ipairs(offsets) do
        local tx = px + off.dx
        local ty = py + off.dy
        local val = fn(tx, ty)
        if val and val >= 0 and val <= 65535 then
            log(string.format("  Shooting at (%d, %d - %s) -> index: %d", tx, ty, off.desc, val))
            -- Send 3 rapid hits to break Dirt
            task.spawn(function()
                for h = 1, 3 do
                    pcall(punchSend, val)
                    if Net.act and Net.act.send then
                        pcall(Net.act.send, { kind = 6, x = tx + 0.5, y = ty + 0.5 })
                    end
                    task.wait(0.18)
                end
            end)
        else
            log(string.format("  Invalid index for (%d, %d): %s", tx, ty, tostring(val)))
        end
    end
end

log("\n=========================================")
log("Solver ready! Use buttons below to test.")
log("=========================================")

local fullText = table.concat(logLines, "\n")
if setclipboard then pcall(setclipboard, fullText) end

-- GUI with Test Buttons
pcall(function()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GembulSolverGui"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 580, 0, 460)
    frame.Position = UDim2.new(0.5, -290, 0.5, -230)
    frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 255, 180)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(20, 40, 35)
    title.Text = "GEMBUL FORMULA SOLVER & TESTER"
    title.TextColor3 = Color3.fromRGB(0, 255, 180)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 13
    title.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 1, -160)
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

    local function refreshBox()
        box.Text = table.concat(logLines, "\n")
    end

    -- Formula Buttons Container
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -20, 0, 75)
    btnContainer.Position = UDim2.new(0, 10, 1, -120)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = frame

    local formulas = {
        { name = "F1: (y-1)*100 + x", fn = function(x, y) return (y - 1) * 100 + x end },
        { name = "F2: (y-1)*100 + (x-1)", fn = function(x, y) return (y - 1) * 100 + (x - 1) end },
        { name = "F3: y*100 + x", fn = function(x, y) return y * 100 + x end },
        { name = "F4: (x-1)*60 + y", fn = function(x, y) return (x - 1) * 60 + y end },
        { name = "F5: bit32(x, y<<8)", fn = function(x, y) return bit32.bor(x, bit32.lshift(y, 8)) end },
    }

    for idx, f in ipairs(formulas) do
        local btn = Instance.new("TextButton")
        local row = idx > 3 and 1 or 0
        local col = (idx - 1) % 3
        btn.Size = UDim2.new(0.31, 0, 0, 32)
        btn.Position = UDim2.new(col * 0.34, 0, row * 0.5, 0)
        btn.BackgroundColor3 = Color3.fromRGB(30, 70, 90)
        btn.Text = f.name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 11
        btn.Parent = btnContainer
        btn.MouseButton1Click:Connect(function()
            testFormula(f.name, f.fn)
            refreshBox()
        end)
    end

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(1, -20, 0, 30)
    close.Position = UDim2.new(0, 10, 1, -38)
    close.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    close.Text = "Tutup / Close"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Font = Enum.Font.SourceSansBold
    close.TextSize = 13
    close.Parent = frame
    close.MouseButton1Click:Connect(function() sg:Destroy() end)
end)
