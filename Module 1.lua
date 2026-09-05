-- ============================================================
--  AK2 | Steal a Brainrot - Script Complet
--  GUI Animée | Auto Steal | Grapple TP | Face Away | Anti-Kick
--  Net Bypass | Auto Farm | Config Save
--  TikTok: @ak2.v
-- ============================================================

if _G.__AK2SAB_ACTIVE then return end
_G.__AK2SAB_ACTIVE = true

-- ── Services ─────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local Workspace        = game:GetService("Workspace")

local LP    = Players.LocalPlayer
local Cam   = Workspace.CurrentCamera

-- ── Config par défaut ─────────────────────────────────────────
local Config = {
    AutoSteal       = false,
    GrappleTP       = true,
    FaceAway        = false,
    FaceAwayModo    = "baseowner",
    AntiFlasher     = false,
    AntiCollision   = false,
    AutoFarm        = false,
    TPSpeed         = 400,
    CloneDelay      = 0.05,
    StealDelay      = 0.1,
    MaxStealDist    = 50,
    NotifEnabled    = true,
    Theme           = "Green",
}

-- ── Save/Load config ──────────────────────────────────────────
local CONFIG_FILE = "ak2sab_config.json"
local function SaveConfig()
    if not writefile then return end
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end)
end
local function LoadConfig()
    if not readfile or not isfile then return end
    pcall(function()
        if isfile(CONFIG_FILE) then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(readfile(CONFIG_FILE))
            end)
            if ok and type(data) == "table" then
                for k, v in pairs(data) do
                    if Config[k] ~= nil then Config[k] = v end
                end
            end
        end
    end)
end
LoadConfig()

-- ── Thèmes ────────────────────────────────────────────────────
local Themes = {
    Green = {
        Accent      = Color3.fromRGB(0, 255, 100),
        AccentDim   = Color3.fromRGB(0, 180, 70),
        AccentDark  = Color3.fromRGB(0, 80, 35),
        BG          = Color3.fromRGB(10, 12, 14),
        Panel       = Color3.fromRGB(16, 19, 22),
        Row         = Color3.fromRGB(22, 26, 30),
        RowHover    = Color3.fromRGB(28, 33, 38),
        Text        = Color3.fromRGB(230, 235, 240),
        Dim         = Color3.fromRGB(110, 120, 130),
        Stroke      = Color3.fromRGB(38, 44, 50),
        ToggleOn    = Color3.fromRGB(0, 255, 100),
        ToggleOff   = Color3.fromRGB(35, 40, 46),
        Red         = Color3.fromRGB(255, 65, 65),
        Green       = Color3.fromRGB(0, 255, 100),
        Blue        = Color3.fromRGB(60, 140, 255),
        Gold        = Color3.fromRGB(255, 200, 50),
    },
    Purple = {
        Accent      = Color3.fromRGB(160, 80, 255),
        AccentDim   = Color3.fromRGB(120, 50, 200),
        AccentDark  = Color3.fromRGB(50, 20, 80),
        BG          = Color3.fromRGB(10, 10, 16),
        Panel       = Color3.fromRGB(16, 15, 24),
        Row         = Color3.fromRGB(22, 20, 32),
        RowHover    = Color3.fromRGB(30, 27, 44),
        Text        = Color3.fromRGB(230, 225, 245),
        Dim         = Color3.fromRGB(110, 105, 130),
        Stroke      = Color3.fromRGB(40, 36, 56),
        ToggleOn    = Color3.fromRGB(160, 80, 255),
        ToggleOff   = Color3.fromRGB(35, 33, 46),
        Red         = Color3.fromRGB(255, 65, 65),
        Green       = Color3.fromRGB(0, 220, 100),
        Blue        = Color3.fromRGB(60, 140, 255),
        Gold        = Color3.fromRGB(255, 200, 50),
    },
}
local T = Themes[Config.Theme] or Themes.Green

-- ── Utilitaires GUI ───────────────────────────────────────────
local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
    return c
