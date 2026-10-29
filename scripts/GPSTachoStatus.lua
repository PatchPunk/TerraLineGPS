-- TerraLine GPS v0.9.9.59 | Compact equipped-vehicle badge at the LEFT of the FS25 speedometer.
-- Native HUD stays intact: never draw on top of fill-type status above the gauge.
GPSTachoStatus = {}
local H = GPSTachoStatus

local function size(display, w, h)
    if type(display.scalePixelValuesToScreenVector) ~= "function" then return nil, nil end
    return display:scalePixelValuesToScreenVector(w, h)
end

local function textSize(display, pixels)
    if type(display.scalePixelToScreenHeight) ~= "function" then return nil end
    return display:scalePixelToScreenHeight(pixels)
end

function H.draw(display, vehicle)
    if not (GPSVehicleEquipment and GPSVehicleEquipment.isInstalled(vehicle)) then return end
    if display == nil or display.isVehicleDrawSafe ~= true or type(renderText) ~= "function" then return end
    if type(display.getVisible) == "function" and not display:getVisible() then return end

    local label, r, g, b = GPSVehicleEquipment.getStatus(vehicle)
    if label == nil then return end
    local bg = display.speedBg
    if not bg or type(bg.x) ~= "number" or type(bg.y) ~= "number" or
        type(bg.width) ~= "number" or type(bg.height) ~= "number" or
        bg.width <= 0 or bg.height <= 0 then return end

    -- Measure everything with the SAME HUD pixel scaling as the GIANTS gauge.
    -- Thus left/right anchoring survives HUD scaling and wide aspect ratios.
    local badgeW, badgeH = size(display, 124, 55)
    local gap = size(display, 11, 0)
    local corner = size(display, 5, 0)
    local accent = size(display, 3, 0)
    local iconInsetX, iconInsetY = size(display, 13, 0)
    local iconW, iconH = size(display, 21, 21)
    local textInsetX = size(display, 42, 0)
    local textTop, textBottom = textSize(display, 12), textSize(display, 11)
    if type(badgeW) ~= "number" or type(badgeH) ~= "number" or
       type(gap) ~= "number" or type(corner) ~= "number" or
       type(accent) ~= "number" or type(iconW) ~= "number" or
       type(iconH) ~= "number" or type(iconInsetX) ~= "number" or
       type(iconInsetY) ~= "number" or type(textInsetX) ~= "number" or
       type(textTop) ~= "number" or type(textBottom) ~= "number" then return end
    if badgeW <= 0 or badgeH <= 0 or gap < 0 then return end

    -- The fill-type readout is ABOVE speedBg. Keep the badge aligned to the
    -- middle of the round dial instead of drawing at speedBg's upper edge.
    local x = bg.x - gap - badgeW
    local y = bg.y + 0.5 * (bg.height - badgeH)
    -- If a reduced HUD scale cannot fit the plaque, do not cover the gauge.
    if x < 0.005 or y < 0.005 or y + badgeH > 0.995 then return end

    local state = "AUS"
    if label:find("AUTO", 1, true) then
        state = "AUTO AKTIV"
    elseif label:find("BEREIT", 1, true) then
        state = "BEREIT"
    end

    -- Dark rounded-corner plaque, muted outline and narrow status accent.
    -- drawFilledRect is the native GIANTS UI rectangle primitive, also used by
    -- the existing TerraLine menus. No external textures or extra HUD panels.
    if type(drawFilledRect) == "function" then
        -- Mild transparency: a single layer in every pixel.  Previously the
        -- two overlapping rounded-rectangle primitives composited twice,
        -- making the center look nearly opaque even with alpha < 1.
        local darkR, darkG, darkB, opacity = 0.10, 0.12, 0.14, 0.78
        drawFilledRect(x + corner, y, badgeW - 2*corner, corner, darkR, darkG, darkB, opacity)
        drawFilledRect(x, y + corner, badgeW, badgeH - 2*corner, darkR, darkG, darkB, opacity)
        drawFilledRect(x + corner, y + badgeH - corner, badgeW - 2*corner, corner, darkR, darkG, darkB, opacity)
        local accentY = y + badgeH*0.18
        drawFilledRect(x + accent, accentY, accent, badgeH*0.64, r, g, b, 0.96)
    end

    -- Reuse the base-game GPS glyph rather than drawing an unrelated symbol.
    -- Cache it once: creating an overlay every draw frame is too expensive.
    if H.iconChecked ~= true then
        H.iconChecked = true
        if g_overlayManager and type(g_overlayManager.createOverlay) == "function" then
            -- Use the same GPS slice as the GIANTS speedometer and keep
            -- the overlay cached. Unexpected overlay errors stay visible.
            local overlay = g_overlayManager:createOverlay("gui.icon_gps", 0, 0, iconW, iconH)
            if overlay then H.statusIcon = overlay end
        end
    end
    if H.statusIcon and type(H.statusIcon.setColor) == "function" and
        type(H.statusIcon.setPosition) == "function" and type(H.statusIcon.render) == "function" then
        H.statusIcon:setDimension(iconW, iconH)
        H.statusIcon:setPosition(x + iconInsetX, y + (badgeH-iconH)*0.5)
        H.statusIcon:setColor(r, g, b, 1)
        H.statusIcon:render()
    end

    if type(setTextAlignment) == "function" and RenderText then
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
    if type(setTextBold) == "function" then setTextBold(true) end
    if type(setTextColor) == "function" then setTextColor(0.92, 0.95, 0.96, 1) end
    local textX = x + textInsetX
    renderText(textX, y + badgeH * 0.54, textTop, "TL GPS")
    if type(setTextBold) == "function" then setTextBold(false) end
    if type(setTextColor) == "function" then setTextColor(r, g, b, 1) end
    renderText(textX, y + badgeH * 0.19, textBottom, state)

    -- Restore GIANTS text state for later HUD elements and other mods.
    if type(setTextBold) == "function" then setTextBold(false) end
    if type(setTextColor) == "function" then setTextColor(1, 1, 1, 1) end
    if type(setTextAlignment) == "function" and RenderText then
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end
