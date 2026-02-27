import SwiftUI

// MARK: - SettingsView

public struct SettingsView: View {

    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var preferencesStore = PreferencesStore()
    @State private var showPrivacyNotice = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                // Dietary & Cuisine
                Section {
                    NavigationLink {
                        PreferencesView(store: preferencesStore)
                    } label: {
                        Label("Dietary & Cuisine Preferences", systemImage: "fork.knife")
                    }
                }

                // AI Provider (sub-screen)
                Section {
                    NavigationLink {
                        AIProviderView(viewModel: viewModel)
                    } label: {
                        HStack {
                            Label("AI Provider", systemImage: "cpu")
                            Spacer()
                            Text(viewModel.selectedProvider.rawValue)
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                }

                // YouTube API Key (sub-screen)
                Section {
                    NavigationLink {
                        YouTubeAPIKeyView(viewModel: viewModel)
                    } label: {
                        HStack {
                            Label("YouTube API Key", systemImage: "play.rectangle")
                            Spacer()
                            Text(viewModel.savedYouTubeAPIKey != nil ? "Saved" : "Not set")
                                .foregroundColor(viewModel.savedYouTubeAPIKey != nil ? .green : .secondary)
                                .font(.subheadline)
                        }
                    }
                }

                // Privacy
                Section {
                    Button("Privacy Notice") { showPrivacyNotice = true }
                }
            }
            .navigationTitle("Settings")
            .onAppear { viewModel.loadAPIKey() }
            .sheet(isPresented: $showPrivacyNotice) {
                PrivacyNoticeView()
            }
        }
    }
}

// MARK: - AIProviderView

public struct AIProviderView: View {

    @ObservedObject public var viewModel: SettingsViewModel
    @State private var showModelPicker = false
    @State private var showAdvanced = false

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            providerCardsSection
            modelSection
            apiKeySection
            advancedSection
        }
        .navigationTitle("AI Provider")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }

    // MARK: - Provider cards

    private var providerCardsSection: some View {
        Section {
            ForEach(AIProvider.allCases) { provider in
                ProviderCard(
                    provider: provider,
                    isSelected: viewModel.selectedProvider == provider
                ) {
                    viewModel.selectedProvider = provider
                }
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        } header: {
            Text("Provider")
        } footer: {
            Text("Your API key is stored per provider in the Keychain.")
                .font(.caption)
        }
    }

    // MARK: - Model

    private var modelSection: some View {
        Section("Model") {
            Picker(selection: $viewModel.selectedModel) {
                ForEach(viewModel.selectedProvider.models) { model in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.name)
                        Text(model.note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(model)
                }
            } label: {
                HStack {
                    Text(viewModel.selectedModel.name)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(viewModel.selectedModel.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .pickerStyle(.menu)
        }
    }

    // MARK: - API Key

    private var apiKeySection: some View {
        Section {
            if let saved = viewModel.savedAPIKey {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Saved key")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(maskedKey(saved))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            SecureField("Enter \(viewModel.selectedProvider.rawValue) API key", text: $viewModel.apiKeyInput)
                .textContentType(.password)
                .autocorrectionDisabled()
#if os(iOS)
                .textInputAutocapitalization(.never)
#endif
            if let error = viewModel.validationError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            HStack(spacing: 12) {
                Button("Save") { viewModel.saveAPIKey(viewModel.apiKeyInput) }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.apiKeyInput.isEmpty)
                if viewModel.savedAPIKey != nil {
                    Button("Delete", role: .destructive) { viewModel.deleteAPIKey() }
                }
            }
        } header: {
            Text("API Key")
        } footer: {
            Text(apiKeyFooter)
                .font(.caption)
        }
    }

    private var apiKeyFooter: String {
        switch viewModel.selectedProvider {
        case .gemini: return "Get a free key at aistudio.google.com"
        case .openAI: return "Get a key at platform.openai.com"
        case .claude: return "Get a key at console.anthropic.com"
        }
    }

    // MARK: - Advanced (collapsible)

    private var advancedSection: some View {
        Section {
            Button {
                withAnimation { showAdvanced.toggle() }
            } label: {
                HStack {
                    Text("Advanced")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if showAdvanced {
                LabeledContent("Base URL") {
                    TextField(viewModel.selectedProvider.baseURL, text: $viewModel.baseURL)
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                        .font(.caption)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
#endif
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        } footer: {
            if showAdvanced {
                Text("Override only if using a custom proxy endpoint.")
                    .font(.caption)
            }
        }
    }

    private func maskedKey(_ key: String) -> String {
        guard key.count > 8 else { return String(repeating: "•", count: key.count) }
        return "\(key.prefix(4))••••\(key.suffix(4))"
    }
}

// MARK: - ProviderCard

private struct ProviderCard: View {
    let provider: AIProvider
    let isSelected: Bool
    let onTap: () -> Void

    private var icon: String {
        switch provider {
        case .gemini: return "sparkles"
        case .openAI: return "brain"
        case .claude: return "text.bubble"
        }
    }

    private var accentColor: Color {
        switch provider {
        case .gemini: return .blue
        case .openAI: return .green
        case .claude: return .orange
        }
    }

    private var subtitle: String {
        switch provider {
        case .gemini: return "Google · aistudio.google.com"
        case .openAI: return "OpenAI · platform.openai.com"
        case .claude: return "Anthropic · console.anthropic.com"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentColor.opacity(isSelected ? 0.15 : 0.08))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(provider.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accentColor)
                        .font(.title3)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary.opacity(0.4))
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - YouTubeAPIKeyView

public struct YouTubeAPIKeyView: View {

    @ObservedObject public var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            Section {
                if let saved = viewModel.savedYouTubeAPIKey {
                    HStack {
                        Text("Saved key")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(maskedKey(saved))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                SecureField("Enter YouTube Data API key", text: $viewModel.youtubeAPIKeyInput)
                    .textContentType(.password)
                    .autocorrectionDisabled()
#if os(iOS)
                    .textInputAutocapitalization(.never)
#endif
                HStack(spacing: 12) {
                    Button("Save") { viewModel.saveYouTubeAPIKey(viewModel.youtubeAPIKeyInput) }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.youtubeAPIKeyInput.isEmpty)
                    if viewModel.savedYouTubeAPIKey != nil {
                        Button("Delete", role: .destructive) { viewModel.deleteYouTubeAPIKey() }
                    }
                }
            } header: {
                Text("YouTube API Key")
            } footer: {
                Text("Used to show recipe videos on suggestion cards.\nGet a free key at console.cloud.google.com → YouTube Data API v3.")
                    .font(.caption)
            }
        }
        .navigationTitle("YouTube API Key")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }

    private func maskedKey(_ key: String) -> String {
        guard key.count > 8 else { return String(repeating: "•", count: key.count) }
        return "\(key.prefix(4))••••\(key.suffix(4))"
    }
}

// MARK: - Privacy Notice

private struct PrivacyNoticeView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text("""
                LunchBox Prep does not collect or transmit any personal data. \
                Your API key is stored securely in the iOS Keychain. \
                Your food inventory and preferences stay on your device. \
                Only your inventory data is sent to the AI endpoint you configure.
                """)
                .padding()
            }
            .navigationTitle("Privacy Notice")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