end
local function stroke(obj, color, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color = color or T.Stroke
    s.Thickness = thick or 1
    s.Transparency = trans or 0.2
    s.Parent = obj
    return s
end
local function tween(obj, props, t, style, dir)
    local info = TweenInfo.new(t or 0.2,
        style or Enum.EasingStyle.Quart,
        dir or Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end
local function shadow(parent)
    local sh = Instance.new("ImageLabel")
    sh.Name = "Shadow"
    sh.AnchorPoint = Vector2.new(0.5, 0.5)
    sh.BackgroundTransparency = 1
    sh.Position = UDim2.new(0.5, 0, 0.5, 4)
    sh.Size = UDim2.new(1, 24, 1, 24)
    sh.ZIndex = parent.ZIndex - 1
    sh.Image = "rbxassetid://6014261993"
    sh.ImageColor3 = Color3.new(0, 0, 0)
    sh.ImageTransparency = 0.5
    sh.ScaleType = Enum.ScaleType.Slice
    sh.SliceCenter = Rect.new(49, 49, 450, 450)
    sh.Parent = parent
    return sh
end
local function notify(title, msg, dur)
    if not Config.NotifEnabled then return end
    task.spawn(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "AK2Notif"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.Parent = CoreGui

        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 260, 0, 64)
        notif.Position = UDim2.new(1, 10, 1, -80)
        notif.AnchorPoint = Vector2.new(1, 1)
        notif.BackgroundColor3 = T.Panel
        notif.BorderSizePixel = 0
        notif.Parent = sg
        corner(notif, 10)
        stroke(notif, T.Accent, 1, 0.3)
        shadow(notif)

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 1, -16)
        bar.Position = UDim2.new(0, 8, 0, 8)
        bar.BackgroundColor3 = T.Accent
        bar.BorderSizePixel = 0
        bar.Parent = notif
        corner(bar, 2)

        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, -20, 0, 22)
        tl.Position = UDim2.new(0, 18, 0, 8)
        tl.BackgroundTransparency = 1
        tl.Text = title
        tl.TextColor3 = T.Text
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 13
        tl.TextXAlignment = Enum.TextXAlignment.Left
        tl.Parent = notif

        local ml = Instance.new("TextLabel")
        ml.Size = UDim2.new(1, -20, 0, 18)
        ml.Position = UDim2.new(0, 18, 0, 30)
        ml.BackgroundTransparency = 1
        ml.Text = msg
        ml.TextColor3 = T.Dim
        ml.Font = Enum.Font.Gotham
        ml.TextSize = 11
        ml.TextXAlignment = Enum.TextXAlignment.Left
        ml.Parent = notif

        -- Slide in
        tween(notif, {Position = UDim2.new(1, -10, 1, -80)}, 0.4,
            Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        task.wait(dur or 3)
        tween(notif, {Position = UDim2.new(1, 10, 1, -80)}, 0.3)
        task.wait(0.35)
        sg:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  SPLASH SCREEN (animation d'ouverture)
-- ═══════════════════════════════════════════════════════════════
local function ShowSplash(onDone)
    local sg = Instance.new("ScreenGui")
    sg.Name = "AK2Splash"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 99999
    sg.Parent = CoreGui

    -- Fond noir full screen
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.new(0, 0, 0)
    bg.BackgroundTransparency = 0
    bg.BorderSizePixel = 0
    bg.ZIndex = 1
    bg.Parent = sg

    -- Conteneur centré
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 320, 0, 180)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.BackgroundTransparency = 1
    container.ZIndex = 2
    container.Parent = sg

    -- Logo AK2
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(1, 0, 0, 80)
    logo.Position = UDim2.new(0, 0, 0, 20)
    logo.BackgroundTransparency = 1
    logo.Text = "AK2"
    logo.TextColor3 = T.Accent
    logo.Font = Enum.Font.GothamBlack
    logo.TextSize = 72
    logo.TextTransparency = 1
    logo.ZIndex = 3
    logo.Parent = container

    -- Sous-titre
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 24)
    sub.Position = UDim2.new(0, 0, 0, 100)
    sub.BackgroundTransparency = 1
    sub.Text = "Steal a Brainrot"
    sub.TextColor3 = T.Dim
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 16
    sub.TextTransparency = 1
    sub.ZIndex = 3
    sub.Parent = container

    -- Barre de chargement background
    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(0, 240, 0, 3)
    barBG.AnchorPoint = Vector2.new(0.5, 0)
    barBG.Position = UDim2.new(0.5, 0, 0, 140)
    barBG.BackgroundColor3 = T.Stroke
    barBG.BorderSizePixel = 0
    barBG.ZIndex = 3
    barBG.Parent = container
    corner(barBG, 2)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = T.Accent
    barFill.BorderSizePixel = 0
    barFill.ZIndex = 4
    barFill.Parent = barBG
    corner(barFill, 2)

    -- Status text
    local statusTxt = Instance.new("TextLabel")
    statusTxt.Size = UDim2.new(0, 240, 0, 18)
    statusTxt.AnchorPoint = Vector2.new(0.5, 0)
    statusTxt.Position = UDim2.new(0.5, 0, 0, 150)
    statusTxt.BackgroundTransparency = 1
    statusTxt.Text = "Chargement..."
    statusTxt.TextColor3 = T.Dim
    statusTxt.Font = Enum.Font.Gotham
    statusTxt.TextSize = 11
    statusTxt.TextTransparency = 1
    statusTxt.ZIndex = 3
    statusTxt.Parent = container

    -- Animation
    task.spawn(function()
        task.wait(0.1)
        -- Fade in logo
        tween(logo, {TextTransparency = 0}, 0.6, Enum.EasingStyle.Quart)
        task.wait(0.3)
        tween(sub, {TextTransparency = 0}, 0.4)
        tween(statusTxt, {TextTransparency = 0}, 0.4)
        task.wait(0.4)

        local steps = {
            {txt = "Connexion aux services...", p = 0.2},
            {txt = "Net bypass...",             p = 0.45},
            {txt = "Chargement GUI...",         p = 0.7},
            {txt = "Initialisation modules...", p = 0.9},
            {txt = "Prêt !",                    p = 1.0},
        }
        for _, step in ipairs(steps) do
            statusTxt.Text = step.txt
            tween(barFill, {Size = UDim2.new(step.p, 0, 1, 0)}, 0.35,
                Enum.EasingStyle.Quart)
            task.wait(0.38)
        end
        task.wait(0.2)

        -- Fade out tout
        tween(logo,      {TextTransparency = 1}, 0.35)
        tween(sub,       {TextTransparency = 1}, 0.35)
        tween(statusTxt, {TextTransparency = 1}, 0.35)
        tween(barBG,     {BackgroundTransparency = 1}, 0.35)
        tween(barFill,   {BackgroundTransparency = 1}, 0.35)
        task.wait(0.3)
        tween(bg, {BackgroundTransparency = 1}, 0.4)
        task.wait(0.45)
        sg:Destroy()
        if onDone then onDone() end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  GUI PRINCIPALE
-- ═══════════════════════════════════════════════════════════════
local function BuildGUI()
    -- Cleanup ancienne instance
    local old = CoreGui:FindFirstChild("AK2SAB")
    if old then old:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AK2SAB"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 9999
    ScreenGui.Parent = CoreGui

    -- ── Fenêtre principale ───────────────────────────────────
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 420, 0, 500)
    Main.Position = UDim2.new(0.5, -210, 0.5, -250)
    Main.BackgroundColor3 = T.BG
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = false
    Main.Parent = ScreenGui
    corner(Main, 12)
    stroke(Main, T.Stroke, 1, 0.1)
    shadow(Main)

    -- Animation d'apparition
    Main.Size = UDim2.new(0, 420, 0, 0)
    Main.BackgroundTransparency = 1
    task.spawn(function()
        task.wait(0.05)
        tween(Main, {
            Size = UDim2.new(0, 420, 0, 500),
            BackgroundTransparency = 0
        }, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    -- ── Draggable ────────────────────────────────────────────
    local dragging, dragInput, dragStart, startPos
    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    Main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local d = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)

    -- ── Header ───────────────────────────────────────────────
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 52)
    Header.BackgroundColor3 = T.Panel
    Header.BorderSizePixel = 0
    Header.Parent = Main
    corner(Header, 12)
    -- Cache coins bas du header
    local hBot = Instance.new("Frame")
    hBot.Size = UDim2.new(1, 0, 0, 12)
    hBot.Position = UDim2.new(0, 0, 1, -12)
    hBot.BackgroundColor3 = T.Panel
    hBot.BorderSizePixel = 0
    hBot.Parent = Header

    -- Gradient line top
    local gradLine = Instance.new("Frame")
    gradLine.Size = UDim2.new(1, 0, 0, 2)
    gradLine.BackgroundColor3 = T.Accent
    gradLine.BorderSizePixel = 0
    gradLine.ZIndex = 2
    gradLine.Parent = Header
    corner(gradLine, 1)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, T.Accent),
        ColorSequenceKeypoint.new(0.5, T.AccentDim),
        ColorSequenceKeypoint.new(1, T.Accent),
    })
    grad.Parent = gradLine

    -- Titre
    local TitleAK2 = Instance.new("TextLabel")
    TitleAK2.Size = UDim2.new(0, 50, 1, 0)
    TitleAK2.Position = UDim2.new(0, 14, 0, 0)
    TitleAK2.BackgroundTransparency = 1
    TitleAK2.Text = "AK2"
    TitleAK2.TextColor3 = T.Accent
    TitleAK2.Font = Enum.Font.GothamBlack
    TitleAK2.TextSize = 22
    TitleAK2.TextXAlignment = Enum.TextXAlignment.Left
    TitleAK2.Parent = Header

    local TitleSub = Instance.new("TextLabel")
    TitleSub.Size = UDim2.new(0, 150, 1, 0)
    TitleSub.Position = UDim2.new(0, 64, 0, 0)
    TitleSub.BackgroundTransparency = 1
    TitleSub.Text = "Steal a Brainrot"
    TitleSub.TextColor3 = T.Dim
    TitleSub.Font = Enum.Font.GothamMedium
    TitleSub.TextSize = 13
    TitleSub.TextXAlignment = Enum.TextXAlignment.Left
    TitleSub.Parent = Header

    -- Version badge
    local verBadge = Instance.new("Frame")
    verBadge.Size = UDim2.new(0, 46, 0, 18)
    verBadge.AnchorPoint = Vector2.new(0, 0.5)
    verBadge.Position = UDim2.new(0, 218, 0.5, 0)
    verBadge.BackgroundColor3 = T.AccentDark
    verBadge.BorderSizePixel = 0
    verBadge.Parent = Header
    corner(verBadge, 5)
    local verTxt = Instance.new("TextLabel")
    verTxt.Size = UDim2.new(1, 0, 1, 0)
    verTxt.BackgroundTransparency = 1
    verTxt.Text = "v2.0"
    verTxt.TextColor3 = T.Accent
    verTxt.Font = Enum.Font.GothamBold
    verTxt.TextSize = 11
    verTxt.Parent = verBadge

    -- Boutons header
    local function makeHeaderBtn(icon, xOffset, color, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 28, 0, 28)
        btn.Position = UDim2.new(1, xOffset, 0.5, -14)
        btn.BackgroundColor3 = T.Row
        btn.Text = icon
        btn.TextColor3 = color or T.Dim
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Parent = Header
        corner(btn, 7)
        btn.MouseEnter:Connect(function()
            tween(btn, {BackgroundColor3 = T.RowHover}, 0.12)
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, {BackgroundColor3 = T.Row}, 0.12)
        end)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    local minimized = false
    local ContentHolder -- déclaré plus bas

    makeHeaderBtn("✕", -8, T.Red, function()
        tween(Main, {Size = UDim2.new(0, 420, 0, 0), BackgroundTransparency = 1}, 0.3,
            Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.35)
        ScreenGui:Destroy()
    end)
    makeHeaderBtn("–", -42, T.Dim, function()
        minimized = not minimized
        if ContentHolder then
            if minimized then
                tween(Main, {Size = UDim2.new(0, 420, 0, 52)}, 0.3, Enum.EasingStyle.Quart)
                ContentHolder.Visible = false
            else
                ContentHolder.Visible = true
                tween(Main, {Size = UDim2.new(0, 420, 0, 500)}, 0.35,
                    Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end
        end
    end)

    -- Toggle visibilité (touche RightAlt)
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightAlt then
            Main.Visible = not Main.Visible
        end
    end)

    -- ── Content holder ───────────────────────────────────────
    ContentHolder = Instance.new("Frame")
    ContentHolder.Size = UDim2.new(1, 0, 1, -52)
    ContentHolder.Position = UDim2.new(0, 0, 0, 52)
    ContentHolder.BackgroundTransparency = 1
    ContentHolder.BorderSizePixel = 0
    ContentHolder.ClipsDescendants = true
    ContentHolder.Parent = Main

    -- ── Tab bar ──────────────────────────────────────────────
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, -20, 0, 34)
    TabBar.Position = UDim2.new(0, 10, 0, 8)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = ContentHolder

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.Parent = TabBar

    -- ── Pages container ──────────────────────────────────────
    local PagesHolder = Instance.new("Frame")
    PagesHolder.Size = UDim2.new(1, 0, 1, -50)
    PagesHolder.Position = UDim2.new(0, 0, 0, 50)
    PagesHolder.BackgroundTransparency = 1
    PagesHolder.BorderSizePixel = 0
    PagesHolder.Parent = ContentHolder

    -- Pages et tabs
    local Pages   = {}
    local TabBtns = {}
    local ActiveTab = nil

    local function MakePage(name)
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = T.Accent
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = PagesHolder

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft   = UDim.new(0, 10)
        pad.PaddingRight  = UDim.new(0, 10)
        pad.PaddingTop    = UDim.new(0, 6)
        pad.Parent = page

        Pages[name] = page
        return page
    end

    local function SwitchTab(name)
        for n, page in pairs(Pages) do
            if n == name then
                page.Visible = true
                tween(page, {}, 0) -- force refresh
            else
                page.Visible = false
            end
        end
        for n, btn in pairs(TabBtns) do
            if n == name then
                tween(btn, {BackgroundColor3 = T.Accent}, 0.2)
                btn.TextColor3 = T.BG
            else
                tween(btn, {BackgroundColor3 = T.Row}, 0.2)
                btn.TextColor3 = T.Dim
            end
        end
        ActiveTab = name
    end

    local function MakeTab(name, icon)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 0, 1, 0)
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.BackgroundColor3 = T.Row
        btn.Text = (icon and icon .. "  " or "") .. name
        btn.TextColor3 = T.Dim
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Parent = TabBar
        corner(btn, 7)

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft  = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.Parent = btn

        TabBtns[name] = btn
        MakePage(name)

        btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
        btn.MouseEnter:Connect(function()
            if ActiveTab ~= name then
                tween(btn, {BackgroundColor3 = T.RowHover}, 0.15)
            end
        end)
        btn.MouseLeave:Connect(function()
            if ActiveTab ~= name then
                tween(btn, {BackgroundColor3 = T.Row}, 0.15)
            end
        end)
        return btn
    end

    -- Création des tabs
    MakeTab("Steal",   "🎯")
    MakeTab("ESP",     "👁")
    MakeTab("Extras",  "⚡")
    MakeTab("Socials", "🔗")
    MakeTab("Config",  "⚙")
    SwitchTab("Steal")

    -- ── Composants réutilisables ──────────────────────────────
    local function Section(parent, text, order)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 26)
        f.BackgroundTransparency = 1
        f.LayoutOrder = order or 0
        f.Parent = parent

        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Position = UDim2.new(0, 0, 0.5, 0)
        line.BackgroundColor3 = T.Stroke
        line.BorderSizePixel = 0
        line.Parent = f

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 0, 1, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.Position = UDim2.new(0, 0, 0, 0)
        lbl.BackgroundColor3 = T.BG
        lbl.BorderSizePixel = 0
        lbl.Text = "  " .. text .. "  "
        lbl.TextColor3 = T.Accent
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.Parent = f
        return f
    end

    local function Toggle(parent, label, desc, configKey, order, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, desc and 50 or 40)
        row.BackgroundColor3 = T.Row
        row.BorderSizePixel = 0
        row.LayoutOrder = order or 0
        row.Parent = parent
        corner(row, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 0, 18)
        lbl.Position = UDim2.new(0, 12, 0, desc and 8 or 11)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = T.Text
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        if desc then
            local dlbl = Instance.new("TextLabel")
            dlbl.Size = UDim2.new(1, -60, 0, 14)
            dlbl.Position = UDim2.new(0, 12, 0, 28)
            dlbl.BackgroundTransparency = 1
            dlbl.Text = desc
            dlbl.TextColor3 = T.Dim
            dlbl.Font = Enum.Font.Gotham
            dlbl.TextSize = 11
            dlbl.TextXAlignment = Enum.TextXAlignment.Left
            dlbl.Parent = row
        end

        local on = Config[configKey]
        local tbg = Instance.new("Frame")
        tbg.Size = UDim2.new(0, 44, 0, 24)
        tbg.AnchorPoint = Vector2.new(1, 0.5)
        tbg.Position = UDim2.new(1, -12, 0.5, 0)
        tbg.BackgroundColor3 = on and T.ToggleOn or T.ToggleOff
        tbg.BorderSizePixel = 0
        tbg.Parent = row
        corner(tbg, 12)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = on and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.Parent = tbg
        corner(knob, 10)

        local function UpdateVisual()
            local v = Config[configKey]
            tween(tbg,  {BackgroundColor3 = v and T.ToggleOn or T.ToggleOff}, 0.15)
            tween(knob, {Position = v
                and UDim2.new(1, -22, 0.5, -10)
                or  UDim2.new(0, 2,   0.5, -10)}, 0.15)
        end

        tbg.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                Config[configKey] = not Config[configKey]
                UpdateVisual()
                if callback then callback(Config[configKey]) end
                SaveConfig()
            end
        end)
        row.MouseEnter:Connect(function()
            tween(row, {BackgroundColor3 = T.RowHover}, 0.12)
        end)
        row.MouseLeave:Connect(function()
            tween(row, {BackgroundColor3 = T.Row}, 0.12)
        end)
        return row, UpdateVisual
    end

    local function Slider(parent, label, configKey, minV, maxV, order, fmt, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 54)
        row.BackgroundColor3 = T.Row
        row.BorderSizePixel = 0
        row.LayoutOrder = order or 0
        row.Parent = parent
        corner(row, 8)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 200, 0, 18)
        lbl.Position = UDim2.new(0, 12, 0, 8)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = T.Text
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0, 80, 0, 18)
        valLbl.AnchorPoint = Vector2.new(1, 0)
        valLbl.Position = UDim2.new(1, -12, 0, 8)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = (fmt or "%d"):format(Config[configKey])
        valLbl.TextColor3 = T.Accent
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 13
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = row

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -24, 0, 4)
        track.Position = UDim2.new(0, 12, 0, 36)
        track.BackgroundColor3 = T.Stroke
        track.BorderSizePixel = 0
        track.Parent = row
        corner(track, 2)

        local ratio = math.clamp((Config[configKey] - minV) / (maxV - minV), 0, 1)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        fill.BackgroundColor3 = T.Accent
        fill.BorderSizePixel = 0
        fill.Parent = track
        corner(fill, 2)

        local handle = Instance.new("Frame")
        handle.Size = UDim2.new(0, 14, 0, 14)
        handle.AnchorPoint = Vector2.new(0.5, 0.5)
        handle.Position = UDim2.new(ratio, 0, 0.5, 0)
        handle.BackgroundColor3 = Color3.new(1,1,1)
        handle.BorderSizePixel = 0
        handle.Parent = track
        corner(handle, 7)

        local sliding = false
        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = true
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = false
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
                local abs = track.AbsolutePosition
                local sz  = track.AbsoluteSize
                local r = math.clamp((i.Position.X - abs.X) / sz.X, 0, 1)
                local val = minV + r * (maxV - minV)
                if (maxV - minV) > 5 then val = math.floor(val) end
                Config[configKey] = val
                fill.Size = UDim2.new(r, 0, 1, 0)
                handle.Position = UDim2.new(r, 0, 0.5, 0)
                valLbl.Text = (fmt or "%d"):format(val)
                if callback then callback(val) end
                SaveConfig()
            end
        end)
        return row
    end

    local function Button(parent, label, desc, color, order, onClick)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 42)
        row.BackgroundColor3 = T.Row
        row.BorderSizePixel = 0
        row.LayoutOrder = order or 0
        row.Parent = parent
        corner(row, 8)

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 1, -16)
        bar.Position = UDim2.new(0, 0, 0, 8)
        bar.BackgroundColor3 = color or T.Accent
        bar.BorderSizePixel = 0
        bar.Parent = row
        corner(bar, 2)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -70, 0, 18)
        lbl.Position = UDim2.new(0, 14, 0, desc and 5 or 12)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = T.Text
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        if desc then
            local dl = Instance.new("TextLabel")
            dl.Size = UDim2.new(1, -70, 0, 14)
            dl.Position = UDim2.new(0, 14, 0, 24)
            dl.BackgroundTransparency = 1
            dl.Text = desc
            dl.TextColor3 = T.Dim
            dl.Font = Enum.Font.Gotham
            dl.TextSize = 11
            dl.TextXAlignment = Enum.TextXAlignment.Left
            dl.Parent = row
        end

        local arrow = Instance.new("TextLabel")
        arrow.Size = UDim2.new(0, 30, 1, 0)
        arrow.AnchorPoint = Vector2.new(1, 0.5)
        arrow.Position = UDim2.new(1, -8, 0.5, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "▶"
        arrow.TextColor3 = color or T.Accent
        arrow.TextSize = 12
        arrow.Font = Enum.Font.GothamBold
        arrow.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = row

        btn.MouseEnter:Connect(function()
            tween(row, {BackgroundColor3 = T.RowHover}, 0.12)
        end)
        btn.MouseLeave:Connect(function()
            tween(row, {BackgroundColor3 = T.Row}, 0.12)
        end)
        btn.MouseButton1Click:Connect(function()
            tween(row, {BackgroundColor3 = color or T.AccentDark}, 0.1)
            task.delay(0.1, function()
                tween(row, {BackgroundColor3 = T.Row}, 0.15)
            end)
            if onClick then onClick() end
        end)
        return row
    end

    -- ── STATUS BAR ────────────────────────────────────────────
    local StatusBar = Instance.new("Frame")
    StatusBar.Size = UDim2.new(1, -20, 0, 26)
    StatusBar.AnchorPoint = Vector2.new(0.5, 1)
    StatusBar.Position = UDim2.new(0.5, 0, 1, -6)
    StatusBar.BackgroundColor3 = T.Panel
    StatusBar.BorderSizePixel = 0
    StatusBar.Parent = ContentHolder
    corner(StatusBar, 7)

    local StatusDot = Instance.new("Frame")
    StatusDot.Size = UDim2.new(0, 7, 0, 7)
    StatusDot.AnchorPoint = Vector2.new(0, 0.5)
    StatusDot.Position = UDim2.new(0, 10, 0.5, 0)
    StatusDot.BackgroundColor3 = T.Accent
    StatusDot.BorderSizePixel = 0
    StatusDot.Parent = StatusBar
    corner(StatusDot, 4)

    local StatusTxt = Instance.new("TextLabel")
    StatusTxt.Size = UDim2.new(1, -80, 1, 0)
    StatusTxt.Position = UDim2.new(0, 24, 0, 0)
    StatusTxt.BackgroundTransparency = 1
    StatusTxt.Text = "AK2 prêt  •  @ak2.v"
    StatusTxt.TextColor3 = T.Dim
    StatusTxt.Font = Enum.Font.Gotham
    StatusTxt.TextSize = 11
    StatusTxt.TextXAlignment = Enum.TextXAlignment.Left
    StatusTxt.Parent = StatusBar

    local function SetStatus(msg, color)
        StatusTxt.Text = msg
        tween(StatusDot, {BackgroundColor3 = color or T.Accent}, 0.2)
    end

    -- Ajuster PagesHolder pour la status bar
    PagesHolder.Size = UDim2.new(1, 0, 1, -86)

    -- ═══════════════════════════════════════════════════════════
    --  PAGE : STEAL
    -- ═══════════════════════════════════════════════════════════
    local pSteal = Pages["Steal"]
    Section(pSteal, "AUTO STEAL", 1)

    local stealLoop = false
    local stealConn = nil

    -- ── Net bypass & remote finder ────────────────────────────
    local NetFolder = nil
    local F1, F2, secret = nil, nil, nil

    local function isGuid(s)
        return type(s) == "string" and #s == 36
            and s:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
    end

    local function buildNet()
        if F1 and secret then return true end
        local ok, nf = pcall(function()
            return ReplicatedStorage:WaitForChild("Packages", 10)
                :WaitForChild("Net", 10)
        end)
        if not ok or not nf then return false end
        NetFolder = nf

        local getupvalues = debug and (debug.getupvalues or debug.getupvalue) or nil
        if not getupvalues or not getgc then return false end

        local jobId = game.JobId
        local a, b, cands = nil, nil, {}
        local seen = {}

        task.wait()
        for _, v in getgc(true) do
            if typeof(v) == "function" then
                local oki, info = pcall(debug.getinfo, v)
                if oki and info and info.source then
                    local src = info.source
                    if src:find("Net", 1, true) and src:find("ReplicatedStorage", 1, true) then
                        local ok2, ups = pcall(getupvalues, v)
                        if ok2 and ups then
                            for _, up in pairs(ups) do
                                if type(up) == "table" then
                                    local x = rawget(up, 1)
                                    local y = rawget(up, 2)
                                    local z = rawget(up, 3)
                                    if not a and type(x) == "function" and type(y) == "function" then
                                        a, b = x, y
                                    end
                                    for _, e in pairs(up) do
                                        if isGuid(e) and e ~= jobId and not seen[e] then
                                            seen[e] = true
                                            cands[#cands+1] = e
                                        end
                                    end
                                elseif isGuid(up) and up ~= jobId and not seen[up] then
                                    seen[up] = true
                                    cands[#cands+1] = up
                                end
                            end
                        end
                    end
                end
            end
        end
        if not a then return false end
        F1, F2 = a, b

        local bufFromStr = buffer.fromstring or function(s)
            local buf = buffer.create(#s)
            buffer.writestring(buf, 0, s)
            return buf
        end

        if #cands == 1 then
            secret = cands[1]
            return true
        end
        for _, sec in ipairs(cands) do
            local okh, cipher = pcall(function() return F2("UseItem", jobId) end)
            if okh then
                local okr, h = pcall(function()
                    return F1(bufFromStr(cipher), bufFromStr(sec .. jobId))
                end)
                if okr and type(h) == "string" and NetFolder:FindFirstChild("RE/" .. h) then
                    secret = sec
                    return true
                end
            end
        end
        return false
    end

    local function resolveRemote(name)
        if not NetFolder then return nil end
        local direct = NetFolder:FindFirstChild("RE/" .. name)
            or NetFolder:FindFirstChild("RF/" .. name)
        if direct then return direct end
        if not F1 or not secret then return nil end
        local jobId = game.JobId
        local bufFromStr = buffer.fromstring or function(s)
            local buf = buffer.create(#s)
            buffer.writestring(buf, 0, s)
            return buf
        end
        local ok, cipher = pcall(function() return F2(name, jobId) end)
        if not ok then return nil end
        local okh, h = pcall(function()
            return F1(bufFromStr(cipher), bufFromStr(secret .. jobId))
        end)
        if not okh or type(h) ~= "string" then return nil end
        for _, pfx in ipairs({"RE","RF","URE"}) do
            local r = NetFolder:FindFirstChild(pfx .. "/" .. h)
            if r then return r end
        end
        return nil
    end

    local function fireRemote(name, ...)
        local r = resolveRemote(name)
        if not r then return false end
        local args = {...}
        if r:IsA("RemoteFunction") then
            return pcall(function() return r:InvokeServer(table.unpack(args)) end)
        else
            return pcall(function() r:FireServer(table.unpack(args)) end)
        end
    end

    -- ── Scanner de pets ───────────────────────────────────────
    local function scanPets()
        local results = {}
        local plots = Workspace:FindFirstChild("Plots")
        if not plots then return results end

        for _, plot in ipairs(plots:GetChildren()) do
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if podiums then
                for _, pod in ipairs(podiums:GetChildren()) do
                    local prompt = pod:FindFirstChildOfClass("ProximityPrompt")
                        or pod:FindFirstChild("Steal", true)
                    local part = pod:IsA("BasePart") and pod
                        or pod:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local owner = plot.Name
                        local isOurs = (owner == LP.Name or owner == LP.DisplayName)
                        if not isOurs then
                            results[#results+1] = {
                                part   = part,
                                prompt = prompt,
                                plot   = plot.Name,
                                pos    = part.Position,
                            }
                        end
                    end
                end
            end
        end
        table.sort(results, function(a, b)
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return false end
            return (a.pos - hrp.Position).Magnitude < (b.pos - hrp.Position).Magnitude
        end)
        return results
    end

    -- ── Grapple TP ───────────────────────────────────────────
    local function doGrappleTP(targetPos)
        local char = LP.Character
        if not char then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return false end

        -- Cherche le grapple hook
        local tool = char:FindFirstChild("Grapple Hook")
        if not tool then
            local bp = LP:FindFirstChildOfClass("Backpack")
            tool = bp and bp:FindFirstChild("Grapple Hook")
            if tool and hum then
                pcall(function() hum:EquipTool(tool) end)
                task.wait(0.1)
                char = LP.Character
                tool = char and char:FindFirstChild("Grapple Hook")
                hrp  = char and char:FindFirstChild("HumanoidRootPart")
            end
        end

        -- TP velocity-based si pas de grapple
        if not tool then
            local dir = (targetPos - hrp.Position).Unit
            hrp.AssemblyLinearVelocity = dir * Config.TPSpeed
            task.wait(0.05)
            hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
            hrp.AssemblyLinearVelocity = Vector3.zero
            return true
        end

        -- Grapple vers la cible
        local ok = pcall(function() tool:Activate() end)
        if not ok then pcall(function() firesignal(tool.Activated) end) end
        task.wait(0.15)
        return true
    end

    -- ── Steal un pet ─────────────────────────────────────────
    local isStealing = false
    local function stealPet(petData)
        if isStealing then return end
        isStealing = true

        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then isStealing = false; return end

        SetStatus("TP vers " .. petData.plot .. "...", T.Gold)
        notify("Auto Steal", "TP vers " .. petData.plot)

        -- Soin pendant le TP
        local maxHP = hum.MaxHealth
        local healConn = RunService.Heartbeat:Connect(function()
            if hum and hum.Parent then
                hum.Health = maxHP
            end
        end)

        -- TP
        if Config.GrappleTP then
            doGrappleTP(petData.pos)
        else
            hrp.CFrame = CFrame.new(petData.pos + Vector3.new(0, 4, 0))
        end

        task.wait(0.3)
        char = LP.Character
        hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            healConn:Disconnect()
            isStealing = false
            return
        end

        -- Attente arrivée
        local t0 = os.clock()
        while (hrp.Position - petData.pos).Magnitude > 15
            and os.clock() - t0 < 5 do
            task.wait(0.1)
        end

        SetStatus("Steal en cours...", T.Gold)

        -- Tentative steal via prompt
        task.wait(Config.StealDelay)
        if petData.prompt then
            local oldMax = nil
            pcall(function() oldMax = petData.prompt.MaxActivationDistance end)
            pcall(function() petData.prompt.MaxActivationDistance = math.huge end)
            pcall(function()
                fireProximityPrompt(petData.prompt)
            end)
            task.wait(0.05)
            pcall(function()
                if oldMax then petData.prompt.MaxActivationDistance = oldMax end
            end)
        end

        -- Fallback: fire remote UseItem
        fireRemote("UseItem")

        healConn:Disconnect()
        SetStatus("Steal terminé!", T.Green)
        notify("Auto Steal", "Steal effectué sur " .. petData.plot, 2)
        task.wait(1)
        isStealing = false
    end

    -- ── Boucle auto steal ────────────────────────────────────
    local function startStealLoop()
        if stealConn then return end
        stealConn = task.spawn(function()
            while stealLoop do
                if not isStealing then
                    local pets = scanPets()
                    if #pets > 0 then
                        stealPet(pets[1])
                    else
                        SetStatus("Aucun pet trouvé...", T.Dim)
                    end
                end
                task.wait(0.5)
            end
        end)
    end
    local function stopStealLoop()
        stealLoop = false
        if stealConn then
            task.cancel(stealConn)
            stealConn = nil
        end
        SetStatus("Auto Steal arrêté", T.Dim)
    end

    -- Widgets steal
    Toggle(pSteal, "Auto Steal", "TP et steal automatiquement", "AutoSteal", 2, function(on)
        stealLoop = on
        if on then
            task.spawn(buildNet)
            startStealLoop()
            notify("Auto Steal", "Activé ✓")
        else
            stopStealLoop()
        end
    end)

    Toggle(pSteal, "Grapple TP", "Utilise le grapple hook pour TP", "GrappleTP", 3)
    Slider(pSteal, "Vitesse TP", "TPSpeed", 100, 800, 4, "%d", nil)
    Slider(pSteal, "Délai steal", "StealDelay", 0, 1, 5, "%.2f", nil)

    Section(pSteal, "MANUEL", 6)
    Button(pSteal, "Steal maintenant", "Force un steal immédiat", T.Accent, 7, function()
        task.spawn(function()
            local pets = scanPets()
            if #pets > 0 then
                stealPet(pets[1])
            else
                notify("Steal", "Aucun pet trouvé", 2)
            end
        end)
    end)
    Button(pSteal, "Scanner pets", "Liste les pets disponibles", T.Blue, 8, function()
        local pets = scanPets()
        notify("Scanner", #pets .. " pet(s) trouvé(s)", 2)
        SetStatus(#pets .. " pets détectés", T.Blue)
    end)

    -- ═══════════════════════════════════════════════════════════
    --  PAGE : ESP
    -- ═══════════════════════════════════════════════════════════
    local pESP = Pages["ESP"]
    Section(pESP, "ESP", 1)

    local ESPEnabled = false
    local ESPObjects = {}

    local function W2S(pos)
        local sp, on = Cam:WorldToViewportPoint(pos)
        return Vector2.new(sp.X, sp.Y), on
    end
    local function lerpC3(a, b, t)
        return Color3.new(
            a.R + (b.R-a.R)*t,
            a.G + (b.G-a.G)*t,
            a.B + (b.B-a.B)*t
        )
    end

    local SKELETON = {
        {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
        {"LowerTorso","HumanoidRootPart"},
        {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
        {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
        {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    }

    local function createESP(player)
        if ESPObjects[player] then return end
        local obj = {BoxLines={}, SkelLines={}}
        for i = 1, 4 do
            local l = Drawing.new("Line")
            l.Visible=false; l.Color=T.Accent; l.Thickness=1.5; l.ZIndex=2
            obj.BoxLines[i] = l
        end
        for i = 1, #SKELETON do
            local l = Drawing.new("Line")
            l.Visible=false; l.Color=Color3.fromRGB(255,140,0); l.Thickness=1; l.ZIndex=1
            obj.SkelLines[i] = l
        end
        obj.NameText = Drawing.new("Text")
        obj.NameText.Visible=false; obj.NameText.Color=T.Text
        obj.NameText.Size=14; obj.NameText.Center=true
        obj.NameText.Outline=true; obj.NameText.OutlineColor=Color3.new(0,0,0)
        obj.NameText.ZIndex=3
        obj.HealthBG = Drawing.new("Line")
        obj.HealthBG.Visible=false; obj.HealthBG.Color=Color3.fromRGB(30,30,30)
        obj.HealthBG.Thickness=4; obj.HealthBG.ZIndex=2
        obj.HealthFill = Drawing.new("Line")
        obj.HealthFill.Visible=false; obj.HealthFill.Thickness=4; obj.HealthFill.ZIndex=3
        ESPObjects[player] = obj
    end

    local function hideESP(obj)
        if not obj then return end
        for _,l in ipairs(obj.BoxLines) do l.Visible=false end
        for _,l in ipairs(obj.SkelLines) do l.Visible=false end
        obj.NameText.Visible=false
        obj.HealthBG.Visible=false
        obj.HealthFill.Visible=false
    end

    local function removeESP(player)
        local obj = ESPObjects[player]
        if not obj then return end
        for _,l in ipairs(obj.BoxLines) do l:Remove() end
        for _,l in ipairs(obj.SkelLines) do l:Remove() end
        obj.NameText:Remove(); obj.HealthBG:Remove(); obj.HealthFill:Remove()
        ESPObjects[player] = nil
    end

    -- ESP config
    local ESPCfg = {
        Boxes    = true,
        Skeleton = true,
        Names    = true,
        Health   = true,
        MaxDist  = 1000,
    }

    local espToggleRow
    espToggleRow = Toggle(pESP, "ESP activé", "Affiche les joueurs", "AutoSteal", 2)
    -- On override le config key pour ESP
    do
        local tbg = espToggleRow:FindFirstChild("Frame", true)
        -- toggle indépendant
        local espOn = false
        local espBG = Instance.new("Frame")
        espBG.Size = UDim2.new(0, 44, 0, 24)
        espBG.AnchorPoint = Vector2.new(1, 0.5)
        espBG.Position = UDim2.new(1, -12, 0.5, 0)
        espBG.BackgroundColor3 = T.ToggleOff
        espBG.BorderSizePixel = 0
        espBG.Parent = espToggleRow
        corner(espBG, 12)
        local espKnob = Instance.new("Frame")
        espKnob.Size = UDim2.new(0, 20, 0, 20)
        espKnob.Position = UDim2.new(0, 2, 0.5, -10)
        espKnob.BackgroundColor3 = Color3.new(1,1,1)
        espKnob.BorderSizePixel = 0
        espKnob.Parent = espBG
        corner(espKnob, 10)
        espBG.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                espOn = not espOn
                ESPEnabled = espOn
                tween(espBG, {BackgroundColor3 = espOn and T.ToggleOn or T.ToggleOff}, 0.15)
                tween(espKnob, {Position = espOn
                    and UDim2.new(1,-22,0.5,-10)
                    or  UDim2.new(0,2,0.5,-10)}, 0.15)
                if not espOn then
                    for p, obj in pairs(ESPObjects) do hideESP(obj) end
                end
            end
        end)
    end

    Section(pESP, "OPTIONS", 3)
    Slider(pESP, "Distance max", "MaxStealDist", 100, 2000, 4, "%d", function(v)
        ESPCfg.MaxDist = v
    end)

    -- ═══════════════════════════════════════════════════════════
    --  PAGE : EXTRAS
    -- ═══════════════════════════════════════════════════════════
    local pExtras = Pages["Extras"]
    Section(pExtras, "FACE AWAY", 1)

    local faceAwayConn = nil
    Toggle(pExtras, "Face Away", "Tourne le dos au propriétaire", "FaceAway", 2, function(on)
        if faceAwayConn then faceAwayConn:Disconnect(); faceAwayConn = nil end
        if on then
            faceAwayConn = RunService.Heartbeat:Connect(function()
                if not Config.FaceAway then return end
                local char = LP.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if not hrp or not hum then return end
                if not LP:GetAttribute("Stealing") then return end
                -- Tourne de 180°
                local cf = hrp.CFrame
                hrp.CFrame = CFrame.new(cf.Position)
                    * CFrame.Angles(0, math.pi, 0)
                    * CFrame.new(0, 0, 0)
            end)
            notify("Face Away", "Activé")
        end
    end)

    Section(pExtras, "ANTI-CHEAT", 3)
    Toggle(pExtras, "Anti Flasher", "Supprime les accessoires", "AntiFlasher", 4, function(on)
        if on then
            local function strip(char)
                if not char then return end
                for _, item in ipairs(char:GetChildren()) do
                    if item:IsA("Accessory") then
                        pcall(function() item:Destroy() end)
                    end
                end
            end
            for _, p in ipairs(Players:GetPlayers()) do
                strip(p.Character)
                p.CharacterAdded:Connect(strip)
            end
            Players.PlayerAdded:Connect(function(p)
                p.CharacterAdded:Connect(strip)
            end)
            notify("Anti Flasher", "Activé")
        end
    end)

    Toggle(pExtras, "Anti Collision", "Passe à travers les joueurs", "AntiCollision", 5, function(on)
        if on then
            local function disableCollision(char)
                if not char then return end
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        pcall(function() p.CanCollide = false end)
                    end
                end
            end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP then disableCollision(p.Character) end
            end
            notify("Anti Collision", "Activé")
        end
    end)

    Section(pExtras, "DIVERS", 6)
    Button(pExtras, "Rejoin", "Rejoint le même serveur", T.Blue, 7, function()
        local TS = game:GetService("TeleportService")
        pcall(function()
            TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        end)
    end)
    Button(pExtras, "Reset character", "Respawn le personnage", T.Red, 8, function()
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end)

    -- ═══════════════════════════════════════════════════════════
    --  PAGE : SOCIALS
    -- ═══════════════════════════════════════════════════════════
    local pSoc = Pages["Socials"]
    Section(pSoc, "SOCIALS", 1)

    local function SocialRow(parent, platform, handle, color, order)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 54)
        row.BackgroundColor3 = T.Row
        row.BorderSizePixel = 0
        row.LayoutOrder = order or 0
        row.Parent = parent
        corner(row, 8)

        local icon = Instance.new("Frame")
        icon.Size = UDim2.new(0, 36, 0, 36)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Position = UDim2.new(0, 10, 0.5, 0)
        icon.BackgroundColor3 = color or T.Accent
        icon.BackgroundTransparency = 0.7
        icon.BorderSizePixel = 0
        icon.Parent = row
        corner(icon, 10)

        local iconLbl = Instance.new("TextLabel")
        iconLbl.Size = UDim2.new(1, 0, 1, 0)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Text = platform:sub(1, 2)
        iconLbl.TextColor3 = color or T.Accent
        iconLbl.Font = Enum.Font.GothamBold
        iconLbl.TextSize = 14
        iconLbl.Parent = icon

        local plat = Instance.new("TextLabel")
        plat.Size = UDim2.new(1, -60, 0, 18)
        plat.Position = UDim2.new(0, 54, 0, 9)
        plat.BackgroundTransparency = 1
        plat.Text = platform
        plat.TextColor3 = T.Text
        plat.Font = Enum.Font.GothamBold
        plat.TextSize = 13
        plat.TextXAlignment = Enum.TextXAlignment.Left
        plat.Parent = row

        local hndl = Instance.new("TextLabel")
        hndl.Size = UDim2.new(1, -60, 0, 16)
        hndl.Position = UDim2.new(0, 54, 0, 28)
        hndl.BackgroundTransparency = 1
        hndl.Text = handle
        hndl.TextColor3 = color or T.Accent
        hndl.Font = Enum.Font.Gotham
        hndl.TextSize = 12
        hndl.TextXAlignment = Enum.TextXAlignment.Left
        hndl.Parent = row
        return row
    end

    SocialRow(pSoc, "TikTok", "@ak2.v", Color3.fromRGB(255, 50, 80), 2)
    SocialRow(pSoc, "Discord", "AK2 Community", Color3.fromRGB(88, 101, 242), 3)

    -- Credit
    local creditFrame = Instance.new("Frame")
    creditFrame.Size = UDim2.new(1, 0, 0, 36)
    creditFrame.BackgroundColor3 = T.Panel
    creditFrame.BorderSizePixel = 0
    creditFrame.LayoutOrder = 10
    creditFrame.Parent = pSoc
    corner(creditFrame, 8)
    local creditLbl = Instance.new("TextLabel")
    creditLbl.Size = UDim2.new(1, 0, 1, 0)
    creditLbl.BackgroundTransparency = 1
    creditLbl.Text = "AK2  •  Steal a Brainrot Script  •  v2.0"
    creditLbl.TextColor3 = T.Dim
    creditLbl.Font = Enum.Font.Gotham
    creditLbl.TextSize = 11
    creditLbl.Parent = creditFrame

    -- ═══════════════════════════════════════════════════════════
    --  PAGE : CONFIG
    -- ═══════════════════════════════════════════════════════════
    local pConfig = Pages["Config"]
    Section(pConfig, "THÈME", 1)

    for themeName, _ in pairs(Themes) do
        Button(pConfig, "Thème " .. themeName, nil,
            Themes[themeName].Accent, 2, function()
            Config.Theme = themeName
            T = Themes[themeName]
            SaveConfig()
            notify("Thème", themeName .. " appliqué — relancez le script", 3)
        end)
    end

    Section(pConfig, "PARAMÈTRES", 5)
    Toggle(pConfig, "Notifications", "Affiche les popups", "NotifEnabled", 6)
    Slider(pConfig, "Délai clone", "CloneDelay", 0, 1, 7, "%.2f")

    Button(pConfig, "Sauvegarder config", "Sauvegarde les paramètres", T.Accent, 8, function()
        SaveConfig()
        notify("Config", "Sauvegardé ✓", 2)
    end)
    Button(pConfig, "Reset config", "Réinitialise tout", T.Red, 9, function()
        if writefile then pcall(function() writefile(CONFIG_FILE, "{}") end) end
        notify("Config", "Reset — relancez le script", 3)
    end)

    -- ═══════════════════════════════════════════════════════════
    --  RENDER LOOP (ESP)
    -- ═══════════════════════════════════════════════════════════
    RunService.RenderStepped:Connect(function()
        if not ESPEnabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LP then continue end
            local char = player.Character
            if not char then
                if ESPObjects[player] then hideESP(ESPObjects[player]) end
                continue
            end
            local hrp  = char:FindFirstChild("HumanoidRootPart")
            local hum  = char:FindFirstChildOfClass("Humanoid")
            local head = char:FindFirstChild("Head")
            if not hrp or not hum or not head then
                if ESPObjects[player] then hideESP(ESPObjects[player]) end
                continue
            end
            local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local dist  = myHRP and (hrp.Position - myHRP.Position).Magnitude or 0
            if dist > ESPCfg.MaxDist then
                if ESPObjects[player] then hideESP(ESPObjects[player]) end
                continue
            end

            createESP(player)
            local obj = ESPObjects[player]

            local headPos, headOn = W2S(head.Position + Vector3.new(0, 0.5, 0))
            local footPos, footOn = W2S(hrp.Position  - Vector3.new(0, 2.5, 0))

            if headOn and footOn then
                local bH = math.abs(footPos.Y - headPos.Y)
                local bW = bH * 0.55
                local bx = headPos.X - bW/2
                local by = headPos.Y
                local corners = {
                    {Vector2.new(bx,    by),    Vector2.new(bx+bW, by)},
                    {Vector2.new(bx+bW, by),    Vector2.new(bx+bW, by+bH)},
                    {Vector2.new(bx+bW, by+bH), Vector2.new(bx,    by+bH)},
                    {Vector2.new(bx,    by+bH), Vector2.new(bx,    by)},
                }
                for i, l in ipairs(obj.BoxLines) do
                    l.From=corners[i][1]; l.To=corners[i][2]; l.Visible=true
                    l.Color = T.Accent
                end
                -- Health bar
                local maxHP   = hum.MaxHealth > 0 and hum.MaxHealth or 100
                local hpRatio = math.clamp(hum.Health/maxHP, 0, 1)
                obj.HealthBG.From=Vector2.new(bx-6,by)
                obj.HealthBG.To=Vector2.new(bx-6,by+bH)
                obj.HealthBG.Visible=true
                obj.HealthFill.From=Vector2.new(bx-6,by+bH*(1-hpRatio))
                obj.HealthFill.To=Vector2.new(bx-6,by+bH)
                obj.HealthFill.Color=lerpC3(
                    Color3.fromRGB(255,0,0),
                    Color3.fromRGB(0,255,0),
                    hpRatio
                )
                obj.HealthFill.Visible=true
                -- Nom
                obj.NameText.Text=player.DisplayName.." ["..math.floor(dist).."m]"
                obj.NameText.Position=Vector2.new(headPos.X, by-18)
                obj.NameText.Visible=true
            else
                hideESP(obj)
            end

            -- Skeleton
            for i, pair in ipairs(SKELETON) do
                local p1 = char:FindFirstChild(pair[1])
                local p2 = char:FindFirstChild(pair[2])
                local line = obj.SkelLines[i]
                if p1 and p2 then
                    local s1, o1 = W2S(p1.Position)
                    local s2, o2 = W2S(p2.Position)
                    if o1 and o2 then
                        line.From=s1; line.To=s2; line.Visible=true
                    else line.Visible=false end
                else line.Visible=false end
            end
        end
    end)

    -- Hooks joueurs
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(1); createESP(p)
        end)
    end)
    Players.PlayerRemoving:Connect(function(p)
        removeESP(p)
    end)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then createESP(p) end
    end

    SetStatus("AK2 v2.0 prêt  •  @ak2.v  •  RightAlt = toggle", T.Accent)
    notify("AK2 SAB", "Script chargé ! RightAlt pour toggle", 4)
end

-- ── Lancement ─────────────────────────────────────────────────
ShowSplash(function()
    task.spawn(BuildGUI)
end)

print("[AK2] Steal a Brainrot v2.0 chargé")
