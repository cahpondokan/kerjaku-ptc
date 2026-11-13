import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lembur/app/theme/app_theme.dart';
import 'package:lembur/features/duty/data/duty_scan_repository.dart';
import 'package:lembur/features/duty/data/duty_packet_pdf.dart';
import 'package:lembur/features/duty/domain/duty_entry.dart';
import 'package:lembur/features/duty/data/duty_scanner.dart';
import 'package:lembur/features/duty/domain/duty_scan_page.dart';
import 'package:lembur/features/duty/presentation/duty_crop_page.dart';
import 'package:lembur/features/duty/presentation/duty_document_page.dart';
import 'package:lembur/features/duty/presentation/duty_packet_controller.dart';
import 'package:lembur/features/duty/presentation/duty_packet_page.dart';
import 'package:lembur/features/duty/presentation/duty_provider.dart';
import 'package:lembur/features/duty/presentation/duty_scan_review_page.dart';
import 'package:provider/provider.dart';
import 'duty_test_helpers.dart';
import 'duty_scan_test.dart' show scanFixture;

class MemoryScans extends DutyScanRepository {
  MemoryScans(this.bytes);
  final Uint8List bytes;
  final rows = <DutyScanPage>[];
  bool failReads = false, failRefreshAfterWrite = false;
  int writes = 0;
  @override
  Future<List<DutyScanPage>> list(String dutyId) async {
    if (failReads) throw StateError('Daftar belum tersedia');
    return List.of(rows);
  }

  @override
  Future<Uint8List> image(String id, {bool original = false}) async => bytes;
  @override
  Future<void> add(
    String dutyId,
    DutyDocumentType type,
    List<Uint8List> images,
  ) async {
    writes++;
    for (final _ in images) {
      rows.add(
        DutyScanPage(
          id: 'page-${rows.length}',
          dutyId: dutyId,
          type: type,
          position: rows.length,
          createdAt: DateTime(2026, 11, 11),
          updatedAt: DateTime(2026, 11, 11),
        ),
      );
    }
    if (failRefreshAfterWrite) failReads = true;
  }
}

