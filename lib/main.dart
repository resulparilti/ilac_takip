import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/platform/database_init.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/features/alarm/presentation/full_screen_alarm_page.dart';
import 'package:ilac_takip/features/home/presentation/home_shell_page.dart';
import 'package:ilac_takip/features/onboarding/presentation/onboarding_page.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initDatabaseForPlatform();
  } catch (e) {
    debugPrint('DB platform init: $e');
  }
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('dotenv: $e');
  }
  try {
    await initializeDateFormatting('tr_TR');
  } catch (e) {
    debugPrint('date formatting: $e');
  }
  runApp(const ProviderScope(child: IlacTakipApp()));
}

class IlacTakipApp extends ConsumerWidget {
  const IlacTakipApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(uiScaleProvider);
    final bootstrap = ref.watch(appBootstrapProvider);
    final onboardingDone = ref.watch(onboardingDoneProvider);

    ref.listen(pendingAlarmProvider, (prev, next) {
      if (next == null) return;
      final nav = appNavigatorKey.currentContext;
      if (nav != null) {
        FullScreenAlarmPage.open(nav, next);
        ref.read(pendingAlarmProvider.notifier).state = null;
      }
    });

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'İlaç Takip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(scale: scale),
      home: bootstrap.when(
        data: (_) =>
            onboardingDone ? const HomeShellPage() : const OnboardingPage(),
        loading: () => const _BootSplash(),
        error: (e, st) => _BootError(
          message: e.toString(),
          onRetry: () => ref.invalidate(appBootstrapProvider),
        ),
      ),
    );
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _BootError extends StatelessWidget {
  const _BootError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Başlatma hatası',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SelectableText(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
