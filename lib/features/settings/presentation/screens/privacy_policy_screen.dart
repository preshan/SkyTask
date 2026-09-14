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
                  'Developer: Preshan Pradeepa Kariyawasam\n'
                  'Contact: preshanpradeepa@gmail.com\n'
                  'GitHub: https://github.com/preshan/SkyTask\n\n'
                  'SkyTask is a personal productivity app for tasks, reminders, '
                  'ideas, notes, and voice memos. This policy explains what data '
                  'the app handles, how it is used, and your rights and choices.',
            ),
            LegalSection(
              heading: '1. Quick summary',
              body:
                  'SkyTask stores your tasks, reminders, ideas, notes, and voice '
                  'memos on your device by default.\n\n'
                  'Extra data is only processed when you opt in to features like '
                  'calendar sync, Google Sign-In / Firebase, or exporting '
                  'backups.\n\n'
                  'We do not sell your personal information.\n\n'
                  'SkyTask does not show ads.',
            ),
            LegalSection(
              heading: '2. Information we collect and store',
              body:
                  '2.1 Content you create (stored on your device)\n\n'
                  'We store the following content locally on your phone:',
              bullets: [
                'Task titles, descriptions/notes, categories, due dates and '
                    'times, completion status, and similar fields',
                'Ideas and notes you create',
                'Reminders, including the times and notification settings you '
                    'choose',
                'Voice memos you record (stored in the app\'s private storage)',
                'App lock settings (PIN or biometric preferences), which remain '
                    'on your device',
              ],
            ),
            LegalSection(
              heading: '2.2 Optional features',
              body: 'These features only run if you enable them:',
              bullets: [
                'Calendar sync - If you turn this on, SkyTask can read and write '
                    'events on calendars you select (device or Google Calendar).',
                'Account / Sign-In - If you sign in using Google / Firebase, '
                    'your email and authentication tokens may be handled by '
                    'those providers to enable account features.',
                'Backups - If you export a backup, the file is created and saved '
                    'under your control (for example, to your device storage or '
                    'cloud drive). SkyTask does not automatically upload your '
                    'data to our servers.',
                'Diagnostics - Android or Google Play may collect crash reports '
                    'or performance signals. SkyTask does not include a separate '
                    'analytics SDK.',
              ],
            ),
            LegalSection(
              heading: '3. Permissions we request',
              body:
                  'SkyTask asks for the following Android permissions, only as '
                  'needed for specific features:',
              bullets: [
                'Microphone - To record voice memos on tasks, reminders, ideas, '
                    'or notes.',
                'Notifications - To show reminder alerts.',
                'Exact alarms - To trigger reminders at the exact time you set, '
                    'including after reboot when allowed by the system.',
                'Calendar - Optional, only if you enable calendar sync with a '
                    'device or Google Calendar you choose.',
                'Biometrics - Optional, to unlock the app using fingerprint or '
                    'face unlock if your device supports it.',
                'Storage - Only on older Android versions, when you pick or save '
                    'backup files using the system file picker.',
                'Internet - For optional cloud or sign-in features and for '
                    'opening links (e.g., this privacy policy).',
              ],
            ),
            LegalSection(
              body:
                  'You can manage most of these permissions in your device '
                  'Settings → Apps → SkyTask → Permissions.',
            ),
            LegalSection(
              heading: '4. How we use your information',
              body: 'We use the data described above only to:',
              bullets: [
                'Organize and display your tasks, reminders, ideas, notes, and '
                    'voice memos',
                'Send reminders at the times you set',
                'Sync with a calendar you explicitly enable',
                'Provide optional app lock and backup/restore features',
                'Support account features if you choose to sign in',
              ],
            ),
            LegalSection(
              body:
                  'Your content is not used for advertising and is not sold to '
                  'third parties.',
            ),
            LegalSection(
              heading: '5. Ads and tracking',
              body:
                  'SkyTask does not contain ads.\n\n'
                  'SkyTask does not use advertising or tracking SDKs.\n\n'
                  'We do not profile you for ads or share your data for '
                  'advertising purposes.',
            ),
            LegalSection(
              heading: '6. Sharing of your information',
              body:
                  'We do not sell your data.\n\n'
                  'Data may be shared or processed by third parties only in '
                  'these situations:',
              bullets: [
                'Device calendar - If you enable calendar sync, your selected '
                    'calendar provider (e.g., Google Calendar) will store and '
                    'process those events according to its own privacy policy.',
                'Google Sign-In / Firebase - If you sign in, Google / Firebase '
                    'may process your email and authentication tokens to provide '
                    'account functionality.',
                'Google Play services - Android or Play may collect diagnostics '
                    'such as crash reports.',
                'Your own sharing - You can share backups or content using the '
                    'Android share sheet or by exporting files; those shares are '
                    'controlled by you and the apps or services you choose.',
              ],
            ),
            LegalSection(
              heading: '7. Data retention and deletion',
              bullets: [
                'Your content stays on your device until you delete it, clear '
                    'app data, or uninstall SkyTask.',
                'Deleting a task, note, idea, reminder, or voice memo removes it '
                    'from local storage.',
                'Uninstalling the app removes app-private data on your device.',
                'Backup files you saved elsewhere (for example, on your device '
                    'storage or in cloud drives) are not automatically removed '
                    'when you uninstall.',
                'If you have an account via Google / Firebase, account-related '
                    'data is managed according to those providers\' policies and '
                    'your settings in your Google account.',
              ],
            ),
            LegalSection(
              heading: '8. Children\'s privacy',
              body:
                  'SkyTask is not intended for children under 13 (or the minimum '
                  'age in your country). We do not knowingly collect personal '
                  'information from children. If we become aware that we have '
                  'inadvertently collected personal information from a child '
                  'under the applicable age, we will take steps to delete it.',
            ),
            LegalSection(
              heading: '9. Security',
              body:
                  'We take reasonable steps to protect your data, including:',
              bullets: [
                'Storing your content in app-private storage on your device',
                'Offering an optional PIN or biometric lock to restrict access '
                    'to the app',
                'Providing optional encryption for private items (if enabled in '
                    'the app)',
              ],
            ),
            LegalSection(
              body:
                  'No method of storage or transmission is 100% secure, but we '
                  'design SkyTask to keep your data local and under your control '
                  'by default.',
            ),
            LegalSection(
              heading: '10. Your rights and choices',
              body: 'You can control your data and privacy in SkyTask by:',
              bullets: [
                'Turning off microphone, calendar, or notification access in '
                    'your device Settings',
                'Turning calendar sync off in SkyTask\'s in-app settings',
                'Turning the app lock off after verifying it is you',
                'Exporting or deleting your data using the app\'s features',
                'Uninstalling SkyTask to remove app-private data from your '
                    'device',
                'Contacting us with questions or requests about your data '
                    '(see Section 11)',
              ],
            ),
            LegalSection(
              body:
                  'Depending on your location, you may also have legal rights to '
                  'access, correct, delete, or restrict processing of your '
                  'personal data. You can exercise these rights by contacting us.',
            ),
            LegalSection(
              heading: '11. Contact us',
              body:
                  'If you have questions, concerns, or requests about this '
                  'privacy policy or your data, please contact:\n\n'
                  'Preshan Pradeepa Kariyawasam\n'
                  'Email: preshanpradeepa@gmail.com\n'
                  'GitHub: https://github.com/preshan/SkyTask',
            ),
            LegalSection(
              heading: '12. Changes to this policy',
              body:
                  'We may update this privacy policy when the app or our '
                  'practices change. The "Last updated" date at the top shows '
                  'the latest revision.\n\n'
                  'If we make material changes, we will try to notify you '
                  'through the app or via other reasonable means (for example, '
                  'in-app notice or updated store listing), where required by '
                  'law.',
            ),
          ],
        );
}
