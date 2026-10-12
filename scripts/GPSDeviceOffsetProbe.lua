-- Diagnostic groundwork for automatic implement offset. Does not affect
-- steering or A/B positions until supported implement geometries are tested.
GPSDeviceOffsetProbe={lastSignature=nil,clock=0}
local function xyz(node,root)
    if not node or not root or type(localToLocal)~="function" then return nil end
    local ok,x=pcall(localToLocal,node,root,0,0,0)
    if ok and type(x)=="number" and x==x and math.abs(x)<100 then return x end
    return nil
end
local function visit(object,items,seen,level)
    if not object or seen[object] or level>6 then return end
    seen[object]=true
    if level>0 then items[#items+1]=object end
    if type(object.getAttachedImplements)=="function" then
        local ok,arr=pcall(object.getAttachedImplements,object)
        if ok and type(arr)=="table" then
            for _,v in pairs(arr) do
                if type(v)=="table" then visit(v.object,items,seen,level+1) end
            end
        end
    end
end
local function findSpan(object,tractorNode)
    -- Prefer live AI marker positions (follow moving / pivoting tools).
    if type(object.getAIMarkers)=="function" then
        local ok,l,r=pcall(object.getAIMarkers,object)
        if ok then
            local lx,rx=xyz(l,tractorNode),xyz(r,tractorNode)
            if lx and rx and math.abs(lx-rx)>=0.5 then
                return math.min(lx,rx),math.max(lx,rx),"AI-Marker"
            end
        end
    end
    local lo,hi=math.huge,-math.huge
    if type(object.getWorkAreaByIndex)=="function" then
        for i=1,128 do
            local ok,wa=pcall(object.getWorkAreaByIndex,object,i)
            if not ok or not wa then break end
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
    local items={};visit(vehicle,items,{},0)
    if #items==0 then return nil,"Kein Arbeitsgeraet" end
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
    local desc=string.format("Arbeitskanten L=%+.2fm R=%+.2fm, Mitte=%+.2fm aus Traktorsicht | %d von %d Geraeten | %s",
        lo,hi,center,included,#items,sources["AI-Marker"] and "AI-Marker" or "WorkArea")
    return center,desc,(included==#items)
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
