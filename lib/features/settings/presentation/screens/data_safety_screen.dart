import 'legal_doc_screen.dart';

/// In-app Data safety + permissions notes (copy for Play Console too).
class DataSafetyScreen extends LegalDocScreen {
  const DataSafetyScreen({super.key})
      : super(
          title: 'Data safety & permissions',
          sections: const [
            LegalSection(
              body:
                  'Use this page as a guide when filling Google Play Data safety '
                  'and permission declarations. Answers below match the current '
                  'SkyTask code.',
            ),
            LegalSection(
              heading: 'Data safety (Play Console) — overview',
              body:
                  '• Does the app collect personal data? Yes, limited and mostly '
                  'on-device / optional.\n'
                  '• Is data encrypted in transit? Yes for network features '
                  '(HTTPS / Google & Firebase SDKs).\n'
                  '• Can users request deletion? Yes: delete items in-app, clear '
                  'app data, or uninstall. Exported backups you saved elsewhere '
                  'must be deleted by you.\n'
                  '• Data sold? No.\n'
                  '• Data used for ads today? No.\n'
                  '• Future ads possible? Yes; disclose before shipping ads.',
            ),
            LegalSection(
              heading: 'Data types to declare',
              body:
                  '• App activity / user-generated content: tasks, reminders, '
                  'ideas, notes (on device).\n'
                  '• Audio files: voice memos (on device; mic required to create).\n'
                  '• Calendar events: only if calendar sync is enabled.\n'
                  '• Personal info / account: only if the user signs in with '
                  'Google / Firebase (optional).\n'
                  '• App info & performance: standard platform crash signals '
                  'possible; no separate analytics SDK today.\n'
                  '• Device IDs: may be used by Firebase / Google Play services '
                  'when those optional features run.',
            ),
            LegalSection(
              heading: 'Microphone (sensitive permission)',
              body:
                  'Purpose: record voice memos for tasks, reminders, ideas, and '
                  'notes.\n\n'
                  'User benefit: capture spoken notes without typing.\n\n'
                  'Not used for: calls, always-on listening, or advertising.\n\n'
                  'Console note example: “SkyTask requests the Microphone '
                  'permission solely so users can attach voice memos to their '
                  'own tasks, reminders, ideas, or notes. Audio is stored in '
                  'app-private storage on the device unless the user exports a '
                  'backup.”',
            ),
            LegalSection(
              heading: 'Calendar (sensitive permission)',
              body:
                  'Purpose: optional sync of SkyTask reminders to a writable '
                  'device calendar (including Google Calendar).\n\n'
                  'User benefit: see reminders alongside other events.\n\n'
                  'Not used for: reading unrelated calendars for ads or '
                  'resale.\n\n'
                  'Console note example: “Calendar permission is used only when '
                  'the user enables Calendar sync in Settings, to create or '
                  'update reminder events on a calendar they select.”',
            ),
            LegalSection(
              heading: 'Exact alarm declaration / justification',
              body:
                  'Permission: SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM.\n\n'
                  'Core function: time-sensitive reminder notifications must fire '
                  'at the user-chosen time.\n\n'
                  'Why exact (not inexact): productivity reminders are '
                  'time-critical; delayed delivery would break the feature.\n\n'
                  'Console declaration example: “SkyTask is a reminder and task '
                  'app. Exact alarms are required so reminder notifications are '
                  'delivered at the precise time set by the user, including '
                  'after device reboot when permitted by the system. Alarms are '
                  'not used for ads or unrelated background work.”',
            ),
            LegalSection(
              heading: 'Notifications',
              body:
                  'POST_NOTIFICATIONS is used to show reminder alerts the user '
                  'scheduled. Users can disable notifications in system '
                  'Settings.',
            ),
            LegalSection(
              heading: 'Account / Firebase',
              body:
                  'Optional. When used: Firebase Auth, Google Sign-In, Firestore, '
                  'and Firebase Cloud Messaging may process account identifiers '
                  'and tokens to provide signed-in / sync / messaging features. '
                  'If you are not shipping those features yet, say account data '
                  'is optional / not collected until the user signs in.',
            ),
            LegalSection(
              heading: 'App content — Ads',
              body:
                  'Current answer: No, the app does not contain ads.\n\n'
                  'If you add AdMob later: change to Yes, update Data safety, '
                  'and update the Privacy Policy before releasing that build.',
            ),
          ],
        );
}
