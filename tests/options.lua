-- luacheck: ignore
-- (this file stubs the WoW API by assigning its globals; nothing here ships)
--
-- Headless test of the settings panel (Options.lua) against a stubbed WoW API
-- and stand-in bars, once as a shaman (four bars, layouts, Blizzard's totem
-- bar) and once as a hunter (one bar): builds the panel, opens it, works every
-- control and the help dialog, and checks each one calls through to the
-- addon's own setters. The bars are built from XML (FloLib.xml) and are not
-- loaded here, so their setters are recorded rather than run. Widget stubs
-- come from ForeverQuestItemBar's tests/smoke.lua.
--
--   cd FloTotemBar-Classic && lua5.1 tests/options.lua

local failures = 0
local function check(cond, msg)
    if cond then print("ok   " .. msg) else failures = failures + 1; print("FAIL " .. msg) end
end

---- A permissive widget: unknown CamelCase methods are no-ops; the ones the
---- addon reads keep real state

local methods = {}
local Widget = {
    __index = function(_, k)
        if methods[k] then return methods[k] end
        if type(k) == "string" and k:match("^%u") then return function() end end
    end,
}
local function NewWidget(kind, name)
    return setmetatable({ kind = kind, name = name, scripts = {}, shown = true, points = {},
                          w = 100, h = 100, alpha = 1, value = 0, scale = 1, attrs = {},
                          enabled = true, children = {} }, Widget)
end
function methods.SetScript(self, k, fn) self.scripts[k] = fn end
function methods.GetScript(self, k) return self.scripts[k] end
function methods.HookScript(self, k, fn)
    local before = self.scripts[k]
    self.scripts[k] = function(...) if before then before(...) end fn(...) end
end
function methods.Show(self) self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods.Hide(self)
    local was = self.shown
    self.shown = false
    if was and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods.SetShown(self, on) if on then self:Show() else self:Hide() end end
function methods.IsShown(self) return self.shown end
function methods.SetSize(self, w, h) self.w, self.h = w, h end
function methods.SetWidth(self, w) self.w = w end
function methods.SetHeight(self, h) self.h = h end
function methods.GetWidth(self) return self.w end
function methods.GetHeight(self) return self.h end
function methods.GetLeft() return 400 end
function methods.GetRight(self) return 400 + self.w end
function methods.GetTop() return 300 end
function methods.GetFrameLevel() return 1 end
function methods.ClearAllPoints(self) self.points = {} end
function methods.SetPoint(self, ...) table.insert(self.points, { ... }) end
function methods.GetPoint(self, i) return unpack(self.points[i or 1] or {}) end
function methods.SetAlpha(self, a) self.alpha = a end
function methods.SetScale(self, s) self.scale = s end
function methods.GetScale(self) return self.scale end
function methods.IsMouseOver() return false end
function methods.HasFocus(self) return self.focus end
function methods.SetFocus(self) self.focus = true end
function methods.ClearFocus(self) self.focus = false end
function methods.SetText(self, t) self.text = t end
function methods.GetText(self) return self.text end
function methods.SetEnabled(self, on) self.enabled = on end
function methods.GetName(self) return self.name end
function methods.GetID(self) return self.id end
function methods.SetAttribute(self, k, v) self.attrs[k] = v end
function methods.GetAttribute(self, k) return self.attrs[k] end
function methods.CreateTexture(self) return NewWidget("Texture") end
function methods.CreateFontString(self) return NewWidget("FontString") end
function methods.GetThumbTexture(self)
    self.thumb = self.thumb or NewWidget("Texture")
    return self.thumb
end
function methods.SetMinMaxValues(self, a, b) self.min, self.max = a, b end
function methods.SetValue(self, v)
    self.value = v
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, v) end
end
function methods.GetValue(self) return self.value end
function methods.RegisterEvent(self, e) self.events = self.events or {}; self.events[e] = true end
function methods.UnregisterEvent(self, e) if self.events then self.events[e] = nil end end
function methods.Click(self, button)
    if self.scripts.OnClick then self.scripts.OnClick(self, button or "LeftButton") end
end

---- Globals

local frames = {}
function CreateFrame(kind, name, parent, template)
    local f = NewWidget(kind, name)
    if name then _G[name] = f end
    if parent then table.insert(parent.children, f) end
    if template and template:find("ActionButtonTemplate") then
        f.icon, f.Count, f.HotKey, f.cooldown =
            NewWidget("Texture"), NewWidget("FontString"), NewWidget("FontString"), NewWidget("Cooldown")
    end
    table.insert(frames, f)
    return f
