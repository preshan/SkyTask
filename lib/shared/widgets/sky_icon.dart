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
    final resolved =
        color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return HugeIcon(
      icon: icon,
      size: size,
      color: resolved,
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

  static const pending = HugeIcons.strokeRoundedClock01;
  static const check = HugeIcons.strokeRoundedTick02;
  static const checkCircle = HugeIcons.strokeRoundedCheckmarkCircle01;
  static const search = HugeIcons.strokeRoundedSearch01;
  static const sort = HugeIcons.strokeRoundedSorting01;
  static const filter = HugeIcons.strokeRoundedFilter;
  static const filterOff = HugeIcons.strokeRoundedFilterReset;
  static const today = HugeIcons.strokeRoundedCalendar03;
  static const event = HugeIcons.strokeRoundedCalendar02;
  static const archive = HugeIcons.strokeRoundedArchive02;
  static const folder = HugeIcons.strokeRoundedFolder01;
  static const chevronLeft = HugeIcons.strokeRoundedArrowLeft01;
  static const chevronRight = HugeIcons.strokeRoundedArrowRight01;
  static const arrowForward = HugeIcons.strokeRoundedArrowRight01;
  static const arrowBack = HugeIcons.strokeRoundedArrowLeft01;
  static const play = HugeIcons.strokeRoundedPlay;
  static const playCircle = HugeIcons.strokeRoundedPlayCircle;
  static const pause = HugeIcons.strokeRoundedPause;
  static const pauseCircle = HugeIcons.strokeRoundedPauseCircle;
  static const stop = HugeIcons.strokeRoundedStop;
  static const unlock = HugeIcons.strokeRoundedSquareUnlock01;
  static const fingerprint = HugeIcons.strokeRoundedFingerprintScan;
  static const shield = HugeIcons.strokeRoundedShield01;
  static const info = HugeIcons.strokeRoundedInformationCircle;
  static const palette = HugeIcons.strokeRoundedPaintBoard;
  static const edit = HugeIcons.strokeRoundedEdit01;
  static const backspace = HugeIcons.strokeRoundedEraser01;
  static const security = HugeIcons.strokeRoundedSecurityLock;
  static const linkedIn = HugeIcons.strokeRoundedLinkedin01;
  static const mail = HugeIcons.strokeRoundedMail01;
}
