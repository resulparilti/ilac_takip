import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Sistem izinleri — her zaman Prominent Disclosure sonrası çağrılmalı.
class PermissionService {
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) return true;
    final result = await Permission.scheduleExactAlarm.request();
    return result.isGranted;
  }

  Future<Map<String, bool>> requestReminderPermissions() async {
    final notification = await requestNotificationPermission();
    final exactAlarm = await requestExactAlarmPermission();
    return {
      'notification': notification,
      'exactAlarm': exactAlarm,
    };
  }

  Future<bool> get notificationsGranted async {
    if (kIsWeb) return true;
    return Permission.notification.isGranted;
  }

  Future<void> openSystemSettings() => openAppSettings();
}
