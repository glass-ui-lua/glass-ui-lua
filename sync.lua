local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local env = (getgenv and getgenv()) or _G

do
	local prev = env.__SpeediSync
	if type(prev) == "table" and type(prev.Destroy) == "function" then pcall(prev.Destroy) end
	env.__SpeediSync = nil
end
assert(writefile and readfile and isfile and listfiles and makefolder and isfolder, "this executor has no file functions")

local seal, unseal
do
	local band, bxor, bnot, rrot, rshift = bit32.band, bit32.bxor, bit32.bnot, bit32.rrotate, bit32.rshift
	local K = {
		1116352408,1899447441,3049323471,3921009573,961987163,1508970993,
		2453635748,2870763221,3624381080,310598401,607225278,1426881987,
		1925078388,2162078206,2614888103,3248222580,3835390401,4022224774,
		264347078,604807628,770255983,1249150122,1555081692,1996064986,
		2554220882,2821834349,2952996808,3210313671,3336571891,3584528711,
		113926993,338241895,666307205,773529912,1294757372,1396182291,
		1695183700,1986661051,2177026350,2456956037,2730485921,2820302411,
		3259730800,3345764771,3516065817,3600352804,4094571909,275423344,
		430227734,506948616,659060556,883997877,958139571,1322822218,
		1537002063,1747873779,1955562222,2024104815,2227730452,2361852424,
		2428436474,2756734187,3204031479,3329325298,
	}
	local function sha256(msg)
		local H = { 1779033703,3144134277,1013904242,2773480762,1359893119,2600822924,528734635,1541459225 }
		local len = #msg
		local padded = msg .. "\128" .. string.rep("\0", (55 - len) % 64) .. string.pack(">I8", len * 8)
		for i = 1, #padded, 64 do
			local w = {}
			for j = 0, 15 do w[j + 1] = string.unpack(">I4", padded, i + j * 4) end
			for j = 17, 64 do
				local s0, s1 = w[j - 15], w[j - 2]
				w[j] = (w[j - 16] + bxor(rrot(s0, 7), rrot(s0, 18), rshift(s0, 3)) + w[j - 7]
					+ bxor(rrot(s1, 17), rrot(s1, 19), rshift(s1, 10))) % 4294967296
			end
			local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
			for j = 1, 64 do
				local S1 = bxor(rrot(e, 6), rrot(e, 11), rrot(e, 25))
				local ch = bxor(band(e, f), band(bnot(e), g))
				local t1 = (h + S1 + ch + K[j] + w[j]) % 4294967296
				local S0 = bxor(rrot(a, 2), rrot(a, 13), rrot(a, 22))
				local maj = bxor(band(a, b), band(a, c), band(b, c))
				local t2 = (S0 + maj) % 4294967296
				h = g; g = f; f = e; e = (d + t1) % 4294967296
				d = c; c = b; b = a; a = (t1 + t2) % 4294967296
			end
			H[1] = (H[1] + a) % 4294967296; H[2] = (H[2] + b) % 4294967296
			H[3] = (H[3] + c) % 4294967296; H[4] = (H[4] + d) % 4294967296
			H[5] = (H[5] + e) % 4294967296; H[6] = (H[6] + f) % 4294967296
			H[7] = (H[7] + g) % 4294967296; H[8] = (H[8] + h) % 4294967296
		end
		local out = {}
		for i = 1, 8 do out[i] = string.format("%08x", H[i]) end
		return table.concat(out)
	end
	local function hexToBin(h)
		return (h:gsub("%x%x", function(cc) return string.char(tonumber(cc, 16)) end))
	end
	local function hmacSha256(key, msg)
		if #key > 64 then key = hexToBin(sha256(key)) end
		local kp = key .. string.rep("\0", 64 - #key)
		local opad, ipad = {}, {}
		for i = 1, 64 do
			local b = kp:byte(i)
			opad[i] = string.char(bxor(b, 92))
			ipad[i] = string.char(bxor(b, 54))
		end
		return sha256(table.concat(opad) .. hexToBin(sha256(table.concat(ipad) .. msg)))
	end
	local function nonce()
		local t = {}
		for i = 1, 8 do t[#t + 1] = string.format("%02x", math.random(0, 255)) end
		return table.concat(t)
	end
	local function decrypt(token, nonceStr, hexData)
		if #hexData % 2 ~= 0 then return nil end
		local out = {}
		local n = #hexData // 2
		for i = 0, n - 1, 32 do
			local ks = hmacSha256(token, nonceStr .. ":" .. tostring(i // 32))
			for j = 0, 31 do
				local idx = i + j
				if idx >= n then break end
				local c = tonumber(hexData:sub(idx * 2 + 1, idx * 2 + 2), 16)
				local k = tonumber(ks:sub(j * 2 + 1, j * 2 + 2), 16)
				out[#out + 1] = string.char(bxor(c, k))
			end
		end
		return table.concat(out)
	end
	local SETTINGS_KEY = "SpeediBoi|Riddler|settings|v1|7c1e9a42d0b54f83"
	seal = function(plain)
		local n = nonce()
		local out = {}
		for i = 0, #plain - 1, 32 do
			local ks = hmacSha256(SETTINGS_KEY, n .. ":" .. tostring(i // 32))
			for j = 0, 31 do
				local idx = i + j
				if idx >= #plain then break end
				local k = tonumber(ks:sub(j * 2 + 1, j * 2 + 2), 16)
				out[#out + 1] = string.format("%02x", bxor(plain:byte(idx + 1), k))
			end
		end
		local hex = table.concat(out)
		return "SRC1." .. n .. "." .. hex .. "." .. string.sub(hmacSha256(SETTINGS_KEY, n .. "." .. hex), 1, 32)
	end
	unseal = function(sealed)
		local n, hex, tag = string.match(tostring(sealed), "^SRC1%.(%x+)%.(%x*)%.(%x+)%s*$")
		if not n then return nil end
		if string.sub(hmacSha256(SETTINGS_KEY, n .. "." .. hex), 1, 32) ~= tag then return nil end
		return decrypt(SETTINGS_KEY, n, hex)
	end

end

local DIR, ALTS_DIR = "riddler_sync", "riddler_sync/alts"
local SYNC_FILE, CONFIG_FILE = DIR .. "/sync.txt", "s_riddler_set_config.txt"
local ONLINE_SECONDS = 4
local SAVED_KEYS = { "enable", "autoListen", "autoRedeem", "autoCopy", "secure", "openFeed", "model" }
local DEFAULTS = { enable = true, autoListen = true, autoRedeem = true, autoCopy = false, secure = false, openFeed = false,
	model = "FASTER", listenKey = "R", phrases = { "the riddle is", "the riddle", "riddle" } }
local alive = true
local connections = {}

local function copySettings(src)
	local t = { listenKey = src.listenKey, phrasesV = 2, phrases = {} }
	for _, k in ipairs(SAVED_KEYS) do t[k] = src[k] end
	for _, p in ipairs(src.phrases or {}) do table.insert(t.phrases, p) end
	return t
end
local function cleanSettings(t)
	local out = copySettings(DEFAULTS)
	if type(t) ~= "table" then return out end
	for _, k in ipairs(SAVED_KEYS) do
		if type(t[k]) == type(DEFAULTS[k]) then out[k] = t[k] end
	end
	if out.model ~= "FASTER" and out.model ~= "FAST" then out.model = "FASTER" end
	if type(t.listenKey) == "string" and t.listenKey ~= "" then out.listenKey = t.listenKey end
	if type(t.phrases) == "table" then
		local list = {}
		for _, p in ipairs(t.phrases) do
			if type(p) == "string" and #p >= 2 then table.insert(list, string.lower(p)) end
		end
		if #list > 0 then out.phrases = list end
	end
	return out
end
local function sameSettings(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then return false end
	for _, k in ipairs(SAVED_KEYS) do
		if a[k] ~= b[k] then return false end
	end
	if tostring(a.listenKey) ~= tostring(b.listenKey) then return false end
	return table.concat(a.phrases or {}, "|") == table.concat(b.phrases or {}, "|")
end
local function readSealed(path)
	local ok, raw = pcall(function() return isfile(path) and readfile(path) end)
	if not ok or type(raw) ~= "string" then return nil end
	local plain = unseal(raw)
	local ok2, t = pcall(function() return plain and HttpService:JSONDecode(plain) end)
	return (ok2 and type(t) == "table") and t or nil
end
pcall(function()
	if not isfolder(DIR) then makefolder(DIR) end
	if not isfolder(ALTS_DIR) then makefolder(ALTS_DIR) end
end)

local sync = readSealed(SYNC_FILE)
if type(sync) ~= "table" or type(sync.groups) ~= "table" then
	sync = { v = 0, groups = { Everyone = { settings = cleanSettings(readSealed(CONFIG_FILE)), members = {} } }, order = { "Everyone" } }
end
sync.default = "Everyone"
sync.cmd = nil
if type(sync.groups.Everyone) ~= "table" then sync.groups.Everyone = { settings = cleanSettings(nil), members = {} } end
do
	local seen, order = { Everyone = true }, { "Everyone" }
	for _, n in ipairs(type(sync.order) == "table" and sync.order or {}) do
		if type(sync.groups[n]) == "table" and not seen[n] then seen[n] = true; table.insert(order, n) end
	end
	for n, g in pairs(sync.groups) do
		if type(g) == "table" and not seen[n] then seen[n] = true; table.insert(order, n) end
	end
	sync.order = order
	for _, n in ipairs(order) do
		local g = sync.groups[n]
		g.settings = cleanSettings(g.settings)
		local members = {}
		if n ~= "Everyone" and type(g.members) == "table" then
			for _, id in ipairs(g.members) do table.insert(members, tostring(id)) end
		end
		g.members = members
	end
end

local dirty = true
local function markDirty() dirty = true end
task.spawn(function()
	while alive do
		if dirty then
			dirty = false
			sync.v = (tonumber(sync.v) or 0) + 1
			pcall(function() writefile(SYNC_FILE, seal(HttpService:JSONEncode(sync))) end)
		end
		task.wait(0.15)
	end
end)

local function groupOf(id)
	for _, n in ipairs(sync.order) do
		if n ~= "Everyone" and table.find(sync.groups[n].members, id) then return n end
	end
	return "Everyone"
end
local function moveTo(id, target)
	for _, n in ipairs(sync.order) do
		local m = sync.groups[n].members
		local i = table.find(m, id)
		while i do table.remove(m, i); i = table.find(m, id) end
	end
	if target ~= "Everyone" and sync.groups[target] then table.insert(sync.groups[target].members, id) end
	markDirty()
end

local alts = {}
local function scanAlts()
	local ok, files = pcall(listfiles, ALTS_DIR)
	if not ok or type(files) ~= "table" then return end
	local found = {}
	for _, path in ipairs(files) do
		local id = string.match(tostring(path), "(%d+)%.txt$")
		if id then
			local info = readSealed(ALTS_DIR .. "/" .. id .. ".txt")
			if info then alts[id] = info; found[id] = true end
		end
	end
	for id in pairs(alts) do
		if not found[id] then alts[id] = nil end
	end
end
local function isOnline(info) return os.time() - (tonumber(info.t) or 0) <= ONLINE_SECONDS end

local rgb = Color3.fromRGB
local BG, CARD, FIELD, FIELD_HOVER = rgb(9, 8, 13), rgb(18, 14, 26), rgb(30, 23, 42), rgb(44, 33, 62)
local LINE, PURPLE, PURPLE_LINE, ORANGE = rgb(50, 37, 70), rgb(146, 98, 240), rgb(96, 62, 156), rgb(255, 138, 36)
local CREAM, INK, DIM = rgb(240, 230, 196), rgb(236, 232, 246), rgb(128, 118, 152)
local GREEN, RED, AMBER, OFF = rgb(96, 226, 140), rgb(255, 96, 112), rgb(255, 184, 70), rgb(58, 48, 78)

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function stroke(o, color, th) return new("UIStroke", { Color = color or LINE, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o) end
local function tween(o, t, props) TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play() end
local function label(parent, str, size, color, font, pos, sz, xAlign)
	return new("TextLabel", { BackgroundTransparency = 1, Text = str, TextSize = size, TextColor3 = color or INK, Font = font or Enum.Font.GothamBold,
		Position = pos, Size = sz, TextXAlignment = xAlign or Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 7 }, parent)
end
local function button(parent, str, pos, size, bg, fg, ts)
	local b = new("TextButton", { Text = str, Font = Enum.Font.GothamBold, TextSize = ts or 12, TextColor3 = fg or INK, AutoButtonColor = false,
		BackgroundColor3 = bg or FIELD, Position = pos, Size = size, ZIndex = 7 }, parent)
	corner(b, 8)
	b:SetAttribute("rest", bg or FIELD)
	b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = (b:GetAttribute("rest") == PURPLE) and rgb(166, 122, 255) or FIELD_HOVER }) end)
	b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundColor3 = b:GetAttribute("rest") or FIELD }) end)
	return b
end
local function setRest(b, color) b:SetAttribute("rest", color); b.BackgroundColor3 = color end

local W, H, HEADER = 600, 446, 44
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local function fitScale()
	local vp = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	return math.min(1, (vp.Y - 40) / H, (vp.X - 20) / W)
end
local gui = new("ScreenGui", { Name = "SpeediBoisSynchronizer", ResetOnSpawn = false, DisplayOrder = 998, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
local vp0 = camera and camera.ViewportSize or Vector2.new(1920, 1080)
local fit = fitScale()
local root = new("Frame", { Name = "Window", Size = UDim2.fromOffset(W, H), Position = UDim2.fromOffset(vp0.X / 2 - W * fit / 2, vp0.Y / 2 - H * fit / 2),
	BackgroundColor3 = BG, BorderSizePixel = 0, ZIndex = 1 }, gui)
corner(root, 14)
stroke(root, PURPLE_LINE, 1.5)
local uiScale = new("UIScale", { Scale = fit }, root)
if camera then
	table.insert(connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() uiScale.Scale = fitScale() end))
end
do
	local top = new("Frame", { Size = UDim2.new(1, 0, 0, 120), BackgroundColor3 = PURPLE, BorderSizePixel = 0, ZIndex = 2 }, root)
	corner(top, 14)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.84), NumberSequenceKeypoint.new(1, 1) }) }, top)
	local bottom = new("Frame", { Position = UDim2.new(0, 0, 1, -70), Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = ORANGE, BorderSizePixel = 0, ZIndex = 2 }, root)
	corner(bottom, 14)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.88) }) }, bottom)
