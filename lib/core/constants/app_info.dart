/// App identity & developer credits (SYU-style).
///
/// [version] / [buildNumber] are filled at startup from the platform package
/// metadata so Settings always matches `pubspec.yaml`.
abstract final class AppInfo {
  static const name = 'SkyTask';
  static const tagline = 'Tasks, reminders, ideas & notes';

  static String version = '1.1.0';
  static String buildNumber = '2';
  static String get versionLabel => '$version+$buildNumber';

  static const developerName = 'Preshan Pradeepa Kariyawasam';
  static const developerLinkedIn = 'https://www.linkedin.com/in/preshan/';
  static const developerGitHub = 'https://github.com/preshan';
  static const developerEmail = 'preshanpradeepa@gmail.com';
  static const repoUrl = 'https://github.com/preshan/SkyTask';
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
