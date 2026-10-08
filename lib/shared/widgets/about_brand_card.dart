import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_info.dart';
import 'content_list_card.dart';
import 'sky_icon.dart';

/// Brand block used on Settings / About: logo, version pill, credits, contacts.
class AboutBrandCard extends StatelessWidget {
  const AboutBrandCard({
    super.key,
    this.onOpenAbout,
    this.showDescription = true,
  });

  final VoidCallback? onOpenAbout;
  final bool showDescription;

  Future<void> _openLink(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.brand(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mist = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
          height: 1.35,
        );
    final linkStyle = mist?.copyWith(
      color: brand,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    final header = Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/images/app_icon.png',
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          AppInfo.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (showDescription) ...[
          const SizedBox(height: 6),
          Text(
            AppInfo.shortDescription,
            textAlign: TextAlign.center,
            style: mist,
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: brand.withValues(alpha: isDark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Version ${AppInfo.versionLabel}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isDark
                      ? Theme.of(context).colorScheme.onSurface
                      : brand,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  brand.withValues(alpha: 0.18),
                  ContentListCard.surfaceColor(context),
                ]
              : [
                  const Color(0xFFE8F1FF),
                  Colors.white,
                ],
        ),
        border: Border.all(
          color: brand.withValues(alpha: isDark ? 0.25 : 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          children: [
            if (onOpenAbout != null)
              InkWell(
                onTap: onOpenAbout,
                borderRadius: BorderRadius.circular(16),
                child: header,
              )
            else
              header,
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('© ${AppInfo.copyrightYear} ', style: mist),
                GestureDetector(
                  onTap: () => _openLink(AppInfo.repoUrl),
                  child: Text(AppInfo.name, style: linkStyle),
                ),
                Text('. All rights reserved.', style: mist),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Developed by ', style: mist),
                GestureDetector(
                  onTap: () => _openLink(AppInfo.developerGitHub),
                  child: Text(AppInfo.developerName, style: linkStyle),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Material(
              color: ContentListCard.surfaceColor(context),
              borderRadius: BorderRadius.circular(16),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _AboutContactButton(
                        icon: SkyIcons.linkedIn,
                        label: 'LinkedIn',
                        onTap: () => _openLink(AppInfo.developerLinkedIn),
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      indent: 10,
                      endIndent: 10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.12),
                    ),
                    Expanded(
                      child: _AboutContactButton(
                        icon: SkyIcons.mail,
                        label: AppInfo.developerEmail,
                        onTap: () =>
                            _openLink('mailto:${AppInfo.developerEmail}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutContactButton extends StatelessWidget {
  const _AboutContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.brand(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SkyIcon(icon, size: 18, color: brand),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: brand,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
