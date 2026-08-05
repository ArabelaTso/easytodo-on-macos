#!/usr/bin/env bash
set -euo pipefail

APP_NAME="EasyTODO"
BUNDLE_ID="${BUNDLE_ID:-com.easytodo.EasyTODO}"
VERSION="${VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
CONFIGURATION="${CONFIGURATION:-release}"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$PROJECT_ROOT/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
INFO_PLIST="$CONTENTS_DIR/Info.plist"
ICON_SOURCE="$PROJECT_ROOT/Sources/EasyTODO/Resources/logo.png"
ICONSET_DIR="$DIST_DIR/$APP_NAME.iconset"
ICON_FILE="$RESOURCES_DIR/$APP_NAME.icns"
ZIP_PATH="$DIST_DIR/$APP_NAME-macOS.zip"

cd "$PROJECT_ROOT"

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$PROJECT_ROOT/.build/clang-module-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

swift build -c "$CONFIGURATION"
BUILD_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
EXECUTABLE="$BUILD_DIR/$APP_NAME"
RESOURCE_BUNDLE="$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle"

if [[ ! -x "$EXECUTABLE" ]]; then
    echo "Missing built executable: $EXECUTABLE" >&2
    exit 1
fi

mkdir -p "$DIST_DIR"

if [[ -e "$APP_BUNDLE" ]]; then
    case "$APP_BUNDLE" in
        "$PROJECT_ROOT"/dist/*.app)
            rm -rf "$APP_BUNDLE"
            ;;
        *)
            echo "Refusing to remove unexpected app path: $APP_BUNDLE" >&2
            exit 1
            ;;
    esac
fi

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
install -m 755 "$EXECUTABLE" "$MACOS_DIR/$APP_NAME"

if [[ -d "$RESOURCE_BUNDLE" ]]; then
    cp -R "$RESOURCE_BUNDLE" "$RESOURCES_DIR/"
fi

if [[ -f "$ICON_SOURCE" ]]; then
    cp "$ICON_SOURCE" "$RESOURCES_DIR/logo.png"
fi

if command -v sips >/dev/null 2>&1 && command -v iconutil >/dev/null 2>&1 && [[ -f "$ICON_SOURCE" ]]; then
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"
    sips -z 16 16 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
    sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
    sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
    sips -z 64 64 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
    sips -z 128 128 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
    sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
    sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
    sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
    sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
    cp "$ICON_SOURCE" "$ICONSET_DIR/icon_512x512@2x.png"
    iconutil -c icns "$ICONSET_DIR" -o "$ICON_FILE"
    rm -rf "$ICONSET_DIR"
fi

cat > "$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
PLIST

printf "APPL????" > "$CONTENTS_DIR/PkgInfo"
plutil -lint "$INFO_PLIST" >/dev/null

if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null
fi

rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo "Packaged app: $APP_BUNDLE"
echo "Installable zip: $ZIP_PATH"
