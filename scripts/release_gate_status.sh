#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE_EVIDENCE_FILE="$ROOT_DIR/build/smoke/release_local_gate.txt"
SMOKE_EVIDENCE_FILE="$ROOT_DIR/build/smoke/qa_smoke_last_run.txt"
HEAD_COMMIT="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"

if [[ ! -f "$GATE_EVIDENCE_FILE" ]]; then
  echo "ERROR: falta evidencia de gate local: $GATE_EVIDENCE_FILE" >&2
  exit 1
fi

if [[ ! -f "$SMOKE_EVIDENCE_FILE" ]]; then
  echo "ERROR: falta evidencia de smoke local: $SMOKE_EVIDENCE_FILE" >&2
  exit 1
fi

gate_commit="$(grep '^commit=' "$GATE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"
smoke_commit="$(grep '^commit=' "$SMOKE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"
gate_status="$(grep '^qa_smoke=' "$GATE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"
smoke_start_stop="$(grep '^smoke_start_stop=' "$SMOKE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"
smoke_import_export="$(grep '^smoke_import_export=' "$SMOKE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"
gate_run_at="$(grep '^run_at_utc=' "$GATE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"
smoke_run_at="$(grep '^run_at_utc=' "$SMOKE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"

if [[ "$gate_commit" != "$HEAD_COMMIT" ]]; then
  echo "ERROR: gate evidence commit ($gate_commit) no coincide con HEAD ($HEAD_COMMIT)" >&2
  exit 1
fi

if [[ "$smoke_commit" != "$HEAD_COMMIT" ]]; then
  echo "ERROR: smoke evidence commit ($smoke_commit) no coincide con HEAD ($HEAD_COMMIT)" >&2
  exit 1
fi

if [[ "$gate_status" != "QA_SMOKE_OK" ]]; then
  echo "ERROR: estado de gate invalido: qa_smoke=$gate_status" >&2
  exit 1
fi

if [[ "$smoke_start_stop" != "SMOKE_START_STOP_OK" ]]; then
  echo "ERROR: estado de smoke start/stop invalido: $smoke_start_stop" >&2
  exit 1
fi

if [[ "$smoke_import_export" != "SMOKE_IMPORT_EXPORT_OK" ]]; then
  echo "ERROR: estado de smoke import/export invalido: $smoke_import_export" >&2
  exit 1
fi

echo "RELEASE_EVIDENCE_STATUS_OK"
echo " - head_commit: $HEAD_COMMIT"
echo " - gate_run_at: $gate_run_at"
echo " - smoke_run_at: $smoke_run_at"
echo " - gate_file: $GATE_EVIDENCE_FILE"
echo " - smoke_file: $SMOKE_EVIDENCE_FILE"
