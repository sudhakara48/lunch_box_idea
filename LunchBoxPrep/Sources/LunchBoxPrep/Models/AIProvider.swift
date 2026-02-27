import Foundation

// MARK: - AIProvider

/// Supported AI providers with their base URLs and available models.
public enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case gemini = "Gemini"
    case openAI = "OpenAI"
    case claude = "Claude"

    public var id: String { rawValue }

    public var baseURL: String {
        switch self {
        case .gemini:  return "https://generativelanguage.googleapis.com/v1beta"
        case .openAI:  return "https://api.openai.com/v1"
        case .claude:  return "https://api.anthropic.com/v1"
        }
    }

    public var models: [AIModel] {
        switch self {
        case .gemini:
            return [
                AIModel(id: "gemini-3.1-pro-preview", name: "Gemini 3.1 Pro Preview", note: "Latest"),
                AIModel(id: "gemini-1.5-flash",       name: "Gemini 1.5 Flash",       note: "Free tier"),
                AIModel(id: "gemini-1.5-flash-8b",    name: "Gemini 1.5 Flash 8B",    note: "Free tier · Faster"),
                AIModel(id: "gemini-1.5-pro",         name: "Gemini 1.5 Pro",         note: "Free tier · Smarter"),
                AIModel(id: "gemini-2.0-flash",       name: "Gemini 2.0 Flash",       note: "Paid"),
                AIModel(id: "gemini-2.0-flash-lite",  name: "Gemini 2.0 Flash Lite",  note: "Paid · Fastest"),
                AIModel(id: "gemini-2.5-pro-preview", name: "Gemini 2.5 Pro Preview", note: "Paid · Best"),
            ]
        case .openAI:
            return [
                AIModel(id: "gpt-4o-mini",   name: "GPT-4o Mini",   note: "Fast · Affordable"),
                AIModel(id: "gpt-4o",        name: "GPT-4o",        note: "Smarter"),
                AIModel(id: "gpt-4-turbo",   name: "GPT-4 Turbo",   note: "Powerful"),
                AIModel(id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", note: "Legacy · Cheapest"),
            ]
        case .claude:
            return [
                AIModel(id: "claude-3-5-haiku-20241022",  name: "Claude 3.5 Haiku",  note: "Fast · Affordable"),
                AIModel(id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet", note: "Balanced"),
                AIModel(id: "claude-3-opus-20240229",     name: "Claude 3 Opus",     note: "Most capable"),
            ]
        }
    }

    public var defaultModel: AIModel { models[0] }

    /// Key used to store the API key in Keychain, per provider.
    public var keychainKey: String { "apiKey_\(rawValue)" }
}

// MARK: - AIModel

public struct AIModel: Identifiable, Equatable, Codable {
    public let id: String
    public let name: String
    public let note: String

    public init(id: String, name: String, note: String) {
        self.id = id
        self.name = name
        self.note = note
    }
}
