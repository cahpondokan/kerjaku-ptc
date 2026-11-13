import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:lembur/core/database/app_database.dart';
import 'package:lembur/features/duty/data/duty_scan_blobs.dart';
import 'package:lembur/features/duty/domain/duty_entry.dart';
import 'package:lembur/features/duty/domain/duty_scan_page.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class BackupSummary {
  const BackupSummary({
    required this.overtimeCount,
    required this.leaveCount,
    this.dutyCount = 0,
    this.includesDuty = false,
    this.scanPageCount = 0,
    this.includesScans = false,
  });

  final int overtimeCount;
  final int leaveCount;
  final int dutyCount;
  final bool includesDuty;
  final int scanPageCount;
  final bool includesScans;
}

class BackupRestoreService {
  BackupRestoreService({
    Future<Database> Function()? database,
    Future<Directory> Function()? temporaryDirectory,
  }) : _database = database ?? (() => AppDatabase.instance.database),
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;
  final Future<Database> Function() _database;
  final Future<Directory> Function() _temporaryDirectory;
  static const _format = 'kerjaku_ptc_backup';
  static const _backupVersion = 3;
  static const _tables = [
    'overtime_entries',
    'leave_entries',
    'leave_year_balances',
    'leave_defaults',
    'duty_entries',
    'duty_scan_pages',
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
    final db = await _database();
    final preferences = await SharedPreferences.getInstance();
    final tables = <String, List<Map<String, Object?>>>{};
    await db.transaction((txn) async {
      for (final table in _tables) {
        final rows =
            table == 'duty_scan_pages'
                ? await DutyScanBlobs.allRows(txn)
                : await txn.query(table);
        tables[table] =
            table != 'duty_scan_pages'
                ? rows
                : rows
                    .map(
                      (row) => {
                        ...row,
                        'image': base64Encode(row['image'] as List<int>),
                        'original_image':
                            row['original_image'] == null
                                ? null
                                : base64Encode(
                                  row['original_image'] as List<int>,
                                ),
                      },
                    )
                    .toList();
      }
    });
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
    final directory = await _temporaryDirectory();
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
      dutyCount: (tables['duty_entries'] as List?)?.length ?? 0,
      includesDuty: tables.containsKey('duty_entries'),
      scanPageCount: (tables['duty_scan_pages'] as List?)?.length ?? 0,
      includesScans: tables.containsKey('duty_scan_pages'),
    );
  }

  Future<BackupSummary> restoreBackup(List<int> bytes) async {
    final backup = _decodeAndValidate(bytes);
    final data = backup['data'] as Map<String, dynamic>;
    final preferencesData = backup['preferences'] as Map<String, dynamic>;
    final db = await _database();
    final preferences = await SharedPreferences.getInstance();

    await db.transaction((txn) async {
      // Older backups cannot contain scan bytes. Preserve their pages and
      // any parent letters absent from the old backup before replacing data.
      final preserveScans =
          !data.containsKey('duty_scan_pages') &&
          data.containsKey('duty_entries');
      final oldScans =
          preserveScans
              ? await DutyScanBlobs.allRows(txn)
              : <Map<String, Object?>>[];
      final oldParents =
          oldScans.isEmpty
              ? <Map<String, Object?>>[]
              : await txn.rawQuery(
                'SELECT * FROM duty_entries WHERE id IN (SELECT duty_id FROM duty_scan_pages)',
              );
      if (data.containsKey('duty_scan_pages')) {
        await txn.delete('duty_scan_pages');
      }
      for (final table in _tables) {
        // A pre-Dinas backup has no duty table: preserve destination letters.
        if (!data.containsKey(table)) continue;
        await txn.delete(table);
        final rows = data[table] as List;
        for (final value in rows) {
          await txn.insert(table, Map<String, Object?>.from(value as Map));
        }
      }
      if (preserveScans) {
        final importedIds =
            (data['duty_entries'] as List)
                .map((row) => (row as Map)['id'])
                .toSet();
        for (final parent in oldParents) {
          if (!importedIds.contains(parent['id'])) {
            await txn.insert('duty_entries', parent);
          }
        }
        for (final page in oldScans) {
          await txn.insert('duty_scan_pages', page);
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
      dutyCount: (data['duty_entries'] as List?)?.length ?? 0,
      includesDuty: data.containsKey('duty_entries'),
      scanPageCount: (data['duty_scan_pages'] as List?)?.length ?? 0,
      includesScans: data.containsKey('duty_scan_pages'),
    );
  }

  Map<String, dynamic> _decodeAndValidate(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != _format ||
        ![1, 2, _backupVersion].contains(decoded['backupVersion'])) {
      throw const FormatException(
        'Berkas ini bukan cadangan KerjaKu PTC yang didukung.',
      );
    }
    final databaseVersion = decoded['databaseVersion'];
    if (databaseVersion is! int || databaseVersion < 1 || databaseVersion > 5) {
      throw const FormatException('Versi data cadangan tidak didukung.');
    }
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Bagian data pada cadangan tidak valid.');
    }
    for (final table in _tables) {
      if (table == 'duty_scan_pages' &&
          (decoded['backupVersion'] as int) < 3 &&
          databaseVersion < 5 &&
          !data.containsKey(table)) {
        continue;
      }
      if (table == 'duty_entries' &&
          decoded['backupVersion'] == 1 &&
          databaseVersion < 4 &&
          !data.containsKey(table)) {
        continue;
      }
      final rows = data[table];
      if (rows is! List || rows.any((row) => row is! Map)) {
        throw FormatException('Data $table pada cadangan tidak valid.');
      }
    }
    final scanRows = data['duty_scan_pages'];
    if (scanRows is List) {
      final parentIds =
          (data['duty_entries'] as List).map((r) => (r as Map)['id']).toSet();
      final ids = <String>{};
      final positions = <String>{};
      for (final row in scanRows) {
        try {
          final map = row as Map<String, dynamic>;
          final page = DutyScanPage.fromMap(map);
          if (page.id.isEmpty ||
              page.position < 0 ||
              !parentIds.contains(page.dutyId) ||
              !ids.add(page.id) ||
              !positions.add(
                '${page.dutyId}/${page.type.name}/${page.position}',
              )) {
            throw const FormatException('Identitas halaman tidak valid.');
          }
          for (final key in ['image', 'original_image']) {
            if (key == 'original_image' && map[key] == null) continue;
            final value = map[key];
            if (value is! String ||
                value.length > ScanImageData.maxBytes * 1.4) {
              throw const FormatException('Gambar tidak valid.');
            }
            final Uint8List bytes = base64Decode(value);
            ScanImageData.validate(bytes);
            map[key] = bytes;
          }
        } catch (_) {
          throw const FormatException(
            'Data scan berkas dinas pada cadangan tidak valid.',
          );
        }
      }
    }
    final dutyRows = data['duty_entries'];
    if (dutyRows is List) {
      final ids = <String>{};
      for (final row in dutyRows) {
        try {
          final map = Map<String, Object?>.from(row as Map);
          if (map['is_draft'] != 0 && map['is_draft'] != 1) {
            throw const FormatException('Status surat tidak valid.');
          }
          final entry = DutyEntry.fromMap(map);
          if (entry.validate(requireComplete: !entry.isDraft) != null ||
              !ids.add(entry.id)) {
            throw const FormatException('Isi surat tidak valid.');
          }
        } catch (_) {
          throw const FormatException(
            'Data surat dinas pada cadangan tidak valid.',
          );
        }
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
