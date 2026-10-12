-- TerraLine GPS - version 0.9.9.40 approved pixel-art navigation symbols.
-- Raster icons are loaded once per open menu; steering calculations never use them.
GPSMenuSymbols = {}
local filenames = {
    [1]="gui/icons/spurfuehrung.dds",
    [3]="gui/icons/speicher.dds",
    [4]="gui/icons/info_version.dds"
}
local function box(s,x,t,w,h,col)
    if type(drawFilledRect)~="function" then return end
    drawFilledRect(s.pageX+x*s.pageW,s.pageY+(1-t-h)*s.pageH,w*s.pageW,h*s.pageH,col[1],col[2],col[3],col[4])
end
-- A width/height pair in screen-local coordinates that is physically square.
local function squareWidth(s,h)
    local ratio=9/16
    if type(g_pixelSizeX)=="number" and type(g_pixelSizeY)=="number" and
       g_pixelSizeX>0 and g_pixelSizeY>0 then
        ratio=g_pixelSizeX/g_pixelSizeY
    elseif type(g_screenWidth)=="number" and type(g_screenHeight)=="number" and
       g_screenWidth>0 and g_screenHeight>0 then
        ratio=g_screenHeight/g_screenWidth
    end
    return h*s.pageH/s.pageW*ratio
end
local function drawImage(s,id,centerX,top,h,key)
    if type(Overlay)~="table" or type(Overlay.new)~="function" then return false end
    local filename=filenames[id]
    local modDir=(GPSMenu and GPSMenu.modDir) or g_currentModDirectory
    if not (filename and modDir and s.pageW and s.pageH) then return false end
    s.terraIconOverlays=s.terraIconOverlays or {}
    s.terraIconFailed=s.terraIconFailed or {}
    if s.terraIconFailed[key] then return false end
    local overlay=s.terraIconOverlays[key]
    if overlay==nil then
        local w=squareWidth(s,h)
        local x=centerX-w*.5
        local px=s.pageX+x*s.pageW
        local py=s.pageY+(1-top-h)*s.pageH
        local ok,created=pcall(Overlay.new,modDir..filename,px,py,w*s.pageW,h*s.pageH)
        if not ok or not created then
            s.terraIconFailed[key]=true
            return false
        end
        overlay=created
        s.terraIconOverlays[key]=overlay
    end
    if overlay.overlayId==0 then return false end
    if type(overlay.render)~="function" then return false end
    overlay:render()
    return true
end
local function drawFallback(s,id,x,t,color)
 local c=color or {.45,.92,.22,1};local charcoal={.027,.057,.065,1};local silver={.88,.94,.91,1}
 if id==1 then
    -- Treaded tractor from above between GPS tramlines.
    for _,dx in ipairs({-.020,.020}) do
       box(s,x+dx-.002,t-.005,.003,.053,c)
       for i=0,3 do box(s,x+dx-.002,t+.002+i*.013,.003,.006,charcoal) end
    end
    for _,dx in ipairs({-.011,.009}) do
       box(s,x+dx,t+.004,.006,.016,charcoal)
       box(s,x+dx,t+.027,.007,.020,charcoal)
    end
    box(s,x-.006,t+.005,.012,.041,c)
    box(s,x-.004,t+.022,.008,.014,silver)
    box(s,x-.002,t+.047,.004,.009,c)
    box(s,x-.009,t+.056,.018,.004,c)
 elseif id==3 then
    -- Storage: clear floppy-disk icon with contrasting label.
    box(s,x-.017,t+.001,.034,.051,c)
    box(s,x-.010,t+.004,.019,.018,charcoal)
    box(s,x+.004,t+.006,.004,.009,silver)
    box(s,x-.012,t+.030,.024,.018,silver)
    box(s,x-.008,t+.036,.016,.003,charcoal)
 elseif id==4 then
    -- Book: instruction / changelog rather than fake gear.
    box(s,x-.018,t+.007,.016,.045,c)
    box(s,x+.002,t+.007,.016,.045,c)
    box(s,x-.015,t+.012,.011,.032,charcoal)
    box(s,x+.004,t+.012,.011,.032,charcoal)
    box(s,x-.013,t+.018,.007,.002,silver)
    box(s,x+.006,t+.018,.007,.002,silver)
    box(s,x-.013,t+.026,.007,.002,silver)
    box(s,x+.006,t+.026,.007,.002,silver)
    box(s,x-.002,t+.007,.004,.048,silver)
 end
end

-- Coordinates match the existing callers; icons are fitted into old sidebar slots.
function GPSMenuSymbols.draw(s,id,x,t,color)
    -- t is the old icon anchor, 0.026 below each navigation item top.
    if not drawImage(s,id,x,t-.006,.071,"nav"..tostring(id)) then
        drawFallback(s,id,x,t,color)
    end
end
function GPSMenuSymbols.header(s,x,t)
    if not drawImage(s,1,x,t-.001,.056,"header") then
        drawFallback(s,1,x,t,{.45,.92,.22,1})
    end
end
-- UI overlay textures must be deleted when this menu closes.
function GPSMenuSymbols.onClose(s)
    if not s then return end
    for _,o in pairs(s.terraIconOverlays or {}) do
        if o and type(o.delete)=="function" then pcall(o.delete,o) end
    end
    s.terraIconOverlays=nil
    s.terraIconFailed=nil
end
