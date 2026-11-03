import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lembur/features/leave/data/leave_pdf_service.dart';
import 'package:lembur/features/leave/presentation/leave_provider.dart';
import 'leave_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Production PDF renders repeatedly without writing or deducting more leave',
    () async {
      final repository = MemoryLeaveRepository();
      final leave = LeaveProvider(repository);
      await leave.load();
      await leave.setInitialUsed(2026, 4);
      await leave.save(sampleLeave());
      final service = LeavePdfService();
      for (var i = 0; i < 2; i++) {
        final bytes = await service.build(
          entry: leave.entries.single,
          usedBeforeCurrent: leave.usedBefore(leave.entries.single),
        );
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(4000));
        expect(leave.remaining(2026), 6);
        expect(repository.writes, 1);
        if (i == 0 && const bool.fromEnvironment('GENERATE_LEAVE_SAMPLE')) {
          final output = File('output/pdf/contoh-surat-cuti.pdf');
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes);
        }
      }
    },
  );
  test(
    'PDF refuses missing required data or an impossible annual balance',
    () async {
      final service = LeavePdfService();
      await expectLater(
        service.build(entry: sampleLeave(reason: ''), usedBeforeCurrent: 2),
        throwsStateError,
      );
      await expectLater(
        service.build(entry: sampleLeave(), usedBeforeCurrent: 11),
        throwsStateError,
      );
      await expectLater(
        service.build(entry: sampleLeave(), usedBeforeCurrent: -1),
        throwsStateError,
      );
    },
  );
  test(
    'PDF uses holiday-aware duration, return date and saved initial usage',
    () async {
      final repository = MemoryLeaveRepository();
      final leave = LeaveProvider(repository);
      await leave.load();
      await leave.setInitialUsed(2026, 4);
      final entry = sampleLeave(
        start: DateTime(2026, 12, 23),
        end: DateTime(2026, 12, 28),
      );
      await leave.save(entry);
      expect(entry.days, 2);
      expect(entry.returnDate, DateTime(2026, 12, 29));
      expect(leave.usedBefore(entry), 4);
      final bytes = await LeavePdfService().build(
        entry: entry,
        usedBeforeCurrent: leave.usedBefore(entry),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(repository.writes, 1);
      if (const bool.fromEnvironment('GENERATE_LEAVE_SAMPLE')) {
        final output = File('output/pdf/contoh-surat-cuti-libur.pdf');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(bytes);
      }
      await expectLater(
        LeavePdfService().build(
          entry: sampleLeave(
            start: DateTime(2026, 12, 24),
            end: DateTime(2026, 12, 27),
          ),
          usedBeforeCurrent: 4,
        ),
        throwsStateError,
      );
      await expectLater(
        LeavePdfService().build(
          entry: sampleLeave(
            start: DateTime(2028, 1, 3),
            end: DateTime(2028, 1, 3),
          ),
          usedBeforeCurrent: 1,
        ),
        throwsStateError,
      );
    },
  );
  test(
    'PDF separates three prior days from three requested days and supports first leave',
    () async {
      final repository = MemoryLeaveRepository();
      final leave = LeaveProvider(repository);
      await leave.load();
      await leave.setInitialUsed(2026, 3);
      final entry = sampleLeave(
        start: DateTime(2026, 10, 26),
        end: DateTime(2026, 10, 28),
      );
      await leave.save(entry);
      expect(entry.days, 3);
      expect(leave.usedBefore(entry), 3);
      expect(leave.remaining(2026), 6);
      final service = LeavePdfService();
      for (var i = 0; i < 2; i++) {
        final bytes = await service.build(
          entry: entry,
          usedBeforeCurrent: leave.usedBefore(entry),
        );
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(leave.remaining(2026), 6);
        expect(repository.writes, 1);
        if (i == 0 && const bool.fromEnvironment('GENERATE_LEAVE_SAMPLE')) {
          final output = File('output/pdf/contoh-surat-cuti-saldo-benar.pdf');
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes);
        }
      }
      // Zero prior usage is valid, and exactly exhausting the entitlement is valid.
      for (final prior in [0, 9]) {
        final bytes = await service.build(
          entry: entry,
          usedBeforeCurrent: prior,
        );
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      }
      await expectLater(
        service.build(entry: entry, usedBeforeCurrent: 10),
        throwsStateError,
      );
    },
  );
}
