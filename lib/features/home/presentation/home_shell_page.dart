import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/features/medicine/presentation/dashboard_page.dart';
import 'package:ilac_takip/features/settings/presentation/settings_page.dart';
import 'package:ilac_takip/features/stats/presentation/stats_page.dart';
import 'package:ilac_takip/features/water/presentation/water_page.dart';

/// Ana kabuk: İlaçlar / Su / İstatistik / Ayarlar.
class HomeShellPage extends ConsumerStatefulWidget {
  const HomeShellPage({super.key});

  @override
  ConsumerState<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends ConsumerState<HomeShellPage>
    with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final isPremium = ref.read(isPremiumProvider);
      ref.read(missedDoseMonitorProvider).scanAndNotifyIfNeeded(
            isPremium: isPremium,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardPage(),
          WaterPage(),
          StatsPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined, size: 30),
            selectedIcon: Icon(Icons.medical_services, size: 30),
            label: 'İlaçlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined, size: 30),
            selectedIcon: Icon(Icons.water_drop, size: 30),
            label: 'Su',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, size: 30),
            selectedIcon: Icon(Icons.bar_chart, size: 30),
            label: 'İstatistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, size: 30),
            selectedIcon: Icon(Icons.settings, size: 30),
            label: 'Ayarlar',
          ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      ),
    );
  }
}
