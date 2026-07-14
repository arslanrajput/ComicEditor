# Publishing Inkwell

Checklist before submitting to Google Play or the Apple App Store.

## 1. Update app metadata

Edit `lib/config/app_info.dart`:

- `supportEmail` — real support address (required by both stores)
- `privacyPolicyUrl` — public HTTPS URL to your hosted privacy policy

## 2. Privacy policy

Privacy policy is hosted and configured:

- **URL:** https://www.usdriverguide.com/privacy-policy-inkwell/
- **In-app:** `lib/config/app_info.dart` → `privacyPolicyUrl`
- **Play Console:** paste the same URL under App content → Privacy policy

Full Play upload steps: **`docs/PLAY_STORE_RELEASE.md`**
## 3. Android release signing

```bash
# Windows (recommended): run scripts/generate-keystore.ps1
# Or with full path to keytool:
# "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v ^
#   -keystore key/comicEditor_app-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

1. Copy `android/key.properties.example` → `android/key.properties`
2. Fill in passwords and `storeFile` path
3. **Never commit** `key.properties` or `*.jks`

Build:

```bash
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.

## 4. iOS release

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your Apple Developer team under Signing & Capabilities
3. Bundle ID: `com.comic.comic_editor`
4. Archive → Distribute to App Store Connect

```bash
flutter build ipa --release
```

## 5. Store assets

| Asset | Size |
|-------|------|
| App icon | 1024×1024 PNG (`assets/branding/app_icon.png`) |
| Feature graphic (Play) | 1024×500 |
| Screenshots | See `docs/PLAY_STORE_LISTING.md` |

## 6. Android 16 KB page size (Play requirement)

Google Play requires native libraries to support **16 KB memory page sizes** for apps targeting Android 15+.

This project is configured for compliance:

| Setting | Value |
|---------|--------|
| Android Gradle Plugin | 8.7.3 (`android/settings.gradle.kts`) |
| Gradle | 8.12 |
| NDK | r28 via `flutter.ndkVersion` (Flutter 3.41+) |
| JNI packaging | `useLegacyPackaging = false` (`android/app/build.gradle.kts`) |

After building the release bundle, confirm alignment in Play Console or locally:

```bash
flutter build appbundle --release
```

On a 16 KB emulator or device (`adb shell getconf PAGE_SIZE` → `16384`), install and smoke-test the app.

If Play Console still flags incompatible `.so` files, update the Flutter SDK and `pubspec.yaml` plugins to their latest versions, then rebuild.

## 7. Pre-flight checks

```bash
flutter analyze
flutter test
flutter build appbundle --release   # Android
flutter build ipa --release         # iOS (macOS + Xcode)
```

## 8. Version bumps

In `pubspec.yaml`:

```yaml
version: 1.0.1+2   # name+buildNumber
```

Android `versionCode` and iOS `CFBundleVersion` use the build number after `+`.

## Package IDs

| Platform | ID |
|----------|-----|
| Android | `com.comic.comic_editor` |
| iOS | `com.comic.comic_editor` |

## Developer accounts

- [Google Play Console](https://play.google.com/console) — one-time fee
- [Apple Developer Program](https://developer.apple.com/programs/) — annual fee
