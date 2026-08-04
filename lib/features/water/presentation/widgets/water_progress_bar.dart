import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

class WaterProgressBar extends StatelessWidget {
  const WaterProgressBar({
    super.key,
    required this.currentMl,
    required this.targetMl,
    required this.progress,
  });

  final int currentMl;
  final int targetMl;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (progress * 100).clamp(0, 999).round();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFB3E5FC).withValues(alpha: 0.35),
              AppColors.surfaceContainerLowest,
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Column(
          children: [
            const Icon(Icons.water_drop, size: 48, color: Color(0xFF0288D1)),
            const SizedBox(height: 8),
            Text(
              '$currentMl ml',
              style: theme.textTheme.displayLarge?.copyWith(
                color: AppColors.primary,
              ),
            ),
            Text(
              'Hedef: $targetMl ml  •  %$pct',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 28,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: AppColors.surfaceContainer),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4FC3F7),
                              AppColors.primary,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
