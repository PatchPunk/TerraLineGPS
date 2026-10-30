-- Work width diagnosis: never present fallback as an automatic measurement.
GPSImplementDetector = {override=nil, lastSignature=nil}
local function valid(w) return type(w)=="number" and w>=0.5 and w<=60 and w==w end
local function displayName(o)
    if o and type(o.getName)=="function" then
        local v=o:getName(); if type(v)=="string" and #v>0 then return v end
    end
    return "Unbekanntes Geraet"
end
local function aiWidth(o)
    if type(o.updateAIMarkerWidth)=="function" then o:updateAIMarkerWidth() end
    if type(o.getAIMarkers)=="function" then
        local l,r,b,inverted,w=o:getAIMarkers()
        if l and r and valid(w) then return w,"AI-Marker" end
        if type(l)=="number" and l>0 and type(r)=="number" and r>0
                and type(o.rootNode)=="number" and o.rootNode>0
                and type(localToLocal)=="function" then
            local x1=localToLocal(l,o.rootNode,0,0,0)
            local x2=localToLocal(r,o.rootNode,0,0,0)
            if type(x1)=="number" and type(x2)=="number" and valid(math.abs(x1-x2)) then
                return math.abs(x1-x2),"AI-Marker-Koordinaten"
            end
        end
    end
end
local function workAreaWidth(o)
    if type(o.getWorkAreaByIndex)~="function" or not o.rootNode or type(localToLocal)~="function" then return nil end
    local minX,maxX=math.huge,-math.huge
    for i=1,128 do
        local wa=o:getWorkAreaByIndex(i)
        if type(wa)~="table" then break end
        if type(wa.start)=="number" and wa.start>0
                and type(wa.width)=="number" and wa.width>0 then
            local left=localToLocal(wa.start,o.rootNode,0,0,0)
            local right=localToLocal(wa.width,o.rootNode,0,0,0)
            if type(left)=="number" and type(right)=="number" then
                minX=math.min(minX,left,right);maxX=math.max(maxX,left,right)
            end
        end
    end
    local width=maxX-minX
    if valid(width) then return width,"Arbeitsbereich" end
end
local function probe(o)
    if o==nil then return nil end
    local width,src=aiWidth(o)
    if width then return width,src end
    for _,method in ipairs({"getWorkingWidth","getWorkWidth","getAIMarkersWidth"}) do
        if type(o[method])=="function" then
            local w=o[method](o)
            if valid(w) then return w,method end
        end
    end
    width,src=workAreaWidth(o)
    if width then return width,src end
    if o.spec_workArea and valid(o.spec_workArea.workWidth) then return o.spec_workArea.workWidth,"spec_workArea" end
