import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lembur/app/app.dart';
import 'package:lembur/app/router/app_router.dart';
import 'package:lembur/app/theme/app_theme.dart';
import 'package:lembur/features/dashboard/presentation/dashboard_page.dart';
import 'package:lembur/features/overtime/presentation/overtime_form_page.dart';
import 'package:lembur/features/overtime/presentation/overtime_provider.dart';
import 'package:lembur/features/report/presentation/documents_page.dart';
import 'package:lembur/features/report/presentation/report_page.dart';
import 'package:lembur/features/settings/domain/user_profile.dart';
import 'package:lembur/features/settings/presentation/settings_page.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:lembur/shared/widgets/profile_reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

Future<(SettingsProvider, OvertimeProvider)> prepare({
  bool ready = false,
  bool invalidEntry = false,
}) async {
  final settings = SettingsProvider();
  await settings.load();
  if (ready) {
    await settings.saveProfile(
      const UserProfile(name: 'Budi Pratama', workerNumber: 'PTC-001'),
    );
    await settings.confirmSignatories();
  }
  final overtime = OvertimeProvider(
    MemoryOvertimeRepository([
      sampleEntry(name: invalidEntry ? 'Nama Penandatangan 3' : 'Joni Herawan'),
    ]),
  );
  await overtime.load();
  return (settings, overtime);
}

