import XCTest
@testable import FinalRoundLite

final class AppModelUsabilityTests: XCTestCase {
    @MainActor
    func testClearSessionOutput_clearsTranscriptAndCoachState() {
        let model = AppModel()
        model.transcript = "texto"
        model.lastTranscriptionAt = Date(timeIntervalSince1970: 10)
        model.currentQuestion = "pregunta"
        model.shortScript = "guion"
        model.clarifyingQuestions = ["q1"]
        model.tradeoffs = ["t1"]
        model.nextSteps = ["n1"]
        model.lastSuggestionAt = Date(timeIntervalSince1970: 20)
        model.errorMessage = "error previo"

        model.clearSessionOutput()

        XCTAssertEqual(model.transcript, "")
        XCTAssertNil(model.lastTranscriptionAt)
        XCTAssertEqual(model.currentQuestion, "")
        XCTAssertEqual(model.shortScript, "")
        XCTAssertEqual(model.clarifyingQuestions, [])
        XCTAssertEqual(model.tradeoffs, [])
        XCTAssertEqual(model.nextSteps, [])
        XCTAssertNil(model.lastSuggestionAt)
        XCTAssertNil(model.errorMessage)
    }

    @MainActor
    func testConsumeStatusChangedAnalyzing_updatesStatus() {
        let model = AppModel()

        model.consume(.statusChanged(.analyzing))

        XCTAssertEqual(model.status, .analyzing)
    }
}