end

local header = new("Frame", { Size = UDim2.new(1, 0, 0, HEADER), BackgroundTransparency = 1, Active = true, ZIndex = 6 }, root)
label(header, "SYNCHRONIZER", 16, CREAM, nil, UDim2.fromOffset(14, 5), UDim2.fromOffset(160, 20))
label(header, "by SpeediBoi", 9, DIM, Enum.Font.GothamMedium, UDim2.fromOffset(14, 25), UDim2.fromOffset(120, 12))
local statusText = label(header, "", 11, DIM, Enum.Font.GothamMedium, UDim2.fromOffset(330, 0), UDim2.new(1, -372, 1, 0), Enum.TextXAlignment.Right)
local tabRiddler = button(header, "Riddler", UDim2.fromOffset(160, 11), UDim2.fromOffset(72, 22), PURPLE, INK, 11)
local tabTyper = button(header, "Typer", UDim2.fromOffset(238, 11), UDim2.fromOffset(72, 22), FIELD, DIM, 11)
local btnMin = button(header, "-", UDim2.new(1, -32, 0, 11), UDim2.fromOffset(22, 22), FIELD, INK, 16)
new("Frame", { Position = UDim2.fromOffset(0, HEADER - 1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = LINE, BorderSizePixel = 0, ZIndex = 6 }, root)
local statusUntil = 0
local function setStatus(msg, color)
	statusText.Text = msg
	statusText.TextColor3 = color or DIM
	statusUntil = os.clock() + 3
end

local typerPage = new("Frame", { Position = UDim2.fromOffset(10, 52), Size = UDim2.fromOffset(580, 384), BackgroundColor3 = CARD, BorderSizePixel = 0,
	Visible = false, ZIndex = 5 }, root)
corner(typerPage, 10)
stroke(typerPage, LINE, 1)
label(typerPage, "TYPER", 22, CREAM, Enum.Font.GothamBlack, UDim2.fromOffset(0, 138), UDim2.new(1, 0, 0, 30), Enum.TextXAlignment.Center)
local wipPill = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 176), Size = UDim2.fromOffset(150, 24),
	BackgroundColor3 = rgb(60, 40, 14), Text = "WORK IN PROGRESS", TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = AMBER, ZIndex = 7 }, typerPage)