end
local function collect(o,items,seen,depth)
    if not o or seen[o] or depth>8 then return end
    seen[o]=true
    if depth>0 then items[#items+1]=o end
    if type(o.getAttachedImplements)=="function" then
        local attached=o:getAttachedImplements()
        if type(attached)=="table" then
            for _,entry in pairs(attached) do
                if type(entry)=="table" then collect(entry.object,items,seen,depth+1) end
            end
        end
    end
end

-- Multi-mower width: USE ONLY vetted WorkAreaType.MOWER geometry.
-- Single implements and all other combinations retain the old detector.
-- A candidate becomes active only while stopped with GPS steering OFF.
-- During travel/steering the last accepted width is frozen.
GPSImplementDetector.comboVehicle=nil
GPSImplementDetector.comboWidth=nil
GPSImplementDetector.comboName=nil
GPSImplementDetector.comboMinX=nil
GPSImplementDetector.comboMaxX=nil
GPSImplementDetector.comboKey=nil
GPSImplementDetector.comboSample=nil
GPSImplementDetector.comboStable=0
GPSImplementDetector.comboClock=0
GPSImplementDetector.comboLastStatus=nil

function GPSImplementDetector.resetCombo()
    local d=GPSImplementDetector
    d.comboVehicle=nil;d.comboWidth=nil;d.comboName=nil
    d.comboMinX=nil;d.comboMaxX=nil;d.comboKey=nil
    d.comboSample=nil;d.comboStable=0;d.comboClock=0;d.comboLastStatus=nil
end

local function mowerArea(area,obj)
    if type(area)~="table" then return false end
    if type(WorkAreaType)=="table" and WorkAreaType.MOWER~=nil and area.type==WorkAreaType.MOWER then
        return true
    end
    -- The mower specialization exposes its own, engine-classified area list.
    local known=obj.spec_mower and obj.spec_mower.workAreas
    if type(known)=="table" then
        for _,entry in pairs(known) do
            if entry==area then return true end
        end
    end
    return false
end
local function localX(node,root)
    if node==nil or root==nil or type(localToLocal)~="function" then return nil end
    if type(node)~="number" or node<=0 or type(root)~="number" or root<=0 then return nil end
    local x=localToLocal(node,root,0,0,0)
    if type(x)=="number" and x==x and math.abs(x)<100 then return x end
    return nil
end
local function measureMowers(vehicle)
    if vehicle==nil or GPSVehicleDetector==nil or type(GPSVehicleDetector.getPositionNode)~="function" then
        return nil,"Keine Traktormessbasis"
    end
    local root=GPSVehicleDetector.getPositionNode(vehicle)
    if root==nil then return nil,"Keine Traktormessbasis" end
    local items={};collect(vehicle,items,{},0)
    items=GPSAttachmentClassifier.filterForGPS(items)
    if #items<2 then return nil,"Weniger als zwei Geraete" end
    local ranges,labels,identities={},{},{}
    for _,obj in ipairs(items) do
        if obj.spec_mower==nil or type(obj.getWorkAreaByIndex)~="function" then
            return nil,"Nicht ausschliesslich Maehwerke"
        end
        if obj.spec_foldable~=nil then
            if type(obj.getIsUnfolded)~="function" then return nil,"Klappzustand unbekannt" end
            local unfolded=obj:getIsUnfolded()
            if unfolded~=true then return nil,"Maehwerk nicht ausgeklappt" end
        end
        local count=0
        for i=1,128 do
            local area=obj:getWorkAreaByIndex(i)
            if type(area)~="table" then break end
            if mowerArea(area,obj) and area.start~=nil and area.width~=nil then
                local a,b=localX(area.start,root),localX(area.width,root)
                if a==nil or b==nil or math.abs(a-b)<0.20 then
                    return nil,"Ungueltige Maeh-WorkArea"
                end
                ranges[#ranges+1]={math.min(a,b),math.max(a,b)}
                count=count+1
            end
        end
        if count==0 then return nil,"Maeh-WorkArea fehlt" end
        labels[#labels+1]=displayName(obj)
        identities[#identities+1]=tostring(obj)
    end
    table.sort(identities)
    table.sort(labels)
    table.sort(ranges,function(a,b) return a[1]<b[1] end)
    local left,right=ranges[1][1],ranges[1][2]
    for i=2,#ranges do
        local a,b=ranges[i][1],ranges[i][2]
        -- More than two detached cutting strips: do not silently use their
        -- outer span as an effective lane width.
        if a>right+0.02 then return nil,"Luecke zwischen Maehbereichen" end
        right=math.max(right,b)
    end
    local width=right-left
    if not valid(width) then return nil,"Gesamtbreite unplausibel" end
    return width,table.concat(labels," + "),string.format("%+.2f..%+.2fm",left,right),
        left,right,table.concat(identities,"|")
end

-- Read-only validation for the offset-auto routine. A multi-mower combination
-- must use the same, already stabilized WorkArea snapshot as lane generation.
-- Do not silently fall back to a single mower's width during calibration.
function GPSImplementDetector.getVerifiedMowerCombo(vehicle)
    if vehicle==nil then return false end
    local items={};collect(vehicle,items,{},0)
    items=GPSAttachmentClassifier.filterForGPS(items)
    if #items<2 then return false end
    for _,obj in ipairs(items) do
        if obj.spec_mower==nil then return false end
    end
    local d=GPSImplementDetector
    if d.comboVehicle~=vehicle or not valid(d.comboWidth) or
        type(d.comboMinX)~="number" or type(d.comboMaxX)~="number" or
        type(d.comboKey)~="string" then
        return true,false,nil,nil,nil,"Gesamtbreite noch nicht stabil"
    end
    -- Recheck actual geometry, including unfolding and gaps, rather than
    -- trusting a previously accepted snapshot after a device transition.
    local liveWidth,reason,_,liveLo,liveHi,liveKey=measureMowers(vehicle)
    if not valid(liveWidth) or liveKey~=d.comboKey or
        math.abs(liveWidth-d.comboWidth)>0.04 or
        math.abs(liveLo-d.comboMinX)>0.04 or
        math.abs(liveHi-d.comboMaxX)>0.04 then
        return true,false,nil,nil,nil,"Geometrie geaendert: "..tostring(reason)
    end
    return true,true,d.comboMinX,d.comboMaxX,d.comboWidth,"Bereit",d.comboKey
end

function GPSImplementDetector.update(dt,vehicle)
    local d=GPSImplementDetector
    if d.comboVehicle~=vehicle then d.resetCombo();d.comboVehicle=vehicle end
    if vehicle==nil or valid(d.override) then return end
    -- MP: measure the current driver's LOCAL implement work areas as in SP.
    -- Only accept a stabilized geometry while stopped and steering OFF;
    -- no server-wide course data or remote vehicle state are modified.
    if GPSSteeringController and GPSSteeringController.enabled then return end
    if type(vehicle.getLastSpeed)~="function" then return end
    local speed=vehicle:getLastSpeed()
    if type(speed)~="number" or math.abs(speed)>0.5 then return end
    d.comboClock=(d.comboClock or 0)+math.max(0,dt or 0)
    if d.comboClock<600 then return end
    d.comboClock=0
    local width,name,edges,lo,hi,key=measureMowers(vehicle)
    if not valid(width) then
        if d.comboWidth~=nil and GPSLogger then
            GPSLogger.info("AUTO-GESAMTBREITE: Kombimessung ungueltig ("..tostring(name).."); Einzelgeraete-Erkennung aktiv")
        end
        d.comboWidth=nil;d.comboName=nil;d.comboMinX=nil;d.comboMaxX=nil;d.comboKey=nil
        d.comboSample=nil;d.comboStable=0
        return
    end
    -- Stability includes both edges and the device identity, not just width.
    -- Equal widths from changed/rotating mower geometry must not pass.
    local sample=d.comboSample
    if type(sample)=="table" and sample.key==key and
        math.abs(sample.width-width)<0.03 and
        math.abs(sample.lo-lo)<0.03 and math.abs(sample.hi-hi)<0.03 then
        d.comboStable=d.comboStable+1
    else
        d.comboSample={width=width,lo=lo,hi=hi,key=key}
        d.comboStable=1
    end
    if d.comboStable<3 then
        -- Remove stale geometry immediately rather than reusing it while a
        -- different attachment is being unfolded or newly attached.
        d.comboWidth=nil;d.comboName=nil;d.comboMinX=nil;d.comboMaxX=nil;d.comboKey=nil
        return
    end
    if d.comboWidth==nil or math.abs(d.comboWidth-width)>0.03 or
        d.comboName~=name or d.comboKey~=key or
        math.abs(d.comboMinX-lo)>0.03 or math.abs(d.comboMaxX-hi)>0.03 then
        d.comboWidth=width;d.comboName=name
        d.comboMinX=lo;d.comboMaxX=hi;d.comboKey=key
        d.lastSignature=nil
        if GPSLogger then GPSLogger.info(string.format(
            "AUTO-GESAMTBREITE BEREIT: %.2fm | %s | Arbeitskanten %s | bei Stillstand eingemessen",
            width,name,tostring(edges))) end
    end
end

function GPSImplementDetector.getData(vehicle)
    if valid(GPSImplementDetector.override) then
        return GPSImplementDetector.override,"Manuell","Manuelle Vorgabe",true
    end
    if vehicle~=nil and GPSImplementDetector.comboVehicle==vehicle and
       valid(GPSImplementDetector.comboWidth) then
        return GPSImplementDetector.comboWidth,"Maehwerk-Kombination (WorkAreas)",
            GPSImplementDetector.comboName or "Maehwerk-Kombination",true
    end
    local items={};collect(vehicle,items,{},0)
    items=GPSAttachmentClassifier.filterForGPS(items)
    local bestW,bestSrc,bestName=nil,nil,nil
    for _,obj in ipairs(items) do
        local w,src=probe(obj)
        if w and (not bestW or w>bestW) then bestW=w;bestSrc=src;bestName=displayName(obj) end
    end
    if bestW then return bestW,bestSrc,bestName,true end
    local name=items[1] and displayName(items[1]) or "Kein Anbaugeraet"
    return GPSConfig.defaultWorkWidth,"Standardwert - NICHT erkannt",name,false
end
function GPSImplementDetector.getWidth(vehicle)
    local width,src=GPSImplementDetector.getData(vehicle)
    return width,src
end
function GPSImplementDetector.logIfChanged(vehicle)
    local w,src,name,detected=GPSImplementDetector.getData(vehicle)
    local signature=string.format("%s|%.2f|%s|%s",name,w,src,tostring(detected))
    if signature~=GPSImplementDetector.lastSignature then
        GPSImplementDetector.lastSignature=signature
        GPSLogger.info(string.format("Anbaugeraet: %s | Breite %.2fm | Quelle: %s | erkannt=%s",name,w,src,tostring(detected)))
    end
end
