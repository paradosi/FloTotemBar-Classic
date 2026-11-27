-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- Printed in the login banner. NOT read from the TOC -- bump it here AND in
-- both .toc files on every release. This drifted once already (fixed in
-- bc025dd) and FloAspectBar's equivalent drifted for two releases.
local VERSION = "1.6.1"

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------
local _

local SHOW_WELCOME = true;
local FLOTOTEMBAR_OPTIONS_DEFAULT = { [1] = { scale = 1, borders = true, barLayout = "1row", barSettings = {} }, active = 1 };
FLOTOTEMBAR_OPTIONS = FLOTOTEMBAR_OPTIONS_DEFAULT;
local FLOTOTEMBAR_BARSETTINGS_DEFAULT = {
	["SEAL"] = { buttonsOrder = {}, position = "auto", color = { 0.49, 0.49, 0, 0.7 }, hiddenSpells = {} },
	["TRAP"] = { buttonsOrder = {}, position = "auto", color = { 0.49, 0.49, 0, 0.7 }, hiddenSpells = {} },
	["EARTH"] = { buttonsOrder = {}, position = "auto", color = { 0, 0.49, 0, 0.7 }, hiddenSpells = {} },
	["FIRE"] = { buttonsOrder = {}, position = "auto", color = { 0.49, 0, 0, 0.7 }, hiddenSpells = {} },
	["WATER"] = { buttonsOrder = {}, position = "auto", color = { 0, 0.49, 0.49, 0.7 }, hiddenSpells = {} },
	["AIR"] = { buttonsOrder = {}, position = "auto", color = { 0, 0, 0.99, 0.7 }, hiddenSpells = {} },
};
FLO_CLASS_NAME = nil;
local ACTIVE_OPTIONS = FLOTOTEMBAR_OPTIONS[1];

-- Ugly
local changingSpec = true;

-- Set when hiding/showing Blizzard's totem bar had to wait for combat to end
local blizzardBarPending;

-- One talent group is all this addon manages, so this always returns 1. It
-- shadows Blizzard's API of the same name on purpose, so the spec-switching
-- paths below can stay unmodified from upstream.
local GetSpecialization = function()
	return 1
end

-- WoW Forever's main action bar frame (MainMenuBar on the old clients)
local MainMenuBar = MainActionBar;
-- Addons cannot read the combat log on WoW Forever, so a trap or seal timer
-- runs its full length: nothing tells the bar the trap was sprung or the seal
-- ended early. Forever has no GetSpellInfo either; C_Spell returns a table, and
-- this keeps the old return shape.
local GetSpellInfo = function(spell)
	if spell == nil then return; end
	local info = C_Spell.GetSpellInfo(spell);
	if info then
		return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID;
	end
end;

