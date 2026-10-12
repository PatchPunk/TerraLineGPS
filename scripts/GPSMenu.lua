-- TerraLine GPS v0.9.9.22: pages 1, 3, 4 drawn natively with working controls.
-- Deleted page 2 (the offset controls already live on page 1).
GPSMenu = { registered=false, guiName="GPSFieldTestMenu", modDir=g_currentModDirectory }
GPSMenuScreen = {}
local GPSMenuScreen_mt = Class(GPSMenuScreen, ScreenElement)

function GPSMenuScreen.new(target, customMt)
    local self=ScreenElement.new(target,customMt or GPSMenuScreen_mt)
    self.page=1
    self.images={}
    return self
end

function GPSMenuScreen:onOpen(...)
    GPSMenuScreen:superClass().onOpen(self,...)
    self.page=1
    self.page3Opened=false
    if GPSDeveloperMenu then GPSDeveloperMenu.close() end
    if GPSMenuPage1 ~= nil then GPSMenuPage1.onOpen(self) end
    self.loggedDraw=false
    self.loggedNativeDraw=false
    self.loggedNoOverlay=false
    self.layerDrawn=false
    GPSLogger.info("GPS Menue: onOpen aufgerufen")
    -- This action is registered in the GUI input context so the same user-
    -- rebindable key can also close this screen.
    local binding=g_inputBinding
    local id=InputAction and InputAction.GPS_FIELD_MENU_TOGGLE
    if binding and id and type(binding.registerActionEvent)=="function" then
        pcall(binding.registerActionEvent,binding,id,self,self.onToggleKey,false,true,false,true)
    end
    -- Individual compressed DDS pages are created on first visit, not all
    -- at menu open. Overlay instances are cached for subsequent visits.
    -- Geometry: centered, 25 percent smaller than v0.9.9.5 (0.9*0.75 = 0.675).
    self.pageX,self.pageY,self.pageW,self.pageH=0.213125,0.213125,0.57375,0.57375
    GPSLogger.info("TerraLine GPS Menue geoeffnet (Seiten 1, 3 und 4; S2 entfernt)")
end

function GPSMenuScreen:onClose(...)
    if GPSMenuSymbols and GPSMenuSymbols.onClose then GPSMenuSymbols.onClose(self) end
    if GPSMenuPage1 and GPSMenuPage1.onClose then GPSMenuPage1.onClose(self) end
    if g_inputBinding and type(g_inputBinding.removeActionEventsByTarget)=="function" then
        g_inputBinding:removeActionEventsByTarget(self)
    end
    GPSMenuScreen:superClass().onClose(self,...)
end

-- GIANTS Gui:keyEvent forwards raw Unicode keys to the current screen.
function GPSMenuScreen:keyEvent(unicode,sym,modifier,isDown,eventUsed)
    if self.page==4 and GPSDeveloperMenu and GPSDeveloperMenu.editing then return GPSDeveloperMenu.keyEvent(unicode,sym,modifier,isDown) end
    if self.page==3 and self.page3Edit and GPSMenuPage3 and GPSMenuPage3.keyEvent then
        return GPSMenuPage3.keyEvent(self,unicode,sym,modifier,isDown)
    end
    return GPSMenuScreen:superClass().keyEvent(self,unicode,sym,modifier,isDown,eventUsed)
end

function GPSMenuScreen:onToggleKey(actionName,inputValue)
    if self.page==4 and GPSDeveloperMenu and GPSDeveloperMenu.editing then return end
    if self.page==3 and self.page3Edit then return end
    if inputValue==nil or inputValue>0.5 then self:onClickBack() end
end

function GPSMenuScreen:onClickBack()
    if self.page==4 and GPSDeveloperMenu and (GPSDeveloperMenu.editing or GPSDeveloperMenu.unlocked) then GPSDeveloperMenu.close();return end
    if self.page==1 and self.page1VisualSettings then self.page1VisualSettings=false;return end
    if self.page==3 and self.page3Edit then self.page3Edit=nil;return end
    if g_gui then g_gui:showGui("") end
end

