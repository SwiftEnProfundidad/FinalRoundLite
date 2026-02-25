import Foundation

protocol SessionPersisting: Sendable {
    func save(session: PersistedSession) async throws -> URL
    func listSessions(limit: Int) async throws -> [SavedSessionRecord]
}

struct SavedSessionRecord: Sendable, Identifiable, Equatable {
    var savedAt: Date
    var jsonURL: URL
    var markdownURL: URL?

    var id: String { jsonURL.path }
}

struct PersistedSuggestion: Codable, Sendable {
    var currentQuestion: String
    var shortScript: String
    var clarifyingQuestions: [String]
    var tradeoffs: [String]
    var nextSteps: [String]
}

struct PersistedSession: Codable, Sendable {
    var savedAt: Date
    var context: ContextCard
    var transcript: String
    var suggestion: PersistedSuggestion
}

actor SessionStore: SessionPersisting {
    private let fileManager: FileManager
    private let baseDirectoryURL: URL?

    init(fileManager: FileManager = .default, baseDirectoryURL: URL? = nil) {
        self.fileManager = fileManager
        self.baseDirectoryURL = baseDirectoryURL
    }

    func save(session: PersistedSession) throws -> URL {
        let directory = try sessionsDirectoryURL()
        let timestamp = Int(session.savedAt.timeIntervalSince1970)
        let suffix = String(UUID().uuidString.prefix(8))
        let jsonURL = directory.appendingPathComponent("session-\(timestamp)-\(suffix).json")
        let markdownURL = directory.appendingPathComponent("session-\(timestamp)-\(suffix).md")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let payload = try encoder.encode(session)
        try payload.write(to: jsonURL, options: .atomic)

        let markdown = MarkdownExporter.export(
            context: session.context,
            transcript: session.transcript,
            suggestion: CoachSuggestion(
                currentQuestion: session.suggestion.currentQuestion,
                shortScript: session.suggestion.shortScript,
                clarifyingQuestions: session.suggestion.clarifyingQuestions,
                tradeoffs: session.suggestion.tradeoffs,
                nextSteps: session.suggestion.nextSteps,
                createdAt: session.savedAt
            )
        )
        try Data(markdown.utf8).write(to: markdownURL, options: .atomic)

        return jsonURL
    }

    func listSessions(limit: Int) throws -> [SavedSessionRecord] {
        guard limit > 0 else { return [] }
        let directory = try sessionsDirectoryURL()
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        let sessionJSONFiles = urls.filter {
            $0.pathExtension.lowercased() == "json" && $0.lastPathComponent.hasPrefix("session-")
        }

        let records = sessionJSONFiles.map { jsonURL in
            let markdownCandidate = jsonURL.deletingPathExtension().appendingPathExtension("md")
            return SavedSessionRecord(
                savedAt: savedDate(for: jsonURL),
                jsonURL: jsonURL,
                markdownURL: fileManager.fileExists(atPath: markdownCandidate.path) ? markdownCandidate : nil
            )
        }

        return records
            .sorted { $0.savedAt > $1.savedAt }
            .prefix(limit)
            .map { $0 }
    }

    private func sessionsDirectoryURL() throws -> URL {
        let root: URL
        if let baseDirectoryURL {
            root = baseDirectoryURL
        } else {
            root = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }

        let sessionsDirectory = root
            .appendingPathComponent("FinalRoundLite", isDirectory: true)
            .appendingPathComponent("sessions", isDirectory: true)

        if !fileManager.fileExists(atPath: sessionsDirectory.path()) {
            try fileManager.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)
        }
        return sessionsDirectory
    }

    private func savedDate(for url: URL) -> Date {
        let filename = url.deletingPathExtension().lastPathComponent
        let components = filename.split(separator: "-")
        if components.count >= 3, components[0] == "session", let epoch = TimeInterval(components[1]) {
            return Date(timeIntervalSince1970: epoch)
        }

        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey])
        if let modified = values?.contentModificationDate {
            return modified
        }
        if let created = values?.creationDate {
            return created
        }
        return .distantPast
    }
}
