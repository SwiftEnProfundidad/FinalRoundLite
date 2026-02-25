# Backlog Priorizado - Release 0.2.0

Fecha de corte: 2026-02-25

## Objetivo
Publicar `0.2.0` como version usable para practica individual con flujo estable:
- captura en vivo,
- analisis post-sesion por importacion,
- persistencia local opcional.

## Criterio de salida de release
Se considera listo para `0.2.0` cuando todos los items `P0` estan en `✅`.

## P0 (bloqueantes de release)
- `✅` `P0.1` Endurecer importacion de audio:
  - validar extensiones/tipos permitidos y tamano maximo antes de enviar.
  - mostrar mensajes de error claros por causa (archivo invalido, archivo vacio, red, timeout).
- `✅` `P0.2` Cobertura de tests del flujo post-sesion:
  - tests unitarios para casos de error en `analyzeImportedAudio`.
  - test de persistencia disparada al finalizar sesion cuando el toggle esta activo.
- `✅` `P0.3` QA de paquete `.app`:
  - `✅` checklist de release documentada y repetible (`docs/release_0.2.0_checklist.md`).
  - `✅` smoke funcional parcial asistido por script (panel, start/error, copiar markdown, apertura de save panel).
  - `✅` smoke test manual completo en app compilada (importar audio end-to-end con coach, guardar markdown y persistencia JSON).
  - `✅` validacion de ausencia de crash en ruta de `Start` sin dispositivo de entrada de microfono en el entorno actual.

## P1 (importante no bloqueante)
- `✅` `P1.1` Historial local minimo:
  - listar sesiones guardadas y abrir el JSON/Markdown desde la app.
- `✅` `P1.2` Mejoras de usabilidad:
  - boton para limpiar transcript/sugerencias de forma explicita.
  - feedback visual durante analisis post-sesion (estado "analizando").

## P2 (mejora incremental)
- `✅` `P2.1` Ajustes avanzados:
  - opcion para elegir carpeta de persistencia local.
  - limite configurable de retencion de sesiones.
- `✅` `P2.2` Telemetria local no sensible:
  - contador local de sesiones y tiempo de procesamiento promedio.
- `✅` `P2.3` Eliminar `@preconcurrency` en `AudioCaptureService`:
  - migrar conversion de `AVAudioPCMBuffer` a una ruta sin captura non-Sendable en closure `@Sendable`.
  - mantener validacion con tests/construccion en Swift 6.2 strict concurrency.

## P3 (post 0.2.0)
- `✅` `P3.1` QA automatizado de flujos clave:
  - script reproducible para smoke de start/stop, importacion y export markdown.
- `✅` `P3.2` Evidencia automatizada de smoke para entregas:
  - integrar ejecucion de `scripts/qa_smoke_flows.sh` en el ciclo de release local.
  - mantener checklist de QA con evidencia del ultimo run automatizado.
- `✅` `P3.3` Endurecimiento del gate local de entrega:
  - comando unico de validacion (`release_local.sh`) documentado como entrada estandar de release local.
  - checklist alineada con evidencia automatizada y comando canonico.
- `🚧` `P3.4` Endurecimiento operativo del ciclo local:
  - consolidar `release_local.sh` como paso previo obligatorio antes de cierre de release local.
  - mantener visibilidad de evidencia de gate y smoke en documentacion operativa.

## Riesgos abiertos
- Coste y latencia dependen del tamano del audio importado y del modelo configurado.
- Persistencia local puede crecer sin rotacion si no se aplica limite de retencion.
