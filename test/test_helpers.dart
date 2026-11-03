import 'package:flutter/material.dart';
import 'package:lembur/app/theme/app_theme.dart';
import 'package:lembur/features/overtime/data/overtime_repository.dart';
import 'package:lembur/features/overtime/domain/overtime_entry.dart';
import 'package:lembur/features/overtime/presentation/overtime_provider.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';

class MemoryOvertimeRepository extends OvertimeRepository {
  MemoryOvertimeRepository([List<OvertimeEntry>? seed]) : entries = [...?seed];
  final List<OvertimeEntry> entries;
  @override
  Future<List<OvertimeEntry>> getAll() async => List.of(entries);
  @override
  Future<void> save(OvertimeEntry entry) async {
    entries.removeWhere((item) => item.id == entry.id);
    entries.add(entry);
  }

  @override
  Future<void> delete(String id) async =>
      entries.removeWhere((entry) => entry.id == id);
}

OvertimeEntry sampleEntry({String name = 'Joni Herawan'}) {
  final now = DateTime.now();
  return OvertimeEntry(
    id: 'sample',
    overtimeDate: now,
    startTime: '16:00',
    endTime: '19:00',
    actualHours: 3,
    convertedHours: 5.5,
    dayType: DayType.regular,
    workDescription: 'Perawatan unit',
    approverPosition: 'AFT Manager',
    approverName: name,
    createdAt: now,
    updatedAt: now,
  );
}

Widget testProviders({
  required SettingsProvider settings,
  required OvertimeProvider overtime,
  required Widget child,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: settings),
    ChangeNotifierProvider.value(value: overtime),
  ],
  child: child,
);

Widget testPage({
  required SettingsProvider settings,
  required OvertimeProvider overtime,
  required Widget child,
  double textScale = 1,
}) => testProviders(
  settings: settings,
  overtime: overtime,
  child: MaterialApp(
    theme: AppTheme.light,
    builder:
        (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
    home: Scaffold(body: child),
  ),
);
