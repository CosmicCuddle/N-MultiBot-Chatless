-- Mock WoW 3.3.5a: persistent saved NT1 codes, page 1/page 2 and safety.
MultiBot = {}
_G.MultiBotNT1SavedBuilds = nil
UISpecialFrames = {}
local commands = {}
local target = {name="Zevon", class="MAGE", guid="Player-Z"}
local Frame = {}
Frame.__index = Frame
function Frame:SetWidth(v) self.width=v end
function Frame:SetHeight(v) self.height=v end
function Frame:SetSize(w,h) self.width=w self.height=h end
function Frame:SetPoint(...) self.position={...} end
function Frame:SetText(v) self.text=v end
function Frame:GetText() return self.text end
function Frame:SetJustifyH(v) self.justify=v end
function Frame:SetTextColor(...) self.color={...} end
function Frame:SetFontObject(v) self.font=v end
function Frame:SetAutoFocus() end
function Frame:SetMaxLetters(v) self.maxLetters=v end
function Frame:SetMultiLine(v) self.multiline=v end
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
function Frame:SetScript(k,fn) self.scripts[k]=fn end
function Frame:Show() self.visible=true end
function Frame:Hide() self.visible=false end
function Frame:CreateFontString() return setmetatable({scripts={}},Frame) end
function CreateFrame(kind,name,parent,template)
    assert(template~="UIPanelScrollFrameTemplate" or
        (type(name)=="string" and name~=""),
        "WoW 3.3.5a scroll-frame OnLoad requires a named template")
    local f=setmetatable({kind=kind,name=name,parent=parent,template=template,scripts={}},Frame)
    if name then _G[name]=f end
    return f
