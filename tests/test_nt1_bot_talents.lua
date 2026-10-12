-- Standalone WoW 3.3.5a UI/transport regression for NT1 playerbot import.
-- Uses a minimal mocked frame surface. Does not change character data.
MultiBot = {}
UISpecialFrames = {}
StaticPopupDialogs = {}
local activeConfirmation
function StaticPopup_Show(key, text)
    assert(StaticPopupDialogs[key] and type(text)=="string")
    activeConfirmation = {key=key,text=text}
    return activeConfirmation
end
local frames, commands, errors = {}, {}, {}
local currentTarget = {name="Testwarrior", class="WARRIOR", guid="Player-01"}
local Frame = {}
Frame.__index = Frame
function Frame:SetWidth(value) self.width=value end
function Frame:SetHeight(value) self.height=value end
function Frame:SetSize(width, height) self.width=width self.height=height end
function Frame:SetPoint(...) self.position={...} end
function Frame:SetText(value) self.text=value end
function Frame:GetText() return self.text end
function Frame:SetJustifyH(value) self.justify=value end
function Frame:SetTextColor(...) self.color={...} end
function Frame:SetNormalFontObject(font) self.normalFont=font end
function Frame:SetHighlightFontObject(font) self.highlightFont=font end
function Frame:SetAllPoints(frame) self.allPoints=frame end
function Frame:SetTexture(path) self.texture=path end
function Frame:SetVertexColor(...) self.vertexColor={...} end
function Frame:CreateTexture(_,layer)
    return setmetatable({scripts={},parent=self,layer=layer},Frame)
end
function Frame:SetFontObject(value) self.font=value end
function Frame:SetAutoFocus() end
function Frame:SetMaxLetters(value) self.maxLetters=value end
function Frame:SetMultiLine(value) self.multiline=value end
function Frame:SetScrollChild(child) self.scrollChild=child end
function Frame:HighlightText() self.highlighted=true end
function Frame:SetFrameStrata() end
function Frame:SetMovable() end
function Frame:SetClampedToScreen() end
function Frame:EnableMouse() end
function Frame:RegisterForDrag() end
function Frame:SetBackdrop() end
function Frame:SetBackdropColor() end
function Frame:SetBackdropBorderColor() end
function Frame:SetFocus() self.focused=true end
function Frame:ClearFocus() self.focused=false end
function Frame:RegisterEvent(event)
    self.registeredEvents=self.registeredEvents or {}
    self.registeredEvents[event]=true
end
function Frame:SetAttribute(name,value)
    self.attributes=self.attributes or {}
    self.attributes[name]=value
end
function Frame:HookScript(event,fn)
    local prior=self.scripts[event]
    self.scripts[event]=function(frame,...)
        if prior then prior(frame,...) end
        -- This is a mock of the native SecureActionButton OnClick:
        -- if the test supplied a nearby named unit, target it before the
        -- insecure hook. Never simulate /targetexact as ordinary addon Lua.
        if frame.template and frame.template:find(
            "SecureActionButtonTemplate",1,true) and
            frame.attributes and frame.attributes.type1=="macro" then
            local name=(frame.attributes.macrotext1 or ""):match(
                "^/targetexact ([A-Za-z]+)$")
            if name then
                frame.lastSecureTarget=name
                if frame.simulateSecureClick then
                    frame:simulateSecureClick(name)
                end
            end
        end
        fn(frame,...)
    end
end
function Frame:SetScript(event, callback) self.scripts[event]=callback end
function Frame:Show() self.visible=true end
function Frame:Hide() self.visible=false end
function Frame:IsShown() return self.visible end
function Frame:CreateFontString()
    return setmetatable({scripts={},parent=self},Frame)
