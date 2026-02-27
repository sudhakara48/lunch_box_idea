# LunchBox Prep — Product Overview

LunchBox Prep is an iOS app that helps users plan and prepare lunch boxes. Users scan or manually enter food items they have on hand, set dietary preferences, and receive AI-generated lunch box recipe suggestions. Favorites can be saved for later reference.

## Core User Flow

1. Scan / add ingredients to an in-session inventory
2. Optionally set dietary preferences (vegetarian, vegan, gluten-free, dairy-free, nut-free) and a cuisine region
3. Tap "Get Lunch Box Ideas" → AI returns ≥ 3 recipe suggestions
4. Save ideas to Favorites for future reference

## Key Constraints

- API key is required (stored in Keychain); the app surfaces a clear error if missing
- Inventory is session-only (not persisted between launches)
- Favorites are persisted to `Documents/favorites.json`
- Minimum of 3 suggestions must be returned; fewer triggers a retry prompt
- Supports Gemini, OpenAI, and Claude as AI providers (configurable in Settings)
