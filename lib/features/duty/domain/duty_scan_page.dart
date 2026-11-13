import 'dart:typed_data';

enum DutyDocumentType {
  sppd('SPPD'),
  spd('SPD'),
  declaration('Deklarasi'),
  invoice('Invoice');

  const DutyDocumentType(this.label);
  final String label;
}

class DutyScanPage {
  const DutyScanPage({
    required this.id,
    required this.dutyId,
    required this.type,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id, dutyId;
  final DutyDocumentType type;
  final int position;
  final DateTime createdAt, updatedAt;
  static const columns = [
    'id',
    'duty_id',
    'kind',
    'position',
    'created_at',
    'updated_at',
  ];
  factory DutyScanPage.fromMap(Map<String, Object?> map) => DutyScanPage(
    id: map['id'] as String,
    dutyId: map['duty_id'] as String,
    type: DutyDocumentType.values.byName(map['kind'] as String),
    position: map['position'] as int,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
  static List<DutyScanPage> ordered(Iterable<DutyScanPage> pages) =>
      pages.toList()..sort((a, b) {
        final kind = a.type.index.compareTo(b.type.index);
        if (kind != 0) return kind;
        final order = a.position.compareTo(b.position);
        return order != 0 ? order : a.id.compareTo(b.id);
      });
}

abstract final class ScanImageData {
  static const maxBytes = 20 * 1024 * 1024;
  static void validate(Uint8List bytes) {
    final jpeg =
        bytes.length > 4 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff;
    final png =
        bytes.length > 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71;
    if ((!jpeg && !png) || bytes.length > maxBytes) {
      throw const FormatException(
        'Gambar scan tidak valid atau melebihi 20 MB per halaman.',
      );
    }
  }
}