end
local function click(b) assert(b and b.scripts.OnClick); b.scripts.OnClick(b) end
UIParent=CreateFrame("Frame","UIParent")
StaticPopupDialogs = {}
local confirmations = {}
function StaticPopup_Show(key,display)
    confirmations[#confirmations+1]={key=key,text=display}
    return confirmations[#confirmations]
end
function Frame:IsShown() return self.visible end
UIErrorsFrame={AddMessage=function() end}
function UnitExists(w) return w=="target" and target ~= nil end
function UnitIsPlayer(w) return w=="target" and target ~= nil end
function UnitIsUnit(w,o) return w=="target" and o=="player" and target and target.name=="Currentplayer" end
function UnitName(w) return w=="target" and target and target.name end
function UnitGUID(w) return w=="target" and target and target.guid end
function UnitClass(w)
    local token = target and target.class or "MAGE"
    return token, token
end
function SendChatMessage(s,channel)
    assert(channel=="SAY")
    commands[#commands+1]=s
end
dofile("Data/NT1WebsitePresets.lua")
assert(type(MultiBot.NT1WebsitePresets)=="table" and
    #MultiBot.NT1WebsitePresets==47,
    "Retain 40 pinned website presets plus 7 owner-supplied Warrior builds")
dofile("UI/MultiBotNT1TalentsUI.lua")
local api=assert(MultiBot.NT1Talents)
local mage="NT1:vanilla:mage:3g-1"
local mage2="NT1:vanilla:mage:3g-2"
local shaman="NT1:vanilla:shaman:3g-1"
assert(#api:ListSavedBuilds()==0 and api:GetSavedCode("anything")==nil,
    "New account should have no saved builds")
assert(not api:SaveBuild("",mage))
assert(not api:SaveBuild("Broken","junk"))
assert(not api:SaveBuild("Name\nInjected",mage))
assert(not api:SaveBuild(string.rep("x",41),mage))
assert(api:SaveBuild("  Vanilla Fire  ",mage))
assert(type(_G.MultiBotNT1SavedBuilds)=="table" and
    _G.MultiBotNT1SavedBuilds["Vanilla Fire"]==mage)
assert(api:SaveBuild("vAnIlLa fIrE",mage) and #api:ListSavedBuilds()==1,
    "Case variants should not duplicate a saved name")
assert(not api:SaveBuild("vanilla fire",mage2),
    "An existing name cannot be silently overwritten")
assert(api:GetSavedCode("VANILLA FIRE")==mage)
assert(api:SaveBuild("vanilla fire",mage2,true))
assert(api:GetSavedCode("Vanilla Fire")==mage2)
assert(api:SaveBuild("Restoration Test",shaman),
    "Other classes can be stored without selecting one as target")
local names=api:ListSavedBuilds()
assert(#names==2 and names[1].name=="Restoration Test" and
    names[2].name=="Vanilla Fire",
    "Saved names sorted without changing original case")
assert(names[1].class=="shaman" and names[2].era=="vanilla")
assert(api:Open())
assert(api.page==1 and api.importPage.visible and not api.savedPage.visible)
assert(api.window.height==465 and api.window.width==660)
assert(api.nameBox.maxLetters==40 and api.input.maxLetters==2048)
assert(#commands==0)
api.input:SetText(mage)
api.nameBox:SetText("PvE Mage")
click(api.saveButton)
assert(api:GetSavedCode("PvE Mage")==mage and #commands==0,
    "Saving must never send a server command")
api.input:SetText(mage2)
click(api.saveButton)
assert(api:GetSavedCode("PvE Mage")==mage and
    api.status.text:find("Save again",1,true),
    "Overwrite requires confirmation")
click(api.saveButton)
assert(api:GetSavedCode("PvE Mage")==mage2 and #commands==0)
-- The saved page must not apply codes merely when opened or selected.
click(api.savedButton)
assert(api.page==2 and api.savedPage.visible and not api.importPage.visible)
assert(#api:ListSavedBuilds()==3 and #commands==0)
click(api.savedRows[1])
assert(api.selectedName=="PvE Mage" and #commands==0)
-- A different class can still be loaded for editing, but the apply path
-- retains the target-class preflight and may never bypass server validation.
click(api.loadButton)
assert(api.page==1 and api.input.text==mage2 and api.nameBox.text=="PvE Mage")
assert(#commands==0)
click(api.savedButton)
click(api.savedRows[2]) -- Restoration Test (shaman)
click(api.loadButton)
assert(api.input.text==shaman and #commands==0)
assert(api.status.text:find("Cannot apply",1,true))
assert(not api:SendToTarget("apply",api.input.text) and #commands==0)
-- A selected named build is deleted only by two separate clicks.
click(api.savedButton)
click(api.savedRows[1]) -- PvE Mage
click(api.deleteButton)
assert(api:GetSavedCode("PvE Mage") and #commands==0)
click(api.deleteButton)
assert(api:GetSavedCode("PvE Mage")==nil and #commands==0)
-- Multiple pages (5 entries per page) and safe page navigation.
for i=1,9 do
    assert(api:SaveBuild("Test "..i,mage))
end
api.savedPageIndex=1
api:UpdateSavedPage()
assert(api.savedPageCounter.text:find("/ 3",1,true),
    "11 saved builds need 3 pages, 5 per page")
click(api.nextSavedPage)
assert(api.savedPageIndex==2)
click(api.nextSavedPage)
assert(api.savedPageIndex==3)
click(api.nextSavedPage)
assert(api.savedPageIndex==3)
click(api.previousSavedPage)
assert(api.savedPageIndex==2)
assert(#commands==0,"Page 2 browsing must never submit commands")
-- Simulate Lua UI reinitialization after reload; the account-wide store
-- persists as a separate SavedVariables global.
local store=_G.MultiBotNT1SavedBuilds
MultiBot.NT1Talents=nil
dofile("UI/MultiBotNT1TalentsUI.lua")
local again=assert(MultiBot.NT1Talents)
assert(_G.MultiBotNT1SavedBuilds==store and #again:ListSavedBuilds()==11,
    "Simulated reload must keep named codes without migrating settings")
assert(again:GetSavedCode("Restoration Test")==shaman)
assert(not again:DeleteBuild("missing"))
assert(again:DeleteBuild("RESTORATION TEST"))
assert(again:GetSavedCode("Restoration Test")==nil)
assert(#commands==0)
-- Website presets: 40 originally pinned, 7 newly approved Warrior builds.
-- Warlock and Death Knight stay excluded; legacy bot specs stay available.
local counts={druid=9,hunter=8,mage=3,priest=7,rogue=6,shaman=7,warrior=7}
for class,count in pairs(counts) do
    assert(#again:ListWebsitePresets(class)==count,
        "Unexpected pinned website preset count for "..class)
end
assert(#again:ListWebsitePresets("warlock")==0)
assert(#again:ListWebsitePresets("WARRIOR")==7)
assert(#again:ListWebsitePresets("deathknight")==0)
assert(#again:ListWebsitePresets("paladin")==0)
-- Death Knight is explicitly excluded, not merely absent from this snapshot.
-- Future accidental DK entries must never appear in the website preset UI.
local originalPresetCount=#MultiBot.NT1WebsitePresets
table.insert(MultiBot.NT1WebsitePresets,{
    class="deathknight",category="Raid",name="Excluded DK Test",
    role="Tank",variant=1,code="NT1:wotlk:deathknight:3g-1"
})
assert(#again:ListWebsitePresets("Death Knight")==0)
assert(#again:ListWebsitePresets("DEATHKNIGHT")==0)
assert(not again:OpenWebsitePresetsForBot(
    "ExampleDK","Death Knight",function() end))
assert(#commands==0)
table.remove(MultiBot.NT1WebsitePresets)
assert(#MultiBot.NT1WebsitePresets==originalPresetCount)
-- Compare the exact seven approved calculator links; do not drift their codes.
local expectedWarrior = {
    {category="Solo",name="Protection Warrior",role="Tank",variant=1,code="NT1:vanilla:warrior:3d-3.3g-1.3j-3.3k-2.3m-5.3u-5.3x-3.40-3.42-1.43-2.44-1.45-2.48-1.49-1.ie-2.ji-5.18h-5.19y-2.1qi-3.2bc-1"},
    {category="Solo",name="Fury Warrior",role="DPS",variant=1,code="NT1:vanilla:warrior:3d-3.3i-2.3j-3.3m-5.4a-2.4b-5.4c-5.4d-5.4f-4.4g-1.4l-1.4n-1.ie-2.17x-5.1a1-3.1qi-3.2bc-1"},
    {category="Solo",name="Arms Warrior",role="DPS",variant=1,code="NT1:vanilla:warrior:3d-3.3i-2.3j-3.3k-3.3m-3.3n-2.3o-5.3p-1.3r-1.3s-3.3t-1.4a-1.4b-2.4d-5.4h-3.4m-3.ie-2.1fn-1.1q0-3.1qi-3.2bc-1"},
    {category="Raid",name="Protection Warrior",role="Tank",variant=1,code="NT1:vanilla:warrior:3g-1.3m-5.3u-5.3w-5.3x-3.40-3.42-1.43-2.44-1.45-2.48-1.49-1.4d-5.4f-1.ji-5.18h-5.19y-2.1qi-3"},
    {category="Raid",name="Fury - Rend Flurry",role="DPS",variant=1,code="NT1:vanilla:warrior:3d-3.3g-1.3j-3.3k-3.3m-2.4a-5.4c-5.4d-5.4f-3.4l-1.4n-1.ht-1.ie-2.16t-2.16u-2.17x-5.1a1-3.1qi-3.2bc-1"},
    {category="Raid",name="Fury - Anger Management",role="DPS",variant=2,code="NT1:vanilla:warrior:3d-3.3g-1.3j-3.3k-3.3m-2.3t-1.4a-5.4c-5.4d-5.4f-3.4l-1.4n-1.ht-1.ie-2.16t-2.16u-2.17x-5.1a1-3.1qi-3"},
    {category="Raid",name="Arms Warrior",role="DPS",variant=1,code="NT1:vanilla:warrior:3d-3.3g-1.3j-3.3k-3.3m-1.3n-2.3o-5.3p-1.3q-1.3r-1.3s-3.3t-1.4d-5.4h-5.4m-2.ht-2.ie-2.16u-1.1fn-2.1q0-3.1qi-3.2bc-1"},
}
local warrior=again:ListWebsitePresets("warrior")
assert(#warrior==#expectedWarrior)
local warriorSeen={}
for _,expected in ipairs(expectedWarrior) do
    local matched=false
    for _,actual in ipairs(warrior) do
        if actual.category==expected.category and
            actual.name==expected.name and actual.role==expected.role and
            actual.variant==expected.variant and actual.code==expected.code then
            matched=true
        end
    end
    assert(matched,"Missing or changed approved Warrior code: "..expected.name)
    local points, ids, entries=0,{},0
    for pair in (expected.code:match("^NT1:vanilla:warrior:(.+)$").."."):gmatch("(.-)%.") do
        local id,rank=pair:match("^([0-9a-z]+)%-([1-5])$")
        assert(id and rank and not ids[id])
        ids[id]=true
        points=points+tonumber(rank)
        entries=entries+1
    end
    assert(points==51 and entries>=1,"Warrior level-60 build must spend 51 points")
    warriorSeen[expected.category]=(warriorSeen[expected.category] or 0)+1
end
assert(warriorSeen.Raid==4 and warriorSeen.Solo==3)
-- Every bundled preset must remain valid and fit the existing transport.
for _,entry in ipairs(MultiBot.NT1WebsitePresets) do
    assert(again:ValidateCode(entry.code,entry.class))
    assert(#(".naxxbot talents preview Examplebot "..entry.code)<=255,
        "Bundled website code cannot fit the supported SAY transport")
end
assert(#again:ListFilteredWebsitePresets("mage")==3)
again.presetFilter="Raid"
assert(#again:ListFilteredWebsitePresets("mage")==1)
again.presetFilter="Solo"
assert(#again:ListFilteredWebsitePresets("mage")==2)
again.presetFilter="All"
local preset=again:ListWebsitePresets("mage")
assert(#preset==3 and preset[1].code:match("^NT1:vanilla:mage:"))
again.presetFilter="Raid"
assert(#again:ListFilteredWebsitePresets("warrior")==4)
again.presetFilter="Solo"
assert(#again:ListFilteredWebsitePresets("warrior")==3)
again.presetFilter="All"
local originalSpecsOpened=false
assert(again:OpenWebsitePresetsForBot("Zevon","Mage",function()
    originalSpecsOpened=true
end))
assert(again.page==3 and again.presetPage.visible and
    not again.importPage.visible and #commands==0)
assert(again.presetStatus.text=="Loading never applies talents.",
    "Preset help must be short at enlarged UI font scale")
assert(not again.loadPresetButton,
    "Website preset rows should load directly without a redundant button")
click(again.presetFilterButtons.Raid)
assert(again.presetFilter=="Raid" and
    again.presetCounter.text:find("(1 builds)",1,true))
click(again.presetFilterButtons.Solo)
assert(again.presetFilter=="Solo" and
    again.presetCounter.text:find("(2 builds)",1,true))
click(again.presetFilterButtons.All)
assert(again.presetFilter=="All" and #commands==0)
assert(again.presetClass=="mage" and again.requestedBot=="Zevon")
assert(again.applyButton.attributes.type1=="macro" and
    again.applyButton.attributes.macrotext1=="/targetexact Zevon",
    "Auto-target macro must be configured for the roster bot")
assert(not again:LoadWebsitePreset(nil) and again.page==3,
    "Missing preset must not leave the browser")
assert(not again:LoadWebsitePreset({
    class="warrior",code="NT1:vanilla:warrior:3g-1",name="Wrong Class",
    category="Raid"
}) and again.page==3,"Wrong-class preset must not load")
click(again.presetRows[1])
assert(again.selectedPreset and again.selectedPreset.class=="mage")
assert(again.page==1 and again.importPage.visible and
    not again.presetPage.visible and again.input.text==preset[1].code,
    "One click must load the Mage preset directly into Import")
assert(again.nameBox.text:find(preset[1].name,1,true))
assert(#commands==0,"Clicking a preset never sends Preview or Apply")
assert(again.boundTarget and again.boundTarget.name=="Zevon",
    "Matching selected target may be safely bound for later review")
-- Bot menu may be used without that bot targeted. In that case, loading is
-- still allowed, but Confirm target is required before Preview/Apply.
target={name="Differentmage",guid="Player-O",class="MAGE"}
assert(again:OpenWebsitePresetsForBot("Zevon","mage",function()
    originalSpecsOpened=true
end))
assert(again.boundTarget==nil and again.page==3)
click(again.presetRows[1])
assert(again.page==1 and again.input.text==preset[1].code and #commands==0,
    "Untargeted bot's website preset must load locally in one click")
assert(not again:SendToTarget("apply",again.input.text))
assert(#commands==0,"A menu-selected but untargeted bot must never receive apply")
click(again.targetConfirm)
assert(again.status.text:find("Target Zevon",1,true) and
    again.boundTarget==nil)
-- Apply should guide toward the roster bot without dispatching commands
-- or showing a red UI error. The target event may bind but never Apply.
click(again.applyButton)
assert(again.applyButton.lastSecureTarget=="Zevon" and
    again.awaitingTarget and #commands==0 and
    again.status.text:find("Target Zevon",1,true),
    "Failed /targetexact must fall back to guidance, never Apply")
-- When the bot is actually nearby, the *secure* hardware click switches
-- the target before the callback checks identity or opens a confirmation.
again.applyButton.simulateSecureClick=function(_,name)
    if name=="Zevon" then
        target={name="Zevon",guid="Player-Z",class="MAGE"}
    end
end
click(again.applyButton)
assert(not again.awaitingTarget and again.boundTarget and
    again.boundTarget.name=="Zevon" and again.pendingApply and
    #commands==0, "Secure target + Apply requires separate confirmation")
StaticPopupDialogs.MULTIBOT_NT1_APPLY_CONFIRM.OnCancel()
assert(not again.pendingApply)
again.applyButton.simulateSecureClick=nil
target={name="Differentmage",guid="Player-O",class="MAGE"}
click(again.applyButton)
assert(again.awaitingTarget and not again.pendingApply and #commands==0)
assert(again.window.registeredEvents.PLAYER_TARGET_CHANGED and
    again.window.registeredEvents.PLAYER_REGEN_ENABLED)
assert(not again.pendingApply)
target={name="Zevon",guid="Player-S",class="SHAMAN"}
again.window.scripts.OnEvent(again.window,"PLAYER_TARGET_CHANGED")
assert(again.boundTarget and again.boundTarget.guid=="Player-Z" and
    #commands==0 and not again.pendingApply and
    again.status.text:find("MAGE",1,true),
    "Wrong-class target must not replace a previously verified bot GUID")
-- A protected macro cannot justify accepting a wrong class/GUID.
again.applyButton.simulateSecureClick=function()
    target={name="Zevon",guid="Player-S",class="SHAMAN"}
end
click(again.applyButton)
assert(not again.pendingApply and #commands==0,
    "Secure name target with wrong class must never prompt Apply")
again.applyButton.simulateSecureClick=nil
assert(#commands==0)
target={name="Zevon",guid="Player-Z",class="MAGE"}
again.window.scripts.OnEvent(again.window,"PLAYER_TARGET_CHANGED")
assert(again.boundTarget and again.boundTarget.name=="Zevon")
assert(again.status.text:find("Target verified",1,true))
assert(#commands==0,"Target event verifies but never applies")
assert(not again.awaitingTarget and not again.pendingApply)
click(again.applyButton)
assert(again.pendingApply and #commands==0)
StaticPopupDialogs.MULTIBOT_NT1_APPLY_CONFIRM.OnCancel()
assert(not again.pendingApply and #commands==0,
    "Cancelling Apply confirmation must not dispatch")
-- Changing target while the second confirmation is open aborts it.
click(again.applyButton)
assert(again.pendingApply and #commands==0)
local staleAccept=StaticPopupDialogs.MULTIBOT_NT1_APPLY_CONFIRM.OnAccept
target={name="Differentmage",guid="Player-Other",class="MAGE"}
again.window.scripts.OnEvent(again.window,"PLAYER_TARGET_CHANGED")
assert(not again.pendingApply and #commands==0,
    "Target changes must invalidate an outstanding confirmation")
staleAccept()
assert(#commands==0,"Stale Apply dialog may never dispatch")
target={name="Zevon",guid="Player-Z",class="MAGE"}
assert(again:OpenWebsitePresetsForBot("Zevon","mage",function()
    originalSpecsOpened=true
end))
click(again.originalSpecButton)
assert(originalSpecsOpened and not again.window.visible,
    "Original bot specialization option must remain accessible")
assert(#commands==0)
-- Warrior now has seven website choices, five per page, without any auto-apply.
local warriorSpecsOpened=false
target={name="Valiant",guid="Player-W",class="WARRIOR"}
assert(again:OpenWebsitePresetsForBot("Valiant","Warrior",function()
    warriorSpecsOpened=true
end))
assert(again.applyButton.attributes.macrotext1=="/targetexact Valiant",
    "Opening another roster bot must refresh the secure target name")
assert(again.page==3 and again.presetClass=="warrior" and
    again.presetCounter.text:find("Page 1 / 2",1,true) and
    again.presetCounter.text:find("(7 builds)",1,true) and #commands==0)
click(again.nextPresetPage)
assert(again.presetPageIndex==2 and again.presetCounter.text:find("Page 2 / 2",1,true))
click(again.presetFilterButtons.Raid)
assert(again.presetPageIndex==1 and
    again.presetCounter.text:find("(4 builds)",1,true))
click(again.presetFilterButtons.Solo)
assert(again.presetCounter.text:find("(3 builds)",1,true))
local selectedWarrior=again:ListFilteredWebsitePresets("warrior")[1].code
click(again.presetRows[1])
assert(again.selectedPreset and again.selectedPreset.class=="warrior")
assert(again.page==1 and again.input.text==selectedWarrior and
    not again.presetPage.visible and #commands==0,
    "Clicking a Solo Warrior preset must load immediately without Apply")
assert(again:DescribeCode(again.input.text).role=="DPS" or
    again:DescribeCode(again.input.text).role=="Tank",
    "Chosen website role must be retained for local build summary")
assert(again:OpenWebsitePresetsForBot("Valiant","Warrior",function()
    warriorSpecsOpened=true
end))
click(again.originalSpecButton)
assert(warriorSpecsOpened and not again.window.visible and #commands==0,
    "Warrior must keep the original Playerbots Bot specs action")
target={name="Zevon",guid="Player-Z",class="MAGE"}
-- Portable plain-text backup: bulk export, round-trip, collision confirmation,
-- format rejection and UI controls must remain entirely client-side.
local backup, backupErr=again:ExportSavedBuilds()
assert(backup and not backupErr and backup:find("^NMB1\n") and
    backup:find("Vanilla Fire",1,true) and
    backup:find("END|10",1,true))
local originalStore=_G.MultiBotNT1SavedBuilds
_G.MultiBotNT1SavedBuilds={}
assert(not again:ImportSavedBuilds("NMB1\nFake|not-a-build\nEND|1\n"))
assert(not again:ImportSavedBuilds(
    "NMB1\nValid|NT1:vanilla:mage:3g-1\n"))
assert(not again:ImportSavedBuilds(
    "NMB1\nValid|NT1:vanilla:mage:3g-1\nEND|2\n"))
assert(not again:ImportSavedBuilds("NMB1\nGood|NT1:vanilla:mage:3g-1\n" ..
    "Good|NT1:vanilla:mage:3g-2\nEND|2\n"))
assert(#again:ListSavedBuilds()==0,
    "Malformed import must never partially change saved data")
assert(again:ImportSavedBuilds(backup))
assert(#again:ListSavedBuilds()==10,"Restored expected 10 named builds")
assert(again:GetSavedCode("Vanilla Fire")==mage2)
assert(not again:ImportSavedBuilds("NMB1\nVanilla Fire|NT1:vanilla:mage:3g-1\nEND|1\n"))
assert(again:GetSavedCode("Vanilla Fire")==mage2,
    "Existing conflicting name must stay unchanged before confirmation")
assert(again:ImportSavedBuilds("NMB1\nVanilla Fire|NT1:vanilla:mage:3g-1\nEND|1\n",true))
assert(again:GetSavedCode("Vanilla Fire")==mage)
_G.MultiBotNT1SavedBuilds=originalStore
assert(again:Open())
click(again.savedButton)
click(again.backupButton)
assert(again.page==4 and again.backupPage.visible and again.backupText.multiline)
assert(_G.MultiBotNT1BackupScrollFrame and
    _G.MultiBotNT1BackupScrollFrame.scrollChild==again.backupText,
    "Backup page requires named 3.3.5a-compatible scroll frame")
click(again.exportButton)
assert(again.backupText.text:find("^NMB1\n") and
    again.backupText.highlighted and #commands==0)
again.backupText:SetText("NMB1\nVanilla Fire|NT1:vanilla:mage:3g-1\nEND|1\n")
click(again.importButton)
assert(again.backupStatus.text:find("Confirm overwrite:",1,true) and
    again:GetSavedCode("Vanilla Fire")==mage2 and #commands==0)
click(again.importButton)
assert(again:GetSavedCode("Vanilla Fire")==mage and #commands==0)
click(again.backFromBackup)
assert(again.page==2 and again.savedPage.visible and #commands==0)
print("NT1 account-wide saved builds, website filters and backup/import: all checks passed")

