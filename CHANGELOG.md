# Changelog

Notable changes to SkyTask. Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [1.8.0] — 2026-08-05

### Changed
- Create menu is a 2×2 grid with larger icons and short labels (Task, Reminder, Idea, Note)

## [1.7.2] — 2026-08-05

### Added
- Compact AppBar "+" on Tasks, Calendar, and Ideas & Notes to create the matching item

### Changed
- Calendar source/view filters use smaller chip tabs instead of large segmented buttons

## [1.7.1] — 2026-08-05

### Fixed
- List cards: remove decorative leading type icons; vertically center chevron and private lock

## [1.7.0] — 2026-08-05

### Added
- Soft pastel colors for categories (Work / Personal fixed; customs pick a random color you can change)
- Long-press a category chip to edit or delete; deleting reassigns items to another category first
- Colored category labels on task, idea, note, and calendar list rows

### Changed
- Denser list tiles (smaller title/subtitle text and tighter padding) so more items fit on screen

## [1.6.0] — 2026-08-05

### Added
- Categories on reminders, ideas, and notes (same Work / Personal / custom list as tasks)
- Shared category picker: add a category once, use it everywhere

### Fixed
- Calendar sync enable: require read + write permission and create a local SkyTask calendar more reliably when none are writable
- Clearer calendar sync copy when Google account calendars are not on the device yet

## [1.5.0] — 2026-08-05

### Added
- Calendar source tabs: SkyTask reminders vs all device calendars
- Local SkyTask calendar created when no writable calendar exists yet
- About / Settings credits link to the GitHub repo and developer profile

### Fixed
- Calendar sync enable when the device has no writable calendar accounts
- Write-only calendar permission requested on OEM paths that split access

## [1.4.1] — 2026-08-04

### Added
- Backup folder setting (pick Download / Documents before export)
- Unlock with fingerprint after PIN is set (Settings → Privacy); PIN remains as backup
- Automated tests for content CRUD, settings providers, and backup crypto

### Fixed
- Dialog crashes when typing PIN, backup password, or new category (controller dispose)
- App lock overlay no longer tears down the navigator mid-confirm
- Export no longer stacks progress on top of the password dialog
- Writing backups to system folders like Alarms (blocked by Android) — clear guidance + save fallback
- Removed Google Drive backup UI (needed extra OAuth setup that does not work out of the box)

### Changed
- Local export / import only; share sheet still available after save

## [1.4.0] — 2026-08-04

### Added
- Full-app backup export / import (`.skytaskbak`: gzip JSON, optional password)
- Settings → Data: Export and Import (share or save the file yourself)

### Notes
- Private item text is decrypted into the backup so it restores on another device; app PIN and device encryption keys are not exported
- Import can replace everything or merge by UUID

## [1.3.1] — 2026-08-04

### Fixed
- Calendar sync enable: clearer errors when permission is missing (was wrongly blaming a missing Google account)
- Request calendar access via `permission_handler` for Android 13+ reliability

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
