import 'package:flutter/foundation.dart';
import 'package:lembur/features/leave/data/leave_repository.dart';
import 'package:lembur/features/leave/domain/leave_calculator.dart';
import 'package:lembur/features/leave/domain/leave_entry.dart';

class LeaveProvider extends ChangeNotifier {
  LeaveProvider(this._repository);
  final LeaveRepository _repository;
  List<LeaveEntry> _entries = [];
  Map<int, int> _initialUsed = {};
  LeaveDefaults _defaults = const LeaveDefaults();
  bool _loaded = false;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  List<LeaveEntry> get entries => List.unmodifiable(_entries);
  LeaveDefaults get defaults => _defaults;
  bool get loaded => _loaded;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  Set<int> get years => {
    ..._initialUsed.keys,
    ..._entries.map((entry) => entry.year),
  };

  Future<void> load() async {
    if (_loading || _saving) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final entries = await _repository.getAll();
      final balances = await _repository.getInitialBalances();
      final defaults = await _repository.getDefaults();
      _entries = entries;
      _initialUsed = balances;
      _defaults = defaults;
      _loaded = true;
    } catch (_) {
      _error = 'Data cuti belum dapat dimuat. Coba lagi.';
      _loaded = false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<LeaveEntry> forYear(int year) =>
      _entries.where((entry) => entry.year == year).toList();
  LeaveEntry? byId(String? id) =>
      _entries.where((entry) => entry.id == id).firstOrNull;
  int initialUsed(int year) => _initialUsed[year] ?? 0;
  bool hasInitialUsed(int year) => _initialUsed.containsKey(year);
  int recordedDays(int year, {String? exceptId}) => forYear(year)
      .where((entry) => entry.id != exceptId)
      .fold(0, (sum, entry) => sum + entry.days);
  int remaining(int year, {String? exceptId}) =>
      LeaveCalculator.annualEntitlement -
      initialUsed(year) -
      recordedDays(year, exceptId: exceptId);
  int usedBefore(LeaveEntry entry) {
    final cutoff = LeaveCalculator.dateOnly(
      entry.startDate,
    ).subtract(const Duration(days: 1));
    var used = initialUsed(entry.year);
    for (final other in forYear(entry.year)) {
      if (other.id == entry.id) continue;
      final end = LeaveCalculator.dateOnly(other.endDate);
      // Ranges may share weekends/holidays. Count only earlier working days,
      // excluding this request and any leave booked for later dates.
      used += LeaveCalculator.workingDays(
        other.startDate,
        end.isBefore(cutoff) ? end : cutoff,
      );
    }
    return used;
  }

  String? validateDates(DateTime start, DateTime end, {String? exceptId}) {
    if (!loaded) return 'Tunggu data cuti selesai dimuat.';
    final invalid = LeaveCalculator.validateRange(start, end);
    if (invalid != null) return invalid;
    if (_entries.any(
      (entry) =>
          entry.id != exceptId &&
          LeaveCalculator.overlaps(start, end, entry.startDate, entry.endDate),
    )) {
      return 'Tanggal ini bertumpang tindih dengan cuti yang sudah tercatat.';
    }
    final available = remaining(start.year, exceptId: exceptId);
    if (LeaveCalculator.workingDays(start, end) > available) {
      return 'Jatah cuti ${start.year} tersisa $available hari.';
    }
    return null;
  }

  Future<void> save(LeaveEntry entry) async {
    final invalid = validateDates(
      entry.startDate,
      entry.endDate,
      exceptId: entry.id,
    );
    if (invalid != null) throw StateError(invalid);
    if ([
      entry.reason,
      entry.address,
      entry.applicantName,
      entry.workerNumber,
      entry.aftName,
      entry.aftPosition,
      entry.managerName,
      entry.managerPosition,
    ].any((value) => value.trim().isEmpty)) {
      throw StateError('Lengkapi profil, alasan, alamat, dan penandatangan.');
    }
    if (entry.reason.length > 300 || entry.address.length > 250) {
      throw StateError('Alasan atau alamat terlalu panjang.');
    }
    await _write(() async {
      final defaults = LeaveDefaults(
        reason: entry.reason,
        address: entry.address,
        aftName: entry.aftName,
        aftPosition: entry.aftPosition,
      );
      await _repository.save(entry, defaults);
      final persistedEntries = await _repository.getAll();
      if (!persistedEntries.any((saved) => saved.id == entry.id)) {
        throw StateError('Surat cuti belum tersimpan. Coba simpan lagi.');
      }
      _entries = persistedEntries;
      _defaults = defaults;
    });
  }

  Future<void> setInitialUsed(int year, int days) async {
    if (!loaded) throw StateError('Tunggu data cuti selesai dimuat.');
    if (days < 0 ||
        days + recordedDays(year) > LeaveCalculator.annualEntitlement) {
      throw StateError(
        'Cuti awal dan catatan aplikasi tidak boleh melebihi 12 hari.',
      );
    }
    await _write(() async {
      await _repository.setInitialUsed(year, days);
      _initialUsed[year] = days;
    });
  }

  Future<void> delete(String id) async => _write(() async {
    await _repository.delete(id);
    _entries.removeWhere((entry) => entry.id == id);
  });

  Future<void> _write(Future<void> Function() action) async {
    if (_saving || _loading) {
      throw StateError('Proses penyimpanan masih berjalan.');
    }
    _saving = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
