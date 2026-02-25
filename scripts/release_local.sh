#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SMOKE_EVIDENCE_FILE="$ROOT_DIR/build/smoke/qa_smoke_last_run.txt"
GATE_EVIDENCE_FILE="$ROOT_DIR/build/smoke/release_local_gate.txt"
RUN_AT_UTC="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
COMMIT_SHA="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"

echo "[P3.3] Validacion canonica de entrega local"

echo "[P3.3] 1/3 - Test suite completa"
swift test >/dev/null

echo "[P3.3] 2/3 - Build .app release"
bash "$ROOT_DIR/scripts/build_app.sh" >/dev/null

echo "[P3.3] 3/3 - Smoke automatizado integrado"
bash "$ROOT_DIR/scripts/qa_smoke_flows.sh" --skip-build

if [[ ! -f "$SMOKE_EVIDENCE_FILE" ]]; then
  echo "ERROR: no se encontro evidencia de smoke en $SMOKE_EVIDENCE_FILE" >&2
  exit 1
fi

if ! grep -q "^commit=${COMMIT_SHA}$" "$SMOKE_EVIDENCE_FILE"; then
  echo "ERROR: la evidencia de smoke no corresponde al commit actual $COMMIT_SHA" >&2
  exit 1
fi

if ! grep -q "^smoke_start_stop=SMOKE_START_STOP_OK$" "$SMOKE_EVIDENCE_FILE"; then
  echo "ERROR: smoke start/stop no esta en estado OK" >&2
  exit 1
fi

if ! grep -q "^smoke_import_export=SMOKE_IMPORT_EXPORT_OK$" "$SMOKE_EVIDENCE_FILE"; then
  echo "ERROR: smoke import/export no esta en estado OK" >&2
  exit 1
fi

{
  echo "run_at_utc=$RUN_AT_UTC"
  echo "commit=$COMMIT_SHA"
  echo "swift_test=SWIFT_TEST_OK"
  echo "build_app=BUILD_APP_OK"
  echo "qa_smoke=QA_SMOKE_OK"
  echo "canonical_command=bash scripts/release_local.sh"
  echo "smoke_evidence_file=$SMOKE_EVIDENCE_FILE"
} >"$GATE_EVIDENCE_FILE"

echo "RELEASE_LOCAL_GATE_OK"
echo " - gate evidence: $GATE_EVIDENCE_FILE"
