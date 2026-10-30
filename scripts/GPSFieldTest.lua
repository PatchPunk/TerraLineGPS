-- TerraLine GPS | PatchPunk Public Beta | 2026-10-12
-- TerraLine GPS v0.9.9.23: user-defined A/B only; independent of farmland.
GPSFieldTest = {isLoaded=false,masterEnabled=false,clock=0,totalMs=0,status="Start",vehicleStatus="-",currentVehicle=nil,
 keyRegistered=false,keyRetry=0,keyABRegistered=false,keyABRetry=0,keyPressedAB=false,
 keyPressedAssist=false,lastActionAt=-9999,keyboardDiagnosticDone=false}

-- Play the actual FS25 automatic-steering sounds already loaded for the locally
-- controlled vehicle. GIANTS owns these samples: do not load, delete, or change
-- them here. Never enable the built-in steering merely to play its audio.
local function playNativeSteeringSample(isEngage)
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle
        and GPSVehicleDetector.getCurrentVehicle()
    -- Only locally controlled vehicle audio; never sound an empty server.
    if vehicle==nil or vehicle.isClient==false then return false end
    local spec=vehicle.spec_aiAutomaticSteering
    local samples=spec and spec.samples
    local name=isEngage and "engage" or "disengage"
    local sample=samples and samples[name]
    if sample==nil then
        GPSLogger.info("GPS Sound: GIANTS "..name.." fuer aktuelles Fahrzeug nicht verfuegbar")
        return false
    end
    if g_soundManager==nil or type(g_soundManager.playSample)~="function" then
        GPSLogger.info("GPS Sound: GIANTS SoundManager nicht verfuegbar")
        return false
    end
    -- The engine's sound manager is available; do not hide runtime errors.
    g_soundManager:playSample(sample)
    return true
end
function GPSFieldTest:playActivationBeep()
    return playNativeSteeringSample(true)
end
function GPSFieldTest:playDeactivationBeep()
    return playNativeSteeringSample(false)
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
    -- Every map session begins with the public-release logging policy.
    -- Diagnostics are enabled explicitly in the developer page or server console.
    if GPSConfig then GPSConfig.showDiagnostics=false end
    self.isLoaded=true
    -- TerraLine stays OFF until the player explicitly enables it (Alt+T/menu).
    -- The saved course database is available to the menu even while OFF.
    self.masterEnabled=false
    self.powerByFarm={} -- Kept for transition diagnostics.
    self.powerByVehicle=setmetatable({},{__mode="k"})
    self.lastPowerVehicle=nil
    self.defaultPowerHotkeyHeld=false
    self.lastPowerToggleAt=-9999
    if GPSCourseManager then GPSCourseManager.reset() end
    if GPSDisplaySettings then GPSDisplaySettings.reset();GPSDisplaySettings.ensureLoaded() end
    self.registeredOnce_MENU=nil
    self.defaultMenuHotkeyHeld=false
    self.defaultShiftRightHeld=false
    self.defaultShiftLeftHeld=false
    self.shiftHeld=nil
    self.assistHeld=nil
    self.rotateHeld=nil
    self.angleMode=false
    self.defaultAngleModeHeld=false;self.lastAngleModeAt=-9999
    self.defaultRotateEastHeld=false;self.defaultRotateWestHeld=false
    self.menuFallbackNotice=false
    self.clock=0; self.totalMs=0; self.status="A/B bereit";self.vehicleStatus="-"
    self.currentVehicle=nil
    self.registeredOnce_AB=nil;self.registeredOnce_ASSIST=nil;self.inputRegistrationWarning=nil
    -- Never carry a previous savegame's unsaved A/B line into a new map.
    if GPSABLineManager then GPSABLineManager.clear() end
    if GPSImplementDetector then
        GPSImplementDetector.override=nil
        if GPSImplementDetector.resetCombo then GPSImplementDetector.resetCombo() end
    end
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
    GPSLogger.info("v"..tostring(GPSConfig.version).." gestartet: frei belegbare Eingaben A/B und GPS, GIANTS GPS EIN/AUS-Sounds")
    self.lastAssistAudioState=false
    self.assistLinesActivatedAtMs=nil
