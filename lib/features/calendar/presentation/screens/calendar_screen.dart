import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../reminders/presentation/widgets/reminder_form_sheet.dart';
import '../../domain/calendar_entry.dart';
import '../providers/calendar_providers.dart';

enum CalendarView { agenda, week, month }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarView _view = CalendarView.agenda;
  DateTime _anchor = DateTime.now();
  late DateRange _range = _computeRange(CalendarView.agenda, DateTime.now());

  DateRange _computeRange(CalendarView view, DateTime anchor) => switch (view) {
        CalendarView.agenda => agendaRange(),
        CalendarView.week => weekRange(anchor),
        CalendarView.month => monthRange(anchor),
      };

  void _setView(CalendarView view) {
    setState(() {
      _view = view;
      _anchor = DateTime.now();
      _range = _computeRange(_view, _anchor);
    });
  }

  void _shiftPeriod(int delta) {
    setState(() {
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
    final entriesAsync = ref.watch(calendarEntriesProvider(_range));
    final settings = ref.watch(calendarSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          if (_view != CalendarView.agenda)
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _shiftPeriod(-1),
            ),
          if (_view != CalendarView.agenda)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _shiftPeriod(1),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<CalendarView>(
              segments: const [
                ButtonSegment(value: CalendarView.agenda, label: Text('Agenda')),
                ButtonSegment(value: CalendarView.week, label: Text('Week')),
                ButtonSegment(value: CalendarView.month, label: Text('Month')),
              ],
              selected: {_view},
              onSelectionChanged: (s) => _setView(s.first),
            ),
          ),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!settings.syncEnabled)
              _GoogleSyncBanner(
                onEnable: () => _enableGoogleSync(context),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  settings.isGoogleCalendar
                      ? 'Syncing new reminders to Google Calendar (${settings.defaultCalendarName})'
                      : 'Syncing new reminders to ${settings.defaultCalendarName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Expanded(child: _buildView(entries)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showReminderFormSheet(context, ref),
        child: const Icon(Icons.add_alarm),
      ),
    );
  }

  Widget _buildView(List<CalendarEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No events in this period.\nTap + to create a reminder.',
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
              _anchor = day;
              _view = CalendarView.agenda;
              _range = _computeRange(_view, _anchor);
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
    final ok =
        await ref.read(calendarSettingsProvider.notifier).setSyncEnabled(true);
    if (!context.mounted) return;
    if (ok) {
      refreshReminders(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google Calendar sync enabled. New reminders will appear in your calendar.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not enable sync. Add a Google account in Android Settings, then try again.',
          ),
        ),
      );
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
              'SkyTask can write reminders to your Google Calendar through Android. '
              'Make sure a Google account is signed in on this device.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onEnable,
              icon: const Icon(Icons.calendar_month),
              label: const Text('Enable Google Calendar sync'),
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
                      color: AppColors.primary,
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
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
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
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
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
    final title = entry.isPrivate ? 'Private reminder' : entry.title;
    final time = DateFormat.jm().format(entry.start);
    final isDevice = entry.source == CalendarEntrySource.deviceCalendar;

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: ListTile(
        dense: compact,
        leading: Icon(
          isDevice ? Icons.event : Icons.alarm,
          color: entry.isCompleted ? Colors.grey : AppColors.primary,
        ),
        title: Text(
          title,
          style: entry.isCompleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          [
            time,
            if (entry.hasCalendarSync) 'Synced to calendar',
            if (isDevice) 'Device calendar',
            if (entry.description != null && !entry.isPrivate)
              entry.description!,
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
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
