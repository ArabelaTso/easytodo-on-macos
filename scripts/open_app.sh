#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$PROJECT_ROOT/dist/EasyTODO.app"

if [[ ! -d "$APP_BUNDLE" ]]; then
    "$PROJECT_ROOT/scripts/package_app.sh"
fi

open "$APP_BUNDLE"
