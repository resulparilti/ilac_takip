import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/features/premium/presentation/paywall_page.dart';

/// Premium özellik kilidi — Free kullanıcıya paywall gösterir.
class PremiumGate extends ConsumerWidget {
  const PremiumGate({
    super.key,
    required this.child,
    required this.featureTitle,
    required this.featureBody,
  });

  final Widget child;
  final String featureTitle;
  final String featureBody;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) return child;

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(featureTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 72, color: AppColors.primary),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              featureTitle,
              style: theme.textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              featureBody,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackLg),
            FilledButton(
              onPressed: () => PaywallPage.open(context),
              child: const Text('Premium’a geç'),
            ),
          ],
        ),
      ),
    );
  }
}
