import 'dart:convert';

import 'package:ilac_takip/core/models/enums.dart';

class MedicineSchedule {
  const MedicineSchedule({
    this.id,
    required this.medicineId,
    required this.scheduleType,
    this.times = const [],
    this.intervalHours,
    this.daysOfWeek = const [],
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  final int? id;
  final int medicineId;
  final ScheduleType scheduleType;

  /// "08:00", "14:30" gibi saatler.
  final List<String> times;
  final int? intervalHours;

  /// 1=Pzt … 7=Paz (ISO).
  final List<int> daysOfWeek;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  MedicineSchedule copyWith({
    int? id,
    int? medicineId,
    ScheduleType? scheduleType,
    List<String>? times,
    int? intervalHours,
    List<int>? daysOfWeek,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return MedicineSchedule(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      scheduleType: scheduleType ?? this.scheduleType,
      times: times ?? this.times,
      intervalHours: intervalHours ?? this.intervalHours,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'medicine_id': medicineId,
        'schedule_type': scheduleType.dbValue,
        'times_json': jsonEncode(times),
        'interval_hours': intervalHours,
        'days_of_week_json': jsonEncode(daysOfWeek),
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'is_active': isActive ? 1 : 0,
      };

  factory MedicineSchedule.fromMap(Map<String, Object?> map) {
    List<String> parseTimes(Object? raw) {
      if (raw == null) return [];
      final list = jsonDecode(raw as String) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    }

    List<int> parseDays(Object? raw) {
      if (raw == null) return [];
      final list = jsonDecode(raw as String) as List<dynamic>;
      return list.map((e) => e as int).toList();
    }

    return MedicineSchedule(
      id: map['id'] as int?,
      medicineId: map['medicine_id'] as int,
      scheduleType: ScheduleType.fromDb(map['schedule_type'] as String),
      times: parseTimes(map['times_json']),
      intervalHours: map['interval_hours'] as int?,
      daysOfWeek: parseDays(map['days_of_week_json']),
      startDate: map['start_date'] != null
          ? DateTime.tryParse(map['start_date'] as String)
          : null,
      endDate: map['end_date'] != null
          ? DateTime.tryParse(map['end_date'] as String)
          : null,
      isActive: (map['is_active'] as int?) == 1,
    );
  }
}
