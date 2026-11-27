-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------
-- Settings panel (Esc > Options > AddOns > FloTotemBar), minimap button and
-- addon compartment entry (WoW Forever). Not upstream code (added in 1.3.0).
--
-- Every control is a proxy setting: it reads the live options and writes
-- through the slash command handler or the bar menu's own functions, so the
-- three can never disagree. Anything that moves, scales or rebuilds a bar
-- touches secure buttons and is refused in combat.
-------------------------------------------------------------------------------

local category;
local minimapButton;

local MINIMAP_DEFAULT_ANGLE = 160;
local ICON = "Interface\\AddOns\\FloTotemBar\\media\\textures\\tauren_totem_64x64";

-- Same order as FloTotemBar.lua's PRIMARY_BARS: position applies to these,
-- and the shaman's other bars follow FloBarEARTH through the layout
local PRIMARY_BARS = { "TRAP", "EARTH", "SEAL" };
local BAR_ORDER = { "TRAP", "SEAL", "EARTH", "FIRE", "WATER", "AIR" };
local BAR_TITLES = {
	TRAP = "Traps", SEAL = "Seals",
	EARTH = "Earth totems", FIRE = "Fire totems", WATER = "Water totems", AIR = "Air totems",
};

local function Say(msg)
	DEFAULT_CHAT_FRAME:AddMessage("FloTotemBar: "..msg);
end

local function NotInCombat()
	if InCombatLockdown() then
		Say(ERR_NOT_IN_COMBAT or "You can't do that while in combat");
		return false;
	end
	return true;
end

-- The class's primary bar (it has settings only once set up for this class)
local function PrimaryBar()
	for _, k in ipairs(PRIMARY_BARS) do
		local bar = _G["FloBar"..k];
		if bar and bar.settings then
			return bar;
		end
	end
end

-- Open the Settings panel on our page, or close it if it is already open
function FloTotemBar_OpenOptions()

	CloseDropDownMenus();
	if not category then
		-- the addon only sets itself up for shamans, hunters and paladins
		Say("there is nothing to set up on this character.");
		return;
	end
	if SettingsPanel and SettingsPanel:IsShown() then
		HideUIPanel(SettingsPanel);
	else
		Settings.OpenToCategory(category:GetID());
	end
end

-- Unlocked shows the borders and lets the bars be dragged
function FloTotemBar_ToggleLock()

	local bar = PrimaryBar();
	if bar then
		FloTotemBar_ReadCmd(bar.settings.position == "unlock" and "lock" or "unlock");
	end
end

-- Minimap button, and the TOC's AddonCompartmentFunc (addonName, mouseButton)
function FloTotemBar_OnMinimapClick(_, mouseButton)

	if mouseButton == "RightButton" then
		FloTotemBar_ToggleLock();
	else
		FloTotemBar_OpenOptions();
	end
end

local function MinimapTooltip(tooltip)

	local bar = PrimaryBar();
	local unlocked = bar and bar.settings.position == "unlock";
	tooltip:AddLine("FloTotemBar");
	tooltip:AddLine("Left-click: settings", 1, 1, 1);
	tooltip:AddLine(unlocked and "Right-click: lock the bars" or "Right-click: unlock the bars to move them", 1, 1, 1);
	tooltip:AddLine("Drag: move this button", 1, 1, 1);
end

-- Compact bars: saved per talent group, applied to every bar of the class
function FloTotemBar_SetCompact(on)

	if not NotInCombat() then
		return;
	end
	local primary = PrimaryBar();
	if not primary then
		return;
	end
	primary.globalSettings.compact = on or nil;
	for _, k in ipairs(BAR_ORDER) do
		local bar = _G["FloBar"..k];
		if bar and bar.settings then
			FloLib_Setup(bar);
		end
	end
	Say("compact bars "..(on and "on: hover a bar's button for its other spells" or "off"));
end

function FloTotemBar_SetMinimapButton(show)

	FLOTOTEMBAR_OPTIONS.minimap.hide = (not show) or nil;
	if minimapButton then
		FloLib_UpdateMinimapButton(minimapButton);
	end
end

