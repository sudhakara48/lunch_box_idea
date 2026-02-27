import Foundation

// MARK: - AIClientError

/// Errors that can be thrown by `AIClient`.
public enum AIClientError: Error, LocalizedError, Equatable {
    case missingAPIKey
    case networkUnavailable
    case httpError(statusCode: Int, body: String)
    case invalidResponse(String)
    /// Thrown when the AI returns fewer than 3 suggestions.
    case insufficientSuggestions(count: Int)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No API key found. Please add your API key in Settings."
        case .networkUnavailable:
            return "You appear to be offline. Please check your connection and try again."
        case let .httpError(statusCode, _) where statusCode == 401:
            return "Invalid API key. Please check your key in Settings."
        case let .httpError(statusCode, _) where statusCode == 429:
            return "Rate limit reached — please try again shortly."
        case let .httpError(statusCode, _) where (500...599).contains(statusCode):
            return "The AI service is temporarily unavailable. Please retry."
        case let .httpError(statusCode, body):
            return "Request failed with status \(statusCode): \(body)"
        case let .invalidResponse(detail):
            return "Unexpected response from AI — please retry. (\(detail))"
        case let .insufficientSuggestions(count):
            return "Only \(count) suggestion(s) returned; at least 3 are required. Please retry."
        }
    }
}

// MARK: - KeychainError

/// Errors that can be thrown by `KeychainService`.
public enum KeychainError: Error, Equatable {
    case itemNotFound
    case duplicateItem
    case unexpectedStatus(OSStatus)
}
