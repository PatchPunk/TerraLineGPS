-- TerraLine GPS logging: operational messages by default, high-frequency telemetry only in diagnostics.
GPSLogger = GPSLogger or {}
GPSLogger.prefix = "[TerraLine GPS] "
function GPSLogger.info(message)
    print(GPSLogger.prefix .. tostring(message))
end
function GPSLogger.debug(message)
    if GPSConfig ~= nil and GPSConfig.showDiagnostics == true then
        GPSLogger.info("DIAG " .. tostring(message))
    end
end
