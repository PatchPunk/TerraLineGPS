-- TerraLine GPS menu page 4 (Info & Version) - UI refresh.
-- Quick guide with key caps, release notes and the (locked) diagnostics view.
GPSMenuPage4={}
local M=GPSMenuPage4
local T=GPSMenuTheme
local C=T.C
local rect=T.rect
local txt=T.text

-- Padlock that opens the diagnostics view (drawn natively).
local function padlock(s,x,t,sizePx)
    local dx,dy=T.px(s)
    local w,h=sizePx*dx,sizePx*dy
    local hovered=T.hover(s,x,t,w,h)
    T.box(s,x,t,w,h,hovered and C.buttonHi or C.button,hovered and C.accentMid or C.line,8)
    local cx=x+w/2
    local bodyW,bodyH=18*dx,13*dy
    local bodyT=t+h/2-1*dy
    local st=3
    -- shackle
    local shW,shH=12*dx,10*dy
    rect(s,cx-shW/2,bodyT-shH,st*dx,shH,C.text)
    rect(s,cx+shW/2-st*dx,bodyT-shH,st*dx,shH,C.text)
    rect(s,cx-shW/2,bodyT-shH,shW,st*dy,C.text)
    -- body + keyhole
    T.round(s,cx-bodyW/2,bodyT,bodyW,bodyH,C.accent,3)
    rect(s,cx-1*dx,bodyT+3*dy,2*dx,5*dy,C.onAccent)
    T.hit(s,x,t,w,h,"developer")
end

-- one guide row: caption left, optional key combination(s) right
local function guideRow(s,x,w,top,caption,keys,groups)
    local dx,dy=T.px(s)
    txt(s,x,T.mid(top,.034,.0200),caption,.0200,C.textDim,false,"left",w*.56)
    if groups then T.keyGroups(s,x+w,top+.0042,groups,.0160)
    elseif keys then T.keys(s,x+w,top+.0042,keys,.0160) end
end
local function groupHeader(s,x,top,title)
    local dx,dy=T.px(s)
    T.dot(s,x+4*dx,top+.0235,8,C.accent)
    txt(s,x+16*dx,top+.0305,title,.0225,C.accent,true)
end
local function bullet(s,x,top,text,color,maxW)
    local dx,dy=T.px(s)
    T.dot(s,x+3*dx,top-.0065,6,color or C.accent)
    txt(s,x+16*dx,top,text,.0195,color==C.warn and C.warn or C.text,false,"left",maxW)
end

