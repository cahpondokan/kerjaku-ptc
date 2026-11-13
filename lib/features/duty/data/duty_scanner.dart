import 'dart:io';
import 'package:flutter/services.dart';
import 'package:lembur/features/duty/domain/duty_scan_page.dart';

class DutyScanner {
  static const channel = MethodChannel('com.niam.ayani.kerjakuptc/duty_scan');
  Future<List<Uint8List>?> scan({int limit = 10}) async {
    final paths = await channel.invokeListMethod<String>('scan', {
      'limit': limit,
    });
    if (paths == null || paths.isEmpty) return null;
    final images = <Uint8List>[];
    try {
      for (final path in paths) {
        final file = File(path);
        if (await file.length() > ScanImageData.maxBytes) {
          throw StateError('Hasil scan terlalu besar.');
        }
        final bytes = await file.readAsBytes();
        ScanImageData.validate(bytes);
        images.add(bytes);
      }
      return images;
    } finally {
      // Native bridge only deletes its own temporary scan files.
      await channel.invokeMethod<void>('discard', {'paths': paths});
    }
  }

  Future<Uint8List> crop(
    Uint8List bytes,
    List<double> corners,
    int rotation,
  ) async {
    final result = await channel.invokeMethod<Uint8List>('crop', {
      'bytes': bytes,
      'corners': corners,
      'rotation': rotation,
    });
    if (result == null) throw StateError('Potongan belum dapat diterapkan.');
    ScanImageData.validate(result);
    return result;
  }
}

String scanError(Object error) {
  if (error is StateError) return error.message.toString();
  if (error is FormatException) return error.message;
  if (error is PlatformException) {
    return error.message ?? 'Pemindai belum siap. Coba lagi.';
  }
  return 'Berkas belum dapat diproses. Data yang tersimpan tetap tersedia. Coba lagi.';
}
