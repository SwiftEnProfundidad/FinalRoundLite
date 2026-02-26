# Seguimiento por fases

Ultima actualizacion: 2026-02-25

## Leyenda
- `✅ Hecho`
- `🚧 En construccion`
- `⏳ Pendiente`
- `⛔ Bloqueado`

Regla: solo puede existir una tarea en `🚧 En construccion`.

## Fase 0 - Gobernanza del repositorio
- `✅` Crear `AGENTS.md` local del repo.
- `✅` Crear tracking por fases con leyenda y estados.
- `✅` Inicializar repo Git local y commit inicial del proyecto.
- `✅` Endurecer `AGENTS.md` para tratar skills iOS prioritarias como contrato hard no negociable.
- `✅` Traducir `AGENTS.md` completamente al espanol y endurecer GitFlow/ramas nombradas como contrato hard.
- `✅` Anadir plantilla hard de trazabilidad por turno (`archivo | skill | regla | evidencia | estado`) y convencion GitFlow de ramas nombradas.
- `✅` Ampliar contrato hard para incluir tambien `windsurf-rules-frontend`, `windsurf-rules-backend` y `windsurf-rules-android` por ambito.
- `✅` Corregir incoherencias de redaccion en `AGENTS.md` (skills siempre disponibles vs aplicables por ambito, y conflicto vendorizado/local con regla mas estricta).
- `✅` Vendorizar skills hard en `docs/codex-skills/*.md` y crear script de sincronizacion reproducible.

## Fase 1 - Base de producto (MVP local)
- `✅` Menubar app SwiftUI con panel de control.
- `✅` Configuracion y guardado de API key en Keychain.
- `✅` Context Card editable para System Design.
- `✅` Export de sesion a Markdown (copiar y guardar archivo).

## Fase 2 - Flujo de audio e IA
- `✅` Captura de microfono con chunking PCM16 + VAD ligero.
- `✅` Transcripcion por OpenAI `/v1/audio/transcriptions`.
- `✅` Coach estructurado por JSON schema via `/v1/responses`.
- `✅` Throttle de sugerencias por evento (8s / 15s low cost).

## Fase 3 - Calidad y disciplina BDD/TDD
- `✅` Iniciar ciclo obligatorio RED -> GREEN -> REFACTOR para `AppCoordinator` y `OpenAIClient`.
- `✅` Agregar tests RED para errores de red, parseo invalido y throttle.
- `✅` Implementar GREEN minimo para los RED anteriores.
- `✅` Refactor de servicios manteniendo tests en verde.
- `✅` Documentar escenarios BDD del flujo principal (Start -> Transcript -> Coach -> Export).

## Fase 4 - Siguiente incremento funcional
- `✅` Modo post-sesion (importar audio y analizar sin captura en vivo).
- `✅` Persistencia local opcional de sesiones (desactivada por defecto).
- `✅` Definir backlog priorizado para release `0.2.0`.

## Fase 5 - Endurecimiento para release 0.2.0
- `✅` Endurecer importacion de audio (validaciones de archivo + errores claros).
- `✅` Ampliar cobertura de tests del flujo post-sesion y persistencia.
- `✅` Crear checklist de release `0.2.0` con evidencia automatizada.
- `✅` Ejecutar smoke funcional parcial asistido por script (panel/start-error/copy/save-panel).
- `✅` Completar smoke funcional manual end-to-end de `.app` (importar audio + coach visible + guardar markdown + persistencia JSON + manejo robusto sin microfono en entorno actual).

## Fase 6 - Post release 0.2.0
- `✅` Auditoria y correccion de cumplimiento de skills iOS prioritarias (`windsurf-rules-ios`, `swift-concurrency`, `swiftui-expert-skill`) en codigo y tests.
- `✅` Implementar `P1.1` Historial local minimo (listar sesiones guardadas y abrir JSON/Markdown desde la app).
- `✅` Implementar `P1.2` mejoras de usabilidad (limpieza explicita y estado "analizando").
- `✅` Implementar `P2.1` ajustes avanzados (carpeta de persistencia y retencion configurable).
- `✅` Implementar `P2.2` telemetria local no sensible (contador de sesiones y tiempo de procesamiento promedio).
- `✅` Implementar `P2.3` eliminacion de `@preconcurrency` en `AudioCaptureService` con validacion en Swift 6.2 strict concurrency.
- `✅` Implementar `P3.1` QA automatizado de flujos clave (start/stop, importacion, export markdown).
- `✅` Implementar `P3.2` evidencia automatizada de smoke en ciclo de release local.
- `✅` Implementar `P3.3` endurecimiento del gate local de entrega con comando canonico de release.
- `✅` Implementar `P3.4` endurecimiento operativo del ciclo local de release y evidencia.
- `✅` Implementar `P3.5` operativa de cierre de release local con secuencia canonica final.
- `✅` Implementar `P3.6` cierre operacional del ciclo local de release y handoff.
- `✅` Implementar `P3.7` handoff final de entrega con comando unico obligatorio.
- `✅` Implementar `P4.1` checkpoint UI/UX visual del panel para revision guiada.
- `✅` Implementar `P4.2` ajustes visuales guiados por feedback de revision UI/UX.
- `✅` Implementar `P4.3` cierre visual de menubar para demo con feedback final de UX.
- `✅` Implementar `P4.4` pulido final de demo UX (copy + consistencia visual).
- `✅` Implementar `P5.1` cierre de release candidate UX (QA visual + smoke local final).
- `✅` Implementar `P5.2` cierre de release candidate tecnico (evidencia final en HEAD + handoff de entrega).
- `✅` Implementar `P6.1` preparacion de entrega final (push/merge + handoff al siguiente turno).
- `✅` Implementar `P6.2` ejecucion de publicacion remota (sincronizacion + push de branch).
- `🚧` Implementar `P6.3` cierre de entrega en plataforma (estado PR/merge + handoff final).
