#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SMOKE_DIR="$ROOT_DIR/build/smoke"
GATE_EVIDENCE_FILE="$SMOKE_DIR/release_local_gate.txt"
SMOKE_EVIDENCE_FILE="$SMOKE_DIR/qa_smoke_last_run.txt"
CLOSE_EVIDENCE_FILE="$SMOKE_DIR/release_close_checklist.txt"
HANDOFF_EVIDENCE_FILE="$SMOKE_DIR/release_handoff_local.txt"

echo "[P3.6] Ejecutar cierre operativo obligatorio"
bash "$ROOT_DIR/scripts/release_close_checklist.sh"

head_commit="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
branch_name="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD)"

if [[ ! -f "$GATE_EVIDENCE_FILE" ]]; then
  echo "ERROR: falta evidencia de gate local: $GATE_EVIDENCE_FILE" >&2
  exit 1
fi

if [[ ! -f "$SMOKE_EVIDENCE_FILE" ]]; then
  echo "ERROR: falta evidencia de smoke local: $SMOKE_EVIDENCE_FILE" >&2
  exit 1
fi

if [[ ! -f "$CLOSE_EVIDENCE_FILE" ]]; then
  echo "ERROR: falta evidencia de cierre local: $CLOSE_EVIDENCE_FILE" >&2
  exit 1
fi

gate_commit="$(grep '^commit=' "$GATE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"
smoke_commit="$(grep '^commit=' "$SMOKE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"
close_commit="$(grep '^head_commit=' "$CLOSE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"
gate_run_at="$(grep '^run_at_utc=' "$GATE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"
smoke_run_at="$(grep '^run_at_utc=' "$SMOKE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"
close_status="$(grep '^release_close_checklist=' "$CLOSE_EVIDENCE_FILE" | cut -d'=' -f2- || true)"

if [[ "$gate_commit" != "$head_commit" ]]; then
  echo "ERROR: gate commit ($gate_commit) no coincide con HEAD ($head_commit)" >&2
  exit 1
fi

if [[ "$smoke_commit" != "$head_commit" ]]; then
  echo "ERROR: smoke commit ($smoke_commit) no coincide con HEAD ($head_commit)" >&2
  exit 1
fi

if [[ "$close_commit" != "$head_commit" ]]; then
  echo "ERROR: close checklist commit ($close_commit) no coincide con HEAD ($head_commit)" >&2
  exit 1
fi

if [[ "$close_status" != "OK" ]]; then
  echo "ERROR: estado de cierre invalido: release_close_checklist=$close_status" >&2
  exit 1
fi

{
  echo "release_handoff_local=OK"
  echo "branch=$branch_name"
  echo "commit=$head_commit"
  echo "gate_run_at_utc=$gate_run_at"
  echo "smoke_run_at_utc=$smoke_run_at"
  echo "mandatory_step_1=bash scripts/release_local.sh"
  echo "mandatory_step_2=bash scripts/release_gate_status.sh"
  echo "mandatory_step_3=bash scripts/release_close_checklist.sh"
  echo "handoff_command=bash scripts/release_handoff_local.sh"
  echo "gate_evidence_file=$GATE_EVIDENCE_FILE"
  echo "smoke_evidence_file=$SMOKE_EVIDENCE_FILE"
  echo "close_evidence_file=$CLOSE_EVIDENCE_FILE"
} >"$HANDOFF_EVIDENCE_FILE"

echo "RELEASE_HANDOFF_LOCAL_OK"
echo " - handoff summary: $HANDOFF_EVIDENCE_FILE"
