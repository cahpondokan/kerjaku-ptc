import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lembur/app/theme/app_theme.dart';
import 'package:lembur/features/duty/presentation/duty_detail_page.dart';
import 'package:lembur/features/duty/presentation/duty_form_page.dart';
import 'package:lembur/features/duty/presentation/duty_page.dart';
import 'package:lembur/features/duty/presentation/duty_provider.dart';
import 'package:lembur/features/settings/domain/user_profile.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'duty_test_helpers.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  late SettingsProvider settings;
  late DutyProvider duty;
  late MemoryDutyRepository repository;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'signatory_names': ['Andi Prasetyo', '', '', ''],
    });
    settings = SettingsProvider();
    await settings.load();
    await settings.saveProfile(
      const UserProfile(name: 'Budi Pratama', workerNumber: 'PTC-001'),
    );
    await settings.confirmSignatories();
    repository = MemoryDutyRepository();
    duty = DutyProvider(repository);
    await duty.load();
  });

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: duty),
    ],
    child: child,
  );

  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  Future<void> advance(WidgetTester tester) async {
    final next = find.byKey(const ValueKey('duty-next'));
    await reveal(tester, next);
    await tester.tap(next);
    await tester.pumpAndSettle();
  }

  testWidgets('Optional serial, date change and final save use stored data', (
    tester,
  ) async {
    await duty.save(sampleDuty(changes: {'is_draft': 1}));
    final router = GoRouter(
      initialLocation: '/duty/form?editId=duty-1',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold()),
        GoRoute(
          path: '/duty/form',
          builder:
              (_, state) =>
                  DutyFormPage(editId: state.uri.queryParameters['editId']),
        ),
        GoRoute(
          path: '/duty/preview/:id',
          builder: (_, _) => const Scaffold(body: Text('PDF siap')),
        ),
        GoRoute(
          path: '/duty/detail/:id',
          builder: (_, _) => const Scaffold(body: Text('Draf tersimpan')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      wrap(MaterialApp.router(theme: AppTheme.light, routerConfig: router)),
    );
    await tester.pumpAndSettle();
    final number = find.byKey(const ValueKey('duty-serial'));
    await reveal(tester, number);
    await tester.enterText(number, '0012');
    await tester.pump();
    expect(find.text('No. 0012 /SPPD/ XI /2026-S8'), findsOneWidget);
    await tester.enterText(number, '');
    await advance(tester);
    await advance(tester);
    final date = find.byKey(const ValueKey('duty-request-date'));
    await reveal(tester, date);
    await tester.tap(date);
    await tester.pumpAndSettle();
    final dialog = find.byType(DatePickerDialog);
    await tester.tap(
      find.descendant(of: dialog, matching: find.byIcon(Icons.edit_outlined)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      '1/2/2027',
    );
    await tester.tap(find.descendant(of: dialog, matching: find.text('Pilih')));
    await tester.pumpAndSettle();
    expect(find.text('No. ... /SPPD/ I /2027-S8'), findsOneWidget);
    final reviewed = find.byKey(const ValueKey('duty-reviewed'));
    await reveal(tester, reviewed);
    await tester.tap(reviewed);
    await advance(tester);
    expect(find.text('PDF siap'), findsOneWidget);
    expect(duty.entries.single.isDraft, isFalse);
    expect(duty.entries.single.requestDate, DateTime(2027, 1, 2));
    expect(duty.entries.single.startDate, DateTime(2026, 11, 2));
    expect(duty.entries.single.applicantName, 'Dimas Saputra');
    expect(duty.entries.single.serial, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Incomplete new letter can be saved as a draft and reopened', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/duty/form',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold()),
        GoRoute(
          path: '/duty/form',
          builder:
              (_, state) =>
                  DutyFormPage(editId: state.uri.queryParameters['editId']),
        ),
        GoRoute(
          path: '/duty/detail/:id',
          builder:
              (_, state) => DutyDetailPage(id: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      wrap(MaterialApp.router(theme: AppTheme.light, routerConfig: router)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan draf'));
    await tester.pumpAndSettle();
    expect(duty.entries.single.isDraft, isTrue);
    expect(duty.entries.single.applicantName, 'Budi Pratama');
    expect(find.text('Detail Surat Dinas'), findsOneWidget);
    expect(find.text('Lihat PDF'), findsNothing);
    router.go('/duty/form?editId=${duty.entries.single.id}');
    await tester.pumpAndSettle();
    expect(find.text('Budi Pratama'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'All form steps and lists fit narrow screens with enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await duty.save(sampleDuty());
      Widget page(Widget child) => wrap(
        MaterialApp(
          theme: AppTheme.light,
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!,
              ),
          home: child,
        ),
      );
      for (final child in [
        const DutyPage(),
        const DutyDetailPage(id: 'duty-1'),
        const DutyFormPage(editId: 'duty-1'),
      ]) {
        await tester.pumpWidget(page(child));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${child.runtimeType}');
        if (child is DutyFormPage) {
          await advance(tester);
          expect(tester.takeException(), isNull);
          await advance(tester);
          expect(tester.takeException(), isNull);
          await reveal(tester, find.byKey(const ValueKey('duty-reviewed')));
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}
