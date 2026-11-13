import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:lembur/features/duty/domain/duty_entry.dart';
import 'package:lembur/features/duty/domain/duty_scan_page.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';

class DutyPacketPdf {
  Future<Uint8List> build(
    List<DutyScanPage> pages,
    Future<Uint8List> Function(String id) read, {
    void Function(int done, DutyDocumentType type)? progress,
    bool Function()? cancelled,
  }) async {
    if (pages.isEmpty) {
      throw StateError('Scan minimal satu halaman sebelum membagikan berkas.');
    }
    final ordered = DutyScanPage.ordered(pages);
    final document = pw.Document(
      title: 'Berkas perjalanan dinas',
      creator: 'KerjaKu PTC',
    );
    for (var i = 0; i < ordered.length; i++) {
      if (cancelled?.call() == true) {
        throw StateError('Penyiapan PDF dibatalkan.');
      }
      final page = ordered[i];
      final bytes = await read(page.id);
      ScanImageData.validate(bytes);
      final image = pw.MemoryImage(bytes);
      final landscape = image.width! > image.height!;
      final base = landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
      // Preserve long receipts at page width, without cropping their content.
      final height = math.max(
        base.height,
        (base.width - 24) * image.height! / image.width! + 24,
      );
      final format = PdfPageFormat(base.width, height);
      document.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(12),
          build:
              (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
      progress?.call(i + 1, page.type);
      await Future<void>.delayed(Duration.zero);
    }
    if (cancelled?.call() == true) {
      throw StateError('Penyiapan PDF dibatalkan.');
    }
    return document.save();
  }

  Future<File> saveTemporary(DutyEntry duty, Uint8List bytes) async {
    final root = await getTemporaryDirectory();
    final directory = Directory(
      p.join(root.path, 'duty_share', const Uuid().v4()),
    );
    await directory.create(recursive: true);
    final place = duty.destination.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File(
      p.join(
        directory.path,
        'Dinas_${place.isEmpty ? 'Perjalanan' : place}_${DateFormat('ddMMyyyy').format(duty.requestDate)}.pdf',
      ),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
