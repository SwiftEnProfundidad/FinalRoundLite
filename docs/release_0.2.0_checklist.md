# Checklist de Release 0.2.0

Ultima actualizacion: 2026-02-25

## 1) Build y salud tecnica (automatizado)
- `✅` Build release del paquete:
  - comando: `bash scripts/build_app.sh`
  - resultado: `.app` generado en `build/FinalRoundLite.app`
- `✅` Validacion de `Info.plist`:
  - comando: `plutil -p build/FinalRoundLite.app/Contents/Info.plist`
  - resultado: `LSUIElement=true`, `LSMinimumSystemVersion=14.0`, `CFBundleIdentifier` correcto.
- `✅` Validacion de firma:
  - comando: `codesign --verify --deep --strict build/FinalRoundLite.app`
  - resultado: verificacion correcta.
- `✅` Validacion de binario:
  - comando: `file build/FinalRoundLite.app/Contents/MacOS/FinalRoundLite`
  - resultado: `Mach-O 64-bit executable arm64`.

## 2) Smoke tecnico del arranque (automatizado)
- `✅` Arranque y permanencia del proceso sin crash temprano:
  - comando: arranque del binario + espera de 5s + cierre controlado.
  - resultado: `SMOKE_LAUNCH_OK`, sin salida de error en log.

## 3) Smoke funcional interactivo GUI (manual)
- `✅` Abrir `build/FinalRoundLite.app` y verificar:
  - `✅` Apertura del panel menubar por automatizacion de accesibilidad (`AXPress`).
  - `✅` `Start` con toggle de audio activo maneja fallo de microfono sin crash y muestra error claro.
  - `✅` Entorno actual sin dispositivo de entrada (`system_profiler SPAudioDataType` -> `Input Channels=0`), por lo que no aplica validacion de `listening` real en esta maquina.
  - `✅` `Importar audio` end-to-end con transcript y sugerencia visible en panel (pregunta actual, guion, clarificaciones, tradeoffs y siguientes pasos).
  - `✅` `Guardar…` con escritura confirmada de archivo `.md` en `build/smoke/smoke_export.md` (1354 bytes).
  - `✅` Con persistencia local activa, se confirma JSON en `~/Library/Application Support/FinalRoundLite/sessions` (conteo de 1 -> 3 y payload con transcript+sugerencia).
  - `✅` `Copiar Markdown` devuelve contenido completo de transcript+sugerencia en portapapeles.

## 4) Smoke automatizado de flujos clave (P3.1)
- `✅` Script reproducible:
  - comando: `bash scripts/qa_smoke_flows.sh`
  - cobertura: start/stop del binario, importacion preflight y export markdown por `SmokeFlowTests`.
  - resultado esperado: `SMOKE_START_STOP_OK` y `SMOKE_IMPORT_EXPORT_OK`.
  - logs generados en: `build/smoke/smoke_launch.log` y `build/smoke/smoke_tests.log`.

## 5) Integracion en ciclo local de release (P3.2)
- `✅` Integracion del smoke en release local:
  - comando: `bash scripts/release_local.sh`
  - comportamiento: build `.app` + ejecucion de `qa_smoke_flows.sh --skip-build`.
  - evidencia automatizada persistida en: `build/smoke/qa_smoke_last_run.txt`.

## 6) Gate canonico de entrega local (P3.3)
- `✅` Comando unico de validacion local:
  - comando canonico: `bash scripts/release_local.sh`
  - valida en un solo flujo: `swift test` completo + build release + smoke automatizado.
  - falla si la evidencia de smoke no corresponde al commit actual.
- `✅` Evidencia automatizada de gate local (ultimo run):
  - archivo: `build/smoke/release_local_gate.txt`
  - `run_at_utc=2026-02-25T14:30:38Z`
  - `commit=22d19c5`
  - `swift_test=SWIFT_TEST_OK`
  - `build_app=BUILD_APP_OK`
  - `qa_smoke=QA_SMOKE_OK`
  - `canonical_command=bash scripts/release_local.sh`
- `✅` Evidencia de smoke enlazada por gate (ultimo run):
  - archivo: `build/smoke/qa_smoke_last_run.txt`
  - `run_at_utc=2026-02-25T14:30:45Z`
  - `smoke_start_stop=SMOKE_START_STOP_OK`
  - `smoke_import_export=SMOKE_IMPORT_EXPORT_OK`
  - logs: `build/smoke/smoke_launch.log` y `build/smoke/smoke_tests.log`

## 7) Visibilidad operativa de evidencia (P3.4)
- `✅` Comando dedicado de lectura y validacion de evidencia:
  - comando: `bash scripts/release_gate_status.sh`
  - valida que gate/smoke existan, esten en `OK` y correspondan al commit actual.
  - salida esperada: `RELEASE_EVIDENCE_STATUS_OK`.
- `✅` Integrado en el gate canonico:
  - `scripts/release_local.sh` ejecuta `scripts/release_gate_status.sh` al final.

## Estado actual
- `P0.3` completado en este entorno con evidencia reproducible de importacion/guardado/persistencia y manejo robusto de ausencia de microfono.
