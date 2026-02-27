import Foundation
import Combine

/// Persists saved `LunchBoxIdea` values to `Documents/favorites.json`.
///
/// - `favorites` is always kept in reverse-chronological order by `savedAt`.
/// - On decode failure the raw file is preserved and `favorites` is set to `[]`.
@MainActor
public final class FavoritesStore: ObservableObject {

    /// All saved ideas, newest first.
    @Published public private(set) var favorites: [LunchBoxIdea] = []

    /// The URL used for reading and writing the favorites JSON file.
    /// Defaults to `<Documents>/favorites.json`; injectable for testing.
    public let fileURL: URL

    // MARK: - Init

    public init(fileURL: URL? = nil) {
        if let url = fileURL {
            self.fileURL = url
        } else {
            let documents = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
            self.fileURL = documents.appendingPathComponent("favorites.json")
        }
    }

    // MARK: - Public API

    /// Persists `idea` to favorites, stamping `savedAt = Date()` before writing.
    /// The in-memory list is kept sorted newest-first.
    public func save(_ idea: LunchBoxIdea) throws {
        var stamped = idea
        stamped.savedAt = Date()

        // Replace existing entry if the same id was already saved.
        favorites.removeAll { $0.id == stamped.id }
        favorites.append(stamped)
        sortDescending()
        try writeToDisk()
    }

    /// Removes the idea with the given `id` from favorites and persists the change.
    public func delete(id: UUID) throws {
        favorites.removeAll { $0.id == id }
        try writeToDisk()
    }

    /// Loads favorites from disk into `favorites`.
    ///
    /// On a decode failure the error is logged with `print()`, `favorites` is set
    /// to `[]`, and the raw file is left untouched so no data is lost.
    public func load() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            favorites = []
            return
        }

        let data = try Data(contentsOf: fileURL)

        do {
            let decoded = try JSONDecoder().decode([LunchBoxIdea].self, from: data)
            favorites = decoded
            sortDescending()
        } catch {
            print("[FavoritesStore] Decode failure — presenting empty list. Error: \(error)")
            favorites = []
            // Raw file is intentionally NOT deleted so the user's data is preserved.
        }
    }

    // MARK: - Private helpers

    private func sortDescending() {
        favorites.sort {
            ($0.savedAt ?? .distantPast) > ($1.savedAt ?? .distantPast)
        }
    }

    private func writeToDisk() throws {
        let data = try JSONEncoder().encode(favorites)
        try data.write(to: fileURL, options: .atomic)
    }
}
