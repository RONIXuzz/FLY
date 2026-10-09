local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Tween      = game:GetService("TweenService")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if _G.__UniFlyClean then pcall(_G.__UniFlyClean) end
local Conns, GuiRef, BV, BG, saved = {}, nil, nil, nil, {}
local function conn(c) table.insert(Conns, c); return c end

local Config = {
    Fly    = false,
    Speed  = 100,
    VSpeed = 100,
    Smooth = 0.18,
    AntiAC = true,
    MaxVel = 1000,
}

local ACCENT = Color3.fromRGB(90,140,255)
local GREEN  = Color3.fromRGB(55,205,125)
local GREY   = Color3.fromRGB(55,55,66)

local function getParent()
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then return cg end
    return LP:WaitForChild("PlayerGui")
end

local function makeDraggable(frame, handle)
    local drag, start, spos
    conn(handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; start = i.Position; spos = frame.Position
            conn(i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then drag = false end
            end))
        end
    end))
    conn(UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - start
            frame.Position = UDim2.new(spos.X.Scale, spos.X.Offset + d.X, spos.Y.Scale, spos.Y.Offset + d.Y)
        end
    end))
end

local function makeSpeedControl(parent, labelText, defV, onChanged)
    local MIN, MAX = 0, 1000
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -24, 0, 58)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -72, 0, 18)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextColor3 = Color3.fromRGB(205,210,222)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.Parent = holder

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 62, 0, 20)
    box.Position = UDim2.new(1, -62, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(34,34,42)
    box.BorderSizePixel = 0
    box.Font = Enum.Font.GothamBold
    box.TextSize = 12
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.Text = tostring(defV)
    box.PlaceholderText = "0-1000"
    box.ClearTextOnFocus = false
    box.Parent = holder
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 7)
    bar.Position = UDim2.new(0, 0, 0, 30)
    bar.BackgroundColor3 = GREY
    bar.BorderSizePixel = 0
    bar.Parent = holder
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defV - MIN) / (MAX - MIN), 0, 1, 0)
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 13, 0, 13)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defV - MIN) / (MAX - MIN), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.Parent = bar
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function apply(val, fromBox)
        val = math.clamp(math.floor(val), MIN, MAX)
        local rel = (val - MIN) / (MAX - MIN)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        if not fromBox then box.Text = tostring(val) end
        onChanged(val)
    end

    conn(box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then
            apply(n, true)
            box.Text = tostring(math.clamp(math.floor(n), MIN, MAX))
        else
            box.Text = tostring(defV)
        end
    end))

    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        apply(MIN + (MAX - MIN) * rel, false)
    end
    conn(bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setFromX(i.Position.X)
        end
    end))
    conn(UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end))
    conn(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    return holder
end

local function guideRow(parent, key, desc)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 19)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 56, 0, 17)
    badge.BackgroundColor3 = Color3.fromRGB(40,42,54)
    badge.BorderSizePixel = 0
    badge.Font = Enum.Font.GothamBold
    badge.TextSize = 10
    badge.TextColor3 = Color3.fromRGB(150,190,255)
    badge.Text = key
    badge.Parent = row
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0,5)

    local lbl = Instance.new("TextLabel")
    lbl.Position = UDim2.new(0, 64, 0, 0)
    lbl.Size = UDim2.new(1, -64, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(200,205,218)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = desc
    lbl.Parent = row

    return row
end

local function clearForces()
    if BV then BV:Destroy(); BV = nil end
    if BG then BG:Destroy(); BG = nil end
end

local function enableFly()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    clearForces()
    pcall(function() hrp:SetNetworkOwner(LP) end)

    BV = Instance.new("BodyVelocity")
    BV.Name = "UniFly_BV"
    BV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    BV.Velocity = Vector3.zero
    BV.Parent = hrp

    BG = Instance.new("BodyGyro")
    BG.Name = "UniFly_BG"
    BG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    BG.P = 3e4
    BG.D = 100
    BG.Parent = hrp

    saved.platform = hum.PlatformStand
    saved.state    = hum:GetState()
    hum.PlatformStand = true
    if Config.AntiAC then
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        pcall(function() hum.AutoRotate = false end)
    end
end

local function disableFly()
    clearForces()
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = saved.platform or false
            pcall(function() hum.AutoRotate = true end)
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        end
    end
end

local function setFly(state)
    Config.Fly = state
    if state then enableFly() else disableFly() end
    if GuiRef and GuiRef.FlyBtn then
        GuiRef.FlyBtn.BackgroundColor3 = state and GREEN or GREY
        GuiRef.FlyBtn.Text = state and "FLY:  ON" or "FLY:  OFF"
    end
end

conn(LP.CharacterAdded:Connect(function()
    task.wait(0.6)
    if Config.Fly then enableFly() end
end))

conn(RunService.RenderStepped:Connect(function(dt)
    if not Config.Fly then return end
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not BV or BV.Parent ~= hrp then enableFly(); return end

    local cam = workspace.CurrentCamera
    local look  = cam.CFrame.LookVector
    local right = cam.CFrame.RightVector

    local move = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then move += look end
    if UIS:IsKeyDown(Enum.KeyCode.S) then move -= look end
    if UIS:IsKeyDown(Enum.KeyCode.D) then move += right end
    if UIS:IsKeyDown(Enum.KeyCode.A) then move -= right end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end

    if move.Magnitude > 0 then move = move.Unit end

    local speed = Config.Speed
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then speed *= 2 end

    local target = Vector3.new(move.X, 0, move.Z) * speed
                   + Vector3.new(0, move.Y, 0) * Config.VSpeed

    if target.Magnitude > Config.MaxVel then
        target = target.Unit * Config.MaxVel
    end

    local alpha = 1 - (1 - Config.Smooth) ^ (dt * 60)
    BV.Velocity = BV.Velocity:Lerp(target, alpha)
    BG.CFrame = CFrame.new(hrp.Position, hrp.Position + look)
end))

local function buildGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "UniFlyGUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = getParent()

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 245, 0, 0)
    main.AutomaticSize = Enum.AutomaticSize.Y
    main.Position = UDim2.new(0, 20, 0, 120)
    main.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    main.BorderSizePixel = 0
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(45, 45, 58)
    stroke.Thickness = 1

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 38)
    top.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    top.BorderSizePixel = 0
    top.Parent = main
    Instance.new("UICorner", top).CornerRadius = UDim.new(0, 12)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextColor3 = Color3.fromRGB(240, 242, 248)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "UNIVERSAL FLY  v3"
    title.Parent = top

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(1, -20, 0.5, -4)
    dot.BackgroundColor3 = GREEN
    dot.Parent = top
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Position = UDim2.new(0, 0, 0, 38)
    body.BackgroundTransparency = 1
    body.Parent = main

    local pad = Instance.new("UIPadding", body)
    pad.PaddingTop = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)

    local layout = Instance.new("UIListLayout", body)
    layout.Padding = UDim.new(0, 9)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local flyBtn = Instance.new("TextButton")
    flyBtn.Name = "FlyBtn"
    flyBtn.Size = UDim2.new(1, 0, 0, 34)
    flyBtn.BackgroundColor3 = GREY
    flyBtn.BorderSizePixel = 0
    flyBtn.Font = Enum.Font.GothamBold
    flyBtn.TextSize = 13
    flyBtn.TextColor3 = Color3.fromRGB(255,255,255)
    flyBtn.Text = "FLY:  OFF"
    flyBtn.Parent = body
    Instance.new("UICorner", flyBtn).CornerRadius = UDim.new(0, 8)
    flyBtn.MouseButton1Click:Connect(function() setFly(not Config.Fly) end)

    local acBtn = Instance.new("TextButton")
    acBtn.Size = UDim2.new(1, 0, 0, 28)
    acBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
    acBtn.BorderSizePixel = 0
    acBtn.Font = Enum.Font.GothamMedium
    acBtn.TextSize = 12
    acBtn.TextColor3 = ACCENT
    acBtn.Text = "Anti-Cheat Bypass:  ON"
    acBtn.Parent = body
    Instance.new("UICorner", acBtn).CornerRadius = UDim.new(0, 8)
    acBtn.MouseButton1Click:Connect(function()
        Config.AntiAC = not Config.AntiAC
        acBtn.Text = "Anti-Cheat Bypass:  " .. (Config.AntiAC and "ON" or "OFF")
        acBtn.TextColor3 = Config.AntiAC and ACCENT or Color3.fromRGB(150,150,160)
        if Config.Fly then enableFly() end
    end)

    makeSpeedControl(body, "Fly Speed", Config.Speed, function(v) Config.Speed = v end)
    makeSpeedControl(body, "Vertical Speed", Config.VSpeed, function(v) Config.VSpeed = v end)

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
    divider.BorderSizePixel = 0
    divider.Parent = body

    local guideTitle = Instance.new("TextLabel")
    guideTitle.Size = UDim2.new(1, 0, 0, 16)
    guideTitle.BackgroundTransparency = 1
    guideTitle.Font = Enum.Font.GothamBold
    guideTitle.TextSize = 11
    guideTitle.TextColor3 = ACCENT
    guideTitle.TextXAlignment = Enum.TextXAlignment.Left
    guideTitle.Text = "GUIDE"
    guideTitle.Parent = body

    guideRow(body, "[F]", "Fly ON / OFF")
    guideRow(body, "[G]", "Menu Hide / Show")
    guideRow(body, "[Shift]", "2x Fly speed")
    guideRow(body, "[Space/Ctrl]", "Up / Down")
    guideRow(body, "[WASD]", "Move")

    local credit = Instance.new("TextLabel")
    credit.Size = UDim2.new(1, 0, 0, 18)
    credit.BackgroundTransparency = 1
    credit.Font = Enum.Font.GothamBold
    credit.TextSize = 12
    credit.TextColor3 = Color3.fromRGB(255,255,255)
    credit.Text = "Created By SYNTAXscriptz"
    credit.Parent = body

    local cg = Instance.new("UIGradient")
    cg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(110,150,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(110,150,255)),
    })
    cg.Offset = Vector2.new(-1.5, 0)
    cg.Parent = credit

    conn(RunService.RenderStepped:Connect(function(dt)
        local x = cg.Offset.X + dt * 0.5
        if x > 1.5 then x = -1.5 end
        cg.Offset = Vector2.new(x, 0)
    end))

    makeDraggable(main, top)
    GuiRef = { gui = gui, main = main, FlyBtn = flyBtn }
    return gui
