# FinalRound Lite (macOS menubar)

Discreta pero visible: una menubar app para practicar entrevistas de **system design**.

## Requisitos

- macOS 14+
- Una `OPENAI_API_KEY` (se guarda en Keychain)

## Build

```bash
cd Developer/Projects/FinalRoundLite
swift build
```

## Crear `.app`

```bash
cd Developer/Projects/FinalRoundLite
bash scripts/build_app.sh
open build/FinalRoundLite.app
```

## QA Smoke Automatizado

```bash
cd Developer/Projects/FinalRoundLite
bash scripts/qa_smoke_flows.sh
```

## Uso

1. Abre `Settings` y pega tu `OPENAI_API_KEY`.
2. En el panel, activa `Enviar audio a OpenAI`.
3. Pulsa `Start` y habla.
4. Copia o guarda el Markdown con el transcript + sugerencias.
5. Opcional: pulsa `Importar audio` para analizar un archivo sin captura en vivo (wav, mp3, mpga, mpeg, m4a, mp4, webm, ogg; maximo 25 MB).
6. Opcional: activa en `Settings` la persistencia local para guardar cada sesion como JSON; tambien puedes elegir carpeta destino y retencion maxima.
7. En `Settings`, revisa la telemetria local no sensible (contador de sesiones y promedio de procesamiento).

## Roadmap

- Backlog priorizado de `0.2.0`: `docs/release_0.2.0_backlog.md`
- Checklist de release `0.2.0`: `docs/release_0.2.0_checklist.md`
