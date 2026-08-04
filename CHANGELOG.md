# Changelog

Notable changes to SkyTask. Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [1.3.0] — 2026-08-04

### Added
- Android launcher shortcuts for New Task / Reminder / Idea (long-press app icon)

### Fixed
- PIN confirm step stuck after create (pad state reused)
- Backspace icon facing the wrong way on the PIN pad
- App lock switch not updating in Settings
- Overdue reminders skipped on reboot reschedule
- Turning off app lock no longer possible without re-auth
- Stronger PIN storage (salted PBKDF2; upgrades legacy hashes on unlock)
- Privacy setup errors surface instead of spinning forever
- More stable notification / alarm ids

### Changed
- Removed non-functional Private vault toggle from Settings

## [1.2.0] — 2026-08-03

### Added
- Day / night sky background and frosted panels on the main shell and home
- Count badges on home shortcuts (pinned, pending, private ideas, private reminders)

### Changed
- Today section shows tasks and reminders due today (incomplete only)
- Week strip is a rolling next 7 days (“Recent reminders”)
- Settings About layout: app icon and credits, no section title
- Better contrast for text and PIN entry in dark mode

### Fixed
- PIN pad hard to read in dark mode
- Shortcut tile alignment and badge placement

## [1.1.3] — 2026-08-03

### Fixed
- Release builds crashing when scheduling a reminder (R8 / Gson `TypeToken` with local notifications)

## [1.1.2] — 2026-08-03

### Added
- Home shortcuts for pinned tasks, pending tasks, private ideas, private reminders
- Amber accent for badges and highlights
- Hugeicons used across the UI (`SkyIcon`)

### Changed
- Today tiles and week reminder boxes on home
- About section credits layout
- Calendar Agenda / Week / Month selected state contrast

### Fixed
- Voice forms no longer autofocus description when voice is the usual input

## [1.1.1] — 2026-08-03

### Added
- Custom task categories (Work / Personal by default)
- Live version string and developer credits in Settings → About

### Changed
- Dark theme brand accent uses sky blue for contrast (navy kept in light mode)

## [1.1.0] — 2026-08-02

### Added
- Create button in the bottom bar (task, reminder, idea, note)
- Voice memos on tasks, reminders, ideas, and notes
- AES-256 encryption for private text fields at rest
- Shared form patterns: autofocus description, private toggle, pin / due icons

### Changed
- Brand primary navy `#000080`
- Private notifications hide real titles; private items skip calendar sync

### Fixed
- Checkbox unchecked styling
- Voice file only deleted after a successful save
- Can’t dismiss a sheet while recording (stops recording first)
- Settings back uses previous route when possible
- Legacy “Untitled …” voice titles no longer rewritten on every edit

### Known limitations
- Private voice `.m4a` files are not encrypted on disk (text is)
- Private note attachment paths are not encrypted
