# Tech Stack

## Language & Platforms
- Swift 5.9+
- iOS 16+ (primary target), macOS 13+ (CI/build compatibility)
- SwiftUI for all UI

## Project Structure
Two separate build targets share the same source library:
- `LunchBoxPrep/` — Swift Package (library + test target)
- `LunchBoxPrepXcode/` — Xcode project that imports `LunchBoxPrep` as a local package and provides the `@main` iOS app entry point

## Dependencies
- `SwiftCheck` 0.12.0 — property-based testing (test target only)
- No other third-party dependencies; all networking uses `URLSession`

## AI Integration
- Default provider: Gemini (`generativelanguage.googleapis.com/v1beta`)
- Also supports OpenAI and Claude (configurable at runtime)
- API key stored in Keychain via `KeychainService`
- Responses must be JSON; `AIClient` handles Gemini envelope unwrapping and fallback decoding

## Common Commands

```bash
# Build the Swift package
swift build --package-path LunchBoxPrep

# Run tests
swift test --package-path LunchBoxPrep

# Run a single test class
swift test --package-path LunchBoxPrep --filter LunchBoxPrepTests.<ClassName>
```

For iOS device/simulator builds, open `LunchBoxPrepXcode/LunchBoxPrepXcode.xcodeproj` in Xcode and build the `LunchBoxPrepXcode` scheme.

## Logging
Uses `OSLog` with subsystem `com.sudhakara.lunchboxprep`. Category per file (e.g. `AIClient`).
