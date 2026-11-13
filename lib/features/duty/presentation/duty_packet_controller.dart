import 'package:flutter/foundation.dart';
import 'package:lembur/features/duty/data/duty_scan_repository.dart';
import 'package:lembur/features/duty/domain/duty_scan_page.dart';

class DutyPacketController extends ChangeNotifier {
  DutyPacketController(this.dutyId, this.repository);
  final String dutyId;
  final DutyScanRepository repository;
  List<DutyScanPage> pages = [];
  bool loaded = false, busy = false;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Object? error;
  List<DutyScanPage> ofType(DutyDocumentType type) =>
      pages.where((p) => p.type == type).toList();
  int get availableTypes => pages.map((p) => p.type).toSet().length;
  bool get canShare => loaded && !busy && pages.isNotEmpty;
  Future<void> load() async {
    try {
      pages = await repository.list(dutyId);
      loaded = true;
      error = null;
    } catch (e) {
      loaded = false;
      error = e;
    }
    notifyListeners();
  }

  void setBusy(bool value) {
    busy = value;
    notifyListeners();
  }

  Future<void> add(DutyDocumentType type, List<Uint8List> images) =>
      _write(() => repository.add(dutyId, type, images));
  Future<void> replace(
    DutyScanPage page,
    Uint8List image, {
    bool crop = false,
  }) => _write(() => repository.replace(page, image, crop: crop));
  Future<void> delete(String id) => _write(() => repository.delete(id));
  Future<void> reorder(DutyDocumentType type, List<String> ids) =>
      _write(() => repository.reorder(dutyId, type, ids));
  Future<void> _write(Future<void> Function() action) async {
    if (busy || !loaded) throw StateError('Tunggu sampai penyimpanan selesai.');
    setBusy(true);
    try {
      try {
        await action();
      } catch (e) {
        error = e;
        rethrow;
      }
      // The write has committed. A failed refresh must not offer a second save
      // of the same captured pages; require a reload instead.
      await load();
    } finally {
      setBusy(false);
    }
  }
}
