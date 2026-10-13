-- TerraLine GPS: preview between A and B. Rendering only; no steering changes.
GPSABPreviewRenderer={}
local M=GPSABPreviewRenderer
local function height(terrain,x,z)
    return GPSLineVisuals.height(terrain,x,z)
end
local function segment(x1,y1,z1,x2,y2,z2,r,g,b)
    GPSLineVisuals.segment(x1,y1,z1,x2,y2,z2,r,g,b)
end
local function drawA(terrain,x,z)
    local y=height(terrain,x,z)
    -- An A-shaped physical marker, raised above the ground for cockpit view.
    segment(x-.48,y+.18,z,x,y+1.35,z,1,.23,.15)
    segment(x,y+1.35,z,x+.48,y+.18,z,1,.23,.15)
    segment(x-.29,y+.64,z,x+.29,y+.64,z,1,.23,.15)
    -- Cross on the soil makes the location visible from above.
    segment(x-.40,y,z-.40,x+.40,y,z+.40,1,.42,.21)
    segment(x-.40,y,z+.40,x+.40,y,z-.40,1,.42,.21)
end
function M.draw(vehicle)
    local a=GPSABLineManager and GPSABLineManager.a
    if not a or not vehicle then return end
    -- The one-press course already has an internal B. Show A as the fixed
    -- rotation pivot, but do not show the old travel-distance-to-B preview.
    local pivotOnly=GPSABLineManager.singlePointMode and GPSABLineManager.b~=nil
    if GPSABLineManager.b and not pivotOnly then return end
    if type(drawDebugLine)~="function" then return end
    local node=GPSVehicleDetector and GPSVehicleDetector.getPositionNode(vehicle)
    if not node or type(getWorldTranslation)~="function" then return end
    local x,_,z=getWorldTranslation(node)
    if type(x)~="number" or type(z)~="number" then return end
    local dx,dz=x-a.x,z-a.z
    local distance=math.sqrt(dx*dx+dz*dz)
    local terrain=g_currentMission and g_currentMission.terrainRootNode or g_terrainNode
    if distance<=60 then drawA(terrain,a.x,a.z) end
    if pivotOnly then return end
    if distance>0.1 then
        local ux,uz=dx/distance,dz/distance
        -- Only the A->tractor distance is measured, not traveled odometer distance.
        local p=0
        local maxDist=math.min(distance,240)
        while p<maxDist do
            local nextP=math.min(maxDist,p+0.9)
            local x1,z1=a.x+ux*p,a.z+uz*p
            local x2,z2=a.x+ux*nextP,a.z+uz*nextP
            segment(x1,height(terrain,x1,z1),z1,x2,height(terrain,x2,z2),z2,1,0.14,0.12)
            p=nextP+0.65
        end
    end
    if type(renderText)=="function" then
        local minDist=GPSABLineManager.minDistance or 20
        local ready=distance+0.0001>=minDist
        if type(setTextColor)=="function" then
            if ready then setTextColor(.43,1,.25,1) else setTextColor(1,.62,.24,1) end
        end
        if type(setTextBold)=="function" then setTextBold(true) end
        renderText(.37,.105,.023,string.format("A  >  B: %.1f / %.1f m",distance,minDist))
        if type(setTextBold)=="function" then setTextBold(false) end
        if type(setTextColor)=="function" then setTextColor(1,1,1,1) end
        renderText(.37,.078,.016,ready and "B nur per gsGPSB" or "Weiterfahren bis 20 m Luftlinie")
    end
end
