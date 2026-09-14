import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/sky_icon.dart';

/// Simple scrollable legal / help document.
class LegalDocScreen extends StatelessWidget {
  const LegalDocScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.45,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          for (final section in sections) ...[
            if (section.heading != null) ...[
              const SizedBox(height: 16),
              Text(
                section.heading!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
            ],
            if (section.body != null && section.body!.isNotEmpty)
              Text(section.body!, style: bodyStyle),
            if (section.bullets != null && section.bullets!.isNotEmpty) ...[
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
        ],
      ),
    );
  }
}

class LegalSection {
  const LegalSection({
    this.heading,
    this.body,
    this.bullets,
  });

  final String? heading;
  final String? body;
  final List<String>? bullets;
}
