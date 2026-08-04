import 'package:flutter/foundation.dart';
import 'package:ilac_takip/core/models/emergency_contact.dart';
import 'package:ilac_takip/core/models/medicine.dart';
import 'package:url_launcher/url_launcher.dart';

/// Premium: sorumlu kişiye WhatsApp / SMS / e-posta açar.
/// Not: WhatsApp/SMS otomatik gönderim OS kısıtlıdır; hazır mesajlı intent açılır.
class EmergencyNotifyService {
  Future<void> notifyContacts({
    required List<EmergencyContact> contacts,
    required Medicine medicine,
    required int consecutiveMisses,
  }) async {
    final message =
        'İlaç Takip uyarısı: "${medicine.name}" ilacı peş peşe '
        '$consecutiveMisses kez alınmadı. Lütfen kontrol edin.';

    for (final contact in contacts) {
      if (!contact.isActive) continue;
      if (consecutiveMisses < contact.missThreshold) continue;

      if (contact.notifyWhatsapp &&
          contact.phone != null &&
          contact.phone!.trim().isNotEmpty) {
        await _openWhatsApp(contact.phone!, message);
      }
      if (contact.notifySms &&
          contact.phone != null &&
          contact.phone!.trim().isNotEmpty) {
        await _openSms(contact.phone!, message);
      }
      if (contact.notifyEmail &&
          contact.email != null &&
          contact.email!.trim().isNotEmpty) {
        await _openEmail(contact.email!, message);
      }
    }
  }

  String _digits(String phone) => phone.replaceAll(RegExp(r'[^\d+]'), '');

  Future<void> _openWhatsApp(String phone, String message) async {
    final cleaned = _digits(phone).replaceAll('+', '');
    final uri = Uri.parse(
      'https://wa.me/$cleaned?text=${Uri.encodeComponent(message)}',
    );
    await _launch(uri);
  }

  Future<void> _openSms(String phone, String message) async {
    final uri = Uri(
      scheme: 'sms',
      path: _digits(phone),
      queryParameters: {'body': message},
    );
    await _launch(uri);
  }

  Future<void> _openEmail(String email, String message) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'İlaç Takip — Acil uyarı',
        'body': message,
      },
    );
    await _launch(uri);
  }

  Future<void> _launch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (kDebugMode) {
        debugPrint('Cannot launch $uri');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Launch error: $e');
    }
  }
}
