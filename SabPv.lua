--[[
    language: Lua
    file: AK2_Brainrot.lua
    target: Roblox (Steal a Brainrot)
    features: Net bypass, auto-steal, grapple TP, anti-ban, FPS unlock, one-way platforms, GUI
    tiktok: @ak2.v
]]

-- // ENVIRONMENT LOCK
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- // ANTI-PATCH LAYER — destroys Sammy's AC hooks before they start
local function nukeAntiCheat()
    for _, v in pairs(getgc(true)) do
        if type(v) == "function" then
            local info = debug.getinfo(v)
            if info and info.source and (info.source:find("anticheat") or info.source:find("sammy") or info.source:find("detect")) then
                local ups = {}
                local i = 1
                while true do
                    local name, val = debug.getupvalue(v, i)
                    if not name then break end
                    ups[name] = val
                    i = i + 1
                end
                if ups["Check"] or ups["Validate"] or ups["Report"] then
                    debug.setupvalue(v, 1, function() end)
                end
            end
        end
    end
    -- kill remotes
    for _, r in pairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") and (r.Name:lower():find("ban") or r.Name:lower():find("detect") or r.Name:lower():find("report")) then
            local old = r.OnServerEvent
            r.OnServerEvent = function(...)
                if select(2, ...) == LocalPlayer then return end
                return old and old(...)
            end
        end
    end
end
nukeAntiCheat()

-- // STATE
local state = {
    autoSteal = false,
    grappleTP = false,
    oneWay = false,
    fpsUncap = false,
    esp = false,
    targetMode = "richest", -- richest | closest
    stealth = false,
    espBoxes = {},
    espNames = {},
    espHealth = {},
    conns = {},
    flying = false,
    flySpeed = 50,
    bv = nil,
    bg = nil
}

-- // CACHE SCANNER (lightning fast)
local function getAnimalCache()
    local cache = SharedState and SharedState.AllAnimalsCache
    if type(cache) == "table" then return cache end
    -- fallback: scrape workspace
    local plots = Workspace:FindFirstChild("Plots")
    if plots then
        local list = {}
        for _, pl in pairs(plots:GetChildren()) do
            if pl:IsA("Model") then
                local owner = pl:FindFirstChild("Owner")
                if owner and owner:IsA("StringValue") then
                    table.insert(list, { plot = pl.Name, owner = owner.Value, slot = 1 })
                end
            end
        end
        return list
    end
    return {}
end

-- // FAST REMOTE RESOLVER (no fancy GUID scanning, direct hash brute)
local function resolveUseItem()
    local netFolder = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Net")
    if not netFolder then return nil end
    -- direct alias first
    local direct = netFolder:FindFirstChild("RE/UseItem")
    if direct then return direct end
    -- hash pair detection
    local reH, rfH = {}, {}
    for _, ch in pairs(netFolder:GetChildren()) do
        local nm = ch.Name
        if type(nm) == "string" then
            local pfx, rest = nm:match("^(R[EF])/(.+)$")
            if pfx and rest and #rest >= 32 and rest:match("^%x%x%x%x%x%x%x%x") then
                if pfx == "RE" then reH[rest] = ch else rfH[rest] = ch end
            end
        end
    end
    for h, ch in pairs(reH) do
        if rfH[h] then return ch end
    end
    return nil
end

-- // GRAPPLE TELEPORT (instant, no camera lag)
local function fireGrappleTP(targetPos)
    local remote = resolveUseItem()
    if not remote then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    -- force equip grapple
    local tool = char:FindFirstChild("Grapple Hook")
    if not tool then
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then tool = bp:FindFirstChild("Grapple Hook") end
        if tool and char:FindFirstChildOfClass("Humanoid") then
            pcall(function() char.Humanoid:EquipTool(tool) end)
        end
    end
    if not tool then return false end
    -- fake aim
    local oldCF = workspace.CurrentCamera.CFrame
    workspace.CurrentCamera.CFrame = CFrame.new(hrp.Position, targetPos)
    -- fire
    local ok = pcall(function()
        remote:FireServer(targetPos, Vector3.new(0, 0, 0), 1) -- typical grapple args
    end)
    if not ok then ok = pcall(function() tool:Activate() end) end
    workspace.CurrentCamera.CFrame = oldCF
    return ok
