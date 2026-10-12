-- TerraLine GPS | Interne Projektmarke: Hallo hier bin ich, der CODE! | TL-GPS/2026-10-12
-- TerraLine GPS v0.9.9.23: user-defined A/B only; independent of farmland.
local GPS_MOD_DIRECTORY = g_currentModDirectory
GPSFieldTest = {isLoaded=false,masterEnabled=false,clock=0,totalMs=0,status="Start",vehicleStatus="-",currentVehicle=nil,
 keyRegistered=false,keyRetry=0,keyABRegistered=false,keyABRetry=0,keyPressedAB=false,
 keyPressedAssist=false,lastActionAt=-9999,keyboardDiagnosticDone=false}

-- Short activation cue; optional if the sound API is unavailable in this game build.
function GPSFieldTest:loadActivationBeep()
    if self.activationBeepSample~=nil then return end
    if type(createSample)~="function" or type(loadSample)~="function" then
        GPSLogger.info("GPS Piepton: Audio-Sample-API nicht verfuegbar")
        return
    end
    local ok,sample=pcall(createSample,"GPSFieldTestActivation")
    if not ok or sample==nil then
        GPSLogger.info("GPS Piepton: Sample konnte nicht erstellt werden")
        return
    end
    local modDir=GPS_MOD_DIRECTORY or g_currentModDirectory or (g_modsDirectory and (g_modsDirectory.."FS25_GPSFieldTest_v0_9_6_2/"))
    if not modDir then
        if type(delete) == "function" then pcall(delete,sample) end
        GPSLogger.info("GPS Piepton: Modpfad nicht verfuegbar")
        return
    end
    local loaded,success=pcall(loadSample,sample,modDir.."sounds/gpsActivate.wav",false)
    if not loaded or success==false then
        if type(delete) == "function" then pcall(delete,sample) end
        GPSLogger.info("GPS Piepton: Laden fehlgeschlagen: "..tostring(success))
        return
    end
    self.activationBeepSample=sample
    GPSLogger.info("GPS Piepton: Sample geladen")
end
function GPSFieldTest:playActivationBeep()
    if not self.activationBeepSample then self:loadActivationBeep() end
    if not self.activationBeepSample or type(playSample)~="function" then
        GPSLogger.info("GPS Piepton: Wiedergabe nicht verfuegbar")
        return
    end
    local ok,err=pcall(playSample,self.activationBeepSample,1,1,0,0,0)
    if not ok then GPSLogger.info("GPS Piepton: Wiedergabefehler: "..tostring(err)) end
end
function GPSFieldTest:unloadActivationBeep()
    if self.activationBeepSample~=nil and type(delete)=="function" then pcall(delete,self.activationBeepSample) end
    self.activationBeepSample=nil
end

-- Separate, lower-pitched acknowledgement when the GPS controller disengages.
function GPSFieldTest:loadDeactivationBeep()
    if self.deactivationBeepSample~=nil then return end
    if type(createSample)~="function" or type(loadSample)~="function" then return end
    local ok,sample=pcall(createSample,"GPSFieldTestDeactivation")
    if not ok or sample==nil then return end
    local modDir=GPS_MOD_DIRECTORY or g_currentModDirectory
    if not modDir then
        if type(delete)=="function" then pcall(delete,sample) end
        return
    end
    local loaded,success=pcall(loadSample,sample,modDir.."sounds/gpsDeactivate.wav",false)
    if not loaded or success==false then
        if type(delete)=="function" then pcall(delete,sample) end
        GPSLogger.info("GPS AUS-Ton: Sample konnte nicht geladen werden")
        return
    end
    self.deactivationBeepSample=sample
    GPSLogger.info("GPS AUS-Ton: Sample geladen")
end
function GPSFieldTest:playDeactivationBeep()
    if not self.deactivationBeepSample then self:loadDeactivationBeep() end
    if not self.deactivationBeepSample or type(playSample)~="function" then return end
    local ok,err=pcall(playSample,self.deactivationBeepSample,1,1,0,0,0)
    if not ok then GPSLogger.info("GPS AUS-Ton: Wiedergabefehler: "..tostring(err)) end
end
function GPSFieldTest:syncAssistAudio()
    local active=GPSSteeringController.enabled==true
    if self.lastAssistAudioState==nil then
        self.lastAssistAudioState=active
        self.assistLinesActivatedAtMs=active and (self.totalMs or 0) or nil
        return
    end
    if active==self.lastAssistAudioState then return end
    self.lastAssistAudioState=active
    -- The clock only controls visuals; the steering controller remains intact.
    self.assistLinesActivatedAtMs=active and (self.totalMs or 0) or nil
    if active then
        self:playActivationBeep()
    else
        self:playDeactivationBeep()
        GPSLogger.info("GPS AUS-Ton: Abschaltung bestaetigt ("..tostring(GPSSteeringController.reason or "unbekannt")..")")
    end
end

