import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lembur/features/leave/domain/leave_calculator.dart';
import 'package:lembur/features/leave/domain/leave_entry.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class LeavePdfService {
  Future<Uint8List> build({
    required LeaveEntry entry,
    required int usedBeforeCurrent,
  }) async {
    final invalid = LeaveCalculator.validateRange(
      entry.startDate,
      entry.endDate,
    );
    if (invalid != null) throw StateError(invalid);
    if (usedBeforeCurrent < 0 ||
        usedBeforeCurrent + entry.days > LeaveCalculator.annualEntitlement) {
      throw StateError('Saldo cuti tidak valid. Periksa catatan cuti.');
    }
    if ([
      entry.applicantName,
      entry.workerNumber,
      entry.reason,
      entry.address,
      entry.aftName,
      entry.aftPosition,
      entry.managerName,
      entry.managerPosition,
    ].any((value) => value.trim().isEmpty)) {
      throw StateError('Data surat cuti belum lengkap.');
    }
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/logos/ptc_cuti.png')).buffer.asUint8List(),
    );
    final document = pw.Document(
      title: 'Form Permohonan Cuti ${entry.applicantName}',
      author: entry.applicantName,
      creator: 'KerjaKu PTC',
    );
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (_) => _form(entry, usedBeforeCurrent, logo),
      ),
    );
    return document.save();
  }

  pw.Widget _form(
    LeaveEntry entry,
    int usedBeforeCurrent,
    pw.MemoryImage logo,
  ) {
    final items = <pw.Widget>[];
    void line(
      double x1,
      double y1,
      double x2,
      double y2, {
      double weight = 0.4,
    }) {
      items.add(
        pw.Positioned(
          left: x1,
          top: y1,
          child: pw.Container(
            width: x2 == x1 ? weight : x2 - x1,
            height: y2 == y1 ? weight : y2 - y1,
            color: PdfColors.black,
          ),
        ),
      );
    }

    void rect(
      double x,
      double y,
      double width,
      double height, {
      double weight = 0.4,
    }) {
      items.add(
        pw.Positioned(
          left: x,
          top: y,
          child: pw.Container(
            width: width,
            height: height,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: weight)),
          ),
        ),
      );
    }

    void text(
      String value,
      double x,
      double y,
      double width, {
      double size = 10.4,
      double height = 14,
      bool bold = false,
      bool center = false,
    }) {
      items.add(
        pw.Positioned(
          left: x,
          top: y,
          child: pw.SizedBox(
            width: width,
            height: height,
            child: pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
              child: pw.Text(
                value.replaceAll(RegExp(r'\s+'), ' '),
                textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
                style: pw.TextStyle(
                  font: bold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
                  fontSize: size,
                ),
              ),
            ),
          ),
        ),
      );
    }

    void paragraph(
      String value,
      double x,
      double y,
      double width,
      double height,
    ) {
      items.add(
        pw.Positioned(
          left: x,
          top: y,
          child: pw.SizedBox(
            width: width,
            height: height,
            child: pw.Text(
              value.replaceAll(RegExp(r'\s+'), ' '),
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: 8.5,
                lineSpacing: 3,
              ),
            ),
          ),
        ),
      );
    }

    void digits(
      String value,
      double x,
      double y, {
      double cellWidth = 23.04,
      double height = 13,
    }) {
      for (var i = 0; i < value.length; i++) {
        rect(x + i * cellWidth, y, cellWidth, height);
        text(
          value[i],
          x + i * cellWidth,
          y,
          cellWidth,
          height: height,
          center: true,
        );
      }
    }

    void date(DateTime value, double y) {
      digits(value.day.toString().padLeft(2, '0'), 460.5, y, height: 15.7);
      text('/', 506.6, y, 23, height: 15.7, center: true);
      digits(value.month.toString().padLeft(2, '0'), 529.6, y, height: 15.7);
      text('/', 575.7, y, 23, height: 15.7, center: true);
      digits(value.year.toString(), 598.7, y, cellWidth: 28.3, height: 15.7);
    }

    void count(String label, int days, double y) {
      text(label, 324, y, 126);
      text(':', 451, y, 8);
      digits(days.toString().padLeft(2, '0'), 460.5, y);
      text('hari', 510, y, 30);
    }

    void signature(
      double x,
      double width,
      String heading,
      String role,
      String name,
      String position,
    ) {
      rect(x, 261, width, position.isEmpty ? 114.5 : 127.2);
      line(x, 273.6, x + width, 273.6);
      line(x, 362.7, x + width, 362.7);
      if (position.isNotEmpty) line(x, 375.4, x + width, 375.4);
      text(heading, x + 2, 261, width - 4, center: true);
      text(role, x + 2, 274, width - 4, size: 8, center: true, height: 11);
      text(
        name,
        x + 3,
        363.4,
        width - 6,
        size: 9.4,
        height: 11,
        bold: true,
        center: true,
      );
      if (position.isNotEmpty) {
        text(
          position,
          x + 3,
          376,
          width - 6,
          size: 7.7,
          height: 11,
          center: true,
        );
      }
    }

    // Coordinates reproduce the supplied landscape form; all signature spaces remain blank.
    rect(52, 54, 680.3, 347, weight: 0.8);
    line(52, 67, 732.3, 67);
    line(307.4, 67, 307.4, 401);
    text('Form Permohonan Cuti', 53.4, 54.5, 280, bold: true, height: 12);
    text('Tanggal', 53.4, 80.5, 65);
    text(':', 121, 80.5, 8);
    text(DateFormat('dd.MM.yyyy').format(entry.requestDate), 131, 80.5, 166);
    line(129, 94, 299, 94);
    text('Pemohon', 53.4, 94.5, 65);
    text(':', 121, 94.5, 8);
    text(entry.applicantName, 131, 94.5, 166);
    line(129, 108, 299, 108);

    rect(52, 118, 247, 130);
    text('Keterangan', 53.4, 118.6, 67);
    text(':', 121, 118.6, 8);
    line(52, 131, 299, 131);
    paragraph('1. ${entry.reason}', 54, 135, 241, 108);

    line(52, 261, 299, 261);
    line(52, 273.6, 299, 273.6);
    text('Alamat Cuti', 53.4, 261, 67);
    text(':', 121, 261, 8);
    paragraph(entry.address, 54, 277, 241, 107);
    line(52, 388.2, 299, 388.2);

    line(307.4, 79.7, 732.3, 79.7);
    line(307.4, 92.5, 732.3, 92.5);
    text('Record Cuti :', 309.3, 79.8, 180);
    items.add(
      pw.Positioned(
        left: 630,
        top: 68,
        child: pw.Container(
          color: PdfColors.white,
          width: 68,
          height: 31,
          child: pw.Image(logo, fit: pw.BoxFit.contain),
        ),
      ),
    );
    text('Hak Cuti Tahun', 324, 105, 126);
    text(':', 451, 105, 8);
    digits(entry.year.toString(), 460.5, 105);
    text('Tanggal Cuti', 324, 132, 126);
    text(':', 451, 132, 8);
    date(entry.startDate, 130.6);
    text('Masuk Kembali', 324, 159, 126);
    text(':', 451, 159, 8);
    date(entry.returnDate, 159);
    count('Lama Cuti', entry.days, 184.5);
    count('Cuti yang sudah diambil', usedBeforeCurrent, 210);
    count(
      'Sisa Cuti',
      LeaveCalculator.annualEntitlement - usedBeforeCurrent - entry.days,
      235.5,
    );
    signature(322, 127.4, 'Pemohon', 'Pekerja', entry.applicantName, '');
    signature(
      460.5,
      115.2,
      'Mengetahui',
      'User',
      entry.aftName,
      entry.aftPosition,
    );
    signature(
      575.7,
      136.3,
      'Menyetujui',
      'Manager Supply Manpower',
      entry.managerName,
      entry.managerPosition,
    );
    return pw.SizedBox(
      width: PdfPageFormat.a4.landscape.width,
      height: PdfPageFormat.a4.landscape.height,
      child: pw.Stack(children: items),
    );
  }
}
