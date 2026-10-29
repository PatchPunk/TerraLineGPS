-- TerraLine GPS: release-safe logging plus opt-in local diagnostic sessions.
-- No steering, physics, rendering or network state is changed by this logger.
GPSLogger = GPSLogger or {}
GPSLogger.prefix = "[TerraLine GPS] "
GPSLogger.diagnosticRun = GPSLogger.diagnosticRun or 0
local function diagnosticMode()
    return GPSConfig ~= nil and GPSConfig.showDiagnostics == true
end
local function origin()
    local mission=g_currentMission
    if g_server~=nil then
        if mission and mission.missionInfo and mission.missionInfo.isMultiplayer then
            return g_client~=nil and "MP-HOST" or "MP-SERVER"
        end
        return "SP-SERVER"
    end
    if g_client~=nil then return "MP-CLIENT" end
    return "LOADING"
end
local function important(message)
    local s = string.lower(message)
    if s:find("warnung", 1, true) or s:find("fehler", 1, true)
       or s:find("fehlgeschlagen", 1, true) or s:find("nicht verfuegbar", 1, true)
       or s:find("ungueltig", 1, true) then return true end
    if s:match("^v[%d%.]+ gestartet:") then return true end
    local reason=message:match("^GPS%-LENK AUS: (.+)$")
    if reason then return reason ~= "Manuell ausgeschaltet" end
    return false
end
local function marker()
    return string.format("[DIAG:%s:#%d] ",origin(),GPSLogger.diagnosticRun)
end
function GPSLogger.force(message)
    print(GPSLogger.prefix..tostring(message))
end
function GPSLogger.info(message)
    local value=tostring(message)
    if diagnosticMode() then
        print(GPSLogger.prefix..marker()..value)
    elseif important(value) then
        print(GPSLogger.prefix..value)
    end
end
function GPSLogger.debug(message)
    if diagnosticMode() then
        print(GPSLogger.prefix..marker()..tostring(message))
    end
end
function GPSLogger.setDiagnostics(enabled, source)
    if not GPSConfig then return false end
    local isOn=enabled==true
    if (GPSConfig.showDiagnostics==true)==isOn then return true end
    if isOn then
        GPSLogger.diagnosticRun=GPSLogger.diagnosticRun+1
        GPSConfig.showDiagnostics=true
        GPSLogger.force(string.format("DIAG START | run=%d role=%s version=%s ausloeser=%s",
            GPSLogger.diagnosticRun,origin(),tostring(GPSConfig.version),tostring(source or "unbekannt")))
    else
        GPSLogger.force(string.format("DIAG ENDE | run=%d role=%s ausloeser=%s",
            GPSLogger.diagnosticRun,origin(),tostring(source or "unbekannt")))
        GPSConfig.showDiagnostics=false
    end
    return true
end