function GPSFieldTest:loadMap()
    self.isLoaded=true
    -- TerraLine stays OFF until the player explicitly enables it (Alt+T/menu).
    -- The saved course database is available to the menu even while OFF.
    self.masterEnabled=false
    self.defaultPowerHotkeyHeld=false
    self.lastPowerToggleAt=-9999
    if GPSCourseManager then GPSCourseManager.reset() end
    if GPSDisplaySettings then GPSDisplaySettings.reset();GPSDisplaySettings.ensureLoaded() end
    self.registeredOnce_MENU=nil
    self.defaultMenuHotkeyHeld=false
    self.defaultShiftRightHeld=false
    self.defaultShiftLeftHeld=false
    self.shiftHeld=nil
    self.menuFallbackNotice=false
    self.clock=0; self.totalMs=0; self.status="A/B bereit";self.vehicleStatus="-"
    self.currentVehicle=nil
    self.registeredOnce_AB=nil;self.registeredOnce_ASSIST=nil;self.inputRegistrationWarning=nil
    -- Never carry a previous savegame's unsaved A/B line into a new map.
    if GPSABLineManager then GPSABLineManager.clear() end
    if GPSImplementDetector then GPSImplementDetector.override=nil end
    GPSTrackGenerator.reset();GPSTrackPosition.reset();GPSSteeringController.stop("Aus")
    -- Optional modules may fail independently; do not block game update/input.
    self.autoMirrorFaulted=false
    self.deviceOffsetFaulted=false
    self.deviceAutoFaulted=false
    if type(GPSAutoMirror)=="table" and type(GPSAutoMirror.reset)=="function" then
        GPSAutoMirror.reset()
    else
        self.autoMirrorFaulted=true
        GPSLogger.info("WARNUNG: Auto-Wende Modul fehlt oder nicht initialisiert")
    end
    if type(GPSDeviceOffsetAuto)=="table" and type(GPSDeviceOffsetAuto.reset)=="function" then GPSDeviceOffsetAuto.reset() else self.deviceAutoFaulted=true end
    if type(GPSDeviceOffsetProbe)=="table" then
        GPSDeviceOffsetProbe.lastSignature=nil
        GPSDeviceOffsetProbe.clock=0
    else
        self.deviceOffsetFaulted=true
        GPSLogger.info("WARNUNG: Geraeteversatz-Messmodul fehlt")
    end
    self.keyRegistered=false;self.keyABRegistered=false;self.keyRetry=0;self.lastKeyDiagnostic=nil
    GPSLogger.info("v0.9.8.5 gestartet: frei belegbare Eingaben A/B und GPS, EIN/AUS-Ton")
    self.lastAssistAudioState=false
    self.assistLinesActivatedAtMs=nil
    self:loadActivationBeep()
    self:loadDeactivationBeep()
end
function GPSFieldTest:deleteMap()
    GPSSteeringDiagnostics.stop("Karte verlassen")
    self.keyRegistered=false;self.keyABRegistered=false
    self:unloadActivationBeep()
    if self.deactivationBeepSample~=nil and type(delete)=="function" then pcall(delete,self.deactivationBeepSample) end
    self.deactivationBeepSample=nil;self.lastAssistAudioState=nil;self.assistLinesActivatedAtMs=nil
    if GPSCourseManager then GPSCourseManager.reset() end
    if GPSABLineManager then GPSABLineManager.clear() end
    if GPSImplementDetector then GPSImplementDetector.override=nil end
    if GPSDisplaySettings then GPSDisplaySettings.reset() end
    self.isLoaded=false;self.masterEnabled=false;self.currentVehicle=nil;self.shiftHeld=nil
    self.defaultPowerHotkeyHeld=false
    self.defaultShiftRightHeld=false;self.defaultShiftLeftHeld=false
    GPSTrackGenerator.reset();GPSTrackPosition.reset();GPSSteeringController.stop("Karte verlassen")
    if type(GPSAutoMirror)=="table" and type(GPSAutoMirror.reset)=="function" then GPSAutoMirror.reset() end
    if type(GPSDeviceOffsetAuto)=="table" and type(GPSDeviceOffsetAuto.reset)=="function" then GPSDeviceOffsetAuto.reset() end
end

-- Draw the GPS status inside the ORIGINAL GIANTS speedometer, as in the
-- DEF-style example (steering-wheel symbol + GPS next to the vertical gauges).
-- We never create another HUD panel and never change the vehicle's actual AI
-- steering state. Only the native HUD draw is temporarily given GPS values.
--
-- Lane numbering: A/B=1, right=2/3/..., left=-2/-3/..., no 0 or -1.
-- It remains visible with steering assistance switched OFF, as long as the
-- A/B reference and a valid lane position exist.
local function getNativeGpsLaneText()
    if GPSABLineManager.b == nil or not GPSTrackPosition.valid then
        return "GPS"
    end
    local index=GPSTrackPosition.track
    if type(index)~="number" then return "GPS" end
    local number=index>=0 and index+1 or index-1
    return "GPS "..tostring(number)
end

