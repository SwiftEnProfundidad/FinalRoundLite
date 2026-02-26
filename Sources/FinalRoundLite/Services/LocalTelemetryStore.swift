import Foundation

struct LocalTelemetrySnapshot: Codable, Sendable, Equatable {
    var sessionCount: Int
    var averageProcessingSeconds: Double

    static let empty = LocalTelemetrySnapshot(
        sessionCount: 0,
        averageProcessingSeconds: 0
    )
}

protocol TelemetryPersisting: Sendable {
    func recordSession(processingSeconds: Double) async throws
    func snapshot() async throws -> LocalTelemetrySnapshot
}

actor LocalTelemetryStore: TelemetryPersisting {
    private let fileManager: FileManager
    private let baseDirectoryURL: URL?
    private var cachedSnapshot: LocalTelemetrySnapshot?

    init(fileManager: FileManager = .default, baseDirectoryURL: URL? = nil) {
        self.fileManager = fileManager
        self.baseDirectoryURL = baseDirectoryURL
    }

    func recordSession(processingSeconds: Double) throws {
        let current = try loadSnapshot()
        let nextCount = current.sessionCount + 1
        let totalSeconds = current.averageProcessingSeconds * Double(current.sessionCount)
        let nextAverage = (totalSeconds + max(0, processingSeconds)) / Double(nextCount)
        let updated = LocalTelemetrySnapshot(
            sessionCount: nextCount,
            averageProcessingSeconds: nextAverage
        )
        try writeSnapshot(updated)
    }

    func snapshot() throws -> LocalTelemetrySnapshot {
        try loadSnapshot()
    }

    private func loadSnapshot() throws -> LocalTelemetrySnapshot {
        if let cachedSnapshot {
            return cachedSnapshot
        }
        let url = try telemetryFileURL()
        guard fileManager.fileExists(atPath: url.path()) else {
            cachedSnapshot = .empty
            return .empty
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let snapshot = try decoder.decode(LocalTelemetrySnapshot.self, from: data)
        cachedSnapshot = snapshot
        return snapshot
    }

    private func writeSnapshot(_ snapshot: LocalTelemetrySnapshot) throws {
        let url = try telemetryFileURL()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: .atomic)
        cachedSnapshot = snapshot
    }

    private func telemetryFileURL() throws -> URL {
        let directory: URL
        if let baseDirectoryURL {
            directory = baseDirectoryURL
        } else {
            directory = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            .appendingPathComponent("FinalRoundLite", isDirectory: true)
        }

        if !fileManager.fileExists(atPath: directory.path()) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent("telemetry.json")
    }
}