-- The primary bar of each class: lock/unlock/auto apply to these. Shaman
-- FIRE/WATER/AIR follow FloBarEARTH through the layout.
local PRIMARY_BARS = { "TRAP", "EARTH", "SEAL" };

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-- Executed on load, calls general set-up functions
function FloTotemBar_OnLoad(self)

	-- Class-based setup, abort if not supported
	_, FLO_CLASS_NAME = UnitClass("player");
	FLO_CLASS_NAME = strupper(FLO_CLASS_NAME);

	local classSpells = FLO_TOTEM_SPELLS[FLO_CLASS_NAME];

	if classSpells == nil then
		return;
	end

	self.sharedCooldown = true;
	self.masqueGroup = "FloTotemBar";

	local thisName = self:GetName();
	self.totemtype = string.sub(thisName, 7);

	-- Store the spell list for later
	self.availableSpells = classSpells[self.totemtype];
	if self.availableSpells == nil then
		return;
	end

	-- Init the settings variable
	ACTIVE_OPTIONS.barSettings[self.totemtype] = FLOTOTEMBAR_BARSETTINGS_DEFAULT[self.totemtype];

	self.spells = {};
	self.SetupSpell = FloTotemBar_SetupSpell;
	self.OnSetup = FloTotemBar_OnSetup;
	self.menuHooks = { SetPosition = FloTotemBar_SetPosition, SetBorders = FloTotemBar_SetBorders,
		Options = { text = "Options...", func = function() FloTotemBar_OpenOptions(); end } };
	if FLO_CLASS_NAME == "SHAMAN" then
		self.menuHooks.Toggle = {
			text = FLOTOTEMBAR_HIDEBLIZZARD,
			get = function() return FLOTOTEMBAR_OPTIONS.hideBlizzard; end,
			set = function(_, hide) FloTotemBar_ReadCmd(hide and "hideblizzard" or "showblizzard"); end,
		};
	end
	if FLO_CLASS_NAME == "SHAMAN" then
		self.menuHooks.SetLayoutMenu = FloTotemBar_SetLayoutMenu;
		self.slot = _G[self.totemtype.."_TOTEM_SLOT"];
	end
	self:EnableMouse(1);

	if SHOW_WELCOME then
		DEFAULT_CHAT_FRAME:AddMessage( "|cffd78900FloTotemBar v"..VERSION.."|r loaded." );
		SHOW_WELCOME = nil;

		SLASH_FLOTOTEMBAR1 = "/flototembar";
		SLASH_FLOTOTEMBAR2 = "/ftb";
		SlashCmdList["FLOTOTEMBAR"] = FloTotemBar_ReadCmd;

		self:RegisterEvent("ADDON_LOADED");
		self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
		self:RegisterEvent("PLAYER_REGEN_ENABLED");
	end
	self:RegisterEvent("CHARACTER_POINTS_CHANGED");
	self:RegisterEvent("SPELLS_CHANGED");
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN");
	self:RegisterEvent("ACTIONBAR_UPDATE_USABLE");
	self:RegisterEvent("UPDATE_BINDINGS");

	if self.totemtype ~= "CALL" then
		self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");
		self:RegisterEvent("PLAYER_DEAD");

		-- Destruction detection (totems only: see GetSpellInfo above)
		if FLO_CLASS_NAME == "SHAMAN" then
			self:RegisterEvent("PLAYER_TOTEM_UPDATE");
		end
	end
end

function FloTotemBar_OnEvent(self, event, arg1, ...)

	if event == "CHARACTER_POINTS_CHANGED" or event == "SPELLS_CHANGED" then
		if not changingSpec then
			if GetSpecialization() ~= FLOTOTEMBAR_OPTIONS.active then
				FloTotemBar_CheckTalentGroup(GetSpecialization());
			else
				FloLib_Setup(self);
			end
		end

	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		if arg1 == "player" then
			FloLib_StartTimer(self, ...);
			-- PLAYER_TOTEM_UPDATE can arrive before or after this event; read
			-- the slot again so the timer takes the totem's real duration
			-- whichever came first.
			if self.slot and self.activeSpell1 then
				FloTotemBar_UpdateTotem(self, self.slot, self.activeSpell1, true);
			end
		end

	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		local _, spellId = ...;
		local spellName = canaccessvalue(spellId) and GetSpellInfo(spellId);
		if arg1 == "player" and spellName == FLOLIB_ACTIVATE_SPEC then
			changingSpec = false;
		end

	elseif event == "SPELL_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_USABLE" then
		FloLib_UpdateState(self);

	elseif event == "PLAYER_DEAD" then
		FloTotemBar_ResetTimers(self);

	elseif (event == "ADDON_LOADED" and arg1 == "FloTotemBar") or event == "UPDATE_BINDINGS" then
		if event == "ADDON_LOADED" then
			FloTotemBar_CheckTalentGroup(FLOTOTEMBAR_OPTIONS.active);

			FloTotemBar_ApplyBlizzardBar();
			FloTotemBar_InitOptions();
		end

		local totemtype = self.totemtype;
		-- Hunters and Paladins have one bar, which uses the Earth bindings
		if totemtype == "TRAP" or totemtype == "SEAL" then totemtype = "EARTH" end
		FloLib_UpdateBindings(self, "FLOTOTEM"..totemtype);

	elseif event == "PLAYER_REGEN_ENABLED" then
		-- A Blizzard bar change asked for during combat waits until now
		if blizzardBarPending then
			FloTotemBar_ApplyBlizzardBar();
		end

	elseif event == "PLAYER_TOTEM_UPDATE" then
		-- Events used for totem destruction detection
		local pos;
		for i = 1, #self.spells do
			if self.sharedCooldown then
				pos = 1
			else
				pos = i
			end
			if arg1 and self["activeSpell"..pos] and i == self["activeSpell"..pos] then
				self.spells[i].algo(self, arg1, i, ...);
			end
		end
	end
