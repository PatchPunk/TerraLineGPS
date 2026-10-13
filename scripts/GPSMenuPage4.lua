-- TerraLine GPS - native, legible guide and current version information.
GPSMenuPage4={}
local M=GPSMenuPage4
local P={base={.048,.074,.087,.975},header={.065,.099,.113,.99},sidebar={.040,.065,.073,.97},
 panel={.065,.104,.116,.96},panel2={.085,.126,.143,.98},input={.108,.152,.169,.95},
 stroke={.18,.275,.292,.94},dim={.19,.25,.265,.57},white={.945,.965,.950,1},
 muted={.68,.75,.75,1},green={.45,.92,.22,1},greenDim={.19,.40,.12,1},yellow={.99,.78,.13,1}}
local function pos(s,x,t,w,h) return s.pageX+x*s.pageW,s.pageY+(1-t-h)*s.pageH,w*s.pageW,h*s.pageH end
local function rect(s,x,t,w,h,c)
 if type(drawFilledRect)~="function" then return end
 local a,b,cw,ch=pos(s,x,t,w,h);drawFilledRect(a,b,cw,ch,c[1],c[2],c[3],c[4])
end
local function rim(s,x,t,w,h,c)
 local dx=(g_pixelSizeX or .0007)*1.35/s.pageW;local dy=(g_pixelSizeY or .0011)*1.35/s.pageH
 rect(s,x,t,w,dy,c);rect(s,x,t+h-dy,w,dy,c);rect(s,x,t,dx,h,c);rect(s,x+w-dx,t,dx,h,c)
end
local function txt(s,x,t,str,size,color,bold,alignment)
 if type(renderText)~="function" then return end
 local px,py=pos(s,x,t,0,0);local c=color or P.white
 if setTextColor then setTextColor(c[1],c[2],c[3],c[4]) end
 if setTextBold then setTextBold(bold==true) end
 if type(setTextAlignment)=="function" and type(RenderText)=="table" then setTextAlignment(alignment=="center" and RenderText.ALIGN_CENTER or alignment=="right" and RenderText.ALIGN_RIGHT or RenderText.ALIGN_LEFT) end
 renderText(px,py,size*s.pageH,tostring(str or ""))
 if type(setTextAlignment)=="function" and type(RenderText)=="table" then setTextAlignment(RenderText.ALIGN_LEFT) end
 if setTextColor then setTextColor(1,1,1,1) end
 if setTextBold then setTextBold(false) end
end
local function panel(s,x,t,w,h,title)
 rect(s,x,t,w,h,P.panel);rim(s,x,t,w,h,P.stroke)
 rect(s,x+.011,t+.018,.004,.034,P.green)
 txt(s,x+.028,t+.048,title,.024,P.white,true)
 rect(s,x+.011,t+.065,w-.022,.0012,P.dim)
