import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/config/env_config.dart';
import 'package:ilac_takip/core/models/alarm_payload.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/features/alarm/presentation/full_screen_alarm_page.dart';
import 'package:ilac_takip/features/medicine/presentation/stock_page.dart';
import 'package:ilac_takip/features/premium/presentation/paywall_page.dart';
import 'package:ilac_takip/features/settings/presentation/widgets/emergency_contact_section.dart';
import 'package:ilac_takip/features/settings/presentation/widgets/legal_and_security_section.dart';
import 'package:ilac_takip/features/settings/presentation/widgets/ringtone_selector.dart';
import 'package:ilac_takip/features/settings/presentation/widgets/size_slider.dart';
import 'package:ilac_takip/features/settings/presentation/widgets/theme_selector.dart';

final themePrimaryHexProvider = StateProvider<String>((ref) => '005BBF');
final medicineRingtoneProvider =
    StateProvider<String>((ref) => 'default_medicine');
final waterRingtoneProvider = StateProvider<String>((ref) => 'default_water');

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = ref.read(settingsRepositoryProvider);
    final theme = await settings.get('theme_primary');
    final medTone = await settings.get('medicine_ringtone');
    final waterTone = await settings.get('water_ringtone');
    if (theme != null) {
      ref.read(themePrimaryHexProvider.notifier).state = theme;
    }
    if (medTone != null) {
      ref.read(medicineRingtoneProvider.notifier).state = medTone;
    }
    if (waterTone != null) {
      ref.read(waterRingtoneProvider.notifier).state = waterTone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = ref.watch(uiScaleProvider);
    final primaryHex = ref.watch(themePrimaryHexProvider);
    final medTone = ref.watch(medicineRingtoneProvider);
    final waterTone = ref.watch(waterRingtoneProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isPremium ? Icons.workspace_premium : Icons.star_outline,
              color: AppColors.primary,
              size: 32,
            ),
            title: Text(
              isPremium ? 'Premium aktif' : 'Ücretsiz sürüm',
              style: theme.textTheme.headlineMedium,
            ),
            subtitle: Text(
              isPremium
                  ? 'Reklamsız deneyim'
                  : '${EnvConfig.premiumPriceTry} TL/ay ile Premium',
            ),
            trailing: isPremium
                ? null
                : FilledButton(
                    onPressed: () => PaywallPage.open(context),
                    child: const Text('Yükselt'),
                  ),
          ),
          const Divider(height: 32),
          ThemeSelector(
            selectedHex: primaryHex,
            onSelected: (hex) async {
              ref.read(themePrimaryHexProvider.notifier).state = hex;
              await ref
                  .read(settingsRepositoryProvider)
                  .set('theme_primary', hex);
            },
          ),
          const SizedBox(height: AppSpacing.stackMd),
          SizeSlider(
            value: scale,
            onChanged: (v) async {
              ref.read(uiScaleProvider.notifier).state = v;
              await ref
                  .read(settingsRepositoryProvider)
                  .set('ui_scale', v.name);
            },
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text('Zil sesleri', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 12),
          RingtoneSelector(
            title: 'İlaç zili',
            value: medTone,
            onChanged: (v) async {
              ref.read(medicineRingtoneProvider.notifier).state = v;
              await ref
                  .read(settingsRepositoryProvider)
                  .set('medicine_ringtone', v);
            },
          ),
          const SizedBox(height: 12),
          RingtoneSelector(
            title: 'Su zili',
            value: waterTone,
            onChanged: (v) async {
              ref.read(waterRingtoneProvider.notifier).state = v;
              await ref
                  .read(settingsRepositoryProvider)
                  .set('water_ringtone', v);
            },
          ),
          const SizedBox(height: AppSpacing.stackMd),
          const EmergencyContactSection(),
          const SizedBox(height: AppSpacing.stackMd),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.inventory_2_outlined, size: 28),
            title: Text('Stok & Yenileme', style: theme.textTheme.titleLarge),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const StockPage()),
              );
            },
          ),
          const SizedBox(height: AppSpacing.stackMd),
          const LegalAndSecuritySection(),
          const SizedBox(height: AppSpacing.stackMd),
          OutlinedButton.icon(
            onPressed: () async {
              final payload = AlarmPayload(
                kind: AlarmKind.medicine,
                title: 'Test ilaç alarmı',
                body: 'Kaydırarak tamamlayın',
                scheduledAt: DateTime.now(),
              );
              await ref.read(notificationServiceProvider).showNow(payload);
              if (context.mounted) {
                await FullScreenAlarmPage.open(context, payload);
              }
            },
            icon: const Icon(Icons.alarm),
            label: const Text('Alarm ekranını test et'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
