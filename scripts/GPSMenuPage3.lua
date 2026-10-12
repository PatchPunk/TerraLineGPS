-- Native, sharp course storage screen; same position and colors as page 1.
GPSMenuPage3={}
local M=GPSMenuPage3
local P={base={.048,.074,.087,.975},header={.065,.099,.113,.99},sidebar={.040,.065,.073,.97},
 panel={.065,.104,.116,.96},panel2={.085,.126,.143,.98},input={.108,.152,.169,.95},
 stroke={.18,.275,.292,.94},dim={.19,.25,.265,.57},white={.945,.965,.950,1},
 muted={.68,.75,.75,1},green={.45,.92,.22,1},greenDim={.19,.40,.12,1},yellow={.99,.78,.13,1}}
local function coords(s,x,t,w,h) return s.pageX+x*s.pageW,s.pageY+(1-t-h)*s.pageH,w*s.pageW,h*s.pageH end
local function rect(s,x,t,w,h,c)
 if type(drawFilledRect)~="function" then return end
 local a,b,d,e=coords(s,x,t,w,h);drawFilledRect(a,b,d,e,c[1],c[2],c[3],c[4])
end
local function rim(s,x,t,w,h,c)
 local dx=(g_pixelSizeX or .0007)*1.35/s.pageW;local dy=(g_pixelSizeY or .0011)*1.35/s.pageH
 rect(s,x,t,w,dy,c);rect(s,x,t+h-dy,w,dy,c);rect(s,x,t,dx,h,c);rect(s,x+w-dx,t,dx,h,c)
end
local function txt(s,x,t,str,size,color,bold,alignment)
 if type(renderText)~="function" then return end
 local px,py=coords(s,x,t,0,0);local c=color or P.white
 if setTextColor then setTextColor(c[1],c[2],c[3],c[4]) end
 if setTextBold then setTextBold(bold==true) end
 if type(setTextAlignment)=="function" and type(RenderText)=="table" then setTextAlignment(alignment=="center" and RenderText.ALIGN_CENTER or alignment=="right" and RenderText.ALIGN_RIGHT or RenderText.ALIGN_LEFT) end
 renderText(px,py,size*s.pageH,tostring(str or ""))
 if type(setTextAlignment)=="function" and type(RenderText)=="table" then setTextAlignment(RenderText.ALIGN_LEFT) end
 if setTextColor then setTextColor(1,1,1,1) end
 if setTextBold then setTextBold(false) end
