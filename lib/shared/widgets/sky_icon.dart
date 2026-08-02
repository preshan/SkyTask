import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Thin wrapper around [HugeIcon] (same library as SYU).
class SkyIcon extends StatelessWidget {
  const SkyIcon(
    this.icon, {
    super.key,
    this.size = 22,
    this.color,
    this.strokeWidth = 1.5,
  });

  final List<List<dynamic>> icon;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: icon,
      size: size,
      color: color,
      strokeWidth: strokeWidth,
    );
  }
}

/// SkyTask [Hugeicons](https://hugeicons.com/) stroke-rounded catalog.
abstract final class SkyIcons {
  static const home = HugeIcons.strokeRoundedHome01;
  static const homeFilled = HugeIcons.strokeRoundedHome02;
  static const tasks = HugeIcons.strokeRoundedCheckList;
  static const tasksFilled = HugeIcons.strokeRoundedTick02;
  static const calendar = HugeIcons.strokeRoundedCalendar01;
  static const calendarFilled = HugeIcons.strokeRoundedCalendarCheckOut01;
  static const ideas = HugeIcons.strokeRoundedIdea;
  static const ideasFilled = HugeIcons.strokeRoundedBulb;
  static const notes = HugeIcons.strokeRoundedNote;
  static const add = HugeIcons.strokeRoundedAdd01;
  static const close = HugeIcons.strokeRoundedCancel01;
  static const settings = HugeIcons.strokeRoundedSettings01;
  static const notification = HugeIcons.strokeRoundedNotification01;
  static const alarm = HugeIcons.strokeRoundedAlarmClock;
  static const reminder = HugeIcons.strokeRoundedAlarmClock;
  static const task = HugeIcons.strokeRoundedTask01;
  static const note = HugeIcons.strokeRoundedNoteAdd;
  static const lightbulb = HugeIcons.strokeRoundedIdea;
  static const pin = HugeIcons.strokeRoundedPin;
  static const lock = HugeIcons.strokeRoundedLock;
  /// Closed eye with slash — private / hidden.
  static const private = HugeIcons.strokeRoundedViewOffSlash;
  static const mic = HugeIcons.strokeRoundedMic01;
}
