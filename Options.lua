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

-- The panel is in wowdb.dev's look (Theme.lua and Widgets.lua, shared with the
-- other Forever addons; 2026-11-27). It reads the live options each time it
-- opens; anything refused in combat springs back.
local _, ns = ...;
local W = ns.W;

local category;
local minimapButton;

-- Both from the TOC, so `wowdev bump` keeps the version current here.
local VERSION = C_AddOns.GetAddOnMetadata("FloTotemBar", "Version") or "?";
local WEBSITE = C_AddOns.GetAddOnMetadata("FloTotemBar", "X-Website");

-- Addons can't open a browser: the link opens selected, for Ctrl+C
function FloTotemBar_ShowSupportLink()
	if WEBSITE then
		W.CopyDialog("Help and bug reports", WEBSITE);
	end
end

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

	if category then
		return;
	end

	-- The active talent group's options, which every bar points at
	local function Options()
		return PrimaryBar().globalSettings;
	end
	local isShaman = (FLO_CLASS_NAME == "SHAMAN");

	local panel, host, fit = W.Panel({
		name = "FloTotemBarOptions",
		title = "FloTotemBar",
		sub = "totems, traps and seals on bars with timers  ·  originally by Floraline",
		logo = ICON,
		version = VERSION,
	});
	local COL_W = W.COL_W;

	local function ColumnTop(x)
		local f = CreateFrame("Frame", nil, host);
		f:SetSize(1, 1);
		f:SetPoint("TOPLEFT", host, "TOPLEFT", x, -8);
		return f;
	end
	local left, right = ColumnTop(18), ColumnTop(18 + COL_W + 40);
	local Sync;

	---- Left column: the bars

	local barSec = W.Section(host, left, 0, isShaman and "Bars" or "Bar");
	local position = W.Segment(host, barSec, -12, {
		{ "auto", FLOLIB_POSITIONS.auto }, { "lock", FLOLIB_POSITIONS.lock }, { "unlock", FLOLIB_POSITIONS.unlock },
	}, function(value)
		FloTotemBar_ReadCmd(value);
		Sync();
	end);
	local positionNote = W.Note(host, position.first, -6, isShaman
		and "auto sits above your action bars; the others follow Earth"
		or "auto sits above your action bars; unlocked can be dragged");
	local below = positionNote;

	-- Shaman: how the four bars are arranged, one button per layout
	local layoutButtons = {};
	if isShaman then
		local layoutSec = W.Section(host, positionNote, -18, FLOLIB_LAYOUT);
		local last = layoutSec;
		for i, value in ipairs(FLO_TOTEM_LAYOUTS_ORDER) do
			local b = W.Button(host, FLO_TOTEM_LAYOUTS[value].label, COL_W);
			b:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, i == 1 and -12 or -4);
			b:SetScript("OnClick", function()
				if NotInCombat() then
					FloTotemBar_SetLayout(nil, value);
				end
				Sync();
			end);
			b.value = value;
			layoutButtons[i] = b;
			last = b;
		end
		below = last;
	end

	local scale = W.Slider(host, below, -16, "Scale", 50, 200, 5, 5, "%");
	scale.onChange = function(value)
		FloTotemBar_ReadCmd("scale "..(value / 100));
		Sync();
	end;

	local borders = W.Check(host, scale, -12, FLOLIB_SHOWBORDERS);
	borders.onChange = function(value)
		FloTotemBar_SetBorders(nil, value);
		Sync();
	end;
	local compact = W.Check(host, borders, -6, "Compact bars");
	compact.onChange = function(value)
		FloTotemBar_SetCompact(value);
		Sync();
	end;
	local compactNote = W.Note(host, compact, -4, "one button per bar; hover it for the rest");
	below = compactNote;

	local hideBlizzard;
	if isShaman then
		hideBlizzard = W.Check(host, compactNote, -10, "Hide Blizzard's totem bar");
		hideBlizzard.onChange = function(value)
			FloTotemBar_ReadCmd(value and "hideblizzard" or "showblizzard");
		end;
		below = hideBlizzard;
	end

	local minimap = W.Check(host, below, isShaman and -6 or -10, "Show minimap button");
	minimap.onChange = function(value)
		FloTotemBar_SetMinimapButton(value);
	end;
	local leftEnd = W.Note(host, minimap, -4, "left-click: settings  ·  right-click: lock or unlock");

	---- Right column: one section per bar, the bar menu's Spells

	local spellChecks = {};
	local last, first = right, true;
	for _, k in ipairs(BAR_ORDER) do
		local bar = _G["FloBar"..k];
		if bar and bar.settings and bar.availableSpells then
			last = W.Section(host, last, first and 0 or -18, BAR_TITLES[k]);
			first = false;
			local section = last;
			for i, spell in ipairs(bar.availableSpells) do
				if not spell.notOnForever then  -- TBC spells (data.lua)
					local name = spell.name or C_Spell.GetSpellName(spell.id) or ("Spell "..spell.id);
					local check = W.Check(host, last, last == section and -10 or -6, name);
					check.onChange = function(value)
						local shown = not bar.settings.hiddenSpells[i];
						if shown ~= value and NotInCombat() then
							FloLib_ToggleSpell(nil, bar, i);
						end
						Sync();
					end;
					table.insert(spellChecks, { check = check, bar = bar, idx = i });
					last = check;
				end
			end
		end
	end
	local rightEnd = W.Note(host, last, -6, "spells you learn later appear on the bar by themselves");

	---- Footer: reset, help, the slash command

	-- A hairline under whichever column ends lower (measured on show)
	local foot = host:CreateTexture(nil, "BORDER");
	foot:SetColorTexture(1, 1, 1, 0.06);
	foot:SetHeight(1);
	foot:SetWidth(COL_W * 2 + 40);
	local function PlaceFoot()
		local a, b = leftEnd:GetBottom(), rightEnd:GetBottom();
		local lower = (a and b and a < b) and leftEnd or rightEnd;
		foot:ClearAllPoints();
		foot:SetPoint("TOP", lower, "BOTTOM", 0, -18);
		foot:SetPoint("LEFT", host, "LEFT", 18, 0);
	end
	PlaceFoot();

	local reset = W.Button(host, "Reset all settings", 150);
	reset:SetPoint("TOPLEFT", foot, "BOTTOMLEFT", 0, -12);
	reset:SetScript("OnClick", function(self)
		-- Two clicks: it wipes every setting and reloads the interface
		if self.armed then
			FloLib_ResetAddon("FloTotemBar");
			return;
		end
		self.armed = true;
		self:SetLabel("Click again to reset");
		C_Timer.After(3, function()
			self.armed = nil;
			self:SetLabel("Reset all settings");
		end);
	end);

	local help = W.Button(host, "Help and bug reports", 170);
	help:SetPoint("LEFT", reset, "RIGHT", 10, 0);
	help:SetScript("OnClick", FloTotemBar_ShowSupportLink);
	help:SetShown(WEBSITE ~= nil);

	local hint = W.Note(host, reset, -10, "/ftb for commands  ·  right-click a bar for its menu", COL_W * 2 + 40);

	Sync = function()
		local options = Options();
		position:Set(PrimaryBar().settings.position);
		for _, b in ipairs(layoutButtons) do
			b:SetSelected(b.value == options.barLayout);
		end
		scale:SetValue(math.floor(options.scale * 100 + 0.5));
		borders:SetChecked(options.borders);
		compact:SetChecked(options.compact);
		if hideBlizzard then
			hideBlizzard:SetChecked(FLOTOTEMBAR_OPTIONS.hideBlizzard);
		end
		minimap:SetChecked(not FLOTOTEMBAR_OPTIONS.minimap.hide);
		for _, s in ipairs(spellChecks) do
			s.check:SetChecked(not s.bar.settings.hiddenSpells[s.idx]);
		end
	end;
	panel:SetScript("OnShow", function()
		Sync();
		PlaceFoot();
		fit(hint);
	end);

	category = Settings.RegisterCanvasLayoutCategory(panel, panel.name);
	Settings.RegisterAddOnCategory(category);
end
