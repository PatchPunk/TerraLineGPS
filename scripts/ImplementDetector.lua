-- Work width diagnosis: never present fallback as an automatic measurement.
GPSImplementDetector = {override=nil, lastSignature=nil}
local function valid(w) return type(w)=="number" and w>=0.5 and w<=60 and w==w end
local function displayName(o)
    if o and type(o.getName)=="function" then
        local ok,v=pcall(o.getName,o); if ok and type(v)=="string" and #v>0 then return v end
    end
    return "Unbekanntes Geraet"
end
local function aiWidth(o)
    if type(o.updateAIMarkerWidth)=="function" then pcall(o.updateAIMarkerWidth,o) end
    if type(o.getAIMarkers)=="function" then
        local ok,l,r,b,inverted,w=pcall(o.getAIMarkers,o)
        if ok and l and r and valid(w) then return w,"AI-Marker" end
        if ok and l and r and type(localToLocal)=="function" and o.rootNode then
            local ok2,x1,x2=pcall(function()
                local a=localToLocal(l,o.rootNode,0,0,0)
                local c=localToLocal(r,o.rootNode,0,0,0)
                return a,c
            end)
            if ok2 and valid(math.abs(x1-x2)) then return math.abs(x1-x2),"AI-Marker-Koordinaten" end
        end
    end
end
local function workAreaWidth(o)
    if type(o.getWorkAreaByIndex)~="function" or not o.rootNode or type(localToLocal)~="function" then return nil end
    local minX,maxX=math.huge,-math.huge
    for i=1,128 do
        local ok,wa=pcall(o.getWorkAreaByIndex,o,i)
        if not ok or not wa then break end
        if wa.start and wa.width then
            local sOk,left,right=pcall(function()
                local lx=localToLocal(wa.start,o.rootNode,0,0,0)
                local rx=localToLocal(wa.width,o.rootNode,0,0,0)
                return lx,rx
            end)
            if sOk then minX=math.min(minX,left,right);maxX=math.max(maxX,left,right) end
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
            local ok,w=pcall(o[method],o)
            if ok and valid(w) then return w,method end
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
        local ok,attached=pcall(o.getAttachedImplements,o)
        if ok and type(attached)=="table" then
            for _,entry in pairs(attached) do
                if type(entry)=="table" then collect(entry.object,items,seen,depth+1) end
            end
        end
    end
end
function GPSImplementDetector.getData(vehicle)
    if valid(GPSImplementDetector.override) then
        return GPSImplementDetector.override,"Manuell","Manuelle Vorgabe",true
    end
    local items={};collect(vehicle,items,{},0)
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
