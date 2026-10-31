-- TerraLine GPS: geometry uses A/B and working width only. No field or contour API.
-- A course is an infinite mathematical line, not a finite field segment.
GPSTrackGenerator={segments={},info="Warte auf A/B",cacheKey=nil,ready=false}
function GPSTrackGenerator.reset()
    GPSTrackGenerator.segments={}
    GPSTrackGenerator.info="Warte auf A/B"
    GPSTrackGenerator.cacheKey=nil
    GPSTrackGenerator.ready=false
end
function GPSTrackGenerator.generate(_,a,b,width)
    GPSTrackGenerator.reset()
    if not a or not b then GPSTrackGenerator.info="A/B noch nicht gesetzt";return end
    if type(width)~="number" or width<=0 then GPSTrackGenerator.info="Arbeitsbreite fehlt";return end
    local dx,dz=b.x-a.x,b.z-a.z
    if dx*dx+dz*dz<400 then GPSTrackGenerator.info="A/B braucht mindestens 20 m";return end
    GPSTrackGenerator.ready=true
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    local spacing=GPSImplementDetector and GPSImplementDetector.getLaneSpacing(vehicle) or width
    if type(spacing)=="number" and spacing<width-0.01 then
        GPSTrackGenerator.info=string.format("Pflug-Modus | %.2f m Spuren (%.2f m Breite)",spacing,width)
    else
        GPSTrackGenerator.info=string.format("Freie A/B-Spuren | %.2f m (ohne Feldkontur)",width)
    end
end
