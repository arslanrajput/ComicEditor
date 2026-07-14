# Google Play Console — complete step-by-step checklist (Inkwell)

Use this document in order. Check off each step in Play Console before uploading to Production.

---

## Phase A — Build the release (on your PC)

### A1. Release signing

Edit `android/key.properties` with real keystore passwords:

```properties
storePassword=your_real_password
keyPassword=your_real_password
keyAlias=upload
storeFile=../key/comicEditor_app-keystore.jks
```

### A2. Build App Bundle

```powershell
cd C:\ComicEditorCode\comic_editor3
flutter clean
flutter pub get
flutter build appbundle --release
```

Confirm: **no** `WARNING: Release signing not configured` in output.

**File to upload:** `build\app\outputs\bundle\release\app-release.aab`

### A3. Keep handy

| Field | Value |
|-------|--------|
| App name | Inkwell |
| App type | Comic editor |
| Package name | `com.comic.comic_editor` |
| Version name | 1.0.0 |
| Version code | 1 |
| Support email | devplussystems@gmail.com |
| Privacy policy | https://www.usdriverguide.com/privacy-policy-inkwell/ |
| App icon | `assets/branding/app_icon.png` |

---

## Phase B — Create the app in Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **Create app**
3. Fill in:
   - **App name:** Inkwell
   - **Default language:** English (United States)
   - **App or game:** App
   - **Free or paid:** Free
4. Declarations — check all that apply, then **Create app**

---

## Phase C — Dashboard: complete every required task

Play Console shows a checklist on the app **Dashboard**. Complete sections below in any order, but all must be green before Production release.

---

### C1. Set up your app → App access

**Path:** Policy → App content → **App access**

- Select: **All functionality is available without special access**
- Inkwell has no login, invite codes, or paywalls
- Click **Save**

---

### C2. Set up your app → Ads

**Path:** Policy → App content → **Ads**

- Select: **No, my app does not contain ads**
- Click **Save**

---

### C3. Set up your app → Content ratings

**Path:** Policy → App content → **Content ratings** → Start questionnaire

Use email: **devplussystems@gmail.com**

Suggested answers for Inkwell (adjust if your build differs):

| Question area | Suggested answer | Notes |
|---------------|------------------|-------|
| Category | Utility, Productivity, Communication, or **Other** | Choose closest; **Art & Design** may appear under app type |
| Violence | **No** or **Mild** | User-created comics could include cartoon content; be honest |
| Sexuality | **No** | |
| Language | **No** or **Infrequent/Mild** | User-written text in comics |
| Controlled substances | **No** | |
| User interaction | **No** | No chat, forums, or social feed |
| Shares location | **No** | |
| Shares personal info | **No** | |
| User-generated content | **Yes** | Users create comics, text, images |
| Online content | **No** or **Yes** (if Google Fonts counts) | Optional network for fonts only |
| Gambling | **No** | |
| Purchases | **No** | No in-app purchases |

Submit → wait for rating (often **Everyone**, **Teen**, or **PEGI 3/12** depending on UGC answers).

---

### C4. Set up your app → Target audience and content

**Path:** Policy → App content → **Target audience and content**

1. **Target age groups:** Select **13 and over** only (matches privacy policy: not directed at under-13)
   - Do **not** select under-13 unless you implement Families policy requirements
2. **Appeal to children:** **No** (or only 13+ if asked separately)
3. **Store presence for families:** **No** (unless you intentionally target kids)
4. Click **Save** → **Next** → **Submit**

---

### C5. Set up your app → Privacy policy

**Path:** Policy → App content → **Privacy policy**

Paste:

```
https://www.usdriverguide.com/privacy-policy-inkwell/
```

Click **Save**

---

### C6. Set up your app → Data safety

**Path:** Policy → App content → **Data safety** → Start

#### Step 1 — Data collection and security

| Question | Answer |
|----------|--------|
| Does your app collect or share any of the required user data types? | **No** |

Inkwell does not transmit user comics, photos, or profile data to developer servers. All projects stay on the device.

> **Note:** Google Fonts may download font files over the internet (handled by Google’s servers, not stored by you). If Play Console forces a follow-up about third-party SDKs, add under **Data types** only what the form requires — do not over-declare data you never access.

| Question | Answer |
|----------|--------|
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS for font downloads) — or N/A if you answered No collection |
| Do you provide a way for users to request that their data is deleted? | **Yes** — users delete projects in-app, clear app storage, or uninstall |

**Deletion instructions** (paste in the form if asked):

```
Users can delete all Inkwell data by removing projects and characters in the app, or by uninstalling the app. Exported backup files are controlled by the user on their device.
```

#### Step 2 — Data types

If you answered **No** to collection, skip adding data types.

If Play requires declaring permissions-only data, use:

| Data type | Collected? | Shared? | Purpose | On device only? |
|-----------|------------|---------|---------|-----------------|
| Photos and videos | No* | No | — | Stored locally if user imports; not sent to developer |

\*Only declare **Yes** if the form treats on-device user content as “collected.” If unsure, prefer **No** with explanation that data never leaves the device to the developer.

#### Step 3 — Preview and submit

Review summary → **Submit**

---

### C7. Set up your app → Government apps

**Path:** Policy → App content → **Government apps**

- **No**, Inkwell is not a government app → **Save**

---

### C8. Set up your app → Financial features

**Path:** Policy → App content → **Financial features**

- **My app doesn't provide any financial features** → **Save**

---

### C9. Set up your app → Health

