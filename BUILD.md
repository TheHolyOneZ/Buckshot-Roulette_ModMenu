# Building from source

This rebuilds the modded executable and produces the small distributable patch.
Everything runs on Linux (you can cross-export the Windows build from Linux too).

## Tools

| Tool | Version | Purpose |
|------|---------|---------|
| [GDRE Tools](https://github.com/GDRETools/gdsdecomp/releases) | v2.6.0-beta.4 | recover the game's GDScript project from the exe |
| [GodotSteam](https://codeberg.org/godotsteam/godotsteam/releases) editor + templates | **v4.2.3 (Godot 4.1.1, Steamworks 1.57)** | engine that provides real `Steam` — required for multiplayer |
| [godot-mod-loader](https://github.com/GodotModding/godot-mod-loader/releases) | **v7.0.1** | mod framework (v7.1+/BRMLNeo need Godot 4.4+, won't parse on 4.1.1) |
| [zstd](https://github.com/facebook/zstd/releases) | 1.5.x | binary delta patch |

> **Use the GodotSteam engine, not vanilla Godot + a Steam stub.** Vanilla Godot has
> no `Steam` singleton, so people stub it out — but that kills multiplayer (Buckshot
> Roulette MP is Steam-networked). The GodotSteam 4.1.1 build (which the game itself
> ships as `custom_build.bd6af8e0e`) is what makes MP work. Its bundle also contains
> Windows/Mac templates, so all platforms build from one machine.

## Pipeline

1. **Recover the project**
   ```
   gdre_tools.x86_64 --headless --recover="<stock game exe>" --output=br_project
   ```

2. **Add the mod loader** — copy `addons/mod_loader` (+ `addons/JSON_Schema_Validator`)
   into `br_project/addons/`, and splice the mod-loader `global_script_class_cache`
   entries into `br_project/.godot/global_script_class_cache.cfg`.

3. **Drop in the mod** — copy [`src/TheHolyOneZ-BuckshotRouletteModMenu/`](src/)
   into `br_project/mods-unpacked/`.

4. **Autoloads** — in `project.godot`, order: `ModLoaderStore`, `ModLoader`, then the
   game's own autoloads. **Do not** add a `Steam` autoload — the GodotSteam engine
   provides the `Steam` singleton itself. (`GlobalSteam` = the game's own wrapper, keep it.)

5. **Export templates** — point `export_presets.cfg` `custom_template/release` (+ debug)
   at the GodotSteam templates (`linux-411-template.x86_64`, `win64-411-template.exe`).

6. **Verify import** (use the GodotSteam editor, not vanilla):
   ```
   linux-411-editor.x86_64 --headless --path br_project --import
   ```
   Expect `SUCCESS ModLoader: DONE: Installed all script extensions` and no
   non-benign `SCRIPT ERROR`s. (`Class "X" hides a global script class` is benign,
   one per path-based extension.)

7. **Export**
   ```
   linux-411-editor.x86_64 --headless --path br_project --export-release "Linux"  <out>.x86_64
   linux-411-editor.x86_64 --headless --path br_project --export-release "Windows Desktop" <out>.exe
   ```

8. **Delta + round-trip verify**
   ```
   zstd -19 --long=31 --patch-from="<stock exe>" "<modded exe>" -o patch.zst
   zstd -d  --long=31 --patch-from="<stock exe>" patch.zst -o test && sha256sum test "<modded exe>"
   ```

9. **Ship** — the installer applies the patch to the recipient's own stock exe and
   swaps in the GodotSteam Steam library (`libsteam_api.so` / `steam_api64.dll`),
   which the modded exe links against.

## Mod structure

- `mod_main.gd` — registers the script extensions
- `state.gd` — the menu UI, hotkeys, and all cheat state / logic
- `extensions/scripts/*.gd` — single-player hooks (`extends "res://scripts/…"`)
- `extensions/scripts/mp/*.gd` — multiplayer hooks (`extends "res://multiplayer/scripts/…"`);
  `MP_PacketVerification.gd` runs host-side and rewrites shot outcomes, which is what
  makes MP cheats take real, synced effect on other players.
