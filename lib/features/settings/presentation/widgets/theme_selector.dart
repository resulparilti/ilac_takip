import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({
    super.key,
    required this.selectedHex,
    required this.onSelected,
  });

  final String selectedHex;
  final ValueChanged<String> onSelected;

  static const options = <(String, Color)>[
    ('005BBF', Color(0xFF005BBF)),
    ('006E2C', Color(0xFF006E2C)),
    ('0D7377', Color(0xFF0D7377)),
    ('C62828', Color(0xFFC62828)),
    ('5D4037', Color(0xFF5D4037)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Renk teması', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final opt in options)
              InkWell(
                onTap: () => onSelected(opt.$1),
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: opt.$2,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedHex.toUpperCase() == opt.$1
                          ? AppColors.onSurface
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: selectedHex.toUpperCase() == opt.$1
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