end
local function btn(s,x,t,w,h,value,action,selected)
 rect(s,x,t,w,h,selected and P.greenDim or P.input);rim(s,x,t,w,h,selected and P.green or P.dim)
 txt(s,x+w/2,t+h*.70,value,math.min(h*.44,.022),P.white,true,"center")
 s.nativeHits[#s.nativeHits+1]={x=x,top=t,w=w,h=h,action=action}
end
local function item(s,x,top,label,value)
 txt(s,x,top,label,.020,P.white)
 if value then txt(s,x+.306,top,value,.020,P.green,true,"right") end
end
function M.draw(s)
 s.nativeHits={}
 rect(s,0,0,1,1,P.base);rim(s,0,0,1,1,P.stroke)
 rect(s,0,0,1,.128,P.header);rect(s,0,.128,1,.002,P.dim)
 rect(s,.024,.033,.038,.055,P.greenDim)
 if GPSMenuSymbols then GPSMenuSymbols.header(s,.044,.029) end
 txt(s,.079,.065,"TERRALINE GPS",.045,P.white,true)
 txt(s,.408,.065,"v"..tostring(GPSConfig.version),.022,P.green)
 txt(s,.079,.106,"ANLEITUNG UND VERSION",.020,P.muted)
 btn(s,.932,.032,.046,.065,"X","close")
 rect(s,.012,.145,.177,.691,P.sidebar)
 for slot,data in ipairs({{id=1,name="Spurfuehrung"},{id=3,name="Speicher"},{id=4,name="Info & Version"}}) do
   local y=.164+(slot-1)*.124;local active=data.id==4
   rect(s,.020,y,.162,.110,active and P.greenDim or P.input)
   rim(s,.020,y,.162,.110,active and P.green or P.dim)
   if GPSMenuSymbols then GPSMenuSymbols.draw(s,data.id,.049,y+.026,active and P.green or P.muted) end
   txt(s,.073,y+.069,data.name,.021,P.white,active)
   s.nativeHits[#s.nativeHits+1]={x=.020,top=y,w=.162,h=.110,action="page"..data.id}
 end
 local dev=GPSDeveloperMenu
 local developerVisible=dev and (dev.editing or dev.unlocked)
 if not developerVisible then
 panel(s,.200,.150,.385,.686,"KURZANLEITUNG")
 local xx=.221
 txt(s,xx,.248,"1. A/B-SPUR SETZEN",.024,P.green,true)
 item(s,xx,.290,"A auch ausserhalb Feld setzen", "Alt+B")
 item(s,xx,.323,"Mind. 20 m fahren, B setzen", "Alt+B")
 txt(s,xx,.376,"2. GPS-LENKUNG",.024,P.green,true)
 item(s,xx,.419,"Lenkung aktivieren / aus", "Alt+X")
 item(s,xx,.452,"TerraLine komplett ein / aus","Alt+T")
 txt(s,xx,.503,"3. SPUR EINSTELLEN",.024,P.green,true)
 item(s,xx,.544,"Menue oeffnen / schliessen", "Alt+M")
 item(s,xx,.576,"Spur um 90 Grad drehen", "Alt+R")
 item(s,xx,.608,"Korrektur per cm", "Alt+Bildauf/-ab")
 txt(s,xx,.661,"4. KURSE SPEICHERN",.024,P.green,true)
 item(s,xx,.703,"Speicher > SPEICHERN")
 item(s,xx,.736,"Kursnamen im Menue eingeben")
 item(s,xx,.769,"Kurs aus Liste waehlen > LADEN")
 -- User guide: current beta capabilities and explicit operating limits.
 -- Keep all navigation, quick-start instructions and developer unlock unchanged.
 panel(s,.594,.150,.393,.352,"VERSION / DAS KANN GPS")
 local x=.612
 txt(s,x,.273,"v"..tostring(GPSConfig.version).."   |   Beta 13.10.2026",.023,P.green,true)
 txt(s,x,.318,"A/B-Gerade + parallele Spuren",.020,P.white)
 txt(s,x,.350,"GPS-Lenkung in beide Richtungen",.020,P.white)
 txt(s,x,.382,"Hofkurse speichern und laden",.020,P.white)
 txt(s,x,.414,"Linienfarbe, -hoehe und -breite",.020,P.white)
 txt(s,x,.446,"GPS-Spuren verschieben / drehen",.020,P.white)
 txt(s,x,.478,"GPS-Status im GIANTS-Tacho",.020,P.white)
 panel(s,.594,.514,.393,.322,"GRENZEN / NOCH NICHT")
 txt(s,x,.604,"Spurhaltung: maximal 30 km/h",.019,P.yellow)
 txt(s,x,.640,"SP-Spurerfassung: nur bis 12 km/h",.019,P.white)
 txt(s,x,.676,"Zu weit / >20 Grad: GPS kann AUS",.019,P.white)
 txt(s,x,.712,"Lenkrad-Eingriff: Lenkung AUS",.019,P.white)
 txt(s,x,.748,"Keine Konturkurse",.019,P.muted)
 txt(s,x,.785,"ProSeed/Vorgewende: Addon",.018,P.muted)
 -- Padlock and button reduced uniformly by 30%, centered on the previous position.
 local bx,bt,bw,bh=.8515,.7335,.063,.063
 rect(s,bx,bt,bw,bh,P.input);rim(s,bx,bt,bw,bh,P.dim)
 local cx=bx+bw*.5
 local bodySize=.0252
 local bodyX=cx-bodySize*.5
 local bodyY=bt+.0287
 local shackleW=.014
 local shackleH=.014
 local shackleX=cx-shackleW*.5
 local shackleY=bt+.0126
 local stroke=.00294
 rect(s,shackleX,shackleY,stroke,shackleH,P.white)
 rect(s,shackleX+shackleW-stroke,shackleY,stroke,shackleH,P.white)
 rect(s,shackleX,shackleY,shackleW,stroke,P.white)
 rect(s,bodyX,bodyY,bodySize,bodySize,P.green)
 rect(s,cx-.00196,bodyY+.007,.00392,.0077,P.base)
 rect(s,cx-.00105,bodyY+.0147,.0021,.0042,P.base)
 s.nativeHits[#s.nativeHits+1]={x=bx,top=bt,w=bw,h=bh,action="developer"}
 rect(s,.013,.849,.974,.059,P.panel2)
 txt(s,.027,.888,"Tipp: Im LS25-Steuerungsmenue kannst du die Tasten neu belegen.",.020,P.muted)
 end
 if developerVisible then
  -- Exclusive page: never render guide text behind the diagnostic view.
  s.nativeHits={}
  rect(s,.198,.145,.790,.694,P.base);rim(s,.198,.145,.790,.694,P.stroke)
  txt(s,.229,.211,"ENTWICKLERDIAGNOSE",.032,P.green,true)
  rect(s,.229,.237,.725,.0015,P.dim)
  if dev.editing then
   txt(s,.230,.288,"Code auf der PC-Tastatur eingeben",.025,P.white)
   rect(s,.231,.310,.522,.105,P.input);rim(s,.231,.310,.522,.105,P.green)
   txt(s,.250,.382,string.rep("*",#dev.code).."|",.035,P.white,true)
   txt(s,.231,.467,"ENTER: entsperren    ESC: abbrechen",.021,P.muted)
  else
   local ab=GPSABLineManager
   local a,b=ab and ab.a,ab and ab.b
   local vx=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle and GPSVehicleDetector.getCurrentVehicle()
   local angle="-"
   if a and b then angle=string.format("%.2f Grad",math.deg(math.atan2(b.x-a.x,b.z-a.z))) end
   txt(s,.230,.271,"Fahrzeug: "..tostring(vx and (vx.getName and vx:getName() or vx.typeName) or "keins"),.020,P.white)
   txt(s,.230,.312,"A: "..(a and string.format("%.2f / %.2f",a.x,a.z) or "nicht gesetzt"),.021,P.white)
   txt(s,.230,.349,"B: "..(b and string.format("%.2f / %.2f",b.x,b.z) or "nicht gesetzt"),.021,P.white)
   txt(s,.230,.386,"Winkel: "..angle,.021,P.white)
   txt(s,.230,.423,"Spurversatz: "..string.format("%.2f m",ab and (ab.offsetMeters or 0) or 0),.021,P.white)
   txt(s,.230,.460,"Felderkennung: "..dev.getFieldDiagnostic(vx),.020,P.muted)
   txt(s,.230,.497,"Geraeteversatz: "..dev.getImplementDiagnostic(vx),.020,P.muted)
   txt(s,.230,.534,"Lenkdiagnose: nur Anzeige, kein aktiver Lenktest",.020,P.yellow)
   btn(s,.230,.584,.320,.072,"SNAPSHOT INS LOG","devlog",true)
   -- Reuse both existing developer-option buttons; no layout changes.
   local diagOn=dev.isDiagnosticsEnabled()
   btn(s,.568,.584,.178,.072,"DIAG EIN","devdiag_on",diagOn)
   btn(s,.765,.584,.178,.072,"DIAG AUS","devdiag_off",not diagOn)
   txt(s,.230,.690,"Detailprotokoll: "..(diagOn and "EIN" or "AUS (Standard)"),.018,diagOn and P.green or P.muted)
  end
  txt(s,.230,.764,dev.message or "",.021,P.yellow)
  btn(s,.790,.743,.162,.065,"ZURUECK","devclose")
 end
 txt(s,.030,.958,"[ESC] Zurueck",.024,P.white,true)
 btn(s,.839,.925,.137,.050,"OK / SCHLIESSEN","close",true)
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
