import 'package:flutter/material.dart';
import 'package:lembur/features/leave/data/leave_repository.dart';
import 'package:lembur/features/leave/presentation/leave_provider.dart';
import 'package:lembur/app/router/app_router.dart';
import 'package:lembur/app/theme/app_theme.dart';
import 'package:lembur/core/constants/app_constants.dart';
import 'package:lembur/shared/widgets/profile_reminder.dart';
import 'package:lembur/features/overtime/data/overtime_repository.dart';
import 'package:lembur/features/overtime/presentation/overtime_provider.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';

class KerjaKuBootstrap extends StatelessWidget {
  const KerjaKuBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(
          create: (_) => LeaveProvider(LeaveRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => OvertimeProvider(OvertimeRepository())..load(),
        ),
      ],
      child: const KerjaKuApp(),
    );
  }
}

class KerjaKuApp extends StatelessWidget {
  const KerjaKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      builder:
          (context, child) => ProfileReminder(
            navigatorKey: appNavigatorKey,
            onComplete: () => appRouter.go('/settings'),
            child: child!,
          ),
    );
  }
}
