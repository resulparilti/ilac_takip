import 'package:flutter/material.dart';
import 'package:ilac_takip/core/models/day_dose_item.dart';
import 'package:ilac_takip/core/models/enums.dart';
import 'package:ilac_takip/core/platform/medicine_image.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/shared/widgets/hold_to_undo_button.dart';

class MedicineCard extends StatelessWidget {
  const MedicineCard({
    super.key,
    required this.item,
    required this.onTaken,
    this.onUndoTaken,
    this.onEdit,
  });

  final DayDoseItem item;
  final VoidCallback onTaken;
  final VoidCallback? onUndoTaken;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (item.status) {
      ReminderStatus.completed => AppColors.secondary,
      ReminderStatus.missed => AppColors.error,
      _ => AppColors.primary,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _Thumb(photoPath: item.medicine.photoPath),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.medicine.name,
                                style: theme.textTheme.headlineMedium,
                              ),
                              Text(
                                [
                                  if (item.medicine.dosage != null &&
                                      item.medicine.dosage!.isNotEmpty)
                                    item.medicine.dosage!,
                                  item.medicine.conditionType.labelTr,
                                ].join(' • '),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusChip(item: item),
                      ],
                    ),
                    if (item.medicine.instructions != null &&
                        item.medicine.instructions!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.medicine.instructions!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (item.status == ReminderStatus.completed)
                      HoldToUndoButton(
                        label:
                            'Alındı${item.completedAt != null ? ' (${_fmt(item.completedAt!)})' : ''} — geri al',
                        hint: 'Geri almak için 3 saniye basılı tutun',
                        onUndo: onUndoTaken ?? () {},
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onTaken,
                              icon: const Icon(Icons.check, size: 28),
                              label: Text(
                                item.status == ReminderStatus.missed
                                    ? 'Şimdi Al'
                                    : 'Alındı Olarak İşaretle',
                              ),
                            ),
                          ),
                          if (onEdit != null) ...[
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Düzenle',
                            ),
                          ],
                        ],
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

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.photoPath});

  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final image = medicineImageProvider(photoPath);
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.primaryContainer,
      backgroundImage: image,
      child: image == null
          ? const Icon(Icons.medication, color: AppColors.onPrimary, size: 28)
          : null,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.item});

  final DayDoseItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (item.status == ReminderStatus.missed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber, size: 18, color: AppColors.error),
            const SizedBox(width: 4),
            Text(
              'Gecikti',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(item.timeLabel, style: theme.textTheme.labelLarge),
    );
  }
}
