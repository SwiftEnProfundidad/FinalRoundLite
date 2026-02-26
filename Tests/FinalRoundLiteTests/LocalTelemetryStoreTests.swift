import XCTest
@testable import FinalRoundLite

final class LocalTelemetryStoreTests: XCTestCase {
    func testSnapshot_isEmptyWhenNoDataFileExists() async throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FinalRoundLiteTelemetry-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let store = LocalTelemetryStore(baseDirectoryURL: tempRoot)
        let snapshot = try await store.snapshot()

        XCTAssertEqual(snapshot, .empty)
    }

    func testRecordSession_updatesCountAndAverage() async throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FinalRoundLiteTelemetry-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let store = LocalTelemetryStore(baseDirectoryURL: tempRoot)
        try await store.recordSession(processingSeconds: 4)
        try await store.recordSession(processingSeconds: 10)

        let snapshot = try await store.snapshot()
        XCTAssertEqual(snapshot.sessionCount, 2)
        XCTAssertEqual(snapshot.averageProcessingSeconds, 7, accuracy: 0.001)
    }
}
