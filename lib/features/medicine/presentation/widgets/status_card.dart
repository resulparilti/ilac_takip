import 'package:flutter/material.dart';
import 'package:ilac_takip/core/models/enums.dart';
import 'package:ilac_takip/core/models/medicine.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.medicine,
    this.onTap,
  });

  final Medicine medicine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, bg, icon) = switch (medicine.stockStatus) {
      StockStatus.critical => (
          AppColors.error,
          AppColors.error.withValues(alpha: 0.1),
          Icons.error_outline,
        ),
      StockStatus.warning => (
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.15),
          Icons.warning_amber_rounded,
        ),
      StockStatus.sufficient => (
          AppColors.success,
          AppColors.secondaryContainer.withValues(alpha: 0.5),
          Icons.check_circle_outline,
        ),
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: bg,
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(medicine.name, style: theme.textTheme.headlineMedium),
                    Text(
                      'Stok: ${medicine.stockCount} • ${medicine.stockStatus.labelTr}',
                      style: theme.textTheme.bodyLarge?.copyWith(color: color),
                    ),
                    if (medicine.renewalDate != null)
                      Text(
                        'Yenileme: ${medicine.renewalDate!.day}.${medicine.renewalDate!.month}.${medicine.renewalDate!.year}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
