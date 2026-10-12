-- Naxxramas NT1 Playerbot talent importer for WoW 3.3.5a.
-- Client-side paste/preview/apply interface for the separately maintained
-- Naxxramas Core command. The server remains authoritative for all changes.
-- No changes to mod-playerbots or the MultiBot bridge are required.
if not MultiBot then return end

local Talents = MultiBot.NT1Talents or {}
MultiBot.NT1Talents = Talents

local MAX_COMMAND_LENGTH = 255 -- WoW 3.3.5a chat transport limit; fail closed.
local MAX_CODE_LENGTH = 2048 -- Naxxramas Core parser limit.
local EXAMPLE = "NT1:vanilla:warrior:3g-1"
local CLASSES = {
    warrior=true, paladin=true, hunter=true, rogue=true, priest=true,
    deathknight=true, shaman=true, mage=true, warlock=true, druid=true,
}
local ERAS = {vanilla=true, tbc=true, wotlk=true}
local WINDOW_NAME = "MultiBotNT1TalentsWindow"

local function trim(value)
    return type(value) == "string" and
        value:match("^%s*(.-)%s*$") or ""
end

local function message(value, isError)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage("NT1 Talents: " .. value,
            isError and 1 or 0.35, isError and 0.3 or 1, 0.3, 1)
    end
end

-- A lightweight syntax check only. The server enforces real bot ownership,
-- talent IDs, class/era levels, prerequisites and available points.
function Talents:ValidateCode(text, botClass)
    local code = trim(text)
    if code == "" then
        return nil, "Paste an NT1 talent code first."
    end
    if #code > MAX_CODE_LENGTH then
        return nil, "This NT1 code exceeds the server's 2048-character limit."
    end
    local era, class, body = code:match("^NT1:([a-z]+):([a-z]+):(.*)$")
    if not era or not ERAS[era] or not CLASSES[class] then
        return nil, "Expected NT1:era:class:talent-ranks (example below)."
    end
    if botClass and CLASSES[botClass] and class ~= botClass then
        return nil, "Code is for " .. class .. ", but the selected bot is " .. botClass .. "."
    end
    if body == "" then
        return nil, "The code has no selected talents. Empty builds are not applied."
    end
    local count, seen = 0, {}
    for part in (body .. "."):gmatch("(.-)%.") do
        count = count + 1
        if count > 120 then return nil, "The code has too many talent entries." end
        local id, rank = part:match("^([0-9a-z]+)%-([1-5])$")
        if not id or not rank or seen[id] then
            return nil, "Invalid or duplicate talent entry in NT1 code."
        end
        seen[id] = true
    end
    return code, nil
end

local function getTarget()
    if not UnitExists or not UnitExists("target") or
        not UnitIsPlayer or not UnitIsPlayer("target") or
        (UnitIsUnit and UnitIsUnit("target", "player")) then
        return nil, "Target the Playerbot whose talents you want to set."
    end
    local name = UnitName and UnitName("target")
    if type(name) ~= "string" or name == "" or name:find("[%s%c]") then
        return nil, "The selected bot has no usable character name."
    end
    local classToken
    if type(UnitClass) == "function" then
        local _, token = UnitClass("target")
        classToken = token
    end
    local class = type(classToken) == "string" and
        classToken:lower():gsub("[^a-z]", "") or nil
    local guid = UnitGUID and UnitGUID("target") or nil
    return {name=name, class=class, guid=guid}, nil
end

-- Shared, read-only preflight; used for Preview and the Apply confirmation.
-- Never trust a stored popup command or the original target alone.
function Talents:PrepareCommand(action, text)
    if action ~= "apply" and action ~= "preview" then
        return nil, "Unknown talent action."
    end
    local target, reason = getTarget()
    if not target then return nil, reason end
    if not CLASSES[target.class] then
        return nil, "Cannot identify targeted bot class. No command sent."
    end
    if not self.boundTarget or target.name ~= self.boundTarget.name or
        (self.boundTarget.guid and target.guid ~= self.boundTarget.guid) then
        return nil, "Target changed. Reopen Talents for the correct bot."
    end
    -- A matching name/GUID is insufficient when class identity is
    -- inconsistent: never redirect an old confirmation to another class.
    if self.boundTarget.class and target.class ~= self.boundTarget.class then
        return nil, "Target class changed. Reopen Talents for the correct bot."
    end
    local code, invalid = self:ValidateCode(text, target.class)
    if not code then return nil, invalid end
    local command = ".naxxbot talents " .. action .. " " .. target.name .. " " .. code
    if #command > MAX_COMMAND_LENGTH then
        return nil, "Code is too long for one 3.3.5a chat command. No command sent."
    end
    return {command=command, code=code, target=target}
end

function Talents:SendToTarget(action, text)
    local plan, reason = self:PrepareCommand(action, text)
    if not plan then return false, reason end
    -- Intentional GM/server command path, never a generic executor.
    SendChatMessage(plan.command, "SAY")
    return true, action == "preview" and
        ("Preview request sent for " .. plan.target.name ..
            ". Server Preview does not mean Apply-ready.") or
        ("Apply request dispatched for " .. plan.target.name ..
            ". Check server chat for success or rejection.")
end

function Talents:DescribeCode(text)
    local code, reason = self:ValidateCode(text)
    if not code then return nil, reason end
    local era, class, entries = code:match("^NT1:([a-z]+):([a-z]+):(.*)$")
    local points = 0
    for entry in (entries .. "."):gmatch("(.-)%.") do
        points = points + tonumber(entry:match("%-([1-5])$"))
    end
    local role = "not specified"
    if self.selectedPreset and self.selectedPreset.code == code then
        role = self.selectedPreset.role or role
    end
    return {code=code, era=era, class=class, points=points, role=role}
end

local APPLY_CONFIRM_KEY = "MULTIBOT_NT1_APPLY_CONFIRM"

