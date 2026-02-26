# Backlog Priorizado - Release 0.2.0

Fecha de corte: 2026-02-26

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
- `✅` `P5.2` Cierre de release candidate tecnico:
  - ejecutar validacion final de evidencia (gate/smoke/handoff) en el nuevo `HEAD`.
  - preparar commit de cierre y resumen operativo final para entrega.

## P6 (post candidate)
- `✅` `P6.1` Preparacion de entrega final:
  - definir estrategia de push/merge y publicacion de branch.
  - cerrar handoff final al siguiente turno con estado de release candidate.
- `✅` `P6.2` Ejecucion de publicacion remota:
  - sincronizar con remoto y resolver integracion de branch.
  - publicar branch actualizado y dejar listo el flujo de PR/entrega.
- `✅` `P6.3` Cierre de entrega en plataforma:
  - revisar estado de PR/merge en GitHub.
  - cerrar handoff final de turno con enlace al estado remoto.

## P7 (post entrega)
- `✅` `P7.1` Espera activa de revision:
  - monitorizar feedback de PR y checks remotos.
  - preparar respuesta rapida a comentarios o ajustes de merge.
- `✅` `P7.2` Cierre final de PR:
  - mantener monitor remoto y resolver feedback en cuanto aparezca.
  - completar merge de release cuando el estado de plataforma lo permita.

## P8 (siguiente ciclo)
- `✅` `P8.1` Arranque del siguiente incremento:
  - sincronizar `develop` local con el estado post-merge.
  - preparar base de trabajo para el siguiente bloque funcional.
- `✅` `P8.2` Definicion del siguiente incremento funcional:
  - concretar alcance del siguiente bloque y su prioridad.
  - desglosar tareas ejecutables para la siguiente iteracion de implementacion.
- `✅` `P8.3` Historial rapido en panel menubar:
  - mostrar ultimas sesiones en el panel sin salir a Settings.
  - permitir abrir markdown/json directamente desde ese bloque.
- `✅` `P8.4` Filtro de historial en Settings:
  - busqueda por texto para sesiones guardadas.
  - mantener apertura de archivos sin romper flujo actual.
- `✅` `P8.5` Operativa de limpieza de historial:
  - accion de borrado de una sesion y limpieza total con confirmacion.
  - actualizar tests y smoke para cubrir nuevas acciones de historial.
- `✅` `P8.6` Cierre del bloque P8:
  - validar PR de continuidad con estado limpio post-cambios.
  - preparar merge del bloque P8 en `develop`.

## P9 (post P8)
- `✅` `P9.1` Arranque de nuevo ciclo:
  - dejar rama de continuidad creada desde `develop` post-merge.
  - consolidar tracking inicial del nuevo ciclo para la siguiente implementacion.
- `✅` `P9.2` Definicion del siguiente incremento funcional:
  - concretar el siguiente bloque de trabajo tras cierre del paquete P8.
  - priorizar tareas implementables del nuevo ciclo.
- `✅` `P9.3` Borrado rapido desde panel:
  - permitir borrar sesiones recientes desde el bloque de historial rapido en menubar.
  - mantener confirmacion destructiva antes de borrar.
- `✅` `P9.4` Operativa de cierre del ciclo P9:
  - validar estado remoto de la PR de continuidad tras los cambios P9.
  - consolidar merge del ciclo cuando plataforma este en estado limpio.

## P10 (post P9)
- `✅` `P10.1` Arranque de nuevo ciclo post-P9:
  - crear rama de continuidad desde `develop` post-merge de `P9`.
  - dejar tracking inicial listo para definir el siguiente incremento funcional.
- `✅` `P10.2` Definicion del siguiente incremento funcional:
  - concretar el alcance implementable del bloque P10 tras el arranque de continuidad.
  - priorizar tareas ejecutables para el siguiente tramo de implementacion.
- `✅` `P10.3` Ergonomia anti-scroll en panel:
  - iniciar transcript y coach en modo colapsado hasta tener contenido relevante.
  - agregar accion rapida para expandir/contraer resultados y reducir altura de secciones.
- `✅` `P10.4` Persistencia de preferencias del panel:
  - guardar y restaurar el estado de vista compacta/expansion de resultados entre aperturas.
  - validar cobertura de tests para la nueva serializacion de preferencias.
- `✅` `P10.5` Operativa de cierre del ciclo P10:
  - validar estado remoto de la PR de continuidad con cambios P10.
  - dejar ciclo listo para merge cuando plataforma este limpia.

## P11 (post P10)
- `🚧` `P11.1` Arranque de nuevo ciclo post-P10:
  - dejar rama de continuidad creada desde `develop` post-merge de `P10`.
  - actualizar tracking inicial para preparar el siguiente bloque funcional.

## Riesgos abiertos
- Coste y latencia dependen del tamano del audio importado y del modelo configurado.
- Persistencia local puede crecer sin rotacion si no se aplica limite de retencion.
