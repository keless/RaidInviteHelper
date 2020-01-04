
local _, core = ...;
-- /console scriptErrors 1
local EZPZ = core.EZPZ


-- CONSTANTS
local windowTitle = "Raid Invite Helper"
local windowW = 480
local windowH = 480
local contentW = windowW - 60
local contentH = 500
local lineItemH = 24

-- RIH Model Data --
local RIH_RaidInvitePanels = {}  --each contains a 'content' frame with the scrollable content in them

CurrentRoster = {}

-- TEST DATA --
-- roles: TM-tank, H-healer, M-melee dps, R-ranged dps --
local TEST_DATA = { {name = "Sundercatz", class = "WARRIOR", role = "T"},
--                    {name = "Sherman", class = "PALADIN", role = "T"},
--                    {name = "Dieform", class = "DRUID", role = "T"}, 
--                    {name = "Loquilla", class = "ROGUE", role = "M"},
--                    {name = "Fippletrenix", class = "MAGE", role = "R"},
                    {name = "Totensie"},
                    {name = "Jaegerwolf", class = "HUNTER", role = "R"},
                    {name = "Kels", class = "PALADIN", role = "H"},
                    {name = "Skullstepper", class = "WARRIOR", role = "M"},
                    {name = "Dieinafire", class = "WARLOCK", role = "R"},
--                    {name = "Diedrisin", class = "PRIEST", role = "H"},
                    {name = "Auntflow", class = "WARLOCK", role = "R"},
                    {name = "Buttons", class = "WARRIOR", role = "M"},
                    {name = "Ribbuku", class = "HUNTER", role = "R"},
                    {name = "Towerpwr", class = "DRUID", role = "R"},
                    {name = "Pushycat", class = "DRUID", role = "M"},
                    {name = "Morkeless", class = "MAGE", role = "R"},
                    {name = "Mazing", class = "MAGE", role = "R"},
                    {name = "Resub", class = "PRIEST", role = "H"},
                };

function RIH_GetCurrentData()
    return CurrentRoster
end

function RIH_SetCurrentData(rosterData)
    CurrentRoster = rosterData
end

function RIH_UseTestData()
    RIH_SetCurrentData(TEST_DATA)
end

local RIH_InviteWindow = nil
function RIH_ToggleRaidInviteWindow()
    if RIH_InviteWindow == nil then
        RIH_InviteWindow = RIH_CreateRaidInviteWindow()
    end
    RIH_InviteWindow:SetShown(not RIH_InviteWindow:IsShown())
end

local function RIH_HandleTabClick(self)
    local parentWindow = self:GetParent()
    PanelTemplates_SetTab(parentWindow, self:GetID())

	local scrollChild = parentWindow.scrollFrame:GetScrollChild();
	if (scrollChild) then
		scrollChild:Hide();
	end
	
	parentWindow.scrollFrame:SetScrollChild(self.content);
	self.content:Show();
end

local function RIH_SortByName()
    local roster = RIH_GetCurrentData()

    table.sort(roster, function (a, b)
        return a.name < b.name
    end)

    RIH_SetCurrentData(roster)
    RIH_UpdateFromData(roster)
end

local CLASS_SORT_VALUE = {  ["UNKNOWN"] = 0,
                            ["HUNTER"] = 1, 
                            ["MAGE"] = 2,
                            ["PRIEST"] = 3, 
                            ["ROGUE"] = 4, 
                            ["WARRIOR"] = 5, 
                            ["WARLOCK"] = 6, 
                            ["SHAMAN"] = 7, 
                            ["PALADIN"] = 8,
                            ["DRUID"] = 9 };
local function RIH_SortByRole()
    local roster = RIH_GetCurrentData()
    table.sort(roster, function (a, b)
        local cA = a.class;
        if cA == nil then 
            cA = "UNKNOWN"
        end
        local cB = b.class;
        if cB == nil then 
            cB = "UNKNOWN"
        end

        local r1 = a.role
        if r1 == nil then 
            r1 = RIH_GetDefaultRoleForClass(cA)
        end
        local r2 = b.role
        if r2 == nil then 
            r2 = RIH_GetDefaultRoleForClass(cB)
        end

        local c1 = CLASS_SORT_VALUE[cA]
        local c2 = CLASS_SORT_VALUE[cB]

        if r1 == r2 then 
            return c1 > c2
        else 
            return r1 > r2
        end
    end)

    RIH_SetCurrentData(roster)
    RIH_UpdateFromData(roster)
end