end
function GPSFieldTest:deleteMap()
    if GPSLineVisuals and GPSLineVisuals.cleanup then GPSLineVisuals.cleanup() end
    GPSSteeringDiagnostics.stop("Karte verlassen")
    self.keyRegistered=false;self.keyABRegistered=false
    self.lastAssistAudioState=nil;self.assistLinesActivatedAtMs=nil
    if GPSCourseManager then GPSCourseManager.reset() end
    if GPSABLineManager then GPSABLineManager.clear() end
    if GPSImplementDetector then
        GPSImplementDetector.override=nil
        if GPSImplementDetector.resetCombo then GPSImplementDetector.resetCombo() end
    end
    if GPSDisplaySettings then GPSDisplaySettings.reset() end
    self.isLoaded=false;self.masterEnabled=false;
        self.powerByFarm={};self.powerByVehicle=nil;
        self.lastPowerVehicle=nil;self.currentVehicle=nil;
        self.shiftHeld=nil;self.assistHeld=nil;
        self.rotateHeld=nil;self.angleMode=false;
        self.defaultAngleModeHeld=false
    self.defaultRotateEastHeld=false;self.defaultRotateWestHeld=false
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
    local shownTrack=GPSSteeringController and GPSSteeringController.enabled and GPSSteeringController.lockedTrack or index
    local number=GPSTrackPosition.getDisplayNumber(shownTrack)
    return number and ("GPS "..tostring(number)) or "GPS"
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
        local bridge=GPSFieldTest.masterEnabled==true and vehicle~=nil and ownVehicle==vehicle
            and GPSVehicleEquipment and GPSVehicleEquipment.isInstalled(vehicle)
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

        -- Keep the native HUD draw intact; on normal return restore every
        -- temporary accessor and label exactly as in the previous build.
        -- Engine failures are no longer hidden and remain visible in log.txt.
        originalDraw(display,...)
        if bridge then
            rawset(vehicle,"getAIAutomaticSteeringState",oldSteeringAccessor)
            rawset(vehicle,"getAIModeSelection",oldModeAccessor)
            display.aiReadyText=oldReadyText
            display.aiActiveText=oldActiveText
        end
        -- Equipment indicator stays visible when the hardware is fitted but
        -- the GPS master is OFF. It is drawn inside this native display only.
        if vehicle~=nil and ownVehicle==vehicle and GPSTachoStatus
                and type(GPSTachoStatus.draw)=="function" then
            GPSTachoStatus.draw(display,vehicle)
        end
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
    -- Input and the required default bindings are already validated above.
    -- Read the key state directly so genuine engine errors remain visible.
    local alt=k.isKeyPressed(k.KEY_lalt) or (k.KEY_ralt and k.isKeyPressed(k.KEY_ralt))
    local pressed=alt and k.isKeyPressed(k.KEY_m)
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
    -- The Input API has already been checked above. Direct key queries
    -- preserve both shortcut states and expose actual engine errors in log.txt.
    local alt=k.isKeyPressed(k.KEY_lalt) or (k.KEY_ralt and k.isKeyPressed(k.KEY_ralt))
    local right=alt and k.KEY_pageup and k.isKeyPressed(k.KEY_pageup) or false
    local left=alt and k.KEY_pagedown and k.isKeyPressed(k.KEY_pagedown) or false
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

-- Use the physically RIGHT Alt key (AltGr on some layouts) with W.
-- The game's action event can be missing on certain keyboard layouts;
-- the edge-triggered fallback shares a debounce with the native callback.
function GPSFieldTest:toggleAngleMode()
    if not self:isMasterEnabled() then return false,"TerraLine GPS AUS" end
    if (g_gui and g_gui.currentGui~=nil) or (GPSMenu and GPSMenu.isOpen()) then return false,"Menue geoeffnet" end
    local vehicle=GPSVehicleDetector.getCurrentVehicle()
    if not vehicle then return false,"Kein Traktor ausgewaehlt" end
    local speed=type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
    if speed>2 then return false,"Spurwinkelmodus nur im Stillstand" end
    if not (GPSABLineManager.a and GPSABLineManager.b) then return false,"Zuerst A/B-Linie erstellen" end
    self.angleMode=not (self.angleMode==true)
    self.rotateHeld=nil
    local state=self.angleMode and "EIN (Alt+J/N je 0,1 Grad)" or "AUS"
    GPSLogger.info("GPS SPURWINKEL-MODUS "..state.." | Drehpunkt: Traktormitte")
    return true,state
