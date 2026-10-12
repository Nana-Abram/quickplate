import 'package:flutter/material.dart';

/// Primary action button. While [isLoading] it shows a spinner and ignores
/// taps, so a form cannot be submitted twice.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  /// Stretch to the available width, as form buttons usually do.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget child = isLoading
        ? SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              semanticsLabel: '$label in progress',
            ),
          )
        : Text(label);

    final button = icon == null || isLoading
        ? FilledButton(onPressed: isLoading ? null : onPressed, child: child)
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: child,
          );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