class TestPacketPdf extends DutyPacketPdf {
  Uint8List? exported;
  @override
  Future<File> saveTemporary(DutyEntry duty, Uint8List bytes) async {
    exported = bytes;
    return File('packet-test.pdf');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List bytes;
  late MemoryScans scans;
  late DutyProvider duty;
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    bytes = await scanFixture(0xffffffff);
  });
  setUp(() async {
    scans = MemoryScans(bytes);
    final repository = MemoryDutyRepository();
    await repository.save(sampleDuty());
    duty = DutyProvider(repository);
    await duty.load();
  });
  tearDown(() => duty.dispose());
  Widget app(Widget child, {double scale = 1}) => ChangeNotifierProvider.value(
    value: duty,
    child: MaterialApp(
      theme: AppTheme.light,
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
      home: child,
    ),
  );
  void narrow(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'Empty packet blocks sharing; a partial packet enables sharing on narrow screen',
    (tester) async {
      narrow(tester);
      await tester.pumpWidget(
        app(DutyPacketPage(id: 'duty-1', repository: scans), scale: 1.4),
      );
      await tester.pumpAndSettle();
      final share = find.byKey(const ValueKey('share-duty-packet'));
      expect(tester.widget<FilledButton>(share).onPressed, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await scans.add('duty-1', DutyDocumentType.spd, [bytes]);
      await tester.pumpWidget(
        app(DutyPacketPage(id: 'duty-1', repository: scans), scale: 1.4),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(share).onPressed, isNotNull);
      expect(find.text('1 dari 4 dokumen tersedia'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Each stored document page offers its own crop, replace and delete actions',
    (tester) async {
      narrow(tester);
      await scans.add('duty-1', DutyDocumentType.invoice, [bytes]);
      final controller = DutyPacketController('duty-1', scans);
      await controller.load();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          DutyDocumentPage(
            controller: controller,
            type: DutyDocumentType.invoice,
            trip: 'Semarang → Solo',
          ),
          scale: 1.4,
        ),
      );
      await tester.pumpAndSettle();
      for (final label in ['Potong', 'Ganti', 'Hapus']) {
        await tester.scrollUntilVisible(find.text(label), 150);
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  Future<void> openReview(
    WidgetTester tester,
    Future<void> Function(List<Uint8List>) save, {
    int? replacing,
  }) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed:
                      () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => DutyScanReviewPage(
                                images: [bytes],
                                label: 'Deklarasi',
                                replacingPage: replacing,
                                save: save,
                              ),
                        ),
                      ),
                  child: const Text('Buka scan'),
                ),
              ),
        ),
        scale: 1.4,
      ),
    );
    await tester.tap(find.text('Buka scan'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Saving replacement once closes review and returns to stored document',
    (tester) async {
      narrow(tester);
      var writes = 0;
      await openReview(tester, (_) async {
        writes++;
      }, replacing: 2);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Simpan pengganti halaman 2'));
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(find.text('Buka scan'), findsOneWidget);
      expect(find.byType(DutyScanReviewPage), findsNothing);
    },
  );

  testWidgets(
    'Failed replacement stays reviewable; cancelling leaves stored page untouched',
    (tester) async {
      narrow(tester);
      await openReview(tester, (_) async {
        throw StateError('Penyimpanan gagal');
      }, replacing: 1);
      await tester.tap(find.text('Simpan pengganti halaman 1'));
      await tester.pumpAndSettle();
      expect(find.text('Penyimpanan gagal'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batalkan scan'));
      await tester.pumpAndSettle();
      expect(find.byType(DutyScanReviewPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Committed save survives refresh failure without allowing duplicate retry',
    () async {
      final controller = DutyPacketController('duty-1', scans);
      await controller.load();
      scans.failRefreshAfterWrite = true;
      await controller.add(DutyDocumentType.sppd, [bytes]);
      expect(scans.writes, 1);
      expect(controller.loaded, isFalse);
      expect(controller.canShare, isFalse);
      await expectLater(
        controller.add(DutyDocumentType.sppd, [bytes]),
        throwsStateError,
      );
      expect(scans.writes, 1);
      scans.failReads = false;
      await controller.load();
      expect(controller.pages, hasLength(1));
      expect(controller.canShare, isTrue);
      controller.dispose();
    },
  );

  testWidgets(
    'Share builds a partial PDF, opens recipient selection with path only, and preserves scans',
    (tester) async {
      await scans.add('duty-1', DutyDocumentType.spd, [bytes]);
      final pdf = TestPacketPdf();
      MethodCall? share;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DutyScanner.channel, (call) async {
            share = call;
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(DutyScanner.channel, null),
      );
      await tester.pumpWidget(
        app(DutyPacketPage(id: 'duty-1', repository: scans, pdf: pdf)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('share-duty-packet')));
      await tester.pumpAndSettle();
      expect(share?.method, 'sharePacket');
      expect(share?.arguments, {'path': 'packet-test.pdf'});
      expect(pdf.exported, isNotNull);
      expect(
        RegExp(
          r'/Type\s*/Page\b',
        ).allMatches(String.fromCharCodes(pdf.exported!)),
        hasLength(1),
      );
      expect(find.text('Menyiapkan berkas'), findsNothing);
      expect(scans.rows, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Crop applies normalized corners and rotation, then closes with result',
    (tester) async {
      narrow(tester);
      MethodCall? crop;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DutyScanner.channel, (call) async {
            crop = call;
            return bytes;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(DutyScanner.channel, null),
      );
      Uint8List? result;
      await tester.pumpWidget(
        app(
          Builder(
            builder:
                (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      result = await Navigator.push<Uint8List>(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => DutyCropPage(
                                bytes: bytes,
                                label: 'SPD • Halaman 1',
                              ),
                        ),
                      );
                    },
                    child: const Text('Potong'),
                  ),
                ),
          ),
          scale: 1.4,
        ),
      );
      await tester.tap(find.text('Potong'));
      await tester.runAsync(() async {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('Putar kanan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terapkan potongan'));
      await tester.pumpAndSettle();
      expect(crop?.method, 'crop');
      expect(crop?.arguments['rotation'], 1);
      expect(crop?.arguments['corners'], [
        0.0,
        0.0,
        1.0,
        0.0,
        1.0,
        1.0,
        0.0,
        1.0,
      ]);
      expect(result, bytes);
      expect(find.byType(DutyCropPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
