/// Takvim günü karşılaştırması (saat yok sayılır).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// İlaç hatırlatmalarının başlayacağı gün (eklenme / schedule başlangıcı).
DateTime medicineEffectiveStart({
  required DateTime createdAt,
  DateTime? scheduleStart,
}) {
  final created = dateOnly(createdAt);
  if (scheduleStart == null) return created;
  final start = dateOnly(scheduleStart);
  return start.isAfter(created) ? start : created;
}

bool isOnOrAfterStart(DateTime day, DateTime start) {
  return !dateOnly(day).isBefore(dateOnly(start));
}
