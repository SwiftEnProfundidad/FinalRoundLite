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

    private func makeTempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FinalRoundLite-Smoke-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

private actor SessionStoreSmokeSpy: SessionPersisting, SessionStoreConfiguring {
    func save(session: PersistedSession, retentionLimit: Int?) async throws -> URL {
        URL(fileURLWithPath: "/tmp/smoke-session.json")
    }

    func listSessions(limit: Int) async throws -> [SavedSessionRecord] {
        []
    }

    func setBaseDirectoryURL(_ url: URL?) async {}
}

private actor TelemetrySmokeSpy: TelemetryPersisting {
    func recordSession(processingSeconds: Double) async throws {}

    func snapshot() async throws -> LocalTelemetrySnapshot {
        .empty
    }
}
