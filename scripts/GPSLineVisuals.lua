-- TerraLine GPS | visual layer only | colored 3D ribbon test (FS25).
-- A real, pooled plane shape replaces unsupported debug-triangle fill.
-- Original depth-tested thin line is retained as fallback for every segment.
GPSLineVisuals = {}
local M = GPSLineVisuals
local EPS = 0.000001
local DEFAULT_HEIGHT = 0.10
local INSIDE_FRONT_CLIP_METERS = 3.5
local MAX_RIBBONS = 224

M.meshPool = {}
M.supportsColorScale = {}
M.lastColors = {}
-- The created plane's default material has no colorScale (confirmed in game).
-- Each color needs a permanently referenced material entity: GIANTS frees unused
-- cloned materials once the last referencing shape switches to another material.
-- Hidden keepers retain red/yellow/green independently of visible ribbon colors.
M.modDirectory = g_currentModDirectory
M.materialKeepers = {} -- one hidden Shape per color keeps its material alive
M.materialKeeperNodes = {}
M.materialInitFailed = {}
M.nodeMaterialColor = {}
M.materialErrorLogged = false
M.pending = {}
M.collecting = false
M.meshFailure = false

function M.height(terrain, x, z)
    local height = GPSConfig and GPSConfig.lineHeightMeters or DEFAULT_HEIGHT
    if type(height) ~= "number" or height ~= height then height = DEFAULT_HEIGHT end
    height = math.max(0.10, math.min(4.0, height))
    if terrain and terrain ~= 0 and type(getTerrainHeightAtWorldPos) == "function" then
        local y = getTerrainHeightAtWorldPos(terrain, x, 0, z)
        if type(y) == "number" and y == y then return y + height end
    end
    return height
end

-- Interior-camera geometry is centered on the TRACTOR, not the camera yaw.
-- The cockpit camera's local +Z is not guaranteed to mean "looking forward"
-- (the previous test wrongly classified the forward camera as rear-facing).
-- Exclude only the +/-3.5 m occupied by the cab and leave BOTH sides visible.
function M.prepare(vehicle)
    M.insideClip = nil
    local camera = g_activeVehicleCamera
    if not vehicle or not camera or camera.vehicle ~= vehicle or camera.isInside ~= true then return end
    local node = (GPSVehicleDetector and GPSVehicleDetector.getPositionNode(vehicle)) or vehicle.rootNode
    if not node or node == 0 or type(getWorldTranslation) ~= "function" or
            type(localDirectionToWorld) ~= "function" then return end
    local x, _, z = getWorldTranslation(node)
    local fx, _, fz = localDirectionToWorld(node, 0, 0, 1)
    if type(x) ~= "number" or type(z) ~= "number" or
            type(fx) ~= "number" or type(fz) ~= "number" then return end
    local len = math.sqrt(fx*fx + fz*fz)
    if len < EPS then return end
    M.insideClip = {x=x,z=z,fx=fx/len,fz=fz/len,min=INSIDE_FRONT_CLIP_METERS}
end

-- Cut just the cockpit footprint [-clearance, +clearance]. The caller
-- generates short terrain segments (<=2m), so a segment cannot cross BOTH
-- clearance planes. In that abnormal case we conservatively hide it.
local function insideClip(x1,y1,z1,x2,y2,z2)
    local clip = M.insideClip
    if not clip then return x1,y1,z1,x2,y2,z2 end
    local d1 = (x1-clip.x)*clip.fx + (z1-clip.z)*clip.fz
    local d2 = (x2-clip.x)*clip.fx + (z2-clip.z)*clip.fz
    local gap = clip.min
    local far1,far2 = math.abs(d1)>=gap, math.abs(d2)>=gap
    if far1 and far2 then
        if d1*d2<0 then return nil end
        return x1,y1,z1,x2,y2,z2
    end
    if not far1 and not far2 then return nil end
    local bound = (far1 and d1 or d2)>0 and gap or -gap
    local divider=d2-d1
    if math.abs(divider)<EPS then return nil end
    local t=(bound-d1)/divider
    local cx,cy,cz=x1+(x2-x1)*t,y1+(y2-y1)*t,z1+(z2-z1)*t
    if not far1 then x1,y1,z1=cx,cy,cz else x2,y2,z2=cx,cy,cz end
    return x1,y1,z1,x2,y2,z2
end

local function hidePool()
    if type(setVisibility) ~= "function" then return end
    for i = 1,#M.meshPool do
        setVisibility(M.meshPool[i], false)
    end
end

function M.hide()
    M.collecting = false
    M.pending = {}
    hidePool()
end

function M.beginFrame()
    M.pending = {}
    M.collecting = true
    hidePool()
end

