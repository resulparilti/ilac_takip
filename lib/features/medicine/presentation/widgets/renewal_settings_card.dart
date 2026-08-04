import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

class RenewalSettingsCard extends StatelessWidget {
  const RenewalSettingsCard({
    super.key,
    required this.stockCount,
    required this.stockLowThreshold,
    required this.renewalDate,
    required this.onStockChanged,
    required this.onThresholdChanged,
    required this.onRenewalDateChanged,
  });

  final int stockCount;
  final int stockLowThreshold;
  final DateTime? renewalDate;
  final ValueChanged<int> onStockChanged;
  final ValueChanged<int> onThresholdChanged;
  final ValueChanged<DateTime?> onRenewalDateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Stok & Yenileme', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: '$stockCount',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Mevcut stok (adet)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => onStockChanged(int.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: '$stockLowThreshold',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Uyarı eşiği',
                border: OutlineInputBorder(),
                helperText: 'Stok bu sayının altına düşünce uyarı',
              ),
              onChanged: (v) => onThresholdChanged(int.tryParse(v) ?? 5),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Yenileme tarihi'),
              subtitle: Text(
                renewalDate == null
                    ? 'Seçilmedi'
                    : '${renewalDate!.day}.${renewalDate!.month}.${renewalDate!.year}',
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: renewalDate ?? DateTime.now().add(
                    const Duration(days: 30),
                  ),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                onRenewalDateChanged(picked);
              },
            ),
          ],
        ),
      ),
    );
  }
}
