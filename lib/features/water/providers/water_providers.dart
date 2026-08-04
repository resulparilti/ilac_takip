import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/models/water.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';

class WaterTodayState {
  const WaterTodayState({
    required this.goal,
    required this.totalMl,
    required this.logs,
    required this.reminderTimes,
  });

  final WaterGoal goal;
  final int totalMl;
  final List<WaterLog> logs;
  final List<String> reminderTimes;

  double get progress =>
      goal.dailyTargetMl <= 0 ? 0 : (totalMl / goal.dailyTargetMl).clamp(0, 1.5);
}

final waterTodayProvider =
    FutureProvider.autoDispose<WaterTodayState>((ref) async {
  final repo = ref.watch(waterRepositoryProvider);
  final goal = await repo.getGoal() ??
      WaterGoal(updatedAt: DateTime.now());
  final total = await repo.todayTotalMl();
  final logs = await repo.logsForDay(DateTime.now());
  final times = repo.buildReminderTimes(goal);
  return WaterTodayState(
    goal: goal,
    totalMl: total,
    logs: logs,
    reminderTimes: times,
  );
});
