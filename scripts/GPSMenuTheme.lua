-- TerraLine GPS - shared menu theme and widgets (UI refresh).
-- Everything is drawn with the same native primitives as before (drawFilledRect,
-- renderText); this file only centralises colours, rounded shapes, text fitting,
-- hover feedback and the small widget set used by pages 1, 3 and 4.
-- Coordinates are fractions of the centred menu area, origin top-left, exactly
-- like the old pages, so hit areas ({x,top,w,h,action}) are unchanged.
GPSMenuTheme = {}
local T = GPSMenuTheme

T.C = {
    base      = {0.040, 0.058, 0.062, 0.985},
    header    = {0.066, 0.094, 0.098, 1},
    sidebar   = {0.052, 0.076, 0.080, 1},
    surface   = {0.078, 0.112, 0.117, 1},
    surface2  = {0.056, 0.083, 0.088, 1},
    well      = {0.046, 0.068, 0.073, 1},
    button    = {0.112, 0.158, 0.165, 1},
    buttonHi  = {0.150, 0.208, 0.216, 1},
    line      = {0.190, 0.262, 0.270, 1},
    lineSoft  = {0.122, 0.172, 0.180, 1},
    text      = {0.945, 0.965, 0.952, 1},
    textDim   = {0.760, 0.820, 0.810, 1},
    textMute  = {0.560, 0.640, 0.630, 1},
    accent    = {0.450, 0.920, 0.220, 1},
    accentHi  = {0.580, 0.980, 0.340, 1},
    accentMid = {0.210, 0.440, 0.140, 1},
    accentDim = {0.145, 0.300, 0.105, 1},
    onAccent  = {0.035, 0.090, 0.030, 1},
    warn      = {0.990, 0.780, 0.130, 1},
    danger    = {0.940, 0.290, 0.230, 1},
    dangerDim = {0.340, 0.115, 0.100, 1},
}
local C = T.C

----------------------------------------------------------------------
-- geometry helpers
----------------------------------------------------------------------
-- Size of ONE screen pixel in menu-local units (x, y).
function T.px(s)
    local gx = (type(g_pixelSizeX) == "number" and g_pixelSizeX > 0) and g_pixelSizeX or (1 / 1920)
    local gy = (type(g_pixelSizeY) == "number" and g_pixelSizeY > 0) and g_pixelSizeY or (1 / 1080)
    return gx / s.pageW, gy / s.pageH
end

-- Width (local units) of a square that is `pixels` px wide / high.
function T.squareW(s, h)
    local dx, dy = T.px(s)
    return h / dy * dx
end

function T.hover(s, x, t, w, h)
    local hx, hy = s.hoverX, s.hoverY
    if hx == nil or hy == nil then return false end
    return hx >= x and hx <= x + w and hy >= t and hy <= t + h
end