end
function CreateFrame(kind,name,parent,template)
    assert(template~="UIPanelScrollFrameTemplate" or
        (type(name)=="string" and name~=""),
        "WoW 3.3.5a scroll-frame OnLoad requires a named template")
    local f=setmetatable({kind=kind,name=name,parent=parent,template=template,scripts={}},Frame)
    frames[#frames+1]=f
    if name then _G[name]=f end
    return f
end
UIParent=CreateFrame("Frame","UIParent")
UIErrorsFrame={AddMessage=function(_,value) errors[#errors+1]=value end}
function UnitExists(unit) return unit=="target" and currentTarget ~= nil end
function UnitIsPlayer(unit) return unit=="target" and currentTarget ~= nil end
function UnitIsUnit(unit,other) return unit=="target" and other=="player" and currentTarget and currentTarget.name=="Actualplayer" end
function UnitName(unit) return unit=="target" and currentTarget and currentTarget.name end
function UnitGUID(unit) return unit=="target" and currentTarget and currentTarget.guid end
function UnitClass(unit)
    if unit~="target" or not currentTarget then return nil,nil end
    local token=currentTarget.class or "WARRIOR"
    return token=="MAGE" and "Mage" or "Warrior",token
end
function SendChatMessage(command,channel)
    assert(channel=="SAY","NT1 commands must use the actual Naxxramas GM command pathway")
    commands[#commands+1]=command
end

dofile("UI/MultiBotNT1TalentsUI.lua")
local importer=assert(MultiBot.NT1Talents)
local created={}
local right={addButton=function(name,x,y,icon,tip)
    local button={name=name,x=x,y=y,icon=icon,tip=tip}
    created[#created+1]=button
    return button
end}
assert(MultiBot.InitializeNT1TalentsUI(right)==importer)
assert(#created==1 and created[1].name=="NT1Talents" and created[1].x==136,
    "One new right-side NT1 talents button should be present")
assert(created[1].tip:find("Naxxramas Core",1,true))
assert(created[1].tip:find("0 off;",1,true) and
    created[1].tip:find("1 GM Apply;",1,true) and
    created[1].tip:find("2 permitted-player Apply.",1,true) and
    created[1].tip:find("3 GM read-only;",1,true) and
    created[1].tip:find("4 permitted-player read-only.",1,true) and
    not created[1].tip:find("Requires Naxxramas Core BotTalentImport AccessMode 1 or 2.",1,true),
    "NT1 tooltip must explain server-owned modes 0–4, not imply only 1/2")
assert(MultiBot.InitializeNT1TalentsUI(right)==importer and #created==1,
    "Repeated initialization must not duplicate toolbar buttons")
assert(importer:ValidateCode("NT1:vanilla:warrior:3g-1", "warrior"))
assert(not importer:ValidateCode("NT1:vanilla:mage:2t-1", "warrior"),
    "Client must reject a code for the wrong target class")
assert(not importer:ValidateCode("NT1:vanilla:warrior:"),
    "An empty build cannot be applied accidentally")
assert(not importer:ValidateCode("NT1:vanilla:warrior:3g-1.3g-2"),
    "Duplicate talent entries are invalid")
assert(not importer:ValidateCode("NT1:vanilla:warrior:3g-1\n.naxxbot talents apply OtherPlayer NT1:"),
    "Chat-command injection must be rejected")
assert(not importer:ValidateCode("NT1:vanilla:warrior:3g-10"),
    "Rank 10 is not valid in NT1")
assert(not importer:ValidateCode("NT1:vanilla:warrior:3g-6"),
    "Rank 6 is impossible in server Talent.dbc")
assert(not importer:DescribeCode("NT1:vanilla:warrior:3g-9"),
    "Malformed rank must not crash the read-only summary")
assert(not importer:ValidateCode("NT1:other:warrior:2t-1"),
    "Unknown eras are rejected")

currentTarget=nil
assert(not importer:Open(),"No target must not show the importer")
assert(#commands==0,"Target errors must never issue commands")
currentTarget={name="Actualplayer",guid="Player-99",class="WARRIOR"}
assert(not importer:Open(),"Do not allow own player character as bot target")
currentTarget={name="Testwarrior",guid="Player-01",class="WARRIOR"}
assert(importer:Open(),"Selected bot must open the NT1 paste window")
assert(importer.importCodePanel and importer.importInfoPanel and
    importer.importNamePanel and importer.status.parent==importer.importInfoPanel,
    "NT1 Import visual sections must exist in standalone UI test")
assert(importer.applyButton and
    importer.applyButton.template:find("SecureActionButtonTemplate",1,true) and
    importer.applyButton.attributes.type1=="macro" and
    importer.applyButton.attributes.macrotext1=="/targetexact Testwarrior",
    "Apply must use a secure exact-name targeting click")
assert(type(importer.applyButton.scripts.OnClick)=="function")
local popup=assert(importer.window)
assert(popup.visible and importer.input.maxLetters==2048)
assert(importer.importPage.visible and not importer.savedPage.visible,
    "NT1 opens in Page 1 import by default")
assert(importer.nameBox.maxLetters==40 and importer.savedButton and
    importer.saveButton and importer.deleteButton and importer.loadButton,
    "Two-page window requires all saved-code controls")
assert(popup.width == 660 and popup.height == 465,
    "NT1 popup needs increased vertical room for large WoW UI fonts")
assert(importer.input.position[5] == -106 and
    importer.status.position[5] == -11 and
    importer.targetLabel.position[5] == -68 and
    importer.buildSummary.position[5] == -37 and
    importer.importSafety.position[5] == -64 and
    importer.importSaveLabel.position[5] == -13 and
    importer.status.parent == importer.importInfoPanel and
    importer.buildSummary.parent == importer.importInfoPanel and
    importer.importSafety.parent == importer.importInfoPanel and
    importer.importSaveLabel.parent == importer.importNamePanel,
    "NT1 code, status, build and safety rows must not collide")
assert(importer.safetyButton and
    importer.safetyButton.text=="Safety Inspection" and
    importer.safetyButton.position[4]==34 and
    importer.safetyButton.position[5]==150 and
    importer.safetyButton.width==184 and
    importer.safetyButton.height==25 and
    not (importer.safetyButton.template or ""):find("SecureActionButtonTemplate",1,true),
    "Read-only Safety Inspection must fit the spare Save As row without moving Apply")
assert(created[1].icon == "INV_Misc_Book_07",
    "Use the standard book icon rather than the invisible custom Talent.blp")
assert(importer.targetLabel.text:find("Testwarrior",1,true))
assert(#UISpecialFrames==1 and UISpecialFrames[1]=="MultiBotNT1TalentsWindow")
assert(#commands==0,"Opening the paste dialog must never send an apply")

local code="NT1:vanilla:warrior:3g-1"
importer.input:SetText(code)
local ok,previewStatus=importer:SendToTarget("preview",importer.input:GetText())
assert(ok and #commands==1 and commands[1]==
    ".naxxbot talents preview Testwarrior "..code,
    "Preview should send the exact read-only Naxxramas Core command")
assert(previewStatus=="Preview sent for Testwarrior. See server chat." and
    #previewStatus <= 58 and
    not previewStatus:find("Apply-ready",1,true),
    "Preview status must remain one line and never claim server approval")
assert(importer:SendToTarget("preview",code) and #commands==2,
    "Repeat Preview is read-only and does not authorize Apply")
assert(importer.status and type(StaticPopupDialogs)=="table")
assert(popup.visible,"Preview must keep input available")

-- Code must never silently be sent to a new target.
currentTarget={name="Otherwarrior",guid="Player-02",class="WARRIOR"}
assert(not importer:SendToTarget("apply",code))
assert(#commands==2)
currentTarget={name="Testwarrior",guid="Player-03",class="WARRIOR"}
assert(not importer:SendToTarget("apply",code),
    "Same visible name with a different GUID must not be accepted")
assert(#commands==2)
currentTarget={name="Testwarrior",guid="Player-01",class="MAGE"}
local mageCode="NT1:vanilla:mage:3g-1"
assert(not importer:SendToTarget("preview",mageCode) and #commands==2,
    "Same-name/GUID target reporting another class must not send Preview")
local classMatched,classHint,classGuided=importer:CheckIntendedTarget("apply")
assert(not classMatched and not classGuided and
    classHint:find("class differs",1,true) and #commands==2,
    "Previously bound class cannot be silently replaced on recheck")
currentTarget={name="Testwarrior",guid="Player-01",class="WARRIOR"}

-- WoW chat has a finite payload: do not issue truncated high-rank NT1 codes.
local longParts = {}
for i = 1, 50 do
    longParts[#longParts+1] = string.format("%x-1", i)
end
local longCode="NT1:vanilla:warrior:"..table.concat(longParts, ".")
assert(importer:ValidateCode(longCode,"warrior"))
assert(not importer:SendToTarget("apply",longCode))
assert(#commands==2,"Oversized chat payload must not reach the server")

importer.input:SetText(code)
importer.input.scripts.OnEnterPressed(importer.input)
assert(#commands==2 and popup.visible,
    "Enter in NT1 code field must never send Apply")
local details=importer:DescribeCode(code)
assert(details.class=="warrior" and details.era=="vanilla" and
    details.points==1 and details.role=="not specified")
importer.applyButton.scripts.OnClick(importer.applyButton)
assert(importer.applyButton.lastSecureTarget=="Testwarrior" and
    #commands==2 and activeConfirmation and
    activeConfirmation.text:find("Testwarrior",1,true) and
    activeConfirmation.text:find("1 selected points",1,true),
    "Apply requires confirmation with target and build summary")
assert(activeConfirmation.text:find("1 selected points",1,true))
assert(StaticPopupDialogs[activeConfirmation.key].text:find(
    "Experimental: server may reject.",1,true))
local cancelledCallback=StaticPopupDialogs[activeConfirmation.key].OnAccept
StaticPopupDialogs[activeConfirmation.key].OnCancel()
assert(#commands==2 and popup.visible,
    "Cancel confirmation must not send any command")
importer.applyButton.scripts.OnClick(importer.applyButton)
cancelledCallback()
assert(#commands==2,"A stale popup callback must not apply the next request")
currentTarget={name="Otherwarrior",guid="Player-55",class="WARRIOR"}
StaticPopupDialogs[activeConfirmation.key].OnAccept()
assert(#commands==2 and popup.visible,
    "Changing target while confirming must block Apply")
currentTarget={name="Testwarrior",guid="Player-01",class="WARRIOR"}
importer.applyButton.scripts.OnClick(importer.applyButton)
importer.input:SetText("NT1:vanilla:warrior:3g-2")
StaticPopupDialogs[activeConfirmation.key].OnAccept()
assert(#commands==2 and popup.visible,
    "Editing the NT1 code while confirming must block Apply")
importer.input:SetText(code)
importer.applyButton.scripts.OnClick(importer.applyButton)
StaticPopupDialogs[activeConfirmation.key].OnAccept()
assert(#commands==3 and commands[3]==
    ".naxxbot talents apply Testwarrior "..code,
    "Only the second, validated confirmation may dispatch Apply")
assert(not popup.visible,"Successful confirmed submission closes popup")
assert(importer:Open(),"Reopen should work")
assert(importer.input.text=="","Reopen must not reuse a dangerous previously pasted code")
-- Direct import retains bot GUID and rejects a same-named replacement.
importer.input:SetText(code)
currentTarget={name="Testwarrior",guid="Player-New",class="WARRIOR"}
local matched,hint,guided=importer:CheckIntendedTarget("apply")
assert(not matched and not guided and
    hint:find("identity differs",1,true))
assert(#commands==3)
currentTarget={name="Testwarrior",guid="Player-01",class="WARRIOR"}
assert(#UISpecialFrames==1,"ESC registration must never duplicate")
importer.input.scripts.OnEscapePressed(importer.input)
assert(not popup.visible and not importer.input.focused,
    "Escape should cancel the window without sending commands")
assert(#commands==3)

-- Server PR #16: no-code Safety Inspection is separate from NT1 Preview/Apply.
-- No server mode is guessed or enabled locally; the server may reject it.
assert(importer:Open())
assert(importer.input:GetText()=="" and importer.requestedBot=="Testwarrior")
local beforeInspection=#commands
importer.safetyButton.scripts.OnClick(importer.safetyButton)
assert(#commands==beforeInspection+1 and
    commands[#commands]==".naxxbot talents safetypreview Testwarrior" and
    importer.status.text:find("Safety request sent for Testwarrior.",1,true) and
    importer.status.text:find("See server chat.",1,true) and
    #importer.status.text <= 64 and
    not importer.status.text:find("Apply-ready",1,true),
    "Safety Inspection click must send precisely one no-code read-only request")
assert(importer.input:GetText()=="" and not importer.pendingApply,
    "Safety Inspection must not require NT1 text or open Apply confirmation")
importer.input:SetText("NT1:vanilla:warrior:3g-1")
importer.safetyButton.scripts.OnClick(importer.safetyButton)
assert(#commands==beforeInspection+2 and
    commands[#commands]==".naxxbot talents safetypreview Testwarrior",
    "Safety Inspection must never append the current NT1 code")
currentTarget={name="Otherwarrior",guid="Player-02",class="WARRIOR"}
importer.safetyButton.scripts.OnClick(importer.safetyButton)
assert(#commands==beforeInspection+2 and
    importer.status.text:find("Safety Inspection.",1,true) and
    importer.awaitingTarget and importer.awaitingAction=="safetypreview",
    "Wrong target must guide a manual target switch, not submit a safety command")
currentTarget={name="Testwarrior",guid="Player-01",class="WARRIOR"}
importer:OnTargetChanged()
assert(#commands==beforeInspection+2 and
    importer.status.text:find("Target verified. Click Safety Inspection.",1,true),
    "Target-changed event must not auto-dispatch Safety Inspection")
currentTarget={name="Testwarrior",guid="Player-22",class="WARRIOR"}
importer.safetyButton.scripts.OnClick(importer.safetyButton)
assert(#commands==beforeInspection+2 and
    importer.status.text:find("identity differs",1,true),
    "Recycled bot name with different GUID must fail closed")
currentTarget={name="Testwarrior",guid="Player-01",class="MAGE"}
importer.safetyButton.scripts.OnClick(importer.safetyButton)
assert(#commands==beforeInspection+2,
    "Wrong target class must fail closed before diagnostics")
currentTarget={name="Bot;apply",guid="Player-Unsafe",class="WARRIOR"}
-- Mock UnitClass returns an uppercase WoW token; the actual bound class
-- is always normalized to lowercase by getTarget() in the real client.
importer.boundTarget={name=currentTarget.name,guid=currentTarget.guid,
    class="warrior"}
importer.requestedBot=currentTarget.name
local rejected,why=importer:SendSafetyInspection()
assert(not rejected and why:find("Unsupported bot name",1,true) and
    #commands==beforeInspection+2,
    "No punctuation/command injection in safety inspection bot names")
currentTarget={name="Testwarrior",guid="Player-01",class="WARRIOR"}
importer.window:Hide()
print("NT1 Bot Talents: toolbar, preview, Safety Inspection, deliberate Apply and transport safety passed")
