import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

class MissedItem {
  const MissedItem({
    required this.title,
    required this.subtitle,
    required this.kind,
  });

  final String title;
  final String subtitle;
  final String kind; // medicine | water
}

class MissedHistoryList extends StatelessWidget {
  const MissedHistoryList({super.key, required this.items});

  final List<MissedItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Kaçırılanlar', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(
                'Son dönemde kaçırılan kayıt yok.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...items.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    e.kind == 'water'
                        ? Icons.water_drop_outlined
                        : Icons.medication_outlined,
                    color: AppColors.error,
                  ),
                  title: Text(e.title, style: theme.textTheme.titleLarge),
                  subtitle: Text(e.subtitle, style: theme.textTheme.bodyMedium),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