end
function GPSFieldTest:pollDefaultAngleModeHotkey()
    local k=Input
    if type(k)~="table" or type(k.isKeyPressed)~="function" or not k.KEY_ralt or not k.KEY_w then return end
    -- The keyboard API and the required key IDs are checked above. Let real
    -- engine errors appear in log.txt instead of hiding them via pcall.
    local pressed=k.isKeyPressed(k.KEY_ralt) and k.isKeyPressed(k.KEY_w)
    local was=self.defaultAngleModeHeld==true
    self.defaultAngleModeHeld=pressed==true
    if pressed and not was then self:onAngleModeKey(nil,1) end
end
function GPSFieldTest:onAngleModeKey(actionName,inputValue,callbackState,isAnalog)
    if inputValue~=nil and inputValue<=0.5 then return end
    local now=self.totalMs or 0
    if now-(self.lastAngleModeAt or -9999)<450 then return end
    self.lastAngleModeAt=now
    local ok,msg=self:toggleAngleMode()
    if not ok then GPSLogger.info("GPS Spurwinkelmodus: "..tostring(msg)) end
end

-- Keyboard fallback for Alt+J/Alt+N, so the default shortcuts still work
-- when GIANTS does not fire the action events for a particular key layout.
function GPSFieldTest:pollDefaultRotationHotkeys()
    local k=Input
    if type(k)~="table" or type(k.isKeyPressed)~="function" or not k.KEY_lalt then return end
    if g_gui and g_gui.currentGui~=nil then
        self.defaultRotateEastHeld=false;self.defaultRotateWestHeld=false
        self.rotateHeld=nil
        return
    end
    -- Input and isKeyPressed have already been checked. Keep the existing
    -- one-press/hold behavior, but allow native key-read errors to reach log.txt.
    local alt=k.isKeyPressed(k.KEY_lalt) or (k.KEY_ralt and k.isKeyPressed(k.KEY_ralt))
    local east=(alt and k.KEY_j and k.isKeyPressed(k.KEY_j))==true
    local west=(alt and k.KEY_n and k.isKeyPressed(k.KEY_n))==true
    if east and west then east=false;west=false end -- contradictory controls
    if east and not self.defaultRotateEastHeld then
        if not (self.rotateHeld and self.rotateHeld.direction==1) then
            GPSLogger.info("GPS Alt+J: Feindrehung Richtung 90 Grad (Fallback)")
            self:onRotateKey(1,1)
        end
    elseif not east and self.defaultRotateEastHeld then
        self:onRotateKey(1,0)
    end
    if west and not self.defaultRotateWestHeld then
        if not (self.rotateHeld and self.rotateHeld.direction==-1) then
            GPSLogger.info("GPS Alt+N: Feindrehung Richtung 270 Grad (Fallback)")
            self:onRotateKey(-1,1)
        end
    elseif not west and self.defaultRotateWestHeld then
        self:onRotateKey(-1,0)
    end
    self.defaultRotateEastHeld=east
    self.defaultRotateWestHeld=west
end

-- Master power is separate from Alt+X. The GPS menu stays accessible when powered OFF.
function GPSFieldTest:isMasterEnabled()
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    return self.masterEnabled==true and GPSVehicleEquipment and GPSVehicleEquipment.isInstalled(vehicle)
end
-- Keeping a power state PER VEHICLE prevents another tractor from inheriting
-- GPS ON when the player changes vehicles or farms in a multiplayer game.
function GPSFieldTest:syncPowerForVehicle(vehicle)
    -- Workbench changes can remove equipment without switching vehicles.
    -- Immediately release steering even in this case.
    if self.lastPowerVehicle==vehicle then
        if self.masterEnabled and not (GPSVehicleEquipment and GPSVehicleEquipment.isInstalled(vehicle)) then
            self.masterEnabled=false
            GPSSteeringController.stop("TerraLine in Werkstatt ausgebaut")
        end
        return
    end
    self.lastPowerVehicle=vehicle
    self.angleMode=false;self.rotateHeld=nil
    local enabled=vehicle and GPSVehicleEquipment and GPSVehicleEquipment.isInstalled(vehicle)
        and self.powerByVehicle and self.powerByVehicle[vehicle]==true or false
    if self.masterEnabled~=enabled then
        self.masterEnabled=enabled
        GPSSteeringController.stop("Fahrzeugwechsel: GPS-Lenkung aus")
        if GPSSteeringDiagnostics then GPSSteeringDiagnostics.stop("Fahrzeugwechsel") end
        self.assistLinesActivatedAtMs=nil
        self.shiftHeld=nil;self.assistHeld=nil;self.rotateHeld=nil;self.angleMode=false
    end
