-- TerraLine GPS menu page 1 (Spurfuehrung) - UI refresh.
-- Layout/drawing only; the click handling at the bottom of this file keeps the
-- previous behaviour (plus direct step selectors). Shared look: GPSMenuTheme.
-- Coordinates are fractions of the centred GUI area (top-left origin).
GPSMenuPage1 = {}

local T = GPSMenuTheme
local C = T.C
local rect = T.rect
local label = T.text

local STEPS = {0.01, 0.05, 0.10, 0.50}

-- Approved blueprint-style line drawings of tractor and implement are
-- small transparent BC3/DXT5 sprites. All headings, values, boundaries
-- and guidance geometry remain native LS text and primitives.
local function drawTractorFallback(screen, cx, top, w, h)
    local x = cx - w * 0.5
    rect(screen, x + w * .13, top + h * .12, w * .18, h * .32, C.well)
    rect(screen, x + w * .69, top + h * .12, w * .18, h * .32, C.well)
    rect(screen, x + w * .09, top + h * .57, w * .22, h * .33, C.well)
    rect(screen, x + w * .69, top + h * .57, w * .22, h * .33, C.well)
    T.box(screen, x + w * .29, top + h * .12, w * .42, h * .76, C.accentDim, C.line, 6)
end

-- Overlays use normalized coordinates, but the monitor is widescreen.
-- Convert sprite height into a width with the SAME NUMBER OF PIXELS, not
-- the same number of normalized screen units (which squashed the tractors).
local function squareSpriteWidth(screen, height)
    local aspect = 9 / 16  -- 16:9 fallback for UI before graphics globals exist
    if type(g_pixelSizeX) == "number" and type(g_pixelSizeY) == "number" and
       g_pixelSizeX > 0 and g_pixelSizeY > 0 then
        aspect = g_pixelSizeX / g_pixelSizeY
    elseif type(g_screenWidth) == "number" and type(g_screenHeight) == "number" and
           g_screenWidth > 0 and g_screenHeight > 0 then
        aspect = g_screenHeight / g_screenWidth
    end
    return height * screen.pageH / screen.pageW * aspect
end

local function sprite(screen, key, file, x, top, w, h)
    if type(Overlay) ~= "table" or type(Overlay.new) ~= "function" then return false end
    screen.gpsPage1Sprites = screen.gpsPage1Sprites or {}
    local px = screen.pageX + x * screen.pageW
    local py = screen.pageY + (1 - top - h) * screen.pageH
    local pw, ph = w * screen.pageW, h * screen.pageH
    local data = screen.gpsPage1Sprites[key]
    -- Work-width graphic may be resized; rebuild *only after a width change*,
    -- never on every frame. Other sprites are permanent until onClose().
    if data and (math.abs(data.w - w) > 0.0001 or math.abs(data.x - x) > 0.0001 or
                 math.abs(data.top - top) > 0.0001 or math.abs(data.h - h) > 0.0001) then
        if data.overlay and type(data.overlay.delete) == "function" then
            data.overlay:delete()
        end
        screen.gpsPage1Sprites[key] = nil
        data = nil
    end
    if not data then
        local dir = GPSMenu and GPSMenu.modDir or g_currentModDirectory
        if not dir then return false end
        local iconPath = dir .. file
        if type(fileExists) == "function" and not fileExists(iconPath) then return false end
        local img = Overlay.new(iconPath, px, py, pw, ph)
        if not img then return false end
        data = {overlay = img, x = x, top = top, w = w, h = h}
        screen.gpsPage1Sprites[key] = data
    end
    local overlay = data.overlay
    if overlay and overlay.overlayId and overlay.overlayId ~= 0 then
        overlay:render()
        return true
    end
    return false
end

function GPSMenuPage1.onClose(screen)
    for _, data in pairs(screen.gpsPage1Sprites or {}) do
        if data.overlay and type(data.overlay.delete) == "function" then
            data.overlay:delete()
        end
    end
    screen.gpsPage1Sprites = nil
end

local function dashLine(screen, x, top, w, h, color, count)
    for i = 0, (count or 7) - 1 do
        rect(screen, x, top + (i + .1) * h / (count or 7), w, h / (count or 7) * 0.58, color)
    end
end

function GPSMenuPage1.getWidth(screen)
    if screen and type(screen.nativeWidth) == "number" then return screen.nativeWidth end
    local vehicle = GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    local w = GPSImplementDetector and GPSImplementDetector.getWidth(vehicle) or 3
    return type(w) == "number" and w or 3
