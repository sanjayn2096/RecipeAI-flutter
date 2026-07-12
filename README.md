# Sous Chef AI (Flutter)

Cross-platform client for **Sous Chef AI** — AI recipes, pantry cooking, meal planning, imports, and Premium assistants. Talks to the [RecipeAI-backend](https://github.com/sanjayn2096/RecipeAI-backend) Firebase Functions API.

- **Firebase project:** `recipeai-89d8b`
- **Android applicationId:** `com.sunj.souschefai`
- **Platforms:** Android, iOS, Web (primary); macOS / Windows / Linux runners present

## Features

### Cook with AI
- **Recipe generation** — custom prompt, preference questionnaire, or “feeling lucky”; streaming results
- **Recipe detail** — ingredients, steps, macros, servings, hero image, public favorites
- **Cook mode** — gather ingredients → step-by-step → finish; Premium step images
- **Recipe assistant** — in-recipe Q&A (Premium)
- **Saved & favorites** — Hive locally + cloud sync; trending and Premium “latest” feeds

### Import and pantry
- **Import hub** — URL, pasted text, or cookbook photo/OCR → structured recipe
- **Pantry scan** — camera/photo → detected items → cook from pantry (Premium; on-device Vision/ML Kit + optional cloud)

### Plan and shop
- **Meal planner** — wizard + slot regeneration (free: 3 days, Premium: 7; guests: 1 trial)
- **Grocery list** — from recipes/plans; Hive for guests, cloud when signed in; text export
- **Daily ideas** — shared catalog from the backend scheduler

### Account and UX
- **Auth** — email/password, Google, guest mode
- **Onboarding** — cuisines, diet, allergies, summary, soft paywall
- **Premium** — store subscriptions with tier comparison and daily credits UI
- **i18n** — English and Spanish
- **Telemetry** — Analytics, Crashlytics, activity metrics
- **Web marketing** — hosting pages (home, privacy, terms)

### Free vs Premium

| Feature | Free / guest | Premium |
|--------|--------------|---------|
| Recipe generations | Free: 3/UTC day; guest: 2 total | Unlimited |
| Imports | 1/UTC day (signed-in) | Unlimited |
| Pantry scan | — | Yes |
| Meal planner | 3 days (guest: 1 trial) | 7 days |
| Latest recipes | — | Yes |
| Recipe assistant | — | Yes |
| Cook-mode step images | — | Yes |

## Architecture

The app uses **MVVM** with a single API boundary and repository layer.

```text
lib/
├── main.dart                 # Firebase, Hive, DI, telemetry, GoRouter
├── navigation/app_router.dart
├── screens/ + widgets/       # Views (UI only)
├── onboarding/               # Preference + paywall flow
├── view_models/              # State and actions
├── data/
│   ├── api/api_service.dart  # All backend HTTP
│   ├── repositories/         # Auth, User, Recipe, Grocery, MealPlan
│   └── models/               # Domain + API DTOs
├── services/                 # SessionManager, platform helpers
└── core/                     # Env, monetization, telemetry, tiers, l10n
```

### Layering

| Layer | Responsibility |
|-------|----------------|
| **Views** | `lib/screens/`, `lib/widgets/`, `lib/onboarding/` — no business logic |
| **ViewModels** | Recipe, home, login, grocery, meal plan, subscription, assistant |
| **Repositories** | Auth, user, recipe, grocery list, meal plan — sole data access |
| **API** | `ApiService` — Firebase Functions HTTP |
| **Local** | Hive (saved recipes, grocery, meal plans) + `SessionManager` prefs |
| **Services** | Session, platform pantry analyzers, OCR stubs for web |

### Navigation and entry

- `main.dart` boots Firebase, Crashlytics, Hive, wiring, and `GoRouter`.
- Routes: splash → login/verify → onboarding → home shell; recipe flow, cook mode, grocery, pantry, meal plan, premium, profile, favorites, trending/latest.

### Notable modules

- **Monetization** — `MonetizationConfig`, `SubscriptionViewModel`, paywall, tier table, daily credits
- **Telemetry** — feature IDs, device identity, Firestore activity metrics
- **Pantry ML** — platform analyzers + `ml/pantry_detection/` training pipeline
- **Import OCR** — IO implementation; web stub

Recipe generation always goes through the backend (`POST generate-recipe` / stream). The client never calls Gemini directly.

## Setup

1. Install Flutter and from the project root:

   ```bash
   flutter pub get
   ```

2. Firebase config:
   - **Android:** `android/app/google-services.json` for package `com.sunj.souschefai` on project `recipeai-89d8b`
   - **iOS:** `GoogleService-Info.plist` in the iOS runner

3. Point at your backend via `lib/core/env_config.dart` (optional `--dart-define=ENV=dev` for staging URLs).

## Run

```bash
flutter run
```

## Design notes (vs original Android)

- Repositories own API/session access; ViewModels stay UI-state focused.
- Async work uses `async/await` throughout.
- Sign-out clears Firebase Auth, backend session, and local session.
- Generation requests send structured preferences plus `recipeMode` (`custom` / `lucky` / `preferences`) so the backend owns prompt assembly.
