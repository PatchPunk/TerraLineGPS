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
