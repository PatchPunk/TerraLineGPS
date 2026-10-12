-- TerraLine GPS MP: server-authoritative farm course requests/snapshots.
-- No GPS steering, HUD, or vehicle physics state is transmitted by this event.
GPSFarmCourseEvent = {}
local E = GPSFarmCourseEvent
local E_mt = Class(E, Event)
InitEventClass(E, "GPSFarmCourseEvent")
E.REQUEST = 1
E.SAVE = 2
E.DELETE = 3
E.SNAPSHOT = 4
E.RESULT = 5

function E.emptyNew()
    return Event.new(E_mt)
end

function E.new(operation, payload)
    local self = E.emptyNew()
    self.operation = operation
    self.payload = payload or {}
    return self
end

function E:writeStream(streamId, connection)
    streamWriteUInt8(streamId, self.operation)
    local p = self.payload
    if self.operation == E.SAVE then
        streamWriteString(streamId, tostring(p.name or ""))
        streamWriteFloat32(streamId, p.ax or 0)
        streamWriteFloat32(streamId, p.az or 0)
        streamWriteFloat32(streamId, p.bx or 0)
        streamWriteFloat32(streamId, p.bz or 0)
        streamWriteFloat32(streamId, p.width or 0)
        streamWriteFloat32(streamId, p.offset or 0)
    elseif self.operation == E.DELETE then
        streamWriteUInt16(streamId, p.id or 0)
    elseif self.operation == E.RESULT then
        streamWriteUInt8(streamId, p.farmId or 0)
        streamWriteUInt8(streamId, p.requestOperation or 0)
        streamWriteBool(streamId, p.ok==true)
        streamWriteString(streamId, tostring(p.message or ""):sub(1,180))
    elseif self.operation == E.SNAPSHOT then
        streamWriteUInt8(streamId, p.farmId or 0)
        local courses = p.courses or {}
        local count = math.min(256, #courses)
        streamWriteUInt16(streamId, count)
        for i=1,count do
            local c = courses[i]
            streamWriteUInt16(streamId, c.id)
            streamWriteString(streamId, c.name)
            streamWriteFloat32(streamId, c.ax)
            streamWriteFloat32(streamId, c.az)
            streamWriteFloat32(streamId, c.bx)
            streamWriteFloat32(streamId, c.bz)
            streamWriteFloat32(streamId, c.width or 0)
            streamWriteFloat32(streamId, c.offset or 0)
            streamWriteUInt16(streamId, c.fieldId or 0)
        end
    end
end

function E:readStream(streamId, connection)
    local operation = streamReadUInt8(streamId)
    self.operation = operation
    local p = {}
    if operation == E.SAVE then
        p.name = streamReadString(streamId)
        p.ax = streamReadFloat32(streamId)
        p.az = streamReadFloat32(streamId)
        p.bx = streamReadFloat32(streamId)
        p.bz = streamReadFloat32(streamId)
        p.width = streamReadFloat32(streamId)
        p.offset = streamReadFloat32(streamId)
    elseif operation == E.DELETE then
        p.id = streamReadUInt16(streamId)
    elseif operation == E.RESULT then
        p.farmId = streamReadUInt8(streamId)
        p.operation = streamReadUInt8(streamId)
        p.ok = streamReadBool(streamId)
        p.message = streamReadString(streamId)
    elseif operation == E.SNAPSHOT then
        p.farmId = streamReadUInt8(streamId)
        local count = streamReadUInt16(streamId)
        p.courses = {}
        for i=1,count do
            local course = {
                id=streamReadUInt16(streamId),
                name=streamReadString(streamId),
                ax=streamReadFloat32(streamId),
                az=streamReadFloat32(streamId),
                bx=streamReadFloat32(streamId),
                bz=streamReadFloat32(streamId),
                width=streamReadFloat32(streamId),
                offset=streamReadFloat32(streamId),
                fieldId=streamReadUInt16(streamId)
            }
            -- The server limits each farm to 256 courses. Still consume a
            -- malformed larger stream without retaining unbounded records.
            if i<=256 then p.courses[#p.courses+1] = course end
        end
    else
        -- Unknown opcode has no payload and must never mutate game state.
        return
    end
    self.payload = p
    self:run(connection)
end

function E:run(connection)
    if connection == nil then return end
    if connection:getIsServer() then
        -- Clients ONLY accept snapshots from their authoritative server.
        if GPSCourseManager then
            if self.operation == E.SNAPSHOT then GPSCourseManager.receiveSnapshot(self.payload)
            elseif self.operation == E.RESULT then GPSCourseManager.receiveResult(self.payload) end
        end
    else
        -- The server derives the real farm ID from this connection; never
        -- trust any farm ID or rights claimed by a client-side payload.
        if g_server ~= nil and GPSCourseManager then
            GPSCourseManager.handleClientRequest(connection, self.operation, self.payload)
        end
    end
end

function E.sendToServer(operation, payload)
    if g_server ~= nil then return false end
    if g_client==nil or type(g_client.getServerConnection)~="function" then return false end
    local connection=g_client:getServerConnection()
    if not connection or type(connection.sendEvent)~="function" then return false end
    connection:sendEvent(E.new(operation, payload))
    return true
end

function E.sendSnapshot(connection, farmId, courses)
    if g_server==nil or not connection or type(connection.sendEvent)~="function" then return end
    connection:sendEvent(E.new(E.SNAPSHOT, {farmId=farmId,courses=courses}))
end

function E.sendResult(connection, operation, farmId, ok, message)
    if g_server==nil or not connection or type(connection.sendEvent)~="function" then return end
    connection:sendEvent(E.new(E.RESULT, {farmId=farmId,requestOperation=operation,
        ok=ok==true,message=message or ""}))
end
