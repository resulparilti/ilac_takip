import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

class DayCompliance {
  const DayCompliance({
    required this.label,
    required this.taken,
    required this.total,
  });

  final String label;
  final int taken;
  final int total;

  double get rate => total == 0 ? 0 : taken / total;
}

class ComplianceChart extends StatelessWidget {
  const ComplianceChart({super.key, required this.days});

  final List<DayCompliance> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('7 günlük uyum', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in days)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${(day.rate * 100).round()}%',
                              style: theme.textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: FractionallySizedBox(
                                heightFactor: day.rate.clamp(0.05, 1.0),
                                widthFactor: 1,
                                alignment: Alignment.bottomCenter,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: day.rate >= 0.8
                                        ? AppColors.secondary
                                        : day.rate >= 0.5
                                            ? AppColors.warning
                                            : AppColors.error,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(day.label, style: theme.textTheme.labelMedium),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
