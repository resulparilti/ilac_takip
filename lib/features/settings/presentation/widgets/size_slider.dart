import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

class SizeSlider extends StatelessWidget {
  const SizeSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final UiScale value;
  final ValueChanged<UiScale> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = UiScale.values.indexOf(value).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Yazı ve buton boyutu', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          switch (value) {
            UiScale.normal => 'Normal',
            UiScale.large => 'Büyük (önerilen)',
            UiScale.extraLarge => 'Çok büyük',
          },
          style: theme.textTheme.bodyLarge,
        ),
        Slider(
          value: index,
          min: 0,
          max: (UiScale.values.length - 1).toDouble(),
          divisions: UiScale.values.length - 1,
          label: value.name,
          onChanged: (v) => onChanged(UiScale.values[v.round()]),
        ),
      ],
    );
  }
}
