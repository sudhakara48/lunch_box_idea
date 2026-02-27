# Implementation Plan: LunchBox Prep iOS

## Overview

Incremental SwiftUI + Combine implementation following the MVVM architecture defined in the design. Tasks build from the data layer upward through domain services, ViewModels, and finally UI screens, wiring everything together at the end.

## Tasks

- [x] 1. Set up Xcode project structure and core data models
  - Create a new SwiftUI iOS 16+ Xcode project named `LunchBoxPrep`
  - Add `SwiftCheck` via Swift Package Manager for property-based testing
  - Define all data model types in `Models/`: `InventoryItem`, `DetectedItem`, `LunchBoxIdea`, `DietaryPreferences`, `ChatCompletionRequest`, `ChatMessage`, `ResponseFormat`
  - Define `AIClientError` and `KeychainError` enums with `LocalizedError` conformance
  - _Requirements: 1.1, 5.4_

- [x] 2. Implement KeychainService
  - [x] 2.1 Implement `KeychainService` conforming to `KeychainServiceProtocol`
    - Use `Security.framework` `SecItem` APIs (`SecItemAdd`, `SecItemCopyMatching`, `SecItemDelete`)
    - Never touch `UserDefaults` for the API key
    - _Requirements: 2.2_

  - [x] 2.2 Write property test for API key Keychain round-trip
    - **Property 1: API key Keychain round-trip**
    - **Validates: Requirements 2.2**

  - [ ]* 2.3 Write unit tests for KeychainService
    - Test `itemNotFound` error when no key is saved
    - Test `duplicateItem` handling on repeated saves
    - _Requirements: 2.2_

- [x] 3. Implement InventoryStore
  - [x] 3.1 Implement `InventoryStore` as an `@MainActor ObservableObject`
    - Implement `add(_:)`, `update(_:)`, `remove(id:)`, `clear()`
    - Inventory is in-memory only — no persistence
    - _Requirements: 3.7, 4.1, 4.2, 4.3, 4.4_

  - [ ]* 3.2 Write property test for inventory update correctness
    - **Property 7: Inventory item update is reflected immediately**
    - **Validates: Requirements 4.2**

  - [ ]* 3.3 Write property test for inventory removal
    - **Property 8: Inventory item removal**
    - **Validates: Requirements 4.3**

  - [ ]* 3.4 Write property test for inventory clear
    - **Property 9: Clear empties the inventory**
    - **Validates: Requirements 4.4**

- [x] 4. Implement PreferencesStore
  - [x] 4.1 Implement `PreferencesStore` persisting `DietaryPreferences` to `UserDefaults` via JSON encoding
    - Implement `save()` and `reset()`
    - Load persisted value on init
    - _Requirements: 6.1, 6.3, 6.4_

  - [ ]* 4.2 Write property test for dietary preferences persistence round-trip
    - **Property 16: Dietary preferences round-trip through persistence**
    - **Validates: Requirements 6.3**

- [x] 5. Implement FavoritesStore
  - [x] 5.1 Implement `FavoritesStore` persisting `[LunchBoxIdea]` to `Documents/favorites.json`
    - Implement `save(_:)`, `delete(id:)`, `load()`
    - Maintain reverse-chronological order by `savedAt`
    - On decode failure: log error and present empty list without deleting the raw file
    - _Requirements: 7.3, 8.1, 8.3, 8.4_

  - [ ]* 5.2 Write property test for save to favorites round-trip
    - **Property 19: Save to favorites round-trip**
    - **Validates: Requirements 7.3**

  - [ ]* 5.3 Write property test for favorites reverse-chronological ordering
    - **Property 20: Favorites are in reverse chronological order**
    - **Validates: Requirements 8.1**

  - [ ]* 5.4 Write property test for favorites deletion
    - **Property 21: Favorites deletion**
    - **Validates: Requirements 8.3**

  - [ ]* 5.5 Write property test for favorites serialization round-trip
    - **Property 22: Favorites persist across store reloads**
    - **Validates: Requirements 8.4**

