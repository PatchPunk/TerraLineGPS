-- GPS Field Test 0.9.9.13: reference-locked driver-side buttons and independent mirror action.
-- All captions, panels, buttons and diagrams are drawn natively. No full-page
-- bitmap is used. Functions only touch the same public APIs used by commands.
-- Coordinates are fractions of the current centred GUI area (top-left origin).
GPSMenuPage1 = {}

local P = {
    base={0.048,0.074,0.087,0.975},
    header={0.065,0.099,0.113,0.99},
    sidebar={0.040,0.065,0.073,0.97},
    panel={0.065,0.104,0.116,0.96},
    panel2={0.085,0.126,0.143,0.98},
    input={0.108,0.152,0.169,0.95},
    row={0.055,0.090,0.101,0.60},
    stroke={0.18,0.275,0.292,0.94},
    strokeDim={0.19,0.25,0.265,0.57},
    white={0.945,0.965,0.950,1},
    muted={0.68,0.75,0.75,1},
    green={0.45,0.92,0.22,1},
    greenDim={0.19,0.40,0.12,1},
    yellow={0.99,0.78,0.13,1},
    red={0.94,0.29,0.23,1},
    black={0.03,0.05,0.055,1}
}
local function L(screen,x,top,w,h)
    return screen.pageX+x*screen.pageW,
           screen.pageY+(1-top-h)*screen.pageH,
           w*screen.pageW,h*screen.pageH
end
local function rect(screen,x,top,w,h,c)
    if type(drawFilledRect)~="function" then return end
    local px,py,pw,ph=L(screen,x,top,w,h)
    drawFilledRect(px,py,pw,ph,c[1],c[2],c[3],c[4])
end
local function rim(screen,x,top,w,h,col)
    local dx=(g_pixelSizeX or 0.0007)*1.35/screen.pageW
    local dy=(g_pixelSizeY or 0.0011)*1.35/screen.pageH
    rect(screen,x,top,w,dy,col)
    rect(screen,x,top+h-dy,w,dy,col)
    rect(screen,x,top,dx,h,col)
    rect(screen,x+w-dx,top,dx,h,col)
end
local function rounded(screen,x,top,w,h,c)
    if type(drawFilledRectRound)=="function" then
        local px,py,pw,ph=L(screen,x,top,w,h)
        drawFilledRectRound(px,py,pw,ph,0.075,c[1],c[2],c[3],c[4])
    else
        rect(screen,x,top,w,h,c)
    end
end
local function label(screen,x,top,t,size,col,bold,alignment)
    if type(renderText)~="function" then return end
    local px,py=L(screen,x,top,0,0)
    local actual=size*screen.pageH
    if type(setTextColor)=="function" then setTextColor((col or P.white)[1],(col or P.white)[2],(col or P.white)[3],(col or P.white)[4]) end
    if type(setTextBold)=="function" then setTextBold(bold==true) end
    if type(setTextAlignment)=="function" and type(RenderText)=="table" then
        setTextAlignment(alignment=="center" and RenderText.ALIGN_CENTER or alignment=="right" and RenderText.ALIGN_RIGHT or RenderText.ALIGN_LEFT)
    end
    renderText(px,py,actual,tostring(t or ""))
    if type(setTextAlignment)=="function" and type(RenderText)=="table" then setTextAlignment(RenderText.ALIGN_LEFT) end
    if type(setTextBold)=="function" then setTextBold(false) end
    if type(setTextColor)=="function" then setTextColor(1,1,1,1) end
