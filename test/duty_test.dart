import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lembur/features/duty/domain/duty_entry.dart';
import 'package:lembur/features/duty/presentation/duty_provider.dart';
import 'package:lembur/features/settings/data/backup_restore_service.dart';
import 'duty_test_helpers.dart';

void main() {
  test('All months, rollover, optional number and leading zeroes', () {
    const months = [
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
    for (var month = 1; month <= 12; month++) {
      expect(
        DutyEntry.numberFor(DateTime(2026, month, 2), ''),
        'No. ... /SPPD/ ${months[month - 1]} /2026-S8',
      );
    }
    expect(
      DutyEntry.numberFor(DateTime(2027, 1, 1), ' 0012 '),
      'No. 0012 /SPPD/ I /2027-S8',
    );
    expect(
      DutyEntry.numberFor(DateTime(2026, 11, 2), '  '),
      'No. ... /SPPD/ XI /2026-S8',
    );
  });

  test('Stored letter date controls number independently of trip dates', () {
    final entry = sampleDuty(
      changes: {
        'request_date': '2026-12-31T00:00:00.000',
        'start_date': '2027-01-02T00:00:00.000',
        'return_date': '2027-01-05T00:00:00.000',
      },
    );
    final restored = DutyEntry.fromMap(jsonDecode(jsonEncode(entry.toMap())));
    expect(restored.toMap(), entry.toMap());
    expect(restored.letterNumber, 'No. ... /SPPD/ XII /2026-S8');
    expect(restored.calendarDays, 4);
  });

  test(
    'Drafts allow incomplete fields; final letters and dates are validated',
    () {
      final draft = sampleDuty(
        changes: {'destination': '', 'start_date': null, 'is_draft': 1},
      );
      expect(draft.validate(), isNull);
      expect(draft.validate(requireComplete: true), isNotNull);
      expect(sampleDuty().validate(requireComplete: true), isNull);
      expect(sampleDuty(changes: {'serial': '12/A'}).validate(), isNotNull);
      expect(
        sampleDuty(changes: {'return_date': '2026-11-01'}).validate(),
        isNotNull,
      );
    },
  );

  test(
    'Draft survives reload; final save replaces draft without duplication',
    () async {
      final repository = MemoryDutyRepository();
      var provider = DutyProvider(repository);
      await provider.load();
      await provider.save(
        sampleDuty(changes: {'is_draft': 1, 'serial': '007'}),
      );
      provider.dispose();
      provider = DutyProvider(repository);
      await provider.load();
      expect(provider.entries.single.isDraft, isTrue);
      expect(provider.entries.single.serial, '007');
      await provider.save(sampleDuty(changes: {'serial': '007'}));
      expect(provider.entries, hasLength(1));
      expect(provider.entries.single.isDraft, isFalse);
      expect(
        provider.entries.single.letterNumber,
        'No. 007 /SPPD/ XI /2026-S8',
      );
      await provider.delete('duty-1');
      await provider.load();
      expect(provider.entries, isEmpty);
      provider.dispose();
    },
  );

  test(
    'Failed reads, writes and silent incomplete writes cannot report success',
    () async {
      final repository = MemoryDutyRepository()..failReads = true;
      final provider = DutyProvider(repository);
      await provider.load();
      expect(provider.loaded, isFalse);
      await expectLater(provider.save(sampleDuty()), throwsStateError);
      repository.failReads = false;
      await provider.load();
      repository.failWrites = true;
      await expectLater(provider.save(sampleDuty()), throwsStateError);
      expect(provider.saving, isFalse);
      repository.failWrites = false;
      repository.ignoreWrites = true;
      await expectLater(provider.save(sampleDuty()), throwsStateError);
      expect(provider.entries, isEmpty);
      expect(provider.saving, isFalse);
      provider.dispose();
    },
  );

  Map<String, Object?> backup({int version = 2}) => {
    'format': 'kerjaku_ptc_backup',
    'backupVersion': version,
    'databaseVersion': version == 1 ? 3 : 4,
    'data': <String, Object?>{
      'overtime_entries': <Object>[],
      'leave_entries': <Object>[],
      'leave_year_balances': <Object>[],
      'leave_defaults': <Object>[],
      if (version == 2) 'duty_entries': [sampleDuty().toMap()],
    },
    'preferences': {'overtime_salary_v1': '{"preserved":true}'},
  };

  test('Backup accepts old format and counts new duty records', () async {
    final service = BackupRestoreService();
    final old = await service.inspectBackup(
      utf8.encode(jsonEncode(backup(version: 1))),
    );
    expect(old.includesDuty, isFalse);
    final current = await service.inspectBackup(
      utf8.encode(jsonEncode(backup())),
    );
    expect(current.includesDuty, isTrue);
    expect(current.dutyCount, 1);
  });

  test('New backups reject absent, duplicate or malformed letters', () async {
    final service = BackupRestoreService();
    for (final records in [
      null,
      [sampleDuty().toMap(), sampleDuty().toMap()],
      [
        sampleDuty(changes: {'destination': ''}).toMap(),
      ],
      [
        {...sampleDuty().toMap(), 'request_date': 'not-a-date'},
      ],
    ]) {
      final data = backup();
      (data['data'] as Map)['duty_entries'] = records;
      await expectLater(
        service.inspectBackup(utf8.encode(jsonEncode(data))),
        throwsFormatException,
      );
    }
  });
}
