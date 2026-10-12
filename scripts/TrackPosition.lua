-- Reference-locked nearest lane: A/B=track 0 (shown as GPS 1).
-- No field polygon, field ID, contour or segment snapping.
GPSTrackPosition={track=nil,offset=nil,side=nil,valid=false,info="Warte auf A/B",lastUpdate=0}
function GPSTrackPosition.reset()
    local s=GPSTrackPosition
    s.track=nil;s.offset=nil;s.side=nil;s.valid=false;s.info="Warte auf A/B";s.lastUpdate=0
end
function GPSTrackPosition.update(dt,vehicle)
    local s=GPSTrackPosition
    s.lastUpdate=(s.lastUpdate or 0)+(dt or 0)
    if s.lastUpdate<150 then return end
    s.lastUpdate=0
    local a,b=GPSABLineManager.a,GPSABLineManager.b
    if not vehicle or not a or not b then s.reset();return end
    local node=GPSVehicleDetector.getPositionNode(vehicle)
    if not node then s.reset();return end
    local x,_,z=getWorldTranslation(node)
    if type(x)~="number" or type(z)~="number" then s.reset();return end
    local dx,dz=b.x-a.x,b.z-a.z
    local len=math.sqrt(dx*dx+dz*dz)
    if len<20 then s.reset();return end
    local width=GPSImplementDetector.getWidth(vehicle)
    if type(width)~="number" or width<=0 then s.reset();return end
    local nx,nz=-dz/len,dx/len
    local live=(x-a.x)*nx+(z-a.z)*nz
    -- v0.9.9.29: the moved A/B course IS the reference for every pass.
    -- Never subtract the shift a second time: all parallel tracks and their
    -- work-width boundaries move together with the A/B reference.
    local track=math.floor(live/width+0.5)
    local deviation=live-track*width
    s.track=track;s.offset=deviation;s.side=deviation>=0 and "links" or "rechts";s.valid=true
    local number=track>=0 and track+1 or track-1
    s.info=string.format("Spur %d | %.0f cm %s",number,math.abs(deviation)*100,s.side)
end