end

local function renderWorkPreview(screen)
    local x, t, w, h = 0.594, 0.150, 0.393, 0.294
    T.panel(screen, x, t, w, h, "VORSCHAU - ARBEITSBREITE")
    T.box(screen, x + .018, t + .078, w - .036, h - .104, C.well, C.lineSoft, 8)
    local cx = x + w * .51
    local ww = GPSMenuPage1.getWidth(screen)
    local half = math.max(.073, math.min(.160, .088 + ww * .0024))
    -- subtle worked-soil structure gives a sense of movement without a
    -- photo or a large background texture.
    for i = 0, 13 do
        rect(screen, x + .028 + i * .0245, t + .090, .004, .150, C.surface2)
    end
    dashLine(screen, cx - half, t + .108, .002, .126, C.warn, 5)
    dashLine(screen, cx + half, t + .108, .002, .126, C.warn, 5)
    -- Independent vertical placement based on the actual DDS alpha bounds:
    -- tractor 256x512 (visible rows 62..448), disc 512x128 (rows 6..121).
    local tractorTop = t + .067
    local tractorH = .125
    local tractorW = squareSpriteWidth(screen, tractorH) * .50
    if not sprite(screen, "widthTractor", "gui/terraline_work_tractor.dds",
                  cx - tractorW * .5, tractorTop, tractorW, tractorH) then
        drawTractorFallback(screen, cx, t + .083, .070, .091)
    end
    -- One common 'half' for the yellow work borders and the VISIBLE device
    -- edges. DDS contains 24px transparent padding on each side.
    local discW = (2 * half) * (512 / 464)
    local discH = .058
    local discTop = t + .181
    if not sprite(screen, "widthPlanter", "gui/terraline_work_disc.dds",
                  cx - discW * .5, discTop, discW, discH) then
        T.round(screen, cx - half, t + .186, 2 * half, .041, C.accentDim, 6)
    end
    rect(screen, cx - half, t + .245, 2 * half, .0026, C.accent)
    rect(screen, cx - half, t + .237, .002, .019, C.accent)
    rect(screen, cx + half - .002, t + .237, .002, .019, C.accent)
    -- width read-out as pill
    local txt = string.format("%.2f m", ww)
    local tw = T.textWidth(screen, txt, .034, true)
    T.box(screen, cx - tw / 2 - .016, t + .252, tw + .032, .034, C.surface, C.accentMid, 9)
    label(screen, cx, t + .277, txt, .029, C.accent, true, "center")
    label(screen, x + .028, t + h - .020, "GERAETEBREITE (DYNAMISCH)", .0145, C.textMute, false)
end

-- The menu uses the very same driver-right conversion as hotkeys.
function GPSMenuPage1.getDriverDirectionSign()
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    return GPSABLineManager.getDriverRightSign(vehicle)
end
function GPSMenuPage1.getDriverRelativeOffset()
    return (GPSABLineManager.offsetMeters or 0)*GPSMenuPage1.getDriverDirectionSign()
end
-- Display only: values in the driver's current left-positive frame.
-- The A/B points already contain the manual translation; do not apply it
-- twice. This is also safe while device-auto awaits its first measurement.
function GPSMenuPage1.getOffsetSummary()
    local manual = GPSMenuPage1.getDriverRelativeOffset()
    local auto = 0
    local state = "AUS"
    local d = GPSDeviceOffsetAuto
    if d and d.enabled then
        state = "MESSUNG"
        local vehicle = GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
        local a, b = GPSABLineManager.a, GPSABLineManager.b
        local node = vehicle and GPSVehicleDetector.getPositionNode(vehicle)
        if node and a and b and type(localDirectionToWorld) == "function" then
            local fx, _, fz = localDirectionToWorld(node, 0, 0, 1)
            if type(fx) == "number" and type(fz) == "number" then
                local dir = (fx * (b.x - a.x) + fz * (b.z - a.z)) >= 0 and 1 or -1
                local correction = d.getCorrection(vehicle, dir)
                if type(correction) == "number" and correction == correction then
                    auto = correction * dir
                    state = "BEREIT"
                end
            end
        end
    end
    return manual, auto, manual + auto, state
end
-- Text-only normalization of signed zero; stored A/B offset is unaffected.
local function uiOffsetMeters(value)
    if type(value) ~= "number" then return "--" end
    if math.abs(value) < 0.005 then return "0.00 m" end
    return string.format("%+.2f m", value)
