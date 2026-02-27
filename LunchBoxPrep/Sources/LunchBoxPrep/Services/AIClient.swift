import Foundation
import OSLog

private let logger = Logger(subsystem: "com.sudhakara.lunchboxprep", category: "AIClient")

// MARK: - Protocol

public protocol AIClientProtocol {
    func fetchSuggestions(prompt: String) async throws -> [LunchBoxIdea]
}

// MARK: - Config

public struct AIClientConfig {
    public var baseURL: URL
    public var model: String

    public init(baseURL: URL, model: String) {
        self.baseURL = baseURL
        self.model = model
    }
}

// MARK: - URLSession protocol for testability

public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - Implementation

/// Handles all HTTP communication with the Gemini `generateContent` endpoint.
/// Loads the API key from `KeychainService` and appends it as a query parameter.
/// Returns parsed `[LunchBoxIdea]` from the model's JSON response.
public final class AIClient: AIClientProtocol {

    private let keychainService: KeychainServiceProtocol
    private let config: AIClientConfig
    private let session: URLSessionProtocol

    public init(
        keychainService: KeychainServiceProtocol,
        config: AIClientConfig,
        session: URLSessionProtocol = URLSession.shared
    ) {
        self.keychainService = keychainService
        self.config = config
        self.session = session
    }

    // MARK: - fetchSuggestions

    public func fetchSuggestions(prompt: String) async throws -> [LunchBoxIdea] {
        // 1. Load API key — throw missingAPIKey if absent.
        let apiKey: String
        do {
            apiKey = try keychainService.loadAPIKey()
            logger.info("🔑 API key loaded (length: \(apiKey.count))")
        } catch {
            logger.error("❌ No API key found in keychain")
            throw AIClientError.missingAPIKey
        }

        // 2. Build the request.
        let request = try buildRequest(prompt: prompt, apiKey: apiKey)

        // 3. Execute — map network-level errors to networkUnavailable.
        let (data, response): (Data, URLResponse)
        do {
            logger.info("🌐 Requesting: \(request.url?.absoluteString ?? "nil", privacy: .public)")
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError
            where urlError.code == .notConnectedToInternet
               || urlError.code == .networkConnectionLost
               || urlError.code == .cannotConnectToHost
               || urlError.code == .timedOut {
            logger.error("❌ Network error: \(urlError.localizedDescription, privacy: .public) (code: \(urlError.code.rawValue))")
            throw AIClientError.networkUnavailable
        } catch {
            logger.error("❌ Unexpected network error: \(error.localizedDescription, privacy: .public)")
            throw AIClientError.networkUnavailable
        }

        // 4. Map HTTP errors — log full response body for non-200s.
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "<empty body>"
            logger.error("❌ HTTP \(httpResponse.statusCode) from \(httpResponse.url?.absoluteString ?? "unknown URL", privacy: .public)")
            logger.error("❌ Response body: \(body, privacy: .public)")
            if (400...599).contains(httpResponse.statusCode) {
                throw AIClientError.httpError(statusCode: httpResponse.statusCode, body: body)
            }
        }

        // 5. Parse the response into [LunchBoxIdea].
        if let httpResponse = response as? HTTPURLResponse {
            logger.info("✅ HTTP \(httpResponse.statusCode) from \(httpResponse.url?.absoluteString ?? "unknown URL", privacy: .public)")
        }
        let rawBody = String(data: data, encoding: .utf8) ?? "<non-utf8 data>"
        logger.debug("📦 Raw response: \(rawBody, privacy: .public)")
        let ideas = try parseResponse(data: data)

        // 6. Enforce minimum suggestion count.
        guard ideas.count >= 3 else {
            throw AIClientError.insufficientSuggestions(count: ideas.count)
        }

        return ideas
    }

    // MARK: - Request builder

    func buildRequest(prompt: String, apiKey: String) throws -> URLRequest {
        // Gemini endpoint: /models/{model}:generateContent?key={apiKey}
        let endpoint = config.baseURL
            .appendingPathComponent("models")
            .appendingPathComponent("\(config.model):generateContent")

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components.url else {
            throw AIClientError.invalidResponse("Failed to construct Gemini URL")
        }

        let systemPrompt = """
        You are a helpful meal-prep assistant. Given a list of available food items, \
        suggest creative and practical lunch box ideas. \
        Return a JSON object with a single key "ideas" containing an array of objects. \
        Each object must have these fields:
        - "id": a UUID string
        - "name": a non-empty string (the recipe name)
        - "ingredients": a non-empty array of strings (ingredients from the provided list)
        - "preparationSteps": a non-empty array of strings (step-by-step instructions)
        Return at least 3 ideas.
        """

        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(role: "user", parts: [GeminiPart(text: prompt)])
            ],
            systemInstruction: GeminiContent(parts: [GeminiPart(text: systemPrompt)]),
            generationConfig: GeminiGenerationConfig()
        )

        let bodyData = try JSONEncoder().encode(requestBody)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        return request
    }

    // MARK: - Response parser

    private func parseResponse(data: Data) throws -> [LunchBoxIdea] {
        // Gemini response: candidates[0].content.parts[0].text contains the JSON string.
        if let ideas = try? decodeFromGeminiEnvelope(data: data) {
            return ideas
        }

        // Fallback: try direct ideas wrapper or bare array.
        if let ideas = try? decodeIdeasWrapper(from: data) {
            return ideas
        }
        if let ideas = try? JSONDecoder().decode([LunchBoxIdea].self, from: data) {
            return ideas
        }

        throw AIClientError.invalidResponse("Unable to parse Gemini response into [LunchBoxIdea]")
    }

    /// Extracts the text from `candidates[0].content.parts[0].text` and decodes it.
    private func decodeFromGeminiEnvelope(data: Data) throws -> [LunchBoxIdea] {
        let envelope = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = envelope.candidates.first?.content.parts.first?.text,
              let contentData = text.data(using: .utf8) else {
            throw AIClientError.invalidResponse("Empty content in Gemini response")
        }

        if let ideas = try? decodeIdeasWrapper(from: contentData) {
            return ideas
        }
        return try JSONDecoder().decode([LunchBoxIdea].self, from: contentData)
    }

    /// Decodes `{ "ideas": [...] }` wrapper.
    private func decodeIdeasWrapper(from data: Data) throws -> [LunchBoxIdea] {
        struct IdeasWrapper: Decodable {
            let ideas: [LunchBoxIdea]
        }
        return try JSONDecoder().decode(IdeasWrapper.self, from: data).ideas
    }
}
