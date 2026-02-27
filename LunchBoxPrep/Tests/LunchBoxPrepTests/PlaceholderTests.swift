import XCTest
@testable import LunchBoxPrep

/// Placeholder test suite — real tests are added in subsequent tasks.
final class PlaceholderTests: XCTestCase {

    // MARK: - Model smoke tests

    func testInventoryItemInit() {
        let item = InventoryItem(name: "Apple", quantity: "3")
        XCTAssertEqual(item.name, "Apple")
        XCTAssertEqual(item.quantity, "3")
    }

    func testDetectedItemInit() {
        let item = DetectedItem(name: "Banana", confidence: 0.9)
        XCTAssertEqual(item.name, "Banana")
        XCTAssertEqual(item.confidence, 0.9, accuracy: 0.001)
    }

    func testLunchBoxIdeaInit() {
        let idea = LunchBoxIdea(
            name: "Fruit Salad",
            ingredients: ["Apple", "Banana"],
            preparationSteps: ["Chop fruit", "Mix together"]
        )
        XCTAssertEqual(idea.name, "Fruit Salad")
        XCTAssertEqual(idea.ingredients.count, 2)
        XCTAssertEqual(idea.preparationSteps.count, 2)
        XCTAssertNil(idea.savedAt)
    }

    func testDietaryPreferencesDefaults() {
        let prefs = DietaryPreferences()
        XCTAssertFalse(prefs.vegetarian)
        XCTAssertFalse(prefs.vegan)
        XCTAssertFalse(prefs.glutenFree)
        XCTAssertFalse(prefs.dairyFree)
        XCTAssertFalse(prefs.nutFree)
    }

    func testDietaryPreferencesNone() {
        XCTAssertEqual(DietaryPreferences.none, DietaryPreferences())
    }

    // MARK: - Error descriptions

    func testAIClientErrorMissingAPIKey() {
        let error = AIClientError.missingAPIKey
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testAIClientErrorHTTP401() {
        let error = AIClientError.httpError(statusCode: 401, body: "Unauthorized")
        XCTAssertTrue(error.errorDescription?.contains("Invalid API key") == true)
    }

    func testAIClientErrorHTTP429() {
        let error = AIClientError.httpError(statusCode: 429, body: "Too Many Requests")
        XCTAssertTrue(error.errorDescription?.contains("Rate limit") == true)
    }

    func testAIClientErrorHTTP500() {
        let error = AIClientError.httpError(statusCode: 500, body: "Internal Server Error")
        XCTAssertTrue(error.errorDescription?.contains("unavailable") == true)
    }

    func testAIClientErrorInsufficientSuggestions() {
        let error = AIClientError.insufficientSuggestions(count: 2)
        XCTAssertTrue(error.errorDescription?.contains("2") == true)
    }

    // MARK: - Codable round-trips

    func testInventoryItemCodableRoundTrip() throws {
        let original = InventoryItem(name: "Cheese", quantity: "100g")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(InventoryItem.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testLunchBoxIdeaCodableRoundTrip() throws {
        let original = LunchBoxIdea(
            name: "Wrap",
            ingredients: ["Tortilla", "Cheese"],
            preparationSteps: ["Fill", "Roll"],
            savedAt: Date(timeIntervalSince1970: 1_000_000)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LunchBoxIdea.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testDietaryPreferencesCodableRoundTrip() throws {
        let original = DietaryPreferences(vegetarian: true, glutenFree: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DietaryPreferences.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testChatCompletionRequestEncoding() throws {
        let request = ChatCompletionRequest(
            model: "gpt-4o-mini",
            messages: [ChatMessage(role: "user", content: "Hello")],
            responseFormat: ResponseFormat()
        )
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["model"] as? String, "gpt-4o-mini")
        XCTAssertNotNil(json?["response_format"])
    }
}