-- The filled plane is a normal scenegraph Shape. Unlike debug triangles it has
-- depth-tested geometry, and it is created only once per cached slot.
-- See GIANTS' PlaceableRiceField.buildMesh for this documented creation API.
local function createRibbonShape(asKeeper)
    if M.meshFailure then return nil end
    if type(createPlaneShapeFrom2DContour) ~= "function" or
            type(getRootNode) ~= "function" or type(link) ~= "function" or
            type(setTranslation) ~= "function" or type(setRotation) ~= "function" or
            type(setScale) ~= "function" or type(setVisibility) ~= "function" then
        M.meshFailure = true
        if GPSLogger then GPSLogger.info("GPS-Mesh: benoetigte Shape-/Node-API nicht vorhanden, Debug-Linie bleibt sichtbar") end
        return nil
    end
    -- Local X = physical width, local Z = segment length (both one metre).
    -- Engine errors remain visible in log.txt; invalid return values keep the
    -- existing thin debug-line fallback without creating a broken scene node.
    local node = createPlaneShapeFrom2DContour(
        "TLGPS_LaneRibbon", {-0.5,-0.5, -0.5,0.5, 0.5,0.5, 0.5,-0.5}, false)
    if type(node) ~= "number" or node <= 0 then
        M.meshFailure = true
        if GPSLogger then GPSLogger.info("GPS-Mesh: Shape-Erzeugung fehlgeschlagen: "..tostring(node)) end
        return nil
    end
    -- Validate the scene root before linking. A broken root retains the
    -- original thin-line fallback and releases the freshly created Shape.
    -- Native link exceptions are intentionally visible in the game log.
    local rootNode = getRootNode()
    if type(rootNode) ~= "number" or rootNode <= 0 then
        if type(delete) == "function" then delete(node) end
        M.meshFailure = true
        if GPSLogger then GPSLogger.info("GPS-Mesh: Root-Knoten ungueltig: "..tostring(rootNode)) end
        return nil
    end
    link(rootNode, node)
    if type(setShapeCastShadowmap) == "function" then setShapeCastShadowmap(node,false) end
    if type(setShapeReceiveShadowmap) == "function" then setShapeReceiveShadowmap(node,false) end
    setVisibility(node,false)
    if not M.meshInfoLogged then
        M.meshInfoLogged = true
        local material = nil
        if type(getMaterial) == "function" then
            material = getMaterial(node,0)
        end
        local colorScale = false
        if type(getHasShaderParameter) == "function" then
            colorScale = getHasShaderParameter(node,"colorScale") == true
        end
        if GPSLogger then
            GPSLogger.info(string.format("GPS-Mesh Shape erzeugt: material=%s colorScale=%s (Farbwirkung im Spiel noch zu testen)",
                tostring(material),tostring(colorScale)))
        end
    end
    if type(getHasShaderParameter) == "function" then
        M.supportsColorScale[node] = getHasShaderParameter(node,"colorScale") == true
    end
    if asKeeper then
        M.materialKeeperNodes[#M.materialKeeperNodes+1] = node
    else
        table.insert(M.meshPool,node)
    end
    return node
end

-- Unlit/shape-default planes have no colorScale parameter in the tested engine.
-- The LS25 API permits cloning the material with a new diffuse-map texture
-- (sharedEdit=false), then assigning the cloned material to the shape.
-- Three tiny BC1 DDS textures match the existing debug-line palette.
local PALETTE_TEXTURES = {
    red = "assets/gpsLine_red.dds",
    yellow = "assets/gpsLine_yellow.dds",
    green = "assets/gpsLine_green.dds"
}

local function paletteKey(r,g,b)
    if g > 0.55 and r < 0.65 then return "green" end
    if r > 0.75 and g > 0.55 and b < 0.55 then return "yellow" end
    return "red"
end

-- Cache keeper Shapes, not bare material IDs. Their material stays valid even
-- when every visible GPS ribbon has switched from red to green (or back).
local function getPaletteMaterial(key)
    local keeper = M.materialKeepers[key]
    if keeper then
        if type(getMaterial) ~= "function" then
            M.materialInitFailed[key] = true
            return nil
        end
        local material = getMaterial(keeper, 0)
        if type(material) == "number" and material > 0 then return material end
        M.materialInitFailed[key] = true
        return nil
    end
    if M.materialInitFailed[key] then return nil end
    local dir = M.modDirectory or (GPSMenu and GPSMenu.modDir)
    if type(dir) ~= "string" or dir == "" then
        M.materialInitFailed[key] = true
        if GPSLogger then GPSLogger.info("GPS-Mesh Farbmaterial: Modpfad fehlt") end
        return nil
    end
    if dir:sub(-1) ~= "/" and dir:sub(-1) ~= "\\" then dir = dir .. "/" end

    keeper = createRibbonShape(true)
    if not keeper then
        M.materialInitFailed[key] = true
        return nil
    end
    local base = nil
    if type(getMaterial) == "function" then
        base = getMaterial(keeper, 0)
    end
    if type(base) ~= "number" or base <= 0 then
        M.materialInitFailed[key] = true
        if GPSLogger then GPSLogger.info("GPS-Mesh Farbmaterial: Basismaterial fehlt ("..key..")") end
        return nil
    end
    local file = dir .. PALETTE_TEXTURES[key]
    -- Check the optional API before calling it. Engine errors are logged by LS25.
    if type(setMaterialDiffuseMapFromFile) ~= "function" then
        M.materialInitFailed[key] = true
        if GPSLogger then GPSLogger.info("GPS-Mesh Farbmaterial: Diffuse-Map API fehlt ("..key..")") end
        return nil
    end
    local material = setMaterialDiffuseMapFromFile(base, file, true, true, false)
    if type(material) ~= "number" or material <= 0 then
        M.materialInitFailed[key] = true
        if GPSLogger then GPSLogger.info("GPS-Mesh Farbmaterial: Diffuse-Map fehlgeschlagen ("..key..")") end
        return nil
    end
    -- Critical: this hidden keeper is never recolored or deleted during gameplay.
    -- The engine must never garbage-collect the stored material ID.
    -- A valid keeper shape and a valid material ID were already checked above.
    -- Guard the optional engine function instead of suppressing engine errors.
    if type(setMaterial) ~= "function" then
        M.materialInitFailed[key] = true
        if GPSLogger then GPSLogger.info("GPS-Mesh Farbmaterial: Keeper-Zuweisung nicht verfuegbar ("..key..")") end
        return nil
    end
    setMaterial(keeper, material, 0)
    M.materialKeepers[key] = keeper
    if GPSLogger then
        GPSLogger.info(string.format("GPS-Mesh Farbmaterial: %s dauerhaft gehalten (Shape %s, Material %s)",
            key, tostring(keeper), tostring(material)))
    end
    return material
end

local function colorMaterial(node, r, g, b)
    if type(getMaterial) ~= "function" or type(setMaterial) ~= "function" or
       type(setMaterialDiffuseMapFromFile) ~= "function" then
        if not M.materialErrorLogged and GPSLogger then
            M.materialErrorLogged = true
            GPSLogger.info("GPS-Mesh Farbmaterial: benoetigte Material-API nicht vorhanden")
        end
        return false
    end
    local key = paletteKey(r,g,b)
    if M.nodeMaterialColor[node] == key then return true end
    local material = getPaletteMaterial(key)
    if material ~= nil and type(node) == "number" and node > 0 then
        -- A healthy ribbon has a positive material ID before color assignment.
        -- This prevents calling the engine setter for absent/invalid nodes.
        local current = getMaterial(node, 0)
        if type(current) == "number" and current > 0 then
            setMaterial(node, material, 0)
            M.nodeMaterialColor[node] = key
            return true
        end
    end
    if not M.materialErrorLogged and GPSLogger then
        M.materialErrorLogged = true
        GPSLogger.info("GPS-Mesh Farbmaterial: Shape-Zuweisung nicht moeglich (ungueltige Materialdaten)")
    end
    return false
end

-- A fixed-size pool eliminates per-frame geometry creation/deletion. Shape
-- transforms can be updated every frame as tractor/field position changes.
local function renderRibbon(i, seg)
    local node = M.meshPool[i] or createRibbonShape()
    if not node then return false end
    -- Check malformed segments before they reach the native transform calls.
    -- Valid GPS segments are unchanged. A bad segment still keeps its thin line.
    if type(node) ~= "number" or node <= 0 or type(seg) ~= "table" then return false end
    for n = 1,10 do
        local v = seg[n]
        if type(v) ~= "number" or v ~= v or math.abs(v) == math.huge then
            setVisibility(node,false)
            if not M.meshTransformErrorLogged and GPSLogger then
                M.meshTransformErrorLogged = true
                GPSLogger.info("GPS-Mesh: ungueltige Liniendaten, Debug-Linie bleibt als Fallback")
            end
            return false
        end
    end
    local x1,y1,z1,x2,y2,z2 = seg[1],seg[2],seg[3],seg[4],seg[5],seg[6]
    local dx,dy,dz = x2-x1,y2-y1,z2-z1
    if seg[10] <= 0 then
        setVisibility(node,false)
        return false
    end
    local len = math.sqrt(dx*dx+dz*dz)
    if len < EPS then return false end
    local yaw = math.atan2 and math.atan2(dx,dz) or math.atan(dx,dz)
    local pitch = 0 -- calculate from elevation difference below
    if type(math.atan2) == "function" then
        pitch = -math.atan2(dy,len)
    else
        pitch = -math.atan(dy,len)
    end
    -- The base plane has an upward normal. For a camera underneath the
    -- raised crop line, turn the surface over so it is not backface-culled.
    local roll = 0
    local camera = g_activeVehicleCamera
    local cameraNode = camera and camera.cameraNode
    if cameraNode and cameraNode ~= 0 and type(getWorldTranslation) == "function" then
        local _,cameraY = getWorldTranslation(cameraNode)
        if type(cameraY) == "number" and cameraY < (y1+y2)*0.5 then
            roll = math.pi
        end
    end
    -- Before updating a cached ribbon, reject invalid input without masking
    -- native engine errors. The original thin debug line remains visible.
    if type(setTranslation) ~= "function" or type(setRotation) ~= "function" or
            type(setScale) ~= "function" or type(setVisibility) ~= "function" then
        if not M.meshTransformErrorLogged and GPSLogger then
            M.meshTransformErrorLogged = true
            GPSLogger.info("GPS-Mesh: Shape-Transform API fehlt, Debug-Linie bleibt als Fallback")
        end
        return false
    end
    setTranslation(node,(x1+x2)*0.5,(y1+y2)*0.5,(z1+z2)*0.5)
    setRotation(node,pitch,yaw,roll)
    setScale(node,seg[10],1,math.sqrt(dx*dx+dy*dy+dz*dz))
    if M.supportsColorScale[node] and type(setShaderParameter) == "function" then
        local last = M.lastColors[node]
        if not last or last[1] ~= seg[7] or last[2] ~= seg[8] or last[3] ~= seg[9] then
            setShaderParameter(node,"colorScale",seg[7],seg[8],seg[9],1,false)
            M.lastColors[node] = {seg[7],seg[8],seg[9]}
        end
    else
        -- Material is assigned only on first use or when changing red/green/yellow.
        colorMaterial(node, seg[7], seg[8], seg[9])
    end
    setVisibility(node,true)
    return true
end

function M.finishFrame()
    M.collecting = false
    local count = math.min(#M.pending,MAX_RIBBONS)
    for i=1,count do renderRibbon(i,M.pending[i]) end
    if #M.pending > MAX_RIBBONS and not M.poolCapLogged then
        M.poolCapLogged=true
        if GPSLogger then GPSLogger.info("GPS-Mesh: Shape-Pool limitiert auf "..MAX_RIBBONS.." Segmente; Debug-Linien bleiben erhalten") end
    end
    M.pending = {}
end

function M.segment(x1,y1,z1,x2,y2,z2,r,g,b)
    x1,y1,z1,x2,y2,z2 = insideClip(x1,y1,z1,x2,y2,z2)
    if not x1 then return end
    -- The existing thin line stays on the exact steering target.
    if type(drawDebugLine) == "function" then
        drawDebugLine(x1,y1,z1,r,g,b,x2,y2,z2,r,g,b,true)
    end
    local thickness = GPSConfig and GPSConfig.lineThicknessMeters or 0
    if not M.collecting or type(thickness) ~= "number" or thickness ~= thickness or
            thickness <= 0 or M.meshFailure then return end
    thickness = math.min(0.30,math.max(0,thickness))
    if #M.pending < MAX_RIBBONS then
        M.pending[#M.pending+1] = {x1,y1,z1,x2,y2,z2,r,g,b,thickness}
    end
end

-- White dashed 25m cross-reference: intentionally ONLY depth-tested debug
-- lines. Passing white through the red/yellow/green ribbon palette would
-- recolor its 3D mesh red, so this marking bypasses the mesh pool entirely.
function M.referenceSegment(x1,y1,z1,x2,y2,z2)
    if type(drawDebugLine)~="function" then return end
    x1,y1,z1,x2,y2,z2=insideClip(x1,y1,z1,x2,y2,z2)
    if not x1 then return end
    drawDebugLine(x1,y1,z1,1,1,1,x2,y2,z2,1,1,1,true)
end

function M.cleanup()
    M.collecting=false
    M.pending={}
    if type(delete) == "function" then
        -- First dispose of visible ribbons, then the palette anchors.
        for i=1,#M.meshPool do
            local node = M.meshPool[i]
            if type(node) == "number" and node > 0 then
                delete(node)
            end
        end
        for i=1,#M.materialKeeperNodes do
            local node = M.materialKeeperNodes[i]
            if type(node) == "number" and node > 0 then
                delete(node)
            end
        end
    end
    M.meshPool={}
    M.supportsColorScale={}
    M.lastColors={}
    M.materialKeepers={}
    M.materialKeeperNodes={}
    M.materialInitFailed={}
    M.nodeMaterialColor={}
    M.materialErrorLogged=false
    M.meshFailure=false
    M.meshInfoLogged=nil
    M.meshTransformErrorLogged=nil
end