end

local function playSplash()
    local sg = Instance.new("ScreenGui")
    sg.Name = "UniFlySplash"
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 999
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = getParent()

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(2, 4, 10)
    bg.BorderSizePixel = 0
    bg.BackgroundTransparency = 1
    bg.Parent = sg

    local bgGrad = Instance.new("UIGradient")
    bgGrad.Rotation = 90
    bgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 14, 30)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(2, 4, 10)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 18, 40)),
    })
    bgGrad.Parent = bg

    local logo = Instance.new("Frame")
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position = UDim2.new(0.5, 0, 0.5, 0)
    logo.Size = UDim2.new(0, 480, 0, 280)
    logo.BackgroundTransparency = 1
    logo.Parent = bg

    local scale = Instance.new("UIScale")
    scale.Scale = 0.2
    scale.Parent = logo

    local glow = Instance.new("Frame")
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.Size = UDim2.new(0, 10, 0, 10)
    glow.BackgroundColor3 = Color3.fromRGB(40, 110, 255)
    glow.BackgroundTransparency = 0.75
    glow.BorderSizePixel = 0
    glow.Parent = logo
    Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)

    local crown = Instance.new("TextLabel")
    crown.AnchorPoint = Vector2.new(0.5, 0.5)
    crown.Position = UDim2.new(0.5, 0, 0.5, -100)
    crown.Size = UDim2.new(0, 100, 0, 70)
    crown.BackgroundTransparency = 1
    crown.Font = Enum.Font.GothamBold
    crown.TextSize = 60
    crown.Text = "♛"
    crown.TextColor3 = Color3.fromRGB(130, 185, 255)
    crown.Parent = logo
    local cStroke = Instance.new("UIStroke")
    cStroke.Color = Color3.fromRGB(50, 120, 255)
    cStroke.Thickness = 2
    cStroke.Transparency = 0.2
    cStroke.Parent = crown

    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Position = UDim2.new(0.5, 0, 0.5, -22)
    title.Size = UDim2.new(0, 460, 0, 80)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 58
    title.RichText = true
    title.Text = "<b>SYNTAX</b>scriptz"
    title.TextColor3 = Color3.fromRGB(235, 240, 250)
    title.Parent = logo
    local tGrad = Instance.new("UIGradient")
    tGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 182, 205)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 156, 185)),
    })
    tGrad.Parent = title
    local tStroke = Instance.new("UIStroke")
    tStroke.Color = Color3.fromRGB(60, 105, 220)
    tStroke.Thickness = 1.5
    tStroke.Transparency = 0.35
    tStroke.Parent = title

    local hub = Instance.new("TextLabel")
    hub.AnchorPoint = Vector2.new(0.5, 0.5)
    hub.Position = UDim2.new(0.5, 0, 0.5, 52)
    hub.Size = UDim2.new(0, 240, 0, 90)
    hub.BackgroundTransparency = 1
    hub.Font = Enum.Font.GothamBlack
    hub.TextSize = 72
    hub.Text = "Hub"
    hub.TextColor3 = Color3.fromRGB(90, 160, 255)
    hub.Parent = logo
    local hGrad = Instance.new("UIGradient")
    hGrad.Rotation = 90
    hGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 205, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(45, 115, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 70, 200)),
    })
    hGrad.Parent = hub
    local hStroke = Instance.new("UIStroke")
    hStroke.Color = Color3.fromRGB(120, 190, 255)
    hStroke.Thickness = 2
    hStroke.Transparency = 0.15
    hStroke.Parent = hub

    local sparkles = {}
    local positions = {
        {0.5, -140}, {0.16, -60}, {0.84, -60}, {0.28, 108}, {0.72, 108},
    }
    for i, p in ipairs(positions) do
        local s = Instance.new("TextLabel")
        s.AnchorPoint = Vector2.new(0.5, 0.5)
        s.Position = UDim2.new(p[1], 0, 0.5, p[2])
        s.Size = UDim2.new(0, 26, 0, 26)
        s.BackgroundTransparency = 1
        s.Font = Enum.Font.GothamBold
        s.TextSize = 18
        s.Text = "✦"
        s.TextColor3 = Color3.fromRGB(150, 205, 255)
        s.TextTransparency = 1
        s.Parent = logo
        table.insert(sparkles, s)
    end

    Tween:Create(bg, TweenInfo.new(0.5), { BackgroundTransparency = 0 }):Play()
    task.wait(0.12)
    Tween:Create(scale, TweenInfo.new(0.85, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    task.spawn(function()
        while glow.Parent do
            glow.Size = UDim2.new(0, 10, 0, 10)
            Tween:Create(glow, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 620, 0, 320),
                BackgroundTransparency = 0.95,
            }):Play()
            task.wait(1.1)
        end
    end)

    task.spawn(function()
        while crown.Parent do
            Tween:Create(crown, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), {
                Position = UDim2.new(0.5, 0, 0.5, -114),
            }):Play()
            task.wait(2.4)
        end
    end)

    for i, s in ipairs(sparkles) do
        task.spawn(function()
            task.wait(0.3 + i * 0.09)
            while s.Parent do
                Tween:Create(s, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
                Tween:Create(s, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
                task.wait(0.7)
            end
        end)
    end

    task.wait(2.15)
    Tween:Create(bg, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
    task.wait(0.65)
    sg:Destroy()
end

buildGUI()
playSplash()

conn(UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F then
        setFly(not Config.Fly)
    elseif i.KeyCode == Enum.KeyCode.G then
        if GuiRef and GuiRef.gui then
            GuiRef.gui.Enabled = not GuiRef.gui.Enabled
        end
    end
end))

_G.__UniFlyClean = function()
    setFly(false)
    for _, c in pairs(Conns) do pcall(function() c:Disconnect() end) end
    if GuiRef and GuiRef.gui then GuiRef.gui:Destroy() end
    Conns = {}
end