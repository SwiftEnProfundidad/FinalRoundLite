import Foundation

@MainActor
final class AppCoordinator {
    private let audioCapture = AudioCaptureService()
    private let pipeline = PipelineWorker()
    private var onEvent: (@Sendable @MainActor (CoordinatorEvent) -> Void)?

    func start(
        apiKey: String?,
        settingsProvider: @escaping @Sendable @MainActor () -> RuntimeSettings,
        contextProvider: @escaping @Sendable @MainActor () -> ContextCard,
        onEvent: @escaping @Sendable @MainActor (CoordinatorEvent) -> Void
    ) async {
        self.onEvent = onEvent
        await stop(emitEvent: false, onEvent: onEvent)

        guard let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onEvent(.error("Falta API key. Ve a Settings y pega tu OPENAI_API_KEY."))
            onEvent(.stopped)
            return
        }

        let settings = settingsProvider()
        guard settings.sendAudioToOpenAI else {
            onEvent(.error("Activa 'Enviar audio a OpenAI' para empezar a transcribir."))
            onEvent(.stopped)
            return
        }

        onEvent(.statusChanged(.starting))

        do {
            let stream = try audioCapture.start()
            onEvent(.started)
            onEvent(.statusChanged(.listening))
            await pipeline.start(
                stream: stream,
                apiKey: apiKey,
                settingsProvider: settingsProvider,
                contextProvider: contextProvider,
                onEvent: onEvent
            )
        } catch {
            onEvent(.error("No se pudo iniciar el microfono. Revisa permisos de microfono en macOS."))
            onEvent(.stopped)
        }
    }

    func analyzeImportedAudio(
        fileURL: URL,
        apiKey: String?,
        settingsProvider: @escaping @Sendable @MainActor () -> RuntimeSettings,
        contextProvider: @escaping @Sendable @MainActor () -> ContextCard,
        onEvent: @escaping @Sendable @MainActor (CoordinatorEvent) -> Void
    ) async {
        self.onEvent = onEvent
        await stop(emitEvent: false, onEvent: onEvent)

        guard let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onEvent(.error("Falta API key. Ve a Settings y pega tu OPENAI_API_KEY."))
            onEvent(.stopped)
            return
        }

        onEvent(.statusChanged(.starting))
        onEvent(.statusChanged(.analyzing))
        await pipeline.analyzeImportedAudio(
            fileURL: fileURL,
            apiKey: apiKey,
            settingsProvider: settingsProvider,
            contextProvider: contextProvider,
            onEvent: onEvent
        )
    }

    func stop() async {
        await stop(emitEvent: true, onEvent: onEvent)
    }

    private func stop(emitEvent: Bool, onEvent: (@Sendable @MainActor (CoordinatorEvent) -> Void)?) async {
        audioCapture.stop()
        await pipeline.stop()

        if emitEvent, let onEvent {
            onEvent(.stopped)
            onEvent(.statusChanged(.idle))
        }
    }
}

private struct CoachInput: Sendable {
    var context: ContextCard
    var transcript: String
    var previousQuestion: String
}

private struct TranscriptBuffer: Sendable {
    private var text = ""

    mutating func append(_ segment: String) {
        if !text.isEmpty { text += "\n" }
        text += segment
        if text.count > 10_000 {
            text = String(text.suffix(10_000))
        }
    }

    func window(maxChars: Int) -> String {
        if text.count <= maxChars { return text }
        return String(text.suffix(maxChars))
    }
}

private struct CoachOutput: Decodable {
    let shouldUpdate: Bool
    let confidence: Double
    let currentQuestion: String
    let shortScript: String
    let clarifyingQuestions: [String]
    let tradeoffs: [String]
    let nextSteps: [String]
    let whyChanged: String

    enum CodingKeys: String, CodingKey {
        case shouldUpdate = "should_update"
        case confidence
        case currentQuestion = "current_question"
        case shortScript = "short_script"
        case clarifyingQuestions = "clarifying_questions"
        case tradeoffs
        case nextSteps = "next_steps"
        case whyChanged = "why_changed"
    }

    var asSuggestion: CoachSuggestion {
        CoachSuggestion(
            currentQuestion: currentQuestion,
            shortScript: shortScript,
            clarifyingQuestions: clarifyingQuestions,
            tradeoffs: tradeoffs,
            nextSteps: nextSteps,
            createdAt: nil
        )
    }

