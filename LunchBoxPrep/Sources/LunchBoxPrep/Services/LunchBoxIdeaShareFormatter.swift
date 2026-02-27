import Foundation

/// Converts a `LunchBoxIdea` into a plain-text string suitable for sharing.
public struct LunchBoxIdeaShareFormatter {

    public init() {}

    /// Formats a `LunchBoxIdea` as plain text containing the name, ingredients, and preparation steps.
    ///
    /// Output format:
    /// ```
    /// <name>
    ///
    /// Ingredients:
    /// - <ingredient1>
    /// - <ingredient2>
    ///
    /// Preparation:
    /// 1. <step1>
    /// 2. <step2>
    /// ```
    public func format(_ idea: LunchBoxIdea) -> String {
        var lines: [String] = []

        lines.append(idea.name)
        lines.append("")

        lines.append("Ingredients:")
        for ingredient in idea.ingredients {
            lines.append("- \(ingredient)")
        }
        lines.append("")

        lines.append("Preparation:")
        for (index, step) in idea.preparationSteps.enumerated() {
            lines.append("\(index + 1). \(step)")
        }

        return lines.joined(separator: "\n")
    }
}
