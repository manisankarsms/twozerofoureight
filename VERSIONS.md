# 2048 — Version History

## Version Management

- **versionName**: User-facing semantic version, such as `1.0.0`.
- **versionCode**: Build number after `+`, such as `1`.
- Increment the build number for every Play Store or App Store upload.

---

## Releases

### v1.0.0+1 (Initial Release)
**Date:** August 16, 2026  
**Track:** Pending store submission  

**Features:**
- Classic 2048 gameplay with 256, 512, 1024, and 2048 goals
- Separate best score for each goal
- Automatic saved-game continuation
- Light and dark themes
- Settings, privacy-policy link, and exit confirmation
- Interstitial-ad and Remove Ads purchase foundations
- Android upload-key signing configured

**Before submission:**
- [ ] Replace AdMob test app IDs and provide production unit IDs
- [ ] Activate the Remove Ads product in both stores
- [ ] Enable iOS In-App Purchase capability
- [ ] Test ads and purchases using store test accounts
- [ ] Upload the signed AAB to Google Play internal testing

---

## Next Version Template

### v_._._+_ (Release name)
**Date:**  
**Track:**  

**Changes:**
- 

---

## Notes

- The version is defined in `pubspec.yaml`.
- Keep the Android upload keystore and its credentials securely backed up.
