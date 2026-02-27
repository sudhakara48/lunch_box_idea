import Foundation
import Combine

/// ViewModel for the Favorites screen.
///
/// Mirrors `FavoritesStore.favorites` and exposes a `delete(id:)` action
/// that delegates to the store.
///
/// - Requirements: 8.1, 8.2, 8.3
@MainActor
public final class FavoritesViewModel: ObservableObject {

    // MARK: - Published state

    /// All saved ideas in reverse-chronological order, mirrored from `FavoritesStore`.
    @Published public private(set) var favorites: [LunchBoxIdea] = []

    /// Non-nil when a delete operation fails.
    @Published public var errorState: AppError? = nil

    // MARK: - Dependencies

    private let favoritesStore: FavoritesStore
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(favoritesStore: FavoritesStore) {
        self.favoritesStore = favoritesStore

        // Mirror store's favorites into our own @Published property so
        // any view observing this ViewModel re-renders on changes.
        favoritesStore.$favorites
            .receive(on: RunLoop.main)
            .assign(to: &$favorites)
    }

    // MARK: - Actions

    /// Deletes the saved idea with the given `id`.
    ///
    /// Delegates to `FavoritesStore.delete(id:)`. Any error is captured in `errorState`.
    public func delete(id: UUID) {
        do {
            try favoritesStore.delete(id: id)
        } catch {
            errorState = .unknown(error.localizedDescription)
        }
    }
}
