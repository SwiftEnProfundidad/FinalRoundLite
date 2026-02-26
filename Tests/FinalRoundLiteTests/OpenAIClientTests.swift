import XCTest
@testable import FinalRoundLite

final class OpenAIClientTests: XCTestCase {
    func testCreateTranscription_throwsNetworkError() async {
        var client = OpenAIClient(apiKey: "test")
        client.dataLoader = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await client.createTranscription(wavData: Data([0x00]), model: "gpt-4o-mini-transcribe", language: "es")
            XCTFail("Expected URLError.notConnectedToInternet")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateTranscription_throwsAPIErrorMessage_onHTTPError() async {
        var client = OpenAIClient(apiKey: "test")
        client.dataLoader = { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 429,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            let body = #"{"error":{"message":"rate limit"}}"#.data(using: .utf8) ?? Data()
            return (body, response)
        }

        do {
            _ = try await client.createTranscription(wavData: Data([0x00]), model: "gpt-4o-mini-transcribe", language: "es")
            XCTFail("Expected ClientError.apiError")
        } catch let OpenAIClient.ClientError.apiError(message) {
            XCTAssertEqual(message, "rate limit")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateTranscription_throwsDecodingError_onInvalidPayload() async {
        var client = OpenAIClient(apiKey: "test")
        client.dataLoader = { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            let body = #"{"unexpected":"value"}"#.data(using: .utf8) ?? Data()
            return (body, response)
        }

        do {
            _ = try await client.createTranscription(wavData: Data([0x00]), model: "gpt-4o-mini-transcribe", language: "es")
            XCTFail("Expected decoding error")
        } catch is DecodingError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateCoachJSON_throwsMissingOutputText_whenOutputTextIsBlank() async {
        var client = OpenAIClient(apiKey: "test")
        client.dataLoader = { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            let body = """
            {
              "output": [
                {
                  "type": "message",
                  "role": "assistant",
                  "content": [
                    { "type": "output_text", "text": "   " }
                  ]
                }
              ]
            }
            """.data(using: .utf8) ?? Data()
            return (body, response)
        }

        do {
            _ = try await client.createCoachJSON(
                systemPrompt: "system",
                userPrompt: "user",
                model: "gpt-4.1-mini",
                schema: ["type": "object"],
                maxOutputTokens: 100
            )
            XCTFail("Expected ClientError.missingOutputText")
        } catch OpenAIClient.ClientError.missingOutputText {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateTranscription_usesProvidedFilenameAndContentType() async throws {
        var client = OpenAIClient(apiKey: "test")
        client.dataLoader = { request in
            let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
            XCTAssertTrue(bodyString.contains("filename=\"sample.mp3\""))
            XCTAssertTrue(bodyString.contains("Content-Type: audio/mpeg"))

            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            let body = #"{"text":"ok"}"#.data(using: .utf8) ?? Data()
            return (body, response)
        }

        let text = try await client.createTranscription(
            audioData: Data([0x10, 0x20]),
            filename: "sample.mp3",
            contentType: "audio/mpeg",
            model: "gpt-4o-mini-transcribe",
            language: "es"
        )

        XCTAssertEqual(text, "ok")
    }

    func testCreateTranscription_targetsV1AudioTranscriptionsEndpoint() async throws {
        var client = OpenAIClient(apiKey: "test")
        client.dataLoader = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/audio/transcriptions")

            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            let body = #"{"text":"ok"}"#.data(using: .utf8) ?? Data()
            return (body, response)
        }

        _ = try await client.createTranscription(
            audioData: Data([0x10, 0x20]),
            filename: "sample.wav",
            contentType: "audio/wav",
            model: "gpt-4o-mini-transcribe",
            language: "es"
        )
    }

    func testCreateCoachJSON_targetsV1ResponsesEndpoint() async throws {
        var client = OpenAIClient(apiKey: "test")
        client.dataLoader = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/responses")

            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            let body = """
            {
              "output": [
                {
                  "type": "message",
                  "role": "assistant",
                  "content": [
                    { "type": "output_text", "text": "{\\"ok\\": true}" }
                  ]
                }
              ]
            }
            """.data(using: .utf8) ?? Data()
            return (body, response)
        }

        let json = try await client.createCoachJSON(
            systemPrompt: "system",
            userPrompt: "user",
            model: "gpt-4o-mini",
            schema: ["type": "object"],
            maxOutputTokens: 128
        )

        XCTAssertEqual(json, #"{"ok": true}"#)
    }
}
