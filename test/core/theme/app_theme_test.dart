import 'package:flutter_test/flutter_test.dart';
import 'package:skytask/features/reminders/domain/entities/reminder.dart';

void main() {
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
