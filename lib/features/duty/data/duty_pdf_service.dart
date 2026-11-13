import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lembur/features/duty/domain/duty_entry.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DutyPdfService {
  static Future<Uint8List>? _logo;
  // Render the existing logo in black for this monochrome letter only.
  static Future<Uint8List> _blackLogo() async {
    final data = await rootBundle.load('assets/logos/pertamina_patran.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImage(
      frame.image,
      ui.Offset.zero,
      ui.Paint()
        ..colorFilter = const ui.ColorFilter.mode(
          ui.Color(0xFF000000),
          ui.BlendMode.srcIn,
        ),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(frame.image.width, frame.image.height);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    frame.image.dispose();
    codec.dispose();
    if (png == null) throw StateError('Logo surat tidak dapat dimuat.');
    return png.buffer.asUint8List();
  }

  static String fileName(DutyEntry entry) {
    final name = entry.applicantName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    return 'SPPD_${name.isEmpty ? 'Pekerja' : name}_${DateFormat('ddMMyyyy').format(entry.requestDate)}.pdf';
  }

  Future<Uint8List> build(DutyEntry entry) async {
    if (entry.isDraft) {
      throw StateError('Lengkapi dan simpan surat sebelum membuat PDF.');
    }
    final invalid = entry.validate(requireComplete: true);
    if (invalid != null) throw StateError(invalid);
    final logo = pw.MemoryImage(await (_logo ??= _blackLogo()));
    final pdf = pw.Document(
      compress: false,
      title: 'Surat Permintaan Perjalanan Dinas ${entry.applicantName}',
      author: entry.applicantName,
      creator: 'KerjaKu PTC',
    );
    final normal = pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10.2);
    String clean(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
    pw.Widget row(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 172, child: pw.Text(label, style: normal)),
          pw.SizedBox(width: 25, child: pw.Text(':', style: normal)),
          pw.Expanded(child: pw.Text(clean(value), style: normal)),
        ],
      ),
    );
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build:
            (_) => pw.SizedBox(
              width: PdfPageFormat.a4.width,
              height: PdfPageFormat.a4.height,
              child: pw.Stack(
                children: [
                  pw.Positioned(
                    left: 408,
                    top: 109,
                    child: pw.Image(logo, width: 103, height: 35),
                  ),
                  pw.Positioned(
                    left: 88,
                    top: 156,
                    child: pw.SizedBox(
                      width: 440,
                      child: pw.Text(
                        'SURAT PERMINTAAN PERJALANAN DINAS',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: pw.Font.helveticaBold(),
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ),
                  pw.Positioned(
                    left: 88,
                    top: 175,
                    child: pw.SizedBox(
                      width: 440,
                      child: pw.Text(
                        entry.letterNumber,
                        textAlign: pw.TextAlign.center,
                        style: normal,
                      ),
                    ),
                  ),
                  pw.Positioned(
                    left: 88,
                    top: 224,
                    child: pw.SizedBox(
                      width: 440,
                      height: math.min(548, PdfPageFormat.a4.height - 270),
                      child: pw.FittedBox(
                        fit: pw.BoxFit.scaleDown,
                        alignment: pw.Alignment.topLeft,
                        child: pw.SizedBox(
                          width: 440,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              row('Kepada', entry.recipient),
                              pw.SizedBox(height: 18),
                              pw.Text(
                                'Mengharap bantuan Saudara untuk menugaskan :',
                                style: normal,
                              ),
                              pw.SizedBox(height: 6),
                              row('Nama', entry.applicantName),
                              row('No. ID Card', entry.workerNumber),
                              row('Bagian / Penempatan', entry.placement),
                              row('Jenis Pekerjaan', entry.jobType),
                              pw.SizedBox(height: 15),
                              pw.Text(
                                'Untuk melaksanakan perjalanan dinas dalam negeri :',
                                style: normal,
                              ),
                              pw.SizedBox(height: 6),
                              row('Dari / Asal', entry.origin),
                              row('Tempat / Tujuan', entry.destination),
                              row(
                                'Terhitung mulai tanggal',
                                DateFormat(
                                  'dd.MM.yyyy',
                                ).format(entry.startDate!),
                              ),
                              row(
                                'Kembali tanggal',
                                DateFormat(
                                  'dd.MM.yyyy',
                                ).format(entry.returnDate!),
                              ),
                              row('Keperluan', entry.purpose),
                              row('Berkendaraan', entry.transport),
                              row('Biaya ditanggung oleh', entry.costBearer),
                              pw.SizedBox(height: 68),
                              pw.Text(
                                '${clean(entry.requestPlace)}, ${DateFormat('dd MMMM yyyy', 'id_ID').format(entry.requestDate)}',
                                style: normal,
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text(
                                clean(entry.signerPosition),
                                style: normal,
                              ),
                              pw.SizedBox(height: 73),
                              pw.Text(clean(entry.signerName), style: normal),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
    return pdf.save();
  }
}
