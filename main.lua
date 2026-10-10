--// Liquid Glass UI Library for Roblox
--// Apple-style liquid glass: frosted blur of the world behind the window
--// (acrylic), visible glass tiles with a two-corner specular rim, soft
--// colour glows, pill controls and iOS switches. WindUI-style API.
--//
--//   local LiquidGlass = loadstring(game:HttpGet("https://raw.githubusercontent.com/glass-ui-lua/glass-ui-lua/refs/heads/main/main.lua"))()
--//   local Window = LiquidGlass:CreateWindow({ Title = "My Script", Author = "me" })
--//   local Tab    = Window:Tab({ Title = "Main" })
--//   Tab:Section({ Title = "General" })
--//   Tab:Toggle({ Title = "Enabled", Value = false, Callback = function(v) print(v) end })
--//
--// Elements : Section, Label, Paragraph, Divider, Button, Toggle, Slider,
--//            Dropdown (single / multi / search), Input, Keybind, ColorPicker,
--//            Progress, Custom, List, Grid
--// Window   : Tab, NavButton, Dialog, Notify, SetStatus, SetTitle, SetToggleKey,
--//            SetAcrylic, SetBlur, SetTransparency, Minimize, Open / Close /
--//            Toggle, Resize, Destroy, OnDestroy, AddSettingsTab,
--//            SaveConfig / LoadConfig / ListConfigs / AutoSave
--// Library  : CreateWindow, Notify, SetTheme (live), AddTheme, GetFlag,
--//            DestroyAll, Creator (raw toolkit: Glass, Glassify, Button, Label,
--//            Switch, TextBox, Scroller, SectionTitle, Badge, Glow, Shadow,
--//            Draggable, Tween, Flash)
--// Elements : :Set, :Get, :SetTitle, :SetDesc, :SetVisible, :Lock, :Unlock,
--//            :SetCallback, :Destroy

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local TextService       = game:GetService("TextService")
local Lighting          = game:GetService("Lighting")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local LiquidGlass = {
    Version = "3.0.0",
    Windows = {},
    Flags   = {},
    Themes  = {},
    Theme   = nil,
    Creator = {},
    Fonts   = { Regular = Enum.Font.Gotham, Medium = Enum.Font.GothamMedium, Bold = Enum.Font.GothamBold, Black = Enum.Font.GothamBlack },
}

local Fonts = LiquidGlass.Fonts

-- soft 9-slice drop shadow sprite (the only asset the library uses)
local SHADOW_IMAGE = "rbxassetid://6015897843"

-- file API (executor dependent, all optional)
local f_write    = writefile  or (syn and syn.writefile)
local f_read     = readfile   or (syn and syn.readfile)
local f_isfile   = isfile     or (syn and syn.isfile)
local f_isfolder = isfolder
local f_mkdir    = makefolder
local f_list     = listfiles

local function warnf(...) warn("[LiquidGlass]", ...) end

--==================================================================--
--  Themes
--==================================================================--

local function theme(t)
    t.White  = Color3.fromRGB(255, 255, 255)
    t.Black  = Color3.fromRGB(0, 0, 0)
    t.Glass       = t.Glass       or Color3.fromRGB(255, 255, 255)
    t.GlassBottom = t.GlassBottom or Color3.fromRGB(205, 205, 220)
    t.GlassT      = t.GlassT      or 0.88
    t.GlassHoverT = t.GlassHoverT or 0.8
    t.GlassGradient = ColorSequence.new(t.Glass, t.GlassBottom)
    t.Sheen  = t.Sheen  or Color3.fromRGB(255, 255, 255)
    t.Rim    = t.Rim    or Color3.fromRGB(255, 255, 255)
    t.RimT   = t.RimT   or 0.2
    t.Green  = t.Green  or Color3.fromRGB(48, 209, 88)
    t.Red    = t.Red    or Color3.fromRGB(255, 69, 58)
    t.Gold   = t.Gold   or Color3.fromRGB(255, 214, 10)
    t.Orange = t.Orange or Color3.fromRGB(255, 159, 10)
    t.Off    = t.Off    or Color3.fromRGB(120, 120, 128)
    t.OffT   = t.OffT   or 0.55
    t.AccentHi = t.AccentHi or t.Accent:Lerp(Color3.new(1, 1, 1), 0.3)
    t.ShellT = t.ShellT or 0.25
    t.WindowTransparency = t.ShellT
    return t
end

LiquidGlass.Themes.Dark = theme({
    Name = "Dark",
    Base = Color3.fromRGB(10, 10, 14), ShellT = 0.25,
    Text = Color3.fromRGB(245, 245, 250), Secondary = Color3.fromRGB(200, 200, 212), Muted = Color3.fromRGB(150, 150, 165),
    Glass = Color3.fromRGB(255, 255, 255), GlassBottom = Color3.fromRGB(200, 200, 218), GlassT = 0.88, GlassHoverT = 0.8,
    Rim = Color3.fromRGB(255, 255, 255), RimT = 0.2,
    Accent = Color3.fromRGB(10, 132, 255), AccentHi = Color3.fromRGB(110, 185, 255),
    Field = Color3.fromRGB(0, 0, 0), FieldT = 0.7,
    MenuSurface = Color3.fromRGB(30, 30, 38), MenuT = 0.18,
    ModalFrost = Color3.fromRGB(22, 22, 30), ModalFrostT = 0.12,
    Scrim = Color3.fromRGB(0, 0, 0), ScrimT = 0.5,
    MeshA = Color3.fromRGB(175, 82, 222), MeshB = Color3.fromRGB(10, 132, 255), MeshC = Color3.fromRGB(255, 55, 95), MeshAlpha = 0.22,
})
LiquidGlass.Themes.Light = theme({
    Name = "Light",
    Base = Color3.fromRGB(238, 240, 246), ShellT = 0.2,
    Text = Color3.fromRGB(28, 28, 34), Secondary = Color3.fromRGB(72, 72, 84), Muted = Color3.fromRGB(125, 125, 138),
    Glass = Color3.fromRGB(255, 255, 255), GlassBottom = Color3.fromRGB(238, 238, 246), GlassT = 0.45, GlassHoverT = 0.3,
    Rim = Color3.fromRGB(150, 155, 175), RimT = 0.35,
    Accent = Color3.fromRGB(0, 122, 255), AccentHi = Color3.fromRGB(70, 160, 255),
    Off = Color3.fromRGB(120, 120, 128), OffT = 0.7,
    Field = Color3.fromRGB(255, 255, 255), FieldT = 0.3,
    MenuSurface = Color3.fromRGB(248, 249, 252), MenuT = 0.08,
    ModalFrost = Color3.fromRGB(250, 250, 253), ModalFrostT = 0.06,
    Scrim = Color3.fromRGB(0, 0, 0), ScrimT = 0.7,
    MeshA = Color3.fromRGB(175, 82, 222), MeshB = Color3.fromRGB(0, 122, 255), MeshC = Color3.fromRGB(255, 55, 95), MeshAlpha = 0.16,
})
LiquidGlass.Theme = LiquidGlass.Themes.Dark

local function th() return LiquidGlass.Theme end

-- Every instance painted with a theme key is remembered here so a theme
-- switch can repaint live windows. Weak keys: destroyed guis fall out.
local Themed = setmetatable({}, { __mode = "k" })

function LiquidGlass:AddTheme(name, t)
    t.Name = name
    self.Themes[name] = theme(t)
    return self.Themes[name]
end

--==================================================================--
--  Creator: low-level glass toolkit (usable on its own)
--==================================================================--

local Creator = LiquidGlass.Creator

-- Remember that `inst[prop]` should follow theme key `key` (a string such
-- as "Accent" or "GlassT"). Pass a value instead of a key and it stays fixed.
function Creator.Themed(inst, map)
    local m = Themed[inst]
    if not m then m = {} Themed[inst] = m end
    for p, k in pairs(map) do
        if type(k) == "string" then
            m[p] = k
            local v = th()[k]
            if v ~= nil then inst[p] = v end
        else
            m[p] = nil
            if k ~= nil then inst[p] = k end
        end
    end
    return inst
end

local function col(c, fallbackKey)
    if type(c) == "string" then return th()[c] or th()[fallbackKey] end
    return c or th()[fallbackKey]
end

function Creator.Corner(i, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r == "full" and UDim.new(1, 0) or UDim.new(0, r or 12)
    c.Parent = i
    return c
end

function Creator.Pad(i, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft, p.PaddingRight = UDim.new(0, l or 0), UDim.new(0, r or 0)
    p.PaddingTop, p.PaddingBottom = UDim.new(0, t or 0), UDim.new(0, b or 0)
    p.Parent = i
    return p
end

function Creator.Tween(i, props, t, style, dir)
    local tw = TweenService:Create(i, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

-- color: Color3, or a theme key string ("Text", "Muted", "Accent", ...)
function Creator.Label(parent, text, size, color, font, xalign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.Font = font or Fonts.Regular
    l.TextSize = size or 13
    l.TextXAlignment = xalign or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    if type(color) == "string" then Creator.Themed(l, { TextColor3 = color })
    else l.TextColor3 = color or th().Text end
    return l
end

local function textHeight(text, size, font, width)
    local ok, v = pcall(function()
        return TextService:GetTextSize(text, size, font, Vector2.new(width, 10000))
    end)
    return ok and v.Y or size + 4
end
local function textWidth(text, size, font)
    local ok, v = pcall(function()
        return TextService:GetTextSize(text, size, font, Vector2.new(10000, 100))
    end)
    return ok and v.X or #text * size * 0.55
end

-- Specular rim: a bright edge at the top-left and bottom-right corners that
-- fades out along the sides, the way light bends through a glass edge.
local function addRim(inst, thickness, chip)
    local st = Instance.new("UIStroke")
    st.Name = "Rim"
    st.Thickness = thickness or 1.2
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    st.Parent = inst
    Creator.Themed(st, { Color = "Rim", Transparency = "RimT" })
    local g = Instance.new("UIGradient")
    g.Rotation = 45
    g.Transparency = chip
        and NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.45, 0.85), NumberSequenceKeypoint.new(1, 0.55) })
        or NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.35, 0.82), NumberSequenceKeypoint.new(0.65, 0.82), NumberSequenceKeypoint.new(1, 0.3) })
    g.Parent = st
    return st
end

-- top-left light sheen laid over a surface
local function addSheen(inst, radius, strength)
    local sheen = Instance.new("Frame")
    sheen.Name = "Sheen"
    sheen.Size = UDim2.fromScale(1, 1)
    sheen.BorderSizePixel = 0
    sheen.ZIndex = inst.ZIndex
    sheen.Parent = inst
    Creator.Themed(sheen, { BackgroundColor3 = "Sheen" })
    Creator.Corner(sheen, radius)
    local g = Instance.new("UIGradient")
    g.Rotation = 120
    local s = strength or 0.86
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, s), NumberSequenceKeypoint.new(0.35, s + (1 - s) * 0.75), NumberSequenceKeypoint.new(1, 1),
    })
    g.Parent = sheen
    return sheen
end

-- Turn any GuiObject into a glass surface.
-- tier: "panel" (default) | "chip" | "menu" | "modal", or a number = custom transparency
function Creator.Glassify(inst, tier, radius)
    local custom
    if type(tier) == "number" then custom, tier = tier, "panel" end
    tier = tier or "panel"
    local r = radius or (tier == "modal" and 20 or tier == "chip" and "full" or 12)
    inst.BorderSizePixel = 0
    Creator.Corner(inst, r)
    if tier == "menu" then
        Creator.Themed(inst, { BackgroundColor3 = "MenuSurface", BackgroundTransparency = custom or "MenuT" })
    elseif tier == "modal" then
        Creator.Themed(inst, { BackgroundColor3 = "ModalFrost", BackgroundTransparency = custom or "ModalFrostT" })
    else
        Creator.Themed(inst, { BackgroundColor3 = "Glass", BackgroundTransparency = custom or "GlassT" })
        local g = Instance.new("UIGradient")
        g.Name = "Tint"
        g.Rotation = 90
        g.Parent = inst
        Creator.Themed(g, { Color = "GlassGradient" })
    end
    if tier ~= "chip" then addSheen(inst, r, tier == "panel" and 0.86 or 0.9) end
    addRim(inst, tier == "chip" and 1 or 1.2, tier == "chip")
    inst:SetAttribute("GlassTier", tier)
    return inst
end

-- Creator.Glass(parent, tier, radius) -> Frame
function Creator.Glass(parent, tier, radius)
    local f = Instance.new("Frame")
    f.Name = "Glass"
    f.ClipsDescendants = true
    f.Parent = parent
    Creator.Glassify(f, tier, radius)
    return f, f:FindFirstChild("Rim")
end

-- hover: brighten the tint
function Creator.Hover(f, hit)
    hit = hit or f
    hit.MouseEnter:Connect(function() Creator.Tween(f, { BackgroundTransparency = th().GlassHoverT }, 0.15) end)
    hit.MouseLeave:Connect(function() Creator.Tween(f, { BackgroundTransparency = th().GlassT }, 0.2) end)
end

