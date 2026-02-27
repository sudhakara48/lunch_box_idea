// LunchBoxPrepApp.swift
// Entry point for the LunchBox Prep iOS application.
//
// NOTE: The @main attribute and SwiftUI App lifecycle are used when building
// for iOS with Xcode. This file is included in the Swift package library target
// so that the module compiles cleanly with `swift build`.

import Foundation

/// Namespace for app-wide constants.
public enum LunchBoxPrepApp {
    public static let appName = "LunchBox Prep"
    public static let minimumSuggestionCount = 3
    public static let defaultModel = "gemini-3.1-pro-preview"
    public static let defaultBaseURL = "https://generativelanguage.googleapis.com/v1beta"
}