end
local function btn(s,x,t,w,h,text,action,selected,disabled)
 rect(s,x,t,w,h,selected and P.greenDim or P.input);rim(s,x,t,w,h,selected and P.green or P.dim)
 txt(s,x+w/2,t+h*.71,text,math.min(h*.43,.022),disabled and P.muted or selected and P.green or P.white,true,"center")
 if not disabled then s.nativeHits[#s.nativeHits+1]={x=x,top=t,w=w,h=h,action=action} end
end
local function panel(s,x,t,w,h,title)
 rect(s,x,t,w,h,P.panel);rim(s,x,t,w,h,P.stroke)
 rect(s,x+.010,t+.015,.004,.032,P.green);txt(s,x+.026,t+.045,title,.023,P.white,true)
 rect(s,x+.011,t+.065,w-.022,.0012,P.dim)
end
function M.onOpen(s) s.page3Row=s.page3Row or 1;s.page3Scroll=s.page3Scroll or 0;s.page3Message=GPSCourseManager.lastServerMessage or "A/B-Kurse des aktuellen Hofes speichern";s.page3Edit=nil;GPSCourseManager.ensureLoaded() end
local function notify(s,ok,msg) s.page3Message=msg;GPSLogger.info("TerraLine S3: "..tostring(msg)) end
-- Native ScreenElement raw key events, not a soft/on-screen keyboard.
-- The editor remains visible as a compact modal for confirmation/cancel only.
local function showInput(s,prompt,initial,operation)
    local entry={prompt=prompt,text=tostring(initial or ""),operation=operation,max=48,replaceOnType=true}
    if prompt:find("Winkel") then entry.mode="numeric";entry.max=12 end
    s.page3Edit=entry
    s.page3EditHits={}
    notify(s,true,"Mit PC-Tastatur eingeben, ENTER speichert, ESC bricht ab")
end
local function editButton(s,x,t,w,h,value,action,selected)
    rect(s,x,t,w,h,selected and P.greenDim or P.input)
    rim(s,x,t,w,h,selected and P.green or P.dim)
    txt(s,x+w/2,t+h*.70,value,.022,selected and P.green or P.white,true,"center")
    s.page3EditHits[#s.page3EditHits+1]={x=x,top=t,w=w,h=h,action=action}
end
local function drawEditor(s)
    local edit=s.page3Edit
    if not edit then return end
    -- Standalone editor view: do NOT draw the underlying course rows/buttons.
    -- GIANTS may batch text after filled rectangles, so a dark overlay alone
    -- is not enough to prevent background labels from showing through.
    s.page3EditHits={}
    rect(s,.205,.165,.780,.666,P.panel)
    rim(s,.205,.165,.780,.666,P.stroke)
    rect(s,.222,.200,.005,.057,P.green)
    txt(s,.246,.246,edit.prompt,.034,P.green,true)
    rect(s,.235,.273,.712,.002,P.dim)
    txt(s,.239,.318,"Wert mit der PC-Tastatur eingeben",.024,P.muted)
    txt(s,.239,.385,"EINGABE",.023,P.white,true)
    rect(s,.239,.404,.706,.114,P.input)
    rim(s,.239,.404,.706,.114,P.green)
    local display=edit.text
    local font=math.max(.023,.035-math.max(0,#display-26)*.00055)
    if edit.replaceOnType then display="[ "..display.." ]" else display=display.."|" end
    txt(s,.262,.476,display,font,P.white,true)
    txt(s,.239,.568,"Tippen: Vorauswahl ersetzen  |  Ruecktaste: loeschen",.021,P.muted)
    txt(s,.239,.608,"ENTER: speichern  |  ESC: abbrechen",.023,P.muted)
    rect(s,.239,.642,.706,.002,P.dim)
    editButton(s,.507,.690,.203,.077,"ABBRECHEN","cancel")
    editButton(s,.731,.690,.214,.077,"UEBERNEHMEN","apply",true)
end

local function applyEditor(s)
    local edit=s.page3Edit
    if not edit then return end
    local success,msg=edit.operation(edit.text)
    notify(s,success,msg)
    if success then s.page3Edit=nil;s.page3Selected=1;s.page3Scroll=0 end
end
function M.editClick(s,px,top)
    if not s.page3Edit then return false end
    for i=#(s.page3EditHits or {}),1,-1 do
        local h=s.page3EditHits[i]
        if px>=h.x and px<=h.x+h.w and top>=h.top and top<=h.top+h.h then
            if h.action=="cancel" then s.page3Edit=nil;notify(s,true,"Eingabe abgebrochen")
            elseif h.action=="apply" then applyEditor(s) end
            return true
        end
    end
    return true -- modal input swallows clicks outside the editor
end
local function keyIs(sym,name,alternate)
    return (Input and sym==Input[name]) or sym==alternate
end
local function encodeUtf8(cp)
    if cp>=32 and cp<=126 then return string.char(cp) end
    if cp>=160 and cp<=2047 then
        return string.char(192+math.floor(cp/64),128+cp%64)
    end
    if cp>=2048 and cp<=65535 then
        return string.char(224+math.floor(cp/4096),128+math.floor(cp/64)%64,128+cp%64)
    end
    return nil
end
local function removeLastUtf8(s)
    local n=#s
    if n==0 then return s end
    while n>1 and s:byte(n)>=128 and s:byte(n)<192 do n=n-1 end
    return s:sub(1,n-1)
end
function M.keyEvent(s,unicode,sym,modifier,isDown)
    local edit=s.page3Edit
    if not edit then return false end
    -- Capture all keyboard events while this modal is active so game actions
    -- or menu navigation are not fired during text entry.
    if not isDown then return true end
    if keyIs(sym,"KEY_esc",27) then
        s.page3Edit=nil;notify(s,true,"Eingabe abgebrochen")
        return true
    end
    if keyIs(sym,"KEY_return",13) or keyIs(sym,"KEY_numpadenter",271) then
        applyEditor(s)
        return true
    end
    if keyIs(sym,"KEY_backspace",8) then
        if edit.replaceOnType then edit.text="";edit.replaceOnType=false
        else edit.text=removeLastUtf8(edit.text) end
        return true
    end
    local cp=type(unicode)=="number" and unicode or nil
    local ch=cp and encodeUtf8(cp) or nil
    if ch then
        if edit.mode=="numeric" then
            if ch=="," then ch="." end
            if not ch:match("^[%d%.%-]$") then return true end
        elseif ch=="<" or ch==">" or ch=='"' then
            return true -- keep XML name values simple
        end
        if edit.replaceOnType then edit.text="";edit.replaceOnType=false end
        if #edit.text+#ch <= edit.max then edit.text=edit.text..ch end
    end
    return true
end
function M.draw(s)
 s.nativeHits={}
 rect(s,0,0,1,1,P.base);rim(s,0,0,1,1,P.stroke)
 rect(s,0,0,1,.128,P.header);rect(s,0,.128,1,.002,P.dim)
 rect(s,.024,.033,.038,.055,P.greenDim);if GPSMenuSymbols then GPSMenuSymbols.header(s,.044,.029) end
 txt(s,.079,.065,"TERRALINE GPS",.045,P.white,true)
 txt(s,.408,.065,"v0.9.9.46",.022,P.green)
 txt(s,.080,.106,"KURSVERWALTUNG (ohne Feldzuordnung)",.020,P.muted)
 btn(s,.932,.032,.046,.065,"X","close")
 rect(s,.012,.145,.177,.691,P.sidebar)
 local nav={{id=1,name="Spurfuehrung"},{id=3,name="Speicher"},{id=4,name="Info & Version"}}
 for slot,item in ipairs(nav) do
    local y=.164+(slot-1)*.124
    local active=item.id==3
    rect(s,.020,y,.162,.110,active and P.greenDim or P.input)
    rim(s,.020,y,.162,.110,active and P.green or P.dim)
    if GPSMenuSymbols then GPSMenuSymbols.draw(s,item.id,.049,y+.026,active and P.green or P.muted) end
    txt(s,.073,y+.068,item.name,.022,P.white,active)
    s.nativeHits[#s.nativeHits+1]={x=.02,top=y,w=.162,h=.11,action="page"..item.id}
 end
 -- While editing, render ONLY the editor page.  Drawing underlying course
 -- captions first would cause them to overlap the modal in GIANTS' text pass.
 if s.page3Edit then drawEditor(s);return end
 local x=.200
 panel(s,x,.150,.385,.262,"AKTUELLER KURS")
 txt(s,x+.020,.257,"Gespeicherte Kurse",.023,P.white)
 txt(s,x+.353,.257,tostring(#GPSCourseManager.listAll()),.028,P.green,true,"right")
 rect(s,x+.010,.285,.362,.001,P.dim)
 txt(s,x+.020,.328,"Aktuelle A/B-Referenz",.022,P.white)
 local courseName=GPSCourseManager.getActiveName() or
     (GPSABLineManager.b and "A/B-Linie (ungespeichert)" or "Noch keine A/B-Linie")
 if #courseName>35 then courseName=courseName:sub(1,32).."..." end
 txt(s,x+.020,.382,courseName,.024,P.green,true)
 panel(s,x,.426,.385,.410,"SPURRICHTUNG")
 local angle=GPSCourseManager.getAngle()
 txt(s,x+.020,.545,"GPS Winkel / Fahrtrichtung",.022,P.white)
 txt(s,x+.322,.550,angle and string.format("%.2f Grad",angle) or "A/B fehlt",.026,angle and P.green or P.yellow,true,"right")
 btn(s,x+.020,.575,.168,.065,"WINKEL EINGEBEN","setAngle")
 btn(s,x+.202,.575,.176,.065,"+90 GRAD","rotate90",false,angle==nil)
 rect(s,x+.012,.660,.360,.001,P.dim)
 txt(s,x+.019,.706,"0 = Nord   |   90 = Ost",.020,P.muted)
 txt(s,x+.019,.757,"180 = Sued   |   270 = West",.020,P.muted)
 txt(s,x+.019,.805,"Drehpunkt: A. GPS wird deaktiviert.",.019,P.yellow)
 local rx,rw=.594,.393
 panel(s,rx,.150,rw,.686,"GESPEICHERTE KURSE")
 local list=GPSCourseManager.listAll()
 s.page3Selected=s.page3Selected or 1
 local rowCount=5
 s.page3Scroll=math.max(0,math.min(s.page3Scroll or 0,math.max(0,#list-rowCount)))
 for i=1,rowCount do
    local idx=i+s.page3Scroll
    local c=list[idx]
    local y=.235+(i-1)*.094
    if c then
      local selected=s.page3Selected==idx
      rect(s,rx+.018,y,rw-.036,.081,selected and P.greenDim or P.input)
      rim(s,rx+.018,y,rw-.036,.081,selected and P.green or P.dim)
      txt(s,rx+.030,y+.043,c.name:sub(1,25),.022,selected and P.green or P.white,true)
      local da=(math.deg(math.atan2(c.bx-c.ax,c.bz-c.az))+360)%360
      txt(s,rx+rw-.031,y+.073,string.format("%.1f Grad | %.2f m",da,c.width or 0),.017,P.muted,false,"right")
      s.nativeHits[#s.nativeHits+1]={x=rx+.018,top=y,w=rw-.036,h=.081,action="select"..idx}
    end
 end
 if #list==0 then txt(s,rx+.030,.330,"Keine gespeicherten Kurse",.026,P.muted) end
 btn(s,rx+.018,.719,.085,.046,"<","scrollPrev",false,s.page3Scroll==0)
 txt(s,rx+.193,.755,string.format("%d / %d",#list==0 and 0 or math.min(s.page3Selected,#list),#list),.022,P.muted,false,"center")
 btn(s,rx+rw-.103,.719,.085,.046,">","scrollNext",false,s.page3Scroll+rowCount>=#list)
 btn(s,rx+.018,.782,.111,.045,"SPEICHERN","save")
 btn(s,rx+.141,.782,.108,.045,"LADEN","load",false,#list==0)
 btn(s,rx+.261,.782,.114,.045,"LOESCHEN","delete",false,#list==0)
 rect(s,.013,.849,.974,.059,P.panel2)
 txt(s,.027,.887,s.page3Message or "A/B-Kurse frei speichern und laden",.021,P.muted)
 txt(s,.030,.958,"[ESC] Zurueck",.024,P.white,true)
 btn(s,.839,.925,.137,.050,"OK / SCHLIESSEN","close",true)
end
function M.onMouseClick(s,px,top)
 if s.page3Edit then return M.editClick(s,px,top) end
 for i=#(s.nativeHits or {}),1,-1 do
    local hit=s.nativeHits[i]
    if px>=hit.x and px<=hit.x+hit.w and top>=hit.top and top<=hit.top+hit.h then
        local a=hit.action
        local list=GPSCourseManager.listAll()
        local selected=list[s.page3Selected or 1]
        if a=="close" then s:onClickBack()
        elseif a:sub(1,4)=="page" then s.page=tonumber(a:sub(5)) or 1
        elseif a:sub(1,6)=="select" then s.page3Selected=tonumber(a:sub(7));s.page3PendingDelete=nil
        elseif a=="scrollPrev" then s.page3Scroll=math.max(0,s.page3Scroll-1)
        elseif a=="scrollNext" then s.page3Scroll=s.page3Scroll+1
        elseif a=="save" then
            showInput(s,"Kursnamen eingeben","",GPSCourseManager.saveCurrent)
        elseif a=="load" and selected then notify(s,GPSCourseManager.loadCourse(selected))
        elseif a=="delete" and selected then
            if s.page3PendingDelete~=selected.id then
                s.page3PendingDelete=selected.id
                notify(s,false,"Zur Sicherheit erneut LOESCHEN klicken: "..selected.name)
            else
                notify(s,GPSCourseManager.deleteCourse(selected))
                s.page3PendingDelete=nil
                s.page3Selected=math.max(1,math.min(s.page3Selected,#list-1))
            end
        elseif a=="setAngle" then
            showInput(s,"Winkel in Grad (0-359.99)",string.format("%.2f",GPSCourseManager.getAngle() or 0),GPSCourseManager.setAngle)
        elseif a=="rotate90" then notify(s,GPSCourseManager.rotate90()) end
        return true
    end
 end
 return true
end
