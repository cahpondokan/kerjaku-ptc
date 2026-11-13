import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:lembur/core/database/app_database.dart';
import 'package:lembur/features/duty/data/duty_packet_pdf.dart';
import 'package:lembur/features/duty/data/duty_repository.dart';
import 'package:lembur/features/duty/data/duty_scan_repository.dart';
import 'package:lembur/features/duty/domain/duty_scan_page.dart';
import 'package:lembur/features/duty/presentation/duty_packet_controller.dart';
import 'package:lembur/features/settings/data/backup_restore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'duty_test_helpers.dart';

Future<Uint8List> scanFixture(
  int color, {
  int width = 180,
  int height = 250,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = ui.Color(color),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(15, 20, 150, 7),
    ui.Paint()..color = const ui.Color(0xff111111),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

Future<Database> scanTestDatabase() async {
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await db.execute('PRAGMA foreign_keys = ON');
  await AppDatabase.createDutyTable(db);
  await AppDatabase.createLeaveTables(db);
  // Unchanged legacy table contains a sentinel salary basis for restore tests.
  await db.execute(
    'CREATE TABLE overtime_entries(id TEXT PRIMARY KEY, monthly_wage_basis_cents INTEGER)',
  );
  await db.insert('overtime_entries', {
    'id': 'legacy',
    'monthly_wage_basis_cents': 437300000,
  });
  await db.insert('leave_year_balances', {'year': 2026, 'initial_used': 4});
  await db.setVersion(4);
  await AppDatabase.createDutyScanTable(db);
  await db.setVersion(5);
  return db;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late DutyScanRepository scans;
  late DutyRepository duties;
  late Directory temporary;
  late Uint8List red, green, blue;
  setUpAll(() async {
    sqfliteFfiInit();
    red = await scanFixture(0xffffcccc);
    green = await scanFixture(0xffccffcc);
    blue = await scanFixture(0xffccccff);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'overtime_salary_v1': 'preserve salary',
    });
    db = await scanTestDatabase();
    temporary = await Directory.systemTemp.createTemp('kerjaku_scan_test_');
    duties = DutyRepository(database: () => Future.value(db));
    scans = DutyScanRepository(database: () => Future.value(db));
    await duties.save(sampleDuty());
  });
  tearDown(() async {
    await db.close();
    await temporary.delete(recursive: true);
  });
  BackupRestoreService backup() => BackupRestoreService(
    database: () => Future.value(db),
    temporaryDirectory: () => Future.value(temporary),
  );

  test(
    'Partial packets share SPPD and SPD in fixed order; empty packets are blocked',
    () async {
      await scans.add('duty-1', DutyDocumentType.spd, [green]);
      await scans.add('duty-1', DutyDocumentType.sppd, [red]);
      final controller = DutyPacketController('duty-1', scans);
      await controller.load();
      expect(controller.canShare, isTrue);
      expect(controller.availableTypes, 2);
      final readTypes = <DutyDocumentType>[];
      final bytes = await DutyPacketPdf().build(
        controller.pages.reversed.toList(),
        (id) async {
          readTypes.add(controller.pages.singleWhere((p) => p.id == id).type);
          return scans.image(id);
        },
      );
      expect(readTypes, [DutyDocumentType.sppd, DutyDocumentType.spd]);
      expect(
        RegExp(r'/Type\s*/Page\b').allMatches(String.fromCharCodes(bytes)),
        hasLength(2),
      );
      await expectLater(
        DutyPacketPdf().build([], scans.image),
        throwsStateError,
      );
      if (const bool.fromEnvironment('GENERATE_SCAN_SAMPLE')) {
        final file = File('output/pdf/contoh-paket-dinas-bertahap.pdf');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
      }
      controller.dispose();
    },
  );

  test(
    'A single available category can be shared and missing kinds add no blank pages',
    () async {
      await scans.add('duty-1', DutyDocumentType.invoice, [blue]);
      final pages = await scans.list('duty-1');
      final bytes = await DutyPacketPdf().build(pages, scans.image);
      expect(
        RegExp(r'/Type\s*/Page\b').allMatches(String.fromCharCodes(bytes)),
        hasLength(1),
      );
      expect(pages.single.type, DutyDocumentType.invoice);
    },
  );

  test(
    'Replace just one page atomically, preserve page ID, other documents and original crop',
    () async {
      await scans.add('duty-1', DutyDocumentType.sppd, [red]);
      await scans.add('duty-1', DutyDocumentType.invoice, [red, green, blue]);
      final before = await scans.list('duty-1');
      final second =
          before.where((p) => p.type == DutyDocumentType.invoice).toList()[1];
      await scans.replace(second, red);
      final after = await scans.list('duty-1');
      expect(after.map((p) => p.id), before.map((p) => p.id));
      expect(await scans.image(second.id), red);
      expect(await scans.image(after.last.id), blue);
      expect(await scans.image(after.first.id), red);
      await scans.replace(
        after.singleWhere((p) => p.id == second.id),
        green,
        crop: true,
      );
      expect(await scans.image(second.id), green);
      expect(await scans.image(second.id, original: true), red);
      await expectLater(scans.replace(second, blue), throwsStateError);
      expect(await scans.image(second.id), green);
    },
  );

  test(
    'Failed add/replace preserves all rows; editing SPPD does not cascade scans',
    () async {
      await scans.add('duty-1', DutyDocumentType.spd, [red]);
      final page = (await scans.list('duty-1')).single;
      await expectLater(
        scans.add('duty-1', DutyDocumentType.invoice, [green, Uint8List(1)]),
        throwsFormatException,
      );
      await expectLater(
        scans.replace(page, Uint8List(1)),
        throwsFormatException,
      );
      await duties.save(sampleDuty(changes: {'purpose': 'Changed purpose'}));
      expect(await scans.list('duty-1'), hasLength(1));
      expect(await scans.image(page.id), red);
      expect((await duties.getAll()).single.purpose, 'Changed purpose');
    },
  );

  test(
    'Reorder and deletion only affect selected category and survive repository reload',
    () async {
      await scans.add('duty-1', DutyDocumentType.spd, [green]);
      await scans.add('duty-1', DutyDocumentType.invoice, [red, blue]);
      final pages = await scans.list('duty-1');
      final invoices =
          pages.where((p) => p.type == DutyDocumentType.invoice).toList();
      await scans.reorder(
        'duty-1',
        DutyDocumentType.invoice,
        invoices.reversed.map((p) => p.id).toList(),
      );
      final reopened = DutyScanRepository(database: () => Future.value(db));
      expect((await reopened.list('duty-1')).map((p) => p.id), [
        pages.first.id,
        invoices.last.id,
        invoices.first.id,
      ]);
      await scans.delete(invoices.first.id);
      expect(await reopened.list('duty-1'), hasLength(2));
      await expectLater(
        scans.reorder('duty-1', DutyDocumentType.invoice, [pages.first.id]),
        throwsStateError,
      );
    },
  );

  test(
    'Backup restores every image and original crop with salary and leave data intact',
    () async {
      await scans.add('duty-1', DutyDocumentType.sppd, [red]);
      final page = (await scans.list('duty-1')).single;
      await scans.replace(page, green, crop: true);
      final file = await backup().createBackup();
      final bytes = await file.readAsBytes();
      final summary = await backup().inspectBackup(bytes);
      expect(summary.includesScans, isTrue);
      expect(summary.scanPageCount, 1);
      await duties.delete('duty-1');
      expect(await scans.list('duty-1'), isEmpty);
      await backup().restoreBackup(bytes);
      expect(await scans.image(page.id), green);
      expect(await scans.image(page.id, original: true), red);
      expect(
        (await db.query('overtime_entries')).single['monthly_wage_basis_cents'],
        437300000,
      );
      expect((await db.query('leave_year_balances')).single['initial_used'], 4);
      expect(
        (await SharedPreferences.getInstance()).getString('overtime_salary_v1'),
        'preserve salary',
      );
    },
  );

  test(
    'Older backup preserves existing scans and their parent letters even if absent from backup',
    () async {
      final file = await backup().createBackup();
      final legacy =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      legacy['backupVersion'] = 2;
      legacy['databaseVersion'] = 4;
      (legacy['data'] as Map).remove('duty_scan_pages');
      (legacy['data'] as Map)['duty_entries'] = [];
      await scans.add('duty-1', DutyDocumentType.invoice, [blue]);
      final page = (await scans.list('duty-1')).single;
      await backup().restoreBackup(utf8.encode(jsonEncode(legacy)));
      expect((await duties.getAll()).single.id, 'duty-1');
      expect(await scans.image(page.id), blue);
    },
  );

  test(
    'Corrupt scan backup and foreign parent are rejected before deleting destination data',
    () async {
      await scans.add('duty-1', DutyDocumentType.spd, [green]);
      final page = (await scans.list('duty-1')).single;
      final file = await backup().createBackup();
      for (final change in [
        {'image': 'invalid'},
        {'duty_id': 'missing-parent'},
        {'position': -1},
      ]) {
        final data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        ((data['data']['duty_scan_pages'] as List).single as Map).addAll(
          change,
        );
        await expectLater(
          backup().restoreBackup(utf8.encode(jsonEncode(data))),
          throwsFormatException,
        );
        expect(await scans.image(page.id), green);
      }
    },
  );

  test(
    'Cancellation does not modify source pages or export an empty PDF',
    () async {
      await scans.add('duty-1', DutyDocumentType.invoice, [blue, green]);
      final before = await scans.list('duty-1');
      var cancelled = false;
      await expectLater(
        DutyPacketPdf().build(
          before,
          scans.image,
          progress: (_, _) => cancelled = true,
          cancelled: () => cancelled,
        ),
        throwsStateError,
      );
      expect(
        (await scans.list('duty-1')).map((p) => p.id),
        before.map((p) => p.id),
      );
    },
  );

  test(
    'Large scan and original survive chunked reads, replacement, and backup restore',
    () async {
      // Storage fixture exceeding typical Android CursorWindow capacity.
      final large = Uint8List(3 * 1024 * 1024 + 17)
        ..setRange(0, red.length, red);
      large[large.length - 1] = 123;
      await scans.add('duty-1', DutyDocumentType.invoice, [large]);
      final page = (await scans.list('duty-1')).single;
      expect(await scans.image(page.id), large);
      await scans.replace(page, blue, crop: true);
      expect(await scans.image(page.id, original: true), large);
      final exported = await (await backup().createBackup()).readAsBytes();
      await duties.delete('duty-1');
      await backup().restoreBackup(exported);
      expect(await scans.image(page.id), blue);
      expect(await scans.image(page.id, original: true), large);
    },
  );

  test(
    'Long invoice keeps full paper width and includes its bottom edge',
    () async {
      final receipt = await scanFixture(0xffccccff, height: 720);
      await scans.add('duty-1', DutyDocumentType.invoice, [receipt]);
      final bytes = await DutyPacketPdf().build(
        await scans.list('duty-1'),
        scans.image,
      );
      final mediaBox = RegExp(
        r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)',
      ).firstMatch(String.fromCharCodes(bytes));
      expect(mediaBox, isNotNull);
      expect(double.parse(mediaBox!.group(1)!), closeTo(595.28, 0.1));
      expect(double.parse(mediaBox.group(2)!), greaterThan(2200));
      if (const bool.fromEnvironment('GENERATE_SCAN_SAMPLE')) {
        await File('output/pdf/contoh-invoice-panjang.pdf').writeAsBytes(bytes);
      }
    },
  );
}