local function RIH_GetDefaultRoleForClass(class)
    if class == "WARRIOR" then
        return "T"
    end
    if class == "PRIEST" then
        return "H"
    end
    if class == "MAGE" or class == "WARLOCK" or class == "HUNTER" then
        return "R"
    end
    if class == "PALADIN" then
        return "H"
    end
    return "M"
end

local RIH_InitialToRole = {
    ["M"] = "Melee",
    ["R"] = "Ranged",
    ["H"] = "Healer",
    ["T"] = "Tank",
    ["?"] = "Unknown"
}

local function RIH_RoleToInitial(roleStr)
    if roleStr == "tank" then
        return "T"
    elseif roleStr == "healer" then
        return "H"
    elseif roleStr == "ranged" then
        return "R"
    elseif roleStr == "melee" then
        return "M"
    else
        return "?"
    end
end


local function RIH_isValidClassName(className)
    if className == "WARRIOR" or className == "SHAMAN" or className == "DRUID" or className == "MAGE" or className == "PRIEST" or className == "WARLOCK" or className == "ROGUE" or className == "HUNTER" or className == "PALADIN" then
        return true
    end
    return false
end

-- return class for character if found, otherwise nil
-- this is a little expensive, O(n) where n = 1 + 5 + 40 + guild size
local function RIH_FindClassForCharacterInPartyRaidOrGuild(charName)
    charName = charName:lower()
    if charName == GetUnitName("player"):lower() then
        local _,playerClass,_ = UnitClass("player")
        return playerClass
    end

    for i = 1, MAX_PARTY_MEMBERS do
        local partyNname = GetUnitName("party" .. i, false)
        if partyNname ~= nil and charName == partyNname:lower() then
            local _,partyClass,_ = UnitClass("party" .. i)
            return partyClass
        end
    end

    for i = 1, MAX_RAID_MEMBERS do
        local raidNname = GetUnitName("raid" .. i, false)
        if raidNname ~= nil and charName == raidNname:lower() then
            local _,raidClass,_ = UnitClass("raid" .. i)
            return raidClass
        end
    end

    local numGuildMembers,_,_ = GetNumGuildMembers()
    for i = 1, numGuildMembers do
        local guildieName,_,_,_,guildieClass,_,_,_ = GetGuildRosterInfo(i)
         --remove the server name postfix  ie:  "Somebody-Someserver" -> "Somebody"
        guildieName = string.sub(guildieName, 1, string.find(guildieName, "-") - 1)
        if guildieName ~= nil and charName == guildieName:lower() then
            return guildieClass:upper()
        end
    end

    return nil
end

function RIH_UpdateUnknowns(shouldRefresh)
    local data = RIH_GetCurrentData()
    local updateMade = false
    for i = 1, table.getn(data) do
        if not RIH_isValidClassName(data[i].class) then
            -- check to see if in party/raid/guild
            local className = RIH_FindClassForCharacterInPartyRaidOrGuild(data[i].name)
            if className ~= nil then
                data[i].class = className
                updateMade = true
            end
        end

        if RIH_isValidClassName(data[i].class) then
            if data[i].role == nil or data[i].role == "UNKNOWN" then
                if data[i].class == "MAGE" or data[i].class == "WARLOCK" or data[i].class == "HUNTER" then
                    data[i].role = RIH_RoleToInitial("ranged")
                    updateMade = true
                elseif data[i].class == "ROGUE" then
                    data[i].role = RIH_RoleToInitial("melee")
                    updateMade = true
                end
            end
        end
    end

    if updateMade and shouldRefresh then
        RIH_SetCurrentData(data)
        -- refresh ui
        RIH_UpdateFromData(RIH_GetCurrentData())
    end
end

local function RIH_ClearDialog(window)
    if window.dialog ~= nil then
        window.dialog:Hide()
        window.dialog:SetParent(nil)
        window.dialog = nil
    end
end

local function RIH_PresentConfirmationDialog(window, title, message, cbFunc)
    RIH_ClearDialog(window)

    if window.dialog == nil  then
        local dialogW = 200
        local dialogH = 100
        local dialog = CreateFrame("Frame", "ConfirmDialog", window, "BasicFrameTemplateWithInset")
        dialog:SetFrameStrata("DIALOG")

        dialog:SetSize(dialogW, dialogH)
        dialog:SetPoint("TOP", window, "TOP", 0, -20)
        
        dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        dialog.title:SetPoint("LEFT", dialog.TitleBg, "LEFT", 5, 0)
        dialog.title:SetText(title)

        -- Message label
        dialog.lblMessage = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dialog.lblMessage:SetPoint("TOP", dialog, "TOP", 0, -32)
        dialog.lblMessage:SetText(message)

        -- okay button
        dialog.btnOkay = EZPZ:CreateButtonSmall(dialog, 80, 20, "OK", function (self)
            local diag = self:GetParent()
            cbFunc()
            diag:Hide()
        end)
        dialog.btnOkay:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -8, 8)

        dialog.btnCancel = EZPZ:CreateButtonSmall(dialog, 80, 20, "Cancel", function (self)
            local diag = self:GetParent()
            diag:Hide()
        end)
        dialog.btnCancel:SetPoint("RIGHT", dialog.btnOkay, "LEFT", -20, 0)

        window.dialog = dialog
        window.dialog:Hide()
    end

    window.dialog:Show()
