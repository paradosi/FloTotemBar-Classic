# Changelog

All notable changes to FloTotemBar-Classic will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.2.9] - 2026-11-20

### Added
- **WoW Forever: Seal of Fury on the paladin seal bar.** Horde paladins' seal was missing from the bar; it now appears once you have learned it.

## [1.2.8] - 2026-11-17

### Fixed
- **WoW Forever: a Lua error when dragging a spell off the bar** (Shift-drag, or with action bars unlocked). The spell is now picked up correctly.
- **Masque skinning works again.** The bar looked for Masque before Masque had loaded, so skins were never applied.
- Shared library FloLib updated to 1.52 (same change in FloTotemBar and FloAspectBar; update both if you use both).

## [1.2.7] - 2026-11-15

### Added
- **Option to hide Blizzard's own totem UI**, for shamans: tick *Hide Blizzard totem bar* in any totem bar's right-click menu, or type `/ftb hideblizzard`. It hides the totem bar (WoW Forever) and the totem timers under the player frame (TBC and WoW Forever). `/ftb showblizzard` brings them back. The setting is saved, and if you use it in combat it takes effect when combat ends. Classic Era has neither frame, so the option does nothing there.
- Shared library FloLib updated to 1.51 (same change in FloTotemBar and FloAspectBar; update both if you use both).

## [1.2.6] - 2026-11-10

### Fixed
- Shared library FloLib updated to 1.50 (same fix in FloTotemBar and FloAspectBar; update both if you use both).

## [1.2.5] - 2026-11-06

### Fixed
- **WoW Forever: Lua errors at login and when casting**, and the bar could stay empty. Forever has no `GetSpellInfo`, `GetSpellCooldown` or `IsUsableSpell`; the bar now uses the newer spell API there.
- **WoW Forever: the bar could not position itself** ("attempt to index global 'MainMenuBar'"). Forever renamed the main action bar; the bar now anchors to it.
- **WoW Forever: dragging a spell from the spellbook onto the bar** now works with the new spellbook.
- Cooldown swirls are skipped instead of erroring when the game hides cooldown values from addons.
- Shared library FloLib updated to 1.49 (same fix in FloTotemBar and FloAspectBar; update both if you use both).

## [1.2.4] - 2026-11-05

### Added
- **WoW Forever support.** Addons cannot read the combat log on Forever, so a trap timer runs its full length there instead of ending when the trap is triggered, and a totem timer is left alone whenever the game hides totem details from addons.

### Fixed
- **Shaman totem timers used a fixed duration for every totem except the first button on each bar.** The bar read the totem's real duration from the game but wrote it to a hidden timer, so totems that last longer at higher ranks (Searing Totem, for one) showed as expired while still up. Timers now follow the totem in the slot, whichever order the game reports the cast and the totem in.
- **Paladins could not keybind seals.** The Seal bar now uses the Earth bindings, as the Trap bar already did (Key Bindings → "Floraline's Earth/Trap/Seal Bar").
- **`/ftb scale` only resized the Trap and Earth bars.** It now applies to every bar, including the Seal bar and the Fire, Water and Air totem bars, and the saved scale is applied to all of them at login.
- **`/ftb lock`, `unlock` and `auto` did nothing for Paladins.** They now reach the Seal bar.
- **Dragging a hidden spell from the spellbook onto its bar caused a Lua error.** It is now ignored.
- **Healing Stream and Mana Spring timers started at 1 minute on TBC**, where those totems last 2 minutes; Magma Totem (21 s) and Mana Tide Totem (13 s) were a second short. The starting values now match TBC Anniversary's spell data, and the timer still corrects itself from the game on both clients.
- **Moving or rescaling a bar in combat** (`/ftb lock`, `unlock`, `auto`, `scale`, or the right-click Position menu) could cause "Interface action failed because of an AddOn". These now say you can't do that in combat.
- **"Lock Action Bars" was ignored**: spells could be dragged off the bar without Shift. The bar now honours the setting and the pick-up modifier, like Blizzard's action bars.

### Changed
- Removed unused code and translations
- Trap and seal timers use `C_CombatLog` instead of the deprecated combat-log functions, so they keep working with `loadDeprecationFallbacks` off and after Blizzard removes the fallbacks.
- FloLib 1.48: buff checks use `C_UnitAuras`, and skip buffs the game hides from addons; unused glyph and talent helpers removed.

## [1.2.3] - 2026-11-05

### Changed
- Updated for the current clients (TBC Anniversary 2.5.6 and Classic Era 1.15.9), so the addon no longer shows as out of date
- Release notes on CurseForge and Wago are now this changelog instead of the commit log

## [1.2.2] - 2026-07-04

### Fixed
- Spell/totem tooltips now show the highest known rank instead of rank 1
  (issue #1). The same max-rank resolution also corrects cooldown and
  usable/out-of-mana coloring for higher ranks. FloLib bumped to 1.45.

## [1.2.1] - 2025-01-01

### Added
- Initial tracked release on GitLab

## [1.2.0]

### Added
- Paladin seal bar support
- Hunter trap bar support
- TBC Anniversary client compatibility
