import SwiftUI

// MARK: - AppRoot

/// Root view of the LunchBox Prep app.
///
/// This view is the entry point for the SwiftUI view hierarchy. It:
/// - Instantiates all stores and services as `@StateObject` / local properties
/// - Handles first-launch onboarding via `@AppStorage("hasSeenOnboarding")`
/// - Shows `OnboardingView` on first launch, then the main `TabView`
///
/// NOTE: Because this is a Swift Package library target, `@main` cannot be used here.
/// Host apps should set `AppRoot()` as their root view.
///
/// Requirements: 1.1, 1.2, 1.3
public struct AppRoot: View {

    // MARK: - First-launch tracking

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    // MARK: - Stores (shared observable state)

    @StateObject private var inventoryStore = InventoryStore()
    @StateObject private var preferencesStore = PreferencesStore()
    @StateObject private var favoritesStore = FavoritesStore()

    // MARK: - Services (value-type config + reference-type clients)

    private let keychainService: KeychainService
    private let aiClient: AIClient
    private let suggestionEngine: SuggestionEngine
    private let youtubeService: YouTubeService

    // MARK: - Init

    public init() {
        let keychain = KeychainService()
        let baseURLString = UserDefaults.standard.string(forKey: "baseURL")
            ?? LunchBoxPrepApp.defaultBaseURL
        let model = UserDefaults.standard.string(forKey: "aiModelID")
            ?? UserDefaults.standard.string(forKey: "aiModel")
            ?? LunchBoxPrepApp.defaultModel
        let baseURL = URL(string: baseURLString)
            ?? URL(string: LunchBoxPrepApp.defaultBaseURL)!

        let config = AIClientConfig(baseURL: baseURL, model: model)
        let client = AIClient(keychainService: keychain, config: config)

        self.keychainService = keychain
        self.aiClient = client
        self.suggestionEngine = SuggestionEngine(aiClient: client)
        self.youtubeService = YouTubeService(keychainService: keychain)
    }

    // MARK: - Body

    public var body: some View {
        if hasSeenOnboarding {
            mainTabView
        } else {
            OnboardingView {
                hasSeenOnboarding = true
            }
        }
    }

    // MARK: - Main Tab View

    private var mainTabView: some View {
        TabView {
            scannerTab
                .tabItem {
                    Label("Scanner", systemImage: "camera.viewfinder")
                }

            favoritesTab
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }

            settingsTab
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
#if os(iOS)
        .tint(.green)
#endif
    }

    // MARK: - Scanner Tab

    /// Scanner → Inventory → Suggestions navigation stack.
    private var scannerTab: some View {
        NavigationStack {
            ScannerView(
                viewModel: ScannerViewModel(inventoryStore: inventoryStore)
            )
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    NavigationLink("Inventory") {
                        inventoryDestination
                    }
                }
            }
            .navigationTitle("Scanner")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }

    /// Inventory screen with a "Get Ideas" button that pushes SuggestionsView.
    private var inventoryDestination: some View {
        let inventoryVM = InventoryViewModel(inventoryStore: inventoryStore)
        let suggestionsVM = SuggestionsViewModel(
            suggestionEngine: suggestionEngine,
            inventoryStore: inventoryStore,
            preferencesStore: preferencesStore,
            youtubeService: youtubeService
        )
        return InventoryViewWithSuggestions(
            inventoryViewModel: inventoryVM,
            suggestionsViewModel: suggestionsVM,
            favoritesStore: favoritesStore
        )
    }

    // MARK: - Favorites Tab

    private var favoritesTab: some View {
        FavoritesView(
            viewModel: FavoritesViewModel(favoritesStore: favoritesStore),
            favoritesStore: favoritesStore
        )
        .onAppear {
            try? favoritesStore.load()
        }
    }

    // MARK: - Settings Tab

    private var settingsTab: some View {
        SettingsView()
    }
}

// MARK: - InventoryViewWithSuggestions

/// Wraps `InventoryView` and provides a `NavigationLink` destination to
/// `SuggestionsView` when the user taps "Get Lunch Box Ideas".
private struct InventoryViewWithSuggestions: View {

    let inventoryViewModel: InventoryViewModel
    let suggestionsViewModel: SuggestionsViewModel
    let favoritesStore: FavoritesStore

    @State private var showSuggestions = false

    var body: some View {
        InventoryView(viewModel: inventoryViewModel) {
            showSuggestions = true
        }
        .navigationDestination(isPresented: $showSuggestions) {
            SuggestionsView(
                viewModel: suggestionsViewModel,
                favoritesStore: favoritesStore
            )
        }
    }
}
