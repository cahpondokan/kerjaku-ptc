import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lembur/features/leave/domain/leave_holidays.dart';

Future<void> showLeaveHolidays(
  BuildContext context,
  int year,
) => showDialog<void>(
  context: context,
  builder:
      (context) => AlertDialog(
        title: Text('Hari libur $year'),
        content: SizedBox(
          width: 420,
          child:
              !LeaveHolidays.covers(year)
                  ? Text(
                    'Kalender libur $year belum tersedia. Kalender dalam aplikasi mencakup 2025–2027. Perbarui aplikasi sebelum membuat surat tahun ini.',
                  )
                  : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Libur nasional dan cuti bersama sesuai SKB pemerintah. Semua tanggal di bawah, Sabtu, dan Minggu dilewati dalam perhitungan cuti.',
                        ),
                        const SizedBox(height: 16),
                        for (final date in LeaveHolidays.datesForYear(year))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat(
                                    'EEE, dd MMM yyyy',
                                    'id_ID',
                                  ).format(date),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${LeaveHolidays.name(date)} • ${LeaveHolidays.isCollective(date) ? 'Cuti bersama' : 'Libur nasional'}',
                                ),
                              ],
                            ),
                          ),
                        const Text(
                          'Kalender tersedia: 2025–2027. Tahun berikutnya memerlukan pembaruan kalender aplikasi.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
);
