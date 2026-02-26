import SwiftUI

struct MenuBarPanelView: View {
    @Bindable var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                statusCard
                controlsCard
                transcriptCard
                suggestionCard
                footer
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollIndicators(.hidden)
        .frame(width: 452)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FinalRound Lite")
                        .font(.headline)
                    Text("Practice mode")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: model.status.symbolName)
                        .font(.caption.bold())
                    Text(model.status.displayText)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(model.status.tintColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(model.status.tintColor.opacity(0.14), in: .capsule)
            }

            if model.status.isBusy, let progressMessage = model.status.progressMessage {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(progressMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.tertiary.opacity(0.5), in: .rect(cornerRadius: 8))
            }

            lastActivityView

            if !model.hasAPIKey {
                banner(
                    text: "Falta API key: abre Settings para pegar tu OPENAI_API_KEY.",
                    tint: .orange,
                    symbol: "key.fill"
                )
            }

            if let error = model.errorMessage {
                banner(
                    text: error,
                    tint: .red,
                    symbol: "exclamationmark.triangle.fill"
                )
            }
        }
        .panelCardStyle()
    }

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Controles")
                .font(.subheadline.bold())

            Toggle("Enviar audio a OpenAI", isOn: $model.sendAudioToOpenAI)
            Toggle("Low cost", isOn: $model.lowCostMode)

            HStack(spacing: 8) {
                Button {
                    model.isListening ? model.stop() : model.start()
                } label: {
                    Label(
                        model.isListening ? "Detener" : "Iniciar",
                        systemImage: model.isListening ? "stop.fill" : "mic.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.status == .analyzing)

                Button {
                    model.importAudioAndAnalyze()
                } label: {
                    Label("Importar audio", systemImage: "waveform.badge.plus")
                }
                .buttonStyle(.bordered)
                .disabled(model.status.isBusy || model.isListening)
            }

            secondaryActionsView
        }
        .panelCardStyle()
    }

    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Transcript")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(model.transcript.count) caracteres")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                Text(model.transcript.isEmpty ? "Todavia no hay transcript." : model.transcript)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .font(.callout)
                    .foregroundStyle(model.transcript.isEmpty ? .secondary : .primary)
                    .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .frame(height: 128)
            .padding(10)
            .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 10))
        }
        .panelCardStyle()
    }

    private var suggestionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Coach (System Design)")
                .font(.subheadline.bold())

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if !model.currentQuestion.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pregunta actual")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Text(model.currentQuestion)
                                .font(.callout)
                        }
                    }

                    if !model.shortScript.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Guion corto")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Text(model.shortScript)
                                .font(.callout)
                                .textSelection(.enabled)
                        }
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
                    if !hasCoachContent {
                        Text("Aun no hay sugerencias. Inicia o importa audio para generar coach.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .frame(height: 184)
            .padding(10)
            .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 10))
        }
        .panelCardStyle()
    }

    private var hasCoachContent: Bool {
        !model.currentQuestion.isEmpty ||
            !model.shortScript.isEmpty ||
            !model.clarifyingQuestions.isEmpty ||
            !model.tradeoffs.isEmpty ||
            !model.nextSteps.isEmpty
    }

    private func banner(text: String, tint: Color, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbol)
                .font(.caption.bold())
            Text(text)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: .rect(cornerRadius: 8))
    }

    private var lastActivityView: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                activityChips
            }
            VStack(alignment: .leading, spacing: 4) {
                activityChips
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var activityChips: some View {
        if let lastTranscriptionAt = model.lastTranscriptionAt {
            Label {
                Text(lastTranscriptionAt, format: .dateTime.hour().minute())
            } icon: {
                Image(systemName: "waveform")
            }
        }
        if let lastSuggestionAt = model.lastSuggestionAt {
            Label {
                Text(lastSuggestionAt, format: .dateTime.hour().minute())
            } icon: {
                Image(systemName: "sparkles")
            }
        }
        if model.lastTranscriptionAt == nil, model.lastSuggestionAt == nil {
            Text("Sin actividad reciente")
        }
    }

    private var secondaryActionsView: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                copyMarkdownButton
                saveMarkdownButton
                clearButton
            }
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    copyMarkdownButton
                    saveMarkdownButton
                }
                clearButton
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var copyMarkdownButton: some View {
        Button {
            Clipboard.copy(model.exportMarkdown())
        } label: {
            Label("Copiar Markdown", systemImage: "doc.on.doc")
        }
        .buttonStyle(.bordered)
        .disabled(!model.hasSessionOutput)
    }

    private var saveMarkdownButton: some View {
        Button {
            Task { @MainActor in
                FileExporter.saveMarkdown(
                    model.exportMarkdown(),
                    defaultFilename: FileExporter.defaultFilename()
                )
            }
        } label: {
            Label("Guardar…", systemImage: "square.and.arrow.down")
        }
        .buttonStyle(.bordered)
        .disabled(!model.hasSessionOutput)
    }

    private var clearButton: some View {
        Button {
            model.clearSessionOutput()
        } label: {
            Label("Limpiar", systemImage: "trash")
        }
        .buttonStyle(.bordered)
        .disabled(!model.hasSessionOutput)
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

private extension View {
    func panelCardStyle() -> some View {
        self
            .padding(12)
            .background(.thinMaterial, in: .rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.quaternary, lineWidth: 1)
            )
    }
}

private extension AppModel.Status {
    var symbolName: String {
        switch self {
        case .idle:
            return "pause.circle.fill"
        case .starting:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .analyzing:
            return "waveform.and.magnifyingglass"
        case .listening:
            return "mic.fill"
        case .stopping:
            return "stop.circle.fill"
        case .error:
            return "exclamationmark.circle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .idle:
            return .secondary
        case .starting:
            return .blue
        case .analyzing:
            return .indigo
        case .listening:
            return .green
        case .stopping:
            return .orange
        case .error:
            return .red
        }
    }

    var isBusy: Bool {
        self == .starting || self == .analyzing || self == .stopping
    }

    var progressMessage: String? {
        switch self {
        case .starting:
            return "Preparando captura de audio…"
        case .analyzing:
            return "Analizando audio importado…"
        case .stopping:
            return "Deteniendo captura…"
        default:
            return nil
        }
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
            ForEach(identifiedItems(items)) { item in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 4))
                        .padding(.top, 7)
                    Text(item.value)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func identifiedItems(_ source: [String]) -> [IdentifiedTagItem] {
        var itemOccurrences: [String: Int] = [:]
        return source.map { value in
            let occurrence = (itemOccurrences[value] ?? 0) + 1
            itemOccurrences[value] = occurrence
            return IdentifiedTagItem(id: "\(value)#\(occurrence)", value: value)
        }
    }
}

private struct IdentifiedTagItem: Identifiable {
    let id: String
    let value: String
}
