-- TerraLine GPS menu page 3 (Speicher) - UI refresh.
-- Course storage screen: same operations as before, new look (GPSMenuTheme).
GPSMenuPage3={}
local M=GPSMenuPage3
local T=GPSMenuTheme
local C=T.C
local rect=T.rect
local txt=T.text

function M.onOpen(s) s.page3Row=s.page3Row or 1;s.page3Scroll=s.page3Scroll or 0;
    s.page3Message=GPSCourseManager.lastServerMessage or "A/B-Kurse des aktuellen Hofes speichern";s.page3Edit=nil;
    GPSCourseManager.ensureLoaded() end
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

local function drawEditor(s)
    local edit=s.page3Edit
    if not edit then return end
    local dx,dy=T.px(s)
    -- Standalone editor view: do NOT draw the underlying course rows/buttons.
    -- GIANTS may batch text after filled rectangles, so a dark overlay alone
    -- is not enough to prevent background labels from showing through.
    T.box(s,.205,.165,.780,.666,C.surface,C.line,12)
    T.round(s,.225,.200,5*dx,.056,C.accent,2)
    txt(s,.246,.246,edit.prompt,.034,C.accent,true,"left",.70)
    T.hline(s,.225,.276,.740,C.lineSoft)
    txt(s,.239,.322,"Wert mit der PC-Tastatur eingeben",.023,C.textDim)
    txt(s,.239,.388,"EINGABE",.0185,C.textMute,true)
    T.box(s,.239,.402,.706,.114,C.well,C.accent,10)
    local display=edit.text
    local size=math.max(.024,.036-math.max(0,#display-26)*.00055)
    local baseline=T.mid(.402,.114,size)
    if edit.replaceOnType then
        -- pre-selected value: highlighted, typing replaces it
        local tw=T.textWidth(s,display,size,true)
        T.round(s,.255,.402+.020,tw+.016,.074,C.accentDim,6)
        txt(s,.263,baseline,display,size,C.text,true,"left",.66)
    else
        local caretOn=(math.floor((g_time or 0)/500)%2)==0
        txt(s,.263,baseline,display,size,C.text,true,"left",.66)
        if caretOn then
            local tw=math.min(T.textWidth(s,display,size,true),.66)
            rect(s,.263+tw+.004,.402+.024,2*dx,.066,C.accent)
        end
    end
    -- key hints
    txt(s,.239,.575,"Tippen ersetzt die Vorauswahl, Ruecktaste loescht.",.0205,C.textMute)
    local x=.239
    x=x+T.keycap(s,x,.610,"ENTER",.0175)+.010
    txt(s,x,T.mid(.610,21*dy,.0205),"speichern",.0205,C.textDim)
    x=x+T.textWidth(s,"speichern",.0205,false)+.030
    x=x+T.keycap(s,x,.610,"ESC",.0175)+.010
    txt(s,x,T.mid(.610,21*dy,.0205),"abbrechen",.0205,C.textDim)
    T.hline(s,.225,.665,.740,C.lineSoft)
    s.nativeHits={}
    T.button(s,.507,.690,.203,.077,"ABBRECHEN","cancel",{size=.022})
    T.button(s,.731,.690,.214,.077,"UEBERNEHMEN","apply",{primary=true,size=.022})
    s.page3EditHits={}
    for _,h in ipairs(s.nativeHits) do s.page3EditHits[#s.page3EditHits+1]=h end
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
    local dx,dy=T.px(s)
    local list=GPSCourseManager.listAll()
    T.chrome(s,{active=3,message=s.page3Message or "A/B-Kurse frei speichern und laden",
        chips={{text="Kursverwaltung (ohne Feldzuordnung)",dot=C.accent,maxW=.40}}})
    -- While editing, render ONLY the editor page.  Drawing underlying course
    -- captions first would cause them to overlap the modal in GIANTS' text pass.
    if s.page3Edit then drawEditor(s);return end

    local x,w=.200,.385
    -- AKTUELLER KURS ----------------------------------------------------
    local ct=T.panel(s,x,.150,w,.196,"AKTUELLER KURS")+.006
    local courseName=GPSCourseManager.getActiveName() or
        (GPSABLineManager.b and "A/B-Linie (ungespeichert)" or "Noch keine A/B-Linie")
    T.tile(s,x+.017,ct,.108,.098,"GESPEICHERT",tostring(#list),C.accent,.044)
    T.tile(s,x+.017+.108+.008,ct,w-.034-.108-.008,.098,"AKTUELLE A/B-REFERENZ",courseName,
        GPSCourseManager.getActiveName() and C.accent or C.textDim,.0245)

    -- SPURRICHTUNG ------------------------------------------------------
    local py=.360
    ct=T.panel(s,x,py,w,.476,"SPURRICHTUNG")+.006
    local angle=GPSCourseManager.getAngle()
    local r=66
    local ccx=x+.115
    local wellH=2*r*dy+.036
    local ccy=ct+wellH/2
    T.box(s,x+.017,ct,.228,wellH,C.well,C.lineSoft,10)
    T.compass(s,ccx,ccy,r,angle,GPSSteeringController and GPSSteeringController.enabled)
    local vx=x+.262
    txt(s,vx,ct+.032,"FAHRTRICHTUNG",.0165,C.textMute,true)
    if angle then
        txt(s,vx,ct+.094,string.format("%.2f",angle),.046,C.accent,true,"left",w-.28)
        txt(s,vx,ct+.130,"Grad",.021,C.textDim)
    else
        txt(s,vx,ct+.090,"A/B fehlt",.026,C.warn,true,"left",w-.28)
        txt(s,vx,ct+.124,"zuerst A und B setzen",.0165,C.textMute,false,"left",w-.28)
    end
    local by=ct+wellH+.012
    T.button(s,x+.017,by,.184,.058,"WINKEL EINGEBEN","setAngle",{size=.0205})
    T.button(s,x+.209,by,.159,.058,"+90 GRAD","rotate90",{size=.0205,disabled=(angle==nil)})
    txt(s,x+.019,by+.058+.030,"0 = Nord   90 = Ost   180 = Sued   270 = West",.0175,C.textMute,false,"left",w-.04)
    txt(s,x+.019,by+.058+.054,"Feindrehung: Alt+J / Alt+N (0,1 Grad)",.0175,C.warn,false,"left",w-.04)

    -- GESPEICHERTE KURSE ------------------------------------------------
    local rx,rw=.594,.393
    T.panel(s,rx,.150,rw,.686,"GESPEICHERTE KURSE")
    s.page3Selected=s.page3Selected or 1
    local rowCount=5
    s.page3Scroll=math.max(0,math.min(s.page3Scroll or 0,math.max(0,#list-rowCount)))
    local activeName=GPSCourseManager.getActiveName()
    for i=1,rowCount do
        local idx=i+s.page3Scroll
        local c=list[idx]
        local y=.232+(i-1)*.094
        if c then
            local selected=s.page3Selected==idx
            local hovered=T.hover(s,rx+.018,y,rw-.036,.081)
            T.box(s,rx+.018,y,rw-.036,.081,selected and C.accentDim or (hovered and C.buttonHi or C.well),
                selected and C.accent or (hovered and C.accentMid or C.lineSoft),9)
            if selected then T.round(s,rx+.018+2*dx,y+12*dy,4*dx,.081-24*dy,C.accent,2) end
            local isActive=activeName~=nil and activeName==c.name
            txt(s,rx+.040,y+.037,c.name:sub(1,28),.0235,selected and C.text or C.textDim,true,"left",rw-.20)
            local da=(math.deg(math.atan2(c.bx-c.ax,c.bz-c.az))+360)%360
            txt(s,rx+.040,y+.065,string.format("%.1f Grad   |   %.2f m",da,c.width or 0),.0170,selected and C.accentHi or C.textMute)
            if isActive then
                local cw=T.textWidth(s,"AKTIV",.0150,true)+.024
                T.chip(s,rx+rw-.036-cw,y+.0235,"AKTIV",{color=C.accent,fill=C.accentDim,border=C.accentMid,bold=true,size=.0150,height=22})
            end
            T.hit(s,rx+.018,y,rw-.036,.081,"select"..idx)
        end
    end
    if #list==0 then
        txt(s,rx+rw/2,.400,"Keine gespeicherten Kurse",.026,C.textDim,true,"center")
        txt(s,rx+rw/2,.440,"SPEICHERN legt die aktuelle A/B-Linie ab.",.0185,C.textMute,false,"center",rw-.05)
    end
    T.button(s,rx+.018,.713,.085,.050,"<","scrollPrev",{disabled=s.page3Scroll==0,size=.030})
    txt(s,rx+rw/2,T.mid(.713,.050,.0225),string.format("%d / %d",#list==0 and 0 or math.min(s.page3Selected,#list),#list),.0225,C.textDim,true,"center")
    T.button(s,rx+rw-.103,.713,.085,.050,">","scrollNext",{disabled=s.page3Scroll+rowCount>=#list,size=.030})
    local selectedCourse=list[s.page3Selected or 1]
    local pending=selectedCourse and s.page3PendingDelete==selectedCourse.id
    T.button(s,rx+.018,.779,.112,.050,"SPEICHERN","save",{primary=true,size=.0195})
    T.button(s,rx+.140,.779,.108,.050,"LADEN","load",{disabled=#list==0,size=.0195})
    T.button(s,rx+.258,.779,.117,.050,pending and "SICHER?" or "LOESCHEN","delete",{danger=true,disabled=#list==0,size=.0195})

    T.button(s,.839,.925,.137,.052,"OK / SCHLIESSEN","close",{primary=true,size=.0195})
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
        elseif a=="rotate90" then notify(s,GPSCourseManager.rotate90())
        end
        return true
    end
 end
 return true
end