end

local function renderGuidePreview(screen)
    local x, t, w, h = 0.594, 0.456, 0.393, 0.380
    T.panel(screen, x, t, w, h, "VORSCHAU - SPURFUEHRUNG")
    T.box(screen, x + .018, t + .078, w - .036, h - .098, C.well, C.lineSoft, 8)
    local cx = x + w * .51
    -- Worked ground / stubble: low-cost native drawing, no large textures.
    for i = 0, 11 do rect(screen, x + .030 + i * .0295, t + .090, .006, h * .66, C.surface2) end
    local width = GPSMenuPage1.getWidth(screen)
    local half = math.max(.075, math.min(.138, .088 + width * .0021))
    local manualOffset, autoOffset, totalOffset, autoState = GPSMenuPage1.getOffsetSummary()
    -- Same total target shift as the 3D guidance line. Use the SAME scale
    -- for track width and offset; fit the whole corridor inside this panel.
    local metersToScreen = (2 * half) / math.max(.50, width)
    local available = w * .5 - .030
    local footprint = width * .5 + math.abs(totalOffset)
    if footprint > 0 and metersToScreen * footprint > available then
        metersToScreen = available / footprint
    end
    half = width * .5 * metersToScreen
    local dx = totalOffset * metersToScreen
    local guideX = cx + dx
    local valid = GPSABLineManager.a ~= nil and GPSABLineManager.b ~= nil
    local active = GPSSteeringController and GPSSteeringController.enabled
    local guideColor = valid and (active and C.accent or C.danger) or C.line
    -- Yellow preview corridor and green tractor target move together.
    dashLine(screen, guideX - half, t + .093, .002, h * .62, C.warn, 7)
    dashLine(screen, guideX + half, t + .093, .002, h * .62, C.warn, 7)
    -- Approved guidance preview: front mower and rear side mower on the RIGHT.
    local sHeight = .210
    local sWidth = squareSpriteWidth(screen, sHeight)
    if not sprite(screen, "guideMower", "gui/terraline_guide_mower_right.dds", cx - sWidth * .5, t + .094, sWidth, sHeight) then
        drawTractorFallback(screen, cx, t + .119, .074, .145)
    end
    -- Course is drawn over the sprite so its position remains unambiguous.
    rect(screen, guideX - .0010, t + .091, .0020, h * .654, guideColor)
    if valid and math.abs(dx) > .001 then
        rect(screen, math.min(cx, guideX), t + .302, math.abs(dx), .003, C.accent)
        rect(screen, cx - .001, t + .293, .002, .020, C.textDim)
        rect(screen, guideX - .001, t + .293, .002, .020, C.accent)
    end
    -- Footer card: legend + offsets.
    local fy = t + h - .090
    T.box(screen, x + .022, fy, w - .044, .076, C.surface, C.line, 8)
    rect(screen, x + .036, fy + .019, .016, .0024, active and C.accent or C.danger)
    label(screen, x + .058, fy + .0265, "FAHRSPUR", .0150, C.textDim)
    rect(screen, x + .160, fy + .019, .016, .0024, C.warn)
    label(screen, x + .182, fy + .0265, "ARBEITSKANTEN", .0150, C.textDim)
    if valid then
        local autoText = autoState == "BEREIT" and uiOffsetMeters(autoOffset)
            or (autoState == "AUS" and "AUS" or "MESSUNG")
        label(screen, x + .036, fy + .0475, "MANUELL " .. uiOffsetMeters(manualOffset) .. "   |   AUTO " .. autoText,
            .0150, C.textMute, false, "left", w - .08)
        label(screen, x + .036, fy + .0690, "EFFEKTIVE FAHRSPUR " .. uiOffsetMeters(totalOffset),
            .0185, autoState == "MESSUNG" and C.warn or C.accent, true, "left", w - .08)
    else
        label(screen, x + .036, fy + .0560, "A und B zuerst setzen (Alt+B)", .0185, C.warn, true)
    end
end

local function fmtTrack()
    if not (GPSTrackPosition and GPSTrackPosition.valid) or type(GPSTrackPosition.track) ~= "number" then return "-" end
    local t = GPSTrackPosition.track
    if GPSSteeringController and GPSSteeringController.enabled and GPSSteeringController.lockedTrack ~= nil then
        t = GPSSteeringController.lockedTrack
    end
    return tostring(GPSTrackPosition.getDisplayNumber(t) or "-")
