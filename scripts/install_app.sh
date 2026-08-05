#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="EasyTODO.app"
SOURCE_APP="$PROJECT_ROOT/dist/$APP_NAME"
DESTINATION_APP="/Applications/$APP_NAME"

"$PROJECT_ROOT/scripts/package_app.sh"

if [[ -d "$DESTINATION_APP" ]]; then
    rm -rf "$DESTINATION_APP"
fi

ditto "$SOURCE_APP" "$DESTINATION_APP"
open "$DESTINATION_APP"

echo "Installed and launched: $DESTINATION_APP"
