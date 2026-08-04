class EmergencyContact {
  const EmergencyContact({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.notifyWhatsapp = true,
    this.notifySms = false,
    this.notifyEmail = false,
    this.missThreshold = 2,
    this.isActive = true,
  });

  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final bool notifyWhatsapp;
  final bool notifySms;
  final bool notifyEmail;
  final int missThreshold;
  final bool isActive;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'notify_whatsapp': notifyWhatsapp ? 1 : 0,
        'notify_sms': notifySms ? 1 : 0,
        'notify_email': notifyEmail ? 1 : 0,
        'miss_threshold': missThreshold,
        'is_active': isActive ? 1 : 0,
      };

  factory EmergencyContact.fromMap(Map<String, Object?> map) =>
      EmergencyContact(
        id: map['id'] as int?,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        notifyWhatsapp: (map['notify_whatsapp'] as int?) == 1,
        notifySms: (map['notify_sms'] as int?) == 1,
        notifyEmail: (map['notify_email'] as int?) == 1,
        missThreshold: (map['miss_threshold'] as int?) ?? 2,
        isActive: (map['is_active'] as int?) == 1,
      );
}
