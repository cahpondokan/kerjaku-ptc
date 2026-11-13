import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lembur/app/theme/app_theme.dart';
import 'package:lembur/core/utils/overtime_pay_calculator.dart';
import 'package:lembur/features/dashboard/presentation/dashboard_page.dart';
import 'package:lembur/features/overtime/domain/overtime_salary.dart';
import 'package:lembur/features/overtime/presentation/overtime_form_page.dart';
import 'package:lembur/features/overtime/presentation/overtime_pay_summary.dart';
import 'package:lembur/features/overtime/presentation/overtime_provider.dart';
import 'package:lembur/features/settings/domain/user_profile.dart';
import 'package:lembur/features/settings/presentation/salary_settings_card.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void size(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<SettingsProvider> readySettings() async {
  final settings = SettingsProvider();
  await settings.load();
  await settings.saveProfile(
    const UserProfile(name: 'Budi', workerNumber: '123'),
  );
  await settings.confirmSignatories();
  return settings;
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    280,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final config in [
    (320.0, 1.0),
    (360.0, 0.85),
    (360.0, 1.3),
    (390.0, 1.5),
    (320.0, 2.0),
  ]) {
    testWidgets(
      'Service cards share one row at width ${config.$1}, scale ${config.$2}',
      (tester) async {
        size(tester, config.$1);
        final settings = await readySettings();
        final overtime = OvertimeProvider(MemoryOvertimeRepository());
        await tester.pumpWidget(
          testPage(
            settings: settings,
            overtime: overtime,
            textScale: config.$2,
            child: const DashboardPage(),
          ),
        );
        await tester.pumpAndSettle();
        final first = find.byKey(const ValueKey('service-overtime'));
        final second = find.byKey(const ValueKey('service-leave'));
        await scrollTo(tester, first);
        final left = tester.getRect(first);
        final right = tester.getRect(second);
        expect(left.top, closeTo(right.top, 0.01));
        expect(left.bottom, closeTo(right.bottom, 0.01));
        expect(left.right, lessThan(right.left));
        expect(left.width, closeTo(right.width, 0.01));
        expect(right.right, lessThanOrEqualTo(config.$1));
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 4; i++) {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -300),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets('Both service buttons still navigate on a narrow phone', (
    tester,
  ) async {
    size(tester, 320);
    final settings = await readySettings();
    final overtime = OvertimeProvider(MemoryOvertimeRepository());
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: DashboardPage()),
        ),
        GoRoute(
          path: '/add',
          builder: (_, _) => const Scaffold(body: Text('Input uji')),
        ),
        GoRoute(
          path: '/leave',
          builder: (_, _) => const Scaffold(body: Text('Cuti uji')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      testProviders(
        settings: settings,
        overtime: overtime,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    for (final destination in [
      ('service-overtime', 'Input uji'),
      ('service-leave', 'Cuti uji'),
    ]) {
      final button = find.descendant(
        of: find.byKey(ValueKey(destination.$1)),
        matching: find.byType(FilledButton),
      );
      await scrollTo(tester, button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text(destination.$2), findsOneWidget);
      router.go('/');
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Salary dialog validates zero and stores all three components', (
    tester,
  ) async {
    size(tester, 320);
    final settings = await readySettings();
    final overtime = OvertimeProvider(MemoryOvertimeRepository());
    await tester.pumpWidget(
      testPage(
        settings: settings,
        overtime: overtime,
        child: const SalarySettingsCard(),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('edit-salary')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('salary-basic')), '0');
    await tester.tap(find.byKey(const ValueKey('save-salary')));
    await tester.pumpAndSettle();
    expect(settings.salary, isNull);
    expect(find.byType(SalaryDialog), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('salary-basic')),
      '2.000.000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('salary-fixed')),
      '1.000.000',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('salary-variable')));
    await tester.enterText(
      find.byKey(const ValueKey('salary-variable')),
      '2.000.001',
    );
    await tester.tap(find.byKey(const ValueKey('save-salary')));
    await tester.pumpAndSettle();
    expect(find.byType(SalaryDialog), findsNothing);
    expect(settings.salary!.basisCents, 375000075);
    final reopened = SettingsProvider();
    await reopened.load();
    expect(reopened.salary!.variable, 2000001);
    expect(reopened.documentsReady, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final scenario in [
    'new',
    'existing',
    'legacy',
    'existing-profile',
    'legacy-manual',
  ]) {
    testWidgets('Form saves correct wage basis for $scenario', (tester) async {
      size(tester, 390);
      final settings = await readySettings();
      await settings.saveSalary(const OvertimeSalary(basic: 6920000));
      final seed =
          scenario == 'existing' || scenario == 'existing-profile'
              ? sampleEntry().copyWith(monthlyWageBasisCents: 519000000)
              : sampleEntry();
      final repo = MemoryOvertimeRepository(scenario == 'new' ? [] : [seed]);
      final overtime = OvertimeProvider(repo);
      await overtime.load();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder:
                (_, _) => Scaffold(
                  body: OvertimeFormPage(
                    editId: scenario == 'new' ? null : 'sample',
                  ),
                ),
          ),
          GoRoute(
            path: '/history',
            builder: (_, _) => const Scaffold(body: Text('Tersimpan')),
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
      if (scenario == 'new') {
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Pekerjaan yang dilemburkan'),
          'Perawatan',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
      }
      if (scenario == 'existing-profile') {
        await scrollTo(tester, find.byKey(const ValueKey('use-profile-wage')));
        await tester.tap(find.byKey(const ValueKey('use-profile-wage')));
        await tester.pumpAndSettle();
      }
      if (scenario == 'legacy-manual') {
        await scrollTo(tester, find.byKey(const ValueKey('edit-entry-wage')));
        await tester.tap(find.byKey(const ValueKey('edit-entry-wage')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('entry-wage-basis')),
          '5.190.000',
        );
        await tester.tap(find.text('Gunakan'));
        await tester.pumpAndSettle();
      }
      await scrollTo(tester, find.text('Simpan Lembur'));
      await tester.tap(find.text('Simpan Lembur'));
      await tester.pumpAndSettle();
      expect(find.text('Tersimpan'), findsOneWidget);
      expect(repo.entries, hasLength(1));
      final expectedBasis = switch (scenario) {
        'new' || 'legacy' || 'existing-profile' => 692000000,
        'existing' || 'legacy-manual' => 519000000,
        _ => null,
      };
      expect(repo.entries.single.monthlyWageBasisCents, expectedBasis);
      expect(
        repo.entries.single.estimatedPay,
        expectedBasis == null
            ? null
            : expectedBasis == 519000000
            ? 165000
            : 220000,
      );
      expect(settings.salary!.basisCents, 692000000);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Summary automatically includes legacy wages and persists hidden amounts',
    (tester) async {
      final settings = await readySettings();
      await settings.saveSalary(const OvertimeSalary(basic: 5190000));
      final overtime = OvertimeProvider(MemoryOvertimeRepository());
      final paid = sampleEntry().copyWith(monthlyWageBasisCents: 519000000);
      await tester.pumpWidget(
        testPage(
          settings: settings,
          overtime: overtime,
          child: OvertimePaySummary(
            entries: [paid, paid.copyWith(id: 'second'), sampleEntry()],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Estimasi upah lembur'), findsOneWidget);
      expect(find.text(OvertimePayCalculator.rupiah(495000)), findsOneWidget);
      expect(find.textContaining('catatan belum dihitung'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('toggle-pay-visibility')));
      await tester.pumpAndSettle();
      expect(find.text('••••••'), findsOneWidget);
      expect(find.text(OvertimePayCalculator.rupiah(495000)), findsNothing);
      final reopened = SettingsProvider();
      await reopened.load();
      expect(reopened.hidePay, isTrue);
    },
  );

  testWidgets(
    'Legacy-only, loading and failure summaries do not claim a zero total',
    (tester) async {
      final settings = await readySettings();
      final overtime = OvertimeProvider(MemoryOvertimeRepository());
      for (final item in [
        (OvertimePaySummary(entries: [sampleEntry()]), 'Belum dihitung'),
        (const OvertimePaySummary(entries: [], loading: true), 'Memuat…'),
        (
          const OvertimePaySummary(entries: [], error: 'load failed'),
          'Data belum dapat dimuat',
        ),
      ]) {
        await tester.pumpWidget(
          testPage(settings: settings, overtime: overtime, child: item.$1),
        );
        await tester.pump();
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('monthly-overtime-pay')))
              .data,
          item.$2,
        );
      }
    },
  );
}
