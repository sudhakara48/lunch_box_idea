import SwiftUI

// MARK: - SuggestionsView

/// Displays AI-generated lunch box suggestions.
///
/// - Shows a loading indicator while the request is in progress.
/// - Shows a list of `LunchBoxIdea` cards when ideas are available.
/// - Shows an error alert with a retry action for non-network errors.
/// - Shows an offline banner (no retry) when the error is `.networkUnavailable`.
///
/// - Requirements: 5.3, 5.5, 5.6, 5.7
public struct SuggestionsView: View {

    @ObservedObject public var viewModel: SuggestionsViewModel
    private let favoritesStore: FavoritesStore

    public init(viewModel: SuggestionsViewModel, favoritesStore: FavoritesStore) {
        self.viewModel = viewModel
        self.favoritesStore = favoritesStore
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                content
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("Lunch Box Ideas")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
            .task {
                guard viewModel.ideas.isEmpty else {
                    // Ideas cached — try to fetch videos if not yet loaded
                    if viewModel.ideas.allSatisfy({ $0.youtubeVideoID == nil }) {
                        await viewModel.fetchVideos()
                    }
                    return
                }
                await viewModel.fetchSuggestions()
            }
            .toolbar {
#if os(iOS)
                if !viewModel.ideas.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if viewModel.isFetchingVideos {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Button {
                                Task { await viewModel.fetchVideos() }
                            } label: {
                                Label("Load Videos", systemImage: "play.rectangle.fill")
                            }
                        }
                    }
                }
#endif
            }
            .alert(
                "Something Went Wrong",
                isPresented: errorAlertBinding,
                presenting: nonNetworkError
            ) { _ in
                Button("Retry") {
                    Task { await viewModel.fetchSuggestions() }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.errorState = nil
                }
            } message: { error in
                Text(error.userMessage)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.errorState == .networkUnavailable {
            offlineBanner
        } else if viewModel.ideas.isEmpty && !viewModel.isLoading {
            emptyState
        } else {
            ideaList
        }
    }

    private var ideaList: some View {
        List {
            if let status = viewModel.youtubeStatusMessage {
                Section {
                    Label(status, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            ForEach(viewModel.ideas) { idea in
                NavigationLink {
                    DetailView(idea: idea, favoritesStore: favoritesStore)
                } label: {
                    IdeaCard(idea: idea)
                }
            }
        }
        .listStyle(.inset)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            Text("No ideas yet")
                .font(.headline)
            Text("Tap retry to fetch lunch box suggestions.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Retry") {
                Task { await viewModel.fetchSuggestions() }
            }
            .font(.headline)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loading overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.primary.colorInvert().opacity(0.7)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.4)
                Text("Finding ideas…")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Offline banner

    private var offlineBanner: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "wifi.slash")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("You're Offline")
                        .font(.headline)
                    Text("Please check your connection and try again.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color.orange.opacity(0.15))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.orange.opacity(0.4)),
                alignment: .bottom
            )
            Button("Retry") {
                Task { await viewModel.fetchSuggestions() }
            }
            .padding(.top, 24)
            Spacer()
        }
    }

    // MARK: - Alert helpers

    /// Binding that is `true` when there is a non-network error to show.
    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: {
                if let error = viewModel.errorState {
                    return error != .networkUnavailable
                }
                return false
            },
            set: { isPresented in
                if !isPresented { viewModel.errorState = nil }
            }
        )
    }

    /// The current error if it is not a network error.
    private var nonNetworkError: AppError? {
        guard let error = viewModel.errorState, error != .networkUnavailable else { return nil }
        return error
    }
}

// MARK: - IdeaCard

private struct IdeaCard: View {
    let idea: LunchBoxIdea
    @State private var showVideo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(idea.name)
                .font(.headline)
                .lineLimit(2)
            if let firstIngredient = idea.ingredients.first {
                Text(firstIngredient + (idea.ingredients.count > 1 ? " +\(idea.ingredients.count - 1) more" : ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
#if os(iOS)
            if let videoID = idea.youtubeVideoID {
                YouTubeThumbnailButton(videoID: videoID) {
                    showVideo = true
                }
            }
#endif
        }
        .padding(.vertical, 4)
#if os(iOS)
        .sheet(isPresented: $showVideo) {
            if let videoID = idea.youtubeVideoID {
                YouTubePlayerSheet(videoID: videoID)
            }
        }
#endif
    }
}

#if os(iOS)
// MARK: - YouTubeThumbnailButton

private struct YouTubeThumbnailButton: View {
    let videoID: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(videoID)/mqdefault.jpg")) { image in
                    image.resizable().aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.black.opacity(0.8))
                        .aspectRatio(16/9, contentMode: .fill)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white, .red)
                    .shadow(radius: 4)
            }
        }
        .buttonStyle(.plain)
    }
}
#endif
