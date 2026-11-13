import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/duty/data/duty_scanner.dart';
import 'package:lembur/features/duty/domain/duty_scan_page.dart';
import 'package:lembur/features/duty/presentation/duty_crop_page.dart';
import 'package:lembur/features/duty/presentation/duty_packet_controller.dart';
import 'package:lembur/features/duty/presentation/duty_scan_review_page.dart';

class DutyDocumentPage extends StatefulWidget {
  const DutyDocumentPage({
    super.key,
    required this.controller,
    required this.type,
    required this.trip,
  });
  final DutyPacketController controller;
  final DutyDocumentType type;
  final String trip;
  @override
  State<DutyDocumentPage> createState() => _DutyDocumentPageState();
}

class _DutyDocumentPageState extends State<DutyDocumentPage> {
  bool _working = false;
  void _error(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(scanError(e))));
    }
  }

  Future<void> _scan({DutyScanPage? replace, int? number}) async {
    setState(() => _working = true);
    try {
      var more = true;
      while (more && mounted) {
        final images = await DutyScanner().scan(
          limit: replace == null ? 10 : 1,
        );
        if (images == null || !mounted) break;
        final next = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder:
                (_) => DutyScanReviewPage(
                  images: images,
                  label: widget.type.label,
                  replacingPage: replace == null ? null : number,
                  save:
                      (values) =>
                          replace == null
                              ? widget.controller.add(widget.type, values)
                              : widget.controller.replace(
                                replace,
                                values.single,
                              ),
                ),
          ),
        );
        more = replace == null && next == true && widget.controller.loaded;
      }
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _crop(DutyScanPage page, int number) async {
    setState(() => _working = true);
    try {
      final source = await widget.controller.repository.image(
        page.id,
        original: true,
      );
      if (!mounted) return;
      final bytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder:
              (_) => DutyCropPage(
                bytes: source,
                label: '${widget.type.label} • Halaman $number',
              ),
        ),
      );
      if (bytes == null || !mounted) return;
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder:
              (_) => DutyScanReviewPage(
                images: [bytes],
                label: widget.type.label,
                replacingPage: number,
                save:
                    (values) => widget.controller.replace(
                      page,
                      values.single,
                      crop: true,
                    ),
              ),
        ),
      );
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _delete(DutyScanPage page, int number) async {
    final yes = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Hapus halaman $number?'),
            content: Text(
              'Hanya halaman $number pada ${widget.type.label} yang dihapus. Halaman lain tetap tersimpan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
    if (yes != true) return;
    try {
      await widget.controller.delete(page.id);
    } catch (e) {
      _error(e);
    }
  }

  Future<void> _view(DutyScanPage page, int number) async {
    try {
      final bytes = await widget.controller.repository.image(page.id);
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder:
              (_) => Scaffold(
                appBar: AppBar(
                  title: Text('${widget.type.label} • Halaman $number'),
                ),
                body: Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 6,
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
              ),
        ),
      );
    } catch (e) {
      _error(e);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final pages = widget.controller.ofType(widget.type);
      final busy = _working || widget.controller.busy;
      final unavailable = busy || !widget.controller.loaded;
      return PopScope(
        canPop: !busy,
        child: Scaffold(
          appBar: AppBar(title: Text(widget.type.label)),
          body: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: pages.length,
            header: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: NeumorphicCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.trip,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${pages.length} halaman tersimpan',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text('Urutkan halaman dengan geser pegangan.'),
                        if (widget.type == DutyDocumentType.sppd)
                          const Text(
                            'Gunakan scan SPPD yang sudah ditandatangani.',
                          ),
                      ],
                    ),
                  ),
                ),
                if (busy) const LinearProgressIndicator(),
                if (!widget.controller.loaded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        const Text(
                          'Daftar halaman belum dapat dimuat. Muat ulang sebelum melanjutkan.',
                        ),
                        TextButton(
                          onPressed: busy ? null : widget.controller.load,
                          child: const Text('Muat ulang'),
                        ),
                      ],
                    ),
                  ),
                if (pages.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Belum ada scan ${widget.type.label}.\nTekan Scan untuk menambahkan halaman.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onReorder: (oldIndex, newIndex) async {
              if (unavailable) return;
              if (newIndex > oldIndex) newIndex--;
              final ids = pages.map((p) => p.id).toList();
              ids.insert(newIndex, ids.removeAt(oldIndex));
              try {
                await widget.controller.reorder(widget.type, ids);
              } catch (e) {
                _error(e);
              }
            },
            itemBuilder: (context, i) {
              final page = pages[i];
              return Padding(
                key: ValueKey(page.id),
                padding: const EdgeInsets.only(bottom: 16),
                child: NeumorphicCard(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 92,
                            child: ScanThumbnail(
                              page: page,
                              controller: widget.controller,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halaman ${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Text(
                                  'Tersimpan di perangkat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed:
                                      unavailable
                                          ? null
                                          : () => _view(page, i + 1),
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: const Text('Lihat'),
                                ),
                              ],
                            ),
                          ),
                          ReorderableDragStartListener(
                            index: i,
                            enabled: !unavailable,
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.drag_indicator),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed:
                                unavailable ? null : () => _crop(page, i + 1),
                            icon: const Icon(Icons.crop),
                            label: const Text('Potong'),
                          ),
                          TextButton.icon(
                            onPressed:
                                unavailable
                                    ? null
                                    : () => _scan(replace: page, number: i + 1),
                            icon: const Icon(Icons.document_scanner_outlined),
                            label: const Text('Ganti'),
                          ),
                          TextButton.icon(
                            onPressed:
                                unavailable ? null : () => _delete(page, i + 1),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Hapus',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  key: const ValueKey('scan-document'),
                  onPressed: unavailable ? null : () => _scan(),
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: Text(
                    pages.isEmpty
                        ? 'Scan ${widget.type.label}'
                        : 'Scan halaman tambahan',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cukup ganti halaman yang salah. Halaman lain tetap tersimpan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pemakaian scan pertama memerlukan internet untuk menyiapkan pemindai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class ScanThumbnail extends StatefulWidget {
  const ScanThumbnail({
    super.key,
    required this.page,
    required this.controller,
  });
  final DutyScanPage page;
  final DutyPacketController controller;
  @override
  State<ScanThumbnail> createState() => _ScanThumbnailState();
}

class _ScanThumbnailState extends State<ScanThumbnail> {
  late Future<Uint8List> _image;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _image = widget.controller.repository.image(widget.page.id);
  }

  @override
  void didUpdateWidget(covariant ScanThumbnail old) {
    super.didUpdateWidget(old);
    if (old.page.id != widget.page.id ||
        old.page.updatedAt != widget.page.updatedAt) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _image,
    builder:
        (_, s) =>
            s.hasData
                ? Image.memory(
                  s.data!,
                  fit: BoxFit.contain,
                  cacheWidth: 180,
                  errorBuilder:
                      (_, _, _) => const Icon(Icons.broken_image_outlined),
                )
                : Icon(
                  s.hasError
                      ? Icons.broken_image_outlined
                      : Icons.description_outlined,
                ),
  );
}
