class WaterGoal {
  const WaterGoal({
    this.id,
    this.dailyTargetMl = 2000,
    this.reminderCount = 6,
    this.startTime = '08:00',
    this.endTime = '22:00',
    this.isActive = true,
    required this.updatedAt,
  });

  final int? id;
  final int dailyTargetMl;
  final int reminderCount;
  final String startTime;
  final String endTime;
  final bool isActive;
  final DateTime updatedAt;

  WaterGoal copyWith({
    int? id,
    int? dailyTargetMl,
    int? reminderCount,
    String? startTime,
    String? endTime,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return WaterGoal(
      id: id ?? this.id,
      dailyTargetMl: dailyTargetMl ?? this.dailyTargetMl,
      reminderCount: reminderCount ?? this.reminderCount,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'daily_target_ml': dailyTargetMl,
        'reminder_count': reminderCount,
        'start_time': startTime,
        'end_time': endTime,
        'is_active': isActive ? 1 : 0,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory WaterGoal.fromMap(Map<String, Object?> map) => WaterGoal(
        id: map['id'] as int?,
        dailyTargetMl: (map['daily_target_ml'] as int?) ?? 2000,
        reminderCount: (map['reminder_count'] as int?) ?? 6,
        startTime: (map['start_time'] as String?) ?? '08:00',
        endTime: (map['end_time'] as String?) ?? '22:00',
        isActive: (map['is_active'] as int?) == 1,
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}

class WaterLog {
  const WaterLog({
    this.id,
    required this.amountMl,
    required this.loggedAt,
    this.source = 'manual',
    this.status = 'completed',
  });

  final int? id;
  final int amountMl;
  final DateTime loggedAt;
  final String source;
  final String status;

  Map<String, Object?> toMap() => {
        'id': id,
        'amount_ml': amountMl,
        'logged_at': loggedAt.toIso8601String(),
        'source': source,
        'status': status,
      };

  factory WaterLog.fromMap(Map<String, Object?> map) => WaterLog(
        id: map['id'] as int?,
        amountMl: map['amount_ml'] as int,
        loggedAt: DateTime.parse(map['logged_at'] as String),
        source: (map['source'] as String?) ?? 'manual',
        status: (map['status'] as String?) ?? 'completed',
      );
}
