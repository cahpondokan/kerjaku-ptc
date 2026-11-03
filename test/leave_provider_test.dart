import 'package:flutter_test/flutter_test.dart';
import 'package:lembur/features/leave/presentation/leave_provider.dart';
import 'leave_test_helpers.dart';

void main() {
  late MemoryLeaveRepository repository;
  late LeaveProvider leave;
  setUp(() async {
    repository = MemoryLeaveRepository();
    leave = LeaveProvider(repository);
    await leave.load();
  });
  test(
    'Initial used days and saved letters survive reloading without double deduction',
    () async {
      await leave.setInitialUsed(2026, 4);
      await leave.save(sampleLeave());
      expect(leave.remaining(2026), 6);
      expect(leave.usedBefore(leave.entries.single), 4);
      final reopened = LeaveProvider(repository);
      await reopened.load();
      expect(reopened.remaining(2026), 6);
      expect(reopened.defaults.reason, 'Acara keluarga');
      expect(reopened.defaults.address, 'Semarang');
      expect(reopened.defaults.aftName, 'Joni Herawan');
      expect(reopened.entries.single.returnDate, DateTime(2026, 10, 27));
      expect(reopened.remaining(2027), 12);
    },
  );
  test(
    'Quota allows exactly 12, blocks excess and invalid initial usage',
    () async {
      await leave.setInitialUsed(2026, 10);
      await leave.save(sampleLeave());
      expect(leave.remaining(2026), 0);
      await expectLater(
        leave.save(
          sampleLeave(
            id: 'excess',
            start: DateTime(2026, 10, 27),
            end: DateTime(2026, 10, 27),
          ),
        ),
        throwsStateError,
      );
      await expectLater(leave.setInitialUsed(2026, 11), throwsStateError);
      await expectLater(leave.setInitialUsed(2026, -1), throwsStateError);
      expect(leave.remaining(2026), 0);
    },
  );
  test(
    'Initial usage including zero persists only for its calendar year',
    () async {
      expect(leave.hasInitialUsed(2026), isFalse);
      await leave.setInitialUsed(2026, 4);
      await leave.setInitialUsed(2025, 0);
      final reopened = LeaveProvider(repository);
      await reopened.load();
      expect(reopened.hasInitialUsed(2025), isTrue);
      expect(reopened.initialUsed(2025), 0);
      expect(reopened.hasInitialUsed(2026), isTrue);
      expect(reopened.initialUsed(2026), 4);
      expect(reopened.remaining(2027), 12);
      expect(reopened.hasInitialUsed(2027), isFalse);
      await reopened.setInitialUsed(2027, 2);
      expect(reopened.remaining(2027), 10);
      expect(reopened.remaining(2026), 8);
    },
  );
  test('Saved and reloaded holiday requests debit only workdays', () async {
    await leave.setInitialUsed(2026, 10);
    final entry = sampleLeave(
      start: DateTime(2026, 12, 23),
      end: DateTime(2026, 12, 28),
    );
    await leave.save(entry);
    expect(leave.remaining(2026), 0);
    expect(leave.usedBefore(entry), 10);
    final reopened = LeaveProvider(repository);
    await reopened.load();
    expect(reopened.entries.single.days, 2);
    expect(reopened.entries.single.returnDate, DateTime(2026, 12, 29));
    expect(reopened.remaining(2026), 0);
    expect(reopened.remaining(2027), 12);
    await expectLater(
      reopened.save(
        sampleLeave(
          id: 'holiday',
          start: DateTime(2027, 1, 5),
          end: DateTime(2027, 1, 5),
        ),
      ),
      throwsStateError,
    );
  });
  test(
    'Edit excludes itself from overlap and quota; delete restores days',
    () async {
      await leave.setInitialUsed(2026, 10);
      await leave.save(sampleLeave());
      await leave.save(sampleLeave(end: DateTime(2026, 10, 23)));
      expect(leave.entries, hasLength(1));
      expect(leave.remaining(2026), 1);
      await leave.save(sampleLeave());
      expect(leave.remaining(2026), 0);
      await leave.delete('leave-1');
      expect(leave.remaining(2026), 2);
    },
  );
  test(
    'Overlapping letters rejected; new calendar year has its own 12 days',
    () async {
      await leave.save(sampleLeave());
      await expectLater(
        leave.save(sampleLeave(id: 'overlap')),
        throwsStateError,
      );
      await leave.save(
        sampleLeave(
          id: '2027',
          start: DateTime(2027, 1, 4),
          end: DateTime(2027, 1, 4),
        ),
      );
      expect(leave.remaining(2026), 10);
      expect(leave.remaining(2027), 11);
    },
  );
  test(
    'PDF prior usage excludes current and later requests regardless of save order',
    () async {
      await leave.setInitialUsed(2026, 4);
      final later = sampleLeave(
        id: 'later',
        start: DateTime(2026, 11, 2),
        end: DateTime(2026, 11, 3),
      );
      await leave.save(later);
      await leave.save(sampleLeave());
      expect(leave.remaining(2026), 4);
      expect(leave.usedBefore(sampleLeave()), 4);
      expect(leave.usedBefore(later), 6);
    },
  );
  test(
    'Three days before a three-day request leaves six; next request uses updated history',
    () async {
      await leave.setInitialUsed(2026, 3);
      final entry = sampleLeave(
        start: DateTime(2026, 10, 26),
        end: DateTime(2026, 10, 28),
      );
      expect(leave.usedBefore(entry), 3);
      await leave.save(entry);
      expect(entry.days, 3);
      expect(leave.usedBefore(entry), 3);
      expect(leave.remaining(2026), 6);
      final later = sampleLeave(
        id: 'next',
        start: DateTime(2026, 11, 2),
        end: DateTime(2026, 11, 4),
      );
      await leave.save(later);
      expect(leave.usedBefore(later), 6);
      expect(leave.usedBefore(entry), 3);
      expect(leave.remaining(2026), 3);
      final reopened = LeaveProvider(repository);
      await reopened.load();
      expect(reopened.usedBefore(entry), 3);
      expect(reopened.usedBefore(later), 6);
      expect(
        reopened.usedBefore(
          sampleLeave(start: DateTime(2027, 1, 4), end: DateTime(2027, 1, 4)),
        ),
        0,
      );
    },
  );
  test(
    'Prior usage handles shared weekends and holidays without counting this request twice',
    () async {
      final earlier = sampleLeave(
        id: 'earlier',
        start: DateTime(2026, 12, 23),
        end: DateTime(2026, 12, 27),
      );
      final current = sampleLeave(
        start: DateTime(2026, 12, 24),
        end: DateTime(2026, 12, 28),
      );
      await leave.save(current);
      await leave.save(earlier);
      expect(leave.usedBefore(earlier), 0);
      expect(leave.usedBefore(current), 1);
      expect(leave.remaining(2026), 10);
      final edited = sampleLeave(
        start: DateTime(2026, 12, 24),
        end: DateTime(2026, 12, 29),
      );
      expect(leave.usedBefore(edited), 1);
      await leave.save(edited);
      expect(leave.usedBefore(edited), 1);
      expect(leave.remaining(2026), 9);
      await leave.delete(earlier.id);
      expect(leave.usedBefore(edited), 0);
      expect(leave.remaining(2026), 10);
    },
  );
  test(
    'Failed storage writes cannot change in-memory balance, history or defaults',
    () async {
      repository.failWrites = true;
      await expectLater(leave.save(sampleLeave()), throwsStateError);
      await expectLater(leave.setInitialUsed(2026, 3), throwsStateError);
      expect(leave.entries, isEmpty);
      expect(leave.remaining(2026), 12);
      expect(leave.defaults.reason, isEmpty);
      expect(leave.saving, isFalse);
    },
  );
  test(
    'Load failure cannot enable new letters against a false empty balance',
    () async {
      repository.failReads = true;
      await leave.load();
      expect(leave.loaded, isFalse);
      expect(leave.error, isNotNull);
      await expectLater(leave.save(sampleLeave()), throwsStateError);
      await expectLater(leave.setInitialUsed(2026, 0), throwsStateError);
      expect(repository.writes, 0);
    },
  );
}
