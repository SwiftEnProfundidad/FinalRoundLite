import Foundation

struct OpenAIClient {
    enum ClientError: Error {
        case invalidURL
        case invalidResponse
        case missingOutputText
        case apiError(String)
    }

    let apiKey: String
    var baseURL = URL(string: "https://api.openai.com/v1")!
    var urlSession: URLSession = .shared

    func createTranscription(wavData: Data, model: String, language: String?) async throws -> String {
        guard let url = URL(string: "audio/transcriptions", relativeTo: baseURL) else {
            throw ClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append(multipart(boundary: boundary, name: "file", filename: "audio.wav", contentType: "audio/wav", data: wavData))
        body.append(multipart(boundary: boundary, name: "model", value: model))
        body.append(multipart(boundary: boundary, name: "response_format", value: "json"))
        if let language, !language.isEmpty {
            body.append(multipart(boundary: boundary, name: "language", value: language))
        }
        body.append(Data("--\(boundary)--\r\n".utf8))

        request.httpBody = body

        let (data, response) = try await urlSession.data(for: request)
        try validateHTTP(response: response, data: data)

        struct TranscriptionResponse: Decodable { let text: String }
        let decoded = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        return decoded.text
    }

    func createCoachJSON(systemPrompt: String, userPrompt: String, model: String, schema: [String: Any], maxOutputTokens: Int) async throws -> String {
        guard let url = URL(string: "responses", relativeTo: baseURL) else {
            throw ClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "store": false,
            "max_output_tokens": maxOutputTokens,
            "temperature": 0.2,
            "input": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "coach_suggestion",
                    "schema": schema,
                    "strict": true
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await urlSession.data(for: request)
        try validateHTTP(response: response, data: data)

        let envelope = try JSONDecoder().decode(ResponseEnvelope.self, from: data)
        let output = envelope.outputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !output.isEmpty else { throw ClientError.missingOutputText }
        return output
    }

    private func validateHTTP(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            if let message = decodeAPIErrorMessage(from: data) {
                throw ClientError.apiError(message)
            }
            throw ClientError.invalidResponse
        }
    }

    private func decodeAPIErrorMessage(from data: Data) -> String? {
        struct ErrorEnvelope: Decodable {
            struct APIError: Decodable { let message: String? }
            let error: APIError?
        }
        return (try? JSONDecoder().decode(ErrorEnvelope.self, from: data))?.error?.message
    }

    private func multipart(boundary: String, name: String, value: String) -> Data {
        var data = Data()
        data.append(Data("--\(boundary)\r\n".utf8))
        data.append(Data("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8))
        data.append(Data(value.utf8))
        data.append(Data("\r\n".utf8))
        return data
    }

    private func multipart(boundary: String, name: String, filename: String, contentType: String, data: Data) -> Data {
        var out = Data()
        out.append(Data("--\(boundary)\r\n".utf8))
        out.append(Data("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".utf8))
        out.append(Data("Content-Type: \(contentType)\r\n\r\n".utf8))
        out.append(data)
        out.append(Data("\r\n".utf8))
        return out
    }
}

struct ResponseEnvelope: Decodable {
    struct OutputItem: Decodable {
        struct ContentItem: Decodable {
            let type: String?
            let text: String?
        }

        let type: String?
        let role: String?
        let content: [ContentItem]?
    }

    let output: [OutputItem]?

    var outputText: String {
        let items = output ?? []
        let texts = items.flatMap { item in
            (item.content ?? [])
                .filter { $0.type == "output_text" }
                .compactMap { $0.text }
        }
        return texts.joined(separator: "\n")
    }
}

