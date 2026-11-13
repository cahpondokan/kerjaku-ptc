import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:lembur/features/duty/data/duty_repository.dart';
import 'package:lembur/features/duty/domain/duty_entry.dart';

class DutyProvider extends ChangeNotifier {
  DutyProvider(this.repository);
  final DutyRepository repository;
  List<DutyEntry> _entries = [];
  List<DutyEntry> get entries => List.unmodifiable(_entries);
  bool loaded = false;
  bool saving = false;
  String? error;

  DutyEntry? byId(String? id) => _entries.where((e) => e.id == id).firstOrNull;

  Future<void> load() async {
    try {
      _entries = await repository.getAll();
      error = null;
      loaded = true;
    } catch (_) {
      error = 'Surat dinas belum dapat dimuat. Coba lagi.';
    }
    notifyListeners();
  }

  Future<void> save(DutyEntry entry) async {
    if (!loaded || saving) throw StateError('Tunggu hingga data siap.');
    final invalid = entry.validate(requireComplete: !entry.isDraft);
    if (invalid != null) throw StateError(invalid);
    saving = true;
    notifyListeners();
    try {
      await repository.save(entry);
      final rows = await repository.getAll();
      final saved = rows.where((e) => e.id == entry.id).firstOrNull;
      if (saved == null ||
          jsonEncode(saved.toMap()) != jsonEncode(entry.toMap())) {
        throw StateError('Surat belum tersimpan dengan lengkap. Coba lagi.');
      }
      _entries = rows;
      error = null;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    if (saving) throw StateError('Penyimpanan sedang berlangsung.');
    saving = true;
    notifyListeners();
    try {
      await repository.delete(id);
      _entries = await repository.getAll();
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
