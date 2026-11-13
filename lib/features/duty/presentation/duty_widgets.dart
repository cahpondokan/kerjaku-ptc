import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/duty/domain/duty_entry.dart';

String dutyDate(DateTime? date) =>
    date == null
        ? 'Belum dipilih'
        : DateFormat('dd MMM yyyy', 'id_ID').format(date);

String dutyRange(DutyEntry entry) =>
    entry.startDate == null || entry.returnDate == null
        ? 'Tanggal belum diisi'
        : '${dutyDate(entry.startDate)} – ${dutyDate(entry.returnDate)} · ${entry.calendarDays} hari';

class DutySection extends StatelessWidget {
  const DutySection({
    super.key,
    required this.title,
    required this.children,
    this.action,
  });
  final String title;
  final List<Widget> children;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (action != null) action!,
          ],
        ),
        const SizedBox(height: 10),
        NeumorphicCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    ),
  );
}

class DutyFact extends StatelessWidget {
  const DutyFact(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? 'Belum diisi' : value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class DutyStatus extends StatelessWidget {
  const DutyStatus({super.key, required this.draft});
  final bool draft;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: draft ? const Color(0xFFFFEDD2) : const Color(0xFFD9E9FF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      draft ? 'Draf' : 'Tersimpan',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: draft ? AppColors.warning : AppColors.primary,
      ),
    ),
  );
}
