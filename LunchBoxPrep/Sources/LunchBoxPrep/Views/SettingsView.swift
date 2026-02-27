import SwiftUI

public struct SettingsView: View {

    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var preferencesStore = PreferencesStore()
    @State private var showPrivacyNotice = false

    public init() {}

    public var body: some View {
        NavigationView {
            Form {
                preferencesLinkSection
                providerSection
                modelSection
                apiKeySection
                youtubeAPIKeySection
                advancedSection
                privacySection
            }
            .navigationTitle("Settings")
            .onAppear { viewModel.loadAPIKey() }
            .sheet(isPresented: $showPrivacyNotice) {
                PrivacyNoticeView()
            }
        }
    }

    // MARK: - Preferences link

    private var preferencesLinkSection: some View {
        Section {
            NavigationLink {
                PreferencesView(store: preferencesStore)
            } label: {
                Label("Dietary & Cuisine Preferences", systemImage: "fork.knife")
            }
        }
    }

    // MARK: - Provider picker

    private var providerSection: some View {
        Section {
            Picker("Provider", selection: $viewModel.selectedProvider) {
                ForEach(AIProvider.allCases) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("AI Provider")
        } footer: {
            Text(providerFooter)
                .font(.caption)
        }
    }

    private var providerFooter: String {
        switch viewModel.selectedProvider {
        case .gemini:  return "Get a free API key at aistudio.google.com"
        case .openAI:  return "Get an API key at platform.openai.com"
        case .claude:  return "Get an API key at console.anthropic.com"
        }
    }

    // MARK: - Model list

    private var modelSection: some View {
        Section("Model") {
            ForEach(viewModel.selectedProvider.models) { model in
                Button {
                    viewModel.selectedModel = model
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.name)
                                .foregroundColor(.primary)
                            Text(model.note)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if viewModel.selectedModel == model {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
    }

    // MARK: - AI API Key

    private var apiKeySection: some View {
        Section {
            if let saved = viewModel.savedAPIKey {
                HStack {
                    Text("Saved key")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(maskedKey(saved))
                        .font(.system(.body, design: .monospaced))
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
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            HStack(spacing: 12) {
                Button("Save") {
                    viewModel.saveAPIKey(viewModel.apiKeyInput)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.apiKeyInput.isEmpty)

                if viewModel.savedAPIKey != nil {
                    Button("Delete", role: .destructive) {
                        viewModel.deleteAPIKey()
                    }
                }
            }
        } header: {
            Text("API Key")
        } footer: {
            Text("Your API key is stored securely in the iOS Keychain.")
                .font(.caption)
        }
    }

    // MARK: - YouTube API Key

    private var youtubeAPIKeySection: some View {
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
                Button("Save") {
                    viewModel.saveYouTubeAPIKey(viewModel.youtubeAPIKeyInput)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.youtubeAPIKeyInput.isEmpty)

                if viewModel.savedYouTubeAPIKey != nil {
                    Button("Delete", role: .destructive) {
                        viewModel.deleteYouTubeAPIKey()
                    }
                }
            }
        } header: {
            Text("YouTube API Key")
        } footer: {
            Text("Used to show recipe videos. Get a free key at console.cloud.google.com → YouTube Data API v3.")
                .font(.caption)
        }
    }

    // MARK: - Advanced (base URL override)

    private var advancedSection: some View {
        Section {
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
        } header: {
            Text("Advanced")
        } footer: {
            Text("Override only if using a custom proxy endpoint.")
                .font(.caption)
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        Section("Privacy") {
            Button("Privacy Notice") {
                showPrivacyNotice = true
            }
        }
    }

    // MARK: - Helpers

    private func maskedKey(_ key: String) -> String {
        guard key.count > 8 else { return String(repeating: "•", count: key.count) }
        return "\(key.prefix(4))••••\(key.suffix(4))"
    }
}

// MARK: - Privacy Notice

private struct PrivacyNoticeView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
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
