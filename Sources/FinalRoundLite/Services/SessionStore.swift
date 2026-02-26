import Foundation

protocol SessionPersisting: Sendable {
    func save(session: PersistedSession, retentionLimit: Int?) async throws -> URL
    func listSessions(limit: Int) async throws -> [SavedSessionRecord]
    func delete(session: SavedSessionRecord) async throws
    func deleteAllSessions() async throws
}

protocol SessionStoreConfiguring: Sendable {
    func setBaseDirectoryURL(_ url: URL?) async
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

actor SessionStore: SessionPersisting, SessionStoreConfiguring {
    private let fileManager: FileManager
    private var baseDirectoryURL: URL?

    init(fileManager: FileManager = .default, baseDirectoryURL: URL? = nil) {
        self.fileManager = fileManager
        self.baseDirectoryURL = baseDirectoryURL
    }

    func setBaseDirectoryURL(_ url: URL?) {
        baseDirectoryURL = url
    }

    func save(session: PersistedSession, retentionLimit: Int?) throws -> URL {
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

        if let retentionLimit {
            try enforceRetention(limit: retentionLimit, in: directory)
        }

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

    func delete(session: SavedSessionRecord) throws {
        if fileManager.fileExists(atPath: session.jsonURL.path()) {
            try fileManager.removeItem(at: session.jsonURL)
        }

        let markdownURL = session.markdownURL ??
            session.jsonURL.deletingPathExtension().appendingPathExtension("md")
        if fileManager.fileExists(atPath: markdownURL.path()) {
            try fileManager.removeItem(at: markdownURL)
        }
    }

    func deleteAllSessions() throws {
        let directory = try sessionsDirectoryURL()
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        for url in urls where url.lastPathComponent.hasPrefix("session-") {
            let ext = url.pathExtension.lowercased()
            if ext == "json" || ext == "md" {
                try fileManager.removeItem(at: url)
            }
        }
    }

    private func sessionsDirectoryURL() throws -> URL {
        let sessionsDirectory: URL
        if let baseDirectoryURL {
            sessionsDirectory = baseDirectoryURL
        } else {
            sessionsDirectory = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            .appendingPathComponent("FinalRoundLite", isDirectory: true)
            .appendingPathComponent("sessions", isDirectory: true)
        }

        if !fileManager.fileExists(atPath: sessionsDirectory.path()) {
            try fileManager.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)
        }
        return sessionsDirectory
    }

    private func enforceRetention(limit: Int, in directory: URL) throws {
        let effectiveLimit = max(1, limit)
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        let sessionJSONFiles = urls.filter {
            $0.pathExtension.lowercased() == "json" && $0.lastPathComponent.hasPrefix("session-")
        }
        let sorted = sessionJSONFiles.sorted { savedDate(for: $0) > savedDate(for: $1) }
        guard sorted.count > effectiveLimit else { return }

        let stale = sorted.dropFirst(effectiveLimit)
        for jsonURL in stale {
            try? fileManager.removeItem(at: jsonURL)
            let markdownURL = jsonURL.deletingPathExtension().appendingPathExtension("md")
            if fileManager.fileExists(atPath: markdownURL.path()) {
                try? fileManager.removeItem(at: markdownURL)
            }
        }
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
