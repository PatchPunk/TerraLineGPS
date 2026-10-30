-- A/B is always user-defined. No vehicle control takes place.
GPSABLineManager={a=nil,b=nil,offsetMeters=0,minDistance=20,captureStage="idle"}
function GPSABLineManager.clear()
    GPSABLineManager.a=nil;GPSABLineManager.b=nil;GPSABLineManager.offsetMeters=0
    GPSABLineManager.captureStage="idle"
end
function GPSABLineManager.getVehiclePoint()
    local vehicle=GPSVehicleDetector.getCurrentVehicle()
    local node=vehicle and GPSVehicleDetector.getPositionNode(vehicle)
    if not node then return nil,"Kein Fahrzeug" end
    local x,y,z=getWorldTranslation(node)
    if type(x)~="number" or type(z)~="number" then return nil,"Keine Position" end
    return {x=x,z=z},nil
end
-- First press only arms capture. Do not destroy an active/saved course.
function GPSABLineManager.armCapture()
    GPSABLineManager.captureStage="armed"
    return "GPS A/B scharf: Alt+B startet die Messung (A)"
end
function GPSABLineManager.setA()
    local p,errorText=GPSABLineManager.getVehiclePoint()
    if not p then return "GPS A: "..errorText end
    -- Capture the vehicle's forward heading at A (not from the subsequent
    -- A->B vector). Only the A marker's visual orientation uses this value.
    local vehicle=GPSVehicleDetector.getCurrentVehicle()
    local node=vehicle and GPSVehicleDetector.getPositionNode(vehicle)
    if node and type(localDirectionToWorld)=="function" then
        local vx,_,vz=localDirectionToWorld(node,0,0,1)
        if type(vx)=="number" and type(vz)=="number" then
            local length=math.sqrt(vx*vx+vz*vz)
            if length>0.000001 then
                p.headingX=vx/length
                p.headingZ=vz/length
            end
        end
    end
    GPSABLineManager.a=p;GPSABLineManager.b=nil;GPSABLineManager.offsetMeters=0
    GPSABLineManager.captureStage="measuring"
    return string.format("GPS A gesetzt: %.1f / %.1f; Messung gestartet (B ab 20 m)",p.x,p.z)
end
function GPSABLineManager.setB()
    if not GPSABLineManager.a then return "GPS B: Zuerst A setzen" end
    local p,errorText=GPSABLineManager.getVehiclePoint()
    if not p then return "GPS B: "..errorText end
    local dx=p.x-GPSABLineManager.a.x;local dz=p.z-GPSABLineManager.a.z
    if dx*dx+dz*dz<(GPSABLineManager.minDistance or 20)^2 then return "GPS B: Mindestens 20 Meter Luftlinie zu A" end
    GPSABLineManager.b=p
    GPSABLineManager.offsetMeters=0
    GPSABLineManager.captureStage="complete"
    return string.format("GPS B gesetzt: %.1f / %.1f",p.x,p.z)
end

-- Shared conversion for the menu AND the keyboard shortcuts. A/B uses
-- normal (dz,-dx), while the driver's right depends on tractor orientation.
-- Do not duplicate this sign conversion in individual input handlers.
function GPSABLineManager.getDriverRightSign(vehicle)
    local a,b=GPSABLineManager.a,GPSABLineManager.b
    if not a or not b then return 1,nil end
    local node=vehicle and GPSVehicleDetector and GPSVehicleDetector.getPositionNode(vehicle)
    if not node or type(localDirectionToWorld)~="function" then return 1,nil end
    local dx,dz=b.x-a.x,b.z-a.z
    local len=math.sqrt(dx*dx+dz*dz)
    if len<0.0001 then return 1,nil end
    local rx,_,rz=localDirectionToWorld(node,1,0,0)
    if type(rx)=="number" and type(rz)=="number" then
        local dot=rx*(dz/len)+rz*(-dx/len)
        if math.abs(dot)>0.05 then return dot>0 and 1 or -1,dot end
    end
    -- With a 90-degree tractor heading the driver's right is ambiguous
    -- relative to the course; use the established forward-heading fallback.
    local fx,_,fz=localDirectionToWorld(node,0,0,1)
    if type(fx)~="number" or type(fz)~="number" then return 1,nil end
    return (fx*dx+fz*dz)<0 and -1 or 1,nil
end
function GPSABLineManager.shiftDriverRelative(direction,meters,vehicle)
    local sign,dot=GPSABLineManager.getDriverRightSign(vehicle)
    local a=GPSABLineManager.a
    local oldX,oldZ=a and a.x,a and a.z
    local ok,msg=GPSABLineManager.shift(direction*sign,meters)
    if ok and GPSConfig and GPSConfig.showDiagnostics and GPSLogger then
        local movedX,movedZ=a.x-oldX,a.z-oldZ
        -- Print actual map translation, not merely the requested step value.
        GPSLogger.info(string.format(
            "SPURVERSATZ KONTROLLE: Fahrerbefehl=%+d Schritt=%.2fm "..
            "AB-Normal-Vorzeichen=%+d DeltaWeltX=%+.3fm DeltaWeltZ=%+.3fm "..
            "Traktor-Rechtsprojektion=%s GesamtAB=%+.2fm",
            direction,meters,sign,movedX,movedZ,
            dot and string.format("%+.3f",dot) or "n/v",
            GPSABLineManager.offsetMeters or 0))
    end
    return ok,msg
end

-- Shift an established A/B guidance line, keeping the heading unchanged.
-- Positive steps move toward the vehicle's right relative to A->B.
function GPSABLineManager.shift(direction,meters)
    local a,b=GPSABLineManager.a,GPSABLineManager.b
    if not a or not b then return false,"GPS Verschieben: Zuerst A und B setzen" end
    local dx,dz=b.x-a.x,b.z-a.z
    local len=math.sqrt(dx*dx+dz*dz)
    if len<10 then return false,"GPS Verschieben: A/B-Linie zu kurz" end
    local distance=direction*meters
    local sx,sz=dz/len*distance,-dx/len*distance
    a.x=a.x+sx; a.z=a.z+sz
    b.x=b.x+sx; b.z=b.z+sz
    GPSABLineManager.offsetMeters=(GPSABLineManager.offsetMeters or 0)+distance
    return true,string.format("GPS A/B %s um %.2f m verschoben", direction>0 and "rechts" or "links",meters)
end
