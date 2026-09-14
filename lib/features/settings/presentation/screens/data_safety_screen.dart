import 'legal_doc_screen.dart';

/// Data safety and permission notes (for users and Play Console).
class DataSafetyScreen extends LegalDocScreen {
  const DataSafetyScreen({super.key})
      : super(
          title: 'Data safety & permissions',
          sections: const [
            LegalSection(
              body:
                  'This page explains how SkyTask handles your data and why the '
                  'app requests certain permissions. It may also help you '
                  'complete relevant Google Play Data safety disclosures.',
            ),
            LegalSection(
              heading: 'Overview',
              bullets: [
                'Personal data: Limited collection, with most app content '
                    'stored on your device. Optional cloud features may process '
                    'additional data.',
                'Encrypted in transit: Yes. Network features use HTTPS and the '
                    'security provided by Google and Firebase SDKs.',
                'Data deletion: Delete items inside the app, clear SkyTask\'s '
                    'app data, or uninstall the app. Exported backup files saved '
                    'elsewhere must be deleted separately.',
                'Sold: No. SkyTask does not sell your personal information.',
                'Used for advertising: No. SkyTask does not use your data for '
                    'advertising.',
                'Advertising ID: SkyTask does not use advertising identifiers '
                    'for ads.',
              ],
            ),
            LegalSection(
              heading: 'Data types',
            ),
            LegalSection(
              heading: 'App content',
              body:
                  'This includes tasks, reminders, ideas, notes, categories, '
                  'dates, times, and completion information. This data is stored '
                  'on your device by default.',
            ),
            LegalSection(
              heading: 'Audio',
              body:
                  'Voice memos you record are stored in SkyTask\'s app-private '
                  'storage on your device. A microphone permission is required '
                  'to record them.\n\n'
                  'Audio remains on your device unless you include it in a '
                  'backup or share it yourself.',
            ),
            LegalSection(
              heading: 'Calendar events',
              body:
                  'Calendar data is accessed only when you enable Calendar Sync. '
                  'SkyTask may read, create, or update events on a calendar you '
                  'select.',
            ),
            LegalSection(
              heading: 'Account information',
              body:
                  'Account information is processed only if you choose to sign '
                  'in or use an account-based feature. Google Sign-In and '
                  'Firebase may process information such as your email address, '
                  'account identifier, and authentication tokens.',
            ),
            LegalSection(
              heading: 'App performance information',
              body:
                  'Android or Google Play may collect crash reports and '
                  'performance signals. SkyTask does not add a separate '
                  'analytics SDK.',
            ),
            LegalSection(
              heading: 'Device or service identifiers',
              body:
                  'Firebase or Google Play services may process device or '
                  'service identifiers when you use features that rely on those '
                  'services, such as authentication, synchronization, messaging, '
                  'or crash reporting.',
            ),
            LegalSection(
              heading: 'Microphone permission',
              body:
                  'SkyTask uses the microphone to attach voice memos to tasks, '
                  'reminders, ideas, or notes.\n\n'
                  'Audio is stored in app-private storage by default.\n\n'
                  'Audio is not used for phone calls.\n\n'
                  'SkyTask does not use the microphone for always-on listening.\n\n'
                  'Audio is not used for advertising.\n\n'
                  'If you deny microphone access, voice recording will be '
                  'unavailable, but other app features will continue to work.',
            ),
            LegalSection(
              heading: 'Calendar permission',
              body:
                  'SkyTask uses calendar access only when Calendar Sync is '
                  'enabled.\n\n'
                  'Calendar access allows the app to create or update reminder '
                  'events on a writable calendar that you select. It is not used '
                  'to sell data, display advertisements, or access calendars '
                  'unrelated to the synchronization feature.\n\n'
                  'You can disable calendar access in your device settings or '
                  'turn off Calendar Sync inside SkyTask.',
            ),
            LegalSection(
              heading: 'Exact alarms',
              body:
                  'SkyTask uses exact alarms to trigger reminder notifications '
                  'at the times you set.\n\n'
                  'Android may restrict exact alarms depending on your device, '
                  'Android version, and system settings. After a reboot, '
                  'reminders can be restored only when permitted by the Android '
                  'system.\n\n'
                  'Exact alarms are not used for advertising or unrelated '
                  'background activity.',
            ),
            LegalSection(
              heading: 'Notifications',
              body:
                  'Notification permission is used to display reminder alerts '
                  'that you schedule.\n\n'
                  'You can disable notifications at any time in your device\'s '
                  'system settings. If notifications are disabled, SkyTask may '
                  'not be able to show reminder alerts.',
            ),
            LegalSection(
              heading: 'Account and Firebase features',
              body:
                  'Account and Firebase features are optional. If you use them, '
                  'Firebase Auth, Google Sign-In, Firestore, or Firebase Cloud '
                  'Messaging may process account identifiers, authentication '
                  'tokens, synchronization data, or messaging-related '
                  'information as required for the feature you select.\n\n'
                  'These services are not required for basic, on-device task and '
                  'note management unless a particular SkyTask feature depends '
                  'on them.',
            ),
            LegalSection(
              heading: 'Backups',
              body:
                  'When you export a backup, SkyTask creates a file containing '
                  'the data selected for export. You decide where to save or '
                  'share that file.\n\n'
                  'If voice memos are included, the backup may also contain those '
                  'recordings. Backup files saved outside the app are not '
                  'automatically deleted when you delete data, clear app data, '
                  'or uninstall SkyTask. You must delete those files yourself.',
            ),
            LegalSection(
              heading: 'Advertising',
              body:
                  'SkyTask does not contain advertisements.\n\n'
                  'The app does not use your tasks, notes, voice memos, calendar '
                  'data, or account information for advertising.',
            ),
          ],
        );
}
