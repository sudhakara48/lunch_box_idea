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
        let youtube = YouTubeService(keychainService: keychain)

        self.keychainService = keychain
        self.aiClient = client
        self.suggestionEngine = SuggestionEngine(aiClient: client)
        self.youtubeService = youtube
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
        ScannerTabView(
            inventoryStore: inventoryStore,
            preferencesStore: preferencesStore,
            favoritesStore: favoritesStore,
            suggestionEngine: suggestionEngine,
            youtubeService: youtubeService
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

// MARK: - ScannerTabView

/// Owns `ScannerViewModel` as a `@StateObject` so it survives tab switches
/// and body re-evaluations, keeping the camera session alive.
private struct ScannerTabView: View {

    let inventoryStore: InventoryStore
    let preferencesStore: PreferencesStore
    let favoritesStore: FavoritesStore
    let suggestionEngine: SuggestionEngineProtocol
    let youtubeService: YouTubeServiceProtocol

    @StateObject private var scannerViewModel: ScannerViewModel

    init(
        inventoryStore: InventoryStore,
        preferencesStore: PreferencesStore,
        favoritesStore: FavoritesStore,
        suggestionEngine: SuggestionEngineProtocol,
        youtubeService: YouTubeServiceProtocol
    ) {
        self.inventoryStore = inventoryStore
        self.preferencesStore = preferencesStore
        self.favoritesStore = favoritesStore
        self.suggestionEngine = suggestionEngine
        self.youtubeService = youtubeService
        _scannerViewModel = StateObject(wrappedValue: ScannerViewModel(inventoryStore: inventoryStore))
    }

    var body: some View {
        NavigationStack {
            ScannerView(viewModel: scannerViewModel)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        NavigationLink("Inventory") {
                            InventoryViewWithSuggestions(
                                inventoryStore: inventoryStore,
                                preferencesStore: preferencesStore,
                                favoritesStore: favoritesStore,
                                suggestionEngine: suggestionEngine,
                                youtubeService: youtubeService
                            )
                        }
                    }
                }
                .navigationTitle("Scanner")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }
}

// MARK: - InventoryViewWithSuggestions

/// Wraps `InventoryView` and owns the `SuggestionsViewModel` as a `@StateObject`
/// so it survives navigation pushes/pops and retains cached ideas + YouTube service.
private struct InventoryViewWithSuggestions: View {

    let inventoryStore: InventoryStore
    let preferencesStore: PreferencesStore
    let favoritesStore: FavoritesStore
    let suggestionEngine: SuggestionEngineProtocol
    let youtubeService: YouTubeServiceProtocol

    @StateObject private var suggestionsViewModel: SuggestionsViewModel
    @StateObject private var inventoryViewModel: InventoryViewModel

    @State private var showSuggestions = false

    init(
        inventoryStore: InventoryStore,
        preferencesStore: PreferencesStore,
        favoritesStore: FavoritesStore,
        suggestionEngine: SuggestionEngineProtocol,
        youtubeService: YouTubeServiceProtocol
    ) {
        self.inventoryStore = inventoryStore
        self.preferencesStore = preferencesStore
        self.favoritesStore = favoritesStore
        self.suggestionEngine = suggestionEngine
        self.youtubeService = youtubeService

        _suggestionsViewModel = StateObject(wrappedValue: SuggestionsViewModel(
            suggestionEngine: suggestionEngine,
            inventoryStore: inventoryStore,
            preferencesStore: preferencesStore,
            youtubeService: youtubeService
        ))
        _inventoryViewModel = StateObject(wrappedValue: InventoryViewModel(
            inventoryStore: inventoryStore
        ))
    }

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
