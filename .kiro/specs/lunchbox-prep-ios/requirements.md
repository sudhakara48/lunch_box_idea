# Requirements Document

## Introduction

LunchBox Prep is an iOS application that helps users prepare lunch boxes by scanning food items available at home (fridge, pantry, countertop, etc.) and leveraging AI APIs to suggest creative, practical lunch box ideas based on the scanned inventory. Users bring their own AI API key, keeping the app lightweight and cost-transparent.

## Glossary

- **App**: The LunchBox Prep iOS application
- **User**: The person using the App on their iOS device
- **Scanner**: The in-app camera-based food item detection component
- **Inventory**: The collection of food items identified or manually entered by the User
- **AI_Client**: The component responsible for communicating with the external AI API
- **Suggestion_Engine**: The component that formats Inventory data and sends it to the AI_Client to retrieve lunch box ideas
- **API_Key**: The User-provided authentication credential for the external AI service (e.g., OpenAI, Anthropic)
- **Lunch_Box_Idea**: A structured suggestion returned by the AI containing a name, ingredients list, and preparation steps
- **Session**: A single scanning and suggestion workflow from scan start to idea display

## Requirements

### Requirement 1: App Installation and iOS Compatibility

**User Story:** As a user, I want to install the app on my iPhone, so that I can use it on my personal device without restrictions.

#### Acceptance Criteria

1. THE App SHALL be distributed as a standard iOS application compatible with iOS 16.0 and later.
2. THE App SHALL run on iPhone devices with a minimum screen size of 4.7 inches.
3. WHEN the App is launched for the first time, THE App SHALL present an onboarding screen explaining its core features.

---

### Requirement 2: API Key Configuration

**User Story:** As a user, I want to provide my own AI API key, so that I control my usage and costs directly.

#### Acceptance Criteria

1. THE App SHALL provide a settings screen where the User can enter, update, and delete their API_Key.
2. THE App SHALL store the API_Key in the iOS Keychain and not in plain-text storage.
3. WHEN the User saves an API_Key, THE App SHALL validate that the key is a non-empty string before persisting it.
4. IF the User attempts to start a Session without a saved API_Key, THEN THE App SHALL display an error message directing the User to the settings screen.
5. THE App SHALL support at least OpenAI-compatible API endpoints, with a configurable base URL so the User can point to alternative providers.

---

### Requirement 3: Food Item Scanning

**User Story:** As a user, I want to scan food items using my phone camera, so that I can quickly build an inventory without typing everything manually.

#### Acceptance Criteria

1. WHEN the User initiates a scan, THE Scanner SHALL request camera permission from iOS before accessing the camera.
2. IF the User denies camera permission, THEN THE App SHALL display an explanation and provide a button to open iOS Settings.
3. WHEN the camera is active, THE Scanner SHALL analyze the camera feed and identify food items in real time using on-device vision or AI-assisted recognition.
4. WHEN a food item is identified with sufficient confidence, THE Scanner SHALL display the item name as an overlay on the camera view.
5. THE Scanner SHALL allow the User to confirm or dismiss each identified item before adding it to the Inventory.
6. THE App SHALL allow the User to manually type and add food items to the Inventory as an alternative to scanning.
7. WHEN an item is added to the Inventory, THE App SHALL display it in a list that the User can review, edit, and remove items from.

---

### Requirement 4: Inventory Management

**User Story:** As a user, I want to review and manage my scanned inventory, so that I can correct mistakes and ensure accuracy before requesting suggestions.

#### Acceptance Criteria

1. THE App SHALL display the current Inventory as a scrollable list showing each item's name and quantity.
2. WHEN the User edits an item name in the Inventory, THE App SHALL update the item immediately upon confirmation.
3. WHEN the User removes an item from the Inventory, THE App SHALL remove it from the list immediately.
4. THE App SHALL allow the User to clear the entire Inventory with a single action, with a confirmation prompt before clearing.
5. WHILE the Inventory contains at least one item, THE App SHALL enable the "Get Lunch Box Ideas" action.
6. IF the Inventory is empty, THEN THE App SHALL disable the "Get Lunch Box Ideas" action and display a prompt to scan or add items.

