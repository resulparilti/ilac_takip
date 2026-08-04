import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

class QuickAddButton extends StatelessWidget {
  const QuickAddButton({
    super.key,
    required this.amountMl,
    required this.onAdd,
    this.label,
  });

  final int amountMl;
  final VoidCallback onAdd;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onAdd,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, AppSpacing.tapTargetMin + 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label ?? '+$amountMl ml'),
    );
  }
}
