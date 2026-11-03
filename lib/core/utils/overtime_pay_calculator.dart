import 'package:intl/intl.dart';

abstract final class OvertimePayCalculator {
  static const divisor = 173;

  static int calculate({
    required int monthlyBasisCents,
    required double convertedHours,
  }) {
    if (monthlyBasisCents <= 0 ||
        !convertedHours.isFinite ||
        convertedHours < 0) {
      throw ArgumentError('Dasar upah dan jam konversi tidak valid.');
    }
    // Input times have minute precision. A 1.5 multiplier can yield half a
    // converted minute. Keep that precision and round only the final rupiah.
    final halfMinutes = (convertedHours * 120).round();
    const denominator = divisor * 120 * 100;
    final numerator = monthlyBasisCents * halfMinutes;
    return (numerator + denominator ~/ 2) ~/ denominator;
  }

  static String rupiah(num value, {int decimals = 0}) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: decimals,
  ).format(value);
  static String hours(double value) =>
      NumberFormat('0.####', 'id_ID').format(value);
  static String basisLabel(int cents) =>
      rupiah(cents / 100, decimals: cents % 100 == 0 ? 0 : 2);

  /// Indonesian input: 5190000 or 5.190.000, optionally ending in ,25.
  static int? parseCents(String value, {bool allowDecimals = true}) {
    final raw = value.trim();
    if (!RegExp(r'^(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d{1,2})?$').hasMatch(raw)) {
      return null;
    }
    final parts = raw.replaceAll('.', '').split(',');
    if (!allowDecimals && parts.length > 1) return null;
    final fraction = parts.length == 1 ? '00' : parts.last.padRight(2, '0');
    return int.tryParse('${parts.first}$fraction');
  }
}