end
UIParent = NewWidget("Frame", "UIParent")
UISpecialFrames = {}
SlashCmdList = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) LAST_PRINT = m end }
SOUNDKIT = { U_CHAT_SCROLL_BUTTON = 1115 }
ATTRIBUTE_NOOP = ""
GameTooltip = NewWidget("GameTooltip")
function PlaySound() end
function CreateColor(r, g, b, a) return { r, g, b, a } end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function tinsert(t, v) table.insert(t, v) end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
function GetBindingKey() return nil end
function GetBindingText(k) return k end
function CooldownFrame_Set() end
function ActionButton_UpdateRangeIndicator() end
function UnitExists() return false end
function UnitCanAttack() return false end
function IsAltKeyDown() return false end
function IsModifiedClick() return false end
function HandleModifiedItemClick() end
function GetQuestLogSpecialItemInfo() return nil end
NUM_TOTAL_EQUIPPED_BAG_SLOTS = 5

local state = { combat = false }
function InCombatLockdown() return state.combat end

local timers = {}
C_Timer = { After = function(_, fn) table.insert(timers, fn) end }
local function RunAfters()
    while #timers > 0 do table.remove(timers, 1)() end
end

function methods.GetVerticalScrollRange() return 0 end
function methods.GetVerticalScroll() return 0 end
function methods.GetBottom() return 100 end
function methods.SetLabel(self, t) self.label.text = t:upper() end

C_AddOns = {
    GetAddOnMetadata = function(_, field)
        if field == "Version" then return "9.9.9" end
        if field == "X-Website" then return "https://github.com/paradosi/FloTotemBar-Classic" end
    end,
}
local opened
local function NewSettings()
    Settings = {
        RegisterCanvasLayoutCategory = function(panel, name)
            return { panel = panel, name = name, GetID = function() return 42 end }
        end,
        RegisterAddOnCategory = function(cat) Settings.category = cat end,
        OpenToCategory = function(id) opened = id end,
    }
end
C_Spell = { GetSpellName = function(id) return "Spell " .. id end }
FLOLIB_POSITIONS = { auto = "Automatic", lock = "Locked", unlock = "Unlocked" }
FLOLIB_SHOWBORDERS = "Show borders"
FLOLIB_LAYOUT = "Layout"
ERR_NOT_IN_COMBAT = "You can't do that while in combat"
FLO_TOTEM_LAYOUTS_ORDER = { "1row", "2rows", "4rows", "2rows-reverse", "4rows-reverse" }
FLO_TOTEM_LAYOUTS = {}
for _, v in ipairs(FLO_TOTEM_LAYOUTS_ORDER) do FLO_TOTEM_LAYOUTS[v] = { label = "Layout " .. v } end
function CloseDropDownMenus() end

