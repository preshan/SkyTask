import 'legal_doc_screen.dart';

/// In-app Privacy Policy (also mirrored at docs/privacy.html for Play Console).
class PrivacyPolicyScreen extends LegalDocScreen {
  const PrivacyPolicyScreen({super.key})
      : super(
          title: 'Privacy Policy',
          sections: const [
            LegalSection(
              body:
                  'Last updated: 14 September 2026\n\n'
                  'SkyTask (“we”, “our”, or “the app”) is developed by '
                  'Preshan Pradeepa Kariyawasam. This Privacy Policy explains '
                  'what information SkyTask processes, why, and your choices. '
                  'It is intended to meet Google Play disclosure expectations.',
            ),
            LegalSection(
              heading: '1. Summary',
              body:
                  'SkyTask is local-first. Tasks, reminders, ideas, notes, and '
                  'voice memos are stored on your device by default.\n\n'
                  'Optional features (calendar sync, Google Sign-In / Firebase, '
                  'cloud messaging, backups you export) process additional data '
                  'only when you use them.\n\n'
                  'We do not sell your personal information.',
            ),
            LegalSection(
              heading: '2. Information the app processes',
              body:
                  '• App content you create: titles, descriptions, categories, '
                  'due dates/times, completion status, and similar fields.\n'
                  '• Voice memos: audio files you record, stored in app private '
                  'storage on your device.\n'
                  '• Reminders & notifications: reminder times and notification '
                  'settings so alerts can fire on time.\n'
                  '• Calendar data (optional): if you enable calendar sync, the '
                  'app reads and writes calendar events on your device calendars '
                  '(including Google Calendar when that account is available).\n'
                  '• Security: PIN / biometric unlock preferences for app lock '
                  'and private items (credentials stay on device).\n'
                  '• Backups (optional): if you export a backup, a file you '
                  'choose may include your app content. Password-protected '
                  'exports stay under your control.\n'
                  '• Account / Firebase (optional): if you sign in, identifiers '
                  'such as account email and auth tokens may be processed by '
                  'Firebase Auth / Google Sign-In / Firestore / FCM as needed '
                  'for that feature.\n'
                  '• Diagnostics: standard Android / Play crash or performance '
                  'signals may be processed by the platform; the app does not '
                  'currently include a separate third-party analytics SDK.',
            ),
            LegalSection(
              heading: '3. Permissions and why we ask',
              body:
                  '• Microphone: record voice memos attached to tasks, '
                  'reminders, ideas, or notes.\n'
                  '• Notifications: show reminder alerts.\n'
                  '• Exact alarms / schedule exact alarm: fire reminders at '
                  'the time you chose, including after reboot where allowed.\n'
                  '• Calendar (read & write): optional sync of reminders to a '
                  'device / Google calendar you select.\n'
                  '• Biometric / fingerprint: optional app unlock.\n'
                  '• Storage (legacy Android versions only): limited access to '
                  'pick/save backup files where the system folder picker is not '
                  'used.\n'
                  '• Internet: optional cloud / auth / messaging features and '
                  'opening links (website, email, LinkedIn).',
            ),
            LegalSection(
              heading: '4. How we use information',
              body:
                  'We use data only to provide SkyTask features you request: '
                  'organizing content, reminding you on time, syncing to a '
                  'calendar you enable, securing private content, and restoring '
                  'backups you import.\n\n'
                  'We do not use your content for advertising profiling today.',
            ),
            LegalSection(
              heading: '5. Advertising (current and future)',
              body:
                  'SkyTask does not show ads in the current release.\n\n'
                  'Future versions may include ads (for example Google AdMob). '
                  'If ads are added, we will update this Privacy Policy and the '
                  'Google Play Data safety / App content answers before or when '
                  'that version ships, and disclose any additional data those '
                  'ad SDKs collect.',
            ),
            LegalSection(
              heading: '6. Sharing',
              body:
                  'We do not sell your data.\n\n'
                  'Data may be processed by service providers only when you use '
                  'related features, for example:\n'
                  '• Google / Android calendar provider (calendar sync)\n'
                  '• Google Sign-In / Firebase (optional account features)\n'
                  '• Google Play services on the device\n\n'
                  'You may also share backups or content yourself through the '
                  'Android share sheet or files you export.',
            ),
            LegalSection(
              heading: '7. Retention and deletion',
              body:
                  'Content remains on your device until you delete it, clear '
                  'app data, or uninstall the app.\n\n'
                  'Deleting an item removes it from local storage. Removing a '
                  'voice memo deletes that recording file (after confirmation).\n\n'
                  'Uninstalling SkyTask removes app-private data on the device. '
                  'Exported backup files you saved elsewhere are under your '
                  'control and are not deleted automatically.',
            ),
            LegalSection(
              heading: '8. Children’s privacy',
              body:
                  'SkyTask is not directed at children under 13 (or the minimum '
                  'age required in your country). We do not knowingly collect '
                  'personal information from children.',
            ),
            LegalSection(
              heading: '9. Security',
              body:
                  'We use platform security features such as app-private '
                  'storage, optional PIN / biometric lock, and optional '
                  'encryption for private content. No method is 100% secure.',
            ),
            LegalSection(
              heading: '10. Your choices',
              body:
                  '• Deny microphone, calendar, or notification permission in '
                  'system Settings (related features will not work).\n'
                  '• Turn calendar sync off in SkyTask Settings.\n'
                  '• Turn app lock off after verifying your identity.\n'
                  '• Export or delete your data from within the app.\n'
                  '• Contact us to ask privacy questions.',
            ),
            LegalSection(
              heading: '11. Contact',
              body:
                  'Developer: Preshan Pradeepa Kariyawasam\n'
                  'Email: preshanpradeepa@gmail.com\n'
                  'GitHub: https://github.com/preshan/SkyTask',
            ),
            LegalSection(
              heading: '12. Changes',
              body:
                  'We may update this policy when features or legal requirements '
                  'change. The “Last updated” date will change, and significant '
                  'updates will be reflected in the app and Play listing where '
                  'required.',
            ),
          ],
        );
}
