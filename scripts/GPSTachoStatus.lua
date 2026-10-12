-- TerraLine GPS v0.9.9.57 | Equipment status inside the native FS25 tachometer.
-- GIANTS FS25 SpeedMeterDisplay uses speedBg, speedBgScale and speedBgRight;
-- gaugeBackgroundElement belongs to the old FS22 implementation.
GPSTachoStatus = {}
local H=GPSTachoStatus
function H.draw(display,vehicle)
    if not (GPSVehicleEquipment and GPSVehicleEquipment.isInstalled(vehicle)) then return end
    if display==nil or display.isVehicleDrawSafe~=true or type(renderText)~="function" then return end
    if type(display.getVisible)=="function" and not display:getVisible() then return end
    local label,r,g,b=GPSVehicleEquipment.getStatus(vehicle)
    if label==nil then return end

    -- The game's native draw just updated these pixel-scaled screen positions.
    -- Use them directly so UI scaling and ultrawide screen placement follow the
    -- real speedometer; avoid hard-coded bottom-right screen coordinates.
    local bg=display.speedBg
    local x=bg and bg.x
    local y=bg and bg.y
    local width=bg and bg.width
    local height=bg and bg.height
    if type(x)~="number" or type(y)~="number" or
       type(width)~="number" or type(height)~="number" or width<=0 or height<=0 then
        -- A nonstandard speedmeter/other HUD mod may replace native overlays.
        -- Skip safely, preserving all original game HUD drawing.
        return
    end
    local dy=0.008
    if type(getNormalizedScreenValues)=="function" then
        local _,normalizedY=getNormalizedScreenValues(0,9)
        if type(normalizedY)=="number" then dy=normalizedY end
    end
    local size=0.014*(display.uiScale or 1)
    if type(display.scalePixelToScreenHeight)=="function" then
        local computed=display:scalePixelToScreenHeight(15)
        if type(computed)=="number" and computed>0 then size=computed end
    end
    local tx=x+width*0.5
    local ty=math.max(0.03,math.min(0.96,y+height+dy))
    -- Preserve the render state used by GIANTS for the rest of the HUD.
    if type(setTextAlignment)=="function" and RenderText then
        setTextAlignment(RenderText.ALIGN_CENTER)
    end
    if type(setTextColor)=="function" then setTextColor(r,g,b,1) end
    renderText(tx,ty,size,label)
    if type(setTextColor)=="function" then setTextColor(1,1,1,1) end
    if type(setTextAlignment)=="function" and RenderText then
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end
