# Changelog

All notable changes to SkyTask are documented in this file.

## [1.2.0] — 2026-08-03

### Added
- **Sky glass theme:** day/night atmosphere gradients with frosted glass surfaces across the shell and home
- Home shortcut live count badges (pinned, pending, private ideas, private reminders)

### Changed
- Today tiles focus on **Tasks + Reminders** due today (incomplete)
- “This week” becomes **Recent reminders** — today plus the next 6 days
- Settings About: centered credits with app icon; section header removed
- Dark-mode text contrast on sky backgrounds, PIN setup, lock screen, and onboarding

### Fixed
- PIN keypad and copy readable in dark mode (theme-aware colors)
- Shortcut tile alignment and badge layout

## [1.1.0] — 2026-08-02

### Added
- Inline **Create** action in the bottom navigation (Task / Reminder / Idea / Note sheet)
- **Voice memos** on tasks, reminders, ideas, and notes (record, play, clear)
- Voice-aware titles: empty/placeholder titles become a date/time label when a memo is attached
- **AES-256 encryption** for private item text fields at rest (`PrivateCryptoService`)
- Shared form UX: autofocus description, private eye-toggle, icon toggles for pin/due
- Hugeicons-based `SkyIcon` system across navigation and actions

### Changed
- Brand primary color to navy `#000080` (secondary `#191970`)
- Tasks screen: reliable check/uncheck + horizontal category filter chips
- Private notifications show “Private reminder” without leaking title/body
- Private items skip device calendar sync; calendar tiles use `PrivateContentGate`
- App version bumped to `1.1.0+2`

### Fixed
- Gold checkbox unchecked state no longer fades incorrectly
- Voice file deletion runs only after a successful save
- Dismiss-while-recording blocked until recording is stopped (`PopScope`)
- Settings back returns to the previous route when possible
- Editing legacy “Untitled …” voice items no longer rewrites titles on every save

### Known limitations
- Private **voice `.m4a` files** are not encrypted on disk (text fields are)
- Private note **attachment paths** are not encrypted
- Emulator may show Android 16 KB page-size compatibility warnings (Isar/Flutter native libs)

See full notes and diagrams: [`docs/release/RELEASE_NOTES.md`](docs/release/RELEASE_NOTES.md)