end

local function RIH_PresentRosterAddDialog(window)
    RIH_ClearDialog(window)

    if window.dialog == nil  then
        local dialogW = 200
        local dialogH = 100
        local dialog = CreateFrame("Frame", "RosterAddDialog", window, "BasicFrameTemplateWithInset")
        dialog:SetFrameStrata("DIALOG")

        dialog:SetSize(dialogW, dialogH)
        dialog:SetPoint("TOP", window, "TOP", 0, -20)
        
        dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        dialog.title:SetPoint("LEFT", dialog.TitleBg, "LEFT", 5, 0)
        dialog.title:SetText("Add Roster Entry")

        -- name input label
        dialog.lblName = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dialog.lblName:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -32)
        dialog.lblName:SetText("Name:")

        -- name input field
        dialog.inputText = CreateFrame("EDITBOX", nil, dialog, "InputBoxTemplate")
        dialog.inputText:SetSize(180, 30)
        dialog.inputText:SetPoint("TOP", dialog, "TOP", 0, -40)
        dialog.inputText:SetFontObject(GameFontNormal)

        -- okay button
        dialog.btnOkay = EZPZ:CreateButtonSmall(dialog, 80, 20, "Add Entry", function (self)
            local diag = self:GetParent()

            local entryName = diag.inputText:GetText()
            entryName = string.sub(entryName, 1, 1):upper() .. string.sub(entryName, 2, -1):lower()

            if entryName ~= nil and entryName ~= "" then
                local data = RIH_GetCurrentData()
                local entry = { name = entryName }
                local alreadyExists = false
                for i = 1, table.getn(data) do
                    if data[i].name == entryName then
                        alreadyExists = true
                        break
                    end
                end

                if not alreadyExists then
                    table.insert(data, entry)
                    RIH_SetCurrentData(data)

                    diag:Hide()
                    --update UI

                    RIH_UpdateUnknowns(false)
                    RIH_UpdateFromData(RIH_GetCurrentData())
                else
                    print("entry " .. entryName .. " already exists")
                end
            end
            
        end)
        dialog.btnOkay:SetPoint("TOP", dialog.inputText, "BOTTOM", 0, 4)

        window.dialog = dialog
        window.dialog:Hide()
    end

    window.dialog:Show()
end

local function RIH_IngestFromSpreadsheet(inputText, shouldOverwrite)
    if inputText:match("select all") or inputText == nil or inputText == "" then
        print("default text still present or no text to import, ignoring import button")
        return
    end

    local lines = {}
    for s in inputText:gmatch("[^\r\n]+") do
        table.insert(lines, s)
    end

    local data = {}
    while true do
        local line = table.remove(lines, 1)
        if line == nil then break end

        local tokens = {}
        for token in line:gmatch("%S+") do 
            table.insert(tokens, token) 
        end

        local nameToken = table.remove(tokens, 1)
        if nameToken == nil then break end
        
        local token2 = table.remove(tokens, 1)
        if token2 ~= nil then
            token2 = token2:lower()
        end
        
        local token3 = table.remove(tokens, 1)
        if token3 ~= nil then
            token3 = token3:lower()
        end

        local class = nil
        local role = nil

        if token2 == "healer" or token2 == "tank" or token2 == "melee" or token2 == "ranged" then
            role = RIH_RoleToInitial(token2)
        elseif token2 ~= nil and RIH_isValidClassName(token2:upper()) then
            class = token2:upper()
        end

        if token3 == "healer" or token3 == "tank" or token3 == "melee" or token3 == "ranged" then
            role = RIH_RoleToInitial(token3)
        elseif token3 ~= nil and RIH_isValidClassName(token3:upper()) then
            class = token3:upper()
        end

        if class == nil then
            class = "UNKNOWN"
        end

        if role == nil then
            role = "UNKNOWN"
        end

        --format name
        nameToken = string.sub(nameToken, 1, 1):upper() .. string.sub(nameToken, 2, -1):lower()

        -- create roster entries
        local entry = { name = nameToken, class = class, role = role}

        -- TODO: ensure uniqueness
        table.insert(data, entry)
    end

    if shouldOverwrite then
        RIH_SetCurrentData(data)
    else
        local currData = RIH_GetCurrentData()
        for i = 1, table.getn(currData) do
            --add to data if not duplicate
            local duplicate = false
            for d = 1, table.getn(data) do
                if data[d].name == currData[i].name then
                    duplicate = true
                    break
                end
            end

            if not duplicate then
                table.insert(data, currData[i])
            end
        end
        RIH_SetCurrentData(data)
    end

    -- check to see if we can fill in unknown class/role values
    RIH_UpdateUnknowns(false)
    
    RIH_UpdateFromData(data)
    if table.getn(data) == 0 then
        RIH_HandleTabClick(RIH_InviteWindow.inviteWindowTabs[3]) -- go to import tab
    else
        RIH_HandleTabClick(RIH_InviteWindow.inviteWindowTabs[1]) -- go to roster tab
    end
