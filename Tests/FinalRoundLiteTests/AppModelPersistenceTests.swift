import XCTest
@testable import FinalRoundLite

final class AppModelPersistenceTests: XCTestCase {
    @MainActor
    func testConsumeStopped_persistsSessionWhenEnabled() async throws {
        let storeSpy = SessionStoreSpy()
        let model = AppModel(sessionStore: storeSpy)
        model.persistSessionsLocally = true
        model.sessionRetentionLimit = 5
        model.transcript = "transcript de prueba"
        model.currentQuestion = "pregunta actual"

        model.consume(.stopped)
        try await Task.sleep(nanoseconds: 150_000_000)

        let savedCount = await storeSpy.savedCount()
        let savedTranscript = await storeSpy.firstSavedTranscript()
        let retentionLimit = await storeSpy.firstRetentionLimit()
        XCTAssertEqual(savedCount, 1)
        XCTAssertEqual(savedTranscript, "transcript de prueba")
        XCTAssertEqual(retentionLimit, 5)
    }

    @MainActor
    func testConsumeStopped_doesNotPersistWhenDisabled() async throws {
        let storeSpy = SessionStoreSpy()
        let model = AppModel(sessionStore: storeSpy)
        model.persistSessionsLocally = false
        model.transcript = "transcript de prueba"
        model.currentQuestion = "pregunta actual"

        model.consume(.stopped)
        try await Task.sleep(nanoseconds: 150_000_000)

        let savedCount = await storeSpy.savedCount()
        XCTAssertEqual(savedCount, 0)
    }

    @MainActor
    func testConsumeStopped_doesNotPersistDuplicateSession() async throws {
        let storeSpy = SessionStoreSpy()
        let model = AppModel(sessionStore: storeSpy)
        model.persistSessionsLocally = true
        model.transcript = "transcript duplicado"
        model.currentQuestion = "pregunta duplicada"

        model.consume(.stopped)
        try await Task.sleep(nanoseconds: 150_000_000)
        model.consume(.stopped)
        try await Task.sleep(nanoseconds: 150_000_000)

        let savedCount = await storeSpy.savedCount()
        XCTAssertEqual(savedCount, 1)
    }

    @MainActor
    func testRefreshSavedSessions_loadsMostRecentSessions() async throws {
        let storeSpy = SessionStoreSpy()
        let openerSpy = FileOpenerSpy()
        let model = AppModel(sessionStore: storeSpy, fileOpener: openerSpy)

        let first = SavedSessionRecord(
            savedAt: Date(timeIntervalSince1970: 10),
            jsonURL: URL(fileURLWithPath: "/tmp/session-1.json"),
            markdownURL: URL(fileURLWithPath: "/tmp/session-1.md")
        )
        let second = SavedSessionRecord(
            savedAt: Date(timeIntervalSince1970: 20),
            jsonURL: URL(fileURLWithPath: "/tmp/session-2.json"),
            markdownURL: URL(fileURLWithPath: "/tmp/session-2.md")
        )
        await storeSpy.setListedSessions([second, first])

        model.refreshSavedSessions(limit: 10)
        try await Task.sleep(nanoseconds: 150_000_000)

        XCTAssertEqual(model.savedSessions, [second, first])
        XCTAssertFalse(model.isLoadingSavedSessions)
    }

    @MainActor
    func testRefreshSavedSessions_usesRetentionLimitByDefault() async throws {
        let storeSpy = SessionStoreSpy()
        let model = AppModel(sessionStore: storeSpy)
        model.sessionRetentionLimit = 3

        model.refreshSavedSessions()
        try await Task.sleep(nanoseconds: 150_000_000)

        let listedLimit = await storeSpy.latestListedLimit()
        XCTAssertEqual(listedLimit, 3)
    }

    @MainActor
    func testInit_appliesStoredCustomDirectoryToConfigurableSessionStore() async throws {
        let storeSpy = SessionStoreSpy()
        let settingsSpy = SessionPersistenceSettingsStoreSpy(
            loadedSettings: SessionPersistenceSettings(
                customDirectoryPath: "/tmp/finalround-lite-custom",
                retentionLimit: 7
            )
        )
        let model = AppModel(
            sessionStore: storeSpy,
            persistenceSettingsStore: settingsSpy
        )

        try await Task.sleep(nanoseconds: 150_000_000)

        XCTAssertFalse(model.usesDefaultSessionsDirectory)
        XCTAssertEqual(model.customSessionsDirectoryPath, "/tmp/finalround-lite-custom")
        XCTAssertEqual(model.sessionRetentionLimit, 7)

        let configuredPath = await storeSpy.latestConfiguredDirectoryPath()
        XCTAssertEqual(configuredPath, "/tmp/finalround-lite-custom")
    }

