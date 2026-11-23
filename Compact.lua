-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------
-- Compact bars (option, off by default). Not upstream code.
--
-- Each bar shows only its first button: the selected spell. Hovering it opens
-- the bar's other buttons in a column above it; clicking one casts it and
-- makes it the selected spell, by swapping the two buttons' "spell"
-- attributes. All of that runs in Blizzard's restricted environment (a secure
-- header with wrapped OnEnter/OnClick scripts), because swapping totems
-- happens in combat, where addon code may not touch secure buttons.
--
-- After a swap the header's "swapped" attribute changes, and the insecure
-- side (FloTotemBar_CompactResync) catches up: the bar's spell table, the
-- icons and the saved button order. None of that is protected, so it works in
-- combat too. Out of combat, FloLib_Setup then rebuilds the same order.
--
-- The header and the wrapped scripts are created the first time compact mode
-- is switched on, so a bar that never uses it is exactly as before.
-------------------------------------------------------------------------------

local MAX_BUTTONS = 10;

-- Button1 OnEnter: show the other buttons, and hide them again once the
-- cursor has been off all of them (and Button1) for 0.4 s
local OPEN_FLYOUT = [[
	if not owner:GetAttribute("compact") then
		return;
	end
	local count = owner:GetAttribute("count") or 0;
	if count < 2 then
		return;
	end
	for i = 2, count do
		owner:GetFrameRef("b"..i):Show();
	end
	for i = 2, count do
		local b = owner:GetFrameRef("b"..i);
		b:RegisterAutoHide(0.4);
		b:AddToAutoHide(self);
		for j = 2, count do
			if j ~= i then
				b:AddToAutoHide(owner:GetFrameRef("b"..j));
			end
		end
	end
]];

-- Other buttons, OnClick: only a left click, and only on its release, so the
-- swap happens after the spell was cast whichever of down/up casts it
local PICK_PRE = [[
	if owner:GetAttribute("compact") and button == "LeftButton" and not down then
		return nil, "swap";
	end
]];

local PICK_POST = [[
	local main = owner:GetFrameRef("b1");
	local picked = self:GetAttribute("spell");
	self:SetAttribute("spell", main:GetAttribute("spell"));
	main:SetAttribute("spell", picked);
	for i = 2, owner:GetAttribute("count") or 0 do
		owner:GetFrameRef("b"..i):Hide();
	end
	owner:SetAttribute("swapped", (owner:GetAttribute("swapped") or 0) + 1);
]];

-- Read the spells back from the buttons after a secure swap
function FloTotemBar_CompactResync(self)

	local name = self:GetName();
	for i = 1, #self.spells do
		local spellName = _G[name.."Button"..i]:GetAttribute("spell");
		for n, spell in ipairs(self.availableSpells) do
			if spell.name == spellName then
				-- in combat SetupSpell leaves the button alone and only
				-- rebuilds self.spells[i]; out of combat it rewrites the same
				-- attribute
				self:SetupSpell(spell, i);
				_G[name.."Button"..i.."Icon"]:SetTexture(spell.texture);
				self.settings.buttonsOrder[i] = n;
				break;
			end
		end
	end
	FloLib_UpdateState(self);
end

local function GetHeader(self)

	if self.compactHeader then
		return self.compactHeader;
	end

	local name = self:GetName();
	local header = CreateFrame("Frame", nil, self, "SecureHandlerBaseTemplate");
	for i = 1, MAX_BUTTONS do
		SecureHandlerSetFrameRef(header, "b"..i, _G[name.."Button"..i]);
	end
	SecureHandlerWrapScript(_G[name.."Button1"], "OnEnter", header, OPEN_FLYOUT);
	for i = 2, MAX_BUTTONS do
		SecureHandlerWrapScript(_G[name.."Button"..i], "OnClick", header, PICK_PRE, PICK_POST);
	end
	header:SetScript("OnAttributeChanged", function(_, attr)
		if attr == "swapped" then
			FloTotemBar_CompactResync(self);
		end
	end);

	self.compactHeader = header;
	return header;
end

-- Lay a bar out compact or normal. Called after every FloLib_Setup, out of
-- combat only (it moves secure buttons).
function FloTotemBar_ApplyCompact(self)

	if InCombatLockdown() or not self.globalSettings then
		return;
	end

	local compact = self.globalSettings.compact and true or false;
	if not compact and not self.compactHeader then
		-- never switched on: nothing to undo
		return;
	end

	local header = GetHeader(self);
	local name = self:GetName();
	local count = #self.spells;
	header:SetAttribute("compact", compact);
	header:SetAttribute("count", count);

	for i = 2, MAX_BUTTONS do
		local button = _G[name.."Button"..i];
		button:ClearAllPoints();
		if compact then
			-- a column above Button1, drawn over the bars next to it
			button:SetPoint("BOTTOM", _G[name.."Button"..(i - 1)], "TOP", 0, 4);
			button:SetFrameStrata("HIGH");
			button:Hide();
		else
			-- where FloLib_Setup puts them on a shared-cooldown bar
			button:SetPoint("LEFT", _G[name.."Countdown"..i], "LEFT", 0, 0);
			button:SetFrameStrata(self:GetFrameStrata());
			if i <= count then
				button:Show();
			end
		end
	end

	if compact and count > 0 then
		-- one button and the shared countdown (FloLib: numSpells * 35 + 21)
		self:SetWidth(35 + 21);
	end
end