end
function GPSFieldTest:syncPowerForFarm(farmId)
    -- A farm change must never copy the power state from another farm.
    -- The state is restored from the actually controlled vehicle next tick.
    self.masterEnabled=false
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    if vehicle and self.powerByVehicle then self.powerByVehicle[vehicle]=false end
    self.lastPowerVehicle=nil
    GPSSteeringController.stop("Hofwechsel: GPS-Lenkung aus")
    self.assistLinesActivatedAtMs=nil
    GPSLogger.info("HAUPTSCHALTER: Hofwechsel zu "..tostring(farmId or "-").." | Fahrzeugausstattung wird geprueft")
end
function GPSFieldTest:setMasterEnabled(enabled)
    enabled=enabled==true
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle()
    if not (vehicle and GPSVehicleEquipment and GPSVehicleEquipment.isInstalled(vehicle)) then
        self.masterEnabled=false
        GPSSteeringController.stop("TerraLine GPS nicht eingebaut")
        return "TerraLine GPS: Fahrzeug ohne GPS-Ausstattung (Shop/Werkstatt +10.000 EUR)"
    end
    local farmId=GPSCourseManager and GPSCourseManager.getFarmId and GPSCourseManager.getFarmId()
    if not farmId then return "TerraLine GPS: erst einem Hof beitreten" end
    self.powerByVehicle=self.powerByVehicle or setmetatable({},{__mode="k"})
    self.powerByVehicle[vehicle]=enabled
    self.lastPowerVehicle=vehicle
    if self.masterEnabled==enabled then
        return "TerraLine GPS "..(enabled and "EIN" or "AUS")
    end
    self.masterEnabled=enabled
    self.shiftHeld=nil;self.rotateHeld=nil;self.angleMode=false;self.defaultAngleModeHeld=false
    self.defaultShiftRightHeld=false
    self.defaultShiftLeftHeld=false
    self.defaultRotateEastHeld=false;self.defaultRotateWestHeld=false
    if not enabled then
        GPSSteeringController.stop("TerraLine Hauptschalter AUS")
        if GPSSteeringDiagnostics then GPSSteeringDiagnostics.stop("TerraLine GPS AUS") end
        self:syncAssistAudio()
        self.assistLinesActivatedAtMs=nil
        if GPSAutoMirror then GPSAutoMirror.reset() end
    else
        GPSSteeringController.stop("TerraLine bereit (Lenkung aus)")
        if GPSTrackPosition then GPSTrackPosition.lastUpdate=150 end
        if GPSAutoMirror then GPSAutoMirror.reset() end
    end
    local msg="TerraLine GPS "..(enabled and "EIN - Lenkung bleibt AUS" or "AUS")
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
    -- Input and the required default bindings are already validated above.
    -- Read the key state directly so genuine engine errors remain visible.
    local alt=k.isKeyPressed(k.KEY_lalt) or (k.KEY_ralt and k.isKeyPressed(k.KEY_ralt))
    local pressed=alt and k.isKeyPressed(k.KEY_t)
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
    self:syncPowerForVehicle(GPSVehicleDetector.getCurrentVehicle())
    self:pollDefaultPowerHotkey()
    if GPSCourseManager then
        GPSCourseManager.ensureLoaded()
        if g_server~=nil and GPSCourseManager.installSaveHook then GPSCourseManager.installSaveHook() end
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
        self.shiftHeld=nil;self.assistHeld=nil;self.rotateHeld=nil;self.angleMode=false
        self.totalMs=self.totalMs+(dt or 0)
        return
    end
    self:pollDefaultAngleModeHotkey()
    self:pollDefaultShiftHotkeys()
    self:pollDefaultRotationHotkeys()
    -- Alt+X: a short release retains the established ON/OFF action;
    -- a 3-second hold resets only lane DISPLAY numbering, not A/B geometry.
    if self.assistHeld then
        local held=self.assistHeld
        if (g_gui and g_gui.currentGui~=nil) or (GPSMenu and GPSMenu.isOpen()) then
            self.assistHeld=nil
        elseif not held.triggered and (self.totalMs or 0)-held.startedAt>=3000 then
            held.triggered=true
            self:commandResetLaneNumbering()
        end
    end
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
    -- Fine rotation: one 0.1-degree click in angle mode, then accelerating repeats.
    -- Use the same 380 ms delay/acceleration as the existing shift controls.
    if g_gui and g_gui.currentGui~=nil then
        self.rotateHeld=nil
    elseif self.rotateHeld then
        local vehicle=GPSVehicleDetector.getCurrentVehicle()
        local speed=vehicle and type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
        if not self.angleMode or speed>2 then
            self.rotateHeld=nil
            if speed>2 and self.angleMode then
                self.angleMode=false
                GPSLogger.info("GPS SPURWINKEL-MODUS AUS: Fahrzeug faehrt")
            end
        end
    end
    if self.rotateHeld then
        local held=self.rotateHeld
        held.elapsed=held.elapsed+(dt or 0)
        local repeats=0
        -- Bound elapsed processing to avoid many full course recomputations
        -- in one frame. Total angular motion stays deterministic per repeat.
        while held.elapsed>=held.nextAt and repeats<8 do
            local ok,msg=self:commandRotateFine(held.direction,true)
            if not ok then
                GPSLogger.info("GPS Feindrehung gestoppt: "..tostring(msg))
                self.rotateHeld=nil
                break
            end
            local heldSeconds=held.nextAt/1000
            held.nextAt=held.nextAt+math.max(25,140-30*math.max(0,heldSeconds-0.38))
            repeats=repeats+1
        end
    end
    if self.angleMode and not self.rotateHeld then
        local vehicle=GPSVehicleDetector.getCurrentVehicle()
        local speed=vehicle and type(vehicle.getLastSpeed)=="function" and math.abs(vehicle:getLastSpeed()) or 0
        if speed>2 then
            self.angleMode=false
            GPSLogger.info("GPS SPURWINKEL-MODUS AUS: Fahrzeug faehrt")
        end
    end
    -- FS25 rebuilds action events regularly; register within update, not just once.
    -- All assignments come from the game's inputBinding settings (keyboard/gamepad).
    if g_gui and g_gui.currentGui~=nil then
        self.angleMode=false;self.rotateHeld=nil
    end
    if not (g_gui and g_gui.currentGui~=nil) then
        self:registerAction("ASSIST")
        self:registerAction("AB")
        self:registerAction("SHIFT_RIGHT")
        self:registerAction("SHIFT_LEFT")
        self:registerAction("ROTATE")
        self:registerAction("ROTATE_MODE")
        self:registerAction("ROTATE_EAST")
        self:registerAction("ROTATE_WEST")
    end
    GPSSteeringDiagnostics.update(dt)
    -- Stable combination widths are sampled only while stopped/steering OFF.
    -- Read them before regenerating A/B lanes; never change width mid-steering.
    if not self.implementWidthFaulted and GPSImplementDetector
            and type(GPSImplementDetector.update)=="function" then
        GPSImplementDetector.update(dt,GPSVehicleDetector.getCurrentVehicle())
    end
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
            GPSAutoMirror.update(dt,optionalVehicle)
        end
    end
    if not self.deviceOffsetFaulted then
        if type(GPSDeviceOffsetProbe)~="table" or type(GPSDeviceOffsetProbe.update)~="function" then
            self.deviceOffsetFaulted=true
            GPSLogger.info("WARNUNG: Geraeteversatz-Messung deaktiviert (update-Funktion fehlt)")
        else
            GPSDeviceOffsetProbe.update(dt,optionalVehicle)
        end
    end
    -- Apply only safe, stable implement offsets while stopped with steering OFF.
    if not self.deviceAutoFaulted and type(GPSDeviceOffsetAuto)=="table"
            and type(GPSDeviceOffsetAuto.update)=="function" then
        GPSDeviceOffsetAuto.update(dt,optionalVehicle)
    end
    GPSTrackPosition.update(dt,GPSVehicleDetector.getCurrentVehicle())
    if GPSSteeringController.updateNetworkSteering then
        GPSSteeringController.updateNetworkSteering(dt,GPSVehicleDetector.getCurrentVehicle())
    end
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
    self.status=GPSABLineManager.captureStage=="armed" and "A/B scharf: Alt+B setzt A"
        or GPSABLineManager.b and "Freie A/B-Spur aktiv"
        or GPSABLineManager.a and "Punkt B setzen" or "Alt+B: A/B scharf stellen"
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
        -- The native HUD API has already been validated. Do not hide engine
        -- errors with pcall; an explicit false alone suppresses GPS visuals.
        local visible=hud:getIsVisible()
        if visible==false then return false end
    end
    -- A missing HUD or visibility method keeps the previous visible fallback.
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
    -- Meshes are persistent scene nodes; hide them whenever 3D GPS lines
    -- are not drawn (power off, map/HUD hidden, timer elapsed).
    if GPSLineVisuals and GPSLineVisuals.hide and
            (not self.isLoaded or not self:isMasterEnabled() or
             not isGameHudVisible() or not self:shouldDrawLines()) then
        GPSLineVisuals.hide()
    end
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
            if not self.abPreviewFaulted and GPSABPreviewRenderer
                    and type(GPSABPreviewRenderer.draw)=="function" then
                GPSABPreviewRenderer.draw(self.currentVehicle)
            end
        end
        -- Confirm the first Alt+B press without changing the existing GUI.
        if GPSABLineManager.captureStage=="armed" and type(renderText)=="function" then
            if type(setTextColor)=="function" then setTextColor(1,.72,.23,1) end
            renderText(.37,.105,.021,"A/B SCHARF: Alt+B startet Messung")
            if type(setTextColor)=="function" then setTextColor(1,1,1,1) end
        end
        -- Keep developer output available only when explicitly enabling diagnostics.
        if GPSConfig.showDiagnostics and type(renderText)=="function" then
            local width,src,name,recognized=GPSImplementDetector.getData(self.currentVehicle)
            renderText(0.02,0.852,0.013,string.format("AB: %s / %s | Breite %.1fm (%s)",
                GPSABLineManager.a and "A" or "-", GPSABLineManager.b and "B" or "-",width,src))
            renderText(0.02,0.83,0.013,"Anbaugeraet: "..tostring(name))
            renderText(0.02,0.808,0.013,tostring(GPSTrackGenerator.info))
            local debugInfo=tostring(GPSTrackPosition.info)
            if GPSDeviceOffsetAuto and GPSDeviceOffsetAuto.enabled then
                local auto=GPSDeviceOffsetAuto
                local measured=auto.ready and type(auto.center)=="number"
                debugInfo=debugInfo..(measured and
                    string.format(" | Geraete-Auto Mitte %+.2f m",auto.center)
                    or " | Geraete-Auto: Messung ausstehend")
            end
            renderText(0.02,0.786,0.015,"GPS: "..debugInfo)
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
        self.angleMode=false;self.rotateHeld=nil
        local stage=GPSABLineManager.captureStage
        if stage=="armed" then
            self:commandA()
        elseif stage=="measuring" and GPSABLineManager.a~=nil and
                GPSABLineManager.b==nil then
            self:commandB()
        else
            GPSLogger.info(GPSABLineManager.armCapture())
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
function GPSFieldTest:commandRotateFine(direction,quiet)
    if not self:isMasterEnabled() then return false,"TerraLine GPS AUS" end
    if GPSMenu and GPSMenu.isOpen() then return false,"Menue geoeffnet" end
    if not self.angleMode then return false,"Spurwinkelmodus AUS (Rechts-Alt+W)" end
    local ok,msg=GPSCourseManager.rotateAroundVehicle(direction*0.1,quiet)
    if not quiet then GPSLogger.info("GPS Feindrehung: "..tostring(msg)) end
    return ok,msg