function Creator.PressScale(btn)
    local sc = Instance.new("UIScale")
    sc.Parent = btn
    btn.MouseEnter:Connect(function() Creator.Tween(sc, { Scale = 1.04 }, 0.15, Enum.EasingStyle.Back) end)
    btn.MouseLeave:Connect(function() Creator.Tween(sc, { Scale = 1 }, 0.18) end)
    btn.MouseButton1Down:Connect(function() Creator.Tween(sc, { Scale = 0.95 }, 0.08) end)
    btn.MouseButton1Up:Connect(function() Creator.Tween(sc, { Scale = 1.04 }, 0.16, Enum.EasingStyle.Back) end)
    return sc
end

-- Pill button. tint: nil = glass; Color3 or theme key = branded (rim kept)
function Creator.Button(parent, text, tint, textColor, textSize)
    local b = Instance.new("TextButton")
    b.Name = "Button"
    b.AutoButtonColor = false
    b.Text = text or ""
    b.Font = Fonts.Bold
    b.TextSize = textSize or 11
    b.Parent = parent
    Creator.Glassify(b, "chip")
    local base
    if tint then
        local g = b:FindFirstChild("Tint")
        if g then g:Destroy() end
        if type(tint) == "string" then Creator.Themed(b, { BackgroundColor3 = tint, BackgroundTransparency = 0.35 })
        else Themed[b] = nil b.BackgroundColor3 = tint b.BackgroundTransparency = 0.35 end
        base = 0.35
        b.TextColor3 = th().White
    else
        base = th().GlassT
    end
    if type(textColor) == "string" then Creator.Themed(b, { TextColor3 = textColor })
    elseif textColor then b.TextColor3 = textColor end
    Creator.PressScale(b)
    b.MouseEnter:Connect(function() Creator.Tween(b, { BackgroundTransparency = tint and 0.15 or th().GlassHoverT }, 0.15) end)
    b.MouseLeave:Connect(function() Creator.Tween(b, { BackgroundTransparency = tint and base or th().GlassT }, 0.2) end)
    return b
end

-- flash a result on a button, then restore its label
function Creator.Flash(btn, text, color, restoreText, restoreColor, hold)
    btn.Text = text
    btn.TextColor3 = col(color, "Text")
    task.delay(hold or 2, function()
        if btn.Parent then
            btn.Text = restoreText
            btn.TextColor3 = col(restoreColor, "Text")
        end
    end)
end

function Creator.Scroller(parent, pos, size)
    local s = Instance.new("ScrollingFrame")
    s.Position = pos or UDim2.new()
    s.Size = size or UDim2.fromScale(1, 1)
    s.BackgroundTransparency = 1
    s.BorderSizePixel = 0
    s.ScrollBarThickness = 3
    s.ScrollBarImageTransparency = 0.5
    s.CanvasSize = UDim2.new()
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    s.ScrollingDirection = Enum.ScrollingDirection.Y
    s.Parent = parent
    Creator.Themed(s, { ScrollBarImageColor3 = "Muted" })
    return s
end

-- small caps header with a short accent bar
function Creator.SectionTitle(parent, text, x, y)
    x, y = x or 12, y or 12
    local bar = Instance.new("Frame")
    bar.Size = UDim2.fromOffset(3, 12)
    bar.Position = UDim2.fromOffset(x, y + 1)
    bar.BorderSizePixel = 0
    bar.Parent = parent
    Creator.Themed(bar, { BackgroundColor3 = "Accent" })
    Creator.Corner(bar, 2)
    local l = Creator.Label(parent, tostring(text or ""):upper(), 11, "Muted", Fonts.Bold)
    l.Size = UDim2.new(1, -(x + 10) - 12, 0, 14)
    l.Position = UDim2.fromOffset(x + 10, y)
    return l, bar
end

-- round letter badge (e.g. first letter of a name) centred in a holder
function Creator.Badge(holder, letter, color, size)
    size = size or 26
    local b = Instance.new("Frame")
    b.Name = "Badge"
    b.Size = UDim2.fromOffset(size, size)
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.Position = UDim2.fromScale(0.5, 0.5)
    b.BackgroundColor3 = col(color, "Accent")
    b.BackgroundTransparency = 0.25
    b.BorderSizePixel = 0
    b.ZIndex = holder.ZIndex + 1
    b.Parent = holder
    Creator.Corner(b, "full")
    addRim(b, 1, true)
    local t = Creator.Label(b, tostring(letter or "?"):sub(1, 1):upper(), math.floor(size * 0.46), th().White, Fonts.Black, Enum.TextXAlignment.Center)
    t.Size = UDim2.fromScale(1, 1)
    t.ZIndex = b.ZIndex + 1
    return b
end

-- inset text field (a darker "well" with a rim); returns wrap frame and the TextBox
function Creator.TextBox(parent, placeholder, text, textSize)
    local w = Instance.new("Frame")
    w.Name = "Field"
    w.BorderSizePixel = 0
    w.ClipsDescendants = true
    w.Parent = parent
    Creator.Corner(w, 9)
    Creator.Themed(w, { BackgroundColor3 = "Field", BackgroundTransparency = "FieldT" })
    addRim(w, 1, true)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 1, 0)
    box.Position = UDim2.fromOffset(10, 0)
    box.BackgroundTransparency = 1
    box.PlaceholderText = placeholder or ""
    box.Text = text or ""
    box.Font = Fonts.Regular
    box.TextSize = textSize or 11
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.ClipsDescendants = true
    box.ZIndex = w.ZIndex + 1
    box.Parent = w
    Creator.Themed(box, { TextColor3 = "Text", PlaceholderColor3 = "Muted" })
    return w, box
end

-- iOS switch; returns controller with :Set(on, animate, silent) and .Button
function Creator.Switch(parent, initial, onChange)
    local track = Instance.new("TextButton")
    track.AutoButtonColor = false
    track.Text = ""
    track.Size = UDim2.fromOffset(42, 24)
    track.BorderSizePixel = 0
    track.Parent = parent
    Creator.Corner(track, "full")
    addRim(track, 1, true)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(20, 20)
    knob.BorderSizePixel = 0
    knob.BackgroundColor3 = th().White
    knob.ZIndex = track.ZIndex + 1
    knob.Parent = track
    Creator.Corner(knob, "full")
    local ks = Instance.new("UIStroke")
    ks.Color = th().Black
    ks.Transparency = 0.82
    ks.Parent = knob
    local ctl = { Button = track, Value = initial == true }
    function ctl:Paint(anim)
        local on = self.Value
        local pos = on and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        local key = on and "Green" or "Off"
        local tr = on and 0 or th().OffT
        Themed[track] = { BackgroundColor3 = key }
        if anim then
            Creator.Tween(track, { BackgroundColor3 = th()[key], BackgroundTransparency = tr }, 0.18)
            Creator.Tween(knob, { Position = pos }, 0.22, Enum.EasingStyle.Back)
        else
            track.BackgroundColor3 = th()[key]
            track.BackgroundTransparency = tr
            knob.Position = pos
        end
    end
    function ctl:Set(on, anim, silent)
        self.Value = on == true
        self:Paint(anim ~= false)
        if not silent and onChange then onChange(self.Value) end
    end
    ctl:Paint(false)
    track.MouseButton1Click:Connect(function() ctl:Set(not ctl.Value, true) end)
    return ctl
end

-- soft colour glow built from stacked circles (no image asset needed)
-- color: Color3 or theme key; alpha = opacity at the centre
function Creator.Glow(parent, color, pos, size, alpha, layers)
    layers = layers or 10
    alpha = alpha or 0.2
    local holder = Instance.new("Frame")
    holder.Name = "Glow"
    holder.BackgroundTransparency = 1
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = pos
    holder.Size = size
    holder.ZIndex = parent.ZIndex
    holder.Parent = parent
    local per = 1 - (1 - alpha) ^ (1 / layers)
    for i = 1, layers do
        local s = 1 - (i - 1) / layers
        local c = Instance.new("Frame")
        c.AnchorPoint = Vector2.new(0.5, 0.5)
        c.Position = UDim2.fromScale(0.5, 0.5)
        c.Size = UDim2.fromScale(s, s)
        c.BackgroundTransparency = 1 - per
        c.BorderSizePixel = 0
        c.ZIndex = holder.ZIndex
        c.Parent = holder
        Creator.Corner(c, "full")
        if type(color) == "string" then Creator.Themed(c, { BackgroundColor3 = color }) else c.BackgroundColor3 = color end
    end
    return holder
end

-- ambient colour behind the glass (what the tiles "pick up")
function Creator.Mesh(parent)
    local holder = Instance.new("Frame")
    holder.Name = "Mesh"
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromScale(1, 1)
    holder.ZIndex = parent.ZIndex
    holder.Parent = parent
    local a = th().MeshAlpha or 0.2
    Creator.Glow(holder, "MeshA", UDim2.fromScale(0.3, 0.36), UDim2.fromScale(0.52, 0.64), a)
    Creator.Glow(holder, "MeshB", UDim2.fromScale(0.7, 0.42), UDim2.fromScale(0.5, 0.7), a * 0.9)
    Creator.Glow(holder, "MeshC", UDim2.fromScale(0.5, 0.74), UDim2.fromScale(0.5, 0.46), a * 0.75)
    return holder
end

-- soft drop shadow sprite (9-slice); caller positions it
function Creator.Shadow(parent, spread, transparency)
    spread = spread or 28
    local s = Instance.new("ImageLabel")
    s.Name = "Shadow"
    s.BackgroundTransparency = 1
    s.Image = SHADOW_IMAGE
    s.ImageColor3 = Color3.new(0, 0, 0)
    s.ImageTransparency = transparency or 0.5
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(49, 49, 450, 450)
    s.AnchorPoint = Vector2.new(0.5, 0.5)
    s.Position = UDim2.fromScale(0.5, 0.5)
    s.Size = UDim2.new(1, spread * 2, 1, spread * 2)
    s.ZIndex = 1
    s.Parent = parent
    return s
end

-- drag `target` by holding `handle` (mouse or touch)
function Creator.Draggable(handle, target)
    target = target or handle
    local dragging, start, startPos
    handle.Active = true
    local c1 = handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, start, startPos = true, i.Position, target.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    local c2 = UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - start
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    return { c1, c2 }
end

--==================================================================--
--  Acrylic: real frosted blur of the world behind a frame
--  (a glass part held just in front of the camera, blurred by a
--  depth-of-field effect; needs Glass material = graphics quality 8+,
--  otherwise it is simply invisible)
--==================================================================--

local Acrylic = {}
local DOF_NAME = "LiquidGlassDepthOfField"
local acrylicCount = 0

local function ensureDOF()
    local dof = Lighting:FindFirstChild(DOF_NAME)
    if not dof then
        dof = Instance.new("DepthOfFieldEffect")
        dof.Name = DOF_NAME
        dof.FarIntensity = 0
        dof.FocusDistance = 51.6
        dof.InFocusRadius = 50
        dof.NearIntensity = 1
        dof.Parent = Lighting
    end
    dof.Enabled = true
    return dof
end

local function isShown(g)
    while g and g:IsA("GuiObject") do
        if not g.Visible then return false end
        g = g.Parent
    end
    return g ~= nil
end

-- Acrylic.new(frame, cornerRadius) -> { Enabled, SetEnabled(on), Destroy() }
function Acrylic.new(frame, radius)
    local self = { Enabled = true }
    acrylicCount = acrylicCount + 1
    ensureDOF()

    local part = Instance.new("Part")
    part.Name = "LiquidGlassAcrylic"
    part.Color = Color3.new(0, 0, 0)
    part.Material = Enum.Material.Glass
    part.Size = Vector3.new(1, 1, 0.001)
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Locked = true
    part.Transparency = 1
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Brick
    mesh.Offset = Vector3.new(0, 0, -0.000001)
    mesh.Parent = part

    local inset = math.floor((radius or 12) * 0.3 + 2)
    local distance = 0.001

    local function render()
        local cam = workspace.CurrentCamera
        if not cam then return end
        if part.Parent ~= cam then part.Parent = cam end
        if not self.Enabled or not frame.Parent or not isShown(frame) then
            part.Transparency = 1
            return
        end
        local pos = frame.AbsolutePosition + Vector2.new(inset, inset)
        local size = frame.AbsoluteSize - Vector2.new(inset * 2, inset * 2)
        if size.X <= 2 or size.Y <= 2 then part.Transparency = 1 return end
        local function toWorld(p)
            local r = cam:ViewportPointToRay(p.X, p.Y)
            return r.Origin + r.Direction * distance
        end
        local tl = toWorld(pos)
        local tr = toWorld(pos + Vector2.new(size.X, 0))
        local br = toWorld(pos + size)
        local w, h = (tr - tl).Magnitude, (tr - br).Magnitude
        part.CFrame = CFrame.fromMatrix((tl + br) / 2, cam.CFrame.XVector, cam.CFrame.YVector, cam.CFrame.ZVector)
        mesh.Scale = Vector3.new(w, h, 0)
        part.Transparency = 0.98
    end

    local conn = RunService.RenderStepped:Connect(function() pcall(render) end)

    function self:SetEnabled(on)
        self.Enabled = on ~= false
        pcall(render)
    end
    function self:Destroy()
        pcall(function() conn:Disconnect() end)
        pcall(function() part:Destroy() end)
        acrylicCount = math.max(0, acrylicCount - 1)
        if acrylicCount == 0 then
            local dof = Lighting:FindFirstChild(DOF_NAME)
            if dof then pcall(function() dof:Destroy() end) end
        end
    end
    return self
