#!/bin/bash
set -e

EMULATOR=~/Android/sdk/emulator/emulator
ADB=~/Android/sdk/platform-tools/adb
FLUTTER=/home/anoir/flutter/bin/flutter
AVD=Pixel7
PROJECT=~/Desktop/Projects/LocusToDo

echo "→ Starting Docker..."
cd $PROJECT
docker compose up -d

# Start API only if port 3000 is free
if ! ss -tlnp | grep -q ':3000 '; then
  echo "→ Starting API..."
  pnpm dev:api &
  API_PID=$!
else
  echo "✓ API already running on :3000"
  API_PID=""
fi

# Start emulator only if none is running
if ! $ADB devices | grep -q 'emulator'; then
  echo "→ Starting emulator..."
  $EMULATOR -avd $AVD -no-metrics -no-snapshot-save 2>/dev/null &
  EMU_PID=$!
  echo "→ Waiting for emulator to boot..."
  $ADB wait-for-device
  while [ "$($ADB shell getprop sys.boot_completed 2>/dev/null)" != "1" ]; do
    sleep 2
  done
  echo "✓ Emulator ready"
else
  echo "✓ Emulator already running"
  EMU_PID=""
fi

echo "→ Running Flutter app..."
cd $PROJECT/apps/mobile
$FLUTTER run --no-enable-impeller

# Cleanup only what we started
[ -n "$API_PID" ] && kill $API_PID 2>/dev/null
[ -n "$EMU_PID" ] && kill $EMU_PID 2>/dev/null
