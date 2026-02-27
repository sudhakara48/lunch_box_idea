import SwiftUI

// MARK: - InventoryView

/// Displays the current inventory with inline editing, swipe-to-delete,
/// a "Clear All" confirmation, and a "Get Lunch Box Ideas" action.
///
/// - Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6
public struct InventoryView: View {

    @ObservedObject private var viewModel: InventoryViewModel

    /// Called when the user taps "Get Lunch Box Ideas".
    /// The parent is responsible for navigation (e.g. pushing SuggestionsView).
    private let onGetIdeas: () -> Void

    public init(viewModel: InventoryViewModel, onGetIdeas: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onGetIdeas = onGetIdeas
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.items.isEmpty {
                    emptyState
                } else {
                    itemList
                }
            }
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    clearAllButton
                }
            }
            .confirmationDialog(
                "Clear all items from your inventory?",
                isPresented: $viewModel.showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) {
                    viewModel.clearAll()
                }
                Button("Cancel", role: .cancel) {}
            }
            .safeAreaInset(edge: .bottom) {
                getIdeasButton
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.bar)
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            Text("Your inventory is empty")
                .font(.headline)
            Text("Scan food items or add them manually to get started.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var itemList: some View {
        List {
            ForEach(viewModel.items) { item in
                InventoryItemRow(item: item, viewModel: viewModel)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.removeItem(id: viewModel.items[index].id)
                }
            }
        }
        .listStyle(.inset)
    }

    private var clearAllButton: some View {
        Button("Clear All", role: .destructive) {
            viewModel.showClearConfirmation = true
        }
        .disabled(viewModel.items.isEmpty)
    }

    private var getIdeasButton: some View {
        Button(action: onGetIdeas) {
            Text("Get Lunch Box Ideas")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canRequestSuggestions ? Color.green : Color.gray.opacity(0.4))
                .foregroundColor(.white)
                .cornerRadius(14)
        }
        .disabled(!viewModel.canRequestSuggestions)
    }
}

// MARK: - InventoryItemRow

/// A single row in the inventory list with inline name/quantity editing.
private struct InventoryItemRow: View {
    let item: InventoryItem
    let viewModel: InventoryViewModel

    @State private var isEditingName = false
    @State private var editedName: String = ""
    @State private var editedQuantity: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isEditingName {
                editingRow
            } else {
                displayRow
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: Display mode

    private var displayRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                if !item.quantity.isEmpty {
                    Text(item.quantity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button {
                startEditing()
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: Editing mode

    private var editingRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Item name", text: $editedName)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .submitLabel(.next)

            TextField("Quantity (optional)", text: $editedQuantity)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
                .foregroundColor(.secondary)
                .submitLabel(.done)
                .onSubmit(commitEdit)

            HStack {
                Button("Save", action: commitEdit)
                    .font(.caption.bold())
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Cancel") {
                    isEditingName = false
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Helpers

    private func startEditing() {
        editedName = item.name
        editedQuantity = item.quantity
        isEditingName = true
    }

    private func commitEdit() {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var updated = item
        updated.name = trimmed
        updated.quantity = editedQuantity.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.editItem(updated)
        isEditingName = false
    }
}
