import 'package:flutter_test/flutter_test.dart';
import 'package:lembur/features/report/data/spkl_number_formatter.dart';

void main() {
  test(
    'nomor SPKL hanya mengosongkan nomor urut dan mengikuti tahun lembur',
    () {
      final date = DateTime(2027, 2, 3);

      expect(
        SpklNumberFormatter.request(date),
        'No.SPKL -            / PPNLK0101 / 2027-S8',
      );
      expect(SpklNumberFormatter.order(date), 'No.            /SPKL/PTC/2027');
    },
  );
}
