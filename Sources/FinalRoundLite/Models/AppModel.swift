import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    var isListening = false
    var status: Status = .idle
    var errorMessage: String?

    var transcript = ""
    var lastTranscriptionAt: Date?

    var currentQuestion = ""
    var shortScript = ""
    var clarifyingQuestions: [String] = []
    var tradeoffs: [String] = []
    var nextSteps: [String] = []
    var lastSuggestionAt: Date?

    var sendAudioToOpenAI = false
    var lowCostMode = false
    var persistSessionsLocally = false
    var savedSessions: [SavedSessionRecord] = []
    var isLoadingSavedSessions = false
    var languageCode = "es"
    var transcriptionModel = "gpt-4o-mini-transcribe"
    var coachModel = "gpt-4o-mini"

    var contextCard = ContextCard()

    var hasAPIKey: Bool { keychain.readAPIKey() != nil }
    var hasSessionOutput: Bool {
        let transcriptTrimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !transcriptTrimmed.isEmpty { return true }
        if !currentQuestion.isEmpty { return true }
        if !shortScript.isEmpty { return true }
        if !clarifyingQuestions.isEmpty { return true }
        if !tradeoffs.isEmpty { return true }
        if !nextSteps.isEmpty { return true }
        return false
    }

    private let keychain = KeychainStore()
    private let coordinator = AppCoordinator()
    private let sessionStore: any SessionPersisting
    private let fileOpener: any FileOpening
    private var lastPersistedFingerprint: String?

    init(
        sessionStore: any SessionPersisting = SessionStore(),
        fileOpener: any FileOpening = WorkspaceFileOpener()
    ) {
        self.sessionStore = sessionStore
        self.fileOpener = fileOpener
    }

    func start() {
        guard !isListening else { return }
        errorMessage = nil
        status = .starting
        isListening = true

        let settings = runtimeSettings()

        let apiKey = keychain.readAPIKey()

        Task {
            await coordinator.start(
                apiKey: apiKey,
                settingsProvider: { [weak self] in
                    guard let self else { return settings }
                    return RuntimeSettings(
                        sendAudioToOpenAI: self.sendAudioToOpenAI,
                        lowCostMode: self.lowCostMode,
                        languageCode: self.languageCode,
                        transcriptionModel: self.transcriptionModel,
                        coachModel: self.coachModel
                    )
                },
                contextProvider: { [weak self] in
                    guard let self else { return ContextCard() }
                    return self.contextCard
                },
                onEvent: { [weak self] event in
                    guard let self else { return }
                    self.consume(event)
                }
            )
        }
    }

    func importAudioAndAnalyze() {
        guard !isListening else { return }
        errorMessage = nil

        AudioFileImporter.pickAudioFile { [weak self] selectedURL in
            guard let self else { return }
            guard let selectedURL else {
                self.status = .idle
                return
            }

            self.status = .starting
            let settings = self.runtimeSettings()
            let apiKey = self.keychain.readAPIKey()

            Task {
                await self.coordinator.analyzeImportedAudio(
                    fileURL: selectedURL,
                    apiKey: apiKey,
                    settingsProvider: { [weak self] in
                        guard let self else { return settings }
                        return self.runtimeSettings()
                    },
                    contextProvider: { [weak self] in
                        guard let self else { return ContextCard() }
                        return self.contextCard
                    },
                    onEvent: { [weak self] event in
                        guard let self else { return }
                        self.consume(event)
                    }
                )
            }
        }
    }

    func stop() {
        guard isListening else { return }
        isListening = false
        status = .stopping
        Task { await coordinator.stop() }
    }

    func saveAPIKey(_ key: String) {
        keychain.saveAPIKey(key)
    }

    func clearAPIKey() {
        keychain.deleteAPIKey()
    }

    func exportMarkdown() -> String {
        MarkdownExporter.export(
            context: contextCard,
            transcript: transcript,
            suggestion: CoachSuggestion(
                currentQuestion: currentQuestion,
                shortScript: shortScript,
                clarifyingQuestions: clarifyingQuestions,
                tradeoffs: tradeoffs,
                nextSteps: nextSteps,
                createdAt: lastSuggestionAt
            )
        )
    }

    func clearSessionOutput() {
        transcript = ""
        lastTranscriptionAt = nil
        currentQuestion = ""
        shortScript = ""
        clarifyingQuestions = []
        tradeoffs = []
        nextSteps = []
        lastSuggestionAt = nil
        errorMessage = nil
        lastPersistedFingerprint = nil
    }

    func refreshSavedSessions(limit: Int = 12) {
        isLoadingSavedSessions = true

        Task { [weak self] in
            guard let self else { return }
            do {
                self.savedSessions = try await self.sessionStore.listSessions(limit: limit)
            } catch {
                self.errorMessage = "No se pudo cargar historial local: \(error.localizedDescription)"
            }
            self.isLoadingSavedSessions = false
        }
    }

    func openSavedSessionJSON(_ session: SavedSessionRecord) {
        if !fileOpener.open(session.jsonURL) {
            errorMessage = "No se pudo abrir el archivo JSON."
        }
    }

    func openSavedSessionMarkdown(_ session: SavedSessionRecord) {
        guard let markdownURL = session.markdownURL else {
            errorMessage = "No hay archivo Markdown para esta sesion."
            return
        }

        if !fileOpener.open(markdownURL) {
            errorMessage = "No se pudo abrir el archivo Markdown."
        }
    }

    func revealSavedSessionInFinder(_ session: SavedSessionRecord) {
        if !fileOpener.reveal(session.jsonURL) {
            errorMessage = "No se pudo mostrar el archivo en Finder."
        }
    }

    private func runtimeSettings() -> RuntimeSettings {
        RuntimeSettings(
            sendAudioToOpenAI: sendAudioToOpenAI,
            lowCostMode: lowCostMode,
            languageCode: languageCode,
            transcriptionModel: transcriptionModel,
            coachModel: coachModel
        )
    }

    func consume(_ event: CoordinatorEvent) {
        switch event {
        case .started:
            status = .listening
            errorMessage = nil
        case .stopped:
            status = .idle
            isListening = false
            persistSessionIfNeeded()
        case let .statusChanged(newStatus):
            status = newStatus
        case let .error(message):
            errorMessage = message
            status = .error
        case let .transcriptAppended(text):
            if !transcript.isEmpty { transcript += "\n" }
            transcript += text
            if transcript.count > 20_000 {
                transcript = "…\n" + String(transcript.suffix(20_000))
            }
            lastTranscriptionAt = .now
        case let .suggestionUpdated(suggestion):
            currentQuestion = suggestion.currentQuestion
            shortScript = suggestion.shortScript
            clarifyingQuestions = suggestion.clarifyingQuestions
            tradeoffs = suggestion.tradeoffs
            nextSteps = suggestion.nextSteps
            lastSuggestionAt = .now
        }
    }

    private func persistSessionIfNeeded() {
        guard persistSessionsLocally else { return }

        let transcriptTrimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasSuggestion = !currentQuestion.isEmpty ||
            !shortScript.isEmpty ||
            !clarifyingQuestions.isEmpty ||
            !tradeoffs.isEmpty ||
            !nextSteps.isEmpty
        guard !transcriptTrimmed.isEmpty || hasSuggestion else { return }

        let fingerprint = [
            transcriptTrimmed,
            currentQuestion,
            shortScript,
            clarifyingQuestions.joined(separator: "|"),
            tradeoffs.joined(separator: "|"),
            nextSteps.joined(separator: "|")
        ].joined(separator: "§")
        guard fingerprint != lastPersistedFingerprint else { return }

        let session = PersistedSession(
            savedAt: .now,
            context: contextCard,
            transcript: transcriptTrimmed,
            suggestion: PersistedSuggestion(
                currentQuestion: currentQuestion,
                shortScript: shortScript,
                clarifyingQuestions: clarifyingQuestions,
                tradeoffs: tradeoffs,
                nextSteps: nextSteps
            )
        )

        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.sessionStore.save(session: session)
                self.lastPersistedFingerprint = fingerprint
                self.savedSessions = try await self.sessionStore.listSessions(limit: 12)
            } catch {
                self.errorMessage = "No se pudo guardar la sesion local: \(error.localizedDescription)"
            }
        }
    }
}

extension AppModel {
    enum Status: String, Sendable {
        case idle
        case starting
        case analyzing
        case listening
        case stopping
        case error

        var displayText: String {
            switch self {
            case .idle:
                return "Idle"
            case .starting:
                return "Starting"
            case .analyzing:
                return "Analizando"
            case .listening:
                return "Listening"
            case .stopping:
                return "Stopping"
            case .error:
                return "Error"
            }
        }
    }
}