**Path:** Policy → App content → **Health** (if shown)

- **My app is not a health app** → **Save**

---

### C10. Set up your app → News apps

**Path:** Policy → App content → **News apps**

- **No**, Inkwell is not a news app → **Save**

---

### C11. Store settings → App category

**Path:** Grow → Store presence → **Store settings** → App category

| Field | Value |
|-------|--------|
| App or game | App |
| Category | **Comics** (preferred) or **Art & Design** |
| Tags | comic editor, comics, manga, webtoon, panels, drawing |

Save.

---

### C12. Main store listing

**Path:** Grow → Store presence → **Main store listing**

#### Text (copy from `docs/PLAY_STORE_LISTING.md`)

**App name:** Inkwell

**Short description** (max 80 characters):

```
Inkwell — comic editor. Layout panels, draw, add text, export PDF.
```

**Full description:**

```
Inkwell is a comic editor for Android — create full comic pages on your device with no account required.

Edit comics your way
• Layout templates for manga, webtoon, and comic strip pages
• Panel editor: text, speech bubbles, photos, and drawing tools
• Drag-and-resize panels and preview every page before you share

Built for comic creators
• Automatic save — projects stay on this device
• Character Studio, story editor, and PDF export
• Import images and back up projects as JSON

Privacy first
• No sign-up and no cloud upload of your comics
• Your pages and artwork remain on your phone or tablet
```

**Contact details:**

- Email: devplussystems@gmail.com
- Website: optional (privacy policy URL is enough)

#### Graphics

| Asset | Spec | Source |
|-------|------|--------|
| App icon | 512×512 PNG (Play uploads 1024 internally) | `assets/branding/app_icon.png` — resize if needed |
| Feature graphic | 1024×500 PNG or JPG | Create marketing banner with Inkwell logo |
| Phone screenshots | Min **2**, max 8; 16:9 or 9:16 | Capture on device or emulator |

**Suggested screenshots:**

1. Home tab — “Continue Creating”
2. Templates screen
3. Layout editor with template applied
4. Panel editor with speech bubble
5. Export / PDF share sheet

**Save** listing.

---

### C13. Store settings → Countries / regions

**Path:** Release → **Countries / regions**

- Select countries where you want Inkwell published (e.g. **United States** + others)
- **Save**

---

### C14. Release → App integrity (recommended)

**Path:** Release → **App integrity**

1. **Play App Signing:** Enroll when prompted (Google manages the app signing key; you keep upload key)
2. **App signing key:** Upload key = your `comicEditor_app-keystore.jks`
3. Optional: enable Play Integrity API later

---

### C15. Release → Create production release

**Path:** Release → **Production** → **Create new release**

1. **Upload** `app-release.aab`
2. Wait for processing (check for 16 KB page size or signing errors)
3. **Release name:** `1.0.0 (1)`
4. **Release notes** (English):

```
Initial release of Inkwell — your comic editor on Android.

• Comic layout templates (manga, webtoon, strip)
• Panel editor with text, speech bubbles, and drawing
• Character Studio and story editor
• PDF export and local project backup
• No account required — your work stays on your device
```

5. **Review release** → fix any errors
6. **Save** → **Next**

---

### C16. Pricing and distribution

**Path:** Monetize → **Products** / app pricing (or during setup)

- **Free**
- Confirm distribution agreements and US export compliance (standard consumer app → usually **No** for encryption restrictions if using standard HTTPS only)

---

### C17. Final review and rollout

1. Return to **Dashboard** — all setup tasks should show complete
2. Open **Production** release → **Send for review** / **Start rollout to Production**
3. Google review typically takes **1–7 days** (first app may take longer)

---

## Phase D — Optional but recommended before Production

### Internal testing track

**Path:** Release → **Testing** → **Internal testing** → Create release

1. Upload same AAB
2. Add tester email addresses
3. Install via Play Store link and smoke-test:
   - Create project
   - Add panel content
   - Export PDF
   - Privacy policy link in Settings

### Pre-launch report

**Path:** Release → **Pre-launch report** (if available)

- Review automated crash / compatibility findings on Firebase test devices

---

## Phase E — After approval

- [ ] Confirm store listing is live
- [ ] Test install from Play Store on a real device
- [ ] Back up `key/comicEditor_app-keystore.jks` and passwords offline
- [ ] For updates: bump `pubspec.yaml` to `1.0.1+2`, rebuild AAB, new Production release

---

## Quick reference — permissions (for review / Data safety)

Declared in `AndroidManifest.xml`:

| Permission | Why |
|------------|-----|
| INTERNET | Google Fonts downloads |
| CAMERA | Optional photo for panels / character portraits |

Photos/gallery access is requested at runtime via `image_picker` (not a manifest permission on modern Android).

---

## Troubleshooting

| Play Console message | Fix |
|---------------------|-----|
| Upload certificate mismatch | Use same upload keystore as first upload |
| Debug certificate | Fix `android/key.properties`, rebuild |
| 16 KB page size | Rebuild on current project (already configured) |
| Privacy policy invalid | URL must be public HTTPS — already live |
| Target API level | Update Flutter SDK and rebuild |
| Missing content rating | Complete C3 |
| Data safety incomplete | Complete C6 |

---

## Related docs

- Listing copy: `docs/PLAY_STORE_LISTING.md`
- Keystore: `docs/KEYSTORE_SETUP.md`
- General publish: `docs/PUBLISHING.md`
- Privacy policy text: `docs/PRIVACY_POLICY.md`
