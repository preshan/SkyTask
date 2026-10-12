import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/voice_memo_service.dart';
import '../../../../shared/create/create_kind.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/async_error_view.dart';
import '../../../../shared/widgets/category_filter_bar.dart';
import '../../../../shared/widgets/category_label.dart';
import '../../../../shared/widgets/content_list_card.dart';
import '../../../../shared/widgets/list_add_button.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../../../shared/widgets/voice_play_button.dart';
import '../../../reminders/presentation/widgets/reminder_form_sheet.dart';
import '../../data/device_calendar_service.dart';
import '../../domain/calendar_entry.dart';
import '../providers/calendar_providers.dart';
import '../widgets/day_plan_view.dart';

enum CalendarView { agenda, day, week, month }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({
    super.key,
    this.focusedDay,
    this.privateOnly = false,
  });

  /// When set (e.g. from Home day strip), open Day Plan for that day.
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
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _privateOnly = widget.privateOnly;
    final focus = widget.focusedDay;
    if (focus != null) {
      _dayFocus = true;
      _view = CalendarView.day;
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
          _view = CalendarView.day;
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
        CalendarView.day => dayRange(anchor),
        CalendarView.week => weekRange(anchor),
        CalendarView.month => monthRange(anchor),
      };

  void _setView(CalendarView view) {
    setState(() {
      _view = view;
      if (view == CalendarView.day) {
        _dayFocus = true;
        _anchor = DateTime(_anchor.year, _anchor.month, _anchor.day);
      } else {
        _dayFocus = false;
        _anchor = DateTime.now();
      }
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
      if (_view == CalendarView.day ||
          (_dayFocus && _view == CalendarView.agenda)) {
        _anchor = _anchor.add(Duration(days: delta));
        _range = dayRange(_anchor);
        return;
      }
      _anchor = switch (_view) {
        CalendarView.week => _anchor.add(Duration(days: 7 * delta)),
        CalendarView.month => DateTime(_anchor.year, _anchor.month + delta, 1),
        CalendarView.agenda || CalendarView.day => _anchor,
      };
      _range = _computeRange(_view, _anchor);
    });
  }

  DateTime get _headerMonthDate {
    if (_view == CalendarView.agenda && !_dayFocus) {
      return DateTime.now();
    }
    return _anchor;
  }

  bool get _showPeriodNav =>
      _view != CalendarView.agenda || _dayFocus;

  bool get _showDayPlanCard =>
      _dayFocus || _view == CalendarView.day;

  Future<void> _pickMonthYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _headerMonthDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (_view == CalendarView.month) {
        _anchor = DateTime(picked.year, picked.month, 1);
      } else if (_view == CalendarView.day ||
          (_dayFocus && _view == CalendarView.agenda)) {
        final day = picked.day.clamp(
          1,
          DateTime(picked.year, picked.month + 1, 0).day,
        );
        _anchor = DateTime(picked.year, picked.month, day);
      } else if (_view == CalendarView.week) {
        _anchor = picked;
      } else {
        _anchor = DateTime(picked.year, picked.month, picked.day);
      }
      _range = _computeRange(_view, _anchor);
    });
  }

  double get _appBarBottomHeight {
    var h = 8.0 + 48.0 + 10.0 + 52.0 + 8.0;
    if (_showDayPlanCard) h += 92.0;
    if (_privateOnly) h += 56.0;
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final query = CalendarQuery(range: _range, source: _sourceTab);
    final entriesAsync = ref.watch(calendarEntriesProvider(query));
    final settings = ref.watch(calendarSettingsProvider);
    final monthLabel = DateFormat.yMMMM().format(_headerMonthDate);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: _CalendarTopBar(
          monthLabel: monthLabel,
          showPeriodNav: _showPeriodNav,
          onMonthTap: _pickMonthYear,
          onPrevious: () => _shiftPeriod(-1),
          onNext: () => _shiftPeriod(1),
          onAdd: () => openCreateSheet(context, ref, CreateKind.reminder),
          trailingActions: skyTaskAppBarActions(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_appBarBottomHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_showDayPlanCard)
                _DayPlanContextCard(
                  eyebrow: _view == CalendarView.day
                      ? 'DAY PLAN'
                      : 'REMINDERS',
                  dateLabel: DateFormat.yMMMEd().format(_anchor),
                  onShowAll: _clearDayFocus,
                ),
              if (_privateOnly)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Material(
                    color: AppColors.brand(context).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      dense: true,
                      leading: SkyIcon(
                        SkyIcons.private,
                        color: AppColors.brand(context),
                        size: 20,
                      ),
                      title: const Text('Showing private reminders'),
                      trailing: TextButton(
                        onPressed: () => setState(() => _privateOnly = false),
                        child: const Text('Clear'),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reminder types',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final tab in CalendarSourceTab.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _CalendarSourceChip(
                              label: tab == CalendarSourceTab.skyTask
                                  ? 'SkyTask'
                                  : 'All',
                              selected: _sourceTab == tab,
                              onSelected: () => _setSourceTab(tab),
                            ),
                          ),
                        const Spacer(),
                        _CalendarFilterChip(
                          label: 'All',
                          selected: _categoryFilter == null,
                          onSelected: () =>
                              setState(() => _categoryFilter = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final view in CalendarView.values)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: view != CalendarView.month ? 6 : 0,
                              ),
                              child: _CalendarViewSegment(
                                view: view,
                                selected: _view == view,
                                onSelected: () => _setView(view),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorView(
          error: e,
          onRetry: () => ref.invalidate(calendarEntriesProvider),
        ),
        data: (entries) {
          final usedCategories = entries
              .where((e) => e.reminder != null)
              .map((e) => e.reminder!.category);
          var visible = _privateOnly
              ? entries.where((e) => e.isPrivate).toList()
              : entries;
          if (_categoryFilter != null) {
            final filter = _categoryFilter!.toLowerCase();
            visible = visible
                .where(
                  (e) =>
                      e.reminder != null &&
                      e.reminder!.category.toLowerCase() == filter,
                )
                .toList();
          }

          return Column(
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
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CategoryFilterBar(
                  selected: _categoryFilter,
                  usedLabels: usedCategories,
                  onChanged: (v) => setState(() => _categoryFilter = v),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: _sourceTab == CalendarSourceTab.all &&
                        _allCalendarPermissionDenied
                    ? _AllCalendarPermissionEmpty(
                        onAllow: () => _setSourceTab(CalendarSourceTab.all),
                      )
                    : _buildView(visible),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildView(List<CalendarEntry> entries) {
    if (_view == CalendarView.day) {
      return DayPlanView(
        day: _anchor,
        privateOnly: _privateOnly,
        categoryFilter: _categoryFilter,
      );
    }

    if (entries.isEmpty) {
      final emptyMessage = switch (
          (_sourceTab, _privateOnly, _dayFocus, _categoryFilter != null)) {
        (CalendarSourceTab.all, _, _, true) =>
          'No events in this category for this period.',
        (_, _, _, true) =>
          'No reminders in this category for this period.',
        (CalendarSourceTab.all, _, _, _) =>
          'No calendar events in this period.',
        (_, true, _, _) => 'No private reminders in this period.',
        (_, _, true, _) => 'No reminders on this day.\nTap + to create one.',
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
      CalendarView.day => DayPlanView(
          day: _anchor,
          privateOnly: _privateOnly,
          categoryFilter: _categoryFilter,
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
              _view = CalendarView.day;
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
        'No writable calendar found. Add a Google account and turn on Calendar sync in Android Settings, or open the Calendar app once. Allow Calendar permission for SkyTask — it can create a local calendar as a fallback.',
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
              'Add reminders to your calendar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'SkyTask writes reminders to a calendar on this phone. '
              'If a Google account is signed in and Calendar sync is on, that includes Google Calendar. '
              'You will be asked for calendar permission.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onEnable,
              icon: const SkyIcon(SkyIcons.calendar),
              label: const Text('Enable calendar sync'),
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
    final meta = [
      time,
      if (entry.reminder?.isVoice == true) 'Voice',
      if (entry.hasCalendarSync) 'Synced to calendar',
      if (isDevice) 'Device calendar',
      if (entry.description != null) entry.description!,
    ].join(' • ');
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          decoration: entry.isCompleted ? TextDecoration.lineThrough : null,
          height: 1.15,
          fontWeight: FontWeight.w600,
        );

    return ContentListCard(
      title: displayTitle,
      isPrivate: entry.isPrivate,
      onTap: onTap,
      compact: compact,
      dimmed: entry.isCompleted,
      titleStyle: titleStyle,
      showChevron: onTap != null,
      categorySlot: entry.reminder != null
          ? CategoryLabel(entry.reminder!.category)
          : null,
      body: meta.isEmpty ? null : meta,
      trailing: [
        if (entry.reminder?.isVoice == true &&
            entry.reminder?.voicePath != null)
          VoicePlayButton(
            path: entry.reminder!.voicePath!,
            title: entry.reminder!.title,
          ),
      ],
    );
  }
}

class _CalendarTopBar extends StatelessWidget {
  const _CalendarTopBar({
    required this.monthLabel,
    required this.showPeriodNav,
    required this.onMonthTap,
    required this.onPrevious,
    required this.onNext,
    required this.onAdd,
    required this.trailingActions,
  });

  final String monthLabel;
  final bool showPeriodNav;
  final VoidCallback onMonthTap;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onAdd;
  final List<Widget> trailingActions;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Row(
        children: [
          InkWell(
            onTap: onMonthTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monthLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: onSurface.withValues(alpha: 0.92),
                        ),
                  ),
                  const SizedBox(width: 2),
                  Transform.rotate(
                    angle: 1.5708,
                    child: SkyIcon(
                      SkyIcons.chevronLeft,
                      size: 18,
                      color: onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showPeriodNav) ...[
            _CalendarNavCircleButton(
              icon: SkyIcons.chevronLeft,
              onPressed: onPrevious,
            ),
            const SizedBox(width: 4),
            _CalendarNavCircleButton(
              icon: SkyIcons.chevronRight,
              onPressed: onNext,
            ),
          ],
          const Spacer(),
          ListAddButton(
            tooltip: 'Add reminder',
            onPressed: onAdd,
          ),
          ...trailingActions,
        ],
      ),
    );
  }
}

class _CalendarNavCircleButton extends StatelessWidget {
  const _CalendarNavCircleButton({
    required this.icon,
    required this.onPressed,
  });

  final List<List<dynamic>> icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Material(
      color: surface.withValues(alpha: 0.65),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Center(
            child: SkyIcon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.75,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayPlanContextCard extends StatelessWidget {
  const _DayPlanContextCard({
    required this.eyebrow,
    required this.dateLabel,
    required this.onShowAll,
  });

  final String eyebrow;
  final String dateLabel;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.brand(context);
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: brand.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: SkyIcon(
                    SkyIcons.calendarFilled,
                    color: brand,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: onSurface.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onShowAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: brand,
                  side: BorderSide(color: brand.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('All'),
                    const SizedBox(width: 2),
                    SkyIcon(
                      SkyIcons.chevronRight,
                      size: 16,
                      color: brand,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarSourceChip extends StatelessWidget {
  const _CalendarSourceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.brand(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? brand : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? brand
                  : onSurface.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1,
                  color: selected
                      ? onPrimary
                      : onSurface.withValues(alpha: 0.72),
                ),
          ),
        ),
      ),
    );
  }
}

class _CalendarViewSegment extends StatelessWidget {
  const _CalendarViewSegment({
    required this.view,
    required this.selected,
    required this.onSelected,
  });

  final CalendarView view;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.brand(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final icon = switch (view) {
      CalendarView.agenda => SkyIcons.tasks,
      CalendarView.day => SkyIcons.calendarFilled,
      CalendarView.week => SkyIcons.calendar,
      CalendarView.month => SkyIcons.today,
    };
    final label = switch (view) {
      CalendarView.agenda => 'Agenda',
      CalendarView.day => 'Day',
      CalendarView.week => 'Week',
      CalendarView.month => 'Month',
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? brand.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? brand.withValues(alpha: 0.55)
                  : onSurface.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkyIcon(
                icon,
                size: 18,
                color: selected
                    ? brand
                    : onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                      color: selected
                          ? brand
                          : onSurface.withValues(alpha: 0.55),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarFilterChip extends StatelessWidget {
  const _CalendarFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.brand(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          height: 1,
          color: selected
              ? brand
              : onSurface.withValues(alpha: 0.72),
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? brand.withValues(alpha: 0.45)
                  : onSurface.withValues(alpha: 0.18),
            ),
          ),
          child: Text(label, style: labelStyle),
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
