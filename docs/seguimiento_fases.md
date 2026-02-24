# Seguimiento por fases

Ultima actualizacion: 2026-02-24

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
- `🚧` Iniciar ciclo obligatorio RED -> GREEN -> REFACTOR para `AppCoordinator` y `OpenAIClient`.
- `⏳` Agregar tests RED para errores de red, parseo invalido y throttle.
- `⏳` Implementar GREEN minimo para los RED anteriores.
- `⏳` Refactor de servicios manteniendo tests en verde.
- `⏳` Documentar escenarios BDD del flujo principal (Start -> Transcript -> Coach -> Export).

## Fase 4 - Siguiente incremento funcional
- `⏳` Modo post-sesion (importar audio y analizar sin captura en vivo).
- `⏳` Persistencia local opcional de sesiones (desactivada por defecto).
- `⏳` Definir backlog priorizado para release `0.2.0`.

