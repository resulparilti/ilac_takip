import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/config/env_config.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PaywallPage()),
    );
  }

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  bool _busy = false;

  Future<void> _buy() async {
    setState(() => _busy = true);
    try {
      final iap = ref.read(subscriptionServiceProvider);
      final started = await iap.buyPremium();
      if (!started && mounted) {
        // Emülatör / ürün tanımsız: geliştirme fallback
        await ref.read(settingsRepositoryProvider).setPremium(
              isPremium: true,
              productId: EnvConfig.premiumSubscriptionId,
            );
        await applyPremiumState(ref, true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Play ürünü yoksa test Premium açıldı. Yayın için Console’da abonelik tanımlayın.',
              ),
            ),
          );
          Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await ref.read(subscriptionServiceProvider).restorePurchases(
            onPremiumChanged: (v) async {
              await applyPremiumState(ref, v);
            },
          );
      final premium = ref.read(isPremiumProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              premium
                  ? 'Satın alımlar geri yüklendi.'
                  : 'Geri yüklenecek satın alma bulunamadı.',
            ),
          ),
        );
        if (premium) Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = EnvConfig.premiumPriceTry;
    final isPremium = ref.watch(isPremiumProvider);
    final productId = EnvConfig.premiumSubscriptionId;

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          children: [
            Text(
              'Reklamsız ve eksiksiz deneyim',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'Aylık $price TL ile Premium özellikleri açın.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ürün: $productId',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            const _FeatureRow(
              icon: Icons.water_drop,
              title: 'Su içme takibi',
              subtitle: 'Hedef, uyarı sıklığı ve görsel ilerleme',
            ),
            const _FeatureRow(
              icon: Icons.bar_chart,
              title: 'Gelişmiş istatistikler',
              subtitle: 'Uyumluluk grafikleri ve kaçırılanlar',
            ),
            const _FeatureRow(
              icon: Icons.family_restroom,
              title: 'Acil bildirim',
              subtitle: 'Peş peşe kaçırmada sorumlu kişiye haber',
            ),
            const _FeatureRow(
              icon: Icons.block,
              title: 'Reklamsız kullanım',
              subtitle: 'Banner ve geçiş reklamları kapanır',
            ),
            const SizedBox(height: AppSpacing.stackLg),
            if (isPremium)
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context),
                child: const Text('Premium aktif'),
              )
            else ...[
              FilledButton(
                onPressed: _busy ? null : _buy,
                child: _busy
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Premium’a geç — $price TL/ay'),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              TextButton(
                onPressed: _busy ? null : _restore,
                child: const Text('Satın alımları geri yükle'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary, size: 32),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
