import 'package:flutter/material.dart';

/// Reusable rounded elevated button with icon.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: scheme.onPrimary),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: scheme.onPrimary,
          ),
        ),
      ],
    );

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      child: child,
    );
  }
}
