# SkyTask 1.1.0 — Release Notes

**Released:** 2026-08-02 · **Version:** `1.1.0+2`

SkyTask 1.1 focuses on faster capture (inline Create + voice memos), a navy brand refresh, and encrypting private text at rest.

## Highlights

- **Inline Create** in the bottom bar — no floating FAB
- **Voice memos** on every item type, with play controls on lists
- **Private text encryption** (AES-256-CBC) with secure key storage
- **Navy brand** (`#000080`) and Hugeicons throughout

## Screenshots

| Home | Tasks | Create |
|:----:|:-----:|:------:|
| ![Home](https://raw.githubusercontent.com/preshan/SkyTask/main/docs/release/screenshots/01_home.png) | ![Tasks](https://raw.githubusercontent.com/preshan/SkyTask/main/docs/release/screenshots/02_tasks.png) | ![Create](https://raw.githubusercontent.com/preshan/SkyTask/main/docs/release/screenshots/03_create_menu.png) |

| Calendar | Ideas |
|:--------:|:-----:|
| ![Calendar](https://raw.githubusercontent.com/preshan/SkyTask/main/docs/release/screenshots/04_calendar.png) | ![Ideas](https://raw.githubusercontent.com/preshan/SkyTask/main/docs/release/screenshots/05_ideas.png) |

> Captured on Android emulator (`emulator-5554`). Browser automation is not used for the Flutter UI; screenshots were taken via `adb screencap`.

## Architecture diagrams

### Navigation shell

```mermaid
flowchart LR
  subgraph BottomNav["App shell"]
    H[Home]
    T[Tasks]
    C[Create]
    Cal[Calendar]
    I[Ideas]
  end

  C --> Sheet{Create sheet}
  Sheet --> Task[New Task]
  Sheet --> Rem[New Reminder]
  Sheet --> Idea[New Idea]
  Sheet --> Note[New Note]
```

### Reminder pipeline

```mermaid
sequenceDiagram
  participant UI as Form sheet
  participant Repo as Reminder repository
  participant Isar as Isar DB
  participant Notif as NotificationService
  participant Alarm as AlarmManager
  participant Cal as Device calendar

  UI->>Repo: save reminder
  Repo->>Isar: persist (encrypt if private)
  Repo->>Notif: schedule / show
  Repo->>Alarm: exact alarm
  alt not private and not voice-only skip
    Repo->>Cal: optional calendar event
  else private
    Note over Cal: calendar sync skipped
  end
```

### Private content encryption

```mermaid
flowchart TD
  A[User marks item private] --> B[Mapper toIsar]
  B --> C{isPrivate?}
  C -->|yes| D[PrivateCryptoService.encrypt]
  D --> E["Store enc:v1:… in Isar"]
  C -->|no| F[Store plaintext]
  E --> G[Read path]
  F --> G
  G --> H[Mapper fromIsar]
  H --> I{enc:v1: prefix?}
  I -->|yes| J[decrypt with AES key from SecureStorage]
  I -->|no| K[return as-is]
  J --> L[UI / PrivateContentGate]
  K --> L
```

### Voice memo lifecycle

```mermaid
stateDiagram-v2
  [*] --> Idle
  Idle --> Recording: tap mic
  Recording --> Idle: stop / PopScope finalize
  Idle --> Ready: file saved
  Ready --> Playing: play
  Playing --> Ready: pause / complete
  Ready --> Idle: clear
  note right of Recording
    First back/dismiss stops
    recording instead of closing
  end note
```

## What’s new (detail)

### Capture & navigation
- Bottom nav: Home · Tasks · **Create** · Calendar · Ideas
- Create opens a sheet for Task / Reminder / Idea / Note
- Forms: description autofocus, category/priority chips, private eye-toggle, voice row

### Voice
- AAC `.m4a` memos via `record` + `audioplayers`
- Empty titles become `MMM d, yyyy · h:mm a`
- Play buttons on home, calendar, and ideas lists

### Privacy & security
- `PrivateCryptoService`: AES-256-CBC, key in `FlutterSecureStorage`
- Encrypted fields: titles, descriptions/content, tags (when private)
- Notifications for private reminders never show the real title
- Calendar sync skipped for private items; agenda tiles gated

### Brand
- Primary `#000080`, secondary `#191970`, background `#F4F6F9`

## Known limitations

| Area | Limitation |
|------|------------|
| Voice | Private voice files remain plaintext on disk |
| Notes | Attachment path strings are not encrypted when private |
| Android 16 KB | Emulator may warn about native lib alignment (Isar/Flutter) |

## Upgrade notes

1. Update to `1.1.0+2` and run a normal install/upgrade.
2. Existing private items are encrypted on the next write through mappers.
3. Grant microphone permission to use voice memos.

## Code review (pre-release)

Bugbot reviewed uncommitted changes before this release. Findings addressed in-tree:

| Severity | Finding | Action |
|----------|---------|--------|
| High | Cleartext private voice on disk | Documented limitation (v1.2 candidate) |
| High | Recording lost on sheet dismiss | `PopScope` + safe teardown |
| Medium | Voice title rewritten on edit | Use `createdAt` when regenerating |
| Low | Settings back always → home | Prefer `context.pop()` |

Remaining medium items (duplicate past-due notification paths; note attachments) tracked for follow-up.
