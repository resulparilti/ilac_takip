import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/features/onboarding/presentation/widgets/permission_explanation_card.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _index = 0;
  bool _busy = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index < 2) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      return;
    }
    await _finishWithPermissionsAndConsent();
  }

  Future<void> _finishWithPermissionsAndConsent() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      // Prominent Disclosure bu ekranda zaten gösterildi → şimdi sistem izinleri.
      await ref.read(permissionServiceProvider).requestReminderPermissions();

      final isPremium = ref.read(isPremiumProvider);
      await ref.read(consentAdsServiceProvider).gatherConsentAndInitAds(
            isPremium: isPremium,
          );

      await ref.read(settingsRepositoryProvider).set('onboarding_done', '1');
      ref.read(onboardingDoneProvider.notifier).state = true;

      final isPremiumNow = ref.read(isPremiumProvider);
      await ref.read(reminderSchedulerProvider).rescheduleAll(
            includeWater: isPremiumNow,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _IntroSlide(
                    title: 'İlaçlarınızı unutmayın',
                    body:
                        'İlaç saatlerini, fotoğraf ve yönergelerle takip edin. '
                        'Hatırlatmalar tam zamanında gelir.',
                    icon: Icons.medication_liquid_outlined,
                  ),
                  _IntroSlide(
                    title: 'Su ve sağlık (Premium)',
                    body:
                        'Su hedefleri, istatistikler ve sorumlu kişiye '
                        'acil bildirim Premium özelliklerdir. '
                        'Temel ilaç takibi ücretsizdir.',
                    icon: Icons.water_drop_outlined,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.marginMobile),
                    child: ListView(
                      children: [
                        Text(
                          'İzinler neden gerekli?',
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                        const PermissionExplanationCard(
                          icon: Icons.notifications_active_outlined,
                          title: 'Bildirim izni',
                          body:
                              'İlaç ve su saatlerini kaçırmamanız için '
                              'bildirim göndermemiz gerekir. İzin vermezseniz '
                              'hatırlatmalar çalışmaz.',
                        ),
                        const SizedBox(height: AppSpacing.stackSm),
                        const PermissionExplanationCard(
                          icon: Icons.alarm_on_outlined,
                          title: 'Tam zamanlı alarm',
                          body:
                              'İlaç saatlerini tam vaktinde hatırlatabilmek için '
                              'arka planda çalışma ve kesin alarm iznine '
                              'ihtiyacımız var.',
                        ),
                        const SizedBox(height: AppSpacing.stackSm),
                        Text(
                          'Sonraki adımda sistem izin pencereleri açılır. '
                          'Avrupa bölgelerinde reklam kişiselleştirme onayı '
                          '(UMP) da sorulabilir.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                0,
                AppSpacing.marginMobile,
                AppSpacing.stackMd,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final active = i == _index;
                      return Container(
                        width: active ? 18 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _next,
                      child: _busy
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_index == 2 ? 'İzinleri ver ve başla' : 'Devam'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 88, color: AppColors.primary),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            title,
            style: theme.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
