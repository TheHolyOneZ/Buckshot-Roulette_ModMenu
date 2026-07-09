#!/usr/bin/env bash
set -euo pipefail
EXE_NAME="Buckshot Roulette.x86_64"
GAME_DIR="${1:-}"
if [ -z "$GAME_DIR" ]; then
  for c in \
    "$HOME/.steam/steam/steamapps/common/Buckshot Roulette/Buckshot Roulette_linux" \
    "$HOME/.local/share/Steam/steamapps/common/Buckshot Roulette/Buckshot Roulette_linux" \
    /run/media/"$USER"/*/SteamLibrary/steamapps/common/"Buckshot Roulette/Buckshot Roulette_linux"; do
    [ -f "$c/$EXE_NAME.stock.bak" ] && { GAME_DIR="$c"; break; }
  done
fi
[ -n "$GAME_DIR" ] && [ -f "$GAME_DIR/$EXE_NAME.stock.bak" ] \
  || { echo "No backup found. Pass the game folder as an argument." >&2; exit 1; }
mv -f "$GAME_DIR/$EXE_NAME.stock.bak" "$GAME_DIR/$EXE_NAME"
chmod +x "$GAME_DIR/$EXE_NAME"
if [ -f "$GAME_DIR/libsteam_api.so.stock.bak" ]; then
  mv -f "$GAME_DIR/libsteam_api.so.stock.bak" "$GAME_DIR/libsteam_api.so"
fi
rm -rf "$GAME_DIR/mods"
echo "Restored stock exe + Steam library in: $GAME_DIR"