end
local function deviceName()
    local vehicle = GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    if GPSImplementDetector and type(GPSImplementDetector.getData) == "function" then
        local _, _, name = GPSImplementDetector.getData(vehicle)
        return name or "Kein Arbeitsgeraet"
    end
    return "Kein Arbeitsgeraet"
end
function GPSMenuPage1.onOpen(screen)
    screen.page1VisualSettings = false
    if GPSDisplaySettings then GPSDisplaySettings.ensureLoaded() end
    screen.widthStepIndex = screen.widthStepIndex or 1
    screen.shiftStepIndex = screen.shiftStepIndex or 1
    screen.nativeMessage = (GPSABLineManager.a and GPSABLineManager.b)
        and "Werte werden direkt uebernommen."
        or "Versatz: Zuerst A und B im Feld setzen (Alt+B zweimal)."
    screen.nativeWidth = GPSMenuPage1.getWidth()
    screen.nativeDeviceName = deviceName()
    local vehicle = GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    if GPSImplementDetector.override == nil and GPSImplementDetector.getData and
       select(4, GPSImplementDetector.getData(vehicle)) == false then
        screen.nativeMessage = "Arbeitsbreite nicht erkannt - Standardwert; bitte pruefen."
    end
end

-- One settings row: caption on the left, control(s) drawn by the caller.
local function rowCaption(screen, x, top, h, text, sub)
    local size = 0.0215
    if sub then
        label(screen, x, top + h * .42, text, size, C.text, false, "left", 0.17)
        label(screen, x, top + h * .42 + .024, sub, 0.0145, C.textMute, false, "left", 0.17)
    else
        label(screen, x, T.mid(top, h, size), text, size, C.text, false, "left", 0.17)
    end
end

local function stepOptions(prefix)
    local out = {}
    for i, v in ipairs(STEPS) do out[i] = {label = string.format("%.2f", v), action = prefix .. i} end
    return out
end

local function drawVisualSettings(screen)
    local dx, dy = T.px(screen)
    local x, w = .200, .787
    T.panel(screen, x, .150, w, .686, "LINIEN-OPTIK")
    -- live preview of the line band
    local bandWidth = (GPSConfig and GPSConfig.lineThicknessMeters) or 0
    local bandHeight = .0035 + math.max(0, math.min(.30, bandWidth)) * .077
    T.box(screen, .222, .228, .757, .074, C.well, C.lineSoft, 8)
    label(screen, .236, .256, "VORSCHAU", .0150, C.textMute, true)
    label(screen, .236, .284, "Geschlossene GPS-Linien", .0175, C.textDim)
    rect(screen, .410, .265 - bandHeight * .5, .545, bandHeight, C.accent)
    rect(screen, .410, .265 - .021, .545, dy, C.lineSoft)
    rect(screen, .410, .265 + .021, .545, dy, C.lineSoft)

    local height = (GPSConfig and GPSConfig.lineHeightMeters) or 0.10
    local thickness = (GPSConfig and GPSConfig.lineThicknessMeters) or 0
    local seconds = (GPSConfig and GPSConfig.lineDurationSeconds) or 0
    local cardH = .120
    local function card(top, title, sub)
        T.box(screen, .222, top, .757, cardH, C.surface2, C.lineSoft, 9)
        label(screen, .240, top + .054, title, .0245, C.text, true, "left", .24)
        label(screen, .240, top + .088, sub, .0165, C.textMute, false, "left", .24)
    end
    local cy = .322
    card(cy, "Linienhoehe", "Abstand zum Boden, 0.25 m Schritte")
    local midY = cy + (cardH - .058) / 2
    T.stepper(screen, .470, midY, .190, .058, string.format("%.2f m", height), "visualHeightMinus", "visualHeightPlus")
    T.button(screen, .676, midY, .137, .058, "BODEN 0.10", "visualHeightGround", {size = .0185})
    T.button(screen, .823, midY, .144, .058, "MAIS 3.00", "visualHeightMaize", {size = .0185})

    cy = .460
    card(cy, "Linienbreite", "Breite einer einzelnen Linie, 0.05 m")
    midY = cy + (cardH - .058) / 2
    T.stepper(screen, .470, midY, .190, .058, string.format("%.2f m", thickness), "visualThicknessMinus", "visualThicknessPlus")
    T.button(screen, .676, midY, .137, .058, "DUENN", "visualThicknessThin", {size = .0185})
    T.button(screen, .823, midY, .144, .058, "BREIT 0.30", "visualThicknessWide", {size = .0185})

    cy = .598
    card(cy, "Sichtbarkeit", "Anzeige bei aktiver Lenkung")
    midY = cy + (cardH - .058) / 2
    local opts, sel = {}, 1
    for i, v in ipairs({{0, "IMMER"}, {2, "2 SEK"}, {5, "5 SEK"}, {10, "10 SEK"}}) do
        opts[i] = {label = v[2], action = "visualDuration" .. v[1]}
        if seconds == v[1] then sel = i end
    end
    T.segmented(screen, .470, midY, .497, .058, opts, sel, {size = .0205})
    label(screen, .240, .760, "Die Einstellungen werden im Spielstand gespeichert.", .0175, C.textMute)

    T.button(screen, .671, .925, .154, .052, "STANDARD", "visualDefaults", {size = .0195})
    T.button(screen, .839, .925, .137, .052, "ZURUECK", "visualBack", {primary = true, size = .0205})
