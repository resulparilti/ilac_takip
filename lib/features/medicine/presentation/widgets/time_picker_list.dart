import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

class TimePickerList extends StatelessWidget {
  const TimePickerList({
    super.key,
    required this.times,
    required this.onChanged,
  });

  final List<String> times;
  final ValueChanged<List<String>> onChanged;

  Future<void> _add(BuildContext context) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      helpText: 'İlaç saati seçin',
    );
    if (picked == null) return;
    final label =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (times.contains(label)) return;
    final next = [...times, label]..sort();
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Saatler', style: theme.textTheme.titleLarge),
            ),
            TextButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add),
              label: const Text('Saat ekle'),
            ),
          ],
        ),
        if (times.isEmpty)
          Text(
            'En az bir saat ekleyin.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in times)
                InputChip(
                  label: Text(t, style: theme.textTheme.labelLarge),
                  onDeleted: () {
                    onChanged(times.where((e) => e != t).toList());
                  },
                  deleteIconColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
