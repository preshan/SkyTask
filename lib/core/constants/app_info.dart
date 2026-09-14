/// App identity & developer credits.
///
/// [version] / [buildNumber] are filled at startup from the platform package
/// metadata so Settings always matches `pubspec.yaml`.
abstract final class AppInfo {
  static const name = 'SkyTask';
  static const tagline = 'Tasks, reminders, ideas & notes';

  /// Google Play short description (max ~80 characters).
  static const shortDescription =
      'Plan tasks, reminders, ideas & notes with voice memos and calendar sync.';

  /// Google Play full description (store listing).
  static const fullDescription = '''
SkyTask helps you capture work and life in one place.

• Tasks with priorities, categories, due dates, and Day Plan times
• Reminders with local notifications and optional device calendar sync
• Ideas and notes, including private items protected by app lock
• Voice memos you can record, play, pause, and seek
• Local-first storage with optional backup export/import
• Light and dark themes

Your content stays on your device by default. Optional features such as Google Sign-In, Firebase, and calendar sync only run when you choose to use them.

Ads are not shown today. Future versions may include ads; if that happens, this privacy policy and Play listings will be updated first.
''';

  static String version = '1.1.0';
  static String buildNumber = '2';
  static String get versionLabel => '$version+$buildNumber';

  static const developerName = 'Preshan Pradeepa Kariyawasam';
  static const developerLinkedIn = 'https://www.linkedin.com/in/preshan/';
  static const developerGitHub = 'https://github.com/preshan';
  static const developerEmail = 'preshanpradeepa@gmail.com';
  static const repoUrl = 'https://github.com/preshan/SkyTask';

  /// Public Privacy Policy URL for Google Play Console.
  /// Hosted from this repo's /docs via GitHub Pages after you enable Pages.
  static const privacyPolicyUrl =
      'https://preshan.github.io/SkyTask/privacy.html';

  static const copyrightYear = '2026';
  static const copyright =
      '© $copyrightYear SkyTask. All rights reserved.';

  static void applyPackageInfo({
    required String versionName,
    required String build,
  }) {
    if (versionName.isNotEmpty) version = versionName;
    if (build.isNotEmpty) buildNumber = build;
  }
}
