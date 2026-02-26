import XCTest
@testable import FinalRoundLite

final class SessionStoreTests: XCTestCase {
    func testSave_writesSessionJSONFile() async throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FinalRoundLiteTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let store = SessionStore(baseDirectoryURL: tempRoot)
        let session = PersistedSession(
            savedAt: Date(timeIntervalSince1970: 1_700_000_000),
            context: ContextCard(problem: "URL shortener", users: "devs", scale: "1M/day", data: "links", slos: "p95 200ms", constraints: "cost", preferredStack: "Swift"),
            transcript: "Necesitamos alta disponibilidad.",
            suggestion: PersistedSuggestion(
                currentQuestion: "Como modelarias la base de datos?",
                shortScript: "Primero separaria lectura y escritura.",
                clarifyingQuestions: ["TTL por enlace?"],
                tradeoffs: ["SQL vs NoSQL"],
                nextSteps: ["Definir particionado"]
            )
        )

        let url = try await store.save(session: session, retentionLimit: 10)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path()))
        let markdownURL = url.deletingPathExtension().appendingPathExtension("md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: markdownURL.path()))

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PersistedSession.self, from: data)
        XCTAssertEqual(decoded.transcript, session.transcript)
        XCTAssertEqual(decoded.context.problem, "URL shortener")

        let markdown = try String(contentsOf: markdownURL, encoding: .utf8)
        XCTAssertTrue(markdown.contains("# FinalRound Lite Session"))
        XCTAssertTrue(markdown.contains("URL shortener"))
    }

    func testListSessions_returnsMostRecentFirst() async throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FinalRoundLiteTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let store = SessionStore(baseDirectoryURL: tempRoot)

        let older = PersistedSession(
            savedAt: Date(timeIntervalSince1970: 1_700_000_000),
            context: ContextCard(),
            transcript: "older",
            suggestion: PersistedSuggestion(currentQuestion: "q1", shortScript: "s1", clarifyingQuestions: [], tradeoffs: [], nextSteps: [])
        )
        let newer = PersistedSession(
            savedAt: Date(timeIntervalSince1970: 1_700_000_100),
            context: ContextCard(),
            transcript: "newer",
            suggestion: PersistedSuggestion(currentQuestion: "q2", shortScript: "s2", clarifyingQuestions: [], tradeoffs: [], nextSteps: [])
        )

        _ = try await store.save(session: older, retentionLimit: 10)
        let newestURL = try await store.save(session: newer, retentionLimit: 10)

        let sessions = try await store.listSessions(limit: 10)
        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(sessions.first?.jsonURL.lastPathComponent, newestURL.lastPathComponent)
        XCTAssertNotNil(sessions.first?.markdownURL)
    }

    func testSave_enforcesRetentionLimit() async throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FinalRoundLiteTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let store = SessionStore(baseDirectoryURL: tempRoot)
        let first = PersistedSession(
            savedAt: Date(timeIntervalSince1970: 1_700_000_000),
            context: ContextCard(),
            transcript: "first",
            suggestion: PersistedSuggestion(currentQuestion: "q1", shortScript: "s1", clarifyingQuestions: [], tradeoffs: [], nextSteps: [])
        )
        let second = PersistedSession(
            savedAt: Date(timeIntervalSince1970: 1_700_000_100),
            context: ContextCard(),
            transcript: "second",
            suggestion: PersistedSuggestion(currentQuestion: "q2", shortScript: "s2", clarifyingQuestions: [], tradeoffs: [], nextSteps: [])
        )
        let third = PersistedSession(
            savedAt: Date(timeIntervalSince1970: 1_700_000_200),
            context: ContextCard(),
            transcript: "third",
            suggestion: PersistedSuggestion(currentQuestion: "q3", shortScript: "s3", clarifyingQuestions: [], tradeoffs: [], nextSteps: [])
        )

        _ = try await store.save(session: first, retentionLimit: 2)
        _ = try await store.save(session: second, retentionLimit: 2)
        _ = try await store.save(session: third, retentionLimit: 2)

        let sessions = try await store.listSessions(limit: 10)
        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(sessions.map { $0.jsonURL.lastPathComponent }.count, 2)
        let transcripts = try sessions.map { record in
            let data = try Data(contentsOf: record.jsonURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(PersistedSession.self, from: data)
            return decoded.transcript
        }
        XCTAssertEqual(Set(transcripts), Set(["second", "third"]))
    }

    func testDelete_removesJSONAndMarkdown() async throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FinalRoundLiteTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let store = SessionStore(baseDirectoryURL: tempRoot)
        let session = PersistedSession(
            savedAt: Date(timeIntervalSince1970: 1_700_000_000),
            context: ContextCard(),
            transcript: "to-delete",
            suggestion: PersistedSuggestion(currentQuestion: "q", shortScript: "s", clarifyingQuestions: [], tradeoffs: [], nextSteps: [])
        )

        let jsonURL = try await store.save(session: session, retentionLimit: 10)
        let markdownURL = jsonURL.deletingPathExtension().appendingPathExtension("md")
        let listed = try await store.listSessions(limit: 10)
        XCTAssertEqual(listed.count, 1)

        try await store.delete(session: listed[0])

        XCTAssertFalse(FileManager.default.fileExists(atPath: jsonURL.path()))
        XCTAssertFalse(FileManager.default.fileExists(atPath: markdownURL.path()))
        let remaining = try await store.listSessions(limit: 10)
        XCTAssertTrue(remaining.isEmpty)
    }

    func testDeleteAllSessions_removesAllPersistedFiles() async throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FinalRoundLiteTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let store = SessionStore(baseDirectoryURL: tempRoot)
        let first = PersistedSession(
            savedAt: Date(timeIntervalSince1970: 1_700_000_000),
            context: ContextCard(),
            transcript: "first",
            suggestion: PersistedSuggestion(currentQuestion: "q1", shortScript: "s1", clarifyingQuestions: [], tradeoffs: [], nextSteps: [])
        )
        let second = PersistedSession(
            savedAt: Date(timeIntervalSince1970: 1_700_000_100),
            context: ContextCard(),
            transcript: "second",
            suggestion: PersistedSuggestion(currentQuestion: "q2", shortScript: "s2", clarifyingQuestions: [], tradeoffs: [], nextSteps: [])
        )

        _ = try await store.save(session: first, retentionLimit: 10)
        _ = try await store.save(session: second, retentionLimit: 10)
        let listed = try await store.listSessions(limit: 10)
        XCTAssertEqual(listed.count, 2)

        try await store.deleteAllSessions()

        let remaining = try await store.listSessions(limit: 10)
        XCTAssertTrue(remaining.isEmpty)
    }
}
