import 'package:flutter/material.dart';

class RingtoneSelector extends StatelessWidget {
  const RingtoneSelector({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String value;
  final ValueChanged<String> onChanged;

  static const options = <(String, String)>[
    ('default_medicine', 'Klasik ilaç zili'),
    ('soft_chime', 'Yumuşak çan'),
    ('bright_alert', 'Net uyarı'),
    ('default_water', 'Su damlası'),
    ('gentle_wave', 'Nazik dalga'),
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: options.any((e) => e.$1 == value) ? value : options.first.$1,
      decoration: InputDecoration(
        labelText: title,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final o in options)
          DropdownMenuItem(value: o.$1, child: Text(o.$2)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
