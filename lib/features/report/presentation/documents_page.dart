import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/report/presentation/document_shortcuts.dart';
import 'package:lembur/features/settings/presentation/profile_completion_card.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final ready = context.watch<SettingsProvider>().documentsReady;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
        children: [
          Text(
            'Rekap & dokumen',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text('Buat rekap lembur, surat cuti, dan surat dinas.'),
          const SizedBox(height: 22),
          if (!ready) ...[
            ProfileCompletionCard(onComplete: () => context.go('/settings')),
            const SizedBox(height: 20),
          ],
          const DocumentShortcuts(),
          const SizedBox(height: 18),
          NeumorphicCard(
            onTap: () => context.push('/duty'),
            child: const Row(
              children: [
                Icon(Icons.work_outline_rounded, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Surat Dinas',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Buat, simpan, dan cetak permintaan perjalanan dinas',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const NeumorphicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dokumen lembur',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Pilih bulan untuk membuat PDF SPKL, rekap Excel, atau membagikan keduanya ke WhatsApp admin.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          NeumorphicCard(
            onTap: () => context.push('/leave'),
            child: const Row(
              children: [
                Icon(Icons.event_note_rounded, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Surat Cuti',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hitung hari, pantau saldo, dan cetak surat',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
