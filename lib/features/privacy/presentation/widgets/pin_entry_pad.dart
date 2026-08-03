import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/sky_icon.dart';

/// Numeric pad for entering a fixed-length PIN.
class PinEntryPad extends StatefulWidget {
  const PinEntryPad({
    super.key,
    required this.onCompleted,
    this.length = AppConstants.pinLength,
    this.title,
    this.subtitle,
    this.errorText,
    this.lightOnDark = false,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final String? title;
  final String? subtitle;
  final String? errorText;

  /// Force light text/icons (e.g. brand gradient lock screen).
  final bool lightOnDark;

  @override
  State<PinEntryPad> createState() => PinEntryPadState();
}

class PinEntryPadState extends State<PinEntryPad> {
  String _digits = '';

  void clear() => setState(() => _digits = '');

  void _tap(String value) {
    if (_digits.length >= widget.length) return;
    HapticFeedback.lightImpact();
    setState(() => _digits += value);
    if (_digits.length == widget.length) {
      widget.onCompleted(_digits);
    }
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = AppColors.brand(context);
    final onSurface =
        widget.lightOnDark ? Colors.white : scheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.72);
    final keyFill = widget.lightOnDark
        ? Colors.white.withValues(alpha: 0.18)
        : scheme.onSurface.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.08,
          );
    final accent = widget.lightOnDark ? Colors.white : brand;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        if (widget.subtitle != null) ...[
          Text(
            widget.subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: muted,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (i) {
            final filled = i < _digits.length;
            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? accent : Colors.transparent,
                border: Border.all(
                  color: filled ? accent : muted,
                  width: 1.5,
                ),
              ),
            );
          }),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.errorText!,
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'back'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                if (key.isEmpty) {
                  return const SizedBox(width: 88, height: 64);
                }
                if (key == 'back') {
                  return _PadButton(
                    icon: SkyIcons.backspace,
                    fill: keyFill,
                    foreground: accent,
                    onPressed: _backspace,
                  );
                }
                return _PadButton(
                  label: key,
                  fill: keyFill,
                  foreground: onSurface,
                  onPressed: () => _tap(key),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({
    this.label,
    this.icon,
    required this.fill,
    required this.foreground,
    required this.onPressed,
  });

  final String? label;
  final List<List<dynamic>>? icon;
  final Color fill;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: fill,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: icon != null
                  ? SkyIcon(icon!, color: foreground)
                  : Text(
                      label!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