-- Roster website presets can open without selecting the corresponding unit.
-- This is only guidance and secure target binding; no command is ever sent.
function Talents:CheckIntendedTarget(action)
    local expectedName=self.requestedBot or
        (self.boundTarget and self.boundTarget.name)
    if not expectedName or expectedName=="" then
        return false, "Reopen Set Talents for the correct bot.", false
    end
    local current=getTarget()
    if not current or string.lower(current.name)~=
        string.lower(expectedName) then
        self.awaitingTarget=true
        self.awaitingAction=action or "apply"
        return false, "Target " .. expectedName .. ", then click " ..
            (self.awaitingAction=="preview" and "Preview." or
                "Apply."), true
    end
    if not CLASSES[current.class] or
        (self.presetClass and current.class~=self.presetClass) then
        self.awaitingTarget=true
        self.awaitingAction=action or "apply"
        return false, "Target " .. expectedName .. " (" ..
            string.upper(self.presetClass or "correct class") ..
            "), then try again.", true
    end
    -- Do not permit a same-name different-GUID replacement to silently
    -- inherit an earlier bot's target verification.
    if self.boundTarget and self.boundTarget.guid and
        self.boundTarget.guid~=current.guid then
        self.awaitingTarget=false
        self.awaitingAction=nil
        return false, "Bot identity differs. Reopen Set Talents.", false
    end
    if self.boundTarget and self.boundTarget.class and
        self.boundTarget.class~=current.class then
        self.awaitingTarget=false
        self.awaitingAction=nil
        return false, "Bot class differs. Reopen Set Talents.", false
    end
    self.boundTarget=current
    self.awaitingTarget=false
    self.awaitingAction=nil
    if self.targetLabel then
        self.targetLabel:SetText("Bot: " .. current.name ..
            "  |  Class: " .. (current.class or "unknown"))
    end
    return true
end

function Talents:OnTargetChanged()
    if not self.window or not self.window:IsShown() then return end
    if self.pendingApply then
        -- TargetByName-style re-target events can arrive after the secure
        -- hardware click. Do not dismiss a popup if the bot's exact GUID
        -- and class still match. A genuinely different unit invalidates it.
        local current=getTarget()
        local bound=self.boundTarget
        local same=current and bound and current.guid and bound.guid and
            current.guid==bound.guid and current.class==bound.class and
            current.name==bound.name
        if not same then
            self.pendingApply=nil
            if type(_G.StaticPopup_Hide)=="function" then
                _G.StaticPopup_Hide(APPLY_CONFIRM_KEY)
            end
            if self.status then
                self.status:SetText("Target changed. Click Apply again.")
            end
        end
    end
    if self.awaitingTarget and self.page==1 then
        local action=self.awaitingAction or "apply"
        local ok,hint=self:CheckIntendedTarget(action)
        if self.status then
            self.status:SetText(ok and
                ("Target verified. Click " ..
                    (action=="preview" and "Preview." or "Apply talents.")) or hint)
        end
    end
end

-- SecureActionButtonTemplate handles /targetexact under a real click, not
-- insecure addon Lua. TargetByName was removed long before WoW 3.3.5a.
-- Configure outside combat; never generate macro text from untrusted input.
-- The addon verifies the resulting target before any Apply confirmation.
function Talents:ConfigureApplyAutoTarget()
    local name=self.requestedBot or
        (self.boundTarget and self.boundTarget.name)
    self.autoTargetReady=false
    if type(_G.InCombatLockdown)=="function" and
        _G.InCombatLockdown() then
        return false
    end
    if not self.applyButton or type(self.applyButton.SetAttribute)~="function" then
        return false
    end
    local safe=type(name)=="string" and #name>=2 and #name<=12 and
        name:match("^[A-Za-z]+$")
    if safe then
        self.applyButton:SetAttribute("macrotext1","/targetexact " .. name)
        self.applyButton:SetAttribute("type1","macro")
        self.autoTargetReady=true
    else
        self.applyButton:SetAttribute("type1",nil)
        self.applyButton:SetAttribute("macrotext1",nil)
    end
    return self.autoTargetReady
end

function Talents:RequestApplyConfirmation()
    local wasBound=self.boundTarget~=nil
    local matched,hint,guided=self:CheckIntendedTarget("apply")
    if not matched then return false,hint,guided end
    -- If the macro just selected the roster bot, let any pending
    -- PLAYER_TARGET_CHANGED event settle before opening an Apply popup.
    -- A second deliberate Apply click is required, but no manual target.
    if not wasBound then
        return false, "Target verified. Click Apply talents again.", true
    end
    local plan, errorText = self:PrepareCommand("apply", self.input:GetText())
    if not plan then return false, errorText end
    local summary = self:DescribeCode(plan.code)
    if not summary then return false, "Invalid NT1 code." end
    if type(StaticPopup_Show) ~= "function" or
        type(StaticPopupDialogs) ~= "table" then
        return false, "Confirmation dialog unavailable; no command sent."
    end
    self.pendingApply = {command=plan.command, code=plan.code}
    local expected = self.pendingApply -- Old/stale popup callbacks fail closed.
    StaticPopupDialogs[APPLY_CONFIRM_KEY] = {
        text="Apply build to %s?\nExperimental: server may reject.",
        button1="Apply talents", button2="Cancel", timeout=0,
        whileDead=1, hideOnEscape=1, preferredIndex=3,
        OnAccept=function()
            local pending = Talents.pendingApply
            if not pending or pending ~= expected then return end
            Talents.pendingApply = nil
            if not Talents.window or
                not Talents.window:IsShown() then
                return
            end
            local current, failure = Talents:PrepareCommand(
                "apply", Talents.input:GetText())
            if not current or current.command ~= pending.command or
                current.code ~= pending.code then
                local messageText = failure or "Build or target changed. No command sent."
                Talents.status:SetText(messageText)
                message(messageText, true)
                return
            end
            local ok, result = Talents:SendToTarget("apply", pending.code)
            Talents.status:SetText(result)
            message(result, not ok)
            if ok then
                Talents.input:ClearFocus()
                Talents.window:Hide()
            end
        end,
        OnCancel=function()
            if Talents.pendingApply == expected then
                Talents.pendingApply = nil
            end
        end,
    }
    local shown = StaticPopup_Show(APPLY_CONFIRM_KEY,
        plan.target.name .. " (" .. string.upper(summary.class) .. ")\n" ..
        string.upper(summary.era) .. ", " .. summary.points ..
        " selected points (local only)")
    if not shown then
        self.pendingApply = nil
        return false, "Confirmation could not open. No command sent."
    end
    return true, "Confirm the target and build in the second dialog."
end

-- These are account-wide addon SavedVariables, deliberately separate
-- from MultiBotDB/AceDB profile settings and from N Talent Calculator saves.
-- WoW loads _G.MultiBotNT1SavedBuilds before addon Lua and writes it on logout.
local MAX_SAVED_BUILDS = 100
local MAX_BUILD_NAME = 40

