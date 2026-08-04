import 'dart:convert';

enum AlarmKind { medicine, water, renewal }

class AlarmPayload {
  const AlarmPayload({
    required this.kind,
    required this.title,
    required this.body,
    required this.scheduledAt,
    this.medicineId,
    this.scheduleId,
    this.notificationId,
  });

  final AlarmKind kind;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final int? medicineId;
  final int? scheduleId;
  final int? notificationId;

  String toJson() => jsonEncode({
        'kind': kind.name,
        'title': title,
        'body': body,
        'scheduledAt': scheduledAt.toIso8601String(),
        'medicineId': medicineId,
        'scheduleId': scheduleId,
        'notificationId': notificationId,
      });

  factory AlarmPayload.fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return AlarmPayload(
      kind: AlarmKind.values.firstWhere(
        (e) => e.name == map['kind'],
        orElse: () => AlarmKind.medicine,
      ),
      title: map['title'] as String? ?? 'Hatırlatma',
      body: map['body'] as String? ?? '',
      scheduledAt: DateTime.parse(map['scheduledAt'] as String),
      medicineId: map['medicineId'] as int?,
      scheduleId: map['scheduleId'] as int?,
      notificationId: map['notificationId'] as int?,
    );
  }

  /// Kararlı bildirim kimliği.
  static int buildId({
    required AlarmKind kind,
    required DateTime scheduledAt,
    int? medicineId,
  }) {
    final key =
        '${kind.name}|${medicineId ?? 0}|${scheduledAt.toIso8601String()}';
    return key.hashCode & 0x7fffffff;
  }
}
