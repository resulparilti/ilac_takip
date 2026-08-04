import 'package:ilac_takip/core/models/dose_log.dart';
import 'package:ilac_takip/core/models/enums.dart';
import 'package:ilac_takip/core/utils/date_utils.dart';
import 'package:ilac_takip/services/database/medicine_repository.dart';
import 'package:ilac_takip/services/database/settings_repository.dart';
import 'package:ilac_takip/services/emergency/emergency_notify_service.dart';

/// Peş peşe kaçırılan dozları tarar; Premium’da eşik aşımında acil bildirir.
class MissedDoseMonitor {
  MissedDoseMonitor({
    required this.medicines,
    required this.settings,
    required this.notifier,
  });

  final MedicineRepository medicines;
  final SettingsRepository settings;
  final EmergencyNotifyService notifier;

  /// Geçmiş bekleyen dozları missed işaretler ve gerekirse acil bildirir.
  Future<void> scanAndNotifyIfNeeded({required bool isPremium}) async {
    await _markOverdueAsMissed();
    if (!isPremium) return;

    final contacts = await settings.getEmergencyContacts();
    if (contacts.isEmpty) return;

    final meds = await medicines.getAll();
    for (final med in meds) {
      if (med.id == null) continue;
      final streak = await medicines.consecutiveMissedCount(med.id!);
      if (streak <= 0) continue;

      final needsNotify = contacts.any((c) => streak >= c.missThreshold);
      if (!needsNotify) continue;

      final key = 'emergency_notified_${med.id}_$streak';
      final already = await settings.get(key);
      if (already == '1') continue;

      final lastAt = await settings.get('emergency_last_at');
      if (lastAt != null) {
        final last = DateTime.tryParse(lastAt);
        if (last != null &&
            DateTime.now().difference(last) < const Duration(hours: 6)) {
          continue;
        }
      }

      await notifier.notifyContacts(
        contacts: contacts,
        medicine: med,
        consecutiveMisses: streak,
      );
      await settings.set(key, '1');
      await settings.set('emergency_last_at', DateTime.now().toIso8601String());
    }
  }

  Future<void> _markOverdueAsMissed() async {
    final meds = await medicines.getAll();
    final schedules = await medicines.getAllActiveSchedules();
    final byMed = {
      for (final m in meds)
        if (m.id != null) m.id!: m,
    };
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 1));

    for (var dayOffset = 0; dayOffset < 3; dayOffset++) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: dayOffset));
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
        final times =
            schedule.times.isNotEmpty ? schedule.times : ['08:00'];
        for (final t in times) {
          final parts = t.split(':');
          final at = DateTime(
            day.year,
            day.month,
            day.day,
            int.tryParse(parts[0]) ?? 8,
            parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
          );
          if (at.isAfter(cutoff)) continue;

          final log = await medicines.findDoseLog(
            medicineId: med.id!,
            scheduledAt: at,
          );
          if (log == null) {
            await medicines.insertDoseLog(
              DoseLog(
                medicineId: med.id!,
                scheduleId: schedule.id,
                scheduledAt: at,
                status: ReminderStatus.missed,
              ),
            );
          } else if (log.status == ReminderStatus.pending && log.id != null) {
            await medicines.markDoseMissed(log.id!);
          }
        }
      }
    }
  }
}
