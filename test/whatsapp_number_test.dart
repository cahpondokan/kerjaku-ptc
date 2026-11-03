import 'package:flutter_test/flutter_test.dart';
import 'package:lembur/features/report/data/whatsapp_share_service.dart';

void main() {
  group('Normalisasi nomor WhatsApp admin', () {
    test('08 diubah menjadi 62', () {
      expect(
        WhatsAppShareService.normalizeNumber('0812-3456-7890'),
        '6281234567890',
      );
    });

    test('nomor 62 dipertahankan', () {
      expect(
        WhatsAppShareService.normalizeNumber('+62 812 3456 7890'),
        '6281234567890',
      );
    });

    test('nomor terlalu pendek tidak valid', () {
      expect(WhatsAppShareService.isValidNumber('08123'), isFalse);
    });
  });
}
