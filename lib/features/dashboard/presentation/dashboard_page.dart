import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/core/constants/app_constants.dart';
import 'package:lembur/core/utils/date_formatter.dart';
import 'package:lembur/core/utils/duration_calculator.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/overtime/presentation/overtime_provider.dart';
import 'package:lembur/features/overtime/presentation/overtime_pay_summary.dart';
import 'package:lembur/features/report/presentation/document_shortcuts.dart';
import 'package:lembur/features/settings/presentation/profile_completion_card.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final overtime = context.watch<OvertimeProvider>();
    final settings = context.watch<SettingsProvider>();
    final now = DateTime.now();
    final current = overtime.forMonth(now);
    final actual = current.fold<double>(
      0,
      (sum, item) => sum + item.actualHours,
    );
    final converted = current.fold<double>(
      0,
      (sum, item) => sum + item.convertedHours,
    );
    final name = settings.profile.name.trim();
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: overtime.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/icons/app_icon.png',
                  width: 44,
                  height: 44,
                  filterQuality: FilterQuality.high,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Lembur & surat cuti',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Profil & pengaturan',
                  onPressed: () => context.go('/settings'),
                  icon: Badge(
                    isLabelVisible: !settings.documentsReady,
                    backgroundColor: AppColors.warning,
                    child: const Icon(Icons.person_outline_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              name.isEmpty ? 'Selamat datang' : 'Halo, $name',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              settings.documentsReady
                  ? 'Siap mencatat kegiatan hari ini?'
                  : 'Lengkapi data agar semua fitur dapat digunakan.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            if (!settings.loaded)
              const LinearProgressIndicator()
            else if (!settings.documentsReady)
              ProfileCompletionCard(onComplete: () => context.go('/settings'))
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F3E9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'Profil & penandatangan lengkap',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 22),
            const _SectionTitle('Layanan'),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ServiceCard(
                      key: const ValueKey('service-overtime'),
                      icon: Icons.schedule_rounded,
                      title: 'Lembur',
                      description: 'Jam & upah',
                      action: 'Input',
                      onTap: () => context.go('/add'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceCard(
                      key: const ValueKey('service-leave'),
                      icon: Icons.event_note_rounded,
                      title: 'Surat Cuti',
                      description: 'Saldo & surat',
                      action: 'Buka',
                      onTap: () => context.push('/leave'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3C8BFA), AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(40),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lembur bulan ini',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppDateFormatter.month(now),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _SummaryItem(
                        value: '${current.length}',
                        label: 'Kegiatan',
                      ),
                      _SummaryItem(
                        value: DurationCalculator.displayHours(actual),
                        label: 'Jam nyata',
                      ),
                      _SummaryItem(
                        value: DurationCalculator.displayHours(converted),
                        label: 'Konversi',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            OvertimePaySummary(
              entries: current,
              loading: overtime.loading,
              error: overtime.error,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(child: _SectionTitle('Rekap & dokumen')),
                if (!settings.documentsReady)
                  const Icon(
                    Icons.lock_rounded,
                    size: 17,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const DocumentShortcuts(),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(child: _SectionTitle('Aktivitas terbaru')),
                Flexible(
                  child: TextButton(
                    onPressed: () => context.go('/history'),
                    child: const Text(
                      'Lihat semua',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            if (overtime.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (overtime.error != null)
              NeumorphicCard(
                child: Column(
                  children: [
                    const Text('Data lembur belum dapat dimuat.'),
                    TextButton(
                      onPressed: overtime.load,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              )
            else if (overtime.entries.isEmpty)
              const NeumorphicCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.event_note_rounded,
                      color: AppColors.primaryLight,
                      size: 34,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Belum ada catatan. Mulai dengan Catat lembur.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else
              NeumorphicCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    for (final entry in overtime.entries.take(3))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          'Lembur · ${AppDateFormatter.short(entry.overtimeDate)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${entry.startTime}–${entry.endTime} · ${DurationCalculator.displayHours(entry.actualHours)} jam',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                        ),
                        onTap: () => context.go('/add?editId=${entry.id}'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
  );
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ],
    ),
  );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String description;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => NeumorphicCard(
    onTap: onTap,
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFE7F0FF),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const Spacer(),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            onPressed: onTap,
            child: Text(action, textAlign: TextAlign.center),
          ),
        ),
      ],
    ),
  );
}
