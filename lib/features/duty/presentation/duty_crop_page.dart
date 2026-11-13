import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lembur/features/duty/data/duty_scanner.dart';

class DutyCropPage extends StatefulWidget {
  const DutyCropPage({super.key, required this.bytes, required this.label});
  final Uint8List bytes;
  final String label;
  @override
  State<DutyCropPage> createState() => _DutyCropPageState();
}

class _DutyCropPageState extends State<DutyCropPage> {
  List<Offset> _points = [
    Offset.zero,
    const Offset(1, 0),
    const Offset(1, 1),
    const Offset(0, 1),
  ];
  Size? _size;
  int? _drag;
  int _rotation = 0;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _readSize();
  }

  Future<void> _readSize() async {
    try {
      final codec = await ui.instantiateImageCodec(
        widget.bytes,
        targetWidth: 1200,
      );
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      codec.dispose();
      if (mounted) setState(() => _size = size);
    } catch (e) {
      if (mounted) setState(() => _error = scanError(e));
    }
  }

  Future<void> _apply() async {
    setState(() => _busy = true);
    try {
      final bytes = await DutyScanner().crop(
        widget.bytes,
        _points.expand((p) => [p.dx, p.dy]).toList(),
        _rotation,
      );
      if (mounted) {
        setState(() => _busy = false);
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.pop(context, bytes);
      }
    } catch (e) {
      if (mounted) setState(() => _error = scanError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Sesuaikan Potongan'),
        actions: [
          TextButton(
            onPressed:
                _busy
                    ? null
                    : () => setState(() {
                      _points = [
                        Offset.zero,
                        const Offset(1, 0),
                        const Offset(1, 1),
                        const Offset(0, 1),
                      ];
                      _rotation = 0;
                    }),
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${widget.label}\nGeser titik sudut mengikuti tepi kertas.',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child:
                _size == null
                    ? Center(
                      child:
                          _error == null
                              ? const CircularProgressIndicator()
                              : Text(_error!),
                    )
                    : Padding(
                      padding: const EdgeInsets.all(24),
                      child: RotatedBox(
                        quarterTurns: _rotation,
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final fitted =
                                applyBoxFit(
                                  BoxFit.contain,
                                  _size!,
                                  box.biggest,
                                ).destination;
                            return Center(
                              child: SizedBox(
                                width: fitted.width,
                                height: fitted.height,
                                child: GestureDetector(
                                  onPanStart:
                                      _busy
                                          ? null
                                          : (d) {
                                            var distance = 48.0;
                                            _drag = null;
                                            for (var i = 0; i < 4; i++) {
                                              final point = Offset(
                                                _points[i].dx * fitted.width,
                                                _points[i].dy * fitted.height,
                                              );
                                              final delta =
                                                  (point - d.localPosition)
                                                      .distance;
                                              if (delta < distance) {
                                                distance = delta;
                                                _drag = i;
                                              }
                                            }
                                          },
                                  onPanUpdate:
                                      _busy
                                          ? null
                                          : (d) {
                                            if (_drag != null) {
                                              setState(
                                                () =>
                                                    _points[_drag!] = Offset(
                                                      (d.localPosition.dx /
                                                              fitted.width)
                                                          .clamp(0.0, 1.0),
                                                      (d.localPosition.dy /
                                                              fitted.height)
                                                          .clamp(0.0, 1.0),
                                                    ),
                                              );
                                            }
                                          },
                                  onPanEnd: (_) => _drag = null,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    clipBehavior: Clip.none,
                                    children: [
                                      Image.memory(
                                        widget.bytes,
                                        fit: BoxFit.contain,
                                        gaplessPlayback: true,
                                      ),
                                      CustomPaint(
                                        painter: _CropPainter(_points),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _busy
                            ? null
                            : () =>
                                setState(() => _rotation = (_rotation + 3) % 4),
                    icon: const Icon(Icons.rotate_left),
                    label: const Text('Putar kiri'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _busy
                            ? null
                            : () =>
                                setState(() => _rotation = (_rotation + 1) % 4),
                    icon: const Icon(Icons.rotate_right),
                    label: const Text('Putar kanan'),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _rotation == 0
                ? 'Dokumen akan diluruskan mengikuti empat sudut.'
                : 'Putaran setelah dipotong: ${_rotation * 90}°',
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _busy || _size == null ? null : _apply,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(_busy ? 'Menerapkan…' : 'Terapkan potongan'),
        ),
      ),
    ),
  );
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.corners);
  final List<Offset> corners;
  @override
  void paint(Canvas canvas, Size size) {
    final points =
        corners
            .map((p) => Offset(p.dx * size.width, p.dy * size.height))
            .toList();
    final polygon = Path()..addPolygon(points, true);
    final outside =
        Path()
          ..addRect(Offset.zero & size)
          ..addPath(polygon, Offset.zero)
          ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      outside,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );
    canvas.drawPath(
      polygon,
      Paint()
        ..color = const Color(0xFF2864DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    for (final point in points) {
      canvas.drawCircle(point, 11, Paint()..color = Colors.white);
      canvas.drawCircle(point, 8, Paint()..color = const Color(0xFF2864DC));
    }
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) => true;
}
