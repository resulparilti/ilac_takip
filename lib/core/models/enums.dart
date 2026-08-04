/// Esnek ilaç zamanlama türleri.
enum ScheduleType {
  daily,
  hourly,
  interval,
  customTimes;

  String get dbValue => name;

  static ScheduleType fromDb(String value) =>
      ScheduleType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ScheduleType.daily,
      );
}

/// Doz / hatırlatma durumu.
enum ReminderStatus {
  pending,
  completed,
  missed,
  snoozed;

  String get dbValue => name;

  static ReminderStatus fromDb(String value) =>
      ReminderStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ReminderStatus.pending,
      );
}

/// Aç/tok vb. kullanım koşulu.
enum MedicineCondition {
  anytime,
  beforeMeal,
  afterMeal,
  withMeal,
  emptyStomach;

  String get labelTr => switch (this) {
        MedicineCondition.anytime => 'Her zaman',
        MedicineCondition.beforeMeal => 'Yemekten önce',
        MedicineCondition.afterMeal => 'Yemekten sonra',
        MedicineCondition.withMeal => 'Yemekle birlikte',
        MedicineCondition.emptyStomach => 'Aç karnına',
      };

  String get dbValue => name;

  static MedicineCondition fromDb(String? value) =>
      MedicineCondition.values.firstWhere(
        (e) => e.name == value,
        orElse: () => MedicineCondition.anytime,
      );
}

enum StockStatus {
  sufficient,
  warning,
  critical;

  String get labelTr => switch (this) {
        StockStatus.sufficient => 'Yeterli',
        StockStatus.warning => 'Uyarı',
        StockStatus.critical => 'Acil',
      };
}
