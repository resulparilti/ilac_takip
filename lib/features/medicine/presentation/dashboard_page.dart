import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/models/alarm_payload.dart';
import 'package:ilac_takip/core/models/day_dose_item.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/features/medicine/presentation/medicine_form_page.dart';
import 'package:ilac_takip/features/medicine/presentation/widgets/date_selector_bar.dart';
import 'package:ilac_takip/features/medicine/presentation/widgets/medicine_card.dart';
import 'package:ilac_takip/features/medicine/providers/medicine_providers.dart';
import 'package:ilac_takip/features/premium/presentation/paywall_page.dart';
import 'package:ilac_takip/shared/widgets/admob_banner.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final dosesAsync = ref.watch(dayDosesProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlaçlar'),
        actions: [
          if (!isPremium)
            TextButton(
              onPressed: () => PaywallPage.open(context),
              child: Text(
                'Premium',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          DateSelectorBar(
            selected: selected,
            onSelected: (d) {
              ref.read(selectedDateProvider.notifier).state = d;
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: dosesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyState(
                    onAdd: () => _openForm(context, ref),
                  );
                }
                final grouped = <String, List<DayDoseItem>>{};
                for (final item in items) {
                  grouped.putIfAbsent(item.periodLabel, () => []).add(item);
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.marginMobile,
                    AppSpacing.stackMd,
                    AppSpacing.marginMobile,
                    100,
                  ),
                  children: [
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 8),
                        child: Row(
                          children: [
                            Icon(
                              _periodIcon(entry.key),
                              color: AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.key} (${entry.value.first.timeLabel})',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final item in entry.value) ...[
                        MedicineCard(
                          item: item,
                          onTaken: () => _markTaken(ref, item),
                          onUndoTaken: () => _undoTaken(context, ref, item),
                          onEdit: () => _openForm(
                            context,
                            ref,
                            medicineId: item.medicine.id,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),
          const AdMobBanner(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add, size: 28),
        label: const Text('İlaç Ekle'),
      ),
    );
  }

  IconData _periodIcon(String period) => switch (period) {
        'Sabah' => Icons.wb_twilight_outlined,
        'Öğle' => Icons.wb_sunny_outlined,
        'Akşam' => Icons.nights_stay_outlined,
        _ => Icons.bedtime_outlined,
      };

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    int? medicineId,
  }) async {
    final saved = await MedicineFormPage.open(
      context,
      medicineId: medicineId,
    );
    if (saved == true) {
      ref.invalidate(dayDosesProvider);
      ref.invalidate(medicinesProvider);
    }
  }

  Future<void> _markTaken(WidgetRef ref, DayDoseItem item) async {
    await ref.read(medicineRepositoryProvider).markDoseTaken(
          medicineId: item.medicine.id!,
          scheduleId: item.schedule.id,
          scheduledAt: item.scheduledAt,
        );
    await ref.read(notificationServiceProvider).clearAlarm(
          AlarmPayload(
            kind: AlarmKind.medicine,
            title: item.medicine.name,
            body: '',
            scheduledAt: item.scheduledAt,
            medicineId: item.medicine.id,
            scheduleId: item.schedule.id,
          ),
        );
    ref.invalidate(dayDosesProvider);
    ref.invalidate(medicinesProvider);
  }

  Future<void> _undoTaken(
    BuildContext context,
    WidgetRef ref,
    DayDoseItem item,
  ) async {
    await ref.read(medicineRepositoryProvider).undoDoseTaken(
          medicineId: item.medicine.id!,
          scheduledAt: item.scheduledAt,
        );
    final isPremium = ref.read(isPremiumProvider);
    await ref.read(reminderSchedulerProvider).rescheduleAll(
          includeWater: isPremium,
        );
    ref.invalidate(dayDosesProvider);
    ref.invalidate(medicinesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alındı işareti geri alındı.')),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication_liquid_outlined, size: 72),
            const SizedBox(height: 16),
            Text(
              'Henüz ilaç yok',
              style: theme.textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Fotoğraf ve saatlerle ilk ilacınızı ekleyin.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('İlaç Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