-- Called once from ADDON_LOADED, after the saved options are in place
function FloTotemBar_InitOptions()

	local primary = PrimaryBar();
	if not primary then
		return;
	end

	-- Minimap button. Its settings are per character but not per talent group.
	FLOTOTEMBAR_OPTIONS.minimap = FLOTOTEMBAR_OPTIONS.minimap or { angle = MINIMAP_DEFAULT_ANGLE };
	if not minimapButton then
		minimapButton = FloLib_CreateMinimapButton("FloTotemBarMinimapButton", FLOTOTEMBAR_OPTIONS.minimap,
			ICON, FloTotemBar_OnMinimapClick, MinimapTooltip);
	end

	if category or not (Settings and Settings.RegisterVerticalLayoutCategory) then
		return;
	end
	local layout;
	category, layout = Settings.RegisterVerticalLayoutCategory("FloTotemBar");

	-- The active talent group's options, which every bar points at
	local function Options()
		return PrimaryBar().globalSettings;
	end
	-- Setting names are global to the Settings registry: keep the prefix
	local function Proxy(key, varType, name, default, get, set)
		return Settings.RegisterProxySetting(category, "FloTotemBar_"..key, varType, name, default, get, set);
	end
	local function Header(text)
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text));
	end
	local isShaman = (FLO_CLASS_NAME == "SHAMAN");

	---- Bars

	Header(isShaman and "Bars" or "Bar");

	local function PositionChoices()
		local list = Settings.CreateControlTextContainer();
		list:Add("auto", FLOLIB_POSITIONS.auto);
		list:Add("lock", FLOLIB_POSITIONS.lock);
		list:Add("unlock", FLOLIB_POSITIONS.unlock);
		return list:GetData();
	end
	Settings.CreateDropdown(category, Proxy("position", "string", FLOLIB_POSITION, "auto",
			function() return PrimaryBar().settings.position; end,
			function(value) FloTotemBar_ReadCmd(value); end),
		PositionChoices,
		"Automatic places the bars above your action bars. Unlocked shows their border so you can drag them; Locked keeps them where you left them."
			..(isShaman and " The Fire, Water and Air bars follow the Earth bar." or ""));

	if isShaman then
		local function LayoutChoices()
			local list = Settings.CreateControlTextContainer();
			for _, value in ipairs(FLO_TOTEM_LAYOUTS_ORDER) do
				list:Add(value, FLO_TOTEM_LAYOUTS[value].label);
			end
			return list:GetData();
		end
		Settings.CreateDropdown(category, Proxy("layout", "string", FLOLIB_LAYOUT, "1row",
				function() return Options().barLayout; end,
				function(value) if NotInCombat() then FloTotemBar_SetLayout(nil, value); end end),
			LayoutChoices, "How the four totem bars are arranged around the Earth bar.");
	end

	Settings.CreateCheckbox(category, Proxy("compact", "boolean", "Compact bars", false,
			function() return Options().compact and true or false; end,
			function(value) FloTotemBar_SetCompact(value); end),
		"Show one button per bar: the spell you picked last. Hover it to open the bar's other spells, and click one to cast it and make it the bar's button. Works in combat. /ftb compact also turns it on and off.");

	local scaleOptions = Settings.CreateSliderOptions(0.5, 2, 0.05);
	scaleOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
		return string.format("%d%%", math.floor(value * 100 + 0.5));
	end);
	Settings.CreateSlider(category, Proxy("scale", "number", "Scale", 1,
			function() return Options().scale; end,
			function(value) FloTotemBar_ReadCmd("scale "..value); end),
		scaleOptions, "Size of the bars.");

	Settings.CreateCheckbox(category, Proxy("borders", "boolean", FLOLIB_SHOWBORDERS, true,
			function() return Options().borders and true or false; end,
			function(value) FloTotemBar_SetBorders(nil, value); end),
		"Draw a border and background behind the bars. An unlocked bar always shows one.");

	if isShaman then
		Settings.CreateCheckbox(category, Proxy("hideBlizzard", "boolean", FLOTOTEMBAR_HIDEBLIZZARD, false,
				function() return FLOTOTEMBAR_OPTIONS.hideBlizzard and true or false; end,
				function(value) FloTotemBar_ReadCmd(value and "hideblizzard" or "showblizzard"); end),
			"Hide Blizzard's own totem bar and totem timers. Applied after combat if you change it in combat.");
	end

	Settings.CreateCheckbox(category, Proxy("minimap", "boolean", "Show minimap button", true,
			function() return not FLOTOTEMBAR_OPTIONS.minimap.hide; end,
			function(value) FloTotemBar_SetMinimapButton(value); end),
		"Left-click the button for these settings, right-click to lock or unlock the bars, drag it to move it around the minimap. /ftb minimap also turns it on and off.");

	---- One section per bar: the same switches as Spells in its right-click menu

	for _, k in ipairs(BAR_ORDER) do
		local bar = _G["FloBar"..k];
		if bar and bar.settings and bar.availableSpells then
			Header(BAR_TITLES[k]);
			for i, spell in ipairs(bar.availableSpells) do
				local name = spell.name or C_Spell.GetSpellName(spell.id) or ("Spell "..spell.id);
				Settings.CreateCheckbox(category, Proxy(k.."_spell"..spell.id, "boolean", name, true,
						function() return not bar.settings.hiddenSpells[i]; end,
						function(value)
							local shown = not bar.settings.hiddenSpells[i];
							if shown ~= value and NotInCombat() then
								FloLib_ToggleSpell(nil, bar, i);
							end
						end),
					"Show this spell on the bar. Spells you have not learned yet appear once you learn them.");
			end
		end
	end

	---- Reset

	Header("Reset");
	layout:AddInitializer(CreateSettingsButtonInitializer("Reset all settings", "Reset", function()
		FloLib_ResetAddon("FloTotemBar");
	end, "Put every FloTotemBar setting back to its default. The interface reloads.", true));

	Settings.RegisterAddOnCategory(category);
end