end

function RIH_SetRoleForCharacter(role, characterName)
    -- find character in roster
    local roster = RIH_GetCurrentData()
    for i = 1, table.getn(roster) do
        if roster[i].name == characterName then
            roster[i].role = role
            -- refresh ui
            RIH_UpdateFromData(RIH_GetCurrentData())
            return
        end
    end
end

-- apply new role from dropdown menu selection
function RIH_RoleSelect_Menu(frame, level, menuList)
    local info = UIDropDownMenu_CreateInfo()

    local character = frame.character

    for i = 1, table.getn(frame.roleOptions) do
        local roleOpt = frame.roleOptions[i]
        if roleOpt == "Tank" then
            info.text, info.checked = "Tank", character.role == "T"
            info.func = function () RIH_SetRoleForCharacter("T", character.name) end
            UIDropDownMenu_AddButton(info)
        elseif roleOpt == "Healer" then
            info.text, info.checked = "Healer", character.role == "H"
            info.func = function () RIH_SetRoleForCharacter("H", character.name) end
            UIDropDownMenu_AddButton(info)
        elseif roleOpt == "Ranged" then
            info.text, info.checked = "Ranged", character.role == "R"
            info.func = function () RIH_SetRoleForCharacter("R", character.name) end
            UIDropDownMenu_AddButton(info)
        elseif roleOpt == "Melee" then
            info.text, info.checked = "Melee", character.role == "M"
            info.func = function () RIH_SetRoleForCharacter("M", character.name) end
            UIDropDownMenu_AddButton(info)
        end
    end
end

local function RIH_OnRoleIconClicked(self)
    local rosterItem = self.rosterItem
    local characterName = rosterItem.character.name
    local className = rosterItem.character.class
    local roleName = rosterItem.character.role

    if className == "MAGE" or className == "WARLOCK" or className == "HUNTER" or className == "ROGUE" then
        -- these classes only have one possible role, do not create a dropdown
        return
    end

    -- create dropdown menu
    local roleOptions = {}
    if className == "DRUID" then
        roleOptions = { "Tank", "Healer", "Melee", "Ranged" }
    elseif className == "PRIEST" then
        roleOptions = { "Healer", "Ranged" }
    elseif className == "WARRIOR" then
        roleOptions = { "Tank", "Melee" }
    elseif className == "PALADIN" then
        roleOptions = { "Tank", "Healer", "Melee" }
    end

    local dropDown = CreateFrame("Frame", "RoleDropDown", self, "UIDropDownMenuTemplate")
    dropDown.character = rosterItem.character
    dropDown.roleOptions = roleOptions
    dropDown:SetPoint("CENTER")
    UIDropDownMenu_SetWidth(dropDown, 4) -- Use in place of dropDown:SetWidth
    UIDropDownMenu_Initialize(dropDown, RIH_RoleSelect_Menu, "MENU")

    ToggleDropDownMenu(1, nil, dropDown, "cursor", 3, -3)
end

-- MAIL START --
function RIH_ScanMailForInvites()
    CheckInbox()
    print("checking inbox ...")
    CallWithDelay(1.5, RIH_ParseMailForInvites)
end

function RIH_ParseMailForInvites()
    print("scanning " .. GetInboxNumItems() .. " mail items for raid invite requests...")
    local requestedInvites = {}
    for i = 1, GetInboxNumItems() do 
        local _,_,sender,subject = GetInboxHeaderInfo(i)
        print("scan mailbox item " .. i .. " " .. sender .. " , " .. subject)
        if string.find(subject, "invite") then
            print("  found " .. sender)
            table.insert(requestedInvites, sender)
        end
        --process invite email GetInboxText(i) + DeleteInboxItem(i)- 
    end

    --add new invites to roster data, after removing duplicates
    local joined = {}
    local uniqueNames = {}
    for i = 1, table.getn(requestedInvites) do
        local data = RIH_GetCurrentData()
        -- ensure unique (o^2 == bad programmer)
        local alreadyExists = false
        for d = 1, table.getn(data) do
            if data[d].name == requestedInvites[i] then
                alreadyExists = true
            end
        end

        if not alreadyExists then

        end
    end