- [x] 6. Checkpoint — Ensure all store and service tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Implement AIClient
  - [x] 7.1 Implement `AIClient` conforming to `AIClientProtocol`
    - Use `URLSession` with `async/await`; no third-party networking
    - Load API key from `KeychainService`; throw `AIClientError.missingAPIKey` if absent
    - Check network reachability before making the request; throw `AIClientError.networkUnavailable` if offline
    - Send `POST /chat/completions` with `responseFormat: { type: "json_object" }`
    - Map 4xx/5xx responses to `AIClientError.httpError(statusCode:body:)`
    - Parse response JSON into `[LunchBoxIdea]`; throw `AIClientError.insufficientSuggestions` if fewer than 3 are returned
    - _Requirements: 2.5, 5.2, 5.5, 5.6, 5.7, 9.1_

  - [ ]* 7.2 Write property test for AIClient request URL matches configured base URL
    - **Property 3: AIClient uses configured base URL**
    - **Validates: Requirements 2.5, 9.1**

  - [ ]* 7.3 Write property test for Authorization header
    - **Property 12: API key appears in Authorization header**
    - **Validates: Requirements 5.2**

  - [ ]* 7.4 Write property test for insufficient suggestions error
    - **Property 13: Response must contain at least 3 suggestions**
    - **Validates: Requirements 5.3**

  - [ ]* 7.5 Write property test for HTTP error descriptions
    - **Property 15: HTTP errors produce human-readable descriptions**
    - **Validates: Requirements 5.6**

  - [ ]* 7.6 Write unit tests for AIClient
    - Test 401 → "Invalid API key" message, 429 → rate limit message, 500 → service unavailable message
    - Test `networkUnavailable` path using a mock `URLSession`
    - _Requirements: 5.6, 5.7_

- [x] 8. Implement SuggestionEngine
  - [x] 8.1 Implement `SuggestionEngine` conforming to `SuggestionEngineProtocol`
    - Build a deterministic prompt string from `[InventoryItem]` and `DietaryPreferences`
    - Include all item names and all active dietary preference labels in the prompt
    - Delegate to `AIClient.fetchSuggestions(prompt:)`
    - _Requirements: 5.1, 6.2, 6.4_

  - [ ]* 8.2 Write property test for prompt contains all inventory items and active preferences
    - **Property 11: Prompt contains all inventory items and active preferences**
    - **Validates: Requirements 5.1, 6.2**

  - [ ]* 8.3 Write property test for cleared preferences produce unconstrained prompt
    - **Property 17: Cleared preferences produce unconstrained prompt**
    - **Validates: Requirements 6.4**

  - [ ]* 8.4 Write unit test for SuggestionEngine with mock AIClient
    - Verify `getSuggestions` passes the constructed prompt to `AIClient`
    - _Requirements: 5.1_

- [x] 9. Implement SettingsViewModel
  - [x] 9.1 Implement `SettingsViewModel`
    - Expose `saveAPIKey(_:)` that validates non-empty/non-whitespace before calling `KeychainService.save`; publish a validation error otherwise
    - Expose `deleteAPIKey()` and `loadAPIKey()`
    - Expose `baseURL` and `model` fields backed by `UserDefaults`
    - _Requirements: 2.1, 2.3, 2.4, 2.5_

  - [ ]* 9.2 Write property test for empty/whitespace API key rejection
    - **Property 2: Empty/whitespace API key is rejected**
    - **Validates: Requirements 2.3**

- [x] 10. Implement ScannerViewModel
  - [x] 10.1 Implement `ScannerViewModel`
    - Manage `AVCaptureSession` lifecycle (`startSession`, `stopSession`)
    - Request camera permission via `AVCaptureDevice.requestAccess`; publish `cameraPermissionStatus`
    - Integrate `VNRecognizeTextRequest` / CoreML food classifier to detect items from camera frames
    - Filter detections by confidence threshold before adding to `detectedItems`
    - Implement `confirm(_:)` — adds a corresponding `InventoryItem` to `InventoryStore`
    - Implement `dismiss(_:)` — removes item from `detectedItems` without touching `InventoryStore`
    - Implement `addManualItem(name:)` — adds a non-empty name directly to `InventoryStore`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [ ]* 10.2 Write property test for confidence threshold filtering
    - **Property 4: Confidence threshold filters detections**
    - **Validates: Requirements 3.4**

  - [ ]* 10.3 Write property test for confirm adds, dismiss does not
    - **Property 5: Confirm adds, dismiss does not**
    - **Validates: Requirements 3.5**

  - [ ]* 10.4 Write property test for manual item addition
    - **Property 6: Manual item addition**
    - **Validates: Requirements 3.6**

- [x] 11. Implement InventoryViewModel and canRequestSuggestions
  - [x] 11.1 Implement `InventoryViewModel`
    - Expose `items` from `InventoryStore`
    - Expose `canRequestSuggestions: Bool` — `true` iff `items` is non-empty
    - Expose `editItem(_:)`, `removeItem(id:)`, `clearAll()` (with confirmation flag)
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

  - [ ]* 11.2 Write property test for canRequestSuggestions
    - **Property 10: Suggestions enabled iff inventory non-empty**
    - **Validates: Requirements 4.5, 4.6**

