#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/android/BurzenTD"
PRESETS_FILE="$PROJECT_DIR/export_presets.cfg"
RELEASE_VERSION="v0.00.1"
OUTPUT_DIR="$ROOT_DIR/builds/$RELEASE_VERSION"
OUTPUT_APK="$OUTPUT_DIR/BurzenTD_${RELEASE_VERSION}.apk"

usage() {
  cat <<USAGE
Usage: $0 [--dry-run]

Build the Android release APK for $RELEASE_VERSION.
  --dry-run   Validate release metadata and export configuration without invoking Godot.
USAGE
}

validate_release_inputs() {
  if [ ! -f "$PRESETS_FILE" ]; then
    echo "Error: Missing export presets file at $PRESETS_FILE" >&2
    exit 1
  fi

  if ! rg -q '^name="Android"$' "$PRESETS_FILE"; then
    echo "Error: Android export preset not found in $PRESETS_FILE" >&2
    exit 1
  fi

  if [ "$RELEASE_VERSION" != "v0.00.1" ]; then
    echo "Error: release version mismatch; expected v0.00.1, got $RELEASE_VERSION" >&2
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
  echo "Dry run passed: release metadata and Android export preset are valid."
  echo "Expected output artifact: $OUTPUT_APK"
  exit 0
fi

if ! command -v godot4 >/dev/null 2>&1 && ! command -v godot >/dev/null 2>&1; then
  echo "Error: Godot executable not found. Install Godot 4 and retry." >&2
  exit 1
fi

GODOT_BIN="$(command -v godot4 || command -v godot)"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-release "Android" "$OUTPUT_APK"

echo "Release APK built at: $OUTPUT_APK"
