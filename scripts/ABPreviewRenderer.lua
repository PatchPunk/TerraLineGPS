-- TerraLine GPS: preview between A and B. Rendering only; no steering changes.
GPSABPreviewRenderer={}
local M=GPSABPreviewRenderer
local function height(terrain,x,z)
    return GPSLineVisuals.height(terrain,x,z)
end
local function segment(x1,y1,z1,x2,y2,z2,r,g,b)
    GPSLineVisuals.segment(x1,y1,z1,x2,y2,z2,r,g,b)
end
local function referenceLine(terrain,x,z,ux,uz,length,dashed)
    if length<=0.05 or not GPSLineVisuals.referenceSegment then return end
    local t=0
    local dash=dashed and 1.25 or math.max(0.35,GPSConfig.terrainStepMeters or 1)
    local gap=dashed and 0.75 or 0
    while t<length-0.001 do
        local finish=math.min(length,t+dash)
        local x1,z1=x+ux*t,z+uz*t
        local x2,z2=x+ux*finish,z+uz*finish
        local y1=height(terrain,x1,z1)+0.08
        local y2=height(terrain,x2,z2)+0.08
        GPSLineVisuals.referenceSegment(x1,y1,z1,x2,y2,z2)
        t=finish+gap
    end
end
local function drawA(terrain,a)
    local x,z=a.x,a.z
    local y=height(terrain,x,z)
    -- Rotate the vertical letter into the vehicle's driving direction when A
    -- is captured. Right is perpendicular to the stored heading (world X/Z).
    local ux,uz=a.headingX or 0,a.headingZ or 1
    local rightX,rightZ=uz,-ux
    segment(x-rightX*.48,y+.18,z-rightZ*.48,x,y+1.35,z,1,.23,.15)
    segment(x,y+1.35,z,x+rightX*.48,y+.18,z+rightZ*.48,1,.23,.15)
    segment(x-rightX*.29,y+.64,z-rightZ*.29,
            x+rightX*.29,y+.64,z+rightZ*.29,1,.23,.15)
    -- Ground cross follows the same orientation as the letter.
    segment(x-rightX*.40-ux*.40,y,z-rightZ*.40-uz*.40,
            x+rightX*.40+ux*.40,y,z+rightZ*.40+uz*.40,1,.42,.21)
    segment(x-rightX*.40+ux*.40,y,z-rightZ*.40+uz*.40,
            x+rightX*.40-ux*.40,y,z+rightZ*.40-uz*.40,1,.42,.21)
end
function M.draw(vehicle)
    GPSLineVisuals.prepare(vehicle)
    local abManager=GPSABLineManager
    local armed=abManager and abManager.captureStage=="armed"
    local a=abManager and abManager.a
    -- Press 1 (armed): preview the center and both recognized work edges now,
    -- without setting A or replacing the existing A/B line.
    -- Press 2 (measuring): also draw A and its thin trace behind the vehicle.
    -- After B: no temporary preview lines.
    if not vehicle or (not armed and (not a or abManager.b)) then return end
    if type(drawDebugLine)~="function" then return end
    local node=GPSVehicleDetector and GPSVehicleDetector.getPositionNode(vehicle)
    if not node or type(getWorldTranslation)~="function" then return end
    local x,_,z=getWorldTranslation(node)
    if type(x)~="number" or type(z)~="number" then return end
    local terrain=g_currentMission and g_currentMission.terrainRootNode or g_terrainNode
    local distance=0
    if not armed then
        local dxAB,dzAB=x-a.x,z-a.z
        distance=math.sqrt(dxAB*dxAB+dzAB*dzAB)
        drawA(terrain,a)
        -- The rearward A-to-vehicle trace starts only with the measurement.
        if distance>0.05 then
            referenceLine(terrain,a.x,a.z,dxAB/distance,dzAB/distance,
                          distance,false)
        end
    end
    -- Temporary white dashed center and half-width work edges: 25 m ahead
    -- starting at the FIRST Alt+B press (armed), and during A->B measurement.
    -- They vanish after B. No steering or course geometry changes.
    if type(localDirectionToWorld)=="function" and GPSLineVisuals.referenceSegment then
        local vx,_,vz=localDirectionToWorld(node,0,0,1)
        if type(vx)=="number" and type(vz)=="number" then
            local dirLength=math.sqrt(vx*vx+vz*vz)
            if dirLength>0.000001 then
                local ux,uz=vx/dirLength,vz/dirLength
                referenceLine(terrain,x,z,ux,uz,25,true)
                -- A-only width preview: TWO white dashed lines, symmetric
                -- left/right of the tractor at the recognized work-width.
                -- Keep the confirmed left-side offset unchanged and mirror it.
                -- A standard fallback width is not a real measurement.
                -- Both helpers disappear when B is set.
                if GPSImplementDetector and
                        type(GPSImplementDetector.getData)=="function" then
                    local workWidth,_,_,recognized=GPSImplementDetector.getData(vehicle)
                    if recognized==true and type(workWidth)=="number" and
                            workWidth==workWidth and workWidth>=0.5 and
                            workWidth<=60 then
                        local halfWidth=workWidth*0.5
                        local offsetX,offsetZ=-uz*halfWidth,ux*halfWidth
                        referenceLine(terrain,x+offsetX,z+offsetZ,ux,uz,25,true)
                        referenceLine(terrain,x-offsetX,z-offsetZ,ux,uz,25,true)
                    end
                end
            end
        end
    end
    if not armed and type(renderText)=="function" then
        local minDist=GPSABLineManager.minDistance or 20
        local ready=distance+0.0001>=minDist
        if type(setTextColor)=="function" then
            if ready then setTextColor(.43,1,.25,1) else setTextColor(1,.62,.24,1) end
        end
        if type(setTextBold)=="function" then setTextBold(true) end
        renderText(.37,.105,.023,string.format("A  >  B: %.1f / %.1f m",distance,minDist))
        if type(setTextBold)=="function" then setTextBold(false) end
        if type(setTextColor)=="function" then setTextColor(1,1,1,1) end
        renderText(.37,.078,.016,ready and "B speichern: Alt+B" or "Weiterfahren bis 20 m Luftlinie")
    end
end
