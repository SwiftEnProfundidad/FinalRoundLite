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
    var languageCode = "es"
    var transcriptionModel = "gpt-4o-mini-transcribe"
    var coachModel = "gpt-4o-mini"

    var contextCard = ContextCard()

    var hasAPIKey: Bool { keychain.readAPIKey() != nil }

    private let keychain = KeychainStore()
    private let coordinator = AppCoordinator()

    func start() {
        guard !isListening else { return }
        errorMessage = nil
        status = .starting
        isListening = true

        let settings = RuntimeSettings(
            sendAudioToOpenAI: sendAudioToOpenAI,
            lowCostMode: lowCostMode,
            languageCode: languageCode,
            transcriptionModel: transcriptionModel,
            coachModel: coachModel
        )

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
                    self.handle(event)
                }
            )
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

    private func handle(_ event: CoordinatorEvent) {
        switch event {
        case .started:
            status = .listening
            errorMessage = nil
        case .stopped:
            status = .idle
            isListening = false
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
}

extension AppModel {
    enum Status: String, Sendable {
        case idle
        case starting
        case listening
        case stopping
        case error
    }
}