end

function FloTotemBar_SetFixupTrap(pos)

	ACTIVE_OPTIONS.baseActionTrap = pos;
	for i = 1, #FLO_TOTEM_SPELLS.HUNTER.TRAP do
		local id = FLO_TOTEM_SPELLS.HUNTER.TRAP[i].id;
		C_Spell.PickupSpell(id);
		PlaceAction(pos - 1 + i);
		ClearCursor();
	end
end

function FloTotemBar_FindEmptyActions(qty)

	local a, remain, start;

	start = nil;
	remain = qty;
	a = 73;
	while a <= 120 and remain > 0 do
		if GetActionInfo(a) then
			start = nil;
			remain = qty;
		else
			if start == nil then
				start = a;
			end
			remain = remain - 1;
		end
		a = a + 1;
	end
	if remain > 0 then
		start = nil;
	end
	return start;
end

function FloTotemBar_TryAddFixupTrapAction()

	if ACTIVE_OPTIONS.baseActionTrap == nil then
		local pos = FloTotemBar_FindEmptyActions(#FLO_TOTEM_SPELLS.HUNTER.TRAP);

		if pos then
			FloTotemBar_SetFixupTrap(pos);
		end
	end
end

function FloTotemBar_TalentGroupChanged(grp)

	-- Save old spec position
	for k, v in pairs(ACTIVE_OPTIONS.barSettings) do
		if v.position ~= "auto" then
			local bar = _G["FloBar"..k];
                        if bar ~= nil then
			        v.refPoint = { bar:GetPoint() };
                        end
		end
	end

	FloTotemBar_CheckTalentGroup(grp);
	for k, v in pairs(ACTIVE_OPTIONS.barSettings) do
		local bar = _G["FloBar"..k];
		if bar ~= nil then
			FloLib_Setup(bar);
			FloTotemBar_ResetTimers(bar);
			-- Restore position
			if v.position ~= "auto" and v.refPoint then
				bar:ClearAllPoints();
				bar:SetPoint(unpack(v.refPoint));
			end
		end
	end
end

function FloTotemBar_CheckTalentGroup(grp)

	changingSpec = false;

	FLOTOTEMBAR_OPTIONS.active = grp;
	ACTIVE_OPTIONS = FLOTOTEMBAR_OPTIONS[grp];
	-- first time talent activation ?
	if not ACTIVE_OPTIONS then
		-- Copy primary spec options into other spec
		FLOTOTEMBAR_OPTIONS[grp] = {};
		FloLib_CopyPreserve(FLOTOTEMBAR_OPTIONS[1], FLOTOTEMBAR_OPTIONS[grp]);
		ACTIVE_OPTIONS = FLOTOTEMBAR_OPTIONS[grp];
	end
	for k, v in pairs(ACTIVE_OPTIONS.barSettings) do
		local bar = _G["FloBar"..k];
                if bar ~= nil then
		        bar.globalSettings = ACTIVE_OPTIONS;
		        bar.settings = v;
		        FloTotemBar_SetPosition(nil, bar, v.position);
                else
                        ACTIVE_OPTIONS.barSettings[k] = nil;
                end
	end
	FloTotemBar_SetScale(ACTIVE_OPTIONS.scale);
	FloTotemBar_SetBorders(nil, ACTIVE_OPTIONS.borders);

end

function FloTotemBar_ReadCmd(line)

	local cmd, var = strsplit(' ', line or "");

	if InCombatLockdown() and (cmd == "scale" or cmd == "lock" or cmd == "unlock" or cmd == "auto" or cmd == "compact") then
		-- moving or scaling a bar moves its secure buttons: blocked in combat
		DEFAULT_CHAT_FRAME:AddMessage("FloTotemBar: "..(ERR_NOT_IN_COMBAT or "You can't do that while in combat"));
	elseif cmd == "scale" and tonumber(var) then
		FloTotemBar_SetScale(var);
	elseif cmd == "lock" or cmd == "unlock" or cmd == "auto" then
		for _, k in ipairs(PRIMARY_BARS) do
			FloTotemBar_SetPosition(nil, _G["FloBar"..k], cmd);
		end
	elseif cmd == "borders" then
		FloTotemBar_SetBorders(nil, true);
	elseif cmd == "noborders" then
		FloTotemBar_SetBorders(nil, false);
	elseif cmd == "hideblizzard" or cmd == "showblizzard" then
		FLOTOTEMBAR_OPTIONS.hideBlizzard = (cmd == "hideblizzard") or nil;
		FloTotemBar_ApplyBlizzardBar();
		DEFAULT_CHAT_FRAME:AddMessage("FloTotemBar: Blizzard totem bar "..(FLOTOTEMBAR_OPTIONS.hideBlizzard and "hidden" or "shown")
			..(blizzardBarPending and " after combat" or ""));
	elseif cmd == "options" or cmd == "config" then
		FloTotemBar_OpenOptions();
	elseif cmd == "compact" then
		FloTotemBar_SetCompact(not ACTIVE_OPTIONS.compact);
	elseif cmd == "minimap" then
		if FLOTOTEMBAR_OPTIONS.minimap then
			FloTotemBar_SetMinimapButton(FLOTOTEMBAR_OPTIONS.minimap.hide);
			DEFAULT_CHAT_FRAME:AddMessage("FloTotemBar: minimap button "..(FLOTOTEMBAR_OPTIONS.minimap.hide and "hidden" or "shown"));
		end
	elseif cmd == "panic" or cmd == "reset" then
		FloLib_ResetAddon("FloTotemBar");
	elseif cmd == "clearfixup" then
		if ACTIVE_OPTIONS.baseActionTrap then
			ACTIVE_OPTIONS.baseActionTrap = nil;
			for i = 73, 120 do
				local t, id = GetActionInfo(i);
				if t == "spell" and (id == 13795 or id == 1499 or id == 13809 or id == 13813 or id == 34600 or id == 77769) then
					PickupAction(i);
					ClearCursor();
				end
			end
		end
	elseif cmd == "addfixup" then
		FloTotemBar_TryAddFixupTrapAction();
	else
		DEFAULT_CHAT_FRAME:AddMessage( "FloTotemBar usage :" );
		DEFAULT_CHAT_FRAME:AddMessage( "/ftb options : Open the settings (Esc > Options > AddOns)" );
		DEFAULT_CHAT_FRAME:AddMessage( "/ftb minimap : Show/hide the minimap button" );
		DEFAULT_CHAT_FRAME:AddMessage( "/ftb compact : One button per bar, the others on hover" );
		DEFAULT_CHAT_FRAME:AddMessage( "/ftb lock|unlock : lock/unlock position" );
		DEFAULT_CHAT_FRAME:AddMessage( "/ftb borders|noborders : show/hide borders" );
		DEFAULT_CHAT_FRAME:AddMessage( "/ftb auto : Automatic positioning" );
		DEFAULT_CHAT_FRAME:AddMessage( "/ftb scale <num> : Set scale" );
		DEFAULT_CHAT_FRAME:AddMessage( "/ftb hideblizzard|showblizzard : hide/show Blizzard's totem bar" );
		DEFAULT_CHAT_FRAME:AddMessage( "/ftb panic||reset : Reset FloTotemBar" );
		return;
	end
end

-- Blizzard's own totem UI: the multicast totem bar and the totem timers under
-- the player frame (TotemFrame). Blizzard re-shows both from its own code, so Hide() would
-- not stick; they are reparented to a hidden frame instead, as bar addons do.
-- MultiCastActionBarFrame holds secure buttons, so this waits out combat.
local BLIZZARD_TOTEM_FRAMES = { "MultiCastActionBarFrame", "TotemFrame" };
local blizzardHider, blizzardParents = nil, {};

function FloTotemBar_ApplyBlizzardBar()

	if InCombatLockdown() then
		blizzardBarPending = true;
		return;
	end
	blizzardBarPending = nil;

	local hide = FLOTOTEMBAR_OPTIONS.hideBlizzard;
	if hide and not blizzardHider then
		blizzardHider = CreateFrame("Frame");
		blizzardHider:Hide();
	end
	for _, name in ipairs(BLIZZARD_TOTEM_FRAMES) do
		local frame = _G[name];
		if frame then
			if hide and not blizzardParents[name] then
				blizzardParents[name] = frame:GetParent();
				frame:SetParent(blizzardHider);
			elseif not hide and blizzardParents[name] then
				frame:SetParent(blizzardParents[name]);
				blizzardParents[name] = nil;
			end
		end
	end
end

-- Sync the bar's timer with the totem actually in the slot. Every bar has
-- sharedCooldown set, so the only visible countdown is number 1, whichever
-- button is active; writing to countdown idx (as this used to) left every
-- totem but the first button on the hardcoded duration from data.lua.
-- resync: called right after the cast, when the slot may still hold the
-- previous totem -- never clear the timer then.
function FloTotemBar_UpdateTotem(self, slot, idx, resync)

	if self.slot ~= slot then
		return;
	end
	-- 7th value is the totem's spell id (Blizzard's CooldownViewer reads it)
	local haveTotem, totemName, startTime, duration, _, _, totemSpellId = GetTotemInfo(slot);
	-- Totem slots can be secret values, which addon code may not
	-- compare; leave the timer alone then.
	if not canaccessvalue(totemName) or not canaccessvalue(duration) then
		return;
	end
	local spell = self.spells[idx];
	-- An expired or destroyed totem can still report haveTotem with an empty
	-- name, so treat no time left as an empty slot too (the old test).
	local timeLeft = GetTotemTimeLeft and GetTotemTimeLeft(slot);
	local empty = not haveTotem or not totemName or totemName == "" or not duration or duration == 0
		or (canaccessvalue(timeLeft) and timeLeft == 0);
	if empty then
		if not resync then
			FloLib_ResetTimer(self, idx);
		end
		return;
	end
	-- Only take the timing when the slot holds this spell's totem: by spell id
	-- (any rank resolves to the same name), else by the totem's name, which
	-- carries the rank ("Searing Totem VII"). Anything else (another totem not
	-- yet reported by UNIT_SPELLCAST_SUCCEEDED) leaves the timer alone.
	local isThisTotem = spell and spell.name and (
		(totemSpellId and totemSpellId ~= 0 and GetSpellInfo(totemSpellId) == spell.name)
		or (totemName and totemName:sub(1, #spell.name) == spell.name));
	if not isThisTotem then
		return;
	end
	local pos = self.sharedCooldown and 1 or idx;
	local countdown = _G[self:GetName().."Countdown"..pos];
	self["startTime"..pos] = startTime;
	if countdown then
		countdown:SetMinMaxValues(0, duration);
	end
	FloLib_OnUpdate(self);
end

function FloTotemBar_SetupSpell(self, spell, pos)

	local duration, algo, spellName, spellTexture;

        spellName = spell.name;
        spellTexture = spell.texture;

	-- Avoid tainting
	if not InCombatLockdown() then
		local name, button, icon;
		name = self:GetName();
		button = _G[name.."Button"..pos];
		icon = _G[name.."Button"..pos.."Icon"];

		button:SetAttribute("type", "spell");
		button:SetAttribute("spell", spell.name);

		icon:SetTexture(spellTexture);
	end

	if FLO_CLASS_NAME == "SHAMAN" then
		algo = FloTotemBar_UpdateTotem;
		duration = spell.duration;
	elseif FLO_CLASS_NAME == "HUNTER" then
		duration = spell.duration or 60;
	elseif FLO_CLASS_NAME == "PALADIN" then
		duration = spell.duration or 30;
	end

	self.spells[pos] = { id = spell.id, name = spellName, addName = spell.addName, duration = duration, algo = algo, talented = spell.talented, talentedName = spell.talentedName };

end

function FloTotemBar_OnSetup(self)

	-- Avoid tainting
	if not InCombatLockdown() then
	        if next(self.spells) == nil then
		        UnregisterStateDriver(self, "visibility")
	        else
		        RegisterStateDriver(self, "visibility", "show")
	        end
        end

	-- Compact bars (Compact.lua): one button, the rest on hover
	FloTotemBar_ApplyCompact(self);

end

function FloTotemBar_UpdatePosition(self)

	-- Avoid tainting when in combat
	if InCombatLockdown() or self == nil then
		return;
	end

	-- non auto positionning
	if not self.settings or self.settings.position ~= "auto" then
		return;
	end

	local layout = FLO_TOTEM_LAYOUTS[ACTIVE_OPTIONS.barLayout];

	self:ClearAllPoints();
	if self == FloBarEARTH or self == FloBarTRAP or self == FloBarSEAL then
		local yOffset = 0;
		local yOffset1 = 0;
		local yOffset2 = 0;
		local anchorFrame;

		if not MainMenuBar:IsShown() then
			anchorFrame = UIParent;
			yOffset = 110 - UIParent:GetHeight();
		else
			anchorFrame = MainMenuBar;

			if MultiBarBottomLeft:IsShown() then
				yOffset = yOffset + 50;
			end
			if MultiBarBottomRight:IsShown() then
				yOffset = yOffset + 50;
			end
		end

		if FLO_CLASS_NAME == "HUNTER" then
            if FloAspectBar ~= nil then
                self:SetPoint("LEFT", FloAspectBar, "RIGHT", 10/ACTIVE_OPTIONS.scale, 0);
            else
			    self:SetPoint("BOTTOMLEFT", anchorFrame, "TOPLEFT", 326/ACTIVE_OPTIONS.scale, (yOffset + yOffset2)/ACTIVE_OPTIONS.scale);
            end
		elseif FLO_CLASS_NAME == "PALADIN" then
			self:SetPoint("BOTTOMLEFT", anchorFrame, "TOPLEFT", 326/ACTIVE_OPTIONS.scale, (yOffset + yOffset1)/ACTIVE_OPTIONS.scale);
		else
			local finalOffset = layout.offset * self:GetHeight();
			self:SetPoint("BOTTOMLEFT", anchorFrame, "TOPLEFT", 164, (yOffset + yOffset1)/ACTIVE_OPTIONS.scale + finalOffset);
		end

	elseif FLO_CLASS_NAME == "SHAMAN" then
		self:SetPoint(unpack(layout[self:GetName()]));
	end
end

function FloTotemBar_UpdatePositions()

	-- Avoid tainting when in combat
	if InCombatLockdown() then
		return;
	end

	for k, v in pairs(ACTIVE_OPTIONS.barSettings) do
		if v.position == "auto" then
			FloTotemBar_UpdatePosition(_G["FloBar"..k])
		end
	end
end

function FloTotemBar_SetBarDrag(frame, enable)

	local countdown = _G[frame:GetName().."Countdown"];
	if enable then
		FloLib_ShowBorders(frame);
		frame:RegisterForDrag("LeftButton");
		if countdown then
			countdown:RegisterForDrag("LeftButton");
		end
	else
		if ACTIVE_OPTIONS.borders then
			FloLib_ShowBorders(frame);
		else
			FloLib_HideBorders(frame);
		end
	end
end

function FloTotemBar_SetBorders(self, visible)

	local k, j;
	ACTIVE_OPTIONS.borders = visible;
	for k, v in pairs(ACTIVE_OPTIONS.barSettings) do
		local bar = _G["FloBar"..k];
		if visible or v.position == "unlock" then
			FloLib_ShowBorders(bar);
		else
			FloLib_HideBorders(bar);
		end
	end

end

function FloTotemBar_SetPosition(self, bar, mode)

	local unlocked = (mode == "unlock");

	-- Close all dropdowns
	CloseDropDownMenus();

	-- Moving a bar moves its secure buttons, which is blocked in combat
	if InCombatLockdown() then
		DEFAULT_CHAT_FRAME:AddMessage("FloTotemBar: "..(ERR_NOT_IN_COMBAT or "You can't do that while in combat"));
		return;
	end

	if bar.settings then
		local savePoints = bar.settings.position ~= mode;
		bar.settings.position = mode;
		DEFAULT_CHAT_FRAME:AddMessage(bar:GetName().." position "..mode);

		FloTotemBar_SetBarDrag(bar, unlocked);

		if mode == "auto" then
			-- Force the auto positionning
			FloTotemBar_UpdatePosition(bar);
		else
			-- Force the game to remember position
			bar:StartMoving();
			bar:StopMovingOrSizing();
			if savePoints then
				bar.settings.refPoint = { bar:GetPoint() };
			end
		end
	end
end

function FloTotemBar_SetLayoutMenu()

	-- Add the possible values to the menu
	for i = 1, #FLO_TOTEM_LAYOUTS_ORDER do
		local value = FLO_TOTEM_LAYOUTS_ORDER[i];
		local info = UIDropDownMenu_CreateInfo();
		info.text = FLO_TOTEM_LAYOUTS[value].label;
		info.value = value;
		info.func = FloTotemBar_SetLayout;
		info.arg1 = value;

		if value == ACTIVE_OPTIONS.barLayout then
			info.checked = 1;
		end
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
	end

end

function FloTotemBar_SetLayout(self, layout)

	-- Close all dropdowns
	CloseDropDownMenus();

	ACTIVE_OPTIONS.barLayout = layout;
	FloTotemBar_UpdatePositions();
end

function FloTotemBar_SetScale(scale)

	scale = tonumber(scale);
	if not scale or scale <= 0 then
		DEFAULT_CHAT_FRAME:AddMessage( "FloTotemBar : scale must be >0 ("..tostring(scale)..")" );
		return;
	end

	local setPoints = ACTIVE_OPTIONS.scale ~= scale;
	ACTIVE_OPTIONS.scale = scale;

	-- Every bar of the class, not only TRAP/EARTH: the Seal bar and the
	-- Fire/Water/Air bars never scaled before.
	for k in pairs(ACTIVE_OPTIONS.barSettings) do
		local v = _G["FloBar"..k];
		if v then
			local p, a, rp, ox, oy = v:GetPoint();
			local os = v:GetScale();
			v:SetScale(scale);
			if setPoints and p and (a == nil or a == UIParent or a == MainMenuBar) then
				v:SetPoint(p, a, rp, ox*os/scale, oy*os/scale);
			end
		end
	end
	FloTotemBar_UpdatePositions();

end

function FloTotemBar_ResetTimers(self)

	for i = 1, 10 do
		self["startTime"..i] = 0;
	end
	FloLib_OnUpdate(self);
end