- [x] 12. Implement SuggestionsViewModel and FavoritesViewModel
  - [x] 12.1 Implement `SuggestionsViewModel`
    - Call `SuggestionEngine.getSuggestions` on demand; publish `ideas`, `isLoading`, `errorState`
    - Map all `AIClientError` cases to user-readable `AppError` values
    - _Requirements: 5.1, 5.3, 5.5, 5.6, 5.7_

  - [x] 12.2 Implement `FavoritesViewModel`
    - Expose `favorites` from `FavoritesStore`
    - Expose `delete(id:)` delegating to `FavoritesStore`
    - _Requirements: 8.1, 8.2, 8.3_

- [x] 13. Implement share formatter
  - [x] 13.1 Implement a `LunchBoxIdeaShareFormatter` that converts a `LunchBoxIdea` to a plain-text string containing name, ingredients, and preparation steps
    - _Requirements: 7.2_

  - [ ]* 13.2 Write property test for share text contains all idea fields
    - **Property 18: Share text contains all idea fields**
    - **Validates: Requirements 7.2**

- [x] 14. Checkpoint — Ensure all ViewModel and domain service tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 15. Build SwiftUI views — Settings and Onboarding
  - [x] 15.1 Implement `OnboardingView`
    - Show on first launch only (track with `UserDefaults` flag)
    - Explain core features; provide a "Get Started" button
    - _Requirements: 1.3_

  - [x] 15.2 Implement `SettingsView`
    - API key entry/update/delete field bound to `SettingsViewModel`
    - Configurable base URL and model fields
    - Privacy notice accessible from this screen
    - _Requirements: 2.1, 2.4, 2.5, 9.4_

- [x] 16. Build SwiftUI views — Scanner and Inventory
  - [x] 16.1 Implement `ScannerView`
    - `AVCaptureVideoPreviewLayer` wrapped in `UIViewRepresentable`
    - Overlay detected item names with confirm/dismiss buttons
    - Camera permission denied state: explanation + "Open Settings" button
    - Manual add text field
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [x] 16.2 Implement `InventoryView`
    - Scrollable list of `InventoryItem` with inline edit and swipe-to-delete
    - "Clear All" button with confirmation alert
    - "Get Lunch Box Ideas" button — disabled when inventory is empty
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 17. Build SwiftUI views — Suggestions, Detail, and Favorites
  - [x] 17.1 Implement `SuggestionsView`
    - Loading indicator while request is in progress
    - List of `LunchBoxIdea` cards; error alert with retry action
    - Offline error banner (no retry spinner)
    - _Requirements: 5.3, 5.5, 5.6, 5.7_

  - [x] 17.2 Implement `DetailView`
    - Full name, ingredients list, and preparation steps
    - Share button invoking iOS share sheet via `LunchBoxIdeaShareFormatter`
    - Save button persisting to `FavoritesStore` with brief visual acknowledgment (e.g. checkmark animation)
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [x] 17.3 Implement `FavoritesView`
    - Reverse-chronological list of saved ideas; swipe-to-delete
    - Tap navigates to `DetailView`
    - _Requirements: 8.1, 8.2, 8.3_

  - [x] 17.4 Implement `PreferencesView`
    - Toggle list for vegetarian, vegan, gluten-free, dairy-free, nut-free
    - Bound to `PreferencesStore`; persists automatically
    - _Requirements: 6.1, 6.3_

- [x] 18. Wire app entry point and environment injection
  - [x] 18.1 Set up `@main App` struct
    - Instantiate `InventoryStore`, `PreferencesStore`, `FavoritesStore`, `KeychainService`, `AIClient`, `SuggestionEngine`
    - Inject stores into the SwiftUI environment
    - Show `OnboardingView` on first launch, then `TabView` with Scanner, Favorites, and Settings tabs
    - _Requirements: 1.1, 1.2, 1.3_

- [ ] 19. Write XCUITest smoke tests
  - [ ]* 19.1 Write XCUITest for onboarding → settings → scan → suggestions happy path
    - _Requirements: 1.3, 2.1, 3.1, 5.3_

  - [ ]* 19.2 Write XCUITest for camera permission denial flow
    - _Requirements: 3.2_

  - [ ]* 19.3 Write XCUITest for offline error state
    - _Requirements: 5.7_

- [ ] 20. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Property tests use SwiftCheck; each test must run ≥ 100 iterations and include the comment `// Feature: lunchbox-prep-ios, Property N: <property text>`
- Inventory is intentionally in-memory only — no persistence between launches
- All local data (favorites, preferences) stays on-device; only the user-configured AI endpoint receives inventory data
