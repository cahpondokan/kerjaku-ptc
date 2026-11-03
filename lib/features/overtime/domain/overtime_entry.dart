import 'package:lembur/core/utils/overtime_pay_calculator.dart';

enum DayType {
  regular('Hari kerja biasa'),
  holiday('Hari istirahat mingguan/libur resmi');

  const DayType(this.label);
  final String label;
}

class OvertimeEntry {
  const OvertimeEntry({
    required this.id,
    required this.overtimeDate,
    required this.startTime,
    required this.endTime,
    required this.actualHours,
    required this.convertedHours,
    required this.dayType,
    required this.workDescription,
    required this.approverPosition,
    required this.approverName,
    required this.createdAt,
    required this.updatedAt,
    this.monthlyWageBasisCents,
  });

  final String id;
  final DateTime overtimeDate;
  final String startTime;
  final String endTime;
  final double actualHours;
  final double convertedHours;
  final DayType dayType;
  final String workDescription;
  final String approverPosition;
  final String approverName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? monthlyWageBasisCents;

  bool get wageDurationSupported =>
      actualHours > 0 &&
      actualHours.isFinite &&
      convertedHours.isFinite &&
      convertedHours > 0 &&
      (dayType != DayType.holiday || actualHours <= 12);
  int? get estimatedPay => estimatedPayWithBasis(null);

  /// Uses the record's saved wage when available, otherwise the current
  /// profile wage. This lets legacy/imported entries calculate automatically.
  int? estimatedPayWithBasis(int? profileBasisCents) {
    final basis = monthlyWageBasisCents ?? profileBasisCents;
    if (basis == null || basis <= 0 || !wageDurationSupported) return null;
    return OvertimePayCalculator.calculate(
      monthlyBasisCents: basis,
      convertedHours: convertedHours,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'overtime_date': overtimeDate.toIso8601String(),
    'start_time': startTime,
    'end_time': endTime,
    'actual_hours': actualHours,
    'converted_hours': convertedHours,
    'day_type': dayType.name,
    'work_description': workDescription,
    'approver_position': approverPosition,
    'approver_name': approverName,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'monthly_wage_basis_cents': monthlyWageBasisCents,
  };

  factory OvertimeEntry.fromMap(Map<String, Object?> map) {
    return OvertimeEntry(
      id: map['id']! as String,
      overtimeDate: DateTime.parse(map['overtime_date']! as String),
      startTime: map['start_time']! as String,
      endTime: map['end_time']! as String,
      actualHours: (map['actual_hours']! as num).toDouble(),
      convertedHours: (map['converted_hours']! as num).toDouble(),
      dayType: DayType.values.byName(map['day_type']! as String),
      workDescription: map['work_description']! as String,
      approverPosition: map['approver_position']! as String,
      approverName: map['approver_name']! as String,
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
      monthlyWageBasisCents: (map['monthly_wage_basis_cents'] as num?)?.toInt(),
    );
  }

  OvertimeEntry copyWith({
    String? id,
    DateTime? overtimeDate,
    String? startTime,
    String? endTime,
    double? actualHours,
    double? convertedHours,
    DayType? dayType,
    String? workDescription,
    String? approverPosition,
    String? approverName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? monthlyWageBasisCents,
  }) {
    return OvertimeEntry(
      id: id ?? this.id,
      overtimeDate: overtimeDate ?? this.overtimeDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      actualHours: actualHours ?? this.actualHours,
      convertedHours: convertedHours ?? this.convertedHours,
      dayType: dayType ?? this.dayType,
      workDescription: workDescription ?? this.workDescription,
      approverPosition: approverPosition ?? this.approverPosition,
      approverName: approverName ?? this.approverName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      monthlyWageBasisCents:
          monthlyWageBasisCents ?? this.monthlyWageBasisCents,
    );
  }
}
