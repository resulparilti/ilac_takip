import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/models/alarm_payload.dart';
import 'package:ilac_takip/core/models/water.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/features/medicine/providers/medicine_providers.dart';
import 'package:ilac_takip/features/water/providers/water_providers.dart';
import 'package:ilac_takip/shared/widgets/swipe_to_complete.dart';

class FullScreenAlarmPage extends ConsumerStatefulWidget {
  const FullScreenAlarmPage({super.key, required this.payload});

  final AlarmPayload payload;

  static Future<void> open(BuildContext context, AlarmPayload payload) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (_, _, _) => FullScreenAlarmPage(payload: payload),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  ConsumerState<FullScreenAlarmPage> createState() =>
      _FullScreenAlarmPageState();
}

class _FullScreenAlarmPageState extends ConsumerState<FullScreenAlarmPage> {
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _complete() async {
    if (_completing) return;
    setState(() => _completing = true);

    final payload = widget.payload;
    final notifications = ref.read(notificationServiceProvider);

    switch (payload.kind) {
      case AlarmKind.medicine:
        if (payload.medicineId != null) {
          await ref.read(medicineRepositoryProvider).markDoseTaken(
                medicineId: payload.medicineId!,
                scheduleId: payload.scheduleId,
                scheduledAt: payload.scheduledAt,
              );
          ref.invalidate(dayDosesProvider);
          ref.invalidate(medicinesProvider);
        }
      case AlarmKind.water:
        await ref.read(waterRepositoryProvider).addLog(
              WaterLog(
                amountMl: 200,
                loggedAt: DateTime.now(),
                source: 'reminder',
              ),
            );
        ref.invalidate(waterTodayProvider);
      case AlarmKind.renewal:
        break;
    }

    await notifications.clearAlarm(payload);
    if (payload.kind == AlarmKind.medicine) {
      final isPremium = ref.read(isPremiumProvider);
      await ref.read(missedDoseMonitorProvider).scanAndNotifyIfNeeded(
            isPremium: isPremium,
          );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payload = widget.payload;
    final isWater = payload.kind == AlarmKind.water;
    final accent = isWater ? const Color(0xFF0288D1) : AppColors.primary;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: accent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Icon(
                  isWater
                      ? Icons.water_drop
                      : payload.kind == AlarmKind.renewal
                          ? Icons.medication
                          : Icons.alarm_on,
                  size: 96,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                Text(
                  payload.title,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  payload.body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Text(
                  'Tamamlamak için kaydırın',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SwipeToComplete(
                      label: 'Tamamladım →',
                      onCompleted: _complete,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Butona basmak yetmez; kaydırmanız gerekir.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
