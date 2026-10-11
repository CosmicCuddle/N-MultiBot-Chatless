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
function Frame:SetScript(k,fn) self.scripts[k]=fn end
function Frame:Show() self.visible=true end
function Frame:Hide() self.visible=false end
function Frame:CreateFontString() return setmetatable({scripts={}},Frame) end
function CreateFrame(kind,name,parent,template)
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
    #MultiBot.NT1WebsitePresets==40,
    "Use precisely the 40 verified converted website presets")
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
-- Website presets are an immutable class-specific snapshot. Warrior,
-- Warlock and Death Knight are excluded; original bot specs remain usable.
local counts={druid=9,hunter=8,mage=3,priest=7,rogue=6,shaman=7}
for class,count in pairs(counts) do
    assert(#again:ListWebsitePresets(class)==count,
        "Unexpected pinned website preset count for "..class)
end
assert(#again:ListWebsitePresets("warlock")==0)
assert(#again:ListWebsitePresets("warrior")==0)
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
local originalSpecsOpened=false
assert(again:OpenWebsitePresetsForBot("Zevon","Mage",function()
    originalSpecsOpened=true
end))
assert(again.page==3 and again.presetPage.visible and
    not again.importPage.visible and #commands==0)
click(again.presetFilterButtons.Raid)
assert(again.presetFilter=="Raid" and
    again.presetCounter.text:find("(1 builds)",1,true))
click(again.presetFilterButtons.Solo)
assert(again.presetFilter=="Solo" and
    again.presetCounter.text:find("(2 builds)",1,true))
click(again.presetFilterButtons.All)
assert(again.presetFilter=="All" and #commands==0)
assert(again.presetClass=="mage" and again.requestedBot=="Zevon")
click(again.presetRows[1])
assert(again.selectedPreset and again.selectedPreset.class=="mage")
assert(#commands==0,"Selecting preset must never send chat commands")
click(again.loadPresetButton)
assert(again.page==1 and again.input.text==preset[1].code)
assert(#commands==0,"Loading a website preset must never apply it")
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
click(again.loadPresetButton)
assert(again.page==1 and again.input.text==preset[1].code)
assert(not again:SendToTarget("apply",again.input.text))
assert(#commands==0,"A menu-selected but untargeted bot must never receive apply")
click(again.targetConfirm)
assert(again.status.text:find("Target Zevon",1,true) and
    again.boundTarget==nil)
target={name="Zevon",guid="Player-S",class="SHAMAN"}
click(again.targetConfirm)
assert(not again.boundTarget and
    again.status.text:find("mage",1,true),
    "Matching name but wrong roster class must never verify")
assert(#commands==0)
target={name="Zevon",guid="Player-Z",class="MAGE"}
click(again.targetConfirm)
assert(again.boundTarget and again.boundTarget.name=="Zevon")
assert(#commands==0,"Target confirmation is not an apply action")
assert(again:OpenWebsitePresetsForBot("Zevon","mage",function()
    originalSpecsOpened=true
end))
click(again.originalSpecButton)
assert(originalSpecsOpened and not again.window.visible,
    "Original bot specialization option must remain accessible")
assert(#commands==0)
-- Portable plain-text backup: bulk export, round-trip, collision confirmation,
-- format rejection and UI controls must remain entirely client-side.
local backup, backupErr=again:ExportSavedBuilds()
assert(backup and not backupErr and backup:find("^NMB1\n") and
    backup:find("Vanilla Fire",1,true))
local originalStore=_G.MultiBotNT1SavedBuilds
_G.MultiBotNT1SavedBuilds={}
assert(not again:ImportSavedBuilds("NMB1\nFake|not-a-build\n"))
assert(not again:ImportSavedBuilds("NMB1\nGood|NT1:vanilla:mage:3g-1\n" ..
    "Good|NT1:vanilla:mage:3g-2\n"))
assert(#again:ListSavedBuilds()==0,
    "Malformed import must never partially change saved data")
assert(again:ImportSavedBuilds(backup))
assert(#again:ListSavedBuilds()==10,"Restored expected 10 named builds")
assert(again:GetSavedCode("Vanilla Fire")==mage2)
assert(not again:ImportSavedBuilds("NMB1\nVanilla Fire|NT1:vanilla:mage:3g-1\n"))
assert(again:GetSavedCode("Vanilla Fire")==mage2,
    "Existing conflicting name must stay unchanged before confirmation")
assert(again:ImportSavedBuilds("NMB1\nVanilla Fire|NT1:vanilla:mage:3g-1\n",true))
assert(again:GetSavedCode("Vanilla Fire")==mage)
_G.MultiBotNT1SavedBuilds=originalStore
assert(again:Open())
click(again.savedButton)
click(again.backupButton)
assert(again.page==4 and again.backupPage.visible and again.backupText.multiline)
click(again.exportButton)
assert(again.backupText.text:find("^NMB1\n") and
    again.backupText.highlighted and #commands==0)
again.backupText:SetText("NMB1\nVanilla Fire|NT1:vanilla:mage:3g-1\n")
click(again.importButton)
assert(again.backupStatus.text:find("Confirm overwrite:",1,true) and
    again:GetSavedCode("Vanilla Fire")==mage2 and #commands==0)
click(again.importButton)
assert(again:GetSavedCode("Vanilla Fire")==mage and #commands==0)
click(again.backFromBackup)
assert(again.page==2 and again.savedPage.visible and #commands==0)
print("NT1 account-wide saved builds, website filters and backup/import: all checks passed")

