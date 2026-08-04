import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/models/water.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/features/water/presentation/widgets/quick_add_button.dart';
import 'package:ilac_takip/features/water/presentation/widgets/upcoming_reminders_list.dart';
import 'package:ilac_takip/features/water/presentation/widgets/water_progress_bar.dart';
import 'package:ilac_takip/features/water/providers/water_providers.dart';
import 'package:ilac_takip/shared/widgets/premium_gate.dart';

class WaterPage extends ConsumerWidget {
  const WaterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumGate(
      featureTitle: 'Su İçme Takibi',
      featureBody:
          'Günlük su hedefi, uyarı sıklığı ve görsel ilerleme Premium özelliktir.',
      child: const _WaterContent(),
    );
  }
}

class _WaterContent extends ConsumerWidget {
  const _WaterContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(waterTodayProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Su'),
        actions: [
          IconButton(
            tooltip: 'Hedef ayarları',
            onPressed: () => _editGoal(context, ref),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (state) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            children: [
              WaterProgressBar(
                currentMl: state.totalMl,
                targetMl: state.goal.dailyTargetMl,
                progress: state.progress,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text('Hızlı ekle', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ml in [100, 200, 250, 330, 500])
                    QuickAddButton(
                      amountMl: ml,
                      onAdd: () => _add(ref, ml),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _addCustom(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Ekstra su içtim'),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              UpcomingRemindersList(times: state.reminderTimes),
              if (state.logs.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.stackMd),
                Text('Bugünkü kayıtlar', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                for (final log in state.logs)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.local_drink_outlined),
                    title: Text(
                      '+${log.amountMl} ml',
                      style: theme.textTheme.titleLarge,
                    ),
                    subtitle: Text(
                      _fmt(log.loggedAt),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _add(WidgetRef ref, int ml) async {
    await ref.read(waterRepositoryProvider).addLog(
          WaterLog(amountMl: ml, loggedAt: DateTime.now()),
        );
    ref.invalidate(waterTodayProvider);
  }

  Future<void> _addCustom(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: '200');
    final ml = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ekstra su'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Miktar (ml)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(ctrl.text.trim()) ?? 0),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    if (ml != null && ml > 0) await _add(ref, ml);
  }

  Future<void> _editGoal(BuildContext context, WidgetRef ref) async {
    final current = await ref.read(waterRepositoryProvider).getGoal() ??
        WaterGoal(updatedAt: DateTime.now());
    if (!context.mounted) return;
    final targetCtrl =
        TextEditingController(text: '${current.dailyTargetMl}');
    var reminderCount = current.reminderCount;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                0,
                AppSpacing.marginMobile,
                MediaQuery.viewInsetsOf(ctx).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Su hedefi',
                    style: Theme.of(ctx).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Günlük hedef (ml)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Günde kaç uyarı: $reminderCount'),
                  Slider(
                    value: reminderCount.toDouble(),
                    min: 2,
                    max: 12,
                    divisions: 10,
                    label: '$reminderCount',
                    onChanged: (v) =>
                        setModal(() => reminderCount = v.round()),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Kaydet'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      await ref.read(waterRepositoryProvider).upsertGoal(
            current.copyWith(
              dailyTargetMl: int.tryParse(targetCtrl.text) ?? 2000,
              reminderCount: reminderCount,
              updatedAt: DateTime.now(),
            ),
          );
      ref.invalidate(waterTodayProvider);
      final isPremium = ref.read(isPremiumProvider);
      await ref.read(reminderSchedulerProvider).rescheduleAll(
            includeWater: isPremium,
          );
    }
  }
}