end
function GPSFieldTest:onRotateKey(direction,inputValue)
    if not self:isMasterEnabled() then self.rotateHeld=nil;return end
    if (g_gui and g_gui.currentGui~=nil) or (GPSMenu and GPSMenu.isOpen()) then self.rotateHeld=nil;return end
    if inputValue==nil then return end
    if inputValue>0.5 then
        if self.rotateHeld and self.rotateHeld.direction==direction then return end
        if not self.angleMode then return end
        local ok,msg=self:commandRotateFine(direction,false)
        if ok then
            self.rotateHeld={direction=direction,elapsed=0,nextAt=380}
        else
            self.rotateHeld=nil
        end
    elseif self.rotateHeld and self.rotateHeld.direction==direction then
        self.rotateHeld=nil
    end
end
function GPSFieldTest:onRotateEastKey(actionName,inputValue,callbackState,isAnalog)
    self:onRotateKey(1,inputValue)
end
function GPSFieldTest:onRotateWestKey(actionName,inputValue,callbackState,isAnalog)
    self:onRotateKey(-1,inputValue)
end
function GPSFieldTest:onShiftRightKey(actionName,inputValue,callbackState,isAnalog)
    self:onShiftKey(1,inputValue)
end
function GPSFieldTest:onShiftLeftKey(actionName,inputValue,callbackState,isAnalog)
    self:onShiftKey(-1,inputValue)
