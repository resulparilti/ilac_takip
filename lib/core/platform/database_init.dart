import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web'de sqflite — shared worker sorunlarını önlemek için no-web-worker.
Future<void> initDatabaseForPlatform() async {
  if (!kIsWeb) return;
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}