end
LiquidGlass.Acrylic = Acrylic

--==================================================================--
--  Live theme switching
--==================================================================--

local function applyTheme(T)
    for inst, map in pairs(Themed) do
        if inst.Parent then
            for prop, key in pairs(map) do
                local v = T[key]
                if v ~= nil then pcall(function() inst[prop] = v end) end
            end
        end
    end
    for _, w in ipairs(LiquidGlass.Windows) do
        w.Theme = T
        if w.Config.Transparent ~= false and not w._customTransparency then
            w._transparency = T.ShellT
            if w.Main.Visible then w.Main.BackgroundTransparency = T.ShellT end
        end
    end
end

-- LiquidGlass:SetTheme("Light") - repaints every open window
function LiquidGlass:SetTheme(name)
    local t = type(name) == "table" and name or self.Themes[name]
    if not t then warnf("unknown theme " .. tostring(name)) return false end
    self.Theme = t
    applyTheme(t)
    return true
end

--==================================================================--
--  Gui parenting
--==================================================================--

local function guiParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and typeof(hui) == "Instance" then return hui end
    if pcall(function() return CoreGui:GetChildren() end) then return CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function protect(gui)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
    end)
end

--==================================================================--
--  Notifications (independent of any window)
--==================================================================--

local notifyGui, notifyList
local NOTIFY_W = 300
local function ensureNotify()
    if notifyGui and notifyGui.Parent then return end
    notifyGui = Instance.new("ScreenGui")
    notifyGui.Name = "LiquidGlassNotify"
    notifyGui.ResetOnSpawn = false
    notifyGui.IgnoreGuiInset = true
    notifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notifyGui.DisplayOrder = 10000
    protect(notifyGui)
    notifyGui.Parent = guiParent()
    notifyList = Instance.new("Frame")
    notifyList.AnchorPoint = Vector2.new(1, 1)
    notifyList.Position = UDim2.new(1, -18, 1, -18)
    notifyList.Size = UDim2.new(0, NOTIFY_W, 1, -36)
    notifyList.BackgroundTransparency = 1
    notifyList.Parent = notifyGui
    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 8)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.VerticalAlignment = Enum.VerticalAlignment.Bottom
    ll.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ll.Parent = notifyList
end