    static var schema: [String: Any] {
        [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "should_update": ["type": "boolean"],
                "confidence": ["type": "number", "minimum": 0, "maximum": 1],
                "current_question": ["type": "string"],
                "short_script": ["type": "string", "description": "2-4 frases maximo, en tono natural."],
                "clarifying_questions": ["type": "array", "items": ["type": "string"], "maxItems": 3],
                "tradeoffs": ["type": "array", "items": ["type": "string"], "maxItems": 6],
                "next_steps": ["type": "array", "items": ["type": "string"], "maxItems": 5],
                "why_changed": ["type": "string"]
            ],
            "required": [
                "should_update",
                "confidence",
                "current_question",
                "short_script",
                "clarifying_questions",
                "tradeoffs",
                "next_steps",
                "why_changed"
            ]
        ]
    }
}

private enum Prompts {
    static func systemDesignCoachSystemPrompt(languageCode: String) -> String {
        """
        Eres un coach para practicar entrevistas de system design. Responde en \(languageCode.uppercased()).

        Reglas:
        - No inventes requisitos: si faltan datos, pregunta 1-3 clarificaciones.
        - No hagas spam: marca should_update=true SOLO si hay una pregunta nueva o un cambio claro de tema.
        - short_script debe ser un guion corto de 2-4 frases, facil de decir en voz alta.
        - tradeoffs y next_steps deben ser concretos y accionables.
        """
    }

    static func systemDesignUserPrompt(input: CoachInput, languageCode: String) -> String {
        var parts: [String] = []
        parts.append("Context Card:")
        parts.append("- Problema: \(input.context.problem)")
        parts.append("- Usuarios: \(input.context.users)")
        parts.append("- Escala: \(input.context.scale)")
        parts.append("- Datos: \(input.context.data)")
        parts.append("- SLOs: \(input.context.slos)")
        parts.append("- Restricciones: \(input.context.constraints)")
        parts.append("- Stack preferido: \(input.context.preferredStack)")
        parts.append("")
        parts.append("Pregunta previa (si aplica): \(input.previousQuestion)")
        parts.append("")
        parts.append("Transcript reciente:")
        parts.append(input.transcript)
        return parts.joined(separator: "\n")
    }
}