function GPSFieldTest:installNativeHudBridge()
    if self.nativeHudHookInstalled or type(SpeedMeterDisplay)~="table" or type(SpeedMeterDisplay.draw)~="function" then
        return
    end
    self.nativeHudHookInstalled=true
    local originalDraw=SpeedMeterDisplay.draw
    SpeedMeterDisplay.draw=function(display,...)
        local vehicle=display and display.vehicle
        local ownVehicle=GPSVehicleDetector.getCurrentVehicle()
        -- Stay strictly inside the controlled vehicle's native speedometer.
        local bridge=GPSFieldTest.masterEnabled~=false and vehicle~=nil and ownVehicle==vehicle
            and GPSABLineManager.b~=nil
            and type(vehicle.getAIAutomaticSteeringState)=="function"
            and type(vehicle.getAIModeSelection)=="function"
            and type(AIAutomaticSteering)=="table" and type(AIAutomaticSteering.STATE)=="table"
            and type(AIModeSelection)=="table" and type(AIModeSelection.MODE)=="table"
            and type(display.aiReadyText)=="string" and type(display.aiActiveText)=="string"

        local oldSteeringAccessor,oldModeAccessor,oldReadyText,oldActiveText
        if bridge then
            -- rawget/rawset ensure that any class/metatable methods are restored
            -- exactly, even after an exception in GIANTS' original draw function.
            oldSteeringAccessor=rawget(vehicle,"getAIAutomaticSteeringState")
            oldModeAccessor=rawget(vehicle,"getAIModeSelection")
            oldReadyText=display.aiReadyText
            oldActiveText=display.aiActiveText

            vehicle.getAIAutomaticSteeringState=function(_)
                if GPSSteeringController.enabled then return AIAutomaticSteering.STATE.ACTIVE end
                return AIAutomaticSteering.STATE.AVAILABLE
            end
            vehicle.getAIModeSelection=function(_)
                return AIModeSelection.MODE.STEERING_ASSIST
            end

            -- The built-in HUD draws the steering icon, the colored GPS state
            -- and this text at its own scaled coordinates. No separate boxes,
            -- offset labels or duplicate "GPS" are drawn by our mod.
            local label=getNativeGpsLaneText()
            display.aiReadyText=label
            display.aiActiveText=label
        end

        local ok,err=pcall(originalDraw,display,...)
        if bridge then
            rawset(vehicle,"getAIAutomaticSteeringState",oldSteeringAccessor)
            rawset(vehicle,"getAIModeSelection",oldModeAccessor)
            display.aiReadyText=oldReadyText
            display.aiActiveText=oldActiveText
        end
        if not ok then error(err) end
    end
    GPSLogger.info("GIANTS Tacho GPS integration ready (native symbol, GPS + lane number)")
end

-- The configurable LS25 action remains the primary menu shortcut.
-- Some installations do not deliver a callback for three-key combinations.
-- In that case we also detect the *default* Ctrl+Alt+M combination directly.
-- Edge-triggered: holding the keys cannot immediately close the menu again.
-- The menu uses the same native two-key InputAction mechanism as the
-- working Alt+B and Alt+X bindings. No additional global raw key hook.
-- Secondary Alt+M detection in the standard game update loop. It only
-- toggles on a rising edge and is suppressed during an unrelated GUI.
-- Primary input remains the configurable GPS_FIELD_MENU_TOGGLE action.
function GPSFieldTest:pollDefaultMenuHotkey()
    local k=Input
    if type(k)~="table" or type(k.isKeyPressed)~="function" or not k.KEY_m or not k.KEY_lalt then
        return
    end
    local ok,pressed=pcall(function()
        local alt=k.isKeyPressed(k.KEY_lalt) or (k.KEY_ralt and k.isKeyPressed(k.KEY_ralt))
        return alt and k.isKeyPressed(k.KEY_m)
    end)
    if not ok then return end
    local wasPressed=self.defaultMenuHotkeyHeld==true
    self.defaultMenuHotkeyHeld=pressed==true
    if pressed and not wasPressed then
        if GPSMenu and (GPSMenu.isOpen() or not (g_gui and g_gui.currentGui~=nil)) then
            local now=self.totalMs or 0
            if now-(self.lastMenuToggleAt or -9999)>=450 then
                self.lastMenuToggleAt=now
                GPSLogger.info("GPS Menue: Alt+M erkannt (Tastatur-Fallback)")
                GPSMenu.toggle()
            end
        end
    end
end

-- GIANTS can register an Alt+PageUp/PageDown action without delivering a
-- usable press callback on some keyboard layouts. Poll the exact DEFAULT
-- shortcuts independently, like the established Alt+M fallback. Configured
-- alternate action bindings still work through onShiftKey().
function GPSFieldTest:pollDefaultShiftHotkeys()
    local k=Input
    if type(k)~="table" or type(k.isKeyPressed)~="function" or not k.KEY_lalt then return end
    if g_gui and g_gui.currentGui~=nil then
        self.defaultShiftRightHeld=false;self.defaultShiftLeftHeld=false
        self.shiftHeld=nil
        return
    end
    local ok,right,left=pcall(function()
        local alt=k.isKeyPressed(k.KEY_lalt) or (k.KEY_ralt and k.isKeyPressed(k.KEY_ralt))
        return alt and k.KEY_pageup and k.isKeyPressed(k.KEY_pageup) or false,
               alt and k.KEY_pagedown and k.isKeyPressed(k.KEY_pagedown) or false
    end)
    if not ok then return end
    if right and not self.defaultShiftRightHeld then
        if not (self.shiftHeld and self.shiftHeld.direction==1) then
            GPSLogger.info("GPS Alt+Bild HOCH erkannt (Tastatur-Fallback)")
            self:onShiftKey(1,1)
        end
    elseif not right and self.defaultShiftRightHeld then
        self:onShiftKey(1,0)
    end
    if left and not self.defaultShiftLeftHeld then
        if not (self.shiftHeld and self.shiftHeld.direction==-1) then
            GPSLogger.info("GPS Alt+Bild RUNTER erkannt (Tastatur-Fallback)")
            self:onShiftKey(-1,1)
        end
    elseif not left and self.defaultShiftLeftHeld then
        self:onShiftKey(-1,0)
    end
    self.defaultShiftRightHeld=right
    self.defaultShiftLeftHeld=left
end

-- Master power is separate from Alt+X. The GPS menu stays accessible when powered OFF.
function GPSFieldTest:isMasterEnabled()
    return self.masterEnabled~=false
