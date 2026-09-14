import 'legal_doc_screen.dart';

/// In-app Privacy Policy (mirrored at docs/privacy.html for the public URL).
class PrivacyPolicyScreen extends LegalDocScreen {
  const PrivacyPolicyScreen({super.key})
      : super(
          title: 'Privacy Policy',
          sections: const [
            LegalSection(
              body:
                  'Last updated: 14 September 2026\n\n'
                  'SkyTask is built by Preshan Pradeepa Kariyawasam. This page '
                  'describes what the app stores, what permissions it uses, and '
                  'how you stay in control.',
            ),
            LegalSection(
              heading: '1. The short version',
              body:
                  'SkyTask keeps your tasks, reminders, ideas, notes, and voice '
                  'memos on your phone by default.\n\n'
                  'Optional features such as calendar sync, Google Sign-In, '
                  'Firebase, or a backup you export only process extra data when '
                  'you use them.\n\n'
                  'We do not sell your personal information. SkyTask does not '
                  'show ads.',
            ),
            LegalSection(
              heading: '2. What the app stores',
              bullets: [
                'Content you create - titles, notes, categories, due dates and '
                    'times, completion status, and similar fields',
                'Voice memos - recordings you make, kept in the app private '
                    'storage',
                'Reminders - times and notification settings so alerts can fire '
                    'when you asked',
                'Calendar - only if you turn on calendar sync; the app can read '
                    'and write events on calendars you choose',
                'App lock - PIN or biometric preferences stay on the device',
                'Backups - only if you export one; the file you save is under '
                    'your control',
                'Account - only if you sign in; Google / Firebase may handle '
                    'email and auth tokens for that feature',
                'Diagnostics - Android or Play may record crash or performance '
                    'signals; SkyTask does not add a separate analytics SDK',
              ],
            ),
            LegalSection(
              heading: '3. Permissions',
              bullets: [
                'Microphone - voice memos on tasks, reminders, ideas, or notes',
                'Notifications - reminder alerts',
                'Exact alarms - reminders at the time you set, including after '
                    'reboot when the system allows it',
                'Calendar - optional sync to a device or Google calendar you '
                    'select',
                'Biometrics - optional unlock',
                'Storage - only on older Android versions when picking or saving '
                    'backup files',
                'Internet - optional cloud or sign-in features, and opening links',
              ],
            ),
            LegalSection(
              heading: '4. How data is used',
              body:
                  'Data is used to run the features you ask for: organizing your '
                  'content, sending reminders on time, syncing a calendar you '
                  'enable, locking private items, and restoring backups you '
                  'import.\n\n'
                  'Your content is not used for advertising.',
            ),
            LegalSection(
              heading: '5. Ads',
              body: 'SkyTask does not contain ads.',
            ),
            LegalSection(
              heading: '6. Sharing',
              body:
                  'We do not sell your data.\n\n'
                  'When you use related features, data may pass through '
                  'providers such as the device calendar, Google Sign-In / '
                  'Firebase, or Google Play services.\n\n'
                  'You can also share backups or content yourself with the '
                  'Android share sheet or files you export.',
            ),
            LegalSection(
              heading: '7. Keeping and deleting data',
              body:
                  'Content stays on your device until you delete it, clear app '
                  'data, or uninstall SkyTask.\n\n'
                  'Deleting an item removes it from local storage. Removing a '
                  'voice memo deletes that recording.\n\n'
                  'Uninstalling removes app-private data on the phone. Backup '
                  'files you saved elsewhere are not removed automatically.',
            ),
            LegalSection(
              heading: '8. Children',
              body:
                  'SkyTask is not aimed at children under 13 (or the minimum age '
                  'in your country). We do not knowingly collect personal '
                  'information from children.',
            ),
            LegalSection(
              heading: '9. Security',
              body:
                  'SkyTask uses app-private storage, optional PIN or biometric '
                  'lock, and optional encryption for private items.',
            ),
            LegalSection(
              heading: '10. Your choices',
              bullets: [
                'Turn off microphone, calendar, or notification access in '
                    'system Settings',
                'Turn calendar sync off in SkyTask Settings',
                'Turn app lock off after verifying it is you',
                'Export or delete your data in the app',
                'Email us with questions',
              ],
            ),
            LegalSection(
              heading: '11. Contact',
              body:
                  'Preshan Pradeepa Kariyawasam\n'
                  'Email: preshanpradeepa@gmail.com\n'
                  'GitHub: https://github.com/preshan/SkyTask',
            ),
            LegalSection(
              heading: '12. Updates',
              body:
                  'This page may change when the app does. The date at the top '
                  'shows the latest revision.',
            ),
          ],
        );
}