corner(wipPill, 12)
stroke(wipPill, rgb(120, 80, 24), 1)
label(typerPage, "Syncing Typer settings across your alts is coming soon.", 12, DIM, Enum.Font.GothamMedium, UDim2.fromOffset(0, 210),
	UDim2.new(1, 0, 0, 18), Enum.TextXAlignment.Center)

local left = new("Frame", { Position = UDim2.fromOffset(10, 52), Size = UDim2.fromOffset(290, 384), BackgroundColor3 = CARD, BorderSizePixel = 0, ZIndex = 5 }, root)
corner(left, 10)
stroke(left, LINE, 1)
label(left, "ALTS", 12, ORANGE, nil, UDim2.fromOffset(12, 6), UDim2.fromOffset(60, 18))
local onlineText = label(left, "", 11, DIM, Enum.Font.GothamMedium, UDim2.fromOffset(52, 6), UDim2.fromOffset(110, 18))
local btnClear = button(left, "CLEAR OFFLINE", UDim2.new(1, -106, 0, 6), UDim2.fromOffset(98, 20), FIELD, INK, 10)
local altList = new("ScrollingFrame", { Position = UDim2.fromOffset(6, 32), Size = UDim2.new(1, -12, 1, -38), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 3, ScrollBarImageColor3 = PURPLE, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 6 }, left)
new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, altList)
local altEmpty = label(left, "no alts yet - run riddler.luau on them", 11, DIM, Enum.Font.GothamMedium, UDim2.fromOffset(0, 60), UDim2.new(1, 0, 0, 18), Enum.TextXAlignment.Center)

