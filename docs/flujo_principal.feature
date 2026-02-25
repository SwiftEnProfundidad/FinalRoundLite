# language: es
Característica: Flujo principal de entrevista asistida
  Como persona practicando system design
  Quiero iniciar una sesion desde la menubar, recibir transcripcion y coaching
  Para exportar una sesion accionable en Markdown

  Antecedentes:
    Dado que la app FinalRoundLite esta abierta
    Y que el panel de menubar esta visible

  Escenario: Inicio exitoso con API key y envio de audio activo
    Dado que existe una OPENAI_API_KEY guardada en Keychain
    Y que "Enviar audio a OpenAI" esta activado
    Cuando pulso "Start"
    Entonces el estado pasa a "starting"
    Y despues pasa a "listening"
    Y la captura de microfono queda activa

  Escenario: Bloqueo de inicio cuando falta API key
    Dado que no existe OPENAI_API_KEY en Keychain
    Cuando pulso "Start"
    Entonces veo el error "Falta API key. Ve a Settings y pega tu OPENAI_API_KEY."
    Y el estado final queda en "idle"

  Escenario: Bloqueo de inicio cuando el envio de audio esta desactivado
    Dado que existe una OPENAI_API_KEY guardada en Keychain
    Y que "Enviar audio a OpenAI" esta desactivado
    Cuando pulso "Start"
    Entonces veo el error "Activa 'Enviar audio a OpenAI' para empezar a transcribir."
    Y el estado final queda en "idle"

  Escenario: Flujo de transcripcion y sugerencia de coach
    Dado que la sesion esta en estado "listening"
    Y que llega un chunk de audio con voz
    Cuando OpenAI devuelve una transcripcion no vacia
    Entonces el transcript se actualiza con el nuevo texto
    Cuando pasa la ventana de throttle configurada
    Y OpenAI devuelve una sugerencia valida con confianza >= 0.6
    Entonces se actualizan "currentQuestion", "shortScript", "tradeoffs" y "nextSteps"

  Escenario: Export de sesion a Markdown
    Dado que existe transcript acumulado
    Y que existe una sugerencia de coach visible
    Cuando pulso "Copiar Markdown"
    Entonces se copia al portapapeles un Markdown con Context Card, Transcript y Suggestion
    Cuando pulso "Guardar Markdown"
    Entonces se guarda el mismo contenido en un archivo .md

  Escenario: Parada manual de sesion
    Dado que la sesion esta en estado "listening"
    Cuando pulso "Stop"
    Entonces el coordinador detiene la captura y el pipeline
    Y el estado final queda en "idle"

  Escenario: Analisis post-sesion por importacion de audio
    Dado que existe una OPENAI_API_KEY guardada en Keychain
    Y que hay un archivo de audio local valido
    Cuando pulso "Importar audio" y selecciono ese archivo
    Entonces la app transcribe el audio sin iniciar captura de microfono
    Y actualiza transcript y sugerencias si la confianza del coach es suficiente
    Y el estado final queda en "idle"

  Escenario: Historial local minimo en Settings
    Dado que existen sesiones guardadas en Application Support
    Cuando abro Settings y pulso "Recargar" en "Historial local"
    Entonces veo la lista de sesiones recientes
    Y puedo abrir el JSON de una sesion
    Y puedo abrir el Markdown de la misma sesion
    Y puedo mostrar el archivo en Finder

  Escenario: Limpieza explicita de transcript y sugerencias
    Dado que existe transcript acumulado
    Y que existe una sugerencia de coach visible
    Cuando pulso "Limpiar"
    Entonces el transcript queda vacio
    Y los bloques de coach quedan vacios

  Escenario: Feedback visual durante analisis post-sesion
    Dado que existe una OPENAI_API_KEY guardada en Keychain
    Y que hay un archivo de audio local valido
    Cuando pulso "Importar audio" y selecciono ese archivo
    Entonces el estado muestra "analizando" durante el procesamiento
    Y veo un indicador visual de progreso mientras dura ese estado
    Y el estado final queda en "idle"
