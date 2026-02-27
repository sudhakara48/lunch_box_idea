import Foundation

// MARK: - Protocol

public protocol SuggestionEngineProtocol {
    func getSuggestions(
        inventory: [InventoryItem],
        preferences: DietaryPreferences
    ) async throws -> [LunchBoxIdea]
}

// MARK: - Implementation

/// Formats inventory and dietary preferences into a deterministic prompt
/// and delegates to `AIClientProtocol` to fetch lunch box ideas.
public final class SuggestionEngine: SuggestionEngineProtocol {

    private let aiClient: AIClientProtocol

    public init(aiClient: AIClientProtocol) {
        self.aiClient = aiClient
    }

    // MARK: - SuggestionEngineProtocol

    public func getSuggestions(
        inventory: [InventoryItem],
        preferences: DietaryPreferences
    ) async throws -> [LunchBoxIdea] {
        let prompt = buildPrompt(inventory: inventory, preferences: preferences)
        return try await aiClient.fetchSuggestions(prompt: prompt)
    }

    // MARK: - Prompt builder

    /// Builds a deterministic prompt string from the inventory and preferences.
    ///
    /// Format:
    /// ```
    /// Available ingredients: apple, bread, cheese
    /// Dietary preferences: vegetarian, gluten-free
    /// ```
    /// If no preferences are active the dietary preferences line is omitted entirely.
    func buildPrompt(inventory: [InventoryItem], preferences: DietaryPreferences) -> String {
        let itemNames = inventory.map(\.name).joined(separator: ", ")
        var lines: [String] = ["Available ingredients: \(itemNames)"]

        let activeLabels = activePreferenceLabels(from: preferences)
        if !activeLabels.isEmpty {
            lines.append("Dietary preferences: \(activeLabels.joined(separator: ", "))")
        }

        if preferences.cuisineRegion != .any {
            lines.append("Cuisine style: \(preferences.cuisineRegion.rawValue)")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    /// Returns the canonical label strings for every active dietary flag,
    /// in a fixed order so the prompt is deterministic.
    private func activePreferenceLabels(from preferences: DietaryPreferences) -> [String] {
        var labels: [String] = []
        if preferences.vegetarian { labels.append("vegetarian") }
        if preferences.vegan      { labels.append("vegan") }
        if preferences.glutenFree { labels.append("gluten-free") }
        if preferences.dairyFree  { labels.append("dairy-free") }
        if preferences.nutFree    { labels.append("nut-free") }
        return labels
    }
}
