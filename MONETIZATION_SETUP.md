# Monetization release setup

The app deliberately uses no banner ads. It counts completed (lost) games and shows a preloaded interstitial after every fourth completed game. Players who own Remove Ads will never receive an interstitial.

## Before releasing

1. Create a non-consumable product in both Google Play Console and App Store Connect with the exact identifier `com.benbelabs.twozerofoureight.remove_ads`.
2. Replace the Google test app IDs in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist` with your real AdMob app IDs.
3. Build release variants with your production interstitial IDs:
   ```sh
   flutter build appbundle --dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=ca-app-pub-.../...
   flutter build ipa --dart-define=ADMOB_IOS_INTERSTITIAL_ID=ca-app-pub-.../...
   ```
4. Enable the In-App Purchase capability for the iOS Runner target in Xcode.
5. Add a published privacy-policy URL to the Settings screen before submission, and complete consent requirements for every territory where you distribute.
6. Test purchases using Play license testers and App Store sandbox accounts. Restore Purchases must work before submission.

Do not ship the Google test app IDs or test ad unit IDs. They are present only to make debug development safe.
