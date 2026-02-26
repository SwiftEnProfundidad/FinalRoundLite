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
- `✅` `P3.4` Endurecimiento operativo del ciclo local:
  - consolidar `release_local.sh` como paso previo obligatorio antes de cierre de release local.
  - mantener visibilidad de evidencia de gate y smoke en documentacion operativa.
- `✅` `P3.5` Operativa de cierre de release local:
  - estandarizar checklist final de cierre usando `release_local.sh` + `release_gate_status.sh`.
  - documentar ruta minima de comandos para validacion final previa a entrega.
- `✅` `P3.6` Cierre operacional del ciclo:
  - consolidar checklist final de release local como paso de handoff obligatorio.
  - mantener actualizacion de evidencia (gate/smoke/close checklist) por commit de entrega.
- `✅` `P3.7` Handoff final de entrega:
  - consolidar comando unico de handoff en documentacion de cierre.
  - mantener salida de handoff como resumen operativo para entrega al siguiente turno.

## P4 (iteracion UX/UI)
- `✅` `P4.1` Checkpoint de UI/UX visual:
  - preparar un corte de UI funcional del panel para revision visual guiada.
  - validar jerarquia visual y legibilidad de estados antes de ajustes de estilo.
- `✅` `P4.2` Ajustes visuales guiados por feedback:
  - aplicar iteracion de layout/espaciado/tipografia segun review visual.
  - cerrar detalles de legibilidad final para transcript, coach y estados del panel.
- `✅` `P4.3` Cierre visual de menubar para demo:
  - validar comportamiento del panel en sesiones largas (scroll y densidad de informacion).
  - ajustar microcopys y botones segun feedback final de UX.
- `✅` `P4.4` Pulido final de demo UX:
  - revisar copy final y consistencia visual entre panel y settings.
  - validar checklist visual corto para presentacion interna.

## P5 (cierre pre-release UX)
- `✅` `P5.1` Cierre de release candidate UX:
  - ejecutar pasada final de QA manual con checklist visual y smoke local.
  - confirmar paquete listo para presentacion interna sin fricciones de operativa.
- `🚧` `P5.2` Cierre de release candidate tecnico:
  - ejecutar validacion final de evidencia (gate/smoke/handoff) en el nuevo `HEAD`.
  - preparar commit de cierre y resumen operativo final para entrega.

## Riesgos abiertos
- Coste y latencia dependen del tamano del audio importado y del modelo configurado.
- Persistencia local puede crecer sin rotacion si no se aplica limite de retencion.
