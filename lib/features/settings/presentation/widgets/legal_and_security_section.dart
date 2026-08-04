import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/config/env_config.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/features/medicine/providers/medicine_providers.dart';
import 'package:ilac_takip/features/water/providers/water_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalAndSecuritySection extends ConsumerWidget {
  const LegalAndSecuritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Yasal & Güvenlik', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(
                'Gizlilik Politikası',
                style: theme.textTheme.titleLarge,
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openUrl(context, EnvConfig.privacyPolicyUrl),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: Text(
                'Kullanım Koşulları',
                style: theme.textTheme.titleLarge,
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openUrl(context, EnvConfig.termsOfUseUrl),
            ),
            const Divider(),
            Text(
              'Tüm ilaç, su, ayar ve iletişim verilerinizi cihazdan kalıcı olarak silebilirsiniz.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              onPressed: () => _confirmWipe(context, ref),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Tüm Verilerimi Sil'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(await canLaunchUrl(uri))) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bağlantı açılamadı. URL’yi kontrol edin.')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm veriler silinsin mi?'),
        content: const Text(
          'İlaçlar, su kayıtları, ayarlar ve acil kişiler silinir. '
          'Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Devam'),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Son onay'),
        content: const Text(
          'Emin misiniz? Tüm verileriniz kalıcı olarak silinecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, sil'),
          ),
        ],
      ),
    );
    if (second != true || !context.mounted) return;

    await ref.read(settingsRepositoryProvider).wipeAllUserData();
    await ref.read(consentAdsServiceProvider).disableAds();

    ref.read(isPremiumProvider.notifier).state = false;
    ref.read(onboardingDoneProvider.notifier).state = false;
    ref.read(uiScaleProvider.notifier).state = UiScale.large;
    ref.invalidate(medicinesProvider);
    ref.invalidate(dayDosesProvider);
    ref.invalidate(waterTodayProvider);
    ref.invalidate(appBootstrapProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm veriler silindi.')),
      );
    }
  }
}