function GPSMenuScreen:inputEvent(action,value,eventUsed)
    if self.page==4 and GPSDeveloperMenu and GPSDeveloperMenu.editing then return true end
    if self.page==3 and self.page3Edit then
        -- KeyEvent handles ESC/Enter; do not let menu bindings close the GUI.
        return true
    end
    if (value==nil or value>0.5) then
        if action==InputAction.MENU_BACK or action==InputAction.GPS_FIELD_MENU_TOGGLE then
            self:onClickBack()
            return true
        end
        if action==InputAction.MENU_PAGE_NEXT or action==InputAction.MENU_PAGE_PREV then
            local pages={1,3,4}
            local at=1
            for i,v in ipairs(pages) do if self.page==v then at=i;break end end
            at=((at-1+(action==InputAction.MENU_PAGE_NEXT and 1 or -1))%#pages)+1
            self.page=pages[at]
            return true
        end
    end
    return GPSMenuScreen:superClass().inputEvent(self,action,value,eventUsed)
end

function GPSMenuScreen:mouseEvent(posX,posY,isDown,isUp,button,eventUsed)
    if isUp and (button==Input.MOUSE_BUTTON_LEFT or button==1) then
        -- Convert screen mouse coordinates back to the image's 0..1 space
        -- so all controls stay aligned after changing display scale.
        local px=(posX-self.pageX)/self.pageW
        local top=((1-posY)-self.pageY)/self.pageH
        if px<0 or px>1 or top<0 or top>1 then
            return GPSMenuScreen:superClass().mouseEvent(self,posX,posY,isDown,isUp,button,eventUsed)
        end
        if (self.page==1 and GPSMenuPage1 and GPSMenuPage1.onMouseClick(self,px,top)) or
           (self.page==3 and GPSMenuPage3 and GPSMenuPage3.onMouseClick(self,px,top)) or
           (self.page==4 and GPSMenuPage4 and GPSMenuPage4.onMouseClick(self,px,top)) then
            return true
        end
        if (px>0.91 and top<0.14) or (px<0.23 and top>0.89) then
            self:onClickBack()
            return true
        end
        if px>0.018 and px<0.21 then
            local visiblePages={1,3,4}
            for slot,pageId in ipairs(visiblePages) do
                local y=0.164+(slot-1)*0.124
                if top>=y and top<=y+0.110 then
                    self.page=pageId
                    GPSLogger.info("GPS Menue: Seite "..tostring(pageId))
                    return true
                end
            end
        end
        -- All three visible pages are native GUI.
        return true
    end
    return GPSMenuScreen:superClass().mouseEvent(self,posX,posY,isDown,isUp,button,eventUsed)
end

-- Draw the picture from a native GuiElement callback, i.e. from GIANTS'
-- actual 2D GUI render pass. Merely loading the screen and its textures
-- does not prove the page has been drawn.
function GPSMenuScreen:renderMenuPage(from)
    if not self.isOpen then return end
    if self.page==2 then self.page=1 end
    if self.page==3 and GPSMenuPage3~=nil then
        if not self.page3Opened then GPSMenuPage3.onOpen(self);self.page3Opened=true end
        GPSMenuPage3.draw(self)
        return
    end
    if self.page==1 and GPSMenuPage1~=nil then
        GPSMenuPage1.draw(self)
        if not self.loggedNativeDraw then
            self.loggedNativeDraw=true
            GPSLogger.info("GPS Menue: S1 nativer GUI-Text und Bedienelemente gezeichnet")
        end
        return
    end
    if self.page==4 and GPSMenuPage4 then
        GPSMenuPage4.draw(self)
        return
    end
    local img=self.images[self.page]
    if img==nil and type(Overlay)=="table" and type(Overlay.new)=="function" then
        img=Overlay.new(GPSMenu.modDir.."gui/menuPage"..self.page..".dds",self.pageX,self.pageY,self.pageW,self.pageH)
        self.images[self.page]=img
    end
    if img and img.overlayId and img.overlayId ~= 0 then
        img:render()
        if not self.loggedDraw then
            self.loggedDraw=true
            GPSLogger.info("GPS Menue: ERSTER BILDAUFBAU erfolgreich ("..tostring(from)..", Seite "..tostring(self.page)..", overlayId="..tostring(img.overlayId)..")")
        end
    else
        if not self.loggedNoOverlay then
            self.loggedNoOverlay=true
            GPSLogger.info("GPS Menue: Seitenbild fehlt beim Zeichnen (Seite "..tostring(self.page)..")")
        end
        if type(drawFilledRect)=="function" then drawFilledRect(0.10,0.25,0.80,0.50,0.10,0.15,0.12,0.95) end
        if type(renderText)=="function" then renderText(0.18,0.53,0.028,"GPS-Menue: Seitenbild konnte nicht dargestellt werden") end
    end
end

-- Called by the GUI element with onDraw=...; this is the primary render path.
function GPSMenuScreen:onMenuLayerDraw(element)
    self.layerDrawn=true
    self:renderMenuPage("GIANTS GuiElement.onDraw")
end

function GPSMenuScreen:draw(...)
    -- Shop/workshop changes or vehicle switches can occur while the screen is
    -- open. An unequipped vehicle must never retain access to the GPS menu.
    if self.isOpen and not GPSMenu.isAvailableForCurrentVehicle() then
        if g_gui and type(g_gui.showGui)=="function" then g_gui:showGui("") end
        return
    end
    self.layerDrawn=false
    GPSMenuScreen:superClass().draw(self,...)
    -- Extra safety in case the XML child failed to emit its callback.
    if not self.layerDrawn then
        self:renderMenuPage("ScreenElement.draw fallback")
    end
end

function GPSMenu.register()
    if GPSMenu.registered then return true end
    if g_gui==nil or type(g_gui.loadGui)~="function" or type(ScreenElement)~="table" then return false end
    local controller=GPSMenuScreen.new()
    local ok,gui=pcall(g_gui.loadGui,g_gui,GPSMenu.modDir.."gui/GPSMenu.xml",GPSMenu.guiName,controller)
    if ok and gui~=nil then
        GPSMenu.screen=controller
        GPSMenu.registered=true
        GPSLogger.info("GPS Menue (S1, S3, S4) ueber GIANTS ScreenElement registriert")
        return true
    end
    if not GPSMenu.registerFailureLogged then
        GPSLogger.info("GPS Menue Registrierung fehlgeschlagen: "..tostring(ok and "XML nicht geladen" or gui))
        GPSMenu.registerFailureLogged=true
    end
    return false
end
function GPSMenu.isOpen()
    return GPSMenu.screen~=nil and GPSMenu.screen.isOpen==true
end
function GPSMenu.isAvailableForCurrentVehicle()
    local vehicle=GPSVehicleDetector and GPSVehicleDetector.getCurrentVehicle and
        GPSVehicleDetector.getCurrentVehicle()
    return vehicle~=nil and GPSVehicleEquipment~=nil and
        type(GPSVehicleEquipment.isInstalled)=="function" and
        GPSVehicleEquipment.isInstalled(vehicle)==true
end
function GPSMenu.toggle()
    -- This central gate covers the native keybind, keyboard fallback and the
    -- gsGPSMenu console command. Unpowered but EQUIPPED vehicles may open it.
    if not GPSMenu.isOpen() and not GPSMenu.isAvailableForCurrentVehicle() then
        GPSLogger.info("GPS Menue gesperrt: TerraLine GPS fuer dieses Fahrzeug nicht eingebaut")
        return false
    end
    if not GPSMenu.register() then
        GPSLogger.info("GPS Menue: GUI noch nicht verfuegbar")
        return false
    end
    if GPSMenu.isOpen() then
        GPSLogger.info("GPS Menue: Schliessen angefordert")
        GPSMenu.screen:onClickBack()
        return true
    end
    if not g_gui then
        GPSLogger.info("GPS Menue: g_gui fehlt")
        return false
    end
    if g_gui.currentGui~=nil then
        GPSLogger.info("GPS Menue: Anderes GIANTS-Menue offen ("..tostring(g_gui.currentGuiName or "unbekannt")..")")
        return false
    end
    GPSLogger.info("GPS Menue: Oeffnen angefordert")
    local ok,result=pcall(g_gui.showGui,g_gui,GPSMenu.guiName)
    local shown=ok and result~=nil
    GPSLogger.info("GPS Menue: showGui="..tostring(shown)..(ok and "" or (" Fehler="..tostring(result))))
    return shown
end
