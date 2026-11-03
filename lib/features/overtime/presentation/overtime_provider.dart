import 'package:flutter/foundation.dart';
import 'package:lembur/features/overtime/data/overtime_repository.dart';
import 'package:lembur/features/overtime/domain/overtime_entry.dart';

class OvertimeProvider extends ChangeNotifier {
  OvertimeProvider(this._repository);

  final OvertimeRepository _repository;
  List<OvertimeEntry> _entries = [];
  bool _loading = false;
  String? _error;

  List<OvertimeEntry> get entries => List.unmodifiable(_entries);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _entries = await _repository.getAll();
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> save(OvertimeEntry entry) async {
    await _repository.save(entry);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }

  OvertimeEntry? byId(String? id) {
    if (id == null) {
      return null;
    }
    for (final entry in _entries) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  List<OvertimeEntry> forMonth(DateTime month) {
    return _entries
        .where(
          (entry) =>
              entry.overtimeDate.year == month.year &&
              entry.overtimeDate.month == month.month,
        )
        .toList();
  }
}
