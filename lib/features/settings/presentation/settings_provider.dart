import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:lembur/features/overtime/domain/overtime_salary.dart';
import 'package:lembur/core/constants/app_constants.dart';
import 'package:lembur/features/settings/domain/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _signatoryKey = 'signatory_names';
  static const _adminWhatsAppKey = 'admin_whatsapp_number';
  static const _ptcManagerNameKey = 'ptc_manager_name';
  static const _ptcManagerPositionKey = 'ptc_manager_position';
  static const _confirmedKey = 'signatories_confirmed_v1';
  static const _positionsKey = 'approver_positions';
  static const _salaryKey = 'overtime_salary_v1';
  static const _hidePayKey = 'hide_overtime_pay';
  OvertimeSalary? _salary;
  bool _hidePay = false;
  OvertimeSalary? get salary => _salary;
  bool get hidePay => _hidePay;

  static const defaultPtcManagerName = 'Ricky Roy Sagita';
  static const defaultPtcManagerPosition = 'Manager Manpower Supply - PTC';

  UserProfile _profile = const UserProfile();
  List<String> _signatories = ['Joni Herawan', 'Ricky Roy Sagita', '', ''];
  List<String> _approverPositions = List.of(AppConstants.approverPositions);
  bool _signatoriesConfirmed = false;
  String _adminWhatsApp = '';
  String _ptcManagerName = defaultPtcManagerName;
  String _ptcManagerPosition = defaultPtcManagerPosition;
  bool _loaded = false;

  UserProfile get profile => _profile;
  List<String> get signatories => List.unmodifiable(_signatories);
  String get adminWhatsApp => _adminWhatsApp;
  String get ptcManagerName => _ptcManagerName;
  String get ptcManagerPosition => _ptcManagerPosition;
  bool get loaded => _loaded;
  List<String> get approverPositions => List.unmodifiable(_approverPositions);
  List<String> get availableSignatories =>
      _signatories.where(isValidSignatory).toSet().toList();
  List<String> get availableApproverPositions =>
      _approverPositions
          .where((value) => value.trim().isNotEmpty)
          .toSet()
          .toList();
  bool get signatoryDataComplete =>
      availableSignatories.isNotEmpty &&
      _signatories.every((name) => name.isEmpty || isValidSignatory(name)) &&
      availableApproverPositions.isNotEmpty &&
      isValidSignatory(_ptcManagerName) &&
      _ptcManagerPosition.trim().isNotEmpty;
  bool get signatoriesConfirmed =>
      _signatoriesConfirmed && signatoryDataComplete;
  bool get documentsReady =>
      loaded && profile.isComplete && signatoriesConfirmed;

  static bool isValidSignatory(String value) {
    final name = value.trim();
    return name.isNotEmpty &&
        name != '-' &&
        !RegExp(
          r'^Nama Penandatangan\s*\d*$',
          caseSensitive: false,
        ).hasMatch(name);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _salary = null;
    _signatories = ['Joni Herawan', 'Ricky Roy Sagita', '', ''];
    _approverPositions = List.of(AppConstants.approverPositions);
    _signatoriesConfirmed = false;
    _adminWhatsApp = '';
    _ptcManagerName = defaultPtcManagerName;
    _ptcManagerPosition = defaultPtcManagerPosition;
    final salaryJson = prefs.getString(_salaryKey);
    if (salaryJson != null) {
      try {
        final value = OvertimeSalary.fromMap(
          jsonDecode(salaryJson) as Map<String, dynamic>,
        );
        if (value.isValid) _salary = value;
      } catch (_) {
        // Invalid salary settings must not block loading the worker's profile.
      }
    }
    _hidePay = prefs.getBool(_hidePayKey) ?? false;
    _profile = UserProfile(
      name: prefs.getString('profile_name') ?? '',
      workerNumber: prefs.getString('profile_worker_number') ?? '',
      company:
          prefs.getString('profile_company') ?? const UserProfile().company,
      function:
          prefs.getString('profile_function') ?? const UserProfile().function,
      placement:
          prefs.getString('profile_placement') ?? const UserProfile().placement,
      jobType:
          prefs.getString('profile_job_type') ?? const UserProfile().jobType,
      location:
          prefs.getString('profile_location') ?? const UserProfile().location,
      costBearer:
          prefs.getString('profile_cost_bearer') ??
          const UserProfile().costBearer,
    );

    final saved = prefs.getStringList(_signatoryKey);
    if (saved != null && saved.isNotEmpty) {
      _signatories =
          saved
              .take(4)
              .map((name) => isValidSignatory(name) ? name.trim() : '')
              .toList();
      while (_signatories.length < 4) {
        _signatories.add('');
      }
    }

    final positions = prefs.getStringList(_positionsKey);
    if (positions != null) {
      _approverPositions =
          positions.take(2).map((value) => value.trim()).toList();
      while (_approverPositions.length < 2) {
        _approverPositions.add('');
      }
    }
    _signatoriesConfirmed = prefs.getBool(_confirmedKey) ?? false;

    _adminWhatsApp = prefs.getString(_adminWhatsAppKey) ?? '';
    _ptcManagerName =
        prefs.getString(_ptcManagerNameKey) ?? defaultPtcManagerName;
    _ptcManagerPosition =
        prefs.getString(_ptcManagerPositionKey) ?? defaultPtcManagerPosition;
    _loaded = true;
    notifyListeners();
  }

  Future<void> saveSalary(OvertimeSalary value) async {
    if (!loaded || !value.isValid) {
      throw StateError('Isi komponen gaji dengan benar.');
    }
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_salaryKey, jsonEncode(value.toMap()))) {
      throw StateError('Gaji belum tersimpan. Coba lagi.');
    }
    _salary = value;
    notifyListeners();
  }

  Future<void> setHidePay(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(_hidePayKey, value)) {
      throw StateError('Pengaturan belum tersimpan.');
    }
    _hidePay = value;
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString('profile_name', profile.name),
      prefs.setString('profile_worker_number', profile.workerNumber),
      prefs.setString('profile_company', profile.company),
      prefs.setString('profile_function', profile.function),
      prefs.setString('profile_placement', profile.placement),
      prefs.setString('profile_job_type', profile.jobType),
      prefs.setString('profile_location', profile.location),
      prefs.setString('profile_cost_bearer', profile.costBearer),
    ]);
    notifyListeners();
  }

  Future<void> updateSignatory(int index, String name) async {
    if (index < 0 || index >= 4) {
      return;
    }

    _signatories[index] = name.trim();
    _signatoriesConfirmed = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_signatoryKey, _signatories);
    await prefs.setBool(_confirmedKey, false);
    notifyListeners();
  }

  Future<void> updateApproverPosition(int index, String position) async {
    if (index < 0 || index >= _approverPositions.length) return;
    _approverPositions[index] = position.trim();
    _signatoriesConfirmed = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_positionsKey, _approverPositions);
    await prefs.setBool(_confirmedKey, false);
    notifyListeners();
  }

  Future<bool> confirmSignatories() async {
    if (!loaded || !signatoryDataComplete) return false;
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setBool(_confirmedKey, true);
    _signatoriesConfirmed = saved;
    notifyListeners();
    return saved;
  }

  Future<void> saveAdminWhatsApp(String number) async {
    _adminWhatsApp = normalizeWhatsAppNumber(number);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminWhatsAppKey, _adminWhatsApp);
    notifyListeners();
  }

  Future<void> savePtcManager({
    required String name,
    required String position,
  }) async {
    _ptcManagerName = name.trim();
    _ptcManagerPosition = position.trim();
    _signatoriesConfirmed = false;

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_ptcManagerNameKey, _ptcManagerName),
      prefs.setString(_ptcManagerPositionKey, _ptcManagerPosition),
      prefs.setBool(_confirmedKey, false),
    ]);
    notifyListeners();
  }

  static String normalizeWhatsAppNumber(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    } else if (digits.startsWith('8')) {
      digits = '62$digits';
    }
    return digits;
  }

  static bool isValidWhatsAppNumber(String value) {
    final normalized = normalizeWhatsAppNumber(value);
    return normalized.length >= 10 && normalized.length <= 15;
  }
}
