-- Isolated regression check for the SP headland flow.
-- Only simulated vehicle / GIANTS primitives; NOT an in-game confirmation.
local side=1
local center=1.40
local speed=0
local steering=false
local car={getLastSpeed=function() return speed end, spec_drivable={}}
g_client=nil; g_server={}
GPSABLineManager={a={x=0,z=0},b={x=0,z=100}}
GPSSteeringController={enabled=false}
GPSVehicleDetector={
  getCurrentVehicle=function()return car end,
  getPositionNode=function()return 42 end
}
localDirectionToWorld=function(node,x,y,z)
  if z==1 then return 0,0,side end
  return 1,0,0
end
GPSImplementDetector={
  getVerifiedMowerCombo=function()return false end,
  getWidth=function()return 4.45 end,
  hasAttachedPlow=function()return true end
}
GPSDeviceOffsetProbe={
  getData=function()return center,"AI-Marker",true,center-2.225,center+2.225 end
}
GPSLogger={info=function()end}
dofile("scripts/GPSDeviceOffsetAuto.lua")
local D=GPSDeviceOffsetAuto
local ok,msg=D.setEnabled(true)
assert(ok,msg)
assert(not D.ready,"Start should require measured geometry")
for i=1,3 do D.update(250,car) end
assert(D.ready and D.calibratedDir==1 and math.abs(D.center-1.4)<0.0001,
  "First side calibration must finish after 3 samples")
assert(math.abs(D.getCorrection(car,1)-1.4)<0.0001)
-- Simulate headland turn: same plough, new work side, 12 km/h,
-- GPS steering switched OFF. No standstill at any sample.
side=-1;center=-1.38;speed=12
assert(D.getCorrection(car,-1)==nil,
  "The old side must never be applied when heading is reversed")
for i=1,2 do
 D.update(250,car)
 assert(D.getCorrection(car,-1)==nil,
   "New side may not be used until measurement is stable")
end
D.update(250,car)
assert(D.ready and D.calibratedDir==-1 and math.abs(D.center+1.38)<0.0001,
  "Next side must calibrate during forward motion without stopping")
assert(math.abs(D.getCorrection(car,-1)-1.38)<0.0001,
  "New side correction must have correct signed A/B direction")
-- Safety: while GPS steering is engaged, do not recalibrate.
GPSSteeringController.enabled=true
side=1;center=1.55
for i=1,5 do D.update(250,car) end
assert(D.calibratedDir==-1 and D.center<0,
  "No corrections may be changed while steering is engaged")
assert(D.getCorrection(car,1)==nil,
  "Previous-side correction must not leak to reverse heading")
GPSSteeringController.enabled=false
-- Safety: speed >18 km/h does not recalibrate.
speed=22
for i=1,5 do D.update(250,car) end
assert(D.calibratedDir==-1,"High speed must not recalibrate")
-- Slow down, but stay moving for the entire sample window.
speed=10;center=1.40
for i=1,3 do D.update(250,car) end
assert(D.calibratedDir==1 and D.center>0,
  "Subsequent headland must calibrate again while moving")
-- Safety: while turning across the course, refuse new calibration.
GPSSteeringController.enabled=false
side=0
center=-1.35
D.update(250,car)
assert(D.calibratedDir==1,
  "Calibration must not accept perpendicular heading")
print("PASS moving plough-side calibration, direction guard and GPS lock")
