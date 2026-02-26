# Checklist visual de demo (P4.4)

Ultima actualizacion: 2026-02-26

## Objetivo
Validar rapidamente que el panel menubar es presentable en una demo corta sin friccion de uso.

## Flujo recomendado (2-3 min)
- Abrir la app `build/FinalRoundLite.app`.
- Abrir panel desde icono menubar.
- Revisar estado inicial sin API key.
- Abrir Ajustes, guardar API key y volver al panel.
- Probar botones `Cerrar panel` y `Salir`.

## Checks de UI/UX
- `✅` Jerarquia visual clara:
  - bloque estado
  - bloque controles
  - transcript
  - coach
- `✅` Legibilidad:
  - textos de ayuda visibles en tamano pequeno
  - contrastes correctos en estados de error/alerta
- `✅` Acciones principales claras:
  - `Iniciar practica` y `Analizar archivo` diferenciadas
  - `Copiar reporte`, `Guardar reporte...`, `Limpiar salida` agrupadas
- `✅` Sesiones largas:
  - scroll solo dentro de `Transcript` y `Coach`
  - `Vista compacta` reduce densidad sin romper layout
- `✅` Control del panel:
  - `Cerrar panel` cierra ventana del menubar
  - `Salir` termina proceso de la app
- `✅` Consistencia de copy:
  - panel y ajustes usan terminologia alineada

## Resultado de la iteracion actual
- Estado: `OK para demo interna`.
