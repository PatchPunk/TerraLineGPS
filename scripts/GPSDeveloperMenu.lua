-- TerraLine GPS - local development diagnostics, display only.
-- UI lock is a convenience gate, NOT cryptographic security (Lua mods are inspectable).
GPSDeveloperMenu = { unlocked=false, editing=false, code="", message="", logging=false, fieldDiagnostic="Noch nicht geprueft" }
local D=GPSDeveloperMenu
local ACCESS_CODE="4826" -- development PIN; change prior to distribution
local function utf8back(s)
 local n=#s
 while n>1 and s:byte(n)>=128 and s:byte(n)<192 do n=n-1 end
 return s:sub(1,n-1)
end
function D.open()
 D.editing=true;D.code="";D.fieldDiagnostic="Noch nicht geprueft";D.message="Code mit PC-Tastatur eingeben"
end
function D.close()
 D.editing=false;D.code="";D.unlocked=false;D.fieldDiagnostic="Noch nicht geprueft"
end
function D.keyEvent(unicode,sym,modifier,isDown)
 if not D.editing then return false end
 if not isDown then return true end
 if sym==27 or (Input and sym==Input.KEY_esc) then D.editing=false;D.code="";return true end
 if sym==13 or sym==271 or (Input and (sym==Input.KEY_return or sym==Input.KEY_numpadenter)) then
  if D.code==ACCESS_CODE then D.unlocked=true;D.fieldDiagnostic=D.detectFieldOnce();D.message="Entwicklerdiagnose freigeschaltet"
  else D.message="Falscher Code" end
  D.code="";D.editing=false
  return true
 end
 if sym==8 or (Input and sym==Input.KEY_backspace) then D.code=utf8back(D.code);return true end
 if type(unicode)=="number" and unicode>=48 and unicode<=57 and #D.code<12 then D.code=D.code..string.char(unicode) end
 return true
end
-- Read-only diagnostics. No steering or track state is modified here.
-- Adapted from TerraLineGPS v0.9.9.21 (GPSFieldTest.resolveFieldId).
-- Performed exactly once on successful developer unlock, never from draw/update.
local function validId(id)
 return type(id)=="number" and id>0 and id==math.floor(id)
end
local function fieldIdOf(field)
 if validId(field) then return field end
 if type(field)~="table" then return nil end
 if type(field.getId)=="function" then
  local ok,id=pcall(field.getId,field)
  if ok and validId(id) then return id end
 end
 local id=field.fieldId or field.id or field.index
 return validId(id) and id or nil
end
local function resolveField(x,z)
 local farmManager=g_farmlandManager or (g_currentMission and g_currentMission.farmlandManager)
 local fieldManager=(g_currentMission and g_currentMission.fieldManager) or g_fieldManager
 local farmland,farmlandId
 if farmManager then
  if type(farmManager.getFarmlandAtWorldPosition)=="function" then
   local ok,obj=pcall(farmManager.getFarmlandAtWorldPosition,farmManager,x,z)
   if ok and type(obj)=="table" then farmland=obj;farmlandId=obj.id end
  end
  if not validId(farmlandId) and type(farmManager.getFarmlandIdAtWorldPosition)=="function" then
   local ok,id=pcall(farmManager.getFarmlandIdAtWorldPosition,farmManager,x,z)
   if ok and validId(id) then farmlandId=id end
  end
 end
 local fieldId
 if type(FSDensityMapUtil)=="table" and type(FSDensityMapUtil.getFieldIdAtWorldPosition)=="function" then
  local ok,id=pcall(FSDensityMapUtil.getFieldIdAtWorldPosition,x,z)
  if ok and validId(id) then fieldId=id end
 end
 if not fieldId and fieldManager and type(fieldManager.getFieldAtWorldPosition)=="function" then
  local ok,field=pcall(fieldManager.getFieldAtWorldPosition,fieldManager,x,z)
  if ok then fieldId=fieldIdOf(field) end
 end
 if not fieldId and fieldManager and validId(farmlandId) then
  local mapped=fieldManager.farmlandIdFieldMapping and fieldManager.farmlandIdFieldMapping[farmlandId]
  fieldId=fieldIdOf(mapped) or fieldIdOf(farmland and farmland.field)
  if not fieldId then
   local fields=fieldManager.fields
   if type(fieldManager.getFields)=="function" then
    local ok,result=pcall(fieldManager.getFields,fieldManager)
    if ok then fields=result end
   end
   if type(fields)=="table" then
    for _,field in pairs(fields) do
     if type(field)=="table" and type(field.farmland)=="table" and field.farmland.id==farmlandId then
      fieldId=fieldIdOf(field)
      if fieldId then break end
     end
    end
   end
  end
 end
 return fieldId,farmlandId
