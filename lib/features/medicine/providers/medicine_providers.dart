import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/models/day_dose_item.dart';
import 'package:ilac_takip/core/models/enums.dart';
import 'package:ilac_takip/core/models/medicine.dart';
import 'package:ilac_takip/core/models/medicine_schedule.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/utils/date_utils.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final medicinesProvider = FutureProvider.autoDispose<List<Medicine>>((ref) {
  return ref.watch(medicineRepositoryProvider).getAll();
});

final dayDosesProvider =
    FutureProvider.autoDispose<List<DayDoseItem>>((ref) async {
  final day = ref.watch(selectedDateProvider);
  final repo = ref.watch(medicineRepositoryProvider);
  final medicines = await repo.getAll();
  final schedules = await repo.getAllActiveSchedules();
  final byMed = {
    for (final m in medicines)
      if (m.id != null) m.id!: m,
  };

  final items = <DayDoseItem>[];
  final weekday = day.weekday;

  for (final schedule in schedules) {
    final medicine = byMed[schedule.medicineId];
    if (medicine == null) continue;

    final start = medicineEffectiveStart(
      createdAt: medicine.createdAt,
      scheduleStart: schedule.startDate,
    );
    // Eklenme tarihinden önceki günlere doz yazılmaz.
    if (!isOnOrAfterStart(day, start)) continue;

    if (schedule.daysOfWeek.isNotEmpty &&
        !schedule.daysOfWeek.contains(weekday)) {
      continue;
    }

    final times = schedule.times.isNotEmpty
        ? schedule.times
        : _timesFromInterval(schedule);

    for (final timeStr in times) {
      final parts = timeStr.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final scheduledAt = DateTime(day.year, day.month, day.day, hour, minute);

      final log = await repo.findDoseLog(
        medicineId: medicine.id!,
        scheduledAt: scheduledAt,
      );

      var status = log?.status ?? ReminderStatus.pending;
      if (status == ReminderStatus.pending &&
          scheduledAt.isBefore(
            DateTime.now().subtract(const Duration(hours: 1)),
          )) {
        status = ReminderStatus.missed;
      }

      items.add(
        DayDoseItem(
          medicine: medicine,
          schedule: schedule,
          scheduledAt: scheduledAt,
          status: status,
          completedAt: log?.completedAt,
        ),
      );
    }
  }

  items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return items;
});

List<String> _timesFromInterval(MedicineSchedule schedule) {
  final hours = schedule.intervalHours;
  if (hours == null || hours <= 0) return ['08:00'];
  final startHour = schedule.startDate?.hour ?? 8;
  const endHour = 22;
  final result = <String>[];
  var h = startHour;
  while (h <= endHour) {
    result.add('${h.toString().padLeft(2, '0')}:00');
    h += hours;
  }
  return result.isEmpty ? ['08:00'] : result;
}