end
-- MAIL END --

local function RIH_SetRemovedFlag(isRemoved, charName)
    local data = RIH_GetCurrentData()
    for i = 1, table.getn(data) do
        if data[i].name == charName then
            print("remove " .. charName)
            data[i].removed = isRemoved

            --trigger UI refresh
            RIH_UpdateFromData(RIH_GetCurrentData())
            return
        end
    end
end

local function RIH_IsInRaidOrGroup(name)
    if name == GetUnitName("player") then
        return true
    end

    for i = 1, MAX_RAID_MEMBERS do
        local raidNname = GetUnitName("raid" .. i, false)
        if name == raidNname then
            return true
        end
    end

    for i = 1, MAX_PARTY_MEMBERS do
        local partyNname = GetUnitName("party" .. i, false)
        if name == partyNname then
            return true
        end
    end

    return false
end

local function RIH_OnBtnInvite(btn)
    local item = btn:GetParent()
    local inviteName = item.character.name
    InviteUnit(inviteName)
end

local INVITE_ALL_INDEX = 1
local function RIH_InviteAllStep()
    local roster = RIH_GetCurrentData()

    -- skip if removed is true
    local char = roster[INVITE_ALL_INDEX]
    if not char.removed then
        print("inviting " .. char.name .. "...")
        InviteUnit(char.name)
    end

    INVITE_ALL_INDEX = INVITE_ALL_INDEX + 1
    if INVITE_ALL_INDEX <= table.getn(roster) then
        C_Timer.After(0.1, function() RIH_InviteAllStep() end)
    end
end

local function RIH_InviteAll()
    -- start inviting the whole list
    INVITE_ALL_INDEX = 1
    C_Timer.After(0.1, function() RIH_InviteAllStep() end)
end

local function RIH_OnBtnRemove(btn)
    local removeName = btn:GetParent().character.name
    RIH_SetRemovedFlag(true, removeName)
end

local function RIH_OnBtnRestore(btn)
    local removeName = btn:GetParent().character.name
    RIH_SetRemovedFlag(false, removeName)
end

local function _baseLineItem(parent, character)
    local size = lineItemH

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(contentW, size)
    --frame:SetClipsChildren(true)

    frame.character = character

    frame.bg = frame:CreateTexture(nil, "ARTWORK")
    frame.bg:SetAllPoints(frame)
    --frame.bg:SetColorTexture(0.2, 0.6, 0, 0.4)
    if character.class == "UNKNOWN" or character.class == nil or character.class == "" then
        frame.bg:SetColorTexture(0.5, 0.5, 0.5, 0.4)
    else
        local cc = RAID_CLASS_COLORS[character.class]
        if cc ~= nil then
            frame.bg:SetColorTexture(cc.r, cc.g, cc.b, 0.4)
        end
    end

    local iconMargin = 4
    frame.icoClass = EZPZ:CreateClassIcon(frame, size - (iconMargin*2), size - (iconMargin*2), character.class)
    frame.icoClass:SetPoint("LEFT", frame, "LEFT", iconMargin, 0)

    local isHunter = character.class == "HUNTER"
    frame.icoRole = EZPZ:CreateRoleIcon(frame, size - (iconMargin*2), size - (iconMargin*2), character.role, isHunter, RIH_OnRoleIconClicked)
    frame.icoRole:SetPoint("LEFT", frame.icoClass, "RIGHT", 2, 0)

    frame.lblName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.lblName:SetText(character.name)
    frame.lblName:SetPoint("LEFT", frame.icoRole, "RIGHT", iconMargin, 0)

    return frame
end

local function RIH_CreateInviteLineItem(parent, character)
    local size = lineItemH

    local frame = _baseLineItem(parent, character)
    
    local buttonMargin = 4
    frame.invite = EZPZ:CreateButtonSmall(frame, 80, size - buttonMargin, "Invite", RIH_OnBtnInvite)
    frame.remove = EZPZ:CreateButtonSmall(frame, size, size - buttonMargin, "X", RIH_OnBtnRemove)
    frame.remove:SetPoint("RIGHT", frame, "RIGHT", -buttonMargin, 0)
    frame.invite:SetPoint("RIGHT", frame.remove, "LEFT", -buttonMargin, 0)

    if RIH_IsInRaidOrGroup(character.name) then
        frame.invite:Disable()
    end

    return frame
