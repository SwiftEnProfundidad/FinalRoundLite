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
- `✅` Ultima evidencia automatizada registrada:
  - `run_at_utc=2026-02-25T11:29:52Z`
  - `commit=26d7626`
  - `smoke_start_stop=SMOKE_START_STOP_OK`
  - `smoke_import_export=SMOKE_IMPORT_EXPORT_OK`
  - `launch_log=/Users/juancarlosmerlosalbarracin/Developer/Projects/FinalRoundLite/build/smoke/smoke_launch.log`
  - `test_log=/Users/juancarlosmerlosalbarracin/Developer/Projects/FinalRoundLite/build/smoke/smoke_tests.log`

## Estado actual
- `P0.3` completado en este entorno con evidencia reproducible de importacion/guardado/persistencia y manejo robusto de ausencia de microfono.
