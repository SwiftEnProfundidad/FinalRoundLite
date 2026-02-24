import XCTest
@testable import FinalRoundLite

final class FinalRoundLiteTests: XCTestCase {
    func testJSONExtractor_findsFirstJSONObject() {
        let text = "prefix {\"a\":1,\"b\":\"x\"} suffix"
        let data = JSONExtractor.firstJSONObjectData(in: text)
        XCTAssertNotNil(data)
        XCTAssertEqual(String(data: data!, encoding: .utf8), "{\"a\":1,\"b\":\"x\"}")
    }
}

