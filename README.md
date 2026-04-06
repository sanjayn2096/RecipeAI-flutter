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

2. Firebase (required for Android): The app needs `FirebaseOptions` from a config file.
   - **Android:** Release `applicationId` is `com.sunj.souschefai`. Use **`android/app/google-services.json`** from Firebase Console → project **recipeai-89d8b** → Android app registered with that package (or run `firebase apps:sdkconfig ANDROID <appId> --project recipeai-89d8b`).
   - **iOS:** Add `GoogleService-Info.plist` to the iOS project if you build for iOS.
   - The Google Services Gradle plugin is already applied in this project; the file path above must be correct or you'll see "Failed to load FirebaseOptions from resource".

3. **Recipe generation** is done by your backend (`POST generate-recipe`). The app does not call Gemini from the client.

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
- **Recipe image**: Model supports both `imageUrl` and `image` for API compatibility.

## Environment / base URL

To add dev or staging later, use `--dart-define=ENV=dev` and add the URL in `lib/core/env_config.dart` (`_baseUrls`).
