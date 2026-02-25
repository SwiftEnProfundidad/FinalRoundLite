#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/build/FinalRoundLite.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/FinalRoundLite"
SMOKE_DIR="$ROOT_DIR/build/smoke"
LAUNCH_LOG="$SMOKE_DIR/smoke_launch.log"
TEST_LOG="$SMOKE_DIR/smoke_tests.log"

mkdir -p "$SMOKE_DIR"

echo "[P3.1] Build release app bundle"
bash "$ROOT_DIR/scripts/build_app.sh" >/dev/null

if [[ ! -x "$APP_BINARY" ]]; then
  echo "ERROR: no se encontro binario ejecutable en $APP_BINARY" >&2
  exit 1
fi

echo "[P3.1] Smoke start/stop del binario"
"$APP_BINARY" >"$LAUNCH_LOG" 2>&1 &
APP_PID=$!
sleep 4
if ! kill -0 "$APP_PID" 2>/dev/null; then
  echo "ERROR: el proceso de la app termino antes del stop controlado" >&2
  exit 1
fi
kill "$APP_PID" >/dev/null 2>&1 || true
wait "$APP_PID" 2>/dev/null || true
echo "SMOKE_START_STOP_OK"

echo "[P3.1] Smoke import/export y estabilidad por tests"
if swift test --filter SmokeFlowTests >"$TEST_LOG" 2>&1; then
  echo "SMOKE_IMPORT_EXPORT_OK"
else
  cat "$TEST_LOG" >&2
  echo "ERROR: fallaron los smoke tests de flujo" >&2
  exit 1
fi

echo "[P3.1] Smoke completado"
echo " - launch log: $LAUNCH_LOG"
echo " - test log:   $TEST_LOG"
