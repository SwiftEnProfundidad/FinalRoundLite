#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[P3.2] Build .app para ciclo de release local"
bash "$ROOT_DIR/scripts/build_app.sh"

echo "[P3.2] Ejecutar smoke automatizado integrado en release local"
bash "$ROOT_DIR/scripts/qa_smoke_flows.sh" --skip-build

echo "RELEASE_LOCAL_OK"