end
function GPSFieldTest:commandResetLaneNumbering()
    if not self:isMasterEnabled() or (GPSMenu and GPSMenu.isOpen()) then return false end
    local vehicle=GPSVehicleDetector.getCurrentVehicle()
    local ok,msg=GPSTrackPosition.resetLaneNumbering(vehicle)
    GPSLogger.info("Alt+X LANG: "..tostring(msg))
    if ok and GPSSteeringController and GPSSteeringController.enabled and GPSSteeringController.lockedTrack~=nil then
        local shown=GPSTrackPosition.getDisplayNumber(GPSSteeringController.lockedTrack)
        GPSSteeringController.reason="Aktiv | Spur "..tostring(shown)
    end
    return ok
end
function GPSFieldTest:onAssistKey(actionName,inputValue,callbackState,isAnalog)
    -- Unlike the previous press-only action, both key DOWN and UP are required
    -- to distinguish a short toggle from a long hold. No toggle on long hold.
    if inputValue==nil then
        self:handleKeyAction("ASSIST","ActionEvent ohne Tastenzustand")
        return
    end
    if inputValue>0.5 then
        if not self.assistHeld and self:isMasterEnabled()
            and not (g_gui and g_gui.currentGui~=nil)
            and not (GPSMenu and GPSMenu.isOpen()) then
            self.assistHeld={startedAt=self.totalMs or 0,triggered=false}
        end
    else
        local held=self.assistHeld
        self.assistHeld=nil
        if held and not held.triggered then
            if (self.totalMs or 0)-held.startedAt>=3000 then
                self:commandResetLaneNumbering()
            else
                self:handleKeyAction("ASSIST","ActionEvent kurz")
            end
        end
    end
