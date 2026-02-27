import SwiftUI

#if os(iOS)
import UIKit
#endif

// MARK: - DetailView

/// Displays the full detail of a `LunchBoxIdea`: name, ingredients, and preparation steps.
///
/// - Share button: invokes the iOS share sheet (or `ShareLink` on macOS) with the idea
///   formatted as plain text via `LunchBoxIdeaShareFormatter`.
/// - Save button: persists the idea to `FavoritesStore` and shows a brief checkmark overlay.
///
/// - Requirements: 7.1, 7.2, 7.3, 7.4
public struct DetailView: View {

    public let idea: LunchBoxIdea
    private let favoritesStore: FavoritesStore

    @State private var isSaved: Bool = false
    @State private var showSavedConfirmation: Bool = false
    @State private var showShareSheet: Bool = false

    private let formatter = LunchBoxIdeaShareFormatter()

    public init(idea: LunchBoxIdea, favoritesStore: FavoritesStore) {
        self.idea = idea
        self.favoritesStore = favoritesStore
        // Pre-populate isSaved based on whether this idea is already in favorites.
        _isSaved = State(initialValue: favoritesStore.favorites.contains { $0.id == idea.id })
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Name
                Text(idea.name)
                    .font(.largeTitle.bold())
                    .padding(.horizontal)

                // Ingredients
                sectionView(title: "Ingredients", systemImage: "list.bullet") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(idea.ingredients, id: \.self) { ingredient in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.green)
                                    .padding(.top, 6)
                                Text(ingredient)
                                    .font(.body)
                            }
                        }
                    }
                }

                // Preparation steps
                sectionView(title: "Preparation", systemImage: "fork.knife") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(idea.preparationSteps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.green)
                                    .clipShape(Circle())
                                Text(step)
                                    .font(.body)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .overlay(savedConfirmationOverlay)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                shareButton
                saveButton
            }
        }
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(text: formatter.format(idea))
        }
#endif
    }

    // MARK: - Section helper

    private func sectionView<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.title3.bold())
                .padding(.horizontal)
            content()
                .padding(.horizontal)
        }
    }

    // MARK: - Share button

    @ViewBuilder
    private var shareButton: some View {
#if os(iOS)
        Button {
            showShareSheet = true
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
#else
        ShareLink(item: formatter.format(idea)) {
            Image(systemName: "square.and.arrow.up")
        }
#endif
    }

    // MARK: - Save button

    private var saveButton: some View {
        Button {
            saveIdea()
        } label: {
            Image(systemName: isSaved ? "heart.fill" : "heart")
                .foregroundColor(isSaved ? .red : .primary)
        }
    }

    // MARK: - Saved confirmation overlay

    @ViewBuilder
    private var savedConfirmationOverlay: some View {
        if showSavedConfirmation {
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("Saved to Favorites")
                        .font(.subheadline.bold())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.regularMaterial)
                .cornerRadius(20)
                .shadow(radius: 6)
                .padding(.bottom, 32)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showSavedConfirmation)
        }
    }

    // MARK: - Actions

    private func saveIdea() {
        try? favoritesStore.save(idea)
        isSaved = true
        withAnimation {
            showSavedConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSavedConfirmation = false
            }
        }
    }
}

// MARK: - ShareSheetView (iOS only)

#if os(iOS)
private struct ShareSheetView: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
