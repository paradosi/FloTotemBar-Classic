-- luacheck configuration for FloTotemBar (WoW Classic addon)
-- Run: luacheck *.lua

std = "lua51"
max_line_length = false
codes = true

-- WoW event/combat-log callbacks receive fixed positional argument lists where
-- most parameters go unused; do not flag those.
unused_args = false

-- The addon's own namespace is shared across .lua files and Blizzard XML
-- (frames, handlers, saved vars, localization tables, key bindings). These are
-- defined in one place and read in another, so silence "non-standard global"
-- for the whole namespace rather than listing every symbol.
ignore = {
	"11./^FLO",        -- FLO_TOTEM_*, FLOTOTEMBAR_*, FLOLIB_*
	"11./^Flo",        -- FloLib_*, FloTotemBar_*, FloBar* frames, FloAspectBar
	"11./^BINDING_",   -- key binding names consumed by WoW
	"11./^SLASH_",     -- slash command registration
}

-- WoW globals whose fields the addon writes (luacheck's stock lua51 std wrongly
-- treats these as read-only).
globals = {
	"SlashCmdList", "StaticPopupDialogs", "GameTooltip",
}

-- WoW API surface actually used by this addon. Listed as read-only so a typo in
-- an API name still surfaces as an undefined-global warning.
read_globals = {
	-- namespaces / tables
	"C_Spell", "string", "bit", "math", "table", "LibStub", "BOOKTYPE_SPELL",
	-- frames / UI globals
	"UIParent", "MainMenuBar", "VehicleMenuBar",
	"MultiBarBottomLeft", "MultiBarBottomRight",
	"DEFAULT_CHAT_FRAME", "ColorPickerFrame", "OpacitySliderFrame",
	-- spell / cooldown / totem API
	"GetSpellInfo", "GetSpellCooldown", "IsUsableSpell", "GetSpellBookItemName",
	"GetTotemInfo", "GetTotemTimeLeft", "GetTime", "CooldownFrame_Set",
	"PickupSpell", "PickupSpellBookItem", "PickupAction", "PlaceAction",
	"GetActionInfo", "ClearCursor", "GetCursorInfo",
	-- unit / class / talent / glyph
	"UnitClass", "UnitBuff", "GetSpecialization", "GetLocale",
	"GetNumTalents", "GetTalentInfo", "GetGlyphSocketInfo", "NUM_GLYPH_SLOTS",
	-- combat log
	"CombatLogGetCurrentEventInfo", "CombatLog_Object_IsA",
	"COMBATLOG_FILTER_MINE", "COMBATLOG_OBJECT_AFFILIATION_MINE",
	"COMBATLOG_OBJECT_REACTION_FRIENDLY", "COMBATLOG_OBJECT_CONTROL_PLAYER",
	"COMBATLOG_OBJECT_TYPE_GUARDIAN",
	-- bindings / state drivers / secure
	"GetBindingKey", "SetOverrideBindingClick", "ClearOverrideBindings",
	"RegisterStateDriver", "UnregisterStateDriver", "InCombatLockdown",
	"hooksecurefunc", "Mixin", "BackdropTemplateMixin",
	-- dropdown menu API
	"UIDropDownMenu_CreateInfo", "UIDropDownMenu_AddButton",
	"UIDropDownMenu_Initialize", "UIDropDownMenu_SetButtonWidth",
	"UIDropDownMenu_SetWidth", "UIDropDownMenu_GetCurrentDropDown",
	"UIDropDownMenuButton_OpenColorPicker", "CloseDropDownMenus",
	"ToggleDropDownMenu", "UIDROPDOWNMENU_MENU_LEVEL", "UIDROPDOWNMENU_MENU_VALUE",
	-- misc helpers / constants
	"StaticPopup_Show", "ReloadUI", "GetCVar", "SecondsToTimeAbbrev",
	"strupper", "strsplit", "strsub", "tContains",
	"HIGHLIGHT_FONT_COLOR", "TOOLTIP_DEFAULT_BACKGROUND_COLOR",
	"CONTAINER_OFFSET_X", "CONTAINER_OFFSET_Y", "LOCK_ACTIONBAR",
	"IsShiftKeyDown", "IsAltKeyDown", "COOLDOWN_TYPE_NORMAL",
	"SPELLS", "BACKGROUND", "YES", "NO",
}
