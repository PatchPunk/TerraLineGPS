-- Experimental SP/MP compensation for asymmetric implements.
-- In MP this works on the local driver's steering target; real two-player
-- operation and implement geometry replication still require an in-game test.
-- The saved A/B work center, work-width borders and manual course shift
-- MUST NOT move. Only the tractor's steering target is displaced by the
-- measured work-center offset. OFF by default; measurement only at rest.
GPSDeviceOffsetAuto={enabled=false,center=nil,ready=false,lastA=nil,lastB=nil,
    lastVehicle=nil,candidate=nil,candidateCount=0,lastStatus="Aus",clock=0}
local D=GPSDeviceOffsetAuto
local function clearMeasurement()
    D.center=nil;D.ready=false;D.candidate=nil;D.candidateCount=0
    D.workMinX=nil;D.workMaxX=nil;D.workWidth=nil;D.comboKey=nil
end
function D.reset()
    D.enabled=false;D.lastA=nil;D.lastB=nil;D.lastVehicle=nil
    D.clock=0;D.lastStatus="Aus"
    clearMeasurement()
end
-- Manual mirroring or A/B exchange may reverse the course direction.
-- Work-center geometry is not a stored A/B shift: never negate it or move A/B.
function D.onCourseMirrored()
    clearMeasurement()
    D.lastA=nil;D.lastB=nil;D.clock=1000
    if D.enabled then D.lastStatus="Kurs geaendert: erneut im Stillstand messen" end
end
function D.getCorrection(vehicle,dir)
    if not D.enabled then return 0 end
    if not D.ready or vehicle~=D.lastVehicle or
        D.lastA~=GPSABLineManager.a or D.lastB~=GPSABLineManager.b then
        return nil
    end
    if dir~=1 and dir~=-1 then return nil end
    -- A manual width change or newly measured mower combination must not
    -- reuse the earlier automatic steering correction.
    if type(D.workWidth)=="number" and GPSImplementDetector and
        math.abs(GPSImplementDetector.getWidth(vehicle)-D.workWidth)>0.05 then
        return nil
    end
    if D.comboKey~=nil and GPSImplementDetector.comboKey~=D.comboKey then
        return nil
    end
    -- A/B normal (-uz,+ux) points LEFT. Measured tractor-local x points
    -- RIGHT. Thus tractor target in A/B-normal coordinates = center*dir.
    return D.center*dir
end
-- Return geometry in tractor-local X only when the SAME measurement is valid
-- for steering, vehicle and A/B pair. Do not re-sample moving implements in draw().
function D.getWorkEdges(vehicle,dir)
    if D.getCorrection(vehicle,dir)==nil or not D.enabled then return nil end
    local lo,hi=D.workMinX,D.workMaxX
    if type(lo)~="number" or type(hi)~="number" or
        lo~=lo or hi~=hi or hi-lo<0.5 then return nil end
    return lo,hi
end
function D.setEnabled(state)
    if GPSSteeringController and GPSSteeringController.enabled then
        return false,"Geraete-Auto: GPS-Lenkung vorher ausschalten"
    end
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    local speed=vehicle and type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    if speed>2 then return false,"Geraete-Auto: Zum Umschalten anhalten" end
    if state then
        if not vehicle then return false,"Geraete-Auto: Traktor fehlt" end
        -- MP clients may enable auto-offset only in their locally driven tractor.
        -- Server-side geometry is not guessed or synchronized by this toggle.
        if g_client~=nil and g_server==nil and
            (vehicle.isClient~=true or vehicle.spec_drivable==nil or
             (type(vehicle.getIsEntered)=="function" and not vehicle:getIsEntered())) then
            return false,"Geraete-Auto: Im MP nur im selbst gefahrenen Traktor"
        end
        if not GPSABLineManager.a or not GPSABLineManager.b then
            return false,"Geraete-Auto: Zuerst A/B erstellen"
        end
    end
    D.enabled=state==true
    clearMeasurement()
    D.lastA=GPSABLineManager.a;D.lastB=GPSABLineManager.b
    D.lastVehicle=vehicle
    D.clock=1000
    D.lastStatus=D.enabled and "Messung abwarten: anhalten, GPS aus" or "Aus"
    if GPSLogger then GPSLogger.info("Geraete-Auto "..(D.enabled and "AN (Lenkziel, A/B unveraendert)" or "AUS (kein gespeicherter Kursversatz)")) end
    return true,D.enabled and "Geraete-Auto AN: Arbeitsmitte wird gemessen" or "Geraete-Auto AUS: Normaler GPS-Modus"
