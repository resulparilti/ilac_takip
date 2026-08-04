import 'package:flutter/material.dart';
import 'package:ilac_takip/core/models/enums.dart';

class ConditionDropdown extends StatelessWidget {
  const ConditionDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final MedicineCondition value;
  final ValueChanged<MedicineCondition> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<MedicineCondition>(
      // ignore: deprecated_member_use
      value: value,
      decoration: const InputDecoration(
        labelText: 'Kullanım koşulu',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final c in MedicineCondition.values)
          DropdownMenuItem(value: c, child: Text(c.labelTr)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
