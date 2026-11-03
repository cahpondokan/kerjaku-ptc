import 'package:flutter/material.dart';
import 'package:lembur/core/utils/overtime_pay_calculator.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:lembur/features/overtime/presentation/overtime_pay_summary.dart';
import 'package:go_router/go_router.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/core/utils/date_formatter.dart';
import 'package:lembur/core/utils/duration_calculator.dart';
import 'package:lembur/core/widgets/app_empty_state.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/overtime/domain/overtime_entry.dart';
import 'package:lembur/features/overtime/presentation/overtime_provider.dart';
import 'package:provider/provider.dart';

class OvertimeHistoryPage extends StatefulWidget {
  const OvertimeHistoryPage({super.key});

  @override
  State<OvertimeHistoryPage> createState() => _OvertimeHistoryPageState();
}

class _OvertimeHistoryPageState extends State<OvertimeHistoryPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  Future<void> _selectMonth() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih salah satu tanggal pada bulan',
    );
    if (result != null) {
      setState(() {
        _selectedMonth = DateTime(result.year, result.month);
      });
    }
  }

  Future<void> _delete(OvertimeEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Hapus data?'),
            content: Text(
              'Data ${AppDateFormatter.short(entry.overtimeDate)} '
              'akan dihapus permanen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      await context.read<OvertimeProvider>().delete(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OvertimeProvider>();
    final entries = provider.forMonth(_selectedMonth);
    final settings = context.watch<SettingsProvider>();
    final hidePay = settings.hidePay;
    final profileBasis = settings.salary?.basisCents;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 125),
        children: [
          Text(
            'Riwayat Lembur',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Text(
            'Kelola data lembur yang tersimpan di HP.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          NeumorphicCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            onTap: _selectMonth,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppDateFormatter.month(_selectedMonth),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${entries.length} data',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 5),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),
          const SizedBox(height: 22),
          OvertimePaySummary(
            entries: entries,
            loading: provider.loading,
            error: provider.error,
          ),
          const SizedBox(height: 22),
          if (entries.isEmpty)
            const NeumorphicCard(
              child: AppEmptyState(
                title: 'Tidak ada data',
                message: 'Belum ada lembur pada bulan yang dipilih.',
              ),
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NeumorphicCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppDateFormatter.full(entry.overtimeDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(26),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              entry.dayType == DayType.regular
                                  ? 'Hari biasa'
                                  : 'Hari libur',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${entry.startTime} – ${entry.endTime}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${DurationCalculator.displayHours(entry.actualHours)} '
                              'jam nyata',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${DurationCalculator.displayHours(entry.convertedHours)} '
                              'jam konversi',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        entry.estimatedPayWithBasis(profileBasis) == null
                            ? 'Upah belum dihitung • lengkapi melalui Edit'
                            : 'Estimasi bruto: ${hidePay ? '••••••' : OvertimePayCalculator.rupiah(entry.estimatedPayWithBasis(profileBasis)!)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Text(entry.workDescription),
                      const SizedBox(height: 10),
                      Text(
                        '${entry.approverPosition} • ${entry.approverName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            onPressed:
                                () => context.go('/add?editId=${entry.id}'),
                            icon: const Icon(
                              Icons.edit_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Hapus',
                            onPressed: () => _delete(entry),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