local right = new("Frame", { Position = UDim2.fromOffset(310, 52), Size = UDim2.fromOffset(280, 384), BackgroundColor3 = CARD, BorderSizePixel = 0, ZIndex = 5 }, root)
corner(right, 10)
stroke(right, LINE, 1)
label(right, "GROUPS", 12, ORANGE, nil, UDim2.fromOffset(12, 6), UDim2.fromOffset(80, 18))
local chips = new("Frame", { Position = UDim2.fromOffset(10, 28), Size = UDim2.new(1, -20, 0, 54), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 6 }, right)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, chips)
local nameBox = new("TextBox", { Text = "", PlaceholderText = "new group name", PlaceholderColor3 = DIM, TextColor3 = INK, TextSize = 12, Font = Enum.Font.GothamMedium,
	ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = FIELD, Position = UDim2.fromOffset(10, 86),
	Size = UDim2.new(1, -86, 0, 26), ZIndex = 7 }, right)
corner(nameBox, 8)
new("UIPadding", { PaddingLeft = UDim.new(0, 9) }, nameBox)
local btnAdd = button(right, "+ ADD", UDim2.new(1, -72, 0, 86), UDim2.fromOffset(62, 26), PURPLE, INK, 12)
new("Frame", { Position = UDim2.fromOffset(10, 120), Size = UDim2.new(1, -20, 0, 1), BackgroundColor3 = LINE, BorderSizePixel = 0, ZIndex = 6 }, right)
local groupTitle = label(right, "", 14, CREAM, nil, UDim2.fromOffset(12, 126), UDim2.new(1, -110, 0, 20))
local groupCount = label(right, "", 10, DIM, Enum.Font.GothamMedium, UDim2.fromOffset(12, 144), UDim2.new(1, -110, 0, 12))
local btnDelete = button(right, "DELETE", UDim2.new(1, -78, 0, 128), UDim2.fromOffset(68, 22), rgb(60, 22, 34), RED, 11)

