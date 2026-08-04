import 'package:ilac_takip/core/models/alarm_payload.dart';
import 'package:ilac_takip/core/models/enums.dart';
import 'package:ilac_takip/core/utils/date_utils.dart';
import 'package:ilac_takip/services/database/medicine_repository.dart';
import 'package:ilac_takip/services/database/settings_repository.dart';
import 'package:ilac_takip/services/database/water_repository.dart';
import 'package:ilac_takip/services/notifications/notification_service.dart';

/// DB'deki ilaç/su planlarından önümüzdeki günlerin alarmlarını kurar.
class ReminderScheduler {
  ReminderScheduler({
    required this.notifications,
    required this.medicines,
    required this.water,
    required this.settings,
  });

  final NotificationService notifications;
  final MedicineRepository medicines;
  final WaterRepository water;
  final SettingsRepository settings;

  Future<void> rescheduleAll({required bool includeWater}) async {
    await notifications.cancelAll();

    final medTone =
        await settings.get('medicine_ringtone') ?? 'default_medicine';
    final waterTone =
        await settings.get('water_ringtone') ?? 'default_water';

    await _scheduleMedicines(medTone);
    await _scheduleRenewals();
    if (includeWater) {
      await _scheduleWater(waterTone);
    }
  }

  Future<void> _scheduleMedicines(String ringtone) async {
    final meds = await medicines.getAll();
    final schedules = await medicines.getAllActiveSchedules();
    final byMed = {
      for (final m in meds)
        if (m.id != null) m.id!: m,
    };
    final now = DateTime.now();

    for (var dayOffset = 0; dayOffset < 3; dayOffset++) {
      final day = DateTime(now.year, now.month, now.day)
          .add(Duration(days: dayOffset));
      for (final schedule in schedules) {
        final med = byMed[schedule.medicineId];
        if (med == null) continue;

        final start = medicineEffectiveStart(
          createdAt: med.createdAt,
          scheduleStart: schedule.startDate,
        );
        if (!isOnOrAfterStart(day, start)) continue;

        if (schedule.daysOfWeek.isNotEmpty &&
            !schedule.daysOfWeek.contains(day.weekday)) {
          continue;
        }
        final times = schedule.times.isNotEmpty
            ? schedule.times
            : _intervalTimes(schedule.intervalHours);
        for (final t in times) {
          final parts = t.split(':');
          final at = DateTime(
            day.year,
            day.month,
            day.day,
            int.tryParse(parts[0]) ?? 8,
            parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
          );
          if (at.isBefore(now)) continue;

          final log = await medicines.findDoseLog(
            medicineId: med.id!,
            scheduledAt: at,
          );
          if (log?.status == ReminderStatus.completed) continue;

          await notifications.scheduleAlarm(
            ringtoneKey: ringtone,
            payload: AlarmPayload(
              kind: AlarmKind.medicine,
              title: 'İlaç zamanı: ${med.name}',
              body: [
                if (med.dosage != null) med.dosage!,
                med.conditionType.labelTr,
                if (med.instructions != null && med.instructions!.isNotEmpty)
                  med.instructions!,
              ].join(' • '),
              scheduledAt: at,
              medicineId: med.id,
              scheduleId: schedule.id,
            ),
          );
        }
      }
    }
  }

  Future<void> _scheduleRenewals() async {
    final meds = await medicines.getAll();
    final now = DateTime.now();
    for (final med in meds) {
      final renewal = med.renewalDate;
      if (renewal == null) continue;
      final at = DateTime(renewal.year, renewal.month, renewal.day, 9);
      if (at.isBefore(now)) continue;
      await notifications.scheduleAlarm(
        ringtoneKey: 'renewal',
        payload: AlarmPayload(
          kind: AlarmKind.renewal,
          title: 'Yenileme: ${med.name}',
          body: 'Stok: ${med.stockCount}. İlacınızı yenilemeyi unutmayın.',
          scheduledAt: at,
          medicineId: med.id,
        ),
      );
    }
  }

  Future<void> _scheduleWater(String ringtone) async {
    final goal = await water.getGoal();
    if (goal == null || !goal.isActive) return;
    final times = water.buildReminderTimes(goal);
    final now = DateTime.now();

    for (var dayOffset = 0; dayOffset < 2; dayOffset++) {
      final day = DateTime(now.year, now.month, now.day)
          .add(Duration(days: dayOffset));
      for (final t in times) {
        final parts = t.split(':');
        final at = DateTime(
          day.year,
          day.month,
          day.day,
          int.tryParse(parts[0]) ?? 8,
          parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
        );
        if (at.isBefore(now)) continue;
        await notifications.scheduleAlarm(
          ringtoneKey: ringtone,
          payload: AlarmPayload(
            kind: AlarmKind.water,
            title: 'Su içme zamanı',
            body: 'Hedef: ${goal.dailyTargetMl} ml',
            scheduledAt: at,
          ),
        );
      }
    }
  }

  List<String> _intervalTimes(int? hours) {
    if (hours == null || hours <= 0) return ['08:00'];
    final result = <String>[];
    for (var h = 8; h <= 22; h += hours) {
      result.add('${h.toString().padLeft(2, '0')}:00');
    }
    return result;
  }
}
