<p align="center">
  <img src="https://raw.githubusercontent.com/paradosi/FloTotemBar-Forever/main/media/art/logo_400.png" width="200" alt="FloTotemBar Forever">
</p>

<h1 align="center">FloTotemBar Forever</h1>

Totem, trap, and seal bar addon for **WoW Forever**. Provides class-specific action bars with cooldown timers and keybinding support for **Shamans**, **Hunters**, and **Paladins**.

Originally created by **Floraline** (MPL 2.0). Maintained for WoW Forever by **paradosi-Dreamscythe**.

![WoW Forever: 16001](https://img.shields.io/badge/WoW_Forever-16001-purple)

## Features

- **Shaman Totem Bars** — 4 separate bars for Earth, Fire, Water, and Air totems with duration timers
- **Hunter Trap Bar** — Immolation, Freezing, Frost and Explosive traps with cooldown tracking
- **Paladin Seal Bar** — All seals, including Forever's Seal of Fury
- **Click to cast** — Left-click any spell to cast it
- **Cooldown & duration timers** — Visual countdown on active totems and trap cooldowns
- **Multiple layout options** — Shamans can choose from various totem bar arrangements
- **Compact bars** — Optional: one button per bar showing the spell you picked last; hover it for the bar's other spells, click one to cast it and make it the bar's button (works in combat)
- **Keybinding support** — Bind keys via WoW's Key Bindings menu (Hunter traps and Paladin seals use the Earth bar's bindings)
- **Drag to reorder** — Drag spells on/off bars to customize button order
- **Position modes** — Automatic, locked, or unlocked (drag to move)
- **Customizable background** — Color picker with opacity slider
- **Show/hide borders** — Toggle bar borders via right-click menu
- **Per-spell visibility** — Hide spells you don't use
- **Scalable** — Adjust bar scale in the settings or via slash command
- **Settings panel** — in the same look as the other WoW Forever addons (navy, gold, two columns). Shamans pick the bars' layout there too. Esc > Options > AddOns > FloTotemBar Forever, or **Options...** in a bar's right-click menu
- **Minimap button** — Left-click for settings, right-click to lock/unlock the bars, drag to move it; can be turned off (WoW Forever also lists the addon in the addon compartment)
- **Masque support** — Optional button skinning with Masque

## Screenshots

### Shaman — Totem Bar
![Shaman Totem Bar](https://raw.githubusercontent.com/paradosi/FloTotemBar-Forever/main/media/screenshots/shaman-totem-bar.png)

### Hunter — Trap Bar
![Hunter Trap Bar](https://raw.githubusercontent.com/paradosi/FloTotemBar-Forever/main/media/screenshots/hunter-trap-bar.png)

### Paladin — Seal Bar
![Paladin Seal Bar](https://raw.githubusercontent.com/paradosi/FloTotemBar-Forever/main/media/screenshots/paladin-seal-bar.png)

### Settings
<img src="https://raw.githubusercontent.com/paradosi/FloTotemBar-Forever/main/media/screenshots/settings.jpg" width="560" alt="The FloTotemBar settings panel, as a Shaman">

### Context Menu
![Context Menu](https://raw.githubusercontent.com/paradosi/FloTotemBar-Forever/main/media/screenshots/context-menu.png)

## Help and bug reports

The settings panel (*Esc > Options > AddOns > FloTotemBar Forever*) shows the installed version in its
header, and its **Help and bug reports** button opens this repository's address, ready to copy. Please
[open an issue](https://github.com/paradosi/FloTotemBar-Forever/issues) for problems.

## Slash Commands

| Command | Description |
|---------|-------------|
| `/ftb` | Show help |
| `/ftb options` | Open the settings panel |
| `/ftb minimap` | Show or hide the minimap button |
| `/ftb compact` | Turn compact bars on or off |
| `/ftb lock` | Lock bar position |
| `/ftb unlock` | Unlock bar (drag to move) |
| `/ftb auto` | Automatic positioning above action bars |
| `/ftb scale <num>` | Set bar scale (e.g. `/ftb scale 1.5`) |
| `/ftb borders` | Show borders |
| `/ftb noborders` | Hide borders |
| `/ftb hideblizzard` | Hide Blizzard's own totem bar and totem timers (also in the bar's right-click menu; saved per character; applies after combat if used in combat) |
| `/ftb showblizzard` | Show them again |
| `/ftb reset` | Reset all settings (reloads UI) |

## Installation

1. Download and extract to WoW Forever's AddOns folder: `_forever_/Interface/AddOns/FloTotemBar/` (the folder keeps its old name, so your settings carry over)

2. Log in on a Shaman, Hunter, or Paladin character
3. The bar appears automatically above your action bars
4. Trap and seal timers always run their full length: WoW Forever doesn't let addons read the combat log, so the bar can't tell when a trap is sprung or a seal ends early. Totem timers do follow the real totem

## Optional Dependencies

- **[FloAspectBar Forever](https://github.com/paradosi/FloAspectBar-Forever)** — Hunter aspect bar. Not required: each addon ships its own copy of FloLib. When both are installed, the trap bar docks to the right of the aspect bar
- **Masque** — Button skinning support

## Compatibility

**WoW Forever** (Interface 16001) only.

> [!NOTE]
> Version 1.4.0 was the last one for Classic Era and TBC Anniversary. It stays downloadable on
> CurseForge, Wago and GitHub Releases, but gets no further updates.

## License

[Mozilla Public License 2.0](http://mozilla.org/MPL/2.0/)

The fonts in `media/fonts` (Oswald, JetBrains Mono) are under the SIL Open Font License;
their licence texts are beside them. `Theme.lua` and `Widgets.lua` are shared, unchanged, with
the author's other WoW Forever addons.
