import 'package:ilac_takip/core/models/emergency_contact.dart';
import 'package:ilac_takip/services/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class SettingsRepository {
  SettingsRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<String?> get(String key) async {
    final db = await _db.database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    final db = await _db.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('settings');
    return {
      for (final row in rows)
        row['key'] as String: row['value'] as String,
    };
  }

  Future<bool> isPremium() async {
    final db = await _db.database;
    final rows = await db.query('subscription', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return false;
    return (rows.first['is_premium'] as int?) == 1;
  }

  Future<void> setPremium({
    required bool isPremium,
    String? productId,
    DateTime? expiresAt,
  }) async {
    final db = await _db.database;
    await db.update(
      'subscription',
      {
        'is_premium': isPremium ? 1 : 0,
        'product_id': productId,
        'expires_at': expiresAt?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = 1',
    );
  }

  Future<List<EmergencyContact>> getEmergencyContacts() async {
    final db = await _db.database;
    final rows = await db.query(
      'emergency_contacts',
      where: 'is_active = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(EmergencyContact.fromMap).toList();
  }

  Future<int> upsertEmergencyContact(EmergencyContact contact) async {
    final db = await _db.database;
    if (contact.id != null) {
      return db.update(
        'emergency_contacts',
        contact.toMap(),
        where: 'id = ?',
        whereArgs: [contact.id],
      );
    }
    final map = contact.toMap()..remove('id');
    return db.insert('emergency_contacts', map);
  }

  Future<void> wipeAllUserData() => _db.wipeAllData();
}