end

function GPSMenuPage1.draw(screen)
    local src = GPSImplementDetector and GPSImplementDetector.override and "Manuell" or "Auto"
    local name = screen.nativeDeviceName or "Kein Arbeitsgeraet"
    if #name > 30 then name = name:sub(1, 27) .. "..." end
    local hint
    do
        local probe = GPSDeviceOffsetProbe
        local autoDevice = GPSDeviceOffsetAuto
        hint = (probe and type(probe.lastValue) == "number") and
            string.format("Geraete-Mitte %+.2f m (Traktorsicht) | %s", probe.lastValue,
                autoDevice and autoDevice.enabled and (autoDevice.lastStatus or "Automatik AN") or "Automatik AUS")
            or "Geraete-Mitte noch nicht erkannt (Diagnose: gsGPSDeviceOffset)"
    end
    T.chrome(screen, {
        active = 1, master = true,
        message = screen.nativeMessage or (screen.page1VisualSettings and "Linienanzahl anpassen." or hint),
        chips = {
            {text = "Kurs: " .. tostring(GPSCourseManager and GPSCourseManager.getActiveName() or "A/B-Linie"), dot = C.accent, maxW = .27},
            {text = name .. " (" .. src .. ")", maxW = .30},
        },
    })
    if screen.page1VisualSettings then
        drawVisualSettings(screen)
        return
    end

    local dx, dy = T.px(screen)
    local x, w = .200, .385
    local abValid = GPSABLineManager.a ~= nil and GPSABLineManager.b ~= nil
    local inner = x + w - .018

    -- ARBEITSBREITE -------------------------------------------------
    local ct = T.panel(screen, x, .150, w, .236, "ARBEITSBREITE") + .005
    local rowH = .044
    rowCaption(screen, x + .020, ct, rowH, "Arbeitsbreite")
    T.stepper(screen, inner - .188, ct, .188, rowH, string.format("%.2f m", GPSMenuPage1.getWidth(screen)), "widthMinus", "widthPlus")
    local r2 = ct + .0525
    rowCaption(screen, x + .020, r2, rowH, "Auto-Arbeitsbreite")
    local isAuto = GPSImplementDetector.override == nil
    T.toggle(screen, inner - 62 * dx, r2 + (rowH - 30 * dy) / 2, 62 * dx, 30 * dy, isAuto, "widthAuto")
    label(screen, inner - 62 * dx - .012, T.mid(r2, rowH, .0200), isAuto and "AN" or "AUS", .0200, isAuto and C.accent or C.textMute, true, "right")
    local r3 = ct + .105
    rowCaption(screen, x + .020, r3, rowH, "Breiten-Schritt (m)")
    T.segmented(screen, inner - .218, r3, .218, rowH, stepOptions("widthStepSet"), screen.widthStepIndex or 1, {size = .0195})

    -- SPURVERSATZ ---------------------------------------------------
    local py = .400
    ct = T.panel(screen, x, py, w, .240, "SPURVERSATZ") + .005
    local mirrorOn = GPSAutoMirror and GPSAutoMirror.enabled == true
    T.toggle(screen, inner - 52 * dx, py + .0115, 52 * dx, 26 * dy, mirrorOn, "toggleAutoMirror")
    label(screen, inner - 52 * dx - .012, T.mid(py + .0115, 26 * dy, .0185), "Auto-Wende", .0185, mirrorOn and C.text or C.textMute, false, "right")
    rowCaption(screen, x + .020, ct, rowH, "Manueller Versatz")
    T.stepper(screen, inner - .188, ct, .188, rowH,
        abValid and uiOffsetMeters(GPSMenuPage1.getDriverRelativeOffset()) or "A/B fehlt",
        "shiftMinus", "shiftPlus", {color = abValid and C.text or C.warn, disabled = false})
    r2 = ct + .0525
    rowCaption(screen, x + .020, r2, rowH, "Versatz-Schritt (m)")
    T.segmented(screen, inner - .218, r2, .218, rowH, stepOptions("shiftStepSet"), screen.shiftStepIndex or 1, {size = .0195})
    r3 = ct + .105
    rowCaption(screen, x + .020, r3, rowH, "A/B-Aktionen")
    T.button(screen, inner - .222, r3, .108, rowH, "A/B TAUSCH", "reverseAB", {size = .0185, disabled = not abValid})
    T.button(screen, inner - .108, r3, .108, rowH, "SPIEGELN", "mirrorOffset", {size = .0185, disabled = not abValid})

    -- AKTUELLE SPUR -------------------------------------------------
    py = .652
    ct = T.panel(screen, x, py, w, .184, "AKTUELLE SPUR") + .004
    local deviceAutoOn = GPSDeviceOffsetAuto and GPSDeviceOffsetAuto.enabled == true
    T.toggle(screen, inner - 52 * dx, py + .0115, 52 * dx, 26 * dy, deviceAutoOn, "toggleDeviceAuto")
    label(screen, inner - 52 * dx - .012, T.mid(py + .0115, 26 * dy, .0185), "Geraete-Auto", .0185, deviceAutoOn and C.text or C.textMute, false, "right")
    local _, autoValue, _, autoState = GPSMenuPage1.getOffsetSummary()
    local active = GPSSteeringController and GPSSteeringController.enabled
    local tw, gap, th = .1105, .0075, .0950
    local tx = x + .017
    T.tile(screen, tx, ct, tw, th, "SPURNUMMER", fmtTrack(), C.accent, .040)
    T.tile(screen, tx + tw + gap, ct, tw, th, "GERAETE-AUTO",
        autoState == "BEREIT" and uiOffsetMeters(autoValue) or autoState, autoState == "BEREIT" and C.accent or C.textMute, .028)
    T.tile(screen, tx + 2 * (tw + gap), ct, tw, th, "GPS STATUS", active and "AKTIV" or "INAKTIV",
        active and C.accent or C.textMute, .028)

    renderWorkPreview(screen)
    renderGuidePreview(screen)

    T.button(screen, .455, .925, .200, .052, "LINIEN-OPTIK", "visualOpen", {size = .0195})
    T.button(screen, .671, .925, .154, .052, "STANDARD", "resetSteps", {size = .0195})
    T.button(screen, .839, .925, .137, .052, "OK / SCHLIESSEN", "close", {primary = true, size = .0195})