Widget reminderApp(SettingsProvider settings, OvertimeProvider overtime) {
  final navigatorKey = GlobalKey<NavigatorState>();
  return testProviders(
    settings: settings,
    overtime: overtime,
    child: MaterialApp(
      navigatorKey: navigatorKey,
      theme: AppTheme.light,
      builder:
          (context, child) => ProfileReminder(
            navigatorKey: navigatorKey,
            onComplete: () {},
            child: child!,
          ),
      home: const Scaffold(body: Text('Beranda uji')),
    ),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Reminder waits for settings, dismisses for this session, and returns on resume or relaunch',
    (tester) async {
      final settings = SettingsProvider();
      final overtime = OvertimeProvider(MemoryOvertimeRepository());
      await tester.pumpWidget(reminderApp(settings, overtime));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileReminderDialog), findsNothing);
      await settings.load();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileReminderDialog), findsOneWidget);
      await tester.tap(find.text('Nanti'));
      await tester.pumpAndSettle();
      await settings.saveAdminWhatsApp('081234567890');
      await tester.pumpAndSettle();
      expect(find.byType(ProfileReminderDialog), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileReminderDialog), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileReminderDialog), findsOneWidget);
      await tester.tap(find.text('Nanti'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(reminderApp(settings, overtime));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileReminderDialog), findsOneWidget);
    },
  );

  testWidgets('Complete persisted setup does not show the reminder', (
    tester,
  ) async {
    final (_, overtime) = await prepare(ready: true);
    final reopened = SettingsProvider();
    await reopened.load();
    await tester.pumpWidget(reminderApp(reopened, overtime));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileReminderDialog), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileReminderDialog), findsNothing);
  });

  testWidgets(
    'Startup CTA in the real app opens profile and navigation does not repeat the reminder',
    (tester) async {
      final (settings, overtime) = await prepare();
      appRouter.go('/');
      await tester.pumpWidget(
        testProviders(
          settings: settings,
          overtime: overtime,
          child: const KerjaKuApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ProfileReminderDialog),
          matching: find.text('Lengkapi sekarang'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Profil & pengaturan'), findsOneWidget);
      appRouter.go('/documents');
      await tester.pumpAndSettle();
      expect(find.byType(ProfileReminderDialog), findsNothing);
      appRouter.go('/report');
      await tester.pumpAndSettle();
      expect(find.text('Pratinjau / Cetak PDF SPKL'), findsNothing);
    },
  );

  testWidgets(
    'Report page guards every export path until profile and signatories are ready',
    (tester) async {
      final (settings, overtime) = await prepare();
      await tester.pumpWidget(
        testPage(
          settings: settings,
          overtime: overtime,
          child: const ReportPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lengkapi data wajib'), findsOneWidget);
      expect(find.text('Buat Excel Rekap'), findsNothing);
      await settings.saveProfile(
        const UserProfile(name: 'Budi', workerNumber: '123'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pratinjau / Cetak PDF SPKL'), findsNothing);
      await settings.confirmSignatories();
      await tester.pumpAndSettle();
      expect(find.text('Pratinjau / Cetak PDF SPKL'), findsOneWidget);
      expect(find.text('Buat Excel Rekap'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Kirim ke WhatsApp Admin'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Kirim ke WhatsApp Admin'), findsOneWidget);
      await settings.updateSignatory(0, 'Pejabat Pengganti');
      await tester.pumpAndSettle();
      expect(find.text('Buat Excel Rekap'), findsNothing);
      expect(find.text('Bagikan PDF + Excel'), findsNothing);
    },
  );

  testWidgets(
    'Legacy overtime with placeholder signatories cannot be exported',
    (tester) async {
      final (settings, overtime) = await prepare(
        ready: true,
        invalidEntry: true,
      );
      await tester.pumpWidget(
        testPage(
          settings: settings,
          overtime: overtime,
          child: const ReportPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Periksa riwayat'), findsOneWidget);
      expect(find.text('Buat Excel Rekap'), findsNothing);
    },
  );

  testWidgets(
    'Profile form cannot save empty fields even when scrolled off screen',
    (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (settings, overtime) = await prepare();
      await tester.pumpWidget(
        testPage(
          settings: settings,
          overtime: overtime,
          child: const SettingsPage(),
        ),
      );
      await tester.tap(find.text('Isi profil pekerja'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Simpan Profil'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Simpan Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Profil & Data Tetap'), findsOneWidget);
      expect(settings.profile.isComplete, isFalse);
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Nama pekerja'),
        -300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama pekerja'),
        'Budi Pratama',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nomor pekerja'),
        '123',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.scrollUntilVisible(
        find.text('Simpan Profil'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Simpan Profil'));
      await tester.pumpAndSettle();
      expect(settings.profile.isComplete, isTrue);
      expect(settings.documentsReady, isFalse);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('confirm-signatories')).hitTestable(),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('confirm-signatories')));
      await tester.pumpAndSettle();
      expect(settings.documentsReady, isTrue);
    },
  );

  for (final config in [(320.0, 1.0), (390.0, 1.0), (320.0, 1.5)]) {
    testWidgets(
      'Home and documents fit width ${config.$1}, text scale ${config.$2}',
      (tester) async {
        tester.view.physicalSize = Size(config.$1, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final (settings, overtime) = await prepare();
        for (final page in [const DashboardPage(), const DocumentsPage()]) {
          await tester.pumpWidget(
            testPage(
              settings: settings,
              overtime: overtime,
              child: page,
              textScale: config.$2,
            ),
          );
          await tester.pumpAndSettle();
          for (var i = 0; i < 4; i++) {
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -350),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        }
        await settings.saveProfile(
          const UserProfile(name: 'Budi', workerNumber: '123'),
        );
        await settings.confirmSignatories();
        await tester.pumpWidget(
          testPage(
            settings: settings,
            overtime: overtime,
            child: const DashboardPage(),
            textScale: config.$2,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Overtime can still be saved with configured signatories and calculated hours',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (settings, _) = await prepare();
      await settings.updateApproverPosition(0, 'Manager Pengganti');
      final repo = MemoryOvertimeRepository();
      final overtime = OvertimeProvider(repo);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: OvertimeFormPage()),
          ),
          GoRoute(
            path: '/history',
            builder: (_, _) => const Scaffold(body: Text('Riwayat tersimpan')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        testProviders(
          settings: settings,
          overtime: overtime,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Pekerjaan yang dilemburkan'),
        'Perawatan refueller',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.scrollUntilVisible(
        find.text('Simpan Lembur'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Simpan Lembur'));
      await tester.pumpAndSettle();
      expect(find.text('Riwayat tersimpan'), findsOneWidget);
      expect(repo.entries, hasLength(1));
      expect(repo.entries.single.approverPosition, 'Manager Pengganti');
      expect(repo.entries.single.actualHours, 3);
      expect(repo.entries.single.convertedHours, 5.5);
    },
  );
}
