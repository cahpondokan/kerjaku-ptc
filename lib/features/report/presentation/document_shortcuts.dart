import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';

class DocumentShortcuts extends StatelessWidget {
  const DocumentShortcuts({super.key});
  @override
  Widget build(BuildContext context) {
    final ready = context.watch<SettingsProvider>().documentsReady;
    return NeumorphicCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth < 280 ||
                  MediaQuery.textScalerOf(context).scale(12) > 17;
              final items = [
                _DocumentTile(
                  label: 'PDF SPKL',
                  icon: Icons.description_rounded,
                  onTap: ready ? () => context.push('/report') : null,
                ),
                _DocumentTile(
                  label: 'Rekap Excel',
                  icon: Icons.table_chart_rounded,
                  onTap: ready ? () => context.push('/report') : null,
                ),
                _DocumentTile(
                  label: 'Surat cuti',
                  icon: Icons.event_note_rounded,
                  onTap: ready ? () => context.push('/leave') : null,
                ),
              ];
              if (stacked) {
                return Column(
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: item,
                      ),
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(child: items[i]),
                  ],
                ],
              );
            },
          ),
          if (!ready) ...[
            const SizedBox(height: 10),
            const Text(
              'Lengkapi profil dan konfirmasi penandatangan untuk membuat dokumen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.label, required this.icon, this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final color = onTap != null ? AppColors.primary : AppColors.textSecondary;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        color:
            onTap != null ? const Color(0xFFEDF5FF) : const Color(0xFFE8EDF3),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 13),
            child: Column(
              children: [
                Icon(
                  onTap == null ? Icons.lock_rounded : icon,
                  color: color,
                  size: 27,
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