function M.draw(s)
    local dx,dy=T.px(s)
    local dev=GPSDeveloperMenu
    local developerVisible=dev and (dev.editing or dev.unlocked)
    T.chrome(s,{active=4,message=(developerVisible and (dev.message or "")) or "Tipp: Im LS25-Steuerungsmenue kannst du die Tasten neu belegen.",
        messageColor=developerVisible and C.warn or C.accent,
        chips={{text="Anleitung und Version",dot=C.accent,maxW=.40}}})
    if not developerVisible then
        -- KURZANLEITUNG --------------------------------------------------
        local x,w=.200,.385
        local ct=T.panel(s,x,.150,w,.686,"KURZANLEITUNG")
        local cx0,cw=x+.022,w-.044
        local y=ct+.012
        groupHeader(s,cx0,y,"1. A/B-SPUR SETZEN"); y=y+.040
        guideRow(s,cx0,cw,y,"A auch ausserhalb Feld setzen",{"Alt","B"}); y=y+.036
        guideRow(s,cx0,cw,y,"Mind. 20 m fahren, B setzen",{"Alt","B"}); y=y+.046
        groupHeader(s,cx0,y,"2. GPS-LENKUNG"); y=y+.040
        guideRow(s,cx0,cw,y,"Kurz EIN/AUS, 3 s: Spur 1",{"Alt","X"}); y=y+.036
        guideRow(s,cx0,cw,y,"TerraLine komplett ein / aus",{"Alt","T"}); y=y+.046
        groupHeader(s,cx0,y,"3. SPUR EINSTELLEN"); y=y+.040
        guideRow(s,cx0,cw,y,"Menue oeffnen / schliessen",{"Alt","M"}); y=y+.036
        guideRow(s,cx0,cw,y,"Drehmodus: Traktormitte",{"R-Alt","W"}); y=y+.036
        guideRow(s,cx0,cw,y,"Drehen +/- 0,1 Grad",nil,{{"Alt","J"},{"Alt","N"}}); y=y+.036
        guideRow(s,cx0,cw,y,"Spur verschieben",nil,{{"Alt","Bild auf"},{"Bild ab"}}); y=y+.046
        groupHeader(s,cx0,y,"4. KURSE SPEICHERN"); y=y+.040
        guideRow(s,cx0,cw,y,"Speicher > SPEICHERN"); y=y+.034
        guideRow(s,cx0,cw,y,"Kursnamen im Menue eingeben"); y=y+.034
        guideRow(s,cx0,cw,y,"Kurs aus Liste waehlen > LADEN")

        -- Release information: only features confirmed by the latest A/B ZIP.
        local rx,rw=.594,.393
        local c2=T.panel(s,rx,.150,rw,.352,"NEU IN VERSION "..tostring(GPSConfig.version))
        local bx=rx+.020
        local notes={"Spurwinkel: 0,1 Grad um Traktormitte","A-Vorschau: 25 m weiss gestrichelt",
            "GPS-Linien: je 40 m vorn / hinten","Kabinenansicht der Linien verbessert",
            "Spurerfassung beim Start optimiert","3D-Linien: Hoehe und Breite waehlen"}
        for i,n in ipairs(notes) do bullet(s,bx,c2+.034+(i-1)*.0385,n,C.accent,rw-.06) end

        local c3=T.panel(s,rx,.514,rw,.322,"BEDIENUNG UND GRENZEN")
        local limits={{"A/B: 2x Alt+B, mind. 20 m",C.accent},{"Winkelmodus: R-Alt+W; J/N drehen",C.accent},
            {"Spurhaltung: maximal 30 km/h",C.warn},{"Spurerfassung SP: Test bis 30 km/h",C.accent},
            {"Lenkeingriff: GPS AUS",C.textMute}}
        for i,l in ipairs(limits) do bullet(s,bx,c3+.034+(i-1)*.0385,l[1],l[2],rw-.14) end
        padlock(s,rx+rw-.018-40*dx,.836-.014-40*dy,40)
    else
        -- Exclusive page: never render guide text behind the diagnostic view.
        local x,w=.200,.787
        T.box(s,x,.150,w,.686,C.surface,C.line,10)
        T.round(s,x+.014,.176,5*dx,.040,C.accent,2)
        txt(s,x+.032,.212,"ENTWICKLERDIAGNOSE",.030,C.accent,true)
        T.hline(s,x+.014,.236,w-.028,C.lineSoft)
        if dev.editing then
            txt(s,.230,.292,"Code auf der PC-Tastatur eingeben",.025,C.textDim)
            T.box(s,.231,.312,.522,.105,C.well,C.accent,10)
            txt(s,.252,.382,string.rep("*",#dev.code)..((math.floor((g_time or 0)/500)%2==0) and "|" or ""),.035,C.text,true)
            txt(s,.231,.467,"ENTER: entsperren    ESC: abbrechen",.021,C.textMute)
        else
            local ab=GPSABLineManager
            local a,b=ab and ab.a,ab and ab.b
            local vx=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle and GPSVehicleDetector.getCurrentVehicle()
            local angle="-"
            if a and b then angle=string.format("%.2f Grad",math.deg(math.atan2(b.x-a.x,b.z-a.z))) end
            local lines={
                {"Fahrzeug",tostring(vx and (vx.getName and vx:getName() or vx.typeName) or "keins")},
                {"A",a and string.format("%.2f / %.2f",a.x,a.z) or "nicht gesetzt"},
                {"B",b and string.format("%.2f / %.2f",b.x,b.z) or "nicht gesetzt"},
                {"Winkel",angle},
                {"Spurversatz",string.format("%.2f m",ab and (ab.offsetMeters or 0) or 0)},
                {"Felderkennung",dev.getFieldDiagnostic(vx)},
                {"Geraeteversatz",dev.getImplementDiagnostic(vx)},
            }
            for i,l in ipairs(lines) do
                local ty=.258+(i-1)*.046
                if i%2==1 then T.round(s,.226,ty,.742,.040,C.surface2,6) end
                txt(s,.240,T.mid(ty,.040,.0205),l[1],.0205,C.textMute,false)
                txt(s,.400,T.mid(ty,.040,.0205),l[2],.0205,C.text,true,"left",.55)
            end
            txt(s,.240,.598,"Lenkdiagnose: nur Anzeige, kein aktiver Lenktest",.0195,C.warn)
            T.button(s,.230,.640,.320,.068,"SNAPSHOT INS LOG","devlog",{primary=true,size=.0215})
            -- Reuse both existing developer-option buttons; no layout changes.
            local diagOn=dev.isDiagnosticsEnabled()
            T.button(s,.568,.640,.178,.068,"DIAG EIN","devdiag_on",{selected=diagOn,size=.0215})
            T.button(s,.765,.640,.178,.068,"DIAG AUS","devdiag_off",{selected=not diagOn,size=.0215})
            txt(s,.230,.742,"Detailprotokoll: "..(diagOn and "EIN" or "AUS (Standard)"),.0185,diagOn and C.accent or C.textMute)
            txt(s,.230,.772,"Nur lokale LOG | Dedicated Server: gsTLGPSDiag on",.0170,C.textMute)
            T.button(s,.790,.752,.162,.062,"ZURUECK","devclose",{size=.0205})
        end
        if dev.editing then s.nativeHits={} end
    end
    T.button(s,.839,.925,.137,.052,"OK / SCHLIESSEN","close",{primary=true,size=.0195})
end
function M.onMouseClick(s,px,top)
 for i=#(s.nativeHits or {}),1,-1 do
  local h=s.nativeHits[i]
  if px>=h.x and px<=h.x+h.w and top>=h.top and top<=h.top+h.h then
    if h.action=="developer" then GPSDeveloperMenu.open()
    elseif h.action=="devclose" then GPSDeveloperMenu.close()
    elseif h.action=="devlog" then GPSDeveloperMenu.logSnapshot()
    elseif h.action=="devdiag_on" then GPSDeveloperMenu.setDiagnosticsEnabled(true)
    elseif h.action=="devdiag_off" then GPSDeveloperMenu.setDiagnosticsEnabled(false)
    elseif h.action=="close" then s:onClickBack()
    elseif h.action:sub(1,4)=="page" then s.page=tonumber(h.action:sub(5)) or 1 end
    return true
  end
 end
 return true
end
