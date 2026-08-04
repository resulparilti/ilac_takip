import 'package:ilac_takip/core/models/water.dart';
import 'package:ilac_takip/services/database/app_database.dart';

class WaterRepository {
  WaterRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<WaterGoal?> getGoal() async {
    final db = await _db.database;
    final rows = await db.query(
      'water_goals',
      where: 'is_active = 1',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WaterGoal.fromMap(rows.first);
  }

  Future<int> upsertGoal(WaterGoal goal) async {
    final db = await _db.database;
    final existing = await getGoal();
    final map = goal.copyWith(updatedAt: DateTime.now()).toMap();
    if (existing?.id != null) {
      map['id'] = existing!.id;
      return db.update(
        'water_goals',
        map,
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
    map.remove('id');
    return db.insert('water_goals', map);
  }

  Future<int> addLog(WaterLog log) async {
    final db = await _db.database;
    final map = log.toMap()..remove('id');
    return db.insert('water_logs', map);
  }

  Future<int> todayTotalMl() async {
    final db = await _db.database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount_ml), 0) AS total
      FROM water_logs
      WHERE logged_at >= ? AND logged_at < ? AND status = 'completed'
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<List<WaterLog>> logsForDay(DateTime day) async {
    final db = await _db.database;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      'water_logs',
      where: 'logged_at >= ? AND logged_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'logged_at DESC',
    );
    return rows.map(WaterLog.fromMap).toList();
  }

  /// Hedef aralığında eşit aralıklı hatırlatma saatleri üretir.
  List<String> buildReminderTimes(WaterGoal goal) {
    final startParts = goal.startTime.split(':');
    final endParts = goal.endTime.split(':');
    final startMin =
        (int.tryParse(startParts[0]) ?? 8) * 60 +
        (startParts.length > 1 ? int.tryParse(startParts[1]) ?? 0 : 0);
    final endMin =
        (int.tryParse(endParts[0]) ?? 22) * 60 +
        (endParts.length > 1 ? int.tryParse(endParts[1]) ?? 0 : 0);
    final count = goal.reminderCount.clamp(1, 12);
    if (count == 1) {
      final mid = ((startMin + endMin) / 2).round();
      return [_fmt(mid)];
    }
    final span = (endMin - startMin).clamp(60, 24 * 60);
    final step = span / (count - 1);
    return List.generate(count, (i) => _fmt((startMin + step * i).round()));
  }

  String _fmt(int totalMinutes) {
    final h = (totalMinutes ~/ 60).clamp(0, 23);
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
