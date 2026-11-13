import 'dart:typed_data';
import 'package:lembur/features/duty/domain/duty_scan_page.dart';
import 'package:sqflite/sqflite.dart';

/// Read bounded slices so high-resolution pages do not exceed Android's
/// CursorWindow row limit. Call within a transaction for a consistent image.
abstract final class DutyScanBlobs {
  static const _chunkBytes = 256 * 1024;
  static Future<Uint8List?> readColumn(
    DatabaseExecutor db,
    String id, {
    bool original = false,
  }) async {
    final column = original ? 'original_image' : 'image';
    final rows = await db.rawQuery(
      'SELECT length($column) AS size FROM duty_scan_pages WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) throw StateError('Halaman scan tidak ditemukan.');
    final length = rows.single['size'] as int?;
    if (length == null) return null;
    if (length <= 0 || length > ScanImageData.maxBytes) {
      throw const FormatException('Ukuran gambar scan tidak valid.');
    }
    final image = Uint8List(length);
    for (var offset = 0; offset < length; offset += _chunkBytes) {
      final count = (length - offset).clamp(0, _chunkBytes);
      final result = await db.rawQuery(
        'SELECT substr($column, ?, ?) AS chunk FROM duty_scan_pages WHERE id = ?',
        [offset + 1, count, id],
      );
      final chunk = result.single['chunk'] as List<int>;
      if (chunk.length != count) {
        throw StateError('Gambar scan tidak dapat dibaca lengkap.');
      }
      image.setRange(offset, offset + count, chunk);
    }
    return image;
  }

  static Future<List<Map<String, Object?>>> allRows(DatabaseExecutor db) async {
    final rows = await db.query(
      'duty_scan_pages',
      columns: DutyScanPage.columns,
    );
    final result = <Map<String, Object?>>[];
    for (final row in rows) {
      final id = row['id'] as String;
      result.add({
        ...row,
        'image': await readColumn(db, id),
        'original_image': await readColumn(db, id, original: true),
      });
    }
    return result;
  }
}
