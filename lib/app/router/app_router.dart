import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lembur/features/duty/presentation/duty_packet_page.dart';
import 'package:lembur/features/duty/presentation/duty_page.dart';
import 'package:lembur/features/duty/presentation/duty_form_page.dart';
import 'package:lembur/features/duty/presentation/duty_detail_page.dart';
import 'package:lembur/features/duty/presentation/duty_preview_page.dart';
import 'package:lembur/features/leave/presentation/leave_page.dart';
import 'package:lembur/features/leave/presentation/leave_form_page.dart';
import 'package:lembur/features/leave/presentation/leave_preview_page.dart';
import 'package:lembur/features/report/presentation/documents_page.dart';
import 'package:lembur/features/dashboard/presentation/dashboard_page.dart';
import 'package:lembur/features/overtime/presentation/overtime_form_page.dart';
import 'package:lembur/features/overtime/presentation/overtime_history_page.dart';
import 'package:lembur/features/report/presentation/report_page.dart';
import 'package:lembur/features/settings/presentation/settings_page.dart';
import 'package:lembur/shared/widgets/main_navigation_shell.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: appNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder:
          (context, state) => const MainNavigationShell(
            currentIndex: 0,
            child: DashboardPage(),
          ),
    ),
    GoRoute(
      path: '/add',
      builder:
          (context, state) => MainNavigationShell(
            currentIndex: 0,
            child: OvertimeFormPage(
              editId: state.uri.queryParameters['editId'],
            ),
          ),
    ),
    GoRoute(
      path: '/history',
      builder:
          (context, state) => const MainNavigationShell(
            currentIndex: 1,
            child: OvertimeHistoryPage(),
          ),
    ),
    GoRoute(
      path: '/settings',
      builder:
          (context, state) =>
              const MainNavigationShell(currentIndex: 3, child: SettingsPage()),
    ),
    GoRoute(path: '/report', builder: (context, state) => const ReportPage()),
    GoRoute(
      path: '/documents',
      builder:
          (context, state) => const MainNavigationShell(
            currentIndex: 2,
            child: DocumentsPage(),
          ),
    ),
    GoRoute(path: '/leave', builder: (context, state) => const LeavePage()),
    GoRoute(path: '/duty', builder: (context, state) => const DutyPage()),
    GoRoute(
      path: '/duty/packet/:id',
      builder:
          (context, state) => DutyPacketPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/duty/form',
      builder:
          (context, state) =>
              DutyFormPage(editId: state.uri.queryParameters['editId']),
    ),
    GoRoute(
      path: '/duty/detail/:id',
      builder:
          (context, state) => DutyDetailPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/duty/preview/:id',
      builder:
          (context, state) => DutyPreviewPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/leave/form',
      builder:
          (context, state) =>
              LeaveFormPage(editId: state.uri.queryParameters['editId']),
    ),
    GoRoute(
      path: '/leave/preview/:id',
      builder:
          (context, state) => LeavePreviewPage(id: state.pathParameters['id']!),
    ),
  ],
);
