import Foundation
import XCTest
@testable import FinalRoundLite

final class SmokeFlowTests: XCTestCase {
    @MainActor
    func testStartStopFlow_keepsModelStable() {
        let model = AppModel(
            sessionStore: SessionStoreSmokeSpy(),
            telemetryStore: TelemetrySmokeSpy()
        )
        model.isListening = true

        model.consume(.started)
        XCTAssertEqual(model.status, .listening)

        model.consume(.stopped)
        XCTAssertEqual(model.status, .idle)
        XCTAssertFalse(model.isListening)
    }

    @MainActor
    func testExportMarkdownFlow_containsTranscriptAndSuggestion() {
        let model = AppModel(
            sessionStore: SessionStoreSmokeSpy(),
            telemetryStore: TelemetrySmokeSpy()
        )
        model.contextCard.problem = "Design URL shortener"
        model.transcript = "Necesitamos alta disponibilidad"
        model.currentQuestion = "Como particionarias la base de datos?"
        model.shortScript = "Empezaria por separar lectura y escritura."
        model.tradeoffs = ["SQL vs NoSQL"]

        let markdown = model.exportMarkdown()

        XCTAssertTrue(markdown.contains("# FinalRound Lite Session"))
        XCTAssertTrue(markdown.contains("## Transcript"))
        XCTAssertTrue(markdown.contains("Necesitamos alta disponibilidad"))
        XCTAssertTrue(markdown.contains("Como particionarias la base de datos?"))
        XCTAssertTrue(markdown.contains("SQL vs NoSQL"))
    }

    func testImportFlow_preflightAcceptsSupportedAudioFile() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let audioURL = directory.appendingPathComponent("smoke.m4a")
        try Data(repeating: 0x03, count: 2_048).write(to: audioURL)

        let result = try ImportedAudioPreflight.validate(fileURL: audioURL)

        XCTAssertEqual(result.filename, "smoke.m4a")
        XCTAssertEqual(result.contentType, "audio/m4a")
        XCTAssertEqual(result.fileSizeBytes, 2_048)
    }

    @MainActor
    func testHistoryCleanupFlow_keepsModelStable() async throws {
        let storeSpy = SessionStoreSmokeSpy()
        let telemetrySpy = TelemetrySmokeSpy()
        let model = AppModel(sessionStore: storeSpy, telemetryStore: telemetrySpy)

        let first = SavedSessionRecord(
            savedAt: Date(timeIntervalSince1970: 10),
            jsonURL: URL(fileURLWithPath: "/tmp/smoke-session-a.json"),
            markdownURL: URL(fileURLWithPath: "/tmp/smoke-session-a.md")
        )
        let second = SavedSessionRecord(
            savedAt: Date(timeIntervalSince1970: 20),
            jsonURL: URL(fileURLWithPath: "/tmp/smoke-session-b.json"),
            markdownURL: URL(fileURLWithPath: "/tmp/smoke-session-b.md")
        )
        await storeSpy.setListedSessions([second, first])

        model.refreshSavedSessions(limit: 10)
        try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertEqual(model.savedSessions, [second, first])

        model.deleteSavedSession(second)
        try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertEqual(model.savedSessions, [first])

        model.deleteAllSavedSessions()
        try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertTrue(model.savedSessions.isEmpty)
    }

    private func makeTempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FinalRoundLite-Smoke-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

private actor SessionStoreSmokeSpy: SessionPersisting, SessionStoreConfiguring {
    private var listedSessions: [SavedSessionRecord] = []

    func save(session: PersistedSession, retentionLimit: Int?) async throws -> URL {
        URL(fileURLWithPath: "/tmp/smoke-session.json")
    }

    func listSessions(limit: Int) async throws -> [SavedSessionRecord] {
        Array(listedSessions.prefix(limit))
    }

    func delete(session: SavedSessionRecord) async throws {
        listedSessions.removeAll { $0.id == session.id }
    }

    func deleteAllSessions() async throws {
        listedSessions.removeAll()
    }

    func setBaseDirectoryURL(_ url: URL?) async {}

    func setListedSessions(_ sessions: [SavedSessionRecord]) {
        listedSessions = sessions
    }
}

private actor TelemetrySmokeSpy: TelemetryPersisting {
    func recordSession(processingSeconds: Double) async throws {}

    func snapshot() async throws -> LocalTelemetrySnapshot {
        .empty
    }
}
