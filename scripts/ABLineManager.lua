-- A/B is always user-defined. No vehicle control takes place.
GPSABLineManager={a=nil,b=nil,offsetMeters=0,minDistance=20,singlePointMode=false}
function GPSABLineManager.clear()
    GPSABLineManager.a=nil;GPSABLineManager.b=nil;GPSABLineManager.offsetMeters=0;GPSABLineManager.singlePointMode=false
end
function GPSABLineManager.getVehiclePoint()
    local vehicle=GPSVehicleDetector.getCurrentVehicle()
    local node=vehicle and GPSVehicleDetector.getPositionNode(vehicle)
    if not node then return nil,"Kein Fahrzeug" end
    local x,y,z=getWorldTranslation(node)
    if type(x)~="number" or type(z)~="number" then return nil,"Keine Position" end
    return {x=x,z=z},nil
end
-- Single-key course setup: capture A and the current tractor heading in one go.
-- B is an INTERNAL direction reference, not a second user-defined waypoint.
-- All existing guidance, lane, steering and savegame code can keep using A/B.
function GPSABLineManager.setA()
    local vehicle=GPSVehicleDetector.getCurrentVehicle()
    local node=vehicle and GPSVehicleDetector.getPositionNode(vehicle)
    if not node or type(getWorldTranslation)~="function" or type(localDirectionToWorld)~="function" then
        return "GPS A: Fahrzeugposition/-richtung nicht verfuegbar"
    end
    local x,_,z=getWorldTranslation(node)
    local dx,_,dz=localDirectionToWorld(node,0,0,1)
    if type(x)~="number" or type(z)~="number" or
       type(dx)~="number" or type(dz)~="number" then
        return "GPS A: Fahrzeugposition/-richtung ungueltig"
    end
    local len=math.sqrt(dx*dx+dz*dz)
    if len<0.5 then return "GPS A: Fahrzeugrichtung nicht messbar" end
    local ax,az=x,z
    local bx,bz=x+dx/len*30,z+dz/len*30
    -- Replace geometry atomically to avoid a frame with A but without B.
    GPSABLineManager.a={x=ax,z=az}
    GPSABLineManager.b={x=bx,z=bz}
    GPSABLineManager.offsetMeters=0
    GPSABLineManager.singlePointMode=true
    local angle=(math.deg(math.atan2(bx-ax,bz-az))+360)%360
    return string.format("GPS A gesetzt: %.1f / %.1f | Fahrtrichtung %.2f Grad (B intern)",ax,az,angle)
end
function GPSABLineManager.setB()
    if not GPSABLineManager.a then return "GPS B: Zuerst A setzen" end
    local p,errorText=GPSABLineManager.getVehiclePoint()
    if not p then return "GPS B: "..errorText end
    local dx=p.x-GPSABLineManager.a.x;local dz=p.z-GPSABLineManager.a.z
    if dx*dx+dz*dz<(GPSABLineManager.minDistance or 20)^2 then return "GPS B: Mindestens 20 Meter Luftlinie zu A" end
    GPSABLineManager.b=p
    GPSABLineManager.offsetMeters=0
    GPSABLineManager.singlePointMode=false
    return string.format("GPS B gesetzt: %.1f / %.1f",p.x,p.z)
end

-- Shift an established A/B guidance line, keeping the heading unchanged.
-- Positive steps move toward the vehicle's right relative to A->B.
function GPSABLineManager.shift(direction,meters)
    local a,b=GPSABLineManager.a,GPSABLineManager.b
    if not a or not b then return false,"GPS Verschieben: Zuerst Punkt A setzen" end
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