end

local function RIH_CreateRaidLineItem(parent, character)
    local size = lineItemH

    local frame = _baseLineItem(parent, character)

    local buttonMargin = 4
    frame.remove = EZPZ:CreateButtonSmall(frame, size, size - buttonMargin, "X", RIH_OnBtnRemove)
    frame.remove:SetPoint("RIGHT", frame, "RIGHT", -buttonMargin, 0)

    return frame
end

local function RIH_CreateRemovedLineItem(parent, character)
    local size = lineItemH

    local frame = _baseLineItem(parent, character)

    local buttonMargin = 4
    frame.remove = EZPZ:CreateButtonSmall(frame, 80, size - buttonMargin, "Restore", RIH_OnBtnRestore)
    frame.remove:SetPoint("RIGHT", frame, "RIGHT", -buttonMargin, 0)

    return frame
end

local function RIH_ClearList(contentFrame)
    for i = 1, table.getn(contentFrame.items) do
        contentFrame.items[i]:Hide()
        contentFrame.items[i]:SetParent(nil)
    end
    contentFrame.items = {} -- reset list
end


local function RIH_PopulateInviteList(contentFrame, data)
    RIH_ClearList(contentFrame)

    for i = 1, table.getn(data) do
        local lineItem = RIH_CreateInviteLineItem(contentFrame, data[i])
        if i == 1 then
            lineItem:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 5, -5)
        else
            lineItem:SetPoint("TOP", contentFrame.items[i-1], "BOTTOM", 0, -2)
        end

        table.insert(contentFrame.items,lineItem)
    end
end

local function RIH_PopulateRaidList(contentFrame, data)
    RIH_ClearList(contentFrame)
    for i = 1, table.getn(data) do
        local lineItem = RIH_CreateRaidLineItem(contentFrame, data[i])
        if i == 1 then
            lineItem:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 5, -5)
        else
            lineItem:SetPoint("TOP", contentFrame.items[i-1], "BOTTOM", 0, -2)
        end

        table.insert(contentFrame.items,lineItem)
    end
end

local function RIH_PopulateRemovedList(contentFrame, data)
    RIH_ClearList(contentFrame)

    for i = 1, table.getn(data) do
        local lineItem = RIH_CreateRemovedLineItem(contentFrame, data[i])
        if i == 1 then
            lineItem:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 5, -5)
        else
            lineItem:SetPoint("TOP", contentFrame.items[i-1], "BOTTOM", 0, -2)
        end

        table.insert(contentFrame.items,lineItem)
    end
end

local function RIH_PopulateData(contentFrame, data)
    contentFrame.items = data

    if contentFrame.textArea == nil then
        contentFrame.textArea = CreateFrame("EDITBOX", nil, contentFrame)
        contentFrame.textArea:SetPoint("TOPLEFT", contentFrame, "TOPLEFT")
        contentFrame.textArea:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT")
        contentFrame.textArea:SetMultiLine(true)
        contentFrame.textArea:SetMaxLetters(99999)
        contentFrame.textArea:SetFontObject(GameFontNormal)

        contentFrame.textArea:SetText(var_dump(data))
    end
end

local function RIH_PopulateImport(contentFrame)
    if contentFrame.textArea == nil then
        contentFrame.textArea = CreateFrame("EDITBOX", nil, contentFrame)
        contentFrame.textArea:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0 , -30)
        contentFrame.textArea:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT")
        contentFrame.textArea:SetMultiLine(true)
        contentFrame.textArea:SetMaxLetters(99999)
        contentFrame.textArea:SetFontObject(GameFontNormal)

        contentFrame.textArea:SetText("select all + paste here")
    end

    if contentFrame.btnImport == nil then
        contentFrame.btnImport = EZPZ:CreateButtonSmall(contentFrame, 140, 20, "Import", function (self)
            local text = contentFrame.textArea:GetText()
            local shouldOverwrite = self.btnOverwrite:GetChecked()
            RIH_IngestFromSpreadsheet(text, shouldOverwrite)
        end)
        contentFrame.btnImport:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, 0)

        contentFrame.btnOverwrite = EZPZ:CreateCheckButton(contentFrame, "Overwrite All")
        contentFrame.btnOverwrite:SetPoint("LEFT", contentFrame.btnImport, "RIGHT", 4, 0)
        contentFrame.btnOverwrite:SetChecked(true)

        contentFrame.btnImport.btnOverwrite = contentFrame.btnOverwrite

        contentFrame.btnExport = EZPZ:CreateButtonSmall(contentFrame, 140, 20, "EXPORT", function (self)
            local data = RIH_GetCurrentData()
            local str_data = ""
            for i=1,table.getn(data) do
                if i ~= 1 then
                    str_data = str_data .. "\n"
                end
                str_data = str_data .. data[i].name
                if data[i].class ~= nil then
                    str_data = str_data .. " " .. string.sub(data[i].class, 1, 1):upper() .. string.sub(data[i].class, 2, -1):lower()
                end
                if data[i].role ~= nil then
                    local role = RIH_InitialToRole[data[i].role]
                    str_data = str_data .. " " .. string.sub(role, 1, 1):upper() .. string.sub(role, 2, -1):lower()
                end
            end

            self.textArea:SetText( str_data )
        end)
        contentFrame.btnExport:SetPoint("LEFT", contentFrame.btnOverwrite, "RIGHT", 70, 0)
        contentFrame.btnExport.textArea =  contentFrame.textArea
    end

