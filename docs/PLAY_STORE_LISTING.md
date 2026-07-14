# Play Store Listing — Inkwell

**Inkwell** is a **comic editor** app — layout pages, edit panels, draw, and export.

## App name
**Inkwell**

## Short description (80 chars max)
```
Inkwell — comic editor. Layout panels, draw, add text, export PDF.
```
(66 characters)

## Full description
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

## Play Console fields

| Field | Value |
|-------|--------|
| App name | Inkwell |
| Category | **Comics** (first choice) or **Art & Design** |
| Tags | See **Manage tags** below (max 5, predefined list only) |

## Manage tags (Play Console)

**Path:** Grow users → Store presence → **Store settings** → App category → **Manage tags**

Google allows **up to 5 tags** — you must pick from their **predefined list** (not free text). Tags affect discovery, similar apps, and peer groups.

### Recommended 5 tags for Inkwell

| Priority | Tag | Why |
|----------|-----|-----|
| 1 | **Comics** | Core purpose — comic page layout and editing |
| 2 | **Art & design** | Creation tool (panels, draw, templates, export) |
| 3 | **Painting** | In-panel drawing and art tools |
| 4 | **Productivity** | Story editor, project workflow, PDF export |
| 5 | **Photo editor** | Import/edit images in panels and character portraits |

### How to add them

1. Open **Manage tags**
2. Use **Search tags** and type each name above (e.g. `Comics`, `Art & design`)
3. Click each tag to add it (max 5)
4. **Save**

### Tags to avoid

Do **not** pick tags that don’t match the app — Google may penalize misleading tags:

| Skip | Reason |
|------|--------|
| Coloring book | Inkwell is not a coloring app |
| Games tags (e.g. Casual, Puzzle) | Inkwell is an **App**, not a game |
| Social / Dating | No social features |
| Children’s literature | Not a kids’ book reader |

### If a tag isn’t in the list

Use **Suggested tags** after setting category to **Comics**. Google’s list can vary slightly — pick the closest match from search results.

### Category + tags together

| Setting | Recommended |
|---------|-------------|
| App or game | **App** |
| Category | **Comics** |
| Tags | Comics, Art & design, Painting, Productivity, Photo editor |

Changes can take **up to 24 hours** to appear on the store listing.

## Privacy policy URL

**https://www.usdriverguide.com/privacy-policy-inkwell/**

Set in Play Console → App content → Privacy policy (also in `lib/config/app_info.dart`).

## Content rating
Likely **Everyone** or **Teen** (user-generated comic content). Complete the Play questionnaire honestly.

Declare: photos (user import), local storage, optional network (Google Fonts).

## Screenshots to capture
1. Home screen with Continue Creating
2. Templates browser
3. Layout editor with template applied
4. Panel editor with speech bubble
5. Export options / PDF share

## Release build
```bash
flutter build appbundle --release
```
Requires `android/key.properties` — see `docs/PUBLISHING.md`.
