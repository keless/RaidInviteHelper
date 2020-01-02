-- NOTE: to turn on lua errors:
-- /console scriptErrors 1

--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...;
core.EZPZ = {}; -- add EZPZ to addon namespace

local EZPZ = core.EZPZ
local ezpz_ConfigWindow = nil

--------
-- Utility functions
--------

-- 'fn' a function to call after 'delayS' seconds
function CallWithDelay(delayS, fn)
    C_Timer.After(delayS, fn)
end

--------------------------------------
-- Defaults (usually a database!)
--------------------------------------
local defaults = {
	theme = {
		r = 0, 
		g = 0.8, -- 204/255
		b = 1,
		hex = "00ccff"
	}
}

RAID_CLASS_COLORS = {
    ["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = "ffabd473" },
    ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79, colorStr = "ff9482c9" },
    ["PRIEST"] = { r = 1.0, g = 1.0, b = 1.0, colorStr = "ffffffff" },
    ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, colorStr = "fff58cba" },
    ["MAGE"] = { r = 0.41, g = 0.8, b = 0.94, colorStr = "ff69ccf0" },
    ["ROGUE"] = { r = 1.0, g = 0.96, b = 0.41, colorStr = "fffff569" },
    ["DRUID"] = { r = 1.0, g = 0.49, b = 0.04, colorStr = "ffff7d0a" },
    ["SHAMAN"] = { r = 0.0, g = 0.44, b = 0.87, colorStr = "ff0070de" },
    ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc79c6e" }
}

--------------------------------------
-- Config functions
--------------------------------------
function EZPZ:GetThemeColor()
	local c = defaults.theme;
	return c.r, c.g, c.b, c.hex;
end

-- fn should support (self:widget, btn:strMouseBtn, isDown:bool)
function EZPZ:CreateButtonSmall(parent, x, y, text, fn)
    local button = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    button:SetSize(x, y)
    button:SetText(text)
    button:SetNormalFontObject("GameFontNormalSmall")
	button:SetHighlightFontObject("GameFontHighlightSmall")

	button:SetScript("OnClick", fn)
    return button
end

function EZPZ:CreateToggleButton(parent, x, y, text, startEnabled, fn)
	local button = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
	
	button.ezpzToggleValue = false
	button.ezpzUpdateUIForToggleValue = function ()
		if button.ezpzToggleValue then
			--button:SetButtonState("PUSHED", true)
			button:SetNormalFontObject("GameFontHighlightSmall")
			button:SetHighlightFontObject("GameFontHighlightSmall")
		else
			--button:SetButtonState("NORMAL", false)
			button:SetNormalFontObject("GameFontDisableSmall")
			button:SetHighlightFontObject("GameFontDisableSmall")
		end
	end
	button.ezpzSetToggleValue = function (value)
		button.ezpzToggleValue = value
		button:ezpzUpdateUIForToggleValue()
	end
	button.ezpzToggle = function ()
		button.ezpzToggleValue = not button.ezpzToggleValue
		button:ezpzUpdateUIForToggleValue()
	end

    button:SetSize(x, y)
    button:SetText(text)
    button:SetNormalFontObject("GameFontNormalSmall")
	button:SetHighlightFontObject("GameFontHighlightSmall")
	button:SetScript("OnClick", function (self, button, down)
		self:ezpzToggle()
		fn(self)
	end)

	button:ezpzSetToggleValue(startEnabled)

    return button
end

function EZPZ:CreateRadioButtons(parent, x, y, textArr, fn)
	local radioButtons = {}
	-- for each textArr create a toggle button
	-- then add a function that toggles the others off when one is turned on
	for i = 1, table.getn(textArr) do
		local text = textArr[i]
		local radioButton = EZPZ:CreateToggleButton(parent, x, y, text, false, function (self, button, down)
			local btn = self
			for r = 1, r < table.getn(btn.ezpzRadioSet) do
				if r ~= btn.ezpzRadioSetIdx then
					btn.ezpzRadioSet[i]:ezpzSetToggleValue(false)
				end
			end
			fn(btn)
		end)

		table.insert(radioButtons, radioButton)
		radioButton.ezpzRadioSetIdx = i

		if i > 1 then
			local prevButton = radioButtons[i-1]
			radioButton:SetPoint("CENTER", prevButton, "RIGHT", x/2, 0)
		end
	end

	for i = 1, table.getn(radioButtons) do
		local copyArray = {unpack(radioButtons)} -- copy array
		print("store radioSet of size " .. table.getn(copyArray))
		radioButtons[i].ezpzRadioSet = copyArray
	end

	return radioButtons
