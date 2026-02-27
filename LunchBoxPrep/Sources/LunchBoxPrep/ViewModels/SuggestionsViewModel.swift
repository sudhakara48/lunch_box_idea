import Foundation
import Combine

// MARK: - AppError

/// User-facing errors surfaced by `SuggestionsViewModel`.
public enum AppError: Error, Equatable {
    case missingAPIKey
    case networkUnavailable
    case httpError(String)
    case insufficientSuggestions
    case unknown(String)

    /// A human-readable message suitable for display in the UI.
    public var userMessage: String {
        switch self {
        case .missingAPIKey:
            return "No API key found. Please add your API key in Settings."
        case .networkUnavailable:
            return "You appear to be offline. Please check your connection and try again."
        case let .httpError(detail):
            return detail
        case .insufficientSuggestions:
            return "Not enough suggestions were returned. Please try again."
        case let .unknown(detail):
            return "Something went wrong. Please try again. (\(detail))"
        }
    }
}

// MARK: - SuggestionsViewModel

@MainActor
public final class SuggestionsViewModel: ObservableObject {

    @Published public private(set) var ideas: [LunchBoxIdea] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public var errorState: AppError? = nil

    private let suggestionEngine: SuggestionEngineProtocol
    private let inventoryStore: InventoryStore
    private let preferencesStore: PreferencesStore
    private let youtubeService: YouTubeServiceProtocol?

    public init(
        suggestionEngine: SuggestionEngineProtocol,
        inventoryStore: InventoryStore,
        preferencesStore: PreferencesStore,
        youtubeService: YouTubeServiceProtocol? = nil
    ) {
        self.suggestionEngine = suggestionEngine
        self.inventoryStore = inventoryStore
        self.preferencesStore = preferencesStore
        self.youtubeService = youtubeService
    }

    public func fetchSuggestions() async {
        guard !isLoading else { return }
        isLoading = true
        errorState = nil

        do {
            var results = try await suggestionEngine.getSuggestions(
                inventory: inventoryStore.items,
                preferences: preferencesStore.preferences
            )
            ideas = results

            // Fetch YouTube video IDs concurrently for each idea
            if let youtube = youtubeService {
                await withTaskGroup(of: (Int, String?).self) { group in
                    for (index, idea) in results.enumerated() {
                        group.addTask {
                            let videoID = try? await youtube.searchVideoID(for: idea.name)
                            return (index, videoID)
                        }
                    }
                    for await (index, videoID) in group {
                        results[index].youtubeVideoID = videoID
                    }
                }
                ideas = results
            }
        } catch let clientError as AIClientError {
            errorState = map(clientError)
        } catch {
            errorState = .unknown(error.localizedDescription)
        }

        isLoading = false
    }

    private func map(_ error: AIClientError) -> AppError {
        switch error {
        case .missingAPIKey:
            return .missingAPIKey
        case .networkUnavailable:
            return .networkUnavailable
        case let .httpError(statusCode, body):
            let detail = error.errorDescription ?? "HTTP \(statusCode): \(body)"
            return .httpError(detail)
        case .insufficientSuggestions:
            return .insufficientSuggestions
        case let .invalidResponse(detail):
            return .unknown(detail)
        }
    }
}