end

local function info(screen,msg)
    screen.nativeMessage=msg
    if GPSLogger and GPSLogger.info then GPSLogger.info("GPS Menu S1: "..msg) end
end
local function adjustWidth(screen,d)
    local v=GPSMenuPage1.getWidth(screen)
    local steps={0.01,0.05,0.10,0.50}
    local step=steps[screen.widthStepIndex or 1]
    local newWidth=math.max(.50,math.min(60,math.floor((v+d*step)*100+.5)/100))
    if math.abs(newWidth-v)<0.001 then return end
    local msg=GPSFieldTest:commandWidth(newWidth)
    screen.nativeWidth=newWidth
    info(screen,msg.." (GPS ggf. deaktiviert)")
end
local function refreshShiftedTracks()
    local vehicle=GPSVehicleDetector.getCurrentVehicle()
    local width=GPSImplementDetector.getWidth(vehicle)
    GPSTrackGenerator.generate(nil,GPSABLineManager.a,GPSABLineManager.b,width)
    GPSTrackGenerator.cacheKey=tostring(GPSABLineManager.a)..":"..tostring(GPSABLineManager.b)..":"..tostring(width)
    GPSTrackPosition.lastUpdate=150
end
local function shift(screen,sign)
    local steps={0.01,0.05,0.10,0.50}
    local amount=steps[screen.shiftStepIndex or 1]
    local direction=GPSMenuPage1.getDriverDirectionSign()
    -- Move the FULL course; match the keyboard's driver-right convention.
    local vehicle=GPSVehicleDetector.getCurrentVehicle()
    local ok,msg=GPSABLineManager.shiftDriverRelative(sign,amount,vehicle)
    if not ok then info(screen,msg.." (Alt+B setzt zuerst A, dann B)");return end
    refreshShiftedTracks()
    info(screen,string.format("Gesamte GPS-Spur %s um %.2f m | Gesamt: %+.2f m",sign>0 and "rechts" or "links",amount,GPSMenuPage1.getDriverRelativeOffset()))
    GPSLogger.info(string.format("Versatz Fahrersicht: Eingabe=%+d RichtungAzuB=%+d gespeicherterVersatz=%+.2f",sign,direction,GPSABLineManager.offsetMeters or 0))
