# Plan de entrega release candidate (P6.1)

Ultima actualizacion: 2026-02-26

## Objetivo
Definir una estrategia segura de entrega para publicar el branch de trabajo y preparar la integracion sin perder trazabilidad.

## Estado de branch actual
- branch local: `feature/p1-2-usabilidad`
- situacion frente a remoto: `ahead/behind` (consultar con `git status --short --branch`)

## Estrategia recomendada (sin reescritura)
1. Sincronizar referencias remotas:
   - `git fetch origin`
2. Integrar cambios remotos en el branch local via merge:
   - `git merge origin/feature/p1-2-usabilidad`
3. Ejecutar validacion final de entrega:
   - `bash scripts/release_handoff_local.sh`
4. Publicar branch:
   - `git push origin feature/p1-2-usabilidad`
5. Abrir/actualizar PR (si aplica en este flujo).

## Nota operativa
- Se prioriza `merge` sobre `rebase` para evitar reescritura de historial en un branch con trazabilidad de entrega.
