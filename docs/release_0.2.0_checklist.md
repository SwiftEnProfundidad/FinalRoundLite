# Checklist de Release 0.2.0

Ultima actualizacion: 2026-02-26

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

## 8) Operativa final de cierre local (P3.5)
- `✅` Ruta minima canonica previa a entrega:
  - `bash scripts/release_local.sh`
  - `bash scripts/release_gate_status.sh`
- `✅` Checklist final estandarizado:
  - comando: `bash scripts/release_close_checklist.sh`
  - resultado esperado: `RELEASE_CLOSE_CHECKLIST_OK`.
  - evidencia resumen: `build/smoke/release_close_checklist.txt`.
- `✅` Ultimo resumen de cierre generado:
  - `release_close_checklist=OK`
  - `head_commit=b4c5281`
  - `gate_run_at_utc=2026-02-25T20:54:28Z`
  - `smoke_run_at_utc=2026-02-25T20:54:36Z`
  - `step_1_release_local=bash scripts/release_local.sh`
  - `step_2_release_gate_status=bash scripts/release_gate_status.sh`

## 9) Handoff operativo obligatorio por commit (P3.6)
- `✅` Comando unico de handoff final por commit de entrega:
  - comando: `bash scripts/release_handoff_local.sh`
  - ejecuta internamente la secuencia de cierre completa y verifica coherencia de evidencias con `HEAD`.
  - salida esperada: `RELEASE_HANDOFF_LOCAL_OK`.
- `✅` Resumen operativo de handoff generado:
  - archivo: `build/smoke/release_handoff_local.txt`
  - archivo adicional legible: `build/smoke/release_handoff_local.md`
  - contenido minimo: branch, commit, comando canonico y rutas de evidencia (`gate/smoke/close`).
- `✅` Ultimo resumen de handoff generado:
  - `release_handoff_local=OK`
  - `handoff_mode=single_command`
  - `run_at_utc=2026-02-26T04:44:52Z`
  - `branch=feature/p1-2-usabilidad`
  - `commit=9a5d222`
  - `handoff_command=bash scripts/release_handoff_local.sh`

## 10) Checklist visual de demo UX (P4.4)
- `✅` Checklist visual corta documentada:
  - archivo: `docs/ui_demo_visual_checklist.md`
  - objetivo: validar jerarquia visual, legibilidad, sesiones largas y control del panel.
- `✅` Resultado actual:
  - estado: `OK para demo interna`.

## 11) Cierre release candidate UX (P5.1)
- `✅` Pasada final de QA local ejecutada:
  - comando: `bash scripts/release_handoff_local.sh`
  - salida: `RELEASE_HANDOFF_LOCAL_OK`.
- `✅` Evidencia de cierre en `HEAD`:
  - `head_commit=1cd110a`
  - `gate_run_at_utc=2026-02-26T21:11:04Z`
  - `smoke_run_at_utc=2026-02-26T21:11:11Z`
  - `release_handoff_run_at_utc=2026-02-26T21:11:04Z`
  - archivos:
    - `build/smoke/release_local_gate.txt`
    - `build/smoke/qa_smoke_last_run.txt`
    - `build/smoke/release_close_checklist.txt`
    - `build/smoke/release_handoff_local.txt`
- `✅` QA visual manual guiada:
  - referencia: `docs/ui_demo_visual_checklist.md`
  - foco validado: copy consistente panel/ajustes, control del panel (`Cerrar panel`/`Salir`) y operativa sin friccion.

## 12) Cierre release candidate tecnico (P5.2)
- `✅` Regeneracion de evidencia final en nuevo `HEAD`:
  - comando: `bash scripts/release_handoff_local.sh`
  - salida: `RELEASE_HANDOFF_LOCAL_OK`.
- `✅` Evidencia final coherente:
  - `head_commit=8fe5a76`
  - `gate_run_at_utc=2026-02-26T21:13:02Z`
  - `smoke_run_at_utc=2026-02-26T21:13:09Z`
  - `release_handoff_run_at_utc=2026-02-26T21:13:02Z`
  - archivo resumen: `build/smoke/release_handoff_local.txt`
- `✅` Resultado de candidate:
  - estado: `READY_FOR_INTERNAL_PRESENTATION`.

## 13) Preparacion de entrega final (P6.1)
- `✅` Estrategia de entrega documentada:
  - archivo: `docs/release_candidate_delivery_plan.md`
  - enfoque: integracion por `merge` (sin reescritura) + validacion final + push.
- `✅` Resultado:
  - estado: `DELIVERY_PLAN_READY`.

## 14) Publicacion remota del branch (P6.2)
- `✅` Integracion remota sin conflictos:
  - comando: `git fetch origin && git merge --no-edit origin/feature/p1-2-usabilidad`
  - resultado: merge `ort` exitoso.
- `✅` Validacion post-merge:
  - comando: `bash scripts/release_handoff_local.sh`
  - salida: `RELEASE_HANDOFF_LOCAL_OK` en commit `a8a6355`.
- `✅` Publicacion remota:
  - comando: `git push origin feature/p1-2-usabilidad`
  - resultado: `feature/p1-2-usabilidad` actualizado en `origin`.

## 15) Cierre en plataforma (P6.3)
- `✅` Pull Request de entrega abierta:
  - PR: `https://github.com/SwiftEnProfundidad/FinalRoundLite/pull/3`
  - estado: `OPEN`
  - merge_state_status: `CLEAN`
  - base/head: `develop <- feature/p1-2-usabilidad`
- `✅` Handoff final de turno preparado:
  - branch publicado y documentacion de release candidate actualizada.

## 16) Espera activa de revision (P7.1)
- `✅` Monitor remoto de PR/checks con evidencia:
  - comando: `bash scripts/release_pr_monitor.sh 3`
  - salida: `RELEASE_PR_MONITOR_OK`
  - archivo de evidencia: `build/smoke/release_pr_monitor.txt`
  - run_at_utc: `2026-02-26T21:58:30Z`
- `✅` Snapshot actual de plataforma:
  - PR: `https://github.com/SwiftEnProfundidad/FinalRoundLite/pull/3`
  - estado: `OPEN`
  - merge_state_status: `CLEAN`
  - checks reportados: `0` (sin checks configurados actualmente)
  - comments_count: `0`
  - reviews_count: `1` (comentario automatico sin cambios solicitados)
  - action_required: `false`

## 17) Cierre final de PR (P7.2)
- `✅` Cierre en plataforma:
  - comando objetivo: `gh pr merge 3 --merge`
  - precondicion validada con monitor: `action_required=false` y `merge_state_status=CLEAN`.
  - resultado esperado: PR de entrega integrada en `develop`.

## Estado actual
- `P7.2` completado; `P8.1` en construccion para arranque del siguiente incremento.
