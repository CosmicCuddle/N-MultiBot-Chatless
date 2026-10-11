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
        local id, rank = part:match("^([0-9a-z]+)%-([1-9])$")
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

function Talents:SendToTarget(action, text)
    if action ~= "apply" and action ~= "preview" then
        return false, "Unknown talent action."
    end
    local target, reason = getTarget()
    if not target then return false, reason end
    if not self.boundTarget or target.name ~= self.boundTarget.name or
        (self.boundTarget.guid and target.guid ~= self.boundTarget.guid) then
        return false, "Target changed. Reopen Talents for the correct bot."
    end
    local code, invalid = self:ValidateCode(text, target.class)
    if not code then return false, invalid end

    local command = ".naxxbot talents " .. action .. " " .. target.name .. " " .. code
    if #command > MAX_COMMAND_LENGTH then
        return false, "Code is too long for one 3.3.5a chat command. No command sent."
    end
    -- Intentional GM/server command path. This is not a Playerbots whisper,
    -- nor a new generic command-execution/fallback facility.
    SendChatMessage(command, "SAY")
    return true, action == "preview" and
        ("Preview sent for " .. target.name .. ". Check server chat.") or
        ("Apply sent for " .. target.name .. ". Check server chat.")
end

-- These are account-wide addon SavedVariables, deliberately separate
-- from MultiBotDB/AceDB profile settings and from N Talent Calculator saves.
-- WoW loads MultiBotNT1SavedBuilds before addon Lua and writes it on logout.
local MAX_SAVED_BUILDS = 100
local MAX_BUILD_NAME = 40

local function getSavedStore(create)
    if type(MultiBotNT1SavedBuilds) == "table" then
        return MultiBotNT1SavedBuilds
    end
    if create then
        MultiBotNT1SavedBuilds = {}
        return MultiBotNT1SavedBuilds
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
    if class=="warrior" or class=="warlock" then return {} end
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
    styledLabel(importPage, "Apply changes bot talents. Back up the bot first.",
        22, -253, 610, {1, 0.67, 0.44})

    local pendingSave
    nameBox:SetScript("OnTextChanged", function() pendingSave = nil end)
    input:SetScript("OnTextChanged", function() pendingSave = nil end)
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
            Talents.boundTarget = current
            Talents.targetLabel:SetText("Bot: " .. current.name ..
                "  |  Class: " .. (current.class or "unknown"))
            Talents.status:SetText("Target verified. Preview before Apply.")
        end)

    self.previewButton = button(importPage, "Preview", 22, 18, 110,
        function() submit("preview") end)
    self.applyButton = button(importPage, "Apply talents", 138, 18, 130,
        function() submit("apply") end)
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
    -- Website data is a pinned snapshot, not fetched over game chat.
    styledLabel(presetPage, "WEBSITE TALENT PRESETS  |  Choose a build to review.",
        22, -21, 610)
    self.presetRows = {}
    self.presetPageIndex = 1
    for i=1,5 do
        local slot=i
        local row = CreateFrame("Button", nil, presetPage, "UIPanelButtonTemplate")
        row:SetSize(610, 31)
        row:SetPoint("TOPLEFT", presetPage, "TOPLEFT", 24, -60-(i-1)*40)
        row:SetText("")
        row:SetScript("OnClick", function()
            local list = Talents:ListWebsitePresets(Talents.presetClass)
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

    self.showPage = function(page)
        pendingSave = nil
        Talents.pendingDelete = nil
        Talents.page = page
        importPage:Hide()
        savedPage:Hide()
        presetPage:Hide()
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
        function() window.showPage(1) end)
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
            window.showPage(1)
            Talents.status:SetText("Loaded " .. chosen ..
                ". Use Preview or Apply separately.")
            local era, class = code:match("^NT1:([a-z]+):([a-z]+):")
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
            local ok, why = Talents:DeleteBuild(chosen)
            Talents.selectedName = nil
            Talents.pendingDelete = nil
            Talents:UpdateSavedPage()
            Talents.savedStatus:SetText(why)
        end)

    self.savedButton = button(importPage, "Saved builds >", 390, 18, 240,
        function()
            Talents.savedPageIndex = 1
            window.showPage(2)
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
            local count=#Talents:ListWebsitePresets(Talents.presetClass)
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
            window.showPage(1)
            Talents.status:SetText("Website preset loaded. Confirm the targeted bot, " ..
                "then Preview or Apply separately.")
        end)
    self.cancelPresetButton = button(presetPage, "Cancel", 404, 17, 120,
        function() window:Hide() end)

    input:SetScript("OnEnterPressed", function() submit("apply") end)
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
    window.showPage(1)
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
    local list=self:ListWebsitePresets(self.presetClass)
    local maxPages=math.max(1,math.ceil(#list/5))
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
    win.showPage(3)
    win:Show()
    return true
end

function Talents:Open()
    local target, reason = getTarget()
    if not target then message(reason, true); return false end
    self.boundTarget = target
    self.requestedBot = target.name
    self.originalSpecsCallback = nil
    local window = self:EnsureWindow()
    self.targetLabel:SetText("Bot: " .. target.name ..
        "  |  Class: " .. (target.class or "unknown"))
    self.status:SetText("Preview is read-only. Server chat confirms results.")
    self.input:SetText("")
    self.nameBox:SetText("")
    self.selectedName = nil
    self.savedPageIndex = 1
    window.showPage(1)
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
        "\n|cffffaa55Apply changes actual bot talents. Preview is read-only.|r" ..
        "\n\n|cffff0000Left-click: open NT1 build paste box|r" ..
        "\n|cff999999Requires Naxxramas Core BotTalentImport AccessMode 1 or 2.|r"
    )
    b.doLeft = function() Talents:Open() end
    Talents.mainButton = b
    return Talents
end