local function getSavedStore(create)
    if type(_G.MultiBotNT1SavedBuilds) == "table" then
        return _G.MultiBotNT1SavedBuilds
    end
    if create then
        _G.MultiBotNT1SavedBuilds = {}
        return _G.MultiBotNT1SavedBuilds
    end
    return nil
end

local function findSavedName(name)
    local store = getSavedStore(false)
    if not store then return nil end
    local key = string.lower(name)
    for savedName, code in pairs(store) do
        if type(savedName) == "string" and
            type(code) == "string" and string.lower(savedName) == key then
            return savedName
        end
    end
    return nil
end

local function validName(name)
    name = trim(name)
    if #name < 1 or #name > MAX_BUILD_NAME or name:find("[%c|]") then
        return nil, "Enter a build name (1-40 characters, no line breaks)."
    end
    return name
end

function Talents:ListSavedBuilds()
    local result = {}
    local store = getSavedStore(false) or {}
    for name, code in pairs(store) do
        if type(name) == "string" and type(code) == "string" then
            local valid = self:ValidateCode(code)
            if valid then
                local era, class = code:match("^NT1:([a-z]+):([a-z]+):")
                result[#result+1] = {name=name, code=code,
                    era=era, class=class}
            end
        end
    end
    table.sort(result, function(a,b)
        local x,y = string.lower(a.name),string.lower(b.name)
        if x == y then return a.name < b.name end
        return x < y
    end)
    return result
end

