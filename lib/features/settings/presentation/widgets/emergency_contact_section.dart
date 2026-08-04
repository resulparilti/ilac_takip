import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/models/emergency_contact.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/features/premium/presentation/paywall_page.dart';

class EmergencyContactSection extends ConsumerWidget {
  const EmergencyContactSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final contactsAsync = ref.watch(_contactsProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Acil iletişim',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                if (!isPremium)
                  Chip(
                    label: const Text('Premium'),
                    avatar: const Icon(Icons.lock, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Peş peşe ilaç kaçırıldığında sorumlu kişiye haber verilir.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (!isPremium)
              OutlinedButton(
                onPressed: () => PaywallPage.open(context),
                child: const Text('Premium ile aç'),
              )
            else ...[
              contactsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (list) {
                  if (list.isEmpty) {
                    return Text(
                      'Henüz sorumlu kişi yok.',
                      style: theme.textTheme.bodyLarge,
                    );
                  }
                  return Column(
                    children: [
                      for (final c in list)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: Text(c.name),
                          subtitle: Text(
                            [
                              if (c.phone != null) c.phone!,
                              if (c.notifyWhatsapp) 'WhatsApp',
                              if (c.notifySms) 'SMS',
                              if (c.notifyEmail) 'E-posta',
                              'Eşik: ${c.missThreshold}',
                            ].join(' • '),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => _addContact(context, ref),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Sorumlu kişi ekle'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(missedDoseMonitorProvider)
                      .scanAndNotifyIfNeeded(isPremium: true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Kaçırma taraması yapıldı. Eşik aşılmışsa mesaj ekranı açılır.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.notification_important_outlined),
                label: const Text('Acil bildirimi test et / tara'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addContact(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    var whatsapp = true;
    var sms = false;
    var email = false;
    var threshold = 2;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return AlertDialog(
              title: const Text('Sorumlu kişi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('WhatsApp'),
                      value: whatsapp,
                      onChanged: (v) => setModal(() => whatsapp = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('SMS'),
                      value: sms,
                      onChanged: (v) => setModal(() => sms = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('E-posta'),
                      value: email,
                      onChanged: (v) => setModal(() => email = v),
                    ),
                    Text('Kaçırma eşiği: $threshold'),
                    Slider(
                      value: threshold.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '$threshold',
                      onChanged: (v) =>
                          setModal(() => threshold = v.round()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await ref.read(settingsRepositoryProvider).upsertEmergencyContact(
            EmergencyContact(
              name: nameCtrl.text.trim(),
              phone: phoneCtrl.text.trim().isEmpty
                  ? null
                  : phoneCtrl.text.trim(),
              email: emailCtrl.text.trim().isEmpty
                  ? null
                  : emailCtrl.text.trim(),
              notifyWhatsapp: whatsapp,
              notifySms: sms,
              notifyEmail: email,
              missThreshold: threshold,
            ),
          );
      ref.invalidate(_contactsProvider);
    }
  }
}

final _contactsProvider =
    FutureProvider.autoDispose<List<EmergencyContact>>((ref) {
  return ref.watch(settingsRepositoryProvider).getEmergencyContacts();
});
