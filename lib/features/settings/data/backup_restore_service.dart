import 'dart:convert';
import 'dart:io';

import 'package:lembur/core/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class BackupSummary {
  const BackupSummary({required this.overtimeCount, required this.leaveCount});

  final int overtimeCount;
  final int leaveCount;
}

class BackupRestoreService {
  static const _format = 'kerjaku_ptc_backup';
  static const _backupVersion = 1;
  static const _tables = [
    'overtime_entries',
    'leave_entries',
    'leave_year_balances',
    'leave_defaults',
  ];
  static const _preferenceKeys = [
    'profile_name',
    'profile_worker_number',
    'profile_company',
    'profile_function',
    'profile_placement',
    'profile_job_type',
    'profile_location',
    'profile_cost_bearer',
    'signatory_names',
    'admin_whatsapp_number',
    'ptc_manager_name',
    'ptc_manager_position',
    'signatories_confirmed_v1',
    'approver_positions',
    'overtime_salary_v1',
    'hide_overtime_pay',
  ];

  Future<File> createBackup() async {
    final db = await AppDatabase.instance.database;
    final preferences = await SharedPreferences.getInstance();
    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in _tables) {
      tables[table] = await db.query(table);
    }
    final savedPreferences = <String, Object?>{};
    for (final key in _preferenceKeys) {
      final value = preferences.get(key);
      if (value != null) savedPreferences[key] = value;
    }

    final backup = {
      'format': _format,
      'backupVersion': _backupVersion,
      'databaseVersion': await db.getVersion(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'data': tables,
      'preferences': savedPreferences,
    };
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File(
      p.join(directory.path, 'KerjaKu_PTC_backup_$timestamp.json'),
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup),
    );
    return file;
  }

  Future<BackupSummary> inspectBackup(List<int> bytes) async {
    final data = _decodeAndValidate(bytes);
    final tables = data['data'] as Map<String, dynamic>;
    return BackupSummary(
      overtimeCount: (tables['overtime_entries'] as List).length,
      leaveCount: (tables['leave_entries'] as List).length,
    );
  }

  Future<BackupSummary> restoreBackup(List<int> bytes) async {
    final backup = _decodeAndValidate(bytes);
    final data = backup['data'] as Map<String, dynamic>;
    final preferencesData = backup['preferences'] as Map<String, dynamic>;
    final db = await AppDatabase.instance.database;
    final preferences = await SharedPreferences.getInstance();

    await db.transaction((txn) async {
      for (final table in _tables) {
        await txn.delete(table);
        final rows = data[table] as List;
        for (final value in rows) {
          await txn.insert(table, Map<String, Object?>.from(value as Map));
        }
      }
    });

    // Older Lembur backups may not contain newer profile and wage settings.
    // Update only settings present in the backup so those destination values
    // remain available for imported records and documents.
    for (final entry in preferencesData.entries) {
      final value = entry.value;
      if (value is String) {
        await preferences.setString(entry.key, value);
      } else if (value is bool) {
        await preferences.setBool(entry.key, value);
      } else if (value is int) {
        await preferences.setInt(entry.key, value);
      } else if (value is List) {
        await preferences.setStringList(
          entry.key,
          value.map((item) => item as String).toList(),
        );
      }
    }

    return BackupSummary(
      overtimeCount: (data['overtime_entries'] as List).length,
      leaveCount: (data['leave_entries'] as List).length,
    );
  }

  Map<String, dynamic> _decodeAndValidate(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != _format ||
        decoded['backupVersion'] != _backupVersion) {
      throw const FormatException(
        'Berkas ini bukan cadangan KerjaKu PTC yang didukung.',
      );
    }
    final databaseVersion = decoded['databaseVersion'];
    if (databaseVersion is! int || databaseVersion < 1 || databaseVersion > 3) {
      throw const FormatException('Versi data cadangan tidak didukung.');
    }
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Bagian data pada cadangan tidak valid.');
    }
    for (final table in _tables) {
      final rows = data[table];
      if (rows is! List || rows.any((row) => row is! Map)) {
        throw FormatException('Data $table pada cadangan tidak valid.');
      }
    }
    final preferences = decoded['preferences'];
    if (preferences is! Map<String, dynamic>) {
      throw const FormatException('Pengaturan pada cadangan tidak valid.');
    }
    for (final key in preferences.keys) {
      if (!_preferenceKeys.contains(key)) {
        throw const FormatException(
          'Cadangan berisi pengaturan yang tidak dikenal.',
        );
      }
    }
    for (final key in ['signatory_names', 'approver_positions']) {
      final value = preferences[key];
      if (value != null &&
          (value is! List || value.any((item) => item is! String))) {
        throw FormatException('Pengaturan $key pada cadangan tidak valid.');
      }
    }
    const stringKeys = {
      'profile_name',
      'profile_worker_number',
      'profile_company',
      'profile_function',
      'profile_placement',
      'profile_job_type',
      'profile_location',
      'profile_cost_bearer',
      'admin_whatsapp_number',
      'ptc_manager_name',
      'ptc_manager_position',
      'overtime_salary_v1',
    };
    const booleanKeys = {'signatories_confirmed_v1', 'hide_overtime_pay'};
    for (final key in stringKeys) {
      final value = preferences[key];
      if (value != null && value is! String) {
        throw FormatException('Pengaturan $key pada cadangan tidak valid.');
      }
    }
    for (final key in booleanKeys) {
      final value = preferences[key];
      if (value != null && value is! bool) {
        throw FormatException('Pengaturan $key pada cadangan tidak valid.');
      }
    }
    return decoded;
  }
}
