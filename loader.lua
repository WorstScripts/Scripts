getgenv().HubListen = true
-- WORST AUTH | Cloudflare Worker loader
local WORKER = "https://script-hub.worstasaiya.workers.dev"
local DISCORD_URL = "https://discord.gg/WFY7f6XAh7"
local SAVE_KEY = true
local KEY_FILE = "disck.txt"

if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- same monochrome ash palette as the main hub (WORSTHUB.lua): near-black window, grey ash stroke,
-- bright ash-white for the one "good" accent, warm ember for the one "bad / warning" accent.
local C = {
    bg = Color3.fromRGB(8,8,8),
    surface = Color3.fromRGB(14,14,14),
    border = Color3.fromRGB(105,105,105),
    accent = Color3.fromRGB(235,235,235),
    text = Color3.fromRGB(242,242,242),
    muted = Color3.fromRGB(150,150,150),
    green = Color3.fromRGB(255,255,255),   -- success (kept the name "green" so nothing else needs renaming)
    red = Color3.fromRGB(255,175,120),     -- error / warm ember accent (same tone the hub's glow uses)
    yellow = Color3.fromRGB(255,175,120),  -- warning, same ember tone
}

local function send(url, body)
    local req = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    if not req then return nil, "This executor can't make web requests." end
    local ok, res = pcall(req, {
        Url = url, Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(body)
    })
    if not ok or type(res) ~= "table" then return nil, "Could not reach the server." end
    local decoded
    pcall(function() decoded = HttpService:JSONDecode(res.Body) end)
    return decoded or {}, nil, tonumber(res.StatusCode or res.Status)
end

local executor = "Unknown"
pcall(function() if identifyexecutor then executor = tostring(identifyexecutor()) end end)

local function check(key)
    local data, err, status = send(WORKER .. "/loader/run", {
        key = key, placeId = game.PlaceId, uid = LocalPlayer.UserId, executor = executor
    })
    if not data then return nil, err end
    if status == 401 then
        return nil, data.error or "Key expired or invalid. Join Discord for a new key."
    end
    if not data.ok then return nil, data.error or "Something went wrong. Try again." end
    return data
end

local function runScripts(data)
    for _, s in ipairs(data.scripts or {}) do
        task.spawn(function()
            local fn, cerr = loadstring(s.code)
            if not fn then
                warn("[WORST AUTH] " .. tostring(s.name) .. " failed to load: " .. tostring(cerr))
                return
            end
            local ok, rerr = pcall(fn)
            if not ok then warn("[WORST AUTH] " .. tostring(s.name) .. " errored: " .. tostring(rerr)) end
        end)
    end
end

local function listen(key)
    if not (getgenv and getgenv().HubListen) then return end
    task.spawn(function()
        local since = nil
        while true do
            local data, _, status = send(WORKER .. "/loader/poll", { key = key, since = since })
            if status == 401 then return end
            if data and data.ok then
                since = data.last
                if data.runs and #data.runs > 0 then runScripts({scripts = data.runs}) end
            end
            task.wait(10)
        end
    end)
end

local function readSaved()
    if not (SAVE_KEY and readfile and isfile) then return nil end
    local ok, v = pcall(function() return isfile(KEY_FILE) and readfile(KEY_FILE) or nil end)
    return ok and v and v ~= "" and v or nil
end
local function writeSaved(key)
    if SAVE_KEY and writefile then pcall(writefile, KEY_FILE, key) end
end

local function round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end
local function outline(obj, color)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = 1
    s.Parent = obj
    return s
end
local function textLabel(parent, content, size, color, bold)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Text = content
    t.TextSize = size
    t.TextColor3 = color
    t.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = parent
    return t
end
local function button(parent, label, position, size, color, foreground)
    local b = Instance.new("TextButton")
    b.Position = position
    b.Size = size
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Text = label
    b.TextColor3 = foreground
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.Parent = parent
    round(b, 9)
    return b
end

-- Gives a UIStroke the same black-to-white shimmer gradient that slowly spins around the main hub's
-- window border. Returns a handle so the caller can stop it (e.g. when the popup closes).
local function ashBorder(st, speed)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(35, 35, 35)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(215, 215, 215)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(35, 35, 35)),
    })
    g.Parent = st
    local rot = math.random() * 360
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not g.Parent then conn:Disconnect() return end
        rot = (rot + dt * (speed or 35)) % 360
        g.Rotation = rot
    end)
    return conn