end
function GPSFieldTest:setMasterEnabled(enabled)
    enabled=enabled==true
    if self.masterEnabled==enabled then
        return "TerraLine GPS "..(enabled and "EIN" or "AUS")
    end
    self.masterEnabled=enabled
    self.shiftHeld=nil
    self.defaultShiftRightHeld=false
    self.defaultShiftLeftHeld=false
    if not enabled then
        -- Immediately release ALL active steering/diagnostic commands;
        -- keep A/B, course manager, widths and stored device corrections intact.
        GPSSteeringController.stop("TerraLine Hauptschalter AUS")
        if GPSSteeringDiagnostics then GPSSteeringDiagnostics.stop("TerraLine GPS AUS") end
        self:syncAssistAudio()
        self.assistLinesActivatedAtMs=nil
        if GPSAutoMirror then GPSAutoMirror.reset() end
    else
        -- Turning power on NEVER arms steering automatically.
        GPSSteeringController.stop("TerraLine bereit (Lenkung aus)")
        if GPSTrackPosition then GPSTrackPosition.lastUpdate=150 end
        if GPSAutoMirror then GPSAutoMirror.reset() end
    end
    local msg="TerraLine GPS "..(enabled and "EIN - Lenkung bleibt AUS" or "AUS - Lenkung, Linien und Tacho-Einblendung deaktiviert")
    GPSLogger.info("HAUPTSCHALTER: "..msg)
    return msg
end
function GPSFieldTest:commandMaster(value)
    local mode=tostring(value or "toggle"):lower()
    if mode=="toggle" then return self:setMasterEnabled(not self:isMasterEnabled()) end
    if mode=="on" or mode=="an" or mode=="1" then return self:setMasterEnabled(true) end
    if mode=="off" or mode=="aus" or mode=="0" then return self:setMasterEnabled(false) end
    return "Benutzung: gsGPSPower [on|off|toggle]"
end
-- Fallback for the DEFAULT Alt+T binding; the rebindable InputAction is primary.
-- The 450-ms shared debounce prevents a double flip when both paths fire.
function GPSFieldTest:pollDefaultPowerHotkey()
    local k=Input
    if type(k)~="table" or type(k.isKeyPressed)~="function" or not k.KEY_t or not k.KEY_lalt then return end
    if g_gui and g_gui.currentGui~=nil then
        self.defaultPowerHotkeyHeld=false
        return
    end
    local ok,pressed=pcall(function()
        return (k.isKeyPressed(k.KEY_lalt) or (k.KEY_ralt and k.isKeyPressed(k.KEY_ralt)))
            and k.isKeyPressed(k.KEY_t)
    end)
    if not ok then return end
    local was=self.defaultPowerHotkeyHeld==true
    self.defaultPowerHotkeyHeld=pressed==true
    if pressed and not was then
        local now=self.totalMs or 0
        if now-(self.lastPowerToggleAt or -9999)>=450 then
            self.lastPowerToggleAt=now
            GPSLogger.info("Hauptschalter Alt+T erkannt (Tastatur-Fallback)")
            self:commandMaster("toggle")
        end
    end
end
function GPSFieldTest:onPowerKey(actionName,inputValue,callbackState,isAnalog)
    if inputValue~=nil and inputValue<=0.5 then return end
    if g_gui and g_gui.currentGui~=nil then return end
    local now=self.totalMs or 0
    if now-(self.lastPowerToggleAt or -9999)<450 then return end
    self.lastPowerToggleAt=now
    GPSLogger.info("Hauptschalter: native Eingabe erkannt")
    self:commandMaster("toggle")
