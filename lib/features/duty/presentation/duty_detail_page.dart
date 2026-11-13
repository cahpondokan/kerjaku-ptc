import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lembur/features/duty/data/duty_pdf_service.dart';
import 'package:lembur/features/duty/presentation/duty_provider.dart';
import 'package:lembur/features/duty/presentation/duty_widgets.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class DutyDetailPage extends StatelessWidget {
  const DutyDetailPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DutyProvider>();
    final entry = provider.byId(id);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Surat Dinas')),
      body:
          !provider.loaded
              ? Center(
                child:
                    provider.error == null
                        ? const CircularProgressIndicator()
                        : TextButton(
                          onPressed: provider.load,
                          child: const Text('Muat ulang surat dinas'),
                        ),
              )
              : entry == null
              ? const Center(child: Text('Surat tidak ditemukan.'))
              : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  DutySection(
                    title: '${entry.origin} → ${entry.destination}',
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DutyStatus(draft: entry.isDraft),
                      ),
                      const SizedBox(height: 10),
                      Text(dutyRange(entry)),
                    ],
                  ),
                  DutySection(
                    title: 'Data surat',
                    children: [
                      DutyFact('Nomor surat', entry.letterNumber),
                      DutyFact('Tanggal surat', dutyDate(entry.requestDate)),
                      DutyFact('Kepada', entry.recipient),
                    ],
                  ),
                  DutySection(
                    title: 'Pekerja & perjalanan',
                    children: [
                      DutyFact('Nama', entry.applicantName),
                      DutyFact('No. ID Card', entry.workerNumber),
                      DutyFact('Bagian / Penempatan', entry.placement),
                      DutyFact('Jenis pekerjaan', entry.jobType),
                      DutyFact('Keperluan', entry.purpose),
                      DutyFact('Berkendaraan', entry.transport),
                      DutyFact('Biaya ditanggung oleh', entry.costBearer),
                    ],
                  ),
                  DutySection(
                    title: 'Penandatangan',
                    children: [
                      DutyFact('Nama', entry.signerName),
                      DutyFact('Jabatan', entry.signerPosition),
                      DutyFact('Tempat surat', entry.requestPlace),
                    ],
                  ),
                  if (!entry.isDraft) ...[
                    DutySection(
                      title: 'Berkas setelah dinas',
                      children: [
                        const Text(
                          'Scan SPPD, SPD, Deklarasi, dan Invoice secara terpisah. Bisa dibagikan bertahap sesuai dokumen yang tersedia.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => context.push('/duty/packet/$id'),
                          icon: const Icon(Icons.document_scanner_outlined),
                          label: const Text('Kelola berkas dinas'),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => context.push('/duty/preview/$id'),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Lihat PDF'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          if (!context
                              .read<SettingsProvider>()
                              .documentsReady) {
                            throw StateError(
                              'Lengkapi Profil dan konfirmasi penandatangan.',
                            );
                          }
                          final bytes = await DutyPdfService().build(entry);
                          if (!context.mounted) return;
                          await Printing.sharePdf(
                            bytes: bytes,
                            filename: DutyPdfService.fileName(entry),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e is StateError
                                      ? e.message.toString()
                                      : 'PDF belum dapat dibagikan.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Bagikan PDF'),
                    ),
                  ],
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/duty/form?editId=$id'),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      entry.isDraft ? 'Lanjutkan draf' : 'Edit surat',
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed:
                        provider.saving
                            ? null
                            : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text('Hapus surat dinas?'),
                                      content: const Text(
                                        'Surat ini beserta seluruh hasil scan berkas dinasnya akan dihapus dari perangkat.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(ctx, false),
                                          child: const Text('Batal'),
                                        ),
                                        FilledButton(
                                          onPressed:
                                              () => Navigator.pop(ctx, true),
                                          child: const Text('Hapus'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirmed != true || !context.mounted) return;
                              try {
                                await provider.delete(id);
                                if (context.mounted) context.pop();
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Surat belum dapat dihapus.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                    child: const Text(
                      'Hapus surat',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
    );
  }
}
