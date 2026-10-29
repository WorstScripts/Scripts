--// =====================================================================================================
--// If any changes were to be made on this file, list it down:
--//
--// 1. Renamed the Farming page "Auto Delete" to "Delete Hatches".
--// 2. Renamed the Pets page "Auto Delete" to "Delete Pets".
--// 3. Added the Miscellaneous tab (above Settings): Hop Different Server, Rejoin Same Server, Join Job ID (input),
--//    Join Low Player Server, Walk Speed + Jump Power sliders.
--// 4. Settings pages renamed: "Page 1" -> "General", "Page 2" -> "Ui" (old saved configs still load via ID_ALIAS).
--// 5. Moved "Animated Background" and "Minimize Keybind" from General to the Ui page.
--// 6. Removed Auto Mine from Events (the page and its code).
--// 7. Auto Balloons: only targets the balloon closest to you within 500 studs (further ones are ignored) and
--//    teleports to it every 0.2 s so you stay on it.
--// 8. Added explanatory comments above every function and every toggle (comments only, no code changed).
--// 9. Trade list scanning (selectPets / scrollList): waits for the list to finish building its cards after every scroll,
--//    scrolls half a window at a time, waits at the "bottom" before giving up, and scans the whole list a second time
--//    before reporting "found only X of Y" (fix for Diamond cards not being found).
--// 10. Added Golden/Diamond pet-per-craft selectors using the existing MachineService requests.
--// 11. Kaitun Stats now assigns distinct pets to Four-Leaf x2, Secret Hunter x2, and Lucky III for extras.
--// 12. Kaitun Stats prioritizes Luck/Gems affinity, Legendary+ rarity and preserves a matching slot.
--// 13. Renamed "Kaitun Enchant" to "Kaitun Stats" (old saved configs still load via ID_ALIAS).
--// 14. Kaitun Hatch no longer touches your pets: Auto Equip (Luckiest while hatching, Richest right before each rebirth) and
--//     Auto Rebirth moved from Kaitun Hatch to Kaitun Stats (Kaitun Stats still needs Kaitun Hatch to be running).
--// 15. Added "Enchant V2" (Pets > Enchanting, under Auto Enchant) + "Enchant V2 Pets" dropdown (every Mythical+ pet in the game, multi select, no amounts).
--//     Watches for Rainbow copies of the ticked pets (new hatches / finished crafts / ones you already own) and rolls them for the Target Enchants.
--//     V2 has priority over Auto Enchant: the normal run finishes its current pet and then waits while V2 has work.
--// 17. Trade (giver): when no card with the wanted pet name shows up in two full looks at the trade list, a third look is taken after a 4 s wait.
--//     The "found only X of Y" message now also lists the pet names / tiers the list really held, the cards whose name could not be read and how many looks were taken.
--// 16. Every dropdown now has a search box at the top of its menu (type letters, only options containing them stay; on a PC it is focused automatically).
--//     Enchant V2 Pets got an "Auto (every Mythical+ Rainbow)" option that enchants any Rainbow pet of Mythical rarity or higher.
--// 18. Trade (giver): the pets are now put into the offer with the game's own Offer request (pet ids from the pet data), the same way Auto Trade (Pay First) does,
--//     instead of scrolling the trade window and clicking cards. The server's echo is checked (other copies are tried if it does not show the pets).
--//     Only if that fails does the old card-clicking method run, so nothing gets worse (fix for "found only 0 of 5 ... list has 44 cards, 0 named ...").
--// =====================================================================================================
--// WORST Hub - Auto Hatch (Hatch tab) + Auto Craft (Pets tab)
--// Execute as a normal script. Executing again closes the previous instance first.
--// Hatch tab    : "Egg to Hatch" dropdown + "Auto Hatch" toggle (travels to that egg's island, teleports to its spot, hatches it)
--// Pets tab     : two pages (buttons at the top of the tab)
--//                  [Settings]    "Auto Scan Inventory" toggle (on by default) -> reads your pets from the game's data every 3 minutes; the inventory is never opened
--//                  [Crafting]    (the pet lists below are filled by that scan)
--//                                "Craft When Storage Is" slider -> Golden crafts only start once your pet storage is at least this full (Diamond/Rainbow ignore it)
--//                                "Pet to Craft" + "Auto Craft"      -> Normal -> Golden (Golden Machine, 6 pets) - pick a pet or "All pets"
--//                                "Diamond Pet" + "Craft to Diamond" -> Golden -> Diamond (Diamond Machine in Crystal Cave, 5 pets)
--//                                "Rainbow Pet" + "Craft to Rainbow" -> Diamond -> Rainbow (Shiny Machine in Shadow Realm, 2 pets, takes 5 hours)
--//                                "Collect Rainbow"                  -> claims finished Rainbow crafts
--//                                Every auto feature first checks that the inventory is CLOSED (and waits / closes it if not) and only one
--//                                feature travels at a time (auto hatch is paused for the trip and resumed afterwards).
--//                  [Placeholder] empty page for later
--// Kaitun tab   : two toggles only. "Kaitun Hatch" = MASTER toggle: switches every other feature toggle off and runs auto delete Common-Legendary, auto hatch the latest detected egg,
--//                  auto craft (Golden at the "Craft When Storage Is" slider, which shows up under it while it is on, + Diamond/Rainbow) + collect, Anti AFK, Auto Rejoin, Show Status (Priority tab order),
--//                  Kaitun Hatch does NOT touch your pets: Auto Rebirth (Best) and Auto Equip (Luckiest while hatching, Richest right before each rebirth) are run by "Kaitun Stats" (needs Kaitun Hatch), together with the enchanting.
--//                  "Kaitun Events" = switches Auto Chest Coins, Auto Trick or Treat, Auto Kill Hallow Boss and Auto Purchase Items (shop checked once an hour, Buy All)
--//                  on by itself and shows live numbers. The window and the tabs never change.
--// Events tab   : page [General] -> "Auto Claim Lucky Ducky"; page [Halloween] -> "Auto Halloween Trick or Treat" (travels to the Halloween island, jumps in each house's circle, waits for the houses to refill, repeats); one lap per 4-hour refill with a countdown; "Auto Kill Boss" (Hallow Lord) and "Auto Purchase Items" (+ Items to Buy dropdown)
--// Events tab   : page [Balloons] -> "Auto Balloons" (teleports to each balloon of the Balloon Party and pops it, then goes back; Kaitun Hatch/Events no longer switch it on)
--//                  page [Dig] -> "Auto Dig" (Autumn dig spot, hits the timing bar by itself, max 10 digs per hour; Kaitun Hatch/Events no longer switch it on)
--// Trade tab    : "Choose Pets" dropdown ("+  pet  -" rows: left click = +1, right click = -1, + / - buttons for touch) + "Tokens They Must Pay" + "Auto Trade (Pay First)" -> accepts requests, offers exactly those pets and only Locks / Confirms once the other player's offer reaches the amount
--// Priority tab : Double Jump first; Craft, Auto Balloons, Auto Trick or Treat, Auto Kill Hallow Lord, Auto Dig and Hatch (saved in WORST/priority.txt)
--// LITE MODE   : (automatic switching is OFF: AUTO_LITE = false near the end of the file. The Mini Ui only opens from Settings > Mini Ui.) Old behaviour: if nothing was toggled by hand since execute and the hub is left alone for 60 s, an "Are you afk?" popup shows; ignore it for another 60 s and the
--//                  main window closes and a small window (Kaitun Hatch + Kaitun Stats switched on; Kaitun Events is yours to switch on) opens. Times: IDLE_SECS / AFK_SECS near the end of the file.
--// Settings tab : two pages (General / Ui). Ui = Animated Background, Minimize Keybind, Auto Save Configuration, Show Status, Auto Rejoin, Anti AFK, Save Configuration, Configuration List,
--//                  FPS Cap; General = everything else. "Reset Script" is a button at the top right of the tab.
--//                  "Minimize Keybind" -> click it, press any key, that key now minimizes / restores the hub (default Left Ctrl)
--//                  "FPS Cap" slider -> limits your FPS (Off = no limit, needs setfpscap). While the small Lite window is open the cap is forced to 5 FPS
--//                  and the slider value is put back when you return to the full UI. Normal Kaitun (full UI) only uses the slider.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

------------------------------------------------------------------ RECORD SYSTEM
local env = (typeof(getgenv) == "function" and getgenv()) or _G
local previous = env.WORSTHubRecord

local alive = true
local gui                  -- the ScreenGui (assigned below)
local connections = {}     -- every global connection, disconnected on close
local cleanupHooks = {}    -- functions run on close (toggles switch themselves off here)

-- Connects a signal and remembers the connection so it gets disconnected when the hub is unloaded.
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

-- Unloads the hub: stops every feature, disconnects everything and destroys the UI.
local function cleanup()
	if not alive then return end
	alive = false
	for _, hook in ipairs(cleanupHooks) do pcall(hook) end
	for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
	if gui then pcall(function() gui:Destroy() end) end
end

local record = {
	runs = previous and ((previous.runs or 1) + 1) or 1,
	firstRun = previous and previous.firstRun or os.time(),
	lastRun = os.time(),
	cleanup = cleanup,
}

if previous then
	print(("[WORST Hub] Already executed (run #%d). Closing the previous instance..."):format(record.runs))
	if typeof(previous.cleanup) == "function" then pcall(previous.cleanup) end
else
	print("[WORST Hub] First execution (run #1).")
end
env.WORSTHubRecord = record

-- also close the old standalone panels if they are still running
for _, name in ipairs({ "HatchCraftPanel", "VolcanoHatchPanel", "GoldenCraftPanel" }) do
	local old = env[name]
	if old and old.destroy then pcall(old.destroy) end
end

-- safety net: remove any leftover UI from a hub that didn't register itself
for _, parent in ipairs({
	player:WaitForChild("PlayerGui"),
	(typeof(gethui) == "function" and gethui()) or nil,
	(function() local ok, cg = pcall(function() return game:GetService("CoreGui") end) return ok and cg or nil end)(),
}) do
	local old = parent and parent:FindFirstChild("WORSTHubUI")
	if old then pcall(function() old:Destroy() end) end
end

-- True if this input is a left mouse button press.
local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

-- True if this input is mouse movement.
local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

-- Optional: paste Roblox image asset ids ("rbxassetid://123") to replace glyph icons.
local ICON_IMAGES = {
	logo = "", home = "", egg = "", character = "", esp = "", server = "", webhook = "", settings = "",
	autoSteal = "", autoReturn = "", treadmill = "", upgrade = "", flight = "", antiTrap = "", bolt = "",
}

local WINDOW_W, WINDOW_H = 1435, 869
local DEFAULT_TAB = "Home"

-- how see-through the cards / rows are (0 = solid, 1 = invisible). Raise it to show more of the background.
local CARD_T = 0.7   -- how see-through the cards / rows are (0 = solid, 1 = invisible): higher shows more of the animated background

-- Colors
local C = {
	window    = Color3.fromRGB(8, 8, 8),
	panel     = Color3.fromRGB(11, 11, 11),
	card      = Color3.fromRGB(14, 14, 14),
	stroke    = Color3.fromRGB(105, 105, 105),
	text      = Color3.fromRGB(242, 242, 242),
	sub       = Color3.fromRGB(150, 150, 150),
	accent    = Color3.fromRGB(120, 120, 120),
	iconBg    = Color3.fromRGB(36, 36, 36),
	iconFg    = Color3.fromRGB(205, 205, 205),
	green     = Color3.fromRGB(90, 90, 90),
	greenText = Color3.fromRGB(225, 225, 225),
	cyan      = Color3.fromRGB(210, 210, 210),
}

-- Creates an Instance of `class`, applies the `props` table to it and parents it.
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

-- Adds rounded corners (UICorner) to a GUI object.
local function corner(parent, r)
	return new("UICorner", { CornerRadius = r or UDim.new(0, 8) }, parent)
end

-- Adds an outline (UIStroke) to a GUI object.
local function stroke(parent, color, thickness, transparency)
	return new("UIStroke", {
		Color = color or C.stroke, Thickness = thickness or 1,
		Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

-- Creates a Frame at x,y with size w,h, a colour and a transparency.
local function frame(parent, x, y, w, h, color, transparency)
	return new("Frame", {
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = color or C.card, BackgroundTransparency = transparency or 0,
		BorderSizePixel = 0,
	}, parent)
end

-- Text label whose (x, y) is the left-center point
local function label(parent, text, x, y, size, color, font, align)
	align = align or Enum.TextXAlignment.Left
	local anchorX = align == Enum.TextXAlignment.Left and 0 or (align == Enum.TextXAlignment.Center and 0.5 or 1)
	return new("TextLabel", {
		AnchorPoint = Vector2.new(anchorX, 0.5),
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(700, size + 8),
		BackgroundTransparency = 1, Text = text, RichText = true,
		TextColor3 = color or C.text, TextSize = size, Font = font or Enum.Font.Gotham,
		TextXAlignment = align, TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
end

-- Glyph or image icon centered at (cx, cy)
local function icon(parent, key, glyph, cx, cy, size, color)
	local id = ICON_IMAGES[key]
	if id and id ~= "" then
		return new("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
			Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, Image = id,
			ImageColor3 = color or Color3.new(1, 1, 1),
		}, parent)
	end
	return new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
		Size = UDim2.fromOffset(size * 1.6, size * 1.6), BackgroundTransparency = 1,
		Text = glyph, TextColor3 = color or C.iconFg, TextSize = size, Font = Enum.Font.GothamBold,
	}, parent)
end

-- Recolours a sidebar icon, whatever kind it is (image, frame or text).
local function setIconColor(ic, color)
	if ic:IsA("ImageLabel") then ic.ImageColor3 = color
	elseif ic:IsA("Frame") then ic.BackgroundColor3 = color
	else ic.TextColor3 = color end
end

-- shape icons (no font glyph needed): "egg" and "diamond"
local function shapeIcon(parent, kind, cx, cy, color)
	local f
	if kind == "egg" then
		f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
			Size = UDim2.fromOffset(18, 24), BackgroundColor3 = color, BorderSizePixel = 0 }, parent)
		corner(f, UDim.new(0.5, 0))
	else
		f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
			Size = UDim2.fromOffset(18, 18), Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0 }, parent)
		corner(f, UDim.new(0, 3))
	end
	return f
end

-- Round icon badge (circle) with glyph
local function badge(parent, key, glyph, cx, cy, d)
	local b = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
		Size = UDim2.fromOffset(d, d), BackgroundColor3 = C.iconBg, BorderSizePixel = 0,
	}, parent)
	corner(b, UDim.new(1, 0))
	new("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(51, 51, 51), Color3.fromRGB(33, 33, 33)),
		Rotation = 90,
	}, b)
	icon(b, key, glyph, d / 2, d / 2, d * 0.46, C.iconFg)
	return b
end

-- Draws a small check-mark shape at cx,cy.
local function check(parent, cx, cy)
	local c = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
		Size = UDim2.fromOffset(26, 26), BackgroundColor3 = C.green, BorderSizePixel = 0,
	}, parent)
	corner(c, UDim.new(1, 0))
	new("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "✓",
		TextColor3 = Color3.new(1, 1, 1), TextSize = 17, Font = Enum.Font.GothamBold,
	}, c)
end

------------------------------------------------------------------ ScreenGui
gui = new("ScreenGui", {
	Name = "WORSTHubUI", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 2147483647, -- highest possible: above the game's HUD AND its forced-event / cutscene screens
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

-- Where the hub lives. The game hides its own screens (forced events, cutscenes) by disabling / clearing PlayerGui, which also
-- hid the hub. gethui() / CoreGui are outside of PlayerGui, so the game can't touch it there. PlayerGui is only the last fallback.
do
	-- Tries to put the hub's ScreenGui into a parent (gethui / CoreGui / PlayerGui); false if that parent is not allowed.
	local function tryParent(p)
		if not p then return false end
		local ok = pcall(function() gui.Parent = p end)
		return ok and gui.Parent == p
	end
	local hui = (typeof(gethui) == "function") and select(2, pcall(gethui)) or nil
	local okCG, coreGui = pcall(function() return game:GetService("CoreGui") end)
	if not (tryParent(hui) or tryParent(okCG and coreGui or nil)) then
		if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then pcall(syn.protect_gui, gui) end
		gui.Parent = player:WaitForChild("PlayerGui")
	end
	record.guiHome = gui.Parent

	-- watchdog: whatever switches the hub off or moves it away (and is not the hub itself) is undone straight away
	connect(gui:GetPropertyChangedSignal("Enabled"), function()
		if alive and not gui.Enabled and not record.guiSuspended then gui.Enabled = true end
	end)
	connect(gui:GetPropertyChangedSignal("DisplayOrder"), function()
		if alive and gui.DisplayOrder ~= 2147483647 then gui.DisplayOrder = 2147483647 end
	end)
	connect(gui:GetPropertyChangedSignal("Parent"), function()
		if alive and gui.Parent ~= record.guiHome and record.guiHome and record.guiHome.Parent then
			pcall(function() gui.Parent = record.guiHome end)
		end
	end)
	task.spawn(function()
		while alive do
			task.wait(0.5)
			if gui.Parent ~= record.guiHome and record.guiHome and record.guiHome.Parent then pcall(function() gui.Parent = record.guiHome end) end
			if not gui.Enabled and not record.guiSuspended then gui.Enabled = true end
		end
	end)
end

local window = new("Frame", {
	AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromOffset(WINDOW_W, WINDOW_H), BackgroundColor3 = C.window,
	BorderSizePixel = 0, ClipsDescendants = true,
}, gui)
corner(window, UDim.new(0, 28))
new("UIGradient", {
	Name = "ShimmerGradient",
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 35)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(215, 215, 215)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 35)),
	}),
}, stroke(window, Color3.fromRGB(200, 200, 200), 2))

-- Initial fit + centering (after this, the user controls scale/position)
local uiScale = new("UIScale", {}, window)
do
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	uiScale.Scale = math.min(vp.X * 0.85 / WINDOW_W, vp.Y * 0.85 / WINDOW_H)
	window.Position = UDim2.fromOffset(
		(vp.X - WINDOW_W * uiScale.Scale) / 2,
		(vp.Y - WINDOW_H * uiScale.Scale) / 2
	)
end

------------------------------------------------------------------ Title bar
local logo = label(window, "W", 56, 52, 78, Color3.new(1, 1, 1), Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
logo.Size = UDim2.fromOffset(90, 90)
new("UIGradient", {
	Color = ColorSequence.new(Color3.fromRGB(2, 2, 2), Color3.fromRGB(191, 191, 191)),
	Rotation = 90,
}, logo)
icon(window, "logo", "", 56, 52, 60) -- only shows if an image id is set

label(window, 'WORST •<font color="rgb(170,170,170)">Tap Simulator</font>', 108, 39, 33, C.text, Enum.Font.GothamBold)
label(window, "by Asaiya", 108, 72, 19, C.sub, Enum.Font.Gotham)

local minLabel = label(window, "—", 1347, 37, 20, C.text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
minLabel.Size = UDim2.fromOffset(40, 30)
local closeLabel = label(window, "X", 1403, 37, 22, C.text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
closeLabel.Size = UDim2.fromOffset(40, 30)

------------------------------------------------------------------ SPINNING ASH BORDER (same look as the outer window ring)
local ashStroke
do
	local list = {}
	-- gives a UIStroke a blackish-ash gradient with a light ash glow that orbits around it.
	-- opts: speed (degrees / second, default 60), dir (1 or -1), paused.  Returns the stroke and a handle
	-- { rot, speed, stopAt, onDone, paused } so callers can make it finish a lap and stop.
	ashStroke = function(st, opts)
		opts = opts or {}
		st.Color = Color3.new(1, 1, 1)
		local g = new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(38, 38, 38)),
				ColorSequenceKeypoint.new(0.30, Color3.fromRGB(48, 48, 48)),
				ColorSequenceKeypoint.new(0.46, Color3.fromRGB(125, 125, 125)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(235, 235, 235)),
				ColorSequenceKeypoint.new(0.54, Color3.fromRGB(125, 125, 125)),
				ColorSequenceKeypoint.new(0.70, Color3.fromRGB(48, 48, 48)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(38, 38, 38)),
			}),
		}, st)
		local e = { g = g, rot = math.random() * 360, speed = opts.speed or 60, dir = opts.dir or 1, paused = opts.paused == true }
		table.insert(list, e)
		return st, e
	end
	connect(game:GetService("RunService").Heartbeat, function(dt)
		if not window.Visible then return end
		dt = math.min(dt, 0.1)
		for _, e in ipairs(list) do
			if e.g.Parent and not e.paused then
				e.rot = e.rot + dt * e.speed * e.dir
				e.g.Rotation = e.rot % 360
				if e.stopAt and e.rot >= e.stopAt then
					e.stopAt = nil
					if e.onDone then e.onDone() end
				end
			end
		end
	end)
end

------------------------------------------------------------------ Main panel background
local panel = frame(window, 295, 77, 1122, 774, C.panel)
corner(panel, UDim.new(0, 22))
ashStroke(stroke(panel, Color3.new(1, 1, 1), 3, 0.05))


------------------------------------------------------------------ Ash / ember effects (UI background + minimized bubble)
local FX = { bg = true }   -- Settings > Animated Background switches the window part
local newEmitter = (function()
	local RunService = game:GetService("RunService")
	local rand = function(a, b) return a + math.random() * (b - a) end
	local COOL = Color3.fromRGB(110, 110, 110)
	-- cfg: count, parent, z, spawn() -> x, y, speed {min,max}, life {min,max}, size {min,max}, drift, sway {min,max},
	--      warm (chance of a glowing ember), maxAlpha, topFade (px from the top where particles fade out)
	return function(cfg)
		local parts = {}
		for i = 1, cfg.count do
			local f = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0,
				Size = UDim2.fromOffset(3, 3), ZIndex = cfg.z or 1, Visible = false,
			}, cfg.parent)
			corner(f, UDim.new(1, 0))
			parts[i] = { f = f, t = 0, life = 1 }
		end
		-- Resets one ash / ember particle (new lifetime and start position).
		local function respawn(p, initial)
			p.life = rand(cfg.life[1], cfg.life[2])
			p.t = initial and rand(0, p.life) or 0
			p.x0, p.y0 = cfg.spawn()
			p.speed = rand(cfg.speed[1], cfg.speed[2])
			p.drift = rand(-cfg.drift, cfg.drift)
			p.phase = rand(0, 6.28)
			p.sway = rand(cfg.sway[1], cfg.sway[2])
			p.size = rand(cfg.size[1], cfg.size[2])
			p.warm = math.random() < cfg.warm
			local g = math.floor(rand(175, 255))
			p.col = p.warm and Color3.fromRGB(255, math.floor(rand(135, 190)), math.floor(rand(70, 110))) or Color3.fromRGB(g, g, g)
		end
		for _, p in ipairs(parts) do respawn(p, true) end
		return function(dt)
			for _, p in ipairs(parts) do
				p.t = p.t + dt
				if p.t >= p.life then respawn(p, false) end
				local k = p.t / p.life
				local x = p.x0 + p.drift * p.t + math.sin(p.phase + p.t * 1.4) * p.sway
				local y = p.y0 - p.speed * p.t
				local a = math.min(k / 0.12, 1) * (1 - math.max((k - 0.35) / 0.65, 0))
				if cfg.topFade then a = a * math.clamp((y - cfg.topFade) / 160, 0, 1) end
				local f = p.f
				f.Position = UDim2.fromOffset(x, y)
				local sz = p.size * (1 - 0.45 * k)
				f.Size = UDim2.fromOffset(sz, sz)
				f.BackgroundColor3 = p.warm and p.col:Lerp(COOL, math.min(k * 1.6, 1)) or p.col
				f.BackgroundTransparency = 1 - a * cfg.maxAlpha * (FX.introA or 1)
				f.Visible = a > 0.01
			end
		end
	end
end)()

-- the window's own background: slow rising ash + a soft glow along the bottom
do
	local layer = new("Frame", {
		Name = "AshLayer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ClipsDescendants = true, ZIndex = 1,
	}, window)
	FX.layer = layer

	local glow = new("Frame", {
		Position = UDim2.fromOffset(0, WINDOW_H - 300), Size = UDim2.fromOffset(WINDOW_W, 300),
		BackgroundColor3 = Color3.fromRGB(230, 230, 230), BackgroundTransparency = 0.93, BorderSizePixel = 0, ZIndex = 1,
	}, layer)
	corner(glow, UDim.new(0, 28))
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
	}, glow)

	local step = newEmitter({
		count = 30, parent = layer, z = 1, maxAlpha = 0.55, warm = 0.12, drift = 5, topFade = 90,
		speed = { 26, 62 }, life = { 8, 15 }, size = { 2, 5 }, sway = { 6, 22 },
		spawn = function() return math.random(0, WINDOW_W), math.random(math.floor(WINDOW_H * 0.55), WINDOW_H + 12) end,
	})

	local clock = 0
	connect(game:GetService("RunService").Heartbeat, function(dt)
		if not (FX.bg and window.Visible) then return end
		dt = math.min(dt, 0.1)
		clock = clock + dt
		step(dt)
		-- the glow breathes between cool white and a faint warm tint
		local pulse = math.sin(clock * 0.6) * 0.5 + 0.5
		glow.BackgroundTransparency = 1 - (1 - (0.95 - pulse * 0.04)) * (FX.introA or 1)
		glow.BackgroundColor3 = Color3.fromRGB(235, 235, 235):Lerp(Color3.fromRGB(255, 175, 120), (math.sin(clock * 0.23) * 0.5 + 0.5) * 0.45)
	end)
end


------------------------------------------------------------------ FLAME BURST (click effect for buttons / toggles / sliders / tabs)
-- Press anything and a short burst of ash + ember sparks rises from it, with a soft flash ring.
-- Tweak: FLAME.warm = 0 for pure black/white/ash, raise it for more orange embers.
local flame
do
local FLAME = { enabled = true, warm = 0.18, sparks = 14, maxLive = 140 }
local flameLayer = new("Frame", {
	Name = "FlameLayer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 500,
}, gui)
local flameLive = 0
-- Random decimal number between a and b.
local function frand(a, b) return a + math.random() * (b - a) end

-- obj: the GuiObject that was pressed.  power: 0.5 small .. 2 big.  rising: false = ash falls/drifts down (toggle off)
function flame(obj, power, rising)
	if not (FLAME.enabled and alive and obj and obj.Parent and window.Visible) then return end
	do -- a control on a hidden page has a stale position: its sparks would pop up in random places
		local p = obj
		while p and p ~= gui do
			if p:IsA("GuiObject") and not p.Visible then return end
			p = p.Parent
		end
	end
	power = power or 1
	rising = rising ~= false
	local pos, size = obj.AbsolutePosition, obj.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then return end
	local cx, cy = pos.X + size.X / 2, pos.Y + size.Y / 2
	local scale = (uiScale and uiScale.Scale) or 1

	-- soft flash ring that matches the control's shape
	local ring = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
		Size = UDim2.fromOffset(size.X, size.Y), BackgroundColor3 = Color3.fromRGB(235, 235, 235),
		BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = 500,
	}, flameLayer)
	local rc = obj:FindFirstChildOfClass("UICorner")
	corner(ring, rc and rc.CornerRadius or UDim.new(0, 12))
	local rs = stroke(ring, Color3.fromRGB(255, 255, 255), 2, 0.2)
	local info = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, {
		Size = UDim2.fromOffset(size.X + 26 * scale, size.Y + 26 * scale), BackgroundTransparency = 1,
	}):Play()
	TweenService:Create(rs, info, { Transparency = 1 }):Play()
	task.delay(0.5, function() ring:Destroy() end)

	-- sparks / ash
	local n = math.floor(FLAME.sparks * power)
	for _ = 1, n do
		if flameLive >= FLAME.maxLive then break end
		flameLive += 1
		local warm = math.random() < FLAME.warm
		local g = math.floor(frand(190, 255))
		local startCol = warm and Color3.fromRGB(255, math.floor(frand(170, 215)), math.floor(frand(110, 150))) or Color3.fromRGB(g, g, g)
		local endCol = warm and Color3.fromRGB(150, 70, 40) or Color3.fromRGB(70, 70, 70)
		local sz = frand(3, 8) * (0.8 + power * 0.2)
		local sx = cx + frand(-size.X * 0.42, size.X * 0.42)
		local sy = cy + frand(-size.Y * 0.2, size.Y * 0.3)
		local sp = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(sx, sy), Size = UDim2.fromOffset(sz, sz),
			BackgroundColor3 = startCol, BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 501,
			Rotation = math.random(0, 90),
		}, flameLayer)
		corner(sp, UDim.new(math.random() < 0.5 and 1 or 0.3, 0))
		local rise = frand(40, 110) * power * scale * (rising and -1 or 0.55)
		local drift = frand(-34, 34) * scale
		local life = frand(0.45, 0.95)
		-- flames lick upward and wobble: ease out on the rise, shrink + fade as they cool
		TweenService:Create(sp, TweenInfo.new(life, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(sx + drift, sy + rise),
			Rotation = sp.Rotation + frand(-140, 140),
		}):Play()
		TweenService:Create(sp, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.fromOffset(sz * 0.2, sz * 0.2), BackgroundTransparency = 1, BackgroundColor3 = endCol,
		}):Play()
		task.delay(life + 0.05, function() sp:Destroy(); flameLive -= 1 end)
	end
end
end

do -- slowly sweeping ash-colored shimmer around the window border
	local rot = 0
	local grad
	for _, ch in ipairs(window:GetChildren()) do
		if ch:IsA("UIStroke") and ch:FindFirstChild("ShimmerGradient") then grad = ch.ShimmerGradient end
	end
	connect(game:GetService("RunService").Heartbeat, function(dt)
		if not (grad and window.Visible) then return end
		rot = (rot + dt * 28) % 360
		grad.Rotation = rot
	end)
end

do -- dark ash border (as thick as the gap around the sidebar) with a light ash glow spinning around it
	local T = 14                                   -- ring thickness in pixels
	local rim = new("Frame", {
		Name = "AshRim", Position = UDim2.fromOffset(T, T), Size = UDim2.fromOffset(WINDOW_W - T * 2, WINDOW_H - T * 2),
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 90, Active = false,
	}, window)
	corner(rim, UDim.new(0, 28 - T))               -- stroke grows outward, so the outer edge ends up 28 px round
	-- the blackish ash ring itself (spinning highlight is its gradient)
	local ringStroke = new("UIStroke", {
		Color = Color3.new(1, 1, 1), Thickness = T, Transparency = 0.04,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, rim)
	local grad = new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(22, 22, 22)),
			ColorSequenceKeypoint.new(0.30, Color3.fromRGB(30, 30, 30)),
			ColorSequenceKeypoint.new(0.46, Color3.fromRGB(120, 120, 120)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(235, 235, 235)),
			ColorSequenceKeypoint.new(0.54, Color3.fromRGB(120, 120, 120)),
			ColorSequenceKeypoint.new(0.70, Color3.fromRGB(30, 30, 30)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(22, 22, 22)),
		}),
	}, ringStroke)
	-- a second, softer light going the other way so the border always feels alive
	local grad2Holder = new("Frame", {
		Name = "AshRim2", Position = UDim2.fromOffset(T, T), Size = UDim2.fromOffset(WINDOW_W - T * 2, WINDOW_H - T * 2),
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 91, Active = false,
	}, window)
	corner(grad2Holder, UDim.new(0, 28 - T))
	local stroke2 = new("UIStroke", {
		Color = Color3.new(1, 1, 1), Thickness = 3, Transparency = 0.2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, grad2Holder)
	local grad2 = new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(30, 30, 30)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190, 190, 190)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(30, 30, 30)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.0, 1), NumberSequenceKeypoint.new(0.35, 1),
			NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.65, 1), NumberSequenceKeypoint.new(1.0, 1),
		}),
	}, stroke2)
	local r1, r2 = 0, 0
	connect(game:GetService("RunService").Heartbeat, function(dt)
		if not window.Visible then return end
		r1 = (r1 + dt * 70) % 360
		r2 = (r2 - dt * 45) % 360
		grad.Rotation = r1
		grad2.Rotation = r2
	end)
end

------------------------------------------------------------------ Tabs / pages
local navItems = {
	{ "Home",          "home",      "⌂", 135 },
	{ "Kaitun",        "egg",       "⚡", 199 },
	{ "Farming",       "character", "◎", 257 },
	{ "Pets",          "esp",       "◉", 320 },
	{ "Events",        "events",    "★", 383 },
	{ "Trade",         "trade",     "⇄", 446 },
	{ "Priority",      "server",    "≡", 509 },
	{ "Webhook",       "webhook",   "∞", 572 },
	{ "Miscellaneous", "misc",      "✚", 635 },
	{ "Settings",      "settings",  "⚙", 698 },
}

local content = new("Frame", {
	Name = "Content", Position = UDim2.fromOffset(295, 77), Size = UDim2.fromOffset(1122, 774),
	BackgroundTransparency = 1, ClipsDescendants = true,
}, window)
local PAGE_HOME = UDim2.fromOffset(-295, -77)

local pages = {}
for _, item in ipairs(navItems) do
	pages[item[1]] = new("Frame", {
		Name = item[1] .. "Page", Position = PAGE_HOME, Size = UDim2.fromOffset(WINDOW_W, WINDOW_H),
		BackgroundTransparency = 1, Visible = (item[1] == DEFAULT_TAB),
	}, content)
end

local veil = new("Frame", {
	Name = "TabVeil", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.panel,
	BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5,
}, content)
corner(veil, UDim.new(0, 22))

------------------------------------------------------------------ Sidebar
-- The tab list lives in a scrolling area (mouse wheel / drag). With the tabs that exist now everything fits and nothing scrolls; once there
-- are more tabs than fit, a thin scrollbar shows up and the selected tab is scrolled into view by itself. Add a tab to navItems with the
-- next y value (63 px apart) and the scroll length follows by itself.
local NAV = { top = 100, h = 656 }   -- top = y of the list inside the window, h = visible height
do
	local lastY = 0
	for _, item in ipairs(navItems) do lastY = math.max(lastY, item[4]) end
	NAV.canvasH = lastY + 27 + 14 - NAV.top
	NAV.scroll = new("ScrollingFrame", {
		Name = "NavScroll", Position = UDim2.fromOffset(0, NAV.top), Size = UDim2.fromOffset(294, NAV.h),
		BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, Active = true,
		ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(110, 110, 110),
		ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
		CanvasSize = UDim2.fromOffset(0, NAV.canvasH),
	}, window)
	-- scrolls the list so the tab at window-y `y` is fully visible (does nothing when everything fits)
	function NAV.reveal(y, instant)
		local maxY = NAV.canvasH - NAV.h
		if maxY <= 0 then return end
		local top = y - 30 - NAV.top
		local cur = NAV.scroll.CanvasPosition.Y
		local goal
		if top < cur + 6 then goal = top - 8
		elseif top + 54 > cur + NAV.h - 6 then goal = top + 54 - NAV.h + 8 end
		if not goal then return end
		goal = math.clamp(goal, 0, maxY)
		if instant then
			NAV.scroll.CanvasPosition = Vector2.new(0, goal)
		else
			TweenService:Create(NAV.scroll, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CanvasPosition = Vector2.new(0, goal) }):Play()
		end
	end
end
local sel = frame(NAV.scroll, 18, 169 - NAV.top, 258, 54, Color3.fromRGB(200, 200, 200))
corner(sel, UDim.new(0, 16))
new("UIGradient", {
	Color = ColorSequence.new(Color3.fromRGB(1, 1, 1), Color3.fromRGB(1, 1, 1)),
	Rotation = 0,
}, sel)
ashStroke(stroke(sel, Color3.new(1, 1, 1), 2.5, 0.1))

local ACTIVE_ICON, IDLE_ICON = Color3.fromRGB(239, 239, 239), Color3.fromRGB(166, 166, 166)
local ACTIVE_TEXT, IDLE_TEXT = Color3.new(1, 1, 1), Color3.fromRGB(213, 213, 213)

local navIcons, navLabels = {}, {}
for _, item in ipairs(navItems) do
	local name, key, glyph, y = item[1], item[2], item[3], item[4]
	if name == "Farming" then
		navIcons[name] = shapeIcon(NAV.scroll, "egg", 50, y - NAV.top, IDLE_ICON)
	elseif name == "Kaitun" then
		navIcons[name] = shapeIcon(NAV.scroll, "diamond", 50, y - NAV.top, IDLE_ICON)
	else
		navIcons[name] = icon(NAV.scroll, key, glyph, 50, y - NAV.top, 26, IDLE_ICON)
	end
	navLabels[name] = label(NAV.scroll, name, 87, y - NAV.top, 22, IDLE_TEXT, Enum.Font.Gotham)
end

local pageTweens = {}
local veilTween
-- Plays the fade-in animation of a tab page (cancels a running one first).
local function animatePageIn(pg)
	if pageTweens[pg] then pageTweens[pg]:Cancel() end
	if veilTween then veilTween:Cancel() end
	pg.Position = PAGE_HOME + UDim2.fromOffset(0, -46)
	veil.BackgroundTransparency = 0.05
	local info = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local t = TweenService:Create(pg, info, { Position = PAGE_HOME })
	veilTween = TweenService:Create(veil, info, { BackgroundTransparency = 1 })
	pageTweens[pg] = t
	t:Play()
	veilTween:Play()
end

local currentTab
-- Switches to another tab: moves the sidebar highlight and shows that tab's page.
local function setTab(name, instant)
	if currentTab == name then return end
	currentTab = name
	for _, item in ipairs(navItems) do
		local n, y = item[1], item[4]
		local on = (n == name)
		setIconColor(navIcons[n], on and ACTIVE_ICON or IDLE_ICON)
		navLabels[n].TextColor3 = on and ACTIVE_TEXT or IDLE_TEXT
		navLabels[n].Font = on and Enum.Font.GothamMedium or Enum.Font.Gotham
		local pg = pages[n]
		if on then
			if not pg.Visible then
				pg.Visible = true
				if not instant then animatePageIn(pg) end
			end
			if n == "Home" and record.homeIntro then task.defer(record.homeIntro) end
		else
			if pageTweens[pg] then pageTweens[pg]:Cancel() end
			pg.Visible = false
			pg.Position = PAGE_HOME
		end
		if on then
			local target = UDim2.fromOffset(18, y - 30 - NAV.top)
			NAV.reveal(y, instant)
			if instant then
				sel.Position = target
			else
				TweenService:Create(sel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Position = target }):Play()
			end
		end
	end
end

for _, item in ipairs(navItems) do
	local name, y = item[1], item[4]
	local btn = new("TextButton", {
		Name = name .. "Tab", Position = UDim2.fromOffset(18, y - 30 - NAV.top), Size = UDim2.fromOffset(258, 54),
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Active = true,
	}, NAV.scroll)
	btn.MouseButton1Click:Connect(function() flame(sel, 0.7); setTab(name) end)
end

-- footer: Roblox avatar + username + how long the script has been running
local foot = frame(window, 18, 764, 258, 84, Color3.fromRGB(8, 8, 8), 0.3)
corner(foot, UDim.new(0, 20))
ashStroke(stroke(foot, Color3.new(1, 1, 1), 2.5, 0.1))
local avatar = new("ImageLabel", {
	Position = UDim2.fromOffset(14, 18), Size = UDim2.fromOffset(48, 48),
	BackgroundColor3 = Color3.fromRGB(174, 174, 174), BorderSizePixel = 0, Image = "",
}, foot)
corner(avatar, UDim.new(1, 0))
stroke(avatar, C.greenText, 2)
task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if ok and alive and avatar.Parent then avatar.Image = img end
end)
-- status dot on the avatar: green, glowing, and gently pulsing
do
	local DX, DY = 57, 61
	local glow = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(DX, DY), Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = C.greenText, BackgroundTransparency = 0.55, BorderSizePixel = 0,
	}, foot)
	corner(glow, UDim.new(1, 0))
	local statusDot = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(DX, DY), Size = UDim2.fromOffset(11, 11),
		BackgroundColor3 = C.greenText, BorderSizePixel = 0,
	}, foot)
	corner(statusDot, UDim.new(1, 0))
	stroke(statusDot, Color3.fromRGB(12, 12, 12), 2) -- dark ring so the dot stands out from the avatar
	local pulse = TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(glow, pulse, { Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 0.9 }):Play()
	TweenService:Create(statusDot, pulse, { Size = UDim2.fromOffset(13, 13) }):Play()
end
local userLbl = label(foot, player.Name, 74, 29, 17, C.text, Enum.Font.GothamMedium)
userLbl.RichText = false
userLbl.Size = UDim2.fromOffset(108, 24)
userLbl.TextTruncate = Enum.TextTruncate.AtEnd

-- Name privacy: the avatar always shows, but your username is hidden until you press Show (remembered between executes, separate from configs).
-- Everything that would print your name inside the hub (footer, Home welcome / signed-in lines, status tooltip) is registered here.
do
	local N = { shown = false, items = {} }
	FX.names = N
	-- Registers a name label so it can switch between the real and the hidden username.
	function N.add(lbl, full, masked)
		N.items[#N.items + 1] = { lbl = lbl, full = full, masked = masked }
		lbl.Text = N.shown and full or masked
	end
	local btn = new("TextButton", {
		Name = "ShowNameButton", Position = UDim2.fromOffset(190, 16), Size = UDim2.fromOffset(56, 26),
		BackgroundColor3 = Color3.fromRGB(44, 44, 44), BorderSizePixel = 0, AutoButtonColor = false,
		Text = "Show", TextColor3 = C.text, TextSize = 15, Font = Enum.Font.GothamMedium,
	}, foot)
	corner(btn, UDim.new(1, 0))
	stroke(btn, Color3.fromRGB(80, 80, 80), 1)
	-- Updates every registered label to show the real or the hidden username.
	local function refresh()
		for _, it in ipairs(N.items) do
			if it.lbl.Parent then it.lbl.Text = N.shown and it.full or it.masked end
		end
		btn.Text = N.shown and "Hide" or "Show"
		btn.BackgroundColor3 = N.shown and Color3.fromRGB(96, 96, 96) or Color3.fromRGB(44, 44, 44)
	end
	-- Turns "show username" on or off (and saves the choice when `save` is true).
	function N.set(on, save)
		N.shown = on == true
		refresh()
		if save and N.save then N.save(N.shown) end
	end
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = N.shown and Color3.fromRGB(116, 116, 116) or Color3.fromRGB(64, 64, 64) }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = N.shown and Color3.fromRGB(96, 96, 96) or Color3.fromRGB(44, 44, 44) }):Play()
	end)
	btn.MouseButton1Click:Connect(function() N.set(not N.shown, true) end)
	N.add(userLbl, player.Name, "\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}")
end
local timeLbl = label(foot, "Running 00:00:00", 74, 56, 15, C.greenText, Enum.Font.Gotham)
timeLbl.Size = UDim2.fromOffset(172, 22)
local startedAt = os.time()
task.spawn(function()
	while alive and timeLbl.Parent do
		local t = os.time() - startedAt
		timeLbl.Text = string.format("Running %02d:%02d:%02d", math.floor(t / 3600), math.floor(t / 60) % 60, t % 60)
		task.wait(1)
	end
end)

------------------------------------------------------------------ CONTROLS (button / toggle / slider / dropdown / input / keybind)
--[[
	type = "button"   run = function() ... end  OR  url = "https://..."
	type = "toggle"   default = false, callback = function(on) ... end
	type = "slider"   min, max, default, step, suffix, callback = function(value) ... end
	type = "dropdown" options = { "A", "B" }, default = "A", width = 220, callback = function(option) ... end
	                  multi = true, picked = {}, clearOption = "A"  -> tick several options (ticked ones are the keys of entry.picked)
	                  Every multi / counter dropdown uses "+  name  -" rows: left click = add, right click = reduce, the + and - buttons do the same for touch.
	                  counter = true, counts = {}, limitOf = function(option) return max end, maxTotal = n, onOpen = function() end,
	                  clearOption, emptyText, isClearActive  -> every option has a number (option -> n in entry.counts); callback(option, delta, newCount)
	type = "input"    placeholder, default, numeric, clearOnSubmit, callback = function(text) ... end
	type = "keybind"  (Settings tab - minimize key)
	type = "webhook"  (Webhook tab)
	Optional on any entry: icon = "⚡", noSave = true
]]
local HttpService = game:GetService("HttpService")
local STORE_DIR = "WORST"
local hasFiles = typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"

local Store = {}
-- Saves text to WORST/<name> (kept in memory only when the executor has no file functions).
function Store.write(name, text)
	if hasFiles then
		if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(STORE_DIR) then
			makefolder(STORE_DIR)
		end
		writefile(STORE_DIR .. "/" .. name, text)
		return true
	end
	env.WORSTHubStore = env.WORSTHubStore or {}
	env.WORSTHubStore[name] = text
	warn("[WORST Hub] writefile isn't available here - saved in memory only (lost when the game closes).")
	return false
end
-- Reads a file from the WORST folder; returns nil if it does not exist.
function Store.read(name)
	if hasFiles then
		local path = STORE_DIR .. "/" .. name
		if isfile(path) then return readfile(path) end
		return nil
	end
	return env.WORSTHubStore and env.WORSTHubStore[name]
end

-- Show / Hide name choice (footer button): saved on its own, whatever the configuration / Auto Save settings are. Default = hidden.
if FX.names then
	FX.names.save = function(on) pcall(Store.write, "showname.txt", on and "1" or "0") end
	FX.names.set(Store.read("showname.txt") == "1", false)
end

------------------------------------------------------------------ ANIMATED BACKGROUND (GIF cut into image sheets)
-- Roblox can't play GIFs, so the GIF is cut into frames packed into 10 image sheets (bg_1.jpg ... bg_10.jpg) and flipped like a flipbook.
-- Put the 10 files into  <executor workspace>/WORSTHub/   -OR- upload them somewhere and set BG_URL to that folder link (ending with "/").
-- If the files can't be found the hub simply keeps its normal plain background.
do
	local BG_URL = "https://raw.githubusercontent.com/Asaiya2/Background/main/"
	local SHEETS, COLS, ROWS, TOTAL = 10, 3, 5, 150
	local FRAME_W, FRAME_H, FPS = 320, 194, 30
	local getAsset = getcustomasset or getsynasset

	task.spawn(function()
		if not (hasFiles and getAsset and typeof(isfile) == "function") then return end
		pcall(function()
			if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(STORE_DIR) then makefolder(STORE_DIR) end
		end)

		local ids = {}
		for i = 1, SHEETS do
			local path = STORE_DIR .. "/bg_" .. i .. ".jpg"
			if not isfile(path) and BG_URL ~= "" then
				local ok, data = pcall(function() return game:HttpGet(BG_URL .. "bg_" .. i .. ".jpg") end)
				if ok and type(data) == "string" and #data > 1000 then pcall(writefile, path, data) end
			end
			if not isfile(path) then
				warn("[WORST Hub] Background: " .. path .. " not found - using the plain background.")
				return
			end
			local okA, id = pcall(getAsset, path)
			if not okA then return end
			ids[i] = id
		end
		if not alive then return end

		local holder = new("Frame", {
			Name = "AnimatedBackground", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0, ClipsDescendants = true,
		}, window)
		corner(holder, UDim.new(0, 28))
		-- while the loading screen is still showing, the background plays inside it
		local loadingScreen = window:FindFirstChild("Loader")
		if loadingScreen then holder.Parent = loadingScreen end
		local imgs = {}
		for i, id in ipairs(ids) do
			imgs[i] = new("ImageLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = id, ZIndex = 0,
				ImageRectSize = Vector2.new(FRAME_W, FRAME_H), ImageRectOffset = Vector2.new(0, 0),
				ScaleType = Enum.ScaleType.Stretch, Visible = (i == 1),
			}, holder)
			corner(imgs[i], UDim.new(0, 28))
		end
		corner(new("Frame", { -- dark layer so the text stays readable
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.window, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 0,
		}, holder), UDim.new(0, 28))
		-- PreloadAsync can take minutes (or never return) with executor files, and everything below waits for it: the panel stayed
		-- solid and the animation never started. Preload in the background instead of waiting for it.
		task.spawn(function() pcall(function() game:GetService("ContentProvider"):PreloadAsync(imgs) end) end)
		FX.holder, FX.panel = holder, panel
		FX.panelTrans = 0.8   -- main panel (higher = more of the animated background shows through)
		panel.BackgroundTransparency = FX.bg and FX.panelTrans or 0 -- lets the animation show through the main panel
		holder.Visible = FX.bg

		local PER = COLS * ROWS
		local t0, cur, lastF = os.clock(), 1, -1
		while alive and holder.Parent do
			if window.Visible and FX.bg then
				local f = math.floor((os.clock() - t0) * FPS) % TOTAL
				local sheet, k = math.floor(f / PER) + 1, f % PER
				if f ~= lastF and imgs[sheet] then
					lastF = f
					imgs[sheet].ImageRectOffset = Vector2.new((k % COLS) * FRAME_W, math.floor(k / COLS) * FRAME_H)
					if sheet ~= cur then
						imgs[sheet].Visible = true
						imgs[cur].Visible = false
						cur = sheet
					end
				end
				task.wait()   -- every frame (a fixed 0.04s wait caps the flipbook at 25 steps/s, so 30 FPS would skip frames)
			else
				task.wait(0.5)   -- window hidden (Mini Ui) or background off: nothing to animate, so don't wake up every frame
			end
		end
	end)
end

local Config = {}
Config.override  = {}   -- control id -> value that is SAVED instead of the live one (Kaitun Hatch owns those controls while it is on)
Config.pageLists = {}   -- tab name -> the scrolling list of a one-page tab
-- FPS cap: the Settings slider sets .user (0 = Off); the Lite window sets .lite = true (forced to LITE_CAP)
-- .event = true while an event feature (Trick or Treat, Hallow Lord, Dig, Balloons, Pet Defense, Double Jump) is on its trip: the Lite window then
-- runs at EVENT_CAP instead of LITE_CAP (5 FPS is too low: the character jumps several times before it even lands).
Config.fps = { user = 0, touched = false, lite = false, active = false, LITE_CAP = 0, EVENT_CAP = 0, event = false }   -- Mini Ui no longer limits FPS (0 = no limit)
Config.execName = function()   -- the executor's name as it reports itself ("Unknown" when it doesn't)
	local name = "Unknown"
	pcall(function()
		if typeof(identifyexecutor) == "function" then
			local n = identifyexecutor()
			if n then name = tostring(n) end
		end
	end)
	return name
end
Config.fpsFn = function()   -- the executor's FPS cap function (some mobile executors only have one of the other names)
	-- Delta: no FPS cap at all (checked first, before any cap function is looked up), so the cap does nothing there
	if string.find(string.lower(Config.execName()), "delta", 1, true) then return nil end
	if typeof(setfpscap) == "function" then return setfpscap end
	if typeof(set_fps_cap) == "function" then return set_fps_cap end
	if typeof(setfps) == "function" then return setfps end
	-- no cap function at all: set Roblox's own FPS target through the fast flags instead. 0 = back to the value it had.
	if typeof(setfflag) == "function" then
		return function(n)
			n = math.floor(tonumber(n) or 0)
			Config.fpsOrig = Config.fpsOrig or (function()
				if typeof(getfflag) ~= "function" then return false end
				local ok, v = pcall(getfflag, "DFIntTaskSchedulerTargetFps")
				return ok and tostring(v) ~= "" and tostring(v) or false
			end)()
			local v = n > 0 and tostring(n) or (Config.fpsOrig or "9999")
			pcall(setfflag, "DFIntTaskSchedulerTargetFps", v)   -- the executors accept one of these two spellings
			pcall(setfflag, "TaskSchedulerTargetFps", v)
		end
	end
	return nil
end
Config.applyFps = function()
	local f = Config.fps
	local fn = Config.fpsFn()
	if not fn then return end
	if not (f.lite or f.touched or f.active) then return end   -- never touch the cap unless the slider / Lite window needs it
	f.active = true
	pcall(fn, f.lite and (f.event and f.EVENT_CAP or f.LITE_CAP) or f.user)
end
Config.fpsEvent = function(on)
	Config.fps.event = on == true
	if Config.fps.lite then Config.applyFps() end
end
table.insert(cleanupHooks, function()   -- closing / re-executing the hub puts the cap back to "no limit"
	local fn = Config.fpsFn()
	if Config.fps.active and fn then pcall(fn, 0) end
end)
local controls = {}

------------------------------------------------------------------ HATCH + CRAFT LOGIC
-- Everything is inside one function so it doesn't use up the script's local-variable limit.
-- It returns the control entries that are placed on the Hatch and Pets tabs.
-- filled in by the webhook code further down; lets features report to the webhook
local WebhookBridge = {}

-- Builds all the feature logic (hatch, craft, delete, events, Kaitun ...) and returns it as the Logic table. Runs once at load.
local function buildLogic()
	local RS = game:GetService("ReplicatedStorage")
	local VIM = game:GetService("VirtualInputManager")
	local GuiService = game:GetService("GuiService")
	local lp = player

	-------------------------------------------------------------------------- settings: hatch
	-- Egg positions (CFrames). Eggs that share a spot share a constant.
	-- The CF_ constants live inside their own function (see "local EGGS = (function()" below), so you can add as many
	-- as you like without hitting Lua's 200-local limit. To add an island: uncomment a "local CF_IslandNN" line,
	-- paste the CFrame, then uncomment the matching egg line in the EGGS list and fill in its name + island.
	local EGGS = (function()
	local CF_SPAWN_A = CFrame.new(-1.6585851907730103, -513.9365844726562, -1829.3428955078125, -0.69408118724823, -5.045127338121347e-08, -0.7198967337608337, 1.33911026711786e-09, 1, -7.137235513710039e-08, 0.7198967337608337, -5.0502229953508504e-08, -0.69408118724823)
	local CF_SPIKED  = CFrame.new(-19.052452087402344, -515.0718383789062, -1706.5780029296875, -0.9986703991889954, 1.1916983844173501e-08, 0.05155022442340851, 1.2161180507064273e-08, 1, 4.423403865416731e-09, -0.05155022442340851, 5.044433759593403e-09, -0.9986703991889954)
	local CF_SKY     = CFrame.new(-89.25822448730469, -49.87088394165039, -1895.8592529296875, 0.4727705121040344, 2.7036550775960677e-08, 0.8811855912208557, 2.5841522255376503e-09, 1, -3.2068456334855e-08, -0.8811855912208557, 1.743813804466754e-08, 0.4727705121040344)
	local CF_AUTUMN  = CFrame.new(-152.27195739746094, 877.6463012695312, -1835.6474609375, 0.24970608949661255, 7.80360096541699e-08, 0.968321681022644, 2.728942050111982e-08, 1, -8.762619074786926e-08, -0.968321681022644, 4.8305729194453306e-08, 0.24970608949661255)
	local CF_MUSHROOM = CFrame.new(-16.21805191040039, 2029.7989501953125, -1925.078125, 0.9055572152137756, -1.9117411653724048e-08, -0.4242241680622101, -1.2195944698589756e-08, 1, -7.109811406280642e-08, 0.4242241680622101, 6.95572239806097e-08, 0.9055572152137756)


	local CF_DESERT = CFrame.new(-197.71743774414062, 3629.472412109375, -1859.665283203125,
		0.20199140906333923, -9.311199278272397e-08, 0.9793872833251953,
		-1.8098362808416368e-09, 1, 9.544493906332718e-08,
		-0.9793872833251953, -2.1051588916520814e-08, 0.20199140906333923)
	local CF_CRYSTAL = CFrame.new(-60.337215423583984, 5436.0673828125, -1985.3702392578125,
		0.9314093589782715, -3.3058732640256494e-08, 0.3639734387397766,
		-9.913732057498237e-09, 1, 1.1619660256201314e-07,
		-0.3639734387397766, -1.1183493597854977e-07, 0.9314093589782715)

	-- Void egg (Shadow Realm): from the game's own egg position (-203.5, 7676.5, -1885.0), 3 studs lower and 6 studs toward the island's landing spot.
	-- Not tested in game yet - if hatching Void fails, stand next to the egg and tell me your position.
	local CF_VOID = CFrame.new(-197.7, 7673.5, -1886.6)

	-- ===== placeholders: remove the "--" and paste the CFrame =====
	-- local CF_Island10 = CFrame.new()   -- spot for Egg10
	-- local CF_Island11 = CFrame.new()   -- spot for Egg11
	-- local CF_Island12 = CFrame.new()   -- spot for Egg12
	-- local CF_Island13 = CFrame.new()   -- spot for Egg13
	-- local CF_Island14 = CFrame.new()   -- spot for Egg14
	-- local CF_Island15 = CFrame.new()   -- spot for Egg15
	-- local CF_Island16 = CFrame.new()   -- spot for Egg16
	-- local CF_Island17 = CFrame.new()   -- spot for Egg17
	-- local CF_Island18 = CFrame.new()   -- spot for Egg18
	-- local CF_Island19 = CFrame.new()   -- spot for Egg19
	-- local CF_Island20 = CFrame.new()   -- spot for Egg20
	-- local CF_Island21 = CFrame.new()   -- spot for Egg21
	-- local CF_Island22 = CFrame.new()   -- spot for Egg22
	-- local CF_Island23 = CFrame.new()   -- spot for Egg23
	-- local CF_Island24 = CFrame.new()   -- spot for Egg24
	-- local CF_Island25 = CFrame.new()   -- spot for Egg25
	-- local CF_Island26 = CFrame.new()   -- spot for Egg26
	-- local CF_Island27 = CFrame.new()   -- spot for Egg27
	-- local CF_Island28 = CFrame.new()   -- spot for Egg28
	-- local CF_Island29 = CFrame.new()   -- spot for Egg29

	-- name = the egg name sent to the server, island = where to Travel first ("" = don't travel), cf = where to stand.
	-- The dropdown on the Hatch tab is built from this list, in this order.
	return {
		{ name = "Basic",     island = "Spawn",    cf = CF_SPAWN_A },
		{ name = "Spotted",   island = "Spawn",    cf = CF_SPAWN_A },
		{ name = "Spiked",    island = "Spawn",    cf = CF_SPIKED },   -- island wasn't given: assumed Spawn (same area), change it if wrong
		{ name = "Nimbus",    island = "Sky Island", cf = CF_SKY },
		{ name = "Sky",       island = "Sky Island", cf = CF_SKY },
		{ name = "Pumpkin",   island = "Autumn",   cf = CF_AUTUMN },
		{ name = "Mycelium",  island = "Mushroom", cf = CF_MUSHROOM },   -- was spelled "Mycellium" (the game uses one "l")
		{ name = "Mushroom",  island = "Mushroom", cf = CF_MUSHROOM },
		{ name = "Cactus",    island = "Desert",   cf = CF_DESERT },
		{ name = "Crystal",   island = "Crystal Cave", cf = CF_CRYSTAL },
		{ name = "Geode",     island = "Crystal Cave", cf = CF_CRYSTAL },
		{ name = "Void",      island = "Shadow Realm", cf = CF_VOID },
		-- ===== placeholders: remove the "--" and fill in name / island (cf = the CF_IslandNN constant above) =====
		-- { name = "Egg10", island = "Island", cf = CF_Island10 },
		-- { name = "Egg11", island = "Island", cf = CF_Island11 },
		-- { name = "Egg12", island = "Island", cf = CF_Island12 },
		-- { name = "Egg13", island = "Island", cf = CF_Island13 },
		-- { name = "Egg14", island = "Island", cf = CF_Island14 },
		-- { name = "Egg15", island = "Island", cf = CF_Island15 },
		-- { name = "Egg16", island = "Island", cf = CF_Island16 },
		-- { name = "Egg17", island = "Island", cf = CF_Island17 },
		-- { name = "Egg18", island = "Island", cf = CF_Island18 },
		-- { name = "Egg19", island = "Island", cf = CF_Island19 },
		-- { name = "Egg20", island = "Island", cf = CF_Island20 },
		-- { name = "Egg21", island = "Island", cf = CF_Island21 },
		-- { name = "Egg22", island = "Island", cf = CF_Island22 },
		-- { name = "Egg23", island = "Island", cf = CF_Island23 },
		-- { name = "Egg24", island = "Island", cf = CF_Island24 },
		-- { name = "Egg25", island = "Island", cf = CF_Island25 },
		-- { name = "Egg26", island = "Island", cf = CF_Island26 },
		-- { name = "Egg27", island = "Island", cf = CF_Island27 },
		-- { name = "Egg28", island = "Island", cf = CF_Island28 },
		-- { name = "Egg29", island = "Island", cf = CF_Island29 },
	}
	end)()

	-- ===== auto-detect new eggs =====
	-- The game lists every egg in Shared.Pets.PetIndexCatalog.Eggs, gives each one's island in Shared.Pets.LaunchEggConfig and keeps its
	-- world position in ReplicatedStorage.PetIndexEggs (not affected by streaming). Any egg that is in the game but not in the list above is
	-- added here. Its stand spot is a GUESS: the egg position, 3 studs lower and 6 studs toward the island's landing spot (that is how the
	-- tested spots above relate to their eggs). The names are kept in EGGS.auto so the dropdown can say so.
	EGGS.auto = {}
	do
		local okA, errA = pcall(function()
			local catalog  = require(RS.Shared.Pets.PetIndexCatalog)
			local launch   = require(RS.Shared.Pets.LaunchEggConfig)
			local landings = require(RS.Shared.Progression.IslandLandings)
			local index    = RS:FindFirstChild("PetIndexEggs")
			local have = {}
			for _, e in ipairs(EGGS) do have[e.name] = true end
			for _, name in ipairs(catalog.Eggs or {}) do
				if type(name) == "string" and not have[name] then
					local cfg  = launch[name]
					local node = index and index:FindFirstChild(name)
					if node and node:IsA("BasePart") then
						local pos    = node.Position
						local island = type(cfg) == "table" and type(cfg.Island) == "string" and cfg.Island or nil
						if not island then
							-- LaunchEggConfig has no entry for this egg (older eggs are not in it): use the island whose landing spot is nearest to the egg
							local bestD
							for iname, l in pairs(landings) do
								local lp = type(l) == "table" and l.Position
								if typeof(lp) == "Vector3" then
									local dd = (lp - pos).Magnitude
									if not bestD or dd < bestD then bestD, island = dd, iname end
								end
							end
							island = island or "Spawn"
						end
						local stand  = pos + Vector3.new(0, -3, 0)
						local land   = landings[island] and landings[island].Position
						if land then
							local d = Vector3.new(land.X - pos.X, 0, land.Z - pos.Z)
							if d.Magnitude > 1 then stand = stand + d.Unit * 6 end
						end
						EGGS[#EGGS + 1] = { name = name, island = island, cf = CFrame.new(stand), auto = true }
						EGGS.auto[#EGGS.auto + 1] = name
					end
				end
			end
		end)
		if not okA then warn("[WORST Hub] egg auto-detect failed: " .. tostring(errA)) end
		if #EGGS.auto > 0 then print("[WORST Hub] new egg(s) found in the game and added: " .. table.concat(EGGS.auto, ", ")) end
	end

	local selectedEgg = EGGS[1]    -- changed by the "Egg to Hatch" dropdown

	local TP_INTERVAL  = 2        -- seconds between position checks while hatching
	local TP_RADIUS    = 10       -- studs: when you're within this distance of the egg spot, you are not teleported onto it (the hatch also snaps you back by itself when the server refuses / does not answer)
	local TRAVEL_SKIP_RADIUS = 70 -- studs: when you're within this distance of the egg spot before hatching starts, the island Travel is skipped
	local HATCH_SETTLE = 0.3      -- seconds to wait after Travel before the first teleport
	local DO_HATCH     = true     -- false = teleport only, no hatching
	local COUNT        = 3        -- eggs per hatch
	local DELAY        = 2        -- seconds between hatches
	local AUTO_FLAG    = true
	local SEQ_FALLBACK = 1
	local SEQ_WAIT     = 10

	-------------------------------------------------------------------------- settings: craft
	local MACHINE       = "Golden"
	local NEED          = 6          -- pets per Golden craft (adjustable)
	local TRIGGER_AT    = NEED       -- minimum matching pets needed to craft; storageGate alone controls when auto-crafting starts
	local SCAN_EVERY    = 30        -- a scan result younger than this is reused: a feature that needs fresh pets (Craft ...) scans at most this often
	local IDLE_SCAN     = 180       -- the background "Auto Scan Inventory" toggle only rescans every X seconds (3 minutes) - it walks every pet you own

	local SPAWN_ISLAND  = "Spawn"
	local MACHINE_CF = CFrame.new(14.760296821594238, -513.3433227539062, -1887.6181640625,
		0.6825100183486938, -1.2589890019398808e-08, -0.7308762073516846,
		4.334497205604748e-08, 1, 2.325084480503392e-08,
		0.7308762073516846, -4.7548745385483926e-08, 0.6825100183486938)
	-- Golden crafting now happens at the Crystal Cave spot below. No machine window is needed, being close is enough.
	local CRAFT_ISLAND  = "Crystal Cave"
	local CRAFT_CF = CFrame.new(-138.69949340820312, 5451.83544921875, -2032.4588623046875,
		0.8476988077163696, 2.00043288600682e-08, 0.5304778218269348,
		1.0813774764528716e-08, 1, -5.499033406408671e-08,
		-0.5304778218269348, 5.2351708745845826e-08, 0.8476988077163696)
	local SKIP_TRAVEL_RADIUS = 100   -- within this many studs of the machine spot: skip the island Travel and teleport straight there
	local CRAFT_ALL_OVER = 12    -- with MORE than this many of the same pet, try "Craft All" first
	local CRAFT_SETTLE  = 1.5


	local CRAFT_DELAY   = 1.0
	local RESULT_WAIT   = 6
	local MAX_FAILS     = 3
	local MAX_CRAFTS    = 0          -- 0 = no limit (Golden craft only)
	local PICK          = "lowest"   -- "lowest", "highest" or "list"
	local SKIP_LOCKED   = true
	local SKIP_EQUIPPED = true

	local WINDOW_TIMEOUT   = 90
	local REFRESH_WAIT     = 10
	local AUTO_OPEN_PROMPT = true
	local PROMPT_RANGE     = 25
	local MACHINE_GUI_PATH = nil     -- optional, e.g. { "Tabs", "Machine" }
	local HIDE_INVENTORY   = true    -- keep the Inventory window invisible while the script scans it
	-- storage (the "Craft When Storage Is" slider): the script looks for an "owned/max" text (like 245/500) in the Inventory window.
	-- If it picks the wrong one (see the output: "[Pets] storage read from ..."), set the exact path here, e.g. { "Menu", "Storage", "Label" }
	local STORAGE_PATH     = nil
	-- fallback if no "owned/max" text exists: your pet storage size. The pets counted in the scan are used as "owned".
	local STORAGE_MAX      = nil

	-------------------------------------------------------------------------- remotes
	local function find(root, names)
		local node = root
		for _, n in ipairs(names) do
			node = node and node:WaitForChild(n, 10)
			if not node then return nil end
		end
		return node
	end

	local travelRemote  = find(RS, { "RemoteServices", "IslandService", "RF", "Travel" })
	local hatchRemote   = find(RS, { "RemoteServices", "EggService", "RE", "EggHatchRequested" })
	local requestRemote = find(RS, { "RemoteServices", "MachineService", "RE", "MachineCraftRequested" })
	local resultRemote  = find(RS, { "RemoteServices", "MachineService", "RE", "MachineCraftResult" })
	assert(travelRemote, "IslandService.RF.Travel not found")
	assert(hatchRemote, "EggService.RE.EggHatchRequested not found")
	assert(requestRemote and resultRemote, "MachineService remotes not found")

	-- Returns the player's PlayerGui.
	local function pg() return lp:FindFirstChild("PlayerGui") end
	-- Follows a list of child names from `root`; returns nil if any step is missing.
	local function walk(root, path)
		local node = root
		for _, name in ipairs(path) do
			node = node and node:FindFirstChild(name)
			if not node then return nil end
		end
		return node
	end

	-- Short text form of a value, used in log messages.
	local function brief(t)
		if type(t) ~= "table" then return tostring(t) end
		local p = {}
		for k, v in pairs(t) do p[#p + 1] = tostring(k) .. "=" .. tostring(v) end
		return "{" .. table.concat(p, ", ") .. "}"
	end

	-- Returns the player's HumanoidRootPart (nil if the character is not loaded).
	local function getHRP()
		local char = lp.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	-- Teleports the character to the given CFrame.
	local function teleportTo(cf)
		local hrp = getHRP()
		if not hrp then return false end
		hrp.CFrame = cf
		pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
		return true
	end

	-- true when your character is already within TP_RADIUS studs of the given spot
	local function isNear(cf, radius)
		local hrp = getHRP()
		return hrp ~= nil and (hrp.Position - cf.Position).Magnitude <= (radius or TP_RADIUS)
	end

	-- true only while the inventory window is closed and no scan is running (assigned further down, once invIsOn exists)
	local inventoryClosed = function() return true end

	-------------------------------------------------------------------------- the control entries (callbacks are set at the bottom)
	-- eggNames = the real egg names (used by Auto Delete and everything that talks to the server)
	-- eggLabels = the same list with "[NEW!!] " in front of auto-detected eggs (only the Egg to Hatch dropdown shows these)
	local eggNames, eggLabels, eggByName = {}, {}, {}
	for _, e in ipairs(EGGS) do
		eggNames[#eggNames + 1] = e.name
		eggLabels[#eggLabels + 1] = e.auto and ("[NEW!!] " .. e.name) or e.name
		eggByName[e.name] = e
	end
	local eggEntry = {
		type = "dropdown", name = "Egg to Hatch", icon = "🥚", width = 240,
		desc = "Pick the egg. Its island and position are used automatically (changes apply live)." .. (#EGGS.auto > 0 and (" Found in the game and added automatically (position guessed, not tested): " .. table.concat(EGGS.auto, ", ") .. ".") or ""),
		options = eggLabels, default = eggLabels[1],
	}
	local hatchEntry = {
		-- TOGGLE "Auto Hatch": Travels to the selected egg's island, teleports to the egg, waits 1 second and presses F once (the game's own auto hatch).
		type = "toggle", name = "Auto Hatch", icon = "🥚", default = false,
		desc = "Travels to the selected egg's island, teleports to the egg, waits 1 second and presses F once (the game's own auto hatch). When Craft / events take over it presses F again to pause, and repeats the same when it is its turn again. Order is set in the Priority tab.",
	}
	local scanEntry = {
		-- TOGGLE "Auto Scan Inventory": reads your pets from the game's own data every few minutes (the inventory is never opened) to keep the pet lists and Auto Craft up to date.
		type = "toggle", name = "Auto Scan Inventory", icon = "I", default = true,
		desc = string.format("Reads your pets from the game's own data every %d minutes (the inventory is never opened) to keep the pet lists and Auto Craft up to date.",
			math.floor(IDLE_SCAN / 60)),
	}
	local dropEntry = {
		type = "dropdown", name = "Pet to Craft", icon = "🐾", noSave = true, width = 320,
		desc = "Left click a pet = +1 craft, right click = -1 (or use + / -). Each craft turns 6 of that pet Golden. All pets = every pet with 6+ copies. The list fills after the first scan (Settings > Auto Scan Inventory).",
		options = { "Waiting for the first scan..." }, default = "Waiting for the first scan...",
		counter = true, counts = {}, clearOption = "All pets", emptyText = "Select a pet...",
	}
	local craftEntry = {
		-- TOGGLE "Auto Craft": Turns every 6 of the chosen pet (or of every pet with 6+) into Golden.
		type = "toggle", name = "Auto Craft", icon = "✨", default = false,
		desc = "Crafts when the storage slider threshold is reached; Golden Amount controls pets used per craft. Pauses auto hatch while crafting.",
	}
	local storageEntry = {
		type = "slider", name = "Craft When Storage Is", icon = "📦",
		desc = "Golden crafts only start once your pet storage is this full (0% = always craft). Diamond/Rainbow ignore this.",
		min = 0, max = 100, default = 0, step = 5, suffix = "%",
	}
	local goldenAmountEntry = {
		type = "dropdown", name = "Golden Amount", icon = "✨", width = 280,
		desc = "Number of matching Normal pets consumed per Golden craft. Crafting starts based on the Craft When Storage Is slider, not this amount.",
		options = { "2 pets", "3 pets", "4 pets", "5 pets", "6 pets" }, default = "6 pets",
	}
	goldenAmountEntry.callback = function(value)
		local n = tonumber(tostring(value):match("^(%d+)"))
		if n and n >= 2 and n <= 6 then
			NEED = n
			TRIGGER_AT = NEED -- matching pets required for a valid craft, NOT the storage trigger
			lastScanAt = -1e9
			if lastGroups and fillOptions then fillOptions(lastGroups) end
		end
	end
	local craftAllEntry = {
		type = "button", name = "Craft All", icon = "⚡", noSave = true,
		desc = "Asks the Golden Machine to craft everything it can in one go (same as the game's own Craft All button). Turn Auto Craft off first.",
	}

	-- Sets the grey description text under an entry (also used as its live status line).
	local function setDesc(entry, text)
		local l = entry._desc
		if l and l.Parent then l.Text = text end
	end
	-- Sets the status text of Auto Hatch.
	local function hSetStatus(text) setDesc(hatchEntry, text) end
	-- Sets the status text of Auto Craft.
	local function setStatus(text) setDesc(craftEntry, text) end

	-------------------------------------------------------------------------- HATCH
	local hEnabled, hReady = false, false
	local hEgg = selectedEgg   -- egg used by the current run
	local hRunId = 0
	local hatched = 0
	local seq = nil

	local canHook = type(hookmetamethod) == "function" and type(getnamecallmethod) == "function"
	local oldNamecall
	if canHook and DO_HATCH then
		oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			if alive and self == hatchRemote and getnamecallmethod() == "FireServer"
				and not (type(checkcaller) == "function" and checkcaller()) then
				local a = ...
				if type(a) == "table" and type(a.Seq) == "number" and (not seq or a.Seq > seq) then
					seq = a.Seq
				end
			end
			return oldNamecall(self, ...)
		end))
	end

	-- True while this Auto Hatch run is still the current one (not switched off / restarted).
	local function hActive(id) return alive and hEnabled and hRunId == id end
	-- Waits `seconds`, but stops early if the hatch run is cancelled.
	local function hSleep(id, seconds)
		local t0 = os.clock()
		while hActive(id) and os.clock() - t0 < seconds do task.wait(0.1) end
	end

	-------------------------------------------------------------------------- hatch amount (auto) + hatch animation hiding
	-- (wrapped in a do-block so it only uses 3 of the function's 200 local-variable slots)
	local currentCount, HA, HA_auto
	local hCount = COUNT
	do
	local RunService_ = game:GetService("RunService")

	-- ---- how many eggs per hatch: reads the game's own Hatch 1 / Hatch 3 / Hatch 8 buttons (a locked "Game Pass" button = not owned)
	local detectedMax, lastDetect = nil, -1e9
	-- Returns the text of a TextLabel / TextButton.
	local function guiText(x)
		if x:IsA("TextLabel") or x:IsA("TextButton") then return (x.Text:gsub("<[^>]+>", "")) end
	end
	local HA_dbg
	-- Reads the game's UI to find the biggest hatch count (1 / 3 / 8 eggs) you own.
	local function detectMax()
		local pgui = lp:FindFirstChild("PlayerGui")
		if not pgui then return nil end
		local best, seen = nil, false
		for _, d in ipairs(pgui:GetDescendants()) do
			local t = guiText(d)
			local n = t and tonumber(t:match("[Hh]atch%s+(%d+)"))
			if n and not d:IsDescendantOf(gui) then
				-- climb to the whole button (stop before a parent that also holds another "Hatch N" label)
				local node = d
				for _ = 1, 4 do
					local par = node.Parent
					if not par or par:IsA("LayerCollector") then break end
					local others = 0
					for _, x in ipairs(par:GetDescendants()) do
						local xt = guiText(x)
						if xt and xt:match("[Hh]atch%s+%d+") then others = others + 1 end
					end
					if others > 1 then break end
					node = par
				end
				local locked, why = false, nil
				-- a lock marker only counts while it is actually visible (owned buttons often keep a hidden lock icon / "Game Pass" label)
				local function visibleIn(x)
					local c = x
					while c and c ~= node.Parent do
						if c:IsA("GuiObject") and not c.Visible then return false end
						if (c:IsA("TextLabel") or c:IsA("TextButton")) and c.TextTransparency >= 0.95 then return false end
						if (c:IsA("ImageLabel") or c:IsA("ImageButton")) and c.ImageTransparency >= 0.95 then return false end
						c = c.Parent
					end
					return true
				end
				for _, x in ipairs(node:GetDescendants()) do
					local xt = guiText(x)
					local hit = (xt and xt:lower():find("game pass", 1, true)) or (x:IsA("ImageLabel") and x.Name:lower():find("lock", 1, true))
					if hit and visibleIn(x) then
						locked, why = true, x:GetFullName()
						break
					end
				end
				if not HA_dbg then HA_dbg = {} end
				HA_dbg[n] = locked and ("locked by " .. tostring(why)) or "owned"
				seen = true
				if not locked and (not best or n > best) then best = n end
			end
		end
		if seen then return best or 1 end
		return nil
	end
	-- AUTO: always try 8 first. The server's answer decides: an answer to a Count=8 request = 8x works (Game Pass or an Octa Hatch Boost),
	-- no answer (rejected) twice in a row = fall back to 3 and try 8 again every hour (boosts come and go).
	HA = HA or {}
	HA.lastFire = -1e9
	-- F CHECK MODE: the Octa (8x) check is done with the game's own "F" auto hatch instead of the 60 s hatch-count test. Every time Auto
	-- Hatch starts (also when it continues after a higher-priority feature finished) F is pressed, the first result the game sends tells if
	-- the game hatches 8 (Octa) or less. F stays on and our own hatch loop runs at the same time with that amount (F is pressed again
	-- only to turn it off when Auto Hatch stops or pauses).
	-- false = the old hatch-count test. (a field on HA because this function is close to Lua's 200-locals limit)
	HA.fMode = true
	HA.own = {}   -- sequence numbers of OUR hatch requests: results of anything else (the game's F) are counted into "Hatched" too
	print("[WORST Hub] build: auto8-probe + restore-hide + scroll-keep")
	local AUTO = { count = 8, fails = 0, nextProbe = 0, ok8 = false, lastEvt = 0, lastData = nil, dumped = 0 }
	HA_auto = AUTO
	local RECHECK = 3600
	-- Debug helper: prints a table recursively.
	local function dump(v, depth)
		depth = depth or 0
		if type(v) ~= "table" then return tostring(v) end
		if depth >= 3 then return "{...}" end
		local out, n = {}, 0
		for k, x in pairs(v) do
			n = n + 1
			if n > 12 then out[#out + 1] = "..."; break end
			out[#out + 1] = tostring(k) .. "=" .. dump(x, depth + 1)
		end
		return "{" .. table.concat(out, ", ") .. "}"
	end
	-- how many pets does this answer contain? (largest list inside it) / did it report a failure?
	local function inspect(d)
		local biggest, failed = nil, false
		-- Debug helper: walks a table (depth-limited) looking for a value.
		local function walk(t, depth)
			if type(t) ~= "table" or depth > 3 then return end
			local n, isList = 0, true
			for k, x in pairs(t) do
				n = n + 1
				if type(k) ~= "number" then isList = false end
				if type(k) == "string" then
					local lk = k:lower()
					if (lk == "success" or lk == "ok") and x == false then failed = true end
					if (lk == "error" or lk == "err" or lk == "reason" or lk == "failed") and x then failed = true end
				end
				walk(x, depth + 1)
			end
			if isList and n > 0 and (not biggest or n > biggest) then biggest = n end
		end
		walk(d, 0)
		return biggest, failed
	end
	pcall(function()
		local egg = RS:WaitForChild("RemoteServices", 10):WaitForChild("EggService", 10):WaitForChild("RE", 10)
		local names = {}
		for _, r in ipairs(egg:GetChildren()) do
			local ln = r.Name:lower()
			if r:IsA("RemoteEvent") and not ln:find("request", 1, true) and not ln:find("delete", 1, true) then
				names[#names + 1] = r.Name
				if r.Name == "EggHatchResult" then AUTO.watching = true end
				connect(r.OnClientEvent, function(d)
					AUTO.lastEvt, AUTO.lastData = os.clock(), d
					if r.Name == "EggHatchResult" and type(d) == "table" then   -- the loop waits for these: next request only after the server answered
						if tonumber(d.Seq) then
							HA.resSeq = math.max(HA.resSeq or 0, d.Seq)
							if not seq or d.Seq > seq then seq = d.Seq end
						end
						if tonumber(d.Speed) then HA.speed = d.Speed end
						if d.Success == false and tonumber(d.Seq) then HA.failSeq = math.max(HA.failSeq or 0, d.Seq) end   -- refused (e.g. too far from the egg)
					end
					if r.Name == "EggHatchResult" and type(d) == "table" and tonumber(d.Rolls) then
						local rolls = tonumber(d.Rolls)
						AUTO.lastRollAt = os.clock()
					HA.lastRolls = rolls
					-- hatches that were not started by our own loop (the game's F) count into "Hatched" as well
					if hEnabled and d.Success ~= false and not HA.own[tonumber(d.Seq) or -1] then hatched = hatched + rolls end
						if rolls >= 8 then AUTO.lastRoll8At = os.clock() end
						-- Auto + we asked for 8: the server tells us right away what it gave
						if HA.isAuto() and AUTO.count == 8 and hCount == 8 and os.clock() - HA.lastFire < 6 then
							if rolls >= 8 then
								AUTO.fails = 0
								if not AUTO.ok8 then print("[WORST Hub] Auto hatch: the server hatched 8 - 8x works") end
								AUTO.ok8 = true
							elseif rolls >= 1 then
								AUTO.count, AUTO.ok8, AUTO.win = 3, false, nil
								AUTO.nextProbe = os.clock() + RECHECK
								print("[WORST Hub] Auto hatch: the server only hatched " .. tostring(rolls) .. " for an 8x request - hatching 3 at a time, testing 8x again in 1 hour")
							end
						end
					end
					if AUTO.dumped < 4 then
						AUTO.dumped = AUTO.dumped + 1
						print("[WORST Hub] Egg event " .. r.Name .. ": " .. dump(d))
					end
				end)
			end
		end
		print("[WORST Hub] Hatch result events watched: " .. table.concat(names, ", "))
	end)
	-- True when "Eggs Per Hatch" is set to Auto.
	function HA.isAuto()
		return not tonumber(tostring(Config.hatchCount or "Auto"):match("^(%d+)$"))
	end
	-- Resets the automatic hatch-count detection back to 8.
	function HA.resetAuto()
		AUTO.count, AUTO.fails, AUTO.win = 8, 0, nil
	end
	-- Ends the pause of the automatic hatch-count detection.
	function HA.resumeAuto()   -- Auto Hatch (re)started: keep what we already know (8x ok / no 8x until the hourly re-check), only restart the test window
		AUTO.win = nil
	end
	-- How many eggs to hatch per press right now (the fixed choice or the Auto result).
	function currentCount()
		local fixed = tonumber(tostring(Config.hatchCount or "Auto"):match("^(%d+)$"))
		if fixed then return fixed end
		if AUTO.count ~= 8 and os.clock() >= AUTO.nextProbe and not HA.fMode then   -- (F mode: the hatch loop re-checks with F instead)
			AUTO.count, AUTO.fails, AUTO.win = 8, 0, nil
			print("[WORST Hub] Auto hatch: re-checking if 8x works (hourly check)")
		end
		return AUTO.count
	end
	-- every "1 in N" pet label that shows up = one pet that was actually hatched; counted so we know how many pets the server really gave us
	local labelSeen = setmetatable({}, { __mode = "k" })
	do
		-- Reacts to a game text label changing while hatching is on (used to read the hatch result).
		local function onLabel(inst)
			if not (hEnabled and inst:IsA("TextLabel")) then return end
			task.delay(0.2, function()
				if inst.Parent and (inst.Text:gsub("<[^>]+>", "")):match("^%s*1%s+in%s+[%d,%.%a]+%s*$") and not labelSeen[inst] then
					labelSeen[inst] = os.clock()
				end
			end)
		end
		local pgui = lp:FindFirstChild("PlayerGui")
		if pgui then connect(pgui.DescendantAdded, onLabel) end
		connect(workspace.DescendantAdded, onLabel)
	end
	-- called after an 8-egg request: did the server really give us 8?
	function HA.verify(fireT)
		local t0 = os.clock()
		while os.clock() - t0 < 3.5 and alive do task.wait(0.1) end
		if not alive then return end
		local pets = 0
		for _, tm in pairs(labelSeen) do if tm >= fireT and tm < fireT + 2 then pets = pets + 1 end end
		local got = AUTO.lastEvt > fireT
		local _, failed = inspect(AUTO.lastData)
		local good
		if pets >= 8 then good = true                       -- 8 pets appeared: 8x works
		elseif pets >= 1 then good = false                  -- fewer pets appeared: the server gave us less than 8
		else good = got and not failed end                  -- no pet labels seen (animation hidden / not detected): trust the server's answer
		AUTO.last = string.format("pets=%d event=%s", pets, tostring(got))
		if good then
			AUTO.fails = 0
			if not AUTO.ok8 then AUTO.ok8 = true; print("[WORST Hub] Auto hatch: 8x works - hatching 8 at a time (" .. AUTO.last .. ")") end
			return true
		end
		AUTO.fails = AUTO.fails + 1
		print("[WORST Hub] Auto hatch: 8x check failed (" .. AUTO.last .. ") " .. AUTO.fails .. "/2")
		if AUTO.fails >= 2 and AUTO.count == 8 then
			AUTO.count, AUTO.ok8 = 3, false
			AUTO.nextProbe = os.clock() + RECHECK
			print("[WORST Hub] Auto hatch: 8x was not accepted - hatching 3 at a time, will try 8x again in 1 hour")
		end
		return false
	end

	-- ---- octa check by HATCH COUNT (Auto): hatch 8x for AUTO.probeSecs seconds, then compare your total hatches (eggs opened) with the
	-- number from before. It went up = you own octa (or the boost is running) -> keep 8x and keep checking every minute.
	-- It did not go up = no octa / the boost expired -> hatch 3 at a time and test 8x again in 1 hour.
	AUTO.probeSecs = 60
	AUTO.hatchesPath = nil   -- optional: path from PlayerGui to the TextLabel that shows your eggs opened, e.g. { "SomeGui", "Frame", "Eggs" }
	-- Reads your total hatch count from the game.
	function HA.readHatches()
		-- Turns text like "1,234" into a number (nil if it is not a plain number).
		local function num(t)
			local d = tostring(t or ""):gsub(",", ""):match("^%s*(%d+)%s*$")
			return d and tonumber(d) or nil
		end
		-- Normalises a hatch-count reading (uses the saved data path once it is known).
		local function norm(x) return tostring(x or ""):lower() end
		if AUTO.hatchesPath then
			local l = walk(pg(), AUTO.hatchesPath)
			local v = l and l:IsA("TextLabel") and num(l.Text)
			if v then AUTO.src = "HATCHES_PATH" return v end
		end
		local ls = lp:FindFirstChild("leaderstats")
		for _, v in ipairs(ls and ls:GetChildren() or {}) do
			local n = v.Name:lower()
			if (n:find("egg") or n:find("hatch")) and v:IsA("ValueBase") and tonumber(v.Value) then
				AUTO.src = "leaderstats." .. v.Name
				return tonumber(v.Value)
			end
		end
		for k, v in pairs(lp:GetAttributes()) do
			local n = tostring(k):lower()
			if (n:find("egg") or n:find("hatch")) and type(v) == "number" then
				AUTO.src = "attribute " .. tostring(k)
				return v
			end
		end
		local plist = pg() and pg():FindFirstChild("PlayerList")
		if plist then
			local me1, me2 = norm(lp.Name), norm(lp.DisplayName)
			for _, d in ipairs(plist:GetDescendants()) do
				if d:IsA("TextLabel") then
					local t = norm(d.Text)
					if t == me1 or t == me2 or t == "@" .. me1 then
						local row = d.Parent
						for _ = 1, 4 do
							if not row or row == plist then break end
							for _, x in ipairs(row:GetDescendants()) do
								if x:IsA("TextLabel") and x ~= d then
									local v = num(x.Text)
									if v then AUTO.src = "PlayerList row" return v end
								end
							end
							row = row.Parent
						end
					end
				end
			end
		end
		return nil
	end
	-- called for every 8x request made in Auto. The first one opens a test window and remembers the hatch count from before it.
	-- returns false when the hatch count can't be read (then the old pet-animation check is used instead)
	function HA.noteFire()
		local w = AUTO.win
		if w then w.fires = w.fires + 1 return true end
		local h = HA.readHatches()
		if not h then
			if not AUTO.warned then
				AUTO.warned = true
				warn("[WORST Hub] Auto hatch: couldn't find your hatch count (leaderstats / player list), so 8x is judged by the pet animation instead. If you know where the number is, set AUTO.hatchesPath.")
			end
			return false
		end
		AUTO.win = { t0 = os.clock(), h0 = h, fires = 1 }
		if not AUTO.ok8 then
			print("[WORST Hub] Auto hatch: testing 8x for " .. tostring(AUTO.probeSecs) .. " s (hatch count now " .. tostring(h) .. ", read from " .. tostring(AUTO.src) .. ")")
		end
		return true
	end
	task.spawn(function()
		while alive do
			task.wait(1)
			local w = AUTO.win
			if w and hEnabled and AUTO.count == 8 and not AUTO.ok8 and AUTO.watching and w.fires >= 2
				and os.clock() - w.t0 >= 6 and (AUTO.lastRollAt or 0) < w.t0 then
				-- the server answers every normal hatch within a second; 8x requests got no answer at all = no octa / boost ended
				AUTO.count, AUTO.win = 3, nil
				AUTO.nextProbe = os.clock() + RECHECK
				hatched = math.max(0, hatched - w.fires * 8)
				print("[WORST Hub] Auto hatch: no hatch result came back for 8x requests - no octa / boost ended. Hatching 3 at a time, testing 8x again in 1 hour")
				w = nil
			end
			if w and hEnabled and AUTO.count == 8 and os.clock() - w.t0 >= AUTO.probeSecs then
				if w.fires < 3 then
					AUTO.win = nil   -- hatching was paused during the window (craft trip, inventory open...): start over
				else
					task.wait(2.5)   -- let the last hatches show up in the count
					if alive and hEnabled and AUTO.win == w then
						local h1 = HA.readHatches()
						AUTO.win = nil
						if h1 == nil then
							print("[WORST Hub] Auto hatch: hatch count disappeared while testing - keeping the current setting")
						elseif h1 > w.h0 then
							AUTO.fails = 0
							if not AUTO.ok8 then print("[WORST Hub] Auto hatch: hatch count went up (" .. tostring(w.h0) .. " -> " .. tostring(h1) .. ") - 8x works, hatching 8 at a time") end
							AUTO.ok8 = true
						elseif os.clock() - (AUTO.lastRoll8At or -1e9) < 15 then
							AUTO.ok8 = true   -- the server itself returned 8 hatches a moment ago: trust that over the hatch counter
						else
							AUTO.count, AUTO.ok8 = 3, false
							AUTO.nextProbe = os.clock() + RECHECK
							hatched = math.max(0, hatched - w.fires * 8)
							print("[WORST Hub] Auto hatch: hatch count did not go up after " .. tostring(w.fires) .. " x8 requests (" .. tostring(w.h0) .. " -> " .. tostring(h1) .. ") - no octa / boost ended. Hatching 3 at a time, testing 8x again in 1 hour")
						end
					end
				end
			end
		end
	end)

	end -- hatch amount do-block

	-- Sends one hatch request to the server with the next sequence number.
	local function fireHatch()
		seq = (seq or (SEQ_FALLBACK - 1)) + 1
		local count = currentCount()
		hCount = count
		HA.lastFire = os.clock()
		local fireT = os.clock()
		local counted = false
		HA.own[seq] = true
		HA.own[seq - 300] = nil
		if HA.isAuto() and count == 8 and not HA.fMode then
			local okN, resN = pcall(HA.noteFire)   -- Auto 8x: judged by the hatch count (see HA.noteFire); an error here must never stop hatching
			counted = okN and resN == true
		end
		local ok, err = pcall(function()
			hatchRemote:FireServer({ Egg = hEgg.name, Count = count, Seq = seq, Auto = AUTO_FLAG })
		end)
		if ok then
			if HA.isAuto() and count == 8 and not counted and not HA.fMode then
				task.spawn(function() if HA.verify(fireT) then hatched = hatched + 8 end end)   -- hatch count unreadable: old pet-animation check
			else
				hatched = hatched + count
			end
		else
			if counted and HA_auto.win then HA_auto.win.fires = math.max(0, HA_auto.win.fires - 1) end
			warn("[Hatch] fire failed: " .. tostring(err))
		end
		return ok
	end

	-- Builds the "holding position" status text for Auto Hatch.
	local function hRunningStatus()
		local s = string.format("%s | holding position (within %d studs)", hEgg.name, TP_RADIUS)
		if DO_HATCH then
			s = s .. string.format(" | Game auto hatch (F) | Hatched: %d", hatched)
		end
		return s
	end

	-- Keeps the character at the egg's spot while Auto Hatch runs.
	local function hTeleportLoop(id)
		local egg = hEgg
		if egg.island and egg.island ~= "" and not isNear(egg.cf, TRAVEL_SKIP_RADIUS) then
			hSetStatus("Traveling to " .. egg.island .. "...")
			local ok, res = pcall(function()
				return travelRemote:InvokeServer({ Source = "Menu", Island = egg.island })
			end)
			if not hActive(id) then return end
			if not (ok and type(res) == "table" and res.Success) then
				warn("[Hatch] Travel did not report success: " .. brief(res))
			end
			hSleep(id, HATCH_SETTLE)
			if not hActive(id) then return end
		end
		while hActive(id) do
			-- only teleport when you're NOT already at the egg spot (outside TP_RADIUS); otherwise leave you alone
			if not isNear(egg.cf) then teleportTo(egg.cf) end
			hReady = true -- the hatch loop starts the moment we have arrived
			if inventoryClosed() then
				hSetStatus(hRunningStatus())
			else
				hSetStatus("Paused: inventory is open / being scanned")
			end
			hSleep(id, TP_INTERVAL)
		end
	end

	-- Main Auto Hatch loop: keeps hatching while it is switched on.
	local function hHatchLoop(id)
		while hActive(id) and not hReady do task.wait() end
		if not hActive(id) then return end
		if HA.fMode and HA.isAuto() and HA.fOctaCheck then pcall(HA.fOctaCheck, id) end   -- start / continue after a priority feature: ask the game (F) if we have Octa
		while hActive(id) do
			if HA.fMode and HA.isAuto() and HA.fOctaCheck and HA_auto.count ~= 8 and os.clock() >= HA_auto.nextProbe then
				pcall(HA.fOctaCheck, id)   -- hourly: a boost may have started in the meantime
				if not hActive(id) then return end
			end
			-- never hatch while the inventory is open (scan running or opened by hand)
			local wait_ = DELAY
			if inventoryClosed() and fireHatch() then
				-- one request at a time: wait for the server's answer to THIS request, then for the hatch time it reports,
				-- so no reveals pile up and nothing is still playing when Auto Hatch is switched off
				local mySeq, t0 = seq, os.clock()
				local limit = (HA.isAuto() and hCount == 8 and not HA_auto.ok8) and 2.5 or 6   -- an 8x test may get no answer at all
				while hActive(id) and (HA.resSeq or 0) < mySeq and os.clock() - t0 < limit do task.wait(0.05) end
				if (HA.resSeq or 0) >= mySeq then
					wait_ = math.max(0.25, tonumber(HA.speed) or DELAY)
					if hActive(id) and (HA.failSeq or 0) >= mySeq and hEgg and hEgg.cf then   -- (only while THIS hatch run is still the active one, so a feature with a higher priority is never pulled back) the server refused this hatch: probably too far away, go back to the egg spot
						HA.refusals = (HA.refusals or 0) + 1
						if HA.refusals >= 3 and os.clock() - (HA.lastRestart or 0) > 30 then
							-- FIX: the first run after loading can get refused over and over; restarting the run (same as toggling Auto Hatch off/on) clears it
							HA.refusals, HA.lastRestart = 0, os.clock()
							print("[WORST Hub] Auto hatch: 3 refusals in a row - restarting the hatch run")
							task.spawn(HA.restart)
							return
						end
						print("[WORST Hub] Auto hatch: the server refused the hatch - teleporting back to the egg spot")
						teleportTo(hEgg.cf)
					else
						HA.refusals = 0
					end
				else
					wait_ = DELAY
					if hActive(id) and hEgg and hEgg.cf and not (HA.isAuto() and hCount == 8 and not HA_auto.ok8) then   -- no answer at all (an 8x test may legitimately get none): same fix
						print("[WORST Hub] Auto hatch: no answer from the server - teleporting back to the egg spot")
						teleportTo(hEgg.cf)
					end
				end
			end
			hSleep(id, wait_)
		end
	end

	-- ---- the game's own "F" key (starts / stops the game's auto hatch; its "This Session" panel only shows while it is on) ----
	-- Order: Auto Hatch starts -> the Octa (8x) check is settled (Auto mode: 8x confirmed, or no 8x for the next hour; a fixed
	-- Hatch 1 / 3 / 8 has nothing to check) -> F is pressed once. When Auto Hatch stops (switched off, paused for a feature with a
	-- higher priority, egg changed, hub closed) F is pressed again so the game's auto hatch is fully off too.
	local F_DELAY       = 1.0    -- seconds to wait after the Octa check is settled before pressing F
	local F_OCTA_WAIT   = 120    -- never wait longer than this for the Octa check (then F is pressed anyway)
	local F_CHECK_PANEL = true   -- true = if the game's "This Session" panel is already showing (its auto hatch is already on), do not press F
	local fOn = false            -- did WE press F (so we must press it again to turn it off)
	-- Presses the game's F key (used to check for / use the 8x hatch).
	local function pressF()
		HA.lastF = os.clock()
		pcall(function()
			VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)
			task.wait(0.05)
			VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
		end)
	end
	-- True if the game's hatch session panel is open.
	local function sessionPanelOpen()
		local root = pg()
		if not root then return false end
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("TextLabel") and (d.Text:gsub("<[^>]+>", "")):match("^%s*This Session%s*$") then
				local o, shown = d, true
				while o and o ~= root do
					if o:IsA("GuiObject") and not o.Visible then shown = false break end
					if o:IsA("LayerCollector") and not o.Enabled then shown = false break end
					o = o.Parent
				end
				if shown then return true end
			end
		end
		return false
	end
	-- True once the Octa (8x) detection has finished.
	local function octaSettled()
		if not HA.isAuto() then return true end
		if HA_auto.ok8 then return true end                                   -- 8x confirmed (Octa owned / boost running)
		return HA_auto.count ~= 8 and os.clock() < HA_auto.nextProbe          -- tested: no 8x, next test in 1 hour
	end
	-- Starts the F-only hatch: travel to the island, teleport to the egg, hatch with F.
	local function startFHatch(id)
		-- F-ONLY HATCH: travel to the island, teleport to the egg (hTeleportLoop sets hReady), wait F_DELAY, press F ONCE. Nothing else:
		-- no hatch requests of our own, no Octa check. When Auto Hatch pauses (a priority feature) or stops, stopFHatch() presses F again.
		task.spawn(function()
			while hActive(id) and not hReady do task.wait(0.1) end   -- at the island and at the egg
			if not hActive(id) then return end
			local t1 = os.clock()
			while hActive(id) and os.clock() - t1 < F_DELAY do task.wait(0.1) end
			while hActive(id) and not inventoryClosed() do task.wait(0.25) end   -- never while the inventory is open / being scanned
			if not hActive(id) or fOn then return end
			if F_CHECK_PANEL and sessionPanelOpen() then
				fOn = true   -- the game's auto hatch is already on: F not pressed now, but it is pressed (off) when Auto Hatch pauses / stops
				print("[WORST Hub] Auto hatch: the game's auto hatch is already on - F not pressed")
				return
			end
			pressF()
			fOn = true
			print("[WORST Hub] Auto hatch: at the egg, pressed F (game's auto hatch on)")
			local tv = os.clock()   -- F must really have switched it on, or pressing F again later would switch it ON
			while hActive(id) and os.clock() - tv < 3 and not sessionPanelOpen() do task.wait(0.25) end
			if hActive(id) and not sessionPanelOpen() then
				fOn = false
				print("[WORST Hub] Auto hatch: the game's auto hatch did not start after F")
			end
		end)
	end
	-- Stops the F-only hatch.
	local function stopFHatch()
		-- the game's own panel decides (fOn alone can be wrong: F started late / was switched by hand), so pressing F never turns it ON by mistake
		local open = sessionPanelOpen()
		local recent = os.clock() - (HA.lastF or -1e9) < 5   -- just pressed: the panel may not be showing yet
		local was = fOn
		fOn = false
		if open or (was and recent) then
			pressF()
			print("[WORST Hub] Auto hatch: pressed F again (game's auto hatch off)")
		end
	end

	-- F Octa check: press F (once), wait for the first hatch result of the GAME's auto hatch (EggHatchResult: Rolls 8 = Octa).
	-- F stays ON afterwards: the game's auto hatch and our own hatch loop run at the same time. F is only pressed again to turn it off
	-- when Auto Hatch stops / pauses (stopFHatch), and pressed to turn it on again the next time hatching starts or resumes.
	HA.fCheckTimeout = 10   -- seconds to wait for the game's first result (a field: buildLogic is near the 200-locals limit)
	-- Checks whether you own Octa (8x) by using the F key.
	function HA.fOctaCheck(id)
		while hActive(id) and not inventoryClosed() do task.wait(0.25) end   -- never while the inventory is open / being scanned
		if not hActive(id) then return end
		local t0 = os.clock()
		local alreadyOn = fOn or (F_CHECK_PANEL and sessionPanelOpen())   -- the game's auto hatch is already running: do not press F again, just read its results
		if not alreadyOn then pressF() fOn = true end
		while hActive(id) and (HA_auto.lastRollAt or 0) < t0 and os.clock() - t0 < HA.fCheckTimeout do task.wait(0.05) end
		-- the run ended during the check (egg changed, paused for a priority feature, switched off): stopFHatch() already pressed F off
		-- for us, pressing here as well would turn the game's auto hatch back ON. The next run does a fresh check at its egg.
		if not hActive(id) then return end
		local got = (HA_auto.lastRollAt or 0) >= t0 and HA.lastRolls or nil
		-- F stays on (both auto hatches run together). Only when the game never answered AND its panel is not showing, F did not switch
		-- on: forget it, so that stopping later does not press F and turn it ON.
		if not got and fOn and not sessionPanelOpen() then fOn = false end
		if got and got >= 8 then
			HA_auto.count, HA_auto.ok8, HA_auto.fails, HA_auto.win = 8, true, 0, nil
			print("[WORST Hub] Auto hatch: F check - the game hatches 8 at a time (Octa). Hatching 8")
		elseif got then
			HA_auto.count, HA_auto.ok8, HA_auto.win = 3, false, nil
			HA_auto.nextProbe = os.clock() + 3600
			print("[WORST Hub] Auto hatch: F check - the game hatches " .. tostring(got) .. " at a time (no Octa). Hatching 3, checking again in 1 hour or when hatching continues")
		else
			HA_auto.nextProbe = os.clock() + 60
			print("[WORST Hub] Auto hatch: F check - no hatch result from the game within " .. HA.fCheckTimeout .. " s, keeping the current amount and trying again in 1 minute")
		end
	end

	-- Switches Auto Hatch on or off (starts or stops its loops).
	local function setHatchEnabled(on)
		if on == hEnabled then return end
		hEnabled = on
		hRunId = hRunId + 1
		hReady = false
		local id = hRunId
		if on then
			if HA.isAuto() then HA.resumeAuto() end   -- Auto: keep what the last hatch-count test found; restart the test window
			hEgg = selectedEgg
			task.spawn(hTeleportLoop, id)
			if DO_HATCH then
				task.spawn(hHatchLoop, id)   -- our own hatch requests (remote), after the Octa check
				startFHatch(id)              -- and the game's own auto hatch (F), pressed once
			end
		else
			hSetStatus(hatchEntry.desc)
			stopFHatch()   -- press F again: the game's auto hatch off too
		end
	end

	-- ---- PRIORITY (set in the Priority tab; default 1) Craft  2) Enchant  3) Hatch) ----
	-- A feature only runs while nothing ranked above it is working or waiting. "Craft" = Auto Craft + Diamond + Rainbow + Collect.
	-- HG.want = the Auto Hatch toggle as you set it; the hatch itself is started / paused automatically from it.
	local tripOwner = nil   -- who is on a machine trip right now (only one at a time)
	local HG = { want = false, waiting = {}, order = { "DoubleJump", "Balloon", "Craft", "TrickOrTreat", "HallowLord", "PetDefense", "Dig", "Hatch" } }   -- waiting[name] = rank of a feature queued for the machine
	HG.fpsEvents = { Halloween = true, HalloweenBoss = true, PetDefense = true, Dig = true, Balloon = true, DoubleJump = true }   -- trips that need more than the Mini Ui's 5 FPS
	HG.rank = function(kind)
		for i, k in ipairs(HG.order) do if k == kind then return i end end
		return 99
	end
	HG.prio = function(name)
		if name == "Halloween" then return HG.rank("TrickOrTreat") end      -- Auto Trick or Treat and Auto Kill Hallow Lord each have their own spot in the Priority tab
		if name == "HalloweenBoss" then return HG.rank("HallowLord") end
		if name == "Dig" then return HG.rank("Dig") end   -- Auto Dig has its own spot in the Priority tab
		if name == "Balloon" then return HG.rank("Balloon") end   -- so has Auto Balloons
		if name == "PetDefense" then return HG.rank("PetDefense") end
		return HG.rank(name == "DoubleJump" and "DoubleJump" or "Craft")
	end
	HG.higher = function(p) -- is anything with a better priority than p waiting for the machine?
		for _, q in pairs(HG.waiting) do if q < p then return true end end
		return false
	end
	HG.hatchFirst = function(p) -- does Auto Hatch (switched on) outrank a feature of rank p?
		return HG.want and HG.rank("Hatch") < p
	end
	HG.sync = function()
		local run = HG.want and tripOwner == nil and not HG.hold and not HG.kwHold
		if run then
			local hr = HG.rank("Hatch")
			for _, q in pairs(HG.waiting) do if q < hr then run = false break end end
		end
		if run == hEnabled then return end
		setHatchEnabled(run)
		if not run and HG.want then
			local who = tripOwner
			if not who then
				local best = 99
				for n, q in pairs(HG.waiting) do if q < best then best, who = q, n end end
			end
			hSetStatus((HG.hold or HG.kwHold) and "Waiting for Auto Delete to finish before hatching..." or ("Paused - " .. tostring(who or "a feature with a higher priority") .. " is working"))
		end
	end
	-- Kaitun Stats only works while this is true: Auto Hatch is really running (not paused by Craft / events / Auto Delete) and you are at the egg
	HG.isHatching = function() return alive and hEnabled == true and hReady == true end
	-- restarts the hatch run (off, short wait, then HG.sync decides whether it may run again)
	HA.restart = function()
		setHatchEnabled(false)
		task.wait(0.5)
		HG.sync()
	end
	HG.save = function()
		pcall(function() Store.write("priority.txt", table.concat(HG.order, ",")) end)
	end
	HG.move = function(index, delta) -- moves the item at `index` up (-1) or down (+1)
		local to = index + delta
		if to < 1 or to > #HG.order then return false end
		HG.order[index], HG.order[to] = HG.order[to], HG.order[index]
		HG.save()
		HG.sync()
		return true
	end
	do -- load the saved order
		local okR, raw = pcall(function() return Store.read("priority.txt") end)
		if okR and type(raw) == "string" then
			local seen, list = {}, {}
			-- Adds the names from a comma separated text to a list.
			local function add(n) if not seen[n] then seen[n] = true list[#list + 1] = n end end
			for name in raw:gmatch("[^,%s]+") do
				if name == "Halloween" then   -- older file: one Halloween entry -> now two separate ones, kept side by side
					add("TrickOrTreat") add("HallowLord")
				elseif name == "Craft" or name == "Enchant" or name == "Hatch" or name == "TrickOrTreat" or name == "HallowLord" or name == "Dig" or name == "PetDefense" or name == "Balloon" then
					add(name)
				end
			end
			for _, need in ipairs({ "TrickOrTreat", "HallowLord", "PetDefense", "Dig" }) do   -- file saved before these entries existed: put them just above Hatch
				if not seen[need] then
					local at = table.find(list, "Hatch") or (#list + 1)
					table.insert(list, at, need)
					seen[need] = true
				end
			end
			if not seen.Balloon then table.insert(list, 1, "Balloon") seen.Balloon = true end   -- file saved before Balloons existed: it goes first (balloons do not last long)
			-- Migrate existing saved priorities: Enchant is location-independent now.
            local migrated = {}
            local present = {}
            for _, kind in ipairs(list) do
                if kind ~= "Enchant" and kind ~= "DoubleJump" and not present[kind] then
                    migrated[#migrated + 1] = kind
                    present[kind] = true
                end
            end
            for _, kind in ipairs({ "Balloon", "Craft", "TrickOrTreat", "HallowLord", "PetDefense", "Dig", "Hatch" }) do
                if not present[kind] then migrated[#migrated + 1] = kind end
            end
            HG.order = { "DoubleJump" }
            for _, kind in ipairs(migrated) do HG.order[#HG.order + 1] = kind end
		end
	end

	-------------------------------------------------------------------------- CRAFT
	local enabled = false
	local runId = 0
	local crafts = 0
	local usedIds = {}
	local lastResult = nil
	local lastGroups = nil
	local lastScanAt = -1e9        -- os.clock() of the last successful scan
	local lastTryAt = -1e9         -- os.clock() of the last scan attempt (even a failed one)
	local lastCraftable = 0
	local spent = {}               -- pet ids already used by a craft since the last scan
	local jobFillers = {}          -- functions that refresh the Diamond / Rainbow dropdowns after every scan
	local ALL_OPT = "All pets"
	local selKey, selText = nil, nil
	local selAll = false           -- "All pets" picked in the Pet to Craft dropdown
	local craftWant = {}           -- pet key -> Golden crafts still wanted (from the + / - counters of Pet to Craft)
	local curKey, curText = nil, nil -- the pet type the Golden craft is working on right now
	local scanBusy = false
	local storageMin = 0           -- "Craft When Storage Is" slider (percent); 0 = craft whenever possible
	local wakeTick = 0             -- bumped when the slider moves: wakes every craft loop so it re-checks the gate right away
	local lastStorage = nil        -- { used, max, pct } read from the inventory during the last scan
	local optionInfo = {}      -- dropdown text -> { key, text }
	local fillOptions, getGroups   -- defined further down (the Craft monitor, the scan loop and the pet jobs all use them)

	local keepRun = 0          -- run id of the Auto Scan Inventory toggle

	local resultConn = resultRemote.OnClientEvent:Connect(function(data)
		if type(data) == "table" then lastResult = data end
	end)
	table.insert(cleanupHooks, function()
		HG.want = false
		hEnabled, enabled = false, false
		stopFHatch()
		hRunId = hRunId + 1
		runId = runId + 1
		pcall(function() resultConn:Disconnect() end)
	end)

	-- True while this priority-system run is still the current one.
	local function active(id) return alive and enabled and runId == id end
	-- Waits up to `seconds` while the run is still active.
	local function sleepWhile(id, seconds)
		local t0 = os.clock()
		while active(id) and os.clock() - t0 < seconds do task.wait(0.1) end
	end
	-- Waits `seconds` or until stillActive() turns false.
	local function sleepFor(stillActive, seconds)
		local t0 = os.clock()
		while alive and stillActive() and os.clock() - t0 < seconds do task.wait(0.1) end
	end
	-- like sleepWhile / sleepFor, but ends early when the "Craft When Storage Is" slider changes (used only for the idle waits between checks)
	local function napWhile(id, seconds)
		local t0, w0 = os.clock(), wakeTick
		while active(id) and wakeTick == w0 and os.clock() - t0 < seconds do task.wait(0.1) end
	end
	-- Like sleepFor, but wakes up early when the priority system wakes it.
	local function napFor(stillActive, seconds)
		local t0, w0 = os.clock(), wakeTick
		while alive and stillActive() and wakeTick == w0 and os.clock() - t0 < seconds do task.wait(0.1) end
	end

	-- Travel to an island, WAIT until the game's own teleport has actually put you there, and only then teleport to the machine.
	-- (Before, our teleport could fire while the game's travel teleport was still in flight: the two overlapped and the character
	-- never reached the machine.) Afterwards it checks you are really at the machine and teleports again if not.
	function HG.travelAndTeleport(stillActive, island, cf, statusFn, skipRadius)
		local TRAVEL_MIN_WAIT, TRAVEL_MAX_WAIT, ARRIVE_WAIT = 4, 14, 3
		local hrp0 = getHRP()
		local before = hrp0 and hrp0.Position
		-- already within skipRadius studs of the spot: no island Travel, just teleport straight to it
		if skipRadius and isNear(cf, skipRadius) then
			for attempt = 1, 3 do
				if not stillActive() then return false end
				statusFn("Already close - teleporting straight to the machine...")
				teleportTo(cf)
				sleepFor(stillActive, 1)
				if isNear(cf, 30) then return true end
			end
			return isNear(cf, 30)
		end
		local okT, res = pcall(function() return travelRemote:InvokeServer({ Source = "Menu", Island = island }) end)
		if not (okT and type(res) == "table" and res.Success) then
			warn("[Travel] to " .. tostring(island) .. " did not report success: " .. brief(res))
		end
		-- 1) give the game time to move you: at least TRAVEL_MIN_WAIT s, longer while you are still moving between islands
		local t0, moved, lastPos, stableSince = os.clock(), false, before, os.clock()
		while alive and stillActive() do
			task.wait(0.2)
			local h = getHRP()
			if h then
				local pos = h.Position
				if before and (pos - before).Magnitude > 30 then moved = true end
				if lastPos and (pos - lastPos).Magnitude > 2 then stableSince = os.clock() end
				lastPos = pos
			end
			local waited = os.clock() - t0
			if waited >= TRAVEL_MAX_WAIT then break end
			if waited >= TRAVEL_MIN_WAIT then
				if moved and os.clock() - stableSince >= 1 then break end   -- it moved and has stopped moving
				if not moved and waited >= TRAVEL_MIN_WAIT + 2 then break end   -- never moved: probably already on that island
			end
		end
		if not stillActive() then return false end
		sleepFor(stillActive, CRAFT_SETTLE)
		-- 2) now our own teleport, then a few seconds to land; check it worked and retry if the game moved you again
		for attempt = 1, 3 do
			if not stillActive() then return false end
			statusFn(attempt == 1 and "Teleporting to the machine..." or ("Teleporting to the machine (try " .. attempt .. ")..."))
			teleportTo(cf)
			sleepFor(stillActive, ARRIVE_WAIT)
			if isNear(cf, 30) then return true end
		end
		warn("[Travel] could not get to the machine spot after 3 tries")
		return isNear(cf, 30)
	end

	-- Direct machine teleport for crafting jobs only; island travel is unnecessary.
	local function directCraftTeleport(stillActive, cf, statusFn)
		for attempt = 1, 3 do
			if not stillActive() then return false end
			statusFn(attempt == 1 and "Teleporting directly to crafting machine..." or ("Retrying machine teleport (" .. attempt .. "/3)..."))
			teleportTo(cf)
			sleepFor(stillActive, 0.5)
			if isNear(cf, 30) then return true end
		end
		return isNear(cf, 30)
	end

	-- ---- PRIORITY IS ABSOLUTE ----
	-- HG.blocker(name) answers "what is in front of this feature?" (nil = nothing, it may go). Every feature asks it BEFORE it does anything
	-- (scan, close the inventory, travel ...) and the answer is written to its status line, so a feature that is not doing anything says why.
	HG.blocker = function(name)
		local p = HG.prio(name)
		if tripOwner ~= nil then
			return string.format("%s is on a machine trip right now (a trip can't be interrupted)", tostring(tripOwner))
		end
		local bestN, bestQ
		for n, q in pairs(HG.waiting) do
			if n ~= name and q < p and (not bestQ or q < bestQ) then bestN, bestQ = n, q end
		end
		if bestN then
			return string.format("%s (priority %d) is waiting for the machine and outranks it (priority %d)", tostring(bestN), bestQ, p)
		end
		if HG.hatchFirst(p) then
			return string.format("Auto Hatch (priority %d) is switched on and ranked above it (priority %d)", HG.rank("Hatch"), p)
		end
		return nil
	end
	-- waits until nothing outranks `name`; returns false if the feature was switched off meanwhile
	HG.gate = function(name, stillActive, say)
		local last
		while alive and stillActive() do
			local why = HG.blocker(name)
			if not why then return true end
			if why ~= last then
				last = why
				if say then pcall(say, "[Priority] Waiting - " .. why) end
			end
			task.wait(0.5)
		end
		return false
	end

	-- only one feature may travel / use a machine at a time
	-- (the lock is handed to the best priority first; Auto Hatch is paused meanwhile). say = the feature's status line (debug text while it waits)
	local function acquireTrip(name, stillActive, say)
		HG.waiting[name] = HG.prio(name)
		HG.sync() -- pauses auto hatch right away
		local lastWhy, lastAt = nil, 0
		while alive and stillActive() do
			local why = HG.blocker(name)
			if not why then
				tripOwner = name
				HG.waiting[name] = nil
				if HG.fpsEvents[name] then Config.fpsEvent(true) end   -- Mini Ui: 30 FPS for the whole event trip (5 FPS makes jumps glitch)
				HG.sync()
				return true
			end
			if say and (why ~= lastWhy or os.clock() - lastAt > 5) then
				lastWhy, lastAt = why, os.clock()
				pcall(say, "[Priority] Waiting - " .. why)
			end
			task.wait(0.5)
		end
		HG.waiting[name] = nil
		HG.sync()
		return false
	end
	-- Gives the "trip" (the right to travel) back so another feature can use it.
	local function releaseTrip(name)
        if tripOwner == name then
            tripOwner = nil
            if HG.fpsEvents[name] then Config.fpsEvent(false) end
        end
        HG.sync() -- hatch comes back only when nothing else is running or waiting
    end
    HG.acquireTrip = acquireTrip
    HG.releaseTrip = releaseTrip
    HG.owner = function() return tripOwner end   -- Home tab: what is running right now

	-- ---- inventory scan ----
	local function invGui() return walk(pg(), { "Tabs", "Inventory" }) end
	-- True if the Inventory menu is open.
	local function invIsOn() local g = invGui() return g ~= nil and g.Enabled == true end
	inventoryClosed = function() return not scanBusy and not invIsOn() end

	-- Clicks a GUI button by firing its connections.
	local function click(btn)
		if not btn or type(getconnections) ~= "function" then return false end
		local fired = false
		for _, sig in ipairs({ "MouseButton1Click", "Activated", "MouseButton1Down" }) do
			pcall(function()
				for _, c in ipairs(getconnections(btn[sig])) do c:Fire() fired = true end
			end)
		end
		return fired
	end

	-- Waits until fn() returns true or the timeout is over.
	local function waitFor(fn, timeout)
		local t0 = os.clock()
		while os.clock() - t0 < timeout do
			local ok, v = pcall(fn)
			if ok and v then return v end
			task.wait(0.3)
		end
		return nil
	end

	-- Forces a menu GUI to be enabled.
	local function forceOn(o)
		if not o then return end
		if o:IsA("ScreenGui") and o.Enabled ~= true then o.Enabled = true end
		if o:IsA("GuiObject") and o.Visible ~= true then o.Visible = true end
	end

	-- Opens a game menu by pressing its button; returns true once it is open.
	local function openMenu(name, btnPath)
		-- Returns the menu's ScreenGui.
		local function gui_() return walk(pg(), { "Tabs", name }) end
		-- True if the menu is open.
		local function on() local g = gui_() return g ~= nil and g.Enabled == true end
		if on() then return true end
		click(walk(pg(), btnPath))
		waitFor(gui_, 5)
		if waitFor(on, 2) then return true end
		click(walk(pg(), btnPath))
		if waitFor(on, 3) then return true end
		forceOn(gui_())
		forceOn(walk(gui_(), { "Menu" }))
		return waitFor(on, 3) ~= nil
	end

	-- How many pet cards are in the inventory list.
	local function cardCount()
		local n = 0
		local g = invGui()
		if g then
			for _, d in ipairs(g:GetDescendants()) do
				if d.Name:sub(1, 4) == "Pet_" and d:GetAttribute("PetId") then n = n + 1 end
			end
		end
		return n
	end

	-- Opens the inventory menu (true when it is open and has cards).
	local function openInventory()
		if invIsOn() and cardCount() > 0 then return true end
		openMenu("Inventory", { "Game", "Bottom", "Pets", "Button" })
		click(walk(invGui(), { "Menu", "Tabs", "Pets", "Button" }))
		local t0 = os.clock()
		while os.clock() - t0 < 12 do
			task.wait(0.4)
			if invIsOn() and cardCount() > 0 then break end
		end
		local last, stable = -1, 0
		while stable < 3 and os.clock() - t0 < 18 do
			task.wait(0.5)
			local n = cardCount()
			if n == last then stable = stable + 1 else stable, last = 0, n end
		end
		return invIsOn()
	end

	-- Closes the inventory menu.
	local function closeInventory()
		if not invIsOn() then return end
		local close = walk(invGui(), { "Menu", "Close" })
		if close then
			for _, d in ipairs(close:GetDescendants()) do
				if d:IsA("TextButton") or d:IsA("ImageButton") then click(d) break end
			end
		end
		task.wait(0.8)
		if invIsOn() then
			click(walk(pg(), { "Game", "Bottom", "Pets", "Button" }))
			task.wait(0.8)
		end
		if invIsOn() then invGui().Enabled = false end
	end

	-- Called before every auto feature runs: waits until the inventory is closed (and no scan is running).
	-- If the inventory stays open for a few seconds on its own (opened by hand), it is closed.
	local function ensureInventoryClosed(stillActive)
		local t0 = os.clock()
		while alive and stillActive() do
			-- Site_Panel (trade agent) is mid-trade: hold every auto feature (craft / trips) until it is over
			if env.TSR_TRADE_BUSY then t0 = os.clock(); task.wait(0.3); continue end
			if inventoryClosed() then return true end
			local waited = os.clock() - t0
			if waited > 4 and not scanBusy and invIsOn() then
				pcall(closeInventory)
			end
			if waited > 90 then return false end
			task.wait(0.3)
		end
		return false
	end

	-- True if this pet card is locked.
	local function cardLocked(card_)
		local lk = card_:FindFirstChild("Lock")
		return lk ~= nil and lk:IsA("GuiObject") and lk.Visible
	end

	-- True if this pet card is in the equipped section.
	local function cardEquipped(card_, stopAt)
		local p = card_.Parent
		while p and p ~= stopAt do
			if p.Name == "Equipped" then return true end
			p = p.Parent
		end
		return false
	end

	-- Reads a pet card's stack count.
	local function stackOf(card_)
		local sc = card_:FindFirstChild("StackCount")
		if sc and sc:IsA("GuiObject") and sc.Visible then
			local lb = sc:FindFirstChild("Label")
			local num = lb and lb:IsA("TextLabel") and lb.Text:gsub(",", ""):match("%d+")
			return tonumber(num) or 1
		end
		return 1
	end

	local SUFFIX = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15, qi = 1e18, sx = 1e21, sp = 1e24, oc = 1e27, no = 1e30, dc = 1e33 }
	-- Parses a multiplier text (like "x5") into a number.
	local function parseMulti(txt)
		if not txt then return nil end
		local num, suf = tostring(txt):gsub(",", ""):match("([%d%.]+)%s*(%a*)")
		local n = tonumber(num)
		if not n then return nil end
		local mult = (suf == "" and 1) or SUFFIX[suf:lower()]
		if not mult then return nil end
		return n * mult
	end

	-- ---- hide the Inventory window while the script uses it ----
	-- The window still opens and fills with pet cards (so the scan works), but every top-level frame of it
	-- is kept at Visible = false. If the game turns one back on, it is switched off again immediately
	-- (property signal) and also every frame, so it is never drawn. Original values are restored afterwards.
	local hiding = false
	local hideConn
	local hideSignals = {}
	local hiddenOrig = {}
	local effectOrig = {}

	-- the game also blurs the world while the Inventory is open: keep any Blur / Depth of Field effect off too
	local function hideEffect(e, preexisting)
		local isBlur = e:IsA("BlurEffect")
		if not (isBlur or e:IsA("DepthOfFieldEffect")) then return end
		if effectOrig[e] == nil then
			effectOrig[e] = { enabled = e.Enabled, size = isBlur and e.Size or nil, new = not preexisting }
			table.insert(hideSignals, e:GetPropertyChangedSignal("Enabled"):Connect(function()
				if hiding and e.Enabled then e.Enabled = false end
			end))
			if isBlur then
				table.insert(hideSignals, e:GetPropertyChangedSignal("Size"):Connect(function()
					if hiding and e.Size ~= 0 then e.Size = 0 end
				end))
			end
		end
		if e.Enabled then e.Enabled = false end
		if isBlur and e.Size ~= 0 then e.Size = 0 end
	end

	-- Hides blur / colour effects the game adds (used while the script works inside menus).
	local function sweepEffects(preexisting)
		for _, parent in ipairs({ game:GetService("Lighting"), workspace.CurrentCamera }) do
			if parent then
				for _, e in ipairs(parent:GetChildren()) do hideEffect(e, preexisting) end
			end
		end
	end

	-- the game also hides the rest of the HUD (Shop, Trade, stats...) while the Inventory is open.
	-- Before the scan, everything that is showing (ScreenGuis and their frames, 3 levels deep) is remembered and
	-- kept the way it was: re-enabled / made visible again, put back in place, and un-faded if the game
	-- turns it off, slides it away or fades it out. Nothing in the Tabs folder, the hub or the Inventory is touched.
	local KEEP_DEPTH = 3
	local KEEP_SKIP = { "notif", "popup", "toast", "alert", "message", "announce", "tooltip", "hint" }
	local keepEn, keepVis, keepPos, keepGT = {}, {}, {}, {}
	local keepLogged = 0

	-- Prints a note about a UI object that was kept visible (limited to 40 lines).
	local function logKeep(o, what)
		if keepLogged < 40 then
			keepLogged = keepLogged + 1
			print("[Craft] kept " .. what .. ": " .. o:GetFullName())
		end
	end

	-- True if a UI object should be skipped by the hiding code (by its name).
	local function skipName(o)
		local lname = o.Name:lower()
		for _, w in ipairs(KEEP_SKIP) do
			if lname:find(w, 1, true) then return true end
		end
		return false
	end

	-- Decides for one UI object whether it stays visible while the rest is hidden.
	local function keepOne(o, depth)
		if o:IsA("ScreenGui") then
			if not o.Enabled or keepEn[o] then return end
			keepEn[o] = true
			table.insert(hideSignals, o:GetPropertyChangedSignal("Enabled"):Connect(function()
				if hiding and not o.Enabled then o.Enabled = true logKeep(o, "enabled") end
			end))
			return
		end
		if not o:IsA("GuiObject") then return end
		if o.Visible and not keepVis[o] then
			keepVis[o] = true
			table.insert(hideSignals, o:GetPropertyChangedSignal("Visible"):Connect(function()
				if hiding and not o.Visible then o.Visible = true logKeep(o, "visible") end
			end))
		end
		if depth == 1 and keepPos[o] == nil then -- top-level HUD frames: stop them from sliding away
			local home = o.Position
			keepPos[o] = home
			table.insert(hideSignals, o:GetPropertyChangedSignal("Position"):Connect(function()
				if hiding and o.Position ~= home then o.Position = home logKeep(o, "in place") end
			end))
		end
		if o:IsA("CanvasGroup") and keepGT[o] == nil then -- stop fade-outs
			local gt = o.GroupTransparency
			keepGT[o] = gt
			table.insert(hideSignals, o:GetPropertyChangedSignal("GroupTransparency"):Connect(function()
				if hiding and o.GroupTransparency > gt + 0.001 then o.GroupTransparency = gt logKeep(o, "unfaded") end
			end))
		end
	end

	-- Applies keepOne to a whole tree of UI objects.
	local function keepTree(o, depth)
		if depth > 0 and skipName(o) then return end
		keepOne(o, depth)
		if depth < KEEP_DEPTH then
			for _, c in ipairs(o:GetChildren()) do keepTree(c, depth + 1) end
		end
	end

	-- Keeps the HUD parts that must stay visible while everything else is hidden.
	local function keepHud()
		local root = pg()
		if not root then return end
		local ig = invGui()
		local tabs = root:FindFirstChild("Tabs")
		for _, sg in ipairs(root:GetDescendants()) do
			if sg:IsA("ScreenGui") and sg ~= gui
				and not (ig and ig:IsDescendantOf(sg))
				and not (tabs and sg:IsDescendantOf(tabs)) then
				keepTree(sg, 0)
			end
		end
	end

	-- Hides one GUI object.
	local function hideObj(c)
		if not c:IsA("GuiObject") then return end
		if hiddenOrig[c] == nil then
			hiddenOrig[c] = c.Visible
			table.insert(hideSignals, c:GetPropertyChangedSignal("Visible"):Connect(function()
				if hiding and c.Visible then c.Visible = false end
			end))
		end
		if c.Visible then c.Visible = false end
	end

	-- Starts hiding the game's UI (used while the script operates menus in the background).
	local function startHiding()
		if hiding then return end
		hiding = true
		keepLogged = 0
		sweepEffects(true)
		keepHud()
		local g = invGui()
		if g then
			local names = {}
			for _, c in ipairs(g:GetChildren()) do
				names[#names + 1] = c.Name .. "(" .. c.ClassName .. ")"
				hideObj(c)
			end
			print("[Craft] hiding Inventory children: " .. table.concat(names, ", "))
		end
		hideConn = game:GetService("RunService").RenderStepped:Connect(function()
			sweepEffects(false)
			for o in pairs(keepEn) do
				if o.Parent and not o.Enabled then o.Enabled = true end
			end
			for o in pairs(keepVis) do
				if o.Parent and not o.Visible then o.Visible = true end
			end
			for o, home in pairs(keepPos) do
				if o.Parent and o.Position ~= home then o.Position = home end
			end
			for o, gt in pairs(keepGT) do
				if o.Parent and o.GroupTransparency > gt + 0.001 then o.GroupTransparency = gt end
			end
			local gi = invGui()
			if not gi then return end
			for _, c in ipairs(gi:GetChildren()) do hideObj(c) end
		end)
	end

	-- Stops hiding and restores the game's UI.
	local function stopHiding()
		hiding = false
		if hideConn then hideConn:Disconnect() hideConn = nil end
		for _, sig in ipairs(hideSignals) do sig:Disconnect() end
		hideSignals = {}
		for c, vis in pairs(hiddenOrig) do
			if c.Parent then c.Visible = vis end
		end
		hiddenOrig = {}
		for e, o in pairs(effectOrig) do
			if e.Parent then
				e.Enabled = o.enabled
				-- an effect the game created for the Inventory goes back to size 0 (no blur); older ones get their old size
				if o.size ~= nil then e.Size = o.new and 0 or o.size end
			end
		end
		effectOrig = {}
		keepEn, keepVis, keepPos, keepGT = {}, {}, {}, {}
	end

	-- Returns the pet list frame of the inventory.
	local function petList()
		return walk(invGui(), { "Menu", "Categories", "Pets", "Inner", "List" })
	end

	-- unload: let a running scan finish (it closes the inventory itself), then give the HUD back
	table.insert(cleanupHooks, function()
		keepRun = keepRun + 1
		task.spawn(function()
			local t0 = os.clock()
			while scanBusy and os.clock() - t0 < 30 do task.wait(0.2) end
			stopHiding()
		end)
	end)

	-- ---- storage (how full the pet inventory is) ----
	local function parseFraction(text)
		local a, b = tostring(text):gsub(",", ""):match("(%d+)%s*/%s*(%d+)")
		a, b = tonumber(a), tonumber(b)
		if a and b and b > 0 and a <= b then return a, b end
	end

	-- True if an object is inside a pet card.
	local function inPetCard(o, stopAt)
		local p = o.Parent
		while p and p ~= stopAt do
			if p.Name:sub(1, 4) == "Pet_" then return true end
			p = p.Parent
		end
		return false
	end

	local lastStoragePath
	-- Called while the inventory is open. Finds an "owned/max" text and stores it in lastStorage.
	local function readStorage(totalPets)
		local g = invGui()
		local used, max, obj
		if g then
			if STORAGE_PATH then
				local o = walk(g, STORAGE_PATH)
				if o and (o:IsA("TextLabel") or o:IsA("TextButton")) then
					used, max = parseFraction(o.Text)
					obj = o
				end
			end
			if not used then
				local cands = {}
				for _, d in ipairs(g:GetDescendants()) do
					if (d:IsA("TextLabel") or d:IsA("TextButton")) and not inPetCard(d, g) then
						local a, b = parseFraction(d.Text)
						if a then cands[#cands + 1] = { a = a, b = b, obj = d } end
					end
				end
				local best
				for _, c in ipairs(cands) do -- 1) the one that matches the number of pets we just counted
					if c.a == totalPets then best = c break end
				end
				if not best then -- 2) one whose name looks like a storage counter
					for _, c in ipairs(cands) do
						local n = c.obj:GetFullName():lower()
						if n:find("storage", 1, true) or n:find("capacity", 1, true) or n:find("space", 1, true)
							or n:find("owned", 1, true) then best = c break end
					end
				end
				if not best then -- 3) the biggest maximum
					for _, c in ipairs(cands) do
						if not best or c.b > best.b then best = c end
					end
				end
				if best then used, max, obj = best.a, best.b, best.obj end
			end
		end
		if not used and STORAGE_MAX and STORAGE_MAX > 0 then
			used, max = totalPets, STORAGE_MAX
		end
		if used then
			lastStorage = { used = used, max = max, pct = used / max * 100 }
			if obj and obj ~= lastStoragePath then
				lastStoragePath = obj
				print(string.format("[Pets] storage read from %s = %d/%d", obj:GetFullName(), used, max))
			end
		else
			lastStorage = nil
		end
	end

	-- true when crafting is allowed by the "Craft When Storage Is" slider
	local function storageGate()
		if storageMin <= 0 then return true end
		local s = lastStorage
		if not s then
			return false, "Can't read your storage - set STORAGE_PATH / STORAGE_MAX in the script (or set the slider to 0%)"
		end
		if s.pct + 1e-6 >= storageMin then return true end
		return false, string.format("Waiting for storage to reach %d%% (now %d%%, %d/%d)",
			storageMin, math.floor(s.pct + 0.5), s.used, s.max)
	end

	-- Text of the pet storage usage (for example used/max and percent).
	local function storageText()
		local s = lastStorage
		if not s then return "Storage: unreadable | crafts only start once storage is this full" end
		return string.format("Storage now %d/%d (%d%%) | crafts only start once storage is this full",
			s.used, s.max, math.floor(s.pct + 0.5))
	end

	-- ---- data scan: reads the game's own replicated save data (the same source the Enchant tab uses) ----
	-- No inventory window: nothing is opened, hidden or closed. Returns the same groups table the old window scan made.
	-- On failure it returns nil, reason, allowWindow. With WINDOW_FALLBACK = false (default) a failure is just reported
	-- (status + output) and the scan retries later; nothing is ever crafted from a list it couldn't read safely.
	-- (kept inside one anonymous function so it only costs buildLogic a single local)
	local scanFromData = (function()
		local ENABLED         = true    -- false = always use the old window scan
		local WINDOW_FALLBACK = false   -- true = if the data can't be read, open the inventory invisibly and read the cards (old method)
		local LOCK_FIELD      = nil     -- e.g. "Locked": trust this field even if no pet has it set yet
		local EQUIP_FIELD     = nil     -- same for equipped pets
		local LOCK_KEYS  = { "Locked", "Lock", "IsLocked", "Favorite", "Favourite", "Favorited", "Favorites", "Favourites", "LockedPets" }
		local EQUIP_KEYS = { "Equipped", "EquippedPets", "Equip", "Team", "Loadout" }
		local POWER_KEYS = { "Multi", "Multiplier", "Mult", "Power", "Strength" }
		local MAX_KEYS   = { "StorageLimit", "MaxStorage", "StorageMax", "PetStorage", "MaxPets", "Capacity", "Storage", "Slots" }
		local reportedOk, reportedFail, dumped = false, nil, false
		local storageFrom = nil

		-- Returns only the pets that have a given field.
		local function withField(list, field)
			if not field then return list end
			local l = { field }
			for _, k in ipairs(list) do l[#l + 1] = k end
			return l
		end
		local lockKeys, equipKeys = withField(LOCK_KEYS, LOCK_FIELD), withField(EQUIP_KEYS, EQUIP_FIELD)

		-- Returns the player's replicated data table (or nil).
		local function replica()
			local okD, data = pcall(function()
				return require(RS.Controllers.Core.DataController):GetReplica().Data
			end)
			if okD and type(data) == "table" and type(data.Pets) == "table" and type(data.Pets.Owned) == "table" then
				return data
			end
		end

		-- id -> true for every pet flagged by one of the keys. Handles { id, id } lists, { [id] = true } maps,
		-- { [slot] = id } maps and a boolean on the pet itself. Second result = where it was found (nil = not found).
		local function idSet(data, owned, keys)
			local set, source = {}, nil
			for _, holder in ipairs({ data.Pets, data }) do
				for _, k in ipairs(keys) do
					local t = holder[k]
					if type(t) == "table" then
						source = source or ((holder == data and "data." or "data.Pets.") .. k)
						for key, v in pairs(t) do
							if type(v) == "string" or type(v) == "number" then set[tostring(v)] = true
							elseif v == true or type(v) == "table" then set[tostring(key)] = true end
						end
					end
				end
			end
			for pid, p in pairs(owned) do
				if type(p) == "table" then
					for _, k in ipairs(keys) do
						if type(p[k]) == "boolean" then
							source = source or ("pet." .. k)
							if p[k] then set[tostring(pid)] = true end
						end
					end
				end
			end
			return set, source
		end

		-- Returns the first number found under any of the given keys.
		local function firstNumber(p, keys)
			for _, k in ipairs(keys) do
				if type(p[k]) == "number" then return p[k] end
			end
		end

		-- prints what the data looks like, once, so the right field names can be set when detection fails
		local function dump(data)
			if dumped then return end
			dumped = true
			-- Lists the keys of a table (limited) for debug output.
			local function keyList(t, limit)
				local l = {}
				for k, v in pairs(t) do
					l[#l + 1] = tostring(k) .. "(" .. type(v) .. ")"
					if #l >= limit then break end
				end
				table.sort(l)
				return table.concat(l, ", ")
			end
			print("[Pets] data keys: " .. keyList(data, 60))
			print("[Pets] data.Pets keys: " .. keyList(data.Pets, 40))
			local _, sample = next(data.Pets.Owned)
			if type(sample) == "table" then
				local parts = {}
				for k, v in pairs(sample) do
					if type(v) ~= "table" then parts[#parts + 1] = tostring(k) .. "=" .. tostring(v) end
				end
				table.sort(parts)
				print("[Pets] sample pet: " .. table.concat(parts, ", "))
			end
		end

		-- Looks for the storage size anywhere in the replicated data (and the player's attributes / leaderstats).
		-- Prints every candidate it finds once, so the right one can be pinned with STORAGE_MAX if it picks wrong.
		local deepDone = false
		-- Looks for the pet storage size anywhere in the replicated data; prints candidates once.
		local function deepMax(data, total)
			local cands, seen, nodes = {}, {}, 0
			local WORDS = { "storage", "capacity", "maxpet", "petslot", "petinv", "inventorysize", "inventoryslots", "limit", "slots" }
			-- Checks one value as a storage-size candidate.
			local function consider(path, key, v)
				if type(v) ~= "number" or v < total or v > 1e6 then return end
				local k = tostring(key):lower()
				if k:find("used") or k:find("count") or k:find("current") then return end
				for _, w in ipairs(WORDS) do
					if k:find(w, 1, true) then
						local score = (k:find("max", 1, true) or k:find("capacity", 1, true)) and 2 or 1
						cands[#cands + 1] = { path = path, v = v, score = score }
						return
					end
				end
			end
			-- Walks the data tree looking for storage-size candidates (depth-limited).
			local function walkT(t, path, depth)
				if depth > 4 or seen[t] or nodes > 4000 then return end
				seen[t] = true
				for k, v in pairs(t) do
					nodes = nodes + 1
					local pth = path .. "." .. tostring(k)
					if type(v) == "table" then
						if v ~= data.Pets.Owned then walkT(v, pth, depth + 1) end
					else
						consider(pth, k, v)
					end
				end
			end
			pcall(walkT, data, "data", 1)
			pcall(function()
				for k, v in pairs(lp:GetAttributes()) do consider("player@" .. tostring(k), k, v) end
				local ls = lp:FindFirstChild("leaderstats")
				for _, holder in ipairs({ lp, ls }) do
					if holder then
						for _, c in ipairs(holder:GetChildren()) do
							if c:IsA("NumberValue") or c:IsA("IntValue") then consider(holder.Name .. "/" .. c.Name, c.Name, c.Value) end
						end
					end
				end
			end)
			table.sort(cands, function(x, y)
				if x.score ~= y.score then return x.score > y.score end
				return x.v < y.v
			end)
			if not deepDone then
				deepDone = true
				if #cands == 0 then
					print("[Pets] storage search: nothing in the data looks like a storage size - set STORAGE_MAX in the script")
				else
					local l = {}
					for i = 1, math.min(#cands, 12) do l[#l + 1] = cands[i].path .. " = " .. tostring(cands[i].v) end
					print("[Pets] storage candidates (first one is used): " .. table.concat(l, " | "))
				end
			end
			if cands[1] then return cands[1].v, cands[1].path end
		end

		-- Reports (once per reason) why the pet scan failed.
		local function fail(why, data)
			if reportedFail ~= why then
				reportedFail = why
				warn("[Pets] data scan unavailable (" .. why .. ")" ..
					(WINDOW_FALLBACK and " - using the inventory window instead" or ""))
				if data then pcall(dump, data) end
			end
			return nil, why, WINDOW_FALLBACK
		end

		return function()
			if not ENABLED then return nil, "disabled", true end
			local data = replica()
			if not data then return fail("couldn't read your pet data (still loading?)") end
			local owned = data.Pets.Owned

			local equipped, equipSource = {}, nil
			if SKIP_EQUIPPED then
				equipped, equipSource = idSet(data, owned, equipKeys)
				equipSource = equipSource or EQUIP_FIELD
				if not equipSource then return fail("equipped pets not found in the data - set EQUIP_FIELD in the script", data) end
			end
			local locked, lockSource = {}, nil
			if SKIP_LOCKED then
				locked, lockSource = idSet(data, owned, lockKeys)
				lockSource = lockSource or LOCK_FIELD
				if not lockSource then
					return fail("locked state not found in the data - lock one pet in the game or set LOCK_FIELD in the script", data)
				end
			end

			local groups, ids, total = {}, {}, 0
			local skey = {}   -- pid -> tostring(pid), computed once (the sort used to call tostring twice per comparison)
			local canYield = coroutine.isyieldable()
			for pid, p in pairs(owned) do
				if type(p) == "table" and type(p.Name) == "string" then
					ids[#ids + 1] = pid
					skey[pid] = tostring(pid)
					total = total + 1
					if canYield and total % 4000 == 0 then task.wait() end
				end
			end
			if total == 0 then return fail("no pets in the data", data) end
			table.sort(ids, function(a, b) return skey[a] < skey[b] end)

			local ordinal = 0
			local walked = 0
			for _, pid in ipairs(ids) do
				walked = walked + 1
				if canYield and walked % 4000 == 0 then task.wait() end
				local p = owned[pid]
				local id = tostring(pid)
				if not (SKIP_LOCKED and locked[id]) and not (SKIP_EQUIPPED and equipped[id]) then
					local tier = tostring(p.Tier or "Normal")
					local key = p.Name .. "|" .. tier
					local g = groups[key]
					if not g then
						g = {
							key = key, name = p.Name, rawTier = tier,
							tier = (tier == "Shiny") and "Rainbow" or tier,
							count = 0, ids = {},
						}
						groups[key] = g
					end
					g.count = g.count + 1
					ordinal = ordinal + 1
					g.ids[#g.ids + 1] = { id = id, power = firstNumber(p, POWER_KEYS), order = ordinal }
				end
			end

			-- storage: STORAGE_MAX, else a max stored in the data, else the max the window scan read earlier
			local max = (STORAGE_MAX and STORAGE_MAX > 0) and STORAGE_MAX or nil
			if not max then
				for _, holder in ipairs({ data.Pets, data }) do
					for _, k in ipairs(MAX_KEYS) do
						local v = holder[k]
						if not max and type(v) == "number" and v >= total then max = v end
					end
				end
			end
			if not max then
				local dm, dp = deepMax(data, total)
				if dm then max = dm storageFrom = dp end
			end
			if not max and lastStorage then max = lastStorage.max end
			if max and max > 0 then
				lastStorage = { used = total, max = max, pct = total / max * 100 }
			elseif storageMin > 0 then
				return fail(WINDOW_FALLBACK and "storage size unknown - reading it from the window once"
					or "storage size unknown - set STORAGE_MAX in the script (or set Craft When Storage Is to 0%)", data)
			else
				lastStorage = nil
			end

			if not reportedOk then
				reportedOk = true
				print(string.format("[Pets] scan source: game data | %d pets | locked=%s equipped=%s storage max=%s",
					total, tostring(lockSource), tostring(equipSource), tostring(max) .. (storageFrom and (" (from " .. storageFrom .. ")") or "")))
			end
			reportedFail = nil
			return groups
		end
	end)()

	-- Opens the inventory (invisibly), reads every pet card, closes it again.
	-- Each group also carries the pet ids (single cards only) so the Diamond / Rainbow crafts can pick pets without a machine window.
	local function scanInventory()
		if scanBusy then return nil, "busy" end
		scanBusy = true
		local okS, dataGroups, dataWhy, allowWindow = pcall(scanFromData) -- game data first: no window needed
		scanBusy = false
		if not okS then return nil, tostring(dataGroups) end
		if dataGroups then lastGroups = dataGroups return dataGroups end
		if not allowWindow then return nil, dataWhy end -- the inventory is never opened unless WINDOW_FALLBACK is on
		scanBusy = true
		local result, why
		local wasOpen = invIsOn()
		local ok, err = pcall(function()
			if HIDE_INVENTORY and not wasOpen then startHiding() end
			if not openInventory() then why = "inventory did not open" return end
			local list = petList()
			if not list then why = "pet list not found" return end

			local groups, seen, scanned, ordinal = {}, {}, 0, 0
			for _, d in ipairs(list:GetDescendants()) do
				if d.Name:sub(1, 4) == "Pet_" then
					local id = d:GetAttribute("PetId")
					if id and not seen[id] then
						seen[id] = true
						local stack = stackOf(d)
						scanned = scanned + stack
						if not (SKIP_LOCKED and cardLocked(d)) and not (SKIP_EQUIPPED and cardEquipped(d, list)) then
							local name = tostring(d:GetAttribute("PetName") or "?")
							local tier = tostring(d:GetAttribute("PetTier") or "?")
							local key = name .. "|" .. tier
							local g = groups[key]
							if not g then
								g = {
									key = key, name = name, rawTier = tier,
									tier = (tier == "Shiny") and "Rainbow" or tier,
									count = 0, ids = {},
								}
								groups[key] = g
							end
							g.count = g.count + stack
							if stack == 1 then
								ordinal = ordinal + 1
								local ml = walk(d, { "Main", "Multi" })
								g.ids[#g.ids + 1] = { id = tostring(id), power = parseMulti(ml and ml.Text), order = ordinal }
							end
						end
					end
				end
			end
			if scanned == 0 then why = "no pets found in the inventory" return end
			readStorage(scanned)
			result = groups
		end)
		if not wasOpen then pcall(closeInventory) end -- always leave it closed (unless you had it open yourself)
		stopHiding()
		scanBusy = false
		if not ok then return nil, tostring(err) end
		if result then lastGroups = result end
		return result, why
	end

	-- ---- machine window (Golden craft only) ----
	local machineGuiCache
	-- Finds the crafting machine's GUI.
	local function findMachineGui()
		if machineGuiCache and machineGuiCache.Parent then return machineGuiCache end
		local root = pg()
		if not root then return nil end
		if MACHINE_GUI_PATH then
			machineGuiCache = walk(root, MACHINE_GUI_PATH)
			return machineGuiCache
		end
		local needle = (MACHINE .. " machine"):lower()
		for _, d in ipairs(root:GetDescendants()) do
			-- skip the hub's own labels (its status text can mention the machine)
			if d:IsA("TextLabel") and not d:IsDescendantOf(gui) and d.Text:lower():find(needle, 1, true) then
				local sg = d:FindFirstAncestorOfClass("ScreenGui")
				if sg then machineGuiCache = sg return sg end
			end
		end
		return nil
	end

	-- True if a GUI object is really visible on screen.
	local function shown(obj)
		local p = obj
		while p and not p:IsA("ScreenGui") do
			if p:IsA("GuiObject") and not p.Visible then return false end
			p = p.Parent
		end
		return p ~= nil and p.Enabled
	end

	-- Collects the pet cards of the machine window and groups them.
	local function collect(root)
		local groups, seen, order = {}, {}, 0
		for _, d in ipairs(root:GetDescendants()) do
			if d.Name:sub(1, 4) == "Pet_" then
				local rawId = d:GetAttribute("PetId")
				if rawId then
					local id = tostring(rawId)
					if not seen[id] and not usedIds[id] and shown(d)
						and not (SKIP_LOCKED and cardLocked(d))
						and not (SKIP_EQUIPPED and cardEquipped(d, root)) then
						seen[id] = true
						order = order + 1
						local name = tostring(d:GetAttribute("PetName") or "?")
						local tier = tostring(d:GetAttribute("PetTier") or "?")
						local key = name .. "|" .. tier
						local g = groups[key]
						if not g then
							g = { key = key, name = name, tier = tier, cards = {} }
							groups[key] = g
						end
						local ml = walk(d, { "Main", "Multi" })
						g.cards[#g.cards + 1] = { id = id, power = parseMulti(ml and ml.Text), order = order }
					end
				end
			end
		end
		return groups
	end

	-- Picks which cards (ids) of a group go into the machine.
	local function pickIds(g)
		local list = table.clone(g.cards)
		local allParsed = true
		for _, c in ipairs(list) do if not c.power then allParsed = false break end end

		if PICK == "list" then
			table.sort(list, function(a, b) return a.order < b.order end)
		elseif allParsed then
			if PICK == "highest" then
				table.sort(list, function(a, b) return a.power > b.power end)
			else
				table.sort(list, function(a, b) return a.power < b.power end)
			end
		else
			table.sort(list, function(a, b)
				if PICK == "highest" then return a.order < b.order end
				return a.order > b.order
			end)
		end
		local ids = {}
		for i = 1, NEED do ids[i] = list[i].id end
		return ids
	end

	-- Tries to open the machine through its proximity prompt.
	local function tryOpenPrompt()
		if type(fireproximityprompt) ~= "function" then return false end
		local hrp = getHRP()
		if not hrp then return false end
		local best, bestDist
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				local par = d.Parent
				local text = (d.ObjectText .. " " .. d.ActionText .. " " .. (par and par.Name or "") ..
					" " .. (par and par.Parent and par.Parent.Name or "")):lower()
				if text:find("machine", 1, true) or text:find(MACHINE:lower(), 1, true) or text:find("craft", 1, true) then
					local pos
					if par and par:IsA("BasePart") then pos = par.Position
					elseif par and par:IsA("Attachment") then pos = par.WorldPosition end
					if pos then
						local dist = (pos - hrp.Position).Magnitude
						if dist <= PROMPT_RANGE and (not bestDist or dist < bestDist) then best, bestDist = d, dist end
					end
				end
			end
		end
		if best then
			pcall(fireproximityprompt, best)
			return true
		end
		return false
	end

	-- ---- dismiss the "Crafted!" popup ----
	local function clickAt(x, y)
		pcall(function()
			VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
			task.wait(0.05)
			VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
		end)
	end

	-- Clicks the centre of a GUI object with a real mouse click.
	local function clickCenterOf(obj)
		-- a ScreenGui with IgnoreGuiInset already starts at the very top of the screen: adding the inset again
		-- would put the click ~58px too low and miss the Continue button
		local sg = obj
		while sg and not sg:IsA("ScreenGui") do sg = sg.Parent end
		local off = (sg and sg.IgnoreGuiInset) and Vector2.new(0, 0) or GuiService:GetGuiInset()
		local pos = obj.AbsolutePosition + obj.AbsoluteSize / 2
		clickAt(pos.X + off.X, pos.Y + off.Y)
	end

	-- the visible "Continue" label of the Crafted! popup (or nil)
	-- Same result as scanning every descendant of PlayerGui, but a label only counts when its ScreenGui is enabled and every
	-- GuiObject above it is visible (that is exactly what shown() checks), so hidden subtrees are skipped instead of walked:
	-- the closed Inventory (thousands of pet cards), hidden menus and the hub itself cost nothing.
	local function resultOpen()
		local root = pg()
		if not root then return nil end
		-- Searches a GUI tree for a node (used to find the machine buttons).
		local function search(node, inScreen)
			for _, c in ipairs(node:GetChildren()) do
				if c ~= gui then
					if c:IsA("ScreenGui") then
						if c.Enabled then
							local hit = search(c, true)
							if hit then return hit end
						end
					elseif c:IsA("GuiObject") then
						if inScreen and c.Visible then
							if (c:IsA("TextLabel") or c:IsA("TextButton")) and (c.Text:lower():gsub("%s", "")) == "continue" then return c end
							local hit = search(c, true)
							if hit then return hit end
						end
					else
						local hit = search(c, inScreen)
						if hit then return hit end
					end
				end
			end
			return nil
		end
		return search(root, false)
	end

	-- Closes the craft result popup.
	local function dismissResult()
		local d = resultOpen()
		if not d then return false end
		local btn = d
		while btn and not btn:IsA("GuiButton") do btn = btn.Parent end
		if not btn then
			local holder = d.Parent
			btn = holder and holder:FindFirstChildWhichIsA("GuiButton", true)
		end
		if not (btn and click(btn)) then
			clickCenterOf(d)
		end
		return true
	end

	-- keeps trying until the popup is really gone (the old code clicked once and never checked): signals -> real mouse click
	-- -> signals -> mouse -> firesignal -> last resort: hide the popup's ScreenGui. Returns true when it is closed.
	local function closeResult()
		for attempt = 1, 6 do
			local d = resultOpen()
			if not d then return true end
			if attempt == 1 or attempt == 3 then
				dismissResult()
			elseif attempt == 2 or attempt == 4 then
				clickCenterOf(d)
			elseif attempt == 5 then
				local btn = d
				while btn and not btn:IsA("GuiButton") do btn = btn.Parent end
				if btn and type(firesignal) == "function" then
					for _, sig in ipairs({ "MouseButton1Down", "MouseButton1Up", "MouseButton1Click", "Activated" }) do
						pcall(firesignal, btn[sig])
					end
				end
			else
				local sg = d
				while sg and not sg:IsA("ScreenGui") do sg = sg.Parent end
				if sg then sg.Enabled = false; warn("[Craft] the Crafted! popup would not close - hid it") end
			end
			task.wait(0.6)
		end
		return resultOpen() == nil
	end

	-- safety net: a Crafted! popup that has been on screen for 5 s is closed, whatever feature left it there
	task.spawn(function()
		local seen, lastActive = 0, 0
		while alive do
			task.wait(1)
			-- resultOpen() walks all of PlayerGui, so only look while a craft feature is running (or just finished)
			if enabled or tripOwner ~= nil then lastActive = os.clock() end
			if os.clock() - lastActive > 20 then
				seen = 0
				continue
			end
			local d = resultOpen()
			local isCraft = false
			if d then
				local sg = d
				while sg and not sg:IsA("ScreenGui") do sg = sg.Parent end
				for _, x in ipairs((sg or d):GetDescendants()) do
					if x:IsA("TextLabel") and shown(x) then
						local t = x.Text:lower()
						if t:find("crafted", 1, true) or t:find("became", 1, true) or t:find("success rate", 1, true) then isCraft = true break end
					end
				end
			end
			if d and isCraft then seen = seen + 1 else seen = 0 end
			if seen >= 5 then
				seen = 0
				pcall(closeResult)
			end
		end
	end)

	-- ---- cycle ----
	local function stopWith(id, reason)
		if runId ~= id then return end
		enabled = false
		runId = runId + 1
		if craftEntry._setUI then craftEntry._setUI(false) end
		setStatus(reason)
	end

	-- Waits until the machine window opens (or a timeout).
	local function waitForWindow(id, timeout)
		local limit = timeout or WINDOW_TIMEOUT
		local t0 = os.clock()
		local lastPrompt = -1e9
		while active(id) do
			local g = findMachineGui()
			if g then
				local grp = collect(g)[curKey]
				if grp and #grp.cards >= NEED then return true end
			end
			local waited = os.clock() - t0
			if waited >= limit then return false end
			if AUTO_OPEN_PROMPT and waited >= 4 and waited - lastPrompt >= 6 then
				lastPrompt = waited
				tryOpenPrompt()
			end
			setStatus("Open the " .. MACHINE .. " window (" .. math.floor(limit - waited) .. "s)")
			sleepWhile(id, 1)
		end
		return false
	end

	-- returns "done", "limit", "fail", "stopped"
	local function craftUntilDone(id, expected)
		local fails = 0
		local crafted = 0
		while active(id) do
			if expected - crafted * NEED < NEED then return "done" end

			local grp
			local t0, lastPrompt = os.clock(), -1e9
			while active(id) do
				dismissResult()
				local g = findMachineGui()
				grp = g and collect(g)[curKey]
				if grp and #grp.cards >= NEED then break end
				grp = nil
				local waited = os.clock() - t0
				if waited >= REFRESH_WAIT then break end
				if waited >= 3 and not dismissResult() then
					local cam = workspace.CurrentCamera
					if cam then clickAt(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2) end
				end
				if AUTO_OPEN_PROMPT and waited >= 5 and waited - lastPrompt >= 5 then
					lastPrompt = waited
					tryOpenPrompt()
				end
				setStatus(string.format("Waiting for the window to refresh | crafted %d | %d left", crafts, expected - crafted * NEED))
				sleepWhile(id, 0.7)
			end
			if not active(id) then return "stopped" end
			if not grp then
				warn("[Craft] window shows fewer than " .. NEED .. " pets, but the scan expected " .. (expected - crafted * NEED))
				return "done"
			end

			local ids = pickIds(grp)
			for _, pid in ipairs(ids) do usedIds[pid] = true end

			lastResult = nil
			local okFire, err = pcall(function()
				requestRemote:FireServer({ PetIds = ids, Machine = MACHINE, Action = "Craft" })
			end)
			if not okFire then warn("[Craft] fire failed: " .. tostring(err)) return "fail" end

			local t1 = os.clock()
			while active(id) and not lastResult and os.clock() - t1 < RESULT_WAIT do task.wait(0.1) end
			if not active(id) then return "stopped" end

			if lastResult and lastResult.Success then
				crafts = crafts + 1
				crafted = crafted + 1
				fails = 0
				local pet = lastResult.Pet
				setStatus(string.format("Crafting | total %d | %d left | last: %s (%s)", crafts,
					math.max(0, expected - crafted * NEED),
					pet and tostring(pet.Name) or "?", pet and tostring(pet.Tier) or "?"))
				if MAX_CRAFTS > 0 and crafts >= MAX_CRAFTS then
					sleepWhile(id, 1)
					dismissResult()
					return "limit"
				end
				sleepWhile(id, 1)
				dismissResult()
			else
				for _, pid in ipairs(ids) do usedIds[pid] = nil end
				fails = fails + 1
				warn("[Craft] craft " .. (lastResult and "was not successful" or "got no reply") .. " (" .. fails .. "/" .. MAX_FAILS .. ")")
				if fails >= MAX_FAILS then return "fail" end
			end
			sleepWhile(id, CRAFT_DELAY)
		end
		return "stopped"
	end

	-- Normal pets only (the Golden machine takes base-tier pets)
	local function isBaseTier(raw)
		local t = tostring(raw):lower()
		return not (t:find("gold", 1, true) or t:find("diamond", 1, true) or t:find("shiny", 1, true) or t:find("rainbow", 1, true))
	end

	-- the pet types the Golden craft should work on: the picked pet, or every pet with enough copies for "All pets"
	local function goalTargets(groups)
		local list = {}
		if next(craftWant) ~= nil then
			for key, n in pairs(craftWant) do
				local g = groups[key]
				if g and isBaseTier(g.rawTier) and n > 0 and g.count >= TRIGGER_AT then
					local text = string.format("%s (%s)", g.name, g.tier)
					list[#list + 1] = { key = key, text = text, count = g.count, want = n }
				end
			end
			table.sort(list, function(a, b) return a.key < b.key end)
		elseif selAll then
			for key, g in pairs(groups) do
				if g.count >= TRIGGER_AT and isBaseTier(g.rawTier) then
					list[#list + 1] = { key = key, text = string.format("%s (%s)", g.name, g.tier), count = g.count }
				end
			end
			table.sort(list, function(a, b) return a.key < b.key end)
		elseif selKey then
			local g = groups[selKey]
			if g and g.count >= TRIGGER_AT then
				list[1] = { key = selKey, text = selText, count = g.count }
			end
		end
		return list
	end

	-- fires a Golden machine request and waits for its MachineCraftResult (matched by Action)
	local function goldenRequest(id, args, timeout)
		local got
		local c = resultRemote.OnClientEvent:Connect(function(d)
			if type(d) == "table" and d.Machine == MACHINE and d.Action == args.Action then got = d end
		end)
		local ok, err = pcall(function() requestRemote:FireServer(args) end)
		if not ok then
			pcall(function() c:Disconnect() end)
			warn("[Craft] fire failed: " .. tostring(err))
			return nil
		end
		local t0 = os.clock()
		while active(id) and not got and os.clock() - t0 < timeout do task.wait(0.1) end
		pcall(function() c:Disconnect() end)
		return got
	end

	-- returns "ok", "limit", "fail", "busy", "stopped"
	local function goCraft(id, targets)
		-- the inventory must be closed before anything else happens
		setStatus("Waiting for the inventory to be closed...")
		if not ensureInventoryClosed(function() return active(id) end) then
			if not active(id) then return "stopped" end
			return "busy"
		end
		if not active(id) then return "stopped" end

		setStatus("Teleporting directly to Golden machine...")
		if not directCraftTeleport(function() return active(id) end, CRAFT_CF, setStatus) then
			return active(id) and "fail" or "stopped"
		end
		if not active(id) then return "stopped" end

		local groups = lastGroups
		if not groups then return "fail" end

		-- 1) more than CRAFT_ALL_OVER of the same pet: try Craft All once. If it works we're done (no one-at-a-time crafting).
		local big = false
		for _, t in ipairs(targets) do
			if t.count > CRAFT_ALL_OVER and t.want == nil then big = true break end
		end
		if big and MAX_CRAFTS == 0 and NEED == 6 then
			setStatus("Craft All...")
			local res = goldenRequest(id, { Machine = MACHINE, Action = "CraftAll" }, RESULT_WAIT)
			if not active(id) then return "stopped" end
			if res and res.Success then
				crafts = crafts + (tonumber(res.Crafted) or 0)
				setStatus(string.format("Craft All done | %s crafts, %s pets used | total %d",
					tostring(res.Crafted), tostring(res.Consumed), crafts))
				for k in pairs(spent) do spent[k] = nil end
				lastScanAt = -1e9   -- the pet list changed: the next check scans again
				task.wait(0.5)
				closeResult()   -- the "36 pets became 6 Golden" popup used to stay open forever
				return "ok"
			end
			warn("[Craft] Craft All " .. (res and "was not successful" or "got no reply") .. " - crafting one at a time")
		end

		-- 2) one at a time: Action = "Craft" with the 6 pet ids
		for _, t in ipairs(targets) do
			local g = groups[t.key]
			local list = {}
			if g then
				for _, e in ipairs(g.ids) do
					if not spent[e.id] then list[#list + 1] = e end
				end
			end
			table.sort(list, function(a, b)
				if a.power and b.power and a.power ~= b.power then
					if PICK == "highest" then return a.power > b.power end
					return a.power < b.power
				end
				return a.order < b.order
			end)

			local i, fails = 1, 0
			while active(id) and i + NEED - 1 <= #list and (t.want == nil or t.want > 0) do
				local pick = {}
				for k = 1, NEED do pick[k] = list[i + k - 1].id end
				local res = goldenRequest(id, { PetIds = pick, Machine = MACHINE, Action = "Craft" }, RESULT_WAIT)
				if not active(id) then return "stopped" end
				if res and res.Success then
					for _, pid in ipairs(pick) do spent[pid] = true end
					crafts = crafts + 1
					i = i + NEED
					fails = 0
					if t.want then   -- counted pick: one craft less to go (also updates the dropdown numbers)
						t.want = t.want - 1
						craftWant[t.key] = t.want > 0 and t.want or nil
						dropEntry.counts[t.text] = craftWant[t.key]
						if dropEntry._refreshMulti then dropEntry._refreshMulti(true) end
					end
					local pet = res.Pet
					setStatus(string.format("Crafting | total %d | %d left | last: %s (%s)", crafts,
						math.max(0, #list - (i - 1)), pet and tostring(pet.Name) or "?", pet and tostring(pet.Tier) or "?"))
					if MAX_CRAFTS > 0 and crafts >= MAX_CRAFTS then closeResult() return "limit" end
					sleepWhile(id, CRAFT_DELAY)
					closeResult()
				else
					fails = fails + 1
					warn(string.format("[Craft] craft %s (%d/%d)", res and "was not successful" or "got no reply", fails, MAX_FAILS))
					if fails >= MAX_FAILS then return "fail" end
					sleepWhile(id, CRAFT_DELAY)
				end
			end
		end
		lastScanAt = -1e9   -- crafted pets changed the list: the next check scans again
		return "ok"
	end

	-- goCraft, but only one machine trip at a time across all auto features
	local function goCraftLocked(id, targets)
		if not acquireTrip("Auto Craft", function() return active(id) end, setStatus) then return "stopped" end
		local ok, r = pcall(goCraft, id, targets)
		releaseTrip("Auto Craft")
		if not ok then
			warn("[Craft] error: " .. tostring(r))
			return "fail"
		end
		return r
	end

	-- Auto Craft monitor loop: watches the machine and starts work.
	local function monitorLoop(id)
		-- True while the monitor run is still the current one.
		local function act() return active(id) end
		while active(id) do
			if not HG.gate("Auto Craft", act, setStatus) then return end   -- priority first: nothing happens while something outranks Craft
			setStatus("Checking inventory...")
			local groups, why = getGroups(act) -- cached: the inventory is only really scanned every SCAN_EVERY seconds
			if not active(id) then return end

			if not groups then
				setStatus("Scan failed (" .. tostring(why) .. "), retrying...")
				sleepWhile(id, 10)
			else
				local okS, msgS = storageGate()
				local targets = goalTargets(groups)
				if #targets > 0 and not okS then
					setStatus(msgS)
				elseif #targets > 0 then
					local r = goCraftLocked(id, targets)
					if r == "stopped" then return end
					if r == "fail" then return stopWith(id, "Stopped: crafts keep failing") end
					if r == "nowindow" then
						return stopWith(id, "Stopped: machine window not open / fewer than " .. NEED .. " " .. tostring(curText) .. " in it")
					end
					if r == "limit" then return stopWith(id, "Done: reached " .. MAX_CRAFTS .. " crafts") end
					if r == "busy" then
						setStatus("Inventory stayed open - will retry next cycle")
					else
						setStatus(string.format("Cycle done | total crafts %d | next check soon", crafts))
					end
				elseif next(craftWant) ~= nil then
					setStatus(string.format("Waiting: not enough copies of the picked pets (%d+ each) | crafts %d", TRIGGER_AT, crafts))
				elseif selAll then
					setStatus(string.format("Waiting: no pet with %d+ copies | crafts %d", TRIGGER_AT, crafts))
				elseif not selKey then
					return stopWith(id, "Done: every picked craft is finished | crafts " .. crafts)
				else
					local have = groups[selKey] and groups[selKey].count or 0
					setStatus(string.format("Waiting: %d/%d %s | crafts %d", have, TRIGGER_AT, tostring(selText), crafts))
				end
				napWhile(id, SCAN_EVERY)
			end
		end
	end

	-- Switches Auto Craft on or off.
	local function setEnabled(on)
		if on == enabled then return end
		if on and not (selKey or selAll or next(craftWant) ~= nil) then
			setStatus("Pick a pet in the dropdown first (needs Auto Scan Inventory on, in Settings)")
			task.defer(function()
				if craftEntry._setUI then craftEntry._setUI(false) end
			end)
			return
		end
		enabled = on
		runId = runId + 1
		local id = runId
		if on then
			usedIds = {}
			task.spawn(monitorLoop, id)
		else
			setStatus("Off | Crafts: " .. crafts)
		end
	end

	-------------------------------------------------------------------------- dropdown filling
	-- Rebuilds the dropdown options from a scan. The pet you picked stays in the list (with its new count)
	-- even if you dropped below 6, so Auto Craft never loses its selection mid-run.
	-- Returns how many pet types currently have NEED or more.
	fillOptions = function(groups)
		local opts = dropEntry.options
		for i = #opts, 1, -1 do opts[i] = nil end
		optionInfo = {}
		dropEntry._limits = {}
		local limits = dropEntry._limits

		opts[1] = ALL_OPT
		optionInfo[ALL_OPT] = { all = true }

		local keys = {}
		for k, g in pairs(groups) do
			if isBaseTier(g.rawTier) and (g.count >= NEED or craftWant[k]) then keys[#keys + 1] = k end
		end
		table.sort(keys, function(a, b)
			local ca, cb = groups[a].count, groups[b].count
			if ca ~= cb then return ca > cb end
			return a < b
		end)

		local labelOf = {}
		for _, key in ipairs(keys) do
			local g = groups[key]
			local text = string.format("%s (%s)", g.name, g.tier)
			opts[#opts + 1] = text
			optionInfo[text] = { key = key, text = text }
			limits[text] = math.floor(g.count / NEED)   -- how many Golden crafts the copies you own allow
			labelOf[key] = text
		end
		for key, n in pairs(craftWant) do   -- a picked pet that is gone from the inventory stays visible (limit 0) so it can be removed
			if not labelOf[key] and (not groups[key] or isBaseTier(groups[key].rawTier)) then
				local text = tostring(key):gsub("|", " (") .. ")"
				opts[#opts + 1] = text
				optionInfo[text] = { key = key, text = text }
				limits[text] = 0
				labelOf[key] = text
			end
		end

		local counts = dropEntry.counts
		for k in pairs(counts) do counts[k] = nil end
		for key, n in pairs(craftWant) do if labelOf[key] then counts[labelOf[key]] = n end end

		local craftable = 0
		for _, g in pairs(groups) do
			if isBaseTier(g.rawTier) and g.count >= NEED then craftable = craftable + 1 end
		end

		dropEntry.emptyText = selAll and ALL_OPT or "Select a pet..."
		if dropEntry._refresh then dropEntry._refresh() end
		if dropEntry._refreshMulti then dropEntry._refreshMulti(true) end
		return craftable
	end

	-------------------------------------------------------------------------- the one place that scans the inventory
	-- Everything (Auto Scan Inventory toggle, Auto Craft, Craft to Diamond, Craft to Rainbow) gets its pet list from here.
	-- A real scan happens at most once every SCAN_EVERY seconds; in between the last result is returned.
	-- It never scans while another feature is on a machine trip, and a scan never overlaps another scan.
	getGroups = function(stillActive)
		-- True if the last card scan is still fresh enough to reuse.
		local function fresh() return lastGroups ~= nil and os.clock() - lastScanAt < SCAN_EVERY end
		if fresh() then return lastGroups end

		local t0 = os.clock()
		while alive and stillActive() and (scanBusy or tripOwner) do
			task.wait(0.3)
			if os.clock() - t0 > 120 then return nil, "busy" end
		end
		if not (alive and stillActive()) then return nil, "stopped" end
		if fresh() then return lastGroups end
		if os.clock() - lastTryAt < 20 then return nil, HG.lastWhy or "scan failed recently" end

		lastTryAt = os.clock()
		local groups, why = scanInventory()
		if not groups then HG.lastWhy = tostring(why) return nil, why end
		HG.lastWhy = nil

		lastScanAt = os.clock()
		for k in pairs(spent) do spent[k] = nil end
		lastCraftable = fillOptions(groups)
		setDesc(storageEntry, storageText())
		for _, f in ipairs(jobFillers) do pcall(f, groups) end
		return groups
	end

	-------------------------------------------------------------------------- Auto Scan Inventory toggle
	local function invLoop(id)
		-- True while the current craft run is active.
		local function act() return alive and keepRun == id end
		while act() do
			local age = os.clock() - lastScanAt
			if lastGroups and age < IDLE_SCAN then
				-- recent enough: do nothing (any feature that needs fresher pets scans by itself, see SCAN_EVERY)
				setDesc(scanEntry, string.format("On | next scan in %ds | %d pet type(s) with %d+ owned", math.max(0, math.ceil(IDLE_SCAN - age)), lastCraftable, NEED))
			else
				setDesc(scanEntry, "Scanning inventory...")
				local groups, why = getGroups(act)
				if not act() then break end
				if groups then
					setDesc(scanEntry, string.format("On | next scan in %ds | %d pet type(s) with %d+ owned", IDLE_SCAN, lastCraftable, NEED))
				elseif why ~= "busy" and why ~= "stopped" then
					setDesc(scanEntry, "Scan failed (" .. tostring(why) .. "), retrying...")
				end
			end
			sleepFor(act, 1)
		end
	end

	-------------------------------------------------------------------------- Diamond / Rainbow crafts + Collect Rainbow
	local function buildPetJobs()
		local CF_DIAMOND = CFrame.new(-170.1920166015625, 5450.46533203125, -1998.5030517578125, 0.29597628116607666, 4.257726615719548e-08, 0.9551953077316284, 4.557870525445651e-09, 1, -4.5986705998757316e-08, -0.9551953077316284, 1.796463067194054e-08, 0.29597628116607666)
		local CF_RAINBOW = CFrame.new(119.37336730957031, 15325.2412109375, -1811.5943603515625, 0.05694764107465744, 3.7273178321584055e-08, -0.9983771443367004, -4.600424485801113e-09, 1, 3.7071355762918756e-08, 0.9983771443367004, 2.4818322952313565e-09, 0.05694764107465744)
		local ISLAND_DIAMOND = "Crystal Cave"   -- island names used by the Travel remote (change them if the game uses other names)
		local ISLAND_RAINBOW = "Shadow Realm"
		local RAINBOW_CAPACITY = 3              -- the Rainbow machine holds 3 crafts at a time
		local RAINBOW_RETRY  = 600              -- seconds to wait after a Rainbow "Start" is refused (machine busy / full)
		local CLAIM_CHECK    = 15               -- seconds between checks for finished Rainbow crafts
		local CLAIM_MAX_FAILS = 3
		local ALL = "All pets"
		local QUEUE_FILE = "rainbow_queue_" .. tostring(lp.UserId) .. ".json"

		-- Rainbow crafts that are cooking: CraftId -> { finish = server time, name = pet name }
		local queue = {}
		do
			local raw = Store.read(QUEUE_FILE)
			if raw then
				local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
				if ok and type(data) == "table" then
					for cid, v in pairs(data) do
						if type(v) == "table" and tonumber(v.finish) then
							queue[tostring(cid)] = { finish = tonumber(v.finish), name = tostring(v.name or "?"), fails = 0 }
						end
					end
				end
			end
		end
		-- Saves the craft queue (running crafts) to a file.
		local function saveQueue()
			local data = {}
			for cid, v in pairs(queue) do data[cid] = { finish = v.finish, name = v.name } end
			pcall(Store.write, QUEUE_FILE, HttpService:JSONEncode(data))
		end
		-- Rebuilds `queue` from the game's own machine data (Data.Machines.Shiny.Queue: CraftId -> { EndTime, Name, ... }),
		-- so the pods always match the real machine (even crafts started / claimed by hand). If that data can't be read,
		-- the saved list is kept as it is. A craft this script started a moment ago is kept until the data shows it.
		local function syncQueue()
			local okD, data = pcall(function() return require(RS.Controllers.Core.DataController):GetReplica().Data end)
			if not okD or type(data) ~= "table" or type(data.Machines) ~= "table" then return end
			local shiny = data.Machines.Shiny
			local real = type(shiny) == "table" and shiny.Queue or nil
			if real ~= nil and type(real) ~= "table" then return end
			local fresh = {}
			for cid, v in pairs(real or {}) do
				if type(v) == "table" and tonumber(v.EndTime) then
					local old = queue[tostring(cid)]
					fresh[tostring(cid)] = { finish = tonumber(v.EndTime), name = tostring(v.Name or "?"), fails = old and old.fails or 0 }
				end
			end
			for cid, v in pairs(queue) do
				if not fresh[cid] and v.at and os.clock() - v.at < 15 then fresh[cid] = v end
			end
			local changed = false
			for cid in pairs(fresh) do if not queue[cid] then changed = true end end
			for cid in pairs(queue) do if not fresh[cid] then changed = true end end
			for cid in pairs(queue) do queue[cid] = nil end
			for cid, v in pairs(fresh) do queue[cid] = v end
			if changed then saveQueue() end
		end
		-- Number of crafts in the queue.
		local function queueCount() syncQueue() local n = 0 for _ in pairs(queue) do n = n + 1 end return n end

		-- True if a pet tier text contains the wanted tier (normal / golden / diamond / rainbow).
		local function tierIs(raw, which)
			return tostring(raw):lower():find(which, 1, true) ~= nil
		end

		-- Sorts cards into the order they should be used.
		local function sortCards(list)
			local allParsed = true
			for _, c in ipairs(list) do if not c.power then allParsed = false break end end
			if PICK == "list" then
				table.sort(list, function(a, b) return a.order < b.order end)
			elseif allParsed then
				if PICK == "highest" then
					table.sort(list, function(a, b) return a.power > b.power end)
				else
					table.sort(list, function(a, b) return a.power < b.power end)
				end
			else
				table.sort(list, function(a, b)
					if PICK == "highest" then return a.order < b.order end
					return a.order > b.order
				end)
			end
		end

		-- fires a MachineCraftRequested and waits for the matching MachineCraftResult
		local function requestWait(args, match, timeout)
			local got
			local c = resultRemote.OnClientEvent:Connect(function(d)
				if type(d) == "table" and match(d) then got = d end
			end)
			local ok, err = pcall(function() requestRemote:FireServer(args) end)
			if not ok then
				c:Disconnect()
				warn("[Pets] fire failed: " .. tostring(err))
				return nil
			end
			local t0 = os.clock()
			while alive and not got and os.clock() - t0 < timeout do task.wait(0.1) end
			c:Disconnect()
			return got
		end

		-- One machine trip: waits for its turn, makes sure the inventory is closed, pauses auto hatch, travels,
		-- teleports to the machine, runs body(), then resumes auto hatch. Returns body's result, "busy", or "stopped".
		local function runTrip(name, stillActive, island, cf, body, statusFn)
			if not acquireTrip(name, stillActive, statusFn) then return "stopped" end
			local ok, result = pcall(function()
				statusFn("Waiting for the inventory to be closed...")
				if not ensureInventoryClosed(stillActive) then
					return stillActive() and "busy" or "stopped"
				end
				if not stillActive() then return "stopped" end

				statusFn("Teleporting directly to " .. island .. " crafting machine...")
				local arrived = directCraftTeleport(stillActive, cf, statusFn)
				if not stillActive() then return "stopped" end
				if not arrived then return "fail" end
				return body() or "ok"
			end)
			releaseTrip(name)
			if not ok then
				warn("[Pets] error: " .. tostring(result))
				pcall(statusFn, "[Debug] Trip failed: " .. tostring(result))
				return "error"
			end
			return result
		end

		-- Creates one craft job (Golden, Diamond or Rainbow) from its config.
		local function newJob(cfg)
			local job = {
				cfg = cfg, enabled = false, runId = 0, crafts = 0,
				selKey = nil, selText = nil, optionInfo = {}, cooldownUntil = 0,
				want = {}, wantText = {}, finished = false,   -- want: pet key -> crafts still wanted (counters); finished = every counted craft is done
				need = cfg.need,   -- pets used per craft (the Rainbow job changes it with its Amount dropdown)
			}
			job.entry = {
				-- TOGGLE (one per craft job: Golden / Diamond / Rainbow): switches that craft job on / off; its name and text come from the job config.
				type = "toggle", name = cfg.name, icon = cfg.icon, default = false, desc = cfg.desc,
			}
			job.setStatus = function(text) setDesc(job.entry, text) end
			job.act = function(id) return alive and job.enabled and job.runId == id end

			if cfg.amounts then
				job.amountOptions = {}
				for _, a in ipairs(cfg.amounts) do job.amountOptions[#job.amountOptions + 1] = a.label end
				job.amountEntry = {
					type = "dropdown", name = cfg.amountName, icon = cfg.icon, width = 280,
					desc = cfg.amountDesc, options = job.amountOptions, default = job.amountOptions[1],
				}
				job.amountEntry.callback = function(option)
					for _, a in ipairs(cfg.amounts) do
						if a.label == option then job.need = a.pets end
					end
				end
			end

			if not cfg.noDrop then
				local limits = {}
				job.drop = {
					type = "dropdown", name = cfg.dropName, icon = cfg.icon, noSave = true, width = 320,
					desc = cfg.dropDesc .. " Left click a pet = +1 craft, right click = -1 (or use + / -). All pets = no counters.",
					options = { ALL }, default = ALL,
					counter = true, counts = {}, clearOption = ALL,
				}
				job.drop.limitOf = function(option) return limits[option] or 0 end
				job.drop.callback = function(option)
					job.finished = false
					job.selKey, job.selText = nil, nil
					if option == ALL then
						for k in pairs(job.want) do job.want[k] = nil end
					elseif option == nil then
						for k in pairs(job.want) do job.want[k] = nil end
						for label, n in pairs(job.drop.counts) do
							local info = job.optionInfo[label]
							if info and info.key and n > 0 then job.want[info.key] = n; job.wantText[info.key] = info.text end
						end
					else
						local info = job.optionInfo[option]
						if info and info.key then
							local n = job.drop.counts[option] or 0
							job.want[info.key] = n > 0 and n or nil
							job.wantText[info.key] = info.text
						end
					end
				end
				-- called after every scan: rebuilds the dropdown (pets of the right tier that have enough copies)
				table.insert(jobFillers, function(groups)
					local opts = job.drop.options
					for i = #opts, 1, -1 do opts[i] = nil end
					job.optionInfo = { [ALL] = { key = nil, text = ALL } }
					opts[1] = ALL
					for k in pairs(limits) do limits[k] = nil end

					local keys = {}
					for k, g in pairs(groups) do
						if tierIs(g.rawTier, cfg.fromTier) and (#g.ids >= job.need or job.want[k]) then
							keys[#keys + 1] = k
						end
					end
					table.sort(keys, function(a, b)
						local ca, cb = groups[a].count, groups[b].count
						if ca ~= cb then return ca > cb end
						return a < b
					end)

					local labelOf = {}
					for _, key in ipairs(keys) do
						local g = groups[key]
						local text = string.format("%s (%s)", g.name, g.tier)
						opts[#opts + 1] = text
						job.optionInfo[text] = { key = key, text = text }
						job.wantText[key] = text
						limits[text] = math.floor(#g.ids / job.need)   -- crafts the copies you own allow
						labelOf[key] = text
					end
					for key in pairs(job.want) do   -- a picked pet that is gone from the inventory stays visible (limit 0)
						if not labelOf[key] then
							local text = tostring(job.wantText[key] or key)
							opts[#opts + 1] = text
							job.optionInfo[text] = { key = key, text = text }
							limits[text] = 0
							labelOf[key] = text
						end
					end
					local counts = job.drop.counts
					for k in pairs(counts) do counts[k] = nil end
					for key, n in pairs(job.want) do counts[labelOf[key]] = n end
					if job.drop._refresh then job.drop._refresh() end
					if job.drop._refreshMulti then job.drop._refreshMulti(true) end
				end)
			end
			return job
		end

		-- Links a job's toggle to its loop (switching it on starts the loop).
		local function bindToggle(job, loop)
			job.entry.callback = function(on)
				if on == job.enabled then return end
				job.enabled = on
				job.runId = job.runId + 1
				if on then
					task.spawn(loop, job, job.runId)
				else
					job.setStatus("Off | crafts: " .. job.crafts)
				end
			end
		end

		-- what can be crafted right now: groups of the right tier (and the picked pet), minus ids already spent
		local function planFor(job, groups)
			local cfg = job.cfg
			local out, sets = {}, 0
			if job.finished then return out, 0 end   -- every counted craft is done: never fall back to "All pets" by itself
			local counted = next(job.want) ~= nil
			for key, g in pairs(groups) do
				if tierIs(g.rawTier, cfg.fromTier) and (counted and job.want[key] ~= nil or (not counted and (job.selKey == nil or key == job.selKey))) then
					local ids = {}
					for _, c in ipairs(g.ids) do
						if not spent[c.id] then ids[#ids + 1] = c end
					end
					if #ids >= job.need then
						sortCards(ids)
						out[#out + 1] = { g = g, ids = ids }
						local n = math.floor(#ids / job.need)
						if counted then n = math.min(n, job.want[key]) end
						sets = sets + n
					end
				end
			end
			table.sort(out, function(a, b) return a.g.key < b.g.key end)
			return out, sets
		end

		-- runs at the machine: crafts every full set of every planned group. Returns "ok" or "fail".
		local function doCrafts(job, act, list)
			local cfg = job.cfg
			local counted = next(job.want) ~= nil
			for _, p in ipairs(list) do
				local ids = p.ids
				local i, fails = 1, 0
				while act() and i + job.need - 1 <= #ids and (not counted or (job.want[p.g.key] or 0) > 0) do
					if cfg.queue and queueCount() >= RAINBOW_CAPACITY then return "ok" end   -- machine full: the rest waits for a free slot
					local pick = {}
					for k = 1, job.need do pick[k] = ids[i + k - 1].id end
					local args = { PetIds = pick, Machine = cfg.machine, Action = cfg.action }
					local res = requestWait(args, function(d)
						return d.Machine == cfg.machine and d.Action == cfg.action
					end, RESULT_WAIT)

					if res and res.Success then
						for _, pid in ipairs(pick) do spent[pid] = true end
						job.crafts = job.crafts + 1
						i = i + job.need
						fails = 0
						if counted then   -- one craft less to go (also updates the dropdown numbers)
							local left = (job.want[p.g.key] or 1) - 1
							job.want[p.g.key] = left > 0 and left or nil
							local label = string.format("%s (%s)", p.g.name, p.g.tier)
							if job.drop and job.drop.counts then job.drop.counts[label] = job.want[p.g.key] end
							if next(job.want) == nil then job.finished = true end
							if job.drop and job.drop._refreshMulti then job.drop._refreshMulti(true) end
						end
						local what
						if cfg.queue then
							local finish = tonumber(res.EndTime)
								or (workspace:GetServerTimeNow() + (tonumber(res.Duration) or 18000))
							queue[tostring(res.CraftId)] = { finish = finish, name = tostring(res.PetName or p.g.name), fails = 0, at = os.clock() }
							saveQueue()
							what = "started " .. tostring(res.PetName or p.g.name)
						else
							local pet = res.Pet
							what = pet and (tostring(pet.Name) .. " (" .. tostring(pet.Tier) .. ")") or "?"
						end
						job.setStatus(string.format("Crafting | total %d | last: %s", job.crafts, what))
						sleepFor(act, CRAFT_DELAY)
						dismissResult()
					else
						fails = fails + 1
						warn(string.format("[Pets] %s %s (%d/%d)", cfg.name,
							res and "was not successful" or "got no reply", fails, MAX_FAILS))
						if cfg.queue then
							if queueCount() >= RAINBOW_CAPACITY then
								-- all pods are in use: wait for the first running craft to finish
								local nf
								for _, v in pairs(queue) do if not nf or v.finish < nf then nf = v.finish end end
								local left = nf and (nf - workspace:GetServerTimeNow()) or 0
								job.cooldownUntil = os.clock() + (left > 0 and (left + 5) or RAINBOW_RETRY)
								return "fail"
							end
							-- pods should still be free, so this was probably a hiccup: retry, then back off only briefly
							if fails >= MAX_FAILS then
								job.cooldownUntil = os.clock() + 60
								return "fail"
							end
							sleepFor(act, 2)
							dismissResult()
						else
							if fails >= MAX_FAILS then return "fail" end
							sleepFor(act, CRAFT_DELAY)
						end
					end
				end
			end
			return "ok"
		end

		-- Main loop of one craft job: collects pets and starts the machine.
		local function craftLoop(job, id)
			local cfg = job.cfg
			-- True while this craft run is still the current one.
			local function act() return job.act(id) end
			while act() do
				if not HG.gate(cfg.name, act, job.setStatus) then return end   -- priority first
				local full = cfg.queue and queueCount() >= RAINBOW_CAPACITY
				if full then
					local nf
					for _, v in pairs(queue) do if not nf or v.finish < nf then nf = v.finish end end
					local left = nf and (nf - workspace:GetServerTimeNow()) or 0
					if left > 0 then
						job.setStatus(string.format("%s machine full (%d/%d) - next slot in %d:%02d:%02d | crafts %d", cfg.label,
							queueCount(), RAINBOW_CAPACITY, math.floor(left / 3600), math.floor(left / 60) % 60, math.floor(left) % 60, job.crafts))
					else
						job.setStatus(string.format("%s machine full (%d/%d) - finished pets are waiting to be claimed (turn on Collect Rainbow)",
							cfg.label, queueCount(), RAINBOW_CAPACITY))
					end
					sleepFor(act, 5)
				elseif job.cooldownUntil > os.clock() then
					job.setStatus(string.format("%s machine busy - retrying in %ds | crafts %d",
						cfg.label, math.ceil(job.cooldownUntil - os.clock()), job.crafts))
					sleepFor(act, 10)
				else
					job.setStatus("Checking inventory...")
					local groups, why = getGroups(act)
					if not act() then return end
					if not groups then
						job.setStatus("Scan failed (" .. tostring(why) .. "), retrying...")
						sleepFor(act, 10)
					else
						-- Diamond / Rainbow crafts ignore the "Craft When Storage Is" slider (only the Golden craft uses it)
						local list, sets = planFor(job, groups)
						if sets > 0 then
							job.setStatus(string.format("%d %s craft(s) ready - going to the machine...", sets, cfg.label))
							local r = runTrip(cfg.name, act, cfg.island, cfg.cf,
								function() return doCrafts(job, act, list) end, job.setStatus)
							if r == "busy" then
								job.setStatus("Inventory stayed open - will retry next cycle")
							elseif r == "fail" then
								job.setStatus("Crafts failed - will retry later | crafts " .. job.crafts)
							elseif r ~= "stopped" then
								job.setStatus(string.format("Cycle done | total crafts %d | next check soon", job.crafts))
							end
						else
							if job.finished then
								job.setStatus(string.format("Done: every picked craft is finished | crafts %d (pick pets again, or All pets)", job.crafts))
							else
								job.setStatus(string.format("Waiting: need %d+ of the same %s pet | crafts %d",
									job.need, cfg.fromLabel, job.crafts))
							end
						end
						if job.cooldownUntil <= os.clock() then napFor(act, SCAN_EVERY) end
					end
				end
			end
		end

		local diamondJob = newJob({
			name = "Craft to Diamond", icon = "💎", label = "Diamond", fromLabel = "Golden",
			dropName = "Diamond Pet", fromTier = "gold", need = 5,
			amountName = "Diamond Amount",
			amountDesc = "How many Golden pets of the same kind to use per Diamond craft (machine must accept the amount).",
			amounts = { {label="2 pets",pets=2}, {label="3 pets",pets=3}, {label="4 pets",pets=4}, {label="5 pets",pets=5} },
			machine = "Diamond", action = "Craft", island = ISLAND_DIAMOND, cf = CF_DIAMOND,
			desc = "Turns 5 Golden pets of the same kind into a Diamond pet (Crystal Cave). Pauses auto hatch while crafting.",
			dropDesc = "Which Golden pet to turn into Diamond (updates after every scan).",
		})
		local rainbowJob = newJob({
			name = "Craft to Rainbow", icon = "🌈", label = "Rainbow", fromLabel = "Diamond",
			dropName = "Rainbow Pet", fromTier = "diamond", need = 2, queue = true,
			machine = "Shiny", action = "Start", island = ISLAND_RAINBOW, cf = CF_RAINBOW,
			amountName = "Rainbow Amount",
			amountDesc = "How many Diamond pets of the same kind go into ONE Rainbow craft: more pets = a much shorter craft. Kaitun Hatch always uses 2.",
			amounts = {
				{ label = "2 pets (5 hours)", pets = 2 },
				{ label = "3 pets (2.5 hours)", pets = 3 },
				{ label = "4 pets (1 hour)", pets = 4 },
				{ label = "5 pets (30 seconds)", pets = 5 },
			},
			desc = "Starts a Rainbow craft with 2-5 Diamond pets of the same kind (pick the Rainbow Amount; 2 pets = 5 hours, Shadow Realm).",
			dropDesc = "Which Diamond pet to turn into Rainbow (updates after every scan).",
		})
		local collectJob = newJob({
			name = "Collect Rainbow", icon = "🎁", noDrop = true,
			desc = "Claims your Rainbow pets as soon as they are finished (Shadow Realm).",
		})

		-- Returns the crafts that are ready to collect.
		local function readyList()
			syncQueue()
			local ready, now = {}, workspace:GetServerTimeNow()
			for cid, v in pairs(queue) do
				if now >= v.finish then ready[#ready + 1] = cid end
			end
			return ready
		end

		-- Returns the time the next craft finishes.
		local function nextFinish()
			syncQueue()
			local best
			for _, v in pairs(queue) do
				if not best or v.finish < best then best = v.finish end
			end
			return best
		end

		-- Formats seconds as a time text.
		local function fmtTime(s)
			s = math.max(0, math.floor(s))
			return string.format("%d:%02d:%02d", math.floor(s / 3600), math.floor(s / 60) % 60, s % 60)
		end

		-- Loop that collects finished crafts.
		local function collectLoop(job, id)
			-- True while this collect run is still the current one.
			local function act() return job.act(id) end
			while act() do
				if not HG.gate("Collect Rainbow", act, job.setStatus) then return end   -- priority first
				local ready = readyList()
				if #ready > 0 then
					job.setStatus(string.format("%d Rainbow craft(s) finished - going to claim...", #ready))
					local r = runTrip("Collect Rainbow", act, ISLAND_RAINBOW, CF_RAINBOW, function()
						for _, cid in ipairs(ready) do
							if not act() then return "stopped" end
							local res = requestWait({ Machine = "Shiny", Action = "Claim", CraftId = cid }, function(d)
								return d.Action == "Claim" and tostring(d.CraftId) == cid
							end, RESULT_WAIT)
							if res and res.Success then
								queue[cid] = nil
								saveQueue()
								job.crafts = job.crafts + 1
								rainbowJob.cooldownUntil = 0 -- a slot is free again
								local pet = res.Pet
								job.setStatus(string.format("Claimed %d | last: %s", job.crafts,
									pet and (tostring(pet.Name) .. " (" .. tostring(pet.Tier) .. ")") or "?"))
								sleepFor(act, CRAFT_DELAY)
								dismissResult()
							else
								local q = queue[cid]
								if q then
									q.fails = q.fails + 1
									warn(string.format("[Pets] claim %s failed (%d/%d)", cid, q.fails, CLAIM_MAX_FAILS))
									if q.fails >= CLAIM_MAX_FAILS then
										queue[cid] = nil -- probably already claimed
										saveQueue()
									end
								end
							end
						end
						return "ok"
					end, job.setStatus)
					if r == "busy" then job.setStatus("Inventory stayed open - will retry") end
					sleepFor(act, 5)
				else
					local nf = nextFinish()
					if nf then
						job.setStatus(string.format("Waiting | %d craft(s) cooking | next ready in %s | claimed %d",
							queueCount(), fmtTime(nf - workspace:GetServerTimeNow()), job.crafts))
					else
						job.setStatus(string.format("Waiting | no Rainbow crafts started yet | claimed %d", job.crafts))
					end
					sleepFor(act, CLAIM_CHECK)
				end
			end
		end

		bindToggle(diamondJob, craftLoop)
		bindToggle(rainbowJob, craftLoop)
		bindToggle(collectJob, collectLoop)

		return {
			dDrop = diamondJob.drop, dAmount = diamondJob.amountEntry, dCraft = diamondJob.entry,
			rDrop = rainbowJob.drop, rCraft = rainbowJob.entry, rAmount = rainbowJob.amountEntry,
			collect = collectJob.entry,
			dJob = diamondJob, rJob = rainbowJob,
		}
	end

	-------------------------------------------------------------------------- AUTO ENCHANT
	-- Uses the game's own server-side Auto Enchant (EnchantService.RF.AutoStart / AutoStop / Claim). Nothing is hooked:
	-- the script stands at the Enchant Machine, starts the game's auto roll for one pet, waits for the game's own
	-- AutoEvent "Stop", takes the pet back (Claim) and moves on to the next pet of the chosen type.
	-- (kept inside one anonymous function so it only costs buildLogic a single local)
	local ench = (function()
		local ok, result = pcall(function()
			local ENCHANT_ISLAND = "Crystal Cave"   -- island that has the Enchant circle (name used by the Travel remote)
			local ENCHANT_CF     = CFrame.new(125.23588562011719, 7679.91650390625, -1802.23779296875, -0.0898766964673996, -6.825602838489431e-08, -0.9959529042243958, 1.1310895553506839e-09, 1, -6.86354582057902e-08, 0.9959529042243958, -7.2952404117643255e-09, -0.0898766964673996)
			local ISLAND_SETTLE  = 3         -- seconds to let the island load after traveling, before teleporting to the circle
			local MACHINE_WAIT   = 10        -- seconds to wait for the machine to load after traveling
			local CLAIM_WAIT     = 8         -- seconds to keep trying to take a pet back out of the enchanter
			local MAX_RETRIES    = 3         -- retries per pet when the server refuses to start
			local MAX_FAILS      = 5         -- stop after this many refused / odd results in a row
			local CS = game:GetService("CollectionService")

			local svc = find(RS, { "RemoteServices", "EnchantService" })
			assert(svc, "EnchantService not found")
			local RF, RE = svc:FindFirstChild("RF"), svc:FindFirstChild("RE")
			assert(RF and RE, "EnchantService.RF / RE not found")

			local okCfg, Config = pcall(function() return require(RS.Shared.Pets.EnchantConfig) end)
			if not okCfg then Config = nil end

			local REASONS = {
				Connection = "Connection interrupted", DataUnavailable = "Your data is still loading",
				Reserved = "That pet is being traded", ConfirmReplace = "Needs a replace confirmation",
				ClaimFirst = "A pet is still in the enchanter", AutoRunning = "Auto Enchant is already running",
				InsufficientGems = "Not enough gems", InvalidSlot = "That pet can't use that slot",
				ChoosePendingEnchant = "Finishing the last roll first", VisitEnchantMachine = "Not at the Enchant Machine",
				EnchantPending = "Finish the current enchant first", NoFilters = "No filters selected",
				PetChangedChooseKeep = "The pet changed since that roll", Frozen = "That pet is unavailable",
				UnknownPet = "That pet is no longer available", RateLimited = "Rate limited", NoRemote = "Remote not found",
			}
			-- Turns a failure result into readable text.
			local function why(r) return REASONS[r] or tostring(r) end

			-- one remote call: returns the result table, or nil + reason
			local function call(name, args)
				local remote = RF:FindFirstChild(name)
				if not remote then return nil, "NoRemote" end
				local okC, res = pcall(function()
					if args == nil then return remote:InvokeServer() end
					return remote:InvokeServer(args)
				end)
				if not okC then return nil, "Connection" end
				if type(res) == "table" and res.Success then return res end
				return nil, (type(res) == "table" and res.Reason) or "Unknown"
			end

			-- your pets, read from the game's own data (no inventory window needed)
			local function ownedPets()
				local okD, data = pcall(function()
					return require(RS.Controllers.Core.DataController):GetReplica().Data
				end)
				local owned = okD and type(data) == "table" and data.Pets and data.Pets.Owned
				if type(owned) == "table" then return owned end
				return nil
			end
			-- Builds a unique key for a pet.
			local function keyOf(p) return tostring(p.Name) .. "|" .. tostring(p.Tier or "") end

			------------------------------------------------------------ entries
			local ALLOPT = "Game filters"
			local selSlot, replaceRare = 1, false
			local enchWant = {}                  -- pet key -> how many pets of that type to enchant (the + / - counters)
			local enchDone, enchSeen = {}, {}    -- this run: pets finished per type / pets already started
			local bothSlots = false   -- "Both slots": roll slot 1, then slot 2 (only pets that have one)
			local running, runId, selfStop = false, 0, false
			local rollCount, stopEvent = 0, nil
			local doneCount, failCount, lastMsg = 0, 0, ""
			local used = {}
			local groupInfo = {}

			local ENCH_CLEAR = "Clear all"
			local petEntry = {
				type = "dropdown", name = "Pet to Enchant", icon = "🐾", noSave = true, width = 320,
				desc = "Left click a pet type = +1 pet, right click = -1 (or use + / -). That many pets of each picked type that still need a wanted enchant are rolled one after another.",
				options = { ENCH_CLEAR }, default = ENCH_CLEAR,
				counter = true, counts = {}, clearOption = ENCH_CLEAR, emptyText = "Select pets...",
				isClearActive = function() return false end,
			}
			local petLimits = {}
			petEntry.limitOf = function(option) return petLimits[option] or 0 end
			local refreshEntry = {
				type = "button", name = "Refresh Pets", icon = "🔄", noSave = true,
				desc = "Reads your pets and fills the list above.",
			}
			local targetOptions = { ALLOPT }
			if Config then
				local names = {}
				for name in pairs(Config.Enchants) do
					if Config.IsFilterable(name) then names[#names + 1] = name end
				end
				table.sort(names, function(a, b)
					local ra, rb = Config.RankOf(a), Config.RankOf(b)
					if ra ~= rb then return ra > rb end
					return a < b
				end)
				for _, n in ipairs(names) do targetOptions[#targetOptions + 1] = n end
			end
			local TARGET_DESC = "Tick every enchant you'd be happy with (Lucky III, Power III, ...) - the roll stops on the first one that hits. Game filters = use whatever is ticked in the game's Filters panel."
			local targetEntry = {
				type = "dropdown", name = "Target Enchants", icon = "🎯", width = 320,
				multi = true, picked = {}, clearOption = ALLOPT,
				desc = TARGET_DESC,
				options = targetOptions, default = ALLOPT,
			}
			local slotEntry = {
				type = "dropdown", name = "Enchant Slot", icon = "📦", width = 160,
				desc = "Slot 2 only exists on Mythic and Secret pets (Legendary and below have one slot). Both slots = rolls slot 1, then slot 2 on every pet that has one.",
				options = { "Slot 1", "Slot 2", "Both slots" }, default = "Slot 1",
			}
			local replaceEntry = {
				-- TOGGLE "Replace Rare / III Enchants": Off = pets holding a Rare or III-tier enchant (that isn't a wanted one) are skipped, so nothing good gets overwritten.
				type = "toggle", name = "Replace Rare / III Enchants", icon = "🚨", default = false,
				desc = "Off = pets holding a Rare or III-tier enchant (that isn't a wanted one) are skipped, so nothing good gets overwritten.",
			}
			local autoEntry = {
				-- TOGGLE "Auto Enchant": Goes to the Enchant circle, starts the game's own auto roll on each pet until it gets a wanted enchant, then takes the pet back and moves on.
				type = "toggle", name = "Auto Enchant", icon = "🔮", default = false,
				desc = "Goes to the Enchant circle, starts the game's own auto roll on each pet until it gets a wanted enchant, then takes the pet back and moves on. The roll runs on the server, so Auto Hatch (and anything below Enchant in Priority) keeps working while it rolls; the script only goes back to the circle to collect the pet and start the next one.",
			}
			-- Sets the status text of this feature.
			local function status(text) setDesc(autoEntry, text) end

			-- Fills the pet dropdown with the pets you own.
			local function fillPets()
				local owned = ownedPets()
				if not owned then return false end
				local groups = {}
				for _, p in pairs(owned) do
					if type(p) == "table" and type(p.Name) == "string" then
						local k = keyOf(p)
						local g = groups[k]
						if not g then
							g = { key = k, name = p.Name, tier = tostring(p.Tier or "Normal"), count = 0 }
							groups[k] = g
						end
						g.count = g.count + 1
					end
				end
				local list = {}
				for _, g in pairs(groups) do list[#list + 1] = g end
				table.sort(list, function(a, b)
					if a.name ~= b.name then return a.name < b.name end
					return a.tier < b.tier
				end)
				local opts = petEntry.options
				for i = #opts, 1, -1 do opts[i] = nil end
				for k in pairs(petLimits) do petLimits[k] = nil end
				groupInfo = {}
				opts[1] = ENCH_CLEAR
				local labelOf = {}
				for _, g in ipairs(list) do
					local shownTier = (g.tier == "Shiny") and "Rainbow" or g.tier -- the game's data calls Rainbow pets "Shiny"
					local text = string.format("%s (%s)", g.name, shownTier)
					opts[#opts + 1] = text
					groupInfo[text] = g.key
					petLimits[text] = g.count          -- you can't enchant more pets than you own
					labelOf[g.key] = text
				end
				for key in pairs(enchWant) do          -- a picked type you no longer own stays visible (limit 0) so it can be removed
					if not labelOf[key] then
						local text = tostring(key):gsub("|", " (") .. ")"
						opts[#opts + 1] = text
						groupInfo[text] = key
						petLimits[text] = 0
						labelOf[key] = text
					end
				end
				local counts = petEntry.counts
				for k in pairs(counts) do counts[k] = nil end
				for key, n in pairs(enchWant) do counts[labelOf[key]] = n end
				if petEntry._refresh then petEntry._refresh() end
				if petEntry._refreshMulti then petEntry._refreshMulti(true) end
				return true
			end
			refreshEntry.run = function()
				if not fillPets() then error("Couldn't read your pets") end
			end

			petEntry.callback = function(option)
				if option == ENCH_CLEAR then
					for k in pairs(enchWant) do enchWant[k] = nil end
				elseif option == nil then   -- numbers set from outside: rebuild
					for k in pairs(enchWant) do enchWant[k] = nil end
					for label, n in pairs(petEntry.counts) do
						local key = groupInfo[label]
						if key and n > 0 then enchWant[key] = n end
					end
				else
					local key = groupInfo[option]
					if key then
						local n = petEntry.counts[option] or 0
						enchWant[key] = n > 0 and n or nil
					end
				end
			end
			targetEntry.callback = function()
				local names = {}
				for _, o in ipairs(targetEntry.options) do
					if o ~= ALLOPT and targetEntry.picked[o] then names[#names + 1] = o end
				end
				if #names == 0 then
					setDesc(targetEntry, TARGET_DESC)
				else
					setDesc(targetEntry, "Stops on any of: " .. table.concat(names, ", ") .. " (replaces your game filters)")
				end
			end
			slotEntry.callback = function(option)
				bothSlots = (option == "Both slots")
				selSlot = (option == "Slot 2") and 2 or 1
			end
			replaceEntry.callback = function(on) replaceRare = on == true end

			------------------------------------------------------------ helpers for the run
			local cleaning = nil   -- run id that is still putting the pet back after the toggle was switched off
			-- True while this enchant run is still the current one.
			local v2On, v2RunId, v2Busy, v2Want = false, nil, false, false   -- Enchant V2: toggle state, current run id (text), machine in use by V2, V2 has a pet waiting
			local function act(id)
				if type(id) == "string" then return alive and v2On and v2RunId == id end   -- Enchant V2 runs use text ids ("v2:1")
				return alive and ((running and runId == id) or cleaning == id)
			end
			-- Waits `seconds` while the run is active.
			local function nap(id, seconds)
				local t0 = os.clock()
				while act(id) and os.clock() - t0 < seconds do task.wait(0.1) end
			end

			-- take the machine lock; the status says what we are waiting for (it used to stay blank while queued)
			local function getTrip(id, msg)
				status(msg)
				return act(id) -- Enchant works anywhere; no travel lock
			end

			local autoEvt = RE:FindFirstChild("AutoEvent")
			local evConn = autoEvt and autoEvt.OnClientEvent:Connect(function(d)
				if type(d) ~= "table" then return end
				if d.Kind == "Roll" then
					rollCount = rollCount + 1
				elseif d.Kind == "Stop" then
					stopEvent = d
				end
			end)
			table.insert(cleanupHooks, function()
				if evConn then pcall(function() evConn:Disconnect() end) end
			end)

			-- Finds the enchant machine in the world.
			local function findMachine()
				for _, o in ipairs(CS:GetTagged("InteractionPoint")) do
					if o.Name == "Enchant" and o:IsDescendantOf(workspace) then return o end
				end
				return nil
			end
			-- Enchanting now works from anywhere; do not travel or teleport.
			local function nearMachine()
				return true
			end
			-- Travels to the machine (force = even if already near).
			local function goToMachine(id, force)
				local hrp = getHRP()
				return hrp and hrp.CFrame or CFrame.new()
			end

			-- id (optional) = the current run: if the server refuses the claim and we're away from the circle, go back there once
			local function claimPet(id)
				local t0, moved = os.clock(), false
				while alive and os.clock() - t0 < CLAIM_WAIT do
					if lp:GetAttribute("EnchantHeldPet") == nil then return true end
					if call("Claim") then return true end
					if id and not moved and act(id) and not nearMachine() then
						moved = true
						goToMachine(id, true)
					end
					task.wait(0.7)
				end
				return lp:GetAttribute("EnchantHeldPet") == nil
			end

			-- Reads the machine's current state from the server.
			local function readState()
				local res = call("GetState")
				return res and res.Enchanting or nil
			end
			-- Handles an enchant that was already pending when the script started.
			local function resolvePending(en)
				local pend = en and en.Pending
				if type(pend) == "table" and pend.Token then
					return call("Resolve", { Token = pend.Token, UseNew = true }) ~= nil
				end
				return false
			end

			-- the enchant sitting in one slot (nil = empty). Not `slot == 2 and p.Enchant2 or p.Enchant`: that reads slot 1 when slot 2 is empty.
			local function slotValue(p, slot)
				if slot == 2 then return p.Enchant2 end
				return p.Enchant
			end

			-- next (pet, slot) of the chosen type that still needs an enchant (nil, nil = none left; nil, text = problem)
			-- returns pid, pet, slot
			local function nextPet(wanted)
				local owned = ownedPets()
				if not owned then return nil, "Couldn't read your pets" end
				local ids = {}
				for pid, p in pairs(owned) do
					if type(p) == "table" and type(p.Name) == "string" then
						local k = keyOf(p)
						local w = enchWant[k]
						-- picked type, and either the wanted number isn't reached yet or this pet was already started (second slot)
						if w and ((enchDone[k] or 0) < w or enchSeen[tostring(pid)]) then
							ids[#ids + 1] = pid
						end
					end
				end
				table.sort(ids, function(a, b) return tostring(a) < tostring(b) end)
				local slots = bothSlots and { 1, 2 } or { selSlot }
				for _, pid in ipairs(ids) do
					local p = owned[pid]
					for _, slot in ipairs(slots) do
						local cur = slotValue(p, slot)
						local slotOk = not used[tostring(pid) .. ":" .. slot]
						if slot == 2 and Config and Config.GetSlotCount and Config.GetSlotCount(p) < 2 then slotOk = false end
						local has = type(cur) == "string"
						if slotOk and not (has and wanted[cur]) then
							if not (has and Config and Config.IsProtected(cur) and not replaceRare) then
								return pid, p, slot
							end
						end
					end
				end
				return nil, nil
			end

			-- starts the game's auto roll; returns nil when started, else "gems" / "stopped" / "skip", reason
			local function startAuto(id, petId, cur, slot)
				for _ = 1, MAX_RETRIES do
					if not act(id) then return "stopped" end
					local args = { PetId = petId, Slot = slot }
					if type(cur) == "string" and replaceRare and Config and Config.IsProtected(cur) then args.Replace = cur end
					local res, reason = call("AutoStart", args)
					if res then return nil end
					if reason == "InsufficientGems" then return "gems" end
					if reason == "VisitEnchantMachine" then
						goToMachine(id, true)
					elseif reason == "AutoRunning" then
						if type(id) ~= "string" and not v2Busy then call("AutoStop") end   -- never stop a roll that Enchant V2 started (and V2 never stops a normal one)
						nap(id, 1)
					elseif reason == "ClaimFirst" then
						claimPet(id)
					elseif reason == "ChoosePendingEnchant" or reason == "EnchantPending" then
						resolvePending(readState())
					elseif reason == "RateLimited" or reason == "Connection" then
						nap(id, 2)
					else
						return "skip", reason
					end
				end
				return "skip", "Retries"
			end

			-- Waits until the machine stops (finished or cancelled).
			local function waitForStop(id, machine, label)
				local t0 = os.clock()
				while act(id) do
					if stopEvent then return stopEvent end
					if os.clock() - t0 > 4 and lp:GetAttribute("EnchantAutoPet") == nil then
						nap(id, 1) -- the Stop event can arrive a moment after the attribute clears
						return stopEvent or { Kind = "Stop", Reason = "Ended" }
					end
					status(string.format("Rolling %s | %d roll(s) | enchanted %d | in background%s", label, rollCount, doneCount,
						lastMsg ~= "" and (" | last: " .. lastMsg) or ""))
					task.wait(0.25)
				end
				return nil
			end

			-- Target Enchants changed while a run is going: the game's filters and the list this script checks are updated at once
			local liveWanted = nil
			do
				local baseCb, token = targetEntry.callback, 0
				targetEntry.callback = function(...)
					if baseCb then baseCb(...) end
					if not (running and liveWanted) then return end
					token = token + 1
					local my = token
					task.spawn(function()
						task.wait(0.4) -- several ticks in a row count as one change
						if my ~= token or not (running and liveWanted) then return end
						local wanted = liveWanted
						local names = {}
						for _, o in ipairs(targetEntry.options) do
							if o ~= ALLOPT and targetEntry.picked[o] then names[#names + 1] = o end
						end
						if #names > 0 then
							local sres, sreason = call("SetFilters", names)
							if not sres then
								status("Couldn't update the targets: " .. why(sreason))
								return
							end
							for k in pairs(wanted) do wanted[k] = nil end
							for _, n in ipairs(names) do wanted[n] = true end
						else
							local en = readState()
							local f = en and type(en.Filters) == "table" and en.Filters or {}
							local fresh = {}
							for k, v in pairs(f) do if v == true then fresh[k] = true end end
							if next(fresh) == nil then
								status("No target ticked and no game filter set - keeping the current targets")
								return
							end
							for k in pairs(wanted) do wanted[k] = nil end
							for k in pairs(fresh) do wanted[k] = true end
						end
					end)
				end
			end

			------------------------------------------------------------ the run
			local function runLoop(id)
				local gotTrip = false
				local okR, err = pcall(function()
					if not getTrip(id, "Waiting for the machine (a higher priority feature is working)...") then return end
					gotTrip = true
					used, doneCount, failCount, lastMsg = {}, 0, 0, ""
					enchDone, enchSeen = {}, {}

					if next(enchWant) == nil or not next(groupInfo) then
						status("Pick the pets to enchant first (left click = +1, right click = -1)")
						return
					end
					status("Reading your enchant state...")
					local en = readState()
					if not en then status("Couldn't read the enchant state - try again") return end
					if en.Pending and not v2Busy then resolvePending(en) end

					local wanted = {}
					liveWanted = wanted
					local targets = {}
					for _, o in ipairs(targetEntry.options) do -- in list order (best rank first)
						if o ~= ALLOPT and targetEntry.picked[o] then targets[#targets + 1] = o end
					end
					if #targets > 0 then
						local sres, sreason = call("SetFilters", targets)
						if not sres then status("Couldn't set the targets: " .. why(sreason)) return end
						for _, n in ipairs(targets) do wanted[n] = true end
					else
						local f = type(en.Filters) == "table" and en.Filters or {}
						for k, v in pairs(f) do
							if v == true then wanted[k] = true end
						end
						if next(wanted) == nil then
							status("No filters ticked - tick results in the game's Filters panel or pick a Target Enchant")
							return
						end
					end

					if lp:GetAttribute("EnchantHeldPet") ~= nil and not v2Busy then claimPet() end

					status("Preparing Auto Enchant...")
					local machine = goToMachine(id)
					if not act(id) then return end
					if not machine then
						status("Couldn't reach the Enchant circle - check ENCHANT_ISLAND / ENCHANT_CF in the script")
						return
					end
					nap(id, 1)

					while act(id) do
						-- Auto Craft has priority: if it is waiting for the machine, hand it over between pets, then come back
						if false then -- Enchant does not compete for travel priority
							releaseTrip("Enchant")
							gotTrip = false
							status("Paused - a higher priority feature is waiting, handing over...")
							if not getTrip(id, "Paused - a higher priority feature is waiting, handing over...") then return end
							gotTrip = true
							status("Resuming Auto Enchant...")
							if not goToMachine(id) then return end
							nap(id, 1)
							if not act(id) then return end
						end
						-- Enchant V2 has priority: finish nothing new here while V2 has a Rainbow pet waiting (the pet that was rolling is already collected)
						while act(id) and v2On and v2Want do
							status("Paused - Enchant V2 has priority")
							nap(id, 0.5)
						end
						if not act(id) then return end
						local petId, p, slot = nextPet(wanted)
						if not petId then
							if type(p) == "string" then
								status(p)
							else
								status(string.format("Done - %d pet(s) enchanted, none left that need it", doneCount))
							end
							return
						end
						local label = tostring(p.Nickname or p.Name)
						if bothSlots or slot == 2 then label = label .. " (slot " .. slot .. ")" end
						local cur = slotValue(p, slot)
						rollCount, stopEvent = 0, nil
						status("Starting auto roll on " .. label .. "...")

						local outcome, reason = startAuto(id, petId, cur, slot)
						if outcome == "gems" then status("Out of gems") return end
						if outcome == "stopped" then return end
						if outcome == "skip" then
							used[tostring(petId) .. ":" .. slot] = true
							if reason ~= "InvalidSlot" then failCount = failCount + 1 end -- "no such slot" is a normal skip, not a failure
							warn("[Enchant] skipped " .. label .. ": " .. why(reason))
							if failCount >= MAX_FAILS then status("Stopped: the server keeps refusing (" .. why(reason) .. ")") return end
						else
							-- the roll runs on the server, so free the machine now: Auto Hatch (and anything lower in the Priority tab) works meanwhile
							releaseTrip("Enchant")
							gotTrip = false
							local ev = waitForStop(id, machine, label)
							if not ev then return end -- toggled off (the clean-up goes back for the pet)
							used[tostring(petId) .. ":" .. slot] = true
							do
								local kk, sid = keyOf(p), tostring(petId)
								if not enchSeen[sid] then
									enchSeen[sid] = true
									enchDone[kk] = (enchDone[kk] or 0) + 1
								end
							end
							local r = tostring(ev.Reason)
							-- roll finished: queue for the machine, go back to the circle and take the pet out
							if not getTrip(id, "Roll finished - waiting for the machine to collect " .. label .. "...") then return end
							gotTrip = true
							if not nearMachine() then
								status("Resuming Auto Enchant...")
								if not goToMachine(id) then return end
								nap(id, 1)
								if not act(id) then return end
							end
							claimPet(id)
							if r == "Matched" then
								doneCount = doneCount + 1
								failCount = 0
								lastMsg = string.format("%s got %s (%d rolls)", label, tostring(ev.Enchant), tonumber(ev.Rolls) or rollCount)
								if WebhookBridge.enchant then
									pcall(WebhookBridge.enchant, {
										name = p.Name, tier = p.Tier, slot = slot, bothSlots = bothSlots,
										enchant = tostring(ev.Enchant), rolls = tonumber(ev.Rolls) or rollCount,
									})
								end
							elseif r == "Gems" then
								status(string.format("Out of gems after %d roll(s) | enchanted %d", tonumber(ev.Rolls) or rollCount, doneCount))
								return
							else
								failCount = failCount + 1
								lastMsg = label .. ": " .. r
								warn("[Enchant] " .. label .. " stopped with reason " .. r)
								if failCount >= MAX_FAILS then status("Stopped: too many unexpected stops (" .. r .. ")") return end
							end
							nap(id, 0.7)
						end
					end
				end)

				-- cleanup (runs on finish, on error and when the toggle is switched off)
				liveWanted = nil
				if not v2Busy then   -- never touch a roll that Enchant V2 is running
					if lp:GetAttribute("EnchantAutoPet") ~= nil then call("AutoStop") end
					if lp:GetAttribute("EnchantHeldPet") ~= nil then call("Claim") end
				end
				task.wait(0.5)
				-- still rolling / holding a pet and not at the circle (it rolled in the background): go back for it, queued like any other trip
				if (lp:GetAttribute("EnchantAutoPet") ~= nil or lp:GetAttribute("EnchantHeldPet") ~= nil)
					and (not running or runId == id) and not nearMachine() then
					cleaning = id
					local t0 = os.clock()
					if not gotTrip then gotTrip = true end -- no travel lock for Enchant
					if gotTrip then pcall(goToMachine, id, false) end
					if lp:GetAttribute("EnchantAutoPet") ~= nil then call("AutoStop") end
				end
				if lp:GetAttribute("EnchantHeldPet") ~= nil and not v2Busy then pcall(claimPet, id) end
				cleaning = nil
				if gotTrip then releaseTrip("Enchant") end
				if not okR then
					warn("[Enchant] error: " .. tostring(err))
					status("Error - see the output")
				end
				if runId == id and running then
					selfStop = true
					if autoEntry._setUI then autoEntry._setUI(false) else running = false end
					selfStop = false
				else
					status(string.format("Off | enchanted %d", doneCount))
				end
			end

			autoEntry.callback = function(on)
				if on == running then return end
				running = on
				runId = runId + 1
				if on then
					task.spawn(runLoop, runId)
				elseif not selfStop then
					status("Stopping...")
				end
			end

			------------------------------------------------------------ ENCHANT V2
			-- TOGGLE "Enchant V2" + dropdown "Enchant V2 Pets" (Pets > Enchanting, under Auto Enchant).
			-- Watches your pets: any RAINBOW copy (the game's data calls it "Shiny") of a ticked pet that does not hold a Target Enchant yet
			-- (new hatch, finished craft, or one you already own) is put on the game's auto roll until it gets one of the Target Enchants.
			-- Uses the same Enchant Slot / Replace Rare / III settings as Auto Enchant. V2 has priority over Auto Enchant.
			local v2Entry, v2PetEntry
			do
				local V2_CLEAR = "Clear all"
				local V2_AUTO  = "Auto (every Mythical+ Rainbow)"   -- ticked = every Rainbow pet of Mythical rarity or higher, no need to tick pets one by one
				local V2_RANK  = { mythic = 1, mythical = 1, godly = 2, secret = 3, secrets = 3, eternal = 4, divine = 5 }   -- Mythical and above only
				local V2_TIER  = { Shiny = true, Rainbow = true }
				local V2_DESC  = "Auto enchants the RAINBOW version of every ticked pet the moment it appears (hatched, crafted or already owned) with your Target Enchants. Tick \"Auto\" in the list to enchant every Mythical+ Rainbow pet. Takes priority over Auto Enchant. Uses the Enchant Slot and Replace Rare / III settings."
				local v2Names, v2Used, v2Known = {}, {}, {}   -- label -> pet name / "petId:slot" tried / every Mythical+ pet name found          -- dropdown label -> pet name / "petId:slot" -> already tried
				local v2HaveList = false
				local filterCache, filterAt = nil, 0
				local v2Self = false

				-- "Secrets 2" -> "secrets", "Mythical" -> "mythical"
				local function baseRarity(r)
					local b = tostring(r):lower():gsub("%s+[ivx%d]+$", "")
					return b
				end

				-- reads the game's pet / egg modules: returns pet name -> rarity text, for Mythical and above only
				local function v2Scan()
					local found, seen, nodes = {}, {}, 0
					local function rarityText(def)
						for _, k in ipairs({ "Rarity", "RarityName", "PetRarity" }) do
							local v = def[k]
							if type(v) == "string" and v ~= "" then return v end
							if type(v) == "table" then
								for _, nk in ipairs({ "Name", "Id", "ID" }) do
									if type(v[nk]) == "string" then return v[nk] end
								end
							end
						end
						return nil
					end
					local function consider(name, def)
						if type(name) ~= "string" or type(def) ~= "table" then return end
						if Config and Config.Enchants and Config.Enchants[name] then return end   -- an enchant, not a pet
						local r = rarityText(def)
						if r and V2_RANK[baseRarity(r)] and not found[name] then found[name] = r end
					end
					local function go(t, d)
						if seen[t] or nodes > 80000 then return end
						seen[t] = true
						nodes = nodes + 1
						for k, v in pairs(t) do
							if type(v) == "table" then
								if type(k) == "string" then
									consider(k, v)
								else
									consider(v.Name or v.PetName or v.Pet or v.Id or v.ID, v)
								end
								if d < 6 then go(v, d + 1) end
							end
						end
					end
					local root = RS:FindFirstChild("Shared") or RS
					for _, m in ipairs(root:GetDescendants()) do
						if m:IsA("ModuleScript") then
							local n = m.Name:lower()
							if n:find("egg", 1, true) or n:find("pet", 1, true) or n:find("rarit", 1, true) then
								local okR, mod = pcall(require, m)
								if okR and type(mod) == "table" then go(mod, 0) end
							end
						end
					end
					return found
				end

				v2PetEntry = {
					type = "dropdown", name = "Enchant V2 Pets", icon = "🌈", width = 320,
					multi = true, picked = {}, clearOption = V2_CLEAR, emptyText = "Select pets...",
					desc = "Tick every Mythical-and-above pet (owned or not) whose Rainbow version Enchant V2 should enchant, or tick Auto for all of them. Several can be ticked, no amounts. Tip: open the list and type to search.",
					options = { V2_CLEAR, V2_AUTO, "Loading pets..." }, default = V2_CLEAR,
				}
				v2Entry = {
					type = "toggle", name = "Enchant V2", icon = "✨", default = false,
					desc = V2_DESC,
				}
				-- Sets the status text of Enchant V2.
				local function v2Say(text) setDesc(v2Entry, text) end

				-- Fills the pet dropdown (Mythical and above, best rarity first).
				local function v2Fill()
					local found = v2Scan()
					local list = {}
					for name, r in pairs(found) do
						list[#list + 1] = { name = name, r = r, rank = V2_RANK[baseRarity(r)] or 0 }
					end
					table.sort(list, function(a, b)
						if a.rank ~= b.rank then return a.rank > b.rank end
						if a.r ~= b.r then return a.r > b.r end
						return a.name < b.name
					end)
					local opts = v2PetEntry.options
					for i = #opts, 1, -1 do opts[i] = nil end
					for k in pairs(v2Names) do v2Names[k] = nil end
					for k in pairs(v2Known) do v2Known[k] = nil end
					opts[1] = V2_CLEAR
					opts[2] = V2_AUTO
					if #list == 0 then
						opts[3] = "No Mythical+ pets found - press Refresh Pets"
					else
						for _, e in ipairs(list) do
							local label = string.format("%s (%s)", e.name, e.r)
							opts[#opts + 1] = label
							v2Names[label] = e.name
							v2Known[e.name] = true
						end
					end
					v2HaveList = #list > 0
					if v2PetEntry._refresh then v2PetEntry._refresh() end
					if v2PetEntry._refreshMulti then v2PetEntry._refreshMulti(true) end
					return v2HaveList
				end
				pcall(v2Fill)   -- filled right away so saved picks can be restored when the configuration loads

				do   -- "Refresh Pets" also refreshes the V2 list
					local baseRun = refreshEntry.run
					refreshEntry.run = function()
						pcall(v2Fill)
						if baseRun then baseRun() end
					end
				end
				task.spawn(function()   -- nothing found yet (game data not ready): keep trying
					task.wait(6)
					while alive and not v2HaveList do
						pcall(v2Fill)
						local t0 = os.clock()
						while alive and os.clock() - t0 < 30 do task.wait(1) end
					end
				end)

				-- pet names ticked in the dropdown (+ true when "Auto" is ticked)
				local function v2Selected()
					local set, any = {}, false
					local auto = v2PetEntry.picked[V2_AUTO] == true
					for label, nm in pairs(v2Names) do
						if v2PetEntry.picked[label] then set[nm] = true any = true end
					end
					return set, any or auto, auto
				end
				-- Auto mode: is this owned pet Mythical or above? (the scanned list, or the rarity the pet data itself carries)
				local function v2IsMythicPlus(p)
					if v2Known[p.Name] then return true end
					return type(p.Rarity) == "string" and V2_RANK[baseRarity(p.Rarity)] ~= nil
				end
				-- Target Enchants ticked (best rank first)
				local function v2Targets()
					local names = {}
					for _, o in ipairs(targetEntry.options) do
						if o ~= ALLOPT and targetEntry.picked[o] then names[#names + 1] = o end
					end
					return names
				end
				-- the enchants that count as success: Target Enchants, or the game's own filters when none is ticked
				local function v2Wanted(targets)
					local wanted = {}
					if #targets > 0 then
						for _, n in ipairs(targets) do wanted[n] = true end
						return wanted
					end
					if not filterCache or os.clock() - filterAt > 15 then
						local en = readState()
						local f = en and type(en.Filters) == "table" and en.Filters or {}
						local fresh = {}
						for k, v in pairs(f) do if v == true then fresh[k] = true end end
						filterCache, filterAt = fresh, os.clock()
					end
					for k in pairs(filterCache) do wanted[k] = true end
					return wanted
				end

				-- next Rainbow pet (and slot) of a ticked type that still needs a wanted enchant
				local function v2Next(sel, wanted, slots, auto)
					local owned = ownedPets()
					if not owned then return nil end
					local ids = {}
					for pid, p in pairs(owned) do
						if type(p) == "table" and type(p.Name) == "string" and V2_TIER[tostring(p.Tier)] and (sel[p.Name] or (auto and v2IsMythicPlus(p))) then
							ids[#ids + 1] = pid
						end
					end
					table.sort(ids, function(a, b) return tostring(a) < tostring(b) end)
					for _, pid in ipairs(ids) do
						local p = owned[pid]
						for _, slot in ipairs(slots) do
							local cur = slotValue(p, slot)
							local slotOk = not v2Used[tostring(pid) .. ":" .. slot]
							if slot == 2 and Config and Config.GetSlotCount and Config.GetSlotCount(p) < 2 then slotOk = false end
							local has = type(cur) == "string"
							if slotOk and not (has and wanted[cur]) then
								if not (has and Config and Config.IsProtected(cur) and not replaceRare) then
									return pid, p, slot
								end
							end
						end
					end
					return nil
				end

				-- waits until the roll on the machine ends (Matched / Gems / stopped)
				local function v2Wait(id, label, doneN)
					local t0 = os.clock()
					while act(id) do
						if stopEvent then return stopEvent end
						if os.clock() - t0 > 4 and lp:GetAttribute("EnchantAutoPet") == nil then
							nap(id, 1)
							return stopEvent or { Kind = "Stop", Reason = "Ended" }
						end
						v2Say(string.format("Rolling %s | %d roll(s) | enchanted %d | in background", label, rollCount, doneN))
						task.wait(0.25)
					end
					return nil
				end

				local function v2Loop(id)
					local doneN, failN, lastKey = 0, 0, ""
					local okR, err = pcall(function()
						v2Used = {}
						v2Say("Enchant V2 on - watching for Rainbow pets...")
						while act(id) do
							local sel, anySel, autoSel = v2Selected()
							local targets = v2Targets()
							local key = table.concat(targets, "|")
							if key ~= lastKey then lastKey = key v2Used = {} end   -- new targets: every pet may be tried again
							if not anySel then
								v2Want = false
								v2Say("Tick the pets to watch (or Auto) in Enchant V2 Pets")
								nap(id, 2)
							else
								local wanted = v2Wanted(targets)
								if next(wanted) == nil then
									v2Want = false
									v2Say("Pick a Target Enchant (or tick results in the game's Filters panel)")
									nap(id, 3)
								else
									local slots = bothSlots and { 1, 2 } or { selSlot }
									local petId, p, slot = v2Next(sel, wanted, slots, autoSel)
									if not petId then
										v2Want = false
										v2Say(string.format("Watching for %s | enchanted %d", autoSel and "any Mythical+ Rainbow pet" or "Rainbow pets", doneN))
										nap(id, 1.5)
									else
										v2Want = true   -- Auto Enchant (normal) pauses after the pet it is rolling now
										local machineBusy = lp:GetAttribute("EnchantAutoPet") ~= nil or lp:GetAttribute("EnchantHeldPet") ~= nil
										if machineBusy then
											if not running and lp:GetAttribute("EnchantAutoPet") == nil then claimPet(id) end   -- a pet was left in the enchanter
											v2Say("Waiting for the current enchant to finish...")
											nap(id, 0.5)
										else
											local label = tostring(p.Nickname or p.Name) .. " (Rainbow)"
											if bothSlots or slot == 2 then label = label .. " slot " .. slot end
											local okSet = true
											if #targets > 0 then
												local sres, sreason = call("SetFilters", targets)
												if not sres then
													okSet = false
													v2Say("Couldn't set the targets: " .. why(sreason))
													nap(id, 3)
												end
											end
											if okSet then
												local cur = slotValue(p, slot)
												v2Busy = true
												rollCount, stopEvent = 0, nil
												v2Say("Starting auto roll on " .. label .. "...")
												local outcome, reason = startAuto(id, petId, cur, slot)
												if outcome == "gems" then
													v2Busy = false
													v2Say("Out of gems - trying again in 30s")
													nap(id, 30)
												elseif outcome == "stopped" then
													v2Busy = false
												elseif outcome == "skip" then
													v2Busy = false
													v2Used[tostring(petId) .. ":" .. slot] = true
													if reason ~= "InvalidSlot" then failN = failN + 1 end
													warn("[Enchant V2] skipped " .. label .. ": " .. why(reason))
													if failN >= MAX_FAILS then v2Say("Stopped: the server keeps refusing (" .. why(reason) .. ")") return end
												else
													local ev = v2Wait(id, label, doneN)
													if ev then
														v2Used[tostring(petId) .. ":" .. slot] = true
														claimPet(id)
														v2Busy = false
														local r = tostring(ev.Reason)
														if r == "Matched" then
															doneN = doneN + 1
															failN = 0
															v2Say(string.format("%s got %s (%d rolls) | enchanted %d", label, tostring(ev.Enchant), tonumber(ev.Rolls) or rollCount, doneN))
															if WebhookBridge.enchant then
																pcall(WebhookBridge.enchant, {
																	name = p.Name, tier = p.Tier, slot = slot, bothSlots = bothSlots,
																	enchant = tostring(ev.Enchant), rolls = tonumber(ev.Rolls) or rollCount,
																})
															end
														elseif r == "Gems" then
															v2Used[tostring(petId) .. ":" .. slot] = nil
															v2Say("Out of gems - trying again in 30s")
															nap(id, 30)
														else
															failN = failN + 1
															v2Say(label .. ": " .. r)
															warn("[Enchant V2] " .. label .. " stopped with reason " .. r)
															if failN >= MAX_FAILS then v2Say("Stopped: too many unexpected stops (" .. r .. ")") return end
														end
														nap(id, 0.7)
													end
													-- ev == nil: toggled off mid roll, the clean-up below stops the roll and takes the pet back
												end
											end
										end
									end
								end
							end
						end
					end)
					-- clean-up (finish, error or toggle off)
					v2Want = false
					if v2Busy then
						if lp:GetAttribute("EnchantAutoPet") ~= nil then call("AutoStop") end
						if lp:GetAttribute("EnchantHeldPet") ~= nil then call("Claim") end
						task.wait(0.5)
						if lp:GetAttribute("EnchantHeldPet") ~= nil then pcall(claimPet, nil) end
						v2Busy = false
					end
					if not okR then
						warn("[Enchant V2] error: " .. tostring(err))
						v2Say("Error - see the output")
					end
					if v2RunId == id and v2On then
						v2Self = true
						if v2Entry._setUI then v2Entry._setUI(false) else v2On = false end
						v2Self = false
					else
						v2Say(string.format("Off | enchanted %d", doneN))
					end
				end

				local v2Count = 0
				v2Entry.callback = function(on)
					if on == v2On then return end
					v2On = on
					if on then
						v2Count = v2Count + 1
						v2RunId = "v2:" .. v2Count
						task.spawn(v2Loop, v2RunId)
					else
						v2Want = false
						if not v2Self then v2Say("Stopping...") end
					end
				end
			end

			-- fill the pet list once the game data is ready, then keep it up to date by itself
			task.spawn(function()
				task.wait(4)
				while alive do
					pcall(fillPets)
					local t0 = os.clock()
					while alive and os.clock() - t0 < 30 do task.wait(1) end
				end
			end)

			return { refresh = refreshEntry, pet = petEntry, target = targetEntry, slot = slotEntry, replace = replaceEntry, auto = autoEntry, v2 = v2Entry, v2Pet = v2PetEntry }
		end)
		if not ok then
			warn("[WORST Hub] Auto Enchant failed to load: " .. tostring(result))
			return nil
		end
		return result
	end)()

	-------------------------------------------------------------------------- AUTO DELETE
	-- Sets the game's own per-egg Auto Delete list: EggService.RE.AutoDeleteRequested { Egg = "Spotted", Entries = { "Chick", "Lamb_Golden", ... } }
	-- (entry = pet name, plus _Golden / _Diamond / _Shiny for the variants; Shiny = Rainbow). The entries are built from a rarity range,
	-- the variants you tick and the eggs you pick. Which pets an egg drops (and their rarity) is read from the game's own config modules
	-- (auto-detected).
	-- Pets whose rarity can't be read are never added. (kept inside one anonymous function so it only costs buildLogic a single local)
	local autodel = (function()
		local ok, result = pcall(function()
			local SEND_PER_TIER = false   -- false = one call per egg with every entry; true = one call per variant (Normal, then Golden, ...)
			local SEND_GAP      = 0.25    -- seconds between calls
			local RARITY_ORDER  = { "common", "uncommon", "rare", "epic", "legendary", "mythic", "mythical", "godly", "secret" } -- lowest -> highest (Godly is BELOW the Secrets; Secret I/II/III sort after it by their number)
			local RARITY_KEYS   = { "Rarity", "RarityName", "PetRarity" }
			local NAME_KEYS     = { "Name", "PetName", "Pet", "Id", "ID" }
			local VARIANTS = {
				{ label = "Normal",    suffix = "" },
				{ label = "Golden",    suffix = "_Golden" },
				{ label = "Diamond",   suffix = "_Diamond" },
				{ label = "Rainbow",   suffix = "_Shiny" },
			}
			local ROMAN = { I = 1, II = 2, III = 3, IV = 4, V = 5, VI = 6 }

			local remote = find(RS, { "RemoteServices", "EggService", "RE", "AutoDeleteRequested" })
			assert(remote, "EggService.RE.AutoDeleteRequested not found")

			------------------------------------------------------------ reading the game's pet / egg data
			local petRarity, eggPets, rarityList, rarityIndex = {}, {}, {}, {}
			local info = { mods = 0, pets = 0, eggs = 0 }

			-- Returns the rarity of a pet definition.
			local function rarityOf(def)
				if type(def) ~= "table" then return nil end
				for _, k in ipairs(RARITY_KEYS) do
					local v = def[k]
					if type(v) == "string" and v ~= "" then return v end
					if type(v) == "number" then return "Rarity " .. v end
					if type(v) == "table" then
						for _, nk in ipairs(NAME_KEYS) do
							if type(v[nk]) == "string" then return v[nk] end
						end
					end
				end
				return nil
			end
			-- Returns the name of a pet definition.
			local function nameOf(def)
				for _, k in ipairs(NAME_KEYS) do
					if type(def[k]) == "string" then return def[k] end
				end
				return nil
			end

			local nodes = 0
			-- Walks a table tree and calls fn on every pet definition (depth-limited).
			local function walk(root, fn, maxDepth)
				local seen = {}
				-- Recursive step of the walk (skips tables already seen).
				local function go(t, d)
					if seen[t] then return end
					seen[t] = true
					nodes = nodes + 1
					if nodes % 1500 == 0 then task.wait() end -- never freeze the game while scanning
					fn(t)
					if d >= maxDepth then return end
					for _, v in pairs(t) do
						if type(v) == "table" then go(v, d + 1) end
					end
				end
				go(root, 0)
			end

			-- require with a time limit (a module that never returns must not freeze Auto Delete / Kaitun)
			local function safeRequire(m)
				local done, okR, mod = false, false, nil
				task.spawn(function() okR, mod = pcall(require, m) done = true end)
				local t0 = os.clock()
				while not done and os.clock() - t0 < 2 do task.wait() end
				return done and okR and type(mod) == "table" and mod or nil
			end
			-- all = false: only modules whose name mentions egg / pet / rarity (the normal search)
			-- all = true : every module under Shared (wider look, used only for eggs the normal search found no pets for)
			local function candidateModules(all)
				local list = {}
				local root = RS:FindFirstChild("Shared") or RS
				for _, m in ipairs(root:GetDescendants()) do
					if m:IsA("ModuleScript") then
						local n = m.Name:lower()
						if all then
							local mod = safeRequire(m)
							if mod then list[#list + 1] = { path = m:GetFullName(), mod = mod } end
						elseif n:find("egg", 1, true) or n:find("pet", 1, true) or n:find("rarit", 1, true) then
							local okR, mod = pcall(require, m)
							if okR and type(mod) == "table" then list[#list + 1] = { path = m:GetFullName(), mod = mod } end
						end
					end
				end
				return list
			end

			-- Turns a rarity text into a sortable key (handles suffixes like "II").
			local function rarityKey(r)
				local base, suffix = r:match("^(.-)%s+([IVX]+)$")
				if not base then base, suffix = r:match("^(.-)%s+(%d+)$") end
				base = (base or r):lower()
				local idx = 99
				for i, w in ipairs(RARITY_ORDER) do
					if w == base then idx = i break end
				end
				return idx, suffix and (ROMAN[suffix] or tonumber(suffix) or 0) or 0
			end

			-- reads the given modules: returns (pet name -> rarity, egg -> { set = pets it can drop, n = count })
			local function scan(mods)
				local petRarity = {}   -- local on purpose: the real tables are only replaced once the whole search is done

				-- 1) every pet name that has a rarity
				for _, m in ipairs(mods) do
					walk(m.mod, function(t)
						for k, v in pairs(t) do
							if type(v) == "table" then
								local r = rarityOf(v)
								if r then
									if type(k) == "string" then
										if not petRarity[k] then petRarity[k] = r end
									else
										local n = nameOf(v)
										if n and not petRarity[n] then petRarity[n] = r end
									end
								end
							end
						end
					end, 6)
				end

				-- 2) which of those pets each egg can drop (the biggest match wins)
				local alias = {}
				for _, n in ipairs(eggNames) do
					alias[n] = n
					alias[n .. "Egg"] = n
					alias[n .. " Egg"] = n
				end
				local best = {}
				for _, m in ipairs(mods) do
					walk(m.mod, function(t)
						for k, v in pairs(t) do
							local egg = type(k) == "string" and alias[k] or nil
							if not egg and type(v) == "table" then
								local id = v.Egg or v.EggName or v.Name or v.Id
								if type(id) == "string" then egg = alias[id] end
							end
							if egg and type(v) == "table" then
								local set, n = {}, 0
								walk(v, function(x)
									for kk, vv in pairs(x) do
										if type(kk) == "string" and petRarity[kk] and not set[kk] then set[kk] = true n = n + 1 end
										if type(vv) == "string" and petRarity[vv] and not set[vv] then set[vv] = true n = n + 1 end
									end
								end, 4)
								if n > (best[egg] and best[egg].n or 0) then best[egg] = { set = set, n = n } end
							end
						end
					end, 6)
				end

				return petRarity, best
			end

			local wideMods = nil   -- every module under Shared, loaded once and only when needed
			local lastMissingKey = nil
			-- Scans the game's pet definition modules to learn every pet and its rarity.
			local function discover()
				local mods = candidateModules()
				local pr, best = scan(mods)
				-- some eggs (usually brand-new ones) keep their drop table in a module whose name does not mention egg / pet / rarity:
				-- for those eggs only, look through every module under Shared (what was already found is kept as it is)
				local missing = {}
				for _, n in ipairs(eggNames) do if not best[n] then missing[#missing + 1] = n end end
				if #missing > 0 then
					wideMods = wideMods or candidateModules(true)
					local pr2, best2 = scan(wideMods)
					for k, v in pairs(pr2) do if pr[k] == nil then pr[k] = v end end
					for _, n in ipairs(missing) do if best2[n] then best[n] = best2[n] end end
					mods = wideMods
				end
				local still = {}
				for _, n in ipairs(eggNames) do if not best[n] then still[#still + 1] = n end end
				local key = table.concat(still, ",")
				if key ~= lastMissingKey then
					lastMissingKey = key
					if #still > 0 then warn("[AutoDelete] no pet data found for egg(s): " .. key .. " - Auto Delete cannot set lists for them") end
				end
				petRarity, eggPets, rarityList, rarityIndex = pr, {}, {}, {}
				info.mods, info.pets, info.eggs = #mods, 0, 0
				for _ in pairs(pr) do info.pets = info.pets + 1 end

				-- 3) the rarities that actually occur, lowest first
				local seen = {}
				for egg, b in pairs(best) do
					eggPets[egg] = b.set
					info.eggs = info.eggs + 1
					for pet in pairs(b.set) do
						local r = petRarity[pet]
						if r and not seen[r] then seen[r] = true rarityList[#rarityList + 1] = r end
					end
				end
				table.sort(rarityList, function(a, b)
					local ia, sa = rarityKey(a)
					local ib, sb = rarityKey(b)
					if ia ~= ib then return ia < ib end
					if sa ~= sb then return sa < sb end
					return a < b
				end)
				for i, r in ipairs(rarityList) do rarityIndex[r] = i end
			end

			------------------------------------------------------------ entries
			local ALLEGG, NONE = "All eggs", "None selected"
			local selFrom, selTo = nil, nil
			local running, runToken, debounce = false, 0, 0
			local applied = {} -- egg -> true for every egg we have set

			-- eggs that must always be in the Auto Delete list (new islands the hatch list may not have / detect): added to Auto Delete ONLY,
			-- they do not appear in "Egg to Hatch". Already-known eggs are not added twice. Add more names here if an egg is missed.
			local EXTRA_DELETE_EGGS = { "Volcanic", "Draconic", "Heaven" }
			do
				local have = {}
				for _, n in ipairs(eggNames) do have[n] = true end
				for _, n in ipairs(EXTRA_DELETE_EGGS) do
					if not have[n] then eggNames[#eggNames + 1] = n have[n] = true end
				end
			end
			local eggOpts = { ALLEGG }
			for _, n in ipairs(eggNames) do eggOpts[#eggOpts + 1] = n end
			local varOpts = { NONE }
			for _, v in ipairs(VARIANTS) do varOpts[#varOpts + 1] = v.label end

			local refreshEntry = {
				type = "button", name = "Refresh Egg Data", icon = "🔄", noSave = true,
				desc = "Reads which pets each egg drops and their rarity from the game. Run it once (it also runs by itself a few seconds after loading).",
			}
			local eggPick = {
				type = "dropdown", name = "Eggs", icon = "🥚", width = 320, multi = true, picked = {}, clearOption = ALLEGG,
				desc = "Tick the eggs to set up. Nothing ticked = every egg.",
				options = eggOpts, default = ALLEGG,
			}
			local fromEntry = {
				type = "dropdown", name = "Delete Rarity From", icon = "🔽", width = 240,
				desc = "Lowest rarity to delete (pets from this rarity up to \"Delete Rarity To\").",
				options = { "Loading egg data..." }, default = "Loading egg data...",
			}
			local toEntry = {
				type = "dropdown", name = "Delete Rarity To", icon = "🔼", width = 240,
				desc = "Highest rarity to delete. Pick the same rarity in both boxes to delete just that one.",
				options = { "Loading egg data..." }, default = "Loading egg data...",
			}
			local varPick = {
				type = "dropdown", name = "Variants", icon = "🌟", width = 320, multi = true, picked = {}, clearOption = NONE,
				desc = "Tick every variant to delete (Normal, Golden, Diamond, Rainbow). Nothing ticked = nothing is deleted.",
				options = varOpts, default = NONE,
			}
			local autoEntry = {
				-- TOGGLE "Auto Delete" (Farming > Delete Hatches): sets the game's own Auto Delete lists for the chosen eggs.
				type = "toggle", name = "Auto Delete", icon = "🗑", default = false,
				desc = "Sets the game's Auto Delete lists for the chosen eggs. If pets inside the chosen rarities / variants still stay in your inventory, it refreshes the egg data by itself. Turning it off (or closing the hub) clears the lists it set.",
			}
			-- Sets the status text of Delete Hatches.
			local function status(text) setDesc(autoEntry, text) end

			-- Fills the "Rarity From / To" dropdowns with the rarities found.
			local function fillRarities()
				for _, e in ipairs({ fromEntry, toEntry }) do
					local opts = e.options
					for i = #opts, 1, -1 do opts[i] = nil end
					if #rarityList == 0 then opts[1] = "Loading egg data..." end
					for _, r in ipairs(rarityList) do opts[#opts + 1] = r end
				end
				if #rarityList > 0 then
					if not rarityIndex[selFrom] then selFrom = rarityList[1] end
					if not rarityIndex[selTo] then selTo = rarityList[1] end
				end
				if fromEntry._refresh then fromEntry._refresh(selFrom or fromEntry.options[1]) end
				if toEntry._refresh then toEntry._refresh(selTo or toEntry.options[1]) end
			end

			-- Builds the one-line summary of what was discovered (modules, pets, eggs).
			local function summaryText()
				return string.format("%d module(s) | %d pet(s) with a rarity | %d egg(s) matched | rarities: %s",
					info.mods, info.pets, info.eggs, #rarityList > 0 and table.concat(rarityList, ", ") or "none")
			end

			-- Returns the eggs ticked in the egg dropdown.
			local function selectedEggs()
				local any = false
				for _, n in ipairs(eggNames) do if eggPick.picked[n] then any = true end end
				local list = {}
				for _, n in ipairs(eggNames) do
					if not any or eggPick.picked[n] then list[#list + 1] = n end
				end
				return list
			end

			-- returns plan (list of { egg, entries }), total   or   nil, message
			local function plan()
				if not next(eggPets) then return nil, "Egg data is still loading - try again in a few seconds" end
				local lo, hi = rarityIndex[selFrom], rarityIndex[selTo]
				if not lo or not hi then return nil, "Pick the rarity range first" end
				if lo > hi then lo, hi = hi, lo end
				local vars = {}
				for _, v in ipairs(VARIANTS) do
					if varPick.picked[v.label] then vars[#vars + 1] = v end
				end
				if #vars == 0 then return nil, "Tick at least one variant" end

				local out, total = {}, 0
				for _, egg in ipairs(selectedEggs()) do
					local pets = eggPets[egg]
					if pets then
						local names = {}
						for pet in pairs(pets) do
							local ri = rarityIndex[petRarity[pet]]
							if ri and ri >= lo and ri <= hi then names[#names + 1] = pet end
						end
						table.sort(names)
						local entries = {}
						for _, v in ipairs(vars) do
							for _, pet in ipairs(names) do entries[#entries + 1] = pet .. v.suffix end
						end
						if #entries > 0 then
							out[#out + 1] = { egg = egg, entries = entries }
							total = total + #entries
						end
					end
				end
				if #out == 0 then return nil, "Nothing matches that rarity range on the chosen eggs" end
				return out, total
			end

			------------------------------------------------------------ sending
			local function send(egg, entries)
				local okS, err = pcall(function() remote:FireServer({ Egg = egg, Entries = entries }) end)
				if not okS then warn("[AutoDelete] send failed for " .. egg .. ": " .. tostring(err)) end
				return okS
			end
			-- True if an entry name ends with the given tier suffix.
			local function hasSuffix(e, suffix) return suffix ~= "" and e:sub(-#suffix) == suffix end
			-- Sends the delete list of one egg to the server (split per tier if needed).
			local function sendEgg(egg, entries)
				if not SEND_PER_TIER or #entries == 0 then send(egg, entries) return end
				for _, v in ipairs(VARIANTS) do
					local part = {}
					for _, e in ipairs(entries) do
						local isVariant = false
						for _, w in ipairs(VARIANTS) do
							if hasSuffix(e, w.suffix) then isVariant = true end
						end
						if (v.suffix == "" and not isVariant) or hasSuffix(e, v.suffix) then part[#part + 1] = e end
					end
					if #part > 0 then send(egg, part) task.wait(SEND_GAP) end
				end
			end

			-- Clears the lists that were set (except the ones in `keep`).
			local function clearApplied(keep)
				for egg in pairs(applied) do
					if not (keep and keep[egg]) then
						send(egg, {})
						applied[egg] = nil
						task.wait(SEND_GAP)
					end
				end
			end

			-- Sets the game's Auto Delete lists for the chosen eggs.
			local function applyOnRun()
				runToken = runToken + 1
				local my = runToken
				local p, total = plan()
				if not p then status(tostring(total)) return end
				local keep = {}
				for _, item in ipairs(p) do keep[item.egg] = true end
				clearApplied(keep) -- eggs that were set before but no longer match / aren't ticked
				for i, item in ipairs(p) do
					if not running or my ~= runToken then return end
					status(string.format("Setting %s (%d/%d)...", item.egg, i, #p))
					sendEgg(item.egg, item.entries)
					applied[item.egg] = true
					print(string.format("[AutoDelete] %s: %s", item.egg, table.concat(item.entries, ", ")))
					task.wait(SEND_GAP)
				end
				if running and my == runToken then
					status(string.format("On | %d entries set on %d egg(s)", total, #p))
				end
			end

			-- counts the runs in progress so Kaitun can wait until every list has been sent
			local applyActive = 0
			-- Starts applying the lists (turn-on step).
			local function applyOn()
				applyActive = applyActive + 1
				local okA, errA = pcall(applyOnRun)
				applyActive = applyActive - 1
				if not okA then warn("[AutoDelete] apply failed: " .. tostring(errA)) end
			end

			-- Stops applying and clears the lists (turn-off step).
			local function applyOff()
				runToken = runToken + 1
				clearApplied(nil)
				status("Off | lists cleared")
			end

			local AW = { run = 0, rebase = false }   -- the Auto Delete watcher (filled in further down): refreshes the egg data when pets inside the chosen range still arrive
			-- Re-applies the lists after one of the settings changed while it is on.
			local function reapply() -- a setting changed while Auto Delete is on
				if not running then return end
				AW.rebase = true   -- eggs / rarities / variants changed: what you own now is the new starting point
				debounce = debounce + 1
				local my = debounce
				task.delay(0.8, function()
					if alive and running and my == debounce then applyOn() end
				end)
			end

			-- hooks filled in further down (Pets tab > Auto Delete > Delete Pets): afterRefresh(why, noWait) runs the Delete Pets button
			local INVX = { afterRefresh = nil, busy = false }

			------------------------------------------------------------ callbacks
			eggPick.callback = function() reapply() end
			varPick.callback = function() reapply() end
			fromEntry.callback = function(option) if rarityIndex[option] then selFrom = option reapply() end end
			toEntry.callback = function(option) if rarityIndex[option] then selTo = option reapply() end end

			refreshEntry.run = function()
				local okD, err = pcall(discover)
				if not okD then
					setDesc(refreshEntry, "Detection failed: " .. tostring(err))
					error("Detection failed")
				end
				fillRarities()
				setDesc(refreshEntry, summaryText())
				for _, egg in ipairs(selectedEggs()) do
					if not eggPets[egg] then warn("[AutoDelete] No pet/drop mapping found for " .. egg) end
				end
				if running then task.spawn(applyOn) end
				if running and INVX.afterRefresh then task.spawn(INVX.afterRefresh, "egg data refreshed") end   -- Farming Auto Delete is on: also run Delete Pets
				if #rarityList == 0 or not next(eggPets) then error("No usable pet/drop mapping found; see console") end
			end

			autoEntry.callback = function(on)
				if on == running then return end
				running = on
				if on then
					task.spawn(applyOn)
					if AW.start then AW.start() end
				else
					AW.run = AW.run + 1
					task.spawn(applyOff)
				end
			end

			-- closing the hub clears whatever it set, so nothing keeps deleting pets unseen
			table.insert(cleanupHooks, function()
				running = false
				for egg in pairs(applied) do pcall(send, egg, {}) end
			end)

			-- Kaitun: Common -> Legendary, Normal -> Rainbow, every egg, Auto Delete on (off = lists cleared)
			local function pickRarity(word)
				for _, r in ipairs(rarityList) do
					if tostring(r):lower() == word then return r end
				end
			end
			local kaitunWatch   -- watcher (assigned further down): while Kaitun is on, re-sets the Farming Auto Delete when pets below Mythical are gained
			-- Lets Kaitun switch the Delete Hatches feature on or off.
			local function kaitunApply(on)
				if kaitunWatch then pcall(kaitunWatch, on) end
				if INVX.kaitun then pcall(INVX.kaitun, on) end   -- Pets > Auto Delete Inventory runs together with the Farming Auto Delete (even if the Farming one breaks below)
				if not on then
					if autoEntry._setUI then autoEntry._setUI(false) else autoEntry.callback(false) end
					return true
				end
				-- Always rescan before Kaitun starts: new eggs may have appeared since loading.
				local scanned, scanErr = pcall(discover)
				if scanned then fillRarities() else warn("[AutoDelete] Kaitun scan failed: " .. tostring(scanErr)) end
				local lo, hi = pickRarity("common"), pickRarity("legendary")
				if not (lo and hi) then return false, "rarity list not loaded yet" end
				selFrom, selTo = lo, hi
				if fromEntry._refresh then fromEntry._refresh(lo) end
				if toEntry._refresh then toEntry._refresh(hi) end
				for k in pairs(eggPick.picked) do eggPick.picked[k] = nil end
				for k in pairs(varPick.picked) do varPick.picked[k] = nil end
				for _, v in ipairs({ "Normal", "Golden", "Diamond", "Rainbow" }) do varPick.picked[v] = true end
				if eggPick._refreshMulti then eggPick._refreshMulti() end
				if varPick._refreshMulti then varPick._refreshMulti() end
				if running then
					task.spawn(applyOn)
				elseif autoEntry._setUI then
					autoEntry._setUI(true)
				else
					autoEntry.callback(true)
				end
				return true
			end


			------------------------------------------------------------ INVENTORY DELETE (Pets tab > Auto Delete)
			-- Deletes pets you already own (not the egg lists above): every pet whose rarity is inside the Common..Secrets 3 range you pick
			-- and whose variant is ticked. Locked and equipped pets are never touched (same rule as the crafting scan).
			-- Pets whose rarity can't be read are never deleted. Nothing happens until at least one variant is ticked.
			local INV_RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Godly", "Secrets 1", "Secrets 2", "Secrets 3" }   -- lowest -> highest
			local INV_EVERY    = 5      -- seconds between two delete passes
			local INV_CHUNK    = 25     -- pets per request
			local INV_GAP      = 0.5    -- seconds between requests
			-- The game's own delete request (captured from a manual delete):
			--   PetService.RE.PetActionRequested:FireServer({ PetIds = { id, ... }, Action = "Delete", Batch = n })
			--   answer: PetService.RE.PetActionResult({ Batch = n, Count = deleted, Skipped = x, Success = true, Action = "Delete" })
			local INV_REMOTE_PATH = { "RemoteServices", "PetService", "RE", "PetActionRequested" }
			local INV_RESULT_PATH = { "RemoteServices", "PetService", "RE", "PetActionResult" }
			local INV_RESULT_WAIT = 4   -- seconds to wait for the server's answer to one request
			-- Builds the arguments for the inventory delete request.
			local function INV_ARGS(ids, batch) return { PetIds = ids, Action = "Delete", Batch = batch } end

			-- answers from the server (also the game's own, so our Batch numbers keep counting after them)
			local invResults, invBatch = {}, 0
			do
				local node = RS
				for _, n in ipairs(INV_RESULT_PATH) do node = node and node:FindFirstChild(n) end
				if node and node:IsA("RemoteEvent") then
					connect(node.OnClientEvent, function(a)
						if type(a) == "table" and tonumber(a.Batch) then
							invResults[a.Batch] = a
							if a.Batch > invBatch then invBatch = a.Batch end
						end
					end)
				end
			end

			local invRank, invRankLower = {}, {}
			for i, r in ipairs(INV_RARITIES) do invRank[r] = i invRankLower[r:lower()] = i end
			local invFromSel, invToSel = INV_RARITIES[1], "Legendary"   -- default upper end = Legendary (Mythical and above only when you choose it)
			-- game rarity text -> index in INV_RARITIES (nil = not deletable / unknown).
			-- "Mythic" = "Mythical"; "Secret 1", "Secrets 1", "Secret I", "Secret1" -> "Secrets 1"; a number after any other rarity is ignored.
			local invWarned = {}
			-- Returns the index of a rarity (used to compare From / To).
			local function invRarityIdx(r)
				local low = tostring(r):lower():gsub("^%s+", ""):gsub("%s+$", "")
				local base, num = low:match("^(.-)%s*(%d+)$")
				if not base then
					local b2, rn = low:match("^(.-)%s+([ivx]+)$")
					if b2 then base, num = b2, ({ i = 1, ii = 2, iii = 3, iv = 4, v = 5, vi = 6 })[rn] end
				end
				base = base or low
				local idx
				if base == "secret" or base == "secrets" then
					idx = num and invRankLower["secrets " .. tostring(num)] or nil
				elseif base == "mythic" or base == "mythical" then
					idx = invRankLower["mythical"]
				else
					idx = invRankLower[base]
				end
				if not idx and not invWarned[low] then
					invWarned[low] = true
					warn("[AutoDelete] inventory: rarity \"" .. tostring(r) .. "\" is not in the Auto Delete list - pets with it are never deleted")
				end
				return idx
			end
			local invOn, invRun, invRemote, invListed = false, 0, nil, false

			local invFrom = {
				type = "dropdown", name = "Pet Rarity From", icon = "🔽", width = 240,
				desc = "Lowest rarity to delete from your inventory (Common up to Secrets 3).",
				options = INV_RARITIES, default = INV_RARITIES[1],
			}
			local invTo = {
				type = "dropdown", name = "Pet Rarity To", icon = "🔼", width = 240,
				desc = "Highest rarity to delete from your inventory. Pick the same rarity in both boxes to delete just that one.",
				options = INV_RARITIES, default = "Legendary",
			}
			local invVariants = {
				type = "dropdown", name = "Pet Variants", icon = "🌟", width = 320, multi = true, picked = {}, clearOption = NONE,
				desc = "Tick every variant to delete (Normal, Golden, Diamond, Rainbow). Nothing ticked = nothing is deleted.",
				options = varOpts, default = NONE,
			}
			local invDelete = {
				type = "button", name = "Delete Pets", icon = "🗑", noSave = true,
				desc = "Deletes, once and right now, every pet in your inventory from Pet Rarity From (Common) up to Pet Rarity To, for the variants ticked above. Locked and equipped pets are kept. Also runs by itself every time the Farming Auto Delete finishes refreshing the egg data.",
			}
			local invAuto = {
				-- TOGGLE "Auto Delete Inventory": Deletes the pets in your inventory that match the settings above, every 
				type = "toggle", name = "Auto Delete Inventory", icon = "🗑", default = false,
				desc = "Deletes the pets in your inventory that match the settings above, every " .. INV_EVERY .. " seconds. Locked and equipped pets are kept.",
			}

			-- Sets the status text of Delete Pets.
			local function invStatus(text) setDesc(invAuto, text) end

			-- Finds the server remote that deletes pets.
			local function findInvRemote()
				if invRemote and invRemote.Parent then return invRemote end
				invRemote = nil
				if INV_REMOTE_PATH then
					local node = RS
					for _, n in ipairs(INV_REMOTE_PATH) do node = node and node:FindFirstChild(n) end
					if node then invRemote = node return node end
				end
				local root = RS:FindFirstChild("RemoteServices")
				if not root then return nil end
				local best, bestScore, names = nil, 0, {}
				for _, svc in ipairs(root:GetChildren()) do
					for _, box in ipairs(svc:GetChildren()) do
						for _, r in ipairs(box:GetChildren()) do
							if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
								local sv, n = svc.Name:lower(), r.Name:lower()
								local nameHit = n:find("delete", 1, true) or n:find("sell", 1, true) or n:find("discard", 1, true) or n:find("remove", 1, true)
								if nameHit or sv:find("pet", 1, true) or sv:find("inventory", 1, true) then
									names[#names + 1] = svc.Name .. "." .. box.Name .. "." .. r.Name
								end
								if nameHit and not n:find("auto", 1, true) and not sv:find("egg", 1, true)
									and (sv:find("pet", 1, true) or sv:find("inventory", 1, true)) then
									local score = (n:find("delete", 1, true) and 3 or 2) + (n:find("pet", 1, true) and 1 or 0)
									if score > bestScore then best, bestScore = r, score end
								end
							end
						end
					end
				end
				if best then
					invRemote = best
					print("[AutoDelete] inventory delete remote: " .. best:GetFullName())
					return best
				end
				if not invListed then
					invListed = true
					table.sort(names)
					warn("[AutoDelete] no pet delete remote found. Remotes that might be it: " .. (#names > 0 and table.concat(names, ", ") or "none")
						.. " - set INV_REMOTE_PATH in the script")
				end
				return nil
			end

			-- one pass: returns how many pets were sent for deletion, or nil + message
			-- force = true: a manual pass (Delete Pets button) that does not depend on the Auto Delete Inventory toggle
			local function invPassRun(my, force)
				if env.TSR_TRADE_BUSY then return 0 end   -- Site_Panel is trading: don't delete pets right now
				if not next(petRarity) then pcall(discover) end
				if not next(petRarity) then return nil, "Pet data is still loading..." end
				local lo, hi = invRank[invFromSel], invRank[invToSel]
				if lo > hi then lo, hi = hi, lo end
				local vars, anyVar = {}, false
				for _, v in ipairs(VARIANTS) do
					if invVariants.picked[v.label] then vars[v.label] = true anyVar = true end
				end
				if not anyVar then return nil, "Tick at least one variant" end
				local remote = findInvRemote()
				if not remote then return nil, "Pet delete remote not found - see the output" end
				local groups, why = scanFromData()
				if not groups then return nil, "Can't read your pets (" .. tostring(why) .. ")" end

				local ids = {}
				for _, g in pairs(groups) do
					local r = petRarity[g.name]
					if r and vars[g.tier] then
						local idx = invRarityIdx(r)   -- only the rarities listed in the dropdowns can be deleted
						if idx and idx >= lo and idx <= hi then
							for _, x in ipairs(g.ids) do ids[#ids + 1] = x.id end
						end
					end
				end
				if #ids == 0 then return 0 end
				local deleted, skipped, failed = 0, 0, 0
				for i = 1, #ids, INV_CHUNK do
					if not (alive and (force or (invOn and invRun == my))) then break end
					local chunk = {}
					for k = i, math.min(i + INV_CHUNK - 1, #ids) do chunk[#chunk + 1] = ids[k] end
					invBatch = invBatch + 1
					local batch = invBatch
					local okS, err = pcall(function()
						if remote:IsA("RemoteFunction") then remote:InvokeServer(INV_ARGS(chunk, batch)) else remote:FireServer(INV_ARGS(chunk, batch)) end
					end)
					if not okS then
						failed = failed + #chunk
						warn("[AutoDelete] inventory delete failed: " .. tostring(err))
					else
						local t0 = os.clock()
						while alive and not invResults[batch] and os.clock() - t0 < INV_RESULT_WAIT do task.wait(0.1) end
						local res = invResults[batch]
						invResults[batch] = nil
						if res and res.Success then
							deleted = deleted + (tonumber(res.Count) or #chunk)
							skipped = skipped + (tonumber(res.Skipped) or 0)
						elseif res then
							failed = failed + #chunk
							warn("[AutoDelete] server refused batch " .. batch .. ": " .. tostring(res.Reason or res.Error or "no reason given"))
						else
							deleted = deleted + #chunk -- no answer seen; the pets list will show whether it worked on the next pass
						end
					end
					task.wait(INV_GAP)
				end
				return deleted, skipped, failed
			end

			-- Runs one pass that deletes the pets in the chosen range (force = ignore the toggle).
			local function invPass(my, force)   -- never two passes at the same time
				if INVX.busy then return nil, "another delete pass is still running" end
				INVX.busy = true
				local okP, a, b, c = pcall(invPassRun, my, force)
				INVX.busy = false
				if not okP then warn("[AutoDelete] inventory delete pass failed: " .. tostring(a)) return nil, tostring(a) end
				return a, b, c
			end

			-- Delete Pets: one pass right now, from "Pet Rarity From" up to "Pet Rarity To" (variants ticked above; locked / equipped pets are kept)
			local function invDeleteNow(why)
				setDesc(invDelete, "Deleting pets (" .. tostring(why or "button") .. ")...")
				local n, msg, failed = invPass(nil, true)
				if n then
					setDesc(invDelete, string.format("Last run (%s): %d pet(s) deleted%s | %s up to %s", tostring(why or "button"), n,
						(failed and failed > 0) and (", " .. failed .. " refused") or "", invFromSel, invToSel))
					print(string.format("[AutoDelete] Delete Pets (%s): %d deleted", tostring(why or "button"), n))
					return true
				end
				setDesc(invDelete, "Not run: " .. tostring(msg))
				return false, msg
			end
			invDelete.run = function()
				task.spawn(invDeleteNow, "button")
				return true
			end
			-- after Farming Auto Delete refreshed the egg data: wait until its lists have been sent, then run Delete Pets
			INVX.afterRefresh = function(why, noWait)
				if not noWait then
					local t0 = os.clock()
					while alive and applyActive > 0 and os.clock() - t0 < 90 do task.wait(0.25) end
				end
				if not alive then return end
				pcall(invDeleteNow, why)
			end

			invFrom.callback = function(option) if invRank[option] then invFromSel = option end end
			invTo.callback = function(option) if invRank[option] then invToSel = option end end
			-- KAITUN: while Kaitun Hatch runs, Auto Delete Inventory (Pets) is on too, set to Common..Legendary with every variant (the same as the Farming
			-- Auto Delete). It deletes whatever is in the list, so new pets the Farming lists miss (new updates) cannot stay. Your own settings (range, variants,
			-- toggle) are put back when Kaitun goes off. If this toggle had to delete pets while Kaitun runs, Refresh Egg Data runs once (at most every 60 s),
			-- because pets getting past the Farming lists means its egg data is out of date.
			local INV_KAITUN_REFRESH_GAP = 60
			local invKS = { saved = nil, wasOn = false, lastRefresh = -1e9 }
			-- Updates the rarity dropdowns of Delete Pets.
			local function invShowSettings()
				if invFrom._refresh then invFrom._refresh(invFromSel) end
				if invTo._refresh then invTo._refresh(invToSel) end
				if invVariants._refreshMulti then invVariants._refreshMulti() end
			end
			INVX.kaitun = function(on)
				if on then
					if not INVX.kaitunOn then   -- first call of this Kaitun run: remember what you had (later calls only re-apply)
						INVX.kaitunOn = true
						invKS.wasOn = invOn
						invKS.saved = { from = invFromSel, to = invToSel, vars = {} }
						for k, v in pairs(invVariants.picked) do invKS.saved.vars[k] = v end
					end
					invFromSel, invToSel = "Common", "Legendary"
					for _, v in ipairs({ "Normal", "Golden", "Diamond", "Rainbow" }) do invVariants.picked[v] = true end
					invShowSettings()
					if not invOn then
						if invAuto._setUI then invAuto._setUI(true) else invAuto.callback(true) end
					end
					if invAuto._id then Config.override[invAuto._id] = invKS.wasOn end   -- what is SAVED for the toggle stays what you had
				else
					if not INVX.kaitunOn then return end
					INVX.kaitunOn = false
					if invOn and not invKS.wasOn then
						if invAuto._setUI then invAuto._setUI(false) else invAuto.callback(false) end
					end
					local sv = invKS.saved
					invKS.saved = nil
					if sv then
						invFromSel, invToSel = sv.from, sv.to
						for k in pairs(invVariants.picked) do invVariants.picked[k] = nil end
						for k, v in pairs(sv.vars) do invVariants.picked[k] = v end
						invShowSettings()
					end
					if invAuto._id then Config.override[invAuto._id] = nil end
				end
			end

			invAuto.callback = function(on)
				invOn = on == true
				invRun = invRun + 1
				if not invOn then invStatus("Off") return end
				local my, total = invRun, 0
				task.spawn(function()
					while alive and invOn and invRun == my do
						invStatus("Checking your pets...")
						local n, msg, failed = invPass(my)
						if not (alive and invOn and invRun == my) then break end
						if n then
							total = total + n
							if n > 0 and INVX.kaitunOn and os.clock() - invKS.lastRefresh >= INV_KAITUN_REFRESH_GAP then
								invKS.lastRefresh = os.clock()
								print("[AutoDelete] Kaitun: Auto Delete (Pets) had to delete " .. n .. " pet(s) - running Refresh Egg Data once")
								task.spawn(function() pcall(refreshEntry.run) end)
							end
							invStatus(string.format("On | last pass: %d deleted%s | total deleted: %d", n,
								(failed and failed > 0) and (", " .. failed .. " refused") or "", total))
						else
							invStatus("On | " .. tostring(msg))
						end
						local t0 = os.clock()
						while alive and invOn and invRun == my and os.clock() - t0 < INV_EVERY do task.wait(0.5) end
					end
				end)
			end
			table.insert(cleanupHooks, function() invOn = false invRun = invRun + 1 end)

			-- Kaitun watcher (Pets tab > Auto Delete is NOT touched by Kaitun any more).
			-- While Kaitun Hatch runs the Farming Auto Delete, your pets are looked at every KW_EVERY seconds. A pet you gained after Kaitun
			-- started, that is lower than Mythical (Common..Legendary) and is still in your inventory on two looks in a row (= the game's
			-- Auto Delete did not remove it), makes the script switch the Farming Auto Delete OFF, wait until its lists are cleared, read the
			-- egg data again and switch it ON again. Hatching is held while that happens. Locked / equipped pets are ignored.
			local KW_EVERY         = 4      -- seconds between two looks at your pets
			local KW_COOLDOWN      = 45     -- at least this many seconds between two resets
			local KW_COUNT_UNKNOWN = false  -- true = pets whose rarity the script can't read also count as "not Mythical"
			local KW_MYTHICAL      = invRankLower["mythical"]
			-- FIRST MINUTE: once the Farming Auto Delete lists are set, your inventory is checked every KW_FIRST_EVERY seconds for KW_FIRST_WINDOW seconds.
			-- If even ONE unlocked / unequipped pet lower than Mythical is found: Refresh Egg Data, then Auto Delete off -> on, then nothing happens
			-- for KW_FIRST_COOLDOWN seconds (the game needs time to delete everything) before it may do the same again. After the minute the normal watcher below takes over.
			local KW_FIRST_WINDOW   = 60
			local KW_FIRST_EVERY    = 10
			local KW_FIRST_COOLDOWN = 20
			local kwOn, kwRun = false, 0

			-- id -> true for every owned pet (not locked / equipped) that is lower than Mythical; nil + reason when the pets can't be read
			local function kwLowPets()
				if not next(petRarity) then pcall(discover) end
				local groups, why = scanFromData()
				if not groups then return nil, why end
				local set = {}
				for _, g in pairs(groups) do
					local r = petRarity[g.name]
					local idx = r and invRarityIdx(r) or nil
					local low
					if idx then low = idx < KW_MYTHICAL else low = KW_COUNT_UNKNOWN end
					if low then
						for _, x in ipairs(g.ids) do set[x.id] = true end
					end
				end
				return set
			end

			-- Kaitun: resets the delete lists and holds hatching until they are set again.
			local function kwReset(my)
				HG.kwHold = true   -- nothing is hatched while the lists are empty (own flag: Kaitun's start-up hold is released separately)
				pcall(HG.sync)
				print("[AutoDelete] Kaitun: pets below Mythical were gained and not deleted - Auto Delete (Farming) off, then on again")
				pcall(function()
					local okR = pcall(discover)   -- same as pressing "Refresh Egg Data" (without re-applying: the toggle below does that)
					if okR then
						fillRarities()
						pcall(function() setDesc(refreshEntry, summaryText()) end)
					end
					if autoEntry._setUI then autoEntry._setUI(false) else autoEntry.callback(false) end
					local t0 = os.clock()   -- wait until every list has been cleared
					while alive and kwOn and kwRun == my and next(applied) and os.clock() - t0 < 30 do task.wait(0.25) end
					if alive and kwOn and kwRun == my then
						task.wait(0.5)
						if autoEntry._setUI then autoEntry._setUI(true) else autoEntry.callback(true) end
						task.wait(0.5)
						local t1 = os.clock()   -- wait until every list has been sent again
						while alive and kwOn and kwRun == my and applyActive > 0 and os.clock() - t1 < 90 do task.wait(0.25) end
						task.wait(1.5)
						if INVX.afterRefresh then INVX.afterRefresh("Kaitun reset", true) end   -- hatching is still held: delete what got through first
					end
				end)
				HG.kwHold = false
				pcall(HG.sync)
			end

			-- AUTO DELETE WATCHER (the Auto Delete toggle itself): while it is ON, your pets are looked at every AW_EVERY seconds.
			-- A pet gained after the toggle was switched on that is INSIDE the chosen rarity range + variants + eggs (= the game's Auto Delete
			-- should have removed it) and is still in your inventory on two looks in a row, makes it press "Refresh Egg Data" (which also
			-- sends the lists again). The toggle is NOT switched off and on. Locked / equipped pets are ignored. While Kaitun Hatch runs,
			-- the Kaitun watcher below does this job.
			local AW_EVERY, AW_COOLDOWN = 5, 20
			-- Returns the pets that match the chosen delete range.
			local function awMatching()   -- id -> pet name for every owned pet inside the chosen range / variants / eggs; nil + reason when pets can't be read
				if not next(petRarity) then pcall(discover) end
				local lo, hi = rarityIndex[selFrom], rarityIndex[selTo]
				if not lo or not hi then return nil, "rarity range not set" end
				if lo > hi then lo, hi = hi, lo end
				local inEgg = {}
				for _, egg in ipairs(selectedEggs()) do
					for pet in pairs(eggPets[egg] or {}) do inEgg[pet] = true end
				end
				local groups, why = scanFromData()
				if not groups then return nil, why end
				local set = {}
				for _, g in pairs(groups) do
					local ri = rarityIndex[petRarity[g.name]]
					if ri and ri >= lo and ri <= hi and inEgg[g.name] and varPick.picked[g.tier] then
						for _, x in ipairs(g.ids) do set[x.id] = g.name end
					end
				end
				return set
			end
			AW.start = function()
				AW.run = AW.run + 1
				local my = AW.run
				task.spawn(function()
					local baseline, handled, seenOnce, lastRefresh = nil, {}, {}, -1e9
					AW.rebase = false
					while alive and running and AW.run == my do
						if AW.rebase then baseline, handled, seenOnce, AW.rebase = nil, {}, {}, false end
						if not kwOn and not env.TSR_TRADE_BUSY and applyActive == 0 then   -- not while the lists are being sent / a trade is running / Kaitun's own watcher works
							local okK, set = pcall(awMatching)
							if okK and set then
								if not baseline then
									baseline = set   -- what you already own is never counted (the game's Auto Delete only removes new hatches)
								else
									local stuck, nowSeen, names = 0, {}, {}
									for id, name in pairs(set) do
										if not baseline[id] and not handled[id] then
											nowSeen[id] = true
											if seenOnce[id] then stuck = stuck + 1 names[name] = true end
										end
									end
									seenOnce = nowSeen
									if stuck > 0 and os.clock() - lastRefresh >= AW_COOLDOWN then
										local list = {}
										for n in pairs(names) do list[#list + 1] = n end
										table.sort(list)
										print("[AutoDelete] pets inside the chosen range were gained and not deleted (" .. table.concat(list, ", ") .. ") - refreshing the egg data")
										pcall(refreshEntry.run)   -- same as pressing \"Refresh Egg Data\"; the lists are sent again by it
										lastRefresh = os.clock()
										for id in pairs(set) do handled[id] = true end   -- pets that survived the refresh do not trigger it again
										seenOnce = {}
									end
								end
							end
						end
						local t0 = os.clock()
						while alive and running and AW.run == my and os.clock() - t0 < AW_EVERY do task.wait(0.5) end
					end
				end)
			end
			table.insert(cleanupHooks, function() AW.run = AW.run + 1 end)

			kaitunWatch = function(on)
				if not on then kwOn = false kwRun = kwRun + 1 return end
				if kwOn then return end   -- already watching (the Kaitun start may call this more than once)
				kwOn = true
				kwRun = kwRun + 1
				local my = kwRun
				task.spawn(function()
					local baseline, handled, seenOnce, lastReset = nil, {}, {}, -1e9
					local winStart   -- set when the Farming Auto Delete is on and every list has been sent
					while alive and kwOn and kwRun == my do
						local nextIn = KW_EVERY
						if running and not env.TSR_TRADE_BUSY then   -- only while the Farming Auto Delete is on (it is never switched on by the watcher on its own)
							if not winStart and applyActive == 0 then winStart = os.clock() end
							if winStart and os.clock() - winStart < KW_FIRST_WINDOW then
								-- first minute: every 10 s, ANY pet below Mythical -> refresh + off/on, then 20 s of nothing
								nextIn = KW_FIRST_EVERY
								if os.clock() - lastReset >= KW_FIRST_COOLDOWN then
									local okK, set = pcall(kwLowPets)
									if okK and set and next(set) then
										kwReset(my)
										lastReset = os.clock()   -- the 20 s start AFTER the reset has finished
									end
								end
							elseif winStart then
								local okK, set = pcall(kwLowPets)
								if okK and set then
									if not baseline then
										baseline = set   -- what you had when the first minute ended is never counted
									else
										local stuck, nowSeen = 0, {}
										for id in pairs(set) do
											if not baseline[id] and not handled[id] then
												nowSeen[id] = true
												if seenOnce[id] then stuck = stuck + 1 end
											end
										end
										seenOnce = nowSeen
										if stuck > 0 and os.clock() - lastReset >= KW_COOLDOWN then
											kwReset(my)
											lastReset = os.clock()
											for id in pairs(set) do handled[id] = true end   -- pets that survived the reset do not trigger it again
											seenOnce = {}
										end
									end
								end
							end
						end
						local t0 = os.clock()
						while alive and kwOn and kwRun == my and os.clock() - t0 < nextIn do task.wait(0.5) end
					end
				end)
			end
			table.insert(cleanupHooks, function() kwOn = false kwRun = kwRun + 1 end)

			-- egg data loads by itself: retry until it is found, then refresh now and then
			task.spawn(function()
				task.wait(5)
				while alive do
					local okD = pcall(discover)
					local found = okD and #rarityList > 0 and next(eggPets) ~= nil
					if okD then
						fillRarities()
					end
					local wait = found and 120 or 15
					local t0 = os.clock()
					while alive and os.clock() - t0 < wait do task.wait(1) end
				end
			end)

			return { kaitun = kaitunApply, busy = function() return applyActive > 0 end,
				unmapped = function() local l = {} for _, n in ipairs(eggNames) do if not eggPets[n] then l[#l + 1] = n end end return l end, refresh = refreshEntry, egg = eggPick, from = fromEntry, to = toEntry, variants = varPick,
				auto = autoEntry,
				rarityOf = function(name) return petRarity[name] end,
				rarest = function()   -- the rarest pet you own: name, rarity (used by the black screen of Disable 3D Rendering / Mini Ui)
					if not next(petRarity) then pcall(discover) end
					local okG, groups = pcall(scanFromData)
					if not okG or type(groups) ~= "table" then return nil end
					local bestName, bestRar, bestIdx
					for _, g in pairs(groups) do
						local r = petRarity[g.name]
						local idx = r and rarityIndex[r]
						if idx and (not bestIdx or idx > bestIdx) then bestIdx, bestName, bestRar = idx, g.name, r end
					end
					return bestName, bestRar
				end,
				petNames = function() local t = {} for n, r in pairs(petRarity) do t[#t + 1] = { name = n, rarity = r } end return t end,
				invFrom = invFrom, invTo = invTo, invVariants = invVariants, invDelete = invDelete, invAuto = invAuto }
		end)
		if not ok then
			warn("[WORST Hub] Auto Delete failed to load: " .. tostring(result))
			return nil
		end
		return result
	end)()

	-------------------------------------------------------------------------- callbacks
	hatchEntry.callback = function(on)
		HG.want = on == true
		HG.sync()
	end

	-- picking another egg while hatching restarts the run on the new egg (travel + teleport + hatch)
	eggEntry.callback = function(opt)
		local actualName = type(opt) == "string" and opt:gsub("^%[NEW!!%]%s*", "") or opt
		local e = eggByName[actualName]
		if not e then return end
		selectedEgg = e
		if hEnabled then
			setHatchEnabled(false)
			setHatchEnabled(true)
		end
	end

	scanEntry.callback = function(on)
		if not alive then return end
		keepRun = keepRun + 1
		local my = keepRun
		if on then
			setDesc(scanEntry, "Starting...")
			task.spawn(invLoop, my)
		else
			setDesc(scanEntry, scanEntry.desc)
		end
	end

	dropEntry.limitOf = function(option)
		return dropEntry._limits and dropEntry._limits[option] or 0
	end
	dropEntry.isClearActive = function() return selAll end
	dropEntry.callback = function(option)
		if option == ALL_OPT then          -- "All pets": clears the counters
			selAll, selKey, selText = true, nil, nil
			for k in pairs(craftWant) do craftWant[k] = nil end
		elseif option == nil then          -- set from outside: rebuild the wanted crafts from the numbers
			for k in pairs(craftWant) do craftWant[k] = nil end
			for label, n in pairs(dropEntry.counts) do
				local info = optionInfo[label]
				if info and info.key and n > 0 then craftWant[info.key] = n end
			end
			selAll, selKey, selText = false, nil, nil
		else
			local info = optionInfo[option]
			if info and info.key then
				local n = dropEntry.counts[option] or 0
				craftWant[info.key] = n > 0 and n or nil
				selAll, selKey, selText = false, nil, nil
			end
		end
		dropEntry.emptyText = selAll and ALL_OPT or "Select a pet..."
		if dropEntry._refreshMulti then dropEntry._refreshMulti(true) end
	end

	local sliderToken = 0
	storageEntry.callback = function(v)
		storageMin = tonumber(v) or 0       -- the gate uses the new value immediately
		sliderToken = sliderToken + 1
		local my = sliderToken
		task.delay(0.25, function()         -- small debounce while the slider is being dragged
			if my ~= sliderToken or not alive then return end
			if os.clock() - lastScanAt > 30 then lastScanAt = -1e9 end  -- storage reading is old: take a fresh one
			wakeTick = wakeTick + 1          -- wake the craft loops so they re-check with the new percentage now
		end)
	end

	craftEntry.callback = function(on) setEnabled(on) end

	-- "Craft All" button: one request, the server decides what gets consumed and replies with MachineCraftResult
	local craftAllBusy = false
	craftAllEntry.run = function()
		if craftAllBusy then return end
		craftAllBusy = true
		local done, reply = false, nil
		local conn = resultRemote.OnClientEvent:Connect(function(d)
			if type(d) == "table" and d.Action == "CraftAll" then reply, done = d, true end
		end)
		local ok, err = pcall(function()
			requestRemote:FireServer({ Machine = "Golden", Action = "CraftAll" })
		end)
		if not ok then
			pcall(function() conn:Disconnect() end)
			craftAllBusy = false
			setDesc(craftAllEntry, "Craft All failed: " .. tostring(err))
			error("[Craft All] fire failed: " .. tostring(err))
		end
		local t0 = os.clock()
		while alive and not done and os.clock() - t0 < 5 do task.wait(0.1) end
		pcall(function() conn:Disconnect() end)
		craftAllBusy = false
		if reply and reply.Success then
			setDesc(craftAllEntry, string.format("Last Craft All: %s crafts, %s pets used.", tostring(reply.Crafted), tostring(reply.Consumed)))
		elseif reply then
			setDesc(craftAllEntry, "Last Craft All: the server refused it (not enough pets?).")
		else
			setDesc(craftAllEntry, "Last Craft All: no reply from the server.")
		end
	end

	-------------------------------------------------------------------------- Events > General: Auto Claim Lucky Ducky
	-- Confirmed capture: RE.Spawn({Id = UUID, Lifetime = 10}). The duck is now pressed in the world instead of calling RF.Claim.
	HG.duck = (function()
		local entry = {
			-- TOGGLE "Auto Claim Lucky Ducky": When a Lucky Ducky spawns, finds the duck in the world and presses it (click on the duck).
			type = "toggle", name = "Auto Claim Lucky Ducky", icon = "🦆", default = false,
			desc = "When a Lucky Ducky spawns, finds the duck in the world and presses it (click on the duck). It keeps re-aiming at the duck while it moves, for the duck's whole lifetime.",
		}
		local on, hooked, count = false, false, 0
		local seen, busy = {}, {}
		-- Sets the status text of Auto Claim Lucky Ducky.
		local function status(t) setDesc(entry, t) end
		-- Finds the spawned duck in the world: first by its Id (many games name the model after it), then any Model / part
		-- with "duck" in its name that is not one we already pressed.
		local pressed = {}   -- instances already pressed (so one duck is never pressed twice)
		-- Returns the part of the duck object.
		local function duckPart(inst)
			if inst:IsA("BasePart") then return inst end
			if inst:IsA("Model") then return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true) end
			return nil
		end
		-- Finds the spawned duck in the world (by its Id, then by name).
		local function findDuck(id)
			local byName
			for _, d in ipairs(workspace:GetDescendants()) do
				if (d:IsA("Model") or d:IsA("BasePart")) and not pressed[d] then
					if d.Name == id then return d end
					if not byName and d.Name:lower():find("duck", 1, true) and duckPart(d) then byName = d end
				end
			end
			return byName
		end
		-- The duck can also be a 2D picture on the screen (a GUI button / image named "duck"): find it and click its middle.
		local function findGuiDuck()
			local root = lp:FindFirstChildOfClass("PlayerGui")
			if not root then return nil end
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("GuiObject") and d.Visible and d.Name:lower():find("duck", 1, true)
					and (d:IsA("ImageButton") or d:IsA("ImageLabel") or d:IsA("TextButton") or d:IsA("ViewportFrame"))
					and d.AbsoluteSize.X > 4 and d.AbsoluteSize.Y > 4 then
					local sg = d
					while sg and not sg:IsA("ScreenGui") do sg = sg.Parent end
					if sg and sg.Enabled and sg ~= gui then return d, sg end
				end
			end
			return nil
		end
		-- Sends a mouse click at screen position x,y.
		local function clickXY(x, y)
			pcall(function()
				VIM:SendMouseMoveEvent(x, y, game)
				VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
				task.wait(0.03)
				VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
			end)
		end
		-- One press, aimed at where the duck is RIGHT NOW (called again and again while the duck moves).
		local function pressDuck(duck)
			local part = duckPart(duck)
			if not part then return false end
			local did = false
			for _, d in ipairs(duck:GetDescendants()) do
				if d:IsA("ClickDetector") and type(fireclickdetector) == "function" then
					pcall(fireclickdetector, d) did = true   -- works wherever the duck is, on screen or not
				elseif d:IsA("ProximityPrompt") and type(fireproximityprompt) == "function" then
					pcall(fireproximityprompt, d) did = true
				end
			end
			local cam = workspace.CurrentCamera
			if cam then
				-- aim a little ahead of the duck so a click sent while it moves still hits it
				local pos = (duck:IsA("Model") and duck:GetPivot().Position) or part.Position
				local vel = Vector3.zero
				pcall(function() vel = part.AssemblyLinearVelocity end)
				local v, onScreen = cam:WorldToViewportPoint(pos + vel * 0.08)
				if onScreen and v.Z > 0 then
					local off = GuiService:GetGuiInset()
					clickXY(v.X + off.X, v.Y + off.Y)
					did = true
				end
			end
			return did
		end
		-- Presses the duck's button on screen.
		local function pressGuiDuck(d, sg)
			local off = sg.IgnoreGuiInset and Vector2.new(0, 0) or GuiService:GetGuiInset()
			local pos = d.AbsolutePosition + d.AbsoluteSize / 2
			clickXY(pos.X + off.X, pos.Y + off.Y)
			return true
		end
		-- Claims one duck (teleports / clicks) if it was not claimed yet.
		local function claim(id, lifetime)
			if not on or seen[id] or busy[id] then return end
			busy[id] = true
			-- Keep looking and pressing for the duck's whole lifetime (10 s): every 0.1 s the duck is found again and the click is
			-- re-aimed at its current position. It counts as caught when the duck disappears after being pressed.
			local t0, life = os.clock(), tonumber(lifetime) or 10
			local target, presses = nil, 0
			while alive and on and os.clock() - t0 < life + 1 do
				if target and not target.Parent then break end        -- it vanished after a press: caught
				target = target and target.Parent and target or findDuck(id)
				if target then
					if pressDuck(target) then presses = presses + 1 end
				else
					local gd, sg = findGuiDuck()
					if gd then
						pressGuiDuck(gd, sg)
						presses = presses + 1
						target = gd
					end
				end
				task.wait(0.1)
			end
			if target and not target.Parent and presses > 0 then
				pressed[target] = true
				seen[id] = true
				count = count + 1
				print("[Ducky] caught after " .. presses .. " press(es)")
				status("On | ducks pressed: " .. count .. " | last: " .. os.date("%H:%M:%S"))
			else
				print("[Ducky] not caught: target=" .. tostring(target and target:GetFullName()) .. " presses=" .. presses)
				status("On | missed the last duck (see console) | ducks pressed: " .. count)
			end
			busy[id] = nil
		end
		-- Connects the listener that tells when a duck spawns.
		local function hook()
			if hooked then return end
			local spawn = find(RS, { "RemoteServices", "LuckyDuckyService", "RE", "Spawn" })
			if not spawn or not spawn:IsA("RemoteEvent") then
				status("LuckyDuckyService.RE.Spawn not found")
				return
			end
			hooked = true
			connect(spawn.OnClientEvent, function(data)
				if not on or type(data) ~= "table" then return end
				local id = data.Id
				if type(id) ~= "string" or id == "" then return end
				task.spawn(claim, id, data.Lifetime)
			end)
		end
		entry.callback = function(v)
			on = v == true
			if on then
				hook()
				if hooked then status("On | waiting for Spawn | claims sent: " .. count) end
			else
				status("Off | claims sent: " .. count)
			end
		end
		return entry
	end)()

	local pet = buildPetJobs()

	-------------------------------------------------------------------------- KAITUN
	HG.kaitun = (function()
		local mainEntry = {
			-- TOGGLE "Kaitun Hatch": MASTER toggle: switches every other feature off and runs your setup (Priority tab order) - auto delete, hatch the latest detected egg, craft + coll...
			type = "toggle", name = "Kaitun Hatch", icon = "⚡", default = false,   -- saved: with Auto Save on, loading the config switches Kaitun back on (and ONLY Kaitun: every other toggle stays off)
			desc = "MASTER toggle: switches every other feature off and runs your setup (Priority tab order) - auto delete, hatch the latest detected egg, craft + collect, Anti AFK, Auto Rejoin, Show Status. (Pets, Auto Equip and Auto Rebirth are handled by Kaitun Stats.)",
		}
		local secondEntry = {
			-- TOGGLE "Kaitun Events": Starts Auto Chest Coins, Auto Trick or Treat, Auto Kill Hallow Boss and Auto Purchase Items by itself and shows live numbers here (works with Kaitu...
			type = "toggle", name = "Kaitun Events", icon = "📊", default = false,
			desc = "Starts Auto Chest Coins, Auto Trick or Treat, Auto Kill Hallow Boss and Auto Purchase Items by itself and shows live numbers here (works with Kaitun Hatch on or off).",
		}
		local enchantEntry = {
			-- TOGGLE "Kaitun Stats": needs Kaitun Hatch; runs Auto Equip + Auto Rebirth and, while hatching, enchants your equipped pets with the wanted enchants (Secret Hunter, Four Leaf, Lucky 3).
			type = "toggle", name = "Kaitun Stats", icon = "🔮", default = false,
			desc = "Needs Kaitun Hatch. Runs Auto Equip (Luckiest while hatching, Richest right before each rebirth) and Auto Rebirth (Best). Enchants Luck-affinity Legendary+ equipped pets: two Four-Leaf, two Secret Hunter, and Lucky III on extras (one matching slot per pet). Rebirth pets prioritize Gems affinity and Renewal III.",
		}
		local turnedOn = {}   -- entries Kaitun switched on (only those are switched off again)
		local kaitunOn = false
		-- Sets the status text of Kaitun.
		local function say(text) setDesc(mainEntry, text) end
		-- Switches a feature toggle on or off from Kaitun (also updates the UI).
		local function flip(entry, on)
			if not entry._setUI then return end
			local was = entry._get and entry._get() or false
			if on then
				if not was then entry._setUI(true) turnedOn[entry] = true end
			else
				if turnedOn[entry] then entry._setUI(false) turnedOn[entry] = nil end
			end
		end
		-- Kaitun tab: clicking a green check switches that part of Kaitun off (and on again). Remembered in WORST/kaitunskip.txt.
		-- skip[key] = true -> Kaitun leaves that part alone. While its master toggle is running the change is applied at once (hooks).
		-- keys: delete, hatch, afk, rebirth (Kaitun Hatch) / chest, treat, boss, shop (Kaitun Events)
		local skip, hooks = {}, {}
		local SKIP_KEYS = { "delete", "hatch", "afk", "rebirth", "chest", "treat", "boss", "shop" }
		do
			local okR, raw = pcall(function() return hasFiles and Store.read("kaitunskip.txt") or nil end)
			if okR and type(raw) == "string" then
				for k in raw:gmatch("[^,%s]+") do skip[k] = true end
			end
		end
		-- Marks a feature as skipped (or not skipped) in Kaitun's checklist.
		local function setSkip(key, v)
			v = v == true
			if (skip[key] == true) == v then return end
			skip[key] = v or nil
			if hasFiles then
				local l = {}
				for _, k in ipairs(SKIP_KEYS) do if skip[k] then l[#l + 1] = k end end
				pcall(function() Store.write("kaitunskip.txt", table.concat(l, ",")) end)
			end
			local h = hooks[key]
			if not (h and alive and h.active()) then return end
			task.spawn(function() pcall(v and h.off or h.on) end)
		end

		-- the four parts of Kaitun Hatch that live in this file (Auto Rebirth + Auto Equip is registered by the code further down)
		local function deleteOn()
			if not (autodel and autodel.kaitun) then return false, "delete unavailable" end
			local okD, why
			for _ = 1, 8 do
				okD, why = autodel.kaitun(true)
				if okD or not (alive and kaitunOn) then break end
				task.wait(2)
			end
			return okD, why
		end
		-- Kaitun: turns the delete feature off.
		local function deleteOff()
			if autodel and autodel.kaitun then autodel.kaitun(false) end
		end
		-- Kaitun: turns on hatching of the latest detected egg.
		local function hatchOn(notes)
			-- 2) Hatch the latest egg according to the game's ordered egg catalog.
			-- We use ipairs (not pairs): the last catalog entry is treated as newest.
			-- Only eggs with a known hatch location are eligible.
			local latestName
			local okLatest, latestErr = pcall(function()
				local catalog = require(RS.Shared.Pets.PetIndexCatalog)
				for _, name in ipairs(catalog.Eggs or {}) do
					if type(name) == "string" and eggByName[name] then
						latestName = name
					end
				end
			end)
			if not okLatest then warn("[WORST Hub] latest egg lookup failed: " .. tostring(latestErr)) end
			-- If the catalog is unavailable, use the last discovered/configured egg.
			if not latestName then latestName = EGGS[#EGGS] and EGGS[#EGGS].name end
			if latestName and eggByName[latestName] then
				local latestLabel = eggByName[latestName].auto and ("[NEW!!] " .. latestName) or latestName
				if eggEntry._refresh then eggEntry._refresh(latestLabel) end
				eggEntry.callback(latestLabel)
				if hatchEntry._setUI and not (hatchEntry._get and hatchEntry._get()) then hatchEntry._setUI(true) end
				turnedOn[hatchEntry] = true
				print("[WORST Hub] Kaitun Hatch selected latest egg: " .. latestName)
			else
				notes[#notes + 1] = "No hatchable egg found"
			end
			-- 3) Golden crafts at 50% storage; Diamond / Rainbow craft regardless of storage; collect
			-- "Craft When Storage Is" is yours to set (it shows in the Kaitun tab while Kaitun Hatch is on): only an untouched 0% becomes 50%
			if storageMin == 0 then
				storageMin = 50
				wakeTick = wakeTick + 1
				if storageEntry._setUI then storageEntry._setUI(50) end
			else
				wakeTick = wakeTick + 1
			end
			selAll, selKey, selText = true, nil, nil
			for k in pairs(craftWant) do craftWant[k] = nil end
			for k in pairs(dropEntry.counts) do dropEntry.counts[k] = nil end
			dropEntry.emptyText = ALL_OPT
			if dropEntry._refreshMulti then dropEntry._refreshMulti(true) end
			for _, j in ipairs({ pet.dJob, pet.rJob }) do
				if j then
					j.selKey, j.selText = nil, nil
					for k in pairs(j.want) do j.want[k] = nil end
					j.finished = false
					if j.drop and j.drop.counts then for k in pairs(j.drop.counts) do j.drop.counts[k] = nil end end
					if j.drop and j.drop._refreshMulti then j.drop._refreshMulti(true) end
					if j == pet.rJob and j.amountEntry then   -- Rainbow Amount: Kaitun always uses 2 pets
						if not j.needBefore then j.needBefore = j.need end
						j.need = 2
						if j.amountEntry._refresh then j.amountEntry._refresh(j.amountOptions[1]) end
					end
				end
			end
			flip(craftEntry, true)
			flip(pet.dCraft, true)
			flip(pet.rCraft, true)
			flip(pet.collect, true)
		end
		-- Kaitun: turns hatching off.
		local function hatchOff()
			flip(hatchEntry, false)
			flip(craftEntry, false)
			flip(pet.dCraft, false)
			flip(pet.rCraft, false)
			flip(pet.collect, false)
			local rj = pet.rJob   -- give the player's own Rainbow Amount back
			if rj and rj.needBefore then
				rj.need, rj.needBefore = rj.needBefore, nil
				if rj.amountEntry and rj.amountEntry._refresh then
					for _, a in ipairs(rj.cfg.amounts or {}) do
						if a.pets == rj.need then rj.amountEntry._refresh(a.label) end
					end
				end
			end
		end
		-- Kaitun: turns on Anti AFK, Auto Rejoin and Show Status.
		local function afkOn(notes)
			-- 4) Anti AFK + Auto Rejoin (Settings tab toggles; found by name once that tab is built)
			for _, nm in ipairs({ "Anti AFK", "Auto Rejoin", "Show Status" }) do
				local e
				for _ = 1, 30 do
					e = HG.findSetting and HG.findSetting(nm)
					if (e and e._setUI) or not (alive and kaitunOn) then break end
					task.wait(0.5)
				end
				if not (alive and kaitunOn) then return end
				if e and e._setUI then flip(e, true) else notes[#notes + 1] = nm .. " not found" end
			end
		end
		-- Kaitun: turns those three off again.
		local function afkOff()
			for _, nm in ipairs({ "Anti AFK", "Auto Rejoin", "Show Status" }) do
				local e = HG.findSetting and HG.findSetting(nm)
				if e then flip(e, false) end
			end
		end
		hooks.delete = { active = function() return kaitunOn end, on = function() deleteOn() end, off = deleteOff }
		hooks.hatch  = { active = function() return kaitunOn end, on = function() hatchOn({}) end, off = hatchOff }
		hooks.afk    = { active = function() return kaitunOn end, on = function() afkOn({}) end, off = afkOff }

		-- Kaitun: starts every part of the setup in order.
		local function startAll()
			local notes = {}
			-- right after the hub loads (saved configuration) the egg / rarity data may not be ready yet: wait for it
			for _ = 1, 15 do
				if next(eggByName) or not (alive and kaitunOn) then break end
				task.wait(1)
			end
			if not (alive and kaitunOn) then return end
			-- 1) auto delete
			if not skip.delete then
				if autodel and autodel.kaitun then
					local okD, why = deleteOn()
					if not (alive and kaitunOn) then return end
					if not okD then notes[#notes + 1] = "delete: " .. tostring(why) end
				if okD and autodel.unmapped then   -- eggs the game has but Auto Delete found no pets for: say so instead of silently skipping them
					local um = autodel.unmapped()
					if #um > 0 then notes[#notes + 1] = "delete: no pet data for " .. table.concat(um, ", ") end
				end
				else
					notes[#notes + 1] = "delete unavailable"
				end
			-- 1b) wait until Auto Delete has finished setting every list: hatching only starts after that,
			-- so nothing that should be deleted can reach the inventory first
			if autodel and autodel.busy then
				say("Setting up Auto Delete before hatching...")
				task.wait(0.3)
				local t0 = os.clock()
				while alive and kaitunOn and autodel.busy() and os.clock() - t0 < 90 do task.wait(0.25) end
				if not (alive and kaitunOn) then return end
				task.wait(1.5)   -- let the server register the last list
				if not (alive and kaitunOn) then return end
			end
			end
			HG.hold = false
			HG.sync()
			-- 2) + 3) hatch the latest egg, craft + collect
			if not skip.hatch then hatchOn(notes) end
			-- 4) Anti AFK + Auto Rejoin + Show Status
			if not skip.afk then afkOn(notes) end
			local parts = {}
			if not skip.delete then parts[#parts + 1] = "deleting Common-Legendary (Farming + Pets)" end
			if not skip.hatch then parts[#parts + 1] = "hatching latest egg" parts[#parts + 1] = "crafting at 50% storage" end
			if not skip.afk then parts[#parts + 1] = "Anti AFK + Auto Rejoin + Status" end
			say(#notes == 0 and ("On | " .. (#parts > 0 and table.concat(parts, " | ") or "everything skipped"))
				or ("On, but: " .. table.concat(notes, "; ")))
		end
		-- Kaitun: stops everything it started.
		local function stopAll()
			deleteOff()
			hatchOff()
			afkOff()
			say(mainEntry.desc)
		end
		mainEntry.callback = function(on)
			if not alive then return end
			kaitunOn = on == true
			Config.statusHideUntil = on and (os.clock() + 300) or nil   -- Show Status stays hidden until the 5th minute of Kaitun
			if on then
				say("Starting...")
				HG.hold = true   -- no hatching until Auto Delete is fully set up
				HG.sync()
				task.spawn(function()
					task.wait(0.2)
					if alive and kaitunOn then
						local okS, errS = pcall(startAll)
						if not okS then warn("[WORST Hub] Kaitun start failed: " .. tostring(errS)) end
					end
					HG.hold = false   -- safety: never leave hatching held
					HG.sync()
				end)
			else
				HG.hold, HG.kwHold = false, false
				stopAll()
			end
		end
		return {
			main = mainEntry, second = secondEntry, enchant = enchantEntry,
			skip = skip, hooks = hooks, setSkip = setSkip,
			counts = function()   -- live numbers for Kaitun Events
				return {
					hatched = hatched, golden = crafts,
					diamond = pet.dJob and pet.dJob.crafts or 0, rainbow = pet.rJob and pet.rJob.crafts or 0,
				}
			end,
		}
	end)()


	-------------------------------------------------------------------------- islands: auto unlock + teleport
	local islandTools = (function()
		local TWEEN_SPEED = 300   -- studs per second while tweening to a portal
		local RETRY_WAIT  = 10    -- seconds between purchase attempts (not enough coins etc.)
		local ISLAND_DELAY = 10   -- seconds to wait after each island is bought + traveled to, before starting on the next one (keep at 10 or more)
		local BUY_WAIT    = 3     -- seconds to wait for the server's answer to one purchase request
		local POPUP_BUY_WAIT = 7  -- seconds to give the portal's purchase popup (green price button) to unlock the island before asking the server directly
		local SETTLE      = 1.5   -- seconds to wait after Travel (lets the island load)
		local TRAVEL_TRIES = 3    -- how many times to retry a Travel that did not report success
		local TRAVEL_GAP   = 6    -- minimum seconds between any two Travel requests (the server has a "Portal request is on cooldown" limit)
		local TRAVEL_RETRY_WAIT = 8     -- seconds to wait before retrying a failed Travel
		local TRAVEL_COOLDOWN_WAIT = 12 -- seconds to wait when the server answered with a cooldown message
		local AFTER_BUY_WAIT = 3  -- seconds to wait after a purchase before the first Travel
		local RECHECK_EVERY = 300 -- seconds to idle once everything is unlocked, then re-check for new islands (stays enabled meanwhile)
		local FAR_Y       = 150   -- if you are more than this many studs above/below a portal, you are on the wrong island -> Travel to its island first
		local svc = RS.RemoteServices.IslandService.RE

		-- each step: tween to the island's portal -> buy the island -> Travel to it. Order = the order they get unlocked.
		-- name = island name used by Travel (same names as the Hatch eggs use).
		-- The portal is looked up automatically in Workspace.NextPortals (child named like the island), so no CFrames are needed.
		local STEPS = {
			{ name = "Sky Island", customPortalCF = CFrame.new(9.347307205200195, -509.73199462890625, -1645.78857421875, -0.8437058925628662, 9.022927116575374e-08, -0.5368057489395142, 5.925359403136099e-08, 1, 7.495572873494893e-08, 0.5368057489395142, 3.143291493756806e-08, -0.8437058925628662) },
			{ name = "Autumn" },
			{ name = "Mushroom" },
			{ name = "Desert" },
			{ name = "Crystal Cave" },
			{ name = "Shadow Realm" },
		}
		STEPS[#STEPS + 1] = { name = "Volcano" }   -- portal on Shadow Realm (position not yet confirmed in game)
		local TRAVEL_LIST = { "Spawn", "Sky Island", "Autumn", "Mushroom", "Desert", "Crystal Cave", "Shadow Realm", "Volcano",}

		-- islands of eggs that were auto-detected in the game and are not in the lists above: added at the end, in the game's egg order.
		-- Their portal is looked up in Workspace.NextPortals like every other island; if it is not found, the unlock skips the tween and just asks the server to buy it from the previous island.
		local AUTO_ISLANDS = {}
		local newIsland = {}   -- island name -> true for islands that are NOT hard-coded in the script (shown as "[NEW!!]" in the Teleport dropdown)
		do
			local known = {}
			for _, n in ipairs(TRAVEL_LIST) do known[n] = true end
			for _, n in ipairs({ "Spawn", SPAWN_ISLAND }) do known[n] = true end
			for _, e in ipairs(EGGS) do
				if e.auto and type(e.island) == "string" and e.island ~= "" and not known[e.island] then
					known[e.island] = true
					STEPS[#STEPS + 1] = { name = e.island, auto = true }
					TRAVEL_LIST[#TRAVEL_LIST + 1] = e.island
					AUTO_ISLANDS[#AUTO_ISLANDS + 1] = e.island
					newIsland[e.island] = true
				end
			end
			if #AUTO_ISLANDS > 0 then print("[WORST Hub] new island(s) found in the game and added: " .. table.concat(AUTO_ISLANDS, ", ")) end
		end

		-- what the server tells us (used to learn the exact purchase name and to see if a purchase worked)
		local results, portalSeen = {}, nil
		connect(svc.IslandUnlockResult.OnClientEvent, function(res)
			if type(res) == "table" and res.Island then results[res.Island] = { r = res, t = os.clock() } end
		end)
		connect(svc.IslandPortalEncountered.OnClientEvent, function(info)
			if type(info) == "table" and info.Action == "Purchase" and info.Island then
				portalSeen = { name = info.Island, price = info.Price, t = os.clock() }
			end
		end)

		local toggle = {
			-- TOGGLE "Auto Unlock Islands": Goes to each island's portal, buys it, travels there and continues to the next one.
			type = "toggle", name = "Auto Unlock Islands", icon = "🏝", default = false,
			desc = "Goes to each island's portal, buys it, travels there and continues to the next one. Keeps retrying until you can afford it. Stays on when finished and re-checks for new islands every 5 minutes.",
		}
		-- the dropdown shows "[NEW!!] <island>" for islands found in the game that are not hard-coded in the script
		local function islandLabel(n) return newIsland[n] and ("[NEW!!] " .. n) or n end
		local TRAVEL_OPTIONS = {}
		for _, n in ipairs(TRAVEL_LIST) do TRAVEL_OPTIONS[#TRAVEL_OPTIONS + 1] = islandLabel(n) end
		local pickEntry = {
			type = "dropdown", name = "Teleport to", icon = "🧭", width = 240,
			desc = "Pick the island you want to travel to. Islands marked [NEW!!] were found in the game and are not in the script's list yet.",
			options = TRAVEL_OPTIONS, default = TRAVEL_OPTIONS[1],
		}
		local goEntry = {
			type = "button", name = "Teleport to Island", icon = "🚀", noSave = true,
			desc = "Travels to the island selected above (turn Auto Hatch off first, it pulls you back to the egg).",
		}

		-- Island purchase confirmation ("Are you sure you want to unlock the "X" island?"): it opens when you touch a portal and has a
		-- green button with the price and a red "No". The green price button is pressed (that is the unlock). If the popup is still
		-- open a few seconds later (e.g. not enough coins) "No" is pressed instead so it does not stay on screen, and the green
		-- button is left alone for DECLINE_PAUSE seconds.
		local PRESS_WAIT = 3         -- seconds the popup may stay open after the green button was pressed before "No" is pressed
		local DECLINE_PAUSE = 8      -- seconds after pressing "No" during which the green button is not pressed again
		local dismissUntil = 0       -- the popup is only handled while an unlock attempt is running
		local lastPress, pressedAt, declinedAt = 0, 0, 0
		-- Cleans a purchase popup text.
		local function purchaseText(t) return (tostring(t):lower():gsub("<[^>]+>", "")) end
		-- True if a text looks like a price amount.
		local function isAmount(t)
			t = purchaseText(t):gsub("^%s+", ""):gsub("%s+$", "")
			return t:find("%d") ~= nil and t:match("^[%d%.,]+%s*%a*$") ~= nil
		end
		-- True if a GUI object is really shown on screen.
		local function shownGui(obj, pgRoot)
			local n = obj
			while n and n ~= pgRoot do
				if n:IsA("GuiObject") and not n.Visible then return false end
				if n:IsA("ScreenGui") and not n.Enabled then return false end
				n = n.Parent
			end
			return true
		end
		-- the whole button that holds `label`: climb until the next step up would also contain `other` (the other button's text)
		local function buttonFrame(label, other)
			local n = label
			while n.Parent and not other:IsDescendantOf(n.Parent) do n = n.Parent end
			return n
		end
		-- Closes the "buy island" popup if it appears while travelling.
		local function dismissIslandPurchasePopup()
			if os.clock() > dismissUntil or os.clock() - lastPress < 0.7 then return end
			local pg = player:FindFirstChildOfClass("PlayerGui")
			if not pg then return end
			for _, textObj in ipairs(pg:GetDescendants()) do
				if (textObj:IsA("TextLabel") or textObj:IsA("TextButton")) and textObj ~= gui and not (gui and textObj:IsDescendantOf(gui)) then
					local msg = purchaseText(textObj.Text)
					if msg:find("unlock", 1, true) and msg:find("island", 1, true) and shownGui(textObj, pg) then
						-- the dialog = the nearest ancestor that also holds a "No" text and an amount text
						local dialog = textObj.Parent
						for _ = 1, 8 do
							if not dialog or dialog == pg then break end
							local noLabel, amountLabel
							for _, d in ipairs(dialog:GetDescendants()) do
								if (d:IsA("TextLabel") or d:IsA("TextButton")) and shownGui(d, pg) then
									local t = purchaseText(d.Text):gsub("^%s+", ""):gsub("%s+$", "")
									if t == "no" then noLabel = noLabel or d
									elseif isAmount(t) then amountLabel = amountLabel or d end
								end
							end
							if noLabel and amountLabel then
								local now = os.clock()
								local target
								if pressedAt > 0 and now - pressedAt >= PRESS_WAIT then
									target = buttonFrame(noLabel, amountLabel)   -- still open after pressing the green button: close it
									pressedAt, declinedAt = 0, now
								elseif pressedAt == 0 and now - declinedAt >= DECLINE_PAUSE then
									target = buttonFrame(amountLabel, noLabel)   -- the green price button
									pressedAt = now
								end
								if target and target.AbsoluteSize.X > 0 and target.AbsoluteSize.Y > 0 then
									lastPress = now
									pcall(clickCenterOf, target)
								end
								return
							end
							dialog = dialog.Parent
						end
					end
				end
			end
			pressedAt = 0   -- no popup on screen: ready for the next one
		end
		task.spawn(function()
			while alive do
				pcall(dismissIslandPurchasePopup)
				task.wait(0.2)
			end
		end)
		local runId, activeTween, pausedHatch = 0, nil, false
		-- True while this island-travel run is still the current one.
		local function active(id) return alive and runId == id end
		-- Waits `sec` while the run is active.
		local function sleep(id, sec)
			local t0 = os.clock()
			while active(id) and os.clock() - t0 < sec do task.wait(0.1) end
		end
		-- Sets the status text of the island travel feature.
		local function status(text) setDesc(toggle, text) end

		local lastTravelAt, lastTravelMsg = 0, ""
		-- Travels to an island (never sends two requests too close together).
		local function travelTo(name, id)
			-- never send two Travel requests closer together than TRAVEL_GAP seconds
			while alive and (id == nil or active(id)) and os.clock() - lastTravelAt < TRAVEL_GAP do task.wait(0.1) end
			if id ~= nil and not active(id) then return false end
			lastTravelAt = os.clock()
			local ok, res = pcall(function() return travelRemote:InvokeServer({ Source = "Menu", Island = name }) end)
			lastTravelAt = os.clock()
			if not (ok and type(res) == "table" and res.Success) then
				lastTravelMsg = tostring(brief(res))
				warn("[Islands] Travel did not report success: " .. lastTravelMsg)
				return false
			end
			lastTravelMsg = ""
			return true
		end

		-- Workspace.NextPortals.<island>  (e.g. NextPortals.Autumn, NextPortals.Mushroom)
		-- names are compared ignoring case / spaces / a trailing "Island", so "Sky Island" also matches "Sky", "SkyIsland", "Sky Island"...
		local PORTAL_OFFSET = Vector3.new(0, 0, 0)   -- stand this far from the portal's centre (e.g. Vector3.new(0, 3, 0) to stand slightly above it)
		-- Lowercases a name and removes symbols so names can be compared.
		local function normName(n)
			n = tostring(n):lower():gsub("[^%w]", "")
			n = n:gsub("island$", "")
			return n
		end
		local warnedPortal = {}
		-- Finds the portal of a travel step in the workspace.
		local function findPortal(step)
			local folder = workspace:FindFirstChild("NextPortals")
			if not folder then return nil end
			local direct = folder:FindFirstChild(step.name)
			if direct then return direct end
			local want = normName(step.name)
			for _, c in ipairs(folder:GetChildren()) do
				if normName(c.Name) == want then return c end
			end
			return nil
		end
		-- Returns the CFrame of a portal object.
		local function portalCFrame(inst)
			if not inst then return nil end
			local ok, cf = pcall(function()
				if inst:IsA("PVInstance") then return inst:GetPivot() end
				local part = inst:FindFirstChildWhichIsA("BasePart", true)
				return part and part.CFrame or nil
			end)
			if ok and cf then return cf + PORTAL_OFFSET end
			return nil
		end
		-- Returns the CFrame to teleport to for a travel step.
		local function getPortalCF(step)
			if step.customPortalCF then return step.customPortalCF end
			return portalCFrame(findPortal(step))
		end
		-- waits a few seconds for the portal to exist (it may still be streaming in right after a Travel)
		local function waitPortalCF(step, id, sec)
			local t0 = os.clock()
			local cf = getPortalCF(step)
			while not cf and active(id) and os.clock() - t0 < sec do
				task.wait(0.25)
				cf = getPortalCF(step)
			end
			if not cf and not warnedPortal[step.name] then
				warnedPortal[step.name] = true
				local names = {}
				local folder = workspace:FindFirstChild("NextPortals")
				if folder then for _, c in ipairs(folder:GetChildren()) do names[#names + 1] = c.Name end end
				warn(string.format("[Islands] no portal found for '%s' in Workspace.NextPortals (children: %s)", step.name, #names > 0 and table.concat(names, ", ") or (folder and "none" or "NextPortals missing")))
			end
			return cf
		end

		-- Moves the character smoothly to a CFrame.
		local function tweenTo(cf, id)
			local hrp = getHRP()
			if not hrp then return false end
			if isNear(cf, 4) then return true end
			local t = math.max((hrp.Position - cf.Position).Magnitude / TWEEN_SPEED, 0.2)
			hrp.Anchored = true
			activeTween = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), { CFrame = cf })
			activeTween:Play()
			activeTween.Completed:Wait()
			activeTween = nil
			if hrp.Parent then
				hrp.Anchored = false
				pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
			end
			return active(id)
		end

		-- Travel with retries; returns true only when the server reported success
		local function travelRetry(name, id)
			for n = 1, TRAVEL_TRIES do
				if not active(id) then return false end
				status(string.format("Traveling to %s (try %d)...", name, n))
				if travelTo(name, id) then
					sleep(id, SETTLE)
					return active(id)
				end
				if lastTravelMsg:lower():find("cooldown") then
					status(string.format("Portal cooldown - waiting %ds before retrying %s...", TRAVEL_COOLDOWN_WAIT, name))
					sleep(id, TRAVEL_COOLDOWN_WAIT)
				else
					sleep(id, TRAVEL_RETRY_WAIT)
				end
			end
			status("Travel to " .. name .. " failed - check the console / island name")
			return false
		end

		-- the portal that buys step i sits on the PREVIOUS island (Spawn for the first one)
		local function hostIsland(i)
			if i <= 1 then return SPAWN_ISLAND end
			return STEPS[i - 1].name
		end

		-- reads Progression.UnlockedIslands from the game's own data
		local function owned(name)
			local ok, res = pcall(function()
				local d = require(RS.Controllers.Core.DataController):GetReplica().Data
				local u = d.Progression.UnlockedIslands
				if type(u) ~= "table" then return false end
				for _, n in ipairs({ name, name .. " Island" }) do
					if u[n] then return true end
				end
				for _, v in pairs(u) do
					if v == name or v == name .. " Island" then return true end
				end
				return false
			end)
			return ok and res == true
		end

		-- Buys the island of a step if it is not owned yet.
		local function buy(step, id)
			local names = {}
			if portalSeen and os.clock() - portalSeen.t < 6 then names[#names + 1] = portalSeen.name end
			for _, n in ipairs({ step.name .. " Island", step.name }) do
				if not n:find(" Island Island$") and not table.find(names, n) then names[#names + 1] = n end
			end
			for _, nm in ipairs(names) do
				results[nm] = nil
				pcall(function() svc.IslandUnlockRequested:FireServer({ Action = "Purchase", Island = nm }) end)
				local t0 = os.clock()
				while active(id) and not results[nm] and os.clock() - t0 < BUY_WAIT do task.wait(0.1) end
				local r = results[nm] and results[nm].r
				if r and (r.Success or r.Unlocked) then
					env.WORST_ISLAND_BUYS = (tonumber(env.WORST_ISLAND_BUYS) or 0) + 1   -- Auto Skill Points wakes up on this (new skill trees open)
					return true
				end
			end
			return false
		end

		-- Resumes Auto Hatch after the trip is finished.
		local function releaseHatch()
			if pausedHatch then
				pausedHatch = false
				if hatchEntry._setUI then hatchEntry._setUI(true) end
			end
		end

		-- Pauses Auto Hatch while the trip is running.
		local function pauseHatch()
			if not pausedHatch and hatchEntry._get and hatchEntry._get() and hatchEntry._setUI then
				pausedHatch = true
				hatchEntry._setUI(false)   -- Auto Hatch would pull you back to the egg, so it is paused meanwhile
			end
		end

		-- adds islands found in Workspace.NextPortals that are not in STEPS yet (new islands the game added), at the end of the list
		local function syncPortals()
			local folder = workspace:FindFirstChild("NextPortals")
			if not folder then return end
			local known = {}
			for _, st in ipairs(STEPS) do known[normName(st.name)] = true end
			for _, n in ipairs(TRAVEL_LIST) do known[normName(n)] = true end
			known[normName("Spawn")] = true
			if SPAWN_ISLAND then known[normName(SPAWN_ISLAND)] = true end
			for _, c in ipairs(folder:GetChildren()) do
				local key = normName(c.Name)
				if key ~= "" and not known[key] then
					known[key] = true
					STEPS[#STEPS + 1] = { name = c.Name, auto = true }
					TRAVEL_LIST[#TRAVEL_LIST + 1] = c.Name
					newIsland[c.Name] = true
					TRAVEL_OPTIONS[#TRAVEL_OPTIONS + 1] = islandLabel(c.Name)
					if pickEntry._refresh then pickEntry._refresh() end
					print("[WORST Hub] new island portal found in Workspace.NextPortals and added: " .. c.Name)
				end
			end
		end

		-- Main loop of the island travel feature.
		local function run(id)
			while active(id) do
				syncPortals()

				local start = #STEPS + 1
				for i, step in ipairs(STEPS) do
					if not owned(step.name) then start = i break end
				end

				-- only do anything when there is something left to unlock; otherwise stay idle (no travelling, no pausing Auto Hatch)
				if start <= #STEPS then
					pauseHatch()
					if start > 1 and active(id) then
						travelRetry(STEPS[start - 1].name, id)
					end

					for i = start, #STEPS do
						local step = STEPS[i]
						local tries = 0
						local hostTried = false
						while active(id) and not owned(step.name) do
							-- Sky Island override: travel to Spawn before going to its fixed purchase spot.
							-- Do this once per unlock attempt cycle, not before every failed purchase.
							if step.customPortalCF and not hostTried then
								hostTried = true
								status("Sky Island: traveling to Spawn before purchase...")
								if not travelRetry(SPAWN_ISLAND, id) then
									status("Sky Island: Spawn travel failed; retrying...")
									hostTried = false
									sleep(id, RETRY_WAIT)
									continue
								end
							end
							local hrp0 = getHRP()
							local portalCF = getPortalCF(step)
							if portalCF then
								if not step.customPortalCF and hrp0 and math.abs(hrp0.Position.Y - portalCF.Position.Y) > FAR_Y then
									-- not on the island that has this portal: Travel there first, then walk to the portal
									travelRetry(hostIsland(i), id)
									portalCF = waitPortalCF(step, id, 6) or portalCF
								end
							else
								-- portal not loaded / not found: go to the previous island (once), wait for it to show up in Workspace.NextPortals
								if not hostTried then
									hostTried = true
									travelRetry(hostIsland(i), id)
								end
								portalCF = waitPortalCF(step, id, 6)
							end
							dismissUntil = os.clock() + 20
							status(string.format("%s: moving to the portal (try %d)...", step.name, tries + 1))
							-- if the portal still cannot be found, skip the tween and just ask the server to buy it
							if (not portalCF or tweenTo(portalCF, id)) and active(id) then
								status(string.format("%s: buying (try %d)...", step.name, tries + 1))
								tries = tries + 1
								-- touching the portal opens the purchase popup: its green price button is pressed by the watcher above.
								-- give that a few seconds; only if the island is still locked ask the server directly as a fallback
								dismissUntil = os.clock() + 20
								local pw = os.clock()
								while active(id) and not owned(step.name) and os.clock() - pw < POPUP_BUY_WAIT do task.wait(0.25) end
								if owned(step.name) then break end
								if not active(id) then break end
								if buy(step, id) then break end
								status(string.format("%s: not bought yet (try %d) - retrying", step.name, tries))
								sleep(id, RETRY_WAIT)
							else
								sleep(id, 1)
							end
						end
						if not active(id) then break end
						status("Bought " .. step.name .. " - waiting before traveling there...")
						sleep(id, AFTER_BUY_WAIT)
						travelRetry(step.name, id)
						if i < #STEPS and active(id) then
							local t0 = os.clock()
							while active(id) and os.clock() - t0 < ISLAND_DELAY do
								status(string.format("%s unlocked - next island in %ds...", step.name, math.ceil(ISLAND_DELAY - (os.clock() - t0))))
								task.wait(0.25)
							end
						end
					end
				end

				releaseHatch()

				-- idle: toggle stays enabled, nothing is done until the next re-check
				local t0 = os.clock()
				while active(id) and os.clock() - t0 < RECHECK_EVERY do
					local left = math.ceil(RECHECK_EVERY - (os.clock() - t0))
					status(string.format("Idle - every known island is unlocked. Re-checking for new islands in %d:%02d...", math.floor(left / 60), left % 60))
					task.wait(1)
				end
			end
			releaseHatch()
		end

		-- background scan (independent of the toggle): lists new islands in the Teleport dropdown as [NEW!!]
		task.spawn(function()
			task.wait(3)
			while alive do
				pcall(syncPortals)
				local t0 = os.clock()
				while alive and os.clock() - t0 < RECHECK_EVERY do task.wait(1) end
			end
		end)

		toggle.callback = function(on)
			runId = runId + 1
			if activeTween then pcall(function() activeTween:Cancel() end) end
			if on then
				task.spawn(run, runId)
			else
				local hrp = getHRP()
				if hrp then hrp.Anchored = false end
				releaseHatch()
				status("Goes to each island's portal, buys it, travels there and continues to the next one. Keeps retrying until you can afford it. Stays on when finished and re-checks for new islands every 5 minutes.")
			end
		end

		local selected = TRAVEL_LIST[1]
		pickEntry.callback = function(option)
			local clean = tostring(option):gsub("^%[NEW!!%]%s*", "")
			selected = clean
		end
		goEntry.run = function()
			if not travelTo(selected) then error("Travel to " .. tostring(selected) .. " failed") end
		end

		return { toggle = toggle, pick = pickEntry, go = goEntry }
	end)()

	-------------------------------------------------------------------------- EVENTS > HALLOWEEN
	-- Auto Halloween Trick or Treat: Travel to the Halloween island, stand in the circle outside each house and JUMP (the game
	-- needs a jump before it gives the treat), wait for the treat, wait at least 3 s, next house. Houses have a cooldown (the game
	-- stores the time each house is ready again), so after a lap it sleeps until the houses refill (read from the board's "All houses refill in" timer) and goes round again.
	-- It ranks above Craft / Enchant / Hatch for the few minutes a lap takes (HG.prio) and releases the trip between laps.
	-- Auto Kill Boss and Auto Purchase Items are placeholders for now.
	do
		local okH, resH = pcall(function()
			local ISLAND           = "Halloween"   -- island name used by the Travel remote
			local AFTER_TREAT_WAIT = 3.5           -- seconds to wait after a treat before the next house (never lower than 3)
			local ENTER_WAIT       = 8             -- seconds to stand (and jump) in the circle waiting for the treat
			local REENTER_WAIT     = 5             -- after stepping out of the circle and back in
			local JUMP_DELAY       = 0.5           -- seconds after arriving before the first jump
			local JUMP_EVERY       = 1.5           -- jump again this often until the treat arrives
			local SETTLE           = 1.5           -- seconds to wait after Travel before the first teleport
			local TRAVEL_GAP       = 6             -- minimum seconds between two Travel requests (the server has a cooldown)
			local TRAVEL_TRIES     = 3
			local REFILL           = 14400         -- the houses refill together every 4 hours, on the server clock (multiples of 14400 s)
			local REFILL_PAD       = 3             -- seconds to wait after the refill moment before starting a lap
			local RETRY_WAIT       = 120           -- some houses failed: try them again after this many seconds
			local Y_OFFSET         = 0             -- the CFrames are your character's own position, so 0 (try 3 if you land inside the ground)

			-- optional: house number (position in the list below) -> the game's house id, e.g. { [1] = "House05" }.
			-- Leave empty: the ids are learned while visiting (the first lap after a restart wastes ~17 s on every house still on cooldown).
			local HOUSE_IDS = {}

			local HOUSES = {
				CFrame.new(-1825.1048583984375, -510.8475036621094, -2049.451904296875, 0.999760091304779, -1.9962897113146028e-08, 0.021902531385421753, 1.7909442817654053e-08, 1, 9.395041189463882e-08, -0.021902531385421753, -9.353561125635679e-08, 0.999760091304779),
				CFrame.new(-1810.755126953125, -511.4144287109375, -1971.3726806640625, -0.9845771789550781, 6.403169550139864e-08, 0.17495079338550568, 7.71301813529135e-08, 1, 6.807012908893739e-08, -0.17495079338550568, 8.051428324051813e-08, -0.9845771789550781),
				CFrame.new(-1747.0343017578125, -510.8515319824219, -1938.178466796875, -0.2404051125049591, -3.3427507872829665e-08, 0.9706726670265198, 1.6243889788825072e-08, 1, 3.846056984002644e-08, -0.9706726670265198, 2.501361606732644e-08, -0.2404051125049591),
				CFrame.new(-1715.6767578125, -510.9827575683594, -1867.0186767578125, -0.38709887862205505, 5.1657366384461056e-08, 0.922038197517395, 1.4631067912773688e-08, 1, -4.9882636687925697e-08, -0.922038197517395, -5.8191083063263704e-09, -0.38709887862205505),
				CFrame.new(-1717.4923095703125, -510.8573913574219, -1783.913330078125, -0.22345781326293945, 4.622394023101606e-09, 0.9747136235237122, 5.903973754328717e-09, 1, -3.3887954664635345e-09, -0.9747136235237122, 4.997430469444453e-09, -0.22345781326293945),
				CFrame.new(-1681.277587890625, -510.8206481933594, -1740.931884765625, -0.9952124953269958, 1.7900424253980418e-08, 0.09773492813110352, 1.8007865421054703e-08, 1, 2.1720354681509235e-10, -0.09773492813110352, 1.9761610126067808e-09, -0.9952124953269958),
				CFrame.new(-1646.8187255859375, -511.0694885253906, -1803.43359375, -0.17263205349445343, 2.6668875108271095e-08, -0.9849863648414612, 7.487635400593717e-08, 1, 1.3952290878194162e-08, 0.9849863648414612, -7.13435781563021e-08, -0.17263205349445343),
				CFrame.new(-1644.0382080078125, -510.8536682128906, -1882.9072265625, -0.03653490170836449, 2.1173022446419054e-08, -0.9993323683738708, -1.72972143275274e-08, 1, 2.181954172897349e-08, 0.9993323683738708, 1.808284189053211e-08, -0.03653490170836449),
				CFrame.new(-1605.8533935546875, -511.1357116699219, -1951.324951171875, -0.4142543375492096, -6.7912964141214616e-09, -0.9101611375808716, 3.9118521755199254e-08, 1, -2.526619979903444e-08, 0.9101611375808716, -4.6070791626107166e-08, -0.4142543375492096),
				CFrame.new(-1613.1864013671875, -510.8457336425781, -2094.546630859375, 0.7605129480361938, -4.3924565318320674e-08, -0.6493227481842041, 8.450388833125544e-08, 1, 3.132761605684209e-08, 0.6493227481842041, -7.869535068039113e-08, 0.7605129480361938),
				CFrame.new(-1755.7349853515625, -510.9259338378906, -2090.5, 0.6520168781280518, 5.337054687082343e-10, 0.758204460144043, -6.105450012228175e-08, 1, 5.17998230975536e-08, -0.758204460144043, -8.006615104250159e-08, 0.6520168781280518),
			}

			local treatEntry = {
				-- TOGGLE "Auto Halloween Trick or Treat": Travels to the Halloween island and jumps in the circle outside every house for a treat, then waits for the houses to refill (the game's real 4-hou...
				type = "toggle", name = "Auto Halloween Trick or Treat", icon = "🎃", default = false,
				desc = "Travels to the Halloween island and jumps in the circle outside every house for a treat, then waits for the houses to refill (the game's real 4-hour timer, countdown shown here) before the next lap. Pauses Auto Hatch / Craft / Enchant while it walks round.",
			}
			local bossEntry = {
				-- TOGGLE "Auto Kill Boss": fights the Hallow Lord, who rises every hour on the hour.
				type = "toggle", name = "Auto Kill Boss", icon = "💀", default = false,
				desc = "The Hallow Lord rises every hour, on the hour. When he is up, goes to the arena and stays until the fight is over - Auto Click (Settings) does the damage. Whether he goes before Auto Trick or Treat is set in the Priority tab.",
			}
			local shopEntry = {
				-- TOGGLE "Auto Purchase Items": Buys the items ticked below from the Halloween shop with the shop's buy remote (no need to visit the shop).
				type = "toggle", name = "Auto Purchase Items", icon = "🛒", default = false,
				desc = "Buys the items ticked below from the Halloween shop with the shop's buy remote (no need to visit the shop).",
			}
			local HWSTAT = {}   -- HWSTAT.refillAt = server time of the next refill (shown in the status line)
			-- Sets the status text of Halloween Trick or Treat.
			local function say(text)
				local r = HWSTAT.refillAt
				if r and not tostring(text):find("refill", 1, true) then
					local left = r - workspace:GetServerTimeNow()
					if left > 0 then text = tostring(text) .. " | houses refill in " .. (left >= 3600 and string.format("%dh %02dm", math.floor(left / 3600), math.floor((left % 3600) / 60)) or string.format("%dm %02ds", math.floor(left / 60), math.floor(left % 60))) end
				end
				setDesc(treatEntry, text)
			end

			local HW = { bossAlive = false, doneWin = nil, failLaps = {}, traveled = false }   -- shared with Auto Kill Boss: set while the Hallow Lord is up
			-- POPUP TAP: the popup after a Hallow Lord kill / a treat lap stays until it is pressed. POPUP_TAP_DELAY seconds after
			-- either feature finishes, one press in the middle of the screen (like a normal user tapping once).
			local POPUP_TAP_ENABLED = true
			local POPUP_TAP_DELAY   = 30     -- seconds after the feature finishes
			HW.tapRun = 0
			-- Taps the screen shortly after a popup so it closes.
			function HW.tapSoon()
				if not POPUP_TAP_ENABLED then return end
				HW.tapRun = HW.tapRun + 1   -- a newer finish replaces a tap that is still waiting
				local my = HW.tapRun
				task.delay(POPUP_TAP_DELAY, function()
					if not alive or my ~= HW.tapRun then return end
					pcall(function()
						local vim = game:GetService("VirtualInputManager")
						local cam = workspace.CurrentCamera
						local x, y = cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2
						vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
						task.wait(0.05)
						vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
						print("[Halloween] popup tap sent (" .. POPUP_TAP_DELAY .. "s after the feature finished)")
					end)
				end)
			end
			-- remembers (also across re-executes) the refill window in which the houses were already collected / are all on cooldown
			local HW_FILE = "halloween_done_" .. tostring(lp.UserId) .. ".txt"
			-- Marks a refill window as done.
			function HW.markDone(w)
				HW.doneWin = w
				pcall(Store.write, HW_FILE, tostring(w))
			end
			-- Trick or Treat only steps aside for the boss when Auto Kill Hallow Lord is ranked ABOVE it in the Priority tab
			local function yieldToBoss() return HW.bossAlive and HG.rank("HallowLord") < HG.rank("TrickOrTreat") end
			local hwOn, hwRun = false, 0
			-- True while this Trick or Treat run is still the current one.
			local function hwActive(id) return alive and hwOn and hwRun == id end
			-- Waits `seconds` while the run is active.
			local function hwSleep(id, seconds)
				local t0 = os.clock()
				while hwActive(id) and os.clock() - t0 < seconds do task.wait(0.1) end
				return hwActive(id)
			end
			-- Formats seconds as a time text.
			local function fmt(sec)
				sec = math.max(0, math.floor(sec))
				if sec >= 3600 then return string.format("%dh %02dm", math.floor(sec / 3600), math.floor((sec % 3600) / 60)) end
				if sec >= 60 then return string.format("%dm %02ds", math.floor(sec / 60), sec % 60) end
				return sec .. "s"
			end
			-- Current server time.
			local function serverNow() return workspace:GetServerTimeNow() end

			-------------------------------------------------- state
			local current, gotTreat = nil, false      -- house index we stand at / treat received there
			local houseOf, idxOf, collectedWin = {}, {}, {}  -- index -> id, id -> index, index -> refill window (floor(serverTime/REFILL)) it was collected in
			local candy = nil
			for i, hid in pairs(HOUSE_IDS) do houseOf[i] = hid idxOf[hid] = i end

			-- A treat arrives as two data writes from the server:
			--   { "TrickOrTreat", "House09" } = <time the house is ready again>    { "Currencies", "CandyCorn" } = <total>
			local function onHouse(hid, ready)
				local i = idxOf[hid]
				if not i and current then   -- first time we see this id: it belongs to the house we stand at
					i = current
					idxOf[hid], houseOf[i] = i, hid
					print(string.format("[Halloween] house #%d = %s", i, hid))
				end
				if not i then return end
				-- (the number the game writes here is NOT the refill time shown on the board, so it is ignored)
				if i == current then gotTreat = true end
			end

			local conn
			-- Connects the listener that reads house refill messages.
			local function ensureListener()
				if conn then return true end
				local ev = walk(RS, { "ReplicaRemoteEvents", "Replica_ReplicaWrite" })
				if not ev then return false end
				conn = ev.OnClientEvent:Connect(function(...)
					local writes = ({ ... })[3]
					if type(writes) ~= "table" then return end
					for _, w in ipairs(writes) do
						local path = type(w) == "table" and w[1]
						if type(path) == "table" then
							if path[1] == "TrickOrTreat" and type(path[2]) == "string" then
								onHouse(path[2], w[2])
							elseif path[1] == "Currencies" and path[2] == "CandyCorn" and type(w[2]) == "number" then
								candy = w[2]
							end
						end
					end
				end)
				return true
			end

			-- candy total from the game's data
			local function syncFromData()
				local ok, data = pcall(function() return require(RS.Controllers.Core.DataController):GetReplica().Data end)
				if not (ok and type(data) == "table") then return end
				if type(data.Currencies) == "table" and type(data.Currencies.CandyCorn) == "number" then candy = data.Currencies.CandyCorn end
			end

			-------------------------------------------------- the real cooldown
			-- The Trick or Treat board shows "All houses refill in 7:47". The houses all refill together every 4 hours on the
			-- server clock (the next multiple of 14400 s), so that is the cooldown. (The per-house numbers in Data.TrickOrTreat
			-- are ~3 h further away and are not what the game uses.)
			local function parseClock(txt)   -- "7:47" -> 467, "1:02:03" -> 3723
				if type(txt) ~= "string" then return nil end
				local a, b, c = txt:match("(%d+):(%d+):(%d+)")
				if a then return tonumber(a) * 3600 + tonumber(b) * 60 + tonumber(c) end
				a, b = txt:match("(%d+):(%d+)")
				if a then return tonumber(a) * 60 + tonumber(b) end
				return nil
			end
			-- Returns the Halloween board panel from PlayerGui.
			local function getPanel()
				local pg = lp:FindFirstChild("PlayerGui")
				local boards = pg and pg:FindFirstChild("TrickOrTreatBoards")
				local sg = boards and boards:FindFirstChild("TrickOrTreatBoard")
				return sg and sg:FindFirstChild("Panel")
			end
			-- Reads the seconds left until the houses refill.
			local function boardRefillSecs()
				local panel = getPanel()
				local lbl = panel and panel:FindFirstChild("Next")
				if lbl and lbl:IsA("TextLabel") then return parseClock(lbl.Text) end
			end
			-- returns the SERVER time of the next refill, and where it came from
			local function nextRefillAt()
				local now = serverNow()
				local grid = (math.floor(now / REFILL) + 1) * REFILL
				local secs = boardRefillSecs()
				if secs and secs > 0 then
					local at = now + secs
					if math.abs(at - grid) <= 90 then return grid, "board" end   -- board agrees with the 4 h clock: use the exact moment
					return at, "board (off the 4 h clock)"
				end
				local ok, data = pcall(function() return require(RS.Controllers.Core.DataController):GetReplica().Data end)
				local r = ok and type(data) == "table" and type(data.TrickOrTreatPotions) == "table" and data.TrickOrTreatPotions.Reset
				if type(r) == "number" and r > now and r - now <= REFILL + 60 then return r, "game data" end
				return grid, "4 h clock"
			end
			-- Counts the houses and how many show a refill timer.
			local function curWindow() return math.floor(serverNow() / REFILL) end
			-- how many board houses exist / how many show a refill countdown ("Lights out")
			local function houseBoardState()
				local panel = getPanel()
				local houses = panel and panel:FindFirstChild("Houses")
				if not houses then return nil end
				local n, cooling = 0, 0
				for _, h in ipairs(houses:GetChildren()) do
					local st = h:FindFirstChild("Status")
					if st and st:IsA("TextLabel") then
						n = n + 1
						if parseClock(st.Text) then cooling = cooling + 1 end
					end
				end
				return n, cooling
			end
			-- How many houses were already collected in refill window `win`, read from the game's own data (no board, no ids needed).
			-- Data.TrickOrTreat["HouseNN"] = <time that house is ready again> = <time it was collected> + REFILL,
			-- so it was collected in this window when (value - REFILL) is at or after the window's start.
			local function collectedFromData(win)
				local ok, data = pcall(function() return require(RS.Controllers.Core.DataController):GetReplica().Data end)
				local t = ok and type(data) == "table" and data.TrickOrTreat
				if type(t) ~= "table" then return 0 end
				local winStart, n = win * REFILL, 0
				for _, v in pairs(t) do
					if type(v) == "number" and v - REFILL >= winStart then n = n + 1 end
				end
				return n
			end
			-- True if house number i is still cooling down.
			local function houseCooling(i)   -- only when the house id is known ("House09" -> board "House9")
				local hid = houseOf[i]
				local num = hid and tonumber(hid:match("%d+"))
				local panel = getPanel()
				local houses = panel and panel:FindFirstChild("Houses")
				local h = houses and num and houses:FindFirstChild("House" .. num)
				local st = h and h:FindFirstChild("Status")
				return st ~= nil and st:IsA("TextLabel") and parseClock(st.Text) ~= nil
			end

			-------------------------------------------------- movement
			local function spot(i) return HOUSES[i] + Vector3.new(0, Y_OFFSET, 0) end
			-- Teleports to a CFrame (used for the houses).
			local function goTo(cf)
				local hrp = getHRP()
				if not hrp then return false end
				pcall(function() hrp.Anchored = false end)
				return teleportTo(cf)
			end
			-- the game needs a jump inside the circle before it hands out the treat
			local function jump()
				local c = lp.Character
				local hum = c and c:FindFirstChildOfClass("Humanoid")
				if not hum or hum.Health <= 0 then return end
				pcall(function() hum.Jump = true end)
				pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
				pcall(function()   -- a real space press too, in case the game listens to the jump key
					VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
					task.delay(0.08, function() pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end)
				end)
			end

			local lastTravelAt = -1e9
			-- Travels to the Halloween island.
			local function hwTravel(id)
				for attempt = 1, TRAVEL_TRIES do
					while hwActive(id) and os.clock() - lastTravelAt < TRAVEL_GAP do task.wait(0.1) end
					if not hwActive(id) then return false end
					lastTravelAt = os.clock()
					local ok, res = pcall(function() return travelRemote:InvokeServer({ Source = "Menu", Island = ISLAND }) end)
					lastTravelAt = os.clock()
					if ok and type(res) == "table" and res.Success then return true end
					warn(string.format("[Halloween] Travel to %s did not report success (try %d/%d): %s", ISLAND, attempt, TRAVEL_TRIES, brief(res)))
					if not hwSleep(id, 2) then return false end
				end
				return false
			end

			-------------------------------------------------- one house
			-- stands in the circle and jumps until the treat arrives (or the time is up)
			local function standAndJump(id, seconds)
				local t0, lastJump = os.clock(), -1e9
				while hwActive(id) and not gotTreat and os.clock() - t0 < seconds do
					if os.clock() - t0 >= JUMP_DELAY and os.clock() - lastJump >= JUMP_EVERY then
						lastJump = os.clock()
						jump()
					end
					task.wait(0.1)
				end
				return gotTreat
			end

			-- Visits one house: jumps in its circle and collects the treat.
			local function visit(id, i)
				current, gotTreat = i, false
				if not goTo(spot(i)) then current = nil return false end
				if standAndJump(id, ENTER_WAIT) then return true end
				if hwActive(id) then   -- no treat: step out of the circle and back in once
					goTo(spot(i) + Vector3.new(0, 30, 0))
					hwSleep(id, 0.7)
					goTo(spot(i))
					if standAndJump(id, REENTER_WAIT) then return true end
				end
				local knock = walk(RS, { "RemoteServices", "TrickOrTreatService", "RF", "Knock" })
				if hwActive(id) and knock and houseOf[i] then   -- id known: send the same Knock the game's client sends
					pcall(function() knock:InvokeServer(houseOf[i]) end)
					if standAndJump(id, 4) then return true end
				end
				return false
			end

			-------------------------------------------------- one cycle = (lap) + 1 hour wait
			local lastGood = 0
			local waitUntil, waitIsRefill = nil, false   -- SERVER time when the next lap may start / is it the refill (vs a short retry)
			local forceLap = false                        -- the wait just ended: visit every house, don't trust the board yet
			local lastResync = 0
			-- Does one full lap over all houses.
			local function cycle(id)
				-- the Hallow Lord goes first: stay out of the way until the fight is over
				if yieldToBoss() then
					say("Hallow Lord is up (ranked first) - waiting for the boss fight to finish...")
					while hwActive(id) and HW.bossAlive and yieldToBoss() do task.wait(1) end
					return
				end
				-- waiting for the houses to refill
				if waitUntil then
					if serverNow() < waitUntil then
						while hwActive(id) and not yieldToBoss() and serverNow() < waitUntil do
							say(string.format("%d treat(s) last lap | %s in %s%s", lastGood, waitIsRefill and "houses refill" or "retry", fmt(waitUntil - serverNow()),
								candy and (" | CandyCorn " .. tostring(candy)) or ""))
							hwSleep(id, 1)
							if waitIsRefill and os.clock() - lastResync > 30 and waitUntil - serverNow() > 15 then   -- re-read the board's timer now and then
								lastResync = os.clock()
								local at = nextRefillAt()
								if at then waitUntil = at + REFILL_PAD end
							end
						end
						return
					end
					waitUntil, forceLap = nil, waitIsRefill
				end

				syncFromData()
				local refillAt, src = nextRefillAt()
				local win = curWindow()
				print(string.format("[Halloween] houses refill in %s (from %s)", fmt(refillAt - serverNow()), src))
				HWSTAT.refillAt = refillAt

				-- the game's own data says every house was already collected in this refill window: nothing to do until the refill
				local nDone = collectedFromData(win)
				if nDone >= #HOUSES then
					print(string.format("[Halloween] all %d houses already collected this window (game data) - waiting for the refill", nDone))
					HW.markDone(win)
					waitUntil, waitIsRefill, lastResync = refillAt + REFILL_PAD, true, os.clock()
					return
				end

				-- every house on the board is dark with a refill countdown: nothing to collect until the refill
				local bn, bcool = houseBoardState()
				if not forceLap and bn and bn > 0 and bcool == bn then
					HW.markDone(win)
					waitUntil, waitIsRefill, lastResync = refillAt + REFILL_PAD, true, os.clock()
					return
				end

				-- already collected in this refill window (remembered in a file, so a re-execute doesn't forget it): don't travel again
				if HW.doneWin == nil then HW.doneWin = tonumber(Store.read(HW_FILE) or "") or false end
				if not forceLap and HW.doneWin == win then
					waitUntil, waitIsRefill, lastResync = refillAt + REFILL_PAD, true, os.clock()
					return
				end

				local todo = {}
				for i = 1, #HOUSES do
					if collectedWin[i] ~= win and (forceLap or not houseCooling(i)) then todo[#todo + 1] = i end
				end
				forceLap = false

				local good, bad, interrupted = 0, 0, false
				if #todo > 0 then
					say("Waiting for its turn (another feature is on a trip)...")
					if not acquireTrip("Halloween", function() return hwActive(id) end, say) then return end
					local ok, err = pcall(function()
						say("Traveling to " .. ISLAND .. "...")
						HW.traveled, HW.allCooling = false, false
						if not hwTravel(id) then bad = #todo return end
						HW.traveled = true
						if not hwSleep(id, SETTLE) then return end
						for n, i in ipairs(todo) do
							if not hwActive(id) then break end
							if yieldToBoss() then interrupted = true break end   -- boss spawned and is ranked first: give the player to it
							say(string.format("House %d/%d: jumping for the treat...", n, #todo))
							if visit(id, i) then
								good = good + 1
								collectedWin[i] = curWindow()
								current = nil
								say(string.format("House %d/%d: treat received%s | next house in %ds", n, #todo,
									candy and (" | CandyCorn " .. tostring(candy)) or "", math.ceil(math.max(3, AFTER_TREAT_WAIT))))
								hwSleep(id, math.max(3, AFTER_TREAT_WAIT))   -- at least 3 s after a treat before the next house
							else
								bad = bad + 1
								current = nil
								warn(string.format("[Halloween] house #%d: no treat (on cooldown or not reached)", i))
								hwSleep(id, 1)
								if good == 0 and bad >= 2 then   -- the first two houses gave nothing: the rest are on cooldown too, don't waste the lap
									HW.allCooling = true
									warn("[Halloween] first 2 houses gave no treat - assuming every house is on cooldown, waiting for the refill")
									break
								end
							end
						end
					end)
					current = nil
					releaseTrip("Halloween")   -- Hatch / Craft / Enchant may continue while we wait for the refill
					if not ok then error(err, 0) end
					lastGood = good
				end
				if not hwActive(id) then return end
				if interrupted then return end   -- the boss took over: the lap is finished afterwards (houses already done are skipped)
				if good > 0 then HW.tapSoon() end   -- treats were claimed: press the popup 30 s later

				local ids = {}
				for i = 1, #HOUSES do if houseOf[i] then ids[#ids + 1] = string.format("[%d]=%q", i, houseOf[i]) end end
				if #ids > 0 and #todo > 0 then print("[Halloween] house ids: { " .. table.concat(ids, ", ") .. " }") end

				-- when to go again: at the next refill (re-read now, the lap took a while)
				if #todo > 0 and good == 0 and bad > 0 then   -- nothing worked
					-- we got there but no house gave a treat = they are most likely still on cooldown. Retry once, then wait for the refill
					HW.failLaps[win] = (HW.failLaps[win] or 0) + 1
					if HW.traveled and (HW.allCooling or HW.failLaps[win] >= 2) then
						HW.markDone(win)
						local at = nextRefillAt()
						waitUntil, waitIsRefill = at + REFILL_PAD, true
					else   -- travel failed / event not running: retry soon
						waitUntil, waitIsRefill = serverNow() + RETRY_WAIT, false
					end
				else
					if #todo > 0 and good > 0 and bad == 0 then HW.markDone(win) end
					local at = nextRefillAt()
					waitUntil, waitIsRefill = at + REFILL_PAD, true
				end
				lastResync = os.clock()
			end

			-- Main loop of Trick or Treat.
			local function run(id)
				while hwActive(id) do
					local ok, err = pcall(cycle, id)
					if not ok then
						warn("[Halloween] error: " .. tostring(err))
						say("Error - trying again in a few seconds (see output)")
						hwSleep(id, 5)
					end
				end
			end

			local failMsg = nil
			treatEntry.callback = function(on)
				if not alive then return end
				hwRun = hwRun + 1
				local my = hwRun
				hwOn = on == true
				if hwOn then
					if not ensureListener() then
						hwOn = false
						failMsg = "Halloween data event not found - is the event running?"
						say(failMsg)
						task.defer(function() if treatEntry._setUI then treatEntry._setUI(false) end end)
						return
					end
					say("Starting...")
					task.spawn(run, my)
				else
					current = nil
					say(failMsg or treatEntry.desc)
					failMsg = nil
				end
			end

			table.insert(cleanupHooks, function()
				hwOn = false
				hwRun = hwRun + 1
				if conn then pcall(function() conn:Disconnect() end) conn = nil end
			end)

			-------------------------------------------------- Auto Kill Boss (Hallow Lord)
			local ARENA_CF = CFrame.new(-1683.7020263671875, -511.9337158203125, -2318.511474609375, 0.9976288080215454, 1.850430564331873e-08, -0.06882422417402267, -1.7633077220580162e-08, 1, 1.3266260090460946e-08, 0.06882422417402267, -1.2021220463509508e-08, 0.9976288080215454)
			local ARENA_STAY   = 40    -- studs: farther from the arena spot than this and you get teleported back
			local ISLAND_RANGE = 900   -- studs from the arena that still count as "on the Halloween island"
			local BOSS_DESC = bossEntry.desc

			local bossOn, bossRun = false, 0
			-- True while this Hallow Lord run is still the current one.
			local function bossActive(id) return alive and bossOn and bossRun == id end
			-- Sets the status text of Auto Kill Boss.
			local function bossSay(t) setDesc(bossEntry, t) end
			-- Lowercases a text and removes spaces / symbols for comparing names.
			local function squash(s) return (tostring(s):lower():gsub("[%s_%-]", "")) end
			-- Formats a boss HP number as text ("?" if unknown).
			local function hpText(n)
				if type(n) ~= "number" then return "?" end
				if n >= 1000 then return string.format("%.3g", n) end
				return tostring(math.floor(n))
			end

			-- a Humanoid, an HP/Health attribute or an HP/Health number value inside the boss
			local HP_NAMES = { "hp", "health", "currenthp", "currenthealth" }
			-- Reads the HP of a boss object.
			local function hpOf(inst)
				if not inst then return nil end
				local hum = inst:IsA("Humanoid") and inst or inst:FindFirstChildWhichIsA("Humanoid", true)
				if hum then return hum.Health end
				for _, a in ipairs({ "Health", "HP", "CurrentHealth", "CurrentHP" }) do
					local v = inst:GetAttribute(a)
					if type(v) == "number" then return v end
				end
				for _, c in ipairs(inst:GetDescendants()) do
					if (c:IsA("NumberValue") or c:IsA("IntValue")) and table.find(HP_NAMES, c.Name:lower()) then return c.Value end
				end
				return nil
			end

			local cands, candConn = {}, nil   -- things in the workspace named like "Hallow Lord"
			-- Adds an object as a possible Hallow Lord candidate.
			local function addCand(inst)
				if #inst.Name < 10 then return end   -- "hallowlord" has 10 letters: skips almost everything without the slower string work
				if not squash(inst.Name):find("hallowlord") then return end
				local root = (inst:IsA("Model") or inst:IsA("BasePart")) and inst or inst:FindFirstAncestorOfClass("Model") or inst
				for _, c in ipairs(cands) do if c == root then return end end
				cands[#cands + 1] = root
			end
			-- Scans the workspace for the Hallow Lord (returns how many candidates).
			local function fullScan()
				local n = 0
				for _, d in ipairs(workspace:GetDescendants()) do
					addCand(d)
					n = n + 1
					if n % 1000 == 0 then task.wait() end   -- spread over several frames (one big loop = a visible freeze)
				end
			end
			-- returns the Hallow Lord (only if it has HP above 0) and its HP
			local function findBoss()
				for i = #cands, 1, -1 do
					local c = cands[i]
					if not c.Parent or not c:IsDescendantOf(workspace) then
						table.remove(cands, i)
					else
						local hp = hpOf(c)
						if hp and hp > 0 then return c, hp end
					end
				end
				return nil
			end

			-- True if the character is on the Halloween island.
			local function onIsland()
				local hrp = getHRP()
				if not hrp then return false end
				local d = hrp.Position - ARENA_CF.Position
				return Vector3.new(d.X, 0, d.Z).Magnitude < ISLAND_RANGE and math.abs(d.Y) < 200
			end
			-- Travels to the Halloween island for the boss fight.
			local function bossTravel(id)
				for attempt = 1, TRAVEL_TRIES do
					while bossActive(id) and os.clock() - lastTravelAt < TRAVEL_GAP do task.wait(0.1) end
					if not bossActive(id) then return false end
					lastTravelAt = os.clock()
					local ok, res = pcall(function() return travelRemote:InvokeServer({ Source = "Menu", Island = ISLAND }) end)
					lastTravelAt = os.clock()
					if ok and type(res) == "table" and res.Success then
						local t0 = os.clock()
						while bossActive(id) and os.clock() - t0 < SETTLE do task.wait(0.1) end
						return bossActive(id)
					end
					warn(string.format("[Halloween] boss: Travel did not report success (try %d/%d): %s", attempt, TRAVEL_TRIES, brief(res)))
					local t0 = os.clock()
					while bossActive(id) and os.clock() - t0 < 4 do task.wait(0.1) end
				end
				return false
			end

			-- The game's own boss board (Workspace.HalloweenIsland.HallowBoss.HallowBossBoard...Main) says it all:
			-- Status = "Rises in mm:ss" while he is down, Health.Title = "64%", and "He rises every hour, on the hour".
			-- So the spawn is on every full hour of server time (a multiple of 3600 s).
			local doneHour = -1   -- the hour (floor(server time / 3600)) we already handled / confirmed over, so we do not bounce back
			-- Returns the boss' main object in the workspace.
			local function bossMain()
				return walk(workspace, { "HalloweenIsland", "HallowBoss", "HallowBossBoard", "Board", "HallowBossGui", "Main" })
			end
			-- "up" / "down" from the board, or nil when the board is not loaded (you are far away: the island streams in only when you are near)
			local function boardState()
				local main = bossMain()
				local st = main and main:FindFirstChild("Status")
				if not (st and st:IsA("TextLabel")) then return nil end
				local raw = st.Text
				local t = raw:lower()
				if t == "" then return nil end
				if t:find("rises in") then return "down", raw end
				if t:find("escaped") or t:find("defeated") or t:find("slain") or t:find("fallen") then return "down", raw end
				return "up", raw
			end
			-- Reads the boss HP from the boss board.
			local function boardHp()
				local main = bossMain()
				local h = main and main:FindFirstChild("Health")
				local t = h and h:FindFirstChild("Title")
				return t and t:IsA("TextLabel") and t.Text or nil
			end
			-- Returns the current hour (used for the boss spawn time).
			local function hourNow() return math.floor(workspace:GetServerTimeNow() / 3600) end
			-- Seconds until the boss spawns.
			local function secsToSpawn()
				local srv = workspace:GetServerTimeNow()
				return (math.floor(srv / 3600) + 1) * 3600 - srv
			end
			-- The boss bar at the top of the screen ("HALLOW LORD", "2,250 / 2,250", timer) is what you see in the game, so it is the main signal:
			-- a visible label that says "Hallow Lord" = he is up. A bar showing 0 HP = he is dead.
			local hudLabel, hudScanAt = nil, -1e9
			-- True if a GUI object is really shown.
			local function shownInGui(o)
				local root = pg()
				local cur = o
				while cur and cur ~= root do
					if cur:IsA("GuiObject") and not cur.Visible then return false end
					if cur:IsA("LayerCollector") and not cur.Enabled then return false end
					cur = cur.Parent
				end
				return cur == root
			end
			-- Scans the HUD text for boss information.
			local function hudScan()
				local root = pg()
				if not root then return nil end
				local n = 0
				for _, d in ipairs(root:GetDescendants()) do
					n = n + 1
					if n % 600 == 0 then task.wait() end   -- spread over several frames
					if d:IsA("TextLabel") and d.Text:lower():find("hallow lord", 1, true) and not (gui and d:IsDescendantOf(gui)) and shownInGui(d) then
						local title = d.Text:lower():gsub("<[^>]+>", ""):gsub("^%s+", ""):gsub("%s+$", "")
						-- The current game uses "THE HALLOW LORD ATTACKS!", not just "Hallow Lord".
						if title == "hallow lord" or title:find("hallow lord attacks", 1, true) then
							return d
						end
					end
				end
			end
			-- returns up (bool or nil when no bar exists), "cur/max" text
			local function hudState()
				if not (hudLabel and hudLabel.Parent and shownInGui(hudLabel)) then
					hudLabel = nil
					local sm = workspace:GetServerTimeNow() % 3600
					local every = (sm < 1500 or sm > 3540) and 1 or 20   -- he rises on the hour and a fight lasts up to ~20 min: scan every second only then
					if os.clock() - hudScanAt >= every then
						hudScanAt = os.clock()
						local ok, l = pcall(hudScan)
						if ok and l and shownInGui(l) then hudLabel = l end
					end
				end
				if not hudLabel then return nil end
				-- the HP numbers sit in the same bar: look a few levels up for a "cur / max" label
				local hpTxt
				local anc = hudLabel.Parent
				for _ = 1, 3 do
					if not anc then break end
					for _, d in ipairs(anc:GetDescendants()) do
						if d:IsA("TextLabel") then
							local cur, max = d.Text:match("^%s*([%d,%.]+)%s*/%s*([%d,%.]+)%s*$")
							if cur then hpTxt = cur .. "/" .. max break end
							local percent = d.Text:lower():match("(%d+)%s*%%%s*health%s+left")
							if percent then hpTxt = percent .. "% health left" break end
						end
					end
					if hpTxt then break end
					anc = anc.Parent
				end
				if hpTxt then
					local curN = tonumber((hpTxt:match("^([^/]+)"):gsub(",", "")))
					if curN and curN <= 0 then return false, hpTxt end
				end
				return true, hpTxt
			end

			local lastDiagAt = -1e9
			-- is the Hallow Lord up right now?  returns up, hpNumber (model), statusText
			local function bossUp()
				local hudUp, hudHp = hudState()
				local st, txt = boardState()
				local boss, hp = findBoss()
				local srv = workspace:GetServerTimeNow()
				if srv % 3600 < 600 and os.clock() - lastDiagAt > 60 then   -- first 10 min of the hour: show what every signal says (for debugging)
					lastDiagAt = os.clock()
					print(string.format("[Halloween] boss check: bar=%s (%s) | board=%s %q | model=%s", tostring(hudUp), tostring(hudHp), tostring(st), tostring(txt), tostring(boss ~= nil)))
				end
				if hudUp == true then return true, hp, hudHp end
				if hudUp == false then return false end
				if st == "up" then return true, hp, txt end
				if boss then return true, hp end
				if st == "down" then return false end
				-- nothing loaded: "it is just past the hour and we have not checked yet"
				if hourNow() ~= doneHour and srv % 3600 < 90 then return true end
				return false
			end

			-- Main loop of Auto Kill Boss.
			local function bossLoop(id)
				fullScan()
				if candConn then candConn:Disconnect() end
				candConn = workspace.DescendantAdded:Connect(function(d) task.defer(addCand, d) end)
				local lastScan = os.clock()
				while bossActive(id) do
					local up = bossUp()
					if up then
						HW.bossAlive = true   -- Trick or Treat steps aside (if the boss is ranked above it)
						bossSay("Hallow Lord is up - waiting for the player to be free...")
						if acquireTrip("HalloweenBoss", function() return bossActive(id) end, bossSay) then
							local okF, errF = pcall(function()
								local misses, t0 = 0, os.clock()
								while bossActive(id) and os.clock() - t0 < 1200 do
									local stillUp, hp, txt = bossUp()
									if stillUp then misses = 0 else misses = misses + 1 end
									if misses >= 3 then break end   -- gone for 3 checks in a row: the fight is over
									if not onIsland() and not bossTravel(id) then
										bossSay("Could not travel to " .. ISLAND .. " - retrying")
										task.wait(5)
									end
									local hrp = getHRP()
									if hrp and (hrp.Position - ARENA_CF.Position).Magnitude > ARENA_STAY then goTo(ARENA_CF) end
									local pct = boardHp()
									bossSay("Fighting the Hallow Lord - HP " .. (pct or (hp and hpText(hp)) or txt or "?") .. " (Auto Click does the damage)")
									task.wait(1)
								end
							end)
							releaseTrip("HalloweenBoss")
							if not okF then warn("[Halloween] boss error: " .. tostring(errF)) end
						end
						doneHour = hourNow()
						HW.bossAlive = false
						HW.tapSoon()   -- the fight is over: press the popup 30 s later
						if bossActive(id) then bossSay("Fight over - Hallow Lord rises again in " .. fmt(secsToSpawn())) end
					else
						if os.clock() - lastScan > 600 then fullScan() lastScan = os.clock() end
						if bossActive(id) and not HW.bossAlive then
							bossSay("Hallow Lord rises in " .. fmt(secsToSpawn()) .. " (every hour, on the hour)")
						end
					end
					task.wait(1)   -- 1 s so the countdown in the toggle ticks every second
				end
				HW.bossAlive = false
			end

			bossEntry.callback = function(on)
				if not alive then return end
				bossRun = bossRun + 1
				bossOn = on == true
				if bossOn then
					task.spawn(bossLoop, bossRun)
				else
					HW.bossAlive = false
					if candConn then candConn:Disconnect() candConn = nil end
					releaseTrip("HalloweenBoss")
					bossSay(BOSS_DESC)
				end
			end

			-------------------------------------------------- Auto Purchase Items (Halloween shop)
			-- label = what the dropdown shows. ids = the Id(s) the shop's Purchase remote may take: the first one that the server accepts
			-- is remembered. TotemOfHatchSpeed and TotemOfSecretLuck are confirmed; the rest are guessed from the item names
			-- (if one never works, check the console warning and put the real Id first in its list).
			local SHOP_ITEMS = {
				{ label = "Totem of Hatch Speed", ids = { "TotemOfHatchSpeed" } },
				{ label = "Totem of Secret Luck", ids = { "TotemOfSecretLuck" } },
				{ label = "Totem of Luck",        ids = { "TotemOfLuck" } },
				{ label = "Blood Moon Dial",      ids = { "BloodMoonDial" } },
				{ label = "Octo Incubator",       ids = { "OctoIncubator" } },
				{ label = "Immortal Pumpkin",     ids = { "ImmortalPumpkin" } },
				{ label = "Secret Fruit",         ids = { "SecretFruit" } },
				{ label = "Rainbow Strawberry",   ids = { "RainbowStrawberry" } },
				{ label = "+10 Levels",           ids = { "Plus10Levels", "PlusTenLevels", "10Levels", "TenLevels", "Levels10" } },
			}
			local BUY_EVERY    = 3600  -- seconds between shop rounds (1 hour)
			local BUY_BACKOFF  = 60    -- seconds an item is skipped after a failed purchase (not enough candy corn / wrong id)
			local SHOP_DESC = shopEntry.desc
			local shopLabels = {}
			for _, it in ipairs(SHOP_ITEMS) do shopLabels[#shopLabels + 1] = it.label end
			local itemsEntry = {
				type = "dropdown", name = "Items to Buy", icon = "🛒", width = 320, multi = true,
				picked = { ["Totem of Hatch Speed"] = true }, clearOption = "None",
				desc = "Tick one or more items for Auto Purchase Items to buy (top of the list first). It uses the shop's buy remote, no need to go to the shop. An item is dropped from the list once it is sold out.",
				options = shopLabels, default = shopLabels[1],
			}
			local shopOn, shopRun = false, 0
			-- True while this Auto Purchase run is still the current one.
			local function shopActive(id) return alive and shopOn and shopRun == id end
			-- Sets the status text of Auto Purchase Items.
			local function shopSay(t) setDesc(shopEntry, t) end

			-- Main loop of Auto Purchase Items (checks the shop and buys).
			local function shopLoop(id)
				local buyRemote = walk(RS, { "RemoteServices", "HalloweenShopService", "RF", "Purchase" })
				if not buyRemote then
					shopSay("HalloweenShopService.RF.Purchase not found - is the event running?")
					return
				end
				-- the server answers { Success, Bought, Remaining (stock left), Id, Candy (your balance) }
				local skipUntil, soldOut, goodId, bought, lastCandy = {}, {}, {}, 0, nil
				while shopActive(id) do
					local any = false
					for _, item in ipairs(SHOP_ITEMS) do
						if not shopActive(id) then break end
						local name = item.label
						if itemsEntry.picked and itemsEntry.picked[name] and not soldOut[name] then
							any = true
							if os.clock() >= (skipUntil[name] or 0) then
								local tryIds = goodId[name] and { goodId[name] } or item.ids
								local done, lastRes = false, nil
								for _, pid in ipairs(tryIds) do
									if not shopActive(id) then break end
									local ok, res = pcall(function() return buyRemote:InvokeServer({ Id = pid }) end)
									local r = ok and type(res) == "table" and res or nil
									lastRes = ok and brief(res) or tostring(res)
									if r and type(r.Candy) == "number" then lastCandy = r.Candy end
									if r and r.Success == true then
										goodId[name] = pid
										bought = bought + (tonumber(r.Bought) or 1)
										if tonumber(r.Remaining) and r.Remaining <= 0 then soldOut[name] = true end
										shopSay(string.format("Bought %s (%d total) | %s left | CandyCorn %s", name, bought,
											tostring(r.Remaining or "?"), tostring(lastCandy or "?")))
										done = true
										break
									end
									warn(string.format("[Halloween] buy %s as Id=%s failed: %s", name, pid, lastRes))
									if r and tonumber(r.Remaining) and r.Remaining <= 0 then soldOut[name] = true break end
									task.wait(0.3)
								end
								if not done then
									skipUntil[name] = os.clock() + BUY_BACKOFF
									shopSay(string.format("%s not bought%s - trying again in %ds", name,
										soldOut[name] and " (sold out)" or "", BUY_BACKOFF))
								end
								task.wait(0.4)
							end
						end
					end
					if not any then
						local ticked = false
						for _, item in ipairs(SHOP_ITEMS) do if itemsEntry.picked and itemsEntry.picked[item.label] then ticked = true end end
						shopSay(ticked and string.format("Everything ticked is sold out (%d bought) - nothing left to buy", bought) or "Nothing ticked in Items to Buy")
					end
					local t0 = os.clock()
					while shopActive(id) and os.clock() - t0 < BUY_EVERY do task.wait(0.25) end
				end
			end

			shopEntry.callback = function(on)
				if not alive then return end
				shopRun = shopRun + 1
				shopOn = on == true
				if shopOn then task.spawn(shopLoop, shopRun) else shopSay(SHOP_DESC) end
			end
			table.insert(cleanupHooks, function()
				bossOn, shopOn, bossRun, shopRun = false, false, bossRun + 1, shopRun + 1
				HW.bossAlive = false
				if candConn then pcall(function() candConn:Disconnect() end) candConn = nil end
			end)

			return { treat = treatEntry, boss = bossEntry, shop = shopEntry, items = itemsEntry }
		end)
		if okH then HG.halloween = resH else warn("[WORST Hub] Halloween failed to load: " .. tostring(resH)) end
	end

	-------------------------------------------------------------------------- EVENTS > PET DEFENSE (Colosseum wave defense)
	-- Travel to Mushroom, stand at the start spot, press "Play" on the Pet Defense popup, attack every opponent the moment it spawns, repeat.
	-- Reward claim is confirmed: ClaimMinigameReward("keep"/"replace"). ReturnFromArena is attempted without arguments.
	do
		local okP, resP = pcall(function()
			local ISLAND       = "Mushroom"
			local SPOT         = CFrame.new(-168.33155822753906, 2025.3372802734375, -1794.38134765625, -0.020469628274440765, -5.5086310624119506e-08, 0.9997904896736145, 3.8178332717464514e-10, 1, 5.510567291366897e-08, -0.9997904896736145, 1.509695923829213e-09, -0.020469628274440765)
			local RETRY_WAIT   = 30      -- seconds before trying to start again when the start was refused (cooldown)
			local COOLDOWN_SECS = 1800   -- length of the cooldown after a run: 30 min (Data.Colosseum.Cooldown holds the time it STARTED; compare the status line with the game's "Come back in" timer and change this if it is off)
			local PRESS_INTERVAL = 0.1   -- seconds between two screen presses while a run is on
			local PRESS_HOLD     = 0.05  -- how long each press is held down
			local POPUP_DELAY  = 3     -- seconds to wait after arriving before looking for the popup / pressing Play
			local POPUP_WAIT   = 60      -- seconds to keep re-checking for the Pet Defense popup after arriving at the start spot
			local START_WAIT   = 8       -- seconds to wait for the first opponent after starting
			local POPUP_RECHECK = 10     -- seconds between two checks for the Play button once on the start spot
			local ARENA_CENTER_DELAY = 2 -- seconds after the battle starts before going to the arena center
			local ARENA_CENTER = CFrame.new(-226.18292236328125, 2026.308837890625, -1793.7020263671875, 0.13348408043384552, 9.956330870863894e-09, 0.9910509586334229, 6.328140500500012e-08, 1, -1.8569570769955135e-08, -0.9910509586334229, 6.519383788372579e-08, 0.13348408043384552)
			local CLAIM_REMOTE = { "RF", "ClaimMinigameReward" }
			local RETURN_REMOTE = { "RF", "ReturnFromArena" }
			-- Builds the arguments for claiming a relic.
			local function claimArgs(replace) return replace and "replace" or "keep" end
			local STAT_ORDER = { "Luck", "ClickMultiplier", "Rebirth", "Walkspeed" }

			local svc = find(RS, { "RemoteServices", "ColosseumService" })
			assert(svc, "ColosseumService not found")

			local DESC = "Travels to Mushroom, presses Play on the Pet Defense popup to start the Colosseum wave defense and taps the middle of the screen repeatedly to fight, then starts the next run (waits and retries while it is on cooldown). Needs the Mushroom island."
			local toggle = {
				-- TOGGLE "Auto Pet Defense": plays the Pet Defense event and handles the new ring by the chosen mode (Keep / Replace / Better).
				type = "toggle", name = "Auto Pet Defense", icon = "🛡", default = false,
				desc = DESC,
			}
			local modeEntry = {
				type = "dropdown", name = "Ring Reward", icon = "💍", width = 240,
				desc = "Keep = keep your ring | Replace = take the new one | Better = compare Luck, ClickMultiplier, Rebirth, Walkspeed in that order. No current ring = Replace.",
				options = { "Keep", "Replace", "Better" }, default = "Keep",
			}
			local infoEntry = {
				type = "button", name = "Print Ring Info", icon = "📋", noSave = true,
				desc = "Prints what the game data holds about your ring / the Colosseum, and the Colosseum remotes, to the console (F9).",
			}

			local runId, mode = 0, "Keep"
			local pd = { run = false, over = nil, claimed = false, wave = 0, spawned = 0, logN = 0, done = 0, waveStarted = false, fight = false }
			-- True while this Pet Defense run is still the current one.
			local function active(id) return alive and runId == id end
			-- Sets the status text of Pet Defense.
			local function say(text) setDesc(toggle, text) end
			-- Waits `sec` while the run is active.
			local function sleep(id, sec)
				local t0 = os.clock()
				while active(id) and os.clock() - t0 < sec do task.wait(0.1) end
			end
			modeEntry.callback = function(opt) mode = tostring(opt) end

			-- ---- the ring: read the game's data (NOT captured yet where the equipped ring lives, so this searches for it)
			local function gameData()
				local ok, d = pcall(function() return require(RS.Controllers.Core.DataController):GetReplica().Data end)
				return ok and type(d) == "table" and d or nil
			end
			-- Returns the relic currently owned.
			local function currentRelic()
                local data = gameData()
                local c = data and data.Colosseum
                return type(c) == "table" and type(c.Relic) == "table" and c.Relic or nil
            end
            -- Returns the relic that is waiting to be claimed.
            local function pendingRelic()
                local data = gameData()
                local c = data and data.Colosseum
                local pending = type(c) == "table" and c.PendingReward
                return type(pending) == "table" and pending.NewRelic or nil
            end
            -- Reads one stat value of a relic.
            local function statValue(relic, key)
                for _, boost in pairs(type(relic) == "table" and relic.Boosts or {}) do
                    if type(boost) == "table" and tostring(boost.Type):lower() == key:lower() then
                        return tonumber(boost.Value) or 0
                    end
                end
                return 0
            end

			-- Builds a readable text for a relic and its stats.
			local function relicText(relic)
				local parts = {}
				for _, b in ipairs(type(relic) == "table" and relic.Boosts or {}) do
					if type(b) == "table" then parts[#parts + 1] = tostring(b.Type) .. " " .. tostring(b.Value) end
				end
				return (relic and relic.Name or "?") .. " (" .. table.concat(parts, ", ") .. ")"
			end
			-- true = replace, false = keep; missing current ring ALWAYS replaces.
            local function decide(over)
                local new = (type(over) == "table" and type(over.RewardData) == "table" and over.RewardData.NewRelic) or pendingRelic()
                if type(new) ~= "table" then return nil end
                local cur = currentRelic()
                if not cur then
                    print("[PetDefense] No existing ring: REPLACE")
                    return true
                end
                if mode == "Replace" then return true end
                if mode == "Keep" then return false end
                for _, stat in ipairs(STAT_ORDER) do
                    local a, b = statValue(new, stat), statValue(cur, stat)
                    if a ~= b then
                        print(string.format("[PetDefense] %s: new %.5f vs current %.5f -> %s", stat, a, b, a > b and "REPLACE" or "KEEP"))
                        return a > b
                    end
                end
                return false
            end

			-- Claims the new relic (replace = swap it with the old one).
			local function claim(replace)
				local r = find(svc, CLAIM_REMOTE)
				if not r then warn("[PetDefense] claim remote not found") return false end
				local ok, err = pcall(function()
					if r:IsA("RemoteFunction") then return r:InvokeServer(claimArgs(replace)) else r:FireServer(claimArgs(replace)) end
				end)
				if not ok then warn("[PetDefense] claim failed: " .. tostring(err)) end
				return ok
			end
            -- Leaves the arena and returns to where you were.
            local function returnFromArena()
                local r = find(svc, RETURN_REMOTE)
                if not r then warn("[PetDefense] ReturnFromArena not found") return false end
                local ok, res = pcall(function() return r:InvokeServer() end)
                if not ok or res == false or (type(res) == "table" and res.Success == false) then
                    warn("[PetDefense] ReturnFromArena was not confirmed: " .. brief(res))
                    return false
                end
                return true
            end

			-- ---- events
			-- ---- cooldown: read when the next run is available from the game's data (Data.Colosseum). The field name is not known for
			-- certain, so any number in there that looks like a future timestamp and has a cooldown-ish name is used. When none is found
			-- the whole Colosseum table is printed once to the console (F9) so the right field can be named.
			local function serverNowT()
				local ok, t = pcall(function() return workspace:GetServerTimeNow() end)
				return ok and t or os.time()
			end
			-- Formats seconds as a time text.
			local function fmtT(sec)
				sec = math.max(0, math.floor(sec))
				if sec >= 3600 then return string.format("%dh %02dm", math.floor(sec / 3600), math.floor((sec % 3600) / 60)) end
				if sec >= 60 then return string.format("%dm %02ds", math.floor(sec / 60), sec % 60) end
				return sec .. "s"
			end
			-- Data.Colosseum.Cooldown = server time (seconds) at which the cooldown STARTED; the game shows the rest as "Come back in 00:20:49!"
			-- (checked against your own numbers: the value was 782 s old while the game still counted down, i.e. start + 30 min).
			-- Returns seconds left (0 when over) and true when the field is there as a timestamp, otherwise nil.
			local warnedCd = false
			-- Exact seconds left of the cooldown (from the game data).
			local function exactCooldownLeft()
				local data = gameData()
				local c = data and data.Colosseum
				local v = type(c) == "table" and c.Cooldown
				if type(v) ~= "number" then return nil, false end
				if v == 0 then return 0, true end   -- never played: no cooldown
				if v <= 1e9 then
					if not warnedCd then warnedCd = true print("[PetDefense] Colosseum.Cooldown = " .. tostring(v) .. " is not a timestamp - not used") end
					return nil, false
				end
				local ts = (v > 1e12) and (v / 1000) or v   -- milliseconds -> seconds
				return math.max(0, ts + COOLDOWN_SECS - serverNowT()), true
			end
			local CD_WORDS = { "cooldown", "next", "avail", "ready", "until" }
			-- Seconds left of the cooldown (estimated when not exact).
			local function cooldownLeft()
				local e, present = exactCooldownLeft()
				if present then return (e > 0) and e or nil, "Colosseum.Cooldown" end
				local data = gameData()
				local c = data and data.Colosseum
				if type(c) ~= "table" then return nil end
				local now, bestLeft, bestKey = serverNowT(), nil, nil
				-- Debug: scans a table for values (used to find the colosseum data).
				local function scan(t, depth, path)
					for k, v in pairs(t) do
						local lk = tostring(k):lower()
						if type(v) == "number" and v > 1e9 then
							for _, w in ipairs(CD_WORDS) do
								if lk:find(w, 1, true) then
									local ts = (v > 1e12) and (v / 1000) or v   -- milliseconds -> seconds
									local left = ts - now
									if left > 0 and left < 43200 and (not bestLeft or left > bestLeft) then bestLeft, bestKey = left, path .. tostring(k) end
									break
								end
							end
						elseif type(v) == "table" and depth < 2 and lk ~= "relic" then
							scan(v, depth + 1, path .. tostring(k) .. ".")
						end
					end
				end
				scan(c, 0, "Colosseum.")
				return bestLeft, bestKey
			end
			local dumpedColosseum = false
			-- Debug: prints the colosseum data once.
			local function dumpColosseum()
				if dumpedColosseum then return end
				dumpedColosseum = true
				local data = gameData()
				local c = data and data.Colosseum
				print("[PetDefense] no cooldown timestamp found. Server time now = " .. tostring(serverNowT()) .. " | Data.Colosseum:")
				if type(c) ~= "table" then print("   (no Colosseum table in your data)") return end
				-- Debug: prints a table with indentation.
				local function walk(t, depth, indent)
					for k, v in pairs(t) do
						if type(v) == "table" then
							print(indent .. tostring(k) .. ":")
							if depth < 3 then walk(v, depth + 1, indent .. "  ") end
						else
							print(indent .. tostring(k) .. " = " .. tostring(v))
						end
					end
				end
				walk(c, 1, "   ")
			end

			-- ---- attacking: like a player tapping the screen. While a run is on, the middle of the screen is pressed
			-- over and over (left click / tap, simulated through VirtualInputManager) - no need to find or aim at opponents.
			local function pressCenter()
				local cam = workspace.CurrentCamera
				if not cam then return end
				local size = cam.ViewportSize
				local x, y = math.floor(size.X / 2), math.floor(size.Y / 2)
				VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
				task.wait(PRESS_HOLD)
				VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
			end
			task.spawn(function()
				while alive do
					if pd.run and pd.fight then
						pcall(pressCenter)
						task.wait(PRESS_INTERVAL)
					else
						task.wait(0.2)
					end
				end
			end)
			-- Listens to a server event of the service by name.
			local function hook(name, fn)
				local r = find(svc, { "RE", name })
				if r then connect(r.OnClientEvent, fn) else warn("[PetDefense] event not found: " .. name) end
			end
			hook("WaveDefenseOpponentSpawned", function(d)
				if pd.run then pd.spawned = pd.spawned + 1 end
			end)
			hook("WaveDefenseWaveStarting", function(d)
				if pd.run then pd.waveStarted = true end
				if type(d) == "table" then pd.wave = tonumber(d.Wave) or pd.wave end
			end)
			hook("WaveDefenseWaveComplete", function(d) if type(d) == "table" then pd.wave = (tonumber(d.WaveCompleted) or pd.wave) + 1 end end)
			hook("WaveDefenseGameOver", function(d) if pd.run then pd.over = d or {} end end)
			hook("MinigameRewardsClaimed", function() pd.claimed = true end)

			-- The intro dialog (Play / Not now) is no longer hidden: the script finds its "Play" button and presses it, exactly like a
			-- player would, so the game runs its own start and close steps. clearBlur() is still kept as a safety net while Auto Pet
			-- Defense is on, in case the game leaves the world blurred after the dialog closes.
			local Lighting = game:GetService("Lighting")
			local dofSaved, blurLogged = {}, {}
			-- Removes the camera blur created by the arena.
			local function clearBlur()
				local cam = workspace.CurrentCamera
				for _, holder in ipairs({ Lighting, cam }) do
					if holder then
						for _, e in ipairs(holder:GetChildren()) do
							if e:IsA("BlurEffect") then
								if e.Size > 0 then
									if not blurLogged[e] then blurLogged[e] = true print("[PetDefense] removing blur: " .. e:GetFullName() .. " (size " .. tostring(e.Size) .. ")") end
									e.Size = 0
								end
							elseif e:IsA("DepthOfFieldEffect") and e.Enabled then
								if not blurLogged[e] then blurLogged[e] = true print("[PetDefense] switching off depth of field: " .. e:GetFullName()) end
								dofSaved[e] = true
								e.Enabled = false
							end
						end
					end
				end
			end
			-- Restores the depth-of-field effects that were turned off.
			local function restoreDof()   -- depth of field is a normal part of the game's look: put it back when Auto Pet Defense is switched off
				for e in pairs(dofSaved) do
					if e.Parent then e.Enabled = true end
					dofSaved[e] = nil
				end
			end
			-- Cleans a text (removes rich-text tags and spaces).
			local function norm(t)   -- plain lower-case text: no rich-text tags, no surrounding spaces
				t = tostring(t or ""):gsub("<[^>]+>", "")
				t = t:gsub("^%s+", "")
				t = t:gsub("%s+$", "")
				return t:lower()
			end
			-- true when the ScreenGui is enabled and every GuiObject above `obj` is visible
			local function isShown(obj)
				local n = obj
				while n and n ~= game do
					if n:IsA("ScreenGui") then return n.Enabled end
					if n:IsA("GuiObject") and not n.Visible then return false end
					n = n.Parent
				end
				return true
			end
			-- Returns the button that contains a GUI object.
			local function buttonOf(obj)   -- the GuiButton that is (or contains) this object
				local n = obj
				while n and not n:IsA("ScreenGui") do
					if n:IsA("GuiButton") then return n end
					n = n.Parent
				end
				return nil
			end

			local playBtn, playContainer, playKind, lastIntroScan, lastDiag, wsDiagDone = nil, nil, "", 0, 0, false
			-- What to press. `container` = the highest frame that holds the "Play" text but NOT the "Not now" text (the whole Play button).
			-- Preferred: a real GuiButton (the label's ancestor, or one inside the container). The game's Pet Defense dialog has no
			-- GuiButton at all (Tabs.Message.Menu.Actions.Yes.Main.TextLabel), so then the container itself is the target.
			local function resolveTarget(label, container)
				local b = buttonOf(label)
				if b and (b == container or b:IsDescendantOf(container)) then return b, "GuiButton (around the label)" end
				local d = container:FindFirstChildWhichIsA("GuiButton", true)
				if d then return d, "GuiButton (inside the Play frame)" end
				return container, "custom button (no GuiButton)"
			end
			-- Failure report: lists every text / button in PlayerGui (disabled ScreenGuis included) that looks like the popup, so we can
			-- see where it really lives. The workspace (world-space billboards / surface GUIs) is searched once.
			local DIAG_KEYS = { "pet defense", "treat pit", "not now", "tap pets" }
			-- Debug: checks whether a GUI node looks like the Play button.
			local function diagMatch(node)
				if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
					local t = norm(node.Text)
					for _, k in ipairs(DIAG_KEYS) do if t:find(k, 1, true) then return "text: " .. t:sub(1, 40) end end
					if t == "play" or (#t <= 10 and t:find("play", 1, true)) then return "text: " .. t end
				end
				if node:IsA("GuiButton") and node.Name:lower():find("play", 1, true) then return "button named " .. node.Name end
				return nil
			end
			-- Debug: prints what was found when searching for the Play popup.
			local function popupDiag(pg, scanned)
				print("[PetDefense] popup search: nothing named/reading 'Play' in the enabled GUIs (" .. scanned .. " objects). Wider search:")
				local lines, names, n = {}, {}, 0
				for _, root in ipairs(pg:GetChildren()) do
					if root ~= gui then
						if root:IsA("ScreenGui") then names[#names + 1] = root.Name .. (root.Enabled and "" or " (disabled)") end
						for _, node in ipairs(root:GetDescendants()) do
							n = n + 1
							if n % 1500 == 0 then task.wait() end
							local why = diagMatch(node)
							if why and #lines < 15 then
								lines[#lines + 1] = node.ClassName .. " " .. node:GetFullName() .. " [" .. why .. "] shown=" .. tostring(isShown(node))
							end
						end
					end
				end
				if #lines == 0 then
					print("[PetDefense]   PlayerGui: no popup text at all. ScreenGuis: " .. table.concat(names, ", "))
				else
					for _, l in ipairs(lines) do print("[PetDefense]   " .. l) end
				end
				if not wsDiagDone then
					wsDiagDone = true
					local found, k = 0, 0
					for _, node in ipairs(workspace:GetDescendants()) do
						k = k + 1
						if k % 3000 == 0 then task.wait() end
						if found < 6 and (node:IsA("TextLabel") or node:IsA("TextButton")) then
							local why = diagMatch(node)
							if why then found = found + 1 print("[PetDefense]   workspace: " .. node.ClassName .. " " .. node:GetFullName() .. " [" .. why .. "]") end
						end
					end
					if found == 0 then print("[PetDefense]   workspace: nothing matching either (" .. k .. " objects)") end
				end
			end
			-- Looks for the Pet Defense dialog and returns its "Play" button (or its label if no button object wraps it), or nil.
			-- It starts from every "Play" text on screen and walks up until it reaches a frame that also holds a "Not now" text and
			-- mentions Pet Defense, so it does not depend on the exact GUI path or on how the title is built.
			local function findPlayButton()
				if playBtn and playBtn.Parent and isShown(playBtn) then return playBtn end
				playBtn = nil
				if os.clock() - lastIntroScan < 1 then return nil end
				lastIntroScan = os.clock()
				local pg = player and player:FindFirstChild("PlayerGui")
				if not pg then return nil end
				local n, scanned, seen = 0, 0, {}
				for _, sg in ipairs(pg:GetChildren()) do
					if sg ~= gui and (not sg:IsA("ScreenGui") or sg.Enabled) then   -- never the hub's own UI; folders / other containers are searched too
						for _, node in ipairs(sg:GetDescendants()) do
							n = n + 1
							scanned = scanned + 1
							if n % 1500 == 0 then task.wait() end
							if (node:IsA("TextLabel") or node:IsA("TextButton")) and (norm(node.Text) == "play" or (#norm(node.Text) <= 10 and norm(node.Text):find("play", 1, true))) then
								local shown = isShown(node)
								local frame, why = node.Parent, "no frame with 'Not now' found above it"
								local container = node
								for _ = 1, 8 do
									if not frame or frame:IsA("ScreenGui") then break end
									local notNow, title = false, false
									for _, child in ipairs(frame:GetDescendants()) do
										if child:IsA("TextButton") or child:IsA("TextLabel") then
											local t = norm(child.Text)
											if t == "not now" then notNow = true end
											if t:find("pet defense", 1, true) or t:find("treat pit", 1, true) then title = true end
										end
									end
									if not notNow then container = frame end
									if notNow and title then
										if shown then
											playBtn, playKind, playContainer = resolveTarget(node, container)
											print("[PetDefense] found the Play button: " .. playBtn:GetFullName() .. " | " .. playKind .. " | frame " .. playContainer:GetFullName())
											-- structure of the Play frame, so a failing press can be diagnosed
											local list, k = { playContainer }, 0
											for _, d in ipairs(playContainer:GetDescendants()) do list[#list + 1] = d end
											for _, d in ipairs(list) do
												k = k + 1
												if k > 20 then break end
												if d:IsA("GuiObject") then
													print(string.format("[PetDefense]   %s '%s' Active=%s Visible=%s pos %s size %s", d.ClassName, d.Name, tostring(d.Active), tostring(d.Visible), tostring(d.AbsolutePosition), tostring(d.AbsoluteSize)))
												end
											end
											return playBtn
										end
										why = "dialog found but hidden (an ancestor is not Visible)"
										break
									elseif notNow then
										why = "has 'Not now' but no 'Pet Defense' text"
									end
									frame = frame.Parent
								end
								seen[#seen + 1] = node:GetFullName() .. "  [" .. why .. "]"
							end
						end
					end
				end
				if os.clock() - lastDiag > 8 then
					lastDiag = os.clock()
					if #seen > 0 then
						for _, line in ipairs(seen) do print("[PetDefense] popup search: 'Play' text rejected: " .. line) end
					else
						popupDiag(pg, scanned)
					end
				end
				return nil
			end

			-- Clicks the centre of a GUI object with a real mouse click.
			local function clickCenter(obj)
				local sg = obj
				while sg and not sg:IsA("ScreenGui") do sg = sg.Parent end
				-- a ScreenGui with IgnoreGuiInset already starts at the very top of the screen: do not add the inset again
				local off = (sg and sg.IgnoreGuiInset) and Vector2.new(0, 0) or GuiService:GetGuiInset()
				local pos = obj.AbsolutePosition + obj.AbsoluteSize / 2
				local x, y = pos.X + off.X, pos.Y + off.Y
				-- the hub's own window may sit on top of the popup and take the click: hide it for a moment
				local hubOn = false
				pcall(function() hubOn = gui and gui:IsA("ScreenGui") and gui.Enabled end)
				if hubOn then record.guiSuspended = true pcall(function() gui.Enabled = false end) task.wait(0.1) end
				pcall(function()
					VIM:SendMouseMoveEvent(x, y, game)   -- hover first: many buttons only react to a click while hovered
					task.wait(0.15)
					VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
					task.wait(0.08)
					VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
				end)
				if hubOn then pcall(function() gui.Enabled = true end) record.guiSuspended = false end
				return string.format("%d,%d", x, y)
			end
			-- Fires the connections of a button signal.
			local function fireConnections(btn, sig)
				local gc = getconnections or get_signal_cons
				if type(gc) ~= "function" or not btn:IsA("GuiButton") then return false end
				local fired = false
				pcall(function()
					for _, c in ipairs(gc(btn[sig])) do c:Fire() fired = true end
				end)
				return fired
			end
			-- Custom buttons listen to InputBegan / InputEnded on a plain frame. Fire those connections (on the Play frame and everything
			-- inside it) with a fake left-click input. The connection counts are printed so it is visible where the game listens.
			local function fireInput(root)
				local gc = getconnections or get_signal_cons
				if type(gc) ~= "function" then return false end
				local center = root.AbsolutePosition + root.AbsoluteSize / 2
				local objs = { root }
				for _, d in ipairs(root:GetDescendants()) do if d:IsA("GuiObject") then objs[#objs + 1] = d end end
				local fired = false
				for _, o in ipairs(objs) do
					for _, sig in ipairs({ "InputBegan", "InputEnded" }) do
						local fake = {
							UserInputType = Enum.UserInputType.MouseButton1,
							UserInputState = (sig == "InputBegan") and Enum.UserInputState.Begin or Enum.UserInputState.End,
							Position = Vector3.new(center.X, center.Y, 0), Delta = Vector3.zero, KeyCode = Enum.KeyCode.Unknown,
						}
						pcall(function()
							local list = gc(o[sig])
							if #list > 0 then print("[PetDefense]   " .. sig .. " x" .. #list .. " on " .. o:GetFullName()) end
							for _, c in ipairs(list) do
								pcall(function() c:Fire(fake) end)
								fired = true
							end
						end)
					end
				end
				return fired
			end
			-- select the button and press Enter (the same path a gamepad / keyboard-navigation player takes)
			local function selectAndEnter(btn)
				if not btn:IsA("GuiButton") then return false end
				local ok = pcall(function()
					GuiService.SelectedObject = btn
					task.wait(0.15)
					VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
					task.wait(0.05)
					VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
				end)
				pcall(function() if GuiService.SelectedObject == btn then GuiService.SelectedObject = nil end end)
				return ok
			end

			-- Presses "Play". One method at a time; after each it waits for proof that the run started (the game's own WaveStarting /
			-- opponent-spawn event, or the dialog closing) before trying the next, so the button is not pressed twice by different
			-- methods. Every step is printed to the console (F9) so a failure can be diagnosed.
			local function pressPlay(id, btn)
				local gc = getconnections or get_signal_cons
				-- Returns how many connections a button signal has.
				local function nconn(sig)
					if type(gc) ~= "function" or not btn:IsA("GuiButton") then return "n/a" end
					local ok, list = pcall(function() return gc(btn[sig]) end)
					return ok and tostring(#list) or "error"
				end
				print(string.format("[PetDefense] Play target: %s %s | pos %s size %s | getconnections=%s firesignal=%s | connections Click=%s Activated=%s Down=%s",
					btn.ClassName, btn:GetFullName(), tostring(btn.AbsolutePosition), tostring(btn.AbsoluteSize),
					tostring(type(gc) == "function"), tostring(type(firesignal) == "function"),
					nconn("MouseButton1Click"), nconn("Activated"), nconn("MouseButton1Down")))
				-- True when the wave has started, ended or the button is gone.
				local function done()
					return pd.waveStarted or pd.spawned > 0 or pd.over ~= nil or not btn.Parent or not isShown(btn)
				end
				-- Waits up to `sec` for done() to be true.
				local function waitDone(sec)
					local t0 = os.clock()
					while active(id) and os.clock() - t0 < sec and not done() do task.wait(0.1) end
					return done()
				end
				sleep(id, 0.6)   -- let the popup finish animating in: a click during the animation can be ignored
				local methods = {
					{ "MouseButton1Click connections", function() return fireConnections(btn, "MouseButton1Click") end },
					{ "Activated connections",         function() return fireConnections(btn, "Activated") end },
					{ "MouseButton1Down connections",  function() return fireConnections(btn, "MouseButton1Down") end },
					{ "firesignal",                    function()
						if type(firesignal) ~= "function" or not btn:IsA("GuiButton") then return false end
						local ok1 = pcall(firesignal, btn.MouseButton1Click)
						local ok2 = pcall(firesignal, btn.Activated)
						return ok1 or ok2
					end },
					{ "InputBegan/InputEnded connections", function() return fireInput(playContainer or btn) end },
					{ "select + Enter key",            function() return selectAndEnter(btn) end },
					{ "real mouse click",              function() return clickCenter(playContainer or btn) end },   -- keep the hub minimized so it is not in the way
				}
				for _, m in ipairs(methods) do
					if not active(id) then return false end
					local res = m[2]()
					print("[PetDefense] press method '" .. m[1] .. "' -> " .. tostring(res))
					if res then
						if waitDone(3) then
							print("[PetDefense] Play worked with: " .. m[1])
							return true
						end
					end
				end
				return waitDone(2)
			end

			-- ---- the loop
			local function loop(id)
				while active(id) do
					do   -- still on cooldown: wait here (no trip held, no travelling) and show when it is available again
						local cd = exactCooldownLeft()
						if cd and cd > 1 then
							print("[PetDefense] on cooldown: " .. fmtT(cd) .. " left")
							while active(id) do
								cd = exactCooldownLeft()
								if not cd or cd <= 0 then break end
								say(string.format("On cooldown | next Pet Defense in %s", fmtT(math.ceil(cd))))
								sleep(id, 1)
							end
							if not active(id) then return end
						end
					end
					say("Waiting for its turn (another feature is on a trip)...")
					if not acquireTrip("PetDefense", function() return active(id) end, say) then return end
					local started = false
					local ok, err = pcall(function()
						say("Traveling to " .. ISLAND .. "...")
						if not HG.travelAndTeleport(function() return active(id) end, ISLAND, SPOT, say, 100) then
							say("Could not reach the start spot - retrying")
							return
						end
                        -- the popup search only starts once the character is really standing on the start spot
                        do
                            local a0, lastTp = os.clock(), 0
                            while active(id) and not isNear(SPOT, 12) and os.clock() - a0 < 15 do
                                if os.clock() - lastTp >= 1.5 then
                                    lastTp = os.clock()
                                    say("Moving to the Colosseum spot...")
                                    teleportTo(SPOT)
                                end
                                task.wait(0.2)
                            end
                            if not active(id) then return end
                            if not isNear(SPOT, 12) then
                                say("Not at Colosseum CFrame - retrying")
                                return
                            end
                        end
						pd.over, pd.claimed, pd.wave, pd.spawned, pd.logN = nil, false, 1, 0, 0
						pd.waveStarted = false
						pd.run = true
						pd.fight = false   -- screen presses only start after Play was pressed (they would hit the popup otherwise)
						say("Waiting for the Pet Defense popup...")
						sleep(id, POPUP_DELAY)
						-- on the spot: look for the Play button now, then re-check every POPUP_RECHECK seconds (until POPUP_WAIT is over)
						local btn
						local w0 = os.clock()
						local checks = 0
						while active(id) and not btn and os.clock() - w0 < POPUP_WAIT do
							if not isNear(SPOT, 12) then
								-- left the spot: go back and restart, the wait only counts while standing on the spot
								say("Not on the Colosseum spot - going back...")
								teleportTo(SPOT)
								sleep(id, 1)
								w0, checks = os.clock(), 0
							else
								checks = checks + 1
								lastIntroScan = 0   -- force a fresh scan on every check
								btn = findPlayButton()
								if btn then break end
								local nextAt = os.clock() + POPUP_RECHECK
								while active(id) and os.clock() < nextAt and os.clock() - w0 < POPUP_WAIT and isNear(SPOT, 12) do
									say(string.format("Play button not found (check %d) - checking again in %ds", checks, math.max(0, math.ceil(nextAt - os.clock()))))
									task.wait(0.5)
								end
							end
						end
						if not btn then
							pd.run = false
							if active(id) then say("Pet Defense popup did not appear (cooldown?) - retrying in " .. RETRY_WAIT .. " s") end
							return
						end
						say('Pressing "Play"...')
						if not pressPlay(id, btn) then
							pd.run = false
							if active(id) then say('Could not press "Play" - retrying in ' .. RETRY_WAIT .. " s") end
							return
						end
						pd.fight = true
						local t0 = os.clock()
						while active(id) and pd.spawned == 0 and not pd.over and os.clock() - t0 < START_WAIT do task.wait(0.1) end
						if pd.spawned == 0 and not pd.over then
							pd.run = false
							say("No opponent appeared after starting (cooldown?) - retrying in " .. RETRY_WAIT .. " s")
							return
						end
						started = true
						-- battle started: 2 s later go to the center of the arena (easier to hit the enemies)
						sleep(id, ARENA_CENTER_DELAY)
						if active(id) and not pd.over then
							local hrpC = getHRP()
							if hrpC then pcall(function() hrpC.CFrame = ARENA_CENTER end) end
						end
                        -- No wave cap, time cap, or intentional EndWaveDefense.
                        -- The server ends the run naturally when all hearts are lost.
						while active(id) and not pd.over do
							say(string.format("Fighting | wave %d | opponents spawned %d | runs finished %d", pd.wave, pd.spawned, pd.done))
							task.wait(1)
						end
                        if pd.over then
                            pd.run = false
                            pd.done = pd.done + 1
                            local replace = decide(pd.over)
                            local rewardClaimed = false
                            if replace ~= nil then
                                say("Natural game over | " .. (replace and "Replacing" or "Keeping") .. " ring")
                                for attempt = 1, 3 do
                                    if not active(id) then break end
                                    local called = claim(replace)
                                    local c0 = os.clock()
                                    while active(id) and not pd.claimed and pendingRelic() and os.clock()-c0 < 6 do task.wait(0.2) end
                                    if pd.claimed or (called and not pendingRelic()) then rewardClaimed = true break end
                                    sleep(id, 1)
                                end
                            elseif not pendingRelic() then
                                rewardClaimed = true
                            end
                            if rewardClaimed then
                                say("Ring handled | returning from arena...")
                                if not returnFromArena() then
                                    say("ReturnFromArena not confirmed; check F9")
                                end
                            else
                                say("Reward claim not confirmed | keeping priority")
                                -- Do not start a new battle while the reward is pending.
                                while active(id) and pendingRelic() do
                                    local retryDecision = decide(pd.over)
                                    if retryDecision ~= nil then claim(retryDecision) end
                                    sleep(id, 5)
                                end
                                if active(id) then returnFromArena() end
                            end
                        end
					end)
					pd.run = false
					releaseTrip("PetDefense")
					if not ok then warn("[PetDefense] error: " .. tostring(err)) end
					if active(id) then
						local left, key = cooldownLeft()
						if left and left > 1 then
							print(string.format("[PetDefense] cooldown read from '%s': %s", tostring(key), fmtT(left)))
							while active(id) do
								left = cooldownLeft()
								if not left or left <= 0 then break end
								say(string.format("On cooldown | next Pet Defense in %s", fmtT(math.ceil(left))))
								sleep(id, 1)
							end
						else
							if not started then dumpColosseum() end
							sleep(id, started and 3 or RETRY_WAIT)
						end
					end
				end
			end

			toggle.callback = function(on)
				if not alive then return end
				runId = runId + 1
				if on == true then
					local popupRun = runId
					task.spawn(function()
						while active(popupRun) do
							pcall(clearBlur)
							task.wait(0.35)
						end
					end)
					task.spawn(loop, runId)
				else
					pd.run = false
					releaseTrip("PetDefense")
					restoreDof()
					say(DESC)
				end
			end

			infoEntry.run = function()
				local data = gameData()
				print("[PetDefense] ---- Colosseum remotes ----")
				for _, folder in ipairs({ "RF", "RE" }) do
					local f = svc:FindFirstChild(folder)
					if f then for _, r in ipairs(f:GetChildren()) do print("  " .. folder .. "." .. r.Name .. " (" .. r.ClassName .. ")") end end
				end
				local cur = currentRelic()
				print("[PetDefense] ---- current ring (searched in your data) ----")
				print(cur and relicText(cur) or "NOT FOUND")
				print("[PetDefense] ---- data entries with 'relic' / 'colos' in the key ----")
				local n, seen = 0, {}
				-- Debug: turns a value into text (tables included).
				local function dumpT(v, depth)
					if type(v) ~= "table" then return tostring(v) end
					if depth > 3 then return "{...}" end
					local parts = {}
					for k, x in pairs(v) do
						parts[#parts + 1] = tostring(k) .. "=" .. dumpT(x, depth + 1)
						if #parts >= 14 then parts[#parts + 1] = "..." break end
					end
					return "{" .. table.concat(parts, ", ") .. "}"
				end
				-- Debug: walks a table (depth-limited).
				local function walkD(t, depth, path)
					if depth > 4 or seen[t] or n > 30 then return end
					seen[t] = true
					for k, v in pairs(t) do
						local kp = path .. "/" .. tostring(k)
						local lk = tostring(k):lower()
						if lk:find("relic", 1, true) or lk:find("colos", 1, true) or lk:find("ring", 1, true) then
							n = n + 1
							print("  " .. kp .. " = " .. dumpT(v, 1))
						elseif type(v) == "table" then
							walkD(v, depth + 1, kp)
						end
					end
				end
				if data then pcall(walkD, data, 1, "") else print("game data not available") end
			end
			table.insert(cleanupHooks, function() runId = runId + 1 pd.run = false end)

			return { toggle = toggle, mode = modeEntry, info = infoEntry }
		end)
		if okP then HG.petdef = resP else warn("[WORST Hub] Pet Defense failed to load: " .. tostring(resP)) end
	end

	-------------------------------------------------------------------------- EVENTS > DIG (Autumn)
	-- Auto Dig: Travel to Autumn, teleport to the dig spot, start the dig (DigService.RF.Begin = the call the game makes itself) and
	-- hit the timing bar the moment the cursor is inside the "DIG" zone (a miss only adds a shovel, the bot just keeps hitting).
	-- The game allows 10 digs per one-hour server window. Use Digging.Completed and Digging.WindowStart
	-- for account-specific cooldowns, releasing travel priority while waiting for a server reset.
	do
		local okD, resD = pcall(function()
			local ISLAND       = "Autumn"
			local SPOT         = CFrame.new(-78.41590118408203, 875.5673217773438, -1618.5010986328125, -0.6279863119125366, -5.2364654834491375e-08, -0.7782243490219116, 3.253542502079654e-08, 1, -9.354172902931168e-08, 0.7782243490219116, -8.406279050632293e-08, -0.6279863119125366)
			local LIMIT        = 10      -- digs the game allows per hour
			local WINDOW       = 3600    -- ... per this many seconds
			local SAFETY       = 5       -- extra seconds on top of the hour before counting a slot as free
			local OPEN_WAIT    = 8       -- seconds to wait for the dig to open after starting it
			local MAX_DIG      = 150     -- give up on one dig after this many seconds
			local NEXT_WAIT    = 2.5     -- after a dig: wait this long in case the game starts the next one by itself
			local PRESS_DELAY  = 0.5     -- seconds to wait after reaching the dig CFrame before pressing the screen to start the dig (was 1)
			local REFUSED_WAIT = 600     -- the game refused to start a dig (limit?): try again after this many seconds
			-- timing bar (the values that worked): click LEAD seconds early, only inside the middle part of the zone, at most once per COOLDOWN
			local LEAD, MARGIN, COOLDOWN = 0.04, 0.15, 0.35
			local ICON         = "🪏"    -- shovel (if your font shows a box, use "⛏")

			local RunService = game:GetService("RunService")
			local GuiService = game:GetService("GuiService")
			local VIM        = game:GetService("VirtualInputManager")

			local beginRF = find(RS, { "RemoteServices", "DigService", "RF", "Begin" })
			assert(beginRF, "DigService.RF.Begin not found")
			local writeEv = find(RS, { "ReplicaRemoteEvents", "Replica_ReplicaWrite" })
			assert(writeEv, "Replica_ReplicaWrite not found")

			local DESC = "Travels to Autumn, goes to the dig spot and digs, hitting the timing bar by itself (a miss just adds a shovel). The game allows 10 digs per hour: after the 10th it lets Hatch / Craft / Enchant work and comes back when a dig is free again. Keep the hub minimized (the keybind in Settings) while it digs, so the clicks reach the game."
			-- TOGGLE "Auto Dig": travels to Autumn, digs at the dig spot and hits the timing bar by itself (10 digs per hour).
			local toggle = { type = "toggle", name = "Auto Dig", icon = ICON, default = false, desc = DESC }

			local dOn, dRun = false, 0
			-- True while this Auto Dig run is still the current one.
			local function dActive(id) return alive and dOn and dRun == id end
			-- Sets the status text of Auto Dig.
			local function say(text) setDesc(toggle, text) end
			-- Waits `sec` while the run is active.
			local function dSleep(id, sec)
				local t0 = os.clock()
				while dActive(id) and os.clock() - t0 < sec do task.wait(0.1) end
			end
			-- Formats seconds as a time text.
			local function fmt(sec)
				sec = math.max(0, math.floor(sec))
				if sec >= 3600 then return string.format("%dh %02dm", math.floor(sec / 3600), math.floor((sec % 3600) / 60)) end
				if sec >= 60 then return string.format("%dm %02ds", math.floor(sec / 60), sec % 60) end
				return sec .. "s"
			end

			-- Hourly usage is authoritative in the server replica, not a local log.
			-- This works on accounts that exhausted digs before the hub was loaded.
			---------------------------------------------------------------- what the server says (Digging data writes)
			local pending, conn = false, nil
			local completionSerial = 0
			local rewardClearSerial = 0
			-- Reads your player data from the game.
			local function readData()
				local ok, data = pcall(function() return require(RS.Controllers.Core.DataController):GetReplica().Data end)
				return ok and type(data) == "table" and data or nil
			end
			-- Reads how many digs and shovels you have.
			local function digCounters()
				local data = readData()
				local d = data and data.Digging
				if type(d) ~= "table" then return nil, nil, false end
				return tonumber(d.Completed), tonumber(d.TotalCompleted), d.PendingReward ~= nil
			end
			-- Reads the current dig window (when the next dig is free).
			local function digWindow()
				local data = readData()
				local d = data and data.Digging
				if type(d) ~= "table" then return nil, nil end
				local completed, windowStart = tonumber(d.Completed), tonumber(d.WindowStart)
				-- The server only rewrites Completed when the next dig starts, so the replica keeps saying 10/10 after the hour is
				-- over. A full counter whose window has ended is really 0: without this the bot waited for a reset that never comes.
				if completed and completed >= LIMIT and windowStart and windowStart > 0 then
					local okT, now = pcall(function() return workspace:GetServerTimeNow() end)
					if not okT then now = os.time() end
					if now >= windowStart + WINDOW + SAFETY then completed = 0 end
				end
				return completed, windowStart
			end
			-- Current server time.
			local function serverNow()
				local ok, now = pcall(function() return workspace:GetServerTimeNow() end)
				return ok and now or os.time()
			end

			-- Reads data changes the server sends (used to follow the dig counters).
			local function onWrite(...)
				local writes = ({ ... })[3]
				if type(writes) ~= "table" then return end
				for _, w in ipairs(writes) do
					local path = type(w) == "table" and w[1]
					if type(path) == "table" and path[1] == "Digging" then
						if path[2] == nil and type(w[2]) == "table" then
							local v = w[2]
							if type(v.S) == "table" then
								if v.S.PendingReward ~= nil then pending = true end
								if v.S.Completed ~= nil or v.S.TotalCompleted ~= nil then
									completionSerial = completionSerial + 1
								end
							end
							if type(v.D) == "table" and table.find(v.D, "PendingReward") then pending = false; rewardClearSerial = rewardClearSerial + 1 end
						elseif path[2] == "Completed" or path[2] == "TotalCompleted" then
							completionSerial = completionSerial + 1
						elseif path[2] == "PendingReward" then
							pending = w[2] ~= nil
						end
					end
				end
			end
			-- Starts listening to data changes.
			local function ensureListener()
				if conn then return end
				conn = writeEv.OnClientEvent:Connect(onWrite)
				local _, _, hasReward = digCounters()
				pending = hasReward
			end
			-- Stops listening to data changes.
			local function dropListener()
				if conn then pcall(function() conn:Disconnect() end) conn = nil end
			end

			-- Returns the dig minigame GUI.
			local function mgGui()
				local p = pg()
				return p and p:FindFirstChild("DigMinigame")
			end
			-- True if the dig minigame is open.
			local function mgOpen()
				local g = mgGui()
				local m = g and g:FindFirstChild("Main")
				return g ~= nil and g.Enabled == true and m ~= nil and m.Visible == true
			end


			-- The reward overlay remains visible after the server clears PendingReward.
			-- Detect it by visible text and dismiss it before the next dig-start tap.
			-- Only ENABLED ScreenGuis are searched (a disabled one cannot show a popup) and never the hub's own UI; the walk yields every
			-- few hundred objects so it can no longer freeze a frame (it used to scan the whole PlayerGui in one go, 10x a second).
			local function rewardVisible()
				local playerGui = pg()
				if not playerGui then return false end
				local n = 0
				for _, sg in ipairs(playerGui:GetChildren()) do
					if sg:IsA("ScreenGui") and sg.Enabled and sg ~= gui then
						for _, obj in ipairs(sg:GetDescendants()) do
							n = n + 1
							if n % 300 == 0 then task.wait() end
							if obj.Parent and (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
								local label = obj.Text
								if label ~= "" then
									label = label:lower()
									if label:find("click anywhere to close", 1, true) or label:find("you found", 1, true) then
										local visible, ancestor = true, obj.Parent
										while visible and ancestor and ancestor ~= sg do
											if ancestor:IsA("GuiObject") and not ancestor.Visible then visible = false end
											ancestor = ancestor.Parent
										end
										if visible then return true end
									end
								end
							end
						end
					end
				end
				return false
			end
			-- Taps the screen to dismiss the reward.
			local function rewardTap()
				local cam = workspace.CurrentCamera
				if not cam then return false end
				local sz = cam.ViewportSize
				local x, y = math.floor(sz.X / 2), math.floor(sz.Y / 2)
				local ok, err = pcall(function()
					VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
					task.wait(0.1)
					VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
				end)
				if not ok then warn("[Dig] Reward tap failed: " .. tostring(err)) end
				return ok
			end
			-- Closes the dig reward screen.
			local function dismissReward(id, waitForAppearance)
				if waitForAppearance then
					local deadline = os.clock() + 3
					while dActive(id) and os.clock() < deadline and not rewardVisible() do task.wait(0.25) end
				end
				if not dActive(id) then return false end
				if not rewardVisible() then return true end
				for attempt = 1, 3 do
					if not dActive(id) then return false end
					say("Closing dig reward popup (" .. attempt .. "/3)")
					if not rewardTap() then return false end
					dSleep(id, 0.35)
					if not rewardVisible() then
						dSleep(id, 0.35)
						return dActive(id)
					end
				end
				say("Reward popup still open | stopping batch")
				return false
			end

			---------------------------------------------------------------- the timing bar bot
			local botConn
			-- Starts the bot that hits the dig timing bar.
			local function startBot()
				if botConn then return end
				local lastClick, lastX, lastT = 0, nil, nil
				botConn = RunService.RenderStepped:Connect(function()
					local gui = mgGui()
					local main = gui and gui:FindFirstChild("Main")
					local cursor = main and main:FindFirstChild("Cursor")
					local cg = main and main:FindFirstChild("CanvasGroup")
					local hit = cg and cg:FindFirstChild("Hit")
					local crit = hit and hit:FindFirstChild("Critical")
					if not (gui and gui.Enabled and main and main.Visible and cursor and crit) then
						lastX = nil
						return
					end
					local now = os.clock()
					local x = cursor.AbsolutePosition.X + cursor.AbsoluteSize.X / 2
					local v = 0
					if lastX and now > lastT then v = (x - lastX) / (now - lastT) end
					lastX, lastT = x, now
					local predicted = x + v * LEAD
					local w = crit.AbsoluteSize.X
					local left  = crit.AbsolutePosition.X + w * MARGIN
					local right = crit.AbsolutePosition.X + w * (1 - MARGIN)
					if predicted >= left and predicted <= right and now - lastClick > COOLDOWN then
						lastClick = now
						local cx = main.AbsolutePosition.X + main.AbsoluteSize.X / 2
						local cy = main.AbsolutePosition.Y + main.AbsoluteSize.Y / 2
						if not gui.IgnoreGuiInset then cy = cy + GuiService:GetGuiInset().Y end
						pcall(function()
							VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
							VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
						end)
					end
				end)
			end
			-- Stops the dig timing bot.
			local function stopBot()
				if botConn then pcall(function() botConn:Disconnect() end) botConn = nil end
			end

			-- the Lite window caps the FPS at 5, far too low to time the bar: lift the cap while a dig is running
			local boosted = false
			-- Lowers or restores the FPS cap while digging (the timing bar needs a smooth game).
			local function boost(on)
				local capFn = Config.fpsFn()
				if not capFn then return end
				if on then
					local f = Config.fps
					if f.lite or (f.touched and f.user > 0 and f.user < 60) then
						pcall(capFn, 60)
						boosted = true
					end
				elseif boosted then
					boosted = false
					Config.applyFps()
				end
			end

			---------------------------------------------------------------- wait for the server's actual dig window
			local function waitForSlot(id)
				while dActive(id) do
					local completed, windowStart = digWindow()
					if completed == nil then
						say("Waiting for server Digging data...")
					elseif completed < LIMIT then
						return true
					elseif windowStart and windowStart > 0 then
						local remaining = math.max(0, windowStart + WINDOW - serverNow())
						if remaining > 0 then
							say(string.format("Auto Dig | %d/%d | Next digs in %s", completed, LIMIT, fmt(math.ceil(remaining))))
						else
							say(string.format("Auto Dig | %d/%d | Waiting for server reset...", completed, LIMIT))
						end
					else
						say("Dig limit reached | waiting for reset data")
					end
					dSleep(id, 1)
				end
				return false
			end

			---------------------------------------------------------------- one visit to the dig spot
			-- One priority reservation covers the ENTIRE batch, not one dig.
			-- Only a higher-priority feature can take over, and only between digs.
			local function session(id)
				-- Wait OUTSIDE the travel reservation so other features remain free.
				if not waitForSlot(id) then return end
			say("Waiting for Dig priority...")
				if not acquireTrip("Dig", function() return dActive(id) end, say) then return end

				local waitAfter = nil
				local ok, err = pcall(function()
					say("Traveling to Autumn for dig batch...")
					if not HG.travelAndTeleport(function() return dActive(id) end, ISLAND, SPOT, say, 100) then
						waitAfter = 15
						say("Could not reach dig spot - retrying")
						return
					end
					while dActive(id) do
						local used = digWindow()
						if used == nil or used >= LIMIT then
							say(used and "Dig limit reached | releasing priority" or "Dig data unavailable | releasing priority")
							break
						end
						-- Check for higher priorities ONLY between digs. Lower ones
						-- cannot interrupt because Dig still owns the trip.
						if HG.higher(HG.prio("Dig")) then
							say("Higher-priority feature waiting | pausing between digs")
							break
						end

						-- Same arrival check and initial screen press as the
						-- successful standalone Auto Dig test.
						local arrived = false
						for attempt = 1, 3 do
							if not dActive(id) then break end
							local ch = lp.Character
							if ch then pcall(function() ch:PivotTo(SPOT) end) else teleportTo(SPOT) end
							local deadline = os.clock() + 2.5
							repeat
								if not dActive(id) then break end
								if isNear(SPOT, 8) then arrived = true break end
								task.wait(0.1)
							until os.clock() >= deadline
							if arrived then break end
						end
						if not arrived then
							say("Dig CFrame arrival not confirmed | retrying")
							waitAfter = 10
							break
						end
						boost(true)   -- no FPS cap while pressing / digging (released when the visit ends)
						say(string.format("At Dig CFrame | pressing in %gs...", PRESS_DELAY))
						dSleep(id, PRESS_DELAY)   -- press the screen PRESS_DELAY seconds after reaching the CFrame
						if not dActive(id) then break end

						-- Snapshot the server's counters BEFORE starting. Shovel hits do not count as digs.
						local beforeCompleted, beforeTotal, beforePending = digCounters()
						local beforeSerial = completionSerial
						local beforeRewardClear = rewardClearSerial
						-- A reward left over from the previous dig blocks the next screen tap.
						if not dismissReward(id, false) then
							waitAfter = 10
							break
						end
						-- Use the original physical screen press to enter the minigame.
						-- Do NOT invoke DigService.RF.Begin directly: it can advance
						-- server state without actually opening the playable UI.
						local started = false
						for tapAttempt = 1, 3 do
							if not dActive(id) then break end
							if mgOpen() then started = true break end
							say(string.format("At Dig CFrame | pressing to start (%d/3)...", tapAttempt))
							local cam = workspace.CurrentCamera
							if cam then
								local sz = cam.ViewportSize
								local x, y = math.floor(sz.X/2), math.floor(sz.Y/2)
								local tapOK, tapErr = pcall(function()
									VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
									task.wait(0.1)
									VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
								end)
								if not tapOK then warn("[Dig] Tap failed: " .. tostring(tapErr)) end
							end
							local openDeadline = os.clock() + 2.5
							while dActive(id) and os.clock() < openDeadline do
								if mgOpen() then started = true break end
								task.wait(0.1)
							end
							if started then break end
						end
						if not started then
							say("Dig UI did not open after screen presses | retrying")
							waitAfter = 10
							break
						end
						-- Server counters, not local screen taps, determine dig usage.
						say(string.format("Digging (%d/%d this hour) | waiting for server completion", math.min((select(1, digWindow()) or 0),LIMIT),LIMIT))
						local deadline = os.clock() + MAX_DIG
						local confirmed = false
						local rewardCleared = false
						while dActive(id) and os.clock() < deadline do
							local currentCompleted, currentTotal, currentPending = digCounters()
							local progressed = (beforeTotal ~= nil and currentTotal ~= nil and currentTotal > beforeTotal)
								or (beforeCompleted ~= nil and currentCompleted ~= nil and currentCompleted > beforeCompleted)
							if progressed then confirmed = true break end
							-- GUI visibility is NOT completion: it may blink between shovel hits.
							task.wait(0.15)
						end

						if not dActive(id) then break end
						if not confirmed then
							say("No server-confirmed dig completion | stopping batch to avoid double-start")
							waitAfter = 30
							break
						end
						say(string.format("Dig finished (%d/%d this hour) | server confirmed", math.min((select(1, digWindow()) or 0),LIMIT),LIMIT))
						if not dismissReward(id, true) then
							waitAfter = 10
							break
						end
						dSleep(id, NEXT_WAIT)
					end
				end)
				boost(false)
				releaseTrip("Dig")
				if not ok then error(err, 0) end
				if waitAfter then
					local resumeAt = os.time() + waitAfter
					while dActive(id) and os.time() < resumeAt do
						say("Dig retry in " .. fmt(resumeAt-os.time()))
						dSleep(id, 1)
					end
				end
			end

			local START_GRACE = 8   -- after being switched on, give the other events this long to queue for the trip first (they rank higher)
			-- Main loop of Auto Dig.
			local function run(id)
				say("Starting - letting the higher priority events queue first...")
				dSleep(id, START_GRACE)
				while dActive(id) do
					local ok, err = pcall(session, id)
					if not ok then
						warn("[Dig] error: " .. tostring(err))
						say("Error - trying again in a few seconds (see output)")
						dSleep(id, 5)
					end
				end
			end

			toggle.callback = function(on)
				if not alive then return end
				dRun = dRun + 1
				dOn = on == true
				if dOn then
					ensureListener()
					startBot()
					say("Starting...")
					task.spawn(run, dRun)
				else
					stopBot()
					dropListener()
					boost(false)
					releaseTrip("Dig")
					say(DESC)
				end
			end

			table.insert(cleanupHooks, function()
				dOn = false
				dRun = dRun + 1
				stopBot()
				dropListener()
				boost(false)
			end)

			return { toggle = toggle }
		end)
		if okD then HG.dig = resD else warn("[WORST Hub] Auto Dig failed to load: " .. tostring(resD)) end
	end

	-------------------------------------------------------------------------- EVENTS > BALLOONS (Balloon Party)
	-- Auto Balloons: the game tells every player about each balloon with BalloonPartyService.RE.Launched (id, launch position, how many hits it
	-- needs, size, coins / gems). This feature keeps that list, and for every balloon that is still alive it teleports to the balloon (the real
	-- object in the workspace when it can find one, otherwise the launch position), sends the hits the way the game does
	-- (BalloonPartyService.RE.Hit, plus the normal tap if the server needs it), waits for the server's answer and moves on to the next
	-- balloon, biggest first. When none are left it teleports you back to where you were and gives the trip back to the other features.
	-- Its place in the order is the "Balloon" row of the Priority tab (default: first - balloons do not last long).
	do
		local okB, resB = pcall(function()
			local MAX_AGE    = 30     -- balloons launched more than this many seconds ago are ignored (guess - raise it if they live longer)
			local HIT_GAP    = 0.2    -- seconds between two teleport + hit rounds: it re-teleports to the balloon every 0.2 s so it sticks to it
			local MAX_RADIUS = 500    -- only balloons within this many studs of you are used; further ones are ignored
			local ACK_WAIT   = 0.7    -- seconds to wait for the server to answer a hit
			local NO_ACK_MAX = 8      -- this many hits in a row without an answer: the balloon is gone or out of reach, skip it
			local EXTRA_HITS = 10     -- never send more than needed + this many hits to one balloon
			local ICON       = "🎈"
			local SIZE_RANK  = { Golden = 4, Big = 3, Medium = 2, Small = 1 }
			local TAGS       = { "Balloon", "Balloons", "PartyBalloon", "BalloonPartyBalloon" }

			local CollectionService = game:GetService("CollectionService")

			local svc = find(RS, { "RemoteServices", "BalloonPartyService" })
			assert(svc, "BalloonPartyService not found - is the balloon event in this game version?")
			local hitRE      = find(svc, { "RE", "Hit" })
			local launchedRE = find(svc, { "RE", "Launched" })
			local poppedRE   = find(svc, { "RE", "Popped" })
			local rewardedRE = find(svc, { "RE", "Rewarded" })
			assert(hitRE and launchedRE, "BalloonPartyService.RE.Hit / Launched not found")
			local tapRE = find(RS, { "RemoteServices", "TapService", "RE", "TapRequested" })

			local DESC = "Teleports to the balloon closest to you (balloons further than 500 studs away are ignored) and pops it, re-teleporting to it every 0.2 s so you stay on it, then goes back to where you were. The balloon list comes from the game's own launch messages, so it only knows balloons launched after you switch it on."
			-- TOGGLE "Auto Balloons": teleports to the closest balloon within 500 studs, every 0.2 s, and pops it; then goes back home.
			local toggle = { type = "toggle", name = "Auto Balloons", icon = ICON, default = false, desc = DESC }

			local bOn, bRun = false, 0
			-- True while this Auto Balloons run is still the current one.
			local function bActive(id) return alive and bOn and bRun == id end
			-- Sets the status text of Auto Balloons.
			local function say(text) setDesc(toggle, text) end
			-- Current server time.
			local function serverNow() return workspace:GetServerTimeNow() end
			-- Formats a big number in short form.
			local function sci(n) return type(n) == "number" and string.format("%.2e", n) or "?" end

			local balloons = {}   -- uid -> { uid, origin, hits, taken, size, launchedAt, coins, gems, bad, done, lastAck, inst }
			local stats = { popped = 0, gems = 0, coins = 0, failed = 0 }
			local useTap = false  -- switched on by itself when hits alone get no answer from the server
			local conns = {}
			-- Connects a server event and keeps the connection.
			local function listen(re, fn)
				if re then conns[#conns + 1] = re.OnClientEvent:Connect(fn) end
			end
			-- Disconnects every balloon listener.
			local function dropListeners()
				for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
				conns = {}
			end

			-- Connects the listeners for balloon launched / hit / popped / rewarded.
			local function ensureListeners()
				if #conns > 0 then return end
				listen(launchedRE, function(d)
					if type(d) ~= "table" or type(d.Uid) ~= "string" or typeof(d.Origin) ~= "Vector3" then return end
					balloons[d.Uid] = {
						uid = d.Uid, origin = d.Origin, hits = tonumber(d.Hits) or 1, taken = tonumber(d.Taken) or 0,
						size = tostring(d.Size), launchedAt = tonumber(d.LaunchedAt) or serverNow(),
						coins = d.Coins == true, gems = d.Gems == true, bad = false, done = false,
					}
				end)
				listen(hitRE, function(uid, count)   -- the server answers every hit (also other players' hits) with the hit count so far
					local b = type(uid) == "string" and balloons[uid]
					if not b then return end
					b.lastAck = os.clock()
					if type(count) == "number" and count > b.taken then b.taken = count end
				end)
				listen(poppedRE, function(uid)
					if type(uid) == "string" then balloons[uid] = nil end
				end)
				listen(rewardedRE, function(uid, r)
					if type(r) ~= "table" then return end
					stats.popped = stats.popped + 1
					stats.gems = stats.gems + (tonumber(r.Gems) or 0)
					stats.coins = stats.coins + (tonumber(r.Coins) or 0)
				end)
			end

			-- one-time look at what the workspace holds with "balloon" in the name (printed so the balloon objects can be identified)
			local scanned = false
			-- Looks once through the workspace for balloon objects (prints what it finds).
			local function scanWorkspace()
				if scanned then return end
				scanned = true
				task.spawn(function()
					local found, n = {}, 0
					for _, d in ipairs(workspace:GetDescendants()) do
						n = n + 1
						if n % 3000 == 0 then task.wait() end
						if #found < 10 and d.Name:lower():find("balloon", 1, true) then
							found[#found + 1] = d:GetFullName() .. " (" .. d.ClassName .. ")"
						end
					end
					print("[Balloons] workspace objects with 'balloon' in the name: " .. (#found > 0 and ("\n  " .. table.concat(found, "\n  ")) or "none"))
				end)
			end

			---------------------------------------------------------------- where is the balloon
			local loggedFound, loggedMissing = false, false
			-- Finds the balloon object in the workspace.
			local function findInstance(b)
				if b.inst and b.inst.Parent then return b.inst end
				b.inst = nil
				if os.clock() - (b.lastLookup or -1) < 0.4 then return nil end
				b.lastLookup = os.clock()
				local inst = workspace:FindFirstChild(b.uid, true)   -- the object is probably named after the balloon id
				if not inst then
					for _, tag in ipairs(TAGS) do
						for _, t in ipairs(CollectionService:GetTagged(tag)) do
							if t.Name == b.uid or t:GetAttribute("Uid") == b.uid or t:GetAttribute("Id") == b.uid then inst = t break end
						end
						if inst then break end
					end
				end
				if inst then
					b.inst = inst
					if not loggedFound then
						loggedFound = true
						print("[Balloons] balloon object found: " .. inst:GetFullName() .. " (" .. inst.ClassName .. ")")
					end
				end
				return inst
			end
			-- Returns the current position of a balloon (its object, or the launch position).
			local function positionOf(b)
				local inst = findInstance(b)
				if inst then
					if inst:IsA("BasePart") then return inst.Position, true end
					if inst:IsA("Model") then
						local ok, cf = pcall(function() return inst:GetPivot() end)
						if ok then return cf.Position, true end
					end
					local p = inst:FindFirstChildWhichIsA("BasePart", true)
					if p then return p.Position, true end
				end
				if not loggedMissing then
					loggedMissing = true
					print("[Balloons] no balloon object found in the workspace - using the launch position (see the 'balloon' list above)")
				end
				return b.origin, false
			end

			---------------------------------------------------------------- picking and popping
			local function eligible(b)
				if b.bad or b.done then return false end
				if serverNow() - b.launchedAt > MAX_AGE then return false end
				return b.hits - b.taken >= 1
			end
			-- Picks the closest balloon within the radius (MAX_RADIUS); balloons further away are ignored.
			local function pickBest()
				local best, bestDist
				local hrp = getHRP()
				local me = hrp and hrp.Position
				for uid, b in pairs(balloons) do
					if serverNow() - b.launchedAt > MAX_AGE + 10 then
						balloons[uid] = nil   -- long gone: forget it
					elseif me and eligible(b) then
						local pos = positionOf(b)
						local dist = (pos - me).Magnitude
						if dist <= MAX_RADIUS and (not bestDist or dist < bestDist) then best, bestDist = b, dist end   -- closest balloon inside the radius, the rest is ignored
					end
				end
				return best
			end
			-- Counts the balloons that can still be popped.
			local function waiting()
				local n = 0
				for _, b in pairs(balloons) do if eligible(b) then n = n + 1 end end
				return n
			end
			-- Builds the text with popped balloons and gems / coins.
			local function summary()
				return string.format("popped %d | gems +%s | coins +%s", stats.popped, sci(stats.gems), sci(stats.coins))
			end

			-- Sends one hit (and the tap when needed) for a balloon.
			local function fire(uid)
				if useTap and tapRE then
					env.WORSTTapSequence = (tonumber(env.WORSTTapSequence) or 811) + 1
					pcall(function() tapRE:FireServer({ ClientSequence = env.WORSTTapSequence, Auto = false, Source = "screen" }) end)
				end
				pcall(function() hitRE:FireServer(uid) end)
			end

			-- Pops one balloon: teleports to it and hits it every HIT_GAP seconds.
			local function pop(id, b)
				local need = math.max(1, b.hits - b.taken)
				local sent, noAck = 0, 0
				while bActive(id) and balloons[b.uid] == b and not b.bad and sent < need + EXTRA_HITS do
					local pos = positionOf(b)
					teleportTo(CFrame.new(pos))   -- every round (0.2 s): the balloon moves, this keeps you on it
					say(string.format("%s balloon: hit %d/%d | %s", b.size, math.min(b.taken + 1, b.hits), b.hits, summary()))
					local before = b.lastAck
					fire(b.uid)
					sent = sent + 1
					task.wait(HIT_GAP)
					if balloons[b.uid] ~= b then break end   -- popped
					if b.lastAck == before then
						noAck = noAck + 1
						if noAck == 3 and not useTap and tapRE then
							useTap = true   -- hits alone get no answer: send the normal tap together with the hit, like the game does
							print("[Balloons] no answer to the hits alone - sending the tap together with each hit now")
						elseif noAck >= NO_ACK_MAX then
							b.bad = true
							stats.failed = stats.failed + 1
							warn(string.format("[Balloons] %s balloon %s: the server never answered - skipped", b.size, b.uid:sub(1, 8)))
						end
					else
						noAck = 0
					end
				end
				if balloons[b.uid] == b and sent >= need then b.done = true end   -- sent everything it needs: do not come back to it
			end

			-- One trip: pops balloons one after another, then goes back home.
			local function session(id)
				say("Balloons found - waiting for its turn...")
				if not acquireTrip("Balloon", function() return bActive(id) end, say) then return end
				local hrp = getHRP()
				local home = hrp and hrp.CFrame
				local ok, err = pcall(function()
					while bActive(id) do
						if HG.higher(HG.prio("Balloon")) then break end   -- something ranked above Balloons is waiting: hand over
						local b = pickBest()
						if not b then break end
						pop(id, b)
					end
				end)
				if home and getHRP() then teleportTo(home) end
				releaseTrip("Balloon")
				if not ok then error(err, 0) end
			end

			-- Main loop of Auto Balloons.
			local function run(id)
				while bActive(id) do
					if pickBest() then
						local ok, err = pcall(session, id)
						if not ok then
							warn("[Balloons] error: " .. tostring(err))
							say("Error - trying again in a few seconds (see output)")
							local t0 = os.clock()
							while bActive(id) and os.clock() - t0 < 5 do task.wait(0.1) end
						end
					else
						say(string.format("Waiting for balloons | %s", summary()))
						task.wait(0.25)
					end
				end
			end

			toggle.callback = function(on)
				if not alive then return end
				bRun = bRun + 1
				bOn = on == true
				if bOn then
					ensureListeners()
					scanWorkspace()
					say("Waiting for balloons...")
					task.spawn(run, bRun)
				else
					dropListeners()
					balloons = {}
					releaseTrip("Balloon")
					say(DESC)
				end
			end

			table.insert(cleanupHooks, function()
				bOn = false
				bRun = bRun + 1
				dropListeners()
			end)

			return { toggle = toggle }
		end)
		if okB then HG.balloon = resB else warn("[WORST Hub] Auto Balloons failed to load: " .. tostring(resB)) end
	end

	return {
		halloween = HG.halloween,
		petdef = HG.petdef,
		dig = HG.dig,
		balloon = HG.balloon,
		islands = islandTools,
		priority = HG, kaitun = HG.kaitun,
		egg = eggEntry, hatch = hatchEntry, scan = scanEntry, storage = storageEntry, drop = dropEntry, craft = craftEntry, craftAll = craftAllEntry,
		dDrop = pet.dDrop, dAmount = pet.dAmount, dCraft = pet.dCraft, goldenAmount = goldenAmountEntry, rDrop = pet.rDrop, rAmount = pet.rAmount, rCraft = pet.rCraft, collect = pet.collect,
		enchant = ench, autodel = autodel,
		hatchCount = function()   -- total hatches the game shows (nil if unreadable), hatches counted by this script since it started
			local ok, v = pcall(HA.readHatches)
			return (ok and tonumber(v)) or nil, hatched
		end,
		-- used by Settings > Reset Script: put back everything the hatch-animation hiding changed and forget the Auto 8x result
		reset = function()
			pcall(function()
				if HA.resetAuto then HA.resetAuto() end
				if HA_auto then HA_auto.nextProbe, HA_auto.ok8 = 0, false end
			end)
		end,
	}
end

local okLogic, Logic = pcall(buildLogic)
if not okLogic then
	warn("[WORST Hub] Hatch/Craft logic failed to load: " .. tostring(Logic))
	Logic = nil
end

-- Anti AFK + Auto Rejoin (Settings tab). One table so no extra top-level locals are used.
local Utility = (function()
	local TeleportService = game:GetService("TeleportService")
	local CoreGui = game:GetService("CoreGui")
	local U = {}

	-- ===== Anti AFK =====
	local afkConn, disabledConns = nil, {}
	-- Anti AFK: switches it on or off.
	function U.antiAfk(on)
		if on then
			if afkConn then return end
			local GC = getconnections or get_signal_cons
			if GC then
				pcall(function()
					for _, v in pairs(GC(player.Idled)) do
						if v["Disable"] then
							pcall(v["Disable"], v)
							table.insert(disabledConns, v)
						elseif v["Disconnect"] then
							pcall(v["Disconnect"], v)
						end
					end
				end)
			end
			-- backup: if an idle kick still fires, answer it with a fake right click
			afkConn = player.Idled:Connect(function()
				local vu = game:FindService("VirtualUser") or game:GetService("VirtualUser")
				vu:CaptureController()
				vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
				task.wait(1)
				vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
			end)
		else
			if afkConn then afkConn:Disconnect() afkConn = nil end
			for _, v in ipairs(disabledConns) do
				if v["Enable"] then pcall(v["Enable"], v) end
			end
			disabledConns = {}
		end
	end

	-- ===== Auto Click =====
	-- Uses VirtualUser (it does NOT move your real mouse or touch the hub's buttons, unlike VirtualInputManager).
	-- It also stops clicking while you are holding the left mouse button, so you can always press buttons / drag the hub.
	-- Roblox only reads input once per frame, so 0.1 ms between clicks isn't possible; CLICK_INTERVAL is the real gap.
	local CLICK_INTERVAL = 0.05 -- seconds between clicks (0 = every frame). Raise it if the game lags or kicks you.
	local CLICK_MARGIN   = 2    -- pixels from the bottom-right corner of the screen that VirtualUser reports the click at
	local clickConn, lastClick = nil, 0
	-- ===== Auto Click (Tap Remote) =====
	-- Fires the game's own TapRequested remote (same call as the standalone Tap Toggle). The server wants ClientSequence to keep
	-- counting UP for the whole session, so the counter is kept in the executor's global table: running the script again carries on
	-- where the last run stopped. (It used to restart at 811 on every execute, and the server then ignored every tap until the new
	-- count had passed the old one.) The game's own taps - when you tap yourself - are watched too, so the counter never falls behind.
	local TAP_INTERVAL = 0.12
	local SYNC_WITH_GAME_TAPS = true   -- set false to skip the (read-only) hook that watches the game's own taps
	if type(env.WORSTTapSequence) ~= "number" then env.WORSTTapSequence = 811 end

	-- Makes the auto click counter follow the game's own taps.
	local function hookTapSync(tapRemote)
		if not SYNC_WITH_GAME_TAPS or env.WORSTTapHooked then return end
		local hook, getMethod = hookmetamethod, getnamecallmethod
		if typeof(hook) ~= "function" or typeof(getMethod) ~= "function" then return end
		local ok = pcall(function()
			local old
			-- Hook handler that watches calls to the tap remote.
			local function handler(self, ...)
				local method = getMethod()
				if method == "FireServer" and self == tapRemote then
					local a = ...
					local n = type(a) == "table" and a.ClientSequence
					if type(n) == "number" and n > env.WORSTTapSequence then env.WORSTTapSequence = n end
				end
				return old(self, ...)
			end
			old = hook(game, "__namecall", (typeof(newcclosure) == "function") and newcclosure(handler) or handler)
		end)
		if ok then env.WORSTTapHooked = true end
	end

	-- Finds the game's tap remote.
	local function findTapRemote()
		local node = game:GetService("ReplicatedStorage")
		for _, name in ipairs({ "RemoteServices", "TapService", "RE", "TapRequested" }) do
			node = node and node:WaitForChild(name, 10)
		end
		return node
	end

	-- Auto Click: switches it on or off.
	function U.autoClick(on)
		if on then
			if U._autoClickConn then return end
			local RunService = game:GetService("RunService")
			local tapRemote = findTapRemote()
			if not tapRemote then warn("[WORST Hub] Auto Click: TapService.RE.TapRequested not found") return end
			hookTapSync(tapRemote)
			print(string.format("[WORST Hub] Auto Click on - taps continue from sequence %d", env.WORSTTapSequence))

			local elapsed, failed = 0, 0
			U._autoClickConn = RunService.Heartbeat:Connect(function(dt)
				if not alive then return end
				elapsed += dt
				if elapsed < TAP_INTERVAL then return end
				elapsed = 0
				env.WORSTTapSequence += 1
				local seq = env.WORSTTapSequence
				local ok, err = pcall(function()
					tapRemote:FireServer({ ClientSequence = seq, Auto = false, Source = "screen" })
				end)
				if ok then failed = 0 else
					failed += 1
					if failed == 1 or failed % 50 == 0 then warn("[WORST Hub] Auto Click: tap request failed: " .. tostring(err)) end
				end
			end)
		else
			if U._autoClickConn then
				U._autoClickConn:Disconnect()
				U._autoClickConn = nil
			end
		end
	end

	-- ===== Auto Rejoin =====
	local rejoinOn, rejoining, useNewServer = false, false, false
	local rejoinConns = {}
	-- Rejoins the server after a disconnect (same or a new server).
	local function rejoin()
		if rejoining or not rejoinOn then return end
		rejoining = true
		task.wait(2) -- small delay so the disconnect fully settles
		if not rejoinOn then rejoining = false return end
		local ok = pcall(function()
			if useNewServer then
				TeleportService:Teleport(game.PlaceId, player)                            -- any server
			else
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) -- same server
			end
		end)
		if not ok then rejoining = false end
	end

	-- Auto Rejoin: switches it on or off.
	function U.autoRejoin(on)
		rejoinOn = on == true
		if on then
			if #rejoinConns > 0 then return end
			-- same-server teleport failed (server closed / full): try a fresh server
			table.insert(rejoinConns, TeleportService.TeleportInitFailed:Connect(function()
				useNewServer = true
				rejoining = false
				task.wait(3)
				rejoin()
			end))
			-- the disconnect / error prompt (CoreGui may be missing on some executors, so everything is in pcall)
			task.spawn(function()
				local ok, overlay = pcall(function()
					return CoreGui:WaitForChild("RobloxPromptGui", 10):WaitForChild("promptOverlay", 10)
				end)
				if not ok or not overlay or not rejoinOn then
					if not ok or not overlay then warn("[WORST Hub] Auto Rejoin: couldn't reach the disconnect prompt (CoreGui blocked?)") end
					return
				end
				table.insert(rejoinConns, overlay.ChildAdded:Connect(function(child)
					if child.Name == "ErrorPrompt" then rejoin() end
				end))
			end)
		else
			for _, c in ipairs(rejoinConns) do pcall(function() c:Disconnect() end) end
			rejoinConns = {}
			rejoining, useNewServer = false, false
		end
	end

	-- ===== Hide Hatch Animation (ported from the standalone v3) =====
	-- hhOn gates everything: while it is off nothing is bound or changed, and anything hidden is put back.
	-- The two hooks are installed once, the first time the switch is turned on; with it off they just pass everything through.
	local HH_ANIM_TAIL, HH_ZOOM_TAIL = 0.6, 1.5   -- seconds the hiding / the camera hold stay active after the last piece is gone
	local hhOn, hhConn, hhCam, hhHooked = false, nil, nil, false
	local hhSaved = setmetatable({}, { __mode = "k" })   -- [obj] = { prop = original }
	local hhTops  = setmetatable({}, { __mode = "k" })   -- animation roots currently in the Camera
	local hhAnimUntil, hhZoomUntil, hhFovCam, hhFov, hhZMin, hhZMax = 0, 0, nil, nil, nil, nil
	-- Hide Hatch Animation: checks if an object belongs to the hatch animation.
	local function hhMatch(n) return n:sub(1, 8) == "TS2Hatch" or n:sub(1, 10) == "TS2PetGain" end
	-- Saves the original value of a property before it is changed.
	local function hhSv(o, ...)
		local t = hhSaved[o]
		if not t then t = {}; hhSaved[o] = t end
		for _, pn in ipairs({ ... }) do
			if t[pn] == nil then local ok, v = pcall(function() return o[pn] end); if ok then t[pn] = v end end
		end
	end
	-- True if an object is part of the hatch animation near the camera.
	local function hhInPiece(o)   -- is this object inside a hatch piece that sits directly in the Camera?
		local cam = workspace.CurrentCamera
		if not cam then return false end
		local top = o
		while top.Parent and top.Parent ~= cam do top = top.Parent end
		return top.Parent == cam and hhMatch(top.Name)
	end
	-- True if hiding is allowed right now.
	local function hhGateOpen() return alive and hhOn and os.clock() < hhZoomUntil end
	-- Installs the hooks that keep the camera and HUD steady.
	local function hhInstallHooks()
		if hhHooked then return end
		hhHooked = true
		if not (type(hookmetamethod) == "function" and type(newcclosure) == "function"
			and type(checkcaller) == "function" and type(getnamecallmethod) == "function") then return end
		-- 1) block the game's writes to zoom limits / FOV while a hatch is being hidden
		local oldNewIndex
		pcall(function()
			oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
				if hhGateOpen() and not checkcaller() then
					if self == player and (key == "CameraMinZoomDistance" or key == "CameraMaxZoomDistance") then return end
					if key == "FieldOfView" and self == workspace.CurrentCamera then return end
				end
				return oldNewIndex(self, key, value)
			end))
		end)
		-- 2) block ParticleEmitter:Emit() for hatch pieces (the white burst streaks)
		local oldNamecall
		pcall(function()
			oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
				if hhOn and alive and getnamecallmethod() == "Emit" and not checkcaller() then
					local ok, block = pcall(function()
						return typeof(self) == "Instance" and self.ClassName == "ParticleEmitter" and hhInPiece(self)
					end)
					if ok and block then return end
				end
				return oldNamecall(self, ...)
			end))
		end)
	end
	-- Hides one hatch animation part.
	local function hhPiece(d)
		if d:IsA("BasePart") then hhSv(d, "LocalTransparencyModifier"); d.LocalTransparencyModifier = 1
		elseif d:IsA("ParticleEmitter") then
			-- Enabled / Rate do not stop Emit() bursts, so also make every particle invisible and instant
			hhSv(d, "Enabled", "Rate", "Transparency", "Size", "Lifetime")
			d.Enabled = false; d.Rate = 0
			d.Transparency = NumberSequence.new(1); d.Size = NumberSequence.new(0); d.Lifetime = NumberRange.new(0)
		elseif d:IsA("Decal") or d:IsA("Texture") then hhSv(d, "Transparency"); d.Transparency = 1
		elseif d:IsA("Beam") or d:IsA("Trail") or d:IsA("Light") or d:IsA("Highlight") or d:IsA("Fire")
			or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
			hhSv(d, "Enabled"); d.Enabled = false
		end
	end
	-- Hides a whole tree of hatch animation parts.
	local function hhTree(root)
		hhPiece(root)
		for _, d in ipairs(root:GetDescendants()) do hhPiece(d) end
	end
	-- Restores everything the hatch hiding changed.
	local function hhRestore()
		for o, t in pairs(hhSaved) do
			hhSaved[o] = nil
			if o.Parent then for pn, v in pairs(t) do pcall(function() o[pn] = v end) end end
		end
		table.clear(hhTops)
		hhAnimUntil, hhZoomUntil, hhZMin, hhZMax, hhFovCam = 0, 0, nil, nil, nil
	end
	-- Handles a new object added to the camera while hiding.
	local function hhCameraAdded(d)   -- the moment the game creates a piece
		if not hhOn then return end
		local cam = workspace.CurrentCamera
		local top = d
		while top.Parent and top.Parent ~= cam do top = top.Parent end
		if top.Parent ~= cam or not hhMatch(top.Name) then return end
		local now = os.clock()
		hhAnimUntil, hhZoomUntil = now + HH_ANIM_TAIL, now + HH_ZOOM_TAIL   -- open the hold BEFORE the game changes zoom / FOV
		hhTops[top] = true
		hhPiece(d)
	end
	-- Runs every frame while hiding (keeps the animation hidden).
	local function hhFrame()   -- end of every frame, after the game's own code (only bound while on)
		if not (alive and hhOn) then return end
		local cam = workspace.CurrentCamera
		if cam and cam ~= hhCam then
			hhCam = cam
			if hhConn then hhConn:Disconnect() end
			hhConn = cam.DescendantAdded:Connect(hhCameraAdded)
		end
		local now, active = os.clock(), false
		for t in pairs(hhTops) do
			if t.Parent then active = true; hhTree(t) else hhTops[t] = nil end
		end
		if cam then
			for _, ch in ipairs(cam:GetChildren()) do
				if hhMatch(ch.Name) and not hhTops[ch] then hhTops[ch] = true; active = true; hhTree(ch) end
			end
		end
		local pg = player:FindFirstChild("PlayerGui")
		if pg then
			local hs = pg:FindFirstChild("Hatching")
			if hs and hs:IsA("ScreenGui") and hs.Enabled then hhSv(hs, "Enabled"); hs.Enabled = false; active = true end
			if active or now < hhAnimUntil then
				local eos = pg:FindFirstChild("Egg Opening Stuff")
				if eos then
					for _, c in ipairs(eos:GetChildren()) do
						if c:IsA("GuiObject") and c.Visible and (c.Name:sub(1, 6) == "Hatch_" or c.Name == "TS2HatchSkipHint") then
							hhSv(c, "Visible"); c.Visible = false
						end
					end
				end
				local fl = pg:FindFirstChild("Flash")
				local ff = fl and fl:FindFirstChild("Frame")
				if ff and ff:IsA("GuiObject") and ff.Visible then hhSv(ff, "Visible"); ff.Visible = false end
				local hud = pg:FindFirstChild("Game")   -- the game switches the HUD off for the animation: keep it on
				if hud and hud:IsA("ScreenGui") and not hud.Enabled then hud.Enabled = true end
			end
		end
		if active then hhAnimUntil, hhZoomUntil = now + HH_ANIM_TAIL, now + HH_ZOOM_TAIL end
		if cam then   -- hold the field of view while the reveal zooms
			if hhFovCam ~= cam or now >= hhZoomUntil then hhFovCam, hhFov = cam, cam.FieldOfView
			elseif cam.FieldOfView ~= hhFov then cam.FieldOfView = hhFov end
		end
		-- hold the zoom limits (the reveal raises the minimum zoom, which pushes the view back)
		if now >= hhZoomUntil then
			hhZMin, hhZMax = player.CameraMinZoomDistance, player.CameraMaxZoomDistance
		elseif hhZMin then
			if player.CameraMinZoomDistance ~= hhZMin then player.CameraMinZoomDistance = hhZMin end
			if player.CameraMaxZoomDistance ~= hhZMax then player.CameraMaxZoomDistance = hhZMax end
		end
	end
	-- Hide Hatch Animation: switches it on or off.
	function U.hideHatch(on)
		on = on == true
		if on == hhOn then return end
		hhOn = on
		pcall(function() game:GetService("RunService"):UnbindFromRenderStep("WORSTHubHideHatch") end)
		if on then
			hhInstallHooks()
			game:GetService("RunService"):BindToRenderStep("WORSTHubHideHatch", Enum.RenderPriority.Last.Value, hhFrame)
		else
			if hhConn then hhConn:Disconnect(); hhConn = nil end
			hhCam = nil
			hhRestore()
		end
	end
	table.insert(cleanupHooks, function() U.hideHatch(false) end)

	-- ===== Hide User =====
	-- Finds every name tag in the world that shows your name and switches it off (and puts it back when you turn Hide User off):
	--   1) the default Roblox overhead name  -> Humanoid.DisplayDistanceType = None
	--   2) any BillboardGui / SurfaceGui in the workspace whose text contains your username or display name (the game's own tag, pet tags ...)
	--   3) BillboardGuis in your PlayerGui that are attached to your character
	local huOn, huRun, huHidden = false, 0, {}
	-- True if a text belongs to you (your name / display name).
	local function huMine(text)
		text = tostring(text or "")
		if text == "" then return false end
		return text:find(player.Name, 1, true) ~= nil or (player.DisplayName ~= "" and text:find(player.DisplayName, 1, true) ~= nil)
	end
	-- Sets a property and remembers the old value.
	local function huSet(obj, prop, value)   -- remembers the first (original) value so it can be restored
		local known = false
		for _, h in ipairs(huHidden) do
			if h.obj == obj and h.prop == prop then known = true break end
		end
		if not known then
			local ok, old = pcall(function() return obj[prop] end)
			if not ok then return end
			huHidden[#huHidden + 1] = { obj = obj, prop = prop, old = old }
		end
		pcall(function() if obj[prop] ~= value then obj[prop] = value end end)   -- re-applied every scan in case the game turns it back on
	end
	-- True if a GUI shows your name.
	local function huGuiShowsMe(g)
		for _, d in ipairs(g:GetDescendants()) do
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and huMine(d.Text) then return true end
		end
		return false
	end
	-- Hides your name tag on your character.
	local function huScanCharacter()
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then huSet(hum, "DisplayDistanceType", Enum.HumanoidDisplayDistanceType.None) end
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
				if huGuiShowsMe(d) then huSet(d, "Enabled", false) end
			end
		end
		local pg = player:FindFirstChildOfClass("PlayerGui")
		if pg then
			for _, d in ipairs(pg:GetDescendants()) do
				if d:IsA("BillboardGui") and d.Adornee and d.Adornee:IsDescendantOf(char) and huGuiShowsMe(d) then
					huSet(d, "Enabled", false)
				end
			end
		end
	end
	-- Hides other name tags in the workspace that show your name.
	local function huScanWorkspace()
		local n = 0
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
				if huGuiShowsMe(d) then huSet(d, "Enabled", false) end
			end
			n = n + 1
			if n % 1500 == 0 then task.wait() end   -- big maps: spread the scan over a few frames
		end
	end
	-- Restores everything Hide User changed.
	local function huRestore()
		for _, h in ipairs(huHidden) do
			pcall(function() if h.obj.Parent then h.obj[h.prop] = h.old end end)
		end
		huHidden = {}
	end
	-- Hide User: switches it on or off.
	function U.hideUser(on)
		on = on == true
		if on == huOn then return end
		huOn = on
		huRun = huRun + 1
		if not on then huRestore() return end
		local my = huRun
		task.spawn(function()
			local lastWorld = 0
			while alive and huOn and huRun == my do
				pcall(huScanCharacter)
				if os.clock() - lastWorld > 8 then
					lastWorld = os.clock()
					pcall(huScanWorkspace)
				end
				task.wait(1)
			end
		end)
	end
	table.insert(cleanupHooks, function() huOn = false huRun = huRun + 1 huRestore() end)

	return U
end)()

local AutoRebirth = (function()
	local RS = game:GetService("ReplicatedStorage")
	local MAX_INDEX   = 16     -- number of rebirth indexes; index i gives +5^(i-1) rebirths (1, 5, 25, 125, ...)
	local PROBE_GAP   = 0.4    -- "Best": seconds between two tries
	local RESULT_WAIT = 1.2    -- "Best": seconds to wait for the server's answer to one try
	local BEST        = "Best (most expensive you can afford)"
	local MIN_DELAY   = 5     -- minimum seconds between rebirth requests
	local state = { on = false, index = 1, best = true, delay = MIN_DELAY, sent = 0, loopId = 0 }

	-- Finds the server remote used by Auto Rebirth.
	local function getRemote()
		local node = RS
		for _, n in ipairs({ "RemoteServices", "RebirthService", "RE", "RebirthRequested" }) do
			node = node and node:FindFirstChild(n)
			if not node then return nil end
		end
		return node
	end

	-- 30517578125 -> "30,517,578,125"
	local function commas(n)
		local str = string.format("%.0f", n)
		local out = str:reverse():gsub("(%d%d%d)", "%1,")
		out = out:reverse()
		if out:sub(1, 1) == "," then out = out:sub(2) end
		return out
	end

	local options, labelToIndex, indexToLabel = { BEST }, {}, {}
	for i = 1, MAX_INDEX do
		local label = "+" .. commas(5 ^ (i - 1))
		options[#options + 1] = label
		labelToIndex[label] = i
		indexToLabel[i] = label
	end

	-- "Best" needs to know whether a try worked. Two signals are used:
	--  1) an answer event next to RebirthRequested (a table with Success / Ok, or a boolean)
	--  2) a number whose key contains "rebirth" in your data changing (the rebirth counter)
	local resultFlag = nil
	local hooked = 0
	do
		local re = nil
		pcall(function() re = RS.RemoteServices.RebirthService.RE end)
		if re then
			for _, r in ipairs(re:GetChildren()) do
				if r:IsA("RemoteEvent") and r.Name ~= "RebirthRequested" then
					hooked = hooked + 1
					connect(r.OnClientEvent, function(a)
						if a == true or (type(a) == "table" and (a.Success == true or a.Ok == true)) then
							resultFlag = true
						elseif a == false or (type(a) == "table" and (a.Success == false or a.Ok == false)) then
							resultFlag = false
						end
					end)
				end
			end
		end
	end

	-- the rebirth counter. A full walk of your data is expensive (up to 3000 nodes), so it only runs when full == true (once per try);
	-- the 0.1 s polling while waiting for the server's answer just re-reads the paths that walk found.
	local counterPaths = nil
	-- Reads a counter from your data (the full value).
	local function counter(full)
		local okD, data = pcall(function() return require(RS.Controllers.Core.DataController):GetReplica().Data end)
		if not (okD and type(data) == "table") then return nil end
		if counterPaths and not full then
			local sum = 0
			for _, path in ipairs(counterPaths) do
				local cur = data
				for _, key in ipairs(path) do
					if type(cur) ~= "table" then cur = nil break end
					cur = cur[key]
				end
				if type(cur) == "number" then sum = sum + cur end
			end
			return #counterPaths > 0 and sum or nil
		end
		local sum, found, nodes, seen, paths = 0, false, 0, {}, {}
		-- Walks the data tree looking for a value (depth-limited).
		local function walkT(t, depth, inside, path)
			if depth > 3 or seen[t] or nodes > 3000 then return end
			seen[t] = true
			for k, v in pairs(t) do
				nodes = nodes + 1
				local hit = inside or tostring(k):lower():find("rebirth", 1, true) ~= nil
				if type(v) == "table" then
					if hit or depth < 3 then
						local np = table.move(path, 1, #path, 1, {})
						np[#np + 1] = k
						walkT(v, depth + 1, hit, np)
					end
				elseif type(v) == "number" and hit then
					sum = sum + v
					found = true
					local np = table.move(path, 1, #path, 1, {})
					np[#np + 1] = k
					paths[#paths + 1] = np
				end
			end
		end
		pcall(walkT, data, 1, false, {})
		counterPaths = found and paths or nil
		return found and sum or nil
	end

	local toggle = {
		-- TOGGLE "Auto Rebirth": Fires a rebirth request over and over until you switch it off.
		type = "toggle", name = "Auto Rebirth", icon = "🔁", default = false,
		desc = "Fires a rebirth request over and over until you switch it off.",
	}
	local indexEntry = {
		type = "dropdown", name = "Rebirth Amount", icon = "#", width = 300,
		desc = "How many rebirths each request gives (+1, +5, +25, +125 ... x5 each step). \"Best\" picks the most expensive one you can afford. Changes apply live.",
		options = options, default = BEST,
	}
	local delayEntry = {
		type = "slider", name = "Rebirth Delay", icon = "🕐", min = MIN_DELAY, max = 3600, default = MIN_DELAY, step = 1, suffix = "s",
		desc = "Seconds to wait between rebirth requests (minimum 5s, up to 1 hour).",
	}

	indexEntry.callback = function(option)
		option = tostring(option)
		if option == BEST then
			state.best = true
		else
			state.best = false
			state.index = labelToIndex[option] or 1
		end
	end
	delayEntry.callback = function(v)
		state.delay = math.max(tonumber(v) or MIN_DELAY, MIN_DELAY)
	end

	-- Sets the status text of Auto Rebirth.
	local function status(text)
		if toggle._desc then toggle._desc.Text = text end
	end

	-- one try; true if the server accepted it
	local function attempt(remote, idx)
		resultFlag = nil
		local before = counter(true)
		local ok, err = pcall(function() remote:FireServer({ Index = idx }) end)
		if not ok then warn("[Rebirth] fire failed: " .. tostring(err)) return false end
		state.sent = state.sent + 1
		local t0 = os.clock()
		while alive and state.on and os.clock() - t0 < RESULT_WAIT do
			if resultFlag ~= nil then return resultFlag end
			local now = counter()
			if before and now and now ~= before then return true end
			task.wait(0.1)
		end
		return false
	end

	toggle.callback = function(on)
		state.on = on == true
		state.loopId = state.loopId + 1
		if not state.on then
			toggle.desc = "Fires a rebirth request over and over until you switch it off."
			return
		end
		local my = state.loopId
		task.spawn(function()
			local warned = false
			while alive and state.on and state.loopId == my do
				if state.before then pcall(state.before) end   -- Kaitun: equip the Richest pets just before the rebirth
				local remote = getRemote()
				if not remote then
					status("[Debug] RebirthService.RE.RebirthRequested not found")
				elseif not state.best then
					local ok, err = pcall(function() remote:FireServer({ Index = state.index }) end)
					if ok then
						state.sent = state.sent + 1
						status(string.format("Running | %s | requests sent: %d", indexToLabel[state.index] or "?", state.sent))
					else
						warn("[Rebirth] fire failed: " .. tostring(err))
					end
				elseif hooked == 0 and counter(true) == nil then
					-- no way to see whether a try worked: trying every index would rebirth more than once
					status("Best can't tell if a rebirth worked (no answer event / counter found) - pick an amount instead")
					if not warned then
						warned = true
						warn("[Rebirth] Best: found no RebirthService answer event and no number with 'rebirth' in its name in your data")
					end
				else
					local done = nil
					for idx = MAX_INDEX, 1, -1 do
						if not (alive and state.on and state.loopId == my) then break end
						status(string.format("Best | trying %s ...", indexToLabel[idx]))
						if attempt(remote, idx) then done = idx break end
						task.wait(PROBE_GAP)
					end
					if done then
						status(string.format("Best | rebirthed %s | requests sent: %d", indexToLabel[done], state.sent))
					else
						status(string.format("Best | can't afford a rebirth yet | requests sent: %d", state.sent))
					end
				end
				if state.after then pcall(state.after) end   -- Kaitun: back to the Luckiest pets for hatching
				local t0 = os.clock()
				while alive and state.on and state.loopId == my and os.clock() - t0 < state.delay do task.wait(0.25) end
			end
		end)
	end

	return { toggle, indexEntry, delayEntry, state = state }
end)()

-- SecretGuard: secret pets are never kept equipped (they are kept for trading to the main account).
-- Auto Equip asks the server for "the best pets" (EquipBest), so the server may pick a secret pet; right afterwards this unequips them again.
-- Used by both Auto Equip modules (the Auto Equip toggle and Kaitun Events).
local SecretGuard = (function()
	local RS = game:GetService("ReplicatedStorage")
	local ENABLED = true
	local WATCH = true          -- true = also runs on its own (even with Auto Equip off): unequips secret pets that are already equipped when the script starts, and any that get equipped later
	local CHECK_EVERY = 10      -- seconds between two checks of the watcher
	-- pet names (lowercase) that must never stay equipped. KEEP IN SYNC with TSR_SECRETS in the website (worst.html): add new secrets in both places.
	local SECRETS = { ["dragon tamer"] = true, ["infernal lord"] = true, ["reanimation"] = true, ["cinder eye"] = true, ["first light"] = true, ["shinigami"] = true, ["nameless diety"] = true, ["nameless deity"] = true }
	local EQUIP_KEYS = { "Equipped", "EquippedPets", "Equip", "Team", "Loadout" }
	local MAX_FAILS = 3   -- stop sending the (guessed) unequip request after this many tries in a row that did not work
	local M = { learned = nil, fails = 0, busy = false, warned = false }

	-- Normalises a text (lowercase, no spaces) for comparing.
	local function norm(s) return (tostring(s):lower():gsub("^%s+", ""):gsub("%s+$", "")) end
	-- Finds the server remote for equipping pets.
	local function petRemote()
		local n = RS
		for _, nm in ipairs({ "RemoteServices", "PetService", "RE", "PetActionRequested" }) do
			n = n and n:FindFirstChild(nm)
			if not n then return nil end
		end
		return n
	end
	-- Returns the player's replicated data table (or nil).
	local function replica()
		local ok, data = pcall(function() return require(RS.Controllers.Core.DataController):GetReplica().Data end)
		if ok and type(data) == "table" and type(data.Pets) == "table" and type(data.Pets.Owned) == "table" then return data end
	end
	-- id -> true for every pet flagged as equipped (same detection as the Pets scan: list of ids, map of ids, or a flag on the pet)
	local function equippedIds(data)
		local set = {}
		for _, holder in ipairs({ data.Pets, data }) do
			for _, k in ipairs(EQUIP_KEYS) do
				local t = holder[k]
				if type(t) == "table" then
					for key, v in pairs(t) do
						if type(v) == "string" or type(v) == "number" then set[tostring(v)] = true
						elseif v == true or type(v) == "table" then set[tostring(key)] = true end
					end
				end
			end
		end
		for pid, p in pairs(data.Pets.Owned) do
			if type(p) == "table" then
				for _, k in ipairs(EQUIP_KEYS) do
					if type(p[k]) == "boolean" and p[k] then set[tostring(pid)] = true end
				end
			end
		end
		return set
	end
	-- list of { id = <key in Pets.Owned>, name = ... } for every equipped secret pet; nil when the data cannot be read
	local function equippedSecrets()
		local data = replica()
		if not data then return nil end
		local eq, list = equippedIds(data), {}
		for pid, p in pairs(data.Pets.Owned) do
			if eq[tostring(pid)] and type(p) == "table" and type(p.Name) == "string" and SECRETS[norm(p.Name)] then
				list[#list + 1] = { id = pid, name = p.Name }
			end
		end
		return list
	end

	-- The game's own requests (captured from a manual equip / unequip):
	--   PetService.RE.PetActionRequested:FireServer({ Action = "Equip" | "Unequip", PetId = "<pet id>" })
	--   answer: PetService.RE.PetActionResult({ Action = "Unequip", Success = true, PowerMultiplier = n })
	--   data:   Pets.Equipped = list of pet ids
	-- The default request below is exactly that. As a safety net, if the game ever changes it, unequipping any pet BY HAND once while the
	-- script runs copies the new request from the game's own call (learn).
	local function learn(args)
		local data = replica()
		if not data then return end
		local owned, idKey, isList, isNumber = data.Pets.Owned, nil, false, false
		for k, v in pairs(args) do
			if (type(v) == "string" or type(v) == "number") and owned[v] ~= nil then idKey, isNumber = k, type(v) == "number" break end
			if (type(v) == "string" or type(v) == "number") and owned[tostring(v)] ~= nil then idKey, isNumber = k, type(v) == "number" break end
			if type(v) == "table" then
				for _, x in pairs(v) do
					if owned[x] ~= nil or owned[tostring(x)] ~= nil then idKey, isList, isNumber = k, true, type(x) == "number" break end
				end
				if idKey then break end
			end
		end
		if not idKey then return end
		local copy = {}
		for k, v in pairs(args) do copy[k] = v end
		M.learned = { args = copy, idKey = idKey, isList = isList, isNumber = isNumber }
		M.fails, M.warned = 0, false
		print("[SecretGuard] learned the game's unequip request: Action = " .. tostring(args.Action) .. ", pet id field = " .. tostring(idKey))
	end
	do
		local canHook = type(hookmetamethod) == "function" and type(getnamecallmethod) == "function"
			and type(newcclosure) == "function" and type(checkcaller) == "function"
		if canHook then
			local old
			local okH = pcall(function()
				old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
					if alive and getnamecallmethod() == "FireServer" and not checkcaller() then
						local a = ...
						if type(a) == "table" and type(a.Action) == "string" and a.Action ~= "UnequipAll"
							and a.Action:lower():find("unequip", 1, true)
							and typeof(self) == "Instance" and self.Name == "PetActionRequested" then
							task.defer(pcall, learn, a)   -- runs after the real call has gone out: no namecall inside the hook before it
						end
					end
					return old(self, ...)
				end))
			end)
			if not okH then old = nil end
		end
	end

	-- Builds the arguments of the equip request.
	local function buildArgs(id)
		local L = M.learned
		if L then
			local args = {}
			for k, v in pairs(L.args) do args[k] = v end
			local v = L.isNumber and (tonumber(id) or id) or tostring(id)
			args[L.idKey] = L.isList and { v } or v
			return args
		end
		return { Action = "Unequip", PetId = id }   -- the game's own request (captured)
	end

	-- unequips every equipped secret pet. Returns how many were taken off (0 = nothing to do or it did not work).
	function M.sweep()
		if not ENABLED or M.busy then return 0 end
		local list = equippedSecrets()
		if not list or #list == 0 then M.fails = 0 return 0 end
		if M.fails >= MAX_FAILS and os.clock() - (M.lastFail or 0) > 120 then M.fails = MAX_FAILS - 1 end   -- try again every 2 minutes
		if M.fails >= MAX_FAILS then
			if not M.warned then
				M.warned = true
				warn("[SecretGuard] secret pet(s) are equipped (" .. list[1].name .. (#list > 1 and " ..." or "") .. ") but the unequip request does not work (the game may have changed it). Unequip any pet by hand once while the script runs so it can copy the game's new request.")
			end
			return 0
		end
		local r = petRemote()
		if not r then return 0 end
		M.busy = true
		for _, sp in ipairs(list) do
			pcall(function() r:FireServer(buildArgs(sp.id)) end)
			task.wait(0.3)
		end
		task.wait(1)   -- let the data update
		local after = equippedSecrets() or list
		M.busy = false
		local done = #list - #after
		if #after > 0 then
			M.fails = M.fails + 1
			M.lastFail = os.clock()
			warn(string.format("[SecretGuard] %d secret pet(s) still equipped after the unequip request (try %d/%d, %s)", #after, M.fails, MAX_FAILS, M.learned and "learned request" or "default request"))
		else
			M.fails = 0
			local names = {}
			for _, sp in ipairs(list) do names[#names + 1] = sp.name end
			print("[SecretGuard] unequipped: " .. table.concat(names, ", "))
		end
		return math.max(done, 0)
	end

	-- Trade hold: while a give-trade runs, no Equip Best may put the pets back on (Auto Equip / Kaitun would re-equip the best pet within seconds)
	function M.hold(on) M.holdUntil = on and (os.clock() + 600) or 0 end
	-- Trade support: unequips equipped pets so they can go into a trade.
	function M.held() return os.clock() < (M.holdUntil or 0) end
	-- Trade support: unequips equipped pets so they can go into a trade. rules = { { name=, tier=, count= }, ... }
	-- Takes off at most `count` equipped copies of each Name|Tier (Shiny = Rainbow). Returns how many were taken off.
	function M.unequipPets(rules)
		if type(rules) ~= "table" or #rules == 0 then return 0 end
		local r = petRemote()
		if not r then return 0 end
		-- Returns the tier of a pet (normal / golden / diamond / rainbow).
		local function tierOf(p) local t = tostring(p.Tier or "Normal") if t == "Shiny" then t = "Rainbow" end return norm(t) end
		-- Turns a tier rule into the tiers wanted.
		local function ruleTier(t) t = norm(t == "" and "Normal" or t) if t == "shiny" then t = "rainbow" end return t end
		local wanted, total = {}, 0
		for _, u in ipairs(rules) do
			local c = math.floor(tonumber(u.count) or 0)
			if c >= 1 then wanted[#wanted + 1] = { name = norm(u.name), tier = ruleTier(u.tier), left = c } total = total + c end
		end
		if total == 0 then return 0 end
		local data = replica()
		if not data then return 0 end
		local eq, ids = equippedIds(data), {}
		for pid, p in pairs(data.Pets.Owned) do
			if eq[tostring(pid)] and type(p) == "table" and type(p.Name) == "string" then
				for _, w in ipairs(wanted) do
					if w.left > 0 and w.name == norm(p.Name) and w.tier == tierOf(p) then
						w.left = w.left - 1
						ids[#ids + 1] = pid
						break
					end
				end
			end
		end
		if #ids == 0 then return 0 end
		-- True while the pets are still equipped after the request.
		local function stillOn()
			local after, left = replica(), 0
			if after then
				local eq2 = equippedIds(after)
				for _, id in ipairs(ids) do if eq2[tostring(id)] then left = left + 1 end end
			end
			return left
		end
		M.busy = true
		-- 1) the game's own "Unequip All" request (captured: { Action = "UnequipAll" }); it works from the script even when the game's button does not
		pcall(function() r:FireServer({ Action = "UnequipAll" }) end)
		task.wait(1.5)   -- let the server answer and the data update
		local left = stillOn()
		-- 2) fallback: the per-pet request, one pet at a time
		if left > 0 then
			for _, id in ipairs(ids) do
				pcall(function() r:FireServer(buildArgs(id)) end)
				task.wait(0.3)
			end
			task.wait(1)
			left = stillOn()
			print("[TSR] UnequipAll did not take every pet off, tried the per-pet request")
		end
		M.busy = false
		print(string.format("[TSR] unequipped %d of %d pet(s) for the trade", #ids - left, #ids))
		return #ids - left
	end

	if WATCH then
		task.spawn(function()
			task.wait(5)   -- let the pet data load
			while alive do
				pcall(M.sweep)
				local t0 = os.clock()
				while alive and os.clock() - t0 < CHECK_EVERY do task.wait(1) end
			end
		end)
	end

	return M
end)()

local AutoEquip = (function()
	local RS = game:GetService("ReplicatedStorage")
	-- captured from the game's own buttons:
	--   PetService.RE.PetActionRequested:FireServer({ Action = "EquipBest", Mode = "Luck" | "Clicks" | "Gems" })
	--   answer: PetService.RE.PetActionResult({ Success = true, Mode = ..., Action = "EquipBest", PowerMultiplier = n })
	local MODES = {
		["Luckiest"]   = "Luck",    -- highest luck pets
		["Strongest"]  = "Clicks",  -- highest power pets
		["Richest"]    = "Gems",    -- best for gems
	}
	local MODE_NAMES = { "Luckiest", "Strongest", "Richest" }
	local state = { on = false, mode = "Luckiest", every = 30, sent = 0, loopId = 0, last = nil }

	-- Finds the server remote for the Auto Equip feature.
	local function getRemote()
		local node = RS
		for _, n in ipairs({ "RemoteServices", "PetService", "RE", "PetActionRequested" }) do
			node = node and node:FindFirstChild(n)
			if not node then return nil end
		end
		return node
	end

	-- Formats a number with commas.
	local function commas(n)
		local str = string.format("%.0f", n)
		local out = str:reverse():gsub("(%d%d%d)", "%1,")
		out = out:reverse()
		if out:sub(1, 1) == "," then out = out:sub(2) end
		return out
	end

	local DESC = "Equips your best pets for the chosen mode over and over until you switch it off. Secret pets are never kept equipped (they are unequipped again)."
	-- TOGGLE "Auto Equip": keeps the best pets equipped for the chosen mode (Luckiest / Strongest / Richest).
	local toggle = { type = "toggle", name = "Auto Equip", icon = "🏅", default = false, desc = DESC }
	local modeEntry = {
		type = "dropdown", name = "Equip Mode", icon = "#", width = 240,
		desc = "Luckiest = highest luck pets | Strongest = highest power pets | Richest = best for gems. Changes apply live.",
		options = MODE_NAMES, default = "Luckiest",
	}
	local everyEntry = {
		type = "slider", name = "Equip Every", icon = "🕐", min = 30, max = 3600, default = 30, step = 1, suffix = "s",
		desc = "Seconds to wait between two equip requests (30 seconds to 1 hour).",
	}

	modeEntry.callback = function(option)
		option = tostring(option)
		if MODES[option] then state.mode = option end
	end
	everyEntry.callback = function(v) state.every = math.max(tonumber(v) or 30, 30) end

	-- Sets the status text of Auto Equip.
	local function status(text)
		if toggle._desc then toggle._desc.Text = text end
	end

	-- the server's answer to our request
	do
		local node = nil
		pcall(function() node = RS.RemoteServices.PetService.RE.PetActionResult end)
		if node and node:IsA("RemoteEvent") then
			connect(node.OnClientEvent, function(a)
				if type(a) == "table" and a.Action == "EquipBest" then
					state.last = a
					if state.on then
						local power = tonumber(a.PowerMultiplier)
						if a.Success then
							status(string.format("Running | %s | equipped%s", state.mode,
								power and (" | power x" .. commas(power)) or ""))
						else
							status(string.format("%s | server refused (%s)", state.mode, tostring(a.Reason or a.Error or "no reason given")))
						end
					end
				end
			end)
		end
	end

	toggle.callback = function(on)
		state.on = on == true
		state.loopId = state.loopId + 1
		if not state.on then
			toggle.desc = DESC
			return
		end
		local my = state.loopId
		task.spawn(function()
			while alive and state.on and state.loopId == my do
				local remote = getRemote()
				if remote and SecretGuard.held() then
					status("Paused: a trade is running")
				elseif remote then
					local ok, err = pcall(function() remote:FireServer({ Action = "EquipBest", Mode = MODES[state.mode] }) end)
					if ok then
						state.sent = state.sent + 1
						status(string.format("Running | %s", state.mode))
						task.wait(1.5)   -- let the server equip, then take any secret pets off again
						pcall(SecretGuard.sweep)
					else
						warn("[Equip] fire failed: " .. tostring(err))
					end
				else
					status("PetService.RE.PetActionRequested not found")
				end
				local t0, lastCheck = os.clock(), os.clock()
				while alive and state.on and state.loopId == my and os.clock() - t0 < state.every do
					task.wait(0.25)
					if os.clock() - lastCheck >= 10 then   -- secret pets that got equipped some other way
						lastCheck = os.clock()
						pcall(SecretGuard.sweep)
					end
				end
			end
		end)
	end

	return { toggle, modeEntry, everyEntry }
end)()

-- "Send New Pets" (Webhook tab): the sender itself is further down, next to the rest of the webhook code
local WebhookState = { on = true, blur = false, enchant = true }
local webhookNewPets = {
	-- TOGGLE "Send New Pets": Sends every new pet that lands in your inventory (hatched or crafted) to the webhook above.
	type = "toggle", name = "Send New Pets", icon = "📨", default = true,
	desc = "Sends every new pet that lands in your inventory (hatched or crafted) to the webhook above. Needs a saved webhook.",
	callback = function(on) WebhookState.on = on == true end,
}
local webhookEnchants = {
	-- TOGGLE "Send Enchants": Sends a message to the webhook each time Auto Enchant lands a wanted enchant.
	type = "toggle", name = "Send Enchants", icon = "📩", default = true,
	desc = "Sends a message to the webhook each time Auto Enchant lands a wanted enchant. Needs a saved webhook.",
	callback = function(on) WebhookState.enchant = on == true end,
}
local webhookBlur = {
	-- TOGGLE "Blur username": Hides your username in webhook messages (Discord shows it blurred until someone clicks it).
	type = "toggle", name = "Blur username", icon = "🙈", default = false,
	desc = "Hides your username in webhook messages (Discord shows it blurred until someone clicks it).",
	callback = function(on) WebhookState.blur = on == true end,
}

-- ============================================================ TRADE AGENT (was Site_Panel.lua) + Trade tab
-- One script: the site link (heartbeat / trade jobs from the site) and the Auto Accept / Ready / Confirm toggles.
-- Do NOT run Site_Panel.lua next to this file any more.
local TradeAgent = (function()
    local okA, resA = pcall(function()
        -- Tap Simulator Reborn agent v9: status + pets + scripts from the site + TRADES from the site + AUTO-UNLOCK
        -- v5: trade cards are found by the name "TradePet_<id>" (+ PetName / PetTier attributes), the list is
        --     scrolled when it only shows ~10 cards, and every trade step is printed to the console.
        -- v6: works WHILE HATCHING. The Inventory / Trade menus are opened with click -> wait -> click again -> force,
        --     the trade window is forced on if the game hides it, the Trade menu is closed again afterwards,
        --     and every heartbeat now sends "hatches" (the site needs it to show "Hatching ..." on the Status page).
        -- v8: MULTI TRADE support: "abort" command from the site, faster check-ins (5 s) while a multi trade runs,
        --     and STACKED pets ("x2") work in trades (a stacked card is clicked once per pet; the offer's stacks are counted).
        -- v7: AUTO-UNLOCK. Locked pets can't be traded, and the game locks some pets automatically (secrets...).
        --     Every Inventory scan (and every 3s while the Inventory is open) unlocks every locked pet.
        --     A pet that is locked again later is unlocked again (UNLOCK_SKIP protects names you want to stay locked).
        -- v10: adds the new CONFIRM step (Review screen -> Confirm -> countdown -> completed).
        -- v9: NO MORE INVENTORY WINDOW for pet data. Pets, equipped pets, storage and locked pets are read from the game's own
        --     replicated data (DataController:GetReplica().Data.Pets.Owned) - the same source AsaiyaHub uses. Auto-unlock still fires
        --     the ToggleLock remote, but picks the locked pets from that data instead of looking for the lock icon on a card.
        --     The window is only used by the old fallbacks below (UI_FALLBACK / the trade-time unlock when no lock field exists).
        local WORKER_URL = "https://tsr-hub.asaiyamain.workers.dev"
        local AGENT_KEY  = "worst"   -- must match the AGENT_KEY variable in Cloudflare
        local EVERY      = 60        -- seconds between heartbeats (a trade starts at the next heartbeat). Was 30: doubled to save Cloudflare requests
        local EVERY_FAST = 10        -- the site asks for this while a multi trade is running (was 5: raise it back if Multi Trade feels too slow)
        local RESCAN     = 120       -- seconds between pet scans (opens the Inventory briefly)
        local DEBUG      = true      -- print every trade step (card counts, picks, scrolling)
        local OPEN_DELAY = 2         -- seconds to wait after the trade window opens, before choosing pets

        -- AUTO-UNLOCK
        local AUTO_UNLOCK = true     -- unlock locked pets so they can be traded (see UNLOCK_MODE)
        local UNLOCK_MODE = "always"   -- "trade"  = only unlock the pets a trade needs, when that trade starts (safe next to WORSTHUB:
                                     --             its auto craft / auto delete skip LOCKED pets, so your locks keep protecting them)
                                     -- "always" = old behaviour: unlock EVERY locked pet every few seconds (WORSTHUB may then craft/delete them!)
        local UNLOCK_SKIP = {}       -- pet names that must NEVER be unlocked, e.g. { "Cinder Eye" }
        local UNLOCK_WATCH = 3       -- seconds between checks while the Inventory happens to be open
        local UNLOCK_COOLDOWN = 8    -- seconds before the SAME pet may be toggled again (lets the lock icon update first)
        local UNLOCK_MAX_FAILS = 3   -- give up on a pet after this many toggles in a row that left it locked

        -- TRADE SAFETY (optional but recommended): list the ONLY usernames this account may ever trade with.
        -- Empty = whatever the site sends is allowed. Example: { "Thegreat_Worst", "MyAlt2" }
        local ALLOWED_PARTNERS = {}
        local MAX_OFFER = 20         -- the game's limit per trade

        -- DATA SCAN (v9)
        local UI_FALLBACK = false    -- true = if the game data can't be read, open the Inventory and read the cards (old method)
        local STORAGE_MAX = nil      -- pet storage size, only needed if the script can't find it (see the "[TSR] storage" line in the output)
        local LOCK_FIELD  = nil      -- exact name of the "locked" field in the data, if auto-detection fails (e.g. "Locked")
        local EQUIP_FIELD = nil      -- same for equipped pets (e.g. "Equipped")

        if not game:IsLoaded() then game.Loaded:Wait() end

        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")
        local lp = Players.LocalPlayer
        local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)
        if not httpRequest then warn("[TSR] this executor has no http request function: the site link is off (the Trade tab still works)") end
        if type(loadstring) ~= "function" then warn("[TSR] this executor has no loadstring: scripts from the site cannot run") end

        -- Prints a debug message (only when DEBUG is on).
        local function dbg(...)
            if not DEBUG then return end
            local t = {}
            for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end
            print("[TSR] " .. table.concat(t, " "))
        end

        -- Follows a list of child names from `root`; nil if a step is missing.
        local function walk(root, path)
            local node = root
            for _, name in ipairs(path) do
                node = node and node:FindFirstChild(name)
                if not node then return nil end
            end
            return node
        end

        -- Returns the player's PlayerGui.
        local function pg() return lp:FindFirstChild("PlayerGui") end
        -- Returns the Inventory ScreenGui.
        local function invGui() return walk(pg(), { "Tabs", "Inventory" }) end
        -- True if the Inventory menu is open.
        local function invIsOn() local g = invGui() return g ~= nil and g.Enabled == true end

        -- Clicks a GUI button by firing its connections.
        local function click(btn)
            if not btn or type(getconnections) ~= "function" then return false end
            local fired = false
            for _, sig in ipairs({ "MouseButton1Click", "Activated", "MouseButton1Down" }) do
                pcall(function()
                    for _, c in ipairs(getconnections(btn[sig])) do c:Fire() fired = true end
                end)
            end
            return fired
        end

        -- Waits until fn() returns true or the timeout is over.
        local function waitFor(fn, timeout)
            local t0 = os.clock()
            while os.clock() - t0 < timeout do
                local ok, v = pcall(fn)
                if ok and v then return v end
                task.wait(0.3)
            end
            return nil
        end

        -- force a ScreenGui / Frame on even if the game hides it while hatching
        local function forceOn(o, why)
            if not o then return false end
            local changed = false
            if o:IsA("ScreenGui") and o.Enabled ~= true then o.Enabled = true changed = true end
            if o:IsA("GuiObject") and o.Visible ~= true then o.Visible = true changed = true end
            if changed then dbg("FORCED visible:", o.Name, "(" .. tostring(why) .. ")") end
            return changed
        end

        -- opens Tabs.<name> even while hatching: click, wait for the game to build it, click again, then force it
        local function openMenu(name, btnPath)
            -- Returns the menu's ScreenGui.
            local function gui() return walk(pg(), { "Tabs", name }) end
            -- True if the menu is open.
            local function on() local g = gui() return g ~= nil and g.Enabled == true end
            if on() then return true end
            click(walk(pg(), btnPath))
            waitFor(gui, 5)
            if waitFor(on, 2) then return true end
            dbg("second click on " .. name .. " (the first one did not show it)")
            click(walk(pg(), btnPath))
            if waitFor(on, 3) then return true end
            dbg(name .. " still closed, forcing it open")
            forceOn(gui(), name)
            forceOn(walk(gui(), { "Menu" }), name .. " menu")
            return waitFor(on, 3) ~= nil
        end

        -- closes Tabs.<name>: press its Close button, and if it is still on, switch it off
        local function closeMenu(name)
            local g = walk(pg(), { "Tabs", name })
            if not (g and g.Enabled) then return end
            click(walk(g, { "Menu", "Close", "Button" }))
            task.wait(0.8)
            if g.Enabled then
                g.Enabled = false
                dbg("FORCED closed:", name)
            end
        end

        -- How many pet cards are in the inventory list.
        local function cardCount()
            local n = 0
            local g = invGui()
            if g then
                for _, d in ipairs(g:GetDescendants()) do
                    if d.Name:sub(1, 4) == "Pet_" and d:GetAttribute("PetId") then n = n + 1 end
                end
            end
            return n
        end

        -- identical pets are drawn as ONE card with a "x2" / "x4" StackCount label; 1 when there is none
        local function stackOf(card)
            local sc = card:FindFirstChild("StackCount")
            if sc and sc:IsA("GuiObject") and sc.Visible then
                local lb = sc:FindFirstChild("Label")
                local num = lb and lb:IsA("TextLabel") and lb.Text:gsub(",", ""):match("%d+")
                return tonumber(num) or 1
            end
            return 1
        end

        -- Reads the text of a label found by path.
        local function labelText(path)
            local l = walk(pg(), path)
            return l and l:IsA("TextLabel") and l.Text or nil
        end
        -- Reads the pet count and the max from a "used/max" text.
        local function parseCount(text)
            if not text then return nil, nil end
            local a, b = text:gsub(",", ""):match("(%d+)%s*/%s*(%d+)")
            return tonumber(a), tonumber(b)
        end

        -- Opens the inventory menu.
        local function openInventory()
            if invIsOn() and cardCount() > 0 then return true end
            openMenu("Inventory", { "Game", "Bottom", "Pets", "Button" })
            click(walk(invGui(), { "Menu", "Tabs", "Pets", "Button" }))   -- make sure the Pets tab (not Items) is showing
            local t0 = os.clock()
            while os.clock() - t0 < 12 do
                task.wait(0.4)
                if invIsOn() and cardCount() > 0 then break end
            end
            -- let the list finish building: wait until the card count stops changing
            local last, stable = -1, 0
            while stable < 3 and os.clock() - t0 < 18 do
                task.wait(0.5)
                local n = cardCount()
                if n == last then stable = stable + 1 else stable, last = 0, n end
            end
            return invIsOn()
        end

        local closeLogged = false
        -- Closes the inventory menu.
        local function closeInventory()
            if not invIsOn() then return end
            -- 1) the menu's own close button
            local close = walk(invGui(), { "Menu", "Close" })
            if close then
                for _, d in ipairs(close:GetDescendants()) do
                    if d:IsA("TextButton") or d:IsA("ImageButton") then click(d) break end
                end
            end
            task.wait(0.8)
            -- 2) the Pets button again (it may toggle)
            if invIsOn() then
                click(walk(pg(), { "Game", "Bottom", "Pets", "Button" }))
                task.wait(0.8)
            end
            if invIsOn() then   -- the game ignored both clicks (busy / hatching): switch it off directly
                invGui().Enabled = false
            end
            if not closeLogged then
                closeLogged = true
                print("[TSR] close attempt: Inventory is now " .. (invIsOn() and "STILL OPEN" or "closed"))
            end
        end

        -- =====================================================================================
        -- AUTO-UNLOCK: the game's lock button sends  PetActionRequested:FireServer({Action="ToggleLock", PetId=...})
        -- It is a TOGGLE, so it is only ever fired on a card whose Lock icon is visible, never on an unlocked pet.
        -- =====================================================================================
        local petRemote = nil
        -- Finds the server remote for pet actions.
        local function getPetRemote()
            if petRemote and petRemote.Parent then return petRemote end
            local rs = game:GetService("ReplicatedStorage")
            local svc = rs:FindFirstChild("RemoteServices")
            local ps = svc and svc:FindFirstChild("PetService")
            local re = ps and ps:FindFirstChild("RE")
            petRemote = re and re:FindFirstChild("PetActionRequested")
            return petRemote
        end

        -- True if a name is in a list.
        local function nameIn(list, name)
            for _, n in ipairs(list) do
                if tostring(n):lower() == tostring(name):lower() then return true end
            end
            return false
        end

        -- True if this pet card is locked.
        local function cardLocked(card)
            local lk = card:FindFirstChild("Lock")
            return lk ~= nil and lk:IsA("GuiObject") and lk.Visible
        end

        local unlockLastTry = {}     -- PetId -> os.clock() of the last toggle (cooldown)
        local unlockFails = {}       -- PetId -> toggles in a row that left the pet locked
        local unlockWarned = false
        local unlockBusy = false
        -- Unlocks locked pets so they can be used (only when AUTO_UNLOCK is on).
        local function unlockLockedPets()
            if not AUTO_UNLOCK or unlockBusy then return 0 end
            local g = invGui()
            local list = g and walk(g, { "Menu", "Categories", "Pets", "Inner", "List" })
            if not list then return 0 end
            local remote = getPetRemote()
            if not remote then
                if not unlockWarned then
                    unlockWarned = true
                    warn("[TSR] auto-unlock: ReplicatedStorage.RemoteServices.PetService.RE.PetActionRequested not found")
                end
                return 0
            end
            unlockBusy = true
            local count = 0
            local ok, err = pcall(function()
                local targets, seenIds = {}, {}
                for _, d in ipairs(list:GetDescendants()) do
                    local id = d:GetAttribute("PetId")
                    if id and d.Name:sub(1, 4) == "Pet_" and not seenIds[id] then
                        seenIds[id] = true
                        id = tostring(id)
                        local name = tostring(d:GetAttribute("PetName") or "?")
                        if cardLocked(d) then
                            local cooled = (os.clock() - (unlockLastTry[id] or -1e9)) >= UNLOCK_COOLDOWN
                            local gaveUp = (unlockFails[id] or 0) >= UNLOCK_MAX_FAILS
                            if cooled and not gaveUp and not nameIn(UNLOCK_SKIP, name) then
                                targets[#targets + 1] = { card = d, id = id, name = name, tier = tostring(d:GetAttribute("PetTier") or "?") }
                            end
                        else
                            unlockFails[id] = nil   -- seen unlocked: reset, so a later re-lock is handled again
                        end
                    end
                end
                for _, t in ipairs(targets) do
                    unlockLastTry[t.id] = os.clock()
                    remote:FireServer({ Action = "ToggleLock", PetId = t.id })
                    task.wait(0.6)
                    local still = t.card.Parent ~= nil and cardLocked(t.card)
                    unlockFails[t.id] = still and ((unlockFails[t.id] or 0) + 1) or nil
                    print("[TSR] auto-unlock: " .. t.name .. " (" .. t.tier .. "): " .. (still and "STILL LOCKED" or "unlocked"))
                    count = count + 1
                end
            end)
            unlockBusy = false
            if not ok then warn("[TSR] auto-unlock error: " .. tostring(err)) end
            return count
        end

        -- PetId -> { name, tier, multi }. Filled by every Inventory scan; used as a fallback to know
        -- which card in the trade window is which pet.
        local petIndex = {}

        -- =====================================================================================
        -- DATA SCAN: reads the game's replicated save data. Nothing is opened, hidden or clicked.
        -- =====================================================================================
        local RS = game:GetService("ReplicatedStorage")
        -- Share the game's discovered pet rarities with the website inventory/trade feed.
        -- The Auto Delete discovery reads the game's pet definition modules.
        local function sitePetRarity(name, direct)
            if type(direct) == "string" and direct ~= "" then return direct end
            if not name or name == "?" then return nil end
            local ok, r = pcall(function()
                return Logic and Logic.autodel and Logic.autodel.rarityOf and Logic.autodel.rarityOf(name)
            end)
            if ok and type(r) == "string" and r ~= "" then return r end
            -- In case the game's pet definitions haven't finished loading yet,
            -- keep the known Stardust Shard mapping as a last resort.
            if tostring(name):lower() == "stardust shard" then return "Godly" end
            return nil
        end

        local DATA = (function()
            local D = {}
            local LOCK_KEYS  = { "Locked", "Lock", "IsLocked", "Favorite", "Favourite", "Favorited", "Favorites", "Favourites", "LockedPets" }
            local EQUIP_KEYS = { "Equipped", "EquippedPets", "Equip", "Team", "Loadout" }
            local POWER_KEYS = { "Multi", "Multiplier", "Mult", "Power", "Strength" }
            local MAX_KEYS   = { "StorageLimit", "MaxStorage", "StorageMax", "PetStorage", "MaxPets", "Capacity", "Storage", "Slots" }
            local EQMAX_KEYS = { "EquipLimit", "MaxEquipped", "EquippedLimit", "MaxEquip", "EquipSlots", "EquippedMax", "TeamSize" }
            -- Returns only the pets that have a given field.
            local function withField(list, field)
                if not field then return list end
                local l = { field }
                for _, k in ipairs(list) do l[#l + 1] = k end
                return l
            end
            local lockKeys, equipKeys = withField(LOCK_KEYS, LOCK_FIELD), withField(EQUIP_KEYS, EQUIP_FIELD)

            local lockSource, equipSource, dumped, loggedOk, failedWhy, deepDone, busy = nil, nil, false, false, nil, false, false

            -- Returns the player's replicated data table (or nil).
            local function replica()
                local okD, data = pcall(function()
                    return require(RS.Controllers.Core.DataController):GetReplica().Data
                end)
                if okD and type(data) == "table" and type(data.Pets) == "table" and type(data.Pets.Owned) == "table" then
                    return data
                end
            end

            -- id -> true for every pet flagged by one of the keys ({ id, id } lists, { [id] = true } maps, { [slot] = id } maps,
            -- or a boolean on the pet itself). Second result = where it was found (nil = no such field in the data).
            local function idSet(data, owned, keys)
                local set, source = {}, nil
                for _, holder in ipairs({ data.Pets, data }) do
                    for _, k in ipairs(keys) do
                        local t = holder[k]
                        if type(t) == "table" then
                            source = source or ((holder == data and "data." or "data.Pets.") .. k)
                            for key, v in pairs(t) do
                                if type(v) == "string" or type(v) == "number" then set[tostring(v)] = true
                                elseif v == true or type(v) == "table" then set[tostring(key)] = true end
                            end
                        end
                    end
                end
                for pid, p in pairs(owned) do
                    if type(p) == "table" then
                        for _, k in ipairs(keys) do
                            if type(p[k]) == "boolean" then
                                source = source or ("pet." .. k)
                                if p[k] then set[tostring(pid)] = true end
                            end
                        end
                    end
                end
                return set, source
            end

            -- Returns the first value found under any of the given keys.
            local function firstOf(t, keys, ty)
                for _, k in ipairs(keys) do
                    if type(t[k]) == ty then return t[k] end
                end
            end

            -- Shortens a number (1.2K, 3.4M ...).
            local function abbr(n)
                if type(n) ~= "number" then return tostring(n) end
                local sfx, i = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }, 1
                while math.abs(n) >= 1000 and i < #sfx do n = n / 1000 i = i + 1 end
                return (string.format("%.2f", n):gsub("%.?0+$", "")) .. sfx[i]
            end

            -- prints what the data looks like, once, so the right field names can be set when detection fails
            local function dump(data)
                if dumped then return end
                dumped = true
                -- Lists the keys of a table (limited) for debug output.
                local function keyList(t, limit)
                    local l = {}
                    for k, v in pairs(t) do
                        l[#l + 1] = tostring(k) .. "(" .. type(v) .. ")"
                        if #l >= limit then break end
                    end
                    table.sort(l)
                    return table.concat(l, ", ")
                end
                print("[TSR] data keys: " .. keyList(data, 60))
                print("[TSR] data.Pets keys: " .. keyList(data.Pets, 40))
                local _, sample = next(data.Pets.Owned)
                if type(sample) == "table" then
                    local parts = {}
                    for k, v in pairs(sample) do
                        if type(v) ~= "table" then parts[#parts + 1] = tostring(k) .. "=" .. tostring(v) end
                    end
                    table.sort(parts)
                    print("[TSR] sample pet: " .. table.concat(parts, ", "))
                end
            end

            -- looks for a storage size anywhere in the data (and player attributes / leaderstats)
            local function deepMax(data, total)
                local cands, seen, nodes = {}, {}, 0
                local WORDS = { "storage", "capacity", "maxpet", "petslot", "petinv", "inventorysize", "inventoryslots", "limit", "slots" }
                -- Checks one value as a pet-storage candidate.
                local function consider(path, key, v)
                    if type(v) ~= "number" or v < total or v > 1e6 then return end
                    local k = tostring(key):lower()
                    if k:find("used") or k:find("count") or k:find("current") then return end
                    for _, w in ipairs(WORDS) do
                        if k:find(w, 1, true) then
                            local score = (k:find("max", 1, true) or k:find("capacity", 1, true)) and 2 or 1
                            cands[#cands + 1] = { path = path, v = v, score = score }
                            return
                        end
                    end
                end
                -- Walks the data tree looking for pet-storage candidates.
                local function walkT(t, path, depth)
                    if depth > 4 or seen[t] or nodes > 4000 then return end
                    seen[t] = true
                    for k, v in pairs(t) do
                        nodes = nodes + 1
                        local pth = path .. "." .. tostring(k)
                        if type(v) == "table" then
                            if v ~= data.Pets.Owned then walkT(v, pth, depth + 1) end
                        else
                            consider(pth, k, v)
                        end
                    end
                end
                pcall(walkT, data, "data", 1)
                pcall(function()
                    for k, v in pairs(lp:GetAttributes()) do consider("player@" .. tostring(k), k, v) end
                    local ls = lp:FindFirstChild("leaderstats")
                    for _, holder in ipairs({ lp, ls }) do
                        if holder then
                            for _, c in ipairs(holder:GetChildren()) do
                                if c:IsA("NumberValue") or c:IsA("IntValue") then consider(holder.Name .. "/" .. c.Name, c.Name, c.Value) end
                            end
                        end
                    end
                end)
                table.sort(cands, function(x, y)
                    if x.score ~= y.score then return x.score > y.score end
                    return x.v < y.v
                end)
                if not deepDone then
                    deepDone = true
                    if #cands == 0 then
                        print("[TSR] storage search: nothing in the data looks like a storage size (the Storage label is used if it exists, or set STORAGE_MAX)")
                    else
                        local l = {}
                        for i = 1, math.min(#cands, 12) do l[#l + 1] = cands[i].path .. " = " .. tostring(cands[i].v) end
                        print("[TSR] storage candidates (first one is used): " .. table.concat(l, " | "))
                    end
                end
                if cands[1] then return cands[1].v, cands[1].path end
            end

            -- Reports (once per reason) why the pet scan failed.
            local function fail(why, data)
                if failedWhy ~= why then
                    failedWhy = why
                    warn("[TSR] pet data scan unavailable (" .. why .. ")" .. (UI_FALLBACK and " - using the inventory window instead" or ""))
                    if data then pcall(dump, data) end
                end
                return nil, why
            end

            -- Returns result, idx on success (same shape the old window scan produced) or nil, reason.
            function D.read()
                local data = replica()
                if not data then return fail("pet data not loaded yet") end
                local owned = data.Pets.Owned

                local equipped, eqSrc = idSet(data, owned, equipKeys)
                local _, lkSrc = idSet(data, owned, lockKeys)
                lockSource, equipSource = lkSrc or LOCK_FIELD, eqSrc or EQUIP_FIELD

                local idx, groups, order, equippedList, total = {}, {}, {}, {}, 0
                for pid, p in pairs(owned) do
                    if type(p) == "table" and type(p.Name) == "string" then
                        total = total + 1
                        local id = tostring(pid)
                        local tier = tostring(p.Tier or "Normal")
                        if tier == "Shiny" then tier = "Rainbow" end   -- the game shows Shiny pets as RAINBOW
                        local power = firstOf(p, POWER_KEYS, "number")
                        local multi = power and abbr(power) or nil
                        local rarity = sitePetRarity(p.Name, p.Rarity or p.rarity)
                        idx[id] = { name = p.Name, tier = tier, multi = multi, rarity = rarity }
                        if equipped[id] then
                            equippedList[#equippedList + 1] = { name = p.Name, tier = tier, multi = multi, affinity = p.Affinity or p.PetAffinity, rarity = rarity }
                        end
                        local key = p.Name .. "|" .. tier
                        if not groups[key] then groups[key] = { name = p.Name, tier = tier, count = 0, rarity = rarity } order[#order + 1] = key end
                        groups[key].count = groups[key].count + 1
                    end
                end
                if total == 0 then return fail("no pets in the data", data) end

                local grouped = {}
                for _, k in ipairs(order) do grouped[#grouped + 1] = groups[k] end
                table.sort(grouped, function(a, b) return a.count > b.count end)

                -- storage size: STORAGE_MAX, a max stored in the data, a deep search; the Storage label (if it exists) overrides in the heartbeat
                local max = (STORAGE_MAX and STORAGE_MAX > 0) and STORAGE_MAX or nil
                if not max then
                    for _, holder in ipairs({ data.Pets, data }) do
                        for _, k in ipairs(MAX_KEYS) do
                            local v = holder[k]
                            if not max and type(v) == "number" and v >= total then max = v end
                        end
                    end
                end
                local maxFrom
                if not max then
                    local dm, dp = deepMax(data, total)
                    if dm then max, maxFrom = dm, dp end
                end
                local eqMax
                for _, holder in ipairs({ data.Pets, data }) do
                    eqMax = eqMax or firstOf(holder, EQMAX_KEYS, "number")
                end

                if not loggedOk then
                    loggedOk = true
                    print(string.format("[TSR] pet data: game data (no inventory window) | %d pets | locked=%s equipped=%s storage max=%s",
                        total, tostring(lockSource), tostring(equipSource), tostring(max) .. (maxFrom and (" (from " .. maxFrom .. ")") or "")))
                    if not equipSource then
                        warn("[TSR] equipped pets not found in the data, the site will show none. Set EQUIP_FIELD in the script.")
                        pcall(dump, data)
                    end
                    if not lockSource then
                        warn("[TSR] locked pets not found in the data (maybe nothing was ever locked). Auto-unlock will use the inventory window only when a trade starts. Set LOCK_FIELD if you know the name.")
                        pcall(dump, data)
                    end
                end
                failedWhy = nil
                return { owned = total, capacity = max, equippedCount = #equippedList, equippedMax = eqMax,
                    scanned = total, stale = false, equipped = equippedList, grouped = grouped }, idx
            end

            -- AUTO-UNLOCK from the data: the locked pets come from the data, then the same ToggleLock remote is fired.
            -- Returns how many pets were toggled, or nil when the data has no lock field (then the window method is the only way).
            -- cheap live pet count straight from the game data (no grouping, no UI)
            function D.count()
                local data = replica()
                if not data then return nil end
                local n = 0
                for _, p in pairs(data.Pets.Owned) do
                    if type(p) == "table" and type(p.Name) == "string" then n = n + 1 end
                end
                return n
            end

            -- Pets that can be put into a trade, read from the game's own data (the same source as the pet lists).
            -- Grouped by Name|Tier, one entry per pet in .uids. Equipped and locked pets are left out, and so are the ids in
            -- gone (already traded away) and bad (the server did not take them). Returns groups, order (or nil = data not loaded).
            local UUID_PAT = "^%x+%-%x+%-%x+%-%x+%-%x+$"
            -- Trade: returns the pets in your data that are tradeable.
            function D.tradePets(gone, bad)
                local data = replica()
                if not data then return nil end
                local owned = data.Pets.Owned
                local equipped = idSet(data, owned, equipKeys)
                local locked = idSet(data, owned, lockKeys)
                local groups, order = {}, {}
                for pid, p in pairs(owned) do
                    if type(p) == "table" and type(p.Name) == "string" then
                        local id = tostring(pid)
                        local uid = id   -- the key of data.Pets.Owned is the pet id the game's remotes use
                        if not id:match(UUID_PAT) then
                            for _, k in ipairs({ "Uid", "Id", "UUID", "PetId" }) do
                                if type(p[k]) == "string" and p[k]:match(UUID_PAT) then uid = p[k] break end
                            end
                        end
                        if not equipped[id] and not locked[id] and not (gone and gone[uid]) and not (bad and bad[uid]) then
                            local tier = tostring(p.Tier or "Normal")
                            if tier == "Shiny" then tier = "Rainbow" end   -- the game shows Shiny pets as RAINBOW
                            local key = p.Name .. "|" .. tier
                            local g = groups[key]
                            if not g then
                                g = { key = key, name = p.Name, tier = tier, uids = {} }
                                groups[key] = g
                                order[#order + 1] = key
                            end
                            g.uids[#g.uids + 1] = uid
                        end
                    end
                end
                table.sort(order, function(a, b)
                    local x, y = groups[a].name:lower(), groups[b].name:lower()
                    if x ~= y then return x < y end
                    return groups[a].tier < groups[b].tier
                end)
                return groups, order
            end

            -- Unlocks pets (optionally only those matching `filter`).
            function D.unlock(filter)   -- filter(name, tier) -> true = may be unlocked (nil = every locked pet)
                if not AUTO_UNLOCK then return 0 end
                if busy then return 0 end
                local data = replica()
                if not data then return nil end
                local owned = data.Pets.Owned
                local locked, src = idSet(data, owned, lockKeys)
                if not src then return nil end
                lockSource = src

                for id in pairs(unlockFails) do   -- seen unlocked: reset, so a later re-lock is handled again
                    if not locked[id] then unlockFails[id] = nil end
                end

                local byId = {}
                for pid, p in pairs(owned) do byId[tostring(pid)] = p end

                local targets = {}
                for id in pairs(locked) do
                    local p = byId[id]
                    if type(p) == "table" and type(p.Name) == "string" then
                        local cooled = (os.clock() - (unlockLastTry[id] or -1e9)) >= UNLOCK_COOLDOWN
                        local gaveUp = (unlockFails[id] or 0) >= UNLOCK_MAX_FAILS
                        if cooled and not gaveUp and not nameIn(UNLOCK_SKIP, p.Name) and (not filter or filter(p.Name, tostring(p.Tier or "Normal"))) then
                            targets[#targets + 1] = { id = id, name = p.Name, tier = tostring(p.Tier or "Normal") }
                        end
                    end
                end
                if #targets == 0 then return 0 end

                local remote = getPetRemote()
                if not remote then
                    if not unlockWarned then
                        unlockWarned = true
                        warn("[TSR] auto-unlock: ReplicatedStorage.RemoteServices.PetService.RE.PetActionRequested not found")
                    end
                    return 0
                end

                busy = true
                local ok, err = pcall(function()
                    for _, t in ipairs(targets) do
                        unlockLastTry[t.id] = os.clock()
                        remote:FireServer({ Action = "ToggleLock", PetId = t.id })
                        task.wait(0.15)
                    end
                    task.wait(1.5)   -- let the data update, then check what is still locked
                    local data2 = replica() or data
                    local after = idSet(data2, data2.Pets.Owned, lockKeys)
                    local stillCount = 0
                    for i, t in ipairs(targets) do
                        local still = after[t.id] == true
                        unlockFails[t.id] = still and ((unlockFails[t.id] or 0) + 1) or nil
                        if still then stillCount = stillCount + 1 end
                        if #targets <= 10 then
                            print("[TSR] auto-unlock: " .. t.name .. " (" .. t.tier .. "): " .. (still and "STILL LOCKED" or "unlocked"))
                        end
                    end
                    if #targets > 10 then
                        print(string.format("[TSR] auto-unlock: toggled %d pets, %d still locked", #targets, stillCount))
                    end
                end)
                busy = false
                if not ok then warn("[TSR] auto-unlock error: " .. tostring(err)) end
                return #targets
            end

            return D
        end)()

        -- (old method, only used when UI_FALLBACK = true) reads the pet cards of the open Inventory
        local function readPets()
            local g = invGui()
            local list = g and walk(g, { "Menu", "Categories", "Pets", "Inner", "List" })
            local owned, capacity = parseCount(labelText({ "Tabs", "Inventory", "Menu", "Categories", "Pets", "Stats", "Storage" }))
            local eqNow, eqMax = parseCount(labelText({ "Tabs", "Inventory", "Menu", "Categories", "Pets", "Stats", "Equipped" }))

            local seen, equipped, groups, order, scanned = {}, {}, {}, {}, 0
            local idx = {}
            if list then
                for _, d in ipairs(list:GetDescendants()) do
                    local id = d:GetAttribute("PetId")
                    if id and d.Name:sub(1, 4) == "Pet_" and not seen[id] then
                        seen[id] = true

                        -- identical pets are drawn as ONE card with a "x2" / "x4" StackCount label
                        local stack = 1
                        local sc = d:FindFirstChild("StackCount")
                        if sc and sc:IsA("GuiObject") and sc.Visible then
                            local lb = sc:FindFirstChild("Label")
                            local num = lb and lb:IsA("TextLabel") and lb.Text:gsub(",", ""):match("%d+")
                            stack = tonumber(num) or 1
                        end
                        scanned = scanned + stack

                        local isEq, p = false, d.Parent
                        while p and p ~= list do
                            if p.Name == "Equipped" then isEq = true break end
                            p = p.Parent
                        end

                        local name = tostring(d:GetAttribute("PetName") or "?")
                        local tier = tostring(d:GetAttribute("PetTier") or "?")
                        if tier == "Shiny" then tier = "Rainbow" end   -- the game shows Shiny pets as RAINBOW
                        local ml = walk(d, { "Main", "Multi" })

                        local rarity = sitePetRarity(name, d:GetAttribute("PetRarity") or d:GetAttribute("Rarity"))
                        local info = { name = name, tier = tier, multi = ml and ml.Text or nil, rarity = rarity }
                        idx[tostring(id)] = info
                        idx[d.Name:sub(5)] = info

                        if isEq then
                            equipped[#equipped + 1] = { name = name, tier = tier,
                                multi = ml and ml.Text or nil, affinity = d:GetAttribute("PetAffinity"), rarity = rarity }
                        end
                        local key = name .. "|" .. tier
                        if not groups[key] then groups[key] = { name = name, tier = tier, count = 0, rarity = rarity } order[#order + 1] = key end
                        groups[key].count = groups[key].count + stack
                    end
                end
            end
            if scanned > 0 then petIndex = idx end

            local grouped = {}
            for _, k in ipairs(order) do grouped[#grouped + 1] = groups[k] end
            table.sort(grouped, function(a, b) return a.count > b.count end)

            return { owned = owned, capacity = capacity, equippedCount = eqNow, equippedMax = eqMax,
                scanned = scanned, stale = false, equipped = equipped, grouped = grouped }
        end

        local lastPets, lastScanAt = nil, 0
        local tradeBusy = false      -- true while a trade job runs (pauses pet scans so they don't collide)

        -- old window method for the unlock: open the Inventory, unlock every card with a visible Lock icon, close it again.
        -- Only used when the game data has no lock field AND a trade is starting.
        local function unlockViaWindow()
            local wasOpen = invIsOn()
            if openInventory() then pcall(unlockLockedPets) end
            if not wasOpen then closeInventory() end
        end

        -- Reads your pets again (for a trade or with a filter).
        local function refreshPets(forTrade, filter)
            local result, idx = DATA.read()
            if result then
                lastPets, lastScanAt = result, os.clock()
                petIndex = idx
                local n
                if UNLOCK_MODE == "always" then n = DATA.unlock()          -- every locked pet
                elseif forTrade and AUTO_UNLOCK then n = DATA.unlock(filter) -- only the pets this trade needs
                end
                if n == nil and forTrade and AUTO_UNLOCK then pcall(unlockViaWindow) end
                return
            end
            if not UI_FALLBACK then
                lastScanAt = os.clock() - RESCAN + 15   -- data not ready: try again in ~15 s
                return
            end
            -- UI_FALLBACK: the old method
            local wasOpen = invIsOn()          -- if you opened it yourself, leave it open
            local opened = openInventory()
            if opened then pcall(unlockLockedPets) end
            local ui = opened and readPets() or nil
            if not wasOpen then closeInventory() end
            if ui and ui.scanned > 0 then
                lastPets, lastScanAt = ui, os.clock()
            elseif ui then
                lastPets = lastPets or ui
                lastScanAt = os.clock()
            end
        end

        -- =====================================================================================
        -- TRADES
        -- =====================================================================================
        local lastTrade = nil        -- { id, stage, ok, msg, at } reported to the site in every heartbeat
        local abortRequested = false -- set by an "abort" command from the site (multi trade: the partner failed / job cancelled)
        local everyNow = EVERY       -- 60 s normally, 10 s while the site runs a multi trade

        -- Stores the result of a trade step so it can be reported.
        local function setTrade(id, stage, ok, msg)
            lastTrade = { id = id, stage = stage, ok = ok, msg = msg, at = os.time() }
            print("[TSR] trade " .. stage .. ": " .. msg)
        end

        -- Normalises a text (lowercase, trimmed).
        local function norm(s) return tostring(s or ""):lower() end
        -- Normalises a pet tier text ("shiny" counts as rainbow).
        local function tierNorm(t) t = norm(t) if t == "shiny" then t = "rainbow" end return t end

        -- Finds a player by name.
        local function findPlayer(name)
            for _, p in ipairs(Players:GetPlayers()) do
                if norm(p.Name) == norm(name) then return p end
            end
        end

        -- True if this trade partner is on the allowed list.
        local function partnerAllowed(name)
            if #ALLOWED_PARTNERS == 0 then return true end
            for _, n in ipairs(ALLOWED_PARTNERS) do
                if norm(n) == norm(name) then return true end
            end
            return false
        end

        -- trade window helpers (ScreenGui "Trading" > Frame "Trading" > Build / Review)
        local function winGui() return walk(pg(), { "Trading" }) end
        -- True if the trade window is open.
        local function winOpen()
            local g = winGui()
            local f = g and g:FindFirstChild("Trading")
            return g ~= nil and g.Enabled == true and f ~= nil and f.Visible == true
        end
        -- Returns the trade build / pet-picker frame.
        local function build() return walk(pg(), { "Trading", "Trading", "Build" }) end
        -- True if the pet-picker frame is open.
        local function buildOpen() local b = build() return winOpen() and b ~= nil and b.Visible == true end
        -- Returns the trade Review screen.
        local function reviewOpen()
            local r = walk(pg(), { "Trading", "Trading", "Review" })
            return winOpen() and r ~= nil and r.Visible == true
        end

        -- If the game hides the trade window while hatching, force it on once this player's name shows in it.
        -- It stops as soon as the window is open, so the game can close it normally when the trade ends.
        local function startWindowForce(player, seconds)
            if not player then return end
            task.spawn(function()
                local t0 = os.clock()
                while os.clock() - t0 < (seconds or 120) do
                    local b = build()
                    local nm = b and walk(b, { "Table", "Them", "Name" })
                    if nm and nm:IsA("TextLabel") and nm.Text ~= "" then
                        local t = norm(nm.Text)
                        if t:find(norm(player.Name), 1, true) or t:find(norm(player.DisplayName), 1, true) then
                            local g = winGui()
                            forceOn(g, "trading gui")
                            forceOn(g and g:FindFirstChild("Trading"), "trading frame")
                            forceOn(b, "build")
                            if buildOpen() then return end
                        end
                    end
                    task.wait(0.3)
                end
            end)
        end

        -- Counts the items in a list.
        local function countItems(list)
            local n = 0
            if list then
                for _, c in ipairs(list:GetChildren()) do
                    if c:IsA("GuiObject") and c.Visible then n = n + stackOf(c) end
                end
            end
            return n
        end
        -- Reads how many pets you offered.
        local function offerCount(b)   -- the "n/20" counter on your side; falls back to counting cards
            local l = walk(b, { "Table", "You", "Count", "Label" })
            if l and l:IsA("TextLabel") then
                local a = l.Text:gsub(",", ""):match("(%d+)%s*/%s*%d+")
                if a then return tonumber(a) end
            end
            return countItems(walk(b, { "Table", "You", "List" }))
        end
        -- Reads how many pets the other player offered.
        local function themCount(b) return countItems(walk(b, { "Table", "Them", "List" })) end

        -- True if the other side of the trade is that player.
        local function themIs(b, player)   -- is the other side of the table really this player?
            local l = walk(b, { "Table", "Them", "Name" })
            if not (l and l:IsA("TextLabel")) then return false end
            local t = norm(l.Text)
            return t:find(norm(player.Name), 1, true) ~= nil or t:find(norm(player.DisplayName), 1, true) ~= nil
        end

        -- Cancels the current trade.
        local function cancelTrade()
            local b = build()
            if winOpen() and b then click(walk(b, { "Actions", "Cancel", "Button" })) end
        end

        -- Debug: prints the Review screen.
        local function dumpReview()
            local r = walk(pg(), { "Trading", "Trading", "Review" })
            if not r then return end
            local out = {}
            for _, d in ipairs(r:GetDescendants()) do
                if d:IsA("TextLabel") and d.Visible and d.Text ~= "" then out[#out + 1] = d.Text end
            end
            print("[TSR] review screen texts: " .. table.concat(out, " | "))
        end

        -- ---- cards in the trade window's pet list ----
        -- They are Frames named "TradePet_<id>" and carry PetName / PetTier attributes (Shiny = Rainbow).
        local function isTradeCard(d)
            return d:IsA("Frame") and (d.Name:sub(1, 9) == "TradePet_" or d:GetAttribute("PetName") ~= nil)
        end
        -- Returns the id of a pet card.
        local function cardId(c)
            local id = c:GetAttribute("PetId")
            if id ~= nil then return tostring(id) end
            if c.Name:sub(1, 9) == "TradePet_" then return c.Name:sub(10) end
            return c.Name
        end
        -- Returns the name and tier of a pet card.
        local function cardMeta(c)
            local n, t = c:GetAttribute("PetName"), c:GetAttribute("PetTier")
            if n then return tostring(n), tostring(t or "?") end
            local m = petIndex[cardId(c)]   -- fallback: the Inventory scan
            if m then return m.name, m.tier end
        end
        -- True if a card is blocked (locked / already in a trade / banked).
        local function cardBlock(c)   -- nil = usable, else why not: Lock / Trading (already offered) / Bank
            for _, nm in ipairs({ "Lock", "Trading", "Bank" }) do
                local x = c:FindFirstChild(nm)
                if x and x:IsA("GuiObject") and x.Visible then return nm end
            end
            return nil
        end
        -- True if a card can be used in a trade.
        local function cardUsable(c) return cardBlock(c) == nil end
        local DG = { d = nil }   -- why a pick found nothing (shown in the failure message); one table = one local
        -- Clears the debug record of why a pick found nothing.
        function DG.reset() DG.d = { seen = {}, named = {}, tiers = {}, match = {}, blocked = {}, marks = {}, cards = {}, log = {}, offer0 = nil, offerNow = nil, offerList = "", clicks = 0, noGrow = 0, names = {}, nm = {}, passes = 0 } end
        DG.reset()
        -- Builds the text that explains why a pick found nothing.
        function DG.text(rule)
            local d = DG.d
            -- Counts the cards by tier.
            local function cnt(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end
            local tl = {}
            for t in pairs(d.tiers) do tl[#tl + 1] = t end
            table.sort(tl)
            local bl = {}
            for _, why in pairs(d.blocked) do bl[why] = (bl[why] or 0) + 1 end
            local bt = {}
            for why, n in pairs(bl) do bt[#bt + 1] = why .. " x" .. n end
            local cl = {}
            for _, v in pairs(d.cards or {}) do cl[#cl + 1] = v end
            table.sort(cl)
            while #cl > 3 do table.remove(cl) end
            local main = string.format("list has %d cards, %d named %s (tiers seen: %s), %d match the tier, blocked: %s, matching cards: <%s>, offer at start %s, clicks %d (%s), no-add %d, offer now %s %s",
                cnt(d.seen), cnt(d.named), tostring(rule.name or "?"), #tl > 0 and table.concat(tl, "/") or "none", cnt(d.match),
                #bt > 0 and table.concat(bt, ", ") or "none", #cl > 0 and table.concat(cl, " | ") or "none", tostring(d.offer0),
                d.clicks, table.concat(d.log or {}, " "), d.noGrow, tostring(d.offerNow), d.offerList or "")
            -- what the list really held: every name/tier seen, cards whose name could not be read, how many looks were taken
            local nl, nmCount = {}, 0
            for k in pairs(d.names or {}) do nl[#nl + 1] = k end
            for _ in pairs(d.nm or {}) do nmCount = nmCount + 1 end
            table.sort(nl)
            local totalNames = #nl
            while #nl > 14 do table.remove(nl) end
            return main .. string.format(" | looks %d, cards without a readable name %d, names seen (%d): %s%s", d.passes or 0, nmCount, totalNames,
                #nl > 0 and table.concat(nl, ", ") or "none", totalNames > #nl and ", ..." or "")
        end
        -- Returns the list frame of the trade window.
        local function tradeList(b) return walk(b, { "Inventory", "List" }) end
        -- Returns the usable pet cards in the trade list.
        local function tradeCards(b)
            local out, list = {}, tradeList(b)
            if list then
                for _, d in ipairs(list:GetChildren()) do
                    if isTradeCard(d) then out[#out + 1] = d end
                end
            end
            return out
        end
        -- True if a pet matches a trade rule (name and tier).
        local function ruleMatches(rule, name, tier)
            if rule.name and rule.name ~= "" and norm(rule.name) ~= norm(name) then return false end
            if rule.tier and rule.tier ~= "" and tierNorm(rule.tier) ~= tierNorm(tier) then return false end
            return true
        end

        -- the list only builds about 10 cards at a time, so scroll it to reveal the rest
        -- Waits (max `maxT` s) until the cards in the trade list stop changing, so a scroll is never judged before the list has built its cards.
        local function settleCards(b, maxT)
            local function sig()
                local cs = tradeCards(b)
                local first = cs[1] and cardId(cs[1]) or ""
                local list = tradeList(b)
                return #cs .. "|" .. tostring(first) .. "|" .. tostring(list and math.floor(list.AbsoluteCanvasSize.Y) or 0)
            end
            local last, same, t0 = sig(), 0, os.clock()
            while same < 2 and os.clock() - t0 < (maxT or 2) do
                task.wait(0.25)
                local now = sig()
                if now == last then same = same + 1 else same, last = 0, now end
            end
        end
        -- Scrolls the trade list: dir "top" or "down"; returns true if it moved.
        -- Down = half a window at a time (cards overlap between steps, so none is skipped); at the end of what is built it waits for more cards before it says "bottom".
        local function scrollList(b, dir)
            local list = tradeList(b)
            if not (list and list:IsA("ScrollingFrame")) then return false end
            local function maxYof() return list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y end
            local y = list.CanvasPosition.Y
            if dir == "top" then
                if y < 1 then return false end
                list.CanvasPosition = Vector2.new(0, 0)
                settleCards(b, 2)
                return true
            end
            if y >= maxYof() - 1 then
                -- looks like the bottom: the list may still be building cards, so give it time before giving up
                settleCards(b, 3)
                if y >= maxYof() - 1 then return false end
            end
            local ny = math.min(maxYof(), y + list.AbsoluteWindowSize.Y * 0.5)
            if math.abs(ny - y) < 1 then return false end
            list.CanvasPosition = Vector2.new(0, ny)
            settleCards(b, 2)   -- let the cards of the new position build before they are read
            return true
        end

        -- Waits until the card list stops changing.
        local function waitCardsStable(b)
            local last, stable, t0 = -1, 0, os.clock()
            while stable < 3 and os.clock() - t0 < 8 do
                task.wait(0.5)
                local n = #tradeCards(b)
                dbg("  pet cards in the trade list:", n)
                if n == last then stable = stable + 1 else stable, last = 0, n end
            end
        end

        -- Click ONE usable card that matches the rule and return how many pets it added (0 = none).
        -- A stacked card ("x2") holds several pets and each click adds one, so the same card is clicked again,
        -- but never more times than its stack size (a second click on a single pet could take it back out).
        local function pickOne(b, rule, picked, room)
            for _, c in ipairs(tradeCards(b)) do
                local id = cardId(c)
                do   -- diagnostics only
                    DG.d.seen[id] = true
                    local dn, dt = cardMeta(c)
                    if dn then DG.d.names[tostring(dn) .. "(" .. tostring(dt) .. ")"] = true else DG.d.nm[id] = true end
                    if dn and rule.name and norm(dn) == norm(rule.name) then
                        DG.d.named[id] = true
                        DG.d.tiers[tostring(dt)] = true
                        if ruleMatches(rule, dn, dt) then
                            DG.d.match[id] = true
                            local why = cardBlock(c)
                            if why then DG.d.blocked[id] = why end
                            if not DG.d.cards[id] then   -- which parts of this card are showing; a TradeCheck is shown with its Visible / transparency
                                local parts = {}
                                for _, ch in ipairs(c:GetChildren()) do
                                    if ch:IsA("GuiObject") then
                                        local tag = ch.Name .. (ch.Visible and "" or "(hidden)")
                                        if ch.Name == "TradeCheck" then
                                            local tr = ch:IsA("ImageLabel") and ch.ImageTransparency or ch.BackgroundTransparency
                                            tag = tag .. "[t=" .. string.format("%.1f", tonumber(tr) or -1) .. "]"
                                        end
                                        parts[#parts + 1] = tag
                                    end
                                end
                                table.sort(parts)
                                DG.d.cards[id] = table.concat(parts, "+")
                            end
                        end
                    end
                end
                if not picked[id] and cardUsable(c) then
                    local name, tier = cardMeta(c)
                    if name and ruleMatches(rule, name, tier) then
                        local btn = walk(c, { "Main", "Button" }) or c:FindFirstChildWhichIsA("GuiButton", true)
                        local stack = stackOf(c)
                        local added = 0
                        while added < stack and added < room and c.Parent do
                            local before = offerCount(b)
                            local fired = click(btn)
                            DG.d.clicks = DG.d.clicks + 1
                            local grew = waitFor(function() return offerCount(b) > before end, 3)
                            if not grew then DG.d.noGrow = DG.d.noGrow + 1 end
                            DG.d.log[#DG.d.log + 1] = tostring(before) .. ">" .. tostring(offerCount(b))
                            if offerCount(b) < before then   -- the click took a pet OUT of the offer: click again to put it back
                                click(btn)
                                waitFor(function() return offerCount(b) >= before end, 3)
                            end
                            local delta = grew and (offerCount(b) - before) or 0
                            dbg("  click", name, "(" .. tostring(tier) .. ") stack=" .. stack, "fired=" .. tostring(fired), "offer +" .. delta, "now", offerCount(b))
                            if delta <= 0 then break end
                            added = added + delta
                            task.wait(0.25)
                        end
                        picked[id] = true   -- this card is used up (or could not be clicked)
                        if added > 0 then return added end
                    end
                end
            end
            return 0
        end

        -- Selects the pets for the trade according to the rules.
        local function selectPets(b, rules)
            local picked = {}
            DG.reset()
            DG.d.offer0 = offerCount(b)
            for _, rule in ipairs(rules) do
                local got, loops, nap3 = 0, 0, false
                dbg("choosing", rule.count, "x", rule.tier or "", rule.name or "any pet")
                -- pass 1 scans the whole list; if the rule is still not filled, pass 2 waits for the list to settle and scans it all again
                -- (a pet that was just unequipped, or a card the list had not built yet, shows up on the second look)
                for pass = 1, 3 do
                    if got >= rule.count then break end
                    -- look 3 only when NO card with this name was seen in looks 1 and 2: the list was probably still loading, so wait longer and look again
                    if pass == 3 and next(DG.d.named) ~= nil then break end
                    DG.d.passes = pass
                    if pass >= 2 then
                        dbg("  not enough found - looking through the whole list again (look " .. pass .. ")")
                        if pass == 3 then nap3 = true task.wait(4) end
                        waitCardsStable(b)
                    end
                    scrollList(b, "top")
                    settleCards(b, 2)
                    while got < rule.count and loops < 300 do
                        loops = loops + 1
                        local n = pickOne(b, rule, picked, rule.count - got)
                        if n > 0 then
                            got = got + n
                        elseif not scrollList(b, "down") then
                            break   -- bottom of the list reached and nothing more matches
                        else
                            dbg("  scrolled the list, cards now:", #tradeCards(b))
                        end
                    end
                end
                if got > rule.count then
                    return false, "a click added more pets than asked (" .. got .. " instead of " .. rule.count .. ")"
                end
                if got < rule.count then
                    DG.d.offerNow = offerCount(b)
                    do
                        local names, lst = {}, walk(b, { "Table", "You", "List" })
                        if lst then
                            for _, ch in ipairs(lst:GetChildren()) do
                                if ch:IsA("GuiObject") and ch.Visible then names[#names + 1] = tostring(ch:GetAttribute("PetName") or ch.Name) .. "/" .. tostring(ch:GetAttribute("PetTier") or "?") end
                            end
                        end
                        DG.d.offerList = #names > 0 and ("in offer: " .. table.concat(names, ", ")) or "offer list empty"
                    end
                    local why = "found only " .. got .. " of " .. rule.count .. " " .. (rule.tier or "") .. " " .. (rule.name or "any pet")
                    print("[TSR] " .. why .. " | " .. DG.text(rule))
                    return false, why .. " [" .. DG.text(rule) .. "]"
                end
            end
            return true
        end

        -- Checks and cleans a trade request.
        local function sanitize(trade)   -- whatever the site sent: check it again before touching anything
            local partner = tostring(trade.partner or "")
            if not partner:match("^[%w_]+$") then return nil, "bad partner name" end
            local rules, total = {}, 0
            for _, p in ipairs(type(trade.pets) == "table" and trade.pets or {}) do
                local c = math.floor(tonumber(p.count) or 0)
                if c >= 1 then
                    rules[#rules + 1] = { name = tostring(p.name or ""), tier = tostring(p.tier or ""), count = c }
                    total = total + c
                end
            end
            local delay = math.clamp(tonumber(trade.readyDelay) or 6, 1, 60)
            local unequip = {}
            for _, u in ipairs(type(trade.unequip) == "table" and trade.unequip or {}) do
                local c = math.floor(tonumber(u.count) or 0)
                if c >= 1 then unequip[#unequip + 1] = { name = tostring(u.name or ""), tier = tostring(u.tier or ""), count = c } end
            end
            return { partner = partner, rules = rules, total = total, delay = delay, expect = tonumber(trade.expect) or total, unequip = unequip }
        end

        -- The game sometimes leaves a FINISHED trade window on screen: empty, "0/20", "Choosing...". That is only visual,
        -- but it must not count as a failed trade. After Ready, an empty window with no Review screen = the trade is over.
        local function windowIsReset()
            local b = build()
            return winOpen() and b ~= nil and b.Visible == true and not reviewOpen() and offerCount(b) == 0 and themCount(b) == 0
        end
        -- Closes a trade window that was left open.
        local function closeStaleWindow()
            local g = winGui()
            if not (g and winOpen()) then return end
            click(walk(build(), { "Actions", "Cancel", "Button" }))   -- also ends a fresh empty session, if the game opened one
            task.wait(1)
            if winOpen() then
                g.Enabled = false
                dbg("FORCED closed: leftover trading window")
            end
        end

        -- ---- v10: Ready -> Review -> CONFIRM (new step in the game's trade) ----
        -- Flow seen in the remote capture:  Lock (our "Ready") -> Review -> Confirm (both sides) -> Countdown 4s -> Processing -> Completed
        -- ---- v11: AUTO TRADE (the hub's Trade tab): Auto Accept / Auto Ready / Auto Confirm ----
        -- Driven by the game's own TradeUpdate remote and answered with the same TradeRequested calls the buttons send.
        -- They only act for TRUSTED players (Trusted Names box, ALLOWED_PARTNERS, or "Accept From Anyone"), and never while a
        -- trade job from the site is running (tradeBusy): the site jobs keep their own accept / ready / confirm flow.
        local Auto = { accept = true, ready = true, confirm = true, anyone = false, names = {} }
        -- Auto Trade (Pay First) state. While PF.on is true, the three trusted-player toggles below stand down so the two never answer the same trade.
        local PF = { on = false, sel = {}, amount = 0, active = false, other = nil, rev = 0, uids = {}, uidSet = {},
            offerOk = false, tokens = 0, locked = false, cdUntil = 0, looping = false, acceptUntil = 0, gen = 0 }
        local autoState = {}
        local autoHandle   -- assigned further down, called by the TradeUpdate listener
        local READY_DELAY = 2.5   -- the partner's offer must stay unchanged this long before Auto Ready locks

        local RS = game:GetService("ReplicatedStorage")
        local tradeUpdateRE  = walk(RS, { "RemoteServices", "TradingService", "RE", "TradeUpdate" })
        local tradeRequestRE = walk(RS, { "RemoteServices", "TradingService", "RE", "TradeRequested" })
        local tflags = {}
        local giveActive = false   -- true while this account is the GIVER of a running trade job
        -- Resets the trade flags on the server side.
        local function resetTradeFlags() tflags = {} end
        if tradeUpdateRE then
            tradeUpdateRE.OnClientEvent:Connect(function(d)   -- passive listener, sends nothing
                if type(d) ~= "table" then return end
                local ty = d.Type
                if autoHandle then pcall(autoHandle, d) end
                if ty == "Started" then tflags = { startedAt = os.clock() }
                elseif ty == "Review" then tflags.review = true
                elseif ty == "Confirm" then
                    if d.UserId == lp.UserId then tflags.myConfirm = true else tflags.theirConfirm = true end
                elseif ty == "Countdown" then tflags.countdown = true
                elseif ty == "Completed" then tflags.completed = true
                end
            end)
        else
            warn("[TSR] TradingService.RE.TradeUpdate not found: Confirm will rely on the window only")
        end

        -- Presses the Confirm button of the trade.
        local function pressConfirm()
            -- 1) the real button on the Review screen (a Frame/Button named "Confirm", usually with a child "Button")
            local r = walk(pg(), { "Trading", "Trading", "Review" })
            if r then
                for _, d in ipairs(r:GetDescendants()) do
                    if norm(d.Name) == "confirm" then
                        local btn = d:IsA("GuiButton") and d or d:FindFirstChild("Button")
                        if btn and click(btn) then dbg("Confirm: clicked", d:GetFullName()) break end
                    end
                end
            end
            if waitFor(function() return tflags.myConfirm or tflags.completed end, 2) then return true end
            -- 2) fallback: send exactly what the game's own button sends
            if tradeRequestRE then
                dbg("Confirm: button did not register, firing TradeRequested {Action='Confirm'}")
                tradeRequestRE:FireServer({ Action = "Confirm" })
                return waitFor(function() return tflags.myConfirm or tflags.completed end, 3) ~= nil
            end
            return false
        end


        -- ---- v11: Auto Accept / Ready / Confirm logic ----
        local function autoActive() return autoState.active and (os.clock() - (autoState.startedAt or 0)) < 180 end
        -- Sets the trusted names for Auto Trade from a text.
        local function autoSetNames(text)
            Auto.names = {}
            for tok in tostring(text or ""):gmatch("[^,%s;]+") do Auto.names[norm(tok)] = true end
        end
        -- True if a name / user id is trusted for auto trading.
        local function autoTrusted(name, uid)
            if Auto.anyone then return true end
            local n = norm(name)
            if n ~= "" and Auto.names[n] then return true end
            if uid and Auto.names[tostring(uid)] then return true end
            for _, a in ipairs(ALLOWED_PARTNERS) do if n ~= "" and norm(a) == n then return true end end
            return false
        end
        -- Sends a trade request through the remote.
        local function autoFire(args)
            if tradeRequestRE then pcall(function() tradeRequestRE:FireServer(args) end) end
        end
        -- Counts the pets offered in a trade table.
        local function offerSize(d)
            local n = 0
            for _, r in ipairs(type(d.Refs) == "table" and d.Refs or {}) do n = n + (tonumber(r.Amount) or 1) end
            if (tonumber(d.Tokens) or 0) > 0 then n = n + 1 end
            return n
        end

        autoHandle = function(d)
            if PF.on then return end   -- Auto Trade (Pay First) is running
            local ty = d.Type
            if ty == "Request" then
                if not Auto.accept or tradeBusy or autoActive() then return end
                if not autoTrusted(d.FromName, d.FromUserId) then
                    dbg("auto accept: ignored a request from " .. tostring(d.FromName) .. " (not trusted)")
                    return
                end
                task.delay(0.8, function()
                    if tradeBusy or autoActive() or not Auto.accept then return end
                    dbg("auto accept: accepting " .. tostring(d.FromName))
                    autoFire({ Action = "Respond", Accepted = true })
                end)
            elseif ty == "Started" then
                local other = (d.A == lp.UserId) and d.B or d.A
                local pl = other and Players:GetPlayerByUserId(other)
                autoState = { active = true, startedAt = os.clock(), partnerId = other, partnerName = pl and pl.Name or "",
                    theirCount = 0, ourCount = 0, theirAt = 0, locked = false, confirmed = false }
            elseif autoActive() then
                if ty == "Offer" then
                    if d.UserId == lp.UserId then
                        autoState.ourCount, autoState.locked = offerSize(d), false
                    elseif d.UserId == autoState.partnerId then
                        autoState.theirCount, autoState.theirAt, autoState.locked = offerSize(d), os.clock(), false
                    end
                elseif ty == "Lock" then
                    if d.UserId == lp.UserId then autoState.locked = true end
                elseif ty == "Review" then
                    if Auto.confirm and not tradeBusy and not autoState.confirmed
                        and autoTrusted(autoState.partnerName, autoState.partnerId) then
                        autoState.confirmed = true
                        local st = autoState
                        task.delay(1, function()
                            if autoState == st and not tradeBusy and Auto.confirm then
                                dbg("auto confirm: confirming with " .. tostring(st.partnerName))
                                autoFire({ Action = "Confirm" })
                            end
                        end)
                    end
                elseif ty == "Completed" then
                    autoState.active = false
                end
            end
        end

        -- called every 0.5 s: Auto Ready (pure receive only: the partner offers something, we offer nothing)
        local function autoTick()
            if PF.on then return end   -- Auto Trade (Pay First) is running
            local s = autoState
            if Auto.ready and autoActive() and not tradeBusy and not s.locked and s.ourCount == 0 and s.theirCount > 0
                and (os.clock() - s.theirAt) >= READY_DELAY and autoTrusted(s.partnerName, s.partnerId) then
                s.locked = true
                dbg("auto ready: locking, " .. tostring(s.theirCount) .. " from " .. tostring(s.partnerName))
                autoFire({ Action = "Lock", Locked = true })
            end
        end

        -- everything after pressing Ready (same for give and receive)
        local function finishTrade(id)
            waitFor(function()
                return tflags.review or reviewOpen() or tflags.completed or not winOpen() or windowIsReset() or abortRequested
            end, 45)
            if abortRequested and not tflags.completed then
                pcall(cancelTrade)
                return setTrade(id, "failed", false, "stopped by the site")
            end
            if (tflags.review or reviewOpen()) and not tflags.completed then
                task.wait(0.5)
                dumpReview()
                setTrade(id, "review", true, "review screen open, pressing Confirm")
                if pressConfirm() then
                    setTrade(id, "confirmed", true, "pressed Confirm, waiting for the countdown / processing")
                else
                    setTrade(id, "confirm_failed", false, "Confirm did not register (see console)")
                end
                waitFor(function() return tflags.completed or not winOpen() or windowIsReset() end, 60)
            end
            closeMenu("Trade")
            if winOpen() and windowIsReset() then closeStaleWindow() end
            if tflags.completed then
                setTrade(id, "done", true, "trade completed")
            elseif winOpen() then
                setTrade(id, "stuck", false, "still open after Confirm (see the Review screen output in the console)")
            else
                setTrade(id, "done", true, "trade window closed (completed or cancelled by the other side)")
            end
        end

        -- v12: DIRECT OFFER. Puts the pets into the trade with the game's own Offer request (pet ids from the pet data), exactly like
        -- Auto Trade (Pay First) does, instead of scrolling the trade window and clicking cards. The server's echo of our offer is checked;
        -- if it does not show the pets, other copies are tried (up to 3 tries). Returns true, or false + the reason (the caller then
        -- falls back to the old card-clicking method).
        local function directOffer(b, rules, total)
            if not (tradeRequestRE and tradeUpdateRE) then return false, "trade remotes not found" end
            local bad, rev, lastWhy = {}, 0, "?"
            for try = 1, 3 do
                local groups = DATA.tradePets(nil, bad)
                if not groups then return false, "pet data not loaded" end
                local refs, set, used = {}, {}, {}
                for _, rule in ipairs(rules) do
                    local need = rule.count
                    for _, g in pairs(groups) do
                        if need <= 0 then break end
                        if ruleMatches(rule, g.name, g.tier) then
                            for _, u in ipairs(g.uids) do
                                if need <= 0 then break end
                                if not used[u] then
                                    used[u], set[u] = true, true
                                    refs[#refs + 1] = { Uid = u, TypeName = "Pet", Amount = 1 }
                                    need = need - 1
                                end
                            end
                        end
                    end
                    if need > 0 then
                        return false, "pet data has only " .. (rule.count - need) .. " of " .. rule.count .. " free " .. (rule.tier or "") .. " " .. (rule.name or "any pet") .. (try > 1 and " (after a retry)" or "")
                    end
                end
                if #refs ~= total then return false, "picked " .. #refs .. " pets but expected " .. total end

                -- is this Offer event (ours, echoed by the server) exactly the pets we sent?
                local function isMine(d)
                    local list = (type(d.Pets) == "table" and d.Pets) or (type(d.Refs) == "table" and d.Refs) or {}
                    local n, seen = 0, {}
                    for _, e in pairs(list) do
                        if type(e) ~= "table" then return false end
                        local id = tostring(e.Uid or e.Id or e.PetId)
                        if not set[id] then return false end
                        seen[id] = true
                        n = n + 1
                    end
                    for u in pairs(set) do if not seen[u] then return false end end
                    return n > 0
                end

                rev = rev + 1
                local acked = false
                local conn = tradeUpdateRE.OnClientEvent:Connect(function(d)
                    if type(d) == "table" and d.Type == "Offer" and d.UserId == lp.UserId and isMine(d) then acked = true end
                end)
                pcall(function() tradeRequestRE:FireServer({ Revision = rev, Action = "Offer", Refs = refs }) end)
                dbg("direct offer: sent", #refs, "pets, revision", rev, "try", try)
                local t0 = os.clock()
                while not acked and os.clock() - t0 < 6 and buildOpen() and not abortRequested do
                    task.wait(0.2)
                    if offerCount(b) == total then acked = true end   -- the window already shows them
                end
                conn:Disconnect()
                if acked then return true end
                if not buildOpen() then return false, "trade window closed" end
                if abortRequested then return false, "stopped by the site" end
                for u in pairs(set) do bad[u] = true end   -- the server did not take these: try other copies
                lastWhy = "the server never showed the pets (try " .. try .. ")"
            end
            return false, lastWhy
        end

        -- Runs a "give" trade command.
        local function runGive(cmd)
            local id = cmd.id
            local t, err = sanitize(cmd.trade)
            if not t then return setTrade(id, "failed", false, err) end
            if t.total < 1 or t.total > MAX_OFFER then return setTrade(id, "failed", false, "pet count must be 1-" .. MAX_OFFER) end
            if not partnerAllowed(t.partner) then return setTrade(id, "failed", false, t.partner .. " is not in ALLOWED_PARTNERS") end
            local target = findPlayer(t.partner)
            if not target then return setTrade(id, "failed", false, t.partner .. " is not in this server") end

            if #t.unequip > 0 then
                setTrade(id, "unequipping", true, "taking equipped pets off before the trade")
                local okU, nU = pcall(SecretGuard.unequipPets, t.unequip)
                if not okU then dbg("unequip before trade failed: " .. tostring(nU)) end
                t.unqNote = "unequip 1st: " .. tostring(nU)
                setTrade(id, "unequipping", true, okU and ("took " .. tostring(nU) .. " equipped pet(s) off") or ("unequip error: " .. tostring(nU)))
                task.wait(1)
            end

            setTrade(id, "scanning", true, "reading pet data (and unlocking locked pets)")
            pcall(refreshPets, true, function(nm, tr)
                for _, r in ipairs(t.rules) do if ruleMatches(r, nm, tr) then return true end end
                return false
            end)
            if next(petIndex) == nil then return setTrade(id, "failed", false, "no pets found in the pet data") end

            -- 1) open the Trade menu (also while hatching) and send the request
            if not openMenu("Trade", { "Game", "LeftButtons", "Trade", "Button" }) then
                return setTrade(id, "failed", false, "trade menu did not open")
            end
            local row = waitFor(function()
                return walk(pg(), { "Tabs", "Trade", "Menu", "Inner", "Trade", "Player_" .. target.UserId })
            end, 8)
            if not row then return setTrade(id, "failed", false, t.partner .. " is not in the trade list (their trade setting?)") end
            if not click(walk(row, { "SendRequestButton", "Button" })) then
                return setTrade(id, "failed", false, "could not press Trade")
            end
            setTrade(id, "requested", true, "request sent to " .. t.partner .. ", waiting for them to accept")
            startWindowForce(target, 120)

            -- 2) wait for the trade window
            local opened = waitFor(function() return buildOpen() or abortRequested end, 90)
            if abortRequested then cancelTrade() return setTrade(id, "failed", false, "stopped by the site") end
            if not opened then
                return setTrade(id, "failed", false, t.partner .. " did not accept in 90 seconds")
            end
            dbg("trade window opened, waiting " .. OPEN_DELAY .. "s before choosing pets")
            task.wait(OPEN_DELAY)
            local b = build()
            if not b or not buildOpen() then return setTrade(id, "failed", false, "the trade window closed right after opening") end
            if not themIs(b, target) then
                cancelTrade()
                return setTrade(id, "failed", false, "the other side is not " .. t.partner .. ", cancelled")
            end

            closeMenu("Trade")   -- the player-list menu is not needed any more once the trade window is open

            -- 3) put the pets in
            setTrade(id, "selecting", true, "choosing pets")
            if #t.unequip > 0 then   -- the window can take a while to open: make sure nothing was put back on, then let the list refresh
                local okU2, nU2 = pcall(SecretGuard.unequipPets, t.unequip)
                t.unqNote = (t.unqNote or "") .. ", 2nd: " .. tostring(nU2)
                if okU2 and (tonumber(nU2) or 0) > 0 then task.wait(1.5) end
            end
            local ok, why = true, nil
            local dOk, dWhy = directOffer(b, t.rules, t.total)   -- v12: same way Auto Trade (Pay First) offers pets
            if not dOk then
                dbg("direct offer failed (" .. tostring(dWhy) .. "), falling back to clicking the cards")
                t.unqNote = (t.unqNote and (t.unqNote .. ", ") or "") .. "direct offer: " .. tostring(dWhy)
                if not buildOpen() then return setTrade(id, "failed", false, "the trade window closed while offering (" .. tostring(dWhy) .. ")") end
                if offerCount(b) > 0 then   -- something may have landed: clicking on top of it could overfill the offer
                    cancelTrade()
                    return setTrade(id, "failed", false, "direct offer failed (" .. tostring(dWhy) .. ") and the offer is not empty, cancelled")
                end
                waitCardsStable(b)
                ok, why = selectPets(b, t.rules)
            end
            if not ok then cancelTrade() return setTrade(id, "failed", false, why .. (t.unqNote and (" {" .. t.unqNote .. "}") or "") .. ", cancelled") end
            if offerCount(b) ~= t.total then
                cancelTrade()
                return setTrade(id, "failed", false, "offer shows " .. offerCount(b) .. " but expected " .. t.total .. ", cancelled")
            end

            -- 4) wait, re-check, press Ready
            setTrade(id, "waiting", true, "offer ready, pressing Ready in " .. t.delay .. "s")
            task.wait(t.delay)
            if not buildOpen() or offerCount(build()) ~= t.total or not themIs(build(), target) then
                cancelTrade()
                return setTrade(id, "failed", false, "offer changed before Ready, cancelled")
            end
            click(walk(build(), { "Actions", "Ready", "Button" }))
            setTrade(id, "ready", true, "pressed Ready, waiting for the other side")

            -- 5) Review screen -> Confirm -> countdown -> done
            finishTrade(id)
        end

        -- Runs a "receive" trade command.
        local function runReceive(cmd)
            local id = cmd.id
            local t, err = sanitize(cmd.trade)   -- here "partner" is the SENDER we are allowed to accept from
            if not t then return setTrade(id, "failed", false, err) end
            if not partnerAllowed(t.partner) then return setTrade(id, "failed", false, t.partner .. " is not in ALLOWED_PARTNERS") end
            if t.expect < 1 or t.expect > MAX_OFFER then return setTrade(id, "failed", false, "bad expected pet count") end
            setTrade(id, "waiting", true, "waiting for a trade request from " .. t.partner)
            startWindowForce(findPlayer(t.partner), 200)

            -- 1) accept the request, but only from that player
            local accepted = waitFor(function()
                if abortRequested then return "abort" end
                if buildOpen() then return "open" end
                -- v9: the game keeps TradeQuest.Enabled = false while hatching, but it still fills in the text, so
                -- we do NOT require Enabled. We match the sender's name, force the popup on, and press Accept.
                local q = walk(pg(), { "Tabs", "TradeQuest" })
                if q then
                    local from = findPlayer(t.partner)
                    local l = walk(q, { "Menu", "PlayerSent" })
                    local txt = l and norm(l.Text) or ""
                    if from and (txt:find(norm(from.Name), 1, true) or txt:find(norm(from.DisplayName), 1, true)) then
                        forceOn(q, "trade request popup")
                        forceOn(walk(q, { "Menu" }), "trade request menu")
                        local btn = walk(q, { "Menu", "Accept", "Button" })
                        local fired = click(btn)
                        if not fired and btn and type(firesignal) == "function" then
                            pcall(function() firesignal(btn.MouseButton1Click) end)
                            pcall(function() firesignal(btn.Activated) end)
                        end
                        dbg("pressed Accept on the trade request, fired =", tostring(fired))
                        task.wait(1.5)
                    end
                end
                return false
            end, 180)
            if accepted == "abort" then cancelTrade() return setTrade(id, "failed", false, "stopped by the site") end
            if not accepted then return setTrade(id, "failed", false, "no request from " .. t.partner .. " in 3 minutes") end

            -- 2) wait until the offer is exactly what we expect
            if not waitFor(buildOpen, 20) then return setTrade(id, "failed", false, "trade window did not open") end
            local sender = findPlayer(t.partner)
            if not sender or not themIs(build(), sender) then
                cancelTrade()
                return setTrade(id, "failed", false, "the other side is not " .. t.partner .. ", cancelled")
            end
            setTrade(id, "checking", true, "waiting for " .. t.expect .. " pets in the offer")
            if not waitFor(function() return themCount(build()) == t.expect or abortRequested end, 120) or abortRequested then
                cancelTrade()
                if abortRequested then return setTrade(id, "failed", false, "stopped by the site") end
                return setTrade(id, "failed", false, "offer never reached " .. t.expect .. " pets (it shows " .. themCount(build()) .. "), cancelled")
            end

            -- 3) wait, re-check, press Ready
            task.wait(t.delay)
            if not buildOpen() or themCount(build()) ~= t.expect or not themIs(build(), sender) then
                cancelTrade()
                return setTrade(id, "failed", false, "offer changed before Ready, cancelled")
            end
            click(walk(build(), { "Actions", "Ready", "Button" }))
            setTrade(id, "ready", true, "pressed Ready")

            -- 4) Review screen -> Confirm -> countdown -> done
            finishTrade(id)
        end

        -- ---- while a site trade job runs, Kaitun Hatch and Auto Hatch are switched off; afterwards only what was on is switched back on ----
        -- (hatching teleports you to the egg every 2 s and fights the trade window, so trades failed while hatching)
        local hatchPaused = nil   -- { kaitun = entry or nil, hatch = entry or nil } = what WE switched off
        -- True if a toggle entry is currently on.
        local function entryIsOn(e) return e ~= nil and e._get ~= nil and e._get() == true end
        -- Pauses Auto Hatch while a trade runs.
        local function pauseHatching()
            if hatchPaused then return end
            local kEntry = Logic and Logic.kaitun and Logic.kaitun.main
            local hEntry = Logic and Logic.hatch
            local p = {
                kaitun = entryIsOn(kEntry) and kEntry or nil,
                hatch = entryIsOn(hEntry) and hEntry or nil,
            }
            if not (p.kaitun or p.hatch) then return end
            hatchPaused = p
            if p.kaitun and kEntry._setUI then pcall(kEntry._setUI, false) end   -- also switches off what Kaitun Hatch runs (hatch, craft, rebirth, equip)
            if entryIsOn(hEntry) and hEntry._setUI then pcall(hEntry._setUI, false) end   -- a manually started Auto Hatch (or one Kaitun skipped)
            print("[TSR] trade: hatching paused (" .. (p.kaitun and "Kaitun Hatch" or "") .. ((p.kaitun and p.hatch) and " + " or "") .. (p.hatch and "Auto Hatch" or "") .. ")")
            task.wait(2)   -- let the hatch loop stop and the game's auto hatch (F) switch off before the trade menu opens
        end
        -- Resumes Auto Hatch after a trade.
        local function resumeHatching()
            local p = hatchPaused
            if not p then return end
            hatchPaused = nil
            if not alive then return end
            -- Kaitun first (it holds hatching until Auto Delete is set up again), then a plain Auto Hatch if it was on
            if p.kaitun and p.kaitun._setUI and not entryIsOn(p.kaitun) then pcall(p.kaitun._setUI, true) end
            if p.hatch and p.hatch._setUI and not entryIsOn(p.hatch) then pcall(p.hatch._setUI, true) end
            print("[TSR] trade: hatching resumed")
        end

        -- Handles one trade command (rejects it when another one is running).
        local function handleTrade(cmd)
            if tradeBusy then return setTrade(cmd.id, "rejected", false, "another trade job is still running") end
            tradeBusy = true
            abortRequested = false
            resetTradeFlags()
            giveActive = (cmd.trade and cmd.trade.role == "give") and true or false
            pcall(pauseHatching)
            if giveActive then pcall(SecretGuard.hold, true) end
            local ok, e = pcall(function()
                local role = cmd.trade and cmd.trade.role
                if role == "give" then runGive(cmd)
                elseif role == "receive" then runReceive(cmd)
                else setTrade(cmd.id, "failed", false, "unknown trade role") end
            end)
            if not ok then
                pcall(cancelTrade)
                setTrade(cmd.id, "failed", false, "error: " .. tostring(e))
            end
            pcall(SecretGuard.hold, false)
            tradeBusy = false
            giveActive = false
            pcall(waitFor, function() return not winOpen() end, 10)   -- let the trade window close before hatching comes back
            pcall(resumeHatching)   -- done, failed or aborted: always put back what was switched off
            lastScanAt = 0   -- rescan soon so the site shows the new inventory
        end

        -- =====================================================================================

        -- =====================================================================================
        -- HATCHES: the total eggs opened. The Worker compares it between two heartbeats: changed = "Hatching ..."
        -- =====================================================================================
        local HATCHES_PATH = nil   -- optional: path to the TextLabel that shows your eggs opened, e.g. { "SomeGui", "Frame", "Eggs" }
        local hatchSrc, hatchWarned = nil, false

        -- Turns text with digits into a number.
        local function numFromText(t)
            local digits = tostring(t or ""):gsub(",", ""):match("^%s*(%d+)%s*$")
            return digits and tonumber(digits) or nil
        end

        -- Reads your hatch count from the game.
        local function readHatches()
            -- 0) a path you set yourself
            if HATCHES_PATH then
                local l = walk(pg(), HATCHES_PATH)
                local v = l and l:IsA("TextLabel") and numFromText(l.Text)
                if v then hatchSrc = "HATCHES_PATH" return v end
            end
            -- 1) leaderstats values and attributes on the player
            local ls = lp:FindFirstChild("leaderstats")
            for _, v in ipairs(ls and ls:GetChildren() or {}) do
                local n = v.Name:lower()
                if (n:find("egg") or n:find("hatch")) and v:IsA("ValueBase") and tonumber(v.Value) then
                    hatchSrc = "leaderstats." .. v.Name
                    return tonumber(v.Value)
                end
            end
            for k, v in pairs(lp:GetAttributes()) do
                local n = tostring(k):lower()
                if (n:find("egg") or n:find("hatch")) and type(v) == "number" then
                    hatchSrc = "attribute " .. tostring(k)
                    return v
                end
            end
            -- 2) the on-screen player list: find this player's row and read its plain number (e.g. 207,485)
            local plist = pg() and pg():FindFirstChild("PlayerList")
            if plist then
                local me1, me2 = norm(lp.Name), norm(lp.DisplayName)
                for _, d in ipairs(plist:GetDescendants()) do
                    if d:IsA("TextLabel") then
                        local t = norm(d.Text)
                        if t == me1 or t == me2 or t == "@" .. me1 then
                            local row = d.Parent
                            for _ = 1, 4 do
                                if not row or row == plist then break end
                                for _, x in ipairs(row:GetDescendants()) do
                                    if x:IsA("TextLabel") and x ~= d then
                                        local v = numFromText(x.Text)
                                        if v then hatchSrc = "PlayerList row" return v end
                                    end
                                end
                                row = row.Parent
                            end
                        end
                    end
                end
            end
            return nil
        end

        local okCount = 0

        -- Scripts and trades sent from the site arrive in the heartbeat reply. Each one runs once.
        local doneCmds = {}
        -- Runs the commands that came back from the server.
        local function runCommands(body)
            local okd, data = pcall(function() return HttpService:JSONDecode(body) end)
            if not okd or type(data) ~= "table" then return end
            everyNow = data.fast and EVERY_FAST or EVERY
            if type(data.commands) ~= "table" then return end
            for _, c in ipairs(data.commands) do
                if type(c) == "table" and c.id and not doneCmds[c.id] then
                    doneCmds[c.id] = true
                    if c.type == "trade" and type(c.trade) == "table" and c.trade.role == "abort" then
                        abortRequested = true   -- stops a running trade job at its next wait, and closes the window if it is open
                        if tradeBusy then pcall(cancelTrade) end
                        print("[TSR] stop requested by the site")
                    elseif c.type == "trade" and type(c.trade) == "table" then
                        task.spawn(handleTrade, c)
                    else
                        task.spawn(function()
                            local label = tostring(c.name or "script")
                            local f, err = loadstring(tostring(c.code or ""))
                            if not f then warn("[TSR] script \"" .. label .. "\" has an error: " .. tostring(err)) return end
                            print("[TSR] running script: " .. label)
                            local okr, e2 = pcall(f)
                            if not okr then warn("[TSR] script \"" .. label .. "\" crashed: " .. tostring(e2)) end
                        end)
                    end
                end
            end
        end
        -- ACTIVITY + HATCH RATE (shown on the site's Status page; sent inside "pets" so the Worker stores it as-is)
        local hSamples = {}   -- { t = os.clock(), h = eggs opened } for the last RATE_WINDOW seconds
        local RATE_WINDOW = 300
        -- Calculates the hatch rate.
        local function hatchRate(h)
            if type(h) ~= "number" then return nil, nil end
            local now = os.clock()
            local first = hSamples[1]
            if first and h < first.h then hSamples = {} end   -- counter went backwards (rejoin / reset)
            hSamples[#hSamples + 1] = { t = now, h = h }
            while #hSamples > 2 and now - hSamples[1].t > RATE_WINDOW do table.remove(hSamples, 1) end
            local a, b = hSamples[1], hSamples[#hSamples]
            local dt = b.t - a.t
            if dt < 20 then return nil, nil end
            local perMin = (b.h - a.h) / (dt / 60)
            return math.floor(perMin * 10 + 0.5) / 10, math.floor(perMin * 60 + 0.5)
        end
        local ACT_SOURCES = {}
        if Logic then
            for _, k in ipairs({ "hatch", "craft", "dCraft", "rCraft", "collect", "scan" }) do
                if Logic[k] then ACT_SOURCES[#ACT_SOURCES + 1] = Logic[k] end
            end
            if Logic.enchant and Logic.enchant.auto then ACT_SOURCES[#ACT_SOURCES + 1] = Logic.enchant.auto end
            if Logic.enchant and Logic.enchant.v2 then ACT_SOURCES[#ACT_SOURCES + 1] = Logic.enchant.v2 end
            if Logic.halloween then
                ACT_SOURCES[#ACT_SOURCES + 1] = Logic.halloween.treat
                ACT_SOURCES[#ACT_SOURCES + 1] = Logic.halloween.boss
                ACT_SOURCES[#ACT_SOURCES + 1] = Logic.halloween.shop
            end
            if Logic.dig then ACT_SOURCES[#ACT_SOURCES + 1] = Logic.dig.toggle end
            if Logic.balloon then ACT_SOURCES[#ACT_SOURCES + 1] = Logic.balloon.toggle end
        end
        -- Returns what the hub is doing right now.
        local function currentActivity()   -- ONE short line: the single thing the hub is doing right now
            local best, bestWait
            for _, src in ipairs(ACT_SOURCES) do
                local ok, txt = pcall(function()
                    if src._get and src._get() and src._desc and src._desc.Parent then return src._desc.Text end
                end)
                if ok and type(txt) == "string" and txt ~= "" then
                    txt = txt:match("^[^\n]*"):match("^(.-)%s*|") or txt:match("^[^\n]*")   -- first line, first part only
                    if #txt > 45 then txt = txt:sub(1, 42) .. "..." end
                    local line = tostring(src.name or "?") .. ": " .. txt
                    local low = txt:lower()
                    if low:find("waiting") or low:find("paused") or low:find("retry") then
                        bestWait = bestWait or line
                    elseif not best then
                        best = line
                    end
                end
            end
            return best or bestWait or "Idle"
        end

        local countWarned = false
        -- Sends a regular status message (heartbeat) to the server.
        local function heartbeat()
            if not httpRequest then return end
            if not tradeBusy and os.clock() - lastScanAt >= RESCAN then pcall(refreshPets) end

            local pets = lastPets or { scanned = 0, equipped = {}, grouped = {} }
            -- counters can be read without opening anything when the labels exist
            -- Pet count: the game's replicated data is the truth (read live every heartbeat).
            -- The Storage label is only a fallback: while the Inventory is closed it can be stale (it showed 999).
            local liveOk, live = pcall(DATA.count)
            if liveOk and live and live > 0 then pets.owned = live end
            local uiOwned, uiCapacity = parseCount(labelText({ "Tabs", "Inventory", "Menu", "Categories", "Pets", "Stats", "Storage" }))
            if not pets.owned and uiOwned then pets.owned = uiOwned end
            if not pets.capacity and uiCapacity then pets.capacity = uiCapacity end
            if uiOwned and pets.owned and uiOwned ~= pets.owned and not countWarned then
                countWarned = true
                print(string.format("[TSR] pet count: game data says %d, the Storage label says %d (label ignored)", pets.owned, uiOwned))
            end
            local eqNow, eqMax = parseCount(labelText({ "Tabs", "Inventory", "Menu", "Categories", "Pets", "Stats", "Equipped" }))
            if eqNow then pets.equippedCount, pets.equippedMax = eqNow, eqMax end
            pets.stale = (os.clock() - lastScanAt) > RESCAN * 2

            local okh, hatches = pcall(readHatches)
            if not okh then hatches = nil end
            if hatches == nil and not hatchWarned then
                hatchWarned = true
                warn("[TSR] could not find your eggs-opened number, so the site will never show \"Hatching\". Set HATCHES_PATH.")
            elseif hatches ~= nil and hatchSrc then
                dbg("hatches =", hatches, "(from " .. hatchSrc .. ")")
                hatchSrc = nil
            end

            local perMin, perHour = hatchRate(hatches)
            pets.hatchPerMin, pets.hatchPerHour = perMin, perHour
            local okA, act = pcall(currentActivity)
            pets.activity = okA and act or nil

            local ok, res = pcall(httpRequest, {
                Url = WORKER_URL .. "/agent/heartbeat", Method = "POST",
                Headers = { ["Content-Type"] = "application/json", ["x-key"] = AGENT_KEY },
                Body = HttpService:JSONEncode({
                    name = lp.Name, userId = lp.UserId, game = "Tap Simulator Reborn",
                    state = "online", placeId = game.PlaceId, jobId = game.JobId, pets = pets, hatches = hatches,
                    lastTrade = lastTrade,
                }),
            })
            local code = ok and type(res) == "table" and tonumber(res.StatusCode) or nil
            if code == 200 then
                okCount = okCount + 1
                print(string.format("[TSR] heartbeat OK #%d (owned %s, scanned %d)", okCount, tostring(pets.owned), pets.scanned or 0))
                if type(res.Body) == "string" then runCommands(res.Body) end
            elseif code == 401 then
                warn("[TSR] 401: the AGENT_KEY in this script does not match the one in Cloudflare")
            else
                warn("[TSR] heartbeat failed: " .. tostring(code or res))
            end
        end

        if type(getgenv) == "function" then getgenv().TSR_AGENT_RUN = (getgenv().TSR_AGENT_RUN or 0) + 1 end
        local myRun = type(getgenv) == "function" and getgenv().TSR_AGENT_RUN or 0

        task.spawn(function()
            while alive and ((type(getgenv) ~= "function") or getgenv().TSR_AGENT_RUN == myRun) do
                local ok, err = pcall(heartbeat)
                if not ok then warn("[TSR] error: " .. tostring(err)) end
                task.wait(everyNow)
            end
        end)

        -- ============================================================ INVENTORY WEBHOOK (Discord, edits itself)
        -- One Discord message PER ACCOUNT. It is posted once, then EDITED in place whenever the inventory changes
        -- (hatched / crafted / deleted / traded). It never touches Cloudflare, so it keeps working when the site is rate limited.
        -- The message id is saved in WORST/inv_msg_<userid>.txt, so rejoining edits the same message instead of posting a new one.
        do
            local INV_ON      = true    -- false = switch the whole inventory webhook off
            local INV_WEBHOOK = "https://discord.com/api/webhooks/1565121533310013632/wjqwlDIJGdASkuwQvSSDx-UL35U7BIpkHQuFxdvUKJjhcPNYBXBhfqFfYVuzqkC1KYlf"   -- <- put your real webhook link here
            local INV_LOOK    = 2       -- seconds between cheap looks (pet count + eggs-opened). Discord is only contacted when something changed.
            local INV_GAP     = 15      -- an account edits its message at most once per this many seconds (15 accounts = about 1 request per second)
            local INV_FORCE   = 30      -- seconds between full re-reads even if the count did not move (catches equip / unequip)
            local INV_REFRESH = 300     -- edit anyway every 5 minutes so "Server players" and the time stay fresh
            local INV_ROWS    = 15      -- how many pet rows to list (rarest first)
            local INV_COLOR   = 5793266 -- embed color (decimal)
            local INV_NAME    = "WORST • Inventory"
            local INV_AVATAR  = "https://static.vecteezy.com/system/resources/previews/004/891/075/non_2x/the-initials-w-logo-is-simple-and-modern8868-free-vector.jpg"   -- webhook profile picture

            local base = (tostring(INV_WEBHOOK):gsub("%?.*$", ""):gsub("/+$", ""))
            local urlOk = base:find("discord.com/api/webhooks/", 1, true) ~= nil or base:find("discordapp.com/api/webhooks/", 1, true) ~= nil
            if not INV_ON or not urlOk then
                if INV_ON then warn("[InvWebhook] INV_WEBHOOK is not a Discord webhook link: the inventory webhook is off") end
            else
                local msgId = nil
                local blockedUntil = 0          -- os.clock() until which we must not talk to Discord (rate limit / bad link)
                local FILE = "inv_msg_" .. tostring(lp.UserId) .. ".txt"
                local tail = base:sub(-12)      -- so a message id saved for another webhook is never reused

                local function loadId()
                    local ok, t = pcall(Store.read, FILE)
                    if ok and type(t) == "string" then
                        local tl, id = t:match("^(.-):(%d+)%s*$")
                        if tl == tail and id then return id end
                    end
                end
                local function saveId(id) pcall(Store.write, FILE, id and (tail .. ":" .. id) or "") end

                local function num(n)
                    local s = tostring(math.floor(tonumber(n) or 0))
                    local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
                    return (r:gsub("^,", ""))
                end

                local RANK = { common = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5, mythical = 6, mythic = 6, godly = 7 }
                local function rarityRank(r)
                    r = tostring(r or ""):lower()
                    if r:find("secret", 1, true) then return 10 + (tonumber(r:match("%d+")) or 0) end
                    return RANK[r] or 0
                end
                local VRANK = { Normal = 1, Golden = 2, Gold = 2, Diamond = 3, Rainbow = 4 }

                local function call(method, url, payload)
                    if not httpRequest then return nil end
                    local ok, res = pcall(httpRequest, {
                        Url = url, Method = method, Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode(payload),
                    })
                    if not ok or type(res) ~= "table" then return nil end
                    return tonumber(res.StatusCode or res.status_code), res.Body
                end
                local function backoff(body)
                    local ok, d = pcall(function() return HttpService:JSONDecode(body) end)
                    local wait = (ok and type(d) == "table" and tonumber(d.retry_after)) or 5
                    blockedUntil = os.clock() + math.min(wait, 60) + 1
                end

                -- Posts the message the first time, edits it afterwards. Returns true when Discord accepted it.
                local function push(embed)
                    if os.clock() < blockedUntil then return false end
                    local payload = { embeds = { embed }, allowed_mentions = { parse = {} } }
                    if msgId then
                        local code, body = call("PATCH", base .. "/messages/" .. msgId, payload)
                        if code == 200 then return true end
                        if code == 429 then backoff(body) return false end
                        if code == 404 then msgId = nil saveId(nil)   -- somebody deleted the message: post a new one below
                        else return false end
                    end
                    payload.username = INV_NAME
                    payload.avatar_url = INV_AVATAR
                    local code, body = call("POST", base .. "?wait=true", payload)
                    if code == 200 then
                        local ok, d = pcall(function() return HttpService:JSONDecode(body) end)
                        if ok and type(d) == "table" and d.id then msgId = tostring(d.id) saveId(msgId) return true end
                        return false
                    end
                    if code == 429 then backoff(body) return false end
                    if code == 401 or code == 404 then
                        warn("[InvWebhook] Discord refused the webhook (HTTP " .. tostring(code) .. "): check INV_WEBHOOK. Trying again in 5 minutes.")
                        blockedUntil = os.clock() + 300
                    end
                    return false
                end

                -- who got added / removed between two reads
                local function diff(oldIdx, newIdx)
                    local gained, lost, counts, order = 0, 0, {}, {}
                    for id, p in pairs(newIdx) do
                        if not oldIdx[id] then
                            gained = gained + 1
                            local k = tostring(p.name) .. " (" .. tostring(p.tier) .. ")"
                            if not counts[k] then counts[k] = 0 order[#order + 1] = k end
                            counts[k] = counts[k] + 1
                        end
                    end
                    for id in pairs(oldIdx) do if not newIdx[id] then lost = lost + 1 end end
                    table.sort(order, function(a, b) if counts[a] ~= counts[b] then return counts[a] > counts[b] end return a < b end)
                    return gained, lost, counts, order
                end
                local function names(counts, order)
                    local t = {}
                    for i = 1, math.min(#order, 3) do t[#t + 1] = order[i] .. (counts[order[i]] > 1 and (" x" .. counts[order[i]]) or "") end
                    if #order > 3 then t[#t + 1] = "+" .. (#order - 3) .. " more" end
                    return table.concat(t, ", ")
                end

                -- order independent fingerprint of the inventory (so "nothing changed" never causes an edit)
                local function fingerprint(res)
                    local h = ((tonumber(res.owned) or 0) * 7919 + (tonumber(res.equippedCount) or 0) * 104729) % 2147483647
                    for _, g in ipairs(res.grouped or {}) do
                        local k, v = tostring(g.name) .. "|" .. tostring(g.tier), 0
                        for i = 1, #k do v = (v * 31 + k:byte(i)) % 1000003 end
                        h = (h + v * (tonumber(g.count) or 0)) % 2147483647
                    end
                    return h
                end

                -- Mythical and above only (Common..Legendary are ignored). A rarity the script does not know by name
                -- (e.g. Eternal / Divine) counts as "above"; a pet whose rarity can't be read is skipped.
                local function isMythicPlus(r)
                    if r == nil or tostring(r) == "" or tostring(r) == "?" then return false end
                    local rk = rarityRank(r)
                    if rk == 0 then return true end
                    return rk >= 6
                end

                local function build(res, action, rarestHatch, hatchTotal)
                    local grouped = {}
                    for _, g in ipairs(res.grouped or {}) do
                        if isMythicPlus(g.rarity) then grouped[#grouped + 1] = g end
                    end
                    table.sort(grouped, function(a, b)
                        local ra, rb = rarityRank(a.rarity), rarityRank(b.rarity)
                        if ra ~= rb then return ra > rb end
                        local va, vb = VRANK[a.tier] or 0, VRANK[b.tier] or 0
                        if va ~= vb then return va > vb end
                        if a.count ~= b.count then return a.count > b.count end
                        return tostring(a.name) < tostring(b.name)
                    end)
                    local shown, rows, wName = math.min(#grouped, INV_ROWS), {}, 0
                    for i = 1, shown do
                        local nm = tostring(grouped[i].name)
                        if #nm > 26 then nm = nm:sub(1, 24) .. ".." end
                        rows[i] = nm
                        wName = math.max(wName, #nm)
                    end
                    local lines = {}
                    for i = 1, shown do
                        local g = grouped[i]
                        lines[i] = rows[i] .. string.rep(" ", wName - #rows[i]) .. "  " .. string.format("%-6s", "x" .. tostring(g.count))
                            .. " " .. string.format("%-10s", tostring(g.rarity or "?")) .. " " .. tostring(g.tier)
                    end
                    local desc = #lines > 0 and ("```\n" .. table.concat(lines, "\n") .. "\n```") or "No Mythical or above pets."
                    if #grouped > shown then desc = desc .. "\n+" .. (#grouped - shown) .. " more pet types" end

                    local owned = tonumber(res.owned) or 0
                    local eq = tonumber(res.equippedCount) or 0
                    local plrs = #Players:GetPlayers() .. "/" .. tostring(Players.MaxPlayers)
                    local hatchTxt = hatchTotal and num(hatchTotal) or "?"
                    local rarestTxt = "None yet"
                    if rarestHatch then
                        rarestTxt = (rarestHatch.rarity and (tostring(rarestHatch.rarity) .. " ") or "") .. tostring(rarestHatch.name)
                            .. (rarestHatch.tier and rarestHatch.tier ~= "Normal" and (" (" .. tostring(rarestHatch.tier) .. ")") or "")
                            .. " · <t:" .. tostring(rarestHatch.at) .. ":R>"
                    end
                    local uname = (WebhookState and WebhookState.blur) and ("||" .. lp.Name .. "||") or lp.Name
                    return {
                        title = "Pet inventory report",
                        description = desc,
                        color = INV_COLOR,
                        fields = {
                            { name = "Username", value = uname, inline = true },
                            { name = "Server players", value = plrs, inline = true },
                            { name = "Hatches", value = hatchTxt, inline = true },
                            { name = "Equipped", value = tostring(eq) .. (res.equippedMax and ("/" .. tostring(res.equippedMax)) or ""), inline = true },
                            { name = "Unequipped", value = num(math.max(owned - eq, 0)), inline = true },
                            { name = "Total", value = num(owned) .. (res.capacity and (" / " .. num(res.capacity)) or ""), inline = true },
                            { name = "Last action", value = action.text .. " · <t:" .. tostring(action.at) .. ":R>", inline = false },
                            { name = "Rarest Hatch", value = rarestTxt, inline = false },
                        },
                        footer = { text = "Updated" },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    }
                end

                task.spawn(function()
                    task.wait(5 + math.random() * 10)   -- spreads 15 accounts out so they do not all talk to Discord at once
                    msgId = loadId()
                    local prevIdx, latest, lastCount, lastHatches
                    local rarestHatch, hatchTotal = nil, nil   -- rarest pet hatched since the script started
                    local baseCount, stable = -1, 0
                    local lastForce, lastSent, lastSig, lastTrade = 0, -1e9, nil, -1e9
                    local gap, pending = INV_GAP, false
                    local action = { text = "Script started", at = os.time() }
                    while alive and ((type(getgenv) ~= "function") or getgenv().TSR_AGENT_RUN == myRun) do
                        task.wait(INV_LOOK)
                        local okLoop, errLoop = pcall(function()
                            local now = os.clock()
                            local tradeNow = false
                            pcall(function() tradeNow = (tradeBusy == true) or (giveActive == true) or (tflags.startedAt ~= nil and now - tflags.startedAt < 60) end)
                            if tradeNow then lastTrade = now end

                            local cnt = DATA.count()
                            if not cnt then return end
                            local hOk, hat = pcall(readHatches)
                            if not hOk then hat = nil end

                            if hat ~= nil then hatchTotal = hat end
                            local changed = (prevIdx == nil) or cnt ~= lastCount or (hat ~= nil and hat ~= lastHatches) or (now - lastForce >= INV_FORCE)
                            if changed then
                                local res, idx = DATA.read()
                                if res and idx then
                                    lastForce = now
                                    if prevIdx == nil then
                                        -- first look: wait until the pet list stops growing, then remember it as the starting point
                                        if cnt == baseCount then stable = stable + 1 else stable = 0 end
                                        baseCount = cnt
                                        if stable >= 2 then
                                            prevIdx, latest, lastCount, lastHatches = idx, res, cnt, hat
                                            lastSig = fingerprint(res)
                                            pending = true
                                        end
                                    else
                                        local gained, lost, counts, order = diff(prevIdx, idx)
                                        local hatched = (hat ~= nil and lastHatches ~= nil and hat > lastHatches) or (gained > 0 and lost == 0)
                                        local recentTrade = (now - lastTrade) < 20
                                        if gained > 0 or lost > 0 then
                                            local text
                                            if recentTrade then
                                                text = (gained > 0 and lost == 0) and ("Received in trade: " .. names(counts, order))
                                                    or (lost > 0 and gained == 0) and ("Traded away " .. lost .. " pet" .. (lost == 1 and "" or "s"))
                                                    or ("Traded: +" .. gained .. " / -" .. lost .. " pets")
                                            elseif hatched then
                                                text = "Hatched: " .. (gained > 0 and names(counts, order) or "?")
                                                if lost > 0 then text = text .. " · Deleted " .. lost end
                                            elseif gained > 0 and lost > 0 then
                                                text = "Crafted: used " .. lost .. ", got " .. names(counts, order)
                                            else
                                                text = "Deleted " .. lost .. " pet" .. (lost == 1 and "" or "s")
                                            end
                                            action = { text = text, at = os.time() }
                                            if hatched and not recentTrade then   -- remember the rarest pet of this hatch
                                                for id, p in pairs(idx) do
                                                    if not prevIdx[id] then
                                                        local rk, vk = rarityRank(p.rarity), VRANK[p.tier] or 0
                                                        local best = rarestHatch
                                                        local bk, bv = best and rarityRank(best.rarity) or -1, best and (VRANK[best.tier] or 0) or -1
                                                        if rk > bk or (rk == bk and vk > bv) then
                                                            rarestHatch = { name = p.name, tier = p.tier, rarity = p.rarity, at = os.time() }
                                                        end
                                                    end
                                                end
                                                pending = true
                                            end
                                        end
                                        prevIdx, latest, lastCount, lastHatches = idx, res, cnt, hat
                                        local sig = fingerprint(res)
                                        if sig ~= lastSig then lastSig = sig pending = true end
                                    end
                                end
                            end

                            if latest and now - lastSent >= INV_REFRESH then pending = true end
                            if pending and latest and now - lastSent >= gap then
                                if push(build(latest, action, rarestHatch, hatchTotal)) then
                                    lastSent, pending = now, false
                                    gap = INV_GAP + math.random() * 3
                                else
                                    lastSent = now - gap + 10   -- try again in about 10 seconds
                                end
                            end
                        end)
                        if not okLoop then warn("[InvWebhook] " .. tostring(errLoop)) task.wait(5) end
                    end
                end)
            end
        end

        -- WORSTHUB handshake: env.TSR_TRADE_BUSY is true while a trade is really happening (we are giving, a trade
        -- session started <30s ago, or the trade window shows an offer). WORSTHUB pauses craft / delete / trips while it is true.
        do
            local env = (type(getgenv) == "function" and getgenv()) or _G
            task.spawn(function()
                while alive and ((type(getgenv) ~= "function") or getgenv().TSR_AGENT_RUN == myRun) do
                    local recent = tflags.startedAt and not tflags.completed and (os.clock() - tflags.startedAt) < 30
                    local okw, w = pcall(function() return winOpen() and not windowIsReset() end)
                    env.TSR_TRADE_BUSY = (giveActive or recent or (okw and w)) and true or false
                    pcall(autoTick)
                    task.wait(0.5)
                end
                env.TSR_TRADE_BUSY = false
            end)
        end

        -- AUTO-UNLOCK watcher (v9): every UNLOCK_WATCH seconds, unlock every locked pet found in the game data. No window involved.
        if AUTO_UNLOCK and UNLOCK_MODE == "always" then
            task.spawn(function()
                while alive and ((type(getgenv) ~= "function") or getgenv().TSR_AGENT_RUN == myRun) do
                    if not tradeBusy then
                        local okU, n = pcall(DATA.unlock)
                        -- nil = the game data has no lock field: only then look at the window, and only if it happens to be open
                        if okU and n == nil and invIsOn() then pcall(unlockLockedPets) end
                    end
                    task.wait(UNLOCK_WATCH)
                end
            end)
        end

        -- ---- the controls of the hub's Trade tab ----
        table.insert(cleanupHooks, function()   -- closing the hub stops the agent loops too
            if type(getgenv) == "function" then getgenv().TSR_AGENT_RUN = (getgenv().TSR_AGENT_RUN or 0) + 1 end
        end)
        -- =====================================================================================
        -- AUTO TRADE (PAY FIRST)
        -- Accepts a trade request, offers the pets you picked in "Choose Pets", and only Locks / Confirms while the other
        -- player's offer is >= the token amount. Pets come from the game's own data (DATA.tradePets), not from getgc.
        -- "Choose Pets": left click a pet = +1, right click = -1 (or the "-" button). Nothing is auto-selected.
        -- =====================================================================================
        local PF_REPLY, PF_ACK_WAIT, PF_ACK_TRIES = 0.5, 6, 3
        local pfGone, pfBad = {}, {}   -- pet ids already traded away / pets the server did not take in this trade
        local pfStock = {}             -- Name|Tier -> how many you could offer right now (from the last read)
        local pfRenderPanel            -- forward declaration (refreshes the Choose Pets list)
        local pfKeyOf = {}             -- dropdown row text -> pet key (Name|Tier)
        local PF_CLEAR = "Clear all"

        -- "Choose Pets" is a counter dropdown: "+  pet  -" rows, left click = +1, right click = -1 (buttons for touch)
        local pfPick = {
            type = "dropdown", name = "Choose Pets", icon = "\u{1F43E}", noSave = true, width = 320,
            counter = true, counts = {}, clearOption = PF_CLEAR, emptyText = "Select pets...",
            options = { PF_CLEAR }, default = PF_CLEAR, maxTotal = MAX_OFFER,
            isClearActive = function() return false end,
            desc = "Nothing selected. Left click a pet = +1, right click = -1 (or use the + / - buttons).",
        }
        pfPick.limitOf = function(opt)
            local k = pfKeyOf[opt]
            return k and (pfStock[k] or 0) or 0
        end
        local pfAmount = {
            type = "input", name = "Tokens They Must Pay", icon = "#", numeric = true, default = "", placeholder = "e.g. 100",
            desc = "Auto Trade never locks or confirms until the other player's offer is at least this many tokens.",
        }
        local pfToggle = {
            -- TOGGLE "Auto Trade (Pay First)": accepts trade requests, offers the chosen pets and waits for the payment (tokens) before confirming.
            type = "toggle", name = "Auto Trade (Pay First)", icon = "💰", default = false, noSave = true,
            desc = "Off. Choose pets and an amount, then switch on: it accepts requests, offers the pets and waits for the payment.",
        }

        -- ---- Giveaway page entries (logic further down) ----
        local GV_NONE = "None (pick a pet)"
        local gvPick = {
            type = "dropdown", name = "Giveaway Pet", icon = "\u{1F43E}", noSave = true, width = 320,
            desc = "Pick the pet to give away. Each trade offers up to 20 of it; when more are left, the next trade offers up to 20 again, until none are left.",
            options = { GV_NONE }, default = GV_NONE,
        }
        local gvToggle = {
            -- TOGGLE "Giveaway": anyone who sends a trade request gets the pets.
            type = "toggle", name = "Giveaway", icon = "\u{1F381}", default = false, noSave = true,
            desc = "Off. Pick a pet, then switch on: every trade request is accepted, the pets are offered, readied and confirmed for free, then it waits for the next one. Takes priority over Auto Trade (Pay First).",
        }
        local gvRepeat = {
            -- TOGGLE "Repeat User": on = the same player may get the giveaway again.
            type = "toggle", name = "Repeat User", icon = "\u{1F64B}", default = true,
            desc = "On = a player who already got the giveaway can receive it again. Off = their trade request is declined.",
        }
        local gvClear = {
            type = "button", name = "Clear Giveaway History", icon = "\u{1F5D1}", noSave = true,
            desc = "Forgets who already received the giveaway (used by Repeat User when it is off).",
        }

        -- Returns the readable label of a pet key.
        local function pfLabel(key)
            local n, t = key:match("^(.-)|(.*)$")
            return n and (n .. " (" .. t .. ")") or key
        end
        -- Returns the total number of pets picked.
        local function pfTotal()
            local n = 0
            for _, c in pairs(PF.sel) do n = n + c end
            return n
        end
        -- Builds the summary text of the picked pets.
        local function pfSummary()
            local parts = {}
            for key, c in pairs(PF.sel) do
                if c > 0 then parts[#parts + 1] = c .. "x " .. pfLabel(key) end
            end
            table.sort(parts)
            return #parts > 0 and table.concat(parts, ", ") or "nothing selected"
        end
        -- Updates the summary under the pet picker.
        local function pfUpdateSummary()
            local l = pfPick._desc
            if l and l.Parent then
                local t = pfTotal()
                l.Text = (t > 0 and ("Selected " .. t .. "/" .. MAX_OFFER .. ": ") or "") .. pfSummary()
            end
        end
        -- Sets the status text of Auto Trade (Pay First).
        local function pfSay(text)
            local l = (PF.give and gvToggle or pfToggle)._desc
            if l and l.Parent then l.Text = text end
        end
        -- Sends a trade request through the remote.
        local function pfFire(t)
            if tradeRequestRE then pcall(function() tradeRequestRE:FireServer(t) end) end
        end
        -- Resets the Pay First trade state.
        local function pfReset()
            PF.gen = PF.gen + 1   -- stops any loop still running for the old trade
            PF.active, PF.other, PF.rev = false, nil, 0
            PF.uids, PF.uidSet = {}, {}
            PF.offerOk, PF.tokens, PF.locked, PF.looping, PF.cdUntil = false, 0, false, false, 0
            pfBad = {}
        end

        -- rebuilds the Choose Pets list from the pet data and keeps the numbers in step with PF.sel
        pfRenderPanel = function()
            local groups, order = DATA.tradePets(pfGone, pfBad)
            if not groups then return end
            local opts, counts = pfPick.options, pfPick.counts
            for i = #opts, 1, -1 do opts[i] = nil end
            for k in pairs(pfKeyOf) do pfKeyOf[k] = nil end
            for k in pairs(counts) do counts[k] = nil end
            pfStock = {}
            opts[1] = PF_CLEAR
            local seen = {}
            for _, key in ipairs(order) do
                local label = pfLabel(key)
                opts[#opts + 1] = label
                pfKeyOf[label] = key
                pfStock[key] = #groups[key].uids
                seen[key] = true
            end
            for key, c in pairs(PF.sel) do   -- picked pets you no longer own stay in the list (in red) so you can remove them
                if c > 0 and not seen[key] then
                    local label = pfLabel(key)
                    opts[#opts + 1] = label
                    pfKeyOf[label] = key
                    pfStock[key] = 0
                end
            end
            for key, c in pairs(PF.sel) do
                if c > 0 then counts[pfLabel(key)] = c end
            end
            if pfPick._refresh then pfPick._refresh() end
            if pfPick._refreshMulti then pfPick._refreshMulti(true) end
            pfUpdateSummary()
        end
        pfPick.onOpen = function() pfRenderPanel() end

        -- a click on a row (callback(option, delta, newCount)); option == nil = the numbers were set from outside
        pfPick.callback = function(opt)
            if opt == PF_CLEAR then
                PF.sel = {}
            elseif opt == nil then
                PF.sel = {}
                for label, n in pairs(pfPick.counts) do
                    local key = pfKeyOf[label]
                    if key and n > 0 then PF.sel[key] = n end
                end
            else
                local key = pfKeyOf[opt]
                if not key then return end
                local n = pfPick.counts[opt] or 0
                PF.sel[key] = n > 0 and n or nil
            end
            pfUpdateSummary()
        end

        pfAmount.callback = function(v) PF.amount = math.max(0, math.floor(tonumber(v) or 0)) end

        -- =====================================================================================
        -- GIVEAWAY (Trade tab > Giveaway): the Pay First engine below, with nothing to pay.
        -- Every incoming request is accepted, up to 20 of the chosen pet are offered (re-counted for every trade, so the next
        -- trade offers 20 again until the pet runs out), then Ready (Lock) + Confirm, and it waits for the next request.
        -- =====================================================================================
        local GV = { key = nil, repeatUser = true, given = {} }
        local GV_FILE = "giveaway_given_" .. tostring(lp.UserId) .. ".txt"
        do
            local raw = Store.read(GV_FILE)
            if type(raw) == "string" then
                for id in raw:gmatch("%d+") do GV.given[id] = true end
            end
        end
        local function gvSave()
            local l = {}
            for id in pairs(GV.given) do l[#l + 1] = id end
            pcall(Store.write, GV_FILE, table.concat(l, ","))
        end
        local gvKeyOf, gvLabelOf = {}, {}
        local function gvStock(groups, key)
            local g = groups and key and groups[key]
            return g and #g.uids or 0
        end
        -- the pets one giveaway trade offers: up to MAX_OFFER of the chosen pet
        local function gvSelect(groups)
            local sel = {}
            if GV.key then
                local n = math.min(MAX_OFFER, gvStock(groups, GV.key))
                if n > 0 then sel[GV.key] = n end
            end
            return sel
        end
        local function gvUpdateDesc()
            local l = gvPick._desc
            if not (l and l.Parent) then return end
            if not GV.key then l.Text = "Pick the pet to give away." return end
            local groups = DATA.tradePets(pfGone, pfBad)
            l.Text = string.format("%s: %d available. Each trade offers up to %d.", pfLabel(GV.key), gvStock(groups, GV.key), MAX_OFFER)
        end
        local function gvRender()
            local groups, order = DATA.tradePets(pfGone, pfBad)
            if not groups then return end
            local opts = gvPick.options
            for i = #opts, 1, -1 do opts[i] = nil end
            for k in pairs(gvKeyOf) do gvKeyOf[k] = nil end
            for k in pairs(gvLabelOf) do gvLabelOf[k] = nil end
            opts[1] = GV_NONE
            local seen = {}
            for _, key in ipairs(order) do
                local label = pfLabel(key) .. "  x" .. #groups[key].uids
                opts[#opts + 1] = label
                gvKeyOf[label] = key
                gvLabelOf[key] = label
                seen[key] = true
            end
            if GV.key and not seen[GV.key] then   -- the chosen pet ran out: keep it in the list (x0)
                local label = pfLabel(GV.key) .. "  x0"
                opts[#opts + 1] = label
                gvKeyOf[label] = GV.key
                gvLabelOf[GV.key] = label
            end
            if gvPick._refresh then gvPick._refresh(GV.key and gvLabelOf[GV.key] or GV_NONE) end
            gvUpdateDesc()
        end
        gvPick.onOpen = function() gvRender() end
        gvPick.callback = function(opt)
            GV.key = gvKeyOf[tostring(opt)]   -- nil for "None"
            gvUpdateDesc()
        end
        gvRepeat.callback = function(on) GV.repeatUser = on == true end
        gvClear.run = function()
            GV.given = {}
            gvSave()
            print("[Giveaway] history cleared")
        end
        -- what a trade has to pay: nothing in Giveaway mode
        local function pfNeed() return PF.give and 0 or PF.amount end

        -- does this Offer event (ours, echoed by the server) show exactly the pets we offered, and nothing else?
        local function pfOfferIsMine(d)
            local list = (type(d.Pets) == "table" and d.Pets) or (type(d.Refs) == "table" and d.Refs) or {}
            local n, seen = 0, {}
            for _, e in pairs(list) do
                if type(e) ~= "table" then return false end
                local id = tostring(e.Uid or e.Id or e.PetId)
                if not PF.uidSet[id] then return false end
                seen[id] = true
                n = n + 1
            end
            for u in pairs(PF.uidSet) do
                if not seen[u] then return false end
            end
            return n > 0
        end

        -- offers exactly the picked amounts (fresh read, so a pet that is already gone is never offered)
        local function pfOfferPets()
            local groups = DATA.tradePets(pfGone, pfBad)
            if not groups then pfSay("Pet data is not loaded yet.") return false end
            local uids, set, refs = {}, {}, {}
            local sel = PF.sel
            if PF.give then
                sel = gvSelect(groups)
                if next(sel) == nil then pfSay("Giveaway finished: nothing left to give. Trade cancelled.") return false end
            end
            for key, want in pairs(sel) do
                if want > 0 then
                    local g = groups[key]
                    local have = g and #g.uids or 0
                    if have < want then
                        pfSay("Not enough " .. pfLabel(key) .. " left (picked " .. want .. ", have " .. have .. "). Trade cancelled.")
                        return false
                    end
                    for i = 1, want do
                        local u = g.uids[i]
                        uids[#uids + 1] = u
                        set[u] = true
                        refs[#refs + 1] = { Uid = u, TypeName = "Pet", Amount = 1 }
                    end
                end
            end
            if #uids == 0 or #uids > MAX_OFFER then
                pfSay("Pick between 1 and " .. MAX_OFFER .. " pets first. Trade cancelled.")
                return false
            end
            PF.uids, PF.uidSet = uids, set
            PF.rev = PF.rev + 1
            PF.offerOk = false
            pfFire({ Revision = PF.rev, Action = "Offer", Refs = refs })
            pfSay(PF.give and ("Offered " .. #uids .. " pet(s). Locking...") or ("Offered " .. #uids .. " pet(s). Waiting for " .. pfNeed() .. " tokens..."))
            return true
        end

        -- the server must show our pets in the offer; if it does not, try again with other copies, then cancel
        local function pfWatchOffer()
            local gen = PF.gen
            task.spawn(function()
                for try = 1, PF_ACK_TRIES do
                    local t0 = os.clock()
                    while PF.gen == gen and not PF.offerOk and os.clock() - t0 < PF_ACK_WAIT do task.wait(0.25) end
                    if PF.gen ~= gen or PF.offerOk then return end
                    if try == PF_ACK_TRIES then break end
                    for u in pairs(PF.uidSet) do pfBad[u] = true end
                    if not pfOfferPets() then pcall(cancelTrade) return end
                end
                if PF.gen == gen and PF.active and not PF.offerOk then
                    pfSay("The server never showed the pets in the offer. Trade cancelled.")
                    pcall(cancelTrade)
                end
            end)
        end

        -- True if the tokens can be locked in now.
        local function pfCanLock()
            return PF.on and PF.active and PF.offerOk and PF.tokens >= pfNeed() and not PF.locked
        end

        -- keeps trying to Lock until the server confirms it (offers put a short cooldown on locking)
        local function pfLockLoop()
            if PF.looping then return end
            PF.looping = true
            local gen = PF.gen
            task.spawn(function()
                local tries = 0
                while PF.gen == gen and pfCanLock() and tries < 12 do
                    task.wait(math.max(PF_REPLY, PF.cdUntil - os.clock() + 0.3))
                    if PF.gen ~= gen or not pfCanLock() then break end
                    tries = tries + 1
                    pfFire({ Action = "Lock", Locked = true })
                    pfSay("Paid (" .. PF.tokens .. "). Locking...")
                    task.wait(1.5)
                end
                if PF.gen == gen then
                    PF.looping = false
                    if pfCanLock() then pfSay("Could not lock after several tries. Press Ready yourself.") end
                end
            end)
        end

        -- Checks the trade and decides the next step.
        local function pfEvaluate()
            if not PF.on or not PF.active then return end
            if PF.tokens >= pfNeed() then
                if PF.offerOk and not PF.locked then pfLockLoop() end
            else
                pfSay("Waiting for payment: " .. PF.tokens .. " / " .. pfNeed() .. " tokens.")
            end
        end

        local PF_ENDED = { Cancelled = 1, Canceled = 1, Declined = 1, Closed = 1, Ended = 1, Failed = 1, Expired = 1, Rejected = 1 }

        if tradeUpdateRE then
            connect(tradeUpdateRE.OnClientEvent, function(d)
                if type(d) ~= "table" or not PF.on then return end
                local ty = d.Type

                if ty == "Request" then
                    if PF.active or tradeBusy or giveActive or os.clock() < PF.acceptUntil then return end
                    if PF.give then
                        local who = tostring(d.FromName)
                        if not GV.key then
                            pfSay("Request from " .. who .. " ignored: pick a pet to give away first.")
                            return
                        end
                        if not GV.repeatUser and d.FromUserId and GV.given[tostring(d.FromUserId)] then
                            pfFire({ Action = "Respond", Accepted = false })
                            pfSay("Declined " .. who .. ": already received the giveaway.")
                            return
                        end
                        if next(gvSelect((DATA.tradePets(pfGone, pfBad)))) == nil then
                            pfSay("Giveaway finished: no " .. pfLabel(GV.key) .. " left. Request from " .. who .. " ignored.")
                            return
                        end
                    elseif PF.amount <= 0 or pfTotal() == 0 then
                        pfSay("Request from " .. tostring(d.FromName) .. " ignored: choose pets and a token amount first.")
                        return
                    end
                    PF.reqName = tostring(d.FromName)
                    PF.acceptUntil = os.clock() + 30   -- only a trade that starts inside this window is ours
                    pfSay("Trade request from " .. tostring(d.FromName) .. ". Accepting...")
                    task.delay(PF_REPLY, function()
                        if PF.on and not PF.active and not tradeBusy and not giveActive then
                            pfFire({ Action = "Respond", Accepted = true })
                        else
                            PF.acceptUntil = 0
                        end
                    end)

                elseif ty == "Started" then
                    if os.clock() >= PF.acceptUntil or tradeBusy or giveActive then return end   -- not a trade we accepted
                    PF.acceptUntil = 0
                    pfReset()
                    PF.active = true
                    PF.other = (d.A == lp.UserId) and d.B or d.A
                    if pfOfferPets() then pfWatchOffer() else pcall(cancelTrade) end

                elseif not PF.active then
                    return

                elseif ty == "Offer" then
                    PF.cdUntil = math.max(PF.cdUntil, os.clock() + (tonumber(d.Cooldown) or 0))
                    if d.UserId == lp.UserId then
                        PF.offerOk = pfOfferIsMine(d)
                        PF.locked = false
                        pfEvaluate()
                    elseif d.UserId == PF.other then
                        local wasLocked = PF.locked
                        PF.tokens = tonumber(d.Tokens) or 0
                        PF.locked = false   -- any change on their side resets the lock; pfEvaluate locks again only if still paid
                        if wasLocked and PF.tokens < pfNeed() then
                            pfFire({ Action = "Lock", Locked = false })
                            pfEvaluate()
                            pfSay("They offer " .. PF.tokens .. ", need " .. pfNeed() .. ". Unlocked.")
                        else
                            pfEvaluate()
                        end
                    end

                elseif ty == "Lock" and d.UserId == lp.UserId then
                    PF.locked = d.Locked and true or false
                    if PF.locked then pfSay("Locked (" .. PF.tokens .. " tokens paid). Waiting for them...") end

                elseif ty == "Review" then
                    -- both sides are locked: confirm only if the payment is still there
                    if PF.tokens >= pfNeed() and PF.offerOk then
                        task.delay(PF_REPLY, function()
                            if PF.on and PF.active and PF.tokens >= pfNeed() and PF.offerOk then
                                pfFire({ Action = "Confirm" })
                                pfSay("Confirmed. Waiting for the server...")
                            end
                        end)
                    else
                        pfSay("Review reached but payment is " .. PF.tokens .. "/" .. pfNeed() .. ". Not confirming.")
                    end

                elseif ty == "Completed" then
                    local gaveN, gaveTo = 0, PF.other
                    for u in pairs(PF.uidSet) do pfGone[u] = true gaveN = gaveN + 1 end
                    if PF.give then
                        if gaveTo then GV.given[tostring(gaveTo)] = true gvSave() end
                        local gLeft = gvStock((DATA.tradePets(pfGone, pfBad)), GV.key)
                        pfSay(string.format("Gave %d pet(s) to %s. %d left. Waiting for the next request...", gaveN, tostring(PF.reqName or gaveTo), gLeft))
                    else
                        pfSay("Trade completed. Received " .. PF.tokens .. " tokens. Waiting for the next request...")
                    end
                    pfReset()
                    task.delay(2, function() pcall(pfRenderPanel) pcall(gvRender) end)

                elseif PF_ENDED[ty] then
                    pfSay("Trade ended (" .. tostring(ty) .. "). Waiting for the next request...")
                    pfReset()
                    PF.acceptUntil = 0
                end
            end)
        end

        -- Pay First and Giveaway share the engine; Giveaway takes priority when both are on
        local function pfSetMode(which, on)
            local toggle = (which == "give") and gvToggle or pfToggle
            local function say(t) local l = toggle._desc if l and l.Parent then l.Text = t end end
            if on then
                if not (tradeUpdateRE and tradeRequestRE) then
                    say("The game's trade remotes were not found, so Auto Trade cannot work.")
                    return
                end
                if which == "give" then PF.giveOn = true else PF.payOn = true end
                PF.give = PF.giveOn and true or false
                PF.on = true
                if which == "give" then
                    if GV.key then say("ON. Waiting for trade requests...") else say("ON, but pick a pet first (requests are ignored until then).") end
                elseif pfTotal() > 0 and PF.amount > 0 then
                    say("ON. Waiting for a trade request...")
                else
                    say("ON, but choose pets and a token amount first (requests are ignored until then).")
                end
            else
                if which == "give" then PF.giveOn = false else PF.payOn = false end
                PF.give = PF.giveOn and true or false
                PF.on = (PF.payOn or PF.giveOn) and true or false
                if not PF.on then
                    if PF.active then   -- never leave an open, locked trade behind
                        if PF.locked then pfFire({ Action = "Lock", Locked = false }) end
                        pcall(cancelTrade)
                    end
                    pfReset()
                    PF.acceptUntil = 0
                end
                say("Off.")
            end
        end
        pfToggle.callback = function(on) pfSetMode("pay", on and true or false) end
        gvToggle.callback = function(on) pfSetMode("give", on and true or false) end

        table.insert(cleanupHooks, function()
            PF.on = false
            if PF.active then
                if PF.locked then pfFire({ Action = "Lock", Locked = false }) end
                pcall(cancelTrade)
            end
        end)

        task.spawn(function()   -- keeps the open picker in step with your pets (not during a trade)
            task.wait(3)
            while alive and ((type(getgenv) ~= "function") or getgenv().TSR_AGENT_RUN == myRun) do
                if not PF.active then pcall(pfRenderPanel) pcall(gvRender) end
                task.wait(8)
            end
        end)

        return { entries = {
            pfPick, pfAmount, pfToggle,
            {
                -- TOGGLE "Auto Accept": Accepts trade requests from trusted players (Trusted Names).
                type = "toggle", name = "Auto Accept", icon = "📥", default = true,
                desc = "Accepts trade requests from trusted players (Trusted Names). Never while a site trade job is running.",
                callback = function(on) Auto.accept = on == true end,
            },
            {
                -- TOGGLE "Auto Ready": Presses Ready when a trusted partner has put pets in and you offered nothing (waits until their offer stays unchanged for a few seconds).
                type = "toggle", name = "Auto Ready", icon = "🚀", default = true,
                desc = "Presses Ready when a trusted partner has put pets in and you offered nothing (waits until their offer stays unchanged for a few seconds).",
                callback = function(on) Auto.ready = on == true end,
            },
            {
                -- TOGGLE "Auto Confirm": Presses Confirm on the Review screen for a trusted partner.
                type = "toggle", name = "Auto Confirm", icon = "🤝", default = true,
                desc = "Presses Confirm on the Review screen for a trusted partner.",
                callback = function(on) Auto.confirm = on == true end,
            },
            {
                type = "input", name = "Trusted Names", icon = "👥", default = "", placeholder = "name1, name2 (usernames or user ids)",
                desc = "Players the three toggles above are allowed to act for. Saved with your configuration.",
                callback = function(text) autoSetNames(text) end,
            },
            {
                -- TOGGLE "Accept From Anyone (unsafe)": Makes EVERY player trusted.
                type = "toggle", name = "Accept From Anyone (unsafe)", icon = "!", default = false,
                desc = "Makes EVERY player trusted. Anyone can then send a trade and have it accepted, readied and confirmed.",
                callback = function(on) Auto.anyone = on == true end,
            },
        }, giveaway = { gvPick, gvToggle, gvRepeat, gvClear } }

    end)
    if okA and type(resA) == "table" then return resA end
    warn("[WORST Hub] the trade agent failed to start: " .. tostring(resA))
    return { entries = {}, giveaway = {} }
end)()

-- Skill Points: continuously checks live game definitions, including skills added in updates.
-- This worker belongs to the hub lifecycle and never switches its toggle off by itself.
local SkillPoints = (function()
    local RS = game:GetService("ReplicatedStorage")
    local entry = {
        -- TOGGLE "Auto Skill Points": Buys every affordable skill at the same time.
        type = "toggle", name = "Auto Skill Points", icon = "🌳", default = false,
        desc = "Buys every affordable skill at the same time. Nothing left to buy: checks again after 5 min, then 60 min, then 2 hours, then waits until Auto Unlock Islands buys another island. Buying anything starts the 5 min cycle again.",
    }
    local on, generation = false, 0
    local retryAt = {}
    local lastSignature = nil
    local lastScan = 0
    local nodes = {}
    local scanError = nil
    -- Sets the status text of this feature.
    local function say(message)
        if entry._desc and entry._desc.Parent then entry._desc.Text = message end
    end
    -- Returns the player data from the controller.
    local function getData(controller)
        local replicas = controller and controller._replicas
        if type(replicas) ~= "table" then return nil end
        for _, replica in pairs(replicas) do
            local data = replica.Data
            if type(data) == "table" and type(data.Currencies) == "table"
                and type(data.SkillTree) == "table"
                and type(data.SkillTree.Unlocked) == "table" then
                return data
            end
        end
    end
    -- Refreshes the scan (at most every 5 minutes unless forced).
    local function refresh(force)
        if not force and os.clock() - lastScan < 300 then return end
        lastScan = os.clock()
        local ok, result = pcall(function()
            local formula = require(RS.Shared.Progression.SkillTreeFormula)
            local result = {}
            for name, node in pairs(formula.Nodes or {}) do
                local info = type(node) == "table" and node.Data
                if type(info) == "table" and type(info.Cost) == "number"
                    and info.Cost > 0 and info.Currency == "Gems" then
                    result[#result + 1] = {
                        name = name, cost = info.Cost, parent = node.Parent,
                        island = info.RequiredIsland,
                    }
                end
            end
            table.sort(result, function(a, b)
                return a.cost == b.cost and tostring(a.name) < tostring(b.name) or a.cost < b.cost
            end)
            return result
        end)
        if ok then
            nodes = result
            scanError = nil
            local names = {}
            for _, n in ipairs(nodes) do names[#names + 1] = tostring(n.name) .. ":" .. tostring(n.cost) end
            local sig = table.concat(names, "|")
            if sig ~= lastSignature then
                retryAt = {} -- New/changed skills get a fresh chance
                lastSignature = sig
            end
        else
            scanError = tostring(result)
        end
    end
    -- Finds the machine nearest to the character.
    local function findNearestMachine()
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local best, bestDist
        local scanned = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            scanned = scanned + 1
            if scanned % 2000 == 0 then task.wait() end
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local name = obj.Name:lower()
                if name:find("doublejump", 1, true)
                    or name:find("double jump", 1, true)
                    or name:find("jumpmachine", 1, true)
                    or name:find("jump machine", 1, true) then
                    local pos
                    if obj:IsA("BasePart") then
                        pos = obj.Position
                    else
                        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                        pos = part and part.Position
                    end
                    if pos then
                        local dist = (root.Position - pos).Magnitude
                        if not bestDist or dist < bestDist then
                            best, bestDist = pos, dist
                        end
                    end
                end
            end
        end
        return best
    end
    -- Schedule (Auto Skill Points):
    --   buy EVERY affordable skill at the same time -> 2 s -> again ... until nothing more can be bought
    --   then wait 5 min -> try again; bought something = 5 min cycle again
    --   nothing after the 5 min wait -> wait 60 min; nothing after that -> wait 2 h; nothing after that -> wait until Auto Unlock Islands
    --   buys another island (new skill trees open). An island bought during ANY wait also ends that wait early and starts the cycle again.
    local AFTER_BUY_GAP = 2
    local WAITS = { 300, 3600, 7200 }   -- stage 1, 2, 3; stage 4 = wait for a new island
    -- Formats seconds as a time text.
    local function fmtTime(t)
        t = math.max(0, math.floor(t))
        if t >= 3600 then return string.format("%dh %02dm", t // 3600, (t % 3600) // 60) end
        return string.format("%d:%02d", t // 60, t % 60)
    end
    -- Counts the islands you own.
    local function islandCount(data)
        local u = data and type(data.Progression) == "table" and data.Progression.UnlockedIslands
        if type(u) ~= "table" then return nil end
        local n = 0
        for _ in pairs(u) do n = n + 1 end
        return n
    end
    -- Returns the island count signal (used to detect a new island).
    local function islandSignal(controller)
        return tonumber(env.WORST_ISLAND_BUYS) or 0, islandCount(getData(controller))
    end

    -- one buying pass: every affordable skill whose parent is unlocked is requested at the same time.
    -- returns how many were really unlocked, and how many were requested
    local function buyAll(controller, remote, id, failed)
        refresh(true)
        local data = getData(controller)
        if not data then return 0, 0, "Waiting for player Skill Tree data..." end
        if scanError then return 0, 0, "Skill Tree scan failed: " .. scanError end
        local unlocked = data.SkillTree.Unlocked
        local left = tonumber(data.Currencies.Gems) or 0
        local batch = {}
        for _, skill in ipairs(nodes) do   -- sorted cheapest first = the most skills for your Gems
            if not unlocked[skill.name] and not failed[skill.name] then
                local parent = skill.parent
                if (not parent or unlocked[parent] == true) and left >= skill.cost then
                    left = left - skill.cost
                    batch[#batch + 1] = skill
                end
            end
        end
        if #batch == 0 then return 0, 0 end
        say("Buying " .. #batch .. " skill(s) at once...")
        local pending, replies = #batch, {}
        for _, skill in ipairs(batch) do
            task.spawn(function()
                local sent, response = pcall(function() return remote:InvokeServer({ Name = skill.name }) end)
                replies[skill.name] = { sent, response }
                pending = pending - 1
            end)
        end
        local t0 = os.clock()
        while pending > 0 and os.clock() - t0 < 6 and alive and on and generation == id do task.wait(0.1) end
        task.wait(1.5)   -- let the replicated data catch up
        local updated = getData(controller)
        local bought = 0
        for _, skill in ipairs(batch) do
            if updated and updated.SkillTree.Unlocked[skill.name] == true then
                bought = bought + 1
            else
                failed[skill.name] = true   -- not tried again in this session
                local r = replies[skill.name]
                warn("[WORST Skill Points] Skipped", skill.name, r and r[1], r and r[2])
            end
        end
        return bought, #batch
    end

    -- wait `seconds` (nil = until an island is bought). Returns "island" when an island was bought, "off" when switched off, "time" otherwise.
    local function waitFor(controller, id, seconds, label)
        local buys0, count0 = islandSignal(controller)
        local t0, lastSay = os.clock(), -1e9
        while alive and on and generation == id do
            local buys, count = islandSignal(controller)
            if buys > buys0 or (count and count0 and count > count0) then return "island" end
            local left = seconds and (seconds - (os.clock() - t0))
            if left and left <= 0 then return "time" end
            if os.clock() - lastSay >= 5 then
                lastSay = os.clock()
                if left then say(label .. " | next check in " .. fmtTime(left))
                else say(label .. " | waiting for Auto Unlock Islands to buy another island") end
            end
            task.wait(0.5)
        end
        return "off"
    end

    -- Main loop of this feature.
    local function run(id)
        local ok, controller, remote = pcall(function()
            return require(RS.Controllers.Core.ReplicaController),
                RS.RemoteServices.SkillTreeService.RF.Unlock
        end)
        if not ok then say("Skill Points unavailable: " .. tostring(controller)); return end
        local stage, advance = 1, false   -- advance = this session follows a timed wait, so finding nothing moves to the next (longer) wait
        while alive and on and generation == id do
            -- ONE SESSION: buy everything, 2 s, buy again ... until nothing more can be bought
            local failed, total = {}, 0
            while alive and on and generation == id do
                local bought, tried, problem = buyAll(controller, remote, id, failed)
                if problem then say(problem) end
                if bought > 0 then
                    total = total + bought
                    say("Bought " .. bought .. " skill(s) (" .. total .. " this round); checking again in " .. AFTER_BUY_GAP .. "s...")
                    local t = 0
                    while t < AFTER_BUY_GAP and alive and on and generation == id do task.wait(0.25) t = t + 0.25 end
                else
                    break   -- nothing (more) could be bought
                end
            end
            if not (alive and on and generation == id) then return end

            if total > 0 then stage = 1
            elseif advance then stage = math.min(stage + 1, 4) end

            local result
            if stage <= 3 then
                local mins = WAITS[stage] / 60
                result = waitFor(controller, id, WAITS[stage],
                    (total > 0 and ("Bought " .. total .. " skill(s)") or "Nothing to buy") .. " | waiting " .. (mins >= 60 and (mins / 60 .. " h") or (mins .. " min")))
            else
                result = waitFor(controller, id, nil, "Nothing to buy for 2 hours")
            end
            if result == "off" then return end
            if result == "island" then
                stage, advance = 1, false   -- new island: new skill trees, fresh start
            else
                advance = true
            end
        end
    end
    entry.callback = function(value)
        on = value == true
        generation = generation + 1
        if on then
            lastScan = 0
            retryAt = {}
            say("Scanning Skill Tree...")
            local id = generation
            task.spawn(function() run(id) end)
        else
            say("Auto Skill Points disabled.")
        end
    end
    table.insert(cleanupHooks, function() on = false; generation = generation + 1 end)
    return { entry }
end)()

-- Double Jump: purchases the next level and verifies it using replicated data.
-- Never turns itself off at the current maximum; periodically retries for future updates.
local DoubleJump = (function()
    local RS = game:GetService("ReplicatedStorage")
    local entry = {
        -- TOGGLE "Auto Double Jump": Priority #1: travels to the nearest loaded Jump Machine, waits 2 seconds, then buys +1 Jump, one level after the other with no upper limit.
        type = "toggle", name = "Auto Double Jump", icon = "🐇", default = false,
        desc = "Priority #1: travels to the nearest loaded Jump Machine, waits 2 seconds, then buys +1 Jump, one level after the other with no upper limit. If a purchase keeps failing once you own 8 or more jumps, that is the limit: it stops buying. Stays enabled.",
    }
    local on, generation = false, 0
    local nextRetry = 0
    local lastAttemptLevel = nil
    local lastFailure = ""
    local IDLE_AFTER_REFUSAL = 24 * 60 * 60   -- limit reached: stay idle this long (toggle stays ON), then check again in case an update raised the limit
    local LIMIT_FROM  = 8    -- the limit is somewhere around 8-10 jumps: from this many owned jumps on, a purchase that keeps failing = limit
    local LIMIT_FAILS = 3    -- ... after this many refused purchases in a row (the server answered but did not unlock it)
    local confirmed = 0      -- highest level we know was bought (the replicated data can lag behind a purchase)
    local failStreak = 0     -- refused purchases in a row for the current level
    -- Formats a waiting time as text.
    local function fmtWait(sec)
        sec = math.max(0, math.ceil(sec))
        if sec >= 3600 then return string.format("%dh %02dm", math.floor(sec / 3600), math.floor((sec % 3600) / 60)) end
        if sec >= 60 then return string.format("%dm %02ds", math.floor(sec / 60), sec % 60) end
        return sec .. "s"
    end
    -- Short text form of a value, used in log messages.
    local function brief(v)
        if type(v) ~= "table" then return tostring(v) end
        local parts = {}
        for k, x in pairs(v) do parts[#parts + 1] = tostring(k) .. "=" .. tostring(x) end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    -- Sets the status text of this feature.
    local function say(message)
        if entry._desc and entry._desc.Parent then entry._desc.Text = message end
    end
    -- Returns the player data from the controller.
    local function getData(controller)
        local replicas = controller and controller._replicas
        if type(replicas) ~= "table" then return nil end
        for _, replica in pairs(replicas) do
            local data = replica.Data
            if type(data) == "table" and type(data.Currencies) == "table"
                and type(data.PhysicalUpgrades) == "table" then
                return data
            end
        end
    end
    local holding = false   -- true while this feature owns the machine trip (so switching it off can always give the trip back)
    local machineCache
    -- Returns the position of a machine object.
    local function machinePos(obj)
        if obj:IsA("BasePart") then return obj.Position end
        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        return part and part.Position
    end
    -- nearest LOADED Jump Machine. A machine found before is reused while it is still loaded, so the whole workspace is not walked again for every purchase.
    local function findNearestMachine()
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        if machineCache and machineCache:IsDescendantOf(workspace) then
            local cached = machinePos(machineCache)
            if cached then return cached end
        end
        local best, bestDist, bestObj
        local scanned = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            scanned = scanned + 1
            if scanned % 2000 == 0 then task.wait() end   -- spread over frames: one big loop is a visible freeze
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local name = obj.Name:lower()
                if name:find("doublejump", 1, true)
                    or name:find("double jump", 1, true)
                    or name:find("jumpmachine", 1, true)
                    or name:find("jump machine", 1, true) then
                    local pos = obj.Parent and machinePos(obj)
                    if pos then
                        local dist = (root.Position - pos).Magnitude
                        if not bestDist or dist < bestDist then
                            best, bestDist, bestObj = pos, dist, obj
                        end
                    end
                end
            end
        end
        machineCache = bestObj
        return best
    end
    -- Main loop of this feature.
    local function run(id)
        local ok, controller, remote = pcall(function()
            return require(RS.Controllers.Core.ReplicaController),
                RS.RemoteServices.PhysicalUpgradeService.RF.Purchase
        end)
        if not ok then say("Double Jump unavailable: " .. tostring(controller)); return end
        while alive and on and generation == id do
            local data = getData(controller)
            if not data then
                say("Waiting for Double Jump player data...")
            else
                local level = math.max(tonumber(data.PhysicalUpgrades.DoubleJump) or 0, confirmed)   -- missing key = level 0
                local gems = tonumber(data.Currencies.Gems) or 0
                if lastAttemptLevel ~= level then
                    nextRetry = 0
                    lastAttemptLevel = level
                end
                if os.clock() >= nextRetry then
                    local index = level + 1
                    say("Trying +1 Jump " .. tostring(index) .. " | Gems: " .. tostring(gems))
                    -- Reserve travel before moving; pause Hatch and lower-priority trips.
                    local priority = Logic and Logic.priority
                    local held = false
                    -- True while this run is still the current one (and the trip is held).
                    local function active() return alive and on and generation == id end
                    if priority and priority.acquireTrip then
                        held = priority.acquireTrip("DoubleJump", active, say)
                    else
                        held = active()
                    end
                    if not held then break end
                    holding = true
                    local sent, response = false, "No Jump Machine is loaded in the workspace (go to the island that has it, it can be streamed out)"
                    local okTrip, tripErr = pcall(function()
                        local target = findNearestMachine()
                        local character = player.Character
                        if target and character and active() then
                            say("Jump " .. tostring(level) .. " | Teleporting to Jump Machine...")
                            local moved, moveErr = pcall(function()
                                character:PivotTo(CFrame.new(target + Vector3.new(0, 4, 0)))
                            end)
                            if moved then
                                task.wait(2)
                                if active() then
                                    say("Buying +1 Jump " .. tostring(index) .. "...")
                                    sent, response = pcall(function()
                                        return remote:InvokeServer({ Upgrade = "+1 Jump", Index = index })
                                    end)
                                end
                            else
                                response = tostring(moveErr)
                            end
                        end
                    end)
                    if not okTrip then
                        sent, response = false, "Error: " .. tostring(tripErr)
                        warn("[WORST Double Jump] trip error:", tripErr)
                    end
                    task.wait(1.5)
                    if priority and priority.releaseTrip then
                        priority.releaseTrip("DoubleJump")
                    end
                    holding = false
                    if not (alive and on and generation == id) then break end
                    -- the server's answer: success flag, or the level shows up in the replicated data (can take a few seconds)
                    local function readLevel()
                        local d = getData(controller)
                        return d and (tonumber(d.PhysicalUpgrades.DoubleJump) or 0)
                    end
                    local serverOK = response == true
                        or (type(response) == "table" and (response.Success == true or response.Unlocked == true))
                    local newLevel = readLevel()
                    local tWait = os.clock()
                    while sent and not (type(newLevel) == "number" and newLevel >= index)
                        and not serverOK and os.clock() - tWait < 6 and alive and on and generation == id do
                        task.wait(0.5)
                        newLevel = readLevel()
                    end
                    if not (alive and on and generation == id) then break end
                    local bought = (type(newLevel) == "number" and newLevel >= index) or (sent and serverOK)
                    if bought then
                        confirmed = math.max(confirmed, index)
                        failStreak = 0
                        nextRetry = 0
                        lastAttemptLevel = confirmed
                        lastFailure = ""
                        say("Double Jump upgraded to " .. tostring(confirmed) .. "; buying the next level...")
                    elseif sent then
                        -- the server answered but did not unlock it
                        failStreak = failStreak + 1
                        local text = brief(response):lower()
                        if level >= LIMIT_FROM and (failStreak >= LIMIT_FAILS or text:find("max", 1, true)) then
                            -- stopped after 8-10 jumps = that is the limit: stop purchasing
                            nextRetry = os.clock() + IDLE_AFTER_REFUSAL
                            lastFailure = "Limit reached: " .. tostring(level) .. " jumps"
                            failStreak = 0
                            say("Jump " .. tostring(level) .. " | " .. lastFailure .. " | Purchasing stopped, next check in " .. fmtWait(IDLE_AFTER_REFUSAL))
                            print("[WORST Double Jump] limit reached at " .. tostring(level) .. " jumps; last answer: " .. brief(response))
                        else
                            -- below the limit zone (or not sure yet): keep trying, slowly backing off (e.g. not enough Gems yet)
                            local delay = math.min(5 * failStreak, 60)
                            nextRetry = os.clock() + delay
                            lastFailure = "Server refused +1 Jump " .. tostring(index) .. " (try " .. tostring(failStreak) .. ")"
                            say("Jump " .. tostring(level) .. " | " .. lastFailure .. " | Retry in " .. fmtWait(delay))
                            warn("[WORST Double Jump] index " .. tostring(index) .. " not unlocked (try " .. tostring(failStreak) .. "). Response: " .. brief(response))
                        end
                    else
                        -- machine not loaded / remote error: back off briefly instead of spamming (does not count towards the limit)
                        nextRetry = os.clock() + 45
                        local detail = "Remote error: " .. brief(response)
                        lastFailure = detail
                        say("Jump " .. tostring(level) .. " | " .. detail .. " | Retry in 45s")
                        warn("[WORST Double Jump]", detail)
                    end
                else
                    say("Jump " .. tostring(level) .. " | " .. lastFailure .. " | Next check in " .. fmtWait(nextRetry - os.clock()))
                end
            end
            local elapsed = 0
            while alive and on and generation == id and elapsed < 3 do
                task.wait(0.25)
                elapsed = elapsed + 0.25
            end
        end
    end
    entry.callback = function(value)
        on = value == true
        generation = generation + 1
        if on then
            nextRetry = 0
            lastAttemptLevel = nil
            lastFailure = ""
            confirmed, failStreak = 0, 0
            say("Scanning Double Jump upgrades...")
            local id = generation
            task.spawn(function() run(id) end)
        else
            if holding and Logic and Logic.priority and Logic.priority.releaseTrip then
                pcall(Logic.priority.releaseTrip, "DoubleJump")
                holding = false
            end
            say("Auto Double Jump disabled.")
        end
    end
    table.insert(cleanupHooks, function() on = false; generation = generation + 1 end)
    return entry
end)()

-- Coin chests: Sky Island first, then Desert. Each has its own server cooldown.
local DesertChest = (function()
    local RS = game:GetService("ReplicatedStorage")
    local chests = {
        {key = "SkyIsland", label = "Sky Island", cf = CFrame.new(-11.399580955505371, -28.014537811279297, -1858.01171875,
            0.921389639377594, 1.05265245409214e-08, 0.38864004611968994,
            2.7346688469265246e-08, 1, -9.191919048134878e-08,
            -0.38864004611968994, 9.532141120871529e-08, 0.921389639377594)},
        {key = "Desert", label = "Desert", cf = CFrame.new(-63.77114486694336, 3651.628173828125, -2099.4404296875,
            0.9304943084716797, -1.3800431908350674e-08, 0.3663064241409302,
            1.9580882693048807e-08, 1, -1.2064948151646604e-08,
            -0.3663064241409302, 1.8398967682742295e-08, 0.9304943084716797)},
    }
    local entry = {
        -- TOGGLE "Auto Chest Coins": Claims Sky Island first, waits 0.5s, then Desert.
        type = "toggle", name = "Auto Chest Coins", icon = "💰", default = false,
        desc = "Claims Sky Island first, waits 0.5s, then Desert. Tracks each chest's own cooldown.",
    }
    local on, generation = false, 0
    local nextAttempt = {SkyIsland = 0, Desert = 0}
    -- Sets the status text of Auto Chest Coins.
    local function say(message)
        if entry._desc and entry._desc.Parent then entry._desc.Text = message end
    end
    -- Returns your player data from the controller.
    local function playerData(controller)
        for _, replica in pairs(controller._replicas or {}) do
            local d = replica.Data
            if type(d) == "table" and type(d.TapChests) == "table" and type(d.Currencies) == "table" then
                return d
            end
        end
    end
    -- Main loop of Auto Chest Coins.
    local function run(id)
        local ok, controller, remote = pcall(function()
            return require(RS.Controllers.Core.ReplicaController), RS.RemoteServices.TapChestService.RF.Claim
        end)
        if not ok then say("Coin chests unavailable: " .. tostring(controller)); return end
        -- True while this run is still the current one.
        local function active() return alive and on and generation == id end
        -- True if a chest is ready to be claimed.
        local function ready(chest, data)
            return (tonumber(data.TapChests[chest.key]) or 0) <= os.time()
                and os.clock() >= nextAttempt[chest.key]
        end
        -- Claims one chest.
        local function claim(chest)
            if not active() then return end
            local character = player.Character
            local moved = character and pcall(function() character:PivotTo(chest.cf) end)
            if not moved then
                say(chest.label .. ": character not ready; retrying in 30s")
                nextAttempt[chest.key] = os.clock() + 30
                return
            end
            say("At " .. chest.label .. " chest; claiming...")
            task.wait(2) -- preserve original chest arrival delay
            if not active() then return end
            local sent, result = pcall(function() return remote:InvokeServer(chest.key) end)
            task.wait(0.3)
            local updated = playerData(controller)
            local nextReady = updated and tonumber(updated.TapChests[chest.key]) or 0
            if nextReady > os.time() then
                say(chest.label .. " chest claimed! Waiting for cooldown.")
            else
                say(chest.label .. " claim unconfirmed: " .. tostring(result) .. "; retrying in 60s")
                nextAttempt[chest.key] = os.clock() + 60
            end
        end
        while active() do
            local d = playerData(controller)
            if not d then
                say("Waiting for coin chest data...")
            else
                local skyReady = ready(chests[1], d)
                local desertReady = ready(chests[2], d)
                if skyReady or desertReady then
                    local priority = Logic and Logic.priority
                    local held = priority and priority.acquireTrip and priority.acquireTrip("Craft", active, say) or active()
                    if held and active() then
                        if skyReady then claim(chests[1]) end
                        if active() and skyReady and desertReady then task.wait(0.5) end
                        if active() and desertReady then
                            local current = playerData(controller)
                            if current and ready(chests[2], current) then claim(chests[2]) end
                        end
                        if priority and priority.releaseTrip then priority.releaseTrip("Craft") end
                    end
                else
                    -- Seconds left until a chest can be claimed.
                    local function remaining(chest)
                        local cooldown = math.max(0, (tonumber(d.TapChests[chest.key]) or 0) - os.time())
                        local retry = math.max(0, nextAttempt[chest.key] - os.clock())
                        local seconds = math.ceil(math.max(cooldown, retry))
                        return string.format("%02d:%02d:%02d", math.floor(seconds/3600), math.floor(seconds/60)%60, seconds%60)
                    end
                    say("Sky Island: " .. remaining(chests[1]) .. " | Desert: " .. remaining(chests[2]))
                end
            end
            for _ = 1, 10 do
                if not active() then break end
                task.wait(0.5)
            end
        end
    end
    entry.callback = function(value)
        on = value == true
        generation = generation + 1
        if on then
            nextAttempt = {SkyIsland = 0, Desert = 0}
            task.spawn(run, generation)
        else
            say("Auto Chest Coins disabled")
        end
    end
    table.insert(cleanupHooks, function() on = false; generation = generation + 1 end)
    return entry
end)()

-- Miscellaneous tab: server hopping / rejoin / join by Job ID / join a low-population server / walk + jump speed
local Miscellaneous = (function()
    local TeleportService = game:GetService("TeleportService")
    local RunService = game:GetService("RunService")
    local PLACE_ID = game.PlaceId

    -- Downloads a web page (uses request(), falls back to HttpGet).
    local function httpGet(url)
        local req = (typeof(request) == "function" and request) or (typeof(http_request) == "function" and http_request)
            or (typeof(syn) == "table" and syn.request) or (typeof(http) == "table" and http.request)
        if req then
            local res = req({ Url = url, Method = "GET" })
            if res and res.Body and res.Body ~= "" then return res.Body end
        end
        return game:HttpGet(url)
    end

    -- the public server list of this game (order = "Asc": fewest players first, "Desc": most players first)
    local function servers(order)
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&excludeFullGames=true&limit=100"):format(PLACE_ID, order)
        local body = httpGet(url)
        local data = HttpService:JSONDecode(body)
        local list = {}
        for _, sv in ipairs(data and data.data or {}) do
            if sv.id ~= game.JobId and tonumber(sv.playing) and tonumber(sv.maxPlayers) and sv.playing < sv.maxPlayers then
                list[#list + 1] = sv
            end
        end
        return list
    end

    -- Teleports you to a server (by Job ID) of this game.
    local function joinServer(jobId)
        TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, player)
    end

    local hop = {
        type = "button", name = "Hop Different Server", icon = "🔀", noSave = true,
        desc = "Teleports you to a different public server of this game (picked at random from the ones that are not full).",
        run = function()
            local list = servers("Desc")
            local roomy = {}
            for _, sv in ipairs(list) do if sv.playing < sv.maxPlayers - 1 then roomy[#roomy + 1] = sv end end
            if #roomy == 0 then roomy = list end
            if #roomy == 0 then error("no other server found", 0) end
            joinServer(roomy[math.random(1, #roomy)].id)
        end,
    }
    local rejoin = {
        type = "button", name = "Rejoin Same Server", icon = "🔄", noSave = true,
        desc = "Leaves and joins the server you are in right now again.",
        run = function()
            joinServer(game.JobId)
        end,
    }
    local lastJob, lastJobAt = "", 0
    local jobId = {
        type = "input", name = "Join Job ID", icon = "#", noSave = true, default = "",
        placeholder = "paste a Job ID, press Enter",
        desc = "Paste the Job ID of a server of this game and press Enter (or click away) to join it.",
        callback = function(text)
            text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if text == "" then return end
            if text == lastJob and os.clock() - lastJobAt < 10 then return end
            lastJob, lastJobAt = text, os.clock()
            local ok, err = pcall(joinServer, text)
            if not ok then warn("[Miscellaneous] Join Job ID failed: " .. tostring(err)) end
        end,
    }
    local low = {
        type = "button", name = "Join Low Player Server", icon = "👇", noSave = true,
        desc = "Teleports you to the public server of this game with the fewest players (not full, not the one you are in).",
        run = function()
            local list = servers("Asc")
            if #list == 0 then error("no other server found", 0) end
            local best = list[1]
            for _, sv in ipairs(list) do if sv.playing < best.playing then best = sv end end
            joinServer(best.id)
        end,
    }

    -- walk speed / jump power: only enforced after you have moved a slider (the game's own values are left alone until then)
    local DEF_WS, DEF_JP = 16, 50
    local ws, jp = DEF_WS, DEF_JP
    local touched = false
    -- Applies your Walk Speed / Jump Power to the character.
    local function apply()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if hum.WalkSpeed ~= ws then hum.WalkSpeed = ws end
        if hum.UseJumpPower ~= true then hum.UseJumpPower = true end
        if hum.JumpPower ~= jp then hum.JumpPower = jp end
    end
    local speed = {
        type = "slider", name = "Walk Speed", icon = "👟", min = 16, max = 250, default = DEF_WS, step = 1,
        desc = "Your walking speed (16 = normal).",
        callback = function(v)
            ws = tonumber(v) or DEF_WS
            if ws ~= DEF_WS then touched = true end
            if touched then apply() end
        end,
    }
    local jump = {
        type = "slider", name = "Jump Power", icon = "🆙", min = 50, max = 300, default = DEF_JP, step = 1,
        desc = "How high you jump (50 = normal).",
        callback = function(v)
            jp = tonumber(v) or DEF_JP
            if jp ~= DEF_JP then touched = true end
            if touched then apply() end
        end,
    }
    local conn = RunService.Heartbeat:Connect(function()
        if alive and touched then pcall(apply) end
    end)
    table.insert(cleanupHooks, function()
        pcall(function() conn:Disconnect() end)
        if touched then
            ws, jp = DEF_WS, DEF_JP
            pcall(apply)
        end
    end)

    return { hop, rejoin, jobId, low, speed, jump }
end)()

local TAB_SCRIPTS = {
	Home = {},   -- the Home tab is drawn by hand further down
	Kaitun = Logic and Logic.kaitun and { Logic.kaitun.main, Logic.kaitun.second } or {},
	-- the Farming tab (was "Hatch") has its own pages, like Pets: Hatch, Auto Rebirth, Auto Delete (eggs)
	Farming = { pages = {
		{ name = "Hatch", entries = Logic and { Logic.egg, Logic.hatch } or {} },
		{ name = "Auto Rebirth", entries = AutoRebirth },
		{
			name = "Delete Hatches",
			entries = (Logic and Logic.autodel and {
				Logic.autodel.egg,
				Logic.autodel.from, Logic.autodel.to,
				Logic.autodel.variants, Logic.autodel.refresh, Logic.autodel.auto,
			}) or {
				{
					type = "button", name = "Auto Delete unavailable", icon = "…", noSave = true,
					desc = "The auto delete logic failed to load - check the output for the reason.",
					run = function() error("Auto Delete failed to load") end,
				},
			},
		},
		{ name = "Islands", entries = Logic and Logic.islands and { Logic.islands.toggle, Logic.islands.pick, Logic.islands.go } or {} },
	} },
	-- the Pets tab has its own pages (buttons at the top of the tab): Crafting, Enchanting, Auto Equip, Auto Delete (inventory)
	Pets = Logic and { pages = {
		{
			name = "Crafting",
			entries = {
				Logic.storage,
				Logic.drop, Logic.goldenAmount, Logic.craft, Logic.craftAll,
				Logic.dDrop, Logic.dAmount, Logic.dCraft,
				Logic.rDrop, Logic.rAmount, Logic.rCraft,
				Logic.collect,
			},
		},
		{
			name = "Enchanting",
			entries = (Logic.enchant and {
				Logic.enchant.pet,
				Logic.enchant.target, Logic.enchant.slot,
				Logic.enchant.replace, Logic.enchant.auto,
				Logic.enchant.v2, Logic.enchant.v2Pet,
			}) or {
				{
					type = "button", name = "Auto Enchant unavailable", icon = "…", noSave = true,
					desc = "The enchant logic failed to load - check the output for the reason.",
					run = function() error("Auto Enchant failed to load") end,
				},
			},
		},
		{ name = "Auto Equip", entries = AutoEquip },
		{
			name = "Delete Pets",
			entries = (Logic.autodel and {
				Logic.autodel.invFrom, Logic.autodel.invTo,
				Logic.autodel.invVariants, Logic.autodel.invDelete, Logic.autodel.invAuto,
			}) or {
				{
					type = "button", name = "Auto Delete unavailable", icon = "…", noSave = true,
					desc = "The auto delete logic failed to load - check the output for the reason.",
					run = function() error("Auto Delete failed to load") end,
				},
			},
		},
	} } or {},
	-- All non-Halloween event controls now live together on General.
	Events = Logic and { pages = {
		{ name = "General", entries = (function()
			local entries = { Logic.priority.duck, SkillPoints[1], DoubleJump, DesertChest }
			if Logic.petdef then
				entries[#entries + 1] = Logic.petdef.toggle
				entries[#entries + 1] = Logic.petdef.mode
				entries[#entries + 1] = Logic.petdef.info
			end
			if Logic.balloon then entries[#entries + 1] = Logic.balloon.toggle end
			if Logic.dig then entries[#entries + 1] = Logic.dig.toggle end
			return entries
		end)() },
		{ name = "Halloween", entries = Logic.halloween and {
			Logic.halloween.treat, Logic.halloween.boss,
			Logic.halloween.shop, Logic.halloween.items,
		} or {} },
	} } or {},
	Trade = { pages = {
		{ name = "General", entries = TradeAgent.entries },
		{ name = "Giveaway", entries = TradeAgent.giveaway or {} },
	} },
	Priority = {},
	Webhook = {
		{
			type = "webhook", name = "Webhook", icon = "🔗", noSave = true,
			desc = "Discord webhook link",
			placeholder = "https://discord.com/api/webhooks/...",
		},
		webhookNewPets,
		webhookEnchants,
		webhookBlur,
	},
	Miscellaneous = Miscellaneous,
	Settings = {
		{
			-- TOGGLE "Animated Background": Floating ash and a soft glow behind the UI.
			type = "toggle", name = "Animated Background", icon = "🎨", default = true,
			desc = "Floating ash and a soft glow behind the UI. Turn it off if you want the UI as light as possible.",
			callback = function(on)
				FX.bg = on == true
				if FX.layer then FX.layer.Visible = FX.bg end
				if FX.holder then FX.holder.Visible = FX.bg end   -- the animated GIF background
				if FX.panel then FX.panel.BackgroundTransparency = FX.bg and (FX.panelTrans or 0.8) or 0 end   -- solid panel when off
			end,
		},
		{
			type = "keybind", name = "Minimize Keybind", icon = "🔑",
			desc = "Click the box, then press any key. Default: Left Ctrl.",
		},
		{
			type = "slider", name = "FPS Cap", icon = "🕐", min = 0, max = 240, default = 0, step = 5,
			format = function(v) return v == 0 and "Off" or tostring(v) end,
			desc = "Limits your FPS to this value (Off = no limit). The Mini Ui does not limit FPS. Needs an executor with setfpscap.",
			callback = function(v)
				Config.fps.user = tonumber(v) or 0
				Config.fps.touched = true
				Config.applyFps()
			end,
		},
		{
			type = "configsave", name = "Save Configuration", icon = "💾", noSave = true,
			desc = "Type a name, then Save to add it to the list below.",
		},
		{
			-- TOGGLE "Auto Save Configuration": Saves every toggle, slider and dropdown you change.
			type = "toggle", name = "Auto Save Configuration", icon = "S", noSave = true,
			default = true,   -- always switched on when the script is executed
			desc = "Saves every toggle, slider and dropdown you change. Switches on by itself and loads your saved settings every time you execute.",
			callback = function(on) Config.setAuto(on) end,
		},
		{
			-- TOGGLE "Anti AFK": Stops Roblox from kicking you for being idle.
			type = "toggle", name = "Anti AFK", icon = "Z",
			desc = "Stops Roblox from kicking you for being idle.",
			callback = function(on) Utility.antiAfk(on) end,
		},
		{
			-- TOGGLE "Auto Click": Switches on by itself every time you execute the script.
			type = "toggle", name = "Auto Click", icon = "🖱", noSave = true, default = true,
			desc = "Switches on by itself every time you execute the script. Sends a tap to the game about 8 times a second through its tap remote (the counter carries on between executes).",
			callback = function(on) Utility.autoClick(on == true) end,
		},
		{
			-- TOGGLE "Auto Rejoin": Rejoins the server automatically if you get disconnected.
			type = "toggle", name = "Auto Rejoin", icon = "R",
			desc = "Rejoins the server automatically if you get disconnected.",
			callback = function(on) Utility.autoRejoin(on) end,
		},
		{
			-- TOGGLE "Hide Hatch Animation": Hides the game's egg hatch animation (hatching keeps working) and keeps the camera and HUD steady.
			type = "toggle", name = "Hide Hatch Animation", icon = "🥚", default = false,
			desc = "Hides the game's egg hatch animation (hatching keeps working) and keeps the camera and HUD steady. Off = the game's animation, with egg and pet names, is left completely alone.",
			callback = function(on) Utility.hideHatch(on == true) end,
		},
		{
			-- TOGGLE "Hide User": Hides your name tag above your character (and any other tag in the world that shows your username / display name).
			type = "toggle", name = "Hide User", icon = "👤", default = false,
			desc = "Hides your name tag above your character (and any other tag in the world that shows your username / display name). Turn it off to bring it back.",
			callback = function(on) Utility.hideUser(on == true) end,
		},
		{
			type = "dropdown", name = "Eggs Per Hatch", icon = "🥚", width = 300,
			desc = "Auto = presses the game's F key to see if you own Octa (8x) - every time hatching starts or continues after another feature. If the game hatches 8 you hatch 8 at a time, if not 3. Or force 1, 3 or 8.",
			options = { "Auto (highest you own)", "1", "3", "8" }, default = "Auto (highest you own)",
			callback = function(option) Config.hatchCount = option end,
		},
		{
			type = "button", name = "Mini Ui", icon = "📱", noSave = true,
			desc = "Shrinks the hub away and opens the small Mini Ui (Kaitun Hatch + Kaitun Stats switch on; Kaitun Events only if you switch it on). 3D rendering is switched off while it is open (black screen with your username, what it is doing, hatches, rarest pet, ping and FPS in the middle); its [-] button hides the toggles. Use its Full UI button, or the minimize key, to come back.",
			run = function()
				local f = record.miniUi
				if not f then return false, "Mini Ui isn't available (the Kaitun controls were not found)" end
				return f()
			end,
		},
		{
			-- TOGGLE "Disable 3D Rendering": Turns 3D rendering off: the screen goes black and your username, current action, hatches, rarest pet, ping and FPS are shown in the middle.
			type = "toggle", name = "Disable 3D Rendering", icon = "🖥", default = false,
			desc = "Turns 3D rendering off: the screen goes black and your username, current action, hatches, rarest pet, ping and FPS are shown in the middle. Saves GPU / CPU while you farm. The Mini Ui switches it off by itself while it is open.",
			callback = function(on)
				Config.render3dOff = on == true
				if record.apply3d then record.apply3d() end
			end,
		},
		{
			-- TOGGLE "Show Status": Shows what every running feature is doing in the middle top of the screen, whether the hub is open or minimized.
			type = "toggle", name = "Show Status", icon = "i",
			desc = "Shows what every running feature is doing in the middle top of the screen, whether the hub is open or minimized. Hover it to see your username.",
			callback = function(on) Config.showStatus = on == true end,
		},
		{
			type = "configlist", name = "Configuration List", icon = "📂", noSave = true,
			desc = "Press a configuration to see its toggles. Load applies it, x deletes it.",
		},
	},
}

-- Auto Scan Inventory lives on the Settings tab (right after Auto Rejoin) and starts switched on
if Logic and Logic.scan then
	local pos = #TAB_SCRIPTS.Settings
	for i, e in ipairs(TAB_SCRIPTS.Settings) do
		if e.name == "Auto Rejoin" then pos = i break end
	end
	table.insert(TAB_SCRIPTS.Settings, pos + 1, Logic.scan)
end

-- lets Kaitun Hatch find the Settings toggles (Anti AFK, Auto Rejoin) by name
if Logic and Logic.priority then
	Logic.priority.findSetting = function(name)
		for _, pg in ipairs(TAB_SCRIPTS.Settings.pages or {}) do
			for _, e in ipairs(pg.entries) do
				if e.name == name then return e end
			end
		end
	end
end

-- the Settings tab has two pages. Ui = the entries listed here (in this order), General = everything else.
-- (Reset Script is not a row any more: it is a button at the top right of the tab, see buildScriptPage.)
do
	local PAGE2 = { "Animated Background", "Minimize Keybind", "Auto Save Configuration", "Show Status", "Mini Ui", "Disable 3D Rendering", "Auto Rejoin", "Anti AFK", "Save Configuration", "Configuration List", "FPS Cap" }
	local isP2, byName, p1, p2 = {}, {}, {}, {}
	for _, n in ipairs(PAGE2) do isP2[n] = true end
	for _, e in ipairs(TAB_SCRIPTS.Settings) do
		if isP2[e.name] then byName[e.name] = e else p1[#p1 + 1] = e end
	end
	for _, n in ipairs(PAGE2) do
		if byName[n] then p2[#p2 + 1] = byName[n] end
	end
	TAB_SCRIPTS.Settings = { pages = { { name = "General", entries = p1 }, { name = "Ui", entries = p2 } } }
end


---------------------------------------------------------------- KAITUN HATCH + KAITUN STATS
-- Kaitun Hatch (master): switches every other feature toggle off, then runs delete / hatch latest detected egg / craft + collect / Anti AFK / Auto Rejoin /
--   Show Status itself, in the order of the Priority tab.
-- Kaitun Stats (needs Kaitun Hatch) runs Auto Rebirth + Auto Equip and the enchanting; Kaitun Hatch itself no longer touches your pets. Kaitun Events: switches Auto Chest Coins, Auto Trick or Treat, Auto Kill Hallow Boss and Auto Purchase Items
--   on BY ITSELF and shows live numbers. It works with Kaitun Hatch on or off. Settings / Webhook toggles are not touched.
do
	local K = Logic and Logic.kaitun
	if K and K.main and AutoRebirth then
		local RS = game:GetService("ReplicatedStorage")
		local mainEntry, statsEntry = K.main, K.second
		local ovr = Config.override
		local kOn = false          -- Kaitun Hatch
		local stOn = false         -- Kaitun Stats
		local statsOn = false      -- Kaitun Events
		local hw = Logic.halloween

		-- fixed settings Kaitun Events uses (there are no rows for them any more)
		local REBIRTH_AMOUNT = AutoRebirth[2].default   -- "Best" = the most expensive rebirth you can afford
		local REBIRTH_DELAY  = 300                         -- seconds between two rebirth requests
		local STATS_DESC = statsEntry.desc

		-- True if an entry is currently on.
		local function entryOn(e) return e and e._get and e._get() == true end
		-- Sets the status text of an entry.
		local function say(e, text) local l = e._desc if l and l.Parent then l.Text = text end end

		-- problems of the modules are shown in front of the stats line (so a module that is not doing anything says why)
		local notes = {}
		-- Stores a note for Kaitun.
		local function note(key, text) notes[key] = text end

		---------------------------------------------------------------- helpers: drive the normal features / keep the user's own values
		local owned = {}   -- toggles Kaitun Events / Kaitun Hatch switched on: what is SAVED for them stays "off" (they start them themselves)
		-- Flips an entry's toggle in the UI.
		local function flipU(e, on)
			if not (e and e._setUI) then return end
			local was = entryOn(e)
			if on then
				if not was then e._setUI(true) end
				owned[e] = true
				if e._id and ovr[e._id] == nil then ovr[e._id] = false end
			else
				if was then e._setUI(false) end
				owned[e] = nil
				if e._id and not kOn then ovr[e._id] = nil end   -- with Kaitun Hatch on it still owns the saved value
			end
		end
		-- sets another control to a Kaitun value; the value you had is what gets saved (and is put back when Kaitun goes off)
		local function override(e, value)
			local c = e and e._id and controls[e._id]
			if not c then return false end
			if ovr[e._id] == nil then ovr[e._id] = c.get() end
			c.set(value)
			return true
		end
		-- Releases an entry that Kaitun was holding.
		local function release(e)
			local id = e and e._id
			if not id then return end
			local old = ovr[id]
			ovr[id] = nil
			if old ~= nil and controls[id] then controls[id].set(old) end
		end

		local SKIP = { ["Replace Rare / III Enchants"] = true, ["Auto Scan Inventory"] = true, ["Auto Delete Inventory"] = true }   -- settings, not features (Pets tab Auto Delete Inventory is never switched on/off by Kaitun: it stays exactly as you set it)
		-- Calls fn for every toggle that Kaitun manages.
		local function eachManaged(fn)
			for _, tabName in ipairs({ "Farming", "Pets", "Events" }) do
				local t = TAB_SCRIPTS[tabName]
				if t then
					-- Scans one list of entries for toggles.
					local function scan(list)
						for _, e in ipairs(list or {}) do
							if type(e) == "table" and e.type == "toggle" and not SKIP[e.name] then fn(e) end
						end
					end
					if t.pages then for _, pg in ipairs(t.pages) do scan(pg.entries) end else scan(t) end
				end
			end
		end

		---------------------------------------------------------------- Auto Rebirth (run by Kaitun Stats)
		local function rebirthApply(on)
			local tog, amt, dly = AutoRebirth[1], AutoRebirth[2], AutoRebirth[3]
			if on then
				override(amt, REBIRTH_AMOUNT)
				override(dly, REBIRTH_DELAY)
				flipU(tog, true)
			else
				flipU(tog, false)
				release(amt)
				release(dly)
			end
		end

		---------------------------------------------------------------- Auto Events (run by Kaitun Events): chest coins, Trick or Treat, Hallow boss, shop
		-- one event feature at a time (the green checks on the Kaitun tab can switch each of them off)
		function K.eventPart(key, on)
			if key == "chest" then
				flipU(DesertChest, on)   -- Auto Chest Coins
			elseif not hw then
				return
			elseif key == "treat" then
				flipU(hw.treat, on)
			elseif key == "boss" then
				flipU(hw.boss, on)
			elseif key == "shop" then
				if on then
					local want = {}
					for _, l in ipairs(hw.items.options) do want[#want + 1] = l end   -- Buy All
					if not override(hw.items, table.concat(want, "|")) then
						note("events", "[Debug] Items to Buy isn't ready yet - it uses its own list")
					else
						note("events", nil)
					end
					flipU(hw.shop, true)
				else
					flipU(hw.shop, false)
					release(hw.items)
					note("events", nil)
				end
			end
		end
		-- Turns the Kaitun Events features on or off.
		local function eventsApply(on)
			if on then
				if not K.skip.chest then K.eventPart("chest", true) end   -- Auto Chest Coins runs with the other events
				if not hw then
					note("events", "[Debug] The Halloween logic did not load - no events")
					return
				end
				for _, key in ipairs({ "treat", "boss", "shop" }) do
					if not K.skip[key] then K.eventPart(key, true) end
				end
			else
				flipU(DesertChest, false)
				if not hw then return end
				flipU(hw.treat, false)
				flipU(hw.boss, false)
				flipU(hw.shop, false)
				release(hw.items)
				note("events", nil)
			end
		end
		for _, key in ipairs({ "chest", "treat", "boss", "shop" }) do
			K.hooks[key] = {
				active = function() return statsOn end,
				on = function() K.eventPart(key, true) end,
				off = function() K.eventPart(key, false) end,
			}
		end

		---------------------------------------------------------------- Auto Equip (run by Kaitun Stats): Luckiest while hatching, Richest right before the rebirth
		local eq = { run = 0, swapping = false, got = nil, lastSwap = -1e9 }
		local EQUIP_REFRESH = 300   -- seconds between two "equip Luckiest" refreshes (was 30: the pets kept re-summoning)
		local SWAP_MIN      = 60    -- at most one Richest <-> Luckiest swap per this many seconds (rebirth tries run every few seconds)
		-- Finds the server remote for equipping pets.
		local function petRemote()
			local n = RS
			for _, nm in ipairs({ "RemoteServices", "PetService", "RE", "PetActionRequested" }) do
				n = n and n:FindFirstChild(nm)
				if not n then return nil end
			end
			return n
		end
		do
			local node
			pcall(function() node = RS.RemoteServices.PetService.RE.PetActionResult end)
			if node and node:IsA("RemoteEvent") then
				connect(node.OnClientEvent, function(a)
					if type(a) == "table" and a.Action == "EquipBest" then eq.got = a end
				end)
			end
		end
		-- Equips the pets of a mode (Luckiest / Richest).
		local function equipMode(mode, waitFor)
			local r = petRemote()
			if not r then return false, "PetService.RE.PetActionRequested not found" end
			if SecretGuard.held() then return true end   -- a trade is running: do not put pets back on
			eq.got = nil
			local ok, err = pcall(function() r:FireServer({ Action = "EquipBest", Mode = mode }) end)
			if not ok then return false, tostring(err) end
			if waitFor then
				local t0 = os.clock()
				while alive and not eq.got and os.clock() - t0 < waitFor do task.wait(0.05) end
				if eq.got and eq.got.Success == false then return false, "server refused: " .. tostring(eq.got.Reason or eq.got.Error or "no reason given") end
				if not eq.got then return false, "no answer from the server" end
			end
			return true
		end
		-- Turns Kaitun's Auto Equip on or off.
		local function equipApply(on)
			eq.run = eq.run + 1
			eq.swapping = false
			if not on then note("equip", nil) return end
			local my = eq.run
			task.spawn(function()
				while alive and kOn and stOn and eq.run == my do
					if not eq.swapping then
						local ok, why = equipMode("Luck", 3)
						note("equip", (not ok) and ("[Debug] Equip Luckiest failed: " .. tostring(why)) or nil)
						if ok then task.wait(0.5) pcall(SecretGuard.sweep) end   -- secret pets never stay equipped
					end
					local t0, lastCheck = os.clock(), os.clock()
					while alive and kOn and stOn and eq.run == my and os.clock() - t0 < EQUIP_REFRESH do
						task.wait(0.25)
						if not eq.swapping and os.clock() - lastCheck >= 10 then   -- secret pets that got equipped some other way
							lastCheck = os.clock()
							pcall(SecretGuard.sweep)
						end
					end
				end
			end)
		end
		AutoRebirth.state.before = function()   -- called by Auto Rebirth right before every rebirth try
			if not (kOn and stOn) then return end
			while alive and eq.probing do task.wait(0.1) end   -- Kaitun Stats is looking for the Richest pets: let it finish first
			if os.clock() - eq.lastSwap < SWAP_MIN then return end
			eq.lastSwap = os.clock()
			eq.swapping = true
			local ok, why = equipMode("Gems", 3)
			note("equip", (not ok) and ("[Debug] Equip Richest failed: " .. tostring(why)) or nil)
			if ok then task.wait(0.5) pcall(SecretGuard.sweep) end   -- secret pets never stay equipped
			task.wait(0.2)
		end
		AutoRebirth.state.after = function()
			if not eq.swapping then return end
			eq.swapping = false
			if kOn and stOn then
				local ok = equipMode("Luck", 3)
				if ok then task.wait(0.5) pcall(SecretGuard.sweep) end   -- secret pets never stay equipped
			end
			eq.swapEnd = os.clock()   -- Kaitun Stats waits a few seconds after this before it reads the equipped pets
		end

		-- Kaitun Stats starts Auto Rebirth + Auto Equip (needs Kaitun Hatch; after the rows of the other tabs exist)
		local hat = { run = 0 }   -- generation counter: bumped whenever Kaitun Hatch or Kaitun Stats is switched, so an old start never runs
		-- Starts the Auto Rebirth + Auto Equip modules of Kaitun Stats.
		local function startStatsModules(my)
			for _ = 1, 40 do
				if not (alive and kOn and stOn and hat.run == my) then return end
				if AutoRebirth[1]._setUI then break end
				task.wait(0.25)
			end
			task.wait(0.4)
			if not (alive and kOn and stOn and hat.run == my) then return end
			if K.skip.rebirth then return end   -- switched off with its green check on the Kaitun tab
			rebirthApply(true)
			equipApply(true)
		end
		K.hooks.rebirth = {
			active = function() return kOn and stOn end,
			on = function() task.spawn(startStatsModules, hat.run) end,
			off = function() pcall(rebirthApply, false) pcall(equipApply, false) end,
		}

		---------------------------------------------------------------- Kaitun Events = switches the event modules on + shows live numbers
		local stats = { run = 0, t0 = os.clock() }
		-- Formats seconds as a time text.
		local function fmtT(s)
			s = math.max(0, math.floor(s))
			return string.format("%d:%02d:%02d", math.floor(s / 3600), math.floor(s / 60) % 60, s % 60)
		end
		local SHORT = { Craft = "Craft", Enchant = "Enchant", TrickOrTreat = "Treat", HallowLord = "Lord", PetDefense = "Defense", Dig = "Dig", Balloon = "Balloon", Hatch = "Hatch" }
		-- Stops all Kaitun modules.
		local function stopModules()
			eventsApply(false)
		end
		-- Starts all Kaitun modules (waits for the other tabs to exist first).
		local function startModules(my)
			-- the rows of the other tabs have to exist (right after the hub loads a saved configuration they may not yet)
			for _ = 1, 40 do
				if not (alive and statsOn and stats.run == my) then return end
				if (not DesertChest or DesertChest._setUI) and (not hw or (hw.treat and hw.treat._setUI)) then break end
				task.wait(0.25)
			end
			task.wait(0.4)
			if not (alive and statsOn and stats.run == my) then return end
			eventsApply(true)
		end
		-- Turns the Kaitun stats display on or off.
		local function statsApply(on)
			stats.run = stats.run + 1
			if not on then
				stopModules()
				for k in pairs(notes) do notes[k] = nil end
				say(statsEntry, STATS_DESC)
				return
			end
			if not kOn then stats.t0 = os.clock() end
			local my = stats.run
			task.spawn(startModules, my)
			task.spawn(function()
				while alive and statsOn and stats.run == my do
					local okS, errS = pcall(function()
						local c = K.counts and K.counts() or {}
						local order = {}
						for _, k in ipairs((Logic.priority and Logic.priority.order) or {}) do order[#order + 1] = SHORT[k] or k end
						local problems = {}
						for _, t in pairs(notes) do problems[#problems + 1] = t end
						say(statsEntry, string.format("%s%sRuntime %s | hatched %d | crafts G/D/R %d/%d/%d | rebirth requests %d | priority %s",
							#problems > 0 and (table.concat(problems, " | ") .. " || ") or "",
							kOn and "" or "(Kaitun Hatch off) ",
							fmtT(os.clock() - stats.t0), c.hatched or 0, c.golden or 0, c.diamond or 0, c.rainbow or 0,
							AutoRebirth.state.sent or 0, table.concat(order, " > ")))
					end)
					if not okS then say(statsEntry, "[Debug] Stats failed: " .. tostring(errS)) end
					task.wait(1)
				end
			end)
		end
		statsEntry.callback = function(on)
			statsOn = on == true
			statsApply(statsOn)
		end

		---------------------------------------------------------------- Kaitun Hatch: master switch for everything else
		local origCb = mainEntry.callback
		mainEntry.callback = function(on)
			on = on == true
			if not alive then
				if origCb then origCb(on) end
				return
			end
			if on == kOn then return end
			kOn = on
			hat.run = hat.run + 1
			if on then
				if not statsOn then stats.t0 = os.clock() end
				-- master toggle: every other feature is switched off first (what Kaitun Events runs stays on); what is saved for them stays "off"
				-- every step is guarded: an error in one of them must never stop the real Kaitun start (auto delete + hatch) below
				local okSweep, errSweep = pcall(eachManaged, function(e)
					if e._id then ovr[e._id] = false end
					if not owned[e] and entryOn(e) and e._setUI then pcall(e._setUI, false) end
				end)
				if not okSweep then warn("[WORST Hub] Kaitun: switching the other features off failed: " .. tostring(errSweep)) end
				if Config.shell then pcall(Config.shell.set, true) end
				if origCb then origCb(true) end
				if stOn then task.spawn(startStatsModules, hat.run) end   -- Kaitun Stats' Auto Rebirth + Auto Equip (Kaitun Hatch itself no longer touches pets)
			else
				pcall(rebirthApply, false)
				pcall(equipApply, false)
				if origCb then origCb(false) end
				eachManaged(function(e) if e._id then ovr[e._id] = nil end end)
				for e in pairs(owned) do if e._id then ovr[e._id] = false end end   -- Kaitun Events still runs these
				if Config.shell then Config.shell.set(false) end
			end
		end

		---------------------------------------------------------------- Kaitun Stats (its own module: it never touches another toggle, and an error in it never reaches them)
		-- Waits for Kaitun Hatch. Works ONLY while you are really hatching (HG.isHatching). Uses the game's own server-side auto roll (EnchantService),
		-- one pet and one slot at a time:  1) the pets you have equipped -> Secret Hunter / Four Leaf / Lucky 3 in both slots
		--                                  2) when those are done -> the pets "Richest" would equip (asked from the server once, then Luckiest is put back) -> Renewal 3
		xpcall(function()
			local enchEntry = K.enchant
			if not enchEntry then return end
			local ENCH_DESC = enchEntry.desc
			local LUCK_NAMES = { "Secret Hunter", "Four Leaf", "Lucky 3" }
			local RICH_NAMES = { "Renewal 3" }
			local REPLACE_PROTECTED = true   -- true = a pet holding some other (Rare / III) enchant gets rerolled too; false = such slots are skipped
			local MAX_ROLLS_PER_TURN = 700 -- defer this pet/slot until other candidates have been tried
			local MAX_FAILS   = 5            -- refused / odd results in a row before a 60 s pause
			local CLAIM_WAIT  = 8            -- seconds to keep trying to take a pet back out of the enchanter
			local RICH_EVERY  = 600          -- seconds between two looks at the Richest pets
			local RECHECK     = 20           -- seconds between two checks once everything is enchanted

			local on, run = false, 0
			local mine = nil                  -- id of the pet WE put into the enchanter
			local rollCount, stopEvt = 0, nil
			local done = 0
			local used, usedAt = {}, os.clock()
			local rich = { ids = nil, at = -1e9 }
			local fails = 0
			local stick = nil                 -- pet we are working on: remains eligible after it is temporarily unequipped

			-- Sets the status text of Kaitun Stats.
			local function status(text) local l = enchEntry._desc if l and l.Parent then l.Text = text end end
			-- True while this enchant run is still the current one.
			local function act(my) return alive and on and run == my end
			-- Waits `secs` while the run is active.
			local function nap(my, secs)
				local t0 = os.clock()
				while act(my) and os.clock() - t0 < secs do task.wait(0.1) end
			end

			------------------------------------------------ game access
			local function enchService()
				local ok, svc = pcall(function() return RS.RemoteServices.EnchantService end)
				if not (ok and svc) then return nil end
				return svc:FindFirstChild("RF"), svc:FindFirstChild("RE")
			end
			local EC
			-- Returns the game's enchant controller.
			local function getEC()
				if EC then return EC end
				local ok, m = pcall(function() return require(RS.Shared.Pets.EnchantConfig) end)
				if ok and type(m) == "table" then EC = m end
				return EC
			end
			-- Calls an enchant remote function.
			local function call(name, args)
				local RF = enchService()
				local remote = RF and RF:FindFirstChild(name)
				if not remote then return nil, "NoRemote" end
				local okC, res = pcall(function()
					if args == nil then return remote:InvokeServer() end
					return remote:InvokeServer(args)
				end)
				if not okC then return nil, "Connection" end
				if type(res) == "table" and res.Success then return res end
				return nil, (type(res) == "table" and res.Reason) or "Unknown"
			end
			local evConn
			-- Connects the enchant events.
			local function hookEvents()
				if evConn then return end
				local _, RE = enchService()
				local ev = RE and RE:FindFirstChild("AutoEvent")
				if not ev then return end
				evConn = ev.OnClientEvent:Connect(function(d)
					if type(d) ~= "table" or mine == nil then return end   -- only OUR rolls
					if d.Kind == "Roll" then rollCount = rollCount + 1
					elseif d.Kind == "Stop" then stopEvt = d end
				end)
			end
			table.insert(cleanupHooks, function()
				on = false run = run + 1
				if evConn then pcall(function() evConn:Disconnect() end) end
			end)

			-- Returns the player's replicated data table.
			local function replicaData()
				local ok, data = pcall(function() return require(RS.Controllers.Core.DataController):GetReplica().Data end)
				if ok and type(data) == "table" and type(data.Pets) == "table" and type(data.Pets.Owned) == "table" then return data end
			end
			local EQUIP_KEYS = { "Equipped", "EquippedPets", "Equip", "Team", "Loadout" }
			-- Returns the set of equipped pets.
			local function equippedSet(data)   -- id -> true for every equipped pet (same detection the rest of the script uses)
				local set = {}
				for _, holder in ipairs({ data.Pets, data }) do
					for _, k in ipairs(EQUIP_KEYS) do
						local t = holder[k]
						if type(t) == "table" then
							for key, v in pairs(t) do
								if type(v) == "string" or type(v) == "number" then set[tostring(v)] = true
								elseif v == true or type(v) == "table" then set[tostring(key)] = true end
							end
						end
					end
				end
				for pid, p in pairs(data.Pets.Owned) do
					if type(p) == "table" then
						for _, k in ipairs(EQUIP_KEYS) do
							if type(p[k]) == "boolean" and p[k] then set[tostring(pid)] = true end
						end
					end
				end
				return set
			end
			-- Reads the enchant in one slot of a pet.
			local function slotValue(p, slot)
				if slot == 2 then return p.Enchant2 end
				return p.Enchant
			end
			-- Counts the enchant slots of a pet.
			local function slotCount(p)
				local ec = getEC()
				if ec and ec.GetSlotCount then
					local ok, c = pcall(ec.GetSlotCount, p)
					if ok and tonumber(c) then return math.clamp(math.floor(c), 1, 2) end
				end
				return 2   -- an invalid slot is answered with "InvalidSlot" and skipped
			end

			------------------------------------------------ enchant names: "Lucky 3" also finds "Lucky III" (and the other way round)
			local ROMAN = { i = "1", ii = "2", iii = "3", iv = "4", v = "5" }
			-- Lowercases and trims a text.
			local function norm(str)
				str = tostring(str):lower():gsub("^%s+", ""):gsub("%s+$", "")
				local base, tail = str:match("^(.-)%s+(%a+)$")
				if tail and ROMAN[tail] then str = base .. ROMAN[tail] end
				return (str:gsub("[^%w]", ""))
			end
			-- Turns the wanted enchant names into a lookup table.
			local function resolve(names)   -- -> { list = {game names}, set = {name = true}, missing = {text} }
				local out = { list = {}, set = {}, missing = {} }
				local ec, byNorm, any = getEC(), {}, false
				if ec and type(ec.Enchants) == "table" then
					for name in pairs(ec.Enchants) do
						local okF, f = true, true
						if ec.IsFilterable then okF, f = pcall(ec.IsFilterable, name) end
						if okF and f then byNorm[norm(name)] = name any = true end
					end
				end
				for _, want in ipairs(names) do
					local hit = any and (byNorm[norm(want)] or ((norm(want) == "secrethunter" or norm(want) == "secretluck") and (byNorm.secrethunter or byNorm.secretluck))) or (not any and want) or nil
					if hit then
					if not out.set[hit] then out.list[#out.list + 1] = hit end
					out.set[hit] = true
				else out.missing[#out.missing + 1] = want end
				end
				return out
			end

			------------------------------------------------ gate: nothing below runs unless Kaitun Hatch is really hatching
			local function gate(my)
				while act(my) do
					local P = Logic and Logic.priority
					local hatching = (P and P.isHatching and P.isHatching()) or false
					-- not during a Richest <-> Luckiest swap either (the equipped pets are the Richest ones then)
					if kOn and hatching and not eq.swapping and not eq.probing and os.clock() - (eq.swapEnd or -1e9) > 4 then return true end
					status(kOn and "Waiting - Kaitun Hatch is not hatching right now (setting up / paused by another feature)..." or "Waiting for Kaitun Hatch to be switched on...")
					task.wait(0.5)
				end
				return false
			end

			-- Returns the pet the enchant feature is holding right now.
			local function held() return player:GetAttribute("EnchantHeldPet") ~= nil end
			-- True while the game is rolling an enchant.
			local function rolling() return player:GetAttribute("EnchantAutoPet") ~= nil end
			-- Claims the pet for the enchant machine and waits until it is claimed.
			local function claimPet()
				local t0 = os.clock()
				while alive and os.clock() - t0 < CLAIM_WAIT do
					if not held() then return true end
					if call("Claim") then return true end
					task.wait(0.7)
				end
				return not held()
			end
			-- Releases the pet / lock that was held.
			local function release()   -- stops OUR roll and takes OUR pet back (used when the toggle goes off or something breaks)
				if mine == nil then return end
				if rolling() then call("AutoStop") end
				if held() then claimPet() end
				mine = nil
			end
			-- Handles an enchant that was already pending.
			local function resolvePending()
				local res = call("GetState")
				local en = res and res.Enchanting
				local pend = en and en.Pending
				if type(pend) == "table" and pend.Token then call("Resolve", { Token = pend.Token, UseNew = true }) end
			end

			------------------------------------------------ the Richest pets: ask the server once, then put Luckiest back
			local function refreshRich(my)
				if rich.ids and os.clock() - rich.at < RICH_EVERY then return true end
				if not gate(my) then return false end
				status("Looking for the pets Richest would equip...")
				eq.probing, eq.swapping = true, true
				local ids
				pcall(function()
					if not equipMode("Gems", 3) then return end
					task.wait(0.4)
					pcall(SecretGuard.sweep)   -- the same sweep Kaitun does before a rebirth: secret pets never count
					task.wait(0.6)
					local d = replicaData()
					if d then ids = equippedSet(d) end
				end)
				pcall(function()
					if equipMode("Luck", 3) then task.wait(0.5) pcall(SecretGuard.sweep) end
				end)
				eq.swapping, eq.probing = false, false
				eq.swapEnd = os.clock()
				if ids and next(ids) then rich.ids, rich.at = ids, os.clock() return true end
				rich.at = os.clock() - RICH_EVERY + 60   -- nothing readable: try again in a minute
				return false
			end

			------------------------------------------------ next (pet, slot) that still needs an enchant
			local RARITY_RANK = { Legendary=1, Mythical=2, Godly=3, Secret=4, Eternal=5, Divine=6 }
			local function eligible(p)
				return type(p) == "table" and type(p.Name) == "string" and
					(RARITY_RANK[tostring(p.Rarity)] or 0) >= 1
			end
			local function hasTarget(p, wanted)
				return wanted.set[slotValue(p, 1)] or wanted.set[slotValue(p, 2)]
			end
			local function rollSlot(pid, p, protected)
				local bestSlot, bestScore
				for slot = 1, slotCount(p) do
					local cur = slotValue(p, slot)
					if not used[tostring(pid) .. ":" .. slot] then
						local score = (cur == nil and 0 or 1)
						if type(cur) == "string" and protected and protected.set[cur] then score = score + 100 end
						if bestScore == nil or score < bestScore then bestSlot, bestScore = slot, score end
					end
				end
				if bestScore and bestScore < 100 then return bestSlot end
			end
			-- Every equipped Luck pet needs a valid TWO-slot combination.
			-- Roles: 2 Secret Hunter + (Four Leaf/Lucky 3), 2 Four Leaf +
			-- (Secret Hunter/Lucky 3), remaining Lucky 3 + any of the three.
			-- Existing valid combinations are assigned first; neither slot has a fixed order.
			local function pickLuck(owned, idSet, targets)
				local ids = {}
				for pid,p in pairs(owned) do
					if idSet[tostring(pid)] and eligible(p) then ids[#ids+1] = pid end
				end
				table.sort(ids, function(a,b)
					local pa,pb = owned[a],owned[b]
					if (pa.Affinity == "Luck") ~= (pb.Affinity == "Luck") then return pa.Affinity == "Luck" end
					return tostring(a) < tostring(b)
				end)
				local secret, leaf, lucky = targets[1], targets[2], targets[3]
				local function kind(v)
					if secret.set[v] then return 1 end
					if leaf.set[v] then return 2 end
					if lucky.set[v] then return 3 end
					return 0
				end
				local function valid(role, x, y)
					if role == 1 then return (x == 1 and (y == 2 or y == 3)) or (y == 1 and (x == 2 or x == 3)) end
					if role == 2 then return (x == 2 and (y == 1 or y == 3)) or (y == 2 and (x == 1 or x == 3)) end
					return (x == 3 and y >= 1) or (y == 3 and x >= 1)
				end
				local function cost(p, role)
					local x,y = kind(slotValue(p,1)),kind(slotValue(p,2))
					if valid(role,x,y) then return 0 end
					for replacement=1,3 do
						if valid(role,replacement,y) or valid(role,x,replacement) then return 1 end
					end
					return 2
				end
				local roles = {}
				for i=1,#ids do roles[i] = i <= 2 and 1 or (i <= 4 and 2 or 3) end
				local assigned, taken = {}, {}
				-- Assign scarce two-pet roles first, minimizing the number of rerolls.
				for i,role in ipairs(roles) do
					local best, bestCost
					for _,pid in ipairs(ids) do
						if not taken[tostring(pid)] then
							local c = cost(owned[pid],role)
							if not best or c < bestCost then best,bestCost = pid,c end
						end
					end
					if best then assigned[i] = best; taken[tostring(best)] = true end
				end
				for i,pid in ipairs(assigned) do
					local p,role = owned[pid],roles[i]
					local x,y = kind(slotValue(p,1)),kind(slotValue(p,2))
					if not valid(role,x,y) then
						local bestSlot,bestTarget,bestScore
						for slot=1,math.min(2,slotCount(p)) do
							if not used[tostring(pid)..":"..slot] then
								local current = slot == 1 and x or y
								for targetKind=1,3 do
									local nx,ny = slot == 1 and targetKind or x, slot == 2 and targetKind or y
									local completes = valid(role,nx,ny)
									local primary = role
									local useful = completes or (targetKind == primary and current ~= primary)
									if useful and current ~= targetKind then
										local score = (completes and 0 or 10) + (current == 0 and 0 or 1)
										if not bestScore or score < bestScore then
											bestSlot,bestTarget,bestScore = slot,targets[targetKind],score
										end
									end
								end
							end
						end
						if bestSlot then return pid,p,bestSlot,bestTarget end
					end
				end
			end
			local function pickRich(owned, idSet, wanted, protect)
				local ids = {}
				for pid,p in pairs(owned) do
					if idSet[tostring(pid)] and eligible(p) then ids[#ids+1]=pid end
				end
				table.sort(ids,function(a,b)
					local aa=owned[a].Affinity == "Gems" and 1 or 0
					local ab=owned[b].Affinity == "Gems" and 1 or 0
					if aa ~= ab then return aa > ab end
					return tostring(a)<tostring(b)
				end)
				for _,pid in ipairs(ids) do
					local p=owned[pid]
					if not hasTarget(p,wanted) then
						local slot=rollSlot(pid,p,protect)
						if slot then return pid,p,slot end
					end
				end
			end

			------------------------------------------------ one roll
			local function roll(my, phaseName, wanted, pid, p, slot)
				local key = tostring(pid) .. ":" .. slot
				local cur = slotValue(p, slot)
				local label = tostring(p.Nickname or p.Name) .. " (slot " .. slot .. ")"
				hookEvents()
				local sres, sreason = call("SetFilters", wanted.list)
				if not sres then status("Couldn't set the enchant targets (" .. tostring(sreason) .. ") - retrying...") nap(my, 5) return end

				rollCount, stopEvt = 0, nil
				mine = pid
				local args = { PetId = pid, Slot = slot }
				if REPLACE_PROTECTED and type(cur) == "string" then
					local ec = getEC()
					if ec and ec.IsProtected and ec.IsProtected(cur) then args.Replace = cur end
				end
				local started, lastReason = false, nil
				for _ = 1, 3 do
					if not act(my) then break end
					local res, reason = call("AutoStart", args)
					if res then started = true break end
					lastReason = reason
					if reason == "InsufficientGems" then
						mine = nil
						status("Out of gems - waiting 30 s...")
						nap(my, 30)
						return
					elseif reason == "AutoRunning" then call("AutoStop") nap(my, 1)
					elseif reason == "ClaimFirst" then claimPet()
					elseif reason == "ChoosePendingEnchant" or reason == "EnchantPending" then resolvePending()
					elseif reason == "RateLimited" or reason == "Connection" or reason == "VisitEnchantMachine" then nap(my, 2)
					else break end
				end
				if not started then
					mine = nil
					if not act(my) then return end
					used[key] = true
					if lastReason ~= "InvalidSlot" then fails = fails + 1 end   -- "no such slot" is a normal skip
					warn("[Kaitun Stats] skipped " .. label .. ": " .. tostring(lastReason))
					return
				end

				-- the roll runs on the server: wait for the game's own Stop event
				local t0 = os.clock()
				local deferred = false
				while act(my) do
					if stopEvt then break end
					if rollCount >= MAX_ROLLS_PER_TURN then
						-- Stop the server-side roll, reclaim this pet, and try another candidate.
						deferred = true
						status(string.format("%s reached %d rolls - moving to next pet", label, rollCount))
						call("AutoStop")
						local stopWait = os.clock()
						while act(my) and rolling() and os.clock() - stopWait < 5 do task.wait(0.2) end
						nap(my, 0.5)
						break
					end
					if os.clock() - t0 > 4 and not rolling() then nap(my, 1) break end   -- the Stop event can arrive a moment after the attribute clears
					status(string.format("%s | rolling %s | %d roll(s) | enchanted %d", phaseName, label, rollCount, done))
					task.wait(0.25)
				end
				if not act(my) then release() return end

				-- taking the pet out is enchanting work too: only while hatching
				if not gate(my) then release() return end
				if not claimPet() then status("Couldn't take " .. label .. " out of the enchanter yet - retrying...") return end
				mine = nil
				if phaseName == "Luckiest pets" then stick = tostring(pid) end
				-- the pet was out of the team while it rolled: put the Luckiest pets back right away (only when Kaitun's own Auto Equip is on)
				if kOn and not K.skip.rebirth and not eq.swapping and not eq.probing then
					pcall(function()
						if equipMode("Luck", 3) then task.wait(0.5) pcall(SecretGuard.sweep) end
					end)
				end
				local ev = stopEvt or { Reason = "Ended" }
				local reason = tostring(ev.Reason)
				-- the data needs a moment to show the new enchant: without this the same slot would be rolled again
				local got = false
				local tc = os.clock()
				while act(my) and os.clock() - tc < 3 do
					local d = replicaData()
					local np = d and d.Pets.Owned[pid]
					local v = np and slotValue(np, slot)
					if type(v) == "string" and wanted.set[v] then got = true break end
					task.wait(0.25)
				end
				used[key] = true   -- deferred slots are revisited after the other candidates have had their turn
				if deferred and not got and reason ~= "Matched" then
					fails = 0 -- reaching the roll budget is intentional, not a server failure
					status(string.format("Deferred %s after %d rolls - trying other pets", label, rollCount))
				elseif got or reason == "Matched" then
					done, fails = done + 1, 0
				elseif reason == "Gems" then
					status("Out of gems - waiting 30 s...") nap(my, 30)
				else
					fails = fails + 1
					warn("[Kaitun Stats] " .. label .. " stopped with reason " .. reason)
				end
				nap(my, 0.7)
			end

			------------------------------------------------ one pass of the loop
			local luck, richW, luckTargets
			-- One enchant step.
			local function step(my)
				if os.clock() - usedAt > 120 then used, usedAt = {}, os.clock() end   -- slots that failed earlier get another try
				if fails >= MAX_FAILS then
					status("Paused - the server keeps refusing the enchant (see the output). Trying again in 60 s...")
					nap(my, 60) fails = 0 used = {} return
				end
				if not luck or #luck.list == 0 then
					luck, richW = resolve(LUCK_NAMES), resolve(RICH_NAMES)
					luckTargets = { resolve({"Secret Hunter", "Secret Luck"}), resolve({"Four Leaf"}), resolve({"Lucky 3"}) }
					if #luck.list == 0 then status("Couldn't find the enchants " .. table.concat(LUCK_NAMES, " / ") .. " in this game - retrying...") luck = nil nap(my, 10) return end
				end
				if not gate(my) then return end
				if rolling() and mine == nil then status("The enchanter is busy with another roll - waiting...") nap(my, 3) return end
				if held() and mine == nil then status("Taking a pet back out of the enchanter...") claimPet() return end
				local data = replicaData()
				if not data then status("Couldn't read your pets - retrying...") nap(my, 3) return end
				local owned = data.Pets.Owned
				pcall(SecretGuard.sweep)

				-- 1) the pets you have equipped right now
				local eqs = equippedSet(data)
				if stick then eqs[stick] = true end
				local pid, p, slot, target = pickLuck(owned, eqs, luckTargets)
				if pid then return roll(my, "Luckiest pets", target, pid, p, slot) end

				-- 2) done: the pets Richest would equip before the rebirth -> Renewal 3 (never over the luck enchants)
				if K.skip.rebirth then status("Equipped pets are enchanted | Auto Rebirth + Equip is off, so there are no Richest pets to look for") nap(my, RECHECK) return end
				if #richW.list == 0 then status("Equipped pets are enchanted | Renewal 3 doesn't exist in this game") nap(my, RECHECK) return end
				if not refreshRich(my) then nap(my, 5) return end
				pid, p, slot = pickRich(owned, rich.ids, richW, luck)
				if pid then return roll(my, "Richest pets", richW, pid, p, slot) end
				if next(used) then
					-- One full pass is complete; retry the deferred pets in a fresh pass.
					used, usedAt = {}, os.clock()
					status("Finished other pets - revisiting deferred enchants...")
					nap(my, 1)
					return
				end
				status(string.format("All done | equipped pets have the luck enchants, Richest pets have Renewal 3 | enchanted %d | checking again in %d s", done, RECHECK))
				nap(my, RECHECK)
			end

			-- Main loop of Kaitun Stats.
			local function loop(my)
				while act(my) do
					local okS, errS = pcall(step, my)
					if not okS then
						warn("[Kaitun Stats] error: " .. tostring(errS))
						status("Error - see the output, retrying in 5 s")
						pcall(release)
						nap(my, 5)
					end
				end
				pcall(release)
			end

			------------------------------------------------ the toggle
			local function needHatchPopup()
				local closed = false
				-- Closes the Kaitun Stats run.
				local function close()
					if closed then return end
					closed = true
					if on and enchEntry._setUI then pcall(enchEntry._setUI, false) end   -- closing the pop up switches the toggle off again
				end
				local pop = Config.kaitunPopup
				if type(pop) == "function" and pcall(pop, "Run Kaitun Hatch First", "Kaitun Stats needs Kaitun Hatch to be running.", close) then return end
				close()
			end
			enchEntry.callback = function(v)
				v = v == true
				if v == on then return end
				on = v
				run = run + 1
				if not v then
					status(ENCH_DESC)
					task.spawn(function() pcall(release) end)
					return
				end
				local my = run
				used, usedAt, fails, stick = {}, os.clock(), 0, nil
				task.spawn(function()
					if not kOn then
						-- a saved configuration may still be switching Kaitun Hatch on: give it time before complaining
						if not Config.ready then
							local t0 = os.clock()
							while alive and on and run == my and not Config.ready and os.clock() - t0 < 30 do task.wait(0.25) end
							if Config.ready then nap(my, 3) end
						end
						if not act(my) then return end
						if not kOn then
							needHatchPopup()
							return
						end
					end
					loop(my)
				end)
			end
		end, function(e) warn("[WORST Hub] Kaitun Stats failed to load: " .. tostring(e)) end)

		---------------------------------------------------------------- Kaitun Stats also runs Auto Rebirth + Auto Equip (needs Kaitun Hatch)
		-- wrapped around the enchant callback, so rebirth + equip keep working even if the enchant part failed to load
		do
			local stEntry = K.enchant
			if stEntry then
				local innerCb = stEntry.callback
				stEntry.callback = function(v)
					v = v == true
					if v ~= stOn then
						stOn = v
						hat.run = hat.run + 1
						if v then
							if kOn then task.spawn(startStatsModules, hat.run) end   -- Kaitun Hatch off: they start as soon as it is switched on
						else
							pcall(rebirthApply, false)
							pcall(equipApply, false)
						end
					end
					if innerCb then return innerCb(v) end
				end
			end
		end

		---------------------------------------------------------------- the Kaitun tab: three toggles (+ "Craft When Storage Is" under the first while it is on)
		TAB_SCRIPTS.Kaitun = { mainEntry, statsEntry, K.enchant }
		Config.kaitunStorage = Logic.storage
	end
end

-- Calls fn safely (an error in it never breaks the hub).
local function safe(fn, ...)
	if typeof(fn) ~= "function" then return true end
	local ok, err = pcall(fn, ...)
	if not ok then warn("[WORST Hub] error: " .. tostring(err)) end
	return ok, err
end

-- Settings > Reset Script: back to the state right after the script was first executed
local resetEntry = {
	type = "button", name = "Reset Script", icon = "🔃", noSave = true,
}
-- Resets every setting to its default (Reset Script).
local function doReset()
	-- Calls fn for every entry of every tab.
	local function each(fn)
		for _, e in pairs(TAB_SCRIPTS) do
			if e.pages then
				for _, pg in ipairs(e.pages) do
					for _, en in ipairs(pg.entries or {}) do if type(en) == "table" and en ~= resetEntry then pcall(fn, en) end end
				end
			else
				for _, en in ipairs(e) do if type(en) == "table" and en ~= resetEntry then pcall(fn, en) end end
			end
		end
	end
	-- 0) stop Auto Save first so it cannot save a half-reset state
	each(function(en)
		if en.type == "toggle" and en.name == "Auto Save Configuration" and en._setUI and en._get and en._get() then en._setUI(false) end
	end)
	-- 1) every toggle off (stops every running feature)
	each(function(en)
		if en.type == "toggle" and en._setUI and en._get and en._get() then en._setUI(false) end
	end)
	task.wait(0.4)
	if not alive then return true end
	-- 2) sliders, dropdowns, inputs and the minimize key back to their defaults
	each(function(en)
		local c = en._id and controls[en._id]
		if en.type == "slider" then
			local v = en.default or en.min or 0
			if en._setUI then en._setUI(v) elseif c then c.set(v) end
		elseif en.type == "dropdown" then
			local v = en.multi and "" or en.default or (type(en.options) == "table" and en.options[1]) or nil
			if c and v ~= nil then c.set(v) end
		elseif en.type == "input" then
			if c then c.set(en.default or "") end
		elseif en.type == "keybind" then
			if c then c.set("LeftControl") end
		end
	end)
	-- 3) toggles whose default is ON go back on (Animated Background, Auto Click ...)
	each(function(en)
		if en.type == "toggle" and en.default == true and en.name ~= "Auto Save Configuration" and en._setUI then en._setUI(true) end
	end)
	-- 4) hatch hiding / Auto 8x state
	if Logic and Logic.reset then Logic.reset() end
	-- 5) interface: every page scrolled to the top, back on the first tab
	for _, d in ipairs(window:GetDescendants()) do
		if d:IsA("ScrollingFrame") then d.CanvasPosition = Vector2.zero end
	end
	pcall(function() setTab(navItems[1][1]) end)
	Config.lastSig = nil
	print("[WORST Hub] Script reset to its original state.")
	return true
end
-- the button only asks first; the reset runs when the player presses Yes
resetEntry.run = function()
	Config.confirm("Reset the Script?", "Every feature is turned off and every setting goes back to default.", doReset)
	return true
end
-- shown as a button at the top right of the Settings tab (built in buildScriptPage), not as a row
Config.resetEntry = resetEntry

-- Runs a button entry (its run function or its url).
local function runEntry(entry)
	if entry.run then
		return pcall(entry.run)
	elseif entry.url then
		return pcall(function()
			local src = game:HttpGet(entry.url)
			local fn, compileErr = loadstring(src)
			assert(fn, compileErr)
			fn()
		end)
	end
	return false, "Entry needs a 'run' function or a 'url'"
end

local RUN_IDLE  = Color3.fromRGB(30, 30, 30)      -- action buttons: dark fill + thin outline (same look as the dropdown fields)
local RUN_HOVER = Color3.fromRGB(48, 48, 48)
local RUN_OK    = C.green
local RUN_FAIL  = Color3.fromRGB(87, 87, 87)
local FIELD     = Color3.fromRGB(28, 28, 28)
local OFF_COLOR = Color3.fromRGB(50, 50, 50)
local RIGHT_X   = 1042 -- right edge of every control inside a row

-- Plays a quick tween on an object.
local function tween(obj, props, t)
	TweenService:Create(obj, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-- tween with a custom style / direction
local function tweenX(obj, props, t, style, dir)
	local tw_ = TweenService:Create(obj,
		TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw_:Play()
	return tw_
end

-- outline + hover / press feedback for the action buttons (Run, Save, Reset Script ...)
function Config.polish(btn)
	local st = btn:FindFirstChildOfClass("UIStroke") or stroke(btn, C.stroke, 1)
	local sc = new("UIScale", { Scale = 1 }, btn)
	btn.MouseEnter:Connect(function() tween(st, { Color = Color3.fromRGB(175, 175, 175) }, 0.15) end)
	btn.MouseLeave:Connect(function()
		tween(st, { Color = C.stroke }, 0.2)
		tweenX(sc, { Scale = 1 }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)
	btn.MouseButton1Down:Connect(function() tweenX(sc, { Scale = 0.96 }, 0.08) end)
	btn.MouseButton1Up:Connect(function() tweenX(sc, { Scale = 1 }, 0.12) end)
	return st
end

---------------------------------------------------------------- minimize keybind state
local minimizeKey = Enum.KeyCode.LeftControl -- changed from the Settings tab
local keybindCapture = nil                    -- while set, the next key press goes to it instead of minimizing

local PRETTY_KEYS = {
	LeftControl = "Left Ctrl", RightControl = "Right Ctrl", LeftShift = "Left Shift", RightShift = "Right Shift",
	LeftAlt = "Left Alt", RightAlt = "Right Alt", Return = "Enter", Backquote = "`",
}
-- Turns a key code into readable text.
local function prettyKey(kc) return PRETTY_KEYS[kc.Name] or kc.Name end

---------------------------------------------------------------- config registry
local function register(entry, ctrl)
	if entry.noSave or not entry._id then return end
	controls[entry._id] = ctrl
end

---------------------------------------------------------------- button
local function buildButton(row, entry)
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(RIGHT_X, 42),
		Size = UDim2.fromOffset(120, 42), BackgroundColor3 = RUN_IDLE, AutoButtonColor = false,
		Text = "Run", TextColor3 = Color3.new(1, 1, 1), TextSize = 17, Font = Enum.Font.GothamMedium,
	}, row)
	corner(btn, UDim.new(0, 14))
	Config.polish(btn)

	-- whole row glows for half a second after a press, then slowly loses the glow (no spinning light)
	local rowGlow = new("UIStroke", {
		Color = Color3.fromRGB(235, 235, 235), Thickness = 3, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, row)
	local rowFill = new("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(235, 235, 235), BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 0,
	}, row)
	corner(rowFill, UDim.new(0, 20))
	local glowToken = 0
	-- Makes the row glow briefly after a button press.
	local function pulseRow()
		glowToken = glowToken + 1
		local my = glowToken
		rowGlow.Transparency = 0.05
		rowFill.BackgroundTransparency = 0.86
		task.delay(0.5, function()
			if my ~= glowToken or not alive then return end
			tween(rowGlow, { Transparency = 1 }, 1.4)
			tween(rowFill, { BackgroundTransparency = 1 }, 1.4)
		end)
	end

	local busy = false
	local pressed = false
	btn.MouseEnter:Connect(function() if not busy then tween(btn, { BackgroundColor3 = RUN_HOVER }) end end)
	btn.MouseLeave:Connect(function() if not busy then tween(btn, { BackgroundColor3 = RUN_IDLE }) end end)

	-- Runs the button when pressed.
	local function trigger()
		if busy then return end
		busy = true
		pressed = true
		pulseRow()
		flame(btn, 1.3)
		btn.Text = "Running..."
		task.spawn(function()
			local ok, err = runEntry(entry)
			if not ok then warn(("[WORST Hub] '%s' failed: %s"):format(entry.name or "?", tostring(err))) end
			if not alive then return end
			btn.Text = ok and "Done ✓" or "Failed ✕"
			tween(btn, { BackgroundColor3 = ok and RUN_OK or RUN_FAIL })
			task.wait(1.5)
			if not alive then return end
			btn.Text = "Run"
			tween(btn, { BackgroundColor3 = RUN_IDLE })
			busy = false
		end)
	end
	btn.MouseButton1Click:Connect(trigger)

	register(entry, {
		type = "button",
		get = function() return pressed end,
		set = function(v) if v then trigger() end end,
	})
end

---------------------------------------------------------------- toggle
local function buildToggle(row, entry)
	local value = entry.default == true
	local sw = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(RIGHT_X, 42),
		Size = UDim2.fromOffset(66, 34), BackgroundColor3 = value and C.accent or OFF_COLOR,
		Text = "", AutoButtonColor = false,
	}, row)
	corner(sw, UDim.new(1, 0))
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(0, value and 36 or 4, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	}, sw)
	corner(knob, UDim.new(1, 0))

	-- the whole row shines while this toggle is on; when it is switched off the light does one last lap, then fades
	local glow, glowE = ashStroke(new("UIStroke", {
		Color = Color3.new(1, 1, 1), Thickness = 3, Transparency = value and 0.05 or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, row), { speed = 150, paused = not value })

	-- Sets the toggle value.
	local function set(v)
		value = v
		if v then
			glowE.stopAt, glowE.onDone, glowE.paused = nil, nil, false
			tween(glow, { Transparency = 0.05 }, 0.25)
		else
			glowE.stopAt = glowE.rot + 360
			glowE.onDone = function()
				tween(glow, { Transparency = 1 }, 0.45)
				task.delay(0.5, function() if not value then glowE.paused = true end end)
			end
		end
		flame(sw, v and 1.4 or 0.6, v)
		tween(sw, { BackgroundColor3 = v and C.accent or OFF_COLOR })
		tween(knob, { Position = UDim2.new(0, v and 36 or 4, 0.5, 0) })
		safe(entry.callback, v)
	end
	sw.MouseButton1Click:Connect(function() record.userToggled = true set(not value) end)

	-- lets scripts flip this toggle from code (updates the switch AND runs the callback)
	entry._setUI = function(v)
		if (v == true) ~= value then set(v == true) end
	end
	entry._get = function() return value end

	if value then safe(entry.callback, true) end
	table.insert(cleanupHooks, function()
		if value then value = false; safe(entry.callback, false) end
	end)

	register(entry, {
		type = "toggle",
		get = function() return value end,
		set = function(v) if (v == true) ~= value then set(v == true) end end,
	})
end

---------------------------------------------------------------- slider
local function buildSlider(row, entry)
	local min, max = entry.min or 0, entry.max or 100
	local step = entry.step or 1
	local suffix = entry.suffix or ""
	local TRACK_W = 260
	local value

	local valueLbl = label(row, "", RIGHT_X, 42, 17, C.text, Enum.Font.GothamMedium, Enum.TextXAlignment.Right)
	valueLbl.Size = UDim2.fromOffset(70, 26)

	local trackX = RIGHT_X - 70 - 18 - TRACK_W
	local track = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(trackX, 42),
		Size = UDim2.fromOffset(TRACK_W, 8), BackgroundColor3 = OFF_COLOR, BorderSizePixel = 0,
	}, row)
	corner(track, UDim.new(1, 0))
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.accent, BorderSizePixel = 0 }, track)
	corner(fill, UDim.new(1, 0))
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(22, 22), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	}, track)
	corner(knob, UDim.new(1, 0))
	stroke(knob, C.accent, 2)

	-- Redraws the slider to its value.
	local function render()
		local a = (max > min) and (value - min) / (max - min) or 0
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.fromScale(a, 0.5)
		valueLbl.Text = entry.format and entry.format(value) or (tostring(value) .. suffix)
	end

	-- Sets the slider value (rounded to the step) and fires its callback.
	local function setValue(v, fire)
		v = min + math.floor((v - min) / step + 0.5) * step
		v = math.clamp(math.round(v * 10000) / 10000, min, max)
		if v == value then return end
		value = v
		render()
		if fire then safe(entry.callback, value) end
	end

	value = math.clamp(entry.default or min, min, max)
	render()
	entry._setUI = function(v) if tonumber(v) then setValue(tonumber(v), true) end end

	local hit = new("TextButton", {
		Position = UDim2.fromOffset(trackX - 12, 22), Size = UDim2.fromOffset(TRACK_W + 24, 40),
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
	}, row)

	local dragging = false
	local lastFlame = 0
	-- Converts a mouse x position into a slider value.
	local function fromX(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		setValue(min + a * (max - min), true)
		if os.clock() - lastFlame > 0.12 then lastFlame = os.clock(); flame(knob, 0.45) end
	end
	hit.InputBegan:Connect(function(input)
		if isPress(input) then dragging = true; flame(knob, 1); fromX(input.Position.X) end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and isMove(input) then fromX(input.Position.X) end
	end)
	connect(UserInputService.InputEnded, function(input)
		if isPress(input) then dragging = false end
	end)

	register(entry, {
		type = "slider",
		get = function() return value end,
		set = function(v) if tonumber(v) then setValue(tonumber(v), true) end end,
	})
end

---------------------------------------------------------------- dropdown (animated + live refresh)
local closeOpenDropdown

local MENU_BG  = Color3.fromRGB(20, 20, 20)
local SEL_BG   = Color3.fromRGB(53, 53, 53)
local HOVER_BG = Color3.fromRGB(35, 35, 35)
local FIELD_HOVER = Color3.fromRGB(37, 37, 37)

-- Builds a dropdown control for a row.
local function buildDropdown(row, entry)
	local options = entry.options or {}           -- the same table is edited by scripts to refresh the list live
	local current = entry.default or options[1] or "—"
	local W, H = entry.width or 220, 42
	local itemH = 38
	local SEARCH_H = 36        -- height of the search strip at the top of every open menu
	local searchText = ""     -- what is typed in the search box ("" = show every option)
	local isOpen = false
	local ui = nil                                -- { menu = ScrollingFrame } while open
	local lastSig = table.concat(options, "\n")

	-- multi = true: several options can be ticked at once and the menu stays open. The ticked ones live in entry.picked
	-- (option -> true, the same table is read by scripts). entry.clearOption = the option that un-ticks everything.
	local counter = entry.counter == true      -- counter = true: every option has a number (left click +1, right click -1)
	local multi = entry.multi == true or counter
	local picked = entry.picked or {}
	entry.picked = picked
	local counts = entry.counts or {}          -- counter mode: option -> how many (scripts read this table)
	entry.counts = counts
	local clearOpt = entry.clearOption
	-- True if an option is selected (or has a count).
	local function isOn(o)
		if counter then return (counts[o] or 0) > 0 end
		return picked[o] and true or false
	end
	-- True if anything is selected.
	local function anyOn()
		if counter then return next(counts) ~= nil end
		return next(picked) ~= nil
	end
	-- Returns the max count of an option.
	local function limitOf(o)                  -- the most one option can reach (1 for plain ticks)
		if not counter then return 1 end
		local v = entry.limitOf and entry.limitOf(o)
		return tonumber(v) or math.huge
	end
	-- Returns the total count of all options.
	local function totalCount()
		local n = 0
		for _, c in pairs(counts) do n = n + c end
		return n
	end
	-- Returns the list of selected options.
	local function pickedList()
		local l = {}
		for _, o in ipairs(options) do
			if o ~= clearOpt and isOn(o) then l[#l + 1] = o end
		end
		return l
	end
	-- Builds the dropdown's summary text.
	local function summary()
		local l = pickedList()
		if #l == 0 then return tostring(entry.emptyText or clearOpt or options[1] or "—") end
		if counter then
			for i, o in ipairs(l) do l[i] = counts[o] .. "x " .. o end
		end
		return table.concat(l, ", ")
	end
	if multi then current = summary() end
	local refreshMulti -- defined below, once the menu helpers exist

	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(RIGHT_X, 42),
		Size = UDim2.fromOffset(W, H), BackgroundColor3 = FIELD, Text = "", AutoButtonColor = false,
	}, row)
	corner(btn, UDim.new(0, 14))
	local st = stroke(btn, C.stroke, 1)
	local btnScale = new("UIScale", { Scale = 1 }, btn)

	local txt = new("TextLabel", {
		Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(W - 44, H), BackgroundTransparency = 1,
		Text = tostring(current), TextColor3 = C.text, TextSize = 16, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, btn)

	local CHEV_REST = UDim2.new(1, -22, 0.5, 0)
	local chev = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = CHEV_REST,
		Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1,
	}, btn)
	for _, side in ipairs({ -1, 1 }) do
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, side * 3.5, 0.5, 0),
			Size = UDim2.fromOffset(9, 2), Rotation = side * -45, BackgroundColor3 = C.sub, BorderSizePixel = 0,
		}, chev)
	end

	-- hover / press feedback
	btn.MouseEnter:Connect(function()
		if isOpen then return end
		tween(btn, { BackgroundColor3 = FIELD_HOVER }, 0.15)
		tween(st, { Color = Color3.fromRGB(75, 75, 75) }, 0.15)
		tween(chev, { Position = UDim2.new(1, -22, 0.5, 2) }, 0.15)
	end)
	btn.MouseLeave:Connect(function()
		tweenX(btnScale, { Scale = 1 }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		if isOpen then return end
		tween(btn, { BackgroundColor3 = FIELD }, 0.2)
		tween(st, { Color = C.stroke }, 0.2)
		tween(chev, { Position = CHEV_REST }, 0.2)
	end)
	btn.MouseButton1Down:Connect(function() tweenX(btnScale, { Scale = 0.96 }, 0.08) end)
	btn.MouseButton1Up:Connect(function()
		tweenX(btnScale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)

	-- the selected text slides + fades in whenever it changes
	local function setText(text)
		txt.Text = tostring(text)
		txt.TextTransparency = 1
		txt.Position = UDim2.fromOffset(14, 10)
		tweenX(txt, { TextTransparency = 0, Position = UDim2.fromOffset(14, 0) }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end

	-- a quick glow on the field (used when the list refreshes by itself or an option is picked)
	local function pulse()
		st.Thickness = 2.5
		st.Color = C.cyan
		tweenX(st, { Thickness = 1, Color = isOpen and C.accent or C.stroke }, 0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end

	-- Chooses an option.
	local function choose(opt, fire)
		current = opt
		setText(opt)
		pulse()
		if fire then safe(entry.callback, opt) end
	end

	-- where the menu goes (below the field, or above it when there is no room)
	local function menuLayout()
		local scale = uiScale.Scale
		local rel = (btn.AbsolutePosition - window.AbsolutePosition) / scale
		local h = math.min(#options * itemH + 8, 300) + SEARCH_H
		if rel.Y + H + 4 + h <= window.Size.Y.Offset - 10 then
			return Vector2.new(rel.X, rel.Y + H + 4), 0, h
		end
		return Vector2.new(rel.X, rel.Y - 4), 1, h
	end

	-- one "+  name  -" row of a multi / counter dropdown.
	-- left click = +1, right click = -1; the + and - buttons (left / right edge) do the same, for touch screens.
	local function getN(opt)
		if counter then return counts[opt] or 0 end
		return picked[opt] and 1 or 0
	end
	-- True if one more of an option can be added.
	local function canAdd(opt)
		if getN(opt) >= limitOf(opt) then return false end
		if counter and entry.maxTotal and totalCount() >= entry.maxTotal then return false end
		return true
	end
	-- Adds or removes one of an option (left / right click).
	local function adjust(opt, delta)
		local cur = getN(opt)
		if delta > 0 then
			if not canAdd(opt) then return end
		elseif cur <= 0 then
			return
		end
		local nv = cur + delta
		if counter then
			counts[opt] = nv > 0 and nv or nil
		else
			picked[opt] = nv > 0 or nil
		end
		safe(entry.callback, opt, delta, nv)
		refreshMulti(false)
	end

	-- Builds one "+ name -" row of a counter dropdown.
	local function stepRow(menu, opt, i, animate, step, di)
		local n, lim = getN(opt), limitOf(opt)
		local on = n > 0
		local o = new("TextButton", {
			Name = "Option", LayoutOrder = i, Size = UDim2.new(1, 0, 0, itemH - 2), ZIndex = 51,
			AutoButtonColor = false, Text = "", BorderSizePixel = 0, ClipsDescendants = true,
			BackgroundColor3 = MENU_BG, BackgroundTransparency = animate and 1 or 0,
		}, menu)
		corner(o, UDim.new(0, 10))
		-- the row fills up (left to right) the closer the number gets to its limit
		local frac = on and 1 or 0
		if lim ~= math.huge and lim > 0 then frac = math.min(n / lim, 1) end
		local fill = new("Frame", {
			Size = UDim2.new(frac, 0, 1, 0), BackgroundColor3 = SEL_BG, BorderSizePixel = 0, ZIndex = 51,
			BackgroundTransparency = animate and 1 or 0,
		}, o)
		corner(fill, UDim.new(0, 10))

		local plusT = canAdd(opt) and 0 or 0.65
		local minusT = on and 0 or 0.65
		-- Builds the + or - button of a row.
		local function stepBtn(sym, side)
			local b = new("TextButton", {
				AnchorPoint = Vector2.new(side, 0.5), Position = UDim2.new(side, side == 0 and 5 or -5, 0.5, 0),
				Size = UDim2.fromOffset(28, itemH - 12), BackgroundColor3 = C.iconBg, Text = sym,
				TextColor3 = C.text, TextSize = 18, Font = Enum.Font.GothamBold, AutoButtonColor = true, ZIndex = 54,
				BackgroundTransparency = animate and 1 or 0, TextTransparency = animate and 1 or (side == 0 and plusT or minusT),
			}, o)
			corner(b, UDim.new(0, 7))
			return b
		end
		local plus, minus = stepBtn("+", 0), stepBtn("-", 1)

		local cntW = counter and 58 or 22
		local lbl = new("TextLabel", {
			Position = UDim2.fromOffset(animate and 52 or 40, 0), Size = UDim2.new(1, -(40 + 38 + cntW), 1, 0), ZIndex = 52,
			BackgroundTransparency = 1, Text = tostring(opt), TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = on and Color3.new(1, 1, 1) or C.sub,
			Font = on and Enum.Font.GothamMedium or Enum.Font.Gotham,
			TextTransparency = animate and 1 or 0,
		}, o)
		local cText = ""
		if counter then
			cText = (lim == math.huge) and tostring(n) or (n .. "/" .. lim)
		elseif on then
			cText = "✓"
		end
		local cnt = new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -38, 0.5, 0), Size = UDim2.fromOffset(cntW, itemH - 12),
			BackgroundTransparency = 1, Text = cText, TextSize = 14, Font = Enum.Font.GothamMedium, ZIndex = 52,
			TextXAlignment = Enum.TextXAlignment.Right, TextTransparency = animate and 1 or 0,
			TextColor3 = (n > lim) and Color3.fromRGB(255, 130, 130) or (on and C.iconFg or C.sub),
		}, o)

		if animate then
			task.delay(math.min(((di or i) - 1) * (step or 0.03), 0.45), function()
				if not o.Parent then return end
				tweenX(o, { BackgroundTransparency = 0 }, 0.2)
				tweenX(fill, { BackgroundTransparency = 0 }, 0.2)
				tweenX(lbl, { TextTransparency = 0, Position = UDim2.fromOffset(40, 0) }, 0.3,
					Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				tweenX(cnt, { TextTransparency = 0 }, 0.2)
				tweenX(plus, { BackgroundTransparency = 0, TextTransparency = plusT }, 0.2)
				tweenX(minus, { BackgroundTransparency = 0, TextTransparency = minusT }, 0.2)
			end)
		end
		o.MouseEnter:Connect(function()
			if not on then tweenX(o, { BackgroundColor3 = HOVER_BG }, 0.1) end
		end)
		o.MouseLeave:Connect(function()
			if not on then tweenX(o, { BackgroundColor3 = MENU_BG }, 0.15) end
		end)
		o.MouseButton1Click:Connect(function() adjust(opt, 1) end)    -- left click  = add
		o.MouseButton2Click:Connect(function() adjust(opt, -1) end)   -- right click = reduce
		plus.MouseButton1Click:Connect(function() adjust(opt, 1) end)
		minus.MouseButton1Click:Connect(function() adjust(opt, -1) end)
	end

	-- (re)builds the option buttons inside the menu; animate = fade + slide in one after the other
	local function addItems(menu, animate, step)
		for _, c in ipairs(menu:GetChildren()) do
			if c:IsA("GuiButton") or c.Name == "NoResults" then c:Destroy() end
		end
		local needle = searchText:lower()
		local shown = 0
		for i, opt in ipairs(options) do
			local visible = needle == "" or tostring(opt):lower():find(needle, 1, true) ~= nil   -- plain, case-insensitive "contains"
			if visible then shown = shown + 1 end
			local selected
			if multi then
				if opt == clearOpt then
					if entry.isClearActive then selected = entry.isClearActive() == true else selected = not anyOn() end
				else
					selected = isOn(opt)
				end
			else
				selected = (opt == current)
			end
			if not visible then
				-- hidden by the search
			elseif multi and opt ~= clearOpt then
				stepRow(menu, opt, i, animate, step, shown)
			else
			local o = new("TextButton", {
				Name = "Option", LayoutOrder = i, Size = UDim2.new(1, 0, 0, itemH - 2), ZIndex = 51,
				AutoButtonColor = false, Text = "", BorderSizePixel = 0,
				BackgroundColor3 = selected and SEL_BG or MENU_BG,
				BackgroundTransparency = animate and 1 or 0,
			}, menu)
			corner(o, UDim.new(0, 8))
			local lbl = new("TextLabel", {
				Position = UDim2.fromOffset(animate and 32 or 14, 0), Size = UDim2.new(1, -44, 1, 0), ZIndex = 52,
				BackgroundTransparency = 1, Text = tostring(opt), TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				TextColor3 = selected and Color3.new(1, 1, 1) or C.sub,
				Font = selected and Enum.Font.GothamMedium or Enum.Font.Gotham,
				TextTransparency = animate and 1 or 0,
			}, o)
			local bar, chk
			if selected then
				bar = new("Frame", {
					AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.new(0, 3, 0.55, 0),
					BackgroundColor3 = C.accent, BorderSizePixel = 0, ZIndex = 52,
					BackgroundTransparency = animate and 1 or 0,
				}, o)
				corner(bar, UDim.new(1, 0))
				chk = new("TextLabel", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(20, 20),
					BackgroundTransparency = 1, Text = "✓", TextSize = 16, Font = Enum.Font.GothamBold,
					TextColor3 = C.iconFg, ZIndex = 52, TextTransparency = animate and 1 or 0,
				}, o)
			end
			if animate then
				task.delay(math.min((shown - 1) * (step or 0.03), 0.45), function()
					if not o.Parent then return end
					tweenX(o, { BackgroundTransparency = 0 }, 0.2)
					tweenX(lbl, { TextTransparency = 0, Position = UDim2.fromOffset(14, 0) }, 0.3,
						Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					if bar then tweenX(bar, { BackgroundTransparency = 0 }, 0.2) end
					if chk then tweenX(chk, { TextTransparency = 0 }, 0.2) end
				end)
			end
			o.MouseEnter:Connect(function()
				if not selected then tweenX(o, { BackgroundColor3 = HOVER_BG }, 0.1) end
				tweenX(lbl, { Position = UDim2.fromOffset(19, 0) }, 0.15)
			end)
			o.MouseLeave:Connect(function()
				if not selected then tweenX(o, { BackgroundColor3 = MENU_BG }, 0.15) end
				tweenX(lbl, { Position = UDim2.fromOffset(14, 0) }, 0.15)
			end)
			o.MouseButton1Click:Connect(function()
				if multi then -- tick / un-tick, keep the menu open
					if opt == clearOpt then
						for k in pairs(picked) do picked[k] = nil end
						for k in pairs(counts) do counts[k] = nil end
					else
						picked[opt] = (not picked[opt]) or nil
					end
					safe(entry.callback, opt)
					refreshMulti()
					return
				end
				if closeOpenDropdown then closeOpenDropdown() end
				choose(opt, true)
			end)
			end
		end
		if shown == 0 and needle ~= "" then
			new("TextLabel", {
				Name = "NoResults", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, itemH - 2), ZIndex = 52, BackgroundTransparency = 1,
				Text = "No results", TextSize = 15, Font = Enum.Font.Gotham, TextColor3 = C.sub,
			}, menu)
		end
	end

	refreshMulti = function(quiet)
		local sum = summary()
		current = sum
		if txt.Text ~= sum then setText(sum) end
		if not quiet then pulse() end
		if ui and ui.menu and ui.menu.Parent then -- rebuild the ticks, keep the scroll position
			local menu, keep = ui.menu, ui.menu.CanvasPosition
			addItems(menu, false)
			task.spawn(function()
				task.wait()
				if menu.Parent then menu.CanvasPosition = keep end
			end)
		end
	end

	-- Opens the dropdown menu (closes any other open one first).
	local function openDropdown()
		if closeOpenDropdown then closeOpenDropdown() end
		isOpen = true
		if entry.onOpen then safe(entry.onOpen) end   -- lets the script refresh the options right before the menu shows

		local pos, anchorY, h = menuLayout()
		local catcher = new("TextButton", {
			Size = UDim2.fromOffset(WINDOW_W, WINDOW_H), BackgroundTransparency = 1, Text = "",
			AutoButtonColor = false, ZIndex = 49, Active = true,
		}, window)
		local menu = new("ScrollingFrame", {
			AnchorPoint = Vector2.new(0, anchorY),
			Position = UDim2.fromOffset(pos.X, pos.Y + (anchorY == 0 and -8 or 8)),
			Size = UDim2.fromOffset(W, 0), ZIndex = 50,
			BackgroundColor3 = MENU_BG, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
			ScrollBarImageColor3 = C.stroke, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, window)
		corner(menu, UDim.new(0, 10))
		local mStroke = stroke(menu, C.stroke, 1, 1)
		new("UIPadding", { PaddingTop = UDim.new(0, 4 + SEARCH_H), PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, menu)
		new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, menu)
		ui = { menu = menu }

		-- search box: stays at the top of the menu (the menu grows / scrolls underneath it). Type to show only the options whose name contains the letters.
		searchText = ""
		local box = new("TextBox", {
			Name = "Search", Size = UDim2.fromOffset(W - 8, SEARCH_H - 6), BackgroundColor3 = FIELD, BorderSizePixel = 0, ZIndex = 60,
			Text = "", PlaceholderText = "Search...", PlaceholderColor3 = C.sub, TextColor3 = C.text, ClearTextOnFocus = false,
			TextSize = 15, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Visible = false,
		}, window)
		corner(box, UDim.new(0, 8))
		new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, box)
		local follow
		follow = game:GetService("RunService").RenderStepped:Connect(function()   -- keeps the box on the top edge while the menu animates
			if not menu.Parent or not box.Parent then follow:Disconnect() return end
			local sc = uiScale.Scale
			local rel = (menu.AbsolutePosition - window.AbsolutePosition) / sc
			box.Position = UDim2.fromOffset(rel.X + 4, rel.Y + 4)
			box.Visible = menu.AbsoluteSize.Y / sc > SEARCH_H + 6 and menu.BackgroundTransparency < 0.9
		end)
		box:GetPropertyChangedSignal("Text"):Connect(function()
			if box.Text == searchText then return end
			searchText = box.Text
			if menu.Parent then
				addItems(menu, false)
				menu.CanvasPosition = Vector2.zero
			end
		end)
		task.delay(0.15, function()   -- on a PC you can just start typing; on touch the keyboard only opens when you tap the box
			if box.Parent and UserInputService.KeyboardEnabled then pcall(function() box:CaptureFocus() end) end
		end)

		addItems(menu, true, 0.03)

		-- the menu grows out of the field
		tweenX(menu, {
			Size = UDim2.fromOffset(W, h), Position = UDim2.fromOffset(pos.X, pos.Y), BackgroundTransparency = 0,
		}, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		tweenX(mStroke, { Transparency = 0 }, 0.25)
		tweenX(chev, { Rotation = 180, Position = CHEV_REST }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tweenX(btn, { BackgroundColor3 = FIELD_HOVER }, 0.15)
		tweenX(st, { Color = C.accent }, 0.2)

		closeOpenDropdown = function()
			closeOpenDropdown = nil
			isOpen = false
			ui = nil
			catcher:Destroy()
			if follow then follow:Disconnect() end
			pcall(function() box:ReleaseFocus() end)
			box:Destroy()
			searchText = ""

			tweenX(chev, { Rotation = 0 }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			tweenX(btn, { BackgroundColor3 = FIELD }, 0.2)
			tweenX(st, { Color = C.stroke }, 0.25)

			-- fade the items, then fold the menu back into the field
			for _, d in ipairs(menu:GetDescendants()) do
				if d:IsA("TextLabel") then
					tweenX(d, { TextTransparency = 1 }, 0.12)
				elseif d:IsA("GuiObject") then
					tweenX(d, { BackgroundTransparency = 1 }, 0.12)
				end
			end
			tweenX(mStroke, { Transparency = 1 }, 0.16)
			tweenX(menu, {
				Size = UDim2.fromOffset(W, 0), BackgroundTransparency = 1,
				Position = UDim2.fromOffset(pos.X, pos.Y + (anchorY == 0 and -8 or 8)),
			}, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.22, function() menu:Destroy() end)
		end
		catcher.MouseButton1Click:Connect(function() if closeOpenDropdown then closeOpenDropdown() end end)
	end
	btn.MouseButton1Click:Connect(openDropdown)

	-- called by scripts after they edit the options table: updates the shown text, the open menu and plays a glow
	entry._refreshMulti = function(quiet) if refreshMulti then refreshMulti(quiet) end end
	entry._refresh = function(selectOpt)
		local sig = table.concat(options, "\n")
		local changed = sig ~= lastSig
		lastSig = sig
		if selectOpt ~= nil and selectOpt ~= current then
			current = selectOpt
			setText(selectOpt)
		end
		if changed then
			pulse()
			if ui and ui.menu and ui.menu.Parent then
				-- the menu is open right now: rebuild the items and resize it smoothly
				local pos, anchorY, h = menuLayout()
				ui.menu.AnchorPoint = Vector2.new(0, anchorY)
				addItems(ui.menu, true, 0.015)
				tweenX(ui.menu, { Size = UDim2.fromOffset(W, h), Position = UDim2.fromOffset(pos.X, pos.Y) },
					0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			end
		end
	end

	register(entry, {
		type = "dropdown",
		get = function()
			if counter then
				local l = {}
				for _, o in ipairs(pickedList()) do l[#l + 1] = o .. "=" .. counts[o] end
				return table.concat(l, "|")
			end
			if multi then return table.concat(pickedList(), "|") end -- "" = nothing ticked
			return current
		end,
		set = function(v)
			if counter then
				for k in pairs(counts) do counts[k] = nil end
				for part in tostring(v):gmatch("[^|]+") do
					local name, n = part:match("^(.*)=(%d+)$")
					if name and table.find(options, name) and name ~= clearOpt then counts[name] = tonumber(n) end
				end
				refreshMulti()
				safe(entry.callback, nil)
				return
			end
			if multi then
				for k in pairs(picked) do picked[k] = nil end
				for name in tostring(v):gmatch("[^|]+") do
					if name ~= clearOpt and table.find(options, name) then picked[name] = true end
				end
				refreshMulti()
				safe(entry.callback, nil)
				return
			end
			if table.find(options, v) and v ~= current then choose(v, true) end
		end,
	})
end

---------------------------------------------------------------- input
local function buildInput(row, entry)
	local W, H = 220, 42
	local IDLE_STROKE = C.stroke
	local lastSubmitted = entry.default ~= nil and tostring(entry.default) or ""

	local box = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(RIGHT_X, 42), Size = UDim2.fromOffset(W, H),
		BackgroundColor3 = FIELD, BorderSizePixel = 0, ClearTextOnFocus = false,
		Text = lastSubmitted,
		PlaceholderText = entry.placeholder or "Type here...", PlaceholderColor3 = Color3.fromRGB(109, 109, 109),
		TextColor3 = C.text, TextSize = 16, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)
	corner(box, UDim.new(0, 14))
	new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, box)
	local st = stroke(box, IDLE_STROKE, 1)

	if entry.numeric then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			local cleaned = (box.Text:gsub("[^%d%.%-]", ""))
			if cleaned ~= box.Text then box.Text = cleaned end
		end)
	end

	-- Flashes the outline of the box (green = ok, grey = failed).
	local function flash(color)
		st.Color = color
		task.delay(0.6, function()
			if alive and not box:IsFocused() then tween(st, { Color = IDLE_STROKE }, 0.25) end
		end)
	end

	-- Reads the box text and sends it to the entry's callback.
	local function submit()
		local value = box.Text
		if entry.numeric then
			value = tonumber(value)
			if not value then flash(RUN_FAIL); return false end
		end
		lastSubmitted = box.Text
		if entry.clearOnSubmit then box.Text = "" end
		flash(RUN_OK)
		safe(entry.callback, value)
		return true
	end

	box.Focused:Connect(function() tween(st, { Color = C.accent }) end)
	box.FocusLost:Connect(function() submit() end)

	register(entry, {
		type = "input",
		get = function() return entry.clearOnSubmit and lastSubmitted or box.Text end,
		set = function(v) box.Text = tostring(v); submit() end,
	})
end

---------------------------------------------------------------- keybind (click it, press a key)
local function buildKeybind(row, entry)
	local W, H = 220, 42
	local listening = false

	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(RIGHT_X, 42), Size = UDim2.fromOffset(W, H),
		BackgroundColor3 = FIELD, AutoButtonColor = false, Text = prettyKey(minimizeKey),
		TextColor3 = C.text, TextSize = 16, Font = Enum.Font.GothamMedium,
	}, row)
	corner(btn, UDim.new(0, 14))
	local st = stroke(btn, C.stroke, 1)
	local sc = new("UIScale", { Scale = 1 }, btn)

	-- Redraws the keybind button.
	local function render()
		if listening then
			btn.Text = "Press a key...  (Esc)"
			btn.TextColor3 = C.iconFg
			btn.TextSize = 15
		else
			btn.Text = prettyKey(minimizeKey)
			btn.TextColor3 = C.text
			btn.TextSize = 16
		end
	end

	-- Stops listening for a key.
	local function stop()
		listening = false
		keybindCapture = nil
		tweenX(st, { Color = C.stroke }, 0.25)
		render()
	end

	-- Captures the next key press as the new key.
	local function capture(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if input.KeyCode == Enum.KeyCode.Escape then stop() return end
		if input.KeyCode == Enum.KeyCode.Unknown then return end
		minimizeKey = input.KeyCode
		stop()
		-- confirmation: green flash + a little pop
		st.Color = C.greenText
		tweenX(st, { Color = C.stroke }, 0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		sc.Scale = 1.07
		tweenX(sc, { Scale = 1 }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end

	-- Starts listening for a key press.
	local function start()
		listening = true
		keybindCapture = capture
		render()
		task.spawn(function() -- breathing outline while it waits for a key
			local on = false
			while listening and alive do
				on = not on
				tweenX(st, { Color = on and C.accent or C.iconFg }, 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				task.wait(0.5)
			end
		end)
	end

	btn.MouseButton1Click:Connect(function()
		if listening then stop() else start() end
	end)
	btn.MouseEnter:Connect(function()
		if not listening then
			tween(btn, { BackgroundColor3 = FIELD_HOVER }, 0.15)
			tween(st, { Color = Color3.fromRGB(75, 75, 75) }, 0.15)
		end
	end)
	btn.MouseLeave:Connect(function()
		tweenX(sc, { Scale = 1 }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		if not listening then
			tween(btn, { BackgroundColor3 = FIELD }, 0.2)
			tween(st, { Color = C.stroke }, 0.2)
		end
	end)
	btn.MouseButton1Down:Connect(function() tweenX(sc, { Scale = 0.96 }, 0.08) end)
	btn.MouseButton1Up:Connect(function()
		tweenX(sc, { Scale = 1 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)

	table.insert(cleanupHooks, function() keybindCapture = nil listening = false end)

	-- saved as a text input in the configuration (stores the key name, e.g. "LeftControl")
	register(entry, {
		type = "input",
		get = function() return minimizeKey.Name end,
		set = function(v)
			local ok, kc = pcall(function() return Enum.KeyCode[tostring(v)] end)
			if ok and kc then
				minimizeKey = kc
				render()
			end
		end,
	})
end

---------------------------------------------------------------- webhook (input + Test Webhook + Save Webhook)
local BOT_NAME = "WORST • Tap simulator"
local BOT_AVATAR = "https://static.vecteezy.com/system/resources/previews/004/891/075/non_2x/the-initials-w-logo-is-simple-and-modern8868-free-vector.jpg"

-- Returns the executor's HTTP request function.
local function getRequestFunction()
	if typeof(request) == "function" then return request end
	if typeof(http_request) == "function" then return http_request end
	if syn and typeof(syn.request) == "function" then return syn.request end
	if http and typeof(http.request) == "function" then return http.request end
	if fluxus and typeof(fluxus.request) == "function" then return fluxus.request end
end

-- your username as it appears in webhook messages (a Discord spoiler = blurred) 
local function webhookName()
	if WebhookState.blur then return "||" .. player.Name .. "||" end
	return player.Name
end

-- Trims spaces from both ends of a text.
local function trim(str) return (str:gsub("^%s+", ""):gsub("%s+$", "")) end

-- True if a text is a Discord webhook link.
local function isWebhookUrl(u)
	return u:match("^https://discord%.com/api/webhooks/%d+/[%w_%-]+") ~= nil
		or u:match("^https://discordapp%.com/api/webhooks/%d+/[%w_%-]+") ~= nil
		or u:match("^https://canary%.discord%.com/api/webhooks/%d+/[%w_%-]+") ~= nil
		or u:match("^https://ptb%.discord%.com/api/webhooks/%d+/[%w_%-]+") ~= nil
end

-- Sends a test message to the webhook.
local function sendTestMessage(url)
	local req = getRequestFunction()
	if not req then return false, "this executor has no HTTP request function" end
	local body = HttpService:JSONEncode({
		username = BOT_NAME,
		avatar_url = BOT_AVATAR,
		embeds = { {
			title = "Webhook Test",
			description = "Your webhook is connected and working.",
			color = 10066329,
			fields = {
				{ name = "Player", value = webhookName(), inline = true },
				{ name = "Time", value = os.date("!%Y-%m-%d %H:%M:%S") .. " UTC", inline = true },
			},
		} },
	})
	local ok, res = pcall(req, {
		Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body,
	})
	if not ok then return false, tostring(res) end
	local code = res.StatusCode or res.status_code
	if res.Success or (type(code) == "number" and code >= 200 and code < 300) then return true end
	return false, ("HTTP %s %s"):format(tostring(code), tostring(res.Body))
end

---------------------------------------------------------------- new pets -> webhook (hatched / crafted)
local PetWebhook = (function()
	local RS = game:GetService("ReplicatedStorage")
	-- ======================= EDIT THESE =======================
	local FROM_TEXT       = "From: WORST"                 -- title of every message
	local FOOTER_TEXT     = "discord.gg/w0rst"   -- footer of every message (your discord link)
	local FOOTER_ICON_URL = ""   -- image link for the footer icon      ("" = none)
	local THUMBNAIL_URL   = ""   -- small image, top right of the card  ("" = none)
	local HATCH_IMAGE_URL = ""   -- big image on hatch messages         ("" = none)
	local ENCHANT_IMAGE_URL = "" -- big image on enchant messages       ("" = none)
	local CRAFT_IMAGE_URL = ""   -- big image on craft messages         ("" = none)
	local COLORS          = { Hatch = 5793266, Craft = 16766720, Enchant = 10181046 }   -- embed colors (decimal)
	-- Per-pet picture shown as the small image of that pet's message. Leave "yourlinkhere" for pets you have no picture for.
	-- Every pet the game has is written to WORST/pet_names.txt (already in this format) a few seconds after you execute:
	-- open it, copy the lines you want in here and replace yourlinkhere with the image link.
	local PET_IMAGES = {
		-- ["Pet Name"] = "yourlinkhere",
	}
	-- ==========================================================
	local POLL         = 1    -- seconds between two looks at your pets
	local CRAFT_WINDOW = 10   -- a new pet counts as crafted if a machine answer arrived in the last X seconds
	local MAX_EMBEDS   = 10   -- Discord's limit per message
	local VARIETY      = { Normal = "Normal", Golden = "Golden", Diamond = "Diamond", Shiny = "Rainbow", Rainbow = "Rainbow" }

	local lastCraft, lastHatch = 0, 0
	pcall(function()
		local machine = RS.RemoteServices.MachineService.RE
		for _, r in ipairs(machine:GetChildren()) do
			if r:IsA("RemoteEvent") and r.Name ~= "MachineCraftRequested" then
				connect(r.OnClientEvent, function() lastCraft = os.clock() end)
			end
		end
	end)
	pcall(function()
		local egg = RS.RemoteServices.EggService.RE
		for _, r in ipairs(egg:GetChildren()) do
			local n = r.Name:lower()
			if r:IsA("RemoteEvent") and n:find("hatch", 1, true) and not n:find("request", 1, true) then
				connect(r.OnClientEvent, function() lastHatch = os.clock() end)
			end
		end
	end)

	-- Returns the current source (time) used for new pet messages.
	local function sourceNow()
		local now = os.clock()
		if now - lastCraft <= CRAFT_WINDOW and lastCraft >= lastHatch then return "Craft" end
		return "Hatch"
	end

	-- Returns the rarity of a pet name.
	local function rarityOf(name)
		local ok, r = pcall(function() return Logic and Logic.autodel and Logic.autodel.rarityOf and Logic.autodel.rarityOf(name) end)
		if ok and type(r) == "string" and r ~= "" then return r end
		return nil
	end

	-- writes every pet the game has (read by Auto Delete's scan) to WORST/pet_names.txt, one `["Name"] = "yourlinkhere",` line each
	task.spawn(function()
		for _ = 1, 90 do   -- the scan needs a little time after execute
			if not alive then return end
			local ok, list = pcall(function() return Logic and Logic.autodel and Logic.autodel.petNames and Logic.autodel.petNames() end)
			if ok and type(list) == "table" and #list > 0 then
				table.sort(list, function(a, b) if a.rarity ~= b.rarity then return tostring(a.rarity) < tostring(b.rarity) end return a.name < b.name end)
				local lines, last = {}, nil
				for _, p in ipairs(list) do
					if not (p.name:find("_Golden$") or p.name:find("_Diamond$") or p.name:find("_Shiny$")) then
						if p.rarity ~= last then lines[#lines + 1] = "-- " .. tostring(p.rarity) last = p.rarity end
						lines[#lines + 1] = string.format("[%q] = \"yourlinkhere\",", p.name)
					end
				end
				pcall(Store.write, "pet_names.txt", table.concat(lines, "\n"))
				print(string.format("[WORST Hub] %d pet names written to WORST/pet_names.txt", #list))
				return
			end
			task.wait(2)
		end
	end)

	-- Builds the Discord embed for a new pet.
	local function embedFor(source, g)
		local rarity = rarityOf(g.name)
		local what = (rarity and (rarity .. " ") or "") .. g.name
		local e = {
			title = FROM_TEXT,
			description = string.format("You %s a **%s**", source == "Craft" and "crafted" or "hatched", what),
			color = COLORS[source],
			fields = {
				{ name = "Variety", value = g.variety, inline = true },
				{ name = "Amount", value = tostring(g.count), inline = true },
				{ name = "Player", value = webhookName(), inline = true },
			},
			footer = { text = FOOTER_TEXT },
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		}
		if FOOTER_ICON_URL ~= "" then e.footer.icon_url = FOOTER_ICON_URL end
		local petImg = PET_IMAGES[g.name]
		if type(petImg) == "string" and petImg:find("^https?://") then
			e.thumbnail = { url = petImg }   -- this pet's own picture
		elseif THUMBNAIL_URL ~= "" then
			e.thumbnail = { url = THUMBNAIL_URL }
		end
		local img = source == "Craft" and CRAFT_IMAGE_URL or HATCH_IMAGE_URL
		if img ~= "" then e.image = { url = img } end
		return e
	end

	-- one message at a time, a short pause between them (Discord rate limits)
	local queue, sending = {}, false
	-- Posts embeds to the saved webhook link.
	local function post(embeds)
		local url = trim(Store.read("webhook.txt") or "")
		if not isWebhookUrl(url) then return end
		local req = getRequestFunction()
		if not req then return end
		local body = HttpService:JSONEncode({ username = BOT_NAME, avatar_url = BOT_AVATAR, embeds = embeds })
		local ok, res = pcall(req, { Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
		if not ok then warn("[Webhook] send failed: " .. tostring(res)) return end
		local code = res.StatusCode or res.status_code
		if code == 429 then
			task.wait(2)
			pcall(req, { Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
		elseif type(code) == "number" and code >= 300 then
			warn("[Webhook] HTTP " .. tostring(code) .. " " .. tostring(res.Body))
		end
	end
	-- Sends the queued embeds (one at a time).
	local function flush()
		if sending then return end
		sending = true
		task.spawn(function()
			while alive and #queue > 0 do
				post(table.remove(queue, 1))
				task.wait(1)
			end
			sending = false
		end)
	end
	WebhookBridge.enchant = function(info)
		if not WebhookState.enchant then return end
		local rarity = rarityOf(info.name)
		local variety = VARIETY[tostring(info.tier or "Normal")] or tostring(info.tier or "Normal")
		local e = {
			title = FROM_TEXT,
			description = string.format("You enchanted a **%s**", (rarity and (rarity .. " ") or "") .. tostring(info.name)),
			color = COLORS.Enchant,
			fields = {
				{ name = "Enchant", value = info.enchant, inline = true },
				{ name = "Variety", value = variety, inline = true },
				{ name = "Rolls", value = tostring(info.rolls), inline = true },
			},
			footer = { text = FOOTER_TEXT },
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		}
		if info.bothSlots or info.slot == 2 then
			table.insert(e.fields, 3, { name = "Slot", value = tostring(info.slot), inline = true })
		end
		e.fields[#e.fields + 1] = { name = "Player", value = webhookName(), inline = true }
		if FOOTER_ICON_URL ~= "" then e.footer.icon_url = FOOTER_ICON_URL end
		if THUMBNAIL_URL ~= "" then e.thumbnail = { url = THUMBNAIL_URL } end
		if ENCHANT_IMAGE_URL ~= "" then e.image = { url = ENCHANT_IMAGE_URL } end
		queue[#queue + 1] = { e }
		flush()
	end

	-- Adds new pet messages to the queue.
	local function enqueue(source, groups)
		local embeds = {}
		for _, g in ipairs(groups) do
			embeds[#embeds + 1] = embedFor(source, g)
			if #embeds >= MAX_EMBEDS then queue[#queue + 1] = embeds embeds = {} end
		end
		if #embeds > 0 then queue[#queue + 1] = embeds end
		flush()
	end

	-- Returns the pets you own.
	local function ownedPets()
		local okD, data = pcall(function() return require(RS.Controllers.Core.DataController):GetReplica().Data end)
		local owned = okD and type(data) == "table" and data.Pets and data.Pets.Owned
		if type(owned) == "table" then return owned end
	end

	task.spawn(function()
		local seen, ready, lastCount, stable = {}, false, -1, 0
		local hasUrl, urlCheckedAt = false, -1e9
		while alive do
			task.wait(POLL)
			-- nothing to announce without a valid webhook URL: skip the per-pet scan entirely (it grows with your pet count)
			if os.clock() - urlCheckedAt > 10 then
				urlCheckedAt = os.clock()
				hasUrl = isWebhookUrl(trim(Store.read("webhook.txt") or ""))
			end
			if not (WebhookState.on and hasUrl) then
				seen, ready, lastCount, stable = {}, false, -1, 0   -- re-learn the baseline when it is switched on
				continue
			end
			local owned = ownedPets()
			if owned then
				if not ready then
					-- the first look only remembers what you already own (waits until the list stops growing)
					local count = 0
					for _ in pairs(owned) do count = count + 1 end
					if count > 0 and count == lastCount then stable = stable + 1 else stable = 0 end
					lastCount = count
					if stable >= 2 then
						for pid in pairs(owned) do seen[tostring(pid)] = true end
						ready = true
					end
				else
					local groups, list = {}, {}
					for pid, p in pairs(owned) do
						local id = tostring(pid)
						if not seen[id] and type(p) == "table" and type(p.Name) == "string" then
							seen[id] = true -- a pet is announced once, even if it leaves and comes back (enchanting, trading)
							if WebhookState.on then
								local variety = VARIETY[tostring(p.Tier or "Normal")] or tostring(p.Tier)
								local key = p.Name .. "|" .. variety
								local g = groups[key]
								if not g then
									g = { name = p.Name, variety = variety, count = 0 }
									groups[key] = g
									list[#list + 1] = g
								end
								g.count = g.count + 1
							end
						end
					end
					if #list > 0 then
						table.sort(list, function(a, b) if a.name ~= b.name then return a.name < b.name end return a.variety < b.variety end)
						enqueue(sourceNow(), list)
					end
				end
			end
		end
	end)
end)()

-- Builds the Webhook tab row (link box, Test and Save buttons).
local function buildWebhook(row, entry)
	local IDLE_STROKE = C.stroke

	local box = new("TextBox", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(330, 42), Size = UDim2.fromOffset(300, 42),
		BackgroundColor3 = FIELD, BorderSizePixel = 0, ClearTextOnFocus = false,
		Text = Store.read("webhook.txt") or "",
		PlaceholderText = entry.placeholder or "https://discord.com/api/webhooks/...",
		PlaceholderColor3 = Color3.fromRGB(109, 109, 109),
		TextColor3 = C.text, TextSize = 15, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)
	corner(box, UDim.new(0, 14))
	new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, box)
	local st = stroke(box, IDLE_STROKE, 1)
	box.Focused:Connect(function() tween(st, { Color = C.accent }) end)
	box.FocusLost:Connect(function() tween(st, { Color = IDLE_STROKE }) end)

	-- Builds one action button of the webhook row.
	local function actionButton(text, x, w, color, hover, pendingText, handler)
		local btn = new("TextButton", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(x, 42), Size = UDim2.fromOffset(w, 42),
			BackgroundColor3 = color, Text = text, TextColor3 = Color3.new(1, 1, 1), TextSize = 16,
			Font = Enum.Font.GothamMedium, AutoButtonColor = false,
		}, row)
		corner(btn, UDim.new(0, 14))
		Config.polish(btn)
		local busy = false
		btn.MouseEnter:Connect(function() if not busy then tween(btn, { BackgroundColor3 = hover }) end end)
		btn.MouseLeave:Connect(function() if not busy then tween(btn, { BackgroundColor3 = color }) end end)
		btn.MouseButton1Click:Connect(function()
			if busy then return end
			busy = true
			btn.Text = pendingText
			task.spawn(function()
				local ok, result = handler()
				if not alive then return end
				btn.Text = result or (ok and "Done ✓" or "Failed ✕")
				tween(btn, { BackgroundColor3 = ok and RUN_OK or RUN_FAIL })
				task.wait(1.6)
				if not alive then return end
				btn.Text = text
				tween(btn, { BackgroundColor3 = color })
				busy = false
			end)
		end)
	end

	actionButton("Test Webhook", 642, 150, Color3.fromRGB(44, 44, 44), Color3.fromRGB(59, 59, 59), "Sending...", function()
		local url = trim(box.Text)
		if not isWebhookUrl(url) then return false, "Invalid link" end
		local ok, err = sendTestMessage(url)
		if not ok then
			warn("[WORST Hub] Webhook test failed: " .. tostring(err))
			return false, "Failed ✕"
		end
		return true, "Sent ✓"
	end)

	actionButton("Save Webhook", RIGHT_X - 150, 150, RUN_IDLE, RUN_HOVER, "Saving...", function()
		local url = trim(box.Text)
		if not isWebhookUrl(url) then return false, "Invalid link" end
		local ok, err = pcall(Store.write, "webhook.txt", url)
		if not ok then
			warn("[WORST Hub] Couldn't save webhook: " .. tostring(err))
			return false, "Failed ✕"
		end
		box.Text = url
		return true, "Saved ✓"
	end)
end

---------------------------------------------------------------- configuration: name box + Save
local function buildConfigSave(row, entry)
	local box = new("TextBox", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(RIGHT_X - 150 - 12 - 250, 42),
		Size = UDim2.fromOffset(250, 42), BackgroundColor3 = FIELD, BorderSizePixel = 0, ClearTextOnFocus = false,
		Text = "", PlaceholderText = "Configuration name", PlaceholderColor3 = Color3.fromRGB(109, 109, 109),
		TextColor3 = C.text, TextSize = 15, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)
	corner(box, UDim.new(0, 14))
	new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, box)
	local st = stroke(box, C.stroke, 1)
	box.Focused:Connect(function() tween(st, { Color = C.accent }) end)
	box.FocusLost:Connect(function() tween(st, { Color = C.stroke }) end)

	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(RIGHT_X - 150, 42), Size = UDim2.fromOffset(150, 42),
		BackgroundColor3 = RUN_IDLE, Text = "Save", TextColor3 = Color3.new(1, 1, 1), TextSize = 16,
		Font = Enum.Font.GothamMedium, AutoButtonColor = false,
	}, row)
	corner(btn, UDim.new(0, 14))
	Config.polish(btn)
	local busy = false
	btn.MouseEnter:Connect(function() if not busy then tween(btn, { BackgroundColor3 = RUN_HOVER }) end end)
	btn.MouseLeave:Connect(function() if not busy then tween(btn, { BackgroundColor3 = RUN_IDLE }) end end)
	btn.MouseButton1Click:Connect(function()
		if busy then return end
		busy = true
		local ok, err = pcall(Config.saveNamed, box.Text)
		if not ok then warn("[WORST Hub] Couldn't save configuration: " .. tostring(err)) end
		btn.Text = ok and "Saved ✓" or "Failed ✕"
		tween(btn, { BackgroundColor3 = ok and RUN_OK or RUN_FAIL })
		if ok then box.Text = "" end
		task.delay(1.5, function()
			if not alive then return end
			btn.Text = "Save"
			tween(btn, { BackgroundColor3 = RUN_IDLE })
			busy = false
		end)
	end)
end

---------------------------------------------------------------- configuration list (header row + one row per saved configuration)
local function buildConfigList(row, entry)
	-- the whole card is the box: header on top, one entry per saved configuration below it
	Config.loadIndex()
	row.AutomaticSize = Enum.AutomaticSize.Y   -- Size.Y (84) stays the minimum, the box grows with its entries
	local RW = 1042                            -- width of an entry inside the box

	local countLbl = label(row, "", RIGHT_X, 42, 16, C.sub, Enum.Font.GothamMedium, Enum.TextXAlignment.Right)
	countLbl.Size = UDim2.fromOffset(240, 24)
	frame(row, 20, 84, 1026, 1, C.stroke, 0.6)

	local body = new("Frame", {
		Position = UDim2.fromOffset(12, 98), Size = UDim2.fromOffset(RW, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, BorderSizePixel = 0,
	}, row)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, body)
	new("UIPadding", { PaddingBottom = UDim.new(0, 16) }, body)

	-- Reads the saved data of a Home card item.
	local function readData(item)
		local raw = Store.read(item.file)
		if not raw then return nil end
		local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
		if ok and type(data) == "table" then return data end
	end

	-- names of the toggles that were on / off in a saved configuration (a name shared by two toggles gets its page in front)
	local function toggleNames(data)
		local on, off, seen = {}, {}, {}
		local toggles = type(data.toggles) == "table" and data.toggles or {}
		for id in pairs(toggles) do
			local nm = tostring(id):match("[^/]+$") or tostring(id)
			seen[nm] = (seen[nm] or 0) + 1
		end
		for id, v in pairs(toggles) do
			local parts = string.split(tostring(id), "/")
			local nm = parts[#parts]
			if seen[nm] > 1 and #parts > 1 then nm = parts[#parts - 1] .. ": " .. nm end
			table.insert(v == true and on or off, nm)
		end
		table.sort(on)
		return on, #off
	end

	-- Formats "time ago" text.
	local function ago(t)
		if type(t) ~= "number" then return nil end
		local d = os.time() - t
		if d < 60 then return "just now" end
		if d < 3600 then return math.floor(d / 60) .. "m ago" end
		if d < 86400 then return math.floor(d / 3600) .. "h ago" end
		return math.floor(d / 86400) .. "d ago"
	end

	-- the panel that opens under an entry: the toggles that were on
	local function mkDetail(parent, data)
		local clip = new("Frame", {   -- the panel grows out of the entry inside this frame (height is tweened)
			LayoutOrder = 2, Size = UDim2.fromOffset(RW, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
			ClipsDescendants = true, Visible = false,
		}, parent)
		local d = new("Frame", {
			Position = UDim2.fromOffset(1, 1), Size = UDim2.fromOffset(RW - 2, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(10, 10, 10), BackgroundTransparency = 0.2, BorderSizePixel = 0,
		}, clip)
		local flowRef
		corner(d, UDim.new(0, 14))
		stroke(d, C.stroke, 1, 0.5)
		new("UIPadding", {
			PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
		}, d)
		new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, d)

		-- Adds a note label to the Home page.
		local function note(text, order, color)
			local l = new("TextLabel", {
				LayoutOrder = order, Size = UDim2.fromOffset(RW - 36, 20), BackgroundTransparency = 1, Text = text,
				TextColor3 = color or C.sub, TextSize = 14, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
			}, d)
			return l
		end

		if not data then
			note("Couldn't read this configuration.", 1)
			return clip, d, nil
		end
		local on, offCount = toggleNames(data)
		note(#on == 0 and "No toggles were on in this configuration." or ("Toggles that were on  (" .. #on .. ")"), 1, #on == 0 and C.sub or C.text)
		if #on > 0 then
			local flow = new("Frame", {
				LayoutOrder = 2, Size = UDim2.fromOffset(RW - 36, 0), AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1, BorderSizePixel = 0,
			}, d)
			flowRef = flow
			new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
			}, flow)
			for i, nm in ipairs(on) do
				local holder = new("Frame", {   -- the extra height is the gap between two rows of chips
					LayoutOrder = i, Size = UDim2.fromOffset(0, 36), AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1, BorderSizePixel = 0,
				}, flow)
				local chip = new("Frame", {
					Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X,
					BackgroundColor3 = Color3.fromRGB(34, 34, 34), BorderSizePixel = 0,
				}, holder)
				corner(chip, UDim.new(1, 0))
				stroke(chip, Color3.fromRGB(150, 150, 150), 1, 0.2)
				new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14) }, chip)
				new("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
				}, chip)
				local dot = new("Frame", {
					LayoutOrder = 1, Size = UDim2.fromOffset(7, 7), BackgroundColor3 = Color3.fromRGB(235, 235, 235), BorderSizePixel = 0,
				}, chip)
				corner(dot, UDim.new(1, 0))
				new("TextLabel", {
					LayoutOrder = 2, Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
					Text = nm, RichText = false, TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamMedium,
				}, chip)
			end
		end
		if offCount > 0 then
			note(offCount .. (offCount == 1 and " other toggle was off." or " other toggles were off."), 3, Color3.fromRGB(110, 110, 110))
		end
		return clip, d, flowRef
	end

	-- fade helpers (same idea as the dropdown menu: items fade in one after the other, everything fades out together)
	local function fadeProp(o)
		if o:IsA("UIStroke") then return "Transparency" end
		if o:IsA("TextLabel") then return "TextTransparency" end
		if o:IsA("GuiObject") then return "BackgroundTransparency" end
	end
	-- Calls fn for an object and all of its children.
	local function eachObj(root, fn)
		fn(root)
		for _, o in ipairs(root:GetDescendants()) do fn(o) end
	end
	-- Records the original transparency of an object tree.
	local function recordFade(root)   -- remember the normal transparency of everything in the panel
		eachObj(root, function(o)
			local prop = fadeProp(o)
			if prop then o:SetAttribute("t", o[prop]) end
		end)
	end
	-- Hides a tree (fully transparent).
	local function hideAll(root)
		eachObj(root, function(o)
			local prop = fadeProp(o)
			if prop and o:GetAttribute("t") ~= nil then o[prop] = 1 end
		end)
	end
	-- Fades a tree in or out.
	local function fadeAll(root, flow, show, dur, step)
		eachObj(root, function(o)
			local prop, t = fadeProp(o), o:GetAttribute("t")
			if not prop or t == nil then return end
			local delay = 0
			if show and flow and o:IsDescendantOf(flow) then   -- chips come in one after the other
				local a = o
				while a.Parent and a.Parent ~= flow do a = a.Parent end
				delay = math.min(math.max(a.LayoutOrder - 1, 0), 20) * step
			end
			-- Runs the fade (after a delay if one is set).
			local function run() if o.Parent then tweenX(o, { [prop] = show and t or 1 }, dur) end end
			if delay > 0 then task.delay(delay, run) else run() end
		end)
	end

	local closeOpen   -- closes the entry that is currently opened (only one is open at a time)

	-- Builds one Home card item.
	local function mkItem(i, item)
		local data = readData(item)
		local on = data and toggleNames(data) or {}
		local holder = new("Frame", {
			LayoutOrder = i, Size = UDim2.fromOffset(RW, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, BorderSizePixel = 0,
		}, body)
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, holder)

		local top = new("TextButton", {
			LayoutOrder = 1, Size = UDim2.fromOffset(RW, 58), BackgroundColor3 = FIELD, Text = "", AutoButtonColor = false,
		}, holder)
		corner(top, UDim.new(0, 14))
		local topStroke = stroke(top, C.stroke, 1, 0.35)

		badge(top, nil, tostring(i), 34, 29, 34)
		local nm = label(top, item.name, 62, 20, 18, C.text, Enum.Font.GothamMedium)
		nm.RichText = false
		nm.Size = UDim2.fromOffset(500, 26)
		local meta = {}
		if data then
			meta[#meta + 1] = #on .. (#on == 1 and " toggle on" or " toggles on")
			local when = ago(data.saved)
			if when then meta[#meta + 1] = "saved " .. when end
		else
			meta[1] = "can't read this file"
		end
		local sub = label(top, table.concat(meta, "  ·  "), 62, 41, 13, C.sub, Enum.Font.Gotham)
		sub.Size = UDim2.fromOffset(500, 18)

		-- Load button: the only place that loads the configuration
		local loadBtn = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(RW - 14, 29), Size = UDim2.fromOffset(104, 36),
			BackgroundColor3 = RUN_IDLE, Text = "Load", TextColor3 = Color3.new(1, 1, 1), TextSize = 16,
			Font = Enum.Font.GothamMedium, AutoButtonColor = false,
		}, top)
		corner(loadBtn, UDim.new(0, 12))
		Config.polish(loadBtn)

		local del = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(RW - 14 - 104 - 8, 29), Size = UDim2.fromOffset(36, 36),
			BackgroundColor3 = FIELD, Text = "x", TextColor3 = C.sub, TextSize = 16, Font = Enum.Font.GothamMedium, AutoButtonColor = false,
		}, top)
		corner(del, UDim.new(0, 12))
		stroke(del, C.stroke, 1, 0.3)

		local chev = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(RW - 14 - 104 - 8 - 36 - 22, 29),
			Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1,
		}, top)
		for _, side in ipairs({ -1, 1 }) do
			new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, side * 3.5, 0.5, 0),
				Size = UDim2.fromOffset(9, 2), Rotation = side * -45, BackgroundColor3 = C.sub, BorderSizePixel = 0,
			}, chev)
		end

		local clip, detail, flow = mkDetail(holder, data)
		recordFade(detail)
		local isOpen, animId = false, 0
		-- Opens or closes the Home card.
		local function setOpen(v)
			isOpen = v
			animId = animId + 1
			local my = animId
			if v then
				tweenX(chev, { Rotation = 180 }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				tweenX(top, { BackgroundColor3 = FIELD_HOVER }, 0.15)
				tweenX(topStroke, { Color = C.accent, Transparency = 0.1 }, 0.2)
				-- the panel grows out of the entry: height grows, it slides down a little, then the chips fade in one by one
				clip.Size = UDim2.fromOffset(RW, 0)
				detail.Position = UDim2.fromOffset(1, -7)
				hideAll(detail)
				clip.Visible = true
				task.spawn(function()
					task.wait()   -- one frame so the panel has its real height
					if my ~= animId or not clip.Parent then return end
					local h = detail.AbsoluteSize.Y / math.max(uiScale.Scale, 0.01) + 2
					tweenX(clip, { Size = UDim2.fromOffset(RW, h) }, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					tweenX(detail, { Position = UDim2.fromOffset(1, 1) }, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					fadeAll(detail, flow, true, 0.25, 0.03)
				end)
			else
				tweenX(chev, { Rotation = 0 }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				tweenX(top, { BackgroundColor3 = FIELD }, 0.2)
				tweenX(topStroke, { Color = C.stroke, Transparency = 0.35 }, 0.25)
				-- fade the content, then fold the panel back into the entry
				fadeAll(detail, flow, false, 0.12, 0)
				tweenX(clip, { Size = UDim2.fromOffset(RW, 0) }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				tweenX(detail, { Position = UDim2.fromOffset(1, -7) }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.delay(0.22, function()
					if my == animId and clip.Parent then clip.Visible = false end
				end)
			end
		end

		-- press anywhere on the entry (except Load / x) = show its toggles
		top.MouseEnter:Connect(function() if not isOpen then tween(top, { BackgroundColor3 = FIELD_HOVER }, 0.12) end end)
		top.MouseLeave:Connect(function() if not isOpen then tween(top, { BackgroundColor3 = FIELD }, 0.12) end end)
		top.MouseButton1Click:Connect(function()
			if isOpen then
				setOpen(false)
				closeOpen = nil
			else
				if closeOpen then closeOpen() end
				setOpen(true)
				closeOpen = function() if holder.Parent then setOpen(false) end end
			end
		end)

		local busy = false
		loadBtn.MouseButton1Click:Connect(function()
			if busy then return end
			busy = true
			local ok = Config.loadNamed(item.name)
			loadBtn.Text = ok and "Loaded ✓" or "Failed ✕"
			tween(loadBtn, { BackgroundColor3 = ok and RUN_OK or RUN_FAIL })
			task.delay(1.5, function()
				if alive and loadBtn.Parent then
					loadBtn.Text = "Load"
					tween(loadBtn, { BackgroundColor3 = RUN_IDLE })
				end
				busy = false
			end)
		end)
		del.MouseEnter:Connect(function() tween(del, { BackgroundColor3 = RUN_FAIL }) del.TextColor3 = Color3.new(1, 1, 1) end)
		del.MouseLeave:Connect(function() tween(del, { BackgroundColor3 = FIELD }) del.TextColor3 = C.sub end)
		del.MouseButton1Click:Connect(function() Config.delete(item.name) end)
	end

	-- Refreshes the Home page content.
	local function refresh()
		if not alive or not body.Parent then return end
		closeOpen = nil
		for _, ch in ipairs(body:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end
		local n = #Config.index
		countLbl.Text = n == 1 and "1 saved" or (n .. " saved")
		if n == 0 then
			local empty = new("TextLabel", {
				Size = UDim2.fromOffset(RW, 52), BackgroundTransparency = 1, TextColor3 = C.sub, TextSize = 16, Font = Enum.Font.Gotham,
				Text = "No saved configurations yet. Type a name above and press Save.",
			}, body)
			return
		end
		for i, item in ipairs(Config.index) do mkItem(i, item) end
	end

	Config.refreshList = refresh
	refresh()
end

---------------------------------------------------------------- page builder
local builders = {
	button = buildButton, toggle = buildToggle, slider = buildSlider, dropdown = buildDropdown,
	input = buildInput, keybind = buildKeybind, webhook = buildWebhook,
	configsave = buildConfigSave, configlist = buildConfigList,
}

-- Builds a tab page from its entries (rows or sub-pages).
local function buildScriptPage(tabName, entries)
	local page = pages[tabName]

	-- builds the rows (one card per entry) inside a scrolling list
	local function buildRows(list, rowEntries, idPrefix)
		for i, entry in ipairs(rowEntries) do
			local row = new("Frame", {
				LayoutOrder = i, Size = UDim2.fromOffset(1066, 84), BackgroundColor3 = C.card, BackgroundTransparency = CARD_T, BorderSizePixel = 0,
			}, list)
			corner(row, UDim.new(0, 20))
			stroke(row, C.stroke, 1)

			badge(row, nil, entry.icon or "▶", 48, 42, 48)
			label(row, entry.name or "Unnamed", 92, 30, 19, C.text, Enum.Font.GothamMedium)
			-- kept on the entry so scripts can show live status text here
			local descLabel = label(row, entry.desc or "", 92, 57, 16, C.sub, Enum.Font.Gotham)
			local narrow = entry.type == "dropdown" or entry.type == "keybind" or entry.type == "slider"
			descLabel.Size = UDim2.fromOffset(entry.type == "configsave" and 500 or (narrow and 590 or 720), 24)
			descLabel.TextTruncate = Enum.TextTruncate.AtEnd
			entry._desc = descLabel

			entry._id = idPrefix .. "/" .. tostring(entry.name or i)
			entry._row, entry._list, entry._order = row, list, i   -- Kaitun Hatch borrows the "Craft When Storage Is" row and gives it back
			local build = builders[entry.type or "button"]
			if build then
				build(row, entry)
			else
				warn("[WORST Hub] unknown control type: " .. tostring(entry.type))
			end
		end
	end

	-- Creates a scrolling list for a page.
	local function newList(x, y, w, h, visible)
		local list = new("ScrollingFrame", {
			Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
			BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
			ScrollBarImageColor3 = C.stroke, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y, Visible = visible,
		}, page)
		new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, list)
		new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4) }, list)
		return list
	end

	label(page, tabName, 322, 119, 30, C.text, Enum.Font.GothamBold)

	-- Settings: "Reset Script" sits outside the pages, at the far right of the title line
	if tabName == "Settings" and Config.resetEntry then
		local rb = new("TextButton", {
			Name = "ResetScriptButton", AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromOffset(322 + 1084, 133), Size = UDim2.fromOffset(160, 40),
			BackgroundColor3 = RUN_IDLE, AutoButtonColor = false, Text = "Reset Script",
			TextColor3 = Color3.new(1, 1, 1), TextSize = 17, Font = Enum.Font.GothamMedium,
		}, page)
		corner(rb, UDim.new(0, 14))
		Config.polish(rb)
		rb.MouseEnter:Connect(function() tween(rb, { BackgroundColor3 = RUN_HOVER }, 0.12) end)
		rb.MouseLeave:Connect(function() tween(rb, { BackgroundColor3 = RUN_IDLE }, 0.12) end)
		rb.MouseButton1Click:Connect(function()
			flame(rb, 1)
			pcall(Config.resetEntry.run)   -- asks "Reset the Script?" first
		end)
	end

	if entries.pages then
		-- tab with several pages: a row of page buttons, one list per page
		label(page, "Pick a page below.", 322, 149, 19, C.sub, Enum.Font.Gotham)
		frame(page, 322, 179, 1084, 1, C.stroke)

		local PILL_W, PILL_H = 176, 38
		local subLists, subButtons, subStrokes = {}, {}, {}
		local curIdx, slideId = 1, 0
		local SLIDE_W = 1084
		-- Shows one sub-page of a tab.
		local function showPage(idx)
			slideId = slideId + 1
			local my = slideId
			local old = curIdx and subLists[curIdx]
			local dir = (curIdx and idx > curIdx) and 1 or -1   -- going to a later page: new one comes from the right
			for i, list in ipairs(subLists) do
				local on = (i == idx)
				tween(subButtons[i], { BackgroundColor3 = on and SEL_BG or FIELD }, 0.15)
				tween(subStrokes[i], { Color = on and Color3.fromRGB(205, 205, 205) or C.stroke }, 0.15)
				subButtons[i].TextColor3 = on and Color3.new(1, 1, 1) or C.sub
				if not on and list ~= old then list.Visible = false end
			end
			local new_ = subLists[idx]
			if old and old ~= new_ then
				local info = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				new_.Position = UDim2.fromOffset(322 + dir * SLIDE_W, 250)
				new_.Visible = true
				TweenService:Create(new_, info, { Position = UDim2.fromOffset(322, 250) }):Play()
				TweenService:Create(old, info, { Position = UDim2.fromOffset(322 - dir * SLIDE_W, 250) }):Play()
				task.delay(0.36, function()
					if slideId == my and old.Parent then old.Visible = false end
				end)
			else
				new_.Position = UDim2.fromOffset(322, 250)
				new_.Visible = true
			end
			curIdx = idx
		end

		-- the row of page buttons scrolls sideways: mouse wheel DOWN = to the right, wheel UP = to the left (drag works too).
		-- It only moves when the buttons are wider than the row (many pages).
		local BAR_PAD, BAR_W = 3, 1090
		local bar = new("ScrollingFrame", {
			Name = "PageBar", Position = UDim2.fromOffset(322 - BAR_PAD, 193), Size = UDim2.fromOffset(BAR_W, PILL_H + 12),
			BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(110, 110, 110),
			ScrollingDirection = Enum.ScrollingDirection.X, ElasticBehavior = Enum.ElasticBehavior.Never,
			CanvasSize = UDim2.fromOffset(BAR_PAD * 2 + #entries.pages * (PILL_W + 10) - 10, 0),
		}, page)
		local barMax = math.max(bar.CanvasSize.X.Offset - BAR_W, 0)
		local barGoal, barWheelAt = 0, 0
		-- Moves the sub-page highlight bar to x.
		local function barTo(x)
			TweenService:Create(bar, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CanvasPosition = Vector2.new(math.clamp(x, 0, barMax), 0) }):Play()
		end
		if barMax > 0 then
			connect(UserInputService.InputChanged, function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
				local c = bar
				while c and c ~= gui do   -- the page / tab / window must be showing
					if c:IsA("GuiObject") and not c.Visible then return end
					c = c.Parent
				end
				local m = UserInputService:GetMouseLocation()
				local ap, as = bar.AbsolutePosition, bar.AbsoluteSize
				if m.X < ap.X or m.X > ap.X + as.X or m.Y < ap.Y or m.Y > ap.Y + as.Y then return end
				if os.clock() - barWheelAt > 0.3 then barGoal = bar.CanvasPosition.X end   -- (a fresh scroll starts from where the row is)
				barWheelAt = os.clock()
				barGoal = math.clamp(barGoal - input.Position.Z * 150, 0, barMax)   -- wheel down gives Z < 0 -> goes right
				barTo(barGoal)
			end)
		end
		for i, sp in ipairs(entries.pages) do
			local btn = new("TextButton", {
				Name = (sp.name or "Page") .. "PageButton",
				Position = UDim2.fromOffset(BAR_PAD + (i - 1) * (PILL_W + 10), 3), Size = UDim2.fromOffset(PILL_W, PILL_H),
				BackgroundColor3 = (i == 1) and SEL_BG or FIELD, AutoButtonColor = false,
				Text = sp.name or ("Page " .. i), TextColor3 = (i == 1) and Color3.new(1, 1, 1) or C.sub,
				TextSize = 16, Font = Enum.Font.GothamMedium,
			}, bar)
			corner(btn, UDim.new(0, 14))
			subStrokes[i] = stroke(btn, (i == 1) and Color3.fromRGB(205, 205, 205) or C.stroke, 1)
			btn.MouseEnter:Connect(function() if curIdx ~= i then tween(btn, { BackgroundColor3 = FIELD_HOVER }, 0.12) end end)
			btn.MouseLeave:Connect(function() if curIdx ~= i then tween(btn, { BackgroundColor3 = FIELD }, 0.12) end end)
			btn.MouseButton1Click:Connect(function()
				showPage(i)
				-- a button that is half outside the row slides fully into view
				local bx, cur = BAR_PAD + (i - 1) * (PILL_W + 10), bar.CanvasPosition.X
				if bx < cur + BAR_PAD then barTo(bx - BAR_PAD)
				elseif bx + PILL_W > cur + BAR_W - BAR_PAD then barTo(bx + PILL_W + BAR_PAD - BAR_W) end
			end)
			subButtons[i] = btn

			local list = newList(322, 250, 1084, 590, i == 1)
			subLists[i] = list
			buildRows(list, sp.entries or {}, tabName .. "/" .. tostring(sp.name or i))
		end
	else
		local SUBTITLES = {
			Kaitun = "Kaitun Hatch runs your setup, Kaitun Events runs chests, Trick or Treat, the boss and the shop, Kaitun Stats equips, rebirths and enchants.",
			Farming = "Hatch eggs and rebirth automatically.",
		}
		label(page, SUBTITLES[tabName] or "Press a button to run its script.", 322, 149, 19, C.sub, Enum.Font.Gotham)
		frame(page, 322, 179, 1084, 1, C.stroke)
		local plist = newList(322, 201, 1084, 640, true)
		Config.pageLists[tabName] = plist
		buildRows(plist, entries, tabName)
	end
end

---------------------------------------------------------------- save configuration (auto-loaded on execute)
-- the value that gets SAVED for a control: normally what it shows now, but while Kaitun Hatch owns a control it is the value you had set yourself
function Config.val(id, c)
	local o = Config.override[id]
	if o ~= nil then return o end
	return c.get()
end

-- Collects every saved control value into a table.
function Config.collect()
	local data = {
		version = 1, saved = os.time(),
		toggles = {}, sliders = {}, dropdowns = {}, inputs = {}, buttons = {},
	}
	for id, c in pairs(controls) do
		local v = Config.val(id, c)
		if c.type == "toggle" then data.toggles[id] = v
		elseif c.type == "slider" then data.sliders[id] = v
		elseif c.type == "dropdown" then data.dropdowns[id] = v
		elseif c.type == "input" then data.inputs[id] = v
		end
	end
	return data
end

-- Saves the configuration (config.json).
function Config.save(silent)
	Store.write("config.json", HttpService:JSONEncode(Config.collect()))
	if not silent then print("[WORST Hub] Configuration saved.") end
end

-- a text fingerprint of every saved control, used by Auto Save to notice changes
function Config.signature()
	local keys = {}
	for id, c in pairs(controls) do keys[#keys + 1] = id .. "=" .. tostring(Config.val(id, c)) end
	table.sort(keys)
	return table.concat(keys, "|")
end

---- named configurations (the Configuration List on the Settings tab)
Config.index = {}      -- { { name = "...", file = "cfg_....json" }, ... }
Config.auto = false    -- Auto Save Configuration toggle
Config.ready = false   -- true once the saved configuration has been loaded (Auto Save never writes before that)
local INDEX_FILE = "configs_index.json"

-- Loads the list of named configurations.
function Config.loadIndex()
	Config.index = {}
	local raw = Store.read(INDEX_FILE)
	if not raw then return end
	local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok and type(data) == "table" then
		for _, it in ipairs(data) do
			if type(it) == "table" and type(it.name) == "string" and type(it.file) == "string" then
				table.insert(Config.index, { name = it.name, file = it.file })
			end
		end
	end
end

-- Saves the list of named configurations.
function Config.saveIndex()
	Store.write(INDEX_FILE, HttpService:JSONEncode(Config.index))
end

-- Finds a named configuration.
function Config.find(name)
	for _, it in ipairs(Config.index) do
		if it.name:lower() == tostring(name):lower() then return it end
	end
end

-- Saves the current settings under a name.
function Config.saveNamed(name)
	name = trim(tostring(name or "")):sub(1, 40)
	if name == "" then
		local n = #Config.index + 1
		while Config.find("Config " .. n) do n = n + 1 end
		name = "Config " .. n
	end
	local item = Config.find(name)
	if not item then
		item = { name = name, file = "cfg_" .. os.time() .. math.random(100, 999) .. ".json" }
		table.insert(Config.index, item)
	end
	Store.write(item.file, HttpService:JSONEncode(Config.collect()))
	Config.saveIndex()
	if Config.refreshList then Config.refreshList() end
	print("[WORST Hub] Configuration '" .. name .. "' saved.")
	return name
end

-- Loads a named configuration.
function Config.loadNamed(name)
	local item = Config.find(name)
	if not item then return false end
	local raw = Store.read(item.file)
	if not raw then return false end
	local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok or type(data) ~= "table" then return false end
	Config.apply(data)
	print("[WORST Hub] Configuration '" .. item.name .. "' loaded.")
	return true
end

-- Deletes a named configuration.
function Config.delete(name)
	for i, it in ipairs(Config.index) do
		if it.name == name then
			table.remove(Config.index, i)
			if hasFiles and typeof(delfile) == "function" then pcall(delfile, STORE_DIR .. "/" .. it.file) end
			break
		end
	end
	Config.saveIndex()
	if Config.refreshList then Config.refreshList() end
end

-- Auto Save Configuration toggle
function Config.setAuto(on)
	Config.auto = on == true
	if not alive then return end        -- the hub is closing: don't touch the saved state
	Store.write("autosave.txt", on and "1" or "0")
	Config.lastSig = nil                -- save the current state on the next tick
end

-- Starts the auto-save loop (saves when something changed).
function Config.startAutoSave()
	task.spawn(function()
		while alive do
			if Config.auto and Config.ready then
				local ok, sig = pcall(Config.signature)
				if ok and sig ~= Config.lastSig then
					Config.lastSig = sig
					pcall(Config.save, true)
				end
			end
			task.wait(1)
		end
	end)
end

-- ids that were renamed: an old save still loads into the new control
local ID_ALIAS = { ["Kaitun/Kaitun Mode"] = "Kaitun/Kaitun Hatch", ["Kaitun/Kaitun Enchant"] = "Kaitun/Kaitun Stats" }
-- the Settings tab used to be one flat list: "Settings/<name>" is now "Settings/<page>/<name>"
for _, pg in ipairs(TAB_SCRIPTS.Settings.pages or {}) do
	for _, e in ipairs(pg.entries) do
		if e.name then
			ID_ALIAS["Settings/" .. e.name] = "Settings/" .. pg.name .. "/" .. e.name
			ID_ALIAS["Settings/Page 1/" .. e.name] = "Settings/" .. pg.name .. "/" .. e.name   -- pages were called Page 1 / Page 2
			ID_ALIAS["Settings/Page 2/" .. e.name] = "Settings/" .. pg.name .. "/" .. e.name
		end
	end
end

-- Applies a saved configuration to the controls.
function Config.apply(data)
	for _, group in ipairs({ "toggles", "sliders", "dropdowns", "inputs" }) do
		local g = data[group]
		if type(g) == "table" then
			for old, new in pairs(ID_ALIAS) do
				if g[old] ~= nil and g[new] == nil then g[new] = g[old] end
			end
		end
	end
	-- Applies one group (toggles, sliders ...) of a saved configuration.
	local function apply(group, kind)
		for id, v in pairs(data[group] or {}) do
			local c = controls[id]
			if c and c.type == kind then safe(c.set, v) end
		end
	end
	apply("dropdowns", "dropdown") -- first, so a saved egg is selected before a saved Auto Hatch starts
	apply("sliders", "slider")
	apply("inputs", "input")
	apply("toggles", "toggle")
	-- Kaitun Hatch owns the other feature toggles: an older save may still list some as ON - they stay off, Kaitun starts what it needs itself
	for id, v in pairs(Config.override) do
		if v == false then
			local c = controls[id]
			if c and c.type == "toggle" and c.get() then safe(c.set, false) end
		end
	end
	-- buttons are never re-fired from a saved configuration (old files may still list some: ignored)
end

-- Loads the saved configuration at start.
function Config.autoLoad()
	local autoOn = true   -- Auto Save is always on at execute
	local raw = autoOn and Store.read("config.json")
	if raw then
		local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
		if ok and type(data) == "table" then
			Config.apply(data)
			print("[WORST Hub] Saved configuration loaded automatically.")
			-- dropdowns whose option list was not filled yet (eggs / enchants load a moment after the hub): try those again once,
			-- but only the ones you have not touched in the meantime
			local after = {}
			for id, c in pairs(controls) do after[id] = c.get() end
			task.delay(8, function()
				if not alive then return end
				for id, want in pairs(data.dropdowns or {}) do
					local c = controls[id]
					if c and c.type == "dropdown" and c.get() == after[id] and c.get() ~= want then safe(c.set, want) end
				end
			end)
		else
			warn("[WORST Hub] Saved configuration is unreadable, skipping auto-load.")
		end
	end
	Config.ready = true
	pcall(function() Config.lastSig = Config.signature() end)
end

Config.startAutoSave()

for tabName, entries in pairs(TAB_SCRIPTS) do
	if pages[tabName] and (#entries > 0 or entries.pages) then
		buildScriptPage(tabName, entries)
	end
end

-- Home tab: welcome card, Discord button, 4 reserved cards on the right
do
	local page = pages["Home"]
	local DISCORD_LINK = "https://discord.gg/w0rst"   -- put your Discord invite here

	-- HOME IMAGES: put an image in the big center card (hero) and the four right cards (box1 - box4).
	-- Each value can be:  a Roblox image id ("rbxassetid://123456789" or just 123456789)
	--                 or  a direct image link ("https://.../picture.png" - downloaded once, needs writefile + getcustomasset)
	-- Leave "" to keep the normal card.
	local HOME_IMAGES = {
		hero = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRzjD6OIEIALJ0Q0TgFK3aDYZZhwlio0q1mK_NWQcUDgGoq5W1d6BerxHg&s=10",
		box1 = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRzjD6OIEIALJ0Q0TgFK3aDYZZhwlio0q1mK_NWQcUDgGoq5W1d6BerxHg&s=10",
		box2 = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRzjD6OIEIALJ0Q0TgFK3aDYZZhwlio0q1mK_NWQcUDgGoq5W1d6BerxHg&s=10",
		box3 = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRzjD6OIEIALJ0Q0TgFK3aDYZZhwlio0q1mK_NWQcUDgGoq5W1d6BerxHg&s=10",
		box4 = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRzjD6OIEIALJ0Q0TgFK3aDYZZhwlio0q1mK_NWQcUDgGoq5W1d6BerxHg&s=10",
		discord = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRzjD6OIEIALJ0Q0TgFK3aDYZZhwlio0q1mK_NWQcUDgGoq5W1d6BerxHg&s=10",   -- the Discord button (bottom left)
	}
	local HOME_IMAGE_KEEP_TEXT = { discord = true }   -- cards that keep their text / JOIN button on top of the image even when HOME_IMAGE_HIDE_TEXT is true
	local HOME_IMAGE_HIDE_TEXT = true  -- true = image only (text hidden) | false = keep the text on top of the image
	local HOME_IMAGE_DIM = 0.6         -- only used when text is kept: 0 = very dark layer, 1 = no dark layer
	if page then
		label(page, "Home", 322, 119, 30, C.text, Enum.Font.GothamBold)
		local welcomeLbl = label(page, "Welcome back, " .. player.DisplayName, 322, 149, 19, C.sub, Enum.Font.Gotham)
		welcomeLbl.RichText = false
		if FX.names then FX.names.add(welcomeLbl, "Welcome back, " .. player.DisplayName, "Welcome back") end
		frame(page, 322, 179, 1084, 1, C.stroke)

		-- a card with a soft gradient and an accent strip on the left
		local function panel(x, y, w, h, className)
			local f = new(className or "Frame", {
				Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
				BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = CARD_T, BorderSizePixel = 0,
			}, page)
			if className == "TextButton" then f.Text = "" f.AutoButtonColor = false end
			corner(f, UDim.new(0, 16))
			ashStroke(stroke(f, Color3.new(1, 1, 1), 3, 0.05))
			new("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(34, 34, 34), Color3.fromRGB(10, 10, 10)), Rotation = 125,
			}, f)
			local strip = frame(f, 0, 18, 4, h - 36, C.accent)
			corner(strip, UDim.new(1, 0))
			return f
		end

		-- turns whatever the person typed into something an ImageLabel can show (downloads links once)
		local function resolveImage(src)
			src = tostring(src or ""):gsub("^%s+", ""):gsub("%s+$", "")
			if src == "" then return nil end
			if tonumber(src) then return "rbxassetid://" .. src end
			if src:find("^rbxassetid://") or src:find("^rbxasset://") or src:find("^rbxthumb://") then return src end
			local id = src:match("roblox%.com/asset/?%?id=(%d+)")
			if id then return "rbxassetid://" .. id end
			if src:find("^https?://") then
				local getAsset = getcustomasset or getsynasset
				if not (hasFiles and getAsset) then
					warn("[WORST Hub] Home image links need writefile + getcustomasset - use a Roblox image id instead.")
					return nil
				end
				local hash = 5381
				for i = 1, #src do hash = (hash * 33 + src:byte(i)) % 4294967296 end
				local path = STORE_DIR .. "/home_" .. hash .. ".png"
				if not isfile(path) then
					local ok, data = pcall(function() return game:HttpGet(src) end)
					if ok and type(data) == "string" and #data > 100 then
						pcall(function()
							if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(STORE_DIR) then makefolder(STORE_DIR) end
							writefile(path, data)
						end)
					else
						warn("[WORST Hub] Couldn't download the home image: " .. src)
						return nil
					end
				end
				local okA, asset = pcall(getAsset, path)
				if okA then return asset end
				return nil
			end
			warn("[WORST Hub] Unknown home image value: " .. src)
			return nil
		end

		-- puts the picture inside a card (rounded, behind the text)
		local function applyImage(card, key)
			local src = HOME_IMAGES[key]
			if not src or src == "" then return end
			task.spawn(function()
				local asset = resolveImage(src)
				if not (asset and alive and card.Parent) then return end
				local img = new("ImageLabel", {
					Name = "HomeImage", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = asset,
					ScaleType = Enum.ScaleType.Crop, ZIndex = 0, BorderSizePixel = 0,
				}, card)
				corner(img, UDim.new(0, 16))
				if HOME_IMAGE_HIDE_TEXT and not HOME_IMAGE_KEEP_TEXT[key] then
					for _, ch in ipairs(card:GetChildren()) do
						if ch:IsA("GuiObject") and ch ~= img then ch.Visible = false end
					end
				else
					corner(new("Frame", {
						Name = "HomeImageDim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
						BackgroundTransparency = HOME_IMAGE_DIM, BorderSizePixel = 0, ZIndex = 0,
					}, card), UDim.new(0, 16))
				end
			end)
		end

		-- cards that slide in: left side from the left, right column from the right
		local slideLeft, slideRight = {}, {}

		-- welcome card (left)
		local hero = panel(322, 201, 520, 420)
		slideLeft[#slideLeft + 1] = hero
		-- HERO: empty card on purpose - put your picture in HOME_IMAGES.hero (top of this block)
		applyImage(hero, "hero")

		-- 4 slots (right column): empty backdrops. The live cooldown cards (see below) slide / fade over them.
		record.homeIdle = {}
		for i = 0, 3 do
			local card = panel(870, 201 + i * 148, 536, 128)
			card.Name = "HomeBox" .. (i + 1)
			slideRight[#slideRight + 1] = card
			local idle = label(card, "Nothing on cooldown", 268, 64, 18, Color3.fromRGB(95, 95, 95), Enum.Font.Gotham, Enum.TextXAlignment.Center)
			idle.Size = UDim2.fromOffset(340, 28)
			record.homeIdle[i + 1] = idle
			local num = label(card, string.format("%02d", i + 1), 506, 64, 40, Color3.fromRGB(70, 70, 70), Enum.Font.GothamBlack, Enum.TextXAlignment.Right)
			num.Size = UDim2.fromOffset(120, 50)
			applyImage(card, "box" .. (i + 1))
		end

		-- Discord button (bottom left)
		local dc = panel(322, 641, 520, 150, "TextButton")
		dc.Name = "DiscordButton"
		slideLeft[#slideLeft + 1] = dc
		applyImage(dc, "discord")
		badge(dc, nil, "D", 60, 75, 58)
		local dcTitle = label(dc, "Join our Discord", 108, 58, 22, C.text, Enum.Font.GothamBold)
		local dcSub = label(dc, "Press to join our discord server", 108, 92, 16, C.sub, Enum.Font.Gotham)
		dcSub.Size = UDim2.fromOffset(300, 24)
		local pillBtn = frame(dc, 400, 52, 96, 44, SEL_BG)
		corner(pillBtn, UDim.new(0, 12))
		stroke(pillBtn, Color3.fromRGB(150, 150, 150), 1)
		local pillTxt = label(pillBtn, "JOIN", 48, 22, 17, Color3.new(1, 1, 1), Enum.Font.GothamBold, Enum.TextXAlignment.Center)
		pillTxt.Size = UDim2.fromOffset(96, 28)
		dc.MouseEnter:Connect(function()
			tween(dc, { BackgroundTransparency = CARD_T - 0.15 })
			tween(pillBtn, { BackgroundColor3 = Color3.fromRGB(75, 75, 75) })
		end)
		dc.MouseLeave:Connect(function()
			tween(dc, { BackgroundTransparency = CARD_T })
			tween(pillBtn, { BackgroundColor3 = SEL_BG })
		end)
		-- Home intro: Hero + Discord slide in from the left, the 3(4) boxes slide in from the right, one after another.
		-- Runs every time the Home tab is opened (and once at start). Page clipping hides the cards while they are outside.
		local SLIDE_DIST   = 700    -- how far outside they start (px)
		local SLIDE_TIME   = 0.65   -- seconds per card
		local SLIDE_STAGGER = 0.09  -- delay between cards
		-- the opening animation draws the cards in this order: welcome card, the 4 boxes, Discord button
		record.homeCards = { slideLeft[1], slideRight[1], slideRight[2], slideRight[3], slideRight[4], slideLeft[2] }
		local home = {}
		for _, c in ipairs(slideLeft) do home[c] = c.Position end
		for _, c in ipairs(slideRight) do home[c] = c.Position end
		local introRun = 0
		-- Plays the intro animation of the Home page.
		local function playIntro()
			if not (alive and page.Parent) then return end
			introRun = introRun + 1
			local my = introRun
			for c, pos in pairs(home) do   -- park everything outside first
				local dir = table.find(slideLeft, c) and -1 or 1
				c.Position = pos + UDim2.fromOffset(dir * SLIDE_DIST, 0)
			end
			local info = TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			-- Animates a list of Home cards one after another.
			local function go(list, delay0)
				for i, c in ipairs(list) do
					task.delay(delay0 + (i - 1) * SLIDE_STAGGER, function()
						if my ~= introRun or not c.Parent then return end
						TweenService:Create(c, info, { Position = home[c] }):Play()
					end)
				end
			end
			go(slideLeft, 0)      -- Hero first, then Discord
			go(slideRight, 0.05)  -- boxes from the right
			task.delay(SLIDE_TIME + 0.6, function()   -- safety: make sure everything ends exactly at home
				if my ~= introRun then return end
				for c, pos in pairs(home) do if c.Parent then c.Position = pos end end
			end)
		end
		-- ---------------------------------------------------------------- Discord card: [Ping] [FPS] [Executor] + "Press to join"
		task.spawn(function()
			local RunService = game:GetService("RunService")
			dcTitle.Position = UDim2.fromOffset(108, 30)
			dcSub.Position = UDim2.fromOffset(108, 124)
			dcSub.Size = UDim2.fromOffset(380, 24)
			pillBtn.Visible = false   -- the whole card is the button now
			-- Draws a small label chip.
			local function chip(x, w, txt)
				local f = frame(dc, x, 62, w, 34, SEL_BG)
				corner(f, UDim.new(0, 10))
				stroke(f, Color3.fromRGB(110, 110, 110), 1)
				local l = label(f, txt, w / 2, 17, 15, Color3.new(1, 1, 1), Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
				l.Size = UDim2.fromOffset(w - 8, 24)
				l.RichText = false
				l.TextTruncate = Enum.TextTruncate.AtEnd
				return l
			end
			local pingLbl = chip(108, 104, "Ping ...")
			local fpsLbl = chip(220, 104, "FPS ...")
			local exec = "Unknown"
			if typeof(identifyexecutor) == "function" then
				local ok, n = pcall(identifyexecutor)
				if ok and n then exec = tostring(n) end
			end
			chip(332, 172, "Executor: " .. exec)

			local frames, acc, fps = 0, 0, 0
			connect(RunService.Heartbeat, function(dt)
				frames = frames + 1
				acc = acc + dt
				if acc >= 0.5 then
					fps = math.floor(frames / acc + 0.5)
					frames, acc = 0, 0
				end
			end)
			-- Reads your ping.
			local function getPing()
				local ok, v = pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
				if ok and tonumber(v) then return math.floor(v + 0.5) end
				local ok2, p = pcall(function() return player:GetNetworkPing() * 2000 end)
				if ok2 and tonumber(p) then return math.floor(p + 0.5) end
				return nil
			end
			while alive and dc.Parent do
				if page.Visible then
					local p = getPing()
					pingLbl.Text = p and ("Ping " .. p .. " ms") or "Ping --"
					fpsLbl.Text = "FPS " .. fps
				end
				task.wait(0.5)
			end
		end)

		-- ---------------------------------------------------------------- 4 boxes: what the script is doing, in order
		-- 1 = running right now, 2 = next, 3 = after that (waits for 2), 4 = after 3. Built from the Priority system: the feature that holds the
		-- machine (or the hatch when it is hatching), then features queued for the machine, then switched-on features that are ready, then the
		-- ones sitting on a cooldown (soonest first). Cards slide up / fade out / fade in when the queue changes.
		task.spawn(function()
			local PAD, STEP, CARD_H = 10, 148, 128
			local FADE_T, SLIDE_T = 0.5, 0.4
			local ROLE = { "DOING NOW", "UP NEXT", "THEN", "AFTER THAT", "LATER" }
			local DEFAULT_ORDER = { "DoubleJump", "Balloon", "Craft", "TrickOrTreat", "HallowLord", "PetDefense", "Dig", "Hatch" }
			local KIND_NAMES = {
				DoubleJump = { "Auto Double Jump" }, Balloon = { "Auto Balloons" },
				Craft = { "Auto Craft", "Craft to Diamond", "Craft to Rainbow", "Collect Rainbow" },
				TrickOrTreat = { "Auto Halloween Trick or Treat" }, HallowLord = { "Auto Kill Boss" },
				PetDefense = { "Auto Pet Defense" }, Dig = { "Auto Dig" }, Hatch = { "Auto Hatch" },
			}
			local TITLE = {
				DoubleJump = "Auto Double Jump", Balloon = "Auto Balloons", Craft = "Auto Craft", TrickOrTreat = "Trick or Treat",
				HallowLord = "Hallow Lord", PetDefense = "Pet Defense", Dig = "Dig Event", Hatch = "Auto Hatch",
			}
			local GLYPH = { DoubleJump = "◆", Balloon = "🎈", Craft = "✨", TrickOrTreat = "🎃", HallowLord = "☠", PetDefense = "🛡", Dig = "🪏", Hatch = "🥚" }
			local KEYS = { "next", " in ", "wait", "cooldown", "left", "retry", "refill", "check" }

			-- Removes tags and spaces from a text.
			local function plain(t) return ((tostring(t or ""):gsub("<[^>]+>", ""))) end
			-- Reads a time text (like "1h 5m") as seconds.
			local function parseSecs(text)
				local l = " " .. plain(text):lower()
				local hit = false
				for _, k in ipairs(KEYS) do if l:find(k, 1, true) then hit = true break end end
				if not hit then return nil end
				local h, m, sec = l:match("(%d+):(%d+):(%d+)")
				if h then return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(sec) end
				m, sec = l:match("(%d+):(%d%d)")
				if m then return tonumber(m) * 60 + tonumber(sec) end
				local total, found = 0, false
				-- Reads one unit of the time text.
				local function unit(pat, mul)
					local n = l:match(pat)
					if n then total = total + tonumber(n) * mul found = true end
				end
				unit("(%d+)%s*h[ou]*r*s?%f[%A]", 3600)
				unit("(%d+)%s*min%a*", 60)
				unit("(%d+)%s*m%f[%A]", 60)
				unit("(%d+)%s*sec%a*", 1)
				unit("(%d+)%s*s%f[%A]", 1)
				return found and total or nil
			end
			-- Formats seconds as a time text.
			local function fmt(sec)
				sec = math.max(0, math.ceil(sec))
				if sec >= 3600 then return string.format("%d:%02d:%02d", sec // 3600, (sec % 3600) // 60, sec % 60) end
				return string.format("%02d:%02d", sec // 60, sec % 60)
			end
			-- trip-owner / waiting names used by the Priority system -> kind
			local function toKind(n)
				n = tostring(n or "")
				if n == "Halloween" then return "TrickOrTreat" end
				if n == "HalloweenBoss" then return "HallowLord" end
				if n:find("Craft") or n:find("Rainbow") or n:find("Diamond") then return "Craft" end
				if TITLE[n] then return n end
				return nil
			end

			-- every toggle by name
			local byName = {}
			for _, tabName in ipairs({ "Farming", "Pets", "Events" }) do
				local t = TAB_SCRIPTS[tabName]
				local lists = {}
				if t and t.pages then
					for _, pgx in ipairs(t.pages) do lists[#lists + 1] = pgx.entries end
				elseif t then
					lists[1] = t
				end
				for _, list in ipairs(lists) do
					for _, e in ipairs(list or {}) do
						if type(e) == "table" and e.type == "toggle" and e._get and e._desc and e.name then byName[e.name] = e end
					end
				end
			end

			local stack = new("Frame", {
				Name = "HomeQueue", Position = UDim2.fromOffset(870, 201), Size = UDim2.fromOffset(536, 572),
				BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3,
			}, page)
			-- Returns the slot position of a Home item.
			local function slotPos(i) return UDim2.fromOffset(-PAD, (i - 1) * STEP - PAD) end
			-- Plays a tween with its own style and direction.
			local function tw(obj, props, t, style, dir)
				TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props):Play()
			end

			-- Builds one Home card.
			local function makeCard(kind)
				local wrap = new("CanvasGroup", {   -- wrapper fades (GroupTransparency); PAD keeps the card border from being clipped
					Size = UDim2.fromOffset(536 + PAD * 2, CARD_H + PAD * 2), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2,
				}, stack)
				local c = panel(PAD, PAD, 536, CARD_H)
				c.BackgroundTransparency = 0.04
				c.Parent = wrap
				badge(c, nil, GLYPH[kind] or "•", 56, 64, 52)
				local role = label(c, "", 100, 28, 13, C.sub, Enum.Font.GothamBold)
				role.Size = UDim2.fromOffset(240, 20)
				role.RichText = false
				local title = label(c, TITLE[kind] or kind, 100, 58, 24, C.text, Enum.Font.GothamBold)
				title.Size = UDim2.fromOffset(300, 30)
				title.RichText = false
				local sub = label(c, "", 100, 92, 15, C.sub, Enum.Font.Gotham)
				sub.Size = UDim2.fromOffset(400, 22)
				sub.RichText = false
				sub.TextTruncate = Enum.TextTruncate.AtEnd
				local timer = label(c, "", 512, 40, 28, C.text, Enum.Font.GothamBlack, Enum.TextXAlignment.Right)
				timer.Size = UDim2.fromOffset(170, 36)
				timer.RichText = false
				return { wrap = wrap, role = role, sub = sub, timer = timer, slot = nil }
			end

			local st, cards = {}, {}   -- st[kind] = { text, untilAt }
			-- Builds the list of items to show on the Home page.
			local function build(now)
				local prio = Logic and Logic.priority
				local order = (prio and prio.order) or DEFAULT_ORDER
				local info = {}
				for _, kind in ipairs(order) do
					local on, text = false, ""
					for _, n in ipairs(KIND_NAMES[kind] or {}) do
						local e = byName[n]
						if e then
							local isOn = false
							pcall(function() isOn = e._get() == true end)
							if isOn then
								on = true
								local t = (e._desc and e._desc.Parent) and e._desc.Text or ""
								if text == "" then text = t end
							end
						end
					end
					if on then
						local s = st[kind]
						if not s then s = { text = "", untilAt = 0 } st[kind] = s end
						if text ~= s.text then
							s.text = text
							local secs = parseSecs(text)
							s.untilAt = (secs and secs > 0) and (now + secs) or 0
						end
						local blocked = plain(text):find("^%[Priority%]") ~= nil
						info[kind] = { text = text, left = (not blocked) and (s.untilAt - now) or 0, blocked = blocked }
					else
						st[kind] = nil
					end
				end

				local list, used = {}, {}
				-- Adds an item to the list.
				local function add(k) if info[k] and not used[k] then used[k] = true list[#list + 1] = k end end
				local hasNow = false
				local ownerKind = prio and prio.owner and toKind(prio.owner())
				if ownerKind and info[ownerKind] then
					add(ownerKind) hasNow = true
				elseif prio and prio.isHatching and prio.isHatching() and info.Hatch then
					add("Hatch") hasNow = true
				end
				if prio and prio.waiting then   -- queued for the machine, best rank first
					local q = {}
					for n, rank in pairs(prio.waiting) do
						local k = toKind(n)
						if k then q[#q + 1] = { k = k, r = tonumber(rank) or 99 } end
					end
					table.sort(q, function(a, b) if a.r ~= b.r then return a.r < b.r end return a.k < b.k end)
					for _, it in ipairs(q) do add(it.k) end
				end
				for _, k in ipairs(order) do   -- switched on and ready, in priority order
					if info[k] and info[k].left <= 0.05 then add(k) end
				end
				local cd = {}
				for _, k in ipairs(order) do if info[k] and not used[k] then cd[#cd + 1] = k end end
				table.sort(cd, function(a, b)
					if math.floor(info[a].left) ~= math.floor(info[b].left) then return info[a].left < info[b].left end
					return a < b
				end)
				for _, k in ipairs(cd) do add(k) end
				return list, info, hasNow
			end

			-- Draws the Home page list.
			local function render(now)
				local list, info, hasNow = build(now)
				local want, inSet = {}, {}
				for i = 1, math.min(#list, 4) do want[i] = list[i] inSet[list[i]] = true end

				-- 1) a task that left the queue fades out where it is while the others slide up over it
				for k, cd in pairs(cards) do
					if not inSet[k] then
						cards[k] = nil
						cd.wrap.ZIndex = 1
						tw(cd.wrap, { GroupTransparency = 1 }, FADE_T, Enum.EasingStyle.Quad)
						task.delay(FADE_T + 0.05, function() if cd.wrap.Parent then cd.wrap:Destroy() end end)
					end
				end
				-- 2) the others move to their new slot (slide ends before the fade does); a new task fades in at its slot
				for i, k in ipairs(want) do
					local cd = cards[k]
					if not cd then
						cd = makeCard(k)
						cards[k] = cd
						cd.slot = i
						cd.wrap.Position = slotPos(i) + UDim2.fromOffset(0, 18)
						cd.wrap.GroupTransparency = 1
						tw(cd.wrap, { GroupTransparency = 0, Position = slotPos(i) }, FADE_T)
					elseif cd.slot ~= i then
						cd.slot = i
						tw(cd.wrap, { Position = slotPos(i) }, SLIDE_T)
					end
					cd.wrap.ZIndex = 2
				end
				-- 3) texts + empty-slot hints
				if page.Visible then
					for k, cd in pairs(cards) do
						local inf = info[k]
						if inf and cd.slot then
							local idx = cd.slot + (hasNow and 0 or 1)
							cd.role.Text = ROLE[math.min(idx, #ROLE)]
							cd.role.TextColor3 = (hasNow and cd.slot == 1) and Color3.new(1, 1, 1) or C.sub
							local txt = plain(inf.text):gsub("^%[Priority%]%s*", "")
							cd.sub.Text = txt ~= "" and txt or "Waiting for its turn..."
							cd.timer.Text = inf.left > 0.05 and fmt(inf.left) or ""
						end
					end
				end
				for i, idle in ipairs(record.homeIdle or {}) do
					if idle.Parent then
						idle.Text = (#want == 0 and i == 1) and "Idle - nothing is running" or "Nothing queued"
						local goal = (i <= #want) and 1 or 0.35
						if math.abs(idle.TextTransparency - goal) > 0.01 then tw(idle, { TextTransparency = goal }, 0.3, Enum.EasingStyle.Quad) end
					end
				end
			end

			-- Home intro: keep the cards hidden while the 4 slots fly in, then fade them in
			local introRun = 0
			record.homeStackHide = function()
				introRun = introRun + 1
				local my = introRun
				stack.Visible = false
				task.delay(0.85, function()
					if my ~= introRun or not stack.Parent then return end
					for _, cd in pairs(cards) do cd.wrap.GroupTransparency = 1 end
					stack.Visible = true
					for _, cd in pairs(cards) do tw(cd.wrap, { GroupTransparency = 0 }, 0.35, Enum.EasingStyle.Quad) end
				end)
			end

			local warnedOnce = false
			while alive and page.Parent do
				local ok, err = pcall(render, os.clock())
				if not ok and not warnedOnce then
					warnedOnce = true
					warn("[WORST Hub] Home queue boxes: " .. tostring(err))
				end
				task.wait(0.25)
			end
		end)

		record.homeIntro = function()
			if record.homeStackHide then record.homeStackHide() end
			playIntro()
		end
		task.defer(record.homeIntro)
		local token = 0
		-- Opens the invite in the Discord desktop app: Discord listens for local requests on ports 6463-6472 and an INVITE_BROWSER
		-- command makes it show the "join this server" screen. Needs Discord running on this computer and an executor with request().
		-- Returns true when Discord accepted it, false when it could not be reached (then the link is copied instead).
		local function inviteCode(link)
			link = tostring(link)
			return link:match("discord%.gg/([%w%-_]+)") or link:match("discord%.com/invite/([%w%-_]+)")
		end
		-- Opens a Discord invite link.
		local function openInDiscord(link)
			local code = inviteCode(link)
			local req = (typeof(request) == "function" and request) or (typeof(http_request) == "function" and http_request)
				or (syn and typeof(syn.request) == "function" and syn.request) or nil
			if not (code and req) then return false end
			local body = HttpService:JSONEncode({ cmd = "INVITE_BROWSER", args = { code = code }, nonce = HttpService:GenerateGUID(false) })
			for port = 6463, 6472 do
				local ok, res = pcall(req, {
					Url = "http://127.0.0.1:" .. port .. "/rpc?v=1", Method = "POST",
					Headers = { ["Content-Type"] = "application/json", ["Origin"] = "https://discord.com" },
					Body = body,
				})
				if ok and type(res) == "table" and (res.StatusCode == 200 or res.Success == true) then return true end
			end
			return false
		end
		dc.MouseButton1Click:Connect(function()
			token = token + 1
			local my = token
			dcSub.Text = "Opening Discord..."
			pillTxt.Text = "..."
			task.spawn(function()
				local opened = openInDiscord(DISCORD_LINK)
				local copied = false
				if not opened and typeof(setclipboard) == "function" then   -- Discord not running / not reachable: fall back to copying the link
					copied = pcall(setclipboard, DISCORD_LINK)
				end
				if token ~= my or not dcSub.Parent then return end
				if opened then
					dcSub.Text = "Opening Discord - accept the invite there!"
					pillTxt.Text = "OPENED"
				else
					dcSub.Text = copied and "Discord not found - invite copied, paste it in your browser!" or DISCORD_LINK
					pillTxt.Text = copied and "COPIED" or "LINK"
				end
				task.delay(3, function()
					if token == my and dcSub.Parent then
						dcSub.Text = "Press to join our discord server"
						pillTxt.Text = "JOIN"
					end
				end)
			end)
		end)
	end
end

-- Kaitun tab: what the two toggles do (ticks light up while the toggle is on)
do
	local page = pages["Kaitun"]
	local kt = Logic and Logic.kaitun
	if page then
		local klist = Config.pageLists.Kaitun
		local card
		if klist then   -- last row of the Kaitun list: scrolls with the rows instead of floating over them
			card = new("Frame", {
				Name = "KaitunInfoCard", LayoutOrder = 1000, Size = UDim2.fromOffset(1066, 800),
				BackgroundColor3 = C.card, BackgroundTransparency = CARD_T, BorderSizePixel = 0,
			}, klist)
		else
			card = frame(page, 323, 395, 1080, 800, C.card, CARD_T)
		end
		corner(card, UDim.new(0, 14))
		stroke(card, C.stroke, 1)
		frame(card, 0, 90, 1066, 1, C.stroke)
		frame(card, 533, 112, 1, 312, C.stroke)

		local checksL, checksR, checksS = {}, {}, {}
		-- (helpers are kept as fields of checksL so this block adds no local variables to the script)
		function checksL.skipped(key) return kt and kt.skip and kt.skip[key] == true end
		-- Paints one checklist item (on / skipped).
		function checksL.paint(e, masterOn)
			local sk = checksL.skipped(e.key)
			e.frame.BackgroundColor3 = (masterOn and not sk) and Color3.fromRGB(70, 160, 90) or OFF_COLOR
			e.glyph.Text = sk and "✕" or "✓"          -- ✕ = this part is switched off (click the check to switch it back on)
			e.title.TextColor3 = sk and Color3.fromRGB(105, 105, 105) or C.text
		end
		-- Returns whether a group is on.
		function checksL.state(group)
			if group == checksL then return kt and kt.main and kt.main._get and kt.main._get() or false end
			if group == checksS then   -- Kaitun Stats parts only run while Kaitun Hatch is on too
				return (kt and kt.enchant and kt.enchant._get and kt.enchant._get() or false) and (kt and kt.main and kt.main._get and kt.main._get() or false) and true or false
			end
			return kt and kt.second and kt.second._get and kt.second._get() or false
		end
		-- Builds one checklist row on the Home page.
		local function item(group, key, x, cx, y, n, title, line1, line2)
			label(card, n .. ".)", x, y + 14, 19, C.sub, Enum.Font.GothamMedium)
			local titleLbl = label(card, title, x + 44, y + 4, 19, C.text, Enum.Font.GothamMedium)
			label(card, line1, x + 44, y + 30, 16, C.sub, Enum.Font.Gotham)
			label(card, line2, x + 44, y + 52, 16, C.sub, Enum.Font.Gotham)
			local c = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, y + 14), Size = UDim2.fromOffset(26, 26),
				BackgroundColor3 = OFF_COLOR, BorderSizePixel = 0,
			}, card)
			corner(c, UDim.new(1, 0))
			local glyph = new("TextLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "✓",
				TextColor3 = Color3.new(1, 1, 1), TextSize = 17, Font = Enum.Font.GothamBold,
			}, c)
			local rec = { frame = c, glyph = glyph, title = titleLbl, key = key }
			group[#group + 1] = rec
			-- click the check: that part of Kaitun is switched off (right now if Kaitun is running) / on again
			local ring = stroke(c, Color3.new(1, 1, 1), 1.5, 1)
			local btn = new("TextButton", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
			}, c)
			btn.MouseEnter:Connect(function() tween(ring, { Transparency = 0.25 }) end)
			btn.MouseLeave:Connect(function() tween(ring, { Transparency = 1 }) end)
			btn.MouseButton1Click:Connect(function()
				if not (kt and kt.setSkip) then return end
				kt.setSkip(key, not checksL.skipped(key))
				checksL.paint(rec, checksL.state(group))
			end)
		end

		label(card, "Tip: click a check to switch that part off (✕) - click it again to switch it back on.", 28, 432, 14, C.sub, Enum.Font.Gotham)

		-- left: Kaitun Hatch
		label(card, "What Kaitun Hatch does", 28, 34, 24, C.text, Enum.Font.GothamMedium)
		label(card, "Runs your whole setup by itself while it is on.", 28, 62, 16, C.sub, Enum.Font.Gotham)
		item(checksL, "delete", 28, 500, 112, 1, "Auto Delete Pets", "Common to Legendary, Normal to Rainbow,", "on every island.")
		item(checksL, "hatch", 28, 500, 192, 2, "Auto Hatch + Auto Craft", "Hatches the latest detected egg and crafts Golden,", "Diamond and Rainbow, then collects Rainbow.")
		item(checksL, "afk", 28, 500, 272, 3, "Anti AFK, Auto Rejoin, Status", "Switched on too. Everything runs in the", "order set in the Priority tab.")

		-- right: Kaitun Events
		label(card, "What Kaitun Events does", 583, 34, 24, C.text, Enum.Font.GothamMedium)
		label(card, "Starts these by itself and shows live numbers.", 583, 62, 16, C.sub, Enum.Font.Gotham)
		item(checksR, "chest", 583, 1037, 112, 1, "Auto Chest Coins", "Claims the Sky Island and Desert coin", "chests whenever they are ready.")
		item(checksR, "treat", 583, 1037, 192, 2, "Auto Trick or Treat", "Collects every house on the Halloween island,", "then waits for the houses to refill.")
		item(checksR, "boss", 583, 1037, 272, 3, "Auto Kill Hallow Boss", "Fights the Hallow Lord when it shows up.", "")
		item(checksR, "shop", 583, 1037, 352, 4, "Auto Purchase Items", "Buys every Halloween shop item,", "checking the shop once every hour.")

		-- middle, below both columns: Kaitun Stats
		frame(card, 0, 462, 1066, 1, C.stroke)
		local enchTitle = label(card, "What Kaitun Stats does", 533, 496, 24, C.text, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
		label(card, "Needs Kaitun Hatch. Equips + rebirths, and enchants while you are hatching.", 533, 524, 16, C.sub, Enum.Font.Gotham, Enum.TextXAlignment.Center)
		label(card, "1.)  Your equipped pets", 533, 566, 19, C.text, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
		label(card, "Two Four-Leaf, two Secret Hunter, remaining Lucky III; one matching slot per pet.", 533, 592, 16, C.sub, Enum.Font.Gotham, Enum.TextXAlignment.Center)
		label(card, "2.)  The pets Richest equips before a rebirth", 533, 634, 19, C.text, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
		label(card, "Renewal 3, once your equipped pets have their enchants.", 533, 660, 16, C.sub, Enum.Font.Gotham, Enum.TextXAlignment.Center)
		item(checksS, "rebirth", 283, 783, 700, 3, "Auto Equip + Auto Rebirth", "Luckiest pets while hatching, Richest pets right before each rebirth,", "rebirths with the Best amount you can afford.")
		label(card, "If Kaitun Hatch is off, a pop up asks you to run it first and the toggle switches itself off again.", 533, 776, 14, C.sub, Enum.Font.Gotham, Enum.TextXAlignment.Center)

		task.spawn(function()
			while alive and card.Parent do
				local enchOn = kt and kt.enchant and kt.enchant._get and kt.enchant._get() or false
				enchTitle.TextColor3 = enchOn and Color3.fromRGB(110, 200, 130) or C.text
				local hatchOn = kt and kt.main and kt.main._get and kt.main._get() or false
				local statsOn = kt and kt.second and kt.second._get and kt.second._get() or false
				for _, e in ipairs(checksL) do checksL.paint(e, hatchOn) end
				for _, e in ipairs(checksR) do checksL.paint(e, statsOn) end
				for _, e in ipairs(checksS) do checksL.paint(e, checksL.state(checksS)) end
				task.wait(0.25)
			end
		end)
	end
end

-- Pop up used by Kaitun Stats ("Run Kaitun Hatch First"). onClose runs once, when the pop up is closed (Kaitun Stats switches itself off there).
do
	local pop = nil
	Config.kaitunPopup = function(title, sub, onClose)
		if pop and pop.Parent then pop:Destroy() end
		local f = new("Frame", {
			Name = "KaitunPopup", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(400, 176), BackgroundColor3 = C.window, BorderSizePixel = 0, ZIndex = 400, Active = true,
		}, gui)
		pop = f
		corner(f, UDim.new(0, 18))
		stroke(f, Color3.fromRGB(200, 200, 200), 1.5)
		new("TextLabel", {
			Position = UDim2.fromOffset(0, 18), Size = UDim2.fromOffset(400, 34), BackgroundTransparency = 1, Text = title,
			TextColor3 = C.text, TextSize = 24, Font = Enum.Font.GothamBold, ZIndex = 401,
		}, f)
		new("TextLabel", {
			Position = UDim2.fromOffset(20, 58), Size = UDim2.fromOffset(360, 44), BackgroundTransparency = 1, Text = sub or "",
			TextColor3 = C.sub, TextSize = 15, Font = Enum.Font.Gotham, TextWrapped = true, ZIndex = 401,
		}, f)
		local ok = new("TextButton", {
			Position = UDim2.fromOffset(140, 116), Size = UDim2.fromOffset(120, 40), BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BorderSizePixel = 0, AutoButtonColor = false, Text = "Close", TextColor3 = C.text, TextSize = 18, Font = Enum.Font.GothamBold, ZIndex = 401,
		}, f)
		corner(ok, UDim.new(0, 12))
		stroke(ok, C.stroke, 1)
		ok.MouseButton1Click:Connect(function()
			if f.Parent then f:Destroy() end
			if pop == f then pop = nil end
			if onClose then safe(onClose) end
		end)
		table.insert(cleanupHooks, function() if f.Parent then f:Destroy() end end)
	end
end

-- Priority tab: the order the features run in (Move Up / Move Down), saved between sessions
do
	local page = pages["Priority"]
	local prio = Logic and Logic.priority
	if page then
		label(page, "Priority", 322, 119, 30, C.text, Enum.Font.GothamBold)
		label(page, "Top of the list runs first. A feature waits while anything above it is working.", 322, 149, 19, C.sub, Enum.Font.Gotham)
		frame(page, 322, 179, 1084, 1, C.stroke)

		local ROW_H, GAP = 84, 14
		local STEP = ROW_H + GAP
		local order = prio and prio.order or { "DoubleJump", "Balloon", "Craft", "TrickOrTreat", "HallowLord", "PetDefense", "Dig", "Hatch" }

		local list = new("ScrollingFrame", {
			Position = UDim2.fromOffset(322, 201), Size = UDim2.fromOffset(1084, 640),
			BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
			ScrollBarImageColor3 = C.stroke, CanvasSize = UDim2.fromOffset(0, #order * STEP),
			ScrollingDirection = Enum.ScrollingDirection.Y,
		}, page)

		local INFO = {
			Craft   = { icon = "✨", desc = "Auto Craft, Craft to Diamond, Craft to Rainbow and Collect Rainbow" },
			DoubleJump = { icon = "🐇", name = "Auto Double Jump", desc = "Events > Skills: visits a Jump Machine before buying upgrades" },
			TrickOrTreat = { icon = "🎃", name = "Auto Trick or Treat", desc = "Events > Halloween: Auto Halloween Trick or Treat" },
			HallowLord   = { icon = "💀", name = "Auto Kill Hallow Lord", desc = "Events > Halloween: Auto Kill Boss (the Hallow Lord, every hour)" },
			Balloon = { icon = "🎈", name = "Auto Balloons", desc = "Events > Balloons: Auto Balloons (teleports to the balloons and pops them)" },
            PetDefense = { icon = "🛡", name = "Auto Pet Defense", desc = "Events > General: fights until natural loss, claims ring, returns from arena" },
		Dig     = { icon = "🪏", name = "Auto Dig", desc = "Events > Dig: Auto Dig (Autumn, 10 digs per hour)" },
		Hatch   = { icon = "🥚", desc = "Auto Hatch" },
		}

		local rows = {}          -- kind -> { frame, title, up, down }
		local dragging = nil     -- { kind, startMouseY, startY }

		-- Returns the position of a feature in the priority list.
		local function indexOf(kind)
			for i, k in ipairs(order) do if k == kind then return i end end
		end
		-- Returns the y position of a priority slot.
		local function slotY(i) return (i - 1) * STEP end

		-- Builds a button of a priority row.
		local function makeButton(row, text, x, onClick)
			local btn = new("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(x, 42), Size = UDim2.fromOffset(130, 38),
				BackgroundColor3 = FIELD, AutoButtonColor = false, Text = text,
				TextColor3 = Color3.fromRGB(95, 95, 95), TextSize = 16, Font = Enum.Font.GothamMedium,
			}, row)
			corner(btn, UDim.new(0, 14))
			stroke(btn, C.stroke, 1)
			local enabled = false
			btn.MouseEnter:Connect(function() if enabled then tween(btn, { BackgroundColor3 = Color3.fromRGB(70, 70, 70) }) end end)
			btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = enabled and SEL_BG or FIELD }) end)
			btn.MouseButton1Click:Connect(function() if enabled then onClick() end end)
			return function(e)
				enabled = e
				btn.BackgroundColor3 = e and SEL_BG or FIELD
				btn.TextColor3 = e and Color3.new(1, 1, 1) or Color3.fromRGB(95, 95, 95)
			end
		end

		-- numbers, button states and (animated) position of one row
		local function refreshRow(kind, animate)
			local r = rows[kind]
			local i = indexOf(kind)
			if not (r and i) then return end
			r.title.Text = string.format("%d.)  %s", i, (INFO[kind] and INFO[kind].name) or kind)
			r.setUp(i > 1)
			r.setDown(i < #order)
			if dragging and dragging.kind == kind then return end -- the row under your finger follows it instead
			local pos = UDim2.fromOffset(0, slotY(i))
			if animate then tween(r.frame, { Position = pos }, 0.22) else r.frame.Position = pos end
		end
		-- Lays out all priority rows.
		local function layout(animate)
			for kind in pairs(rows) do refreshRow(kind, animate) end
		end

		-- Moves a priority row up or down.
		local function swap(i, delta)
			if prio then return prio.move(i, delta) end
			local to = i + delta
			if to < 1 or to > #order then return false end
			order[i], order[to] = order[to], order[i]
			return true
		end

		for i, kind in ipairs(order) do
			local info = INFO[kind] or { icon = "🔹", desc = "" }
			local row = new("Frame", {
				Position = UDim2.fromOffset(0, slotY(i)), Size = UDim2.fromOffset(1066, ROW_H), BackgroundColor3 = C.card,
				BackgroundTransparency = CARD_T, BorderSizePixel = 0,
			}, list)
			corner(row, UDim.new(0, 20))
			stroke(row, C.stroke, 1)
			badge(row, nil, info.icon, 48, 42, 48)
			local title = label(row, "", 92, 30, 19, C.text, Enum.Font.GothamMedium)
			label(row, info.desc, 92, 57, 16, C.sub, Enum.Font.Gotham)

			local r = { frame = row, title = title }
			rows[kind] = r
			r.setDown = makeButton(row, "Move Down", RIGHT_X, function()
				local at = indexOf(kind)
				if at and swap(at, 1) then layout(true) end
			end)
			r.setUp = makeButton(row, "Move Up", RIGHT_X - 140, function()
				local at = indexOf(kind)
				if at and swap(at, -1) then layout(true) end
			end)

			-- the handle: hold it and drag the row up or down
			local handle = new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(RIGHT_X - 290, 42), Size = UDim2.fromOffset(44, 56),
				BackgroundTransparency = 1, Active = true, Text = "≡", TextSize = 34, Font = Enum.Font.GothamBold,
				TextColor3 = C.sub,
			}, row)
			handle.MouseEnter:Connect(function() handle.TextColor3 = C.text end)
			handle.MouseLeave:Connect(function() if not (dragging and dragging.kind == kind) then handle.TextColor3 = C.sub end end)
			handle.InputBegan:Connect(function(input)
				if not isPress(input) or dragging then return end
				dragging = { kind = kind, startMouseY = input.Position.Y, startY = row.Position.Y.Offset, handle = handle }
				row.ZIndex = 5
				handle.TextColor3 = C.text
				list.ScrollingEnabled = false
			end)

			refreshRow(kind, false)
		end

		connect(UserInputService.InputChanged, function(input)
			if not dragging or not isMove(input) then return end
			local r = rows[dragging.kind]
			if not r then return end
			local dy = (input.Position.Y - dragging.startMouseY) / math.max(uiScale.Scale, 0.01)
			local y = math.clamp(dragging.startY + dy, 0, (#order - 1) * STEP)
			r.frame.Position = UDim2.fromOffset(0, y)
			local target = math.clamp(math.floor((y + STEP / 2) / STEP) + 1, 1, #order)
			local at = indexOf(dragging.kind)
			local moved = false
			while at and at < target and swap(at, 1) do at = at + 1 moved = true end
			while at and at > target and swap(at, -1) do at = at - 1 moved = true end
			if moved then layout(true) end -- the other rows slide out of the way
		end)

		connect(UserInputService.InputEnded, function(input)
			if not dragging or not isPress(input) then return end
			local d = dragging
			dragging = nil
			list.ScrollingEnabled = true
			if d.handle then d.handle.TextColor3 = C.sub end
			local r = rows[d.kind]
			if r then
				refreshRow(d.kind, true) -- slides into its slot
				task.delay(0.25, function() if r.frame.Parent then r.frame.ZIndex = 1 end end)
			end
		end)
	end
end

-- start on the default tab (no animation)
setTab(DEFAULT_TAB, true)

------------------------------------------------------------------ Drag + Resize
local MIN_SCALE, MAX_SCALE = 0.3, 1.6

-- Returns the screen size.
local function viewport()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1920, 1080)
end

-- Keeps the window inside the screen.
local function clampPosition(x, y)
	local vp, s = viewport(), uiScale.Scale
	local w, h = WINDOW_W * s, WINDOW_H * s
	x = math.clamp(x, -w + 120, vp.X - 120)
	y = math.clamp(y, 0, vp.Y - 40)
	return x, y
end

local dragBar = new("Frame", {
	Name = "DragBar", Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(1290, 77),
	BackgroundTransparency = 1, Active = true,
}, window)

local grip = new("TextLabel", {
	Name = "ResizeGrip", AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.fromOffset(WINDOW_W - 6, WINDOW_H - 6), Size = UDim2.fromOffset(34, 34),
	BackgroundTransparency = 1, Active = true, Text = "◢", TextSize = 22,
	TextColor3 = Color3.fromRGB(84, 84, 84), TextXAlignment = Enum.TextXAlignment.Right,
	TextYAlignment = Enum.TextYAlignment.Bottom, Font = Enum.Font.GothamBold,
}, window)

local mode, startMouse, startPos, startScale

dragBar.InputBegan:Connect(function(input)
	if isPress(input) then
		mode = "drag"
		startMouse = Vector2.new(input.Position.X, input.Position.Y)
		startPos = Vector2.new(window.Position.X.Offset, window.Position.Y.Offset)
	end
end)

grip.InputBegan:Connect(function(input)
	if isPress(input) then
		mode = "resize"
		startMouse = Vector2.new(input.Position.X, input.Position.Y)
		startPos = Vector2.new(window.Position.X.Offset, window.Position.Y.Offset)
		startScale = uiScale.Scale
		grip.TextColor3 = C.iconFg
	end
end)

connect(UserInputService.InputChanged, function(input)
	if not mode or not isMove(input) then return end
	local delta = Vector2.new(input.Position.X, input.Position.Y) - startMouse

	if mode == "drag" then
		local x, y = clampPosition(startPos.X + delta.X, startPos.Y + delta.Y)
		window.Position = UDim2.fromOffset(x, y)
	elseif mode == "resize" then
		local ds = (delta.X / WINDOW_W + delta.Y / WINDOW_H) / 2
		local vp = viewport()
		local maxFit = math.min((vp.X - startPos.X) / WINDOW_W, (vp.Y - startPos.Y) / WINDOW_H)
		uiScale.Scale = math.clamp(startScale + ds, MIN_SCALE, math.max(MIN_SCALE, math.min(MAX_SCALE, maxFit)))
	end
end)

connect(UserInputService.InputEnded, function(input)
	if mode and isPress(input) then
		mode = nil
		grip.TextColor3 = Color3.fromRGB(84, 84, 84)
	end
end)

------------------------------------------------------------------ KAITUN TAB: "Craft When Storage Is" shows up under Kaitun Hatch while it is on
-- (the window and the tabs never change; only this one row is borrowed from its own tab and given back when Kaitun Hatch goes off)
do
	local sh = {}
	Config.shell = sh
	-- Shows or hides the username (Show / Hide name button).
	function sh.set(on)
		on = on == true
		local list = Config.pageLists.Kaitun
		local e = Config.kaitunStorage
		local row = e and e._row
		if not (row and row.Parent and list) then return end
		local stats = Logic.kaitun and Logic.kaitun.second
		local statsRow = stats and stats._row
		local ench = Logic.kaitun and Logic.kaitun.enchant
		local enchRow = ench and ench._row
		if on then
			row.Parent = list
			row.LayoutOrder = 2                                  -- Kaitun Hatch = 1, this slider = 2, Kaitun Events = 3, Kaitun Stats = 4
			if statsRow then statsRow.LayoutOrder = 3 end
			if enchRow then enchRow.LayoutOrder = 4 end
		else
			if e._list then row.Parent = e._list end
			row.LayoutOrder = e._order or 1
			if statsRow then statsRow.LayoutOrder = stats._order or 2 end
			if enchRow then enchRow.LayoutOrder = ench._order or 3 end
		end
	end
	-- Auto Save may already have switched Kaitun Hatch on before this point
	local kt = Logic and Logic.kaitun
	if kt and kt.main and kt.main._get and kt.main._get() then sh.set(true) end
end

------------------------------------------------------------------ MINIMIZE (— button / keybind -> small "A" circle)
local function tw(obj, props, time, style, dir)
	local t = TweenService:Create(obj, TweenInfo.new(time or 0.3, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local BUBBLE = 64
local MIN_SHRINK = 0.04

local bubble = new("TextButton", {
	Name = "MinimizedBubble", Size = UDim2.fromOffset(BUBBLE, BUBBLE), BackgroundColor3 = C.window,
	Text = "", AutoButtonColor = false, Visible = false, ZIndex = 60, Active = true,
}, gui)
corner(bubble, UDim.new(1, 0))
local bubbleStroke = new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, bubble)
local bubbleRing = new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 235, 235)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(40, 40, 40)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(210, 210, 210)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30)),
	}),
}, bubbleStroke)
local bubbleScale = new("UIScale", { Scale = 1 }, bubble)
local bubbleA = new("TextLabel", {
	Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "W", TextColor3 = Color3.new(1, 1, 1),
	TextSize = 44, Font = Enum.Font.GothamBlack, ZIndex = 61,
}, bubble)
local bubbleShimmer = new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 70, 70)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(215, 215, 215)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 70, 70)),
	}),
	Rotation = 90,
}, bubbleA)

-- burning look: two glowing rings around the ball, a turning edge, a shimmer through the W and ash rising off it
do
	local rings = {}
	for i, size in ipairs({ BUBBLE + 12, BUBBLE + 26 }) do
		local r = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 59,
		}, bubble)
		corner(r, UDim.new(1, 0))
		rings[i] = new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 3 - i, Transparency = 0.85 }, r)
	end

	local step = newEmitter({
		count = 14, parent = bubble, z = 62, maxAlpha = 0.9, warm = 0.3, drift = 7, topFade = nil,
		speed = { 16, 34 }, life = { 1.4, 2.6 }, size = { 1.5, 3.6 }, sway = { 2, 6 },
		spawn = function() return math.random(14, BUBBLE - 14), math.random(BUBBLE - 26, BUBBLE - 6) end,
	})

	local clock = 0
	connect(game:GetService("RunService").Heartbeat, function(dt)
		if not bubble.Visible then return end
		dt = math.min(dt, 0.1)
		clock = clock + dt
		step(dt)
		bubbleRing.Rotation = (clock * 90) % 360
		bubbleShimmer.Offset = Vector2.new(0, math.sin(clock * 2.2) * 0.35)
		-- the glow flickers like embers: mostly white, drifting to a faint warm orange now and then
		local warm = (math.sin(clock * 0.9) * 0.5 + 0.5) * 0.35
		local tint = Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(255, 160, 90), warm)
		for i, st in ipairs(rings) do
			local flick = math.sin(clock * (2.4 + i) + i * 1.7) * 0.5 + 0.5
			st.Color = tint
			st.Transparency = 0.9 - flick * 0.16
		end
	end)
end

local minimized, animating = false, false
local savedPos, savedScale
local scrollKeep = {}   -- scroll positions of every page, kept while minimized
local bubblePos

-- Keeps the minimized bubble inside the screen.
local function clampBubble(x, y)
	local vp = viewport()
	return math.clamp(x, 0, vp.X - BUBBLE), math.clamp(y, 0, vp.Y - BUBBLE)
end

-- Minimizes the hub into the small bubble.
local function minimize()
	if minimized or animating or not alive then return end
	animating = true
	mode = nil
	if closeOpenDropdown then closeOpenDropdown() end
	scrollKeep = {}   -- saved BEFORE the shrink animation: shrinking the window clamps the scroll back to the top
	for _, d in ipairs(window:GetDescendants()) do
		if d:IsA("ScrollingFrame") then scrollKeep[d] = d.CanvasPosition end
	end

	savedPos = Vector2.new(window.Position.X.Offset, window.Position.Y.Offset)
	savedScale = uiScale.Scale
	if not bubblePos then
		local bx, by = clampBubble(savedPos.X + 14, savedPos.Y + 14)
		bubblePos = Vector2.new(bx, by)
	end

	tw(window, { Position = UDim2.fromOffset(bubblePos.X, bubblePos.Y) }, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	local t = tw(uiScale, { Scale = MIN_SHRINK }, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	t.Completed:Wait()
	if not alive then return end

	window.Visible = false
	bubble.Position = UDim2.fromOffset(bubblePos.X, bubblePos.Y)
	bubbleScale.Scale = 0
	bubble.Visible = true
	tw(bubbleScale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	minimized = true
	animating = false
end

-- Restores the hub from the small bubble.
local function restore()
	if not minimized or animating or not alive then return end
	animating = true

	local vp = viewport()
	local tx = math.clamp(savedPos.X, -WINDOW_W * savedScale + 120, vp.X - 120)
	local ty = math.clamp(savedPos.Y, 0, vp.Y - 40)

	tw(bubbleScale, { Scale = 0 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	window.Position = UDim2.fromOffset(bubblePos.X, bubblePos.Y)
	uiScale.Scale = MIN_SHRINK
	window.Visible = true
	task.spawn(function()   -- the lists re-measure themselves while the window grows back, so keep putting the scroll back for a moment
		local t0 = os.clock()
		while os.clock() - t0 < 0.8 and alive do
			for d, pos in pairs(scrollKeep) do
				if d.Parent and d.CanvasPosition ~= pos then d.CanvasPosition = pos end
			end
			game:GetService("RunService").RenderStepped:Wait()
		end
	end)
	tw(window, { Position = UDim2.fromOffset(tx, ty) }, 0.42)
	local t = tw(uiScale, { Scale = savedScale }, 0.42)
	t.Completed:Wait()
	if not alive then return end
	bubble.Visible = false
	minimized = false
	animating = false
end

-- Status pill (top middle): only visible while Settings > Show Status is on (minimized or not), shows what each running feature is doing right now
do
	local sources = {}
	if Logic then
		for _, k in ipairs({ "hatch", "craft", "dCraft", "rCraft", "collect", "scan" }) do
			if Logic[k] then table.insert(sources, Logic[k]) end
		end
		if Logic.enchant and Logic.enchant.auto then table.insert(sources, Logic.enchant.auto) end   -- Auto Enchant
		if Logic.enchant and Logic.enchant.v2 then table.insert(sources, Logic.enchant.v2) end   -- Enchant V2
		if Logic.halloween then
			table.insert(sources, Logic.halloween.treat)
			table.insert(sources, Logic.halloween.boss)
			table.insert(sources, Logic.halloween.shop)
		end
		if Logic.dig then table.insert(sources, Logic.dig.toggle) end
		if Logic.balloon then table.insert(sources, Logic.balloon.toggle) end
	end

	local PILL_TOP = 6   -- distance from the top of the screen (raise it / lower it here)
	local pill = new("TextButton", {
		Name = "StatusPill", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, PILL_TOP),
		Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, Text = "", AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(12, 12, 12), BackgroundTransparency = 0.05, BorderSizePixel = 0, Visible = false,
	}, gui)
	local pillCorner = corner(pill, UDim.new(0, 28))
	stroke(pill, C.accent, 1.5)
	local pillPad = new("UIPadding", {
		PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22), PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11),
	}, pill)
	local pillLayout = new("UIListLayout", {
		Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, pill)

	-- Creates one line of the Show Status pill.
	local function line(order)
		return new("TextLabel", {
			LayoutOrder = order, Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1, RichText = true, Text = "", TextSize = 21, Font = Enum.Font.GothamMedium,
			TextColor3 = C.text, Visible = false,
		}, pill)
	end
	local lines = {}
	for i = 1, #sources do lines[i] = line(i) end
	local idle = line(#sources + 1)

	-- hover tooltip: shows the Roblox username under the pill
	local tip = new("TextLabel", {
		Name = "StatusTip", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(12, 12, 12), BorderSizePixel = 0, Text = "Username: " .. player.Name,
		TextColor3 = C.text, TextSize = 18, Font = Enum.Font.GothamMedium, Visible = false, ZIndex = 50,
	}, gui)
	if FX.names then FX.names.add(tip, "Username: " .. player.Name, "Username hidden") end
	corner(tip, UDim.new(0, 12))
	stroke(tip, C.stroke, 1)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
	}, tip)
	local hovering = false
	-- Positions the Show Status tooltip.
	local function placeTip()
		tip.Position = UDim2.fromOffset(pill.AbsolutePosition.X + pill.AbsoluteSize.X / 2, pill.AbsolutePosition.Y + pill.AbsoluteSize.Y + 8)
	end
	pill.MouseEnter:Connect(function() hovering = true placeTip() tip.Visible = true end)
	pill.MouseLeave:Connect(function() hovering = false tip.Visible = false end)

	-- Escapes text for rich text.
	local function esc(t) return (tostring(t):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end

	-- COMPACT MODE: drag the pill anywhere and it shrinks to a small box ("Auto Hatch: ●").
	-- green = on, yellow = waiting, red = off.  Drag it back to the top middle and it snaps home with the full details.
	local COMPACT_SHOW_OFF = true   -- false = the small box only lists features that are on / waiting
	local DOT = { on = "rgb(90,225,120)", wait = "rgb(255,205,70)", off = "rgb(235,75,75)" }
	local compact, dragging, moved = false, false, false
	local pscale = new("UIScale", {}, pill)

	local clines = {}
	for i = 1, #sources do
		local l = line(100 + i)
		l.TextSize = 17
		l.TextXAlignment = Enum.TextXAlignment.Left
		clines[i] = l
	end
	local cidle = line(300)
	cidle.TextSize = 17
	cidle.Text = '<font color="rgb(235,75,75)">●</font>  Everything is off'

	-- Returns the state (off / working / waiting) of a feature.
	local function stateOf(src)
		if not (src._get and src._get()) then return "off" end
		local txt = (src._desc and src._desc.Parent and src._desc.Text or ""):lower()
		if txt:find("waiting") or txt:find("paused") or txt:find("retry") or txt:find("pick a pet") or txt:find("open the") then
			return "wait"
		end
		return "on"
	end

	-- Refreshes the Show Status pill.
	local function refresh()
		if compact then
			local shown = 0
			for i, src in ipairs(sources) do
				lines[i].Visible = false
				local st = stateOf(src)
				local show = COMPACT_SHOW_OFF or st ~= "off"
				clines[i].Visible = show
				if show then
					shown = shown + 1
					clines[i].Text = string.format('%s: <font color="%s">●</font>', esc(src.name or "?"), DOT[st])
				end
			end
			idle.Visible = false
			cidle.Visible = shown == 0
		else
			local any = false
			for i, src in ipairs(sources) do
				clines[i].Visible = false
				local txt = src._desc and src._desc.Parent and src._desc.Text or ""
				local on = src._get and src._get() and txt ~= ""
				lines[i].Visible = on and true or false
				if on then
					any = true
					if #txt > 80 then txt = txt:sub(1, 77) .. "..." end
					lines[i].Text = string.format('<font color="rgb(225,225,225)">%s</font>  %s', esc(src.name or "?"), esc(txt))
				end
			end
			cidle.Visible = false
			idle.Visible = not any
			idle.Text = '<font color="rgb(225,225,225)">WORST Hub</font>  Idle'
		end
	end

	-- Switches the pill between compact and full.
	local function setCompact(v, animate)
		compact = v
		pillCorner.CornerRadius = UDim.new(0, v and 12 or 28)
		pillPad.PaddingLeft, pillPad.PaddingRight = UDim.new(0, v and 14 or 22), UDim.new(0, v and 14 or 22)
		pillPad.PaddingTop, pillPad.PaddingBottom = UDim.new(0, v and 9 or 11), UDim.new(0, v and 9 or 11)
		pillLayout.Padding = UDim.new(0, v and 3 or 5)
		pillLayout.HorizontalAlignment = v and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center
		refresh()
		if animate then
			pscale.Scale = 0.85
			TweenService:Create(pscale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
	end

	local HOME_POS = UDim2.new(0.5, 0, 0, PILL_TOP)
	local dragStartMouse, dragStartPos
	pill.InputBegan:Connect(function(input)
		if isPress(input) then
			dragging, moved = true, false
			dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
			dragStartPos = Vector2.new(pill.AbsolutePosition.X + pill.AbsoluteSize.X / 2, pill.AbsolutePosition.Y)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if not (dragging and isMove(input)) then return end
		local d = Vector2.new(input.Position.X, input.Position.Y) - dragStartMouse
		if not moved and d.Magnitude > 6 then
			moved = true
			hovering = false
			tip.Visible = false
			if not compact then setCompact(true, true) end
		end
		if moved then
			local vp = viewport()
			local w, h = pill.AbsoluteSize.X, pill.AbsoluteSize.Y
			local x = math.clamp(dragStartPos.X + d.X, w / 2, math.max(vp.X - w / 2, w / 2))
			local y = math.clamp(dragStartPos.Y + d.Y, 0, math.max(vp.Y - h, 0))
			pill.Position = UDim2.fromOffset(x, y)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if not (dragging and isPress(input)) then return end
		dragging = false
		if not moved then return end
		local vp = viewport()
		local cx = pill.AbsolutePosition.X + pill.AbsoluteSize.X / 2
		local top = pill.AbsolutePosition.Y
		if top < 70 and math.abs(cx - vp.X / 2) < 280 then
			-- dropped back at the top: glide home and open up to the full details again
			setCompact(false, true)
			TweenService:Create(pill, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = HOME_POS }):Play()
		end
	end)

	task.spawn(function()
		while alive do
			if Config.showStatus and not record.liteActive and os.clock() >= (Config.statusHideUntil or 0) then   -- not shown in Mini Ui mode
				refresh()
				pill.Visible = true
				if hovering and not dragging then placeTip() end
			else
				pill.Visible = false
				tip.Visible = false
				hovering = false
			end
			task.wait(0.4)
		end
	end)
end

local minBtn = new("TextButton", {
	Name = "MinimizeButton", Position = UDim2.fromOffset(1327, 22), Size = UDim2.fromOffset(40, 30),
	BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
}, window)
minBtn.MouseEnter:Connect(function() minLabel.TextColor3 = C.iconFg end)
minBtn.MouseLeave:Connect(function() minLabel.TextColor3 = C.text end)
minBtn.MouseButton1Click:Connect(function() task.spawn(minimize) end)

local bDragging, bMoved, bStartM, bStartP = false, false, nil, nil
bubble.InputBegan:Connect(function(input)
	if isPress(input) then
		bDragging, bMoved = true, false
		bStartM = Vector2.new(input.Position.X, input.Position.Y)
		bStartP = Vector2.new(bubble.Position.X.Offset, bubble.Position.Y.Offset)
	end
end)
connect(UserInputService.InputChanged, function(input)
	if bDragging and isMove(input) then
		local d = Vector2.new(input.Position.X, input.Position.Y) - bStartM
		if d.Magnitude > 6 then bMoved = true end
		if bMoved then
			local x, y = clampBubble(bStartP.X + d.X, bStartP.Y + d.Y)
			bubblePos = Vector2.new(x, y)
			bubble.Position = UDim2.fromOffset(x, y)
		end
	end
end)
connect(UserInputService.InputEnded, function(input)
	if bDragging and isPress(input) then
		bDragging = false
		if not bMoved then task.spawn(restore) end
	end
end)

------------------------------------------------------------------ OPENING ANIMATION (drawn border -> background fades in -> drawn tabs and pages)
-- Nothing is visible when the script runs. Then:
--   1. a small arc appears in each of the 4 corners, and lines grow out of every corner along the edges until they meet in the middle of each edge (the box)
--   2. only once the box is complete, the real window slowly fades in inside it (border, animated background, ash, title bar); the drawn lines melt into the real border
--   3. when the background is fully there, the tabs and pages are DRAWN in, one piece after another:
--      tabs (pen stroke + text written in) -> selector + footer -> main panel border -> Home title -> each Home card
-- All the timing numbers are the constants right below.
do
	-- phase 1 timeline, in seconds after the script starts
	local ARC_START                = 0.15   -- the 4 corner arcs fade in
	local LINE_START, LINE_DUR     = 0.35, 1.25   -- lines grow from the corners until they meet in the middle of every edge (the box is done at 1.6 s)
	local BG_START, BG_DUR         = 1.75, 2.80   -- the background slowly fades in, starting only after the box is complete
	local TAB_DELAY                = 0.10         -- the tabs / pages start drawing this long after the background has fully faded in

	-- phase 2 timeline, in seconds after the background is done (start, duration)
	local TAB_START, TAB_STAGGER, TAB_DUR = 0.00, 0.15, 0.60   -- tab number i starts at TAB_START + (i-1) * TAB_STAGGER
	local SEL_START, SEL_DUR               = 0.35, 0.45        -- the highlighted selector behind the current tab
	local FOOT_START, FOOT_DUR             = 1.20, 0.60        -- avatar / name footer
	local PANEL_START, PANEL_DUR           = 1.60, 0.80        -- the big panel (border drawn)
	local CONTENT_START, CONTENT_DUR       = 2.10, 0.50        -- page title, welcome line, divider
	local CARD_START, CARD_STAGGER, CARD_DUR = 2.20, 0.16, 0.70 -- Home cards, one after another
	local PEN_COLOR = Color3.fromRGB(235, 235, 235)             -- colour of the drawing stroke

	local RunService = game:GetService("RunService")

	-- keeps clicks away from the hub while it fades in (also tells the Lite-mode idle clock that the hub is still opening)
	local blocker = new("Frame", {
		Name = "IntroBlocker", Size = UDim2.fromOffset(WINDOW_W, WINDOW_H), BackgroundTransparency = 1, ZIndex = 99, Active = true,
	}, window)

	-- Smooth easing function (0 to 1).
	local function smooth(x) return x * x * (3 - 2 * x) end   -- starts slowly, ends slowly

	-- an element belongs to a "group" = its own little timeline. Everything that is not in a group belongs to the background.
	local groups, allGroups = {}, {}
	-- Creates an animation group (start, duration, fill).
	local function mkGroup(start, dur, fillFrom)
		local g = { start = start, dur = dur, fill = fillFrom or 0, p = 0, a = 0 }
		allGroups[#allGroups + 1] = g
		return g
	end
	-- Assigns an object to an animation group.
	local function assign(root, g) if typeof(root) == "Instance" then groups[root] = g end end
	-- Returns the group of an object.
	local function groupOf(o)
		local c = o
		while c and c ~= window do
			local g = groups[c]
			if g then return g end
			c = c.Parent
		end
		return nil
	end
	-- the pen strokes / wipes created below are never part of the fade
	local function isFx(o)
		local c = o
		while c and c ~= window do
			if c.Name == "DrawFX" then return true end
			c = c.Parent
		end
		return false
	end

	-- 1) the tabs: one group each (icon + name share it)
	for i, item in ipairs(navItems) do
		local name, y = item[1], item[4]
		local g = mkGroup(TAB_START + (i - 1) * TAB_STAGGER, TAB_DUR, 0.2)
		g.wipeRoots = { { obj = navIcons[name], text = false }, { obj = navLabels[name], text = true } }
		g.spec = function() return NAV.scroll, UDim2.fromOffset(18, y - 30 - NAV.top), UDim2.fromOffset(258, 54), 16, 2 end
		assign(navIcons[name], g)
		assign(navLabels[name], g)
	end
	-- 2) selector + footer
	assign(sel, mkGroup(SEL_START, SEL_DUR, 0))
	assign(foot, mkGroup(FOOT_START, FOOT_DUR, 0.2))
	assign(NAV.scroll, mkGroup(FOOT_START, FOOT_DUR, 0.2))   -- (its scrollbar, only shows when there are many tabs)
	-- 3) main panel (its border is drawn)
	do
		local g = mkGroup(PANEL_START, PANEL_DUR, 0.25)
		g.spec = function() return window, UDim2.fromOffset(295, 77), UDim2.fromOffset(1122, 774), 22, 3 end
		assign(panel, g)
	end
	-- 4) the page: title + divider first, then every Home card gets its own group
	assign(content, mkGroup(CONTENT_START, CONTENT_DUR, 0))
	for i, card in ipairs(record.homeCards or {}) do
		local g = mkGroup(CARD_START + (i - 1) * CARD_STAGGER, CARD_DUR, 0.3)
		g.spec = function() return card.Parent, card.Position, card.Size, 16, 3 end
		assign(card, g)
	end

	-- every transparency that is showing inside the window: { obj, prop, final value, grp }. Hidden pages / frames are skipped (they stay as they are).
	local rec, recSet = {}, {}
	-- True if an object is shown.
	local function shown(o)
		local c = o
		while c and c ~= window do
			if c:IsA("GuiObject") and not c.Visible then return false end
			c = c.Parent
		end
		return true
	end
	local alphaNow = 0   -- background opacity
	-- Records an object for the opening animation.
	local function put(e, a) e.obj[e.prop] = 1 - (1 - e.val) * a end   -- (only called for objects that still have a parent)
	-- Adds an object (and its children) to the animation.
	local function add(o)
		if recSet[o] or o == blocker or o:IsDescendantOf(blocker) or isFx(o) then return end
		local list = {}
		if o:IsA("GuiObject") then
			if o.BackgroundTransparency < 1 then list[#list + 1] = "BackgroundTransparency" end
			if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
				if o.TextTransparency < 1 then list[#list + 1] = "TextTransparency" end
				if o.TextStrokeTransparency < 1 then list[#list + 1] = "TextStrokeTransparency" end
			elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then
				if o.ImageTransparency < 1 then list[#list + 1] = "ImageTransparency" end
			elseif o:IsA("ScrollingFrame") then
				if o.ScrollBarImageTransparency < 1 then list[#list + 1] = "ScrollBarImageTransparency" end
			end
		elseif o:IsA("UIStroke") then
			if o.Transparency < 1 then list[#list + 1] = "Transparency" end
		end
		-- the GIF background flips between 10 image sheets and only one is visible at a time: all of them must fade, otherwise the next
		-- sheet pops in at full opacity (that was the "suddenly clear" jump)
		local inBg = o.Parent and o.Parent.Name == "AnimatedBackground" and shown(o.Parent)
		if #list == 0 or not (inBg or shown(o)) then return end
		recSet[o] = true
		local grp = groupOf(o)
		for _, prop in ipairs(list) do
			local e = { obj = o, prop = prop, val = o[prop], grp = grp }
			rec[#rec + 1] = e
			put(e, grp and grp.a or alphaNow)   -- new things that show up while fading start at the current opacity
		end
	end

	FX.introA = 0   -- the ash particles / bottom glow multiply their own transparency with this (they rewrite it every frame)
	add(window)
	for _, d in ipairs(window:GetDescendants()) do add(d) end
	local addConn = window.DescendantAdded:Connect(function(d) if alive then add(d) end end)
	for _, e in ipairs(rec) do put(e, 0) end   -- completely invisible

	------------------------------------------------ the pen: a wipe mask (left -> right) used for strokes and for writing text
	-- p = 0 nothing shows, p = 1 everything shows; the edge in between is where the "pen" is
	local function setWipe(grad, p)
		if p <= 0 then
			grad.Transparency = NumberSequence.new(1)
		elseif p >= 1 then
			grad.Transparency = NumberSequence.new(0)
		else
			local x = math.clamp(p, 0.002, 0.995)
			grad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(x, 0),
				NumberSequenceKeypoint.new(x + 0.004, 1), NumberSequenceKeypoint.new(1, 1),
			})
		end
	end

	local fxObjects = {}   -- everything created for the drawing, removed at the end
	-- Draws one outline box of the opening animation.
	local function makeOutline(parent, pos, size, radius, thick)
		local f = Instance.new("Frame")
		f.Name = "DrawFX"
		f.Position, f.Size = pos, size
		f.BackgroundTransparency = 1
		f.BorderSizePixel = 0
		f.ZIndex = 60
		f.Visible = false
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, radius)
		c.Parent = f
		local st = Instance.new("UIStroke")
		st.Color = PEN_COLOR
		st.Thickness = thick
		st.Transparency = 0.05
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		st.Parent = f
		local gr = Instance.new("UIGradient")
		gr.Transparency = NumberSequence.new(1)
		gr.Parent = st
		f.Parent = parent
		fxObjects[#fxObjects + 1] = f
		return { frame = f, stroke = st, grad = gr }
	end
	-- Creates a wipe gradient on an object.
	local function makeWipe(obj)
		local gr = Instance.new("UIGradient")
		gr.Name = "DrawFX"
		gr.Transparency = NumberSequence.new(1)
		gr.Parent = obj
		fxObjects[#fxObjects + 1] = gr
		return gr
	end

	------------------------------------------------ the opening: corner arcs + lines that draw the box
	local function buildIntroFX()
		local W, H, R, LT = WINDOW_W, WINDOW_H, 28, 2
		-- Creates an Instance with properties.
		local function mk(class, parent, props)
			local o = Instance.new(class)
			for k, v in pairs(props) do o[k] = v end
			o.Parent = parent
			return o
		end
		-- Easing function of the opening animation.
		local function ease(x) return smooth(math.clamp(x, 0, 1)) end

		local root = mk("Frame", nil, {
			Name = "DrawFX", Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 72, Active = false,
		})

		-- the 8 growing lines (two per edge, one from each corner)
		local function seg()
			return mk("Frame", root, { BackgroundColor3 = PEN_COLOR, BorderSizePixel = 0, ZIndex = 72, Visible = false })
		end
		local tl, tr, bl, br = seg(), seg(), seg(), seg()   -- horizontal: top-left, top-right, bottom-left, bottom-right
		local lt, lb, rt, rb = seg(), seg(), seg(), seg()   -- vertical: left-top, left-bottom, right-top, right-bottom

		-- the 4 corner arcs (a quarter of a rounded outline, so the lines follow the window's round corners)
		local arcs = {}
		-- Draws an arc of the opening animation.
		local function arc(cx, cy, ox, oy)
			local clip = mk("Frame", root, {
				Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(R, R), BackgroundTransparency = 1,
				BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 72, Visible = false,
			})
			local ch = mk("Frame", clip, {
				Position = UDim2.fromOffset(ox, oy), Size = UDim2.fromOffset(R * 2 - LT, R * 2 - LT), BackgroundTransparency = 1,
				BorderSizePixel = 0, ZIndex = 72,
			})
			mk("UICorner", ch, { CornerRadius = UDim.new(0, R - LT) })
			local st = mk("UIStroke", ch, { Color = PEN_COLOR, Thickness = LT, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
			arcs[#arcs + 1] = { clip = clip, stroke = st }
		end
		arc(0, 0, LT, LT)
		arc(W - R, 0, -R, LT)
		arc(0, H - R, LT, -R)
		arc(W - R, H - R, -R, -R)

		root.Parent = window
		fxObjects[#fxObjects + 1] = root

		-- Updates the opening animation.
		local function r(x) return math.floor(x + 0.5) end
		-- Updates one element of the opening animation.
		local function update(el)
			-- the drawn box melts into the real border while the background fades in
			local fade = ease((el - BG_START) / (BG_DUR * 0.7))

			local aq = ease((el - ARC_START) / 0.35)
			for _, a in ipairs(arcs) do
				a.clip.Visible = aq > 0 and fade < 1
				a.stroke.Transparency = 1 - aq * (1 - fade) * 0.95
			end

			local q = ease((el - LINE_START) / LINE_DUR)
			local showLines = q > 0 and fade < 1
			for _, f in ipairs({ tl, tr, bl, br, lt, lb, rt, rb }) do
				f.Visible = showLines
				f.BackgroundTransparency = fade
			end
			if showLines then
				local lh, lv = r((W / 2 - R) * q), r((H / 2 - R) * q)
				tl.Position, tl.Size = UDim2.fromOffset(R, 0), UDim2.fromOffset(lh, LT)
				tr.Position, tr.Size = UDim2.fromOffset(W - R - lh, 0), UDim2.fromOffset(lh, LT)
				bl.Position, bl.Size = UDim2.fromOffset(R, H - LT), UDim2.fromOffset(lh, LT)
				br.Position, br.Size = UDim2.fromOffset(W - R - lh, H - LT), UDim2.fromOffset(lh, LT)
				lt.Position, lt.Size = UDim2.fromOffset(0, R), UDim2.fromOffset(LT, lv)
				lb.Position, lb.Size = UDim2.fromOffset(0, H - R - lv), UDim2.fromOffset(LT, lv)
				rt.Position, rt.Size = UDim2.fromOffset(W - LT, R), UDim2.fromOffset(LT, lv)
				rb.Position, rb.Size = UDim2.fromOffset(W - LT, H - R - lv), UDim2.fromOffset(LT, lv)
			end
		end
		return { update = update }
	end

	-- phase 2 begins: build the pen strokes (done now so the Home cards are sitting at their final spots)
	local function startDrawing()
		for _, g in ipairs(allGroups) do
			if g.spec then
				local ok, parent, pos, size, radius, thick = pcall(g.spec)
				if ok and parent and parent.Parent then g.ol = makeOutline(parent, pos, size, radius, thick) end
			end
			if g.wipeRoots then
				g.wipes = {}
				for _, w in ipairs(g.wipeRoots) do
					if w.obj and w.obj.Parent then g.wipes[#g.wipes + 1] = { obj = w.obj, text = w.text, grad = makeWipe(w.obj) } end
				end
			end
		end
	end

	-- one frame of drawing for one group
	local function drawGroup(g)
		local p = g.p
		-- the stroke: sweeps across during the first 70 %, then fades away while the content finishes inking in
		local ol = g.ol
		if ol then
			if p <= 0 or p >= 1 then
				ol.frame.Visible = false
			else
				ol.frame.Visible = true
				setWipe(ol.grad, math.clamp(p / 0.7, 0, 1))
				ol.stroke.Transparency = 0.05 + 0.95 * smooth(math.clamp((p - 0.7) / 0.3, 0, 1))
			end
		end
		-- text / icons of a tab: written from left to right right behind the stroke
		if g.wipes then
			local wp = math.clamp((p - 0.12) / 0.66, 0, 1)
			for _, w in ipairs(g.wipes) do
				local x = wp
				if w.text and wp > 0 and wp < 1 then
					-- a text label is much wider than its text: sweep over the text only
					local o = w.obj
					local aw = math.max(o.AbsoluteSize.X, 1)
					local frac = math.clamp(o.TextBounds.X / aw * 1.08 + 0.01, 0.05, 1)
					x = wp * frac
				end
				if p >= 1 then x = 1 end
				setWipe(w.grad, x)
			end
		end
	end

	task.spawn(function()
		local t0 = os.clock()
		local t2                      -- when phase 2 (the tabs / pages being drawn) started
		local panelRec
		local okFx, fx = pcall(buildIntroFX)
		if not okFx then warn("[WORST Hub] Opening animation: " .. tostring(fx)) fx = { update = function() end } end
		while alive do
			local now = os.clock()
			local el = now - t0
			-- the real window (border, animated background, ash, title bar) slowly fades in, but only after the box has been drawn
			alphaNow = smooth(math.clamp((el - BG_START) / BG_DUR, 0, 1))
			if not t2 and el >= BG_START + BG_DUR + TAB_DELAY then   -- the background is fully there: now the tabs and pages get drawn
				t2 = now
				startDrawing()
			end
			local allDone = el >= BG_START + BG_DUR
			for _, g in ipairs(allGroups) do
				g.p = t2 and math.clamp((now - t2 - g.start) / g.dur, 0, 1) or 0
				g.a = smooth(math.clamp((g.p - g.fill) / (1 - g.fill), 0, 1))   -- the fill comes in a little after the stroke starts
				if g.p < 1 then allDone = false end
				if t2 then drawGroup(g) end
			end
			pcall(fx.update, el)
			FX.introA = alphaNow
			if FX.panel and FX.panelTrans and not panelRec then   -- the GIF finished loading: the panel's real value is now panelTrans
				for _, e in ipairs(rec) do if e.obj == FX.panel and e.prop == "BackgroundTransparency" then panelRec = e break end end
			end
			if panelRec then panelRec.val = FX.bg and FX.panelTrans or 0 end
			for _, e in ipairs(rec) do if e.obj.Parent then put(e, e.grp and e.grp.a or alphaNow) end end
			if allDone then break end
			RunService.RenderStepped:Wait()
		end
		pcall(function() addConn:Disconnect() end)
		FX.introA = nil
		for _, o in ipairs(fxObjects) do pcall(function() o:Destroy() end) end   -- the pen strokes / wipe masks are gone
		if not alive then return end
		if panelRec then panelRec.val = FX.bg and FX.panelTrans or 0 end
		for _, e in ipairs(rec) do if e.obj.Parent then put(e, 1) end end   -- exactly the original look
		pcall(function() blocker:Destroy() end)
		Config.autoLoad()
	end)
end

------------------------------------------------------------------ UNLOAD CONFIRMATION (X button)
local closeBtn = new("TextButton", {
	Name = "CloseButton", Position = UDim2.fromOffset(1383, 22), Size = UDim2.fromOffset(40, 30),
	BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
}, window)
closeBtn.MouseEnter:Connect(function() closeLabel.TextColor3 = Color3.fromRGB(144, 144, 144) end)
closeBtn.MouseLeave:Connect(function() closeLabel.TextColor3 = C.text end)

local dialogOpen = false
-- Opens a Yes / No dialog.
local function openConfirmDialog(titleText, subText, onYes, unloading)
	if dialogOpen or not alive then return end
	dialogOpen = true
	mode = nil
	if closeOpenDropdown then closeOpenDropdown() end

	local backdrop = new("TextButton", {
		Name = "UnloadDialog", Size = UDim2.fromOffset(WINDOW_W, WINDOW_H), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 80, Active = true,
	}, window)
	corner(backdrop, UDim.new(0, 28))

	local dlg = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(WINDOW_W / 2, WINDOW_H / 2),
		Size = UDim2.fromOffset(520, 220), BackgroundColor3 = C.card, BorderSizePixel = 0,
	}, backdrop)
	corner(dlg, UDim.new(0, 16))
	stroke(dlg, Color3.fromRGB(57, 57, 57), 1)
	local dlgScale = new("UIScale", { Scale = 0.88 }, dlg)

	label(dlg, titleText, 260, 62, 25, C.text, Enum.Font.GothamBold,
		Enum.TextXAlignment.Center).Size = UDim2.fromOffset(500, 36)
	label(dlg, subText, 260, 100, 16, C.sub, Enum.Font.Gotham,
		Enum.TextXAlignment.Center).Size = UDim2.fromOffset(500, 24)

	-- Builds one button of the dialog.
	local function dialogButton(text, x, color, hover)
		local b = new("TextButton", {
			Position = UDim2.fromOffset(x, 140), Size = UDim2.fromOffset(180, 48), BackgroundColor3 = color,
			Text = text, TextColor3 = Color3.new(1, 1, 1), TextSize = 19, Font = Enum.Font.GothamMedium,
			AutoButtonColor = false,
		}, dlg)
		corner(b, UDim.new(0, 10))
		b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = hover }) end)
		b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = color }) end)
		return b
	end
	local yes = dialogButton("Yes", 62, Color3.fromRGB(91, 91, 91), Color3.fromRGB(112, 112, 112))
	local no  = dialogButton("No", 278, Color3.fromRGB(44, 44, 44), Color3.fromRGB(59, 59, 59))

	tw(backdrop, { BackgroundTransparency = 0.45 }, 0.2, Enum.EasingStyle.Quad)
	tw(dlgScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)

	no.MouseButton1Click:Connect(function()
		if not dialogOpen then return end
		dialogOpen = false
		tw(backdrop, { BackgroundTransparency = 1 }, 0.12, Enum.EasingStyle.Quad)
		tw(dlgScale, { Scale = 0.88 }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.13, function() backdrop:Destroy() end)
	end)

	yes.MouseButton1Click:Connect(function()
		if not dialogOpen then return end
		if unloading then
			onYes()
			return
		end
		dialogOpen = false
		tw(backdrop, { BackgroundTransparency = 1 }, 0.12, Enum.EasingStyle.Quad)
		tw(dlgScale, { Scale = 0.88 }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.13, function() backdrop:Destroy() end)
		task.spawn(onYes)
	end)
end
Config.confirm = function(titleText, subText, onYes) openConfirmDialog(titleText, subText, onYes, false) end
-- Opens the "Do you want to Unload the Script?" dialog.
local function openUnloadDialog()
	openConfirmDialog("Do you want to Unload the Script?", "This stops everything it was doing and closes the UI.", function()
		cleanup()
		if env.WORSTHubRecord == record then record.unloaded = true end
		print("[WORST Hub] Unloaded.")
	end, true)
end
closeBtn.MouseButton1Click:Connect(openUnloadDialog)

------------------------------------------------------------------ KEYBOARD: minimize key + keybind capture
-- One handler for both, so the key you are assigning never also minimizes the hub.
connect(UserInputService.InputBegan, function(input, gameProcessed)
	if keybindCapture then
		keybindCapture(input)
		return
	end
	if gameProcessed or not alive or dialogOpen then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if input.KeyCode ~= minimizeKey then return end
	if record.liteActive then record.exitLite() return end
	if minimized then
		task.spawn(restore)
	else
		task.spawn(minimize)
	end
end)


------------------------------------------------------------------ 3D RENDERING OFF
-- Used by Settings > Ui > "Disable 3D Rendering" and by the Mini Ui (always off while it is open). The screen turns solid black and
-- your username is shown in the middle of it. Everything of the hub stays above the black layer (ZIndex 0 = lowest).
do
	local RunSvc = game:GetService("RunService")
	local black = new("Frame", {
		Name = "BlackScreen", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0, Visible = false, ZIndex = 0, Active = false,
	}, gui)
	-- six lines in the middle of the black screen: username / current action / hatches / rarest pet / ping / FPS
	local stack = new("Frame", {
		Name = "BlackScreenInfo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(760, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, ZIndex = 0,
	}, gui)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, stack)
	-- Creates one info text line of the black screen.
	local function infoLine(order, size, h, color)
		return new("TextLabel", {
			LayoutOrder = order, Size = UDim2.fromOffset(760, h), BackgroundTransparency = 1, ZIndex = 0, Text = "",
			TextColor3 = color, TextSize = size, Font = order == 1 and Enum.Font.GothamBold or Enum.Font.GothamMedium,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, stack)
	end
	local lUser   = infoLine(1, 46, 56, Color3.new(1, 1, 1))
	local lAction = infoLine(2, 22, 30, Color3.fromRGB(215, 215, 215))
	local lHatch  = infoLine(3, 22, 30, Color3.fromRGB(215, 215, 215))
	local lRare   = infoLine(4, 22, 30, Color3.fromRGB(215, 215, 215))
	local lPing   = infoLine(5, 22, 30, Color3.fromRGB(215, 215, 215))
	local lFps    = infoLine(6, 22, 30, Color3.fromRGB(215, 215, 215))

	local fpsNow, frames, acc = 0, 0, 0
	connect(RunSvc.Heartbeat, function(dt)
		frames = frames + 1
		acc = acc + dt
		if acc >= 0.5 then fpsNow = math.floor(frames / acc + 0.5) Config.fpsMeasured = fpsNow frames, acc = 0, 0 end
	end)
	-- Formats a number with commas.
	local function commas(n)
		local t = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
		return (t:gsub("^,", ""))
	end
	-- Reads your ping.
	local function pingNow()
		local ok, v = pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
		if ok and tonumber(v) then return math.floor(v + 0.5) end
		local ok2, p = pcall(function() return player:GetNetworkPing() * 2000 end)
		if ok2 and tonumber(p) then return math.floor(p + 0.5) end
		return nil
	end
	-- what the script is doing right now: the first running feature that is not just waiting / paused (same sources as Show Status)
	local function currentAction()
		if not Logic then return "Idle" end
		local list = {}
		for _, k in ipairs({ "hatch", "craft", "dCraft", "rCraft", "collect", "scan" }) do list[#list + 1] = Logic[k] end
		if Logic.enchant and Logic.enchant.auto then list[#list + 1] = Logic.enchant.auto end
		if Logic.enchant and Logic.enchant.v2 then list[#list + 1] = Logic.enchant.v2 end
		if Logic.halloween then list[#list + 1] = Logic.halloween.treat list[#list + 1] = Logic.halloween.boss list[#list + 1] = Logic.halloween.shop end
		if Logic.dig then list[#list + 1] = Logic.dig.toggle end
		if Logic.balloon then list[#list + 1] = Logic.balloon.toggle end
		local fallback
		for _, src in ipairs(list) do
			local txt = src and src._desc and src._desc.Parent and src._desc.Text or ""
			if src and src._get and src._get() and txt ~= "" then
				txt = txt:gsub("%s*|%s*Hatched:%s*[%d,]+", "")
				if #txt > 70 then txt = txt:sub(1, 67) .. "..." end
				local line = tostring(src.name or "?") .. ": " .. txt
				if txt:find("^Paused") or txt:find("^Waiting") then fallback = fallback or line else return line end
			end
		end
		return fallback or "Idle"
	end
	local rarestTxt, rarestAt = "Rarest: --", -1e9
	-- Refreshes the black screen info (user, action, hatches, pet, ping, FPS).
	local function refreshInfo()
		lUser.Text = player.Name
		lAction.Text = currentAction()
		local total, session = nil, 0
		if Logic and Logic.hatchCount then local ok, a, b = pcall(Logic.hatchCount) if ok then total, session = a, b or 0 end end
		lHatch.Text = total and ("Hatches: " .. commas(total)) or ("Hatches: " .. commas(session or 0) .. " (this session)")
		if os.clock() - rarestAt > 30 then   -- scanning every pet is not free: every 30 s is plenty
			rarestAt = os.clock()
			task.spawn(function()
				local f = Logic and Logic.autodel and Logic.autodel.rarest
				if not f then return end
				local ok, n, r = pcall(f)
				if ok and n then rarestTxt = "Rarest: " .. tostring(n) .. (r and (" (" .. tostring(r) .. ")") or "") end
			end)
		end
		lRare.Text = rarestTxt
		local pg_ = pingNow()
		lPing.Text = pg_ and ("Ping: " .. pg_ .. " ms") or "Ping: --"
		lFps.Text = "FPS: " .. fpsNow
	end
	local last = nil
	record.apply3d = function()
		if not alive then return end
		local off = Config.render3dOff == true or record.liteActive == true
		black.Visible, stack.Visible = off, off
		if off then pcall(refreshInfo) end
		if off ~= last then
			last = off
			pcall(function() RunSvc:Set3dRenderingEnabled(not off) end)
		end
	end
	table.insert(cleanupHooks, function() pcall(function() RunSvc:Set3dRenderingEnabled(true) end) end)   -- never leave the game black when the hub is closed
	task.spawn(function()
		while alive do
			task.wait(1)
			if stack.Visible then pcall(refreshInfo) end
		end
	end)
	if Config.render3dOff then record.apply3d() end   -- the saved configuration was loaded before this point
end

------------------------------------------------------------------ LITE MODE
-- Only while NOTHING has been toggled by hand since the script was executed (record.userToggled stays false):
--   hub left alone for IDLE_SECS  ->  "Are you afk?" popup  ->  [No] closes it and restarts the timer
--   popup ignored for AFK_SECS    ->  main window closes, a small window opens with Kaitun Hatch + Kaitun Stats (both switched on; Kaitun Events is not)
-- Any press / scroll on the hub, minimizing, or an open dialog counts as activity. Toggling anything yourself (also in the
-- Lite window) turns this watcher off for good. While the Lite window is open the FPS cap is forced to 5. The Lite window has a "Full UI" button (or press the minimize key) to go back.
-- Everything lives inside one function so it does not use up the script's local-variable limit.
task.spawn(function()
	local IDLE_SECS = 60   -- no interaction with the hub for this long -> popup
	local AFK_SECS  = 60   -- popup ignored for this long -> Lite window
	local AUTO_LITE = false   -- false = the "Are you afk?" popup and the automatic switch never happen: the Mini Ui only opens from Settings > Mini Ui

	local kt = Logic and Logic.kaitun
	if not (kt and kt.main and kt.second) then
		warn("[WORST Hub] Lite mode unavailable: the Kaitun controls were not found")
		return
	end
	local GuiService = game:GetService("GuiService")
	local lastActive = os.clock()
	local popupAt = nil

	-- Creates a panel (frame) of the Mini Ui.
	local function panel(name, w, h, z)
		local f = new("Frame", {
			Name = name, Size = UDim2.fromOffset(w, h), BackgroundColor3 = C.window, BorderSizePixel = 0,
			Visible = false, ZIndex = z,
		}, gui)
		corner(f, UDim.new(0, 18))
		stroke(f, Color3.fromRGB(200, 200, 200), 1.5)
		return f
	end
	-- Creates a text label of the Mini Ui.
	local function text(parent, str, x, y, w, h, size, color, font, align)
		return new("TextLabel", {
			Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1,
			Text = str, TextColor3 = color or C.text, TextSize = size, Font = font or Enum.Font.GothamMedium,
			TextXAlignment = align or Enum.TextXAlignment.Left,
		}, parent)
	end

	------------------------------------------------ "Are you afk?" popup
	local popup = panel("AfkPopup", 330, 150, 300)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Position = UDim2.fromScale(0.5, 0.5)
	text(popup, "Are you afk?", 0, 16, 330, 32, 24, C.text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	local popSub = text(popup, "", 0, 54, 330, 22, 15, C.sub, Enum.Font.Gotham, Enum.TextXAlignment.Center)
	local noBtn = new("TextButton", {
		Position = UDim2.fromOffset(105, 92), Size = UDim2.fromOffset(120, 38), BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderSizePixel = 0, AutoButtonColor = false, Text = "No", TextColor3 = C.text, TextSize = 18, Font = Enum.Font.GothamBold,
	}, popup)
	corner(noBtn, UDim.new(0, 12))
	stroke(noBtn, C.stroke, 1)

	------------------------------------------------ the Lite window (same look as the main UI, but light: 8 embers, one rotating border)
	local LW, LH = 290, (kt.enchant and 260 or 208)   -- room for the Kaitun Stats switch
	local lite = panel("LiteUI", LW, LH, 250)
	lite.Position = UDim2.fromOffset(16, 16)
	lite.Active = true
	lite.ClipsDescendants = true
	lite:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 22)
	local liteStroke = lite:FindFirstChildOfClass("UIStroke")
	liteStroke.Thickness = 2
	local liteGrad = new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 35)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(215, 215, 215)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 35)),
		}),
	}, liteStroke)

	-- background: soft glow along the bottom + a few rising embers
	local ash = new("Frame", {
		Name = "AshLayer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ClipsDescendants = true,
	}, lite)
	local liteGlow = new("Frame", {
		Position = UDim2.fromOffset(0, LH - 110), Size = UDim2.fromOffset(LW, 110),
		BackgroundColor3 = Color3.fromRGB(230, 230, 230), BackgroundTransparency = 0.93, BorderSizePixel = 0,
	}, ash)
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
	}, liteGlow)
	local liteStep = newEmitter({
		count = 8, parent = ash, z = 1, maxAlpha = 0.5, warm = 0.12, drift = 4,
		speed = { 14, 34 }, life = { 6, 11 }, size = { 2, 4 }, sway = { 4, 12 },
		spawn = function() return math.random(0, LW), math.random(math.floor(LH * 0.5), LH + 8) end,
	})
	do
		local rot, clock = 0, 0
		connect(game:GetService("RunService").Heartbeat, function(dt)
			if not lite.Visible then return end
			-- Mini Ui is meant to be as light as possible: no spinning border, no embers, no glow. The window stays still,
			-- so the screen has nothing to redraw each frame (only the status text on the black screen changes, once a second).
			ash.Visible = false
		end)
	end

	-- header: logo + title (drag the window by it)
	local liteLogo = text(lite, "W", 14, 9, 34, 38, 30, Color3.new(1, 1, 1), Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	new("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(70, 70, 70), Color3.fromRGB(235, 235, 235)), Rotation = 90,
	}, liteLogo)
	text(lite, "WORST Lite", 54, 10, 220, 22, 17, C.text, Enum.Font.GothamBold)
	text(lite, "Kaitun mode", 54, 31, 220, 16, 12, C.sub, Enum.Font.Gotham)
	local header = new("Frame", {
		Size = UDim2.fromOffset(LW, 56), BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, ZIndex = 5,
	}, lite)
	local liteDivider = new("Frame", {
		Position = UDim2.fromOffset(14, 56), Size = UDim2.fromOffset(LW - 28, 1),
		BackgroundColor3 = C.stroke, BackgroundTransparency = 0.6, BorderSizePixel = 0,
	}, lite)

	-- one card per Kaitun toggle, same style as the rows of the main UI
	local switchRows = {}   -- the cards [-] hides
	-- Builds one toggle switch of the Mini Ui.
	local function makeSwitch(y, name, glyph, entry)
		local row = new("Frame", {
			Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(LW - 24, 46),
			BackgroundColor3 = C.card, BackgroundTransparency = CARD_T, BorderSizePixel = 0,
		}, lite)
		switchRows[#switchRows + 1] = row
		corner(row, UDim.new(0, 13))
		local rowStroke = stroke(row, C.stroke, 1.5, 0.55)
		local chip = new("Frame", {
			Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = C.iconBg, BorderSizePixel = 0,
		}, row)
		corner(chip, UDim.new(1, 0))
		new("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = glyph, TextColor3 = C.iconFg,
			TextSize = 15, Font = Enum.Font.GothamBold,
		}, chip)
		text(row, name, 46, 10, 130, 26, 15, C.text)
		local sw = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(50, 26),
			Text = "", AutoButtonColor = false, BackgroundColor3 = OFF_COLOR, BorderSizePixel = 0,
		}, row)
		corner(sw, UDim.new(1, 0))
		local knob = new("Frame", {
			Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		}, sw)
		corner(knob, UDim.new(1, 0))
		-- Redraws the switch to match its toggle.
		local function paint()   -- no tweens: the Lite window can run at 5 FPS
			local on = entry._get and entry._get() or false
			sw.BackgroundColor3 = on and C.accent or OFF_COLOR
			knob.Position = UDim2.fromOffset(on and 27 or 3, 3)
			rowStroke.Color = on and Color3.new(1, 1, 1) or C.stroke
			rowStroke.Transparency = on and 0.1 or 0.55
		end
		sw.MouseButton1Click:Connect(function()
			record.userToggled = true   -- your own choice: Lite mode never takes over again
			if entry._setUI then entry._setUI(not (entry._get and entry._get())) end
			paint()
		end)
		return paint
	end
	local paintA = makeSwitch(64, "Kaitun Hatch", "⚡", kt.main)
	local paintB = makeSwitch(116, "Kaitun Events", "📊", kt.second)
	local paintC = kt.enchant and makeSwitch(168, "Kaitun Stats", "🔮", kt.enchant) or function() end
	-- Redraws all Mini Ui switches.
	local function paintAll() paintA() paintB() paintC() end

	local fpsLbl = text(lite, "", 16, LH - 40, 150, 26, 12, C.sub, Enum.Font.Gotham)
	fpsLbl.Text = "Executor: " .. Config.execName()
	task.spawn(function()   -- the number below is measured: if it stays far above the cap, say so instead of showing a cap that does nothing
		while alive do
			task.wait(3)
			fpsLbl.Text = "Executor: " .. Config.execName()
		end
	end)
	local fullBtn = new("TextButton", {
		Position = UDim2.fromOffset(LW - 12 - 84, LH - 40), Size = UDim2.fromOffset(84, 26), BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderSizePixel = 0, AutoButtonColor = false, Text = "Full UI", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamMedium,
	}, lite)
	corner(fullBtn, UDim.new(0, 10))
	stroke(fullBtn, C.stroke, 1)

	-- [-] in the header: hides every toggle (the window shrinks to the header + the Full UI bar); [+] brings them back
	local LH_FULL, LH_MIN = LH, 100
	local collapsed = false
	local collapseBtn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(LW - 12, 12), Size = UDim2.fromOffset(36, 26),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40), BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 8,
		Text = "[-]", TextColor3 = C.text, TextSize = 15, Font = Enum.Font.GothamBold,
	}, lite)
	corner(collapseBtn, UDim.new(0, 10))
	stroke(collapseBtn, C.stroke, 1)
	-- Collapses or expands the Mini Ui toggles.
	local function setCollapsed(on)
		collapsed = on == true
		for _, r in ipairs(switchRows) do r.Visible = not collapsed end
		liteDivider.Visible = not collapsed
		LH = collapsed and LH_MIN or LH_FULL
		lite.Size = UDim2.fromOffset(LW, LH)
		liteGlow.Position = UDim2.fromOffset(0, LH - 110)
		fpsLbl.Position = UDim2.fromOffset(16, LH - 40)
		fullBtn.Position = UDim2.fromOffset(LW - 12 - 84, LH - 40)
		collapseBtn.Text = collapsed and "[+]" or "[-]"
		local vp = viewport()   -- keep the window on screen after it grew back
		lite.Position = UDim2.fromOffset(
			math.clamp(lite.Position.X.Offset, 0, math.max(vp.X - LW, 0)),
			math.clamp(lite.Position.Y.Offset, 0, math.max(vp.Y - LH, 0)))
	end
	collapseBtn.MouseButton1Click:Connect(function() setCollapsed(not collapsed) end)


	-- drag the Lite window by its header
	local dragging, dragStart, startPos = false, nil, nil
	header.InputBegan:Connect(function(input)
		if isPress(input) then
			dragging = true
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			startPos = lite.Position
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and isMove(input) then
			local d = Vector2.new(input.Position.X, input.Position.Y) - dragStart
			local vp = viewport()
			lite.Position = UDim2.fromOffset(
				math.clamp(startPos.X.Offset + d.X, 0, math.max(vp.X - LW, 0)),
				math.clamp(startPos.Y.Offset + d.Y, 0, math.max(vp.Y - LH, 0)))
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if dragging and isPress(input) then dragging = false end
	end)

	------------------------------------------------ switching between the two UIs
	local liteScale = new("UIScale", { Scale = 1 }, lite)
	-- Switches to the Mini Ui (Lite window).
	local function enterLite(grow)
		if record.liteActive or not alive then return end
		record.liteActive = true
		popup.Visible, popupAt = false, nil
		if closeOpenDropdown then pcall(closeOpenDropdown) end
		window.Visible = false   -- every window animation / refresh loop checks this and stops
		lite.Visible = true
		if record.apply3d then record.apply3d() end   -- Mini Ui: 3D rendering off, black screen + username
		if grow then   -- opened from Settings > Mini Ui: the small window pops open (the 5 FPS cap only starts once it has finished)
			liteScale.Scale = 0.05
			tw(liteScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			-- no FPS cap in Mini Ui any more (Config.fps.lite stays false)
		else
			liteScale.Scale = 1
			-- no FPS cap in Mini Ui any more
		end
		pcall(function() if kt.main._setUI then kt.main._setUI(true) end end)     -- no-op when it is already on
		pcall(function() if kt.enchant and kt.enchant._setUI then kt.enchant._setUI(true) end end)   -- Kaitun Events stays as it is: switch it on yourself if you want it
		paintAll()
		print("[WORST Hub] Lite mode: idle, switched to the small window (Kaitun Hatch + Kaitun Stats on).")
	end
	record.exitLite = function()
		if not record.liteActive then return end
		record.liteActive = false
		if record.apply3d then record.apply3d() end   -- back to the full UI: 3D rendering on again (unless the Settings toggle keeps it off)
		lite.Visible = false
		window.Visible = true
		Config.fps.lite = false     -- back to the FPS Cap slider value
		Config.applyFps()
		Config.statusHideUntil = math.max(Config.statusHideUntil or 0, os.clock() + 60)   -- Show Status stays hidden for 1 minute after returning to the full UI
		lastActive = os.clock()
	end
	-- Settings > Mini Ui: the hub shrinks (towards its own centre) until it can't be seen, then closes and the Mini Ui opens
	record.miniUi = function()
		if record.liteActive or minimized or animating or dialogOpen or not alive then return false, "busy" end
		animating = true
		mode = nil
		if closeOpenDropdown then pcall(closeOpenDropdown) end
		local savedP = Vector2.new(window.Position.X.Offset, window.Position.Y.Offset)
		local savedS = uiScale.Scale
		local center = savedP + Vector2.new(WINDOW_W, WINDOW_H) * savedS / 2
		tw(window, { Position = UDim2.fromOffset(center.X, center.Y) }, 0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		local t = tw(uiScale, { Scale = 0.01 }, 0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		t.Completed:Wait()
		if not alive then return true end
		window.Visible = false
		window.Position = UDim2.fromOffset(savedP.X, savedP.Y)   -- put it back while it is hidden, so "Full UI" opens it exactly as it was
		uiScale.Scale = savedS
		animating = false
		enterLite(true)
		return true
	end
	fullBtn.MouseButton1Click:Connect(function() record.exitLite() end)

	------------------------------------------------ activity on the hub
	local function overWindow(pos)
		local p, s = window.AbsolutePosition, window.AbsoluteSize
		return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
	end
	-- Counts activity on the hub (resets the idle timer).
	local function bump()
		lastActive = os.clock()
		if popup.Visible then popup.Visible, popupAt = false, nil end
	end
	noBtn.MouseButton1Click:Connect(bump)
	connect(UserInputService.InputBegan, function(input)
		if not window.Visible then return end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 then
			if overWindow(UserInputService:GetMouseLocation()) then bump() end
		elseif t == Enum.UserInputType.Touch then
			local raw = Vector2.new(input.Position.X, input.Position.Y)
			if overWindow(raw) or overWindow(raw + GuiService:GetGuiInset()) then bump() end
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if window.Visible and input.UserInputType == Enum.UserInputType.MouseWheel
			and overWindow(UserInputService:GetMouseLocation()) then bump() end
	end)

	------------------------------------------------ the idle clock (one cheap check per second)
	task.spawn(function()
		while alive do
			if not AUTO_LITE then break end   -- automatic Mini Ui is off
			task.wait(1)
			if record.userToggled then break end   -- you toggled something yourself: Lite mode stays out of the way
			local busy = record.liteActive or not window.Visible or minimized or animating or dialogOpen
				or window:FindFirstChild("IntroBlocker") ~= nil
			if busy then
				lastActive = os.clock()
				if popup.Visible then popup.Visible, popupAt = false, nil end
			elseif popupAt then
				local left = math.ceil(AFK_SECS - (os.clock() - popupAt))
				if left <= 0 then
					enterLite()
				else
					popSub.Text = string.format("Switching to the Lite UI in %ds", left)
				end
			elseif os.clock() - lastActive >= IDLE_SECS then
				popupAt = os.clock()
				popSub.Text = string.format("Switching to the Lite UI in %ds", AFK_SECS)
				popup.Visible = true
			end
		end
		popup.Visible, popupAt = false, nil
	end)

	-- keep the two Lite switches in sync with the real toggles (only while the Lite window is showing)
	task.spawn(function()
		while alive do
			task.wait(0.5)
			if lite.Visible then paintAll() end
		end
	end)
end)
