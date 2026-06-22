import 'package:flutter_test/flutter_test.dart';
import 'package:skytask/core/constants/app_colors.dart';
import 'package:skytask/core/theme/app_theme.dart';
import 'package:skytask/features/reminders/domain/entities/reminder.dart';

void main() {
  group('AppTheme', () {
    test('uses Material 3 with sky blue primary', () {
      final theme = AppTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primary);
    });
  });

  group('Reminder.fireDateTime', () {
    test('applies notification offset correctly', () {
      final reminder = Reminder(
        id: '1',
        title: 'Meeting',
        reminderDateTime: DateTime(2026, 6, 17, 20, 0),
        notificationOffset: NotificationOffset.thirtyMinutesBefore,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        reminder.fireDateTime,
        DateTime(2026, 6, 17, 19, 30),
      );
    });
  });
}