end

-- // AUTO-STEAL LOOP (speed optimized)
RunService.Heartbeat:Connect(function()
    if not state.autoSteal then return end
    local cache = getAnimalCache()
    if #cache == 0 then return end
    local target = nil
    if state.targetMode == "richest" then
        -- we need actual money values, but for now pick random rich-looking
        for _, a in ipairs(cache) do
            if a.owner and a.owner ~= LocalPlayer.Name and a.owner ~= LocalPlayer.DisplayName then
                target = a
                break
            end
        end
    else
        -- closest: find nearest plot
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local best, bestD = nil, math.huge
        for _, a in ipairs(cache) do
            if a.owner and a.owner ~= LocalPlayer.Name and a.owner ~= LocalPlayer.DisplayName then
                local pl = Workspace:FindFirstChild("Plots") and Workspace.Plots:FindFirstChild(a.plot)
                if pl then
                    local d = (pl:GetPivot().Position - hrp.Position).Magnitude
                    if d < bestD then bestD = d; best = a end
                end
            end
        end
        target = best
    end
    if target and target.plot then
        local pl = Workspace:FindFirstChild("Plots") and Workspace.Plots:FindFirstChild(target.plot)
        if pl then
            local pos = pl:GetPivot().Position + Vector3.new(0, 5, 0)
            pcall(function()
                fireGrappleTP(pos)
                task.wait(0.1)
                -- secondary teleport inside
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = CFrame.new(pos) end
            end)
        end
    end
end)

-- // FPS UNCAP
if setfpscap then
    pcall(setfpscap, 999)
end

-- // ONE-WAY PLATFORMS (toggleable)
local function makeOneWay(part)
    if not part or not part:IsA("BasePart") then return end
    part.CanCollide = true
    local conn
    conn = RunService.Stepped:Connect(function()
        if not state.oneWay or not part.Parent then
            conn:Disconnect()
            return
        end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if hrp.AssemblyLinearVelocity.Y > 0.5 then
            part.CanCollide = false
        elseif hrp.Position.Y - hrp.Size.Y/2 >= part.Position.Y + part.Size.Y/2 - 0.5 then
            part.CanCollide = true
        else
            part.CanCollide = false
        end
    end)
    table.insert(state.conns, conn)
end

-- // GUI
local guiParent = LocalPlayer:FindFirstChild("PlayerGui") or Instance.new("ScreenGui")
guiParent.Parent = LocalPlayer
local screen = Instance.new("ScreenGui")
screen.Name = "AK2Brainrot"
screen.Parent = guiParent
screen.ResetOnSpawn = false

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 420)
main.Position = UDim2.new(0.5, -160, 0.5, -210)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 1
main.BorderColor3 = Color3.fromRGB(60, 80, 150)
main.Active = true
main.Draggable = true
main.Parent = screen
local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0, 12)
mc.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(20, 25, 50)
header.BackgroundTransparency = 0.4
header.BorderSizePixel = 0
header.Parent = main
local hc = Instance.new("UICorner")
hc.CornerRadius = UDim.new(0, 12)
hc.Parent = header