    @MainActor
    func testOpenSavedSessionActions_delegateToFileOpener() {
        let storeSpy = SessionStoreSpy()
        let openerSpy = FileOpenerSpy()
        let model = AppModel(sessionStore: storeSpy, fileOpener: openerSpy)

        let session = SavedSessionRecord(
            savedAt: Date(timeIntervalSince1970: 50),
            jsonURL: URL(fileURLWithPath: "/tmp/session-a.json"),
            markdownURL: URL(fileURLWithPath: "/tmp/session-a.md")
        )

        model.openSavedSessionJSON(session)
        model.openSavedSessionMarkdown(session)
        model.revealSavedSessionInFinder(session)

        XCTAssertEqual(openerSpy.openedURLs, [session.jsonURL, session.markdownURL!])
        XCTAssertEqual(openerSpy.revealedURLs, [session.jsonURL])
    }

    @MainActor
    func testOpenSavedSessionMarkdown_setsErrorWhenMissingMarkdown() {
        let storeSpy = SessionStoreSpy()
        let openerSpy = FileOpenerSpy()
        let model = AppModel(sessionStore: storeSpy, fileOpener: openerSpy)

        let session = SavedSessionRecord(
            savedAt: Date(timeIntervalSince1970: 50),
            jsonURL: URL(fileURLWithPath: "/tmp/session-b.json"),
            markdownURL: nil
        )

        model.openSavedSessionMarkdown(session)

        XCTAssertEqual(model.errorMessage, "No hay archivo Markdown para esta sesion.")
        XCTAssertTrue(openerSpy.openedURLs.isEmpty)
    }
}

private actor SessionStoreSpy: SessionPersisting, SessionStoreConfiguring {
    private var sessions: [PersistedSession] = []
    private var sessionsForListing: [SavedSessionRecord] = []
    private var retentionLimits: [Int?] = []
    private var listedLimits: [Int] = []
    private var configuredDirectoryURLs: [URL?] = []

    func save(session: PersistedSession, retentionLimit: Int?) async throws -> URL {
        sessions.append(session)
        retentionLimits.append(retentionLimit)
        return URL(fileURLWithPath: "/tmp/finalround-lite-session-test.json")
    }

    func listSessions(limit: Int) async throws -> [SavedSessionRecord] {
        listedLimits.append(limit)
        return Array(sessionsForListing.prefix(limit))
    }

    func setBaseDirectoryURL(_ url: URL?) async {
        configuredDirectoryURLs.append(url)
    }

    func setListedSessions(_ sessions: [SavedSessionRecord]) {
        sessionsForListing = sessions
    }

    func savedCount() -> Int {
        sessions.count
    }

    func firstSavedTranscript() -> String? {
        sessions.first?.transcript
    }

    func firstRetentionLimit() -> Int? {
        retentionLimits.first ?? nil
    }

    func latestListedLimit() -> Int? {
        listedLimits.last
    }

    func latestConfiguredDirectoryPath() -> String? {
        if let latest = configuredDirectoryURLs.last {
            return latest?.path
        }
        return nil
    }
}

private final class SessionPersistenceSettingsStoreSpy: SessionPersistenceSettingsStoring {
    private let loadedSettings: SessionPersistenceSettings

    init(loadedSettings: SessionPersistenceSettings = .default) {
        self.loadedSettings = loadedSettings
    }

    func load() -> SessionPersistenceSettings {
        loadedSettings
    }

    func save(_ settings: SessionPersistenceSettings) {}
}

@MainActor
private final class FileOpenerSpy: FileOpening {
    private(set) var openedURLs: [URL] = []
    private(set) var revealedURLs: [URL] = []

    @discardableResult
    func open(_ url: URL) -> Bool {
        openedURLs.append(url)
        return true
    }

    @discardableResult
    func reveal(_ url: URL) -> Bool {
        revealedURLs.append(url)
        return true
    }
}
