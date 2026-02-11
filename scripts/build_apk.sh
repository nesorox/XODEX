#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/android/BurzenTD"
PRESETS_FILE="$PROJECT_DIR/export_presets.cfg"
RELEASE_VERSION="v0.00.2"
OUTPUT_DIR="$ROOT_DIR/builds/$RELEASE_VERSION"
OUTPUT_APK="$OUTPUT_DIR/BurzenTD_${RELEASE_VERSION}.apk"
CHECKSUM_FILE="$OUTPUT_DIR/checksum.txt"

usage() {
  cat <<USAGE
Usage: $0 [--dry-run]

Build the Android APK for $RELEASE_VERSION.
  --dry-run   Validate project/export metadata and expected artifact path without invoking Godot.
USAGE
}

require_line() {
  local pattern="$1"
  local description="$2"
  if ! rg -q "$pattern" "$PRESETS_FILE"; then
    echo "Error: Missing or invalid $description in $PRESETS_FILE" >&2
    exit 1
  fi
}

validate_release_inputs() {
  if [ ! -f "$PRESETS_FILE" ]; then
    echo "Error: Missing export presets file at $PRESETS_FILE" >&2
    exit 1
  fi

  require_line '^name="Android"$' 'Android preset name'
  require_line '^version/name="0\.00\.2"$' 'version/name'
  require_line '^version/code=2$' 'version/code'
  require_line '^package/unique_name="com\.nesorox\.burzentd"$' 'package/unique_name'
  require_line '^gradle_build/export_format=0$' 'APK export format'
  require_line '^gradle_build/use_gradle_build=false$' 'Use Custom Build disabled'
  require_line '^permissions/internet=false$' 'internet permission disabled'
  require_line '^permissions/access_network_state=false$' 'network state permission disabled'
  require_line '^permissions/read_external_storage=false$' 'read storage permission disabled'
  require_line '^permissions/write_external_storage=false$' 'write storage permission disabled'

  if ! rg -q '^run/main_scene="res://scenes/MainMenu\.tscn"$' "$PROJECT_DIR/project.godot"; then
    echo "Error: Main scene is not locked to res://scenes/MainMenu.tscn" >&2
    exit 1
  fi

  if [ "$RELEASE_VERSION" != "v0.00.2" ]; then
    echo "Error: release version mismatch; expected v0.00.2, got $RELEASE_VERSION" >&2
    exit 1
  fi
}

DRY_RUN=0
case "${1:-}" in
  "") ;;
  --dry-run) DRY_RUN=1 ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

validate_release_inputs
mkdir -p "$OUTPUT_DIR"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run passed: release metadata and Android export configuration are valid."
  echo "Version: $RELEASE_VERSION"
  echo "Expected output artifact: $OUTPUT_APK"
  exit 0
fi

if ! command -v godot4 >/dev/null 2>&1 && ! command -v godot >/dev/null 2>&1; then
  echo "Error: Godot executable not found. Install Godot 4 and retry." >&2
  exit 1
fi

GODOT_BIN="$(command -v godot4 || command -v godot)"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-release "Android" "$OUTPUT_APK"

sha256sum "$OUTPUT_APK" | tee "$CHECKSUM_FILE"

echo "Version: $RELEASE_VERSION"
echo "Release APK built at: $OUTPUT_APK"
echo "Checksum file written to: $CHECKSUM_FILE"
