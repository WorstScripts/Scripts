-- WORST AUTH | Cloudflare Worker loader
local WORKER = "https://script-hub.worstasaiya.workers.dev"
local DISCORD_URL = "https://discord.gg/WFY7f6XAh7"
local SAVE_KEY = true
local KEY_FILE = "WorstKey.txt"

if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local C = {
    bg = Color3.fromRGB(12,14,23),
    surface = Color3.fromRGB(25,28,43),
    border = Color3.fromRGB(52,55,76),
    accent = Color3.fromRGB(167,139,250),
    text = Color3.fromRGB(244,245,255),
    muted = Color3.fromRGB(149,155,176),
    green = Color3.fromRGB(74,222,128),
    red = Color3.fromRGB(248,113,113),
    yellow = Color3.fromRGB(251,191,36)
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

local function copyDiscord()
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, DISCORD_URL)
        return ok
    end
    return false
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

    local main = Instance.new("CanvasGroup")
    main.Name = "Main"
    main.GroupTransparency = 1
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.Size = UDim2.fromOffset(390, 440)
    main.BackgroundColor3 = C.bg
    main.BorderSizePixel = 0
    main.Parent = gui
    round(main, 15)
    outline(main, C.border)

    local scale = Instance.new("UIScale")
    scale.Parent = main
    local viewportConn
    local animating = true
    local function targetScale()
        local camera = workspace.CurrentCamera
        if not camera then return 1 end
        local v = camera.ViewportSize
        return math.max(0.45, math.min(1, (v.X - 24) / 390, (v.Y - 24) / 440))
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
    end)

    local header = Instance.new("Frame")
    header.Position = UDim2.fromOffset(16, 10)
    header.Size = UDim2.new(1, -32, 0, 53)
    header.BackgroundTransparency = 1
    header.Active = true
    header.Parent = main

    local logo = textLabel(header, "◆", 27, C.accent, true)
    logo.Size = UDim2.fromOffset(30, 35)
    local title = textLabel(header, "WORST AUTH", 17, C.text, true)
    title.Position = UDim2.fromOffset(35, 0)
    title.Size = UDim2.fromOffset(230, 24)
    local subtitle = textLabel(header, "SECURE SCRIPT ACCESS", 10, C.muted)
    subtitle.Position = UDim2.fromOffset(36, 25)
    subtitle.Size = UDim2.fromOffset(230, 17)

    local close = button(header, "×", UDim2.new(1, -27, 0, 4), UDim2.fromOffset(27, 27), C.surface, C.muted)
    close.TextSize = 20
    close.MouseButton1Click:Connect(function() gui:Destroy() end)

    local divider = Instance.new("Frame")
    divider.Position = UDim2.fromOffset(16, 69)
    divider.Size = UDim2.new(1, -32, 0, 1)
    divider.BorderSizePixel = 0
    divider.BackgroundColor3 = C.border
    divider.Parent = main

    local shield = textLabel(main, "◆", 34, C.accent, true)
    shield.Size = UDim2.fromOffset(62, 62)
    shield.AnchorPoint = Vector2.new(0.5, 0)
    shield.Position = UDim2.new(0.5, 0, 0, 88)
    shield.BackgroundTransparency = 0
    shield.BackgroundColor3 = C.surface
    shield.TextXAlignment = Enum.TextXAlignment.Center
    round(shield, 31)

    local heading = textLabel(main, "Authentication Required", 19, C.text, true)
    heading.Position = UDim2.fromOffset(15, 163)
    heading.Size = UDim2.new(1, -30, 0, 27)
    heading.TextXAlignment = Enum.TextXAlignment.Center
    local description = textLabel(main, "Enter your license key to unlock WORST Hub.", 12, C.muted)
    description.Position = UDim2.fromOffset(15, 193)
    description.Size = UDim2.new(1, -30, 0, 20)
    description.TextXAlignment = Enum.TextXAlignment.Center

    local keyLabel = textLabel(main, "LICENSE KEY", 11, C.text, true)
    keyLabel.Position = UDim2.fromOffset(25, 227)
    keyLabel.Size = UDim2.new(1, -50, 0, 18)

    local input = Instance.new("TextBox")
    input.Position = UDim2.fromOffset(25, 250)
    input.Size = UDim2.new(1, -50, 0, 43)
    input.BackgroundColor3 = C.surface
    input.BorderSizePixel = 0
    input.PlaceholderText = "WORST-XXXX-XXXX-XXXX"
    input.PlaceholderColor3 = C.muted
    input.Text = ""
    input.TextColor3 = C.text
    input.TextSize = 13
    input.Font = Enum.Font.Code
    input.ClearTextOnFocus = false
    input.Parent = main
    round(input, 9)
    outline(input, C.border)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = input

    local verify = button(main, "VERIFY KEY", UDim2.fromOffset(25, 303), UDim2.new(1, -50, 0, 43), C.accent, C.bg)
    local discord = button(main, "COPY DISCORD INVITE", UDim2.fromOffset(25, 354), UDim2.new(1, -50, 0, 43), C.surface, C.text)
    outline(discord, C.border)

    local status = textLabel(main, "●  " .. (firstMessage or "Enter a key to continue"), 11, firstMessage and C.yellow or C.muted)
    status.Position = UDim2.fromOffset(25, 408)
    status.Size = UDim2.new(1, -50, 0, 25)
    status.TextWrapped = true
    status.TextTruncate = Enum.TextTruncate.AtEnd
    local function setStatus(message, color)
        if not gui.Parent then return end
        status.Text = "●  " .. tostring(message)
        status.TextColor3 = color or C.muted
    end

    discord.MouseButton1Click:Connect(function()
        if copyDiscord() then
            setStatus("Discord invite copied to clipboard!", C.green)
        else
            setStatus("Clipboard unavailable: " .. DISCORD_URL, C.yellow)
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
