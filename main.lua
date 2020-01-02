
local appName, core = ...;

local EZPZ = core.EZPZ

MinimapButtonPos = 45

-- Call this in a mod's initialization to move the minimap button to its saved position (also used in its movement)
-- ** do not call from the mod's OnLoad, VARIABLES_LOADED or later is fine. **
function RIH_MinimapButton_Reposition()
	RIH_MinimapButton:SetPoint("TOPLEFT","Minimap","TOPLEFT",52-(80*cos(MinimapButtonPos)),(80*sin(MinimapButtonPos))-52)
end

-- Only while the button is dragged this is called every frame
function RIH_MinimapButton_DraggingFrame_OnUpdate()

	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()

    local radius = 60
	xpos = xmin-xpos/UIParent:GetScale()+radius -- get coordinates as differences from the center of the minimap
	ypos = ypos/UIParent:GetScale()-ymin-radius

	MinimapButtonPos = math.deg(math.atan2(ypos,xpos)) -- save the degrees we are relative to the minimap center
	RIH_MinimapButton_Reposition() -- move the button
end

-- Put your code that you want on a minimap button click here.  arg1="LeftButton", "RightButton", etc
function RIH_MinimapButton_OnClick()
	RIH_ToggleRaidInviteWindow()
end

SLASH_RAIDINVITEHELPER1 = "/raidinv"
SlashCmdList["RAIDINVITEHELPER"] = function(msg, editbox)
    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

    if cmd == "test" then
        print("Raid Invite Helper - test")
    elseif cmd == "help" or cmd == "?" then
        print("type '/raidinv' to toggle the raid invite window")
    else
        RIH_ToggleRaidInviteWindow()
    end
end


function RIH_onInit(self, event, arg1, ...)
    if event == "ADDON_LOADED" and appName == arg1 then
        print("Raid Invite Helper loaded")
        self:UnregisterEvent("ADDON_LOADED") 
        --RIH_ToggleRaidInviteWindow()
--    elseif event == "MAIL_SHOW" then
--        RIH_ScanMailForInvites()
    elseif event == "VARIABLES_LOADED" then
        RIH_MinimapButton_Reposition()
    elseif event == "GROUP_ROSTER_UPDATE" then
        RIH_UpdateUnknowns(true)
--    elseif event ~= "ADDON_LOADED" then
--        print("evt: " .. event)
    end
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED") -- initialize data
events:RegisterEvent("VARIABLES_LOADED") -- initialize data

--events:RegisterEvent("MAIL_SHOW") -- scan mail for invite requests
events:RegisterEvent("GROUP_ROSTER_UPDATE") -- update raid list
events:SetScript("OnEvent", RIH_onInit);