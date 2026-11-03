import 'package:lembur/core/constants/app_constants.dart';

class UserProfile {
  const UserProfile({
    this.name = '',
    this.workerNumber = '',
    this.company = AppConstants.companyDefault,
    this.function = 'Maintenance',
    this.placement = AppConstants.placementDefault,
    this.jobType = AppConstants.jobTypeDefault,
    this.location = AppConstants.locationDefault,
    this.costBearer = AppConstants.costBearerDefault,
  });

  final String name;
  final String workerNumber;
  final String company;
  final String function;
  final String placement;
  final String jobType;
  final String location;
  final String costBearer;

  List<String> get missingRequiredFields => [
    if (name.trim().isEmpty) 'Nama pekerja',
    if (workerNumber.trim().isEmpty) 'Nomor pekerja',
    if (company.trim().isEmpty) 'Nama perusahaan',
    if (function.trim().isEmpty) 'Fungsi/bagian',
    if (placement.trim().isEmpty) 'Penempatan',
    if (jobType.trim().isEmpty) 'Jenis pekerjaan',
    if (location.trim().isEmpty) 'Lokasi',
    if (costBearer.trim().isEmpty) 'Penanggung biaya',
  ];

  bool get isComplete => missingRequiredFields.isEmpty;

  UserProfile copyWith({
    String? name,
    String? workerNumber,
    String? company,
    String? function,
    String? placement,
    String? jobType,
    String? location,
    String? costBearer,
  }) {
    return UserProfile(
      name: name ?? this.name,
      workerNumber: workerNumber ?? this.workerNumber,
      company: company ?? this.company,
      function: function ?? this.function,
      placement: placement ?? this.placement,
      jobType: jobType ?? this.jobType,
      location: location ?? this.location,
      costBearer: costBearer ?? this.costBearer,
    );
  }
}