end
-- Mirror about the ORIGINAL A/B reference, not around the already shifted
-- guidance line. Negating the stored offset requires moving the current A/B
-- points by -2*offset (otherwise only the UI value would change).
-- Keep current A->B orientation and GPS locked-track steering intact.
local function mirrorOffset(screen)
    if not GPSABLineManager.a or not GPSABLineManager.b then
        info(screen,"Versatz spiegeln: Zuerst A und B setzen")
        return
    end
    local stored=GPSABLineManager.offsetMeters or 0
    if math.abs(stored)<0.0001 then
        info(screen,"Versatz spiegeln: Aktuell 0.00 m - kein Versatz vorhanden")
        return
    end
    local direction=stored>0 and -1 or 1
    local ok,msg=GPSABLineManager.shift(direction,2*math.abs(stored))
    if not ok then info(screen,msg);return end
    -- Counteract floating point drift for exact visual 0.5/-0.5 symmetry.
    GPSABLineManager.offsetMeters=-stored
    if GPSDeviceOffsetAuto and type(GPSDeviceOffsetAuto.onCourseMirrored)=="function" then GPSDeviceOffsetAuto.onCourseMirrored() end
    refreshShiftedTracks()
    info(screen,string.format("Versatz gespiegelt | Jetzt %+.2f m aus Fahrersicht",GPSMenuPage1.getDriverRelativeOffset()))
    GPSLogger.info(string.format("Versatz gespiegelt: vorher=%+.2f nachher=%+.2f",stored,GPSABLineManager.offsetMeters))
end
local function reverse(screen)
    if not GPSABLineManager.a or not GPSABLineManager.b then return end
    -- Reverse the reference direction only when the steering assist is stopped.
    GPSSteeringController.stop("A/B-Richtung geaendert")
    GPSABLineManager.a,GPSABLineManager.b=GPSABLineManager.b,GPSABLineManager.a
    GPSABLineManager.offsetMeters=-(GPSABLineManager.offsetMeters or 0)
    if GPSDeviceOffsetAuto and type(GPSDeviceOffsetAuto.onCourseMirrored)=="function" then GPSDeviceOffsetAuto.onCourseMirrored() end
    GPSTrackGenerator.reset()
    GPSTrackPosition.reset()
    info(screen,"A/B-Richtung getauscht; GPS ausgeschaltet")
