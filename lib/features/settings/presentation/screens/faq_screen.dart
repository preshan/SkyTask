import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/content_list_card.dart';
import '../../../../shared/widgets/sky_icon.dart';
import 'legal_doc_screen.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _sections = <LegalSection>[
    LegalSection(
      heading: 'What is SkyTask?',
      body:
          'SkyTask is an Android app for managing tasks, reminders, '
          'ideas, and notes. You can also record voice memos, organize '
          'items with categories, and optionally synchronize reminders '
          'with a calendar on your device.',
    ),
    LegalSection(
      heading: 'Where is my data stored?',
      body:
          'Your data is stored on your phone by default. Optional '
          'features such as calendar synchronization, Google Sign-In, '
          'Firebase, and backups only process data when you enable or '
          'use them.',
    ),
    LegalSection(
      heading: 'Why does SkyTask ask for microphone access?',
      body:
          'Microphone access is required to record voice memos.\n\n'
          'If you deny microphone permission, voice recording will not '
          'be available, but the rest of the app will continue to work '
          'normally.',
    ),
    LegalSection(
      heading: 'Why does SkyTask request calendar access?',
      body:
          'Calendar access is used only when you enable Calendar Sync '
          'in Settings.\n\n'
          'This allows SkyTask to add or synchronize reminders with a '
          'writable calendar on your device, such as Google Calendar. '
          'You choose which calendar is used.',
    ),
    LegalSection(
      heading: 'Why does SkyTask request exact alarms?',
      body:
          'Exact alarms help SkyTask deliver reminders at the specific '
          'times you set.\n\n'
          'Android may apply additional restrictions to exact alarms '
          'depending on your device and system version. Reminder '
          'delivery may also depend on your device\'s battery-saving '
          'and notification settings.',
    ),
    LegalSection(
      heading: 'What is Day Plan?',
      body:
          'Day Plan is a timeline view available under Calendar → Day.\n\n'
          'Timed tasks and reminders appear as blocks on the timeline. '
          'You can:',
      bullets: [
        'Tap an empty time slot to create a task or reminder.',
        'Tap an existing block to edit it.',
        'Mark an item as complete.',
        'Move an item to a different time.',
      ],
    ),
    LegalSection(
      heading: 'How do voice memos play?',
      body:
          'Open a voice memo and tap the Play button.\n\n'
          'The voice-memo player includes:',
      bullets: [
        'Play and pause controls.',
        'A seek bar for moving through the recording.',
        'The ability to jump to a different position in the memo.',
      ],
    ),
    LegalSection(
      heading: 'How do backups work?',
      body:
          'Open Settings → Export backup to create a backup file.\n\n'
          'You can save the file on your device or share it using the '
          'Android share sheet. To restore your data, use the Import '
          'backup option and select the backup file.\n\n'
          'You may set a password when exporting a backup. Keep the '
          'backup file and password secure, because anyone who has '
          'access to both may be able to restore the backup.',
    ),
    LegalSection(
      heading: 'Does SkyTask show ads?',
      body: 'No. SkyTask does not display advertisements.',
    ),
    LegalSection(
      heading: 'How do I get help?',
      body:
          'For help, contact us at preshanpradeepa@gmail.com.\n\n'
          'You can also report a problem or suggest an improvement by '
          'opening an issue in the SkyTask GitHub repository.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.45,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        leading: IconButton(
          icon: const SkyIcon(SkyIcons.arrowBack),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.settings);
            }
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final section = _sections[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: ContentListCard.surfaceColor(context),
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  title: Text(
                    section.heading ?? '',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  children: [
                    if (section.body != null && section.body!.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(section.body!, style: bodyStyle),
                      ),
                    if (section.bullets != null &&
                        section.bullets!.isNotEmpty) ...[
                      if (section.body != null && section.body!.isNotEmpty)
                        const SizedBox(height: 8),
                      for (final item in section.bullets!)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('•  ', style: bodyStyle),
                              Expanded(child: Text(item, style: bodyStyle)),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
