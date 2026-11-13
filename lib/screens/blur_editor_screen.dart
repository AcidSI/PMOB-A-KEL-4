import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:find_it/services/image_processor.dart';

/// Menggambar ulang [image] pada [canvas] (ukuran asli gambar) lalu mengaburkan
/// setiap area di [rects] (koordinat piksel gambar).
void paintImageWithBlur(Canvas canvas, ui.Image image, List<Rect> rects) {
  canvas.drawImage(image, Offset.zero, Paint());
  final sigma = math.max(image.width, image.height) / 25.0;
  for (final rect in rects) {
    canvas.save();
    canvas.clipRect(rect);
    canvas.saveLayer(
      rect,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.clamp,
        ),
    );
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.restore();
    canvas.restore();
  }
}

/// Alat blur manual untuk menyamarkan data sensitif pada foto (FR-R07).
/// Pengguna menggeser jari untuk menandai kotak area; hasilnya dikembalikan
/// sebagai JPEG ≤ 2 MB lewat `Navigator.pop`. File asli tidak disimpan.
class BlurEditorScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const BlurEditorScreen({super.key, required this.imageBytes});

  @override
  State<BlurEditorScreen> createState() => _BlurEditorScreenState();
}

class _BlurEditorScreenState extends State<BlurEditorScreen> {
  ui.Image? _image;
  final List<Rect> _rects = []; // koordinat piksel gambar
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Foto tidak dapat dibuka: $error');
    }
  }

  // Tata letak gambar di dalam area layar (BoxFit.contain).
  ({Offset offset, double scale}) _layout(Size area, ui.Image image) {
    final scale = math.min(area.width / image.width, area.height / image.height);
    final shown = Size(image.width * scale, image.height * scale);
    return (
      offset: Offset((area.width - shown.width) / 2, (area.height - shown.height) / 2),
      scale: scale,
    );
  }

  Offset _toImage(Offset local, Size area, ui.Image image) {
    final layout = _layout(area, image);
    final point = (local - layout.offset) / layout.scale;
    return Offset(
      point.dx.clamp(0, image.width.toDouble()).toDouble(),
      point.dy.clamp(0, image.height.toDouble()).toDouble(),
    );
  }

  Rect? get _draftRect {
    final start = _dragStart;
    final current = _dragCurrent;
    if (start == null || current == null) return null;
    return Rect.fromPoints(start, current);
  }

  Future<void> _apply() async {
    final image = _image;
    if (image == null || _saving) return;
    if (_rects.isEmpty) {
      Navigator.pop(context); // tidak ada perubahan
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      paintImageWithBlur(canvas, image, _rects);
      final rendered = await recorder.endRecording().toImage(
        image.width,
        image.height,
      );
      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      rendered.dispose();
      if (data == null) throw StateError('Gagal membuat gambar.');
      final jpeg = await ImageProcessor.compressToLimit(
        data.buffer.asUint8List(),
        force: true,
      );
      if (!mounted) return;
      Navigator.pop<Uint8List>(context, jpeg);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Gagal menerapkan blur: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Samarkan Data Sensitif'),
        actions: [
          IconButton(
            tooltip: 'Urungkan',
            onPressed: _rects.isEmpty || _saving
                ? null
                : () => setState(_rects.removeLast),
            icon: const Icon(Icons.undo),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: image == null
                ? Center(
                    child: _error == null
                        ? const CircularProgressIndicator()
                        : Text(
                            _error!,
                            style: const TextStyle(color: Colors.white),
                          ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final area = constraints.biggest;
                      return GestureDetector(
                        key: const Key('blur-canvas'),
                        behavior: HitTestBehavior.opaque,
                        onPanStart: _saving
                            ? null
                            : (details) => setState(() {
                                  _dragStart = _toImage(
                                    details.localPosition,
                                    area,
                                    image,
                                  );
                                  _dragCurrent = _dragStart;
                                }),
                        onPanUpdate: _saving
                            ? null
                            : (details) => setState(() {
                                  _dragCurrent = _toImage(
                                    details.localPosition,
                                    area,
                                    image,
                                  );
                                }),
                        onPanEnd: _saving
                            ? null
                            : (_) => setState(() {
                                  final rect = _draftRect;
                                  if (rect != null &&
                                      rect.width > 8 &&
                                      rect.height > 8) {
                                    _rects.add(rect);
                                  }
                                  _dragStart = null;
                                  _dragCurrent = null;
                                }),
                        child: CustomPaint(
                          size: area,
                          painter: _BlurPreviewPainter(
                            image: image,
                            rects: List.of(_rects),
                            draft: _draftRect,
                            layout: _layout(area, image),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Geser jari pada foto untuk menandai nama, nomor kartu, '
                    'atau data pribadi yang harus disamarkan.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF63777B)),
                  ),
                  if (_error != null && image != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('blur-apply'),
                    onPressed: image == null || _saving ? null : _apply,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _rects.isEmpty
                                ? 'Selesai tanpa blur'
                                : 'Terapkan blur (${_rects.length} area)',
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurPreviewPainter extends CustomPainter {
  _BlurPreviewPainter({
    required this.image,
    required this.rects,
    required this.draft,
    required this.layout,
  });

  final ui.Image image;
  final List<Rect> rects;
  final Rect? draft;
  final ({Offset offset, double scale}) layout;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(layout.offset.dx, layout.offset.dy);
    canvas.scale(layout.scale);
    paintImageWithBlur(canvas, image, rects);
    final rect = draft;
    if (rect != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0x5511796F)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0xFF0A5934)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / layout.scale,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BlurPreviewPainter oldDelegate) => true;
}