end
local function touch(screen,x,top,w,h,action,disabled)
    if not disabled and action then
        screen.nativeHits[#screen.nativeHits+1]={x=x,top=top,w=w,h=h,action=action}
    end
end
local function button(screen,x,top,w,h,title,action,accent,disabled)
    local fill=accent and P.greenDim or P.input
    if disabled then fill=P.row end
    rounded(screen,x,top,w,h,fill)
    rim(screen,x,top,w,h,accent and P.green or P.strokeDim)
    label(screen,x+w/2,top+h*0.70,title,math.min(h*0.48,0.021),disabled and P.muted or (accent and P.green or P.white),true,"center")
    touch(screen,x,top,w,h,action,disabled)
end
local function panel(screen,x,top,w,h,heading)
    rounded(screen,x,top,w,h,P.panel)
    rim(screen,x,top,w,h,P.stroke)
    rect(screen,x+0.011,top+0.015,0.004,0.032,P.green)
    label(screen,x+0.025,top+0.044,heading,0.023,P.white,true)
    rect(screen,x+0.012,top+0.066,w-0.024,0.0013,P.strokeDim)
end
local function statLine(screen,x,top,w,title,value,rowH)
    rect(screen,x+0.009,top,w-0.018,rowH,P.row)
    label(screen,x+0.018,top+rowH*.69,title,0.0215,P.white,false)
    label(screen,x+w-0.020,top+rowH*.69,value,0.0225,P.green,true,"right")
end
-- Approved blueprint-style line drawings of tractor and implement are
-- small transparent BC3/DXT5 sprites. All headings, values, boundaries
-- and guidance geometry remain native LS text and primitives.
local function drawTractorFallback(screen,cx,top,w,h)
    local x=cx-w*0.5
    rect(screen,x+w*.13,top+h*.12,w*.18,h*.32,P.black)
    rect(screen,x+w*.69,top+h*.12,w*.18,h*.32,P.black)
    rect(screen,x+w*.09,top+h*.57,w*.22,h*.33,P.black)
    rect(screen,x+w*.69,top+h*.57,w*.22,h*.33,P.black)
    rounded(screen,x+w*.29,top+h*.12,w*.42,h*.76,P.greenDim)
    rim(screen,x+w*.29,top+h*.12,w*.42,h*.76,P.stroke)
end
-- Overlays use normalized coordinates, but the monitor is widescreen.
-- Convert sprite height into a width with the SAME NUMBER OF PIXELS, not
-- the same number of normalized screen units (which squashed the tractors).
local function squareSpriteWidth(screen,height)
    local aspect=9/16  -- 16:9 fallback for UI before graphics globals exist
    if type(g_pixelSizeX)=="number" and type(g_pixelSizeY)=="number" and
       g_pixelSizeX>0 and g_pixelSizeY>0 then
        aspect=g_pixelSizeX/g_pixelSizeY
    elseif type(g_screenWidth)=="number" and type(g_screenHeight)=="number" and
           g_screenWidth>0 and g_screenHeight>0 then
        aspect=g_screenHeight/g_screenWidth
    end
    return height*screen.pageH/screen.pageW*aspect
end
local function sprite(screen,key,file,x,top,w,h)
    if type(Overlay)~="table" or type(Overlay.new)~="function" then return false end
    screen.gpsPage1Sprites=screen.gpsPage1Sprites or {}
    local px,py,pw,ph=L(screen,x,top,w,h)
    local data=screen.gpsPage1Sprites[key]
    -- Work-width graphic may be resized; rebuild *only after a width change*,
    -- never on every frame. Other sprites are permanent until onClose().
    if data and (math.abs(data.w-w)>0.0001 or math.abs(data.x-x)>0.0001 or
                 math.abs(data.top-top)>0.0001 or math.abs(data.h-h)>0.0001) then
        if data.overlay and type(data.overlay.delete)=="function" then
            pcall(data.overlay.delete,data.overlay)
        end
        screen.gpsPage1Sprites[key]=nil
        data=nil
    end
    if not data then
        local dir=GPSMenu and GPSMenu.modDir or g_currentModDirectory
        if not dir then return false end
        local ok,img=pcall(Overlay.new,dir.."gui/"..file,px,py,pw,ph)
        if not ok or not img then return false end
        data={overlay=img,x=x,top=top,w=w,h=h}
        screen.gpsPage1Sprites[key]=data
    end
    local overlay=data.overlay
    if overlay and overlay.overlayId and overlay.overlayId~=0 then
        overlay:render()
        return true
    end
    return false
end
function GPSMenuPage1.onClose(screen)
    for _,data in pairs(screen.gpsPage1Sprites or {}) do
        if data.overlay and type(data.overlay.delete)=="function" then
            pcall(data.overlay.delete,data.overlay)
        end
    end
    screen.gpsPage1Sprites=nil
end
local function dashLine(screen,x,top,w,h,color,count)
    for i=0,(count or 7)-1 do
        rect(screen,x,top+(i+.1)*h/(count or 7),w,h/(count or 7)*0.58,color)
    end
end
local function renderWorkPreview(screen)
    local x,t,w,h=0.594,0.150,0.393,0.294
    panel(screen,x,t,w,h,"VORSCHAU - ARBEITSBREITE")
    rect(screen,x+.018,t+.082,w-.036,h-.112,P.panel2)
    local cx=x+w*.51
    local ww=GPSMenuPage1.getWidth(screen)
    local half=math.max(.073,math.min(.160,.088+ww*.0024))
    -- subtle worked-soil structure gives a sense of movement without a
    -- photo or a large background texture.
    for i=0,13 do
        rect(screen,x+.025+i*.025,t+.093,.004,.145,P.row)
    end
    dashLine(screen,cx-half,t+.108,.002,.126,P.yellow,5)
    dashLine(screen,cx+half,t+.108,.002,.126,P.yellow,5)
    local sHeight=.158
    local sWidth=squareSpriteWidth(screen,sHeight)
    if not sprite(screen,"widthTractor","tractorTop.dds",cx-sWidth*.5,t+.082,sWidth,sHeight) then
        drawTractorFallback(screen,cx,t+.095,.087,.125)
    end
    -- The implement scales when the selected working width changes.
    if not sprite(screen,"widthPlanter","planterTop.dds",cx-half*.90,t+.198,half*1.80,.040) then
        rounded(screen,cx-half*.9,t+.215,half*1.80,.016,P.greenDim)
    end
    rect(screen,cx-half,t+.245,2*half,.0026,P.green)
    rect(screen,cx-half,t+.237,.002,.019,P.green)
    rect(screen,cx+half-.002,t+.237,.002,.019,P.green)
    label(screen,cx,t+.277,string.format("%.2f m",ww),.037,P.green,true,"center")
    label(screen,x+.025,t+h-.012,"GERAETEBREITE (DYNAMISCH)",.013,P.muted,false)
end
-- Stored AB shifts use ABLineManager's signed geometric normal. The LS25
-- field-view direction is opposite to the originally assumed sign. UI +/-
-- and the displayed signed value therefore invert that stored sign, while
-- still accounting for whether the driver faces A->B or B->A.
-- This does NOT change the underlying keyboard shift actions.
function GPSMenuPage1.getDriverDirectionSign()
    local a,b=GPSABLineManager.a,GPSABLineManager.b
    if not a or not b then return 1 end
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    local node=vehicle and GPSVehicleDetector.getPositionNode(vehicle)
    if not node or type(localDirectionToWorld)~="function" then return 1 end
    local fx,_,fz=localDirectionToWorld(node,0,0,1)
    if type(fx)~="number" or type(fz)~="number" then return 1 end
    local dot=fx*(b.x-a.x)+fz*(b.z-a.z)
    return dot<0 and -1 or 1
end
function GPSMenuPage1.getDriverRelativeOffset()
    return -(GPSABLineManager.offsetMeters or 0)*GPSMenuPage1.getDriverDirectionSign()
end
local function renderGuidePreview(screen)
    local x,t,w,h=0.594,0.456,0.393,0.380
    panel(screen,x,t,w,h,"VORSCHAU - SPURFUEHRUNG")
    rect(screen,x+.018,t+.081,w-.036,h-.101,P.panel2)
    local cx=x+w*.51
    -- Worked ground / stubble: low-cost native drawing, no large textures.
    for i=0,11 do rect(screen,x+.028+i*.029,t+.087,.006,h*.70,P.row) end
    local width=GPSMenuPage1.getWidth(screen)
    local half=math.max(.075,math.min(.138,.088+width*.0021))
    local offset=GPSMenuPage1.getDriverRelativeOffset()
    -- A/B shift translates the course, not the actual tractor. This motion
    -- deliberately has an enlarged visual scale so 10 cm is recognizable.
    local dx=math.max(-.057,math.min(.057,offset*.045))
    local guideX=cx+dx
    local valid=GPSABLineManager.a~=nil and GPSABLineManager.b~=nil
    local active=GPSSteeringController and GPSSteeringController.enabled
    local guideColor=valid and (active and P.green or P.red) or P.strokeDim
    -- The yellow working borders and the centerline move as ONE course.
    dashLine(screen,guideX-half,t+.093,.002,h*.62,P.yellow,7)
    dashLine(screen,guideX+half,t+.093,.002,h*.62,P.yellow,7)
    local sHeight=.185
    local sWidth=squareSpriteWidth(screen,sHeight)
    if not sprite(screen,"guideTractor","tractorTop.dds",cx-sWidth*.5,t+.101,sWidth,sHeight) then
        drawTractorFallback(screen,cx,t+.119,.074,.145)
    end
    local planHalf=math.max(.066,math.min(.138,half*.90))
    if not sprite(screen,"guidePlanter","planterTop.dds",cx-planHalf,t+.263,planHalf*2,.040) then
        rounded(screen,cx-planHalf,t+.277,planHalf*2,.014,P.greenDim)
    end
    -- Course is drawn over the sprite so its position remains unambiguous.
    rect(screen,guideX-.0010,t+.091,.0020,h*.654,guideColor)
    if valid and math.abs(dx)>.001 then
        rect(screen,math.min(cx,guideX),t+.302,math.abs(dx),.003,P.green)
        rect(screen,cx-.001,t+.293,.002,.020,P.muted)
        rect(screen,guideX-.001,t+.293,.002,.020,P.green)
    end
    label(screen,x+.030,t+h-.058,"SPURMITTE",.016,P.muted)
    rect(screen,x+.154,t+h-.072,.028,.002,P.green)
    label(screen,x+.191,t+h-.058,"ARBEITSKANTE",.016,P.muted)
    rect(screen,x+.319,t+h-.072,.025,.002,P.yellow)
    label(screen,x+.030,t+h-.019,
        valid and ("Gesamte GPS-Spur "..string.format("%+.2f m",offset))
              or "A und B zuerst setzen",.020,valid and P.green or P.yellow,true)
end
local function fmtTrack()
    if not (GPSTrackPosition and GPSTrackPosition.valid) or type(GPSTrackPosition.track)~="number" then return "-" end
    local t=GPSTrackPosition.track
    return tostring(t>=0 and t+1 or t-1)
end
function GPSMenuPage1.getWidth(screen)
    if screen and type(screen.nativeWidth)=="number" then return screen.nativeWidth end
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    local w=GPSImplementDetector and GPSImplementDetector.getWidth(vehicle) or 3
    return type(w)=="number" and w or 3
end
local function deviceName()
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    if GPSImplementDetector and type(GPSImplementDetector.getData)=="function" then
        local _,_,name=GPSImplementDetector.getData(vehicle)
        return name or "Kein Arbeitsgeraet"
    end
    return "Kein Arbeitsgeraet"
end
function GPSMenuPage1.onOpen(screen)
    screen.page1VisualSettings=false
    if GPSDisplaySettings then GPSDisplaySettings.ensureLoaded() end
    screen.widthStepIndex=screen.widthStepIndex or 1
    screen.shiftStepIndex=screen.shiftStepIndex or 1
    screen.nativeMessage= (GPSABLineManager.a and GPSABLineManager.b)
        and "Werte werden direkt uebernommen."
        or "Versatz: Zuerst A und B im Feld setzen (Alt+B zweimal)."
    screen.nativeWidth=GPSMenuPage1.getWidth()
    screen.nativeDeviceName=deviceName()
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    if GPSImplementDetector.override==nil and GPSImplementDetector.getData and
       select(4,GPSImplementDetector.getData(vehicle))==false then
        screen.nativeMessage="Arbeitsbreite nicht erkannt - Standardwert; bitte pruefen."
    end
end
function GPSMenuPage1.draw(screen)
    screen.nativeHits={}
    rounded(screen,0,0,1,1,P.base)
    rim(screen,0,0,1,1,P.stroke)
    rect(screen,0,.0,1,.128,P.header)
    rect(screen,0,.128,1,.0018,P.strokeDim)
    -- GPS mark
    rounded(screen,.024,.033,.038,.055,P.greenDim)
    if GPSMenuSymbols then GPSMenuSymbols.header(screen,.044,.029) end
    label(screen,.079,.065,"TERRALINE GPS",.045,P.white,true)
    label(screen,.409,.065,"v0.9.9.46",.022,P.green,false)
    local src=GPSImplementDetector and GPSImplementDetector.override and "Manuell" or "Auto"
    local name=screen.nativeDeviceName or "Kein Arbeitsgeraet"
    if #name>26 then name=name:sub(1,23).."..." end
    label(screen,.080,.106,"Kurs: "..(GPSCourseManager and GPSCourseManager.getActiveName() or "A/B-Linie").."    |    "..name.." ("..src..")",.019,P.muted)
    button(screen,.932,.032,.046,.065,"X","close",false,false)
    -- Left navigation
    rounded(screen,.012,.145,.177,.691,P.sidebar)
    local nav={ {id=1,name="Spurfuehrung"}, {id=3,name="Speicher"}, {id=4,name="Info & Version"} }
    for slot,item in ipairs(nav) do
        local top=.164+(slot-1)*.124
        rounded(screen,.020,top,.162,.110,slot==1 and P.greenDim or P.input)
        rim(screen,.020,top,.162,.110,slot==1 and P.green or P.strokeDim)
        if GPSMenuSymbols then
            GPSMenuSymbols.draw(screen,item.id,.049,top+.026,slot==1 and P.green or P.muted)
        end
        label(screen,.073,top+.068,item.name,.022,P.white,slot==1)
        touch(screen,.020,top,.162,.110,"page"..item.id)
    end
    -- Always-available master switch in the unused sidebar area; this also
    -- remains available in the visual-settings subview when GPS is OFF.
    local powered=GPSFieldTest and GPSFieldTest.masterEnabled~=false
    label(screen,.030,.591,"TERRALINE GPS",.020,P.white,true)
    button(screen,.020,.613,.162,.073,powered and "SYSTEM AN" or "SYSTEM AUS","masterToggle",powered)
    label(screen,.038,.730,"Alt+T: ein / aus",.018,P.muted)
    -- Full-width subview: visual settings need room; never stack controls on
    -- top of the densely populated work-width / offset panels.
    if screen.page1VisualSettings then
        local x=.200
        panel(screen,x,.150,.787,.686,"LINIEN-OPTIK")
        label(screen,.232,.246,"ANZAHL DER GPS-LINIEN",.026,P.white,true)
        local count=(GPSConfig and GPSConfig.lineStrokes) or 1
        for i=1,3 do
            local bx=.228+(i-1)*.246
            local name=i==1 and "1 LINIE" or (i==2 and "2 LINIEN" or "3 LINIEN")
            button(screen,bx,.303,.232,.068,name,"visualStrokes"..i,count==i)
            if i==1 then label(screen,bx+.116,.401,"STANDARD",.018,P.green,true,"center") end
            -- The preview retains the centered arrangement used by the renderer.
            local cx=bx+.116
            for j=1,i do
                local offset=(j-(i+1)*0.5)*.025
                rect(screen,cx+offset-.0015,.428,.003,.095,P.green)
            end
            label(screen,cx,.560,i==1 and "Schmal" or (i==2 and "Mittel" or "Deutlich"),.018,P.muted,false,"center")
        end
        rect(screen,.222,.587,.738,.0016,P.strokeDim)
        label(screen,.232,.631,"SICHTBARKEIT BEI AKTIVER LENKUNG",.026,P.white,true)
        local seconds=(GPSConfig and GPSConfig.lineDurationSeconds) or 0
        local times={{0,"IMMER"},{2,"2 SEK"},{5,"5 SEK"},{10,"10 SEK"}}
        for i,entry in ipairs(times) do
            local bx=.228+(i-1)*.184
            button(screen,bx,.662,.174,.065,entry[2],"visualDuration"..entry[1],seconds==entry[1])
        end
        label(screen,.233,.784,"Bei GPS EIN kurz sichtbar; Lenkung laeuft weiter.",.019,P.muted)
        rounded(screen,.013,.848,.974,.061,P.panel2)
        label(screen,.027,.888,screen.nativeMessage or "Linienanzahl anpassen.",.020,P.muted)
        label(screen,.030,.958,"[ESC] Zurueck",.024,P.white,true)
        button(screen,.671,.925,.154,.050,"STANDARD","visualDefaults")
        button(screen,.839,.925,.137,.050,"ZURUECK","visualBack",true)
        return
    end
    -- Center-left panels
    local x,w=.200,.385
    panel(screen,x,.150,w,.236,"ARBEITSBREITE")
    label(screen,x+.017,.245,"Arbeitsbreite",.022,P.white)
    button(screen,x+.217,.219,.040,.046,"-","widthMinus")
    label(screen,x+.301,.244,string.format("%.2f m",GPSMenuPage1.getWidth(screen)),.026,P.white,true,"center")
    button(screen,x+.344,.219,.036,.046,"+","widthPlus")
    rect(screen,x+.010,.268,w-.020,.0012,P.strokeDim)
    label(screen,x+.017,.308,"Auto-Arbeitsbreite",.022,P.white)
    local isAuto=GPSImplementDetector.override==nil
    button(screen,x+.247,.277,.117,.048,isAuto and "AN" or "AUS","widthAuto",isAuto)
    rect(screen,x+.010,.337,w-.020,.0012,P.strokeDim)
    label(screen,x+.017,.372,"Breiten-Schritt",.021,P.white)
    local steps={0.01,0.05,0.10,0.50}
    label(screen,x+.292,.372,string.format("%.2f m",steps[screen.widthStepIndex]),.022,P.green,true,"center")
    button(screen,x+.346,.343,.034,.041,">","widthStep")

    panel(screen,x,.400,w,.240,"SPURVERSATZ")
    local mirrorOn=GPSAutoMirror and GPSAutoMirror.enabled==true
    button(screen,x+.258,.409,.120,.038,mirrorOn and "AUTO-WENDE AN" or "AUTO-WENDE AUS","toggleAutoMirror",mirrorOn)
    label(screen,x+.017,.494,"GPS-Spurversatz",.021,P.white)
    local abValid=GPSABLineManager.a~=nil and GPSABLineManager.b~=nil
    button(screen,x+.217,.471,.040,.046,"-","shiftMinus")
    label(screen,x+.297,.492,abValid and string.format("%+.2f m",GPSMenuPage1.getDriverRelativeOffset()) or "A/B fehlt",.024,abValid and P.white or P.yellow,true,"center")
    button(screen,x+.344,.471,.036,.046,"+","shiftPlus")
    rect(screen,x+.010,.522,w-.020,.0012,P.strokeDim)
    label(screen,x+.017,.561,"Versatz-Schrittweite",.021,P.white)
    label(screen,x+.292,.561,string.format("%.2f m",steps[screen.shiftStepIndex]),.022,P.green,true,"center")
    button(screen,x+.346,.534,.034,.041,">","shiftStep")
    rect(screen,x+.010,.585,w-.020,.0012,P.strokeDim)
    label(screen,x+.017,.620,"A/B-Aktionen",.021,P.white)
    button(screen,x+.168,.595,.102,.037,"A/B TAUSCH","reverseAB",false,not abValid)
    button(screen,x+.276,.595,.104,.037,"SPIEGELN","mirrorOffset",false,not abValid)

    panel(screen,x,.652,w,.184,"AKTUELLE SPUR")
    local deviceAutoOn=GPSDeviceOffsetAuto and GPSDeviceOffsetAuto.enabled==true
    button(screen,x+.240,.656,.137,.043,deviceAutoOn and "GERAET: AUTO AN" or "GERAET: AUTO AUS","toggleDeviceAuto",deviceAutoOn)
    local courseAngle=GPSCourseManager and GPSCourseManager.getAngle()
    if courseAngle then
        label(screen,x+.018,.713,string.format("Kurs %.1f Grad",courseAngle),.0175,P.muted)
    end
    label(screen,x+.018,.755,"Spurnummer",.022,P.white)
    label(screen,x+.339,.755,fmtTrack(),.037,P.green,true,"right")
    rect(screen,x+.010,.770,w-.020,.0012,P.strokeDim)
    label(screen,x+.018,.817,"GPS Status",.023,P.white)
    local active=GPSSteeringController and GPSSteeringController.enabled
    label(screen,x+.354,.819,active and "AKTIV" or "INAKTIV",.026,active and P.green or P.muted,true,"right")

    renderWorkPreview(screen)
    renderGuidePreview(screen)
    rounded(screen,.013,.848,.974,.061,P.panel2)
    local probe=GPSDeviceOffsetProbe
    local autoDevice=GPSDeviceOffsetAuto
    local hint=(probe and type(probe.lastValue)=="number") and
        string.format("Geraete-Mitte %+.2f m (Traktorsicht) | %s",probe.lastValue,
            autoDevice and autoDevice.enabled and (autoDevice.lastStatus or "Automatik AN") or "Automatik AUS")
        or "Geraete-Mitte noch nicht erkannt (Diagnose: gsGPSDeviceOffset)"
    label(screen,.027,.886,screen.nativeMessage or hint,.020,P.muted)
    label(screen,.030,.958,"[ESC] Zurueck",.024,P.white,true)
    touch(screen,.018,.921,.18,.070,"close")
    button(screen,.455,.925,.200,.050,"LINIEN-OPTIK","visualOpen")
    button(screen,.671,.925,.154,.050,"STANDARD SCHRITTE","resetSteps")
    button(screen,.839,.925,.137,.050,"OK / SCHLIESSEN","close",true)
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
    -- LS25's actual field-view movement is opposite the old menu sign.
    local physicalSign=-sign*direction
    -- There is no work-width limit: shifting means moving the FULL guide
    -- corridor, not nudging a target within an unshifted corridor.
    local ok,msg=GPSABLineManager.shift(physicalSign,amount)
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
                screen.nativeMessage="Linien-Optik: Breite und Anzeigezeit einstellen"
            elseif a=="visualBack" then
                screen.page1VisualSettings=false
                screen.nativeMessage="Linien-Optik uebernommen"
            elseif a=="visualDefaults" or a:match("^visualStrokes[123]$") then
                if GPSDisplaySettings then
                    local count=a=="visualDefaults" and 1 or tonumber(a:sub(-1))
                    local ok,msg
                    if a=="visualDefaults" then
                        ok,msg=GPSDisplaySettings.restoreDefaults()
                    else
                        ok,msg=GPSDisplaySettings.setStrokes(count)
                    end
                    info(screen,string.format("GPS-Linien: %d %s | Anzeige: %s - %s",
                        GPSConfig.lineStrokes,GPSConfig.lineStrokes==1 and "Linie" or "Linien",
                        GPSConfig.lineDurationSeconds==0 and "IMMER" or (tostring(GPSConfig.lineDurationSeconds).." Sek"),
                        ok and "gespeichert" or msg))
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
