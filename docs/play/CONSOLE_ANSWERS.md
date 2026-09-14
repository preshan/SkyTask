# Google Play Console answers for SkyTask

Copy/paste helpers for App content, Data safety, and permission declarations.

---

## Store listing

**App name:** SkyTask

**Short description:**
```
Plan tasks, reminders, ideas & notes with voice memos and calendar sync.
```

**Full description:**
```
SkyTask helps you capture work and life in one place.

• Tasks with priorities, categories, due dates, and Day Plan times
• Reminders with local notifications and optional device calendar sync
• Ideas and notes, including private items protected by app lock
• Voice memos you can record, play, pause, and seek
• Local-first storage with optional backup export/import
• Light and dark themes

Your content stays on your device by default. Optional features such as Google Sign-In, Firebase, and calendar sync only run when you choose to use them.
```

**Privacy Policy URL (after GitHub Pages is enabled on /docs):**
```
https://preshan.github.io/SkyTask/privacy.html
```

**Icon for Play:** `docs/play/icon_512.png` (512×512)

---

## App content questionnaire

| Question | Answer now |
|----------|------------|
| Ads | **No** |
| In-app purchases | No (unless you add them) |
| News app | No |
| COVID-19 contact tracing / status | No |
| Data safety form completed | Yes (fill using section below) |

---

## Data safety (suggested)

- **Collects / shares user data:** Yes (limited; mostly on-device; optional account/calendar)
- **Encrypted in transit:** Yes (for network features)
- **Users can request deletion:** Yes (in-app delete / clear data / uninstall)
- **Data sold:** No
- **Data used for ads:** No

### Data types
- User-generated content (tasks, reminders, ideas, notes) — on device
- Audio (voice memos) — on device; microphone to create
- Calendar — only if sync enabled
- Account / personal info — only if user signs in (Firebase / Google)
- App info / diagnostics — platform level possible; no separate analytics SDK

---

## Microphone declaration

```
SkyTask requests the Microphone permission so users can attach voice memos to their own tasks, reminders, ideas, or notes. Audio is stored in app-private storage on the device unless the user exports a backup. It is not used for advertising or always-on listening.
```

---

## Calendar declaration

```
Calendar permission is used only when the user enables Calendar sync in Settings, to create or update reminder events on a writable calendar they select (including Google Calendar when available). It is not used to sell data or show ads.
```

---

## Exact alarm declaration

```
SkyTask is a reminder and task app. Exact alarms are required so reminder notifications are delivered at the time set by the user, including after device reboot when permitted by the system. Alarms are not used for ads or unrelated background work.
```

---

## Enable Privacy Policy URL (You · GitHub)

1. GitHub repo **SkyTask** → Settings → Pages
2. Source: Deploy from branch **main**, folder **/docs**
3. Wait a minute, open `https://preshan.github.io/SkyTask/privacy.html`
4. Paste that URL into Play Console → App content → Privacy policy
