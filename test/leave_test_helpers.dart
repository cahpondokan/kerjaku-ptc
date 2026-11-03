import 'package:lembur/features/leave/data/leave_repository.dart';
import 'package:lembur/features/leave/domain/leave_entry.dart';

class MemoryLeaveRepository extends LeaveRepository {
  final entries = <LeaveEntry>[];
  final balances = <int, int>{};
  LeaveDefaults defaults = const LeaveDefaults();
  bool failWrites = false;
  bool failReads = false;
  int writes = 0;
  @override
  Future<List<LeaveEntry>> getAll() async {
    if (failReads) throw StateError('Storage unavailable');
    return List.of(entries);
  }

  @override
  Future<Map<int, int>> getInitialBalances() async => Map.of(balances);
  @override
  Future<LeaveDefaults> getDefaults() async => defaults;
  @override
  Future<void> save(LeaveEntry entry, LeaveDefaults defaults) async {
    if (failWrites) throw StateError('Storage unavailable');
    writes++;
    entries.removeWhere((other) => other.id == entry.id);
    entries.add(LeaveEntry.fromMap(entry.toMap()));
    this.defaults = LeaveDefaults.fromMap(defaults.toMap());
  }

  @override
  Future<void> setInitialUsed(int year, int days) async {
    if (failWrites) throw StateError('Storage unavailable');
    balances[year] = days;
  }

  @override
  Future<void> delete(String id) async {
    if (failWrites) throw StateError('Storage unavailable');
    entries.removeWhere((entry) => entry.id == id);
  }
}

LeaveEntry sampleLeave({
  String id = 'leave-1',
  DateTime? start,
  DateTime? end,
  String reason = 'Acara keluarga',
  String address = 'Semarang',
}) => LeaveEntry(
  id: id,
  startDate: start ?? DateTime(2026, 10, 23),
  endDate: end ?? DateTime(2026, 10, 26),
  requestDate: DateTime(2026, 10, 22),
  reason: reason,
  address: address,
  applicantName: 'Budi Pratama',
  workerNumber: 'PTC-001',
  aftName: 'Joni Herawan',
  aftPosition: 'PJS AFTM Ahmad Yani',
  managerName: 'Ricky Roy Sagita',
  managerPosition: 'Manager Manpower Supply - PTC',
);
