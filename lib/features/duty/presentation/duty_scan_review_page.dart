import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lembur/features/duty/data/duty_scanner.dart';
import 'package:lembur/features/duty/presentation/duty_crop_page.dart';

class DutyScanReviewPage extends StatefulWidget {
  const DutyScanReviewPage({
    super.key,
    required this.images,
    required this.label,
    required this.save,
    this.replacingPage,
  });
  final List<Uint8List> images;
  final String label;
  final int? replacingPage;
  final Future<void> Function(List<Uint8List>) save;
  @override
  State<DutyScanReviewPage> createState() => _DutyScanReviewPageState();
}

class _DutyScanReviewPageState extends State<DutyScanReviewPage> {
  late final List<Uint8List> _images = List.of(widget.images);
  int _current = 0;
  bool _busy = false;
  String? _error;
  Future<void> _crop() async {
    final edited = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder:
            (_) => DutyCropPage(
              bytes: _images[_current],
              label: '${widget.label} • Halaman ${_current + 1}',
            ),
      ),
    );
    if (edited != null && mounted) setState(() => _images[_current] = edited);
  }

  Future<void> _rescan() async {
    setState(() => _busy = true);
    try {
      final images = await DutyScanner().scan(limit: 1);
      if (images != null && mounted) {
        setState(() => _images[_current] = images.single);
      }
    } catch (e) {
      if (mounted) setState(() => _error = scanError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(bool next) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.save(List.unmodifiable(_images));
      if (mounted) {
        setState(() => _allowPop = true);
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.pop(context, next);
      }
    } catch (e) {
      if (mounted) setState(() => _error = scanError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _discard() async =>
      await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Batalkan hasil scan ini?'),
              content: const Text(
                'Hasil scan baru belum disimpan. Halaman yang sebelumnya tersimpan tetap tersedia.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Lanjutkan'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Batalkan scan'),
                ),
              ],
            ),
      ) ??
      false;
  bool _allowPop = false;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop || _busy) return;
      if (await _discard() && mounted) {
        setState(() => _allowPop = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.replacingPage == null
              ? 'Periksa Hasil Scan'
              : 'Ganti Halaman ${widget.replacingPage}',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${widget.label} • Halaman ${_current + 1} dari ${_images.length}\n${widget.replacingPage == null ? 'Periksa potongan dan keterbacaan dokumen.' : 'Halaman lama tetap tersimpan sampai pengganti disimpan.'}',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: PageView.builder(
              itemCount: _images.length,
              onPageChanged: (v) => setState(() => _current = v),
              itemBuilder:
                  (_, index) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: InteractiveViewer(
                      key: ValueKey(_images[index]),
                      minScale: 1,
                      maxScale: 5,
                      child: Image.memory(_images[index], fit: BoxFit.contain),
                    ),
                  ),
            ),
          ),
          if (_images.length > 1)
            const Text('Geser untuk memeriksa halaman berikutnya'),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _crop,
                    icon: const Icon(Icons.crop),
                    label: const Text('Ubah potongan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _rescan,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Scan ulang'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : () => _save(false),
              icon: const Icon(Icons.save_outlined),
              label: Text(
                _busy
                    ? 'Menyimpan…'
                    : widget.replacingPage == null
                    ? 'Simpan ke ${widget.label}'
                    : 'Simpan pengganti halaman ${widget.replacingPage}',
              ),
            ),
            if (widget.replacingPage == null)
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _save(true),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Simpan & scan berikutnya'),
              ),
          ],
        ),
      ),
    ),
  );
}
