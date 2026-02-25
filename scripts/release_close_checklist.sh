#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SMOKE_DIR="$ROOT_DIR/build/smoke"
SUMMARY_FILE="$SMOKE_DIR/release_close_checklist.txt"
GATE_EVIDENCE_FILE="$SMOKE_DIR/release_local_gate.txt"
SMOKE_EVIDENCE_FILE="$SMOKE_DIR/qa_smoke_last_run.txt"

mkdir -p "$SMOKE_DIR"

echo "[P3.5] Paso 1/2 - Gate canonico de release local"
bash "$ROOT_DIR/scripts/release_local.sh"

echo "[P3.5] Paso 2/2 - Validacion de visibilidad de evidencia"
gate_status_output="$(bash "$ROOT_DIR/scripts/release_gate_status.sh")"
echo "$gate_status_output"

head_commit="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
gate_run_at="$(grep '^run_at_utc=' "$GATE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"
smoke_run_at="$(grep '^run_at_utc=' "$SMOKE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"

{
  echo "release_close_checklist=OK"
  echo "head_commit=$head_commit"
  echo "gate_run_at_utc=$gate_run_at"
  echo "smoke_run_at_utc=$smoke_run_at"
  echo "step_1_release_local=bash scripts/release_local.sh"
  echo "step_2_release_gate_status=bash scripts/release_gate_status.sh"
  echo "gate_evidence_file=$GATE_EVIDENCE_FILE"
  echo "smoke_evidence_file=$SMOKE_EVIDENCE_FILE"
} >"$SUMMARY_FILE"

echo "RELEASE_CLOSE_CHECKLIST_OK"
echo " - summary: $SUMMARY_FILE"
