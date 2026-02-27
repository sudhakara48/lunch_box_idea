# Project Structure

## Top-Level Layout

```
LunchBoxPrep/          # Swift Package — all shared app logic
LunchBoxPrepXcode/     # Xcode project — iOS app host (imports LunchBoxPrep)
.kiro/                 # Kiro specs and steering
```

## Swift Package (`LunchBoxPrep/`)

```
Sources/
  LunchBoxPrep/        # Library target — all reusable app code
    Models/            # Pure data types and error enums (no dependencies)
    Services/          # Networking, Keychain, AI prompt formatting
    Stores/            # @MainActor ObservableObject state holders
    ViewModels/        # @MainActor ObservableObject view-facing state + actions
    Views/             # SwiftUI views
    AppRoot.swift      # Root SwiftUI view; wires stores/services together
    LunchBoxPrepApp.swift  # App-wide constants (no @main)
  LunchBoxPrepApp/     # Executable target — macOS entry point (main.swift)
Tests/
  LunchBoxPrepTests/   # XCTest + SwiftCheck property-based tests
```

## Xcode Project (`LunchBoxPrepXcode/`)

```
LunchBoxPrepXcode/
  LunchBoxPrepXcodeApp.swift  # @main iOS entry point — sets AppRoot() as root view
  Assets.xcassets
  Info.plist
```

## Architecture Patterns

- MVVM: Views observe ViewModels (`@StateObject` / `@ObservedObject`); ViewModels delegate mutations to Stores
- Stores are the single source of truth for shared mutable state; injected into ViewModels at construction
- Services are stateless or config-only; injected via protocol for testability (`AIClientProtocol`, `KeychainServiceProtocol`, `URLSessionProtocol`)
- `AppRoot` is the composition root — it instantiates all stores and services and passes them down
- `@MainActor` on all Stores and ViewModels; async work in ViewModels via `async/await`

## Persistence Strategy

| Data | Mechanism |
|---|---|
| Inventory | In-memory only (`InventoryStore`) |
| Favorites | JSON file at `Documents/favorites.json` (`FavoritesStore`) |
| Dietary preferences | `UserDefaults` via JSON encoding (`PreferencesStore`) |
| API key | Keychain (`KeychainService`) |
| AI provider/model | `UserDefaults` keys `baseURL`, `aiModelID` |

## Naming Conventions

- Files and types follow the layer they belong to: `*Store`, `*ViewModel`, `*View`, `*Service`, `*Client`
- Protocols named with the concrete type + `Protocol` suffix (e.g. `AIClientProtocol`)
- Error enums suffixed with `Error` (e.g. `AIClientError`, `KeychainError`)
- Requirement references in doc comments use `/// - Requirements: X.Y` format
