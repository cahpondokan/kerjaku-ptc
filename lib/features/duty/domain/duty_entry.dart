class DutyEntry {
  const DutyEntry({
    required this.id,
    required this.requestDate,
    required this.createdAt,
    required this.updatedAt,
    this.serial = '',
    this.recipient = '',
    this.applicantName = '',
    this.workerNumber = '',
    this.placement = '',
    this.jobType = '',
    this.origin = '',
    this.destination = '',
    this.startDate,
    this.returnDate,
    this.purpose = '',
    this.transport = 'Umum',
    this.costBearer = '',
    this.requestPlace = '',
    this.signerName = '',
    this.signerPosition = '',
    this.isDraft = true,
  });

  final String id, serial, recipient, applicantName, workerNumber;
  final String placement, jobType, origin, destination, purpose, transport;
  final String costBearer, requestPlace, signerName, signerPosition;
  final DateTime requestDate, createdAt, updatedAt;
  final DateTime? startDate, returnDate;
  final bool isDraft;

  static const romanMonths = [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
    'XI',
    'XII',
  ];

  static String numberFor(DateTime date, String serial) =>
      'No. ${serial.trim().isEmpty ? '...' : serial.trim()} '
      '/SPPD/ ${romanMonths[date.month - 1]} /${date.year}-S8';

  String get letterNumber => numberFor(requestDate, serial);

  int? get calendarDays {
    if (startDate == null || returnDate == null) return null;
    final start = DateTime.utc(
      startDate!.year,
      startDate!.month,
      startDate!.day,
    );
    final end = DateTime.utc(
      returnDate!.year,
      returnDate!.month,
      returnDate!.day,
    );
    return end.difference(start).inDays + 1;
  }

  static const fieldLimits = <String, int>{
    'serial': 20,
    'recipient': 120,
    'applicant_name': 100,
    'worker_number': 40,
    'placement': 120,
    'job_type': 80,
    'origin': 100,
    'destination': 100,
    'purpose': 300,
    'transport': 60,
    'cost_bearer': 120,
    'request_place': 80,
    'signer_name': 100,
    'signer_position': 120,
  };

  String? validate({bool requireComplete = false}) {
    if (id.trim().isEmpty) return 'Identitas surat tidak valid.';
    if (serial.trim().isNotEmpty &&
        !RegExp(r'^\d{1,20}$').hasMatch(serial.trim())) {
      return 'Nomor urut harus berupa angka, maksimal 20 digit.';
    }
    final map = toMap();
    for (final field in fieldLimits.entries) {
      if ((map[field.key] as String).length > field.value) {
        return 'Isian surat terlalu panjang. Periksa kembali formulir.';
      }
    }
    if (calendarDays != null && calendarDays! < 1) {
      return 'Tanggal kembali tidak boleh sebelum tanggal mulai.';
    }
    if (!requireComplete) return null;
    final requiredFields = {
      'Nama pekerja': applicantName,
      'No. ID Card': workerNumber,
      'Bagian / Penempatan': placement,
      'Jenis pekerjaan': jobType,
      'Kepada': recipient,
      'Dari / Asal': origin,
      'Tempat / Tujuan': destination,
      'Keperluan': purpose,
      'Berkendaraan': transport,
      'Biaya ditanggung oleh': costBearer,
      'Tempat surat': requestPlace,
      'Penandatangan': signerName,
      'Jabatan penandatangan': signerPosition,
    };
    for (final field in requiredFields.entries) {
      if (field.value.trim().isEmpty) return '${field.key} wajib diisi.';
    }
    if (startDate == null || returnDate == null) {
      return 'Pilih tanggal mulai dan kembali.';
    }
    return null;
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'serial': serial,
    'recipient': recipient,
    'applicant_name': applicantName,
    'worker_number': workerNumber,
    'placement': placement,
    'job_type': jobType,
    'origin': origin,
    'destination': destination,
    'start_date': startDate?.toIso8601String(),
    'return_date': returnDate?.toIso8601String(),
    'request_date': requestDate.toIso8601String(),
    'purpose': purpose,
    'transport': transport,
    'cost_bearer': costBearer,
    'request_place': requestPlace,
    'signer_name': signerName,
    'signer_position': signerPosition,
    'is_draft': isDraft ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory DutyEntry.fromMap(Map<String, Object?> map) => DutyEntry(
    id: map['id'] as String,
    serial: map['serial'] as String,
    recipient: map['recipient'] as String,
    applicantName: map['applicant_name'] as String,
    workerNumber: map['worker_number'] as String,
    placement: map['placement'] as String,
    jobType: map['job_type'] as String,
    origin: map['origin'] as String,
    destination: map['destination'] as String,
    startDate:
        map['start_date'] == null
            ? null
            : DateTime.parse(map['start_date'] as String),
    returnDate:
        map['return_date'] == null
            ? null
            : DateTime.parse(map['return_date'] as String),
    requestDate: DateTime.parse(map['request_date'] as String),
    purpose: map['purpose'] as String,
    transport: map['transport'] as String,
    costBearer: map['cost_bearer'] as String,
    requestPlace: map['request_place'] as String,
    signerName: map['signer_name'] as String,
    signerPosition: map['signer_position'] as String,
    isDraft: map['is_draft'] == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
}