end

function EZPZ:CreateCheckButton(parent, text)
    local button = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    button.text:SetText(text)
    return button
end

function EZPZ:CreateSlider(parent, min, max, start)
	local slider = CreateFrame("SLIDER", nil, parent, "OptionsSliderTemplate")
	slider:SetMinMaxValues(min, max)
	slider:SetValue(start)
	slider:SetValueStep(30)
	slider:SetObeyStepOnDrag(true)
	return slider
end

function EZPZ:CreateClassIcon(parent, w, h, className)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(w, h)

    frame.icon = frame:CreateTexture(nil,"CENTER")
    frame.icon:SetAllPoints(frame)

    if className == "UNKNOWN" or className == nil then
        frame.icon:SetTexture("Interface\\MINIMAP\\UI-QuestBlob-MinimapRing") -- empty circle
    else
        frame.icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")

				local coords = CLASS_ICON_TCOORDS[className]
				if coords ~= nil then
					frame.icon:SetTexCoord(unpack(coords))
				end
    end

    return frame
end

-- "M" melee dps, "R" ranged dps, "T" tank, "H" healer
function EZPZ:CreateRoleIcon(parent, w, h, role, isHunter, fn)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(w, h)

    frame.icon = frame:CreateTexture(nil,"CENTER")
    frame.icon:SetAllPoints(frame)

    if role == "H" then
        frame.icon:SetTexture("Interface\\Icons\\spell_holy_healingaura")
    elseif role == "T" then
        frame.icon:SetTexture("Interface\\Icons\\inv_shield_06")
    elseif role == "R" then
        if isHunter then
            frame.icon:SetTexture("Interface\\Icons\\inv_ammo_arrow_02")
        else
            frame.icon:SetTexture("Interface\\Icons\\inv_staff_13")
        end
    elseif role == "M" then
        frame.icon:SetTexture("Interface\\Icons\\Ability_DualWield")
    else
        frame.icon:SetTexture("Interface\\MINIMAP\\UI-QuestBlob-MinimapRing") -- empty circle
    end

    frame.dropButton = CreateFrame("Button", nil, frame)
    frame.dropButton:SetAllPoints(frame)
    frame.dropButton.rosterItem = parent
    frame.dropButton:SetScript("OnClick", fn)

    return frame
end

function EZPZ:ToggleConfig()
	if ezpz_ConfigWindow == nil then
		ezpz_ConfigWindow = EZPZ:CreateConfigMenu()
	end
	ezpz_ConfigWindow:SetShown(not ezpz_ConfigWindow:IsShown());
end

function EZPZ:CreateConfigMenu()
	local windowTitle = "EZPZ Config"

	local window = CreateFrame("Frame", "AuraTrackerConfig", UIParent, "BasicFrameTemplateWithInset");
	window:SetSize(260, 360);
	window:SetPoint("CENTER"); -- Doesn't need to be ("CENTER", UIParent, "CENTER")

	window.title = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
	window.title:SetPoint("LEFT", window.TitleBg, "LEFT", 5, 0);
	window.title:SetText(windowTitle);

	-- Save Button:
    window.saveBtn = EZPZ:CreateButtonSmall(window, 140, 20, "Save")
    window.saveBtn:SetPoint("CENTER", window, "TOP", 0, -70)

    -- Reset Button:
    window.resetBtn = EZPZ:CreateButtonSmall(window, 140, 20, "Reset")
    window.resetBtn:SetPoint("TOP", window.saveBtn, "BOTTOM", 0, -10)

    -- Load Button:
    window.loadBtn = EZPZ:CreateButtonSmall(window, 140, 20, "Load")
	window.loadBtn:SetPoint("TOP", window.resetBtn, "BOTTOM", 0, -10)
	
	window.slider1 = EZPZ:CreateSlider(window, 1, 100, 50)
	window.slider1:SetPoint("TOP", window.loadBtn, "BOTTOM", 0, -20)

    -- Check Button 1:
    window.checkBtn1 = EZPZ:CreateCheckButton(window, "My Check Button!")
    window.checkBtn1:SetPoint("TOPLEFT", window.slider1, "BOTTOMLEFT", -10, -40)

    -- Check Button 2:
    window.checkBtn2 = EZPZ:CreateCheckButton(window, "Another Check Button!")
    window.checkBtn2:SetPoint("TOPLEFT", window.checkBtn1, "BOTTOMLEFT", 0, -10)
    window.checkBtn2:SetChecked(true)

	window:Hide()
	return window
end