end
function GPSFieldTest:update(dt)
    if not self.isLoaded then return end
    self:installNativeHudBridge()
    self:pollDefaultMenuHotkey()
    self:pollDefaultPowerHotkey()
    if GPSCourseManager then
        GPSCourseManager.ensureLoaded()
        -- Required on host and clients, including while TerraLine power is OFF.
        if GPSCourseManager.watchLocalFarm then GPSCourseManager.watchLocalFarm() end
        if GPSCourseManager.pollNetwork then GPSCourseManager.pollNetwork(dt) end
    end
    if GPSMenu and not GPSMenu.registered and (self.totalMs or 0)>=(self.nextMenuRegisterAttempt or 0) then
        self.nextMenuRegisterAttempt=(self.totalMs or 0)+5000
        GPSMenu.register()
    end
    -- A powered-down TerraLine processes no track, offset, steering or 3D work.
    -- Keep the two escape routes alive even when everything else is paused.
    if not (g_gui and g_gui.currentGui~=nil) then
        self:registerAction("POWER")
        self:registerAction("MENU")
    end
    if not self:isMasterEnabled() then
        self.shiftHeld=nil
        self.totalMs=self.totalMs+(dt or 0)
        return
    end
    self:pollDefaultShiftHotkeys()
    -- Continuous fine adjustment: one centimetre on press, then slow auto-repeat.
    -- A release event clears held direction; no steering state is changed.
    if g_gui and g_gui.currentGui~=nil then
        self.shiftHeld=nil
    elseif self.shiftHeld then
        local held=self.shiftHeld
        held.elapsed=held.elapsed+(dt or 0)
        local repeats=0
        while held.elapsed>=held.nextAt and repeats<8 do
            self:commandShift(held.direction,true)
            -- Acceleration: first 7 cm/s, rising to 40 cm/s after sustained hold.
            local heldSeconds=held.nextAt/1000
            local interval=math.max(25,140-30*math.max(0,heldSeconds-0.38))
            held.nextAt=held.nextAt+interval
            repeats=repeats+1
        end
    end
    -- FS25 rebuilds action events regularly; register within update, not just once.
    -- All assignments come from the game's inputBinding settings (keyboard/gamepad).
    if not (g_gui and g_gui.currentGui~=nil) then
        self:registerAction("ASSIST")
        self:registerAction("AB")
        self:registerAction("SHIFT_RIGHT")
        self:registerAction("SHIFT_LEFT")
        self:registerAction("ROTATE")
    end
    GPSSteeringDiagnostics.update(dt)
    if GPSABLineManager.a and GPSABLineManager.b then
        local vehicle=GPSVehicleDetector.getCurrentVehicle()
        local width=GPSImplementDetector.getWidth(vehicle)
        local key=tostring(GPSABLineManager.a)..":"..tostring(GPSABLineManager.b)..":"..tostring(width)
        if GPSTrackGenerator.cacheKey~=key then
            GPSTrackGenerator.generate(nil,GPSABLineManager.a,GPSABLineManager.b,width)
            GPSTrackGenerator.cacheKey=key
        end
    end
    -- Direction-sensitive manual offset; switches only after a verified return
    -- pass with forward motion, never during a turn or a brief reverse.
    local optionalVehicle=GPSVehicleDetector.getCurrentVehicle()
    if not self.autoMirrorFaulted then
        if type(GPSAutoMirror)~="table" or type(GPSAutoMirror.update)~="function" then
            self.autoMirrorFaulted=true
            GPSLogger.info("WARNUNG: Auto-Wende deaktiviert (update-Funktion fehlt)")
        else
            local ok,err=pcall(GPSAutoMirror.update,dt,optionalVehicle)
            if not ok then
                self.autoMirrorFaulted=true
                GPSAutoMirror.enabled=false
                GPSLogger.info("WARNUNG: Auto-Wende wegen Laufzeitfehler deaktiviert: "..tostring(err))
            end
        end
    end
    if not self.deviceOffsetFaulted then
        if type(GPSDeviceOffsetProbe)~="table" or type(GPSDeviceOffsetProbe.update)~="function" then
            self.deviceOffsetFaulted=true
            GPSLogger.info("WARNUNG: Geraeteversatz-Messung deaktiviert (update-Funktion fehlt)")
        else
            local ok,err=pcall(GPSDeviceOffsetProbe.update,dt,optionalVehicle)
            if not ok then
                self.deviceOffsetFaulted=true
                GPSLogger.info("WARNUNG: Geraeteversatz-Messung nach Fehler deaktiviert: "..tostring(err))
            end
        end
    end
    -- Apply only safe, stable implement offsets while stopped with steering OFF.
    if not self.deviceAutoFaulted and type(GPSDeviceOffsetAuto)=="table" and type(GPSDeviceOffsetAuto.update)=="function" then
        local ok,err=pcall(GPSDeviceOffsetAuto.update,dt,optionalVehicle)
        if not ok then
            self.deviceAutoFaulted=true
            GPSDeviceOffsetAuto.enabled=false
            GPSLogger.info("WARNUNG: Geraete-Auto deaktiviert: "..tostring(err))
        end
    end
    GPSTrackPosition.update(dt,GPSVehicleDetector.getCurrentVehicle())
    self.totalMs=self.totalMs+(dt or 0)
    self.clock=self.clock+(dt or 0)
    if self.clock<GPSConfig.checkIntervalMs then return end
    self.clock=0
    local vehicle,source=GPSVehicleDetector.getCurrentVehicle()
    if not vehicle then
        self.status="Warte auf Traktor"
        self.vehicleStatus="Nicht erkannt"
        GPSSteeringController.stop("Fahrzeug verlassen")
        self.currentVehicle=nil
        return
    end
    self.vehicleStatus=GPSVehicleDetector.getDisplayName(vehicle)
    GPSSteeringController.install(vehicle)
    GPSImplementDetector.logIfChanged(vehicle)
    if self.currentVehicle~=vehicle then
        GPSSteeringController.stop("Fahrzeug gewechselt")
        self.currentVehicle=vehicle
        GPSLogger.info("Aktives Fahrzeug: "..self.vehicleStatus.." ("..source..")")
        GPSImplementDetector.lastSignature=nil
    end
    self.status=GPSABLineManager.b and "Freie A/B-Spur aktiv" or GPSABLineManager.a and "Punkt B setzen" or "Punkt A setzen"
end
-- Both DashboardLive HUD visibility actions use the native GIANTS HUD:
--   DBL_HUDVISIBILITY_PART -> hud:setIsVisible(...)
--   DBL_HUDVISIBILITY_FULL -> hud:consoleCommandToggleVisibility()
-- Respect the HUD state rather than hooking DashboardLive's controls. This
-- also works with the GIANTS HUD toggle and does not require DashboardLive.
-- Rendering only: the GPS steering and course update run independently.
local function isGameHudVisible()
    local hud=g_currentMission and g_currentMission.hud
    if hud and type(hud.getIsVisible)=="function" then
        local ok,visible=pcall(hud.getIsVisible,hud)
        if ok and visible==false then return false end
    end
    -- Missing HUD/visibility API or a failed read must never break the mod.
    return true