---

### Requirement 5: AI-Powered Lunch Box Suggestions

**User Story:** As a user, I want to receive lunch box ideas based on my scanned items, so that I can prepare a meal without needing to search for recipes manually.

#### Acceptance Criteria

1. WHEN the User triggers the "Get Lunch Box Ideas" action, THE Suggestion_Engine SHALL send the Inventory contents and any dietary preferences to the AI_Client.
2. THE AI_Client SHALL call the configured AI API endpoint using the stored API_Key and receive a structured response.
3. WHEN the AI API returns a valid response, THE App SHALL display a minimum of 3 Lunch_Box_Ideas to the User.
4. EACH Lunch_Box_Idea SHALL include a name, a list of required ingredients from the Inventory, and step-by-step preparation instructions.
5. WHEN the AI API request is in progress, THE App SHALL display a loading indicator to the User.
6. IF the AI API returns an error response, THEN THE App SHALL display a human-readable error message and allow the User to retry.
7. IF the network is unavailable when the User triggers suggestions, THEN THE App SHALL display an offline error message without attempting the API call.

---

### Requirement 6: Dietary Preferences and Filters

**User Story:** As a user, I want to specify dietary preferences, so that the suggestions I receive are relevant to my needs.

#### Acceptance Criteria

1. THE App SHALL provide a preferences screen where the User can select dietary options including vegetarian, vegan, gluten-free, dairy-free, and nut-free.
2. WHEN dietary preferences are set, THE Suggestion_Engine SHALL include them in the prompt sent to the AI_Client.
3. THE App SHALL persist dietary preferences across Sessions so the User does not need to re-enter them each time.
4. WHEN the User clears all dietary preferences, THE Suggestion_Engine SHALL send requests without dietary constraints.

---

### Requirement 7: Suggestion Detail and Sharing

**User Story:** As a user, I want to view full recipe details and share them, so that I can follow the instructions and send ideas to others.

#### Acceptance Criteria

1. WHEN the User selects a Lunch_Box_Idea from the list, THE App SHALL display the full detail view including name, ingredients, and preparation steps.
2. THE App SHALL provide a share action on the detail view that invokes the iOS share sheet with the Lunch_Box_Idea formatted as plain text.
3. THE App SHALL provide a "Save" action that persists the Lunch_Box_Idea to a local favorites list.
4. WHEN a Lunch_Box_Idea is saved, THE App SHALL confirm the save with a brief visual acknowledgment.

---

### Requirement 8: Saved Favorites

**User Story:** As a user, I want to access previously saved lunch box ideas, so that I can reuse recipes I liked without scanning again.

#### Acceptance Criteria

1. THE App SHALL provide a favorites screen listing all saved Lunch_Box_Ideas in reverse chronological order.
2. WHEN the User selects a saved Lunch_Box_Idea, THE App SHALL display its full detail view.
3. WHEN the User deletes a saved Lunch_Box_Idea, THE App SHALL remove it from the favorites list immediately.
4. THE App SHALL persist saved Lunch_Box_Ideas across app restarts using local on-device storage.

---

### Requirement 9: Privacy and Data Handling

**User Story:** As a user, I want my data to stay on my device, so that I have confidence my food inventory and API key are not shared without my knowledge.

#### Acceptance Criteria

1. THE App SHALL not transmit Inventory data to any server other than the User-configured AI API endpoint.
2. THE App SHALL not collect or transmit analytics, usage data, or personal information to any third-party service without explicit User consent.
3. THE App SHALL store all local data (Inventory, favorites, preferences) on-device only.
4. THE App SHALL include a privacy notice accessible from the settings screen describing data handling practices.
