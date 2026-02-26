import AppKit
import SwiftUI

struct MenuBarPanelView: View {
    @Bindable var model: AppModel
    @State private var isCompactMode = false
    @State private var isTranscriptExpanded = false
    @State private var isCoachExpanded = false
    @State private var sessionPendingDeletion: SavedSessionRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusCard
            controlsCard
            recentSessionsCard
            transcriptCard
            suggestionCard
            footer
        }
        .padding(12)
        .frame(width: 452)
        .task {
            model.refreshPanelSavedSessions()
        }
        .onChange(of: model.transcript) { oldValue, newValue in
            let hadContent = !oldValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let hasContent = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if !hadContent, hasContent {
                isTranscriptExpanded = true
            }
        }
        .onChange(of: hasCoachContent) { oldValue, newValue in
            if !oldValue, newValue {
                isCoachExpanded = true
            }
        }
        .confirmationDialog("Borrar sesion local", isPresented: isDeleteSessionDialogPresented, titleVisibility: .visible) {
            Button("Borrar", role: .destructive) {
                guard let sessionPendingDeletion else { return }
                model.deleteSavedSession(sessionPendingDeletion)
                self.sessionPendingDeletion = nil
            }
            Button("Cancelar", role: .cancel) {
                sessionPendingDeletion = nil
            }
        } message: {
            if let sessionPendingDeletion {
                Text("Se borrara \(sessionPendingDeletion.jsonURL.lastPathComponent).")
            }
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FinalRound Lite")
                        .font(.headline)
                    Text("Modo practica")
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
                    text: "Falta API key: abre Ajustes para pegar tu OPENAI_API_KEY.",
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

            Toggle("Enviar audio a OpenAI (transcripcion)", isOn: $model.sendAudioToOpenAI)
            Toggle("Modo ahorro (coach menos frecuente)", isOn: $model.lowCostMode)
            Toggle("Vista compacta", isOn: $isCompactMode)
            Button {
                setResultsSectionsExpanded(!allResultSectionsExpanded)
            } label: {
                Label(
                    allResultSectionsExpanded ? "Contraer resultados" : "Expandir resultados",
                    systemImage: allResultSectionsExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical"
                )
            }
            .buttonStyle(.borderless)
            .font(.caption.weight(.semibold))

            HStack(spacing: 8) {
                Button {
                    model.isListening ? model.stop() : model.start()
                } label: {
                    Label(
                        model.isListening ? "Detener practica" : "Iniciar practica",
                        systemImage: model.isListening ? "stop.fill" : "mic.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.status == .analyzing)

                Button {
                    model.importAudioAndAnalyze()
                } label: {
                    Label("Analizar archivo", systemImage: "waveform.badge.plus")
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
                Button(isTranscriptExpanded ? "Ocultar" : "Mostrar") {
                    isTranscriptExpanded.toggle()
                }
                .buttonStyle(.borderless)
                .font(.caption2.weight(.semibold))
            }

            if isTranscriptExpanded {
                ScrollView {
                    Text(model.transcript.isEmpty ? "Todavia no hay transcript." : model.transcript)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .font(isCompactMode ? .caption : .callout)
                        .foregroundStyle(model.transcript.isEmpty ? .secondary : .primary)
                        .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
                .frame(height: transcriptSectionHeight)
                .padding(10)
                .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 10))

                if transcriptWasTrimmed {
                    Text("Mostrando solo el tramo mas reciente del transcript.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(transcriptPreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 10))
            }
        }
        .panelCardStyle()
    }

    private var recentSessionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Historial rapido")
                    .font(.subheadline.bold())
                Spacer()
                if model.isLoadingPanelSavedSessions {
                    ProgressView()
                        .controlSize(.small)
                }
                Button("Actualizar") {
                    model.refreshPanelSavedSessions()
                }
                .buttonStyle(.borderless)
                .font(.caption2.weight(.semibold))
            }

            if model.panelSavedSessions.isEmpty {
                Text("No hay sesiones recientes. Activa persistencia local y finaliza una sesion.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 10))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(model.panelSavedSessions) { session in
                        quickSessionRow(session)
                    }
                }
            }
        }
        .panelCardStyle()
    }

    private var suggestionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Coach (System Design)")
                    .font(.subheadline.bold())
                Spacer()
                Button(isCoachExpanded ? "Ocultar" : "Mostrar") {
                    isCoachExpanded.toggle()
                }
                .buttonStyle(.borderless)
                .font(.caption2.weight(.semibold))
            }

            if isCoachExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if !model.currentQuestion.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pregunta actual")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Text(model.currentQuestion)
                                    .font(isCompactMode ? .caption : .callout)
                            }
                        }

                        if !model.shortScript.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Guion corto")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Text(model.shortScript)
                                    .font(isCompactMode ? .caption : .callout)
                                    .textSelection(.enabled)
                            }
                        }

                        if !model.clarifyingQuestions.isEmpty {
                            TagListView(
                                title: "Clarificaciones",
                                items: model.clarifyingQuestions,
                                isCompact: isCompactMode
                            )
                        }
                        if !model.tradeoffs.isEmpty {
                            TagListView(
                                title: "Tradeoffs",
                                items: model.tradeoffs,
                                isCompact: isCompactMode
                            )
                        }
                        if !model.nextSteps.isEmpty {
                            TagListView(
                                title: "Siguientes pasos",
                                items: model.nextSteps,
                                isCompact: isCompactMode
                            )
                        }
                        if !hasCoachContent {
                            Text("Aun no hay sugerencias. Inicia o importa audio para generar coach.")
                                .font(isCompactMode ? .caption : .callout)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
                .frame(height: coachSectionHeight)
                .padding(10)
                .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 10))
            } else {
                Text(coachPreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 10))
            }
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
            Label("Copiar reporte", systemImage: "doc.on.doc")
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
            Label("Guardar reporte…", systemImage: "square.and.arrow.down")
        }
        .buttonStyle(.bordered)
        .disabled(!model.hasSessionOutput)
    }

    private var clearButton: some View {
        Button {
            model.clearSessionOutput()
        } label: {
            Label("Limpiar salida", systemImage: "trash")
        }
        .buttonStyle(.bordered)
        .disabled(!model.hasSessionOutput)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            SettingsLink {
                Text("Ajustes")
            }
            Button("Cerrar panel") {
                closePanelWindow()
            }
            .buttonStyle(.bordered)

            Spacer()
            Button("Salir") {
                terminateApplication()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .font(.caption)
    }

    private var allResultSectionsExpanded: Bool {
        isTranscriptExpanded && isCoachExpanded
    }

    private var transcriptSectionHeight: CGFloat {
        isCompactMode ? 84 : 116
    }

    private var coachSectionHeight: CGFloat {
        isCompactMode ? 132 : 170
    }

    private var transcriptWasTrimmed: Bool {
        model.transcript.hasPrefix("…\n")
    }

    private var transcriptPreview: String {
        let value = model.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "Sin transcript todavia." }
        let limit = isCompactMode ? 90 : 140
        let slice = String(value.prefix(limit))
        return value.count > limit ? "\(slice)…" : slice
    }

    private var coachPreview: String {
        if !model.currentQuestion.isEmpty {
            return "Pregunta: \(model.currentQuestion)"
        }
        if !model.shortScript.isEmpty {
            let limit = isCompactMode ? 90 : 140
            let slice = String(model.shortScript.prefix(limit))
            return model.shortScript.count > limit ? "\(slice)…" : slice
        }
        return "Sin coach todavia."
    }

    private func quickSessionRow(_ session: SavedSessionRecord) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.savedAt, format: .dateTime.day().month().hour().minute())
                    .font(.caption.bold())
                Text(session.jsonURL.lastPathComponent)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 4)

            Button("MD") {
                model.openSavedSessionMarkdown(session)
            }
            .buttonStyle(.bordered)
            .font(.caption2)
            .disabled(session.markdownURL == nil)

            Button("JSON") {
                model.openSavedSessionJSON(session)
            }
            .buttonStyle(.bordered)
            .font(.caption2)

            Button {
                sessionPendingDeletion = session
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .font(.caption2)
            .tint(.red)
        }
        .padding(8)
        .background(.quaternary.opacity(0.3), in: .rect(cornerRadius: 8))
    }

    private var isDeleteSessionDialogPresented: Binding<Bool> {
        Binding(
            get: { sessionPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    sessionPendingDeletion = nil
                }
            }
        )
    }

    private func setResultsSectionsExpanded(_ isExpanded: Bool) {
        isTranscriptExpanded = isExpanded
        isCoachExpanded = isExpanded
    }

    private func closePanelWindow() {
        if let keyWindow = NSApplication.shared.keyWindow {
            keyWindow.performClose(nil)
            return
        }
        NSApp.sendAction(#selector(NSWindow.performClose(_:)), to: nil, from: nil)
    }

    private func terminateApplication() {
        NSApplication.shared.terminate(nil)
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
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(title) (\(items.count))")
                .font((isCompact ? Font.caption2 : Font.caption).bold())
                .foregroundStyle(.secondary)
            ForEach(identifiedItems(items)) { item in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 4))
                        .padding(.top, 7)
                    Text(item.value)
                        .font(isCompact ? .caption2 : .caption)
                        .lineLimit(isCompact ? 2 : nil)
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
