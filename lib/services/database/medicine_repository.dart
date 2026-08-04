import 'package:ilac_takip/core/models/dose_log.dart';
import 'package:ilac_takip/core/models/enums.dart';
import 'package:ilac_takip/core/models/medicine.dart';
import 'package:ilac_takip/core/models/medicine_schedule.dart';
import 'package:ilac_takip/services/database/app_database.dart';

class MedicineRepository {
  MedicineRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<List<Medicine>> getAll({bool activeOnly = true}) async {
    final db = await _db.database;
    final rows = await db.query(
      'medicines',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Medicine.fromMap).toList();
  }

  Future<Medicine?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Medicine.fromMap(rows.first);
  }

  Future<int> insert(Medicine medicine) async {
    final db = await _db.database;
    final map = medicine.toMap()..remove('id');
    return db.insert('medicines', map);
  }

  Future<int> update(Medicine medicine) async {
    final db = await _db.database;
    return db.update(
      'medicines',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  Future<int> softDelete(int id) async {
    final db = await _db.database;
    return db.update(
      'medicines',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<MedicineSchedule>> getSchedules(int medicineId) async {
    final db = await _db.database;
    final rows = await db.query(
      'schedules',
      where: 'medicine_id = ? AND is_active = 1',
      whereArgs: [medicineId],
    );
    return rows.map(MedicineSchedule.fromMap).toList();
  }

  Future<int> insertSchedule(MedicineSchedule schedule) async {
    final db = await _db.database;
    final map = schedule.toMap()..remove('id');
    return db.insert('schedules', map);
  }

  Future<void> replaceSchedules(int medicineId, List<MedicineSchedule> schedules) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update(
        'schedules',
        {'is_active': 0},
        where: 'medicine_id = ?',
        whereArgs: [medicineId],
      );
      for (final schedule in schedules) {
        final map = schedule.copyWith(medicineId: medicineId).toMap()
          ..remove('id');
        await txn.insert('schedules', map);
      }
    });
  }

  Future<int> saveMedicineWithSchedule({
    required Medicine medicine,
    required MedicineSchedule schedule,
  }) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      late int medicineId;
      if (medicine.id == null) {
        final map = medicine.toMap()..remove('id');
        medicineId = await txn.insert('medicines', map);
      } else {
        medicineId = medicine.id!;
        await txn.update(
          'medicines',
          medicine.toMap(),
          where: 'id = ?',
          whereArgs: [medicineId],
        );
        await txn.update(
          'schedules',
          {'is_active': 0},
          where: 'medicine_id = ?',
          whereArgs: [medicineId],
        );
      }
      final scheduleMap = schedule.copyWith(medicineId: medicineId).toMap()
        ..remove('id');
      await txn.insert('schedules', scheduleMap);
      return medicineId;
    });
  }

  Future<DoseLog?> findDoseLog({
    required int medicineId,
    required DateTime scheduledAt,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'dose_logs',
      where: 'medicine_id = ? AND scheduled_at = ?',
      whereArgs: [medicineId, scheduledAt.toIso8601String()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DoseLog.fromMap(rows.first);
  }

  Future<void> markDoseTaken({
    required int medicineId,
    int? scheduleId,
    required DateTime scheduledAt,
  }) async {
    final existing = await findDoseLog(
      medicineId: medicineId,
      scheduledAt: scheduledAt,
    );
    final now = DateTime.now();
    if (existing?.id != null) {
      await markDoseCompleted(existing!.id!);
    } else {
      await insertDoseLog(
        DoseLog(
          medicineId: medicineId,
          scheduleId: scheduleId,
          scheduledAt: scheduledAt,
          status: ReminderStatus.completed,
          completedAt: now,
        ),
      );
    }

    final med = await getById(medicineId);
    if (med != null && med.stockCount > 0) {
      await update(
        med.copyWith(
          stockCount: med.stockCount - 1,
          updatedAt: now,
        ),
      );
    }
  }

  /// Yanlışlıkla “alındı” işaretini geri alır; stoğu 1 artırır.
  Future<void> undoDoseTaken({
    required int medicineId,
    required DateTime scheduledAt,
  }) async {
    final existing = await findDoseLog(
      medicineId: medicineId,
      scheduledAt: scheduledAt,
    );
    if (existing?.id == null) return;
    if (existing!.status != ReminderStatus.completed) return;

    final db = await _db.database;
    await db.update(
      'dose_logs',
      {
        'status': ReminderStatus.pending.dbValue,
        'completed_at': null,
      },
      where: 'id = ?',
      whereArgs: [existing.id],
    );

    final med = await getById(medicineId);
    if (med != null) {
      await update(
        med.copyWith(
          stockCount: med.stockCount + 1,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<List<MedicineSchedule>> getAllActiveSchedules() async {
    final db = await _db.database;
    final rows = await db.query(
      'schedules',
      where: 'is_active = 1',
    );
    return rows.map(MedicineSchedule.fromMap).toList();
  }

  Future<int> insertDoseLog(DoseLog log) async {
    final db = await _db.database;
    final map = log.toMap()..remove('id');
    return db.insert('dose_logs', map);
  }

  Future<int> markDoseCompleted(int doseLogId) async {
    final db = await _db.database;
    return db.update(
      'dose_logs',
      {
        'status': ReminderStatus.completed.dbValue,
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [doseLogId],
    );
  }

  Future<int> markDoseMissed(int doseLogId) async {
    final db = await _db.database;
    return db.update(
      'dose_logs',
      {'status': ReminderStatus.missed.dbValue},
      where: 'id = ?',
      whereArgs: [doseLogId],
    );
  }

  Future<List<DoseLog>> getMissedDoses({int? medicineId}) async {
    final db = await _db.database;
    final rows = await db.query(
      'dose_logs',
      where: medicineId == null
          ? 'status = ?'
          : 'status = ? AND medicine_id = ?',
      whereArgs: medicineId == null
          ? [ReminderStatus.missed.dbValue]
          : [ReminderStatus.missed.dbValue, medicineId],
      orderBy: 'scheduled_at DESC',
    );
    return rows.map(DoseLog.fromMap).toList();
  }

  Future<int> consecutiveMissedCount(int medicineId) async {
    final db = await _db.database;
    final rows = await db.query(
      'dose_logs',
      where: 'medicine_id = ?',
      whereArgs: [medicineId],
      orderBy: 'scheduled_at DESC',
      limit: 10,
    );
    var count = 0;
    for (final row in rows) {
      if (row['status'] == ReminderStatus.missed.dbValue) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }
}
