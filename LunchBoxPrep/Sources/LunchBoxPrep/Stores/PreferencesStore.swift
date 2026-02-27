import Foundation
import Combine

/// Observable store that persists `DietaryPreferences` to `UserDefaults` via JSON encoding.
@MainActor
public final class PreferencesStore: ObservableObject {

    private static let defaultsKey = "dietaryPreferences"

    private let defaults: UserDefaults

    /// The current dietary preferences. Mutate this directly; call `save()` to persist.
    @Published public var preferences: DietaryPreferences

    /// Creates a store, loading any previously persisted preferences from `UserDefaults`.
    /// Falls back to `DietaryPreferences()` if no value is found or decoding fails.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode(DietaryPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = DietaryPreferences()
        }
    }

    /// Encodes the current `preferences` and writes them to `UserDefaults`.
    public func save() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }

    /// Resets `preferences` to the default (all flags `false`) and persists the reset value.
    public func reset() {
        preferences = DietaryPreferences()
        save()
    }
}
