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
function Talents:RequestApplyConfirmation()
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
        text="Apply experimental bot talents?\n%s\n\nNo server Apply-ready check yet. Server may reject.",
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
    -- Explicit hold: these classes must use the original Bot specs menu,
    -- even if a future website snapshot accidentally includes their codes.
    if class=="warrior" or class=="warlock" or class=="deathknight" then
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

local function button(parent, name, x, y, width, callback)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 25)
    b:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, y)
    b:SetText(name)
    b:SetScript("OnClick", callback)
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

    styledLabel(importPage, "Paste an NT1 code from N Talent Calculator or the website.",
        22, -23, 610)
    styledLabel(importPage, "Example (Warrior): " .. EXAMPLE, 22, -66, 610,
        {0.69, 0.85, 1})

    local input = CreateFrame("EditBox", nil, importPage, "InputBoxTemplate")
    input:SetPoint("TOPLEFT", importPage, "TOPLEFT", 32, -106)
    input:SetSize(594, 28)
    input:SetAutoFocus(false)
    input:SetMaxLetters(MAX_CODE_LENGTH)
    input:SetText("")
    self.input = input

    styledLabel(importPage, "SAVE AS", 22, -158, 140, {1, 0.84, 0.42})
    local nameBox = CreateFrame("EditBox", nil, importPage, "InputBoxTemplate")
    nameBox:SetPoint("TOPLEFT", importPage, "TOPLEFT", 166, -149)
    nameBox:SetSize(283, 28)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(MAX_BUILD_NAME)
    nameBox:SetText("")
    self.nameBox = nameBox

    self.status = styledLabel(importPage, "No command sent.", 22, -203, 606)
    self.buildSummary = styledLabel(importPage,
        "Local summary only (not an Apply-ready or level-adjusted plan).",
        22, -231, 606,
        {0.69, 0.85, 1})
    styledLabel(importPage, "Apply requires confirmation and a bot backup.",
        22, -259, 610, {1, 0.67, 0.44})

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
                "Local summary only; paste an NT1 code (not server validation).")
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

    self.targetConfirm = button(importPage, "Confirm target", 469, 150, 157,
        function()
            local requested = Talents.requestedBot
            -- Failed reconfirmation must never leave an old binding active.
            Talents.boundTarget = nil
            local current, why = getTarget()
            if not current then
                Talents.status:SetText(why)
                return
            end
            if requested and string.lower(current.name) ~=
                string.lower(requested) then
                Talents.status:SetText("Target " .. requested .. " before applying.")
                return
            end
            -- A roster bot's class is part of the intended identity.
            if Talents.presetClass and current.class ~= Talents.presetClass then
                Talents.status:SetText("Target a " .. Talents.presetClass ..
                    " bot before applying.")
                return
            end
            Talents.boundTarget = current
            Talents.targetLabel:SetText("Bot: " .. current.name ..
                "  |  Class: " .. (current.class or "unknown"))
            Talents.status:SetText("Target verified. Preview before Apply.")
        end)

    self.previewButton = button(importPage, "Preview", 22, 18, 110,
        function() submit("preview") end)
    self.applyButton = button(importPage, "Apply talents", 138, 18, 130,
        function()
            local ok, result = Talents:RequestApplyConfirmation()
            Talents.status:SetText(result)
            message(result, not ok)
        end)
    self.cancelButton = button(importPage, "Cancel", 274, 18, 104,
        function()
            input:ClearFocus()
            nameBox:ClearFocus()
            window:Hide()
        end)

    -- Saved page uses five rows per page, not a single endless icon list.
    -- Selecting or loading is read-only; no server command is sent here.
    styledLabel(savedPage, "SAVED BUILDS  |  Select a build to review or manage.",
        22, -21, 606)
    self.savedRows = {}
    local PAGE_SIZE = 5
    self.savedPageIndex = 1
    for i=1,PAGE_SIZE do
        local slot = i
        local rowButton = CreateFrame("Button", nil, savedPage,
            "UIPanelButtonTemplate")
        rowButton:SetSize(610, 31)
        rowButton:SetPoint("TOPLEFT", savedPage, "TOPLEFT",
            24, -60 - (i-1)*40)
        rowButton:SetText("")
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
    self.savedStatus = styledLabel(savedPage,
        "Choose a build. Loading never applies it.", 22, -266, 610)
    self.savedPageCounter = styledLabel(savedPage, "", 239, -302, 190,
        {1, 0.84, 0.42})

    -- Page 3 appears when Set Talents is opened from a bot's menu.
    -- Website data is pinned; filters only affect display, not commands.
    styledLabel(presetPage, "WEBSITE TALENT PRESETS  |  Select a build.",
        22, -18, 610)
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
        local row = CreateFrame("Button", nil, presetPage, "UIPanelButtonTemplate")
        row:SetSize(610, 31)
        row:SetPoint("TOPLEFT", presetPage, "TOPLEFT", 24, -82-(i-1)*37)
        row:SetText("")
        row:SetScript("OnClick", function()
            local list = Talents:ListFilteredWebsitePresets(Talents.presetClass)
            local entry = list[(Talents.presetPageIndex-1)*5+slot]
            if not entry then return end
            Talents.selectedPreset = entry
            Talents:UpdatePresetPage()
        end)
        self.presetRows[i]=row
    end
    self.presetStatus = styledLabel(presetPage,
        "Select a class preset; nothing is applied yet.", 22, -266, 610)
    self.presetCounter = styledLabel(presetPage, "", 239, -302, 190,
        {1, 0.84, 0.42})

    -- Page 4: user-controlled copy/paste backup, with no game commands.
    styledLabel(backupPage, "BACKUP SAVED BUILDS  |  Plain-text NMB1 format",
        22, -18, 610)
    styledLabel(backupPage,
        "Export: Ctrl+A, Ctrl+C. To import, paste an NMB1 backup below.",
        22, -48, 610)
    local backupScroll = CreateFrame("ScrollFrame", nil, backupPage,
        "UIPanelScrollFrameTemplate")
    backupScroll:SetPoint("TOPLEFT", backupPage, "TOPLEFT", 28, -81)
    backupScroll:SetSize(590, 206)
    local backupText = CreateFrame("EditBox", nil, backupScroll)
    backupText:SetPoint("TOPLEFT", backupScroll, "TOPLEFT", 0, 0)
    backupText:SetSize(560, 206)
    backupText:SetMultiLine(true)
    backupText:SetAutoFocus(false)
    backupText:SetMaxLetters(BACKUP_LIMIT)
    if _G.ChatFontNormal then backupText:SetFontObject(_G.ChatFontNormal) end
    backupText:SetText("")
    backupScroll:SetScrollChild(backupText)
    self.backupText = backupText
    local pendingImport
    backupText:SetScript("OnTextChanged", function(box)
        pendingImport = nil
        if box.GetStringHeight then
            box:SetHeight(math.max(206,box:GetStringHeight()+30))
        end
    end)
    self.backupStatus = styledLabel(backupPage,
        "No account data will be replaced without confirmation.",
        22, -301, 610)

    self.showPage = function(page)
        pendingSave = nil
        Talents.pendingDelete = nil
        Talents.pendingApply = nil
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
    self.deleteButton = button(savedPage, "Delete", 355, 17, 130,
        function()
            local chosen = Talents.selectedName
            if not chosen or not Talents:GetSavedCode(chosen) then
                Talents.savedStatus:SetText("Select a saved build first.")
                return
            end
            if Talents.pendingDelete ~= chosen then
                Talents.pendingDelete = chosen
                Talents.savedStatus:SetText("Click Delete again to remove " ..
                    chosen .. ".")
                return
            end
            local _, why = Talents:DeleteBuild(chosen)
            Talents.selectedName = nil
            Talents.pendingDelete = nil
            Talents:UpdateSavedPage()
            Talents.savedStatus:SetText(why)
        end)

    self.backupButton = button(savedPage, "Backup / Import", 499, 17, 137,
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
    self.loadPresetButton = button(presetPage, "Load to import", 167, 17, 210,
        function()
            local entry=Talents.selectedPreset
            if not entry or entry.class ~= Talents.presetClass then
                Talents.presetStatus:SetText("Select a class preset first.")
                return
            end
            input:SetText(entry.code)
            nameBox:SetText(entry.name .. " " .. entry.category)
            Talents.showPage(1)
            Talents.status:SetText("Website preset loaded. Confirm the targeted bot, " ..
                "then Preview or Apply separately.")
        end)
    self.cancelPresetButton = button(presetPage, "Cancel", 404, 17, 120,
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
            local chosen = self.selectedName == entry.name and "> " or "   "
            local label = entry.name
            if #label > 25 then label = label:sub(1,22) .. "..." end
            row:SetText(chosen .. label .. "  |  " ..
                string.upper(entry.class) .. " / " ..
                string.upper(entry.era))
            row:Show()
        else
            row:Hide()
        end
    end
    self.savedPageCounter:SetText("Page " .. self.savedPageIndex ..
        " / " .. maxPages .. "  (" .. #list .. " builds)")
    self.savedStatus:SetText(self.selectedName and
        ("Selected: " .. self.selectedName .. " (not applied)") or
        "Choose a build. Loading never applies it.")
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
            local chosen=self.selectedPreset==entry and "> " or "  "
            local label=entry.category .. " | " .. entry.name ..
                " | " .. entry.role
            if (entry.variant or 1)>1 then
                label=label .. " (variant " .. entry.variant .. ")"
            end
            row:SetText(chosen .. label)
            row:Show()
        else
            row:Hide()
        end
    end
    self.presetCounter:SetText("Page " .. self.presetPageIndex ..
        " / " .. maxPages .. "  (" .. #list .. " builds)")
    self.presetStatus:SetText(self.selectedPreset and
        ("Selected: " .. self.selectedPreset.name .. " (not applied)") or
        "Select a class preset; nothing is applied yet.")
end

-- Open from the bot's existing "Set Talents" menu, not the current target.
-- Actual apply is deliberately locked until Confirm target matches the bot.
function Talents:OpenWebsitePresetsForBot(bot, className, originalSpecsCallback)
    local class=type(className)=="string" and
        className:lower():gsub("[^a-z]", "") or ""
    if #self:ListWebsitePresets(class)==0 then return false end
    if type(bot)~="string" or bot=="" then return false end
    self.requestedBot=bot:match("^[^-]+") or bot
    self.presetClass=class
    self.originalSpecsCallback=originalSpecsCallback
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
    self.requestedBot = target.name
    self.originalSpecsCallback = nil
    self.selectedPreset = nil
    self.presetClass = nil -- Never inherit an earlier roster class.
    local window = self:EnsureWindow()
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
