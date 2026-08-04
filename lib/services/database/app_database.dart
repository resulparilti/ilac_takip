import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// SQLite tek giriş noktası. Şema v1 — Adım 2.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'ilac_takip.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    // Web: WASM + IndexedDB kararsız olabiliyor; UI testi için bellek içi DB.
    final path =
        kIsWeb ? inMemoryDatabasePath : p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        if (!kIsWeb) {
          await db.execute('PRAGMA foreign_keys = ON');
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT,
        instructions TEXT,
        photo_path TEXT,
        condition_type TEXT,
        stock_count INTEGER DEFAULT 0,
        stock_low_threshold INTEGER DEFAULT 5,
        renewal_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_id INTEGER NOT NULL,
        schedule_type TEXT NOT NULL,
        times_json TEXT,
        interval_hours INTEGER,
        days_of_week_json TEXT,
        start_date TEXT,
        end_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (medicine_id) REFERENCES medicines (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE dose_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_id INTEGER NOT NULL,
        schedule_id INTEGER,
        scheduled_at TEXT NOT NULL,
        status TEXT NOT NULL,
        completed_at TEXT,
        note TEXT,
        FOREIGN KEY (medicine_id) REFERENCES medicines (id) ON DELETE CASCADE,
        FOREIGN KEY (schedule_id) REFERENCES schedules (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE renewals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_id INTEGER NOT NULL,
        remind_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (medicine_id) REFERENCES medicines (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE water_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        daily_target_ml INTEGER NOT NULL DEFAULT 2000,
        reminder_count INTEGER NOT NULL DEFAULT 6,
        start_time TEXT DEFAULT '08:00',
        end_time TEXT DEFAULT '22:00',
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE water_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount_ml INTEGER NOT NULL,
        logged_at TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual',
        status TEXT NOT NULL DEFAULT 'completed'
      )
    ''');

    await db.execute('''
      CREATE TABLE water_reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scheduled_at TEXT NOT NULL,
        status TEXT NOT NULL,
        completed_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE emergency_contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        notify_whatsapp INTEGER NOT NULL DEFAULT 1,
        notify_sms INTEGER NOT NULL DEFAULT 0,
        notify_email INTEGER NOT NULL DEFAULT 0,
        miss_threshold INTEGER NOT NULL DEFAULT 2,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subscription (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        is_premium INTEGER NOT NULL DEFAULT 0,
        product_id TEXT,
        expires_at TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    final now = DateTime.now().toIso8601String();
    await db.insert('water_goals', {
      'daily_target_ml': 2000,
      'reminder_count': 6,
      'start_time': '08:00',
      'end_time': '22:00',
      'is_active': 1,
      'updated_at': now,
    });

    await db.insert('subscription', {
      'id': 1,
      'is_premium': 0,
      'product_id': null,
      'expires_at': null,
      'updated_at': now,
    });

    await db.insert('settings', {
      'key': 'ui_scale',
      'value': 'large',
    });
    await db.insert('settings', {
      'key': 'medicine_ringtone',
      'value': 'default_medicine',
    });
    await db.insert('settings', {
      'key': 'water_ringtone',
      'value': 'default_water',
    });
    await db.insert('settings', {
      'key': 'theme_primary',
      'value': '005BBF',
    });
    await db.insert('settings', {
      'key': 'onboarding_done',
      'value': '0',
    });
  }

  /// Ayarlar → “Tüm Verilerimi Sil” için.
  Future<void> wipeAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('dose_logs');
      await txn.delete('water_logs');
      await txn.delete('water_reminders');
      await txn.delete('renewals');
      await txn.delete('schedules');
      await txn.delete('medicines');
      await txn.delete('emergency_contacts');
      await txn.delete('water_goals');
      await txn.delete('settings');
      await txn.delete('subscription');
    });
    await _db?.close();
    _db = null;
    final path = kIsWeb ? _dbName : p.join(await getDatabasesPath(), _dbName);
    await deleteDatabase(path);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
