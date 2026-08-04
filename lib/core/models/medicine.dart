import 'package:ilac_takip/core/models/enums.dart';

class Medicine {
  const Medicine({
    this.id,
    required this.name,
    this.dosage,
    this.instructions,
    this.photoPath,
    this.conditionType = MedicineCondition.anytime,
    this.stockCount = 0,
    this.stockLowThreshold = 5,
    this.renewalDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String? dosage;
  final String? instructions;
  final String? photoPath;
  final MedicineCondition conditionType;
  final int stockCount;
  final int stockLowThreshold;
  final DateTime? renewalDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  StockStatus get stockStatus {
    if (stockCount <= 0) return StockStatus.critical;
    if (stockCount <= stockLowThreshold) return StockStatus.warning;
    return StockStatus.sufficient;
  }

  Medicine copyWith({
    int? id,
    String? name,
    String? dosage,
    String? instructions,
    String? photoPath,
    MedicineCondition? conditionType,
    int? stockCount,
    int? stockLowThreshold,
    DateTime? renewalDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      photoPath: photoPath ?? this.photoPath,
      conditionType: conditionType ?? this.conditionType,
      stockCount: stockCount ?? this.stockCount,
      stockLowThreshold: stockLowThreshold ?? this.stockLowThreshold,
      renewalDate: renewalDate ?? this.renewalDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'dosage': dosage,
        'instructions': instructions,
        'photo_path': photoPath,
        'condition_type': conditionType.dbValue,
        'stock_count': stockCount,
        'stock_low_threshold': stockLowThreshold,
        'renewal_date': renewalDate?.toIso8601String(),
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Medicine.fromMap(Map<String, Object?> map) => Medicine(
        id: map['id'] as int?,
        name: map['name'] as String,
        dosage: map['dosage'] as String?,
        instructions: map['instructions'] as String?,
        photoPath: map['photo_path'] as String?,
        conditionType: MedicineCondition.fromDb(
          map['condition_type'] as String?,
        ),
        stockCount: (map['stock_count'] as int?) ?? 0,
        stockLowThreshold: (map['stock_low_threshold'] as int?) ?? 5,
        renewalDate: map['renewal_date'] != null
            ? DateTime.tryParse(map['renewal_date'] as String)
            : null,
        isActive: (map['is_active'] as int?) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
