import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lembur/core/utils/overtime_pay_calculator.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/overtime/domain/overtime_entry.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';

class OvertimePaySummary extends StatelessWidget {
  const OvertimePaySummary({
    super.key,
    required this.entries,
    this.loading = false,
    this.error,
  });
  final List<OvertimeEntry> entries;
  final bool loading;
  final String? error;
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final profileBasis = settings.salary?.basisCents;
    final amounts =
        entries
            .map((entry) => entry.estimatedPayWithBasis(profileBasis))
            .whereType<int>()
            .toList();
    final total = amounts.fold<int>(0, (sum, value) => sum + value);
    final missing = entries.length - amounts.length;
    return NeumorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  missing > 0 ? 'Subtotal upah lembur' : 'Estimasi upah lembur',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('toggle-pay-visibility'),
                tooltip:
                    settings.hidePay
                        ? 'Tampilkan nominal'
                        : 'Sembunyikan nominal',
                icon: Icon(
                  settings.hidePay
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () async {
                  try {
                    await settings.setHidePay(!settings.hidePay);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Pengaturan belum tersimpan. Coba lagi.',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          Text(
            loading
                ? 'Memuat…'
                : error != null
                ? 'Data belum dapat dimuat'
                : amounts.isEmpty && entries.isNotEmpty
                ? 'Belum dihitung'
                : settings.hidePay
                ? '••••••'
                : OvertimePayCalculator.rupiah(total),
            key: const ValueKey('monthly-overtime-pay'),
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bruto sebelum pajak dan potongan.',
            style: TextStyle(fontSize: 12),
          ),
          if (!loading && error == null && missing > 0) ...[
            const SizedBox(height: 6),
            Text(
              '$missing catatan belum dihitung. Buka Edit Lembur untuk melengkapi dasar upah atau memeriksa durasinya.',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          if (settings.salary == null)
            TextButton(
              onPressed: () => context.push('/settings'),
              child: const Text('Isi gaji di Profil'),
            ),
          if (settings.salary != null &&
              entries.any((entry) => entry.monthlyWageBasisCents == null))
            const Text(
              'Catatan lama otomatis memakai dasar upah dari Profil.',
              style: TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
}
