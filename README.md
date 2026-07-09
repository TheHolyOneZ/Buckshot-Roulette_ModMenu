# Buckshot Roulette — Mod Menu

A mod menu / cheat for **Buckshot Roulette** (Godot, Steam **v2.2.0.6**), for
**single-player and multiplayer**. Built on [godot-mod-loader](https://github.com/GodotModding/godot-mod-loader)
as script extensions — no game files are modified on disk, the mod is baked into
a rebuilt executable.

> You must own Buckshot Roulette on Steam. This repo contains **only the mod
> source** — no game code, no game executables. You build against your own copy.

## Features

**Single-player**
- God Mode (no damage)
- Instant-Kill Dealer
- Shell Order ESP (live, with dealer-known-shell reveal)
- Live health readout + heal

**Multiplayer** (host-authoritative — you must **host** the lobby)
- God Mode — incoming shots on you are forced blank
- Instant-Kill — your shots are forced lethal
- Shell Order ESP — reads the real shell sequence, updates on item effects
- All-player health readout + control

### Controls
| Key | Action |
|-----|--------|
| Right Shift | show / hide menu |
| F1 | God Mode |
| F4 | Instant-Kill |
| F3 | Shell Order ESP |
| F5 | Multiplayer Mode |

## Install (for players)

**Precompiled builds (Linux & Windows): https://zlogic.eu/mods/**
Download the `.zip` for your OS, extract it, and run the installer — done.

It applies a small binary patch to *your own* game exe (backed up first) and
swaps in the matching Steam library. Nothing large is downloaded.

- **Linux:** `./install.sh` (needs `zstd`) — `./uninstall.sh` to revert
- **Windows:** `install.ps1` in PowerShell — `uninstall.ps1` to revert

The installer scripts live in [`installer/`](installer/); prefer the packaged
downloads above, which already include the patch and Steam library.

## Build from source

The full pipeline (decompile → integrate mod → GodotSteam engine → export →
binary patch) is documented in **[BUILD.md](BUILD.md)**. Short version: recover the
game project with GDRE, drop the mod source from [`src/`](src/) into
`mods-unpacked/`, import/export with the **GodotSteam 4.1.1** editor + templates
(this is what enables real multiplayer), then produce a `zstd --patch-from` delta
against the stock exe.

## Credits / dependencies
- [godot-mod-loader](https://github.com/GodotModding/godot-mod-loader) (MIT) — mod framework
- [GodotSteam](https://godotsteam.com) (MIT) — Steam integration for Godot 4.1.1
- [GDRE Tools](https://github.com/GDRETools/gdsdecomp) — Godot project recovery
- Buckshot Roulette by Mike Klubnika — not affiliated, not included here

## License

Copyright (C) 2026 **TheHolyOneZ**

Licensed under the **GNU General Public License v3.0** — see [LICENSE](LICENSE).

You may use, study, build, and fork this project freely. If you distribute a
modified version, it **must also be released under the GPL-3.0 and keep this
attribution** — you may not strip the author's name or ship a closed-source
ripoff. Dependencies (GodotSteam, godot-mod-loader) are MIT, which is
GPL-compatible.
