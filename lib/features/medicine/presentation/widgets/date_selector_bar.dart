import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Bugünden başlayarak ileriye doğru gün seçici (hafta başından geriye yayılmaz).
class DateSelectorBar extends StatelessWidget {
  const DateSelectorBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.dayCount = 7,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  final int dayCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile,
          vertical: AppSpacing.stackSm,
        ),
        itemCount: dayCount,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = start.add(Duration(days: index));
          final isSelected = _sameDay(day, selected);
          final weekday = DateFormat('E', 'tr_TR').format(day);

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelected(DateTime(day.year, day.month, day.day)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekday,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.onSurface,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
