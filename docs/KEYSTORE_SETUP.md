# Android keystore & release signing

## Quick setup (recommended)

From the project root in PowerShell:

```powershell
cd C:\ComicEditorCode\comic_editor3
.\scripts\setup-release-signing.ps1
flutter build appbundle --release
```

This script will:

1. Create `key/comicEditor_app-keystore.jks` (upload key)
2. Write `android/key.properties` with matching passwords
3. Save `key/SIGNING_CREDENTIALS.txt` — **back this up offline**

Upload to Play Console:

`build\app\outputs\bundle\release\app-release.aab`

## Manual setup

### Step 1 — Create the keystore

```powershell
.\scripts\generate-keystore.ps1
```

### Step 2 — Set `android/key.properties`

```properties
storePassword=your_real_keystore_password
keyPassword=your_real_key_password
keyAlias=upload
storeFile=../key/comicEditor_app-keystore.jks
```

### Step 3 — Build release

```powershell
flutter build appbundle --release
```

If signing is missing, the build **fails** (it will not fall back to debug signing).

## Play Console error: “signed in debug mode”

Cause: `android/key.properties` had placeholders or wrong passwords.

Fix: run `.\scripts\setup-release-signing.ps1`, rebuild, upload the **new** AAB.

## Security

- Never commit `key.properties`, `*.jks`, or `SIGNING_CREDENTIALS.txt`
- Back up `key/comicEditor_app-keystore.jks` and passwords — required for all future updates
