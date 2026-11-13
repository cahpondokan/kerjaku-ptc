import 'package:lembur/features/duty/data/duty_repository.dart';
import 'package:lembur/features/duty/domain/duty_entry.dart';

DutyEntry sampleDuty({Map<String, Object?> changes = const {}}) {
  final entry = DutyEntry(
    id: 'duty-1',
    requestDate: DateTime(2026, 11, 2),
    createdAt: DateTime(2026, 11, 2, 9),
    updatedAt: DateTime(2026, 11, 2, 9),
    recipient: 'PT. Pertamina Training & Consulting',
    applicantName: 'Dimas Saputra',
    workerNumber: 'PTC-CONTOH-001',
    placement: 'AFT Ahmad Yani',
    jobType: 'Maintenance',
    origin: 'Semarang',
    destination: 'Solo',
    startDate: DateTime(2026, 11, 2),
    returnDate: DateTime(2026, 11, 5),
    purpose: 'Undangan Presentasi CIP TH 2026',
    costBearer: 'PT. Pertamina Training & Consulting',
    requestPlace: 'Semarang',
    signerName: 'Andi Prasetyo',
    signerPosition: 'Aviation Fuel Terminal Manager Ahmad Yani',
    isDraft: false,
  );
  return DutyEntry.fromMap({...entry.toMap(), ...changes});
}

class MemoryDutyRepository extends DutyRepository {
  final rows = <String, Map<String, Object?>>{};
  bool failReads = false, failWrites = false, ignoreWrites = false;
  int writes = 0;
  @override
  Future<List<DutyEntry>> getAll() async {
    if (failReads) throw StateError('Storage unavailable');
    return rows.values.map(DutyEntry.fromMap).toList()
      ..sort((a, b) => b.requestDate.compareTo(a.requestDate));
  }

  @override
  Future<void> save(DutyEntry entry) async {
    if (failWrites) throw StateError('Write failed');
    writes++;
    if (!ignoreWrites) rows[entry.id] = entry.toMap();
  }

  @override
  Future<void> delete(String id) async {
    if (failWrites) throw StateError('Delete failed');
    rows.remove(id);
  }
}
