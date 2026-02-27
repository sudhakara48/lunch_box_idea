import Foundation

// MARK: - Inventory

/// A single item in the current inventory.
public struct InventoryItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    /// Free-text quantity, e.g. "2 cups", "half a block".
    public var quantity: String

    public init(id: UUID = UUID(), name: String, quantity: String = "") {
        self.id = id
        self.name = name
        self.quantity = quantity
    }
}

// MARK: - Scanner

/// A food item detected by the scanner (pre-confirmation).
public struct DetectedItem: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    /// Detection confidence in the range 0.0 – 1.0.
    public let confidence: Float

    public init(id: UUID = UUID(), name: String, confidence: Float) {
        self.id = id
        self.name = name
        self.confidence = confidence
    }
}

// MARK: - Suggestions

/// A lunch box recipe returned by the AI.
public struct LunchBoxIdea: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var ingredients: [String]
    public var preparationSteps: [String]
    /// Non-nil when persisted to favorites.
    public var savedAt: Date?
    /// YouTube video ID fetched after suggestion generation.
    public var youtubeVideoID: String?

    public init(
        id: UUID = UUID(),
        name: String,
        ingredients: [String],
        preparationSteps: [String],
        savedAt: Date? = nil,
        youtubeVideoID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.ingredients = ingredients
        self.preparationSteps = preparationSteps
        self.savedAt = savedAt
        self.youtubeVideoID = youtubeVideoID
    }
}

// MARK: - Preferences

/// Supported cuisine regions for recipe suggestions.
public enum CuisineRegion: String, Codable, CaseIterable, Identifiable {
    case any          = "Any"
    case indian       = "Indian"
    case italian      = "Italian"
    case mexican      = "Mexican"
    case chinese      = "Chinese"
    case japanese     = "Japanese"
    case mediterranean = "Mediterranean"
    case american     = "American"
    case thai         = "Thai"
    case middleEastern = "Middle Eastern"
    case korean       = "Korean"
    case french       = "French"

    public var id: String { rawValue }
    public var flag: String {
        switch self {
        case .any:           return "🌍"
        case .indian:        return "🇮🇳"
        case .italian:       return "🇮🇹"
        case .mexican:       return "🇲🇽"
        case .chinese:       return "🇨🇳"
        case .japanese:      return "🇯🇵"
        case .mediterranean: return "🫒"
        case .american:      return "🇺🇸"
        case .thai:          return "🇹🇭"
        case .middleEastern: return "🌙"
        case .korean:        return "🇰🇷"
        case .french:        return "🇫🇷"
        }
    }
}

/// Dietary filter flags.
public struct DietaryPreferences: Codable, Equatable {
    public var vegetarian: Bool
    public var vegan: Bool
    public var glutenFree: Bool
    public var dairyFree: Bool
    public var nutFree: Bool
    public var cuisineRegion: CuisineRegion

    public init(
        vegetarian: Bool = false,
        vegan: Bool = false,
        glutenFree: Bool = false,
        dairyFree: Bool = false,
        nutFree: Bool = false,
        cuisineRegion: CuisineRegion = .any
    ) {
        self.vegetarian = vegetarian
        self.vegan = vegan
        self.glutenFree = glutenFree
        self.dairyFree = dairyFree
        self.nutFree = nutFree
        self.cuisineRegion = cuisineRegion
    }

    /// Returns a `DietaryPreferences` with all flags set to `false`.
    public static var none: DietaryPreferences { DietaryPreferences() }
}

// MARK: - Gemini API shapes

/// Request body for the Gemini `generateContent` endpoint.
public struct GeminiRequest: Encodable {
    public let contents: [GeminiContent]
    public let systemInstruction: GeminiContent?
    public let generationConfig: GeminiGenerationConfig

    public init(contents: [GeminiContent], systemInstruction: GeminiContent? = nil, generationConfig: GeminiGenerationConfig = GeminiGenerationConfig()) {
        self.contents = contents
        self.systemInstruction = systemInstruction
        self.generationConfig = generationConfig
    }

    enum CodingKeys: String, CodingKey {
        case contents
        case systemInstruction = "system_instruction"
        case generationConfig = "generation_config"
    }
}

/// A content block (role + parts) in a Gemini request or response.
public struct GeminiContent: Codable, Equatable {
    public let role: String?
    public let parts: [GeminiPart]

    public init(role: String? = nil, parts: [GeminiPart]) {
        self.role = role
        self.parts = parts
    }
}

/// A single text part inside a `GeminiContent`.
public struct GeminiPart: Codable, Equatable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

/// Generation config — requests JSON output.
public struct GeminiGenerationConfig: Encodable, Equatable {
    public let responseMimeType: String

    public init(responseMimeType: String = "application/json") {
        self.responseMimeType = responseMimeType
    }

    enum CodingKeys: String, CodingKey {
        case responseMimeType = "response_mime_type"
    }
}

/// Top-level Gemini response envelope.
public struct GeminiResponse: Decodable {
    public let candidates: [GeminiCandidate]
}

/// A single candidate in the Gemini response.
public struct GeminiCandidate: Decodable {
    public let content: GeminiContent
}
