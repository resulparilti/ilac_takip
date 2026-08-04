import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/models/enums.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/features/stats/presentation/widgets/compliance_chart.dart';
import 'package:ilac_takip/features/stats/presentation/widgets/missed_history_list.dart';
import 'package:ilac_takip/shared/widgets/premium_gate.dart';
import 'package:intl/intl.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumGate(
      featureTitle: 'İstatistikler',
      featureBody:
          'Uyumluluk grafikleri ve kaçırılan doz geçmişi Premium özelliktir.',
      child: const _StatsContent(),
    );
  }
}

class _StatsContent extends ConsumerWidget {
  const _StatsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('İstatistik')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            children: [
              ComplianceChart(days: data.days),
              const SizedBox(height: AppSpacing.stackMd),
              MissedHistoryList(items: data.missed),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _StatsData {
  const _StatsData({required this.days, required this.missed});

  final List<DayCompliance> days;
  final List<MissedItem> missed;
}

final _statsProvider = FutureProvider.autoDispose<_StatsData>((ref) async {
  final repo = ref.watch(medicineRepositoryProvider);
  final medicines = await repo.getAll();
  final schedules = await repo.getAllActiveSchedules();
  final byMed = {
    for (final m in medicines)
      if (m.id != null) m.id!: m,
  };

  final now = DateTime.now();
  final days = <DayCompliance>[];
  final missed = <MissedItem>[];

  for (var i = 6; i >= 0; i--) {
    final day = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: i));
    var total = 0;
    var taken = 0;

    for (final schedule in schedules) {
      final med = byMed[schedule.medicineId];
      if (med == null) continue;
      if (schedule.daysOfWeek.isNotEmpty &&
          !schedule.daysOfWeek.contains(day.weekday)) {
        continue;
      }
      final times =
          schedule.times.isNotEmpty ? schedule.times : ['08:00'];
      for (final t in times) {
        final parts = t.split(':');
        final scheduledAt = DateTime(
          day.year,
          day.month,
          day.day,
          int.tryParse(parts[0]) ?? 8,
          parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
        );
        total++;
        final log = await repo.findDoseLog(
          medicineId: med.id!,
          scheduledAt: scheduledAt,
        );
        if (log?.status == ReminderStatus.completed) {
          taken++;
        } else if (scheduledAt.isBefore(now) &&
            (log == null || log.status == ReminderStatus.missed)) {
          if (i <= 2) {
            missed.add(
              MissedItem(
                title: med.name,
                subtitle:
                    '${DateFormat('d MMM', 'tr_TR').format(day)} • $t',
                kind: 'medicine',
              ),
            );
          }
        }
      }
    }

    days.add(
      DayCompliance(
        label: DateFormat('E', 'tr_TR').format(day),
        taken: taken,
        total: total,
      ),
    );
  }

  return _StatsData(days: days, missed: missed);
});