end
-- Inactive GPS: setup and A/B previews are always displayed.
-- Active GPS: 0 = continuous (default), otherwise a 2/5/10-second preview.
-- Speed, frame rate and the DashboardLive/GIANTS HUD state do not affect time.
function GPSFieldTest:shouldDrawLines()
    if not self:isMasterEnabled() then return false end
    if not GPSSteeringController or not GPSSteeringController.enabled then return true end
    local duration=GPSConfig and GPSConfig.lineDurationSeconds or 0
    if duration==0 then return true end
    local started=self.assistLinesActivatedAtMs
    if type(started)~="number" then return true end -- safe until next sync
    return ((self.totalMs or 0)-started)<duration*1000
end
function GPSFieldTest:draw()
    if self.isLoaded and self:isMasterEnabled() then
        self:syncAssistAudio()
        -- Hide all self-rendered visuals: GPS tracks, A marker, A/B preview,
        -- distance hints and optional diagnostics. Keep driving logic active.
        if not isGameHudVisible() then return end
        -- The timer hides 3D line geometry only, not the native speedometer,
        -- menu or developer diagnostics. HUD-hidden takes precedence above.
        if self:shouldDrawLines() then
            GPSTrackRenderer.draw(nil,self.currentVehicle)
            -- Optional rendering must NEVER interrupt the game update/render loop.
            if not self.abPreviewFaulted and GPSABPreviewRenderer and GPSABPreviewRenderer.draw then
                local ok,err=pcall(GPSABPreviewRenderer.draw,self.currentVehicle)
                if not ok then
                    self.abPreviewFaulted=true
                    GPSLogger.info("A/B Vorschau deaktiviert nach Fehler: "..tostring(err))
                end
            end
        end
        -- Keep developer output available only when explicitly enabling diagnostics.
        if GPSConfig.showDiagnostics and type(renderText)=="function" then
            local width,src,name,recognized=GPSImplementDetector.getData(self.currentVehicle)
            renderText(0.02,0.852,0.013,string.format("AB: %s / %s | Breite %.1fm (%s)",
                GPSABLineManager.a and "A" or "-", GPSABLineManager.b and "B" or "-",width,src))
            renderText(0.02,0.83,0.013,"Anbaugeraet: "..tostring(name))
            renderText(0.02,0.808,0.013,tostring(GPSTrackGenerator.info))
            renderText(0.02,0.786,0.015,"GPS: "..tostring(GPSTrackPosition.info))
            local steer=GPSSteeringController
            if type(setTextColor)=="function" then
                if steer.enabled then setTextColor(0.15,1,0.28,1) else setTextColor(1,0.78,0.2,1) end
            end
            renderText(0.02,0.756,0.019,steer.enabled and "GPS AKTIV" or "GPS AUS")
            if type(setTextColor)=="function" then setTextColor(1,1,1,1) end
            local reason=tostring(steer.reason or "-")
            renderText(0.02,0.733,0.013,(steer.enabled and "Spurhaltung: " or "Status: ")..reason)
            renderText(0.02,0.711,0.012,"A/B und GPS: Tastenbelegung im LS25-Menue")
            renderText(0.02,0.689,0.011,"Lenkdiagnose: "..GPSSteeringDiagnostics.getStatus())
        end
    end
end
-- Actions are routed through a shared debouncer: a keyboard fallback and an
-- action-event callback can fire on the same physical keypress.
function GPSFieldTest:handleKeyAction(kind,origin)
    if not self:isMasterEnabled() then return end
    if GPSMenu and GPSMenu.isOpen() then return end
    local now=self.totalMs or 0
    if now-(self.lastActionAt or -9999)<300 then return end
    self.lastActionAt=now
    GPSLogger.info("Tasteneingabe erkannt: "..kind.." via "..origin)
    if kind=="MENU" then
        GPSMenu.toggle()
    elseif kind=="AB" then
        if GPSABLineManager.a==nil or GPSABLineManager.b~=nil then
            self:commandA()
        else
            self:commandB()
        end
    elseif kind=="ROTATE" then
        local ok,msg=GPSCourseManager.rotate90()
        GPSLogger.info("90 Grad: "..msg)
    elseif kind=="SHIFT_RIGHT" or kind=="SHIFT_LEFT" then
        self:commandShift(kind=="SHIFT_RIGHT" and 1 or -1)
    else
        self:commandAssist()
        self:syncAssistAudio()
    end
end
function GPSFieldTest:onShiftKey(direction,inputValue)
    if not self:isMasterEnabled() then self.shiftHeld=nil;return end
    if GPSMenu and GPSMenu.isOpen() then return end
    -- Receive both press and release events from LS25's configurable InputAction.
    if inputValue==nil then return end
    if inputValue>0.5 then
        if self.shiftHeld and self.shiftHeld.direction==direction then return end
        self.shiftHeld={direction=direction,elapsed=0,nextAt=380}
        self:commandShift(direction)
    elseif self.shiftHeld and self.shiftHeld.direction==direction then
        self.shiftHeld=nil
    end
end
function GPSFieldTest:onShiftRightKey(actionName,inputValue,callbackState,isAnalog)
    self:onShiftKey(1,inputValue)
end
function GPSFieldTest:onShiftLeftKey(actionName,inputValue,callbackState,isAnalog)
    self:onShiftKey(-1,inputValue)
end
function GPSFieldTest:onAssistKey(actionName,inputValue,callbackState,isAnalog)
    self:handleKeyAction("ASSIST","ActionEvent")
end
function GPSFieldTest:onABKey(actionName,inputValue,callbackState,isAnalog)
    self:handleKeyAction("AB","ActionEvent")
end
function GPSFieldTest:onRotate90Key(actionName,inputValue,callbackState,isAnalog)
    if inputValue==nil or inputValue>0.5 then self:handleKeyAction("ROTATE","ActionEvent") end