end

local tabNames = { "Roster", "Removed", "Import" }
local function RIH_CreateRaidInviteWindowTabs(parentWindow, contentW, contentH)
    parentWindow.numTabs = table.getn(tabNames)
    parentWindow.inviteWindowTabs = {}

    local frameName = parentWindow:GetName();
    local contents = {}
    local prevTab = nil

    for i = 1, parentWindow.numTabs do
        local tab = CreateFrame("Button", frameName .. "Tab" .. i, parentWindow, "CharacterFrameTabButtonTemplate")
        tab:SetID(i)
        tab:SetText(tabNames[i])
        tab:SetScript("OnClick", RIH_HandleTabClick);

        tab.content = CreateFrame("Frame", nil, parentWindow.scrollFrame)
		tab.content:SetSize(contentW, contentH)
        tab.content:Hide()

        tab.content.items = {}

        table.insert(contents, tab.content)
        table.insert(parentWindow.inviteWindowTabs, tab)

        if (i == 1) then
			tab:SetPoint("TOPLEFT", parentWindow, "BOTTOMLEFT", 5, 2);
		else
			tab:SetPoint("TOPLEFT", prevTab, "TOPRIGHT", -10, 0);
        end
        prevTab = tab
    end


    local data = RIH_GetCurrentData()
    if table.getn(data) == 0 then
        RIH_HandleTabClick(RIH_InviteWindow.inviteWindowTabs[3]) -- go to import tab
    else
        RIH_HandleTabClick(RIH_InviteWindow.inviteWindowTabs[1]) -- go to roster tab
    end

    return contents
end

local function RIH_GetEntryNamed(name, data)
    for i = 1, table.getn(data) do
        if data[i].name == name then
            return data[i]
        end
    end
    return nil
end

local function RIH_FindClassNameInGroupOrRaid(charName)
    local class = nil
    if charName == UnitName("player") then
        local _,playerUnitClass,_ = UnitClass("player")
        class = playerUnitClass
    end

    if class == nil then
        for r = 1, MAX_RAID_MEMBERS do
            if GetUnitName("raid" .. r) == charName then
                local raidN = "raid" .. r
                local _,raidUnitClass,_ = UnitClass(raidN)
                class = raidUnitClass
                break
            end
        end
    end

    if class == nil then
        for p = 1, MAX_PARTY_MEMBERS do
            if GetUnitName("party" .. p) == charName then
                local partyN = "party" .. p
                local _,partyUnitClass,_ = UnitClass(partyN)
                class = partyUnitClass
                break
            end
        end
    end

    return class
end

function RIH_UpdateFromData(data)
    -- go through data entries and update UI tabs 
    local currentPlayer, realm = UnitName("player")

    --1) get list of people currently in party/raid
    local raidMembers = {}
    for i = 1, MAX_RAID_MEMBERS do
        local name = GetUnitName("raid" .. i) --GetRaidRosterInfo(i)
        if name ~= nil then
            table.insert(raidMembers, name)
        end
    end

    if table.getn(raidMembers) == 0 then
        -- just use current party members
        for i = 1, MAX_PARTY_MEMBERS do
            local name = GetUnitName("party" .. i)
            if name ~= nil then
                table.insert(raidMembers, name)
            end
        end
    end

    table.insert(raidMembers, currentPlayer)

    local raidDatas = {}
    for i = 1, table.getn(raidMembers) do
        --print("process raid member " .. raidMembers[i])
        -- find the raid member in data table, or create a new entry
        local entry = RIH_GetEntryNamed(raidMembers[i], data)
        if entry == nil then
            local class = RIH_FindClassNameInGroupOrRaid(raidMembers[i])
            if class ~= nil then
                entry = { name = raidMembers[i], class = class, role = RIH_GetDefaultRoleForClass(class) }
            else
                entry = { name = raidMembers[i] } --unknown class
            end
            
        end
        table.insert(raidDatas, entry)
    end

    local inviteDatas = {}
    local removedDatas = {}
    for i = 1, table.getn(data) do
        if data[i].removed then
            table.insert(removedDatas, data[i])
        else
            table.insert(inviteDatas, data[i])
        end
    end

    --RIH_PopulateRaidList(RIH_RaidInvitePanels[1], raidDatas)
    RIH_PopulateInviteList(RIH_RaidInvitePanels[1], inviteDatas)
    RIH_PopulateRemovedList(RIH_RaidInvitePanels[2], removedDatas)
    RIH_PopulateImport(RIH_RaidInvitePanels[3])

