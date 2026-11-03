abstract final class SpklNumberFormatter {
  static const _blankSequence = '          ';

  static String request(DateTime overtimeDate) {
    return 'No.SPKL - $_blankSequence / PPNLK0101 / '
        '${overtimeDate.year}-S8';
  }

  static String order(DateTime overtimeDate) {
    return 'No. $_blankSequence /SPKL/PTC/${overtimeDate.year}';
  }
}
