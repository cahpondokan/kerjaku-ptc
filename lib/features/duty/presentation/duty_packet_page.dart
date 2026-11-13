import 'package:flutter/material.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/duty/data/duty_packet_pdf.dart';
import 'package:lembur/features/duty/data/duty_scan_repository.dart';
import 'package:lembur/features/duty/data/duty_scanner.dart';
import 'package:lembur/features/duty/domain/duty_entry.dart';
import 'package:lembur/features/duty/domain/duty_scan_page.dart';
import 'package:lembur/features/duty/presentation/duty_document_page.dart';
import 'package:lembur/features/duty/presentation/duty_packet_controller.dart';
import 'package:lembur/features/duty/presentation/duty_provider.dart';
import 'package:lembur/features/duty/presentation/duty_widgets.dart';
import 'package:provider/provider.dart';

class DutyPacketPage extends StatefulWidget {
  const DutyPacketPage({
    super.key,
    required this.id,
    this.repository,
    this.pdf,
  });
  final String id;
  final DutyScanRepository? repository;
  final DutyPacketPdf? pdf;
  @override
  State<DutyPacketPage> createState() => _DutyPacketPageState();
}

class _DutyPacketPageState extends State<DutyPacketPage> {
  late final DutyPacketController _controller = DutyPacketController(
    widget.id,
    widget.repository ?? DutyScanRepository(),
  );
  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share(DutyEntry entry) async {
    if (!_controller.canShare) return;
    final pages = List<DutyScanPage>.unmodifiable(_controller.pages);
    final progress = ValueNotifier<int>(0);
    var cancelled = false;
    _controller.setBusy(true);
    final dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('Menyiapkan berkas'),
              content: SingleChildScrollView(
                child: ValueListenableBuilder<int>(
                  valueListenable: progress,
                  builder:
                      (_, done, _) => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${entry.origin} → ${entry.destination}'),
                          const SizedBox(height: 16),
                          for (final type in DutyDocumentType.values)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                '${type.label} • ${pages.where((p) => p.type == type).length} halaman${pages.any((p) => p.type == type) ? '' : ' • dilewati'}',
                              ),
                            ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(value: done / pages.length),
                          const SizedBox(height: 12),
                          Text('$done dari ${pages.length} halaman diproses'),
                          const SizedBox(height: 12),
                          const Text(
                            'WhatsApp akan terbuka setelah PDF siap. Pilih sendiri kontak atau grup penerimanya.',
                          ),
                        ],
                      ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    cancelled = true;
                  },
                  child: const Text('Batalkan'),
                ),
              ],
            ),
          ),
    );
    String? message;
    try {
      final service = widget.pdf ?? DutyPacketPdf();
      final bytes = await service.build(
        pages,
        (id) => _controller.repository.image(id),
        progress: (done, _) => progress.value = done,
        cancelled: () => cancelled,
      );
      if (!cancelled) {
        final file = await service.saveTemporary(entry, bytes);
        if (!cancelled) {
          await DutyScanner.channel.invokeMethod<bool>('sharePacket', {
            'path': file.path,
          });
          message =
              'PDF siap dibagikan. Pilih penerima dan kirim melalui WhatsApp.';
        }
      }
    } catch (e) {
      if (!cancelled) message = scanError(e);
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      await dialog;
      progress.dispose();
      _controller.setBusy(false);
    }
    if (mounted && message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = context.watch<DutyProvider>().byId(widget.id);
    return AnimatedBuilder(
      animation: _controller,
      builder:
          (context, _) => PopScope(
            canPop: !_controller.busy,
            child: Scaffold(
              appBar: AppBar(title: const Text('Berkas Dinas')),
              body:
                  entry == null
                      ? const Center(child: Text('Surat tidak ditemukan.'))
                      : entry.isDraft
                      ? const Center(
                        child: Text('Simpan surat dinas terlebih dahulu.'),
                      )
                      : !_controller.loaded
                      ? Center(
                        child:
                            _controller.error == null
                                ? const CircularProgressIndicator()
                                : TextButton(
                                  onPressed: _controller.load,
                                  child: const Text('Muat ulang berkas'),
                                ),
                      )
                      : ListView(
                        padding: const EdgeInsets.all(18),
                        children: [
                          NeumorphicCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.origin} → ${entry.destination}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(dutyRange(entry)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          NeumorphicCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _controller.availableTypes == 4
                                      ? 'Semua dokumen tersedia'
                                      : '${_controller.availableTypes} dari 4 dokumen tersedia',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                LinearProgressIndicator(
                                  value: _controller.availableTypes / 4,
                                  color:
                                      _controller.availableTypes == 4
                                          ? AppColors.success
                                          : AppColors.primary,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  '${_controller.pages.length} halaman tersimpan',
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Bisa dibagikan bertahap. Dokumen lainnya dapat ditambahkan nanti.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Dokumen perjalanan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text('Scan terpisah untuk setiap dokumen'),
                          const SizedBox(height: 14),
                          for (final type in DutyDocumentType.values)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: NeumorphicCard(
                                onTap:
                                    _controller.busy
                                        ? null
                                        : () => Navigator.push<void>(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => DutyDocumentPage(
                                                  controller: _controller,
                                                  type: type,
                                                  trip:
                                                      '${entry.origin} → ${entry.destination}',
                                                ),
                                          ),
                                        ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 17,
                                      child: Text('${type.index + 1}'),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 42,
                                      height: 62,
                                      child:
                                          _controller.ofType(type).isEmpty
                                              ? const Icon(
                                                Icons.document_scanner_outlined,
                                                color: AppColors.primary,
                                              )
                                              : ScanThumbnail(
                                                page:
                                                    _controller
                                                        .ofType(type)
                                                        .first,
                                                controller: _controller,
                                              ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            type.label,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            _controller.ofType(type).isEmpty
                                                ? 'Belum ditambahkan'
                                                : '${_controller.ofType(type).length} halaman • tersimpan',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  _controller
                                                          .ofType(type)
                                                          .isEmpty
                                                      ? AppColors.textSecondary
                                                      : AppColors.success,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            _controller.ofType(type).isEmpty
                                                ? 'Scan ${type.label}'
                                                : 'Lihat / kelola',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            ),
                          const DutySection(
                            title: 'Urutan PDF otomatis',
                            children: [
                              Text(
                                'SPPD → SPD → Deklarasi → Invoice',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Hanya dokumen yang tersedia yang digabung. Hasil scan tetap tersimpan terpisah.',
                              ),
                            ],
                          ),
                        ],
                      ),
              bottomNavigationBar:
                  entry == null || entry.isDraft
                      ? null
                      : SafeArea(
                        minimum: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton.icon(
                              key: const ValueKey('share-duty-packet'),
                              onPressed:
                                  _controller.canShare
                                      ? () => _share(entry)
                                      : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.success,
                              ),
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Bagikan via WhatsApp'),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _controller.pages.isEmpty
                                  ? 'Scan minimal satu halaman untuk dibagikan.'
                                  : 'Anda memilih sendiri kontak atau grup penerima.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
            ),
          ),
    );
  }
}
