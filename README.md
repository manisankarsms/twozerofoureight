# 2048

A polished Flutter implementation of the classic 2048 sliding-tile puzzle, with
selectable goals, light/dark themes, session save/restore, and production-ready
monetization (interstitial ads + a one-time Remove Ads purchase) and telemetry.

## Features

- Classic 4×4 gameplay with swipe controls and haptic feedback.
- Four goal modes: 2048 (Classic), 1024 (Standard), 512 (Easy), 256 (Quick).
- Per-goal best scores, persisted locally.
- Automatic session save/restore — close the app mid-game and continue later.
- Light and dark themes with a persisted preference.
- Interstitial ads after every fourth completed game, with a Remove Ads IAP.
- Firebase Analytics + Crashlytics (optional; the app runs without them).

## Project layout

```
lib/
  main.dart                 App entry, theme wiring, service init
  models/tile.dart          Tile data model
  game/game_controller.dart Pure game logic (moves, merges, win/loss)
  data/
    game_save.dart          Persistent state model
    save_manager.dart       SharedPreferences persistence + migration
  screens/                  Home, Gameplay, Settings
  widgets/                  Tile and game-over overlay
  services/
    ad_service.dart         Interstitial ad loading/showing
    purchase_service.dart   Remove Ads in-app purchase
    receipt_validator.dart  Purchase verification seam (see Purchases)
    firebase_service.dart   Analytics + Crashlytics init
  theme/app_theme.dart      Design tokens and text styles
```

## Getting started

Requires the Flutter SDK (Dart `^3.12.2`, see `pubspec.yaml`).

```sh
flutter pub get
flutter run
```

In debug builds, ads use Google's official test ad units and Firebase silently
disables itself when platform config files are missing, so the game runs
out of the box without any additional setup.

## Configuration

### AdMob (release only)

Release builds keep ads disabled until real AdMob interstitial unit IDs are
supplied through `--dart-define`. Debug builds always use test units.

```sh
flutter build appbundle --dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=ca-app-pub-XXX/YYY
flutter build ipa       --dart-define=ADMOB_IOS_INTERSTITIAL_ID=ca-app-pub-XXX/ZZZ
```

Also replace the test AdMob **app** IDs in `android/app/src/main/AndroidManifest.xml`
and `ios/Runner/Info.plist` with your production app IDs. See
[`MONETIZATION_SETUP.md`](MONETIZATION_SETUP.md) for the full release checklist.

### In-app purchase

Create a non-consumable "Remove Ads" product in the Play Console and App Store
Connect. The client product identifier is `remove_ads`
(`PurchaseService.removeAdsProductId`); align your store product ID with it.

> **Security note:** purchases are currently verified on-device via
> `LocalReceiptValidator`, which trusts the store and can be spoofed on
> compromised devices. Before a production launch, implement
> `ServerReceiptValidator` in `lib/services/receipt_validator.dart` to verify
> receipts against a backend, then swap it in `PurchaseService`.

### Firebase (optional)

Analytics and Crashlytics activate automatically once the platform config files
are present. Without them the app still launches; telemetry is simply disabled.
See [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md) for registering the Android/iOS apps
and adding `google-services.json` / `GoogleService-Info.plist`.

## Versioning

The app version comes from `pubspec.yaml` (`version: <name>+<build>`) and is
shown in Settings by reading it at runtime via `package_info_plus`, so the two
never drift. Bump the version in `pubspec.yaml` only.

## Testing

```sh
flutter test
```

## Build

```sh
flutter build appbundle   # Android
flutter build ipa         # iOS
flutter build web         # Web (hosted at twozero48.web.app)
```
