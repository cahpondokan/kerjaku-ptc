import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lembur/core/utils/overtime_pay_calculator.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/overtime/domain/overtime_salary.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';

class SalarySettingsCard extends StatelessWidget {
  const SalarySettingsCard({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final salary = settings.salary;
    return NeumorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gaji & upah lembur',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            salary == null
                ? 'Isi gaji untuk menghitung estimasi upah lembur.'
                : 'Dasar upah: ${settings.hidePay ? '••••••' : OvertimePayCalculator.basisLabel(salary.basisCents)} / bulan',
          ),
          const SizedBox(height: 6),
          const Text(
            'Pola 5 hari kerja / 40 jam seminggu. Estimasi bruto sebelum pajak dan potongan.',
            style: TextStyle(fontSize: 12),
          ),
          TextButton.icon(
            key: const ValueKey('edit-salary'),
            onPressed:
                () => showDialog<void>(
                  context: context,
                  builder: (_) => SalaryDialog(settings: settings),
                ),
            icon: const Icon(Icons.payments_outlined),
            label: Text(salary == null ? 'Isi gaji' : 'Ubah gaji'),
          ),
        ],
      ),
    );
  }
}

class SalaryDialog extends StatefulWidget {
  const SalaryDialog({super.key, required this.settings});
  final SettingsProvider settings;
  @override
  State<SalaryDialog> createState() => _SalaryDialogState();
}

class _SalaryDialogState extends State<SalaryDialog> {
  final _form = GlobalKey<FormState>();
  late final _basic = TextEditingController(
    text: widget.settings.salary?.basic.toString() ?? '',
  );
  late final _fixed = TextEditingController(
    text: '${widget.settings.salary?.fixed ?? 0}',
  );
  late final _variable = TextEditingController(
    text: '${widget.settings.salary?.variable ?? 0}',
  );
  bool _saving = false;
  String? _error;
  int? _value(TextEditingController c) =>
      OvertimePayCalculator.parseCents(c.text, allowDecimals: false);
  OvertimeSalary? get _salary {
    final values = [_value(_basic), _value(_fixed), _value(_variable)];
    if (values.any((value) => value == null)) return null;
    final salary = OvertimeSalary(
      basic: values[0]! ~/ 100,
      fixed: values[1]! ~/ 100,
      variable: values[2]! ~/ 100,
    );
    return salary.isValid ? salary : null;
  }

  @override
  void dispose() {
    _basic.dispose();
    _fixed.dispose();
    _variable.dispose();
    super.dispose();
  }

  Widget _field(String id, String label, TextEditingController controller) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          key: ValueKey(id),
          controller: controller,
          enabled: !_saving,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            LengthLimitingTextInputFormatter(15),
          ],
          decoration: InputDecoration(
            labelText: label,
            prefixText: 'Rp ',
            helperText: 'Per bulan; isi 0 jika tidak ada',
          ),
          onChanged: (_) => setState(() {}),
          validator: (_) {
            final cents = _value(controller);
            return cents == null || cents > OvertimeSalary.maxComponent * 100
                ? 'Isi angka rupiah yang valid (maks. 999.999.999).'
                : null;
          },
        ),
      );
  @override
  Widget build(BuildContext context) {
    final salary = _salary;
    return AlertDialog(
      scrollable: true,
      title: const Text('Gaji untuk upah lembur'),
      content: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('salary-basic', 'Gaji pokok', _basic),
            _field('salary-fixed', 'Tunjangan tetap', _fixed),
            _field('salary-variable', 'Tunjangan tidak tetap', _variable),
            if (salary != null) ...[
              Text(
                'Dasar upah: ${OvertimePayCalculator.basisLabel(salary.basisCents)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                'Upah sejam: ${OvertimePayCalculator.rupiah(salary.basisCents / 100 / 173, decimals: 2)}',
              ),
              const SizedBox(height: 8),
              Text(
                salary.usesSeventyFivePercent
                    ? 'Dasar memakai 75% seluruh komponen upah karena gaji pokok + tunjangan tetap lebih kecil dari 75% total.'
                    : 'Dasar memakai gaji pokok + tunjangan tetap.',
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Rumus: dasar upah ÷ 173 × jam konversi (PP 35/2021 Pasal 31–32). Gaji baru dipakai untuk catatan baru; gaji pada riwayat tetap tersimpan.',
              style: TextStyle(fontSize: 12),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const ValueKey('save-salary'),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Menyimpan…' : 'Simpan gaji'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final salary = _salary;
    if (salary == null) {
      setState(() => _error = 'Dasar upah harus lebih dari 0.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.settings.saveSalary(salary);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Gaji belum tersimpan. Coba lagi.';
        });
      }
    }
  }
}

Future<int?> editOvertimeBasis(BuildContext context, int? initialCents) =>
    showDialog<int>(
      context: context,
      builder: (_) => _BasisDialog(initialCents: initialCents),
    );

class _BasisDialog extends StatefulWidget {
  const _BasisDialog({required this.initialCents});
  final int? initialCents;
  @override
  State<_BasisDialog> createState() => _BasisDialogState();
}

class _BasisDialogState extends State<_BasisDialog> {
  final _form = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text:
        widget.initialCents == null
            ? ''
            : (widget.initialCents! / 100)
                .toStringAsFixed(2)
                .replaceAll('.', ','),
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Dasar upah catatan ini'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Masukkan dasar upah bulanan yang berlaku pada tanggal lembur ini. Gaji di profil tidak ikut berubah.',
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('entry-wage-basis'),
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              LengthLimitingTextInputFormatter(20),
            ],
            decoration: const InputDecoration(
              labelText: 'Dasar upah / bulan',
              prefixText: 'Rp ',
              helperText: 'Contoh: 5.190.000 atau 5.190.000,25',
            ),
            validator: (value) {
              final cents = OvertimePayCalculator.parseCents(value ?? '');
              return cents == null ||
                      cents <= 0 ||
                      cents > OvertimeSalary.maxBasis * 100
                  ? 'Isi dasar upah yang valid.'
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
            Navigator.pop(
              context,
              OvertimePayCalculator.parseCents(_controller.text),
            );
          }
        },
        child: const Text('Gunakan'),
      ),
    ],
  );
}
