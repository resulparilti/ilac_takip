import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:ilac_takip/core/models/alarm_payload.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

typedef AlarmTapCallback = void Function(AlarmPayload payload);

/// Yerel bildirim + exact alarm + ongoing kaçırılan hatırlatmalar.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  AlarmTapCallback? onAlarmOpened;
  bool _initialized = false;

  static const _medicineChannelId = 'medicine_alarm';
  static const _waterChannelId = 'water_alarm';
  static const _missedChannelId = 'missed_ongoing';
  static const _renewalChannelId = 'renewal_reminder';

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onResponse,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _medicineChannelId,
          'İlaç alarmı',
          description: 'İlaç hatırlatmaları (yüksek öncelik)',
          importance: Importance.max,
          playSound: true,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _waterChannelId,
          'Su alarmı',
          description: 'Su içme hatırlatmaları',
          importance: Importance.max,
          playSound: true,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _missedChannelId,
          'Kaçırılan hatırlatmalar',
          description: 'Tamamlanana kadar sabit kalan bildirimler',
          importance: Importance.high,
          playSound: false,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _renewalChannelId,
          'İlaç yenileme',
          description: 'Stok / yenileme hatırlatmaları',
          importance: Importance.defaultImportance,
        ),
      );
    }

    _initialized = true;

    final launch = await _plugin.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp == true &&
        response?.payload != null) {
      _dispatchPayload(response!.payload!);
    }
  }

  void _onResponse(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;
    _dispatchPayload(raw);
  }

  void _dispatchPayload(String raw) {
    try {
      final payload = AlarmPayload.fromJson(raw);
      onAlarmOpened?.call(payload);
    } catch (e) {
      if (kDebugMode) debugPrint('Alarm payload parse error: $e');
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> scheduleAlarm({
    required AlarmPayload payload,
    required String ringtoneKey,
  }) async {
    if (!_initialized || kIsWeb) return;

    final id = payload.notificationId ??
        AlarmPayload.buildId(
          kind: payload.kind,
          scheduledAt: payload.scheduledAt,
          medicineId: payload.medicineId,
        );
    final enriched = AlarmPayload(
      kind: payload.kind,
      title: payload.title,
      body: payload.body,
      scheduledAt: payload.scheduledAt,
      medicineId: payload.medicineId,
      scheduleId: payload.scheduleId,
      notificationId: id,
    );

    if (payload.scheduledAt.isBefore(DateTime.now())) {
      return;
    }

    final channelId = switch (payload.kind) {
      AlarmKind.medicine => _medicineChannelId,
      AlarmKind.water => _waterChannelId,
      AlarmKind.renewal => _renewalChannelId,
    };
    final channelName = switch (payload.kind) {
      AlarmKind.medicine => 'İlaç alarmı',
      AlarmKind.water => 'Su alarmı',
      AlarmKind.renewal => 'İlaç yenileme',
    };

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Hatırlatma: $ringtoneKey',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: payload.kind != AlarmKind.renewal,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        subtitle: ringtoneKey,
      ),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: enriched.title,
      body: enriched.body,
      scheduledDate: tz.TZDateTime.from(enriched.scheduledAt, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: enriched.toJson(),
    );

    if (payload.kind != AlarmKind.renewal) {
      final missAt = enriched.scheduledAt.add(const Duration(hours: 1));
      if (missAt.isAfter(DateTime.now())) {
        final missId = id ^ 0x5A5A5A5A;
        await _plugin.zonedSchedule(
          id: missId,
          title: 'Kaçırıldı: ${enriched.title}',
          body: 'Tamamlayana kadar bu bildirim kalır. Dokunun.',
          scheduledDate: tz.TZDateTime.from(missAt, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _missedChannelId,
              'Kaçırılan hatırlatmalar',
              channelDescription: 'Tamamlanana kadar sabit',
              importance: Importance.high,
              priority: Priority.high,
              ongoing: true,
              autoCancel: false,
              category: AndroidNotificationCategory.reminder,
              visibility: NotificationVisibility.public,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: enriched.toJson(),
        );
      }
    }
  }

  Future<void> showNow(AlarmPayload payload) async {
    if (!_initialized || kIsWeb) return;
    final id = payload.notificationId ??
        AlarmPayload.buildId(
          kind: payload.kind,
          scheduledAt: payload.scheduledAt,
          medicineId: payload.medicineId,
        );
    final channelId = payload.kind == AlarmKind.water
        ? _waterChannelId
        : _medicineChannelId;

    await _plugin.show(
      id: id,
      title: payload.title,
      body: payload.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == _waterChannelId ? 'Su alarmı' : 'İlaç alarmı',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: payload.toJson(),
    );
  }

  Future<void> clearAlarm(AlarmPayload payload) async {
    final id = payload.notificationId ??
        AlarmPayload.buildId(
          kind: payload.kind,
          scheduledAt: payload.scheduledAt,
          medicineId: payload.medicineId,
        );
    await cancel(id);
    await cancel(id ^ 0x5A5A5A5A);
  }
}
