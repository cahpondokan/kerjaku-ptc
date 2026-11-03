import 'package:flutter/material.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';

class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1D5A3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_rounded, color: AppColors.warning),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lengkapi data wajib',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Data diperlukan untuk rekap dan surat cuti.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Profil pekerja',
            complete: settings.profile.isComplete,
            pendingLabel: 'Belum lengkap',
          ),
          const SizedBox(height: 8),
          _StatusRow(
            label: 'Penandatangan',
            complete: settings.signatoriesConfirmed,
            pendingLabel: 'Perlu diperiksa',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onComplete,
              child: const Text('Lengkapi sekarang'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.complete,
    required this.pendingLabel,
  });
  final String label;
  final bool complete;
  final String pendingLabel;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        complete ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        size: 18,
        color: complete ? AppColors.success : AppColors.warning,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          complete ? 'Lengkap' : pendingLabel,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 11,
            color: complete ? AppColors.success : AppColors.warning,
          ),
        ),
      ),
    ],
  );
}
