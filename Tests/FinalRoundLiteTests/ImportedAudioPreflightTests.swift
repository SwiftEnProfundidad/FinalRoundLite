import XCTest
@testable import FinalRoundLite

final class ImportedAudioPreflightTests: XCTestCase {
    func testValidate_acceptsSupportedFileWithinLimit() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("sample.mp3")
        try Data(repeating: 0x01, count: 1024).write(to: fileURL)

        let result = try ImportedAudioPreflight.validate(fileURL: fileURL, maxBytes: 10 * 1024)

        XCTAssertEqual(result.filename, "sample.mp3")
        XCTAssertEqual(result.contentType, "audio/mpeg")
        XCTAssertEqual(result.fileSizeBytes, 1024)
    }

    func testValidate_rejectsUnsupportedExtension() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("sample.txt")
        try Data(repeating: 0x01, count: 16).write(to: fileURL)

        XCTAssertThrowsError(try ImportedAudioPreflight.validate(fileURL: fileURL)) { error in
            XCTAssertEqual(error as? ImportedAudioPreflightError, .unsupportedFileType("txt"))
        }
    }

    func testValidate_rejectsEmptyFile() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("sample.wav")
        try Data().write(to: fileURL)

        XCTAssertThrowsError(try ImportedAudioPreflight.validate(fileURL: fileURL)) { error in
            XCTAssertEqual(error as? ImportedAudioPreflightError, .emptyFile)
        }
    }

    func testValidate_rejectsFileTooLarge() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("sample.wav")
        try Data(repeating: 0x02, count: 4096).write(to: fileURL)

        XCTAssertThrowsError(try ImportedAudioPreflight.validate(fileURL: fileURL, maxBytes: 1024)) { error in
            guard case let ImportedAudioPreflightError.fileTooLarge(fileSizeBytes, maxBytes) = error else {
                XCTFail("Expected fileTooLarge error")
                return
            }
            XCTAssertEqual(fileSizeBytes, 4096)
            XCTAssertEqual(maxBytes, 1024)
        }
    }

    func testErrorPresenter_returnsTimeoutMessage() {
        let message = ImportedAudioErrorPresenter.message(for: URLError(.timedOut))
        XCTAssertTrue(message.contains("Timeout"))
    }

    func testErrorPresenter_returnsOfflineMessage() {
        let message = ImportedAudioErrorPresenter.message(for: URLError(.notConnectedToInternet))
        XCTAssertTrue(message.contains("conexion de red"))
    }

    func testErrorPresenter_returnsUnsupportedFormatMessage() {
        let message = ImportedAudioErrorPresenter.message(for: ImportedAudioPreflightError.unsupportedFileType("txt"))
        XCTAssertTrue(message.contains("Formato no soportado"))
    }

    func testErrorPresenter_returnsMissingTranscriptionMessage() {
        let message = ImportedAudioErrorPresenter.message(for: OpenAIClient.ClientError.missingOutputText)
        XCTAssertTrue(message.contains("no devolvio transcripcion"))
    }

    private func makeTempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FinalRoundLite-ImportedAudioTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
