import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:lembur/core/utils/date_formatter.dart';
import 'package:lembur/core/utils/duration_calculator.dart';
import 'package:lembur/features/overtime/domain/overtime_entry.dart';
import 'package:lembur/features/report/data/spkl_number_formatter.dart';
import 'package:lembur/features/report/domain/report_files.dart';
import 'package:lembur/features/settings/domain/user_profile.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportExportService {
  Future<ReportFiles> createAll({
    required List<OvertimeEntry> entries,
    required UserProfile profile,
    required DateTime month,
    required String ptcManagerName,
    required String ptcManagerPosition,
  }) async {
    final pdf = await createSpklPdf(
      entries: entries,
      profile: profile,
      month: month,
      ptcManagerName: ptcManagerName,
      ptcManagerPosition: ptcManagerPosition,
    );
    final excel = await createExcelReport(
      entries: entries,
      profile: profile,
      month: month,
    );
    return ReportFiles(pdf: pdf, excel: excel);
  }

  Future<File> createSpklPdf({
    required List<OvertimeEntry> entries,
    required UserProfile profile,
    required DateTime month,
    required String ptcManagerName,
    required String ptcManagerPosition,
  }) async {
    _requireEntries(entries);
    final logos = await _loadPdfLogos();
    final document = pw.Document(
      title: 'SPKL ${AppDateFormatter.month(month)}',
      author: profile.name,
      creator: 'KerjaKu PTC',
    );

    for (final entry in entries) {
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(28, 22, 28, 20),
          build:
              (_) => _spklPage(
                profile: profile,
                entry: entry,
                logos: logos,
                ptcManagerName: ptcManagerName,
                ptcManagerPosition: ptcManagerPosition,
              ),
        ),
      );
    }

    final directory = await _exportDirectory();
    final name =
        'SPKL_${AppDateFormatter.fileMonth(month)}_${_safeName(profile.name)}.pdf';
    final file = File(p.join(directory.path, name));
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }

  Future<File> createExcelReport({
    required List<OvertimeEntry> entries,
    required UserProfile profile,
    required DateTime month,
  }) async {
    _requireEntries(entries);
    final workbook = Excel.createExcel();
    const sheetName = 'Rekap Lembur';
    final defaultSheet = workbook.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      workbook.rename(defaultSheet, sheetName);
    }
    final sheet = workbook[sheetName];

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 12,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
    final bodyStyle = CellStyle(
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
    final centeredBodyStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
    final totalStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#D9E8F5'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('K1'),
      customValue: TextCellValue(
        'JUSTIFIKASI KELEBIHAN JAM KERJA LEMBUR TAD AFT AHMAD YANI',
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('K2'),
      customValue: TextCellValue(
        'PERIODE BULAN ${AppDateFormatter.month(month).toUpperCase()}',
      ),
    );
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = titleStyle;
    sheet.cell(CellIndex.indexByString('A2')).cellStyle = titleStyle;

    const headers = <String>[
      'NO.',
      'HARI',
      'TANGGAL',
      'NAMA TKJP',
      'NOMOR PEKERJA',
      'NAMA PT.',
      'FUNGSI',
      'JAM LEMBUR',
      'JUMLAH JAM NYATA',
      'JUMLAH JAM KONVERSI',
      'KETERANGAN',
    ];

    for (var column = 0; column < headers.length; column++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 3),
      );
      cell.value = TextCellValue(headers[column]);
      cell.cellStyle = headerStyle;
    }

    var totalActual = 0.0;
    var totalConverted = 0.0;
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      totalActual += entry.actualHours;
      totalConverted += entry.convertedHours;
      final row = index + 4;
      final values = <CellValue>[
        IntCellValue(index + 1),
        TextCellValue(AppDateFormatter.day(entry.overtimeDate)),
        TextCellValue(AppDateFormatter.dateOnly(entry.overtimeDate)),
        TextCellValue(profile.name),
        TextCellValue(profile.workerNumber),
        TextCellValue(profile.company),
        TextCellValue(profile.function),
        TextCellValue(
          '${_documentTime(entry.startTime)}    s/d    '
          '${_documentTime(entry.endTime)}',
        ),
        DoubleCellValue(entry.actualHours),
        DoubleCellValue(entry.convertedHours),
        TextCellValue(entry.workDescription),
      ];

      for (var column = 0; column < values.length; column++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
        );
        cell.value = values[column];
        cell.cellStyle =
            (column <= 2 || column == 4 || (column >= 7 && column <= 9))
                ? centeredBodyStyle
                : bodyStyle;
      }
    }

    final totalRow = entries.length + 4;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: totalRow),
      customValue: TextCellValue('Total'),
    );
    final totalLabelCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow),
    );
    totalLabelCell.cellStyle = totalStyle;

    final totalActualCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: totalRow),
    );
    totalActualCell.value = DoubleCellValue(totalActual);
    totalActualCell.cellStyle = totalStyle;

    final totalConvertedCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: totalRow),
    );
    totalConvertedCell.value = DoubleCellValue(totalConverted);
    totalConvertedCell.cellStyle = totalStyle;

    final totalDescriptionCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: totalRow),
    );
    totalDescriptionCell.cellStyle = totalStyle;

    final signatory = entries.first;
    final signatureDate = DateTime(month.year, month.month + 1, 1);
    final signatureRow = totalRow + 3;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: signatureRow),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: signatureRow),
      customValue: TextCellValue(
        'Semarang, ${AppDateFormatter.dateOnly(signatureDate)}',
      ),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: signatureRow + 1),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: signatureRow + 1),
      customValue: TextCellValue('Mengetahui'),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: signatureRow + 2),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: signatureRow + 2),
      customValue: TextCellValue(signatory.approverPosition),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: signatureRow + 6),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: signatureRow + 6),
      customValue: TextCellValue(signatory.approverName),
    );

    const widths = <double>[6, 12, 17, 25, 18, 31, 18, 24, 13, 15, 54];
    for (var index = 0; index < widths.length; index++) {
      sheet.setColumnWidth(index, widths[index]);
    }

    final bytes = workbook.save();
    if (bytes == null) {
      throw StateError('File Excel tidak dapat dibuat.');
    }

    final directory = await _exportDirectory();
    final name =
        'REKAP_LEMBUR_${AppDateFormatter.fileMonth(month)}_${_safeName(profile.name)}.xlsx';
    final file = File(p.join(directory.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<_PdfLogos> _loadPdfLogos() async {
    final pertaminaData = await rootBundle.load(
      'assets/logos/pertamina_patran.png',
    );
    final ptcData = await rootBundle.load('assets/logos/ptc.png');

    return _PdfLogos(
      pertamina: pw.MemoryImage(pertaminaData.buffer.asUint8List()),
      ptc: pw.MemoryImage(ptcData.buffer.asUint8List()),
    );
  }

  pw.Widget _spklPage({
    required UserProfile profile,
    required OvertimeEntry entry,
    required _PdfLogos logos,
    required String ptcManagerName,
    required String ptcManagerPosition,
  }) {
    final fullDate = _documentFullDate(entry.overtimeDate);
    final dateOnly = AppDateFormatter.dateOnly(entry.overtimeDate);
    final actual = DurationCalculator.displayHours(entry.actualHours);
    final startTime = _documentTime(entry.startTime);
    final endTime = _documentTime(entry.endTime);
    final managerName =
        ptcManagerName.trim().isEmpty
            ? 'Ricky Roy Sagita'
            : ptcManagerName.trim();
    final managerPosition =
        ptcManagerPosition.trim().isEmpty
            ? 'Manager Manpower Supply - PTC'
            : ptcManagerPosition.trim();

    return pw.DefaultTextStyle(
      style: const pw.TextStyle(fontSize: 8.7, lineSpacing: 1.05),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _documentHeader(
            logo: logos.pertamina,
            logoWidth: 106,
            logoHeight: 39,
            titleLines: const ['SURAT PERMINTAAN KERJA LEMBUR'],
            numberLine: SpklNumberFormatter.request(entry.overtimeDate),
          ),
          pw.SizedBox(height: 9),
          _field('Kepada', profile.company),
          pw.SizedBox(height: 8),
          pw.Text('Mengharap bantuan Saudara untuk menugaskan :'),
          pw.SizedBox(height: 2),
          _field('Nama', profile.name),
          _field('No. Pekerja', profile.workerNumber),
          _field('Bagian / Penempatan', profile.placement),
          _field('Jenis Pekerjaan', profile.jobType),
          pw.SizedBox(height: 8),
          pw.Text('Untuk melaksanakan kerja lembur pada :'),
          pw.SizedBox(height: 2),
          _field('Hari/ Tanggal', fullDate),
          _field('Waktu', '$startTime  s/d  $endTime    Jumlah: $actual Jam'),
          _field('Lokasi', profile.location),
          _field('Biaya ditanggung oleh', profile.costBearer),
          _field('Pekerjaan yang dilemburkan', entry.workDescription),
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 290,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Semarang, $dateOnly'),
                  pw.Text(entry.approverPosition),
                  pw.SizedBox(height: 31),
                  pw.Text(entry.approverName),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Keterangan :'),
          _noteLine(
            '1.',
            'Untuk permintaan lembur di daerah battery limit/hazardous area',
          ),
          _noteLine(
            '2.',
            'Ditandatangani oleh user minimal Manager/Ast.Manager/OH '
                '(unit area) tempat TKJP ditempatkan',
          ),
          pw.SizedBox(height: 14),
          _documentHeader(
            logo: logos.ptc,
            logoWidth: 110,
            logoHeight: 49,
            titleLines: const [
              'PT. PERTAMINA TRAINING & CONSULTING',
              'SURAT PERINTAH KERJA LEMBUR',
            ],
            numberLine: SpklNumberFormatter.order(entry.overtimeDate),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Dengan ini menugaskan :'),
          pw.SizedBox(height: 1),
          _field('Nama', profile.name),
          _field('No. Pekerja', profile.workerNumber),
          _field('Bagian / Penempatan', profile.placement),
          _field('Jenis Pekerjaan', profile.jobType),
          pw.SizedBox(height: 7),
          pw.Text('Untuk melaksanakan kerja lembur pada :'),
          pw.SizedBox(height: 1),
          _field('Hari/ Tanggal', fullDate),
          _field('Waktu', '$startTime  s/d  $endTime    Jumlah : $actual Jam'),
          _field('Lokasi', profile.location),
          _field('Biaya ditanggung oleh', profile.costBearer),
          _field('Pekerjaan yang dilemburkan', entry.workDescription),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Ybs,'),
                    pw.SizedBox(height: 50),
                    pw.Text(profile.name),
                  ],
                ),
              ),
              pw.SizedBox(width: 25),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Semarang, $dateOnly'),
                    pw.Text('Menyetujui,'),
                    pw.Text(managerPosition),
                    pw.SizedBox(height: 31),
                    pw.Text(managerName),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Center(child: pw.Text('Mengetahui')),
          pw.SizedBox(height: 3),
          _attendanceTables(startTime: startTime, endTime: endTime),
          pw.SizedBox(height: 5),
          pw.Text(
            '*) Jika lembur di daerah battery limit / hazardous area.',
            style: const pw.TextStyle(fontSize: 7.2),
          ),
        ],
      ),
    );
  }

  pw.Widget _documentHeader({
    required pw.MemoryImage logo,
    required double logoWidth,
    required double logoHeight,
    required List<String> titleLines,
    required String numberLine,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(width: logoWidth),
        pw.Expanded(
          child: pw.Column(
            children: [
              for (final line in titleLines)
                pw.Text(
                  line,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 11.1,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              pw.Text(
                numberLine,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(
          width: logoWidth,
          height: logoHeight,
          child: pw.Image(
            logo,
            fit: pw.BoxFit.contain,
            alignment: pw.Alignment.centerRight,
          ),
        ),
      ],
    );
  }

  pw.Widget _field(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 126, child: pw.Text(label)),
          pw.SizedBox(width: 10, child: pw.Text(':')),
          pw.Expanded(child: pw.Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  pw.Widget _noteLine(String number, String text) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 20, child: pw.Text(number)),
        pw.Expanded(child: pw.Text(text)),
      ],
    );
  }

  pw.Widget _attendanceTables({
    required String startTime,
    required String endTime,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Security'),
              _attendanceTable(startTime: startTime, endTime: endTime),
            ],
          ),
        ),
        pw.SizedBox(width: 28),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('HSE*)'),
              _attendanceTable(startTime: startTime, endTime: endTime),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _attendanceTable({
    required String startTime,
    required String endTime,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.45),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          children: [
            _tableCell('Keterangan'),
            _tableCell('Pukul'),
            _tableCell('Tanda Tangan'),
          ],
        ),
        pw.TableRow(
          children: [
            _tableCell('Jam Masuk'),
            _tableCell(startTime),
            _tableCell(''),
          ],
        ),
        pw.TableRow(
          children: [
            _tableCell('Jam Pulang'),
            _tableCell(endTime),
            _tableCell(''),
          ],
        ),
      ],
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Container(
      height: 20,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 7.2),
      ),
    );
  }

  String _documentFullDate(DateTime date) {
    final day = AppDateFormatter.day(date).replaceAll('Jumat', "Jum'at");
    return '$day, ${AppDateFormatter.dateOnly(date)}';
  }

  String _documentTime(String value) => value.replaceAll(':', '.');

  Future<Directory> _exportDirectory() async {
    final root =
        await getExternalStorageDirectory() ??
        await getApplicationSupportDirectory();
    final directory = Directory(p.join(root.path, 'Lembur', 'exports'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  void _requireEntries(List<OvertimeEntry> entries) {
    if (entries.isEmpty) {
      throw StateError('Belum ada data lembur untuk diekspor.');
    }
  }

  String _safeName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return cleaned.isEmpty ? 'PEKERJA' : cleaned.toUpperCase();
  }
}

class _PdfLogos {
  const _PdfLogos({required this.pertamina, required this.ptc});

  final pw.MemoryImage pertamina;
  final pw.MemoryImage ptc;
}
