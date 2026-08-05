#!/usr/bin/env bash
set -euo pipefail

APP_NAME="EasyTODO"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$PROJECT_ROOT/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_ROOT="$DIST_DIR/dmg-root"
DMG_PATH="$DIST_DIR/$APP_NAME-macOS.dmg"

if ! command -v hdiutil >/dev/null 2>&1; then
    echo "hdiutil is required to create a macOS DMG." >&2
    exit 1
fi

"$PROJECT_ROOT/scripts/package_app.sh"

case "$DMG_ROOT" in
    "$PROJECT_ROOT"/dist/dmg-root)
        rm -rf "$DMG_ROOT"
        ;;
    *)
        echo "Refusing to remove unexpected DMG root: $DMG_ROOT" >&2
        exit 1
        ;;
esac

mkdir -p "$DMG_ROOT"
ditto "$APP_BUNDLE" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"

rm -f "$DMG_PATH"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

rm -rf "$DMG_ROOT"

echo "Installer DMG: $DMG_PATH"
