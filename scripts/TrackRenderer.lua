-- TerraLine GPS: Display the effective TRACTOR target line.
-- Device-auto changes only steering and the visible guidance corridor;
-- saved A/B points and the manual course shift remain unchanged.
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
    GPSLineVisuals.prepare(vehicle)
    GPSLineVisuals.beginFrame() -- pooled visual meshes only; original lines remain
    local a,b=GPSABLineManager.a,GPSABLineManager.b
    if not a then return end
    local node=GPSVehicleDetector.getPositionNode(vehicle)
    if not node then return end
    local x,_,z=getWorldTranslation(node)
    local fx,_,fz=localDirectionToWorld(node,0,0,1)
    local forwardLen=math.sqrt(fx*fx+fz*fz)
    if forwardLen<EPS then return end
    fx,fz=fx/forwardLen,fz/forwardLen
    -- Use the tractor's heading (not reverse velocity) for the same
    -- A/B direction sign used by SteeringController.compute().
    local headingX,headingZ=fx,fz
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
        -- This is exactly the A/B-normal offset used for the steering target.
        -- The stored A/B work center is untouched; only visible lines move.
        local nx,nz=-dz/abLength,dx/abLength
        local autoCorrection=0
        if GPSDeviceOffsetAuto and GPSDeviceOffsetAuto.enabled then
            local dir=(headingX*dx+headingZ*dz)>=0 and 1 or -1
            local correction=GPSDeviceOffsetAuto.getCorrection(vehicle,dir)
            -- Never extrapolate an invalid/stale measurement into the display.
            if type(correction)=="number" and correction==correction then
                autoCorrection=correction
            end
        end
        local track=GPSSteeringController.enabled and GPSSteeringController.lockedTrack or nil
        if track==nil and GPSTrackPosition.valid then track=GPSTrackPosition.track end
        if track==nil then return end
        local baseX,baseZ=a.x+nx*(track*width+autoCorrection),
                            a.z+nz*(track*width+autoCorrection)
        local projected=(x-baseX)*ux+(z-baseZ)*uz
        cx,cz=baseX+ux*projected,baseZ+uz*projected
        -- Centerline and work-width preview borders share the steering target.
        length=40 -- 40 m ahead AND 40 m behind the tractor; visuals only
        centerColor=GPSSteeringController.enabled and {0.15,1.0,0.20} or {1.0,0.12,0.12}
        leftColor={1.0,0.83,0.06};sideDashed=true
    end
    local nx,nz=-uz,ux
    local half=width*0.5
    local lx,lz=cx+nx*half,cz+nz*half
    local rx,rz=cx-nx*half,cz-nz*half
    -- Only with approved device-auto geometry, place YELLOW lines at the
    -- physical work edges measured by GPSDeviceOffsetProbe (tractor-local X).
    -- The original raw A/B normal, not the flipped draw direction, is used.
    -- Actual green centerline / steering target remains exactly as before.
    if GPSDeviceOffsetAuto and GPSDeviceOffsetAuto.enabled and a and b then
        local abX,abZ=b.x-a.x,b.z-a.z
        local abLen=math.sqrt(abX*abX+abZ*abZ)
        if abLen>0.000001 and GPSDeviceOffsetAuto.getWorkEdges then
            local node=GPSVehicleDetector.getPositionNode(vehicle)
            if node then
                local hx,_,hz=localDirectionToWorld(node,0,0,1)
                -- Same A/B direction definition as steering and center renderer.
                local dir=(hx*abX+hz*abZ)>=0 and 1 or -1
                local workMinX,workMaxX=GPSDeviceOffsetAuto.getWorkEdges(vehicle,dir)
                if workMinX and workMaxX then
                    local rawNX,rawNZ=-abZ/abLen,abX/abLen
                    -- Local +X points in the opposite direction to A/B-left.
                    -- Relative to the green TRACTOR target, marker X maps to
                    -- -X*dir on the raw A/B normal, for both A->B and B->A.
                    local leftShift=-workMinX*dir
                    local rightShift=-workMaxX*dir
                    lx,lz=cx+rawNX*leftShift,cz+rawNZ*leftShift
                    rx,rz=cx+rawNX*rightShift,cz+rawNZ*rightShift
                end
            end
        end
    end
    -- Drawing distance only; no field boundary limits or island clipping.
    -- Both sides of the projection are visible, even outside farmland.
    local centerLimit,leftLimit,rightLimit=length,length,length
    local backCenter,backLeft,backRight=length,length,length
    local terrain=g_currentMission and g_currentMission.terrainRootNode or g_terrainNode
    -- Display the effective tractor target in both directions.
    line(terrain,cx,cz,ux,uz,centerLimit,centerColor[1],centerColor[2],centerColor[3],false)
    line(terrain,cx,cz,-ux,-uz,backCenter,centerColor[1],centerColor[2],centerColor[3],false)
    line(terrain,lx,lz,ux,uz,leftLimit,leftColor[1],leftColor[2],leftColor[3],sideDashed)
    line(terrain,lx,lz,-ux,-uz,backLeft,leftColor[1],leftColor[2],leftColor[3],sideDashed)
    line(terrain,rx,rz,ux,uz,rightLimit,leftColor[1],leftColor[2],leftColor[3],sideDashed)
    line(terrain,rx,rz,-ux,-uz,backRight,leftColor[1],leftColor[2],leftColor[3],sideDashed)
    -- For eight seconds after a MANUAL shift, display the unshifted lane
    -- center in yellow dashes for comparison. Never changes steering or
    -- the saved A/B geometry. Also visible after closing the menu.
    local now=GPSFieldTest and GPSFieldTest.totalMs or 0
    local changed=GPSABLineManager.lastManualShiftAt
    local manual=GPSABLineManager.offsetMeters or 0
    if type(changed)=="number" and now>=changed and now-changed<=8000
            and math.abs(manual)>=0.05 then
        local abX,abZ=b.x-a.x,b.z-a.z
        local abLen=math.sqrt(abX*abX+abZ*abZ)
        if abLen>0.001 then
            local refX=cx-abZ/abLen*manual
            local refZ=cz+abX/abLen*manual
            line(terrain,refX,refZ,ux,uz,12,1.0,0.83,0.06,true)
            line(terrain,refX,refZ,-ux,-uz,12,1.0,0.83,0.06,true)
            local refY=groundY(terrain,refX,refZ)+0.13
            local curY=groundY(terrain,cx,cz)+0.13
            GPSLineVisuals.segment(refX,refY,refZ,cx,curY,cz,1.0,0.83,0.06)
        end
    end
    GPSLineVisuals.finishFrame()
end