local calls = {}
local function Record(name) return function(...) table.insert(calls, { name, ... }) end end
local function Last() return calls[#calls] or {} end
local options
function FloTotemBar_ReadCmd(cmd)
    table.insert(calls, { "ReadCmd", cmd })
    local word, arg = cmd:match("^(%S+)%s*(.*)$")
    if InCombatLockdown() and (word == "scale" or word == "lock" or word == "unlock" or word == "auto") then return end
    if word == "scale" then options.scale = tonumber(arg)
    elseif word == "lock" or word == "unlock" or word == "auto" then FloBarPRIMARY.settings.position = word
    elseif word == "hideblizzard" then FLOTOTEMBAR_OPTIONS.hideBlizzard = true
    elseif word == "showblizzard" then FLOTOTEMBAR_OPTIONS.hideBlizzard = nil end
end
function FloTotemBar_SetLayout(_, v) options.barLayout = v; Record("SetLayout")(v) end
function FloTotemBar_SetBorders(_, v) options.borders = v; Record("SetBorders")(v) end
function FloLib_ToggleSpell(_, bar, i)
    bar.settings.hiddenSpells[i] = not bar.settings.hiddenSpells[i] or nil
    Record("ToggleSpell")(bar.name, i)
end
FloLib_Setup = Record("Setup")
FloLib_ResetAddon = Record("ResetAddon")
FloLib_CreateMinimapButton = function() return NewWidget("Button") end
FloLib_UpdateMinimapButton = Record("UpdateMinimap")

local function Bar(name, spells)
    local b = { name = name, settings = { position = "auto", hiddenSpells = {} }, globalSettings = options,
                availableSpells = {} }
    for i, s in ipairs(spells) do b.availableSpells[i] = { id = i, name = s } end
    _G["FloBar" .. name] = b
    return b
end

local function Walk(f, out)
    out = out or {}
    for _, c in ipairs(f.children) do table.insert(out, c); Walk(c, out) end
    return out
end
local function Controls(panel)
    local checks, buttons, sliders = {}, {}, {}
    for _, f in ipairs(Walk(panel)) do
        if f.kind == "Button" and f.label and f.label.text then
            if rawget(f, "checked") ~= nil then checks[f.label.text] = f else buttons[f.label.text] = f end
        elseif f.kind == "Slider" then table.insert(sliders, f) end
    end
    return checks, buttons, sliders
end

local function Load(class)
    for _, k in ipairs({ "TRAP", "SEAL", "EARTH", "FIRE", "WATER", "AIR" }) do _G["FloBar" .. k] = nil end
    FloTotemBarOptions = nil
    calls = {}
    options = { scale = 1, borders = true, barLayout = "1row" }
    FLOTOTEMBAR_OPTIONS = {}
    FLO_CLASS_NAME = class
    NewSettings()
    local ns = {}
    for _, file in ipairs({ "Theme.lua", "Widgets.lua", "Options.lua" }) do
        assert(loadfile(file))("FloTotemBar", ns)
    end
end

---- Shaman

Load("SHAMAN")
FloBarPRIMARY = Bar("EARTH", { "Stoneskin Totem", "Earthbind Totem" })
Bar("FIRE", { "Searing Totem" }); Bar("WATER", { "Healing Stream Totem" }); Bar("AIR", { "Windfury Totem" })
FloTotemBar_InitOptions()
check(Settings.category and Settings.category.name == "FloTotemBar", "shaman: panel registered")
FloTotemBarOptions:Show()
local checks, buttons, sliders = Controls(FloTotemBarOptions)

check(buttons["LAYOUT 1ROW"] and buttons["LAYOUT 1ROW"].selected, "shaman: five layouts, the saved one selected")
check(buttons["LAYOUT 4ROWS-REVERSE"] ~= nil, "shaman: every layout listed")
check(checks["Hide Blizzard's totem bar"] ~= nil, "shaman: Blizzard bar option shown")
check(checks["Searing Totem"] and checks["Windfury Totem"] and checks["Earthbind Totem"], "shaman: every bar's spells listed")

buttons["LAYOUT 2ROWS"]:Click()
check(Last()[1] == "SetLayout" and Last()[2] == "2rows" and buttons["LAYOUT 2ROWS"].selected
    and not buttons["LAYOUT 1ROW"].selected, "shaman: picking a layout applies it")
state.combat = true
buttons["LAYOUT 4ROWS"]:Click()
check(options.barLayout == "2rows" and buttons["LAYOUT 2ROWS"].selected, "shaman: in combat the layout is refused")
sliders[1]:SetValue(150)
check(options.scale == 1 and sliders[1].value == 100, "shaman: in combat the scale springs back")
state.combat = false

buttons["UNLOCKED"]:Click()
check(Last()[2] == "unlock" and FloBarPRIMARY.settings.position == "unlock", "shaman: Unlocked unlocks")
sliders[1]:SetValue(120)
check(math.abs(options.scale - 1.2) < 1e-9, "shaman: scale 120% applied")
checks["Hide Blizzard's totem bar"]:Click()
check(FLOTOTEMBAR_OPTIONS.hideBlizzard == true, "shaman: hide Blizzard's bar")
checks["Compact bars"]:Click()
check(options.compact == true, "shaman: compact bars on")
checks["Searing Totem"]:Click()
check(Last()[1] == "ToggleSpell" and Last()[2] == "FIRE" and Last()[3] == 1, "shaman: unticking a totem hides it on its own bar")
checks["Show borders"]:Click()
check(options.borders == false, "shaman: borders off")
checks["Show minimap button"]:Click()
check(FLOTOTEMBAR_OPTIONS.minimap.hide == true, "shaman: minimap button off")

local reset = buttons["RESET ALL SETTINGS"]
reset:Click(); reset:Click()
check(Last()[1] == "ResetAddon" and Last()[2] == "FloTotemBar", "shaman: reset after two clicks")
buttons["HELP AND BUG REPORTS"]:Click()
check(FloTotemBarCopyDialog.shown and FloTotemBarCopyDialog.box.text:find("FloTotemBar%-Classic"), "help opens the link")

---- Hunter

Load("HUNTER")
FloBarPRIMARY = Bar("TRAP", { "Immolation Trap", "Freezing Trap" })
FloTotemBar_InitOptions()
FloTotemBarOptions:Show()
checks, buttons, sliders = Controls(FloTotemBarOptions)
check(buttons["LAYOUT 1ROW"] == nil and checks["Hide Blizzard's totem bar"] == nil, "hunter: no shaman-only controls")
check(checks["Freezing Trap"] and checks["Freezing Trap"].checked, "hunter: traps listed")
checks["Freezing Trap"]:Click()
check(Last()[1] == "ToggleSpell" and Last()[2] == "TRAP" and Last()[3] == 2, "hunter: unticking a trap hides it")

print(failures == 0 and "\nall passed" or ("\n" .. failures .. " failed"))
os.exit(failures == 0 and 0 or 1)