end
function GPSMenuPage1.onMouseClick(screen,px,top)
    local hits=screen.nativeHits or {}
    for i=#hits,1,-1 do
        local hit=hits[i]
        if px>=hit.x and px<=hit.x+hit.w and top>=hit.top and top<=hit.top+hit.h then
            local a=hit.action
            if a=="close" then screen:onClickBack()
            elseif a=="masterToggle" then
                info(screen,GPSFieldTest:commandMaster("toggle"))
            elseif a:sub(1,4)=="page" then
                screen.page=tonumber(a:sub(5)) or 1
                GPSLogger.info("GPS Menue: Seite "..tostring(screen.page))
            elseif GPSFieldTest and GPSFieldTest.masterEnabled==false then
                info(screen,"TerraLine GPS AUS - zuerst SYSTEM AN waehlen")
            elseif a=="visualOpen" then
                if GPSDisplaySettings then GPSDisplaySettings.ensureLoaded() end
                screen.page1VisualSettings=true
                screen.nativeMessage="Linien-Optik: Hoehe, Breite und Anzeigezeit einstellen"
            elseif a=="visualBack" then
                screen.page1VisualSettings=false
                screen.nativeMessage="Linien-Optik uebernommen"
            elseif a=="visualDefaults" then
                if GPSDisplaySettings then
                    local ok,msg=GPSDisplaySettings.restoreDefaults()
                    info(screen,string.format("Linienhoehe: %.2f m | Breite: %.2f m | %s",
                        GPSConfig.lineHeightMeters or 0.10,
                        GPSConfig.lineThicknessMeters or 0,ok and "gespeichert" or msg))
                end
            elseif a=="visualHeightMinus" or a=="visualHeightPlus" or
                    a=="visualHeightGround" or a=="visualHeightMaize" then
                if GPSDisplaySettings then
                    local value=(GPSConfig.lineHeightMeters or 0.10)
                    if a=="visualHeightMinus" then value=value-0.25
                    elseif a=="visualHeightPlus" then value=value+0.25
                    elseif a=="visualHeightGround" then value=0.10
                    else value=3.00 end
                    local ok,msg=GPSDisplaySettings.setHeightMeters(value)
                    info(screen,string.format("GPS-Linienhoehe: %.2f m | %s",
                        GPSConfig.lineHeightMeters,ok and "gespeichert" or msg))
                end
            elseif a=="visualThicknessMinus" or a=="visualThicknessPlus" or
                    a=="visualThicknessThin" or a=="visualThicknessWide" then
                if GPSDisplaySettings then
                    local value=(GPSConfig.lineThicknessMeters or 0)
                    if a=="visualThicknessMinus" then value=value-0.05
                    elseif a=="visualThicknessPlus" then value=value+0.05
                    elseif a=="visualThicknessThin" then value=0
                    else value=0.30 end
                    local ok,msg=GPSDisplaySettings.setThicknessMeters(value)
                    info(screen,string.format("GPS-Liniendicke: %.2f m | %s",
                        GPSConfig.lineThicknessMeters,ok and "gespeichert" or msg))
                end
            elseif a:match("^visualDuration%d+$") then
                if GPSDisplaySettings then
                    local seconds=tonumber(a:match("%d+$")) or 0
                    local ok,msg=GPSDisplaySettings.setDurationSeconds(seconds)
                    info(screen,"Linien bei GPS EIN: "..(GPSConfig.lineDurationSeconds==0 and "IMMER" or (tostring(GPSConfig.lineDurationSeconds).." Sekunden"))..
                        (ok and " | gespeichert" or (" | "..msg)))
                end
            elseif a=="widthMinus" then adjustWidth(screen,-1)
            elseif a=="widthPlus" then adjustWidth(screen,1)
            elseif a=="widthAuto" then
                if GPSImplementDetector.override==nil then
                    info(screen,GPSFieldTest:commandWidth(GPSMenuPage1.getWidth(screen)))
                else
                    info(screen,GPSFieldTest:commandAutoWidth())
                    screen.nativeWidth=GPSMenuPage1.getWidth()
                    screen.nativeDeviceName=deviceName()
                end
            elseif a=="toggleAutoMirror" then
                if GPSAutoMirror then
                    GPSAutoMirror.enabled=not GPSAutoMirror.enabled
                    GPSAutoMirror.reset()
                    info(screen,"Automatische Wende "..(GPSAutoMirror.enabled and "AN" or "AUS"))
                end
            elseif a=="toggleDeviceAuto" then
                if GPSDeviceOffsetAuto and type(GPSDeviceOffsetAuto.setEnabled)=="function" then
                    local ok,msg=GPSDeviceOffsetAuto.setEnabled(not GPSDeviceOffsetAuto.enabled)
                    info(screen,msg)
                end
            elseif a:match("^widthStepSet%d$") then screen.widthStepIndex=tonumber(a:sub(-1)) or 1
            elseif a:match("^shiftStepSet%d$") then screen.shiftStepIndex=tonumber(a:sub(-1)) or 1
            elseif a=="widthStep" then screen.widthStepIndex=(screen.widthStepIndex%4)+1
            elseif a=="shiftMinus" then shift(screen,-1)
            elseif a=="shiftPlus" then shift(screen,1)
            elseif a=="shiftStep" then screen.shiftStepIndex=(screen.shiftStepIndex%4)+1
            elseif a=="rotate90" then
                local ok,msg=GPSCourseManager.rotate90()
                info(screen,msg)
            elseif a=="reverseAB" then reverse(screen)
            elseif a=="mirrorOffset" then mirrorOffset(screen)
            elseif a=="resetSteps" then
                screen.widthStepIndex=1;screen.shiftStepIndex=1
                info(screen,"Schrittweiten auf 0.01 m zurueckgesetzt")
            end
            return true
        end
    end
    return true -- S1 handles its own native hit areas exclusively
end