end

function RIH_CreateRaidInviteWindow()
    local window = CreateFrame("Frame", "RaidInviteWindow", UIParent, "BasicFrameTemplateWithInset")
    RIH_InviteWindow = window
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
	window:SetSize(windowW, windowH)
    window:SetPoint("CENTER")
    
	window.title = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
	window.title:SetPoint("LEFT", window.TitleBg, "LEFT", 5, 0);
    window.title:SetText(windowTitle);
    
    -- SORT BUTTONS --
    --[[
    window.sortButtons = EZPZ:CreateRadioButtons(window, 60, 20, {"ABC", "Role", "Raid"})
    window.sortButtons[1]:SetPoint("CENTER", window, "TOP", -60, -50)
    ]]--


    window.sortName = EZPZ:CreateToggleButton(window, 50, 20, "ABC", true, function ()
        RIH_SortByName()
        window.sortRole.ezpzSetToggleValue(not window.sortName.ezpzToggleValue)
    end)
    window.sortRole = EZPZ:CreateToggleButton(window, 50, 20, "Role", false, function ()
        RIH_SortByRole()
        window.sortName.ezpzSetToggleValue(not window.sortRole.ezpzToggleValue)
    end)
    window.sortRole:SetPoint("TOPRIGHT", window, "TOPRIGHT", -10, -30)
    window.sortName:SetPoint("RIGHT", window.sortRole, "LEFT", 2, 0)

    --window.sortName:ezpzSetToggleValue(true)
    --window.sortRole:ezpzSetToggleValue(false)

    -- REFRESH BUTTON --
--[[
    window.refresh = EZPZ:CreateButtonSmall(window, 80, 20, "Refresh", function (self)
        RIH_UpdateFromData(RIH_GetCurrentData())
    end)
    window.refresh:SetPoint("TOPLEFT", window, "TOPLEFT", 10, -30)
]]--
    -- INVITE ALL BUTTON --
    window.btnInviteAll = EZPZ:CreateButtonSmall(window, 80, 20, "Inv All", function (self)
        RIH_InviteAll()
    end)
    window.btnInviteAll:SetPoint("TOPLEFT", window, "TOPLEFT", 10, -30)

    window.btnAdd = EZPZ:CreateButtonSmall(window, 80, 20, "Add", function (self)
        RIH_PresentRosterAddDialog(window)
    end)
    window.btnAdd:SetPoint("LEFT", window.btnInviteAll, "RIGHT", 0, 0)

    --[[
    window.test = EZPZ:CreateButtonSmall(window, 80, 20, "RELOADUI", function (self)
        ReloadUI() -- reload the ui
    end)
    window.test:SetPoint("LEFT", window.btnAdd, "RIGHT", 2, 0)
    --]]--

    window.btnClearAll = EZPZ:CreateButtonSmall(window, 80, 20, "Del All", function (self)
        RIH_PresentConfirmationDialog(window, "Delete All", "Are you sure?", function ()
            print("removing all of roster")
            RIH_SetCurrentData({})
            RIH_UpdateFromData(RIH_GetCurrentData())
        end)
    end)
    window.btnClearAll:SetPoint("LEFT", window.btnAdd, "RIGHT", 2, 0)

    -- SCROLL AREA CONTENT --

    window.scrollFrame = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    window.scrollFrame:SetPoint("TOPLEFT", window, "TOPLEFT", 10, -60)
    window.scrollFrame:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -32, 10)
    --window.scrollFrame:SetClipsChildren(true)

    RIH_RaidInvitePanels = RIH_CreateRaidInviteWindowTabs(window, contentW, contentH)


    --RIH_PopulateInviteList(contentFrames[2], invitedata)
    RIH_UpdateFromData(RIH_GetCurrentData())

    window:Hide()
	return window
end
