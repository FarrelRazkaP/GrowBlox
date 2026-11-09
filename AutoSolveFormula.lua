-- =====================================================================
-- GEMBUL AUTO FORMULA SOLVER (Click-to-Solve)
-- =====================================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local logLines = {}
local function log(str)
    print(str)
    logLines[#logLines + 1] = tostring(str)
end

log("=========================================")
log("[Gembul Auto Solver] Initializing...")
log("=========================================")

-- 1. Find Net table and World
local Net = nil
local World = nil

if type(getgc) == "function" then
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            if not Net and rawget(v, "call") and rawget(v, "on") and rawget(v, "punch") then
                Net = v
            end
            if not World and rawget(v, "fg") and rawget(v, "bg") and rawget(v, "w") and rawget(v, "h") then
                World = v
            end
            if Net and World then break end
        end
    end
end

if not Net or not Net.punch or not Net.punch.send then
    log("[-] ERROR: Net.punch.send not found in GC!")
    return
end

local punchSend = _G.__OrigPunchSend or Net.punch.send
log("[+] Net.punch.send is ready!")
log("World found: " .. tostring(World ~= nil) .. (World and string.format(" (size %dx%d)", World.w or 100, World.h or 60) or ""))

local function tileAt(layer, x, y)
    if World and World[layer] and World[layer][y] then
        return World[layer][y][x] or 0
    end
    return nil
end

local function getView()
    local gg = PlayerGui:FindFirstChild("GameGui")
    local cam = gg and gg:FindFirstChild("World") and gg.World:FindFirstChild("Camera")
    local tiles = cam and cam:FindFirstChild("Tiles")
    local pv = cam and cam:FindFirstChild("PlayerView")
    if not (tiles and pv) then return nil end
    local sample = tiles:FindFirstChildWhichIsA("ImageLabel")
    if not sample or sample.AbsoluteSize.X <= 0 then return nil end
    return { tiles = tiles, pv = pv, ts = sample.AbsoluteSize.X }
end

local function getTileFromScreen(screenX, screenY)
    local v = getView()
    if not v or not v.tiles or not v.ts or v.ts <= 0 then return nil, nil end
    local tx = math.floor((screenX - v.tiles.AbsolutePosition.X) / v.ts) + 1
    local ty = math.floor((screenY - v.tiles.AbsolutePosition.Y) / v.ts) + 1
    return tx, ty
end

-- 10 Candidate Formulas
local formulas = {
    { name = "F1: (y-1)*100 + x", fn = function(x, y) return (y - 1) * 100 + x end },
    { name = "F2: (y-1)*100 + (x-1)", fn = function(x, y) return (y - 1) * 100 + (x - 1) end },
    { name = "F3: y*100 + x", fn = function(x, y) return y * 100 + x end },
    { name = "F4: (x-1)*60 + y", fn = function(x, y) return (x - 1) * 60 + y end },
    { name = "F5: (x-1)*60 + (y-1)", fn = function(x, y) return (x - 1) * 60 + (y - 1) end },
    { name = "F6: bit32(x, y<<8)", fn = function(x, y) return bit32.bor(x, bit32.lshift(y, 8)) end },
    { name = "F7: bit32(y, x<<8)", fn = function(x, y) return bit32.bor(y, bit32.lshift(x, 8)) end },
    { name = "F8: bit32(x-1, (y-1)<<8)", fn = function(x, y) return bit32.bor(x - 1, bit32.lshift(y - 1, 8)) end },
    { name = "F9: bit32(y-1, (x-1)<<8)", fn = function(x, y) return bit32.bor(y - 1, bit32.lshift(x - 1, 8)) end },
    { name = "F10: x + y*60", fn = function(x, y) return x + y * 60 end },
}

local winningFormula = nil
local isTesting = false

-- Screen GUI
local sg = Instance.new("ScreenGui")
sg.Name = "GembulAutoSolverGui"
sg.ResetOnSpawn = false
sg.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 540, 0, 360)
frame.Position = UDim2.new(0.5, -270, 0.5, -180)
frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(0, 220, 255)
frame.Active = true
frame.Draggable = true
frame.Parent = sg

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundColor3 = Color3.fromRGB(25, 35, 45)
title.Text = "GEMBUL CLICK-TO-SOLVE FORMULA (KLIK 1 BLOCK DI GAME!)"
title.TextColor3 = Color3.fromRGB(0, 220, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 13
title.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 1, -85)
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
box.Text = "Menunggu klik Anda pada block Tanah/Dirt di game...\n"
box.Parent = frame

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

local function updateUI()
    box.Text = table.concat(logLines, "\n")
end

-- Test a clicked tile
local function testTile(screenX, screenY)
    if isTesting or winningFormula then return end
    local tx, ty = getTileFromScreen(screenX, screenY)
    if not tx or not ty then return end
    
    local startId = tileAt("fg", tx, ty)
    log(string.format("\n[TARGET CLICKED] Pos: (%d, %d), Tile ID: %s", tx, ty, tostring(startId)))
    updateUI()

    isTesting = true
    task.spawn(function()
        for idx, f in ipairs(formulas) do
            local val = f.fn(tx, ty)
            log(string.format("  Testing [%d/10] %s -> Index: %d", idx, f.name, val))
            updateUI()

            -- Fire 4 hits with this formula
            for h = 1, 4 do
                pcall(punchSend, val)
                if Net.act and Net.act.send then
                    pcall(Net.act.send, { kind = 6, x = tx + 0.5, y = ty + 0.5 })
                end
                task.wait(0.18)
            end

            -- Check if block broke
            task.wait(0.1)
            local currentId = tileAt("fg", tx, ty)
            if startId and startId ~= 0 and currentId == 0 then
                winningFormula = f
                log("\n" .. string.rep("=", 40))
                log("[!!!] JACKPOT! WINNING FORMULA FOUND:")
                log("  >>> " .. f.name .. " <<<")
                log(string.rep("=", 40))
                if setclipboard then pcall(setclipboard, f.name) end
                title.Text = "WINNER FOUND: " .. f.name
                title.TextColor3 = Color3.fromRGB(0, 255, 100)
                updateUI()
                break
            end
        end
        isTesting = false
        if not winningFormula then
            log("Semua 10 formula sudah dicoba pada koordinat ini. Coba klik block lain lebih dekat.")
            updateUI()
        end
    end)
end

-- Listen to mouse click on PC
local mouse = LocalPlayer:GetMouse()
mouse.Button1Down:Connect(function()
    testTile(mouse.X, mouse.Y)
end)

-- Listen to Touch on Mobile
UserInputService.TouchTap:Connect(function(touches)
    if touches and touches[1] then
        testTile(touches[1].X, touches[1].Y)
    end
end)

log("[+] Siap! Sekarang cukup KLIK 1 KALI pada block Tanah (Dirt) di samping karakter Anda.")
log("[+] Script akan otomatis mencoba ke-10 formula satu per satu sampai block hancur!")
updateUI()
