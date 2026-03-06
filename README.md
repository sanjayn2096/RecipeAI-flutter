# RecipeAI (Flutter)

Flutter version of RecipeAI — generates recipes based on user suggestions and preferences.

- **Firebase project ID:** `recipeai-89d8b`

## Architecture (MVVM)

- **Models**: `lib/data/models/` — Recipe, UserData, NutritionalValue, API DTOs
- **Views**: `lib/screens/` — UI only, no business logic
- **ViewModels**: `lib/view_models/` — state and actions, use repositories
- **Repositories**: `lib/data/repositories/` — Auth, User, Recipe (single place for API/data)
- **API**: `lib/data/api/api_service.dart` — all backend calls
- **Services**: `lib/services/session_manager.dart` — session and preferences

## Setup

1. Install Flutter and run from project root:
   ```bash
   cd recipe_ai_flutter
   flutter pub get
   ```

2. Firebase: add your `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) for project **recipeai-89d8b** and run:
   ```bash
   flutterfire configure
   ```

3. Gemini API key: set in **Firebase Remote Config** with key `gemini_api_key`. The app fetches it at startup (no hardcoded key).

## Run

```bash
flutter run
```

## Architectural fixes (vs original Android)

- **Repositories**: Auth and User use `AuthRepository` / `UserRepository` instead of calling API from ViewModels.
- **Async**: All API/session work uses `async/await` (no callbacks).
- **Firebase sign out**: Sign out now calls `FirebaseAuth.signOut()` in addition to backend and session clear.
- **Prompt**: Prompt text is built in `PromptBuilder` (testable), not inside the ViewModel.
- **Session**: Single `SessionManager` instance created in `main.dart` and passed where needed.
- **Recipe image**: Model supports both `imageUrl` (API/Gemini) and `image` for compatibility.

## Environment / base URL

To add dev or staging later, use `--dart-define=ENV=dev` and add the URL in `lib/core/env_config.dart` (`_baseUrls`).
