import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

/// Google Play Prominent Disclosure kartı — sistem izni istenmeden önce gösterilir.
class PermissionExplanationCard extends StatelessWidget {
  const PermissionExplanationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 36, color: AppColors.primary),
                const SizedBox(width: AppSpacing.stackSm),
                Expanded(
                  child: Text(title, style: theme.textTheme.headlineMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              body,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