end
function GPSFieldTest:onMenuKey(actionName,inputValue,callbackState,isAnalog)
    if inputValue==nil or inputValue>0.5 then
        local now=self.totalMs or 0
        if now-(self.lastMenuToggleAt or -9999)>=450 then
            self.lastMenuToggleAt=now
            GPSLogger.info("GPS Menue: native Menue-Aktion erkannt")
            if GPSMenu then GPSMenu.toggle() end
        end
    end
end
function GPSFieldTest:registerAction(kind)
    local binding=g_inputBinding
    local actions={AB="GPS_FIELD_AB_MARK",ASSIST="GPS_FIELD_ASSIST_TOGGLE",SHIFT_RIGHT="GPS_FIELD_SHIFT_RIGHT",SHIFT_LEFT="GPS_FIELD_SHIFT_LEFT",MENU="GPS_FIELD_MENU_TOGGLE",ROTATE="GPS_FIELD_ROTATE_90",POWER="GPS_FIELD_POWER_TOGGLE"}
    local actionName=actions[kind]
    if not actionName then return end
    local id=InputAction and InputAction[actionName]
    if not binding or type(binding.registerActionEvent)~="function" or id==nil then
        if not self.inputRegistrationWarning then
            GPSLogger.info("GPS Eingaberegistrierung nicht verfuegbar")
            self.inputRegistrationWarning=true
        end
        return
    end
    local callbacks={AB=self.onABKey,ASSIST=self.onAssistKey,SHIFT_RIGHT=self.onShiftRightKey,SHIFT_LEFT=self.onShiftLeftKey,MENU=self.onMenuKey,ROTATE=self.onRotate90Key,POWER=self.onPowerKey}
    local callback=callbacks[kind]
    local isShift=kind=="SHIFT_RIGHT" or kind=="SHIFT_LEFT"
    local ok,registered,eventId=pcall(binding.registerActionEvent,binding,id,self,callback,isShift,true,false,true)
    if ok and registered then
        if kind=="AB" then
            self.keyABEventId=eventId
        else
            self.keyEventId=eventId
        end
        -- Emit diagnostics once, not each frame.
        if not self["registeredOnce_"..kind] then
            GPSLogger.info(actionName.." dynamisch registriert (EventId="..tostring(eventId)..")")
            self["registeredOnce_"..kind]=true
        end
    elseif not ok and not self["registrationError_"..kind] then
        GPSLogger.info(actionName.." Fehler: "..tostring(registered))
        self["registrationError_"..kind]=true
    end
end

function GPSFieldTest:commandSteerTest(direction)
    if direction~="left" and direction~="right" then return "Benutzung: gsGPSSteerTest left ODER right" end
    return GPSSteeringDiagnostics.start(GPSVehicleDetector.getCurrentVehicle(),direction)
end
function GPSFieldTest:commandSteerReport()
    local d=GPSSteeringDiagnostics
    local msg="GPS Lenktest: "..d.lastReport.." | Hook="..tostring(GPSSteeringController.hookInstalled)
    GPSLogger.info(msg)
    return msg
end
function GPSFieldTest:commandAssist()
    if not self:isMasterEnabled() then return "TerraLine GPS AUS - erst mit Alt+T einschalten" end
    local vehicle=GPSVehicleDetector.getCurrentVehicle()
    -- A/B may have just been completed while stationary. Resolve a valid pass
    -- immediately rather than requiring movement or waiting for the next tick.
    if not GPSSteeringController.enabled and vehicle and GPSABLineManager.a and GPSABLineManager.b then
        local width=GPSImplementDetector.getWidth(vehicle)
        if type(width)=="number" and width>0 then
            if not GPSTrackGenerator.ready then
                GPSTrackGenerator.generate(nil,GPSABLineManager.a,GPSABLineManager.b,width)
                GPSTrackGenerator.cacheKey=tostring(GPSABLineManager.a)..":"..tostring(GPSABLineManager.b)..":"..tostring(width)
            end
            GPSTrackPosition.lastUpdate=150
            GPSTrackPosition.update(0,vehicle)
        end
    end
    local message=GPSSteeringController.toggle(vehicle);GPSLogger.info(message);return message
end
function GPSFieldTest:commandShift(direction,quiet)
    if not self:isMasterEnabled() then return "TerraLine GPS AUS" end
    if not GPSABLineManager.a or not GPSABLineManager.b then
        GPSLogger.info("GPS Verschieben: Zuerst A und B setzen")
        return
    end
    -- Fine adjustment: keep the GPS assist engaged on its currently locked track.
    -- Regenerate clipped guide segments immediately, so physics never sees an empty set.
    local ok,message=GPSABLineManager.shift(direction,0.01)
    if ok then
        local vehicle=GPSVehicleDetector.getCurrentVehicle()
        local width=GPSImplementDetector.getWidth(vehicle)
        GPSTrackGenerator.generate(nil,GPSABLineManager.a,GPSABLineManager.b,width)
        GPSTrackGenerator.cacheKey=tostring(GPSABLineManager.a)..":"..tostring(GPSABLineManager.b)..":"..tostring(width)
        -- Refresh the displayed offset on the next regular position update.
        GPSTrackPosition.lastUpdate=150
    end
    if not quiet then GPSLogger.info(tostring(message).." | gesamte GPS-Spur inkl. Arbeitsbreitengrenzen") end
