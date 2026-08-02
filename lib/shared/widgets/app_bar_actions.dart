import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import 'sky_icon.dart';

/// Shared AppBar actions: notifications + settings.
List<Widget> skyTaskAppBarActions(BuildContext context) {
  return [
    IconButton(
      icon: const SkyIcon(SkyIcons.notification),
      tooltip: 'Reminders',
      onPressed: () => context.go(AppRoutes.calendar),
    ),
    IconButton(
      icon: const SkyIcon(SkyIcons.settings),
      tooltip: 'Settings',
      onPressed: () => context.go(AppRoutes.settings),
    ),
  ];
}