end
function GPSFieldTest:onABKey(actionName,inputValue,callbackState,isAnalog)
    -- One step per press, not per release. Keep the shared 300ms debounce.
    if inputValue==nil or inputValue>0.5 then
        self:handleKeyAction("AB","ActionEvent")
    end
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
    local actions={AB="GPS_FIELD_AB_MARK",ASSIST="GPS_FIELD_ASSIST_TOGGLE",
        SHIFT_RIGHT="GPS_FIELD_SHIFT_RIGHT",SHIFT_LEFT="GPS_FIELD_SHIFT_LEFT",
        MENU="GPS_FIELD_MENU_TOGGLE",ROTATE="GPS_FIELD_ROTATE_90",
        ROTATE_MODE="GPS_FIELD_ROTATE_MODE",ROTATE_EAST="GPS_FIELD_ROTATE_EAST",
        ROTATE_WEST="GPS_FIELD_ROTATE_WEST",POWER="GPS_FIELD_POWER_TOGGLE"}
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
    local callbacks={AB=self.onABKey,ASSIST=self.onAssistKey,
        SHIFT_RIGHT=self.onShiftRightKey,SHIFT_LEFT=self.onShiftLeftKey,
        MENU=self.onMenuKey,ROTATE=self.onRotate90Key,
        ROTATE_MODE=self.onAngleModeKey,ROTATE_EAST=self.onRotateEastKey,
        ROTATE_WEST=self.onRotateWestKey,POWER=self.onPowerKey}
    local callback=callbacks[kind]
    local heldAction=kind=="ASSIST" or kind=="SHIFT_RIGHT" or kind=="SHIFT_LEFT" or kind=="ROTATE_EAST" or kind=="ROTATE_WEST"
    local registered,eventId=binding:registerActionEvent(id,self,callback,heldAction,true,false,true)
    if registered then
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
    if not self:isMasterEnabled() then return "TerraLine GPS AUS oder nicht eingebaut" end
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
    local vehicle=GPSVehicleDetector.getCurrentVehicle()
    -- Shortcut RIGHT/LEFT is driver-relative, exactly like the menu stepper.
    local ok,message=GPSABLineManager.shiftDriverRelative(direction,0.01,vehicle)
    if ok then
        local width=GPSImplementDetector.getWidth(vehicle)
        GPSTrackGenerator.generate(nil,GPSABLineManager.a,GPSABLineManager.b,width)
        GPSTrackGenerator.cacheKey=tostring(GPSABLineManager.a)..":"..tostring(GPSABLineManager.b)..":"..tostring(width)
        -- Refresh the displayed offset on the next regular position update.
        GPSTrackPosition.lastUpdate=150
    end
    if not quiet then GPSLogger.info(tostring(message).." | gesamte GPS-Spur inkl. Arbeitsbreitengrenzen") end
    if quiet and GPSConfig and GPSConfig.showDiagnostics then
        local clock=self.totalMs or 0
        if clock-(self.lastDiagShiftAt or -100000)>=500 then
            self.lastDiagShiftAt=clock
            GPSLogger.debug(string.format("VERSATZ: seitlich=%+.2fm richtung=%d",GPSABLineManager.offsetMeters or 0,direction))
        end
    end
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
    GPSImplementDetector.override=n
    if GPSImplementDetector.resetCombo then GPSImplementDetector.resetCombo() end
    GPSTrackGenerator.reset()
    return string.format("GPS Arbeitsbreite manuell %.1f m",n)
