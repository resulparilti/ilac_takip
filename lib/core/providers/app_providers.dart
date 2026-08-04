import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/models/alarm_payload.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/features/alarm/presentation/full_screen_alarm_page.dart';
import 'package:ilac_takip/services/ads/consent_ads_service.dart';
import 'package:ilac_takip/services/database/app_database.dart';
import 'package:ilac_takip/services/database/medicine_repository.dart';
import 'package:ilac_takip/services/database/settings_repository.dart';
import 'package:ilac_takip/services/database/water_repository.dart';
import 'package:ilac_takip/services/emergency/emergency_notify_service.dart';
import 'package:ilac_takip/services/emergency/missed_dose_monitor.dart';
import 'package:ilac_takip/services/notifications/notification_service.dart';
import 'package:ilac_takip/services/notifications/reminder_scheduler.dart';
import 'package:ilac_takip/services/permissions/permission_service.dart';
import 'package:ilac_takip/services/subscription/subscription_service.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  return MedicineRepository(db: ref.watch(appDatabaseProvider));
});

final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  return WaterRepository(db: ref.watch(appDatabaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(db: ref.watch(appDatabaseProvider));
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

final consentAdsServiceProvider = Provider<ConsentAdsService>((ref) {
  return ConsentAdsService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final emergencyNotifyServiceProvider = Provider<EmergencyNotifyService>((ref) {
  return EmergencyNotifyService();
});

final missedDoseMonitorProvider = Provider<MissedDoseMonitor>((ref) {
  return MissedDoseMonitor(
    medicines: ref.watch(medicineRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    notifier: ref.watch(emergencyNotifyServiceProvider),
  );
});

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return ReminderScheduler(
    notifications: ref.watch(notificationServiceProvider),
    medicines: ref.watch(medicineRepositoryProvider),
    water: ref.watch(waterRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
  );
});

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(settings: ref.watch(settingsRepositoryProvider));
});

final uiScaleProvider = StateProvider<UiScale>((ref) => UiScale.large);
final isPremiumProvider = StateProvider<bool>((ref) => false);
final onboardingDoneProvider = StateProvider<bool>((ref) => false);
final pendingAlarmProvider = StateProvider<AlarmPayload?>((ref) => null);

Future<void> applyPremiumState(WidgetRef ref, bool isPremium) async {
  ref.read(isPremiumProvider.notifier).state = isPremium;
  if (isPremium) {
    await ref.read(consentAdsServiceProvider).disableAds();
  } else {
    await ref.read(consentAdsServiceProvider).gatherConsentAndInitAds(
          isPremium: false,
        );
  }
  await ref.read(reminderSchedulerProvider).rescheduleAll(
        includeWater: isPremium,
      );
}

final appBootstrapProvider = FutureProvider<void>((ref) async {
  try {
    debugPrint('Bootstrap: DB açılıyor…');
    final db = ref.read(appDatabaseProvider);
    await db.database;
    debugPrint('Bootstrap: DB hazır');

    final settings = ref.read(settingsRepositoryProvider);
    var premium = await settings.isPremium();
    ref.read(isPremiumProvider.notifier).state = premium;

    final scaleKey = await settings.get('ui_scale');
    final scale = UiScale.values.firstWhere(
      (e) => e.name == scaleKey,
      orElse: () => UiScale.large,
    );
    ref.read(uiScaleProvider.notifier).state = scale;

    final onboarding = await settings.get('onboarding_done');
    final done = onboarding == '1';
    ref.read(onboardingDoneProvider.notifier).state = done;
    debugPrint('Bootstrap: ayarlar yüklendi (onboarding=$done)');

    final notifications = ref.read(notificationServiceProvider);
    try {
      await notifications.init();
      notifications.onAlarmOpened = (payload) {
        ref.read(pendingAlarmProvider.notifier).state = payload;
        final nav = appNavigatorKey.currentContext;
        if (nav != null) {
          FullScreenAlarmPage.open(nav, payload);
          ref.read(pendingAlarmProvider.notifier).state = null;
        }
      };
    } catch (e) {
      debugPrint('Bildirim init atlandı: $e');
    }

    try {
      final subscription = ref.read(subscriptionServiceProvider);
      await subscription.init(
        onPremiumChanged: (value) async {
          ref.read(isPremiumProvider.notifier).state = value;
          if (value) {
            await ref.read(consentAdsServiceProvider).disableAds();
          }
          await ref.read(reminderSchedulerProvider).rescheduleAll(
                includeWater: value,
              );
        },
      );
      premium = await settings.isPremium();
      ref.read(isPremiumProvider.notifier).state = premium;
    } catch (e) {
      debugPrint('Abonelik init atlandı: $e');
    }

    if (done) {
      try {
        await ref.read(consentAdsServiceProvider).gatherConsentAndInitAds(
              isPremium: premium,
            );
      } catch (e) {
        debugPrint('Ads init atlandı: $e');
      }
      try {
        await ref.read(reminderSchedulerProvider).rescheduleAll(
              includeWater: premium,
            );
      } catch (e) {
        debugPrint('Zamanlama atlandı: $e');
      }
      try {
        await ref.read(missedDoseMonitorProvider).scanAndNotifyIfNeeded(
              isPremium: premium,
            );
      } catch (e) {
        debugPrint('Kaçırma tarama atlandı: $e');
      }
    }
    debugPrint('Bootstrap: tamam');
  } catch (e, st) {
    debugPrint('Bootstrap hata: $e\n$st');
    rethrow;
  }
});
