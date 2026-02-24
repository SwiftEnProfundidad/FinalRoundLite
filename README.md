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

## Uso

1. Abre `Settings` y pega tu `OPENAI_API_KEY`.
2. En el panel, activa `Enviar audio a OpenAI`.
3. Pulsa `Start` y habla.
4. Copia o guarda el Markdown con el transcript + sugerencias.

