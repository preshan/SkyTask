# SkyTask

Premium productivity app combining Tasks, Reminders, Ideas, Notes, Calendar Integration, Privacy Lock, and Cloud Sync.

Inspired by Google Tasks, Google Calendar, TickTick, Todoist, and Notion Quick Notes.

## Author

**Owner & Developer:** Preshan Pradeepa Kariyawasam

## Architecture

```
lib/
├── main.dart
├── app.dart
├── firebase_options.dart
├── core/
│   ├── constants/       # Brand colors, app keys
│   ├── database/        # Isar collections
│   ├── di/              # Riverpod providers
│   ├── router/          # go_router
│   ├── services/        # Isar, notifications, alarms, background
│   └── theme/           # Material 3 navy theme
├── features/
│   ├── auth/            # Firebase Auth (Google, Email, Anonymous)
│   ├── home/            # Dashboard
│   ├── tasks/           # CRUD, search, filters, archive, pin
│   ├── reminders/       # Offline-first reminder engine
│   ├── ideas/           # Quick capture
│   ├── notes/           # Long-form notes + voice
│   ├── calendar/        # Device calendar (Phase 1)
│   ├── privacy/         # Biometric app lock + private vault
│   ├── settings/
│   ├── splash/
│   └── onboarding/
└── shared/
    └── widgets/         # GoldCheckbox, SkyIcon, voice, PrivateContentGate
```

**Clean Architecture** per feature: `data/` → `domain/` → `presentation/`

## Reminder Engine (Critical)

Reminders are **never Firebase-only**. Flow:

1. Save to Isar (local)
2. Schedule `flutter_local_notifications` (zoned, exact)
3. Schedule `AlarmManager` exact alarm
4. Optionally create device calendar event
5. Store `notificationId` + `calendarEventId`

Survives: offline, app closed, app killed, device reboot (via boot receiver + WorkManager).

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter (latest stable) |
| State | Riverpod |
| Local DB | Isar |
| Auth | Firebase Auth |
| Cloud | Firestore (Sprint 7) |
| Push | FCM |
| Local alerts | flutter_local_notifications + AlarmManager |
| Background | WorkManager |
| Calendar | device_calendar (Phase 1) |
| Security | local_auth + flutter_secure_storage + AES private fields |
| Voice | record + audioplayers |
| Icons | hugeicons |

## Brand

| Token | Color |
|-------|-------|
| Primary (light) | `#000080` |
| Primary (dark) | `#6EC6FF` |
| Secondary (amber) | `#F59E0B` |
| Secondary (dark) | `#FBBF24` |
| Background | `#F4F6F9` |
| Gold Accent | `#F4C542` |
| Completed Gold | `#D4AF37` |

## Release

See [CHANGELOG.md](CHANGELOG.md) and [docs/release/RELEASE_NOTES.md](docs/release/RELEASE_NOTES.md) for v1.1.0 notes, screenshots, and diagrams.

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.2
- Android Studio
- Firebase project (for auth/sync)

### Setup

```bash
# Install dependencies
flutter pub get

# Generate Isar schemas (required)
dart run build_runner build --delete-conflicting-outputs

# Configure Firebase
dart pub global activate flutterfire_cli
flutterfire configure

# Add google-services.json to android/app/

# Run on Android
flutter run
```

## Development Roadmap

| Sprint | Focus |
|--------|-------|
| 1 | ✅ Flutter setup, theme, navigation, Isar |
| 2 | Tasks CRUD, search, filters |
| 3 | Reminder engine, notifications, AlarmManager |
| 4 | Device calendar integration |
| 5 | Ideas and Notes rich editor |
| 6 | Privacy lock, biometrics |
| 7 | Firebase Auth, Firestore sync |
| 8 | Animations, performance, polish |

## Phase 2 (Planned)

- Google Calendar API sync
- Google Drive backup
- AI task suggestions
- Voice assistant
- Home screen widgets

## Tests

```bash
flutter test
```

## CI/CD

Project is structured for CI with `flutter analyze`, `flutter test`, and `build_runner` codegen step.
