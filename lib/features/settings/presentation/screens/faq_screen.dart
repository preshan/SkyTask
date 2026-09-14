import 'legal_doc_screen.dart';

class FaqScreen extends LegalDocScreen {
  const FaqScreen({super.key})
      : super(
          title: 'FAQ',
          sections: const [
            LegalSection(
              heading: 'What is SkyTask?',
              body:
                  'SkyTask is a local-first Android app for tasks, reminders, '
                  'ideas, and notes. You can add voice memos, use categories, '
                  'and optionally sync reminders to a device calendar.',
            ),
            LegalSection(
              heading: 'Is my data stored in the cloud?',
              body:
                  'By default, no. Content stays on your phone. Optional '
                  'features like Google Sign-In / Firebase or calendar sync '
                  'only process data when you turn them on or use them.',
            ),
            LegalSection(
              heading: 'Why does SkyTask need the microphone?',
              body:
                  'Only to record voice memos on tasks, reminders, ideas, or '
                  'notes. You can deny the permission; voice recording will not '
                  'work, but the rest of the app still works.',
            ),
            LegalSection(
              heading: 'Why calendar permission?',
              body:
                  'Calendar read/write is used only if you enable Calendar sync '
                  'in Settings, so reminders can appear in Google Calendar or '
                  'another writable calendar on the device.',
            ),
            LegalSection(
              heading: 'Why exact alarms / precise reminders?',
              body:
                  'Reminders need to fire at the time you set. On modern Android, '
                  'exact alarms are the reliable way to do that, including after '
                  'reboot when the system allows it.',
            ),
            LegalSection(
              heading: 'What is Day Plan?',
              body:
                  'In Calendar → Day, timed tasks and reminders appear as blocks '
                  'on a timeline. Tap an empty slot to create an item, or tap a '
                  'block to edit, complete, or change the time.',
            ),
            LegalSection(
              heading: 'How do voice memos play?',
              body:
                  'Tap the play button on a voice item. A player opens with '
                  'play/pause and a seek bar so you can jump to any point.',
            ),
            LegalSection(
              heading: 'How do backups work?',
              body:
                  'Settings → Export backup creates a file you can keep or share. '
                  'Import restores from a backup file. You can optionally set a '
                  'password on export.',
            ),
            LegalSection(
              heading: 'Does SkyTask show ads?',
              body:
                  'Not in the current version. Ads may appear in a future update. '
                  'If that happens, the Privacy Policy and Play listing will be '
                  'updated first.',
            ),
            LegalSection(
              heading: 'How do I contact support?',
              body:
                  'Email preshanpradeepa@gmail.com or open an issue on the '
                  'SkyTask GitHub repository linked in Settings.',
            ),
          ],
        );
}