end

-- A handful of slow-rising ash / ember particles inside a clipped frame, the same look (toned down) as
-- the hub's background effect. cfg.parent must clip descendants (the popup's CanvasGroup already does).
local function emberField(parent, w, h, count)
    local COOL = Color3.fromRGB(130, 130, 130)
    local parts = {}
    for i = 1, (count or 12) do
        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.Size = UDim2.fromOffset(3, 3)
        f.ZIndex = 1
        f.Parent = parent
        round(f, 2)
        parts[i] = { f = f, t = 0 }
    end
    local function respawn(p)
        p.t, p.life = 0, 3 + math.random() * 4
        p.x0 = math.random(0, w)
        p.speed = 10 + math.random() * 18
        p.sway = 4 + math.random() * 10
        p.phase = math.random() * 6.28
        p.size = 2 + math.random() * 2
        p.warm = math.random() < 0.25
        p.col = p.warm and C.red or COOL
    end
    for _, p in ipairs(parts) do respawn(p) p.t = math.random() * p.life end
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not parent.Parent then conn:Disconnect() return end
        dt = math.min(dt, 0.1)
        for _, p in ipairs(parts) do
            p.t = p.t + dt
            if p.t >= p.life then respawn(p) end
            local k = p.t / p.life
            local x = p.x0 + math.sin(p.phase + p.t * 1.4) * p.sway
            local y = h - p.speed * p.t
            local a = math.min(k / 0.15, 1) * (1 - math.max((k - 0.4) / 0.6, 0))
            p.f.Position = UDim2.fromOffset(x, y)
            p.f.BackgroundColor3 = p.col
            p.f.BackgroundTransparency = 1 - a * 0.5
            p.f.Visible = a > 0.02 and y > -10
        end
    end)
    return conn
end

local function copyDiscord()
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, DISCORD_URL)
        return ok
    end
    return false
end

-- Best-effort: ask Roblox to open the system browser on the invite link. If the person's OS/browser has
-- Discord's protocol registered, the browser itself offers to hand off to the Discord app from there.
-- GuiService:OpenBrowserWindow is a protected engine call Roblox normally reserves for itself, so whether
-- this works depends entirely on the executor - that's why it's wrapped in pcall and never assumed to work.
local function openDiscordApp()
    local launched = false
    pcall(function()
        local gs = game:GetService("GuiService")
        if gs and typeof(gs.OpenBrowserWindow) == "function" then
            gs:OpenBrowserWindow(DISCORD_URL)
            launched = true
        end
    end)
    return launched
end

