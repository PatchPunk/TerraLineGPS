-- Diagnostic groundwork for automatic implement offset. Does not affect
-- steering or A/B positions until supported implement geometries are tested.
GPSDeviceOffsetProbe={lastSignature=nil,clock=0}
local function xyz(node,root)
    if type(node)~="number" or node<=0 or type(root)~="number" or root<=0 or type(localToLocal)~="function" then return nil end
    local x=localToLocal(node,root,0,0,0)
    if type(x)=="number" and x==x and math.abs(x)<100 then return x end
    return nil
end
local function visit(object,items,seen,level)
    if not object or seen[object] or level>6 then return end
    seen[object]=true
    if level>0 then items[#items+1]=object end
    if type(object.getAttachedImplements)=="function" then
        local arr=object:getAttachedImplements()
        if type(arr)=="table" then
            for _,v in pairs(arr) do
                if type(v)=="table" then visit(v.object,items,seen,level+1) end
            end
        end
    end
end
local function relevantItems(items,tractorNode)
    return GPSAttachmentClassifier.filterForGPS(items,tractorNode)
end
local function ignoredCounts(ignored)
    local weights,packers=0,0
    for _,entry in ipairs(ignored) do
        if entry.kind=="Packer" then packers=packers+1 else weights=weights+1 end
    end
    return weights,packers
end
local function findSpan(object,tractorNode)
    -- Prefer live AI marker positions (follow moving / pivoting tools).
    if type(object.getAIMarkers)=="function" then
        local l,r=object:getAIMarkers()
        if l and r then
            local lx,rx=xyz(l,tractorNode),xyz(r,tractorNode)
            if lx and rx and math.abs(lx-rx)>=0.5 then
                return math.min(lx,rx),math.max(lx,rx),"AI-Marker"
            end
        end
    end
    local lo,hi=math.huge,-math.huge
    if type(object.getWorkAreaByIndex)=="function" then
        for i=1,128 do
            local wa=object:getWorkAreaByIndex(i)
            if not wa then break end
            if wa.start and wa.width then
                local lx,rx=xyz(wa.start,tractorNode),xyz(wa.width,tractorNode)
                if lx and rx then lo=math.min(lo,lx,rx);hi=math.max(hi,lx,rx) end
            end
        end
        if hi>lo and hi-lo>=0.5 then return lo,hi,"WorkArea" end
    end
    return nil
end
function GPSDeviceOffsetProbe.getData(vehicle)
    local node=vehicle and GPSVehicleDetector.getPositionNode(vehicle)
    if not node then return nil,"Kein Traktor" end
    -- A recognized mower combination MUST use one authoritative geometry
    -- snapshot for both total lane width and the steering-offset correction.
    -- AI markers and live WorkAreas may disagree on pivoting side mowers.
    -- Never report a guessed offset while the combination is not verified.
    if GPSImplementDetector and type(GPSImplementDetector.getVerifiedMowerCombo)=="function" then
        local isCombo,ready,lo,hi,width,reason=
            GPSImplementDetector.getVerifiedMowerCombo(vehicle)
        if isCombo then
            if ready and type(lo)=="number" and type(hi)=="number" and
                    type(width)=="number" and hi-lo>=0.5 and
                    math.abs((hi-lo)-width)<=0.06 then
                local center=(lo+hi)*0.5
                return center,string.format(
                    "Maehwerk-Kombi WorkAreas: L=%+.2fm R=%+.2fm Mitte=%+.2fm Breite=%.2fm",
                    lo,hi,center,width),true,lo,hi
            end
            return nil,"Maehwerk-Kombi nicht stabil: "..tostring(reason),false
        end
    end
    local attached={};visit(vehicle,attached,{},0)
    local items,ignored=relevantItems(attached,node)
    if #items==0 then
        return nil,#ignored>0 and "Kein GPS-Arbeitsgeraet (nur ausgeschlossene Anbauten)" or "Kein Arbeitsgeraet"
    end
    local lo,hi=math.huge,-math.huge
    local sources={};local included=0
    for _,obj in ipairs(items) do
        local l,r,source=findSpan(obj,node)
        if l and r then
            lo=math.min(lo,l);hi=math.max(hi,r)
            sources[source]=true;included=included+1
        end
    end
    if included==0 or lo>=hi then return nil,"Keine geeigneten Marker/Arbeitsbereiche" end
    local center=(lo+hi)*0.5
    local weights,packers=ignoredCounts(ignored)
    local desc=string.format("Arbeitskanten L=%+.2fm R=%+.2fm, Mitte=%+.2fm aus Traktorsicht | %d von %d Arbeitsgeraeten | %s | %d Gewichte, %d Packer ignoriert",
        lo,hi,center,included,#items,sources["AI-Marker"] and "AI-Marker" or "WorkArea",weights,packers)
    -- Extra return values expose the SAME physical bounds used to calculate
    -- center. Old callers accepting only three values remain compatible.
    return center,desc,(included==#items),lo,hi
end
function GPSDeviceOffsetProbe.update(dt,vehicle)
    local self=GPSDeviceOffsetProbe
    self.clock=(self.clock or 0)+(dt or 0)
    if self.clock<2000 then return end
    self.clock=0
    local val,desc,complete=self.getData(vehicle)
    self.lastValue=val
    self.lastDesc=desc
    self.lastComplete=complete
    local signature=string.format("%s|%s|%s",val and string.format("%.2f",val) or "-",desc or "-",tostring(complete))
    if signature~=self.lastSignature then
        self.lastSignature=signature
        GPSLogger.debug("Geraeteversatz (nur Messung): "..tostring(desc).." | sicher="..tostring(complete))
    end
end

-- On-demand ONLY: inspect separate physical work areas on all attached
-- implements. Logging has no effect on GPS steering, A/B points, width,
-- user settings, net state or stored course data.
local function widthDiagName(obj)
    if obj and type(obj.getName)=="function" then
        local name=obj:getName()
        if type(name)=="string" and name~="" then return name end
    end
    return "Unbekannt"
end
local function widthDiagValid(a,b)
    return type(a)=="number" and type(b)=="number" and
        a==a and b==b and math.abs(a)<100 and math.abs(b)<100 and
        math.abs(b-a)>=0.20
end
local function widthDiagMerge(ranges)
    table.sort(ranges,function(a,b) return a[1]<b[1] end)
    local merged={}
    for _,range in ipairs(ranges) do
        local previous=merged[#merged]
        if previous and range[1]<=previous[2]+0.001 then
            previous[2]=math.max(previous[2],range[2])
        else
            merged[#merged+1]={range[1],range[2]}
        end
    end
    local union=0
    for _,range in ipairs(merged) do union=union+range[2]-range[1] end
    return merged,union
end
local function widthDiagIntervals(obj,root)
    local areas={}
    if type(obj.getWorkAreaByIndex)=="function" then
        for i=1,128 do
            local area=obj:getWorkAreaByIndex(i)
            if type(area)~="table" then break end
            if area.start and area.width then
                local l,r=xyz(area.start,root),xyz(area.width,root)
                if widthDiagValid(l,r) then
                    areas[#areas+1]={math.min(l,r),math.max(l,r)}
                end
            end
        end
    end
    return areas
end
local function widthDiagMarker(obj,root)
    if type(obj.getAIMarkers)~="function" then return nil end
    local left,right=obj:getAIMarkers()
    if not left or not right then return nil end
    local l,r=xyz(left,root),xyz(right,root)
    if not widthDiagValid(l,r) then return nil end
    return {math.min(l,r),math.max(l,r)}
end
local function widthDiagFormat(ranges)
    if #ranges==0 then return "keine" end
    local strings={}
    for _,span in ipairs(ranges) do
        strings[#strings+1]=string.format("[%+.2f..%+.2f]",span[1],span[2])
    end
    return table.concat(strings," ")
end
function GPSDeviceOffsetProbe.logWidthDiagnostic(vehicle)
    if not GPSLogger or type(GPSLogger.force)~="function" then
        return "TerraLine: Diagnose-Logger fehlt"
    end
    local node=vehicle and GPSVehicleDetector and
        GPSVehicleDetector.getPositionNode and GPSVehicleDetector.getPositionNode(vehicle)
    if not node then
        GPSLogger.force("BREITENDIAG: Kein aktiver Traktor mit Positionsnode")
        return "BREITENDIAG: Kein aktiver Traktor"
    end
    local objects={};visit(vehicle,objects,{},0)
    GPSLogger.force(string.format("BREITENDIAG START | angehaengte Objekte=%d | Messbasis: Traktor-Lokal-X in Metern",#objects))
    if #objects==0 then
        GPSLogger.force("BREITENDIAG ENDE | Keine Anbaugeraete")
        return "BREITENDIAG: Keine Anbaugeraete"
    end
    local unionCandidates={}
    local _,ignored=relevantItems(objects,node)
    local ignoredMap={}
    for _,entry in ipairs(ignored) do ignoredMap[entry.object]=entry end
    local deviceCount,workingCount,weightCount,packerCount=0,0,0,0
    for index,obj in ipairs(objects) do
        local _,position,name,category,vehicleType=GPSAttachmentClassifier.classify(obj,node)
        local excluded=ignoredMap[obj]
        GPSLogger.force(string.format("BREITENDIAG ANBAU %d/%d | %s | Position=%s | Klasse=%s | Shop=%s | Typ=%s",
            index,#objects,name,position,excluded and excluded.kind or "Arbeitsgeraet/ungeklaert",tostring(category),tostring(vehicleType)))
        if excluded then
            if excluded.kind=="Packer" then packerCount=packerCount+1 else weightCount=weightCount+1 end
            GPSLogger.force(string.format("BREITENDIAG AUSGEKLAMMERT %d | %s (%s) | %s, Grund=%s",
                index,name,position,excluded.kind,excluded.reason))
        else
            workingCount=workingCount+1
            local marker=widthDiagMarker(obj,node)
            local areas=widthDiagIntervals(obj,node)
            local mergedWork,workUnion=widthDiagMerge(areas)
            GPSLogger.force(string.format("BREITENDIAG GERAET %d/%d | %s | AI-Marker=%s | WorkAreas=%d | Arbeitsbereich-Union=%.2fm",
                index,#objects,name,marker and widthDiagFormat({marker}) or "keine",#areas,workUnion))
            if #areas>0 then
                GPSLogger.force("BREITENDIAG BEREICHE "..index.." | "..widthDiagFormat(mergedWork))
                for _,range in ipairs(mergedWork) do unionCandidates[#unionCandidates+1]={range[1],range[2]} end
                deviceCount=deviceCount+1
            elseif marker then
                GPSLogger.force("BREITENDIAG ERSATZ "..index.." | Keine WorkArea; AI-Marker als Naeherung")
                unionCandidates[#unionCandidates+1]={marker[1],marker[2]}
                deviceCount=deviceCount+1
            else
                GPSLogger.force("BREITENDIAG NICHT ERKANNT "..index.." | kein gueltiger Arbeitsbereich/Marker")
            end
        end
    end
    local merged,total=widthDiagMerge(unionCandidates)
    local span=(#merged>0) and merged[#merged][2]-merged[1][1] or 0
    local currentWidth,currentSource,currentName,currentDetected=nil,nil,nil,false
    if GPSImplementDetector and GPSImplementDetector.getData then
        currentWidth,currentSource,currentName,currentDetected=GPSImplementDetector.getData(vehicle)
    end
    GPSLogger.force(string.format("BREITENDIAG SUMME | erkannt=%d/%d Arbeitsgeraete | Gewichte ignoriert=%d | Packer ignoriert=%d | Union=%.2fm | Aeussere-Spannweite=%.2fm | Bereiche=%s",
        deviceCount,workingCount,weightCount,packerCount,total,span,widthDiagFormat(merged)))
    GPSLogger.force(string.format("BREITENDIAG AKTUELL | TerraLine-Breite=%s | Quelle=%s | erkannt=%s | KEINE automatische Uebernahme",
        currentWidth and string.format("%.2fm",currentWidth) or "unbekannt",tostring(currentSource),tostring(currentDetected)))
    GPSLogger.force("BREITENDIAG ENDE | Union ist nur ein Messkandidat; WorkArea-Typen/aktivierte Bereiche noch nicht gefiltert")
    return string.format("BREITENDIAG: %d/%d Arbeitsgeraete, %d Gewichte, %d Packer ignoriert; Union %.2fm, Spannweite %.2fm. Bitte log.txt senden.",deviceCount,workingCount,weightCount,packerCount,total,span)
end
