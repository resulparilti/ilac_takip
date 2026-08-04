import 'package:ilac_takip/core/models/enums.dart';

class DoseLog {
  const DoseLog({
    this.id,
    required this.medicineId,
    this.scheduleId,
    required this.scheduledAt,
    required this.status,
    this.completedAt,
    this.note,
  });

  final int? id;
  final int medicineId;
  final int? scheduleId;
  final DateTime scheduledAt;
  final ReminderStatus status;
  final DateTime? completedAt;
  final String? note;

  Map<String, Object?> toMap() => {
        'id': id,
        'medicine_id': medicineId,
        'schedule_id': scheduleId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': status.dbValue,
        'completed_at': completedAt?.toIso8601String(),
        'note': note,
      };

  factory DoseLog.fromMap(Map<String, Object?> map) => DoseLog(
        id: map['id'] as int?,
        medicineId: map['medicine_id'] as int,
        scheduleId: map['schedule_id'] as int?,
        scheduledAt: DateTime.parse(map['scheduled_at'] as String),
        status: ReminderStatus.fromDb(map['status'] as String),
        completedAt: map['completed_at'] != null
            ? DateTime.tryParse(map['completed_at'] as String)
            : null,
        note: map['note'] as String?,
      );
}
