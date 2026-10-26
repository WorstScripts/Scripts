-- Script hub loader. Shows an [Enter key] popup, checks the key with the Worker, then runs your enabled auto execute scripts.

local WORKER   = "https://script-hub.worstasaiya.workers.dev"
local SAVE_KEY = true  -- true: remember a correct key on this PC so it isn't asked every time. false: always ask.
local KEY_FILE = "scripthub_key.txt"

if not game:IsLoaded() then game.Loaded:Wait() end

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function send(url, body)
    local req = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    if not req then return nil, "This executor can't make web requests." end
    local ok, res = pcall(req, {
        Url = url, Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(body),
    })
    if not ok or type(res) ~= "table" then return nil, "Could not reach the server." end
    local decoded; pcall(function() decoded = HttpService:JSONDecode(res.Body) end)
    return decoded or {}, nil, res.StatusCode
end

local executor = "Unknown"
pcall(function() if identifyexecutor then executor = tostring((identifyexecutor())) end end)

-- Returns data on success, or nil plus a message to show.
local function check(key)
    local data, err, status = send(WORKER .. "/loader/run", {
        key = key, placeId = game.PlaceId, uid = LocalPlayer.UserId, executor = executor,
    })
    if not data then return nil, err end
    if status == 401 then return nil, data.error or "Join the discord server to get updates on the new key" end
    if not data.ok then return nil, data.error or "Something went wrong. Try again." end
    return data
end

local function runScripts(data)
    for _, s in ipairs(data.scripts or {}) do
        task.spawn(function()
            local fn, cerr = loadstring(s.code)
            if not fn then warn("[Script hub] " .. tostring(s.name) .. " failed to load: " .. tostring(cerr)) return end
            local ok, rerr = pcall(fn)
            if not ok then warn("[Script hub] " .. tostring(s.name) .. " errored: " .. tostring(rerr)) end
        end)
    end
end

-- Only for your own accounts: set getgenv().HubListen = true before the loadstring.
-- The account then checks the Worker every 10 seconds for scripts you pressed Run on.
local function listen(key)
    if not (getgenv and getgenv().HubListen) then return end
    task.spawn(function()
        local since = nil
        while true do
            local data, _, status = send(WORKER .. "/loader/poll", { key = key, since = since })
            if status == 401 then return end
            if data and data.ok then
                since = data.last
                if data.runs and #data.runs > 0 then runScripts({ scripts = data.runs }) end
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
local function writeSaved(k) if SAVE_KEY and writefile then pcall(writefile, KEY_FILE, k) end end

local function popup(firstMessage, onKey)
    local gui = Instance.new("ScreenGui")
    gui.Name = "ScriptHubKey"; gui.ResetOnSpawn = false; gui.DisplayOrder = 999
    local parent
    pcall(function() if gethui then parent = gethui() end end)
    gui.Parent = parent or game:GetService("CoreGui")

    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(320, 150); box.AnchorPoint = Vector2.new(0.5, 0.5); box.Position = UDim2.fromScale(0.5, 0.5)
    box.BackgroundColor3 = Color3.fromRGB(23, 28, 38); box.BorderSizePixel = 0; box.Parent = gui
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -24, 0, 24); title.Position = UDim2.fromOffset(12, 10); title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold; title.TextSize = 16; title.TextColor3 = Color3.fromRGB(233, 237, 244)
    title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = "Enter key"; title.Parent = box

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -24, 0, 34); input.Position = UDim2.fromOffset(12, 40)
    input.BackgroundColor3 = Color3.fromRGB(16, 19, 26); input.BorderSizePixel = 0; input.ClearTextOnFocus = false
    input.Font = Enum.Font.Gotham; input.TextSize = 14; input.TextColor3 = Color3.fromRGB(233, 237, 244)
    input.PlaceholderText = "Paste your key here"; input.Text = ""; input.Parent = box
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 8)

    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -24, 0, 34); msg.Position = UDim2.fromOffset(12, 78); msg.BackgroundTransparency = 1
    msg.Font = Enum.Font.Gotham; msg.TextSize = 12; msg.TextWrapped = true; msg.TextYAlignment = Enum.TextYAlignment.Top
    msg.TextXAlignment = Enum.TextXAlignment.Left; msg.TextColor3 = Color3.fromRGB(255, 138, 138); msg.Text = firstMessage or ""; msg.Parent = box

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 30); btn.Position = UDim2.fromOffset(12, 112)
    btn.BackgroundColor3 = Color3.fromRGB(169, 155, 255); btn.BorderSizePixel = 0; btn.AutoButtonColor = true
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.TextColor3 = Color3.fromRGB(20, 17, 43); btn.Text = "Submit"; btn.Parent = box
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local busy = false
    local function submit()
        local k = input.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if busy or k == "" then return end
        busy = true; btn.Text = "Checking..."; msg.TextColor3 = Color3.fromRGB(138, 149, 168); msg.Text = ""
        task.spawn(function()
            local err = onKey(k)
            if err then busy = false; btn.Text = "Submit"; msg.TextColor3 = Color3.fromRGB(255, 138, 138); msg.Text = err
            else gui:Destroy() end
        end)
    end
    btn.MouseButton1Click:Connect(submit)
    input.FocusLost:Connect(function(enter) if enter then submit() end end)
end

-- 1) a key set before the loadstring (getgenv().Key = "...") or saved from last time, 2) otherwise the popup
local first = (getgenv and getgenv().Key) or readSaved()
if first then
    local data = check(tostring(first))
    if data then writeSaved(tostring(first)) runScripts(data) listen(tostring(first)) return end
end

popup(first and "Join the discord server to get updates on the new key" or nil, function(key)
    local data, err = check(key)
    if not data then return err end
    writeSaved(key); runScripts(data); listen(key)
    return nil
end)
