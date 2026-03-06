#!/usr/bin/env bash
set -euo pipefail

SCHEME="Pomodoro"
ARCHIVE="$HOME/Desktop/MacPomodoro.xcarchive"
EXPORT_DIR="$HOME/Desktop/MacPomodoroExport"
EXPORT_PLIST="$(dirname "$0")/export-options.plist"

echo "==> Archiving $SCHEME..."
xcodebuild \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE" \
  archive

echo "==> Exporting .app..."
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_PLIST"

echo
echo "Done. App exported to: $EXPORT_DIR/MacPomodoro.app"
echo "Install:  cp -R \"$EXPORT_DIR/MacPomodoro.app\" /Applications/"
echo "Unquarantine (on each machine after copying):"
echo "  xattr -cr /Applications/MacPomodoro.app"
