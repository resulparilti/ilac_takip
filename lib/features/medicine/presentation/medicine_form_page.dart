import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/models/enums.dart';
import 'package:ilac_takip/core/models/medicine.dart';
import 'package:ilac_takip/core/models/medicine_schedule.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/features/medicine/presentation/widgets/condition_dropdown.dart';
import 'package:ilac_takip/features/medicine/presentation/widgets/photo_picker_widget.dart';
import 'package:ilac_takip/features/medicine/presentation/widgets/renewal_settings_card.dart';
import 'package:ilac_takip/features/medicine/presentation/widgets/time_picker_list.dart';
import 'package:ilac_takip/features/medicine/providers/medicine_providers.dart';

class MedicineFormPage extends ConsumerStatefulWidget {
  const MedicineFormPage({super.key, this.medicineId});

  final int? medicineId;

  static Future<bool?> open(BuildContext context, {int? medicineId}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MedicineFormPage(medicineId: medicineId),
      ),
    );
  }

  @override
  ConsumerState<MedicineFormPage> createState() => _MedicineFormPageState();
}

class _MedicineFormPageState extends ConsumerState<MedicineFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  String? _photoPath;
  MedicineCondition _condition = MedicineCondition.anytime;
  ScheduleType _scheduleType = ScheduleType.daily;
  List<String> _times = ['08:00'];
  int _intervalHours = 8;
  int _stockCount = 30;
  int _stockLow = 5;
  DateTime? _renewalDate;
  bool _loading = true;
  bool _saving = false;
  Medicine? _existing;
  DateTime? _existingStartDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.medicineId == null) {
      setState(() => _loading = false);
      return;
    }
    final repo = ref.read(medicineRepositoryProvider);
    final med = await repo.getById(widget.medicineId!);
    if (med == null) {
      setState(() => _loading = false);
      return;
    }
    final schedules = await repo.getSchedules(med.id!);
    final schedule = schedules.isNotEmpty ? schedules.first : null;
    _existing = med;
    _nameCtrl.text = med.name;
    _dosageCtrl.text = med.dosage ?? '';
    _instructionsCtrl.text = med.instructions ?? '';
    _photoPath = med.photoPath;
    _condition = med.conditionType;
    _stockCount = med.stockCount;
    _stockLow = med.stockLowThreshold;
    _renewalDate = med.renewalDate;
    if (schedule != null) {
      _scheduleType = schedule.scheduleType;
      _times = List.of(schedule.times);
      _intervalHours = schedule.intervalHours ?? 8;
      _existingStartDate = schedule.startDate;
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduleType != ScheduleType.interval && _times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir saat ekleyin.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final medicine = Medicine(
        id: _existing?.id,
        name: _nameCtrl.text.trim(),
        dosage: _dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim(),
        instructions: _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
        photoPath: _photoPath,
        conditionType: _condition,
        stockCount: _stockCount,
        stockLowThreshold: _stockLow,
        renewalDate: _renewalDate,
        createdAt: _existing?.createdAt ?? now,
        updatedAt: now,
      );

      final schedule = MedicineSchedule(
        medicineId: _existing?.id ?? 0,
        scheduleType: _scheduleType,
        times: _scheduleType == ScheduleType.interval ? const [] : _times,
        intervalHours:
            _scheduleType == ScheduleType.interval ? _intervalHours : null,
        startDate: _existingStartDate ??
            DateTime(now.year, now.month, now.day),
      );

      await ref.read(medicineRepositoryProvider).saveMedicineWithSchedule(
            medicine: medicine,
            schedule: schedule,
          );

      final isPremium = ref.read(isPremiumProvider);
      await ref.read(reminderSchedulerProvider).rescheduleAll(
            includeWater: isPremium,
          );
      await ref
          .read(consentAdsServiceProvider)
          .showInterstitialIfAvailable(isPremium: isPremium);

      ref.invalidate(medicinesProvider);
      ref.invalidate(dayDosesProvider);

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.medicineId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'İlacı Düzenle' : 'İlaç Ekle'),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: 'Sil',
              onPressed: _saving
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('İlacı sil?'),
                          content: const Text(
                            'Bu ilaç listeden kaldırılacak.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Vazgeç'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && widget.medicineId != null) {
                        await ref
                            .read(medicineRepositoryProvider)
                            .softDelete(widget.medicineId!);
                        ref.invalidate(medicinesProvider);
                        ref.invalidate(dayDosesProvider);
                        if (context.mounted) Navigator.pop(context, true);
                      }
                    },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.marginMobile),
                children: [
                  PhotoPickerWidget(
                    photoPath: _photoPath,
                    onChanged: (p) => setState(() => _photoPath = p),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'İlaç adı',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dosageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Doz (örn. 20mg • 1 hap)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _instructionsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Yönerge / not',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConditionDropdown(
                    value: _condition,
                    onChanged: (v) => setState(() => _condition = v),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  Text('Zamanlama', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<ScheduleType>(
                    segments: const [
                      ButtonSegment(
                        value: ScheduleType.daily,
                        label: Text('Günlük'),
                        icon: Icon(Icons.today),
                      ),
                      ButtonSegment(
                        value: ScheduleType.customTimes,
                        label: Text('Saatler'),
                        icon: Icon(Icons.schedule),
                      ),
                      ButtonSegment(
                        value: ScheduleType.interval,
                        label: Text('Tekrarlı'),
                        icon: Icon(Icons.loop),
                      ),
                    ],
                    selected: {_scheduleType},
                    onSelectionChanged: (s) {
                      setState(() => _scheduleType = s.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_scheduleType == ScheduleType.interval)
                    DropdownButtonFormField<int>(
                      // ignore: deprecated_member_use
                      value: _intervalHours,
                      decoration: const InputDecoration(
                        labelText: 'Kaç saatte bir?',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 4, child: Text('4 saatte bir')),
                        DropdownMenuItem(value: 6, child: Text('6 saatte bir')),
                        DropdownMenuItem(value: 8, child: Text('8 saatte bir')),
                        DropdownMenuItem(value: 12, child: Text('12 saatte bir')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _intervalHours = v);
                      },
                    )
                  else
                    TimePickerList(
                      times: _times,
                      onChanged: (t) => setState(() => _times = t),
                    ),
                  const SizedBox(height: AppSpacing.stackMd),
                  RenewalSettingsCard(
                    stockCount: _stockCount,
                    stockLowThreshold: _stockLow,
                    renewalDate: _renewalDate,
                    onStockChanged: (v) => setState(() => _stockCount = v),
                    onThresholdChanged: (v) => setState(() => _stockLow = v),
                    onRenewalDateChanged: (v) =>
                        setState(() => _renewalDate = v),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Kaydet' : 'İlacı Ekle'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
