import Foundation
import Combine

/// ViewModel for the Inventory screen.
///
/// Wraps `InventoryStore` and re-publishes its `items` so SwiftUI views
/// receive updates automatically. All mutations delegate to the store.
///
/// - Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6
@MainActor
public final class InventoryViewModel: ObservableObject {

    // MARK: - Published state

    /// The current inventory items, mirrored from `InventoryStore`.
    @Published public private(set) var items: [InventoryItem] = []

    /// Controls the "Clear All" confirmation alert.
    @Published public var showClearConfirmation: Bool = false

    // MARK: - Derived state

    /// `true` iff the inventory contains at least one item.
    /// Drives the enabled/disabled state of the "Get Lunch Box Ideas" button.
    public var canRequestSuggestions: Bool {
        !items.isEmpty
    }

    // MARK: - Dependencies

    private let inventoryStore: InventoryStore
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(inventoryStore: InventoryStore) {
        self.inventoryStore = inventoryStore

        // Mirror store's items into our own @Published property so
        // any view observing this ViewModel re-renders on changes.
        inventoryStore.$items
            .receive(on: RunLoop.main)
            .assign(to: &$items)
    }

    // MARK: - Mutations

    /// Updates an existing inventory item (delegates to `InventoryStore.update(_:)`).
    public func editItem(_ item: InventoryItem) {
        inventoryStore.update(item)
    }

    /// Removes the item with the given `id` (delegates to `InventoryStore.remove(id:)`).
    public func removeItem(id: UUID) {
        inventoryStore.remove(id: id)
    }

    /// Clears the entire inventory (delegates to `InventoryStore.clear()`).
    /// Call this after the user confirms the "Clear All" prompt.
    public func clearAll() {
        inventoryStore.clear()
    }
}
