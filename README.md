# LunchBox Prep

An iOS app that helps you plan and prepare lunch boxes using AI-generated recipe suggestions.

## Features

- **Ingredient Scanner** — use your iPhone camera to scan food items, or add them manually
- **AI Suggestions** — get ≥ 3 lunch box recipe ideas based on your current inventory
- **Dietary Preferences** — filter by vegetarian, vegan, gluten-free, dairy-free, nut-free, and cuisine region
- **YouTube Videos** — each suggestion links to a relevant recipe video via YouTube Data API
- **Favorites** — save ideas to revisit later (persisted across launches)
- **Multi-provider AI** — switch between Gemini, OpenAI, and Claude in Settings

## Requirements

- Xcode 15+
- iOS 16+ device or simulator
- A Gemini, OpenAI, or Claude API key
- (Optional) A YouTube Data API v3 key for video suggestions

## Project Structure

```
LunchBoxPrep/          # Swift Package — all shared app logic
LunchBoxPrepXcode/     # Xcode project — iOS app host
.kiro/                 # Specs and steering
```

The Swift Package contains all models, services, stores, view models, and views. The Xcode project imports it as a local package and provides the `@main` iOS entry point.

## Getting Started

1. Clone the repo
2. Open `LunchBoxPrepXcode/LunchBoxPrepXcode.xcodeproj` in Xcode
3. Select your team under Signing & Capabilities
4. Build and run on a simulator or device
5. On first launch, complete onboarding then go to **Settings** to add your API key

## API Keys

API keys are stored securely in the iOS Keychain — never in code or UserDefaults.

| Key | Where to get it | Required |
|-----|----------------|----------|
| Gemini | [Google AI Studio](https://aistudio.google.com/app/apikey) | Yes (default provider) |
| OpenAI | [platform.openai.com](https://platform.openai.com/api-keys) | If using OpenAI |
| Claude | [console.anthropic.com](https://console.anthropic.com/) | If using Claude |
| YouTube Data API v3 | [Google Cloud Console](https://console.cloud.google.com/) | Optional (for video links) |

To add your YouTube API key, go to **Settings → YouTube API Key**.

> For YouTube: enable "YouTube Data API v3" in Google Cloud Console and set Application Restrictions to **None** (or iOS apps with your bundle ID).

## Building & Testing

```bash
# Build the Swift package
swift build --package-path LunchBoxPrep

# Run all tests
swift test --package-path LunchBoxPrep

# Run a specific test class
swift test --package-path LunchBoxPrep --filter LunchBoxPrepTests.<ClassName>
```

For iOS device/simulator builds, use Xcode with the `LunchBoxPrepXcode` scheme.

## Architecture

MVVM with a clear separation of concerns:

- **Models** — pure data types (`InventoryItem`, `LunchBoxIdea`, `DietaryPreferences`)
- **Services** — stateless networking (`AIClient`, `YouTubeService`, `KeychainService`)
- **Stores** — `@MainActor ObservableObject` state holders (single source of truth)
- **ViewModels** — view-facing state and async actions, delegate mutations to Stores
- **Views** — SwiftUI, observe ViewModels via `@StateObject` / `@ObservedObject`
- **AppRoot** — composition root; wires all stores and services together

## Persistence

| Data | Mechanism |
|------|-----------|
| Inventory | In-memory only (cleared on relaunch) |
| Favorites | `Documents/favorites.json` |
| Dietary preferences | `UserDefaults` |
| API keys | Keychain |
| AI provider/model | `UserDefaults` |

## Dependencies

- [SwiftCheck](https://github.com/typelift/SwiftCheck) 0.12.0 — property-based testing (test target only)
- No other third-party dependencies; all networking uses `URLSession`

## License

MIT
