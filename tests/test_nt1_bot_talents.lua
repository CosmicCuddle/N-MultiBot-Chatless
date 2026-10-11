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
function Frame:SetScript(event, callback) self.scripts[event]=callback end
function Frame:Show() self.visible=true end
function Frame:Hide() self.visible=false end
function Frame:IsShown() return self.visible end
function Frame:CreateFontString()
    return setmetatable({scripts={}},Frame)
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
function UnitClass(unit) return unit=="target" and "Warrior","WARRIOR" end
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
    importer.status.position[5] == -203 and
    importer.targetLabel.position[5] == -68,
    "NT1 fields must have independent rows without label overlap")
assert(created[1].icon == "INV_Misc_Book_07",
    "Use the standard book icon rather than the invisible custom Talent.blp")
assert(importer.targetLabel.text:find("Testwarrior",1,true))
assert(#UISpecialFrames==1 and UISpecialFrames[1]=="MultiBotNT1TalentsWindow")
assert(#commands==0,"Opening the paste dialog must never send an apply")

local code="NT1:vanilla:warrior:3g-1"
importer.input:SetText(code)
local ok=importer:SendToTarget("preview",importer.input:GetText())
assert(ok and #commands==1 and commands[1]==
    ".naxxbot talents preview Testwarrior "..code,
    "Preview should send the exact read-only Naxxramas Core command")
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
assert(#commands==2 and activeConfirmation and
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
assert(#UISpecialFrames==1,"ESC registration must never duplicate")
importer.input.scripts.OnEscapePressed(importer.input)
assert(not popup.visible and not importer.input.focused,
    "Escape should cancel the window without sending commands")
assert(#commands==3)

print("NT1 Bot Talents: toolbar, preview, deliberate Apply and transport safety passed")
