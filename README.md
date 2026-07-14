# Inkwell

Comic editor for your device — layout panels, draw, add speech bubbles, and export PDF. No account required; projects are saved locally.

## Features

- **Home dashboard** — resume projects, quick actions, trending templates
- **Layout editor** — templates, drag/resize panels, multi-page comics
- **Panel editor** — draw, text, speech bubbles, images, clipart
- **Character Studio** — build cast for your stories
- **Story editor** — script beats linked to panels
- **Export** — PDF, PNG pages, project backup JSON

## Getting started

```bash
flutter pub get
flutter run
```

## Release builds

See **[docs/PUBLISHING.md](docs/PUBLISHING.md)** for signing, store listings, and privacy policy hosting.

```bash
flutter build appbundle --release   # Google Play
flutter build ipa --release         # App Store (macOS)
```

## Configuration before publish

Update `lib/config/app_info.dart`:

- `supportEmail`
- `privacyPolicyUrl`

## Project structure

| Path | Purpose |
|------|---------|
| `lib/ProjectsListScreen.dart` | Main shell & navigation |
| `lib/PanelLayoutEditorScreen.dart` | Page/panel layout |
| `lib/PanelEditScreen.dart` | Panel content editor |
| `lib/screens/` | Home, templates, wizard, profile |
| `assets/` | Icons, templates, characters, clipart |

## Tests

```bash
flutter test
flutter analyze
```

## License

Proprietary — all rights reserved unless otherwise noted.
