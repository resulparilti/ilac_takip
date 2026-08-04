import 'package:ilac_takip/core/models/enums.dart';
import 'package:ilac_takip/core/models/medicine.dart';
import 'package:ilac_takip/core/models/medicine_schedule.dart';

/// Dashboard'da gösterilecek tek doz satırı.
class DayDoseItem {
  const DayDoseItem({
    required this.medicine,
    required this.schedule,
    required this.scheduledAt,
    required this.status,
    this.completedAt,
  });

  final Medicine medicine;
  final MedicineSchedule schedule;
  final DateTime scheduledAt;
  final ReminderStatus status;
  final DateTime? completedAt;

  String get timeLabel {
    final h = scheduledAt.hour.toString().padLeft(2, '0');
    final m = scheduledAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get periodLabel {
    final hour = scheduledAt.hour;
    if (hour < 12) return 'Sabah';
    if (hour < 17) return 'Öğle';
    if (hour < 21) return 'Akşam';
    return 'Gece';
  }
}