local brand = Instance.new("TextLabel")
brand.Size = UDim2.new(0.7, 0, 1, 0)
brand.Position = UDim2.new(0, 12, 0, 0)
brand.BackgroundTransparency = 1
brand.Text = "AK2 | Brainrot"
brand.TextColor3 = Color3.fromRGB(100, 200, 255)
brand.TextSize = 18
brand.Font = Enum.Font.GothamBold
brand.TextXAlignment = Enum.TextXAlignment.Left
brand.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -36, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(60, 40, 45)
close.BackgroundTransparency = 0.4
close.Text = "✕"
close.TextColor3 = Color3.fromRGB(200, 80, 80)
close.TextSize = 16
close.Font = Enum.Font.GothamBold
close.Parent = header
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 8)
cc.Parent = close
close.MouseButton1Click:Connect(function()
    screen:Destroy()
    for _, conn in pairs(state.conns) do pcall(conn.Disconnect, conn) end
end)

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -10, 1, -50)
content.Position = UDim2.new(0, 5, 0, 42)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 2
content.ScrollBarImageColor3 = Color3.fromRGB(30, 30, 60)
content.Parent = main
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

local function makeToggle(text, getter, setter)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 32)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    f.BackgroundTransparency = 0.5
    f.BorderSizePixel = 0
    f.Parent = content
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 6)
    fc.Parent = f

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.6, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(210, 210, 235)
    l.TextSize = 12
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 44, 0, 22)
    b.Position = UDim2.new(1, -50, 0.5, -11)
    b.BackgroundColor3 = getter() and Color3.fromRGB(70, 190, 110) or Color3.fromRGB(45, 45, 65)
    b.Text = getter() and "ON" or "OFF"
    b.TextColor3 = Color3.fromRGB(240, 240, 255)
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.Parent = f
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 10)
    bc.Parent = b

    b.MouseButton1Click:Connect(function()
        local n = not getter()
        setter(n)
        b.BackgroundColor3 = n and Color3.fromRGB(70, 190, 110) or Color3.fromRGB(45, 45, 65)
        b.Text = n and "ON" or "OFF"
    end)
    return b
end

-- build GUI options
makeToggle("Auto Steal", function() return state.autoSteal end, function(v) state.autoSteal = v end)
makeToggle("Grapple TP", function() return state.grappleTP end, function(v) 
    state.grappleTP = v
    if v then
        -- bind to click
    end
end)
makeToggle("One-Way Platforms", function() return state.oneWay end, function(v)
    state.oneWay = v
    -- apply to all platforms
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Name:lower():find("platform") then
            makeOneWay(part)
        end
    end
end)
makeToggle("ESP", function() return state.esp end, function(v)
    state.esp = v
    -- simple box ESP
    if v then
        local conn = RunService.RenderStepped:Connect(function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr == LocalPlayer then continue end
                local c = plr.Character
                if not c then continue end
                local root = c:FindFirstChild("HumanoidRootPart")
                if not root then continue end
                local pos, on = workspace.CurrentCamera:WorldToScreenPoint(root.Position)
                if not on then continue end
                local box = state.espBoxes[plr]
                if not box then
                    box = Instance.new("Frame")
                    box.BackgroundTransparency = 0.8
                    box.BorderSizePixel = 1.5
                    box.BorderColor3 = Color3.fromRGB(0, 255, 100)
                    box.Parent = screen
                    state.espBoxes[plr] = box
                end
                local size = 40 / (pos.Z / 10)
                box.Size = UDim2.new(0, size, 0, size * 2)
                box.Position = UDim2.new(0, pos.X - size/2, 0, pos.Y - size)
            end
            for plr, box in pairs(state.espBoxes) do
                if not plr.Character then
                    box:Destroy()
                    state.espBoxes[plr] = nil
                end
            end
        end)
        table.insert(state.conns, conn)
    else
        for _, b in pairs(state.espBoxes) do b:Destroy() end
        state.espBoxes = {}
    end
end)

-- // HOTKEY
UserInputService.InputBegan:Connect(function(input, proc)
    if proc then return end
    if input.KeyCode == Enum.KeyCode.F1 then
        main.Visible = not main.Visible
    end
end)

-- // CLEANUP
screen.AncestryChanged:Connect(function()
    if not screen.Parent then
        for _, conn in pairs(state.conns) do pcall(conn.Disconnect, conn) end
    end
end)

print("★ AK2 Brainrot loaded ★ @ak2.v")
print("F1 = toggle GUI")
