import Foundation
import Combine

/// Observable store holding the current session's inventory.
/// Inventory is in-memory only — no persistence between launches.
@MainActor
public final class InventoryStore: ObservableObject {

    @Published public private(set) var items: [InventoryItem] = []

    public init() {}

    /// Appends a new item to the inventory.
    public func add(_ item: InventoryItem) {
        items.append(item)
    }

    /// Replaces the existing item with the same `id`.
    /// If no item with that `id` exists, this is a no-op.
    public func update(_ item: InventoryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
    }

    /// Removes the item with the given `id`.
    /// If no item with that `id` exists, this is a no-op.
    public func remove(id: UUID) {
        items.removeAll { $0.id == id }
    }

    /// Removes all items from the inventory.
    public func clear() {
        items.removeAll()
    }
}
