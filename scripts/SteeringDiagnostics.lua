-- Isolated experimental diagnostic. Never controls throttle, brakes or implement.
GPSSteeringDiagnostics = {
    active=false, vehicle=nil, duration=0, timer=0, command=0,
    calls=0, attempted=0, startSteering=nil, endSteering=nil,
    lastAxis=nil, status="Bereit", lastReport="Noch kein Test", lastFrameCount=0
}
local D=GPSSteeringDiagnostics
local function output(message)
    D.status=message
    if GPSLogger and GPSLogger.info then GPSLogger.info("LENK-DIAG "..message) end
end
local function readSteering(vehicle)
    if vehicle and vehicle.spec_drivable then
        local s=vehicle.spec_drivable
        if type(s.axisSide)=="number" then return s.axisSide,"spec_drivable.axisSide" end
        if type(s.lastInputValues)=="table" and type(s.lastInputValues.axisSteer)=="number" then
            return s.lastInputValues.axisSteer,"spec_drivable.lastInputValues.axisSteer"
        end
    end
    return nil,"kein lesbarer Lenkwert"
end
function D.stop(reason)
    if D.active then
        local value,source=readSteering(D.vehicle)
        D.endSteering=value
        D.lastReport=string.format("%s | Physikaufrufe=%d, Eingriffe=%d, Ausgang=%s, Ende=%s (%s)",
            reason or "Beendet",D.calls,D.attempted,tostring(D.startSteering),tostring(value),source)
        output(D.lastReport)
    end
    D.active=false;D.vehicle=nil;D.timer=0
end
function D.start(vehicle,sign)
    -- Public release: a console/editor call must never inject steering.
    if GPSConfig == nil or GPSConfig.publicBeta ~= false then
        return "Lenkimpuls-Diagnose nur in interner Entwicklerfassung"
    end
    if D.active then D.stop("Abgebrochen");return "Lenkdiagnose abgebrochen" end
    if GPSSteeringController then GPSSteeringController.stop("Diagnosetest") end
    if not vehicle or not vehicle.spec_drivable then return "Lenkdiagnose: kein lenkbares Fahrzeug" end
    if not GPSSteeringController or not GPSSteeringController.install(vehicle) then return "Lenkdiagnose: Fahrzeug-Hook nicht installiert" end
    D.vehicle=vehicle;D.active=true;D.duration=900;D.timer=0
    D.command=(sign=="right") and 0.12 or -0.12
    D.calls=0;D.attempted=0;D.lastAxis=nil
    D.startSteering=readSteering(vehicle)
    output(string.format("Test gestartet: Achswert %.2f, max. 0.9s. Nur auf freier Flaeche, langsam fahren.",D.command))
    return D.status
end
function D.physics(vehicle,axisForward,axisSide,handbrake,dt)
    if not D.active or D.vehicle~=vehicle then return axisSide end
    D.calls=D.calls+1
    local speed=type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    if handbrake or speed>12 then
        D.stop("Test beendet (Zeit/Geschwindigkeit/Handbremse)")
        return axisSide
    end
    -- Keep user takeover possible: substantial deliberate input cancels the test.
    if type(axisSide)=="number" and math.abs(axisSide)>0.35 then
        D.stop("Fahrereingriff")
        return axisSide
    end
    D.attempted=D.attempted+1
    D.lastAxis=axisSide
    if D.attempted==1 and GPSLogger then GPSLogger.info("LENK-DIAG erster Physik-Eingriff erfolgreich; Original-Achse="..tostring(axisSide)) end
    return D.command
end
function D.update(dt)
    if D.active then
        D.timer=D.timer+(dt or 0)
        if D.timer>1200 then D.stop("Zeitlimit (kein/zu wenig Physikaufruf)") end
    end
end
function D.getStatus()
    if D.active then return string.format("AKTIV | Hook %d | Eingriffe %d | Wert %.2f",D.calls,D.attempted,D.command) end
    return D.status
end