end
function GPSFieldTest:commandClear()
    self.angleMode=false;self.rotateHeld=nil
    GPSSteeringController.stop("A/B geloescht");GPSABLineManager.clear();GPSTrackGenerator.reset();return "GPS A/B zurueckgesetzt"
end
function GPSFieldTest:commandAutoWidth()
    GPSSteeringController.stop("Breite neu ermittelt")
    GPSImplementDetector.override=nil
    if GPSImplementDetector.resetCombo then GPSImplementDetector.resetCombo() end
    GPSTrackGenerator.reset()
    return "GPS automatische Breite aktiviert (Kombimaeher nach Stillstand einmessen)"
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
function GPSFieldTest:commandWorkWidthDiag()
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle and
        GPSVehicleDetector.getCurrentVehicle()
    if GPSDeviceOffsetProbe and type(GPSDeviceOffsetProbe.logWidthDiagnostic)=="function" then
        return GPSDeviceOffsetProbe.logWidthDiagnostic(vehicle)
    end
    return "TerraLine: Breiten-Diagnose nicht verfuegbar"
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
    addConsoleCommand("gsTLGPSDiag","Testdiagnose dieser Instanz: on/off/status/snapshot","consoleDiagnostics",GPSDeveloperMenu)
    addConsoleCommand("gsGPSPower","TerraLine GPS Hauptschalter: on/off/toggle","commandMaster",GPSFieldTest)
    addConsoleCommand("gsGPSMenu","GPS Einstellungsmenue oeffnen/schliessen","commandMenu",GPSFieldTest)
    -- gsGPSSteerTest is intentionally not exposed in the public beta.
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
    addConsoleCommand("gsGPSWorkWidthDiag","Arbeitsbereiche aller Anbaugeraete in log.txt ausgeben (nur Diagnose)","commandWorkWidthDiag",GPSFieldTest)
end
