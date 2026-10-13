-- TerraLine GPS v0.9.9.42: separate implement-auto compensation from manual course shift.
-- Manual shift translates the full course. Automatic implement offset moves only
-- the live steering target INSIDE the manually positioned work-width borders.
-- Rendering only: no changes to geometry used by steering or track selection.
GPSTrackRenderer={lastTravelDirection=1}
local EPS=0.000001
local function groundY(terrain,x,z)
    if terrain and type(getTerrainHeightAtWorldPos)=="function" then
        return GPSLineVisuals.height(terrain,x,z)
    end
    return GPSLineVisuals.height(terrain,x,z)
end
local function line(terrain,x,z,ux,uz,length,r,g,b,dashed)
    if length<=0.05 then return end
    local t=0
    local dash= dashed and 1.3 or math.max(0.5,GPSConfig.terrainStepMeters or 2)
    local gap= dashed and 0.9 or 0
    while t<length-0.001 do
        local last=math.min(length,t+dash)
        local x1,z1=x+ux*t,z+uz*t
        local x2,z2=x+ux*last,z+uz*last
        GPSLineVisuals.segment(x1,groundY(terrain,x1,z1),z1,x2,groundY(terrain,x2,z2),z2,r,g,b)
        t=last+gap
    end
end
function GPSTrackRenderer.draw(_,vehicle)
    if type(drawDebugLine)~="function" or not vehicle then return end
    local a,b=GPSABLineManager.a,GPSABLineManager.b
    if not a then return end
    local node=GPSVehicleDetector.getPositionNode(vehicle)
    if not node then return end
    local x,_,z=getWorldTranslation(node)
    local fx,_,fz=localDirectionToWorld(node,0,0,1)
    local forwardLen=math.sqrt(fx*fx+fz*fz)
    if forwardLen<EPS then return end
    fx,fz=fx/forwardLen,fz/forwardLen
    -- LS25 movingDirection is -1 in reverse, +1 forwards, 0 at rest.
    -- Hold last meaningful direction when stopped to avoid flicker.
    local motion=vehicle.movingDirection
    if type(motion)=="number" and math.abs(motion)>0.1 then
        GPSTrackRenderer.lastTravelDirection=motion<0 and -1 or 1
    end
    local travel=GPSTrackRenderer.lastTravelDirection or 1
    fx,fz=fx*travel,fz*travel
    local width=GPSImplementDetector.getWidth(vehicle)
    if type(width)~="number" or width<=0 then width=GPSConfig.defaultWorkWidth or 3 end
    local ux,uz,cx,cz,length,centerColor,leftColor,sideDashed
    if not b then
        -- During A->B measurement ONLY the temporary red A marker/dashes are
        -- drawn by ABPreviewRenderer. No fake 40m course or work borders.
        return
    else
        -- After B: a single guidance pass at the same track index as steering.
        local dx,dz=b.x-a.x,b.z-a.z
        local abLength=math.sqrt(dx*dx+dz*dz)
        if abLength<10 then return end
        ux,uz=dx/abLength,dz/abLength
        if fx*ux+fz*uz<0 then ux,uz=-ux,-uz end
        -- A/B right = (dz,-dx), i.e. NEGATIVE of this normal.
        -- ABLineManager.shift() has already translated the A/B points used by
        -- steering, so the GPS target (center) needs NO additional shift.
        -- Preserve this A->B normal for undoing ONLY the auto implement offset
        -- on the yellow display borders; it must not flip with travel direction.
        local nx,nz=-dz/abLength,dx/abLength
        local autoApplied=GPSDeviceOffsetAuto and tonumber(GPSDeviceOffsetAuto.applied) or 0
        if autoApplied~=autoApplied then autoApplied=0 end
        GPSTrackRenderer.autoVisualX=nx*autoApplied
        GPSTrackRenderer.autoVisualZ=nz*autoApplied
        local track=GPSSteeringController.enabled and GPSSteeringController.lockedTrack or nil
        if track==nil and GPSTrackPosition.valid then track=GPSTrackPosition.track end
        if track==nil then return end
        local baseX,baseZ=a.x+nx*track*width,a.z+nz*track*width
        local projected=(x-baseX)*ux+(z-baseZ)*uz
        cx,cz=baseX+ux*projected,baseZ+uz*projected
        -- Target follows ALL A/B shifts (manual + auto), exactly as steering.
        -- Coverage borders below will follow MANUAL shifts only.
        length=60 -- only ahead of tractor (visual limit)
        centerColor=GPSSteeringController.enabled and {0.15,1.0,0.20} or {1.0,0.12,0.12}
        leftColor={1.0,0.83,0.06};sideDashed=true
    end
    local nx,nz=-uz,ux
    local half=width*0.5
    -- Undo only the AUTO implement compensation in the BORDER rendering.
    -- shift(distance): A/B move by -normalAB*distance, so reversing its
    -- contribution adds normalAB*autoApplied back to the shifted center.
    -- Manual A/B shifts remain visible on the entire corridor as before.
    -- The middle GPS line is still EXACTLY on the actual steering target.
    local borderX=cx+(GPSTrackRenderer.autoVisualX or 0)
    local borderZ=cz+(GPSTrackRenderer.autoVisualZ or 0)
    local lx,lz=borderX+nx*half,borderZ+nz*half
    local rx,rz=borderX-nx*half,borderZ-nz*half
    -- Render only the forward corridor. A stays the rotation pivot.
    -- The current vehicle projection is the visual start, without back rays.
    local terrain=g_currentMission and g_currentMission.terrainRootNode or g_terrainNode
    line(terrain,cx,cz,ux,uz,length,centerColor[1],centerColor[2],centerColor[3],false)
    line(terrain,lx,lz,ux,uz,length,leftColor[1],leftColor[2],leftColor[3],sideDashed)
    line(terrain,rx,rz,ux,uz,length,leftColor[1],leftColor[2],leftColor[3],sideDashed)
end
