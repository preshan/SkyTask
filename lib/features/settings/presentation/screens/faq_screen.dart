import 'legal_doc_screen.dart';

class FaqScreen extends LegalDocScreen {
  const FaqScreen({super.key})
      : super(
          title: 'FAQ',
          sections: const [
            LegalSection(
              heading: 'What is SkyTask?',
              body:
                  'SkyTask is an Android app for tasks, reminders, ideas, and '
                  'notes. Add voice memos, organize with categories, and '
                  'optionally sync reminders to a calendar on your phone.',
            ),
            LegalSection(
              heading: 'Where is my data stored?',
              body:
                  'On your phone by default. Calendar sync, Google Sign-In, or '
                  'Firebase only run when you turn them on or use them.',
            ),
            LegalSection(
              heading: 'Why does SkyTask ask for the microphone?',
              body:
                  'To record voice memos. If you deny access, recording is '
                  'unavailable; everything else still works.',
            ),
            LegalSection(
              heading: 'Why calendar access?',
              body:
                  'Only when Calendar sync is on in Settings, so reminders can '
                  'show up in Google Calendar or another writable calendar on '
                  'the device.',
            ),
            LegalSection(
              heading: 'Why exact alarms?',
              body:
                  'So reminders fire at the time you set. On newer Android '
                  'versions, exact alarms are how that stays reliable after '
                  'reboot.',
            ),
            LegalSection(
              heading: 'What is Day Plan?',
              body:
                  'In Calendar → Day, timed tasks and reminders show as blocks '
                  'on a timeline. Tap an empty slot to create something, or tap '
                  'a block to edit, complete, or move it.',
            ),
            LegalSection(
              heading: 'How do voice memos play?',
              body:
                  'Tap play on a voice item. You get play/pause and a seek bar '
                  'to jump anywhere in the recording.',
            ),
            LegalSection(
              heading: 'How do backups work?',
              body:
                  'Settings → Export backup creates a file you can keep or '
                  'share. Import restores from that file. You can set a password '
                  'when exporting.',
            ),
            LegalSection(
              heading: 'Does SkyTask show ads?',
              body: 'No.',
            ),
            LegalSection(
              heading: 'How do I get help?',
              body:
                  'Email preshanpradeepa@gmail.com, or open an issue on the '
                  'SkyTask GitHub repo linked in Settings.',
            ),
          ],
        );
}
