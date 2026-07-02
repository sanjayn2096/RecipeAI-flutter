# Premium subscription and ads setup

## Store products

Create an auto-renewing subscription in both stores:

| Field | Value |
|-------|--------|
| Product ID | `sous_chef_standard_monthly` |
| Price | $5.99 / month |

- **Google Play**: Play Console → Monetize → Subscriptions
- **App Store**: App Store Connect → Subscriptions (same product ID)

## Release ad unit IDs

Run or build with `--dart-define`:

```
--dart-define=ANDROID_BANNER_AD_UNIT_ID=ca-app-pub-XXXX/YYYY
--dart-define=IOS_BANNER_AD_UNIT_ID=ca-app-pub-XXXX/YYYY
```

Replace test App IDs in `AndroidManifest.xml` and `ios/Runner/Info.plist` with your AdMob app IDs.

## Backend verification

Cloud Function `POST /verify-subscription` validates purchases and writes `users/{uid}.subscription`.

Environment variables (Firebase Functions):

| Variable | Purpose |
|----------|---------|
| `GOOGLE_PLAY_PACKAGE_NAME` | Default `com.sunj.souschefai` |
| `APPLE_SHARED_SECRET` | App Store shared secret for receipt validation |
| `SUBSCRIPTION_ALLOW_UNVERIFIED` | `true` only for local/dev testing (never in production) |

Service account used by Cloud Functions needs **Google Play Android Developer API** access in Play Console.

## Legal URLs

Override defaults in `lib/core/monetization_config.dart`:

```
--dart-define=TERMS_URL=https://your-site/terms
--dart-define=PRIVACY_URL=https://your-site/privacy
```