local function hit(s, x, t, w, h, action)
    if action then
        s.nativeHits[#s.nativeHits + 1] = {x = x, top = t, w = w, h = h, action = action}
    end
end
T.hit = hit

----------------------------------------------------------------------
-- primitives (pixel exact: every edge is snapped once to the screen grid)
----------------------------------------------------------------------
local function pxSize()
    local gx = (type(g_pixelSizeX) == "number" and g_pixelSizeX > 0) and g_pixelSizeX or (1 / 1920)
    local gy = (type(g_pixelSizeY) == "number" and g_pixelSizeY > 0) and g_pixelSizeY or (1 / 1080)
    return gx, gy
end
-- local -> integer screen pixels (origin top-left of the screen)
local function toPx(s, x, t, w, h)
    local gx, gy = pxSize()
    local x0 = math.floor((s.pageX + x * s.pageW) / gx + 0.5)
    local x1 = math.floor((s.pageX + (x + w) * s.pageW) / gx + 0.5)
    local y0 = math.floor((1 - s.pageY - (1 - t) * s.pageH) / gy + 0.5)
    local y1 = math.floor((1 - s.pageY - (1 - t - h) * s.pageH) / gy + 0.5)
    if x1 <= x0 then x1 = x0 + 1 end
    if y1 <= y0 then y1 = y0 + 1 end
    return x0, y0, x1, y1
end
local function fillPx(x0, y0, x1, y1, c)
    if type(drawFilledRect) ~= "function" or x1 <= x0 or y1 <= y0 then return end
    local gx, gy = pxSize()
    drawFilledRect(x0 * gx, 1 - y1 * gy, (x1 - x0) * gx, (y1 - y0) * gy, c[1], c[2], c[3], c[4] or 1)
end
-- Stepped quarter-circle corners on an integer pixel rectangle.
local function roundPx(x0, y0, x1, y1, c, r)
    local rr = math.floor(math.min(r or 0, (x1 - x0) / 2, (y1 - y0) / 2))
    if rr <= 1 then fillPx(x0, y0, x1, y1, c) return end
    local insets = {}
    for i = 0, rr - 1 do
        local yy = rr - i - 0.5
        insets[#insets + 1] = rr - math.floor(math.sqrt(rr * rr - yy * yy) + 0.5)
    end
    local i = 1
    while i <= #insets do
        local inset, j = insets[i], i
        while j < #insets and insets[j + 1] == inset do j = j + 1 end
        fillPx(x0 + inset, y0 + i - 1, x1 - inset, y0 + j, c)
        fillPx(x0 + inset, y1 - j, x1 - inset, y1 - i + 1, c)
        i = j + 1
    end
    fillPx(x0, y0 + rr, x1, y1 - rr, c)
end

function T.rect(s, x, t, w, h, c)
    if w <= 0 or h <= 0 then return end
    local x0, y0, x1, y1 = toPx(s, x, t, w, h)
    fillPx(x0, y0, x1, y1, c)
end
local rect = T.rect

-- Filled rectangle with rounded corners; r in screen pixels.
function T.round(s, x, t, w, h, c, r)
    if w <= 0 or h <= 0 then return end
    local x0, y0, x1, y1 = toPx(s, x, t, w, h)
    roundPx(x0, y0, x1, y1, c, r or 6)
end

-- Rounded box with a 1 px border.
function T.box(s, x, t, w, h, fill, border, r)
    if w <= 0 or h <= 0 then return end
    r = r or 8
    local x0, y0, x1, y1 = toPx(s, x, t, w, h)
    if border then
        roundPx(x0, y0, x1, y1, border, r)
        roundPx(x0 + 1, y0 + 1, x1 - 1, y1 - 1, fill, math.max(1, r - 1))
    else
        roundPx(x0, y0, x1, y1, fill, r)
    end
end

function T.hline(s, x, t, w, c)
    local _, dy = T.px(s)
    rect(s, x, t, w, dy, c or C.lineSoft)
end

function T.vline(s, x, t, h, c)
    local dx = T.px(s)
    rect(s, x, t, dx, h, c or C.lineSoft)
end

-- Small round dot, diameter in pixels, centred at (cx, cy) in local units.
function T.dot(s, cx, cy, px, c)
    local dx, dy = T.px(s)
    T.round(s, cx - px * dx / 2, cy - px * dy / 2, px * dx, px * dy, c, px / 2)
end

----------------------------------------------------------------------
-- text
----------------------------------------------------------------------
local function chopUtf8(str)
    local n = #str
    if n <= 1 then return "" end
    n = n - 1
    while n > 1 and str:byte(n + 1) ~= nil and str:byte(n + 1) >= 128 and str:byte(n + 1) < 192 do n = n - 1 end
    return str:sub(1, n)
end

-- Width of a string in local x units.
function T.textWidth(s, str, size, bold)
    str = tostring(str or "")
    if type(getTextWidth) == "function" then
        if type(setTextBold) == "function" then setTextBold(bold == true) end
        local w = getTextWidth(size * s.pageH, str)
        if type(setTextBold) == "function" then setTextBold(false) end
        if type(w) == "number" then return w / s.pageW end
    end
    return #str * size * 0.52 * (s.pageH / s.pageW) * (bold and 1.06 or 1)
end

-- Baseline (top-origin) that vertically centres a line of text in [t, t+h].
function T.mid(t, h, size)
    return t + h / 2 + size * 0.43
end

function T.text(s, x, t, str, size, color, bold, align, maxW)
    if type(renderText) ~= "function" then return end
    str = tostring(str or "")
    local c = color or C.text
    if maxW and T.textWidth(s, str, size, bold) > maxW then
        while #str > 1 and T.textWidth(s, str .. "...", size, bold) > maxW do str = chopUtf8(str) end
        str = str .. "..."
    end
    local px = s.pageX + x * s.pageW
    local py = s.pageY + (1 - t) * s.pageH
    if type(setTextColor) == "function" then setTextColor(c[1], c[2], c[3], c[4] or 1) end
    if type(setTextBold) == "function" then setTextBold(bold == true) end
    if type(setTextAlignment) == "function" and type(RenderText) == "table" then
        setTextAlignment(align == "center" and RenderText.ALIGN_CENTER or
                         align == "right" and RenderText.ALIGN_RIGHT or RenderText.ALIGN_LEFT)
    end
    renderText(px, py, size * s.pageH, str)
    if type(setTextAlignment) == "function" and type(RenderText) == "table" then setTextAlignment(RenderText.ALIGN_LEFT) end
    if type(setTextBold) == "function" then setTextBold(false) end
    if type(setTextColor) == "function" then setTextColor(1, 1, 1, 1) end
end

----------------------------------------------------------------------
-- widgets
----------------------------------------------------------------------
-- o: primary, selected, danger, disabled, size, bold(default true)
function T.button(s, x, t, w, h, title, action, o)
    o = o or {}
    local hovered = (not o.disabled) and T.hover(s, x, t, w, h)
    local fill, border, tc
    if o.disabled then
        fill, border, tc = C.surface2, C.lineSoft, C.textMute
    elseif o.primary then
        fill = hovered and C.accentHi or C.accent
        border, tc = fill, C.onAccent
    elseif o.danger then
        fill = hovered and {0.46, 0.15, 0.13, 1} or C.dangerDim
        border, tc = C.danger, {1, 0.80, 0.76, 1}
    elseif o.selected then
        fill = hovered and C.accentMid or C.accentDim
        border, tc = C.accent, C.accentHi
    else
        fill = hovered and C.buttonHi or C.button
        border = hovered and C.accentMid or C.line
        tc = hovered and C.text or C.textDim
        if o.plain then tc = C.text end
    end
    T.box(s, x, t, w, h, fill, border, o.radius or 7)
    local size = o.size or math.min(h * 0.47, 0.027)
    T.text(s, x + w / 2, T.mid(t, h, size), title, size, tc, o.bold ~= false, "center", w - 0.006)
    if not o.disabled then hit(s, x, t, w, h, action) end
end

-- Pill switch. Hit area covers the track.
function T.toggle(s, x, t, w, h, on, action, disabled)
    local dx, dy = T.px(s)
    local hovered = (not disabled) and T.hover(s, x, t, w, h)
    local track = on and (hovered and C.accentHi or C.accent) or (hovered and C.line or C.lineSoft)
    if disabled then track = C.surface2 end
    T.round(s, x, t, w, h, track, h / dy / 2)
    local kp = h / dy - 6
    local kw, kh = kp * dx, kp * dy
    local kx = on and (x + w - 3 * dx - kw) or (x + 3 * dx)
    T.round(s, kx, t + 3 * dy, kw, kh, on and C.onAccent or C.textDim, kp / 2)
    if not disabled then hit(s, x, t, w, h, action) end
end

-- [ - ]  value  [ + ] control. Returns nothing.
function T.stepper(s, x, t, w, h, value, minusAction, plusAction, o)
    o = o or {}
    local dx, dy = T.px(s)
    local bw = h / dy * dx
    T.box(s, x, t, w, h, C.well, C.lineSoft, 8)
    T.button(s, x + 2 * dx, t + 2 * dy, bw - 2 * dx, h - 4 * dy, "-", minusAction, {size = 0.036, radius = 6, disabled = o.disabled})
    T.button(s, x + w - bw, t + 2 * dy, bw - 2 * dx, h - 4 * dy, "+", plusAction, {size = 0.034, radius = 6, disabled = o.disabled})
    local vs = o.size or 0.029
    T.text(s, x + w / 2, T.mid(t, h, vs), value, vs, o.color or C.text, true, "center", w - 2 * bw - 0.01)
end

-- Segmented selector. options = {{label=..., action=...}, ...}
function T.segmented(s, x, t, w, h, options, selected, o)
    o = o or {}
    local dx, dy = T.px(s)
    T.box(s, x, t, w, h, C.well, C.lineSoft, 8)
    local n = #options
    local gap = 2 * dx
    local sw = (w - 2 * dx - gap * (n + 1)) / n
    for i, opt in ipairs(options) do
        local sx = x + dx + gap + (i - 1) * (sw + gap)
        local hovered = T.hover(s, sx, t, sw, h)
        local isSel = (i == selected)
        local fill = isSel and C.accentDim or (hovered and C.buttonHi or nil)
        if fill then T.round(s, sx, t + 2 * dy, sw, h - 4 * dy, fill, 6) end
        local size = o.size or 0.021
        T.text(s, sx + sw / 2, T.mid(t, h, size), opt.label, size,
            isSel and C.accentHi or (hovered and C.text or C.textDim), isSel, "center", sw - 0.006)
        hit(s, sx, t, sw, h, opt.action)
    end
end

-- Panel with accent title bar. Returns the y where content may start.
function T.panel(s, x, t, w, h, title, o)
    o = o or {}
    local dx, dy = T.px(s)
    T.box(s, x, t, w, h, C.surface, C.line, 10)
    T.round(s, x + 12 * dx, t + 17 * dy, 4 * dx, 22 * dy, C.accent, 2)
    T.text(s, x + 24 * dx, t + 34 * dy, title, 0.022, C.text, true, "left", w - 0.05)
    T.hline(s, x + 12 * dx, t + 49 * dy, w - 24 * dx, C.lineSoft)
    return t + 49 * dy
end

-- Rounded stat tile: small caption on top, big value.
function T.tile(s, x, t, w, h, caption, value, valueColor, valueSize)
    local dx, dy = T.px(s)
    T.box(s, x, t, w, h, C.well, C.lineSoft, 8)
    T.text(s, x + 10 * dx, t + 22 * dy, caption, 0.0165, C.textMute, false, "left", w - 0.02)
    local vs = valueSize or 0.034
    T.text(s, x + 10 * dx, t + h - 12 * dy, value, vs, valueColor or C.text, true, "left", w - 0.02)
end

-- Pill label; returns its width (local units).
function T.chip(s, x, t, str, o)
    o = o or {}
    local dx, dy = T.px(s)
    local size = o.size or 0.0185
    local hp = o.height or 24
    local pad = 12 * dx
    local tw = T.textWidth(s, str, size, o.bold)
    local maxW = o.maxW
    local w = tw + 2 * pad + (o.dot and 14 * dx or 0)
    if maxW and w > maxW then w = maxW; tw = w - 2 * pad - (o.dot and 14 * dx or 0) end
    local h = hp * dy
    T.box(s, x, t, w, h, o.fill or C.well, o.border or C.lineSoft, hp / 2)
    local tx = x + pad
    if o.dot then
        T.dot(s, x + pad + 4 * dx, t + h / 2, 8, o.dot)
        tx = tx + 14 * dx
    end
    T.text(s, tx, T.mid(t, h, size), str, size, o.color or C.textDim, o.bold, "left", tw + 0.002)
    return w
end

-- Key cap, e.g. "Alt". Returns width.
function T.keycap(s, x, t, str, size)
    local dx, dy = T.px(s)
    size = size or 0.0165
    local tw = T.textWidth(s, str, size, true)
    local w = tw + 14 * dx
    local h = 21 * dy
    T.round(s, x, t + 2 * dy, w, h, C.line, 5)
    T.round(s, x, t, w, h, C.button, 5)
    T.text(s, x + w / 2, T.mid(t, h, size), str, size, C.text, true, "center")
    return w
end

-- Total width of a "Alt + T" style key combination.
function T.keysWidth(s, parts, size)
    local dx = T.px(s)
    local total = 0
    for i, p in ipairs(parts) do
        total = total + T.textWidth(s, p, size or 0.0165, true) + 14 * dx + (i > 1 and 12 * dx or 0)
    end
    return total
end

-- Key combination drawn from the left; returns its width.
function T.keysAt(s, x, t, parts, size)
    local dx, dy = T.px(s)
    local x0 = x
    for i, p in ipairs(parts) do
        if i > 1 then
            T.text(s, x + 2 * dx, T.mid(t, 21 * dy, 0.016), "+", 0.016, C.textMute, true)
            x = x + 12 * dx
        end
        x = x + T.keycap(s, x, t, p, size)
    end
    return x - x0
end

-- Right-anchored key combination.
function T.keys(s, right, t, parts, size)
    return T.keysAt(s, right - T.keysWidth(s, parts, size), t, parts, size)
end

-- Several alternative key combinations separated by "/", right anchored.
function T.keyGroups(s, right, t, groups, size)
    local dx = T.px(s)
    local sep = 16 * dx
    local total = 0
    for i, g in ipairs(groups) do total = total + T.keysWidth(s, g, size) + (i > 1 and sep or 0) end
    local x = right - total
    for i, g in ipairs(groups) do
        if i > 1 then
            T.text(s, x + 4 * dx, T.mid(t, 21 * select(2, T.px(s)), 0.016), "/", 0.016, C.textMute, true)
            x = x + sep
        end
        x = x + T.keysAt(s, x, t, g, size)
    end
end

-- Compass dial with needle; angle in degrees clockwise from north.
function T.compass(s, cx, cy, radiusPx, angle, active)
    local dx, dy = T.px(s)
    local function put(ox, oy, size, c)
        T.rect(s, cx + ox * dx - size * dx / 2, cy + oy * dy - size * dy / 2, size * dx, size * dy, c)
    end
    for i = 0, 71 do
        local a = math.rad(i * 5)
        local major = (i % 18 == 0)
        local mid = (i % 6 == 0)
        local len = major and 7 or (mid and 5 or 3)
        local sz = major and 3 or 2
        for k = 0, (major and 2 or (mid and 1 or 0)) do
            local rr = radiusPx - k * 2.5
            put(math.sin(a) * rr, -math.cos(a) * rr, sz, major and C.textDim or (mid and C.line or C.lineSoft))
        end
    end
    local labels = {{"N", 0, -1}, {"O", 1, 0}, {"S", 0, 1}, {"W", -1, 0}}
    for _, l in ipairs(labels) do
        local lr = radiusPx - 17
        T.text(s, cx + l[2] * lr * dx, cy + l[3] * lr * dy + 0.0065, l[1], 0.0175,
            l[1] == "N" and C.danger or C.textMute, true, "center")
    end
    if type(angle) == "number" then
        local a = math.rad(angle)
        local sx, sy = math.sin(a), -math.cos(a)
        local col = active and C.accentHi or C.accent
        local len = radiusPx - 24
        local step = 2
        for d = -10, len, step do
            put(sx * d, sy * d, 3, d < 0 and C.textMute or col)
        end
        for _, off in ipairs({150, -150}) do
            local b = a + math.rad(off)
            for d = 2, 11, 2 do
                put(sx * len + math.sin(b) * d, sy * len - math.cos(b) * d, 3, col)
            end
        end
    end
    T.dot(s, cx, cy, 8, C.surface)
    T.dot(s, cx, cy, 4, C.textDim)
end

----------------------------------------------------------------------
-- page chrome shared by all pages
----------------------------------------------------------------------
T.navItems = {
    {id = 1, name = "Spurfuehrung"},
    {id = 3, name = "Speicher"},
    {id = 4, name = "Info & Version"},
}

-- o.active (1|3|4), o.chips = {{text=,color=,dot=},...}, o.message,
-- o.master = true: interactive SYSTEM switch (page 1)
function T.chrome(s, o)
    o = o or {}
    s.nativeHits = {}
    local dx, dy = T.px(s)

    -- window + header
    T.box(s, 0, 0, 1, 1, C.base, C.line, 14)
    T.round(s, dx, dy, 1 - 2 * dx, 0.128, C.header, 13)
    rect(s, dx, 0.090, 1 - 2 * dx, 0.038 - dy, C.header)
    T.hline(s, dx, 0.128, 1 - 2 * dx, C.line)
    rect(s, dx, 0.128 - dy, 0.20, dy * 2, C.accent)

    -- logo tile
    local th = 46 * dy
    local tw = 46 * dx
    local ty = (0.128 - th) / 2
    T.box(s, 0.024, ty, tw, th, C.accentDim, C.accent, 9)
    if GPSMenuSymbols then
        GPSMenuSymbols.header(s, 0.024 + tw / 2, ty + (th - 0.056) / 2 + 0.001)
    end

    -- title block
    local titleX = 0.024 + tw + 0.018
    T.text(s, titleX, 0.070, "TERRALINE GPS", 0.046, C.text, true)
    local titleW = T.textWidth(s, "TERRALINE GPS", 0.046, true)
    T.chip(s, titleX + titleW + 0.014, 0.036, "v" .. tostring(GPSConfig and GPSConfig.version or "?"),
        {color = C.accent, fill = C.accentDim, border = C.accentMid, bold = true, size = 0.017, height = 22})
    local cx = titleX
    for _, chip in ipairs(o.chips or {}) do
        local w = T.chip(s, cx, 0.083, chip.text, {color = chip.color or C.textDim, dot = chip.dot, maxW = chip.maxW or 0.30, size = 0.0175})
        cx = cx + w + 0.010
    end

    -- live status (read only)
    local master = GPSFieldTest and GPSFieldTest.isMasterEnabled and GPSFieldTest:isMasterEnabled()
    local steering = GPSSteeringController and GPSSteeringController.enabled
    local label, col
    if not master then label, col = "SYSTEM AUS", C.textMute
    elseif steering then label, col = "GPS-LENKUNG AKTIV", C.accent
    else label, col = "BEREIT", C.warn end
    local sw = T.textWidth(s, label, 0.019, true) + 40 * dx
    T.chip(s, 0.915 - sw - 0.012, 0.047, label, {color = col, dot = col, bold = true, size = 0.019, height = 30, fill = C.well})

    -- close button
    T.button(s, 0.923, 0.041, 46 * dx, 46 * dy, "X", "close", {size = 0.026, radius = 9})

    -- sidebar
    T.box(s, 0.012, 0.145, 0.177, 0.691, C.sidebar, C.lineSoft, 12)
    for slot, item in ipairs(T.navItems) do
        local top = 0.164 + (slot - 1) * 0.124
        local active = (item.id == o.active)
        local hovered = (not active) and T.hover(s, 0.020, top, 0.162, 0.110)
        if active then
            T.box(s, 0.020, top, 0.162, 0.110, C.accentDim, C.accent, 9)
            T.round(s, 0.020 + 2 * dx, top + 14 * dy, 4 * dx, 0.110 - 28 * dy, C.accent, 2)
        else
            T.box(s, 0.020, top, 0.162, 0.110, hovered and C.buttonHi or C.button, hovered and C.accentMid or C.lineSoft, 9)
        end
        if GPSMenuSymbols then
            GPSMenuSymbols.draw(s, item.id, 0.049, top + 0.026, active and C.accent or C.textMute)
        end
        T.text(s, 0.075, top + 0.066, item.name, 0.0225, active and C.text or C.textDim, active, "left", 0.106)
        hit(s, 0.020, top, 0.162, 0.110, "page" .. item.id)
    end

    -- system card at the bottom of the sidebar
    local cardT = 0.552
    T.box(s, 0.020, cardT, 0.162, 0.276, C.well, C.lineSoft, 9)
    T.text(s, 0.032, cardT + 0.038, "TERRALINE GPS", 0.0175, C.textMute, true)
    T.text(s, 0.032, cardT + 0.092, master and "SYSTEM AN" or "SYSTEM AUS", 0.027, master and C.accent or C.textMute, true, "left", 0.14)
    if o.master then
        T.toggle(s, 0.032, cardT + 0.118, 62 * dx, 30 * dy, master == true, "masterToggle")
    else
        local lw = T.chip(s, 0.032, cardT + 0.120, steering and "Lenkung aktiv" or "Lenkung aus",
            {color = steering and C.accent or C.textMute, dot = steering and C.accent or C.textMute, size = 0.0165, height = 24, maxW = 0.138})
    end
    T.hline(s, 0.030, cardT + 0.186, 0.142, C.lineSoft)
    T.text(s, 0.032, T.mid(cardT + 0.214, 21 * dy, 0.0165), "Ein / aus:", 0.0165, C.textMute)
    T.keys(s, 0.172, cardT + 0.214, {"Alt", "T"}, 0.0165)

    -- message bar + escape hint
    T.box(s, 0.013, 0.849, 0.974, 0.060, C.surface2, C.lineSoft, 9)
    T.dot(s, 0.030, 0.879, 8, o.messageColor or C.accent)
    T.text(s, 0.042, T.mid(0.849, 0.060, 0.021), o.message or "", 0.021, C.textDim, false, "left", 0.93)
    local kw = T.keycap(s, 0.030, 0.939, "ESC", 0.0175)
    T.text(s, 0.030 + kw + 0.010, T.mid(0.939, 21 * dy, 0.021), "Zurueck", 0.021, C.textDim, false)
    hit(s, 0.018, 0.921, 0.18, 0.070, "close")
end
