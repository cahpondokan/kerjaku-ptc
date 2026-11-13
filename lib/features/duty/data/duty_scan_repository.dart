import 'dart:typed_data';
import 'package:lembur/core/database/app_database.dart';
import 'package:lembur/features/duty/data/duty_scan_blobs.dart';
import 'package:lembur/features/duty/domain/duty_scan_page.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DutyScanRepository {
  DutyScanRepository({Future<Database> Function()? database})
    : _database = database ?? (() => AppDatabase.instance.database);
  final Future<Database> Function() _database;

  Future<List<DutyScanPage>> list(String dutyId) async {
    final db = await _database();
    return DutyScanPage.ordered(
      (await db.query(
        'duty_scan_pages',
        columns: DutyScanPage.columns,
        where: 'duty_id = ?',
        whereArgs: [dutyId],
      )).map(DutyScanPage.fromMap),
    );
  }

  Future<Uint8List> image(String id, {bool original = false}) async {
    final db = await _database();
    return db.transaction((txn) async {
      if (original) {
        final source = await DutyScanBlobs.readColumn(txn, id, original: true);
        if (source != null) return source;
      }
      return (await DutyScanBlobs.readColumn(txn, id))!;
    });
  }

  Future<void> _checkParent(DatabaseExecutor db, String dutyId) async {
    final parents = await db.query(
      'duty_entries',
      columns: ['id', 'is_draft'],
      where: 'id = ?',
      whereArgs: [dutyId],
      limit: 1,
    );
    if (parents.isEmpty || parents.single['is_draft'] == 1) {
      throw StateError('Simpan surat dinas terlebih dahulu.');
    }
  }

  Future<void> add(
    String dutyId,
    DutyDocumentType type,
    List<Uint8List> images,
  ) async {
    if (images.isEmpty) throw StateError('Belum ada hasil scan.');
    for (final bytes in images) {
      ScanImageData.validate(bytes);
    }
    final db = await _database();
    await db.transaction((txn) async {
      await _checkParent(txn, dutyId);
      final maximum =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT MAX(position) FROM duty_scan_pages WHERE duty_id = ? AND kind = ?',
              [dutyId, type.name],
            ),
          ) ??
          -1;
      final now = DateTime.now().toIso8601String();
      for (var i = 0; i < images.length; i++) {
        await txn.insert('duty_scan_pages', {
          'id': const Uuid().v4(),
          'duty_id': dutyId,
          'kind': type.name,
          'position': maximum + 1 + i,
          'image': images[i],
          'original_image': null,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }

  Future<void> replace(
    DutyScanPage page,
    Uint8List bytes, {
    bool crop = false,
  }) async {
    ScanImageData.validate(bytes);
    final db = await _database();
    await db.transaction((txn) async {
      final old = await txn.query(
        'duty_scan_pages',
        columns: ['id', 'updated_at'],
        where: 'id = ? AND duty_id = ?',
        whereArgs: [page.id, page.dutyId],
        limit: 1,
      );
      if (old.isEmpty) {
        throw StateError('Halaman sudah dihapus. Muat ulang dokumen.');
      }
      if (old.single['updated_at'] != page.updatedAt.toIso8601String()) {
        throw StateError(
          'Halaman sudah berubah. Muat ulang sebelum menggantinya.',
        );
      }
      // Retain the original inside SQLite without returning a large BLOB row.
      await txn.rawUpdate(
        'UPDATE duty_scan_pages SET original_image = ${crop ? 'COALESCE(original_image, image)' : 'NULL'}, image = ?, updated_at = ? WHERE id = ?',
        [bytes, DateTime.now().toIso8601String(), page.id],
      );
    });
  }

  Future<void> delete(String id) async {
    final db = await _database();
    await db.delete('duty_scan_pages', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorder(
    String dutyId,
    DutyDocumentType type,
    List<String> ids,
  ) async {
    final db = await _database();
    await db.transaction((txn) async {
      final rows = await txn.query(
        'duty_scan_pages',
        columns: ['id'],
        where: 'duty_id = ? AND kind = ?',
        whereArgs: [dutyId, type.name],
      );
      final expected = rows.map((r) => r['id']).toSet();
      if (ids.toSet().length != ids.length ||
          expected.length != ids.length ||
          !expected.containsAll(ids)) {
        throw StateError('Daftar halaman sudah berubah. Muat ulang dokumen.');
      }
      for (var i = 0; i < ids.length; i++) {
        await txn.update(
          'duty_scan_pages',
          {'position': i},
          where: 'id = ?',
          whereArgs: [ids[i]],
        );
      }
    });
  }
}