local notifyOrder = 0
-- LiquidGlass:Notify({ Title, Content, Duration = 3, Color = Color3 | theme key, Buttons = { { Title, Callback } } })
function LiquidGlass:Notify(cfg)
    cfg = cfg or {}
    ensureNotify()
    local T = th()
    local textW = NOTIFY_W - 34
    local hasTitle = cfg.Title and cfg.Title ~= ""
    local hasContent = cfg.Content and cfg.Content ~= ""
    local titleH = hasTitle and textHeight(cfg.Title, 13, Fonts.Bold, textW) or 0
    local contentH = hasContent and textHeight(cfg.Content, 11, Fonts.Medium, textW) or 0
    local buttons = cfg.Buttons
    local btnH = (type(buttons) == "table" and #buttons > 0) and 36 or 0
    local height = 12 + titleH + (hasTitle and hasContent and 3 or 0) + contentH + btnH + 13

    notifyOrder = notifyOrder + 1
    local card = Creator.Glass(notifyList, "menu", 14)
    card.Size = UDim2.new(1, 0, 0, height)
    card.LayoutOrder = notifyOrder
    local accent = cfg.Color
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, -18)
    bar.Position = UDim2.fromOffset(6, 9)
    bar.BorderSizePixel = 0
    bar.ZIndex = card.ZIndex + 1
    bar.Parent = card
    Creator.Corner(bar, 2)
    if type(accent) == "string" then Creator.Themed(bar, { BackgroundColor3 = accent })
    else bar.BackgroundColor3 = accent or T.Accent end

    local y = 12
    if hasTitle then
        local t = Creator.Label(card, cfg.Title, 13, "Text", Fonts.Bold)
        t.Size = UDim2.new(0, textW, 0, titleH)
        t.Position = UDim2.fromOffset(18, y)
        t.TextWrapped = true
        t.TextYAlignment = Enum.TextYAlignment.Top
        t.ZIndex = card.ZIndex + 1
        y = y + titleH + 3
    end
    if hasContent then
        local c = Creator.Label(card, cfg.Content, 11, "Secondary", Fonts.Medium)
        c.Size = UDim2.new(0, textW, 0, contentH)
        c.Position = UDim2.fromOffset(18, y)
        c.TextWrapped = true
        c.TextYAlignment = Enum.TextYAlignment.Top
        c.ZIndex = card.ZIndex + 1
        y = y + contentH
    end

    local obj = {}
    local closed = false
    local sc = Instance.new("UIScale")
    sc.Scale = 0.9
    sc.Parent = card
    Creator.Tween(sc, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
    function obj:Close()
        if closed then return end
        closed = true
        Creator.Tween(sc, { Scale = 0.9 }, 0.15)
        Creator.Tween(card, { BackgroundTransparency = 1 }, 0.15)
        for _, d in ipairs(card:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then Creator.Tween(d, { TextTransparency = 1, BackgroundTransparency = 1 }, 0.15)
            elseif d:IsA("Frame") then Creator.Tween(d, { BackgroundTransparency = 1 }, 0.15)
            elseif d:IsA("UIStroke") then Creator.Tween(d, { Transparency = 1 }, 0.15) end
        end
        task.delay(0.17, function() pcall(function() card:Destroy() end) end)
    end

    if btnH > 0 then
        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.new(1, -34, 0, 26)
        holder.Position = UDim2.fromOffset(18, y + 8)
        holder.ZIndex = card.ZIndex + 1
        holder.Parent = card
        local hl = Instance.new("UIListLayout")
        hl.FillDirection = Enum.FillDirection.Horizontal
        hl.Padding = UDim.new(0, 6)
        hl.SortOrder = Enum.SortOrder.LayoutOrder
        hl.Parent = holder
        for i, b in ipairs(buttons) do
            local tint = b.Tint or (i == 1 and "Accent" or nil)
            local btn = Creator.Button(holder, b.Title or "OK", tint, tint and T.White or "Text", 10)
            btn.Size = UDim2.fromOffset(math.max(62, textWidth(b.Title or "OK", 10, Fonts.Bold) + 24), 26)
            btn.LayoutOrder = i
            btn.ZIndex = holder.ZIndex + 1
            btn.MouseButton1Click:Connect(function()
                if type(b.Callback) == "function" then pcall(b.Callback) end
                obj:Close()
            end)
        end
    end

    local duration = cfg.Duration or 3
    if duration > 0 then
        local prog = Instance.new("Frame")
        prog.Size = UDim2.new(1, -28, 0, 2)
        prog.Position = UDim2.new(0, 14, 1, -4)
        prog.BorderSizePixel = 0
        prog.BackgroundTransparency = 0.35
        prog.ZIndex = card.ZIndex + 1
        prog.Parent = card
        Creator.Corner(prog, "full")
        if type(accent) == "string" then Creator.Themed(prog, { BackgroundColor3 = accent })
        else prog.BackgroundColor3 = accent or T.Accent end
        Creator.Tween(prog, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)
        task.delay(duration, function() obj:Close() end)
    end
    return obj
end

--==================================================================--
--  Elements
--==================================================================--

local Element = {}
Element.__index = Element

function Element:SetTitle(t) if self.TitleLabel then self.TitleLabel.Text = tostring(t) end self.Title = t return self end
function Element:SetDesc(d) if self.DescLabel then self.DescLabel.Text = tostring(d) end return self end
function Element:SetVisible(v) self.Frame.Visible = v ~= false return self end
function Element:SetCallback(fn) self.Callback = fn return self end
function Element:Get() return self.Value end
function Element:Set(v, silent)
    if self._set then self._set(self, v, silent) end
    return self
end
function Element:Destroy()
    if self.Flag then
        self.Window.Flags[self.Flag] = nil
        if LiquidGlass.Flags[self.Flag] == self then LiquidGlass.Flags[self.Flag] = nil end
    end
    self.Frame:Destroy()
end
-- dim and block input (optional reason text)
function Element:Lock(reason)
    if self._lock then self._lock.Text = reason or "" return self end
    local l = Instance.new("TextButton")
    l.AutoButtonColor = false
    l.Text = reason or ""
    l.Font = Fonts.Bold
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Right
    l.BackgroundTransparency = 0.5
    l.BorderSizePixel = 0
    l.Size = UDim2.fromScale(1, 1)
    l.ZIndex = self.Frame.ZIndex + 20
    l.Parent = self.Frame
    Creator.Corner(l, 12)
    Creator.Pad(l, 0, 14, 0, 0)
    Creator.Themed(l, { BackgroundColor3 = "Base", TextColor3 = "Muted" })
    self._lock = l
    self.Locked = true
    return self
end
function Element:Unlock()
    if self._lock then self._lock:Destroy() self._lock = nil end
    self.Locked = false
    return self
end
function Element:_fire(...)
    if type(self.Callback) == "function" then
        local ok, err = pcall(self.Callback, ...)
        if not ok then warnf(("%s '%s' callback error: %s"):format(self.Type, tostring(self.Title), tostring(err))) end
    end
    local w = self.Window
    if w._autosave and self.Flag then w:SaveConfig(w._autosave) end
end
function Element:GetConfigValue()
    local v = self.Value
    if typeof(v) == "EnumItem" then return v.Name end
    if typeof(v) == "Color3" then return "#" .. v:ToHex() end
    return v
end
function Element:SetFromConfig(v)
    if self.Type == "Keybind" and type(v) == "string" then
        local ok, k = pcall(function() return Enum.KeyCode[v] end)
        if ok then v = k else return end
    elseif self.Type == "ColorPicker" and type(v) == "string" then
        local ok, c = pcall(Color3.fromHex, v)
        if ok then v = c else return end
    end
    self:Set(v)
end

local function newElement(tab, typ, cfg, frame, titleLbl, descLbl)
    local el = setmetatable({
        Type = typ, Title = cfg.Title, Frame = frame, TitleLabel = titleLbl, DescLabel = descLbl,
        Callback = cfg.Callback, Flag = cfg.Flag, Tab = tab, Window = tab.Window, Value = nil,
    }, Element)
    tab.Elements[#tab.Elements + 1] = el
    if cfg.Flag then
        tab.Window.Flags[cfg.Flag] = el
        LiquidGlass.Flags[cfg.Flag] = el
    end
    if cfg.Tooltip and cfg.Tooltip ~= "" then tab.Window:_tooltip(frame, cfg.Tooltip) end
    return el
end

-- glass tile with title + optional desc; `reserve` = px kept free on the right
local function makeRow(tab, cfg, height, reserve)
    reserve = reserve or 0
    local row = Creator.Glass(tab.Content, "panel", 12)
    row.Name = "Row"
    row.Size = UDim2.new(1, -4, 0, height)
    row.LayoutOrder = tab:_nextOrder()
    row.ZIndex = tab.Content.ZIndex
    local hasDesc = type(cfg.Desc) == "string" and cfg.Desc ~= ""
    local title = Creator.Label(row, cfg.Title or "", 12, "Text", Fonts.Bold)
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.ZIndex = row.ZIndex + 1
    local desc
    if hasDesc then
        title.Size = UDim2.new(1, -reserve - 28, 0, 15)
        title.Position = UDim2.fromOffset(14, 8)
        desc = Creator.Label(row, cfg.Desc, 10, "Muted", Fonts.Regular)
        desc.Size = UDim2.new(1, -reserve - 28, 0, 13)
        desc.Position = UDim2.fromOffset(14, 24)
        desc.TextTruncate = Enum.TextTruncate.AtEnd
        desc.ZIndex = row.ZIndex + 1
    else
        title.Size = UDim2.new(1, -reserve - 28, 0, height)
        title.Position = UDim2.fromOffset(14, 0)
    end
    return row, title, desc
end

local function isPress(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

local Tab = {}
Tab.__index = Tab

function Tab:_nextOrder()
    self._order = self._order + 1
    return self._order
end

-- usable text width inside a tile
function Tab:_textWidth()
    local w = self.Content.AbsoluteSize.X
    if w <= 0 then w = self.Window:_contentWidth() end
    return math.max(60, w - 4 - 8 - 28)
end

function Tab:Select() self.Window:SelectTab(self) return self end

-- Tab:Section({ Title = "Players" })
function Tab:Section(cfg)
    cfg = type(cfg) == "table" and cfg or { Title = tostring(cfg) }
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(1, -4, 0, 24)
    f.LayoutOrder = self:_nextOrder()
    f.Parent = self.Content
    local l = Creator.SectionTitle(f, cfg.Title or "", 4, 6)
    local el = newElement(self, "Section", cfg, f, l, nil)
    el._set = function(s, v) s.TitleLabel.Text = tostring(v):upper() end
    return el
end

-- Tab:Label({ Text = "a small muted note" })
function Tab:Label(cfg)
    cfg = type(cfg) == "table" and cfg or { Text = tostring(cfg) }
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(1, -4, 0, 16)
    f.LayoutOrder = self:_nextOrder()
    f.Parent = self.Content
    local l = Creator.Label(f, cfg.Text or "", 10, cfg.Color or "Muted", Fonts.Regular)
    l.Size = UDim2.new(1, -28, 1, 0)
    l.Position = UDim2.fromOffset(14, 0)
    l.TextWrapped = true
    l.TextYAlignment = Enum.TextYAlignment.Top
    local el = newElement(self, "Label", cfg, f, l, nil)
    el.Value = cfg.Text
    function el:_measure()
        local h = textHeight(l.Text, 10, Fonts.Regular, self.Tab:_textWidth())
        f.Size = UDim2.new(1, -4, 0, h + 4)
    end
    el._set = function(s, v) s.Value = v l.Text = tostring(v) s:_measure() end
    el:_measure()
    return el
end

-- Tab:Divider()
function Tab:Divider()
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(1, -4, 0, 8)
    f.LayoutOrder = self:_nextOrder()
    f.Parent = self.Content
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -28, 0, 1)
    line.Position = UDim2.new(0, 14, 0.5, 0)
    line.BackgroundTransparency = 0.85
    line.BorderSizePixel = 0
    line.Parent = f
    Creator.Themed(line, { BackgroundColor3 = "Rim" })
    return newElement(self, "Divider", {}, f)
end

-- Tab:Paragraph({ Title = "...", Desc = "long text" })
function Tab:Paragraph(cfg)
    cfg = cfg or {}
    local row = Creator.Glass(self.Content, "panel", 12)
    row.Name = "Row"
    row.Size = UDim2.new(1, -4, 0, 40)
    row.LayoutOrder = self:_nextOrder()
    row.ZIndex = self.Content.ZIndex
    local title = Creator.Label(row, cfg.Title or "", 12, "Text", Fonts.Bold)
    title.Position = UDim2.fromOffset(14, 10)
    title.TextWrapped = true
    title.TextYAlignment = Enum.TextYAlignment.Top
    title.ZIndex = row.ZIndex + 1
    local desc = Creator.Label(row, cfg.Desc or "", 11, "Secondary", Fonts.Regular)
    desc.TextWrapped = true
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.ZIndex = row.ZIndex + 1
    local el = newElement(self, "Paragraph", cfg, row, title, desc)
    function el:_measure()
        local w = self.Tab:_textWidth()
        local th_ = title.Text ~= "" and textHeight(title.Text, 12, Fonts.Bold, w) or 0
        local dh = desc.Text ~= "" and textHeight(desc.Text, 11, Fonts.Regular, w) or 0
        title.Size = UDim2.new(1, -28, 0, th_)
        title.Visible = th_ > 0
        desc.Position = UDim2.fromOffset(14, 10 + th_ + (th_ > 0 and dh > 0 and 4 or 0))
        desc.Size = UDim2.new(1, -28, 0, dh)
        desc.Visible = dh > 0
        row.Size = UDim2.new(1, -4, 0, 10 + th_ + (th_ > 0 and dh > 0 and 4 or 0) + dh + 10)
    end
    function el:SetTitle(t) title.Text = tostring(t) self.Title = t self:_measure() return self end
    function el:SetDesc(d) desc.Text = tostring(d) self:_measure() return self end
    el:_measure()
    return el
end

-- Tab:Button({ Title, Desc, Tint = Color3 | theme key, Callback })
function Tab:Button(cfg)
    cfg = cfg or {}
    local row, title, desc = makeRow(self, cfg, 44, 20)
    if cfg.Tint then
        if type(cfg.Tint) == "string" then Creator.Themed(title, { TextColor3 = cfg.Tint })
        else Themed[title] = nil title.TextColor3 = cfg.Tint end
    end
    local arrow = Creator.Label(row, "›", 18, "Muted", Fonts.Medium, Enum.TextXAlignment.Center)
    arrow.Size = UDim2.fromOffset(20, 44)
    arrow.Position = UDim2.new(1, -32, 0, 0)
    arrow.ZIndex = row.ZIndex + 1
    local hit = Instance.new("TextButton")
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Size = UDim2.fromScale(1, 1)
    hit.ZIndex = row.ZIndex + 3
    hit.Parent = row
    local el = newElement(self, "Button", cfg, row, title, desc)
    hit.MouseEnter:Connect(function() Creator.Tween(row, { BackgroundTransparency = th().GlassHoverT }, 0.12) Creator.Tween(arrow, { TextColor3 = th().Text }, 0.12) end)
    hit.MouseLeave:Connect(function() Creator.Tween(row, { BackgroundTransparency = th().GlassT }, 0.18) Creator.Tween(arrow, { TextColor3 = th().Muted }, 0.18) end)
    hit.MouseButton1Down:Connect(function() Creator.Tween(row, { BackgroundTransparency = th().GlassHoverT - 0.08 }, 0.06) end)
    hit.MouseButton1Up:Connect(function() Creator.Tween(row, { BackgroundTransparency = th().GlassHoverT }, 0.12) end)
    hit.MouseButton1Click:Connect(function() if not el.Locked then el:_fire() end end)
    function el:Click() self:_fire() end
    return el
end

-- Tab:Toggle({ Title, Desc, Value = false, Flag, Callback(state) })
function Tab:Toggle(cfg)
    cfg = cfg or {}
    local row, title, desc = makeRow(self, cfg, 44, 56)
    local el = newElement(self, "Toggle", cfg, row, title, desc)
    el.Value = cfg.Value == true
    local sw = Creator.Switch(row, el.Value, function(on)
        el.Value = on
        el:_fire(on)
    end)
    sw.Button.Position = UDim2.new(1, -56, 0.5, -12)
    sw.Button.ZIndex = row.ZIndex + 2
    el._set = function(s, v, silent)
        sw:Set(v == true, true, true)
        s.Value = v == true
        if not silent then s:_fire(s.Value) end
    end
    return el
end

-- shared bar used by Slider and Progress
local function makeBar(row, y)
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 5)
    track.Position = UDim2.fromOffset(14, y)
    track.BorderSizePixel = 0
    track.ZIndex = row.ZIndex + 1
    track.Parent = row
    Creator.Themed(track, { BackgroundColor3 = "Off", BackgroundTransparency = "OffT" })
    Creator.Corner(track, "full")
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BorderSizePixel = 0
    fill.ZIndex = track.ZIndex + 1
    fill.Parent = track
    Creator.Themed(fill, { BackgroundColor3 = "Accent" })
    Creator.Corner(fill, "full")
    return track, fill
end

-- Tab:Slider({ Title, Desc, Value = { Min = 0, Max = 100, Default = 50 }, Step = 1, Suffix = "", Flag, Callback(value) })
function Tab:Slider(cfg)
    cfg = cfg or {}
    local v = cfg.Value or {}
    local min, max = v.Min or 0, v.Max or 100
    local step = cfg.Step or 1
    if step <= 0 then step = 1 end
    local decimals = 0
    do
        local s = tostring(step)
        local dot = s:find("%.")
        if dot then decimals = #s - dot end
    end
    local hasDesc = type(cfg.Desc) == "string" and cfg.Desc ~= ""
    local h = hasDesc and 62 or 50
    local row, title, desc = makeRow(self, cfg, h, 80)
    if not hasDesc then title.Size = UDim2.new(1, -108, 0, 15) title.Position = UDim2.fromOffset(14, 8) end
    local valLbl = Creator.Label(row, "", 11, "Secondary", Fonts.Bold, Enum.TextXAlignment.Right)
    valLbl.Size = UDim2.fromOffset(80, 15)
    valLbl.Position = UDim2.new(1, -94, 0, 8)
    valLbl.ZIndex = row.ZIndex + 1

    local trackY = h - 16
    local track, fill = makeBar(row, trackY)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = th().White
    knob.BorderSizePixel = 0
    knob.ZIndex = track.ZIndex + 2
    knob.Parent = track
    Creator.Corner(knob, "full")
    local ks = Instance.new("UIStroke")
    ks.Color = th().Black
    ks.Transparency = 0.82
    ks.Parent = knob
    local hit = Instance.new("TextButton")
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Size = UDim2.new(1, -14, 0, 26)
    hit.Position = UDim2.fromOffset(7, trackY - 10)
    hit.ZIndex = track.ZIndex + 3
    hit.Parent = row

    local el = newElement(self, "Slider", cfg, row, title, desc)
    local function snap(x)
        x = math.clamp(x, min, max)
        x = min + math.floor((x - min) / step + 0.5) * step
        return math.clamp(x, min, max)
    end
    local function paint(anim)
        local pct = (max > min) and (el.Value - min) / (max - min) or 0
        valLbl.Text = ("%." .. decimals .. "f"):format(el.Value) .. (cfg.Suffix or "")
        if anim then
            Creator.Tween(fill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.08)
            Creator.Tween(knob, { Position = UDim2.new(pct, 0, 0.5, 0) }, 0.08)
        else
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, 0, 0.5, 0)
        end
    end
    el.Value = snap(v.Default or min)
    paint(false)
    el._set = function(s, x, silent)
        x = snap(tonumber(x) or min)
        local changed = x ~= s.Value
        s.Value = x
        paint(true)
        if changed and not silent then s:_fire(x) end
    end
    function el:SetRange(newMin, newMax)
        min, max = newMin or min, newMax or max
        self:Set(self.Value, true)
    end

    local dragging = false
    local function fromX(px)
        local w = track.AbsoluteSize.X
        if w <= 0 then return end
        local pct = math.clamp((px - track.AbsolutePosition.X) / w, 0, 1)
        el:Set(min + (max - min) * pct)
    end
    hit.InputBegan:Connect(function(i)
        if isPress(i) and not el.Locked then dragging = true fromX(i.Position.X) end
    end)
    hit.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end)
    local conns = self.Window._conns
    conns[#conns + 1] = UserInputService.InputChanged:Connect(function(i)
        if dragging and isMove(i) then fromX(i.Position.X) end
    end)
    conns[#conns + 1] = UserInputService.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end)
    return el
end

-- Tab:Progress({ Title, Desc, Value = 0, Max = 100, Suffix = "%" }) -> :Set(value)
function Tab:Progress(cfg)
    cfg = cfg or {}
    local max = cfg.Max or 100
    local hasDesc = type(cfg.Desc) == "string" and cfg.Desc ~= ""
    local h = hasDesc and 62 or 50
    local row, title, desc = makeRow(self, cfg, h, 80)
    if not hasDesc then title.Size = UDim2.new(1, -108, 0, 15) title.Position = UDim2.fromOffset(14, 8) end
    local valLbl = Creator.Label(row, "", 11, "Secondary", Fonts.Bold, Enum.TextXAlignment.Right)
    valLbl.Size = UDim2.fromOffset(80, 15)
    valLbl.Position = UDim2.new(1, -94, 0, 8)
    valLbl.ZIndex = row.ZIndex + 1
    local _, fill = makeBar(row, h - 16)
    if cfg.Color then
        if type(cfg.Color) == "string" then Creator.Themed(fill, { BackgroundColor3 = cfg.Color })
        else Themed[fill] = nil fill.BackgroundColor3 = cfg.Color end
    end
    local el = newElement(self, "Progress", cfg, row, title, desc)
    el.Value = 0
    el._set = function(s, x, silent)
        x = math.clamp(tonumber(x) or 0, 0, max)
        s.Value = x
        local pct = max > 0 and x / max or 0
        valLbl.Text = cfg.Format and cfg.Format(x, max) or (("%d"):format(math.floor(pct * 100 + 0.5)) .. (cfg.Suffix or "%"))
        Creator.Tween(fill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.2)
        if not silent then s:_fire(x) end
    end
    el:Set(cfg.Value or 0, true)
    return el
end

-- popup placed under an anchor, inside the window overlay (menu tier)
local function openPopup(Window, anchor, w, hgt, onClose)
    local overlay = Window:_openOverlay(onClose)
    local scale = Window._scale.Scale
    local rel = (anchor.AbsolutePosition - Window.Main.AbsolutePosition) / scale
    local popup = Creator.Glass(overlay, "menu", 12)
    popup.ZIndex = overlay.ZIndex + 1
    popup.Size = UDim2.fromOffset(w, hgt)
    local winH = Window.Main.AbsoluteSize.Y / scale
    local y = rel.Y + anchor.AbsoluteSize.Y / scale + 6
    if y + hgt > winH - 8 then y = rel.Y - hgt - 6 end
    popup.Position = UDim2.fromOffset(math.max(8, rel.X + anchor.AbsoluteSize.X / scale - w), math.max(8, y))
    local sc = Instance.new("UIScale")
    sc.Scale = 0.92
    sc.Parent = popup
    Creator.Tween(sc, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    return popup
end

-- Tab:Dropdown({ Title, Desc, Values = {...}, Value = "x" | {"x","y"}, Multi = false, Search = bool, Flag, Callback(value) })
function Tab:Dropdown(cfg)
    cfg = cfg or {}
    local Window = self.Window
    local row, title, desc = makeRow(self, cfg, 44, 150)
    local btn = Creator.Button(row, "", nil, "Text", 11)
    btn.Font = Fonts.Medium
    btn.Size = UDim2.fromOffset(140, 28)
    btn.Position = UDim2.new(1, -154, 0.5, -14)
    btn.ZIndex = row.ZIndex + 2
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Creator.Pad(btn, 12, 26, 0, 0)
    local chev = Creator.Label(btn, "›", 16, "Muted", Fonts.Medium, Enum.TextXAlignment.Center)
    chev.Size = UDim2.fromOffset(16, 16)
    chev.AnchorPoint = Vector2.new(0.5, 0.5)
    chev.Position = UDim2.new(1, 14, 0.5, 0)
    chev.Rotation = 90
    chev.ZIndex = btn.ZIndex + 1

    local el = newElement(self, "Dropdown", cfg, row, title, desc)
    el.Values = type(cfg.Values) == "table" and cfg.Values or {}
    el.Multi = cfg.Multi == true
    if el.Multi then
        el.Value = {}
        if type(cfg.Value) == "table" then for _, x in ipairs(cfg.Value) do el.Value[#el.Value + 1] = x end end
    else
        el.Value = cfg.Value
    end

    local function selected(x)
        if el.Multi then
            for _, y in ipairs(el.Value) do if y == x then return true end end
            return false
        end
        return el.Value == x
    end
    local function labelText()
        if el.Multi then
            if #el.Value == 0 then return "None" end
            if #el.Value <= 2 then return table.concat(el.Value, ", ") end
            return #el.Value .. " selected"
        end
        return el.Value ~= nil and tostring(el.Value) or "None"
    end
    btn.Text = labelText()

    local popup, optionButtons = nil, {}
    local function paintOptions()
        local T = Window.Theme
        for x, b in pairs(optionButtons) do
            local on = selected(x)
            b.TextColor3 = on and T.AccentHi or T.Text
            b.BackgroundTransparency = on and T.GlassHoverT or 1
            local dot = b:FindFirstChild("Dot")
            if dot then dot.Visible = on end
        end
    end
    local function close()
        if popup then popup:Destroy() popup = nil end
        optionButtons = {}
        Window:_closeOverlay()
    end
    local function open()
        if popup then close() return end
        if el.Locked then return end
        local T = Window.Theme
        local count = #el.Values
        local searchable = cfg.Search or count > 8
        local listTop = searchable and 40 or 6
        local hgt = math.min(count * 29 + listTop + 6, 260)
        popup = openPopup(Window, btn, 190, hgt, close)
        local list = Creator.Scroller(popup, UDim2.fromOffset(6, listTop), UDim2.new(1, -12, 1, -listTop - 6))
        list.ZIndex = popup.ZIndex + 1
        local ll = Instance.new("UIListLayout")
        ll.Padding = UDim.new(0, 2)
        ll.SortOrder = Enum.SortOrder.LayoutOrder
        ll.Parent = list
        if searchable then
            local wrap, box = Creator.TextBox(popup, "Search", "", 11)
            wrap.Size = UDim2.new(1, -12, 0, 28)
            wrap.Position = UDim2.fromOffset(6, 6)
            wrap.ZIndex = popup.ZIndex + 1
            box.ZIndex = wrap.ZIndex + 1
            box:GetPropertyChangedSignal("Text"):Connect(function()
                local q = box.Text:lower()
                for x, b in pairs(optionButtons) do
                    b.Visible = q == "" or tostring(x):lower():find(q, 1, true) ~= nil
                end
            end)
            task.defer(function() pcall(function() box:CaptureFocus() end) end)
        end
        if count == 0 then
            local l = Creator.Label(list, "No options", 11, "Muted", Fonts.Medium, Enum.TextXAlignment.Center)
            l.Size = UDim2.new(1, -4, 0, 27)
            l.ZIndex = list.ZIndex + 1
        end
        for i, x in ipairs(el.Values) do
            local b = Instance.new("TextButton")
            b.AutoButtonColor = false
            b.Text = tostring(x)
            b.Font = Fonts.Medium
            b.TextSize = 11
            b.TextColor3 = T.Text
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.TextTruncate = Enum.TextTruncate.AtEnd
            b.BackgroundColor3 = T.Glass
            b.BackgroundTransparency = 1
            b.BorderSizePixel = 0
            b.Size = UDim2.new(1, -4, 0, 27)
            b.LayoutOrder = i
            b.ZIndex = list.ZIndex + 1
            b.Parent = list
            Creator.Corner(b, 8)
            Creator.Pad(b, 10, 24, 0, 0)
            local dot = Instance.new("Frame")
            dot.Name = "Dot"
            dot.Size = UDim2.fromOffset(6, 6)
            dot.AnchorPoint = Vector2.new(1, 0.5)
            dot.Position = UDim2.new(1, 14, 0.5, 0)
            dot.BorderSizePixel = 0
            dot.ZIndex = b.ZIndex + 1
            dot.Visible = false
            dot.Parent = b
            Creator.Corner(dot, "full")
            Creator.Themed(dot, { BackgroundColor3 = "AccentHi" })
            b.MouseEnter:Connect(function() if not selected(x) then b.BackgroundTransparency = T.GlassT end end)
            b.MouseLeave:Connect(function() if not selected(x) then b.BackgroundTransparency = 1 end end)
            optionButtons[x] = b
            b.MouseButton1Click:Connect(function()
                if el.Multi then
                    if selected(x) then
                        for k, y in ipairs(el.Value) do if y == x then table.remove(el.Value, k) break end end
                    else
                        el.Value[#el.Value + 1] = x
                    end
                    paintOptions()
                    btn.Text = labelText()
                    el:_fire(el.Value)
                else
                    el.Value = x
                    btn.Text = labelText()
                    close()
                    el:_fire(x)
                end
            end)
        end
        paintOptions()
    end
    btn.MouseButton1Click:Connect(open)

    el._set = function(s, v, silent)
        if s.Multi then
            s.Value = {}
            if type(v) == "table" then for _, x in ipairs(v) do s.Value[#s.Value + 1] = x end
            elseif v ~= nil then s.Value[1] = v end
        else
            s.Value = v
        end
        btn.Text = labelText()
        paintOptions()
        if not silent then s:_fire(s.Value) end
    end
    function el:Refresh(values, keep)
        self.Values = type(values) == "table" and values or {}
        if not keep then
            if self.Multi then self.Value = {} else self.Value = nil end
        end
        btn.Text = labelText()
        if popup then close() end
        return self
    end
    function el:Close() close() end
    return el
end

-- Tab:Input({ Title, Desc, Value = "", Placeholder = "", Numeric = false, Flag, Callback(text, enterPressed), OnChange(text) })
function Tab:Input(cfg)
    cfg = cfg or {}
    local hasDesc = type(cfg.Desc) == "string" and cfg.Desc ~= ""
    local h = hasDesc and 80 or 64
    local row, title, desc = makeRow(self, cfg, h, 0)
    if not hasDesc then title.Size = UDim2.new(1, -28, 0, 15) title.Position = UDim2.fromOffset(14, 8) end
    local wrap, box = Creator.TextBox(row, cfg.Placeholder or "", tostring(cfg.Value or ""), 11)
    wrap.Size = UDim2.new(1, -28, 0, 28)
    wrap.Position = UDim2.fromOffset(14, h - 38)
    wrap.ZIndex = row.ZIndex + 1
    box.ZIndex = wrap.ZIndex + 1
    local el = newElement(self, "Input", cfg, row, title, desc)
    el.Value = tostring(cfg.Value or "")
    el.Box = box
    local rim = wrap:FindFirstChild("Rim")
    box.Focused:Connect(function()
        if el.Locked then box:ReleaseFocus() return end
        if rim then Themed[rim] = nil Creator.Tween(rim, { Color = self.Window.Theme.AccentHi, Transparency = 0.2 }, 0.15) end
    end)
    box.FocusLost:Connect(function(enter)
        if rim then Creator.Themed(rim, { Color = "Rim", Transparency = "RimT" }) end
        local txt = box.Text
        if cfg.Numeric then
            local n = tonumber(txt)
            if not n then box.Text = el.Value return end
            txt = tostring(n)
        end
        if txt == el.Value then return end
        el.Value = txt
        el:_fire(txt, enter == true)
    end)
    if cfg.OnChange then
        box:GetPropertyChangedSignal("Text"):Connect(function() pcall(cfg.OnChange, box.Text) end)
    end
    el._set = function(s, v, silent)
        s.Value = tostring(v or "")
        box.Text = s.Value
        if not silent then s:_fire(s.Value, false) end
    end
    return el
end

-- Tab:Keybind({ Title, Desc, Value = Enum.KeyCode.F, Flag, Callback() fires when pressed, OnChange(key) })
function Tab:Keybind(cfg)
    cfg = cfg or {}
    local row, title, desc = makeRow(self, cfg, 44, 100)
    local btn = Creator.Button(row, "", nil, "Text", 11)
    btn.Size = UDim2.fromOffset(90, 28)
    btn.Position = UDim2.new(1, -104, 0.5, -14)
    btn.ZIndex = row.ZIndex + 2
    local el = newElement(self, "Keybind", cfg, row, title, desc)
    el.Value = cfg.Value
    local listening = false
    local function paint()
        btn.Text = listening and "..." or (el.Value and el.Value.Name or "None")
    end
    paint()
    btn.MouseButton1Click:Connect(function()
        if el.Locked then return end
        listening = not listening
        paint()
    end)
    local kb = self.Window._keybinds
    kb[#kb + 1] = el
    function el:_input(i)
        if i.UserInputType ~= Enum.UserInputType.Keyboard then return false end
        if listening then
            listening = false
            if i.KeyCode ~= Enum.KeyCode.Escape then
                self.Value = i.KeyCode
                if type(cfg.OnChange) == "function" then pcall(cfg.OnChange, self.Value) end
                local w = self.Window
                if w._autosave and self.Flag then w:SaveConfig(w._autosave) end
            end
            paint()
            return true
        elseif self.Value and i.KeyCode == self.Value and not self.Locked then
            self:_fire(self.Value)
        end
        return false
    end
    el._set = function(s, v, silent)
        if type(v) == "string" then
            local ok, k = pcall(function() return Enum.KeyCode[v] end)
            v = ok and k or nil
        end
        s.Value = v
        paint()
        if not silent and type(cfg.OnChange) == "function" then pcall(cfg.OnChange, v) end
    end
    return el
end

-- Tab:ColorPicker({ Title, Desc, Default = Color3, Flag, Callback(color) })
function Tab:ColorPicker(cfg)
    cfg = cfg or {}
    local Window = self.Window
    local row, title, desc = makeRow(self, cfg, 44, 60)
    local el = newElement(self, "ColorPicker", cfg, row, title, desc)
    el.Value = cfg.Default or cfg.Value or Color3.fromRGB(255, 255, 255)
    local h, s, v = el.Value:ToHSV()

    local swatch = Instance.new("TextButton")
    swatch.AutoButtonColor = false
    swatch.Text = ""
    swatch.Size = UDim2.fromOffset(44, 26)
    swatch.Position = UDim2.new(1, -58, 0.5, -13)
    swatch.BackgroundColor3 = el.Value
    swatch.BorderSizePixel = 0
    swatch.ZIndex = row.ZIndex + 2
    swatch.Parent = row
    Creator.Corner(swatch, "full")
    addRim(swatch, 1, true)
    Creator.PressScale(swatch)

    local popup, hexBox
    local svCursor, hueCursor, svBox, hueBar
    local function apply(fire)
        el.Value = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = el.Value
        if popup then
            svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
            hueCursor.Position = UDim2.new(0, 0, h, 0)
            if hexBox and not hexBox:IsFocused() then hexBox.Text = "#" .. el.Value:ToHex():upper() end
        end
        if fire then el:_fire(el.Value) end
    end
    local function close()
        if popup then popup:Destroy() popup = nil end
        Window:_closeOverlay()
    end
    local dragSV, dragHue = false, false
    local function fromSV(p)
        local sz = svBox.AbsoluteSize
        if sz.X <= 0 or sz.Y <= 0 then return end
        s = math.clamp((p.X - svBox.AbsolutePosition.X) / sz.X, 0, 1)
        v = 1 - math.clamp((p.Y - svBox.AbsolutePosition.Y) / sz.Y, 0, 1)
        apply(true)
    end
    local function fromHue(p)
        local sz = hueBar.AbsoluteSize
        if sz.Y <= 0 then return end
        h = math.clamp((p.Y - hueBar.AbsolutePosition.Y) / sz.Y, 0, 0.9999)
        apply(true)
    end
    local function open()
        if popup then close() return end
        if el.Locked then return end
        local W, H = 224, 204
        popup = openPopup(Window, swatch, W, H, close)

        svBox = Instance.new("Frame")
        svBox.Size = UDim2.fromOffset(166, 144)
        svBox.Position = UDim2.fromOffset(12, 12)
        svBox.BorderSizePixel = 0
        svBox.ZIndex = popup.ZIndex + 1
        svBox.Parent = popup
        Creator.Corner(svBox, 10)
        local white = Instance.new("Frame")
        white.Size = UDim2.fromScale(1, 1)
        white.BackgroundColor3 = Color3.new(1, 1, 1)
        white.BorderSizePixel = 0
        white.ZIndex = svBox.ZIndex + 1
        white.Parent = svBox
        Creator.Corner(white, 10)
        local wg = Instance.new("UIGradient")
        wg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
        wg.Parent = white
        local black = Instance.new("Frame")
        black.Size = UDim2.fromScale(1, 1)
        black.BackgroundColor3 = Color3.new(0, 0, 0)
        black.BorderSizePixel = 0
        black.ZIndex = svBox.ZIndex + 2
        black.Parent = svBox
        Creator.Corner(black, 10)
        local bg = Instance.new("UIGradient")
        bg.Rotation = 90
        bg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
        bg.Parent = black
        svCursor = Instance.new("Frame")
        svCursor.Size = UDim2.fromOffset(14, 14)
        svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
        svCursor.BackgroundTransparency = 1
        svCursor.ZIndex = svBox.ZIndex + 3
        svCursor.Parent = svBox
        local cs = Instance.new("UIStroke")
        cs.Color = Color3.new(1, 1, 1)
        cs.Thickness = 2
        cs.Parent = svCursor
        Creator.Corner(svCursor, "full")
        local svHit = Instance.new("TextButton")
        svHit.Text = ""
        svHit.BackgroundTransparency = 1
        svHit.Size = UDim2.fromScale(1, 1)
        svHit.ZIndex = svBox.ZIndex + 4
        svHit.Parent = svBox
        svHit.InputBegan:Connect(function(i) if isPress(i) then dragSV = true fromSV(i.Position) end end)
        svHit.InputEnded:Connect(function(i) if isPress(i) then dragSV = false end end)

        hueBar = Instance.new("Frame")
        hueBar.Size = UDim2.fromOffset(18, 144)
        hueBar.Position = UDim2.fromOffset(190, 12)
        hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
        hueBar.BorderSizePixel = 0
        hueBar.ZIndex = popup.ZIndex + 1
        hueBar.Parent = popup
        Creator.Corner(hueBar, "full")
        local hg = Instance.new("UIGradient")
        hg.Rotation = 90
        local keys = {}
        for i = 0, 6 do keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 == 1 and 0.9999 or i / 6, 1, 1)) end
        hg.Color = ColorSequence.new(keys)
        hg.Parent = hueBar
        hueCursor = Instance.new("Frame")
        hueCursor.Size = UDim2.new(1, 4, 0, 4)
        hueCursor.AnchorPoint = Vector2.new(0, 0.5)
        hueCursor.Position = UDim2.new(0, -2, 0, 0)
        hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
        hueCursor.BorderSizePixel = 0
        hueCursor.ZIndex = hueBar.ZIndex + 1
        hueCursor.Parent = hueBar
        Creator.Corner(hueCursor, "full")
        local hueHit = Instance.new("TextButton")
        hueHit.Text = ""
        hueHit.BackgroundTransparency = 1
        hueHit.Size = UDim2.new(1, 8, 1, 0)
        hueHit.Position = UDim2.fromOffset(-4, 0)
        hueHit.ZIndex = hueBar.ZIndex + 2
        hueHit.Parent = hueBar
        hueHit.InputBegan:Connect(function(i) if isPress(i) then dragHue = true fromHue(i.Position) end end)
        hueHit.InputEnded:Connect(function(i) if isPress(i) then dragHue = false end end)

        local wrap, box = Creator.TextBox(popup, "#FFFFFF", "", 11)
        wrap.Size = UDim2.fromOffset(116, 28)
        wrap.Position = UDim2.fromOffset(12, 164)
        wrap.ZIndex = popup.ZIndex + 1
        box.ZIndex = wrap.ZIndex + 1
        hexBox = box
        box.FocusLost:Connect(function()
            local ok, c = pcall(Color3.fromHex, box.Text)
            if ok then
                h, s, v = c:ToHSV()
                apply(true)
            else
                box.Text = "#" .. el.Value:ToHex():upper()
            end
        end)
        local done = Creator.Button(popup, "DONE", "Accent", th().White, 10)
        done.Size = UDim2.fromOffset(76, 28)
        done.Position = UDim2.fromOffset(136, 164)
        done.ZIndex = popup.ZIndex + 1
        done.MouseButton1Click:Connect(close)
        apply(false)
    end
    swatch.MouseButton1Click:Connect(open)
    local conns = Window._conns
    conns[#conns + 1] = UserInputService.InputChanged:Connect(function(i)
        if not popup or not isMove(i) then return end
        if dragSV then fromSV(i.Position) elseif dragHue then fromHue(i.Position) end
    end)
    conns[#conns + 1] = UserInputService.InputEnded:Connect(function(i)
        if isPress(i) then dragSV, dragHue = false, false end
    end)

    el._set = function(s_, c, silent)
        if typeof(c) ~= "Color3" then return end
        h, s, v = c:ToHSV()
        apply(not silent)
    end
    function el:Close() close() end
    return el
end

-- Tab:Custom({ Height = 200, Glass = true }) -> element with .Frame to fill yourself
function Tab:Custom(cfg)
    cfg = cfg or {}
    local f
    if cfg.Glass ~= false then
        f = Creator.Glass(self.Content, "panel", cfg.Radius or 12)
    else
        f = Instance.new("Frame")
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.Parent = self.Content
    end
    f.Size = UDim2.new(1, -4, 0, cfg.Height or 120)
    f.LayoutOrder = self:_nextOrder()
    f.ZIndex = self.Content.ZIndex
    local el = newElement(self, "Custom", cfg, f)
    function el:SetHeight(hh) f.Size = UDim2.new(1, -4, 0, hh) return self end
    return el
end

local function scrollContainer(tab, cfg, typ, layout)
    local el = tab:Custom({ Height = cfg.Height or 220, Glass = cfg.Glass, Radius = cfg.Radius })
    el.Type = typ
    local top = 8
    if cfg.Title and cfg.Title ~= "" then
        el.TitleLabel = Creator.SectionTitle(el.Frame, cfg.Title, 12, 12)
        el.TitleLabel.ZIndex = el.Frame.ZIndex + 1
        top = 34
    end
    local s = Creator.Scroller(el.Frame, UDim2.fromOffset(8, top), UDim2.new(1, -16, 1, -top - 8))
    s.ZIndex = el.Frame.ZIndex + 1
    layout.Parent = s
    el.Scroll = s
    el.Layout = layout
    function el:Clear()
        for _, c in ipairs(s:GetChildren()) do
            if c:IsA("GuiObject") then c:Destroy() end
        end
    end
    return el
end

-- Tab:Grid({ Title?, Height = 220, CellSize = UDim2.fromOffset(88, 80), Padding = 6 }) -> .Scroll has a UIGridLayout
function Tab:Grid(cfg)
    cfg = cfg or {}
    local gl = Instance.new("UIGridLayout")
    gl.CellSize = cfg.CellSize or UDim2.fromOffset(88, 80)
    gl.CellPadding = UDim2.fromOffset(cfg.Padding or 6, cfg.Padding or 6)
    gl.SortOrder = Enum.SortOrder.LayoutOrder
    return scrollContainer(self, cfg, "Grid", gl)
end

-- Tab:List({ Title?, Height = 220, Padding = 6 }) -> .Scroll has a UIListLayout, for card lists
function Tab:List(cfg)
    cfg = cfg or {}
    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, cfg.Padding or 6)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    return scrollContainer(self, cfg, "List", ll)
end

--==================================================================--
--  Window
--==================================================================--

local Window = {}
Window.__index = Window

-- LiquidGlass:CreateWindow({
--     Title = "SAB Base Scanner", Author = "SpeediBoi", Size = UDim2.fromOffset(620, 460),
--     Theme = "Dark" | "Light", Accent = Color3?, Folder = "LiquidGlass", SideBarWidth = 150,
--     ToggleKey = Enum.KeyCode.RightControl, ReopenButton = true, ReopenText = "MENU",
--     Transparent = true, Acrylic = true, Blur = false, BlurSize = 12, Mesh = true, Shadow = true,
--     Resizable = true, MinSize = Vector2.new(420, 300),
-- })
function LiquidGlass:CreateWindow(cfg)
    cfg = cfg or {}
    if cfg.Theme then self:SetTheme(cfg.Theme) end
    local T = th()
    if cfg.Accent then
        local copy = {}
        for k, v in pairs(T) do copy[k] = v end
        copy.Name = (T.Name or "Custom") .. "+"
        copy.Accent = cfg.Accent
        copy.AccentHi = cfg.AccentHi or cfg.Accent:Lerp(Color3.new(1, 1, 1), 0.3)
        T = theme(copy)
        self.Theme = T
    end

    local titleText = cfg.Title or "Liquid Glass"
    local GUI_NAME = "LiquidGlass_" .. titleText:gsub("%W", "")
    local parent = guiParent()
    for _, ch in ipairs(parent:GetChildren()) do
        if ch.Name == GUI_NAME and ch:IsA("ScreenGui") then pcall(function() ch:Destroy() end) end
    end

    local self_ = setmetatable({
        Title = titleText, Theme = T, Config = cfg, Tabs = {}, Flags = {},
        Folder = cfg.Folder or "LiquidGlass", _conns = {}, _keybinds = {}, _navOrder = 0, _onDestroy = {},
        ToggleKey = cfg.ToggleKey, _blurOn = true,
    }, Window)

    local size = cfg.Size or UDim2.fromOffset(620, 460)
    local WIN_W, WIN_H, NAV_H = size.X.Offset, size.Y.Offset, 48
    local SIDE_W = cfg.SideBarWidth == nil and 150 or cfg.SideBarWidth
    self_.WIN_W, self_.WIN_H, self_.NAV_H, self_.SIDE_W = WIN_W, WIN_H, NAV_H, SIDE_W
    self_.MinSize = cfg.MinSize or Vector2.new(420, 300)
    self_._transparency = cfg.Transparent == false and 0 or T.ShellT

    local sg = Instance.new("ScreenGui")
    sg.Name = GUI_NAME
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 9999
    protect(sg)
    sg.Parent = parent
    self_.Gui = sg

    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)

    -- shell: tinted glass over the (acrylic-blurred) world
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.fromOffset(WIN_W, WIN_H)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.BackgroundTransparency = self_._transparency
    main.BorderSizePixel = 0
    main.Active = true
    main.ClipsDescendants = true
    main.ZIndex = 2
    main.Parent = sg
    Creator.Themed(main, { BackgroundColor3 = "Base" })
    Creator.Corner(main, 22)
    self_.Main = main
    local mainScale = Instance.new("UIScale")
    mainScale.Scale = math.min(1, math.max(0.45, (viewport.X - 40) / WIN_W), math.max(0.45, (viewport.Y - 40) / WIN_H))
    mainScale.Parent = main
    self_._scale = mainScale
    local baseScale = mainScale.Scale

    if cfg.Shadow ~= false then
        local s = Creator.Shadow(sg, 30, 0.5)
        local ss = Instance.new("UIScale")
        ss.Parent = s
        local function sync()
            s.Position = main.Position + UDim2.fromOffset(0, 10)
            s.Size = UDim2.fromOffset(main.Size.X.Offset + 60, main.Size.Y.Offset + 60)
            s.Visible = main.Visible
            ss.Scale = mainScale.Scale
        end
        main:GetPropertyChangedSignal("Position"):Connect(sync)
        main:GetPropertyChangedSignal("Size"):Connect(sync)
        main:GetPropertyChangedSignal("Visible"):Connect(sync)
        mainScale:GetPropertyChangedSignal("Scale"):Connect(sync)
        sync()
        self_.ShadowImage = s
    end

    if cfg.Mesh ~= false then Creator.Mesh(main) end
    addSheen(main, 22, 0.9)
    addRim(main, 1.5, false)

    if cfg.Acrylic ~= false then
        self_.Acrylic = Acrylic.new(main, 22)
    end
    if cfg.Blur then
        local b = Instance.new("BlurEffect")
        b.Name = GUI_NAME .. "_Blur"
        b.Size = cfg.BlurSize or 12
        b.Enabled = true
        b.Parent = Lighting
        self_.Blur = b
    end

    -- nav strip
    local nav = Instance.new("Frame")
    nav.Name = "Nav"
    nav.Size = UDim2.new(1, 0, 0, NAV_H)
    nav.BackgroundTransparency = 1
    nav.ZIndex = 3
    nav.Parent = main
    self_.Nav = nav
    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(9, 9)
    dot.Position = UDim2.fromOffset(22, 20)
    dot.BorderSizePixel = 0
    dot.ZIndex = 4
    dot.Parent = nav
    Creator.Themed(dot, { BackgroundColor3 = "AccentHi" })
    Creator.Corner(dot, "full")
    local title = Creator.Label(nav, titleText, 15, "Text", Fonts.Bold)
    title.Size = UDim2.new(0, 300, 1, 0)
    title.Position = UDim2.fromOffset(40, 0)
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.ZIndex = 4
    self_.TitleLabel = title
    if cfg.Author and cfg.Author ~= "" then
        local a = Creator.Label(nav, "by " .. cfg.Author, 10, "Muted", Fonts.Medium)
        a.Size = UDim2.new(0, 200, 0, 12)
        a.Position = UDim2.fromOffset(41, 31)
        a.ZIndex = 4
        title.Size = UDim2.new(0, 300, 0, 20)
        title.Position = UDim2.fromOffset(40, 10)
        dot.Position = UDim2.fromOffset(22, 16)
    end
    local statusLbl = Creator.Label(nav, "", 11, "Muted", Fonts.Medium, Enum.TextXAlignment.Right)
    statusLbl.Size = UDim2.new(0, 260, 1, 0)
    statusLbl.Position = UDim2.new(1, -360, 0, 0)
    statusLbl.TextTruncate = Enum.TextTruncate.AtEnd
    statusLbl.ZIndex = 4
    self_.StatusLabel = statusLbl

    local navRight = Instance.new("Frame")
    navRight.BackgroundTransparency = 1
    navRight.AnchorPoint = Vector2.new(1, 0.5)
    navRight.Position = UDim2.new(1, -18, 0.5, 0)
    navRight.Size = UDim2.new(0, 400, 0, 28)
    navRight.ZIndex = 4
    navRight.Parent = nav
    local nl = Instance.new("UIListLayout")
    nl.FillDirection = Enum.FillDirection.Horizontal
    nl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    nl.VerticalAlignment = Enum.VerticalAlignment.Center
    nl.Padding = UDim.new(0, 6)
    nl.SortOrder = Enum.SortOrder.LayoutOrder
    nl.Parent = navRight
    self_.NavRight = navRight

    local minBtn = self_:NavButton("–", function() self_:Minimize() end)
    minBtn.LayoutOrder = 998
    local closeBtn = self_:NavButton("×", function() self_:Close() end, "Red")
    closeBtn.LayoutOrder = 999
    self_.MinButton = minBtn

    Creator.Draggable(nav, main)

    -- reopen pill
    local reopenText = (cfg.ReopenText or titleText):upper()
    local reopen = Creator.Button(sg, reopenText, "Accent", T.White, 11)
    reopen.Size = UDim2.fromOffset(math.max(84, textWidth(reopenText, 11, Fonts.Bold) + 32), 32)
    reopen.Position = UDim2.fromOffset(16, 60)
    reopen.Visible = false
    reopen.ZIndex = 5
    reopen.MouseButton1Click:Connect(function() self_:Open() end)
    Creator.Draggable(reopen)
    self_.ReopenButton = reopen

    -- body
    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.new(1, 0, 1, -NAV_H)
    body.Position = UDim2.fromOffset(0, NAV_H)
    body.BackgroundTransparency = 1
    body.ZIndex = 3
    body.Parent = main
    Creator.Pad(body, 14, 14, 0, 14)
    self_.Body = body

    local contentX = 0
    if SIDE_W > 0 then
        local side = Creator.Glass(body, "panel", 16)
        side.Name = "SideBar"
        side.Size = UDim2.new(0, SIDE_W, 1, 0)
        side.ZIndex = 3
        local list = Creator.Scroller(side, UDim2.fromOffset(6, 6), UDim2.new(1, -12, 1, -12))
        list.ScrollBarThickness = 2
        list.ZIndex = 4
        local ll = Instance.new("UIListLayout")
        ll.Padding = UDim.new(0, 3)
        ll.SortOrder = Enum.SortOrder.LayoutOrder
        ll.Parent = list
        self_.SideBar, self_.TabList = side, list
        contentX = SIDE_W + 12
    end
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, -contentX, 1, 0)
    content.Position = UDim2.fromOffset(contentX, 0)
    content.ZIndex = 3
    content.Parent = body
    self_.ContentPanel = content

    -- overlay for popups; click outside to close
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundTransparency = 1
    overlay.Visible = false
    overlay.ZIndex = 100
    overlay.Parent = main
    local backdrop = Instance.new("TextButton")
    backdrop.Text = ""
    backdrop.BackgroundTransparency = 1
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.ZIndex = 100
    backdrop.Parent = overlay
    backdrop.MouseButton1Click:Connect(function()
        if self_._overlayClose then self_._overlayClose() end
    end)
    self_.Overlay = overlay

    -- tooltip (menu tier)
    local tip = Creator.Glass(main, "menu", 8)
    tip.Visible = false
    tip.ZIndex = 180
    tip.Size = UDim2.fromOffset(40, 26)
    local tipL = Creator.Label(tip, "", 11, "Text", Fonts.Medium)
    tipL.Size = UDim2.new(1, -20, 1, 0)
    tipL.Position = UDim2.fromOffset(10, 0)
    tipL.ZIndex = 181
    self_.Tooltip, self_.TooltipLabel = tip, tipL

    -- resize grip
    if cfg.Resizable ~= false then
        local grip = Instance.new("TextButton")
        grip.Text = ""
        grip.AutoButtonColor = false
        grip.BackgroundTransparency = 1
        grip.Size = UDim2.fromOffset(22, 22)
        grip.AnchorPoint = Vector2.new(1, 1)
        grip.Position = UDim2.new(1, -4, 1, -4)
        grip.ZIndex = 90
        grip.Parent = main
        local mark = Instance.new("Frame")
        mark.Size = UDim2.fromOffset(8, 8)
        mark.AnchorPoint = Vector2.new(1, 1)
        mark.Position = UDim2.new(1, -4, 1, -4)
        mark.BackgroundTransparency = 0.6
        mark.BorderSizePixel = 0
        mark.ZIndex = 91
        mark.Parent = grip
        Creator.Corner(mark, 3)
        Creator.Themed(mark, { BackgroundColor3 = "Muted" })
        local resizing, start, startSize
        grip.InputBegan:Connect(function(i)
            if isPress(i) and not self_._collapsed then resizing, start, startSize = true, i.Position, Vector2.new(self_.WIN_W, self_.WIN_H) end
        end)
        self_._conns[#self_._conns + 1] = UserInputService.InputChanged:Connect(function(i)
            if resizing and isMove(i) then
                local d = (i.Position - start) / mainScale.Scale
                self_:Resize(startSize.X + d.X, startSize.Y + d.Y)
            end
        end)
        self_._conns[#self_._conns + 1] = UserInputService.InputEnded:Connect(function(i)
            if isPress(i) then resizing = false end
        end)
    end

    -- input: toggle key + keybinds
    self_._conns[#self_._conns + 1] = UserInputService.InputBegan:Connect(function(i, gp)
        if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
        for _, el in ipairs(self_._keybinds) do
            if el.Frame.Parent and el:_input(i) then return end
        end
        if gp then return end
        if self_.ToggleKey and i.KeyCode == self_.ToggleKey then self_:Toggle() end
    end)

    -- open animation
    mainScale.Scale = baseScale * 0.94
    main.BackgroundTransparency = 1
    Creator.Tween(mainScale, { Scale = baseScale }, 0.35, Enum.EasingStyle.Back)
    Creator.Tween(main, { BackgroundTransparency = self_._transparency }, 0.3)
    self_._baseScale = baseScale

    LiquidGlass.Windows[#LiquidGlass.Windows + 1] = self_
    return self_
end

function Window:_contentWidth()
    return self.WIN_W - 28 - (self.SIDE_W > 0 and (self.SIDE_W + 12) or 0)
end

-- Window:NavButton("S", callback, color) -> round glass button in the title bar
function Window:NavButton(text, callback, color)
    local b = Creator.Button(self.NavRight, text, nil, color or "Secondary", 13)
    b.Size = UDim2.fromOffset(28, 28)
    b.ZIndex = 5
    self._navOrder = self._navOrder + 1
    b.LayoutOrder = self._navOrder
    if callback then b.MouseButton1Click:Connect(function() pcall(callback) end) end
    return b
end

function Window:_openOverlay(onClose)
    if self._overlayClose then self._overlayClose() end
    self._overlayClose = onClose
    self.Overlay.Visible = true
    return self.Overlay
end

function Window:_closeOverlay()
    self._overlayClose = nil
    self.Overlay.Visible = false
end

function Window:_tooltip(frame, text)
    local tip, lbl = self.Tooltip, self.TooltipLabel
    local w = textWidth(text, 11, Fonts.Medium) + 20
    local function move()
        local m = UserInputService:GetMouseLocation()
        local rel = (m - self.Main.AbsolutePosition) / self._scale.Scale
        local x = rel.X + 14
        if x + w > self.WIN_W - 8 then x = rel.X - w - 6 end
        tip.Position = UDim2.fromOffset(x, rel.Y + 18)
    end
    frame.MouseEnter:Connect(function()
        lbl.Text = text
        tip.Size = UDim2.fromOffset(w, 26)
        tip.Visible = true
        move()
    end)
    frame.MouseMoved:Connect(move)
    frame.MouseLeave:Connect(function() tip.Visible = false end)
end

-- Window:Tab({ Title = "Main", Icon = "rbxassetid://..." | 123456 })
function Window:Tab(cfg)
    cfg = type(cfg) == "table" and cfg or { Title = tostring(cfg) }
    local tab = setmetatable({
        Title = cfg.Title or ("Tab " .. (#self.Tabs + 1)), Window = self, Elements = {}, _order = 0,
    }, Tab)

    local content = Creator.Scroller(self.ContentPanel, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 1, 0))
    content.Visible = false
    content.ZIndex = 3
    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 6)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent = content
    Creator.Pad(content, 2, 6, 2, 8)
    tab.Content = content

    if self.TabList then
        local b = Instance.new("TextButton")
        b.AutoButtonColor = false
        b.Text = ""
        b.BorderSizePixel = 0
        b.BackgroundTransparency = 1
        b.Size = UDim2.new(1, 0, 0, 34)
        b.LayoutOrder = #self.Tabs + 1
        b.ZIndex = 4
        b.Parent = self.TabList
        Creator.Corner(b, 10)
        Creator.Themed(b, { BackgroundColor3 = "Glass" })
        local rim = addRim(b, 1, true)
        Themed[rim] = { Color = "Rim" }
        rim.Transparency = 1
        local x = 12
        if cfg.Icon and cfg.Icon ~= "" then
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.fromOffset(16, 16)
            img.Position = UDim2.new(0, 10, 0.5, -8)
            img.BackgroundTransparency = 1
            img.Image = type(cfg.Icon) == "number" and ("rbxassetid://" .. cfg.Icon) or cfg.Icon
            img.ZIndex = 5
            img.Parent = b
            Creator.Themed(img, { ImageColor3 = "Muted" })
            tab.Icon = img
            x = 34
        end
        local l = Creator.Label(b, tab.Title, 12, "Muted", Fonts.Bold)
        l.Size = UDim2.new(1, -x - 6, 1, 0)
        l.Position = UDim2.fromOffset(x, 0)
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.ZIndex = 5
        tab.TabButton, tab.TabLabel, tab.TabRim = b, l, rim
        b.MouseEnter:Connect(function() if self.CurrentTab ~= tab then Creator.Tween(b, { BackgroundTransparency = th().GlassT }, 0.15) end end)
        b.MouseLeave:Connect(function() if self.CurrentTab ~= tab then Creator.Tween(b, { BackgroundTransparency = 1 }, 0.18) end end)
        b.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
    end

    self.Tabs[#self.Tabs + 1] = tab
    if #self.Tabs == 1 then self:SelectTab(tab) end
    return tab
end

function Window:SelectTab(t)
    if type(t) == "number" then t = self.Tabs[t] end
    if not t then return end
    local T = self.Theme
    for _, tab in ipairs(self.Tabs) do
        local on = tab == t
        tab.Content.Visible = on
        if tab.TabButton then
            local key = on and "Text" or "Muted"
            Themed[tab.TabLabel] = { TextColor3 = key }
            Creator.Tween(tab.TabLabel, { TextColor3 = T[key] }, 0.15)
            Creator.Tween(tab.TabButton, { BackgroundTransparency = on and T.GlassHoverT or 1 }, 0.18)
            if on then Creator.Themed(tab.TabRim, { Color = "Rim", Transparency = "RimT" })
            else Themed[tab.TabRim] = { Color = "Rim" } tab.TabRim.Transparency = 1 end
            if tab.Icon then
                local ik = on and "AccentHi" or "Muted"
                Themed[tab.Icon] = { ImageColor3 = ik }
                Creator.Tween(tab.Icon, { ImageColor3 = T[ik] }, 0.15)
            end
        end
    end
    self.CurrentTab = t
    if self._overlayClose then self._overlayClose() end
end

function Window:SetTitle(t) self.Title = t self.TitleLabel.Text = tostring(t) return self end
function Window:SetStatus(t) self.StatusLabel.Text = tostring(t or "") return self end
function Window:SetToggleKey(k) self.ToggleKey = k return self end
function Window:SetTheme(name) return LiquidGlass:SetTheme(name) end
function Window:OnDestroy(fn) if type(fn) == "function" then self._onDestroy[#self._onDestroy + 1] = fn end return self end

function Window:SetTransparency(a)
    self._transparency = math.clamp(tonumber(a) or 0, 0, 0.95)
    self._customTransparency = true
    self.Main.BackgroundTransparency = self._transparency
    return self
end

function Window:SetAcrylic(on)
    if self.Acrylic then self.Acrylic:SetEnabled(on ~= false) end
    return self
end

function Window:SetBlur(on)
    self._blurOn = on ~= false
    if self.Blur then self.Blur.Enabled = self._blurOn and self.Main.Visible end
    return self
end

function Window:_reflow()
    for _, tab in ipairs(self.Tabs) do
        for _, el in ipairs(tab.Elements) do
            if el._measure then pcall(el._measure, el) end
        end
    end
end

function Window:Resize(w, h)
    w = math.max(self.MinSize.X, math.floor(w))
    h = math.max(self.MinSize.Y, math.floor(h))
    self.WIN_W, self.WIN_H = w, h
    if not self._collapsed then self.Main.Size = UDim2.fromOffset(w, h) end
    self:_reflow()
    return self
end

function Window:Minimize()
    self._collapsed = not self._collapsed
    local c = self._collapsed
    self.Body.Visible = not c
    if c and self._overlayClose then self._overlayClose() end
    Creator.Tween(self.Main, { Size = c and UDim2.fromOffset(self.WIN_W, self.NAV_H + 6) or UDim2.fromOffset(self.WIN_W, self.WIN_H) }, 0.22)
    self.MinButton.Text = c and "+" or "–"
end

function Window:Close()
    self.Main.Visible = false
    self.Tooltip.Visible = false
    if self._overlayClose then self._overlayClose() end
    if self.Blur then self.Blur.Enabled = false end
    if self.Config.ReopenButton ~= false then self.ReopenButton.Visible = true end
end

function Window:Open()
    self.Main.Visible = true
    self.ReopenButton.Visible = false
    if self.Blur then self.Blur.Enabled = self._blurOn end
end

function Window:Toggle()
    if self.Main.Visible then self:Close() else self:Open() end
end

function Window:IsOpen() return self.Main.Visible end

function Window:Notify(cfg) return LiquidGlass:Notify(cfg) end

-- Window:Dialog({ Title, Content, Buttons = { { Title = "OK", Callback = fn, Tint = Color3 | key }, ... } })
function Window:Dialog(cfg)
    cfg = cfg or {}
    local T = self.Theme
    local dim = Instance.new("TextButton")
    dim.Text = ""
    dim.AutoButtonColor = false
    dim.BackgroundTransparency = 1
    dim.Size = UDim2.fromScale(1, 1)
    dim.ZIndex = 190
    dim.Parent = self.Main
    Creator.Themed(dim, { BackgroundColor3 = "Scrim" })
    Creator.Tween(dim, { BackgroundTransparency = T.ScrimT }, 0.2)

    local width = cfg.Width or 320
    local textW = width - 36
    local titleH = (cfg.Title and cfg.Title ~= "") and 20 or 0
    local contentH = (cfg.Content and cfg.Content ~= "") and textHeight(cfg.Content, 11, Fonts.Regular, textW) or 0
    local height = 16 + titleH + (titleH > 0 and contentH > 0 and 6 or 0) + contentH + 16 + 30 + 16

    local panel = Creator.Glass(self.Main, "modal", 18)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(width, height)
    panel.ZIndex = 191
    local y = 16
    if titleH > 0 then
        local t = Creator.Label(panel, cfg.Title, 14, "Text", Fonts.Bold)
        t.Size = UDim2.new(1, -36, 0, 20)
        t.Position = UDim2.fromOffset(18, y)
        t.ZIndex = 192
        y = y + 20 + 6
    end
    if contentH > 0 then
        local c = Creator.Label(panel, cfg.Content, 11, "Secondary", Fonts.Regular)
        c.Position = UDim2.fromOffset(18, y)
        c.Size = UDim2.new(0, textW, 0, contentH)
        c.TextWrapped = true
        c.TextYAlignment = Enum.TextYAlignment.Top
        c.ZIndex = 192
        y = y + contentH
    end
    local rowHolder = Instance.new("Frame")
    rowHolder.BackgroundTransparency = 1
    rowHolder.Size = UDim2.new(1, -36, 0, 30)
    rowHolder.Position = UDim2.fromOffset(18, y + 16)
    rowHolder.ZIndex = 192
    rowHolder.Parent = panel
    local hl = Instance.new("UIListLayout")
    hl.FillDirection = Enum.FillDirection.Horizontal
    hl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    hl.Padding = UDim.new(0, 8)
    hl.SortOrder = Enum.SortOrder.LayoutOrder
    hl.Parent = rowHolder
    local sc = Instance.new("UIScale")
    sc.Scale = 0.9
    sc.Parent = panel
    Creator.Tween(sc, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)

    local dlg = {}
    function dlg:Close()
        Creator.Tween(dim, { BackgroundTransparency = 1 }, 0.15)
        Creator.Tween(sc, { Scale = 0.9 }, 0.15)
        task.delay(0.16, function() pcall(function() dim:Destroy() panel:Destroy() end) end)
    end
    local buttons = cfg.Buttons or { { Title = "OK" } }
    for i, b in ipairs(buttons) do
        local tint = b.Tint or (i == 1 and "Accent" or nil)
        local btn = Creator.Button(rowHolder, b.Title or "OK", tint, tint and T.White or "Text", 11)
        btn.Size = UDim2.fromOffset(math.max(72, textWidth(b.Title or "OK", 11, Fonts.Bold) + 30), 30)
        btn.LayoutOrder = i
        btn.ZIndex = 193
        btn.MouseButton1Click:Connect(function()
            if type(b.Callback) == "function" then pcall(b.Callback) end
            dlg:Close()
        end)
    end
    if cfg.CloseOnBackdrop ~= false then dim.MouseButton1Click:Connect(function() dlg:Close() end) end
    return dlg
end

function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, fn in ipairs(self._onDestroy) do pcall(fn) end
    for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    for i, w in ipairs(LiquidGlass.Windows) do
        if w == self then table.remove(LiquidGlass.Windows, i) break end
    end
    for flag, el in pairs(self.Flags) do
        if LiquidGlass.Flags[flag] == el then LiquidGlass.Flags[flag] = nil end
    end
    if self.Acrylic then pcall(function() self.Acrylic:Destroy() end) end
    if self.Blur then pcall(function() self.Blur:Destroy() end) end
    Creator.Tween(self._scale, { Scale = self._baseScale * 0.94 }, 0.18)
    Creator.Tween(self.Main, { BackgroundTransparency = 1 }, 0.18)
    local sg = self.Gui
    task.delay(0.2, function() pcall(function() sg:Destroy() end) end)
end

--==================================================================--
--  Config save / load (elements with a Flag)
--==================================================================--

local function ensureFolder(folder)
    if not f_mkdir then return end
    pcall(function()
        if not (f_isfolder and f_isfolder(folder)) then f_mkdir(folder) end
    end)
end

function Window:GetConfig()
    local data = {}
    for flag, el in pairs(self.Flags) do data[flag] = el:GetConfigValue() end
    return data
end

function Window:ApplyConfig(data)
    if type(data) ~= "table" then return false end
    for flag, v in pairs(data) do
        local el = self.Flags[flag]
        if el then pcall(function() el:SetFromConfig(v) end) end
    end
    return true
end

function Window:SaveConfig(name)
    name = name or "default"
    if not f_write then warnf("executor has no writefile - config not saved") return false, "no writefile" end
    ensureFolder(self.Folder)
    local ok, err = pcall(function()
        f_write(self.Folder .. "/" .. name .. ".json", HttpService:JSONEncode(self:GetConfig()))
    end)
    if not ok then warnf("could not save config: " .. tostring(err)) end
    return ok, err
end

function Window:LoadConfig(name)
    name = name or "default"
    if not (f_read and f_isfile) then return false, "no readfile" end
    local path = self.Folder .. "/" .. name .. ".json"
    local ok, data = pcall(function()
        if not f_isfile(path) then return nil end
        return HttpService:JSONDecode(f_read(path))
    end)
    if not ok then warnf("could not read config: " .. tostring(data)) return false, data end
    if data == nil then return false, "not found" end
    return self:ApplyConfig(data)
end

function Window:ListConfigs()
    local out = {}
    if not f_list then return out end
    pcall(function()
        for _, p in ipairs(f_list(self.Folder)) do
            local n = tostring(p):match("([^/\\]+)%.json$")
            if n then out[#out + 1] = n end
        end
    end)
    table.sort(out)
    return out
end

-- Window:AutoSave("default") loads now and saves on every flagged change
function Window:AutoSave(name)
    name = name or "default"
    self:LoadConfig(name)
    self._autosave = name
    return self
end

--==================================================================--
--  Ready-made settings tab
--==================================================================--

-- Window:AddSettingsTab({ Title = "Settings", Icon = ..., Configs = true })
function Window:AddSettingsTab(cfg)
    cfg = cfg or {}
    local w = self
    local tab = self:Tab({ Title = cfg.Title or "Settings", Icon = cfg.Icon })

    tab:Section({ Title = "Appearance" })
    local names = {}
    for k in pairs(LiquidGlass.Themes) do names[#names + 1] = k end
    table.sort(names)
    tab:Dropdown({
        Title = "Theme", Values = names, Value = self.Theme.Name,
        Flag = cfg.Flag ~= false and "LG_Theme" or nil,
        Callback = function(n) if LiquidGlass.Themes[n] then LiquidGlass:SetTheme(n) end end,
    })
    tab:Slider({
        Title = "Window transparency", Desc = "how much of the world shows through the shell",
        Value = { Min = 0, Max = 90, Default = math.floor(self._transparency * 100 + 0.5) },
        Suffix = "%", Flag = cfg.Flag ~= false and "LG_Transparency" or nil,
        Callback = function(v) w:SetTransparency(v / 100) end,
    })
    if self.Acrylic then
        tab:Toggle({
            Title = "Frosted glass", Desc = "blurs the world behind the window (needs graphics quality 8+)", Value = true,
            Flag = cfg.Flag ~= false and "LG_Acrylic" or nil,
            Callback = function(on) w:SetAcrylic(on) end,
        })
    end
    if self.Blur then
        tab:Toggle({
            Title = "Full screen blur", Value = true,
            Flag = cfg.Flag ~= false and "LG_Blur" or nil,
            Callback = function(on) w:SetBlur(on) end,
        })
    end

    tab:Section({ Title = "Window" })
    tab:Keybind({
        Title = "Toggle key", Desc = "show or hide the window", Value = self.ToggleKey,
        Flag = cfg.Flag ~= false and "LG_ToggleKey" or nil,
        OnChange = function(k) w.ToggleKey = k end,
    })
    tab:Button({ Title = "Hide window", Desc = "the pill in the corner brings it back", Callback = function() w:Close() end })
    tab:Button({ Title = "Destroy UI", Tint = "Red", Callback = function()
        w:Dialog({
            Title = "Destroy UI?", Content = "This closes the window and removes every element. Re-run the script to get it back.",
            Buttons = { { Title = "Destroy", Tint = "Red", Callback = function() w:Destroy() end }, { Title = "Cancel" } },
        })
    end })

    if cfg.Configs ~= false and f_write then
        tab:Section({ Title = "Config" })
        local nameBox = tab:Input({ Title = "Config name", Placeholder = "default", Value = "default" })
        local list = tab:Dropdown({ Title = "Saved configs", Values = self:ListConfigs(), Search = true })
        tab:Button({ Title = "Save", Desc = "writes every flagged element to the name above", Callback = function()
            local n = nameBox.Value ~= "" and nameBox.Value or "default"
            local ok = w:SaveConfig(n)
            list:Refresh(w:ListConfigs(), true)
            LiquidGlass:Notify({ Title = ok and "Config saved" or "Save failed", Content = n, Color = ok and "Green" or "Red" })
        end })
        tab:Button({ Title = "Load selected", Callback = function()
            local n = list.Value
            if not n then LiquidGlass:Notify({ Title = "Pick a config first", Color = "Gold" }) return end
            local ok = w:LoadConfig(n)
            LiquidGlass:Notify({ Title = ok and "Config loaded" or "Load failed", Content = n, Color = ok and "Green" or "Red" })
        end })
        tab:Toggle({ Title = "Auto save", Desc = "save on every change to the name above", Callback = function(on)
            w._autosave = on and (nameBox.Value ~= "" and nameBox.Value or "default") or nil
        end })
    end
    return tab
end

--==================================================================--
--  Misc
--==================================================================--

function LiquidGlass:DestroyAll()
    for i = #self.Windows, 1, -1 do self.Windows[i]:Destroy() end
end

function LiquidGlass:GetFlag(flag)
    local el = self.Flags[flag]
    return el and el.Value or nil
end

return LiquidGlass
