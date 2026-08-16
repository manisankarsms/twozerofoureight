# Firebase Analytics and Crashlytics setup

The Dart and Android build integration is in place. The Firebase project `twozero48` currently has no mobile apps registered, so add the platform registrations before expecting telemetry.

1. In Firebase Console, register an **Android** app with package name `com.benbelabs.twozerofoureight`, enable Google Analytics, then save its generated `google-services.json` as `android/app/google-services.json`.
2. Register an **iOS** app with bundle ID `com.benbelabs.twozerofoureight`, then add its generated `GoogleService-Info.plist` to `ios/Runner` and the Runner target in Xcode.
3. Run `flutter pub get`, then `cd ios && pod install` after the iOS file is present.
4. Build a release and verify Analytics events appear in DebugView. Trigger a controlled test crash only in a non-production build to confirm Crashlytics reporting.

The Android Google Services and Crashlytics plugins activate automatically when `google-services.json` is present. Do not add either configuration file to `.gitignore`; Firebase client configuration is intended to ship with the app and is not a secret.
