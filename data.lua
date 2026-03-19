-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.

FLO_TOTEM_SPELLS = {
	["HUNTER"] = {
		["TRAP"] = {
			{ id = 13795, algo = 1 }, -- Immolation Trap
			{ id = 1499, algo = 1 },  -- Freezing Trap
			{ id = 13809, algo = 1 }, -- Frost Trap
			{ id = 13813, algo = 1 }, -- Explosive Trap
			{ id = 34600, algo = 1 }, -- Snake Trap (TBC)
		}
	},
	["SHAMAN"] = {
		["EARTH"] = {
			{ id = 8071, duration = 120 },  -- Stoneskin Totem
			{ id = 2484, duration = 45 },   -- Earthbind Totem
			{ id = 5730, duration = 15 },   -- Stoneclaw Totem
			{ id = 8075, duration = 120 },  -- Strength of Earth Totem
			{ id = 8143, duration = 120 },  -- Tremor Totem
		},
		["FIRE"] = {
			{ id = 3599, duration = 30 },   -- Searing Totem
			{ id = 1535, duration = 5 },    -- Fire Nova Totem
			{ id = 8181, duration = 120 },  -- Frost Resistance Totem
			{ id = 8190, duration = 20 },   -- Magma Totem
			{ id = 8227, duration = 120 },  -- Flametongue Totem
			{ id = 30706, duration = 120 }, -- Totem of Wrath (TBC, Elemental talent)
		},
		["WATER"] = {
			{ id = 5394, duration = 60 },   -- Healing Stream Totem
			{ id = 8166, duration = 120 },  -- Poison Cleansing Totem
			{ id = 5675, duration = 60 },   -- Mana Spring Totem
			{ id = 8184, duration = 120 },  -- Fire Resistance Totem
			{ id = 8170, duration = 120 },  -- Disease Cleansing Totem
			{ id = 16190, duration = 12 },  -- Mana Tide Totem
		},
		["AIR"] = {
			{ id = 8177, duration = 45 },   -- Grounding Totem
			{ id = 10595, duration = 120 }, -- Nature Resistance Totem
			{ id = 8512, duration = 120 },  -- Windfury Totem
			{ id = 6495, duration = 300 },  -- Sentry Totem
			{ id = 15107, duration = 120 }, -- Windwall Totem
			{ id = 8835, duration = 120 },  -- Grace of Air Totem
			{ id = 25908, duration = 120 }, -- Tranquil Air Totem
			{ id = 3738, duration = 120 },  -- Wrath of Air Totem (TBC)
		}
	},
	["PALADIN"] = {
		["SEAL"] = {
			{ id = 20154 }, -- Seal of Righteousness
			{ id = 21082 }, -- Seal of the Crusader
			{ id = 20164 }, -- Seal of Justice
			{ id = 20375 }, -- Seal of Command
			{ id = 20165 }, -- Seal of Light
			{ id = 20166 }, -- Seal of Wisdom
			{ id = 31892 }, -- Seal of Blood (TBC, Horde)
			{ id = 31801 }, -- Seal of Vengeance (TBC, Alliance)
		}
	}
};

FLO_TOTEM_LAYOUTS = {
	["1row"] = { label = FLO_TOTEM_1ROW, offset = 0,
		["FloBarFIRE"] = { "LEFT", "FloBarEARTH", "RIGHT", 3, 0 },
		["FloBarWATER"] = { "LEFT", "FloBarFIRE", "RIGHT", 3, 0 },
		["FloBarAIR"] = { "LEFT", "FloBarWATER", "RIGHT", 3, 0 },
	},
	["2rows"] = { label = FLO_TOTEM_2ROWS, offset = 1,
		["FloBarFIRE"] = { "LEFT", "FloBarEARTH", "RIGHT", 3, 0 },
		["FloBarWATER"] = { "TOPLEFT", "FloBarEARTH", "BOTTOMLEFT", 0, 0 },
		["FloBarAIR"] = { "LEFT", "FloBarWATER", "RIGHT", 3, 0 },
	},
	["4rows"] = { label = FLO_TOTEM_4ROWS, offset = 3,
		["FloBarFIRE"] = { "TOPLEFT", "FloBarEARTH", "BOTTOMLEFT", 0, 0 },
		["FloBarWATER"] = { "TOPLEFT", "FloBarFIRE", "BOTTOMLEFT", 0, 0 },
		["FloBarAIR"] = { "TOPLEFT", "FloBarWATER", "BOTTOMLEFT", 0, 0 },
	},
	["2rows-reverse"] = { label = FLO_TOTEM_2ROWS_REVERSE, offset = 0,
		["FloBarFIRE"] = { "LEFT", "FloBarEARTH", "RIGHT", 3, 0 },
		["FloBarWATER"] = { "BOTTOMLEFT", "FloBarEARTH", "TOPLEFT", 0, 0 },
		["FloBarAIR"] = { "LEFT", "FloBarWATER", "RIGHT", 3, 0 },
	},
	["4rows-reverse"] = { label = FLO_TOTEM_4ROWS_REVERSE, offset = 0,
		["FloBarFIRE"] = { "BOTTOMLEFT", "FloBarEARTH", "TOPLEFT", 0, 0 },
		["FloBarWATER"] = { "BOTTOMLEFT", "FloBarFIRE", "TOPLEFT", 0, 0 },
		["FloBarAIR"] = { "BOTTOMLEFT", "FloBarWATER", "TOPLEFT", 0, 0 },
	},
};

FLO_TOTEM_LAYOUTS_ORDER = {
	"1row",
	"2rows",
	"4rows",
	"2rows-reverse",
	"4rows-reverse"
};