-- Pinned website presets are read-only and always class-filtered.
-- No runtime HTTP or out-of-game file access is possible in 3.3.5a.
function Talents:ListWebsitePresets(className)
    local class = type(className)=="string" and
        className:lower():gsub("[^a-z]", "") or ""
    -- Death Knight remains explicitly excluded, even if a future data
    -- refresh accidentally contains an entry. Warlock now has five
    -- owner-approved Vanilla presets (2 Raid, 3 Solo); Warrior has seven.
    if class=="deathknight" then
        return {}
    end
    local result = {}
    for _,entry in ipairs(MultiBot.NT1WebsitePresets or {}) do
        if entry.class==class and self:ValidateCode(entry.code, class) then
            result[#result+1]=entry
        end
    end
    table.sort(result, function(a,b)
        if a.category ~= b.category then
            return a.category == "Raid"
        end
        if a.name~=b.name then return a.name<b.name end
        return a.variant<b.variant
    end)
    return result
end

function Talents:ListFilteredWebsitePresets(className)
    local all = self:ListWebsitePresets(className)
    local filter = self.presetFilter or "All"
    if filter == "All" then return all end
    local result = {}
    for _, entry in ipairs(all) do
        if entry.category == filter then result[#result+1] = entry end
    end
    return result
end

function Talents:GetSavedCode(name)
    local clean = validName(name)
    if not clean then return nil end
    local existing = findSavedName(clean)
    local store = getSavedStore(false)
    return existing and store and store[existing] or nil
end

function Talents:SaveBuild(name, text, replace)
    local clean, why = validName(name)
    if not clean then return false, why end
    local code, invalid = self:ValidateCode(text)
    if not code then return false, invalid end
    local existing = findSavedName(clean)
    local store = getSavedStore(false)
    if existing and store[existing] ~= code and not replace then
        return false, "Build exists. Save again to replace it."
    end
    if not existing and #self:ListSavedBuilds() >= MAX_SAVED_BUILDS then
        return false, "Saved build limit reached (100)."
    end
    store = getSavedStore(true)
    store[existing or clean] = code
    return true, "Saved " .. (existing or clean) .. "."
end

-- Portable, plain-text account backup. WoW has no programmatic clipboard;
-- players manually select/copy and paste the exported text.
-- A 30 KB UI cap prevents silent truncation in the 3.3.5a EditBox.
local BACKUP_LIMIT = 30000
local BACKUP_HEADER = "NMB1\n"

function Talents:ExportSavedBuilds()
    local saved = self:ListSavedBuilds()
    if #saved == 0 then return nil, "No saved builds to export." end
    local rows = {BACKUP_HEADER}
    for _, entry in ipairs(saved) do
        local valid = validName(entry.name)
        if valid ~= entry.name or entry.name:find("|",1,true) then
            return nil, "Invalid saved name; use the WTF SavedVariables backup."
        end
        rows[#rows+1] = entry.name .. "|" .. entry.code .. "\n"
    end
    rows[#rows+1] = "END|" .. #saved .. "\n"
    local exported = table.concat(rows)
    if #exported > BACKUP_LIMIT then
        return nil, "Backup exceeds 30 KB. Back up WTF SavedVariables instead."
    end
    return exported
end

function Talents:ImportSavedBuilds(text, allowOverwrite)
    if type(text) ~= "string" or #text > BACKUP_LIMIT then
        return false, "Backup text is missing or exceeds 30 KB. No changes."
    end
    local normalized = text:gsub("\r\n", "\n")
    if normalized:sub(1,#BACKUP_HEADER) ~= BACKUP_HEADER then
        return false, "Expected NMB1 backup header. No changes."
    end
    local body = normalized:sub(#BACKUP_HEADER+1)
    if body == "" or body:sub(1,1) == "\n" or
        body:find("\n\n",1,true) or body:find("\r",1,true) then
        return false, "Empty or malformed backup. No changes."
    end
    local lines = {}
    for line in body:gmatch("([^\n]+)") do
        lines[#lines+1] = line
    end
    local declared = lines[#lines] and
        lines[#lines]:match("^END|([0-9]+)$")
    if not declared or tonumber(declared) ~= #lines-1 then
        return false, "Incomplete backup or missing END count. No changes."
    end
    lines[#lines] = nil
    local records, seen = {}, {}
    for _, line in ipairs(lines) do
        local rawName, code = line:match("^([^|]+)|([^|]+)$")
        local name = rawName and validName(rawName)
        if not name or name ~= rawName or not code or
            not self:ValidateCode(code) then
            return false, "Invalid name or NT1 code in backup. No changes."
        end
        local key = string.lower(name)
        if seen[key] then
            return false, "Duplicate named build in backup. No changes."
        end
        seen[key] = true
        records[#records+1] = {name=name,code=code}
        if #records > MAX_SAVED_BUILDS then
            return false, "Backup exceeds the 100-build limit. No changes."
        end
    end
    if #records == 0 then return false, "Empty backup. No changes." end
    local additions, conflicts = 0, 0
    local store = getSavedStore(false) or {}
    for _, entry in ipairs(records) do
        local existing = findSavedName(entry.name)
        if not existing then
            additions = additions + 1
        elseif store[existing] ~= entry.code then
            conflicts = conflicts + 1
        end
    end
    if #self:ListSavedBuilds() + additions > MAX_SAVED_BUILDS then
        return false, "Import would exceed the 100-build limit. No changes."
    end
    if conflicts > 0 and not allowOverwrite then
        return false, "Confirm overwrite: " .. conflicts ..
            " existing name(s) differ. Click Import again to replace."
    end
    store = getSavedStore(true)
    for _, entry in ipairs(records) do
        local existing = findSavedName(entry.name)
        store[existing or entry.name] = entry.code
    end
    return true, "Imported " .. #records ..
        " saved build(s) locally. No server command sent."
end

function Talents:DeleteBuild(name)
    local clean, why = validName(name)
    if not clean then return false, why end
    local existing = findSavedName(clean)
    local store = getSavedStore(false)
    if not existing or not store then
        return false, "Build not found."
    end
    store[existing] = nil
    return true, "Deleted " .. existing .. "."
end

local function styledLabel(parent, text, x, y, width, color)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    if color then label:SetTextColor(unpack(color)) end
    return label
end

-- A restrained Wrath-native backdrop for the list: only Blizzard
-- textures/templates, no custom assets and no protected action changes.
local function listPanel(parent, x, y, width, height)
    local panel=CreateFrame("Frame",nil,parent)
    panel:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    panel:SetSize(width,height)
    panel:SetBackdrop({
        bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true,tileSize=16,edgeSize=12,
        insets={left=3,right=3,top=3,bottom=3},
    })
    panel:SetBackdropColor(0.07,0.065,0.055,0.93)
    panel:SetBackdropBorderColor(0.42,0.34,0.20,0.82)
    return panel
end

-- Unlike UIPanelButtonTemplate, the plain button lets the actual preset
-- list look like a Blizzard browser rather than red confirmation buttons.
-- Text and category remain explicit for screen readability.
local function presetListRow(parent,slot,firstRowOffset,rowSpacing)
    local row=CreateFrame("Button",nil,parent)
    row:SetSize(584,31)
    row:SetPoint("TOPLEFT",parent,"TOPLEFT",38,
        -(firstRowOffset or 82)-(slot-1)*(rowSpacing or 37))
    row:SetNormalFontObject(_G.GameFontHighlightSmall or
        "GameFontHighlightSmall")
    row:SetHighlightFontObject(_G.GameFontHighlight or
        "GameFontHighlight")
    local bg=row:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    local shade=(slot%2==0) and 0.14 or 0.11
    bg:SetVertexColor(shade,shade*0.88,shade*0.67,0.93)
    row.background=bg
    local hover=row:CreateTexture(nil,"HIGHLIGHT")
    hover:SetAllPoints(row)
    hover:SetTexture("Interface\\Buttons\\WHITE8X8")
    hover:SetVertexColor(0.29,0.23,0.13,0.40)
    row.hoverTexture=hover
    local stripe=row:CreateTexture(nil,"ARTWORK")
    stripe:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
    stripe:SetSize(4,31)
    stripe:SetTexture("Interface\\Buttons\\WHITE8X8")
    stripe:SetVertexColor(0.73,0.52,0.22,1)
    row.categoryStripe=stripe
    row.categoryLabel=styledLabel(row,"",15,-9,72,
        {0.91,0.76,0.42})
    return row
end

local function button(parent, name, x, y, width, callback, secureTarget)
    local template=secureTarget and
        "SecureActionButtonTemplate,UIPanelButtonTemplate" or
        "UIPanelButtonTemplate"
    local b=CreateFrame("Button", nil, parent, template)
    b:SetSize(width, 25)
    b:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, y)
    b:SetText(name)
    if secureTarget then
        -- HookScript leaves Blizzard's protected targeting handler intact.
        -- SetScript here would replace it, silently breaking the macro.
        b:HookScript("OnClick", callback)
    else
        b:SetScript("OnClick", callback)
    end
    return b
end

function Talents:EnsureWindow()
    if self.window then return self.window end
    local window = CreateFrame("Frame", WINDOW_NAME, UIParent)
    window:SetWidth(660)
    window:SetHeight(465)
    window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
    window:SetScript("OnDragStop", function(frame) frame:StopMovingOrSizing() end)
    window:SetBackdrop({
        bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=false, edgeSize=28,
        insets={left=8,right=8,top=8,bottom=8},
    })
    window:SetBackdropColor(0.035, 0.03, 0.045, 0.98)
    window:SetBackdropBorderColor(0.68, 0.54, 0.30, 1)
    local divider=window:CreateTexture(nil,"ARTWORK")
    divider:SetPoint("TOPLEFT",window,"TOPLEFT",22,-91)
    divider:SetSize(616,2)
    divider:SetTexture("Interface\\Buttons\\WHITE8X8")
    divider:SetVertexColor(0.54,0.39,0.20,0.85)
    self.headerDivider=divider

    self.title = styledLabel(window, "NT1 TALENT IMPORT", 22, -22, 560,
        {1, 0.84, 0.42})
    if _G.GameFontNormalLarge then
        self.title:SetFontObject(_G.GameFontNormalLarge)
    end
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -7, -6)
    self.targetLabel = styledLabel(window, "", 22, -68, 610,
        {1, 0.84, 0.42})

    local importPage = CreateFrame("Frame", nil, window)
    importPage:SetSize(660, 365)
    importPage:SetPoint("TOPLEFT", window, "TOPLEFT", 0, -85)
    local savedPage = CreateFrame("Frame", nil, window)
    savedPage:SetSize(660, 365)
    savedPage:SetPoint("TOPLEFT", window, "TOPLEFT", 0, -85)
    self.importPage = importPage
    self.savedPage = savedPage
    local presetPage = CreateFrame("Frame", nil, window)
    presetPage:SetSize(660, 365)
    presetPage:SetPoint("TOPLEFT", window, "TOPLEFT", 0, -85)
    self.presetPage = presetPage
    local backupPage = CreateFrame("Frame", nil, window)
    backupPage:SetSize(660,365)
    backupPage:SetPoint("TOPLEFT", window, "TOPLEFT", 0, -85)
    self.backupPage = backupPage

    -- Page 1 visual polish: three orderly Wrath-native sections.
    -- Only frames, labels and positions change. The secure Apply button,
    -- its targeting macro, all actions and their callbacks stay unchanged.
    self.importIntro=styledLabel(importPage,
        "PASTE OR LOAD AN NT1 TALENT CODE",
        22,-20,610,{0.86,0.85,0.79})
    self.importExample=styledLabel(importPage,
        "Example: " .. EXAMPLE,22,-59,610,{0.69,0.85,1})
    self.importCodePanel=listPanel(importPage,22,-87,616,57)

    local input = CreateFrame("EditBox", nil, importPage, "InputBoxTemplate")
    input:SetPoint("TOPLEFT", importPage, "TOPLEFT", 32, -106)
    input:SetSize(594, 28)
    input:SetAutoFocus(false)
    input:SetMaxLetters(MAX_CODE_LENGTH)
    input:SetText("")
    self.input = input

    self.importNamePanel=listPanel(importPage,22,-145,616,79)
    -- FontStrings must belong to the panel; child Frame backdrops otherwise
    -- tint their parent-level text under WoW 3.3.5a rendering.
    self.importSaveLabel=styledLabel(self.importNamePanel,
        "SAVE AS", 12, -13, 122, {1, 0.84, 0.42})
    local nameBox = CreateFrame("EditBox", nil, importPage, "InputBoxTemplate")
    nameBox:SetPoint("TOPLEFT", importPage, "TOPLEFT", 166, -149)
    nameBox:SetSize(283, 28)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(MAX_BUILD_NAME)
    nameBox:SetText("")
    self.nameBox = nameBox

    self.importInfoPanel=listPanel(importPage,22,-227,616,83)
    self.status = styledLabel(self.importInfoPanel, "No command sent.",
        12,-11,590,{0.86,0.85,0.79})
    self.buildSummary = styledLabel(self.importInfoPanel,
        "Build details appear here (local check only).",
        12,-37,590,{0.69,0.85,1})
    self.importSafety=styledLabel(self.importInfoPanel,
        "Apply requires confirmation and a bot backup.",
        12,-64,590,{1,0.67,0.44})

    local pendingSave
    nameBox:SetScript("OnTextChanged", function() pendingSave = nil end)
    input:SetScript("OnTextChanged", function()
        pendingSave = nil
        Talents.pendingApply = nil
        local details = Talents:DescribeCode(input:GetText())
        if details then
            Talents.buildSummary:SetText("Build: " ..
                string.upper(details.class) .. " | " ..
                string.upper(details.era) .. " | " ..
                details.points .. " selected (local) | Role: " .. details.role)
        else
            Talents.buildSummary:SetText(
                "Enter a valid NT1 code (local check only).")
        end
    end)
    local function submit(action)
        local ok, reason = Talents:SendToTarget(action, input:GetText())
        Talents.status:SetText(reason)
        message(reason, not ok)
        if ok and action == "apply" then
            input:ClearFocus()
            window:Hide()
        end
        return ok
    end

    self.saveButton = button(importPage, "Save code", 469, 190, 157,
        function()
            local name, code = nameBox:GetText(), input:GetText()
            local trimmedName = trim(name)
            local previous = Talents:GetSavedCode(trimmedName)
            if previous and previous ~= trim(code) and
                (not pendingSave or pendingSave.name ~= string.lower(trimmedName) or
                 pendingSave.code ~= trim(code)) then
                local valid, why = Talents:ValidateCode(code)
                if not valid then
                    Talents.status:SetText(why)
                    return
                end
                pendingSave = {name=string.lower(trimmedName), code=trim(code)}
                Talents.status:SetText("Save again to replace " .. trimmedName .. ".")
                return
            end
            local ok, why = Talents:SaveBuild(trimmedName, code, previous ~= nil)
            pendingSave = nil
            Talents.status:SetText(why)
            if ok then Talents.selectedName = trimmedName end
        end)

    self.targetConfirm = button(importPage, "Check target", 469, 150, 157,
        function()
            local ok,hint=Talents:CheckIntendedTarget("apply")
            Talents.status:SetText(ok and
                "Target verified. Preview before Apply." or hint)
        end)

    self.previewButton = button(importPage, "Preview", 22, 18, 110,
        function()
            local ok,hint,guided=Talents:CheckIntendedTarget("preview")
            if not ok then
                Talents.status:SetText(hint)
                if not guided then message(hint,true) end
            else
                submit("preview")
            end
        end)
    self.applyButton = button(importPage, "Apply talents", 138, 18, 130,
        function()
            local ok,result,guided=Talents:RequestApplyConfirmation()
            Talents.status:SetText(result)
            -- Targeting is a protected click action. The callback never
            -- assumes the macro succeeded, and never sends Apply itself.
            if not guided then message(result,not ok) end
        end, true)
    self.cancelButton = button(importPage, "Cancel", 274, 18, 104,
        function()
            input:ClearFocus()
            nameBox:ClearFocus()
            window:Hide()
        end)

    -- Saved page uses five rows per page, not a single endless icon list.
    -- Selecting or loading is read-only; no server command is sent here.
    -- Saved Builds shares the visually accepted website-list styling.
    -- Status stays at the top: an enlarged client font cannot fit another
    -- full-width line below five rows without colliding with the footer.
    self.savedStatus=styledLabel(savedPage,
        "Select a saved build. No talents applied.",
        22,-18,606,{0.86,0.85,0.79})
    self.savedListPanel=listPanel(savedPage,22,-52,616,207)
    self.savedRows = {}
    local PAGE_SIZE = 5
    self.savedPageIndex = 1
    for i=1,PAGE_SIZE do
        local slot = i
        local rowButton=presetListRow(savedPage,i,60,40)
        rowButton.categoryLabel:SetWidth(128)
        rowButton.nameLabel=styledLabel(rowButton,"",164,-9,298)
        rowButton.eraLabel=styledLabel(rowButton,"",482,-9,98,
            {0.67,0.76,0.78})
        rowButton:SetScript("OnClick", function()
            local list = Talents:ListSavedBuilds()
            local entry = list[(Talents.savedPageIndex-1)*PAGE_SIZE + slot]
            if not entry then return end
            Talents.selectedName = entry.name
            Talents.pendingDelete = nil
            Talents:UpdateSavedPage()
        end)
        self.savedRows[i] = rowButton
    end
    -- No status label next to the footer navigation or page counter.
    self.savedPageCounter = styledLabel(savedPage, "", 239, -302, 190,
        {1, 0.84, 0.42})

    -- Page 3 first visual polish: a deliberate list container and quieter
    -- rows. Page 1 protected Apply behaviour remains byte-for-byte intact.
    -- Website data is pinned; filters only affect display, not commands.
    -- At enlarged in-game font scales the old footer help text collided
    -- with Previous/Next. Show the safety hint in the existing top
    -- instruction slot instead; leave the list and footer positions alone.
    self.presetStatus=styledLabel(presetPage,
        "Select a build. No talents are applied.",
        22,-18,610,{0.86,0.85,0.79})
    self.presetListPanel=listPanel(presetPage,22,-75,616,196)
    self.presetRows = {}
    self.presetPageIndex = 1
    self.presetFilter = "All"
    self.presetFilterButtons = {}
    for i, kind in ipairs({"All", "Raid", "Solo"}) do
        local filter = kind
        local b = CreateFrame("Button", nil, presetPage, "UIPanelButtonTemplate")
        b:SetSize(106, 23)
        b:SetPoint("TOPLEFT", presetPage, "TOPLEFT", 22+(i-1)*113, -43)
        b:SetScript("OnClick", function()
            Talents.presetFilter = filter
            Talents.presetPageIndex = 1
            Talents.selectedPreset = nil
            Talents:UpdatePresetPage()
        end)
        self.presetFilterButtons[kind] = b
    end
    for i=1,5 do
        local slot=i
        local row=presetListRow(presetPage,i)
        row:SetText("")
        row:SetScript("OnClick", function()
            local list = Talents:ListFilteredWebsitePresets(Talents.presetClass)
            local entry = list[(Talents.presetPageIndex-1)*5+slot]
            -- Direct load is local UI navigation only. No Preview or Apply.
            Talents:LoadWebsitePreset(entry)
        end)
        self.presetRows[i]=row
    end
    -- No status label between the full-height list and bottom navigation.
    self.presetCounter = styledLabel(presetPage, "", 239, -302, 190,
        {1, 0.84, 0.42})

    -- Page 4 appearance only. Place dynamic status above the editor so
    -- large 3.3.5a fonts cannot wrap into the bottom navigation buttons.
    -- The NMB1 parser, SavedVariables and all button callbacks are unchanged.
    self.backupHeading = styledLabel(backupPage,
        "COPY OR PASTE AN NMB1 BACKUP",
        22, -18, 610, {1, 0.84, 0.42})
    self.backupStatus = styledLabel(backupPage,
        "Export all, or paste an NMB1 backup to import.",
        22, -48, 610, {0.86, 0.85, 0.79})
    self.backupTextPanel = listPanel(backupPage, 22, -112, 616, 186)
    -- Like Page 1, this label belongs to its child panel so the panel
    -- backdrop never darkens it.
    self.backupTextHeading = styledLabel(self.backupTextPanel,
        "BACKUP TEXT  |  COPY OR PASTE",
        12, -12, 582, {0.69, 0.85, 1})

    -- Wrath's UIPanelScrollFrameTemplate MUST have a nonempty name.
    -- Retain the same global scroll frame and text edit control.
    local backupScroll = CreateFrame("ScrollFrame",
        "MultiBotNT1BackupScrollFrame", backupPage,
        "UIPanelScrollFrameTemplate")
    backupScroll:SetPoint("TOPLEFT", backupPage, "TOPLEFT", 34, -151)
    backupScroll:SetSize(580, 137)
    local backupText = CreateFrame("EditBox", nil, backupScroll)
    backupText:SetPoint("TOPLEFT", backupScroll, "TOPLEFT", 0, 0)
    backupText:SetSize(548, 137)
    backupText:SetMultiLine(true)
    backupText:SetAutoFocus(false)
    backupText:SetMaxLetters(BACKUP_LIMIT)
    if _G.ChatFontNormal then backupText:SetFontObject(_G.ChatFontNormal) end
    backupText:SetText("")
    backupScroll:SetScrollChild(backupText)
    self.backupScroll = backupScroll
    self.backupText = backupText
    local pendingImport
    backupText:SetScript("OnTextChanged", function(box)
        pendingImport = nil
        if box.GetStringHeight then
            box:SetHeight(math.max(137,box:GetStringHeight()+30))
        end
    end)

    self.showPage = function(page)
        pendingSave = nil
        Talents.pendingDelete = nil
        Talents.pendingApply = nil
        Talents.awaitingTarget = false
        Talents.awaitingAction = nil
        Talents.page = page
        importPage:Hide()
        savedPage:Hide()
        presetPage:Hide()
        backupPage:Hide()
        if page == 2 then
            savedPage:Show()
            Talents.title:SetText("SAVED TALENT BUILDS")
            input:ClearFocus()
            nameBox:ClearFocus()
            Talents:UpdateSavedPage()
        elseif page == 3 then
            presetPage:Show()
            Talents.title:SetText("WEBSITE CLASS PRESETS")
            input:ClearFocus()
            nameBox:ClearFocus()
            Talents:UpdatePresetPage()
        elseif page == 4 then
            backupPage:Show()
            Talents.title:SetText("SAVED BUILDS BACKUP / IMPORT")
            input:ClearFocus()
            nameBox:ClearFocus()
            pendingImport = nil
            Talents.backupStatus:SetText(
                "Export all, or paste an NMB1 backup to import.")
        else
            importPage:Show()
            Talents.title:SetText("NT1 TALENT IMPORT")
        end
    end

    self.previousSavedPage = button(savedPage, "< Previous", 24, 55, 119,
        function()
            if Talents.savedPageIndex > 1 then
                Talents.savedPageIndex = Talents.savedPageIndex - 1
            end
            Talents:UpdateSavedPage()
        end)
    self.nextSavedPage = button(savedPage, "Next >", 502, 55, 132,
        function()
            local count = #Talents:ListSavedBuilds()
            local maxPages = math.max(1, math.ceil(count/PAGE_SIZE))
            if Talents.savedPageIndex < maxPages then
                Talents.savedPageIndex = Talents.savedPageIndex + 1
            end
            Talents:UpdateSavedPage()
        end)
    self.backButton = button(savedPage, "< Import", 22, 17, 140,
        function() Talents.showPage(1) end)
    self.loadButton = button(savedPage, "Load to import", 176, 17, 166,
        function()
            local chosen = Talents.selectedName
            local code = chosen and Talents:GetSavedCode(chosen)
            if not code then
                Talents.savedStatus:SetText("Select a saved build first.")
                return
            end
            input:SetText(code)
            nameBox:SetText(chosen)
            Talents.showPage(1)
            Talents.status:SetText("Loaded " .. chosen ..
                ". Use Preview or Apply separately.")
            local _, class = code:match("^NT1:([a-z]+):([a-z]+):")
            if Talents.boundTarget and Talents.boundTarget.class and
                class ~= Talents.boundTarget.class then
                Talents.status:SetText("Loaded " .. class ..
                    " build; selected bot class is " ..
                    Talents.boundTarget.class .. ". Cannot apply.")
            end
        end)
    self.deleteButton = button(savedPage, "Delete", 355, 17, 112,
        function()
            local chosen = Talents.selectedName
            if not chosen or not Talents:GetSavedCode(chosen) then
                Talents.savedStatus:SetText("Select a saved build first.")
                return
            end
            if Talents.pendingDelete ~= chosen then
                Talents.pendingDelete = chosen
                Talents.savedStatus:SetText(
                    "Delete selected build? Click Delete again.")
                return
            end
            local ok = Talents:DeleteBuild(chosen)
            Talents.selectedName = nil
            Talents.pendingDelete = nil
            Talents:UpdateSavedPage()
            Talents.savedStatus:SetText(ok and "Build deleted." or
                "Could not delete build.")
        end)

    self.backupButton = button(savedPage, "Backup/Import", 480, 17, 156,
        function() Talents.showPage(4) end)
    self.exportButton = button(backupPage, "Export all", 22, 17, 119,
        function()
            local text, reason = Talents:ExportSavedBuilds()
            if not text then
                Talents.backupStatus:SetText(reason)
                return
            end
            backupText:SetText(text)
            backupText:SetFocus()
            backupText:HighlightText()
            Talents.backupStatus:SetText(
                "Select all and copy (Ctrl+C). Nothing sent to server.")
        end)
    self.importButton = button(backupPage, "Import pasted", 152, 17, 152,
        function()
            local text = backupText:GetText()
            local overwrite = pendingImport == text
            local ok, reason = Talents:ImportSavedBuilds(text, overwrite)
            if not ok and reason:find("Confirm overwrite:",1,true) then
                pendingImport = text
            else
                pendingImport = nil
            end
            Talents.backupStatus:SetText(reason)
            message(reason, not ok)
        end)
    self.backFromBackup = button(backupPage, "< Saved builds", 315, 17, 145,
        function()
            backupText:ClearFocus()
            Talents.showPage(2)
        end)
    self.closeBackup = button(backupPage, "Cancel", 475, 17, 120,
        function()
            backupText:ClearFocus()
            window:Hide()
        end)

    self.savedButton = button(importPage, "Saved builds >", 390, 18, 240,
        function()
            Talents.savedPageIndex = 1
            Talents.showPage(2)
        end)

    self.prevPresetPage = button(presetPage, "< Previous", 24, 55, 119,
        function()
            if Talents.presetPageIndex>1 then
                Talents.presetPageIndex=Talents.presetPageIndex-1
            end
            Talents:UpdatePresetPage()
        end)
    self.nextPresetPage = button(presetPage, "Next >", 502, 55, 132,
        function()
            local count=#Talents:ListFilteredWebsitePresets(Talents.presetClass)
            if Talents.presetPageIndex < math.max(1,math.ceil(count/5)) then
                Talents.presetPageIndex=Talents.presetPageIndex+1
            end
            Talents:UpdatePresetPage()
        end)
    self.originalSpecButton = button(presetPage, "Bot specs", 22, 17, 128,
        function()
            local original = Talents.originalSpecsCallback
            window:Hide()
            if type(original) == "function" then original() end
        end)
    -- Each large red preset row loads directly. The second Load button
    -- formerly here was redundant and made the user click twice.
    self.cancelPresetButton = button(presetPage, "Cancel", 502, 17, 120,
        function() window:Hide() end)

    input:SetScript("OnEnterPressed", function()
        input:ClearFocus() -- Enter must never mutate a bot or send Apply.
    end)
    input:SetScript("OnEscapePressed", function()
        input:ClearFocus()
        window:Hide()
    end)
    nameBox:SetScript("OnEnterPressed", function()
        nameBox:ClearFocus() -- Enter in the name field must never apply.
    end)
    nameBox:SetScript("OnEscapePressed", function()
        nameBox:ClearFocus()
        window:Hide()
    end)
    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, WINDOW_NAME)
    end
    -- Target selection events update guidance, never dispatch server chat.
    window:RegisterEvent("PLAYER_TARGET_CHANGED")
    window:RegisterEvent("PLAYER_REGEN_ENABLED")
    window:SetScript("OnEvent", function(_,event)
        if event=="PLAYER_TARGET_CHANGED" then
            Talents:OnTargetChanged()
        elseif event=="PLAYER_REGEN_ENABLED" and
            Talents.window and Talents.window:IsShown() then
            Talents:ConfigureApplyAutoTarget()
        end
    end)
    window:Hide()
    self.window = window
    Talents.showPage(1)
    return window
end

function Talents:UpdateSavedPage()
    if not self.savedRows then return end
    local list = self:ListSavedBuilds()
    local size = #self.savedRows
    local maxPages = math.max(1, math.ceil(#list/size))
    if self.savedPageIndex > maxPages then
        self.savedPageIndex = maxPages
    end
    for i, row in ipairs(self.savedRows) do
        local entry = list[(self.savedPageIndex-1)*size + i]
        if entry then
            local chosen=self.selectedName==entry.name
            local name=entry.name
            if #name>22 then name=name:sub(1,19).. "..." end
            row:SetText("")
            row.categoryLabel:SetText(string.upper(entry.class))
            row.nameLabel:SetText((chosen and "> " or "")..name)
            row.eraLabel:SetText(string.upper(entry.era))
            if chosen then
                row.categoryStripe:SetVertexColor(0.42,0.75,0.40,1)
                row.background:SetVertexColor(0.17,0.21,0.15,0.96)
                row.nameLabel:SetTextColor(0.94,1,0.86)
            else
                row.categoryStripe:SetVertexColor(0.73,0.52,0.22,1)
                local shade=(i%2==0) and 0.14 or 0.11
                row.background:SetVertexColor(shade,shade*0.88,
                    shade*0.67,0.93)
                row.nameLabel:SetTextColor(1,1,1)
            end
            row:Show()
        else
            row:Hide()
        end
    end
    self.savedPageCounter:SetText("Page " .. self.savedPageIndex ..
        " / " .. maxPages .. "  (" .. #list ..
        (#list==1 and " build)" or " builds)"))
    if self.selectedName then
        local short=self.selectedName
        if #short>24 then short=short:sub(1,21).."..." end
        self.savedStatus:SetText("Selected: "..short.." (not applied)")
    else
        self.savedStatus:SetText("Select a saved build. No talents applied.")
    end
end

function Talents:UpdatePresetPage()
    if not self.presetRows then return end
    local list=self:ListFilteredWebsitePresets(self.presetClass)
    local maxPages=math.max(1,math.ceil(#list/5))
    for name, b in pairs(self.presetFilterButtons or {}) do
        b:SetText((name == (self.presetFilter or "All") and "[ " ..
            name .. " ]") or name)
    end
    if self.presetPageIndex>maxPages then self.presetPageIndex=maxPages end
    for i,row in ipairs(self.presetRows) do
        local entry=list[(self.presetPageIndex-1)*5+i]
        if entry then
            local label=entry.name .. " (" .. entry.role .. ")"
            if (entry.variant or 1)>1 then
                label=label .. " v" .. entry.variant
            end
            row:SetText(label)
            row.categoryLabel:SetText(string.upper(entry.category))
            if entry.category=="Raid" then
                row.categoryStripe:SetVertexColor(0.73,0.52,0.22,1)
                row.categoryLabel:SetTextColor(0.91,0.76,0.42)
            else
                row.categoryStripe:SetVertexColor(0.31,0.56,0.71,1)
                row.categoryLabel:SetTextColor(0.57,0.79,0.91)
            end
            row:Show()
        else
            row:Hide()
        end
    end
    self.presetCounter:SetText("Page " .. self.presetPageIndex ..
        " / " .. maxPages .. "  (" .. #list .. " builds)")
    self.presetStatus:SetText("Select a build. No talents are applied.")
end

-- Red website preset buttons jump straight to the read-only import editor.
-- Target confirmation and all server actions remain separate operations.
function Talents:LoadWebsitePreset(entry)
    if type(entry)~="table" or entry.class~=self.presetClass then
        return false, "Choose a preset for this bot's class."
    end
    local code, reason=self:ValidateCode(entry.code, self.presetClass)
    if not code then return false, reason end
    if not self.input or not self.nameBox or not self.showPage then
        return false, "Talent import editor is unavailable."
    end
    self.selectedPreset=entry
    self.input:SetText(code)
    self.nameBox:SetText(entry.name .. " " .. entry.category)
    self.showPage(1)
    self.status:SetText("Build loaded. Apply attempts to target " ..
        (self.requestedBot or "the bot") .. " first.")
    return true
end

-- Open from the bot's existing "Set Talents" menu, not the current target.
-- Apply is locked until the correct bot name/class and GUID are verified.
-- Merely changing targets can never automatically issue a command.
function Talents:OpenWebsitePresetsForBot(bot, className, originalSpecsCallback)
    local class=type(className)=="string" and
        className:lower():gsub("[^a-z]", "") or ""
    if #self:ListWebsitePresets(class)==0 then return false end
    if type(bot)~="string" or bot=="" then return false end
    self.requestedBot=bot:match("^[^-]+") or bot
    self.presetClass=class
    self.originalSpecsCallback=originalSpecsCallback
    self.awaitingTarget=false
    self.awaitingAction=nil
    self.selectedPreset=nil
    self.presetPageIndex=1
    self.presetFilter="All"
    self.boundTarget=nil
    local current=getTarget()
    if current and string.lower(current.name)==
        string.lower(self.requestedBot) and current.class==class then
        self.boundTarget=current
    end
    local win=self:EnsureWindow()
    self:ConfigureApplyAutoTarget()
    self.targetLabel:SetText("Bot: "..self.requestedBot.." | Class: "..class)
    self.input:SetText("")
    self.nameBox:SetText("")
    Talents.showPage(3)
    win:Show()
    return true
end

function Talents:Open()
    local target, reason = getTarget()
    if not target then message(reason, true); return false end
    self.boundTarget = target
    self.awaitingTarget = false
    self.awaitingAction = nil
    self.requestedBot = target.name
    self.originalSpecsCallback = nil
    self.selectedPreset = nil
    self.presetClass = nil -- Never inherit an earlier roster class.
    local window = self:EnsureWindow()
    self:ConfigureApplyAutoTarget()
    self.targetLabel:SetText("Bot: " .. target.name ..
        "  |  Class: " .. (target.class or "unknown"))
    self.status:SetText(
        "Preview is read-only; it does not confirm Apply eligibility.")
    self.input:SetText("")
    self.nameBox:SetText("")
    self.selectedName = nil
    self.savedPageIndex = 1
    Talents.showPage(1)
    window:Show()
    self.input:SetFocus()
    return true
end

function MultiBot.InitializeNT1TalentsUI(tRight)
    if Talents.mainButton then return Talents end
    if not tRight or not tRight.addButton then return nil end
    local b = tRight.addButton(
        "NT1Talents", 136, 0,
        "INV_Misc_Book_07",
        "NT1 Talents - selected Playerbot" ..
        "\n|cffffffffTarget a bot and paste an NT1 build from N Talent Calculator or the website.|r" ..
        "\n|cffffaa55Apply requires confirmation; server may still reject.|r" ..
        "\n\n|cffff0000Left-click: open NT1 build paste box|r" ..
        "\n|cff999999Requires Naxxramas Core BotTalentImport AccessMode 1 or 2.|r"
    )
    b.doLeft = function() Talents:Open() end
    Talents.mainButton = b
    return Talents
end
