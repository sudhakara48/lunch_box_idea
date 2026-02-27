import SwiftUI

// MARK: - FavoritesView

/// Displays saved lunch box ideas in reverse-chronological order.
///
/// - Swipe-to-delete removes an idea via `FavoritesViewModel.delete(id:)`.
/// - Tapping an idea navigates to `DetailView`.
/// - Shows an empty state when there are no saved ideas.
///
/// - Requirements: 8.1, 8.2, 8.3
public struct FavoritesView: View {

    @ObservedObject public var viewModel: FavoritesViewModel
    private let favoritesStore: FavoritesStore

    public init(viewModel: FavoritesViewModel, favoritesStore: FavoritesStore) {
        self.viewModel = viewModel
        self.favoritesStore = favoritesStore
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.favorites.isEmpty {
                    emptyState
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favorites")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            Text("No Saved Ideas")
                .font(.headline)
            Text("Save lunch box ideas from the suggestions screen to see them here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Favorites list

    private var favoritesList: some View {
        List {
            ForEach(viewModel.favorites) { idea in
                NavigationLink {
                    DetailView(idea: idea, favoritesStore: favoritesStore)
                } label: {
                    FavoriteRow(idea: idea)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.delete(id: viewModel.favorites[index].id)
                }
            }
        }
        .listStyle(.inset)
    }
}

// MARK: - FavoriteRow

private struct FavoriteRow: View {
    let idea: LunchBoxIdea

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(idea.name)
                .font(.headline)
                .lineLimit(2)
            if let savedAt = idea.savedAt {
                Text(savedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let firstIngredient = idea.ingredients.first {
                Text(firstIngredient + (idea.ingredients.count > 1 ? " +\(idea.ingredients.count - 1) more" : ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
