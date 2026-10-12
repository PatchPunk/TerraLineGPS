-- TerraLine GPS 0.9.9.55 | Native FS25 vehicle shop configuration.
-- Follows the stock Precision Farming crop/manure sensor configuration path.
GPSVehicleEquipment = {configName = "terraLineGPS", price = 10000, hookInstalled = false}
local E = GPSVehicleEquipment
local function report(message)
    if GPSLogger and GPSLogger.info then GPSLogger.info("AUSSTATTUNG: "..tostring(message)) end
end

-- Category names vary between maps and additional vehicle packs. Only
-- self-propelled/driver-operated categories are allowed, not implements.
local eligibleCategories = {
    TRACTORSS=true, TRACTORSM=true, TRACTORSL=true, TRACTORSXL=true,
    HARVESTERS=true, FORAGEHARVESTERS=true, COTTONHARVESTERS=true,
    POTATOHARVESTERS=true, BEETHARVESTERS=true, SUGARCANEHARVESTERS=true,
    VEGETABLEHARVESTERS=true, SPRAYERS=true, MOWERS=true, WINDROWERS=true,
    BALERS=true, GRAPEHARVESTERS=true, OLIVEHARVESTERS=true,
    SKIDSTEERS=true, TELEHANDLERS=true, WHEELLOADERS=true,
    FRONTLOADERS=true, FORESTRYMACHINES=true,
}
local eligibleTypes = {
    tractor=true, articulatedTractor=true, combineDrivable=true,
    forageHarvester=true, cottonHarvester=true, potatoHarvester=true,
    beetHarvester=true, grapeHarvester=true, oliveHarvester=true,
    selfPropelledSprayer=true, selfPropelledMower=true,
    selfPropelledWindrower=true, selfPropelledBaler=true,
    woodHarvester=true, wheelLoader=true, teleHandler=true,
    skidSteer=true,
}
function E.isEligible(xmlFile, storeItem)
    if xmlFile==nil or type(xmlFile.getValue)~="function" then return false end
    local category=storeItem and tostring(storeItem.categoryName or ""):upper() or ""
    local vehicleType=xmlFile:getValue("vehicle#type", "")
    local allowCategory=eligibleCategories[category] == true
    local allowType=eligibleTypes[vehicleType] == true
    if not (allowCategory or allowType) then return false end
    -- A shared shop category such as SPRAYERS can also contain implements.
    -- Both nodes must be present: an engine AND a place for the driver.
    -- Do not silently offer a 10,000 EUR GPS unit on unpowered trailers.
    if type(xmlFile.hasProperty)~="function" then return false end
    if not xmlFile:hasProperty("vehicle.motorized") then return false end
    if not xmlFile:hasProperty("vehicle.enterable") then return false end
    return true
end

function E.ensureRegistered()
    if type(g_vehicleConfigurationManager)~="table" then return false end
    if type(g_vehicleConfigurationManager.addConfigurationType)~="function" then return false end
    if type(g_vehicleConfigurationManager.getConfigurationDescByName)=="function" then
        local existing=g_vehicleConfigurationManager:getConfigurationDescByName(E.configName)
        if existing~=nil then return true end
    end
    if type(VehicleConfigurationItem)~="table" then return false end
    g_vehicleConfigurationManager:addConfigurationType(E.configName,"TerraLine GPS",nil,VehicleConfigurationItem)
    report("Native Shop-Konfiguration registriert (+10.000 EUR)")
    return true
end

function E.getConfigurationsFromXML(superFunc, manager, xmlFile, key, baseDir, customEnvironment, isMod, storeItem, ...)
    -- Register *before* the GIANTS loader runs so the descriptor is available
    -- when the game builds the standard vehicle shop UI/configuration streams.
    E.ensureRegistered()
    local configs,defaults=superFunc(manager,xmlFile,key,baseDir,customEnvironment,isMod,storeItem,...)
    if not E.isEligible(xmlFile,storeItem) then return configs,defaults end
    if not E.ensureRegistered() or type(VehicleConfigurationItem.new)~="function" then
        return configs,defaults
    end
    configs=configs or {}; defaults=defaults or {}
    if configs[E.configName]~=nil then return configs,defaults end
    local without=VehicleConfigurationItem.new(E.configName)
    without:setIndex(1)
    without.name="Ohne TerraLine GPS"
    without.price=0; without.isDefault=true; without.isYesNoOption=true
    local with=VehicleConfigurationItem.new(E.configName)
    with:setIndex(2)
    with.name="Mit TerraLine GPS"
    with.price=E.price; with.isDefault=false; with.isYesNoOption=true
    configs[E.configName]={without,with}
    if ConfigurationUtil and ConfigurationUtil.getDefaultConfigIdFromItems then
        defaults[E.configName]=ConfigurationUtil.getDefaultConfigIdFromItems(configs[E.configName])
    else
        defaults[E.configName]=1
    end
    return configs,defaults
end

function E.install()
    if E.hookInstalled then return true end
    if type(ConfigurationUtil)~="table" or type(ConfigurationUtil.getConfigurationsFromXML)~="function" or
       type(Utils)~="table" or type(Utils.overwrittenFunction)~="function" then
        report("WARNUNG: Shop-Konfigurations-API noch nicht bereit")
        return false
    end
    E.ensureRegistered()
    ConfigurationUtil.getConfigurationsFromXML=Utils.overwrittenFunction(
        ConfigurationUtil.getConfigurationsFromXML,E.getConfigurationsFromXML)
    E.hookInstalled=true
    report("Native Fahrzeugkonfiguration eingebunden")
    return true
end

function E.isInstalled(vehicle)
    if vehicle==nil or type(vehicle.configurations)~="table" then return false end
    return tonumber(vehicle.configurations[E.configName])==2
end
function E.getStatus(vehicle)
    if not E.isInstalled(vehicle) then return nil end
    if GPSFieldTest and GPSFieldTest.masterEnabled and
       GPSSteeringController and GPSSteeringController.enabled and GPSSteeringController.vehicle==vehicle then
        return "TL AUTO  |  AKTIV", 0.46, 1.00, 0.18
    end
    if GPSFieldTest and GPSFieldTest.masterEnabled then
        return "TL GPS  |  BEREIT", 0.46, 1.00, 0.18
    end
    return "TL GPS  |  AUS", 0.65, 0.67, 0.70
end
E.install()
