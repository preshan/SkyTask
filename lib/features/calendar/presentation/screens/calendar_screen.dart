import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/voice_memo_service.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/private_content_gate.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../../shared/widgets/voice_play_button.dart';
import '../../../reminders/presentation/widgets/reminder_form_sheet.dart';
import '../../data/device_calendar_service.dart';
import '../../domain/calendar_entry.dart';
import '../providers/calendar_providers.dart';

enum CalendarView { agenda, week, month }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({
    super.key,
    this.focusedDay,
    this.privateOnly = false,
  });

  /// When set (e.g. from Home “This week”), open agenda for that day.
  final DateTime? focusedDay;
  final bool privateOnly;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late CalendarView _view;
  late DateTime _anchor;
  late DateRange _range;
  late bool _dayFocus;
  late bool _privateOnly;
  CalendarSourceTab _sourceTab = CalendarSourceTab.skyTask;
  bool _allCalendarPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _privateOnly = widget.privateOnly;
    final focus = widget.focusedDay;
    if (focus != null) {
      _dayFocus = true;
      _view = CalendarView.agenda;
      _anchor = DateTime(focus.year, focus.month, focus.day);
      _range = dayRange(_anchor);
    } else {
      _dayFocus = false;
      _view = CalendarView.agenda;
      _anchor = DateTime.now();
      _range = agendaRange();
    }
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.privateOnly != widget.privateOnly) {
      _privateOnly = widget.privateOnly;
    }
    final focus = widget.focusedDay;
    final old = oldWidget.focusedDay;
    if (focus?.millisecondsSinceEpoch != old?.millisecondsSinceEpoch) {
      if (focus != null) {
        setState(() {
          _dayFocus = true;
          _view = CalendarView.agenda;
          _anchor = DateTime(focus.year, focus.month, focus.day);
          _range = dayRange(_anchor);
        });
      } else if (old != null) {
        setState(() {
          _dayFocus = false;
          _view = CalendarView.agenda;
          _anchor = DateTime.now();
          _range = agendaRange();
        });
      }
    }
  }

  DateRange _computeRange(CalendarView view, DateTime anchor) => switch (view) {
        CalendarView.agenda =>
          _dayFocus ? dayRange(anchor) : agendaRange(),
        CalendarView.week => weekRange(anchor),
        CalendarView.month => monthRange(anchor),
      };

  void _setView(CalendarView view) {
    setState(() {
      _dayFocus = false;
      _view = view;
      _anchor = DateTime.now();
      _range = _computeRange(_view, _anchor);
    });
  }

  Future<void> _setSourceTab(CalendarSourceTab tab) async {
    if (tab == CalendarSourceTab.all) {
      final service = DeviceCalendarService.instance;
      var granted = await service.hasPermissions();
      if (!granted) {
        granted = await service.requestPermissions();
      }
      if (!mounted) return;
      setState(() {
        _sourceTab = tab;
        _allCalendarPermissionDenied = !granted;
      });
      if (granted) {
        ref.invalidate(calendarEntriesProvider);
      }
      return;
    }
    setState(() {
      _sourceTab = tab;
      _allCalendarPermissionDenied = false;
    });
  }

  void _clearDayFocus() {
    setState(() {
      _dayFocus = false;
      _view = CalendarView.agenda;
      _anchor = DateTime.now();
      _range = agendaRange();
    });
  }

  void _shiftPeriod(int delta) {
    setState(() {
      if (_dayFocus && _view == CalendarView.agenda) {
        _anchor = _anchor.add(Duration(days: delta));
        _range = dayRange(_anchor);
        return;
      }
      _anchor = switch (_view) {
        CalendarView.week => _anchor.add(Duration(days: 7 * delta)),
        CalendarView.month => DateTime(_anchor.year, _anchor.month + delta, 1),
        CalendarView.agenda => _anchor,
      };
      _range = _computeRange(_view, _anchor);
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = CalendarQuery(range: _range, source: _sourceTab);
    final entriesAsync = ref.watch(calendarEntriesProvider(query));
    final settings = ref.watch(calendarSettingsProvider);
    final title = _dayFocus
        ? DateFormat.MMMd().format(_anchor)
        : 'Calendar';
    final bannerExtra =
        (_dayFocus ? 48.0 : 0.0) + (_privateOnly ? 48.0 : 0.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_dayFocus || _view != CalendarView.agenda)
            IconButton(
              icon: const SkyIcon(SkyIcons.chevronLeft),
              onPressed: () => _shiftPeriod(-1),
            ),
          if (_dayFocus || _view != CalendarView.agenda)
            IconButton(
              icon: const SkyIcon(SkyIcons.chevronRight),
              onPressed: () => _shiftPeriod(1),
            ),
          ...skyTaskAppBarActions(context),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(96 + bannerExtra),
          child: Column(
            children: [
              if (_dayFocus)
                Material(
                  color: AppColors.brandSecondary(context).withValues(alpha: 0.15),
                  child: ListTile(
                    dense: true,
                    leading: SkyIcon(
                      SkyIcons.event,
                      color: AppColors.brandSecondary(context),
                    ),
                    title: Text(
                      'Reminders on ${DateFormat.yMMMEd().format(_anchor)}',
                    ),
                    trailing: TextButton(
                      onPressed: _clearDayFocus,
                      child: const Text('All'),
                    ),
                  ),
                ),
              if (_privateOnly)
                Material(
                  color: AppColors.brand(context).withValues(alpha: 0.08),
                  child: ListTile(
                    dense: true,
                    leading: SkyIcon(
                      SkyIcons.private,
                      color: AppColors.brand(context),
                    ),
                    title: const Text('Showing private reminders'),
                    trailing: TextButton(
                      onPressed: () => setState(() => _privateOnly = false),
                      child: const Text('Clear'),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SegmentedButton<CalendarSourceTab>(
                  segments: const [
                    ButtonSegment(
                      value: CalendarSourceTab.skyTask,
                      label: Text('SkyTask'),
                    ),
                    ButtonSegment(
                      value: CalendarSourceTab.all,
                      label: Text('All'),
                    ),
                  ],
                  selected: {_sourceTab},
                  onSelectionChanged: (s) => _setSourceTab(s.first),
                  style: _segmentStyle(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<CalendarView>(
                  segments: const [
                    ButtonSegment(
                      value: CalendarView.agenda,
                      label: Text('Agenda'),
                    ),
                    ButtonSegment(
                      value: CalendarView.week,
                      label: Text('Week'),
                    ),
                    ButtonSegment(
                      value: CalendarView.month,
                      label: Text('Month'),
                    ),
                  ],
                  selected: {_view},
                  onSelectionChanged: (s) => _setView(s.first),
                  style: _segmentStyle(context),
                ),
              ),
            ],
          ),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_sourceTab == CalendarSourceTab.skyTask &&
                !settings.syncEnabled)
              _GoogleSyncBanner(
                onEnable: () => _enableGoogleSync(context),
              )
            else if (_sourceTab == CalendarSourceTab.skyTask &&
                settings.syncEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  settings.isGoogleCalendar
                      ? 'Syncing new reminders to Google Calendar (${settings.defaultCalendarName})'
                      : 'Syncing new reminders to ${settings.defaultCalendarName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Expanded(
              child: _sourceTab == CalendarSourceTab.all &&
                      _allCalendarPermissionDenied
                  ? _AllCalendarPermissionEmpty(
                      onAllow: () => _setSourceTab(CalendarSourceTab.all),
                    )
                  : _buildView(
                      _privateOnly
                          ? entries.where((e) => e.isPrivate).toList()
                          : entries,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _segmentStyle(BuildContext context) {
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        final scheme = Theme.of(context).colorScheme;
        if (states.contains(WidgetState.selected)) {
          return scheme.onPrimary;
        }
        return scheme.onSurface;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        final scheme = Theme.of(context).colorScheme;
        if (states.contains(WidgetState.selected)) {
          return scheme.primary;
        }
        return scheme.surface;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        final scheme = Theme.of(context).colorScheme;
        if (states.contains(WidgetState.selected)) {
          return scheme.onPrimary;
        }
        return scheme.onSurface;
      }),
    );
  }

  Widget _buildView(List<CalendarEntry> entries) {
    if (entries.isEmpty) {
      final emptyMessage = switch ((_sourceTab, _privateOnly, _dayFocus)) {
        (CalendarSourceTab.all, _, _) =>
          'No calendar events in this period.',
        (_, true, _) => 'No private reminders in this period.',
        (_, _, true) => 'No reminders on this day.\nTap + to create one.',
        _ => 'No SkyTask reminders in this period.\nTap + to create a reminder.',
      };
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return switch (_view) {
      CalendarView.agenda => _AgendaView(
          entries: entries,
          onTapReminder: (entry) => _openReminder(entry),
        ),
      CalendarView.week => _WeekView(
          entries: entries,
          anchor: _anchor,
          onTapReminder: (entry) => _openReminder(entry),
        ),
      CalendarView.month => _MonthView(
          entries: entries,
          month: _anchor,
          onSelectDay: (day) {
            setState(() {
              _dayFocus = true;
              _anchor = day;
              _view = CalendarView.agenda;
              _range = dayRange(_anchor);
            });
          },
        ),
    };
  }

  void _openReminder(CalendarEntry entry) {
    if (entry.reminder == null) return;
    showReminderFormSheet(context, ref, reminder: entry.reminder);
  }

  Future<void> _enableGoogleSync(BuildContext context) async {
    final result =
        await ref.read(calendarSettingsProvider.notifier).setSyncEnabled(true);
    if (!context.mounted) return;
    if (result.success) {
      refreshReminders(ref);
      final settings = ref.read(calendarSettingsProvider);
      final name = settings.defaultCalendarName ?? 'your calendar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.isGoogleCalendar
                ? 'Sync enabled. New reminders will appear in Google Calendar ($name).'
                : 'Sync enabled. New reminders will appear in $name.',
          ),
        ),
      );
    } else {
      await _showSyncFailure(context, result.failure);
    }
  }

  Future<void> _showSyncFailure(
    BuildContext context,
    CalendarSyncFailure? failure,
  ) async {
    final message = switch (failure) {
      CalendarSyncFailure.permanentlyDenied =>
        'Calendar permission is blocked. Open Settings → Apps → SkyTask → Permissions and allow Calendar.',
      CalendarSyncFailure.permissionDenied =>
        'Calendar permission is required to sync reminders.',
      CalendarSyncFailure.noCalendars =>
        'No writable calendars found. Open the Calendar app once, or check that your Google account is syncing calendars in Android Settings.',
      null => 'Could not enable calendar sync. Try again.',
    };

    final messenger = ScaffoldMessenger.of(context);
    if (failure == CalendarSyncFailure.permanentlyDenied) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
    } else {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _GoogleSyncBanner extends StatelessWidget {
  const _GoogleSyncBanner({required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add reminders to Google Calendar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'SkyTask can write reminders to your device calendar (including Google Calendar when that account is syncing on this phone). '
              'You will be asked for calendar permission.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onEnable,
              icon: const SkyIcon(SkyIcons.calendar),
              label: const Text('Enable Google Calendar sync'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllCalendarPermissionEmpty extends StatelessWidget {
  const _AllCalendarPermissionEmpty({required this.onAllow});

  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Allow calendar access to see events from Google and other calendars on this phone.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAllow,
              child: const Text('Allow calendar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaView extends StatelessWidget {
  const _AgendaView({
    required this.entries,
    required this.onTapReminder,
  });

  final List<CalendarEntry> entries;
  final ValueChanged<CalendarEntry> onTapReminder;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<CalendarEntry>>{};
    for (final entry in entries) {
      final key = DateFormat.yMMMMd().format(entry.start);
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final day = keys[i];
        final dayEntries = grouped[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Text(
                day,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.brand(context),
                    ),
              ),
            ),
            for (final entry in dayEntries)
              _CalendarEntryTile(
                entry: entry,
                onTap: entry.reminder != null
                    ? () => onTapReminder(entry)
                    : null,
              ),
          ],
        );
      },
    );
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView({
    required this.entries,
    required this.anchor,
    required this.onTapReminder,
  });

  final List<CalendarEntry> entries;
  final DateTime anchor;
  final ValueChanged<CalendarEntry> onTapReminder;

  @override
  Widget build(BuildContext context) {
    final range = weekRange(anchor);
    final days = List.generate(
      7,
      (i) => range.start.add(Duration(days: i)),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${DateFormat.MMMd().format(days.first)} – ${DateFormat.MMMd().format(days.last.subtract(const Duration(days: 1)))}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (final day in days) ...[
          Text(
            DateFormat('EEEE, MMM d').format(day),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          ..._entriesForDay(entries, day).map(
            (entry) => _CalendarEntryTile(
              entry: entry,
              compact: true,
              onTap: entry.reminder != null
                  ? () => onTapReminder(entry)
                  : null,
            ),
          ),
          if (_entriesForDay(entries, day).isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12, left: 4),
              child: Text('No events'),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.entries,
    required this.month,
    required this.onSelectDay,
  });

  final List<CalendarEntry> entries;
  final DateTime month;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            DateFormat.yMMMM().format(month),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: Center(child: Text('M'))),
              Expanded(child: Center(child: Text('T'))),
              Expanded(child: Center(child: Text('W'))),
              Expanded(child: Center(child: Text('T'))),
              Expanded(child: Center(child: Text('F'))),
              Expanded(child: Center(child: Text('S'))),
              Expanded(child: Center(child: Text('S'))),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: leadingEmpty + daysInMonth,
              itemBuilder: (_, index) {
                if (index < leadingEmpty) return const SizedBox.shrink();
                final day = index - leadingEmpty + 1;
                final date = DateTime(month.year, month.month, day);
                final dayEntries = _entriesForDay(entries, date);
                final isToday = _isSameDay(date, DateTime.now());

                return InkWell(
                  onTap: () => onSelectDay(date),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.brand(context).withValues(alpha: 0.15)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.brand(context).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day'),
                        if (dayEntries.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.brand(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarEntryTile extends StatelessWidget {
  const _CalendarEntryTile({
    required this.entry,
    this.onTap,
    this.compact = false,
  });

  final CalendarEntry entry;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final displayTitle = displayItemTitle(
      title: entry.title,
      isVoice: entry.reminder?.isVoice == true,
      createdAt: entry.reminder?.createdAt ?? entry.start,
    );
    final time = DateFormat.jm().format(entry.start);
    final isDevice = entry.source == CalendarEntrySource.deviceCalendar;

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: PrivateContentGate(
        isPrivate: entry.isPrivate,
        child: ListTile(
          dense: compact,
          leading: SkyIcon(
            entry.reminder?.isVoice == true
                ? SkyIcons.mic
                : (isDevice ? SkyIcons.event : SkyIcons.alarm),
            color: entry.isCompleted ? Colors.grey : AppColors.brand(context),
          ),
          title: Text(
            displayTitle,
            style: entry.isCompleted
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: Text(
            [
              time,
              if (entry.reminder?.isVoice == true) 'Voice',
              if (entry.hasCalendarSync) 'Synced to calendar',
              if (isDevice) 'Device calendar',
              if (entry.description != null) entry.description!,
            ].join(' • '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.reminder?.isVoice == true &&
                  entry.reminder?.voicePath != null)
                VoicePlayButton(path: entry.reminder!.voicePath!),
              if (onTap != null) const SkyIcon(SkyIcons.chevronRight),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

List<CalendarEntry> _entriesForDay(List<CalendarEntry> entries, DateTime day) {
  return entries
      .where((e) => _isSameDay(e.start, day))
      .toList();
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
