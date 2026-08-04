import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

class UpcomingRemindersList extends StatelessWidget {
  const UpcomingRemindersList({
    super.key,
    required this.times,
  });

  final List<String> times;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bugünkü uyarılar', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            if (times.isEmpty)
              Text(
                'Uyarı planı yok.',
                style: theme.textTheme.bodyLarge,
              )
            else
              ...times.map((t) {
                final parts = t.split(':');
                final mins = (int.tryParse(parts[0]) ?? 0) * 60 +
                    (int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
                final passed = mins < nowMinutes;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    passed ? Icons.check_circle : Icons.alarm,
                    color: passed ? AppColors.secondary : AppColors.primary,
                  ),
                  title: Text(t, style: theme.textTheme.titleLarge),
                  subtitle: Text(
                    passed ? 'Geçti' : 'Bekliyor',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
