-- Regression: clicking the legacy bot Talent/Spellbook controls must tolerate
-- stale roster entries and unit bars without those controls (e.g. SelfBot).
-- This exercises MultiBot.addEvery's real click callbacks, not a regex mock.
StaticPopupDialogs = {}
ACCEPT, CANCEL = "OK", "Cancel"
local sent, inspected = {}, {}
local function fakeFrame(botName)
    local frame = {buttons={},frames={}}
    frame.getName = function() return botName end
    frame.getClass = function() return "WARRIOR" end
    frame.Hide = function() frame.hidden = true end
    frame.Show = function() frame.hidden = false end
    frame.addFrame = function(id)
        local child = fakeFrame(botName)
        frame.frames[id] = child
        return child
    end
    frame.addButton = function(id)
        local b = {name=id,state=false,disableCount=0}
        b.getName = function() return botName end
        b.getClass = function() return "WARRIOR" end
        b.setDisable = function()
            b.state=false
            b.disableCount=b.disableCount+1
            return b
        end
        b.setEnable = function()
            b.state=true
            return b
        end
        b.doHide = function() b.hidden=true; return b end
        b.doShow = function() b.hidden=false; return b end
        b.icon = {
            SetTexture=function() end,
            SetDesaturated=function() end,
            SetVertexColor=function() end,
        }
        frame.buttons[id]=b
        return b
    end
    frame.getButton = function(id) return frame.buttons[id] end
    return frame
end

local units = {buttons={},frames={}}
MultiBot = {
    L=function(key,fallback) return fallback or key end,
    SafeTexturePath=function(path) return path end,
    hasStrategy=function() return false end,
    IsFavorite=function() return false end,
    RefreshEveryGroupActionFrame=function() end,
    toUnit=function(name) return name end,
    frames={MultiBar={frames={Units=units}}},
    index={actives={"Clicked","NoFrame","NoTalent","NoRosterButton","Player","Validbot"}},
    allowLegacyChatFallback=false,
    bridge={connected=false},
    auto={},
    talent={Hide=function() end,doClear=function() end},
    spellbook={Hide=function() end},
}
function UnitName(unit) return unit=="player" and "Player" or unit end
function UnitLevel() return 60 end
function CheckInteractDistance() return true end
function InspectUnit(name) inspected[#inspected+1]=name end
function SendChatMessage(...) sent[#sent+1]={...} end
dofile("Core/MultiBotEvery.lua")

local clicked = fakeFrame("Clicked")
units.buttons.Clicked={name="Clicked",waitFor=""}
units.frames.Clicked=clicked
units.buttons.NoFrame={name="NoFrame"}
local noTalent=fakeFrame("NoTalent")
units.frames.NoTalent=noTalent
units.buttons.NoTalent={name="NoTalent"}
units.frames.NoRosterButton=fakeFrame("NoRosterButton")
units.buttons.Player={name="Player"}
units.frames.Player=fakeFrame("Player")

local valid=fakeFrame("Validbot")
local validTalent=valid.addButton("Talent")
local validSpellbook=valid.addButton("Spellbook")
units.frames.Validbot=valid
units.buttons.Validbot={name="Validbot"}

MultiBot.addEvery(clicked,{}, {})
local talent=assert(clicked.buttons.Talent)
assert(type(talent.doLeft)=="function")
-- NoFrame has a roster button but no matching frame.
-- NoTalent has a frame but no Talent button.
-- NoRosterButton has a frame but no corresponding roster button.
-- Player has no Talent button because SelfBot bars are shorter.
talent.doLeft(talent)
assert(#inspected==1 and inspected[1]=="Clicked",
    "Talent inspection should continue despite stale roster bars")
assert(validTalent.disableCount==1,
    "Present other bot Talent controls should still be disabled")
assert(talent.state==true and #sent==0,
    "Talent inspection must not dispatch any server command")
talent.doLeft(talent)
assert(talent.state==false and #inspected==1,
    "Second click must still close the original talent UI")

local spellbook=assert(clicked.buttons.Spellbook)
spellbook.doLeft(spellbook)
assert(validSpellbook.disableCount==1 and
    MultiBot.spellbook.name=="Clicked" and #sent==0,
    "Spellbook must tolerate the same stale/missing roster controls")

-- Both legacy tool callbacks must tolerate a roster that vanishes
-- between opening the per-bot control bar and clicking the tool icon.
talent.setDisable()
MultiBot.frames.MultiBar.frames.Units=nil
talent.doLeft(talent)
assert(#inspected==2 and #sent==0,
    "Absent roster frame must not crash legacy Talent inspection")
spellbook.setDisable()
spellbook.doLeft(spellbook)
assert(spellbook.state==true and #sent==0,
    "Absent roster must not crash unconnected Spellbook inspection")
-- The bridge-connected path must not index the absent roster either.
spellbook.setDisable()
MultiBot.bridge.connected=true
MultiBot.Comm={RequestSpellbook=function(name) return name=="Clicked" end}
spellbook.doLeft(spellbook)
assert(spellbook.state==true and #sent==0,
    "A successful bridge Spellbook request must tolerate absent roster state")
MultiBot.bridge.connected=false
MultiBot.Comm=nil
MultiBot.allowLegacyChatFallback=true
spellbook.setDisable()
spellbook.doLeft(spellbook)
assert(#sent==1 and sent[1][1]=="spells" and sent[1][2]=="WHISPER" and
    sent[1][4]=="Clicked",
    "Legacy fallback must still send its original whisper without a roster")
print("Legacy bot Talent/Spellbook stale-roster regression passed")
