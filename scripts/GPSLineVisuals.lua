-- TerraLine GPS v0.9.9.26: one, two or three reliable debug lines.
-- Each lane remains centered at exactly the same underlying GPS reference.
-- No triangle-based ribbons (not displayed reliably in LS25).
GPSLineVisuals={}
local M=GPSLineVisuals
local FIXED_HEIGHT=0.10
local STROKE_SPACING=0.07
function M.height(terrain,x,z)
    if terrain and type(getTerrainHeightAtWorldPos)=="function" then
        local ok,y=pcall(getTerrainHeightAtWorldPos,terrain,x,0,z)
        if ok and type(y)=="number" then return y+FIXED_HEIGHT end
    end
    return FIXED_HEIGHT
end
function M.segment(x1,y1,z1,x2,y2,z2,r,g,b)
    if type(drawDebugLine)~="function" then return end
    local n=(GPSConfig and GPSConfig.lineStrokes) or 1
    if type(n)~="number" or n~=n then n=1 end
    n=math.max(1,math.min(3,math.floor(n+0.5)))
    local dx,dz=x2-x1,z2-z1
    local len=math.sqrt(dx*dx+dz*dz)
    if len<0.00001 then
        drawDebugLine(x1,y1,z1,r,g,b,x2,y2,z2,r,g,b,false)
        return
    end
    local nx,nz=-dz/len,dx/len
    for i=1,n do
        local offset=(i-(n+1)*0.5)*STROKE_SPACING
        local ox,oz=nx*offset,nz*offset
        drawDebugLine(x1+ox,y1,z1+oz,r,g,b,x2+ox,y2,z2+oz,r,g,b,false)
    end
end
