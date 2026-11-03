import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/leave/domain/leave_entry.dart';
import 'package:lembur/features/leave/domain/leave_calculator.dart';
import 'package:lembur/features/leave/domain/leave_holidays.dart';
import 'package:lembur/features/leave/presentation/leave_holiday_dialog.dart';
import 'package:lembur/features/leave/presentation/leave_initial_balance_card.dart';
import 'package:lembur/features/leave/presentation/leave_provider.dart';
import 'package:lembur/features/settings/presentation/profile_completion_card.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key, this.now = DateTime.now});
  final DateTime Function() now;
  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> with WidgetsBindingObserver {
  late int _currentYear;
  late int _year;
  Timer? _dayTimer;

  @override
  void initState() {
    super.initState();
    _currentYear = widget.now().year;
    _year = _currentYear;
    WidgetsBinding.instance.addObserver(this);
    _scheduleDayCheck();
  }

  void _scheduleDayCheck() {
    _dayTimer?.cancel();
    final now = widget.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _dayTimer = Timer(midnight.difference(now), _refreshYear);
  }

  void _refreshYear() {
    final year = widget.now().year;
    if (year != _currentYear) {
      setState(() {
        if (_year == _currentYear) _year = year;
        _currentYear = year;
      });
    }
    _scheduleDayCheck();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshYear();
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leave = context.watch<LeaveProvider>();
    final ready = context.watch<SettingsProvider>().documentsReady;
    final years =
        {
            ...leave.years,
            _currentYear - 1,
            _currentYear,
            _currentYear + 1,
            _year,
          }.toList()
          ..sort((a, b) => b.compareTo(a));
    return Scaffold(
      appBar: AppBar(title: const Text('Surat Cuti')),
      body:
          !leave.loaded
              ? Center(
                child:
                    leave.error == null
                        ? const CircularProgressIndicator()
                        : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(leave.error!),
                            TextButton(
                              onPressed: leave.load,
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
              )
              : RefreshIndicator(
                onRefresh: leave.load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (!ready) ...[
                      ProfileCompletionCard(
                        onComplete: () => context.push('/settings'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Saldo cuti tahunan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              DropdownButton<int>(
                                value: _year,
                                dropdownColor: AppColors.primary,
                                iconEnabledColor: Colors.white,
                                underline: const SizedBox.shrink(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                items: [
                                  for (final year in years)
                                    DropdownMenuItem(
                                      value: year,
                                      child: Text('$year'),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _year = value);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${leave.remaining(_year)} hari tersisa',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Hak 12 hari · Terpakai / tercatat ${12 - leave.remaining(_year)} hari',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Sabtu, Minggu, libur nasional, dan cuti bersama tidak dihitung.',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Setiap 1 Januari, hak cuti kembali 12 hari. Sisa tahun lalu tidak ditambahkan; riwayat tetap tersimpan.',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => showLeaveHolidays(context, _year),
                            child: Text('Lihat hari libur $_year'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (!LeaveHolidays.covers(_year)) ...[
                      Text(
                        'Kalender libur $_year belum tersedia. Perbarui aplikasi sebelum membuat surat tahun ini.',
                      ),
                      const SizedBox(height: 14),
                    ],
                    LeaveInitialBalanceCard(year: _year),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed:
                          ready && !leave.saving
                              ? () => context.push('/leave/form')
                              : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Buat surat cuti'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Riwayat cuti $_year',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Surat tersimpan langsung mengurangi saldo. Cetak ulang tidak mengurangi lagi.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (leave.forYear(_year).isEmpty)
                      const NeumorphicCard(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Belum ada surat cuti pada tahun ini.'),
                        ),
                      ),
                    for (final entry in leave.forYear(_year))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: NeumorphicCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${DateFormat('dd MMM', 'id_ID').format(entry.startDate)} – ${DateFormat('dd MMM yyyy', 'id_ID').format(entry.endDate)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                LeaveCalculator.calendarError(
                                      entry.startDate,
                                      entry.endDate,
                                    ) ??
                                    '${entry.days} hari kerja · Masuk ${DateFormat('dd MMM yyyy', 'id_ID').format(entry.returnDate)}',
                              ),
                              const SizedBox(height: 5),
                              Text(
                                entry.reason,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed:
                                        ready && !leave.saving
                                            ? () => context.push(
                                              '/leave/preview/${entry.id}',
                                            )
                                            : null,
                                    icon: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Lihat PDF'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        ready && !leave.saving
                                            ? () => context.push(
                                              '/leave/form?editId=${entry.id}',
                                            )
                                            : null,
                                    child: const Text('Ubah'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        leave.saving
                                            ? null
                                            : () => _delete(leave, entry),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Future<void> _delete(LeaveProvider leave, LeaveEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus surat cuti?'),
            content: Text(
              '${entry.days} hari akan dikembalikan ke saldo ${entry.year}. Surat yang sudah dibagikan tidak ikut terhapus.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await leave.delete(entry.id);
    } catch (error) {
      _error(error);
    }
  }

  void _error(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'Perubahan belum tersimpan. Coba lagi.',
          ),
        ),
      );
    }
  }
}
