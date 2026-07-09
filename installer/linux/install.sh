#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH="$HERE/br_2206.patch.zst"
STEAMLIB="$HERE/libsteam_api.so"

EXE_NAME="Buckshot Roulette.x86_64"
TARGET_VERSION="Steam v2.2.0.6"
STOCK_SHA="4d320ab0264743e15f8c5b137237787a3986af85d82d4b6c79adeccbe74438c4"
MODDED_SHA="4a681d91cd27714b67ecbc9e902e3f8c644ba7feea3bbc9ac657c97cc3e1b04d"

say()  { printf '\033[1;36m[modmenu]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

command -v zstd >/dev/null || die "zstd is not installed. Install it (e.g. 'sudo pacman -S zstd' / 'sudo apt install zstd') and re-run."
[ -f "$PATCH" ]  || die "Missing patch file next to this script: $PATCH"
[ -f "$STEAMLIB" ] || die "Missing libsteam_api.so next to this script: $STEAMLIB"

GAME_DIR="${1:-}"
if [ -z "$GAME_DIR" ]; then
  say "No path given — searching common Steam locations..."
  CANDIDATES=(
    "$HOME/.steam/steam/steamapps/common/Buckshot Roulette/Buckshot Roulette_linux"
    "$HOME/.local/share/Steam/steamapps/common/Buckshot Roulette/Buckshot Roulette_linux"
    "/run/media/$USER"/*/SteamLibrary/steamapps/common/"Buckshot Roulette/Buckshot Roulette_linux"
  )
  for c in "${CANDIDATES[@]}"; do
    [ -f "$c/$EXE_NAME" ] && { GAME_DIR="$c"; break; }
  done
fi
[ -n "$GAME_DIR" ] && [ -f "$GAME_DIR/$EXE_NAME" ] \
  || die "Could not find '$EXE_NAME'. Re-run with the game folder as an argument:
        ./install.sh \"/path/to/Buckshot Roulette_linux\""

STOCK="$GAME_DIR/$EXE_NAME"
say "Game folder: $GAME_DIR"

say "Verifying game version ($TARGET_VERSION)..."
CUR_SHA="$(sha256sum "$STOCK" | cut -d' ' -f1)"
if [ "$CUR_SHA" = "$MODDED_SHA" ]; then
  say "This exe is ALREADY patched. Making sure the mod is in place, then done."
elif [ "$CUR_SHA" != "$STOCK_SHA" ]; then
  die "This exe does not match $TARGET_VERSION.
        Expected stock sha256: $STOCK_SHA
        Found:                 $CUR_SHA
        The game was probably updated. A version-matched patch is needed instead."
fi

BACKUP="$GAME_DIR/$EXE_NAME.stock.bak"
if [ "$CUR_SHA" = "$STOCK_SHA" ]; then
  if [ ! -f "$BACKUP" ]; then
    say "Backing up original exe -> $(basename "$BACKUP")"
    cp -f "$STOCK" "$BACKUP"
  fi
  say "Applying patch..."
  TMP="$STOCK.tmp.$$"
  zstd -q -d --long=31 --patch-from="$BACKUP" "$PATCH" -o "$TMP" -f
  OUT_SHA="$(sha256sum "$TMP" | cut -d' ' -f1)"
  [ "$OUT_SHA" = "$MODDED_SHA" ] || { rm -f "$TMP"; die "Patched exe hash mismatch — aborting, original untouched."; }
  mv -f "$TMP" "$STOCK"
  chmod +x "$STOCK"
  say "Patch applied and verified."
fi

STEAM_TARGET="$GAME_DIR/libsteam_api.so"
STEAM_BACKUP="$GAME_DIR/libsteam_api.so.stock.bak"
if [ -f "$STEAM_TARGET" ] && [ ! -f "$STEAM_BACKUP" ]; then
  say "Backing up stock libsteam_api.so -> $(basename "$STEAM_BACKUP")"
  cp -f "$STEAM_TARGET" "$STEAM_BACKUP"
fi
say "Installing Steam library..."
cp -f "$STEAMLIB" "$STEAM_TARGET"

mkdir -p "$GAME_DIR/mods"

cat <<EOF

$(printf '\033[1;32m')Done!$(printf '\033[0m') Launch the game from Steam.
   [Right Shift] menu   F1 God Mode   F4 Instant-Kill   F3 Shell ESP   F5 Multiplayer
   (multiplayer cheats require you to HOST the lobby)

Uninstall: ./uninstall.sh
EOF
