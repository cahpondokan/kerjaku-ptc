import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lembur/features/duty/data/duty_pdf_service.dart';
import 'duty_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('id_ID'));
  test(
    'PDF uses stored November date, optional serial, complete one-page content',
    () async {
      final service = DutyPdfService();
      for (final serial in ['', '0012']) {
        final bytes = await service.build(
          sampleDuty(changes: {'serial': serial}),
        );
        final raw = String.fromCharCodes(bytes);
        final text = RegExp(
          r'\[\((.*?)\)\]TJ',
        ).allMatches(raw).map((m) => m[1]).join(' ');
        expect(raw.startsWith('%PDF-'), isTrue);
        expect(
          text,
          contains('No. ${serial.isEmpty ? '...' : serial} /SPPD/ XI /2026-S8'),
        );
        expect(text, contains('SURAT PERMINTAAN PERJALANAN DINAS'));
        expect(text, contains('Andi Prasetyo'));
        expect(text, contains('02 November 2026'));
        expect(RegExp(r'/Type\s*/Page\b').allMatches(raw), hasLength(1));
        if (const bool.fromEnvironment('GENERATE_DUTY_SAMPLE')) {
          final output = File(
            'output/pdf/contoh-surat-dinas${serial.isEmpty ? '' : '-bernomor'}.pdf',
          );
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes);
        }
      }
    },
  );

  test(
    'Long field values stay on one A4 page; incomplete letters are blocked',
    () async {
      final service = DutyPdfService();
      final entry = sampleDuty(
        changes: {
          'purpose': List.filled(20, 'Koordinasi PTC').join(' '),
          'signer_position':
              'Pejabat Sementara Aviation Fuel Terminal Manager Ahmad Yani dan Koordinator Operasional Wilayah',
          'destination':
              'Terminal operasional wilayah Jawa Tengah dan Daerah Istimewa Yogyakarta',
        },
      );
      final bytes = await service.build(entry);
      expect(
        RegExp(r'/Type\s*/Page\b').allMatches(String.fromCharCodes(bytes)),
        hasLength(1),
      );
      if (const bool.fromEnvironment('GENERATE_DUTY_SAMPLE')) {
        await File(
          'output/pdf/contoh-surat-dinas-isian-panjang.pdf',
        ).writeAsBytes(bytes);
      }
      await expectLater(
        service.build(sampleDuty(changes: {'is_draft': 1})),
        throwsStateError,
      );
      await expectLater(
        service.build(sampleDuty(changes: {'signer_name': ''})),
        throwsStateError,
      );
    },
  );
}
