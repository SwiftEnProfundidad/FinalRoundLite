import XCTest
@testable import FinalRoundLite

final class CoachThrottleTests: XCTestCase {
    func testDelay_isZeroWhenThereIsNoPreviousCoachCall() {
        let now = Date(timeIntervalSince1970: 10_000)

        let delay = CoachThrottle.delay(lastCoachCallAt: nil, now: now, lowCostMode: false)

        XCTAssertEqual(delay, 0, accuracy: 0.001)
    }

    func testDelay_usesEightSecondsWhenLowCostModeIsDisabled() {
        let now = Date(timeIntervalSince1970: 10_000)
        let lastCall = now.addingTimeInterval(-3)

        let delay = CoachThrottle.delay(lastCoachCallAt: lastCall, now: now, lowCostMode: false)

        XCTAssertEqual(delay, 5, accuracy: 0.001)
    }

    func testDelay_usesFifteenSecondsWhenLowCostModeIsEnabled() {
        let now = Date(timeIntervalSince1970: 10_000)
        let lastCall = now.addingTimeInterval(-3)

        let delay = CoachThrottle.delay(lastCoachCallAt: lastCall, now: now, lowCostMode: true)

        XCTAssertEqual(delay, 12, accuracy: 0.001)
    }

    func testDelay_neverReturnsNegativeValues() {
        let now = Date(timeIntervalSince1970: 10_000)
        let lastCall = now.addingTimeInterval(-99)

        let delay = CoachThrottle.delay(lastCoachCallAt: lastCall, now: now, lowCostMode: false)

        XCTAssertEqual(delay, 0, accuracy: 0.001)
    }
}
