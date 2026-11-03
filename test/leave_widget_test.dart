import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lembur/app/theme/app_theme.dart';
import 'package:lembur/features/leave/presentation/leave_form_page.dart';
import 'package:lembur/features/leave/presentation/leave_initial_balance_card.dart';
import 'package:lembur/features/leave/presentation/leave_holiday_dialog.dart';
import 'package:lembur/features/leave/presentation/leave_page.dart';
import 'package:lembur/features/leave/presentation/leave_preview_page.dart';
import 'package:lembur/features/leave/presentation/leave_provider.dart';
import 'package:lembur/features/settings/domain/user_profile.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'leave_test_helpers.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  late SettingsProvider settings;
  late LeaveProvider leave;
  late MemoryLeaveRepository repository;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsProvider();
    await settings.load();
    repository = MemoryLeaveRepository();
    leave = LeaveProvider(repository);
    await leave.load();
  });
  Future<void> ready() async {
    await settings.saveProfile(
      const UserProfile(name: 'Budi Pratama', workerNumber: 'PTC-001'),
    );
    await settings.confirmSignatories();
  }

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: leave),
    ],
    child: child,
  );
  Widget page(Widget child, {double scale = 1}) => wrap(
    MaterialApp(
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

  testWidgets(
    'Leave form and PDF require complete profile and confirmed signatories',
    (tester) async {
      await leave.save(sampleLeave());
      await tester.pumpWidget(page(const LeaveFormPage()));
      await tester.pumpAndSettle();
      expect(find.text('Lengkapi data wajib'), findsOneWidget);
      expect(find.byKey(const ValueKey('save-leave')), findsNothing);
      await tester.pumpWidget(page(const LeavePreviewPage(id: 'leave-1')));
      await tester.pumpAndSettle();
      expect(find.byType(PdfPreview), findsNothing);
      expect(find.text('Lengkapi data wajib'), findsOneWidget);
      await ready();
      await settings.updateSignatory(0, 'Pejabat Baru');
      await tester.pumpAndSettle();
      expect(find.byType(PdfPreview), findsNothing);
    },
  );

  testWidgets(
    'Saved defaults fill the next letter and edit changes dates without double debit',
    (tester) async {
      await ready();
      await leave.setInitialUsed(2026, 4);
      await leave.save(sampleLeave());
      await tester.pumpWidget(page(const LeaveFormPage()));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Alasan cuti'),
            )
            .controller!
            .text,
        'Acara keluarga',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Alamat selama cuti'),
            )
            .controller!
            .text,
        'Semarang',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const LeaveFormPage(editId: 'leave-1'),
          ),
          GoRoute(
            path: '/leave/preview/:id',
            builder: (_, _) => const Scaffold(body: Text('PDF siap')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        wrap(MaterialApp.router(theme: AppTheme.light, routerConfig: router)),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 hari kerja'), findsOneWidget);
      expect(find.text('Masuk kembali: 27 Okt 2026'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('leave-dates')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(DateRangePickerDialog),
          matching: find.byIcon(Icons.edit_outlined),
        ),
      );
      await tester.pumpAndSettle();
      final dialog = find.byType(DateRangePickerDialog);
      final fields = find.descendant(
        of: dialog,
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), '12/23/2026');
      await tester.enterText(fields.at(1), '12/28/2026');
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Pilih')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Masuk kembali: 29 Des 2026'), findsOneWidget);
      expect(find.text('2 hari kerja'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('save-leave')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('save-leave')));
      await tester.pumpAndSettle();
      expect(find.text('PDF siap'), findsOneWidget);
      expect(leave.entries, hasLength(1));
      expect(leave.entries.single.startDate, DateTime(2026, 12, 23));
      expect(leave.remaining(2026), 6);
      expect(repository.writes, 2);
    },
  );

  testWidgets('Narrow leave pages fit with larger text and retain balances', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await ready();
    await leave.setInitialUsed(2026, 4);
    await leave.save(sampleLeave());
    for (final child in [
      const LeavePage(),
      const LeaveFormPage(editId: 'leave-1'),
    ]) {
      await tester.pumpWidget(page(child, scale: 1.5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -350));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
    expect(leave.remaining(2026), 6);
  });

  testWidgets('Initial usage entered once is restored on the next form', (
    tester,
  ) async {
    await ready();
    await leave.save(sampleLeave());
    await tester.pumpWidget(
      page(const Scaffold(body: LeaveInitialBalanceCard(year: 2026))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('initial-leave-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('initial-leave-days')),
      '4',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(leave.remaining(2026), 6);
    expect(find.textContaining('Tersimpan. Otomatis'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    leave = LeaveProvider(repository);
    await leave.load();
    await tester.pumpWidget(page(const LeaveFormPage(editId: 'leave-1')));
    await tester.pumpAndSettle();
    expect(find.text('Sisa setelah surat ini: 6 dari 12 hari'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('initial-leave-edit')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('4 hari sudah diambil sebelum memakai aplikasi.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('initial-leave-edit')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('initial-leave-days')),
          )
          .controller!
          .text,
      '4',
    );
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(leave.remaining(2026), 6);
  });

  testWidgets('Balance follows 1 January while the page stays open', (
    tester,
  ) async {
    await ready();
    await leave.setInitialUsed(2026, 4);
    await leave.save(sampleLeave());
    var now = DateTime(2026, 12, 31, 23, 59, 50);
    await tester.pumpWidget(page(LeavePage(now: () => now)));
    await tester.pumpAndSettle();
    expect(find.text('6 hari tersisa'), findsOneWidget);
    now = DateTime(2027, 1, 1);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('12 hari tersisa'), findsOneWidget);
    expect(
      tester
          .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
          .value,
      2027,
    );
    expect(leave.remaining(2026), 6);
    expect(leave.entries, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Resume in a new year keeps advance bookings and past balances', (
    tester,
  ) async {
    await ready();
    await leave.setInitialUsed(2026, 8);
    await leave.save(
      sampleLeave(
        id: 'future',
        start: DateTime(2027, 1, 4),
        end: DateTime(2027, 1, 4),
      ),
    );
    var now = DateTime(2026, 12, 31, 12);
    await tester.pumpWidget(page(LeavePage(now: () => now)));
    await tester.pumpAndSettle();
    expect(find.text('4 hari tersisa'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2027, 1, 1, 8);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('11 hari tersisa'), findsOneWidget);
    expect(leave.initialUsed(2027), 0);
    expect(leave.remaining(2026), 4);
    expect(leave.entries, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Holiday list is readable on a narrow screen with enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        page(
          Scaffold(
            body: Builder(
              builder:
                  (context) => TextButton(
                    onPressed: () => showLeaveHolidays(context, 2026),
                    child: const Text('Kalender'),
                  ),
            ),
          ),
          scale: 1.5,
        ),
      );
      await tester.tap(find.text('Kalender'));
      await tester.pumpAndSettle();
      expect(find.text('Hari libur 2026'), findsOneWidget);
      expect(find.text('Imlek • Cuti bersama'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Natal • Cuti bersama'), 300);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
    },
  );
}
