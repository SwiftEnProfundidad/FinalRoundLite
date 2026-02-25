import SwiftUI

struct MenuBarPanelView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            controls
            Divider()
            transcriptSection
            Divider()
            suggestionSection
            Divider()
            footer
        }
        .padding(12)
        .frame(width: 420)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("FinalRound Lite")
                    .font(.headline)
                Text(model.status.displayText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let last = model.lastSuggestionAt {
                Text(last, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Enviar audio a OpenAI", isOn: $model.sendAudioToOpenAI)
            Toggle("Low cost", isOn: $model.lowCostMode)

            HStack(spacing: 10) {
                Button(model.isListening ? "Stop" : "Start") {
                    model.isListening ? model.stop() : model.start()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.status == .analyzing)

                Button("Importar audio") {
                    model.importAudioAndAnalyze()
                }
                .buttonStyle(.bordered)
                .disabled(model.status == .analyzing || model.isListening)

                Button("Copiar Markdown") {
                    Clipboard.copy(model.exportMarkdown())
                }
                .buttonStyle(.bordered)

                Button("Guardar…") {
                    Task { @MainActor in
                        FileExporter.saveMarkdown(
                            model.exportMarkdown(),
                            defaultFilename: FileExporter.defaultFilename()
                        )
                    }
                }
                .buttonStyle(.bordered)

                Button("Limpiar") {
                    model.clearSessionOutput()
                }
                .buttonStyle(.bordered)
                .disabled(!model.hasSessionOutput)
            }

            if model.status == .analyzing {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Analizando audio importado…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !model.hasAPIKey {
                Text("Falta API key: abre Settings para pegar tu OPENAI_API_KEY.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if let error = model.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Transcript")
                .font(.subheadline.bold())
            ScrollView {
                Text(model.transcript.isEmpty ? "…" : model.transcript)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .font(.callout)
            }
            .frame(height: 120)
        }
    }

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Coach (System Design)")
                .font(.subheadline.bold())

            if !model.currentQuestion.isEmpty {
                Text("Pregunta actual: \(model.currentQuestion)")
                    .font(.callout)
            }

            if !model.shortScript.isEmpty {
                Text(model.shortScript)
                    .font(.callout)
                    .textSelection(.enabled)
            }

            if !model.clarifyingQuestions.isEmpty {
                TagListView(title: "Clarificaciones", items: model.clarifyingQuestions)
            }
            if !model.tradeoffs.isEmpty {
                TagListView(title: "Tradeoffs", items: model.tradeoffs)
            }
            if !model.nextSteps.isEmpty {
                TagListView(title: "Siguientes pasos", items: model.nextSteps)
            }
        }
    }

    private var footer: some View {
        HStack {
            SettingsLink {
                Text("Settings")
            }
            Spacer()
        }
        .font(.caption)
    }
}

private struct TagListView: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Text("• \(item)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
