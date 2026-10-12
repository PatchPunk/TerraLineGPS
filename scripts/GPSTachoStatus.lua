-- TerraLine GPS 0.9.9.55 | Minimal status drawn on the existing GIANTS speedometer.
-- Called by the existing SpeedMeterDisplay.draw bridge: no additional GUI.
GPSTachoStatus = {}
local H=GPSTachoStatus
function H.draw(display,vehicle)
    if not (GPSVehicleEquipment and GPSVehicleEquipment.isInstalled(vehicle)) then return end
    if type(renderText)~="function" or not display then return end
    if type(display.getVisible)=="function" and not display:getVisible() then return end
    if not display.isVehicleDrawSafe then return end
    local gauge=display.gaugeBackgroundElement
    if not gauge or type(gauge.getPosition)~="function" or type(gauge.getHeight)~="function" then return end
    local label,r,g,b=GPSVehicleEquipment.getStatus(vehicle)
    if label==nil then return end
    local x,y=gauge:getPosition()
    local width=type(gauge.getWidth)=="function" and gauge:getWidth() or 0.10
    local height=gauge:getHeight()
    local dx,dy=0.01,0.008
    if type(getNormalizedScreenValues)=="function" then
        dx,dy=getNormalizedScreenValues(8,7)
    end
    local tx=x+width*0.5
    local ty=math.min(0.985,y+height+dy)
    local size=0.013*(display.uiScale or 1)
    if type(setTextAlignment)=="function" and RenderText and RenderText.ALIGN_CENTER then
        setTextAlignment(RenderText.ALIGN_CENTER)
    end
    if type(setTextColor)=="function" then setTextColor(r,g,b,1) end
    renderText(tx,ty,size,label)
    if type(setTextColor)=="function" then setTextColor(1,1,1,1) end
    if type(setTextAlignment)=="function" and RenderText and RenderText.ALIGN_LEFT then
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end