private actor PipelineWorker {
    private var runTask: Task<Void, Never>?
    private var scheduledCoachTask: Task<Void, Never>?

    private var transcriptBuffer = TranscriptBuffer()
    private var lastCoachCallAt: Date?
    private var pendingCoachInput: CoachInput?
    private var lastSuggestionFingerprint: String?
    private var lastKnownQuestion: String = ""

    private var onEvent: (@Sendable @MainActor (CoordinatorEvent) -> Void)?
    private var settingsProvider: (@Sendable @MainActor () -> RuntimeSettings)?
    private var contextProvider: (@Sendable @MainActor () -> ContextCard)?
    private var apiKey: String?

    func start(
        stream: AsyncStream<AudioChunk>,
        apiKey: String,
        settingsProvider: @escaping @Sendable @MainActor () -> RuntimeSettings,
        contextProvider: @escaping @Sendable @MainActor () -> ContextCard,
        onEvent: @escaping @Sendable @MainActor (CoordinatorEvent) -> Void
    ) async {
        await stop()
        self.apiKey = apiKey
        self.settingsProvider = settingsProvider
        self.contextProvider = contextProvider
        self.onEvent = onEvent

        runTask = Task { [weak self] in
            guard let self else { return }
            await self.run(stream: stream)
        }
    }

    func analyzeImportedAudio(
        fileURL: URL,
        apiKey: String,
        settingsProvider: @escaping @Sendable @MainActor () -> RuntimeSettings,
        contextProvider: @escaping @Sendable @MainActor () -> ContextCard,
        onEvent: @escaping @Sendable @MainActor (CoordinatorEvent) -> Void
    ) async {
        await stop()
        self.apiKey = apiKey
        self.settingsProvider = settingsProvider
        self.contextProvider = contextProvider
        self.onEvent = onEvent

        await runImportedAudio(fileURL: fileURL)
    }

    func stop() async {
        runTask?.cancel()
        runTask = nil

        scheduledCoachTask?.cancel()
        scheduledCoachTask = nil
        pendingCoachInput = nil
    }

    private func run(stream: AsyncStream<AudioChunk>) async {
        guard let onEvent, let settingsProvider, let contextProvider, let apiKey else { return }
        let client = OpenAIClient(apiKey: apiKey)

        for await chunk in stream {
            if Task.isCancelled { return }

            let settings = await settingsProvider()
            if !settings.sendAudioToOpenAI {
                await onEvent(.error("Se desactivo 'Enviar audio a OpenAI'. Parando captura."))
                break
            }

            do {
                let wav = WavEncoder.wrapPCM16LEAsWav(
                    pcmData: chunk.pcm16Data,
                    sampleRate: chunk.sampleRate,
                    channels: chunk.channels
                )
                let text = try await client.createTranscription(
                    wavData: wav,
                    model: settings.transcriptionModel,
                    language: settings.languageCode
                )

                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { continue }

                transcriptBuffer.append(trimmed)
                await onEvent(.transcriptAppended(trimmed))

                let context = await contextProvider()
                let input = CoachInput(
                    context: context,
                    transcript: transcriptBuffer.window(maxChars: 4000),
                    previousQuestion: lastKnownQuestion
                )
                pendingCoachInput = input
                await scheduleCoachUpdateIfNeeded(settings: settings, client: client)
            } catch {
                await onEvent(.error("Transcripcion fallo: \(error.localizedDescription)"))
            }
        }

        if Task.isCancelled { return }
        await onEvent(.stopped)
        await onEvent(.statusChanged(.idle))
    }

    private func runImportedAudio(fileURL: URL) async {
        guard let onEvent, let settingsProvider, let contextProvider, let apiKey else { return }
        let client = OpenAIClient(apiKey: apiKey)

        do {
            let settings = await settingsProvider()
            let preflight = try ImportedAudioPreflight.validate(fileURL: fileURL)
            let data = try Data(contentsOf: fileURL, options: [.mappedIfSafe])
            let text = try await client.createTranscription(
                audioData: data,
                filename: preflight.filename,
                contentType: preflight.contentType,
                model: settings.transcriptionModel,
                language: settings.languageCode
            )

            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw OpenAIClient.ClientError.missingOutputText
            }

            transcriptBuffer.append(trimmed)
            await onEvent(.transcriptAppended(trimmed))

            let context = await contextProvider()
            let input = CoachInput(
                context: context,
                transcript: transcriptBuffer.window(maxChars: 4000),
                previousQuestion: lastKnownQuestion
            )
            if let suggestion = try await buildCoachSuggestion(client: client, settings: settings, input: input) {
                await onEvent(.suggestionUpdated(suggestion))
            }
        } catch {
            await onEvent(.error(ImportedAudioErrorPresenter.message(for: error)))
        }

        await onEvent(.stopped)
        await onEvent(.statusChanged(.idle))
    }

    private func scheduleCoachUpdateIfNeeded(settings: RuntimeSettings, client: OpenAIClient) async {
        let now = Date()
        let delay = CoachThrottle.delay(lastCoachCallAt: lastCoachCallAt, now: now, lowCostMode: settings.lowCostMode)

        guard scheduledCoachTask == nil else { return }
        scheduledCoachTask = Task { [weak self] in
            guard let self else { return }
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            await self.performCoachUpdate(client: client)
        }
    }

    private func performCoachUpdate(client: OpenAIClient) async {
        scheduledCoachTask = nil
        guard let onEvent, let settingsProvider else { return }

        let settings = await settingsProvider()
        guard let input = pendingCoachInput else { return }
        pendingCoachInput = nil

        lastCoachCallAt = Date()

        do {
            if let suggestion = try await buildCoachSuggestion(client: client, settings: settings, input: input) {
                await onEvent(.suggestionUpdated(suggestion))
            }
        } catch {
            await onEvent(.error("Coach fallo: \(error.localizedDescription)"))
        }
    }

    private func buildCoachSuggestion(client: OpenAIClient, settings: RuntimeSettings, input: CoachInput) async throws -> CoachSuggestion? {
        let model = settings.coachModel
        let schema = CoachOutput.schema
        let systemPrompt = Prompts.systemDesignCoachSystemPrompt(languageCode: settings.languageCode)
        let userPrompt = Prompts.systemDesignUserPrompt(input: input, languageCode: settings.languageCode)

        let outputText = try await client.createCoachJSON(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            model: model,
            schema: schema,
            maxOutputTokens: settings.lowCostMode ? 220 : 320
        )

        guard let jsonData = JSONExtractor.firstJSONObjectData(in: outputText) ?? outputText.data(using: .utf8) else {
            return nil
        }

        let decoded = try JSONDecoder().decode(CoachOutput.self, from: jsonData)
        guard decoded.confidence >= 0.6, decoded.shouldUpdate else { return nil }

        let fingerprint = "\(decoded.currentQuestion)|\(decoded.shortScript)|\(decoded.tradeoffs.joined(separator: ";"))"
        guard fingerprint != lastSuggestionFingerprint else { return nil }
        lastSuggestionFingerprint = fingerprint
        lastKnownQuestion = decoded.currentQuestion
        return decoded.asSuggestion
    }
}