end
function D.update(dt,vehicle)
    if not D.enabled then return end
    local a,b=GPSABLineManager.a,GPSABLineManager.b
    if a~=D.lastA or b~=D.lastB or vehicle~=D.lastVehicle then
        D.lastA=a;D.lastB=b;D.lastVehicle=vehicle
        clearMeasurement()
        D.clock=1000
    end
    if not a or not b or not vehicle then D.lastStatus="A/B oder Traktor fehlt";return end
    -- Never change a locked steering target while GPS is active or moving.
    if GPSSteeringController and GPSSteeringController.enabled then return end
    local speed=type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    if speed>2 then D.lastStatus="Zum Einmessen anhalten";return end
    D.clock=(D.clock or 0)+math.max(0,dt or 0)
    if D.clock<900 then return end
    D.clock=0
    local node=GPSVehicleDetector.getPositionNode(vehicle)
    if not node then D.lastStatus="Traktorkoordinaten fehlen";return end
    local fx,_,fz=localDirectionToWorld(node,0,0,1)
    local dx,dz=b.x-a.x,b.z-a.z
    local length=math.sqrt(dx*dx+dz*dz)
    if length<10 then D.lastStatus="A/B zu kurz";return end
    local alignment=(fx*dx+fz*dz)/length
    if math.abs(alignment)<0.90 then D.lastStatus="Traktor parallel zu A/B ausrichten";return end
    local isCombo,comboReady,comboLo,comboHi,comboWidth,comboReason,comboKey=
        GPSImplementDetector.getVerifiedMowerCombo(vehicle)
    if isCombo and not comboReady then
        D.lastStatus="Maehwerk-Kombi: "..tostring(comboReason)
        clearMeasurement()
        return
    end
    -- getData uses the verified WorkArea span for stable mower combinations.
    -- Preserve the previous AI-marker path for single implements.
    local center,desc,complete,lo,hi=GPSDeviceOffsetProbe.getData(vehicle)
    if type(center)~="number" or center~=center then
        D.lastStatus="Keine Geraetegeometrie erkannt";clearMeasurement();return
    end
    local width=GPSImplementDetector.getWidth(vehicle)
    if not complete or type(width)~="number" or width<0.5 or
        type(lo)~="number" or type(hi)~="number" or
        lo~=lo or hi~=hi or hi-lo<0.5 then
        D.lastStatus="Arbeitsbreite/Arbeitskanten nicht sicher erkannt";clearMeasurement();return
    end
    if not isCombo and math.abs((hi-lo)-width)>math.max(0.08,width*0.02) then
        -- A second work object must not widen the measured steering center
        -- beyond the effective lane width (e.g. an unrecognized plough packer).
        D.lastStatus="Arbeitskanten passen nicht zur GPS-Arbeitsbreite"
        clearMeasurement()
        return
    end
    if isCombo then
        -- These must describe the SAME unfolded geometry. In Phase 7 the
        -- effective width could still be 6.30 m while the edges spanned
        -- only 4.07 m; this is no longer a permissible steering reference.
        if math.abs(width-comboWidth)>0.06 or
            math.abs(hi-lo-comboWidth)>0.06 or
            math.abs(lo-comboLo)>0.06 or math.abs(hi-comboHi)>0.06 or
            math.abs(center-(lo+hi)*0.5)>0.04 then
            D.lastStatus="Maehwerk-Kombi: Breite und Arbeitskanten widersprechen sich"
            clearMeasurement()
            return
        end
    end
    -- Only near-center work offsets; in particular allow the 1.67m mower
    -- measurement previously refused by the hardcoded 1.50m limit.
    local maximum=math.min(3.0,math.max(0,width*.5-.10))
    if math.abs(center)>maximum then
        D.lastStatus=string.format("Arbeitsmitte %+.2fm ausserhalb sicherer Grenze %.2fm",center,maximum)
        clearMeasurement();return
    end
    local sample=D.candidate
    if type(sample)=="table" and sample.key==comboKey and
        math.abs(sample.center-center)<0.04 and
        math.abs(sample.lo-lo)<0.04 and math.abs(sample.hi-hi)<0.04 and
        math.abs(sample.width-width)<0.04 then
        D.candidateCount=D.candidateCount+1
    else
        D.candidate={center=center,lo=lo,hi=hi,width=width,key=comboKey}
        D.candidateCount=1
        -- Revoke the old release immediately if the geometry changes.
        D.center=nil;D.ready=false;D.workMinX=nil;D.workMaxX=nil
        D.workWidth=nil;D.comboKey=nil
    end
    if D.candidateCount<3 then
        D.lastStatus=string.format("Arbeitsgeometrie stabilisieren (%d/3)",D.candidateCount)
        return
    end
    local previous=D.center
    D.center=center;D.workMinX=lo;D.workMaxX=hi;D.workWidth=width
    D.comboKey=comboKey;D.ready=true
    D.lastStatus=string.format("Bereit: Geraetemitte %+.2fm, Traktorversatz automatisch",center)
    if previous==nil or math.abs(previous-center)>0.03 then
        GPSLogger.info(string.format("Geraete-Auto BEREIT: Mitte=%+.2fm, Breite=%.2fm, Arbeitskanten=%+.2f..%+.2fm, Markersicher=%s | A/B unveraendert",center,width,lo,hi,tostring(complete)))
    end
end
