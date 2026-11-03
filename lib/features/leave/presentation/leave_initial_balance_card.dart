import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/leave/domain/leave_calculator.dart';
import 'package:lembur/features/leave/presentation/leave_provider.dart';
import 'package:provider/provider.dart';

class LeaveInitialBalanceCard extends StatelessWidget {
  const LeaveInitialBalanceCard({super.key, required this.year});
  final int year;

  @override
  Widget build(BuildContext context) {
    final leave = context.watch<LeaveProvider>();
    final saved = leave.hasInitialUsed(year);
    final recorded = leave.recordedDays(year);
    return NeumorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cuti sebelumnya • $year',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text('$recorded hari dari surat di aplikasi sudah tercatat.'),
          Text(
            '${leave.initialUsed(year)} hari cuti dipakai sebelum menggunakan aplikasi.',
          ),
          const SizedBox(height: 6),
          Text(
            saved
                ? 'Tersimpan dan otomatis mengurangi saldo. Surat yang tercatat di aplikasi dihitung terpisah; jangan masukkan lagi di sini.'
                : recorded > 0
                ? 'Surat yang dibuat di aplikasi sudah otomatis mengurangi saldo. Bagian ini hanya untuk cuti yang diambil sebelum menggunakan aplikasi.'
                : 'Isi hanya cuti yang diambil sebelum menggunakan aplikasi. Surat yang dibuat setelah ini akan tersimpan dan otomatis mengurangi saldo. Isi 0 jika belum ada.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          TextButton.icon(
            key: const ValueKey('initial-leave-edit'),
            onPressed:
                !leave.loaded || leave.loading || leave.saving
                    ? null
                    : () => _edit(context, leave),
            icon: Icon(
              saved ? Icons.edit_outlined : Icons.history_outlined,
              size: 18,
            ),
            label: Text(saved ? 'Ubah cuti sebelumnya' : 'Isi cuti sebelumnya'),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, LeaveProvider leave) async {
    final days = await showDialog<int>(
      context: context,
      builder:
          (_) => _InitialBalanceDialog(
            year: year,
            initialUsed: leave.initialUsed(year),
            maximum:
                LeaveCalculator.annualEntitlement - leave.recordedDays(year),
          ),
    );
    if (days == null || !context.mounted) return;
    try {
      await leave.setInitialUsed(year, days);
    } catch (error) {
      if (context.mounted) {
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
}

class _InitialBalanceDialog extends StatefulWidget {
  const _InitialBalanceDialog({
    required this.year,
    required this.initialUsed,
    required this.maximum,
  });
  final int year;
  final int initialUsed;
  final int maximum;
  @override
  State<_InitialBalanceDialog> createState() => _InitialBalanceDialogState();
}

class _InitialBalanceDialogState extends State<_InitialBalanceDialog> {
  late final _controller = TextEditingController(text: '${widget.initialUsed}');
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text('Cuti sebelumnya ${widget.year}'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Isi jumlah hari cuti yang sudah terpakai. Jangan sertakan Sabtu, Minggu, libur nasional, cuti bersama, atau surat yang sudah tercatat di aplikasi.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('initial-leave-days'),
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: const InputDecoration(labelText: 'Jumlah hari'),
            validator: (value) {
              final days = int.tryParse(value ?? '');
              return days == null || days < 0 || days > widget.maximum
                  ? 'Isi 0–${widget.maximum} hari.'
                  : null;
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, int.parse(_controller.text));
          }
        },
        child: const Text('Simpan'),
      ),
    ],
  );
}