end
function D.detectFieldOnce()
 local detector=GPSVehicleDetector
 local vehicle=detector and detector.getCurrentVehicle and detector.getCurrentVehicle()
 if not vehicle then return "Kein Fahrzeug" end
 local node=detector.getPositionNode and detector.getPositionNode(vehicle)
 if not node or type(getWorldTranslation)~="function" then return "Position unbekannt" end
 local ok,x,_,z=pcall(getWorldTranslation,node)
 if not ok or type(x)~="number" or type(z)~="number" then return "Position unbekannt" end
 local success,fieldId,farmlandId=pcall(resolveField,x,z)
 if not success then
  if GPSLogger and GPSLogger.info then GPSLogger.info("DEV Feldsuche Fehler: "..tostring(fieldId)) end
  return "Abfragefehler"
 end
 local result=fieldId and ("Feld "..fieldId) or "Feld-ID nicht verfuegbar"
 if validId(farmlandId) then result=result.." | Flurstueck "..farmlandId end
 if GPSLogger and GPSLogger.info then GPSLogger.info("DEV Feldsuche (nur bei Freischaltung): "..result) end
 return result
end
-- The detailed logger is a local, session-only developer option.
-- Unlocking the developer page does NOT activate it; default is OFF.
function D.isDiagnosticsEnabled()
 return GPSConfig~=nil and GPSConfig.showDiagnostics==true
end
function D.setDiagnosticsEnabled(enabled)
 if not D.unlocked or GPSConfig==nil then return false end
 local isOn=enabled==true
 GPSConfig.showDiagnostics=isOn
 D.logging=isOn
 D.message=isOn and "Detaillierte Diagnose EIN" or "Detaillierte Diagnose AUS"
 if GPSLogger and GPSLogger.info then
  GPSLogger.info("Entwicklerdiagnose "..(isOn and "EIN" or "AUS"))
 end
 return true
end
function D.getFieldDiagnostic()
 return D.unlocked and D.fieldDiagnostic or "Diagnose gesperrt"
end
function D.getImplementDiagnostic(vehicle)
 if not vehicle then return "Kein Fahrzeug" end
 local probe=GPSDeviceOffsetProbe
 if not probe or type(probe.getData)~="function" then return "Messung nicht verfuegbar" end
 local ok,center,desc,complete=pcall(probe.getData,vehicle)
 if not ok then return "Messfehler" end
 if type(center)~="number" then return tostring(desc or "Keine Messung") end
 return string.format("Arbeitsmitte %+.2f m (%s)",center,complete and "vollstaendig" or "teilweise")
end
function D.logSnapshot()
 if not D.unlocked then return end
 local a=GPSABLineManager and GPSABLineManager.a
 local b=GPSABLineManager and GPSABLineManager.b
 local v=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle and GPSVehicleDetector.getCurrentVehicle()
 local field=D.getFieldDiagnostic(v)
 local implement=D.getImplementDiagnostic(v)
 if GPSLogger and GPSLogger.info then
  GPSLogger.info(string.format("DEV SNAPSHOT vehicle=%s A=%s B=%s shift=%s field=%s implement=%s",
   tostring(v and (v.getName and v:getName() or v.typeName)),
   a and string.format("%.2f/%.2f",a.x,a.z) or "-",
   b and string.format("%.2f/%.2f",b.x,b.z) or "-",
   tostring(GPSABLineManager and GPSABLineManager.offsetMeters),field,implement))
 end
 D.message="Diagnose-Snapshot ins Log geschrieben"
end