local selected = "Everyone"
local function sel() return sync.groups[selected].settings end
local painters = {}

local function switch(x, y, text_, key)
	local cell = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(126, 26), BackgroundColor3 = BG, BorderSizePixel = 0, ZIndex = 6 }, right)
	corner(cell, 8)
	stroke(cell, LINE, 1)
	label(cell, text_, 10, INK, nil, UDim2.fromOffset(8, 0), UDim2.new(1, -50, 1, 0))
	local track = new("TextButton", { Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(32, 16), BackgroundColor3 = OFF, ZIndex = 7 }, cell)
	corner(track, 8)
	local knob = new("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = CREAM, ZIndex = 8 }, track)
	corner(knob, 6)
	local function paint()
		local on = sel()[key] == true
		tween(track, 0.15, { BackgroundColor3 = on and PURPLE or OFF })
		tween(knob, 0.15, { Position = UDim2.fromOffset(on and 18 or 2, 2) })
	end
	table.insert(connections, track.Activated:Connect(function()
		sel()[key] = not sel()[key]
		markDirty()
		paint()
		setStatus(("%s: %s %s"):format(selected, text_:lower(), sel()[key] and "on" or "off"), GREEN)
	end))
	table.insert(painters, paint)
end
switch(10, 160, "ENABLE", "enable")
switch(144, 160, "AUTO LISTEN", "autoListen")
switch(10, 190, "AUTO REDEEM", "autoRedeem")
switch(144, 190, "SECURE (1-3)", "secure")
switch(10, 220, "AUTO COPY", "autoCopy")
switch(144, 220, "OPEN FEED", "openFeed")

label(right, "MODEL", 11, INK, nil, UDim2.fromOffset(12, 252), UDim2.fromOffset(80, 22))
do
	local chipsM = {}
	local function paintModel()
		for name, b in pairs(chipsM) do
			setRest(b, (sel().model == name) and PURPLE or FIELD)
			b.TextColor3 = (sel().model == name) and INK or DIM
		end
	end
	for i, name in ipairs({ "FASTER", "FAST" }) do
		local b = button(right, name, UDim2.fromOffset(i == 1 and 140 or 206, 252), UDim2.fromOffset(62, 22), FIELD, DIM, 10)
		chipsM[name] = b
		table.insert(connections, b.Activated:Connect(function()
			sel().model = name
			markDirty()
			paintModel()
			setStatus(selected .. ": model " .. name, GREEN)
		end))
	end
	table.insert(painters, paintModel)
end

label(right, "TRIGGER PHRASES (comma separated)", 10, INK, nil, UDim2.fromOffset(12, 280), UDim2.new(1, -24, 0, 14))
local phraseBox = new("TextBox", { Text = "", PlaceholderText = "the riddle is, the riddle, riddle", PlaceholderColor3 = DIM, TextColor3 = CREAM,
	TextSize = 11, Font = Enum.Font.GothamMedium, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	BackgroundColor3 = FIELD, Position = UDim2.fromOffset(10, 296), Size = UDim2.new(1, -20, 0, 24), ZIndex = 7 }, right)
corner(phraseBox, 8)
new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }, phraseBox)
table.insert(painters, function() if not phraseBox:IsFocused() then phraseBox.Text = table.concat(sel().phrases, ", ") end end)
table.insert(connections, phraseBox.FocusLost:Connect(function()
	local list = {}
	for part in string.gmatch(phraseBox.Text, "[^,]+") do
		local p = string.lower((string.gsub(part, "^%s*(.-)%s*$", "%1")))
		if #p >= 2 and not table.find(list, p) then table.insert(list, p) end
	end
	if #list == 0 then
		setStatus("keep at least one trigger phrase", AMBER)
	else
		sel().phrases = list
		markDirty()
		setStatus(selected .. ": " .. #list .. " trigger phrases", GREEN)
	end
	phraseBox.Text = table.concat(sel().phrases, ", ")
end))

label(right, "LISTEN NOW", 11, INK, nil, UDim2.fromOffset(12, 326), UDim2.fromOffset(100, 22))
local btnOn = button(right, "ON", UDim2.fromOffset(140, 326), UDim2.fromOffset(62, 22), FIELD, GREEN, 11)
local btnOff = button(right, "OFF", UDim2.fromOffset(206, 326), UDim2.fromOffset(62, 22), FIELD, RED, 11)
local btnAll = button(right, "SET ALL GROUPS TO THESE SETTINGS", UDim2.fromOffset(10, 352), UDim2.new(1, -20, 0, 24), PURPLE, INK, 11)

local renderAlts
local function renderGroups()
	for _, c in ipairs(chips:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for i, name in ipairs(sync.order) do
		local chip = new("TextButton", { LayoutOrder = i, AutoButtonColor = false, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24),
			Text = name, TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = (name == selected) and INK or CREAM,
			BackgroundColor3 = (name == selected) and PURPLE or FIELD, ZIndex = 7 }, chips)
		corner(chip, 12)
		new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, chip)
		chip.Activated:Connect(function()
			selected = name
			renderGroups()
		end)
	end
	groupTitle.Text = selected
	local n = 0
	for id in pairs(alts) do
		if groupOf(id) == selected then n += 1 end
	end
	groupCount.Text = (selected == "Everyone") and ("alts in no other group: " .. n) or ("alts in this group: " .. n)
	btnDelete.Visible = selected ~= "Everyone"
	for _, paint in ipairs(painters) do pcall(paint) end
