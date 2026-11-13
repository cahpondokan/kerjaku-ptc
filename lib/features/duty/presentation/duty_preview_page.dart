import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lembur/features/duty/data/duty_pdf_service.dart';
import 'package:lembur/features/duty/presentation/duty_provider.dart';
import 'package:lembur/features/settings/presentation/profile_completion_card.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class DutyPreviewPage extends StatefulWidget {
  const DutyPreviewPage({super.key, required this.id});
  final String id;
  @override
  State<DutyPreviewPage> createState() => _DutyPreviewPageState();
}

class _DutyPreviewPageState extends State<DutyPreviewPage> {
  static const _channel = MethodChannel('com.niam.ayani.kerjakuptc/backup');
  Future<Uint8List>? _pdf;
  String? _revision;
  bool _working = false;

  Future<void> _export({required bool share}) async {
    if (_working || _pdf == null) return;
    setState(() => _working = true);
    try {
      if (!context.read<SettingsProvider>().documentsReady) {
        throw StateError('Lengkapi Profil dan konfirmasi penandatangan.');
      }
      final entry = context.read<DutyProvider>().byId(widget.id)!;
      final bytes = await _pdf!;
      if (!mounted) return;
      if (share) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: DutyPdfService.fileName(entry),
        );
      } else {
        final saved = await _channel.invokeMethod<bool>('savePdf', {
          'fileName': DutyPdfService.fileName(entry),
          'bytes': bytes,
        });
        if (saved == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF berhasil disimpan.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError
                  ? e.message.toString()
                  : 'PDF belum dapat disimpan atau dibagikan.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DutyProvider>();
    final ready = context.watch<SettingsProvider>().documentsReady;
    final entry = provider.byId(widget.id);
    final revision = entry?.toMap().toString();
    if (ready && entry != null && !entry.isDraft && revision != _revision) {
      _revision = revision;
      _pdf = DutyPdfService().build(entry);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pratinjau Surat'),
        actions: [
          if (entry != null)
            IconButton(
              tooltip: 'Edit surat',
              onPressed:
                  () =>
                      context.pushReplacement('/duty/form?editId=${widget.id}'),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body:
          !ready
              ? ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  ProfileCompletionCard(
                    onComplete: () => context.push('/settings'),
                  ),
                ],
              )
              : !provider.loaded
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
              : entry.isDraft
              ? const Center(
                child: Text('Lengkapi dan simpan surat sebelum membuat PDF.'),
              )
              : FutureBuilder<Uint8List>(
                future: _pdf,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: TextButton(
                        onPressed:
                            () => setState(
                              () => _pdf = DutyPdfService().build(entry),
                            ),
                        child: const Text('PDF belum dapat dibuat. Coba lagi.'),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return PdfPreview(
                    key: ValueKey(_revision),
                    pdfFileName: DutyPdfService.fileName(entry),
                    initialPageFormat: PdfPageFormat.a4,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    allowSharing: false,
                    build: (_) async => snapshot.data!,
                  );
                },
              ),
      bottomNavigationBar:
          !ready || entry == null || entry.isDraft
              ? null
              : SafeArea(
                minimum: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _working ? null : () => _export(share: false),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Simpan PDF'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _working ? null : () => _export(share: true),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Bagikan PDF'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
