import Foundation
import Combine

@MainActor
public final class SettingsViewModel: ObservableObject {

    // MARK: - Published State

    @Published public var apiKeyInput: String = ""
    @Published public var validationError: String? = nil
    @Published public var savedAPIKey: String? = nil
    @Published public var youtubeAPIKeyInput: String = ""
    @Published public var savedYouTubeAPIKey: String? = nil

    /// Currently selected provider — drives baseURL and available models.
    @Published public var selectedProvider: AIProvider {
        didSet {
            UserDefaults.standard.set(selectedProvider.rawValue, forKey: Keys.provider)
            // Switch to the provider's default model when provider changes.
            selectedModel = selectedProvider.defaultModel
            baseURL = selectedProvider.baseURL
            loadAPIKey()
        }
    }

    /// Currently selected model for the active provider.
    @Published public var selectedModel: AIModel {
        didSet {
            UserDefaults.standard.set(selectedModel.id, forKey: Keys.model)
            UserDefaults.standard.set(selectedModel.id, forKey: Keys.legacyModel)
        }
    }

    /// Base URL — auto-set when provider changes, but still user-editable.
    @Published public var baseURL: String {
        didSet { UserDefaults.standard.set(baseURL, forKey: Keys.baseURL) }
    }

    // MARK: - Dependencies

    private let keychainService: KeychainServiceProtocol

    // MARK: - Keys

    private enum Keys {
        static let provider    = "aiProvider"
        static let model       = "aiModelID"
        static let baseURL     = "baseURL"
        static let legacyModel = "aiModel"   // kept for AppRoot compatibility
    }

    // MARK: - Init

    public init(keychainService: KeychainServiceProtocol = KeychainService()) {
        self.keychainService = keychainService

        // Restore provider
        let providerRaw = UserDefaults.standard.string(forKey: Keys.provider) ?? AIProvider.gemini.rawValue
        let provider = AIProvider(rawValue: providerRaw) ?? .gemini
        self.selectedProvider = provider

        // Restore base URL
        self.baseURL = UserDefaults.standard.string(forKey: Keys.baseURL) ?? provider.baseURL

        // Restore model — fall back to provider default
        let savedModelID = UserDefaults.standard.string(forKey: Keys.model)
        self.selectedModel = provider.models.first { $0.id == savedModelID } ?? provider.defaultModel
    }

    // MARK: - API Key Management

    public func saveAPIKey(_ key: String) {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationError = "API key cannot be empty."
            return
        }
        do {
            try keychainService.save(apiKey: key)
            validationError = nil
            savedAPIKey = key
            apiKeyInput = ""
        } catch {
            validationError = error.localizedDescription
        }
    }

    public func deleteAPIKey() {
        do {
            try keychainService.deleteAPIKey()
            savedAPIKey = nil
            validationError = nil
        } catch {
            validationError = error.localizedDescription
        }
    }

    public func loadAPIKey() {
        do {
            savedAPIKey = try keychainService.loadAPIKey()
        } catch KeychainError.itemNotFound {
            savedAPIKey = nil
        } catch {
            validationError = error.localizedDescription
        }
        do {
            savedYouTubeAPIKey = try keychainService.loadAPIKey(account: YouTubeService.keychainAccount)
        } catch KeychainError.itemNotFound {
            savedYouTubeAPIKey = nil
        } catch {}
    }

    public func saveYouTubeAPIKey(_ key: String) {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        try? keychainService.save(apiKey: key, account: YouTubeService.keychainAccount)
        savedYouTubeAPIKey = key
        youtubeAPIKeyInput = ""
    }

    public func deleteYouTubeAPIKey() {
        try? keychainService.deleteAPIKey(account: YouTubeService.keychainAccount)
        savedYouTubeAPIKey = nil
    }
}