end

local function ago(sec)
	if sec < 60 then return sec .. "s" end
	if sec < 3600 then return math.floor(sec / 60) .. "m" end
	return math.floor(sec / 3600) .. "h"
end
renderAlts = function()
	for _, c in ipairs(altList:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	local list, online = {}, 0
	for id, info in pairs(alts) do
		local on = isOnline(info)
		if on then online += 1 end
		table.insert(list, { id = id, info = info, on = on })
	end
	table.sort(list, function(a, b)
		if a.on ~= b.on then return a.on end
		return tostring(a.info.display or a.info.name):lower() < tostring(b.info.display or b.info.name):lower()
	end)
	onlineText.Text = ("%d online / %d"):format(online, #list)
	altEmpty.Visible = #list == 0
	for i, e in ipairs(list) do
		local info, g = e.info, groupOf(e.id)
		local row = new("TextButton", { LayoutOrder = i, Text = "", AutoButtonColor = false, Size = UDim2.new(1, -4, 0, 48), BackgroundColor3 = BG, ZIndex = 7 }, altList)
		corner(row, 8)
		stroke(row, (g == selected) and PURPLE_LINE or LINE, 1)
		local dot = new("Frame", { Position = UDim2.fromOffset(10, 11), Size = UDim2.fromOffset(8, 8), ZIndex = 8,
			BackgroundColor3 = (not e.on) and OFF or (info.listen and GREEN or AMBER) }, row)
		corner(dot, 4)
		new("TextLabel", { BackgroundTransparency = 1, RichText = true, Position = UDim2.fromOffset(24, 4), Size = UDim2.new(1, -30, 0, 18), ZIndex = 8,
			Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = e.on and INK or DIM, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			Text = ('%s  <font color="#807898">@%s</font>'):format(tostring(info.display or "?"), tostring(info.name or "?")) }, row)
		local pill = new("TextButton", { Position = UDim2.fromOffset(24, 25), Size = UDim2.fromOffset(92, 18), Text = g, TextSize = 10, Font = Enum.Font.GothamBold,
			TextColor3 = INK, BackgroundColor3 = (g == "Everyone") and FIELD or PURPLE_LINE, AutoButtonColor = false, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 9 }, row)
		corner(pill, 9)
		local stateText, stateColor
		if not e.on then
			stateText, stateColor = "offline " .. ago(math.max(0, os.time() - (tonumber(info.t) or 0))), DIM
		else
			local synced = sameSettings(info.settings, sync.groups[g].settings) and info.group == g
			stateText = (info.listen and "listening" or "not listening") .. "  -  " .. (synced and "synced" or "updating...")
			stateColor = synced and GREEN or AMBER
		end
		new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(122, 25), Size = UDim2.new(1, -128, 0, 18), ZIndex = 8, Font = Enum.Font.GothamMedium,
			TextSize = 10, TextColor3 = stateColor, Text = stateText, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)
		pill.Activated:Connect(function()
			local idx = table.find(sync.order, g) or 1
			local nextG = sync.order[idx % #sync.order + 1]
			moveTo(e.id, nextG)
			setStatus(("%s -> %s"):format(tostring(info.display or info.name), nextG), GREEN)
			renderAlts()
			renderGroups()
		end)
		row.Activated:Connect(function()
			selected = g
			renderGroups()
			renderAlts()
		end)
	end
end

local function addGroup()
	local name = string.gsub(nameBox.Text, "^%s*(.-)%s*$", "%1")
	name = string.gsub(name, "[^%w%s%-_]", "")
	name = string.sub(name, 1, 16)
	if #name < 1 then setStatus("type a group name first", AMBER) return end
	if sync.groups[name] then setStatus("that group already exists", AMBER) return end
	sync.groups[name] = { settings = copySettings(sel()), members = {} }
	table.insert(sync.order, name)
	selected = name
	nameBox.Text = ""
	markDirty()
	setStatus("group " .. name .. " made - click an alt's group pill to move it in", GREEN)
	renderGroups()
	renderAlts()
end
table.insert(connections, btnAdd.Activated:Connect(addGroup))
table.insert(connections, nameBox.FocusLost:Connect(function(enter) if enter then addGroup() end end))
table.insert(connections, btnDelete.Activated:Connect(function()
	if selected == "Everyone" then return end
	local gone = selected
	sync.groups[gone] = nil
	local i = table.find(sync.order, gone)
	if i then table.remove(sync.order, i) end
	selected = "Everyone"
	markDirty()
	setStatus("group " .. gone .. " deleted - its alts went back to Everyone", AMBER)
	renderGroups()
	renderAlts()
end))
local function listenCommand(on)
	sync.cmd = { id = HttpService:GenerateGUID(false), t = os.time(), group = selected, listen = on }
	markDirty()
	setStatus(("%s: listen %s"):format(selected, on and "on" or "off"), on and GREEN or AMBER)
end
table.insert(connections, btnOn.Activated:Connect(function() listenCommand(true) end))
table.insert(connections, btnOff.Activated:Connect(function() listenCommand(false) end))
table.insert(connections, btnAll.Activated:Connect(function()
	local src = copySettings(sel())
	for _, n in ipairs(sync.order) do sync.groups[n].settings = copySettings(src) end
	markDirty()
	setStatus("every group now has " .. selected .. "'s settings", GREEN)
	renderAlts()
end))
table.insert(connections, btnClear.Activated:Connect(function()
	local n = 0
	for id, info in pairs(alts) do
		if not isOnline(info) then
			pcall(function() delfile(ALTS_DIR .. "/" .. id .. ".txt") end)
			alts[id] = nil
			n += 1
		end
	end
	setStatus(("cleared %d offline alt%s"):format(n, n == 1 and "" or "s"), DIM)
	renderAlts()
end))

local currentTab, folded = "Riddler", false
local function applyVisibility()
	left.Visible = not folded and currentTab == "Riddler"
	right.Visible = not folded and currentTab == "Riddler"
	typerPage.Visible = not folded and currentTab == "Typer"
end
local function setTab(name)
	currentTab = name
	setRest(tabRiddler, name == "Riddler" and PURPLE or FIELD)
	tabRiddler.TextColor3 = name == "Riddler" and INK or DIM
	setRest(tabTyper, name == "Typer" and PURPLE or FIELD)
	tabTyper.TextColor3 = name == "Typer" and INK or DIM
	if folded then
		folded = false
		root.Size = UDim2.fromOffset(W, H)
		btnMin.Text = "-"
	end
	applyVisibility()
end
table.insert(connections, tabRiddler.Activated:Connect(function() setTab("Riddler") end))
table.insert(connections, tabTyper.Activated:Connect(function() setTab("Typer") end))

do
	local dragging, dragStart, startPos
	table.insert(connections, header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart, startPos = true, input.Position, root.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end))
	table.insert(connections, UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			root.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
		end
	end))
	table.insert(connections, btnMin.Activated:Connect(function()
		folded = not folded
		applyVisibility()
		root.Size = folded and UDim2.fromOffset(W, HEADER) or UDim2.fromOffset(W, H)
		btnMin.Text = folded and "+" or "-"
	end))
	table.insert(connections, UIS.InputBegan:Connect(function(input, gp)
		if not gp and input.KeyCode == Enum.KeyCode.RightControl then gui.Enabled = not gui.Enabled end
	end))
end

local api = {}
function api.Destroy()
	if not alive then return end
	alive = false
	if dirty then pcall(function() writefile(SYNC_FILE, seal(HttpService:JSONEncode(sync))) end) end
	for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
	pcall(function() gui:Destroy() end)
	if env.__SpeediSync == api then env.__SpeediSync = nil end
end
env.__SpeediSync = api

scanAlts()
renderGroups()
renderAlts()
task.spawn(function()
	while alive do
		task.wait(1)
		if not alive then break end
		scanAlts()
		renderAlts()
		if os.clock() > statusUntil then
			statusText.Text = "sync file: riddler_sync/sync.txt"
			statusText.TextColor3 = DIM
		end
		local n = 0
		for id in pairs(alts) do
			if groupOf(id) == selected then n += 1 end
		end
		groupCount.Text = (selected == "Everyone") and ("alts in no other group: " .. n) or ("alts in this group: " .. n)
	end
end)
print("[Synchronizer] ready. Run riddler.luau on your alts and they show up here.")
