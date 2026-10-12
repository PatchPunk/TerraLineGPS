-- A/B is always user-defined. No vehicle control takes place.
GPSABLineManager={a=nil,b=nil,offsetMeters=0,minDistance=20}
function GPSABLineManager.clear()
    GPSABLineManager.a=nil;GPSABLineManager.b=nil;GPSABLineManager.offsetMeters=0
end
function GPSABLineManager.getVehiclePoint()
    local vehicle=GPSVehicleDetector.getCurrentVehicle()
    local node=vehicle and GPSVehicleDetector.getPositionNode(vehicle)
    if not node then return nil,"Kein Fahrzeug" end
    local x,y,z=getWorldTranslation(node)
    if type(x)~="number" or type(z)~="number" then return nil,"Keine Position" end
    return {x=x,z=z},nil
end
function GPSABLineManager.setA()
    local p,errorText=GPSABLineManager.getVehiclePoint()
    if not p then return "GPS A: "..errorText end
    GPSABLineManager.a=p;GPSABLineManager.b=nil;GPSABLineManager.offsetMeters=0
    return string.format("GPS A gesetzt: %.1f / %.1f (B wird zurueckgesetzt)",p.x,p.z)
end
function GPSABLineManager.setB()
    if not GPSABLineManager.a then return "GPS B: Zuerst A setzen" end
    local p,errorText=GPSABLineManager.getVehiclePoint()
    if not p then return "GPS B: "..errorText end
    local dx=p.x-GPSABLineManager.a.x;local dz=p.z-GPSABLineManager.a.z
    if dx*dx+dz*dz<(GPSABLineManager.minDistance or 20)^2 then return "GPS B: Mindestens 20 Meter Luftlinie zu A" end
    GPSABLineManager.b=p
    GPSABLineManager.offsetMeters=0
    return string.format("GPS B gesetzt: %.1f / %.1f",p.x,p.z)
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
