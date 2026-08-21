# Release Versions

## 1.0.1+2 — 2026-08-16

Play internal-testing release.

- Enables Firebase Analytics and Crashlytics.
- Configures the production AdMob app ID and interstitial unit.
- Shows an interstitial after every fourth lost game when ads have not been removed.
- Uses WorkManager 2.11.2 to fix the Android 16 release startup crash from the Ads SDK.
- Connects the active Google Play one-time product `remove_ads` to disable ads after purchase or restoration.

## 1.0.0+1

Initial release build.