end
function GPSFieldTest:commandA()
    if not self:isMasterEnabled() then return "TerraLine GPS AUS" end
    GPSSteeringController.stop("A neu gesetzt")
    if GPSCourseManager then GPSCourseManager.activeCourseName=nil end
    local text=GPSABLineManager.setA();GPSTrackGenerator.reset();GPSLogger.info(text);return text
end
function GPSFieldTest:commandB()
    if not self:isMasterEnabled() then return "TerraLine GPS AUS" end
    GPSSteeringController.stop("B neu gesetzt")
    local text=GPSABLineManager.setB();GPSTrackGenerator.reset();GPSLogger.info(text);return text
end
function GPSFieldTest:commandWidth(value)
    GPSSteeringController.stop("Breite geaendert")
    local n=tonumber(value)
    if not n or n<0.5 or n>60 then return "Breite muss zwischen 0.5 und 60 Metern liegen" end
    GPSImplementDetector.override=n;GPSTrackGenerator.reset()
    return string.format("GPS Arbeitsbreite manuell %.1f m",n)
end
function GPSFieldTest:commandClear()
    GPSSteeringController.stop("A/B geloescht");GPSABLineManager.clear();GPSTrackGenerator.reset();return "GPS A/B zurueckgesetzt"
end
function GPSFieldTest:commandAutoWidth()
    GPSSteeringController.stop("Breite neu ermittelt")
    GPSImplementDetector.override=nil;GPSTrackGenerator.reset();return "GPS automatische Breite aktiviert"
end
function GPSFieldTest:commandAutoMirror(value)
    local mode=tostring(value or "toggle"):lower()
    if mode=="on" or mode=="1" then GPSAutoMirror.enabled=true
    elseif mode=="off" or mode=="0" then GPSAutoMirror.enabled=false
    elseif mode=="toggle" then GPSAutoMirror.enabled=not GPSAutoMirror.enabled
    else return "Benutzung: gsGPSAutoWende on/off" end
    GPSAutoMirror.reset()
    local msg="GPS Auto-Wende "..(GPSAutoMirror.enabled and "AN" or "AUS")
    GPSLogger.info(msg);return msg
end
function GPSFieldTest:commandDeviceOffset()
    local value,source,complete=GPSDeviceOffsetProbe.getData(GPSVehicleDetector.getCurrentVehicle())
    local msg=value and string.format("Geraeteversatz erkannt: %+.2f m aus Traktorsicht (%s). Noch NICHT auf Lenkung angewandt.",value,source)
              or ("Geraeteversatz: "..tostring(source))
    GPSLogger.info(msg);return msg
end
function GPSFieldTest:commandAngle(value)
    local ok,msg=GPSCourseManager.setAngle(value)
    GPSLogger.info(msg);return msg
end
function GPSFieldTest:commandRotate90()
    if not self:isMasterEnabled() then return "TerraLine GPS AUS" end
    local ok,msg=GPSCourseManager.rotate90()
    GPSLogger.info(msg);return msg
end
function GPSFieldTest:commandCourseSave(name)
    local ok,msg=GPSCourseManager.saveCurrent(name)
    GPSLogger.info(msg);return msg
end
function GPSFieldTest:commandMenu()
    GPSMenu.toggle()
    return "GPS Menue umgeschaltet"
end
function GPSFieldTest:loadMission00() end
addModEventListener(GPSFieldTest)
if type(addConsoleCommand)=="function" then
    addConsoleCommand("gsGPSPower","TerraLine GPS Hauptschalter: on/off/toggle","commandMaster",GPSFieldTest)
    addConsoleCommand("gsGPSMenu","GPS Einstellungsmenue oeffnen/schliessen","commandMenu",GPSFieldTest)
    addConsoleCommand("gsGPSSteerTest","Kurzer Diagnoseimpuls: left/right","commandSteerTest",GPSFieldTest)
    addConsoleCommand("gsGPSSteerReport","Diagnosebericht der Lenkung","commandSteerReport",GPSFieldTest)
    addConsoleCommand("gsGPSAssist","GPS Spurhaltung ein/aus (0-30 km/h, gerade Spuren)","commandAssist",GPSFieldTest)
    addConsoleCommand("gsGPSA","GPS Punkt A am Traktor setzen","commandA",GPSFieldTest)
    addConsoleCommand("gsGPSB","GPS Punkt B am Traktor setzen (mindestens 20m)","commandB",GPSFieldTest)
    addConsoleCommand("gsGPSWidth","GPS Breite in m, z.B. gsGPSWidth 3","commandWidth",GPSFieldTest)
    addConsoleCommand("gsGPSAutoWidth","GPS Arbeitsbreite automatisch","commandAutoWidth",GPSFieldTest)
    addConsoleCommand("gsGPSReset","GPS A/B zuruecksetzen","commandClear",GPSFieldTest)
    addConsoleCommand("gsGPSAutoWende","GPS Versatz bei Rueckfahrt spiegeln: on/off","commandAutoMirror",GPSFieldTest)
    addConsoleCommand("gsGPSAngle","TerraLine GPS Winkel: gsGPSAngle 90","commandAngle",GPSFieldTest)
    addConsoleCommand("gsGPSRotate90","TerraLine GPS Spur 90 Grad rechts drehen","commandRotate90",GPSFieldTest)
    addConsoleCommand("gsGPSCourseSave","TerraLine aktuellen Kurs unter Namen speichern","commandCourseSave",GPSFieldTest)
    addConsoleCommand("gsGPSDeviceOffset","Geraeteversatz-Erkennung diagnose (nur Messung)","commandDeviceOffset",GPSFieldTest)
end
