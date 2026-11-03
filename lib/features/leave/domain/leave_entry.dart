import 'package:lembur/features/leave/domain/leave_calculator.dart';

class LeaveEntry {
  const LeaveEntry({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.requestDate,
    required this.reason,
    required this.address,
    required this.applicantName,
    required this.workerNumber,
    required this.aftName,
    required this.aftPosition,
    required this.managerName,
    required this.managerPosition,
  });

  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime requestDate;
  final String reason;
  final String address;
  final String applicantName;
  final String workerNumber;
  final String aftName;
  final String aftPosition;
  final String managerName;
  final String managerPosition;
  int get year => startDate.year;
  int get days => LeaveCalculator.workingDays(startDate, endDate);
  DateTime get returnDate => LeaveCalculator.returnDate(endDate);

  Map<String, Object?> toMap() => {
    'id': id,
    'start_date': _date(startDate),
    'end_date': _date(endDate),
    'request_date': _date(requestDate),
    'reason': reason,
    'address': address,
    'applicant_name': applicantName,
    'worker_number': workerNumber,
    'aft_name': aftName,
    'aft_position': aftPosition,
    'manager_name': managerName,
    'manager_position': managerPosition,
  };

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  factory LeaveEntry.fromMap(Map<String, Object?> map) => LeaveEntry(
    id: map['id']! as String,
    startDate: DateTime.parse(map['start_date']! as String),
    endDate: DateTime.parse(map['end_date']! as String),
    requestDate: DateTime.parse(map['request_date']! as String),
    reason: map['reason']! as String,
    address: map['address']! as String,
    applicantName: map['applicant_name']! as String,
    workerNumber: map['worker_number']! as String,
    aftName: map['aft_name']! as String,
    aftPosition: map['aft_position']! as String,
    managerName: map['manager_name']! as String,
    managerPosition: map['manager_position']! as String,
  );
}

class LeaveDefaults {
  const LeaveDefaults({
    this.reason = '',
    this.address = '',
    this.aftName = '',
    this.aftPosition = '',
  });
  final String reason;
  final String address;
  final String aftName;
  final String aftPosition;
  Map<String, Object?> toMap() => {
    'id': 1,
    'reason': reason,
    'address': address,
    'aft_name': aftName,
    'aft_position': aftPosition,
  };
  factory LeaveDefaults.fromMap(Map<String, Object?> map) => LeaveDefaults(
    reason: map['reason']! as String,
    address: map['address']! as String,
    aftName: map['aft_name']! as String,
    aftPosition: map['aft_position']! as String,
  );
}
