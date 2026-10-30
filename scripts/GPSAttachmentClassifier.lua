-- Classify attached objects for TerraLine working-width and offset measurement.
-- Only confirmed ballast is excluded. Unknown attachments stay relevant so
-- missing implement geometries cannot silently enable steering compensation.
GPSAttachmentClassifier={}
local C=GPSAttachmentClassifier

local function text(value)
    if type(value)=="string" then return value:lower() end
    return ""
end

local function hasWord(value,word)
    return value:find("%f[%a]"..word.."%f[%A]")~=nil
end

local function isWeightCategory(value)
    local category=text(value):gsub("[%s_%-]","")
    return category=="weights" or category=="weight" or
        category=="frontweights" or category=="rearweights" or
        category=="counterweights" or category=="ballastweights"
end

local function isWeightType(value)
    local kind=text(value):gsub("[%s_%-]","")
    return kind=="weight" or kind=="frontweight" or kind=="rearweight" or
        kind=="counterweight" or kind=="ballastweight"
end

local function nameOf(object)
    if object and type(object.getName)=="function" then
        local n=object:getName()
        if type(n)=="string" and n~="" then return n end
    end
    return "Unbekannt"
end

local function positionOf(object,tractorNode)
    local node=object and object.rootNode
    if type(node)~="number" or node<=0 or type(tractorNode)~="number" or tractorNode<=0 or
        type(localToLocal)~="function" then return "unbekannt" end
    local x,y,z=localToLocal(node,tractorNode,0,0,0)
    if type(z)~="number" or z~=z or math.abs(z)>100 then return "unbekannt" end
    -- Tractor-local +Z is forward. This is a diagnostic position approximation;
    -- classification does not rely on it (e.g. pivoting front implements).
    if z>0.35 then return "Front" end
    if z< -0.35 then return "Heck" end
    return "Fahrzeugmitte"
end

function C.classify(object,tractorNode)
    local name=nameOf(object)
    local category=""
    local filename=object and object.configFileName
    local store=g_storeManager
    if type(filename)=="string" and store~=nil and type(store.getItemByXMLFilename)=="function" then
        local item=store:getItemByXMLFilename(filename)
        if type(item)=="table" then
            category=item.categoryName or ""
        end
    end
    local vehicleType=object and (object.typeName or (type(object.type)=="table" and object.type.name)) or ""
    local ballast=false
    local reason=""
    if isWeightCategory(category) then
        ballast=true;reason="Shopkategorie"
    elseif isWeightType(vehicleType) then
        ballast=true;reason="Fahrzeugtyp"
    elseif type(filename)=="string" then
        local path=text(filename):gsub("\\","/")
        if path:find("/weights/",1,true) or path:find("/weight/",1,true) or
            path:find("/frontweights/",1,true) or path:find("/counterweights/",1,true) then
            ballast=true;reason="XML-Pfad"
        end
    end
    if not ballast then
        local lower=text(name)
        if hasWord(lower,"weight") or hasWord(lower,"gewicht") or
            hasWord(lower,"counterweight") or hasWord(lower,"ballast") then
            ballast=true;reason="Geraetename"
        end
    end
    return ballast,positionOf(object,tractorNode),name,category,vehicleType,reason
end

function C.isBallast(object)
    local ballast=C.classify(object,nil)
    return ballast
end

-- A plough's auxiliary packer/roller must not define the GPS work center.
-- Exclude it ONLY while a plough is present in the same attachment group:
-- a roller used as the main implement must still be measurable by TerraLine.
local function objectMetadata(object)
    local name=text(nameOf(object))
    local kind=text(object and (object.typeName or
        (type(object.type)=="table" and object.type.name)))
    local filename=text(object and object.configFileName):gsub("\\","/")
    local category=""
    if filename~="" and g_storeManager and
            type(g_storeManager.getItemByXMLFilename)=="function" then
        local item=g_storeManager:getItemByXMLFilename(object.configFileName)
        if type(item)=="table" then category=text(item.categoryName) end
    end
    return name,kind,filename,category
end

-- Inspect ONLY this object's own specialization, shop type/category and
-- XML basename. A directory or mod-pack path (e.g. plows/ or a TIGGES
-- plough+packer bundle) is not evidence that each contained object ploughs.
function C.isPlow(object)
    if not object then return false end
    if object.spec_plow~=nil then return true end
    local name,kind,path,category=objectMetadata(object)
    local basename=path:match("([^/]+)$") or ""
    for _,part in ipairs({kind,category,basename}) do
        if part:find("plow",1,true) or part:find("plough",1,true) or
            part:find("pflug",1,true) then return true end
    end
    if hasWord(name,"plow") or hasWord(name,"plough") or
        hasWord(name,"pflug") then return true end
    -- Some modded ploughs expose only a PLOW WorkAreaType. Do not infer
    -- this from directory names shared by a roller in the same pack.
    if type(object.getWorkAreaByIndex)=="function" and type(WorkAreaType)=="table" then
        for i=1,32 do
            local area=object:getWorkAreaByIndex(i)
            if type(area)~="table" then break end
            if (WorkAreaType.PLOW~=nil and area.type==WorkAreaType.PLOW) or
               (WorkAreaType.PLOWSHARE~=nil and area.type==WorkAreaType.PLOWSHARE) then
                return true
            end
        end
    end
    return false
end

function C.isPacker(object)
    if not object then return false end
    local name,kind,path,category=objectMetadata(object)
    local basename=path:match("([^/]+)$") or ""
    -- Distinctive names / XML basenames refer to THIS object, not the
    -- parent mod folder used by both the SERVO plough and the DP 900.
    local namedPacker=name:find("dp[%s_%-]*900") or
        basename:find("dp[%s_%-]*900") or basename:find("dp900",1,true) or
        name:find("packer",1,true) or name:find("packomat",1,true) or
        hasWord(name,"roller") or hasWord(name,"walze")
    if namedPacker then return true end
    if object.spec_plow~=nil or C.isPlow(object) then return false end
    if object.spec_roller~=nil then return true end
    for _,part in ipairs({kind,category}) do
        if part:find("packer",1,true) or part:find("packomat",1,true) or
           part=="roller" or part=="rollers" or part:find("walze",1,true) then
            return true
        end
    end
    if path:find("/packers/",1,true) or path:find("/rollers/",1,true) or
       path:find("/packer",1,true) then return true end
    return false
end

-- Shared filter for lane width AND steering-offset measurement. Returning the
-- same set prevents an auxiliary packer changing the offset but not the width.
-- Unknown attachments remain relevant (fail-safe; no guessed correction).
function C.filterForGPS(objects,tractorNode)
    local hasPlow=false
    for _,object in ipairs(objects or {}) do
        if C.isPlow(object) then hasPlow=true;break end
    end
    local working,ignored={},{}
    for _,object in ipairs(objects or {}) do
        local ballast,position,name,_,_,reason=C.classify(object,tractorNode)
        if ballast then
            ignored[#ignored+1]={object=object,name=name,position=position,
                reason=reason,kind="Gewicht"}
        elseif hasPlow and C.isPacker(object) then
            ignored[#ignored+1]={object=object,name=name,position=position,
                reason="Packer beim Pfluegen ohne GPS-Einfluss",kind="Packer"}
        else
            working[#working+1]=object
        end
    end
    return working,ignored
end
