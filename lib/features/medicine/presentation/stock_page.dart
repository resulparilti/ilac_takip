import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/models/enums.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/features/medicine/presentation/medicine_form_page.dart';
import 'package:ilac_takip/features/medicine/presentation/widgets/status_card.dart';
import 'package:ilac_takip/features/medicine/providers/medicine_providers.dart';
import 'package:ilac_takip/shared/widgets/admob_banner.dart';

class StockPage extends ConsumerWidget {
  const StockPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicinesAsync = ref.watch(medicinesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Stok & Yenileme')),
      body: Column(
        children: [
          Expanded(
            child: medicinesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (medicines) {
                if (medicines.isEmpty) {
                  return Center(
                    child: Text(
                      'Stok takibi için önce ilaç ekleyin.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final sorted = [...medicines]
                  ..sort(
                    (a, b) =>
                        b.stockStatus.index.compareTo(a.stockStatus.index),
                  );

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.marginMobile),
                  children: [
                    _Legend(theme: theme),
                    const SizedBox(height: AppSpacing.stackMd),
                    for (final med in sorted) ...[
                      StatusCard(
                        medicine: med,
                        onTap: () async {
                          await MedicineFormPage.open(
                            context,
                            medicineId: med.id,
                          );
                          ref.invalidate(medicinesProvider);
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ),
          const AdMobBanner(),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _dot(AppColors.error, StockStatus.critical.labelTr),
            _dot(AppColors.warning, StockStatus.warning.labelTr),
            _dot(AppColors.success, StockStatus.sufficient.labelTr),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color, String label) {
    return Row(
      children: [
        Icon(Icons.circle, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.labelMedium),
      ],
    );
  }
}