local function popup(firstMessage, onKey)
    local gui = Instance.new("ScreenGui")
    gui.Name = "WORST_AUTH"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local parent
    pcall(function() if gethui then parent = gethui() end end)
    if not parent then
        local ok, core = pcall(function() return game:GetService("CoreGui") end)
        if ok then parent = core end
    end
    if not parent then parent = LocalPlayer:WaitForChild("PlayerGui") end
    local old = parent:FindFirstChild("WORST_AUTH")
    if old then old:Destroy() end
    gui.Parent = parent

    local POPUP_W, POPUP_H = 340, 400

    local main = Instance.new("CanvasGroup")
    main.Name = "Main"
    main.GroupTransparency = 1
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.Size = UDim2.fromOffset(POPUP_W, POPUP_H)
    main.BackgroundColor3 = C.bg
    main.BorderSizePixel = 0
    main.Parent = gui
    round(main, 22)   -- same rounding language as the hub's window (28) / panel (22), scaled down
    local mainStroke = outline(main, Color3.new(1, 1, 1))
    mainStroke.Thickness = 2
    local ashConn = ashBorder(mainStroke, 35)

    -- faint rising ash behind everything, same idea as the hub's background, far fewer particles
    local emberConn = emberField(main, POPUP_W, POPUP_H, 10)

    local scale = Instance.new("UIScale")
    scale.Parent = main
    local viewportConn
    local animating = true
    local function targetScale()
        local camera = workspace.CurrentCamera
        if not camera then return 1 end
        local v = camera.ViewportSize
        return math.max(0.45, math.min(1, (v.X - 24) / POPUP_W, (v.Y - 24) / POPUP_H))
    end
    scale.Scale = targetScale()
    local camera = workspace.CurrentCamera
    if camera then
        viewportConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if not animating then scale.Scale = targetScale() end
        end)
    end
    gui.Destroying:Connect(function()
        if viewportConn then viewportConn:Disconnect() end
        if ashConn then ashConn:Disconnect() end
        if emberConn then emberConn:Disconnect() end
    end)

    local header = Instance.new("Frame")
    header.ZIndex = 2
    header.Position = UDim2.fromOffset(14, 8)
    header.Size = UDim2.new(1, -28, 0, 46)
    header.BackgroundTransparency = 1
    header.Active = true
    header.Parent = main

    local logo = textLabel(header, "W", 22, Color3.new(1, 1, 1), true)
    logo.ZIndex = 2
    logo.Size = UDim2.fromOffset(34, 34)
    logo.TextXAlignment = Enum.TextXAlignment.Center
    local logoGrad = Instance.new("UIGradient")
    logoGrad.Color = ColorSequence.new(Color3.fromRGB(2, 2, 2), Color3.fromRGB(191, 191, 191))
    logoGrad.Rotation = 90
    logoGrad.Parent = logo

    local title = textLabel(header, 'WORST <font color="rgb(170,170,170)">AUTH</font>', 16, C.text, true)
    title.ZIndex = 2
    title.RichText = true
    title.Position = UDim2.fromOffset(44, -2)
    title.Size = UDim2.fromOffset(220, 22)
    local subtitle = textLabel(header, "SECURE SCRIPT ACCESS", 9, C.muted)
    subtitle.ZIndex = 2
    subtitle.Position = UDim2.fromOffset(45, 19)
    subtitle.Size = UDim2.fromOffset(220, 15)

    local close = button(header, "×", UDim2.new(1, -24, 0, 1), UDim2.fromOffset(24, 24), C.surface, C.muted)
    close.ZIndex = 2
    close.TextSize = 18
    close.MouseButton1Click:Connect(function() gui:Destroy() end)

    local divider = Instance.new("Frame")
    divider.ZIndex = 2
    divider.Position = UDim2.fromOffset(14, 60)
    divider.Size = UDim2.new(1, -28, 0, 1)
    divider.BorderSizePixel = 0
    divider.BackgroundColor3 = C.border
    divider.Parent = main

    -- circular ash badge, same construction as the hub's icon badges (gradient disc + glyph)
    local badge = Instance.new("Frame")
    badge.ZIndex = 2
    badge.AnchorPoint = Vector2.new(0.5, 0)
    badge.Position = UDim2.new(0.5, 0, 0, 74)
    badge.Size = UDim2.fromOffset(54, 54)
    badge.BackgroundColor3 = C.surface
    badge.BorderSizePixel = 0
    badge.Parent = main
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = badge
    end
    local badgeGrad = Instance.new("UIGradient")
    badgeGrad.Color = ColorSequence.new(Color3.fromRGB(51, 51, 51), Color3.fromRGB(33, 33, 33))
    badgeGrad.Rotation = 90
    badgeGrad.Parent = badge
    outline(badge, C.border)
    local badgeGlyph = textLabel(badge, "W", 20, C.text, true)
    badgeGlyph.ZIndex = 2
    badgeGlyph.Size = UDim2.fromScale(1, 1)
    badgeGlyph.TextXAlignment = Enum.TextXAlignment.Center

    local heading = textLabel(main, "Authentication Required", 17, C.text, true)
    heading.ZIndex = 2
    heading.Position = UDim2.fromOffset(14, 140)
    heading.Size = UDim2.new(1, -28, 0, 24)
    heading.TextXAlignment = Enum.TextXAlignment.Center
    local description = textLabel(main, "Enter your license key to unlock WORST Hub.", 11, C.muted)
    description.ZIndex = 2
    description.Position = UDim2.fromOffset(14, 164)
    description.Size = UDim2.new(1, -28, 0, 18)
    description.TextXAlignment = Enum.TextXAlignment.Center

    local keyLabel = textLabel(main, "LICENSE KEY", 10, C.text, true)
    keyLabel.ZIndex = 2
    keyLabel.Position = UDim2.fromOffset(22, 196)
    keyLabel.Size = UDim2.new(1, -44, 0, 16)

    local input = Instance.new("TextBox")
    input.ZIndex = 2
    input.Position = UDim2.fromOffset(22, 216)
    input.Size = UDim2.new(1, -44, 0, 40)
    input.BackgroundColor3 = C.surface
    input.BorderSizePixel = 0
    input.PlaceholderText = "WORST-XXXX-XXXX-XXXX"
    input.PlaceholderColor3 = C.muted
    input.Text = ""
    input.TextColor3 = C.text
    input.TextSize = 12
    input.Font = Enum.Font.Code
    input.ClearTextOnFocus = false
    input.Parent = main
    round(input, 9)
    outline(input, C.border)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = input

    local verify = button(main, "VERIFY KEY", UDim2.fromOffset(22, 266), UDim2.new(1, -44, 0, 40), C.accent, C.bg)
    verify.ZIndex = 2
    local discord = button(main, "JOIN DISCORD", UDim2.fromOffset(22, 314), UDim2.new(1, -44, 0, 40), C.surface, C.text)
    discord.ZIndex = 2
    outline(discord, C.border)

    local status = textLabel(main, "●  " .. (firstMessage or "Enter a key to continue"), 11, firstMessage and C.yellow or C.muted)
    status.ZIndex = 2
    status.Position = UDim2.fromOffset(22, 364)
    status.Size = UDim2.new(1, -44, 0, 24)
    status.TextWrapped = true
    status.TextTruncate = Enum.TextTruncate.AtEnd
    local function setStatus(message, color)
        if not gui.Parent then return end
        status.Text = "●  " .. tostring(message)
        status.TextColor3 = color or C.muted
    end

    -- "JOIN DISCORD": copies the invite AND tries to hand off straight to the Discord app at the same time.
    -- The hand-off is best-effort (see openDiscordApp above) so the status line always reflects what
    -- actually happened rather than promising something that may not work on every executor.
    discord.MouseButton1Click:Connect(function()
        local copied = copyDiscord()
        local launched = openDiscordApp()
        if copied and launched then
            setStatus("Invite copied - opening Discord...", C.green)
        elseif launched then
            setStatus("Opening Discord...", C.green)
        elseif copied then
            setStatus("Copied! Paste it in Discord: " .. DISCORD_URL, C.green)
        else
            setStatus("Couldn't copy or open automatically: " .. DISCORD_URL, C.yellow)
        end
    end)

    local busy = false
    local function showSuccess()
        -- Shrink and fade all panel contents together, keeping the panel intact.
        local content = {}
        for _, child in ipairs(main:GetChildren()) do
            if child:IsA("GuiObject") then
                table.insert(content, child)
            end
        end

        -- A UIScale on each root content object gives a smooth, unified exit.
        local shrinkTweens = {}
        for _, child in ipairs(content) do
            local contentScale = Instance.new("UIScale")
            contentScale.Name = "WORST_ExitScale"
            contentScale.Scale = 1
            contentScale.Parent = child
            local t = TweenService:Create(contentScale,
                TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
                {Scale = 0.15})
            table.insert(shrinkTweens, t)
            t:Play()
        end

        -- Fade the contents, but not the outer window.
        local fadeTweens = {}
        for _, child in ipairs(content) do
            local props = {}
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                props.TextTransparency = 1
            end
            if child.BackgroundTransparency < 1 then
                props.BackgroundTransparency = 1
            end
            if next(props) then
                local t = TweenService:Create(child,
                    TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), props)
                table.insert(fadeTweens, t)
                t:Play()
            end
            for _, descendant in ipairs(child:GetDescendants()) do
                if descendant:IsA("UIStroke") then
                    TweenService:Create(descendant,
                        TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                        {Transparency = 1}):Play()
                end
            end
        end

        task.wait(0.29)
        if not gui.Parent then return end
        for _, child in ipairs(content) do
            child.Visible = false
        end

        local checkmark = Instance.new("TextLabel")
        checkmark.Name = "SuccessCheckmark"
        checkmark.BackgroundTransparency = 1
        checkmark.AnchorPoint = Vector2.new(0.5, 0.5)
        checkmark.Position = UDim2.fromScale(0.5, 0.5)
        checkmark.Size = UDim2.fromOffset(180, 180)
        checkmark.Font = Enum.Font.GothamBold
        checkmark.Text = "✓"
        checkmark.TextColor3 = C.green
        checkmark.TextSize = 140
        checkmark.TextTransparency = 1
        checkmark.Parent = main

        local checkScale = Instance.new("UIScale")
        checkScale.Scale = 0.5
        checkScale.Parent = checkmark
        TweenService:Create(checkmark,
            TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 0}):Play()
        TweenService:Create(checkScale,
            TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1}):Play()

        task.wait(1)
        if gui.Parent then
            local fade = TweenService:Create(main,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {GroupTransparency = 1})
            fade:Play()
            fade.Completed:Wait()
            if gui.Parent then gui:Destroy() end
        end
    end

    -- Wrong key effect: UI grows a little + turns red + vibrates, typed letters vanish one by one,
    -- "Wrong Password" shows for 1 second, then everything goes back to normal.
    local function wrongKeyEffect()
        if not gui.Parent then return end
        local RED = Color3.fromRGB(255, 60, 60)
        local DARK_RED = Color3.fromRGB(45, 8, 8)
        local baseScale = targetScale()
        local basePos = main.Position
        local strokeGrad = mainStroke:FindFirstChildOfClass("UIGradient")

        local originalPlaceholder = input.PlaceholderText
        input.PlaceholderText = ""   -- so it can't overlap the "Wrong Password" text
        input.TextEditable = false
        input.ClearTextOnFocus = false
        input:ReleaseFocus()

        -- turn red (the shimmer gradient would tint over the stroke colour, so pause it)
        if strokeGrad then strokeGrad.Enabled = false end
        mainStroke.Color = Color3.new(1, 1, 1)
        TweenService:Create(mainStroke, TweenInfo.new(0.2), {Color = RED}):Play()
        TweenService:Create(main, TweenInfo.new(0.2), {BackgroundColor3 = DARK_RED}):Play()

        -- grow a little
        TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = baseScale * 1.06}):Play()

        -- vibrate (horizontal shake that settles)
        for i = 1, 10 do
            if not gui.Parent then return end
            local amp = 7 * (1 - (i - 1) / 10)
            local dir = (i % 2 == 0) and 1 or -1
            main.Position = UDim2.new(basePos.X.Scale, basePos.X.Offset + dir * amp,
                basePos.Y.Scale, basePos.Y.Offset)
            task.wait(0.035)
        end
        if not gui.Parent then return end
        main.Position = basePos

        -- every typed letter disappears, one by one
        local typed = input.Text
        local n = #typed
        if n > 0 then
            local delay = math.min(0.06, 0.6 / n)
            for i = n - 1, 0, -1 do
                if not gui.Parent then return end
                input.Text = typed:sub(1, i)
                task.wait(delay)
            end
        end

        -- "Wrong Password" appears
        local wrong = Instance.new("TextLabel")
        wrong.Name = "WrongPassword"
        wrong.ZIndex = 3
        wrong.BackgroundTransparency = 1
        wrong.Size = UDim2.fromScale(1, 1)
        wrong.Font = Enum.Font.GothamBold
        wrong.Text = "Wrong Password"
        wrong.TextSize = 13
        wrong.TextColor3 = RED
        wrong.TextXAlignment = Enum.TextXAlignment.Center
        wrong.Parent = input

        task.wait(1)
        if not gui.Parent then return end

        -- back to the original
        wrong:Destroy()
        TweenService:Create(mainStroke, TweenInfo.new(0.25), {Color = Color3.new(1, 1, 1)}):Play()
        TweenService:Create(main, TweenInfo.new(0.25), {BackgroundColor3 = C.bg}):Play()
        local back = TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Scale = baseScale})
        back:Play()
        back.Completed:Wait()
        if not gui.Parent then return end
        scale.Scale = targetScale()
        if strokeGrad then strokeGrad.Enabled = true end
        input.PlaceholderText = originalPlaceholder
        input.TextEditable = true
        setStatus("Enter a key to continue", C.muted)
    end

    local function submit()
        if busy then return end
        local key = input.Text:match("^%s*(.-)%s*$")
        if key == "" then
            setStatus("Please enter your license key.", C.red)
            return
        end
        busy = true
        verify.Text = "VERIFYING..."
        setStatus("Checking key with WORST server...", C.muted)
        task.spawn(function()
            local ok, err = pcall(onKey, key)
            if not gui.Parent then return end
            if not ok then
                setStatus("Verification error. Try again.", C.red)
            elseif err then
                setStatus(err, C.red)
                wrongKeyEffect()
                if not gui.Parent then return end
            else
                showSuccess()
                return
            end
            busy = false
            verify.Text = "VERIFY KEY"
        end)
    end
    verify.MouseButton1Click:Connect(submit)
    input.FocusLost:Connect(function(enter) if enter then submit() end end)

    -- Drag via the header (mouse or touch).
    local dragging, dragStart, initial, dragInput = false, nil, nil, nil
    header.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inputObject.Position
            initial = main.Position
            dragInput = inputObject
            inputObject.Changed:Connect(function()
                if inputObject.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    local dragConn = UIS.InputChanged:Connect(function(inputObject)
        if not dragging then return end
        if inputObject ~= dragInput and inputObject.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local delta = inputObject.Position - dragStart
        local factor = math.max(scale.Scale, 0.01)
        main.Position = UDim2.new(initial.X.Scale, initial.X.Offset + delta.X / factor,
            initial.Y.Scale, initial.Y.Offset + delta.Y / factor)
    end)
    gui.Destroying:Connect(function() dragConn:Disconnect() end)

    -- Fade in, overshoot larger than the final window, then settle.
    local goal = targetScale()
    scale.Scale = goal * 0.68
    main.GroupTransparency = 1
    local pop = TweenService:Create(scale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Scale = goal
    })
    local fade = TweenService:Create(main, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        GroupTransparency = 0
    })
    pop:Play()
    fade:Play()
    pop.Completed:Connect(function()
        animating = false
        if gui.Parent then scale.Scale = targetScale() end
    end)
end

local first = (getgenv and getgenv().Key) or readSaved()
if first then
    local data = check(tostring(first))
    if data then
        writeSaved(tostring(first))
        runScripts(data)
        listen(tostring(first))
        return
    end
end

popup(first and "Saved key invalid or expired. Join Discord." or nil, function(key)
    local data, err = check(key)
    if not data then return err end
    writeSaved(key)
    runScripts(data)
    listen(key)
    return nil
end)
