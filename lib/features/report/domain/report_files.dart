import 'dart:io';

class ReportFiles {
  const ReportFiles({required this.pdf, required this.excel});

  final File pdf;
  final File excel;

  List<File> get all => [pdf, excel];
}
