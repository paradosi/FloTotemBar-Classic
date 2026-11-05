# Changelog

All notable changes to FloTotemBar-Classic will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.2.4] - 2026-11-05

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
- Trap and seal timers use `C_CombatLog` instead of the deprecated combat-log functions, so they keep working with `loadDeprecationFallbacks` off and after Blizzard removes the fallbacks.
- FloLib 1.46: buff checks use `C_UnitAuras`; unused glyph and talent helpers removed.

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
