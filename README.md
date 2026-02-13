<p align="center">
  <img src="https://raw.githubusercontent.com/paradosi/FloTotemBar_TBC/main/media/art/tauren_totem_400x400.png" width="200" alt="FloTotemBar">
</p>

<h1 align="center">FloTotemBar — TBC Classic Anniversary</h1>

Totem, trap, and seal bar addon for **WoW TBC Classic Anniversary** (Interface 20505). Provides class-specific action bars with cooldown timers and keybinding support for **Shamans**, **Hunters**, and **Paladins**.

Originally created by **Floraline** (MPL 2.0). Ported to TBC Classic Anniversary by **paradosi-Dreamscythe**.

## Features

- **Shaman Totem Bars** — 4 separate bars for Earth, Fire, Water, and Air totems with duration timers
- **Hunter Trap Bar** — All 5 traps (Immolation, Freezing, Frost, Explosive, Snake) with cooldown tracking
- **Paladin Seal Bar** — All seals including TBC faction-specific seals (Blood/Vengeance)
- **Click to cast** — Left-click any spell to cast it
- **Cooldown & duration timers** — Visual countdown on active totems and trap cooldowns
- **Multiple layout options** — Shamans can choose from various totem bar arrangements
- **Keybinding support** — Bind keys via WoW's Key Bindings menu
- **Drag to reorder** — Drag spells on/off bars to customize button order
- **Position modes** — Automatic, locked, or unlocked (drag to move)
- **Customizable background** — Color picker with opacity slider
- **Show/hide borders** — Toggle bar borders via right-click menu
- **Per-spell visibility** — Hide spells you don't use
- **Scalable** — Adjust bar scale via slash command
- **ButtonFacade support** — Optional skinning with ButtonFacade/Masque

## Screenshots

### Shaman — Totem Bar
![Shaman Totem Bar](https://raw.githubusercontent.com/paradosi/FloTotemBar_TBC/main/media/screenshots/shaman-totem-bar.png)

### Hunter — Trap Bar
![Hunter Trap Bar](https://raw.githubusercontent.com/paradosi/FloTotemBar_TBC/main/media/screenshots/hunter-trap-bar.png)

### Paladin — Seal Bar
![Paladin Seal Bar](https://raw.githubusercontent.com/paradosi/FloTotemBar_TBC/main/media/screenshots/paladin-seal-bar.png)

### Context Menu
![Context Menu](https://raw.githubusercontent.com/paradosi/FloTotemBar_TBC/main/media/screenshots/context-menu.png)

## Slash Commands

| Command | Description |
|---------|-------------|
| `/ftb` | Show help |
| `/ftb lock` | Lock bar position |
| `/ftb unlock` | Unlock bar (drag to move) |
| `/ftb auto` | Automatic positioning above action bars |
| `/ftb scale <num>` | Set bar scale (e.g. `/ftb scale 1.5`) |
| `/ftb borders` | Show borders |
| `/ftb noborders` | Hide borders |
| `/ftb reset` | Reset all settings (reloads UI) |

## Installation

1. Download and extract to `World of Warcraft/_anniversary_/Interface/AddOns/FloTotemBar/`
2. Log in on a Shaman, Hunter, or Paladin character
3. The bar appears automatically above your action bars

## Optional Dependencies

- **[FloAspectBar](https://github.com/paradosi/FloAspectBar_TBC)** — Hunter aspect bar (shared FloLib library)
- **ButtonFacade** — Button skinning support

## License

[Mozilla Public License 2.0](http://mozilla.org/MPL/2.0/)
