import 'legal_doc_screen.dart';

/// Data safety and permission notes (for users and Play Console).
class DataSafetyScreen extends LegalDocScreen {
  const DataSafetyScreen({super.key})
      : super(
          title: 'Data safety & permissions',
          sections: const [
            LegalSection(
              body:
                  'How SkyTask handles data and why it asks for certain '
                  'permissions. Useful when filling Google Play forms too.',
            ),
            LegalSection(
              heading: 'Overview',
              bullets: [
                'Personal data: limited, mostly on-device; some optional cloud '
                    'features',
                'Encrypted in transit: yes for network features (HTTPS / Google '
                    'and Firebase SDKs)',
                'Delete your data: delete items in the app, clear app data, or '
                    'uninstall. Delete exported backups yourself if you saved '
                    'them elsewhere',
                'Sold: no',
                'Used for ads: no',
              ],
            ),
            LegalSection(
              heading: 'Data types',
              bullets: [
                'App content — tasks, reminders, ideas, notes (on device)',
                'Audio — voice memos (on device; mic needed to record)',
                'Calendar events — only with calendar sync on',
                'Account info — only if you sign in with Google / Firebase',
                'App performance — platform crash signals possible; no separate '
                    'analytics SDK',
                'Device IDs — may be used by Firebase or Play services when '
                    'those features run',
              ],
            ),
            LegalSection(
              heading: 'Microphone',
              body:
                  'Used to attach voice memos to tasks, reminders, ideas, or '
                  'notes. Audio stays in app-private storage unless you export '
                  'a backup.\n\n'
                  'Not used for calls, always-on listening, or ads.',
            ),
            LegalSection(
              heading: 'Calendar',
              body:
                  'Used only when Calendar sync is enabled, to create or update '
                  'reminder events on a calendar you pick.\n\n'
                  'Not used to sell data or show ads.',
            ),
            LegalSection(
              heading: 'Exact alarms',
              body:
                  'SkyTask needs exact alarms so reminder notifications arrive '
                  'at the time you set, including after reboot when the system '
                  'allows it.\n\n'
                  'Alarms are not used for ads or unrelated background work.',
            ),
            LegalSection(
              heading: 'Notifications',
              body:
                  'Used for reminder alerts you scheduled. You can turn '
                  'notifications off in system Settings.',
            ),
            LegalSection(
              heading: 'Account / Firebase',
              body:
                  'Optional. When you sign in, Firebase Auth, Google Sign-In, '
                  'Firestore, and Cloud Messaging may use account identifiers '
                  'and tokens for signed-in, sync, or messaging features.',
            ),
            LegalSection(
              heading: 'Ads',
              body: 'SkyTask does not contain ads.',
            ),
          ],
        );
}
