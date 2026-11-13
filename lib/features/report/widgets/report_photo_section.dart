import 'package:flutter/material.dart';

import 'package:find_it/features/report/domain/report_rules.dart';
import 'package:find_it/features/report/models/report_photo_entry.dart';

/// Bagian "Foto barang" pada form: tombol tambah (kamera/galeri), pratinjau
/// maksimal 3 foto, hapus, dan tombol samarkan data sensitif per foto.
class ReportPhotoSection extends StatelessWidget {
  const ReportPhotoSection({
    super.key,
    required this.photos,
    required this.isFound,
    required this.isBusy,
    required this.onAdd,
    required this.onRemove,
    required this.onBlur,
  });

  static const _green = Color(0xFF0A5934);
  static const _muted = Color(0xFF63777B);

  final List<ReportPhotoEntry> photos;
  final bool isFound;
  final bool isBusy;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onBlur;

  @override
  Widget build(BuildContext context) {
    final canAdd = photos.length < ReportRules.maxPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canAdd)
          CustomPaint(
            key: const Key('report-photo'),
            painter: _DashedBorderPainter(
              color: _green,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              height: 80,
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('report-photo-add'),
                onPressed: isBusy ? null : onAdd,
                icon: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isFound
                            ? Icons.photo_camera_outlined
                            : Icons.image_outlined,
                      ),
                label: Text(
                  isBusy
                      ? 'Memproses foto...'
                      : isFound
                      ? 'Ambil foto dengan kamera'
                      : 'Pilih dari galeri',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _green,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          isFound
              ? 'Foto wajib diambil langsung dengan kamera, maksimal '
                    '${ReportRules.maxPhotos} foto (${photos.length}/'
                    '${ReportRules.maxPhotos}).'
              : 'Pilih foto dari galeri, maksimal ${ReportRules.maxPhotos} foto '
                    '(${photos.length}/${ReportRules.maxPhotos}).',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _thumbnail(index),
            ),
          ),
        ],
      ],
    );
  }

  Widget _thumbnail(int index) {
    final photo = photos[index];
    return SizedBox(
      width: 150,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(photo.bytes, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: _circleButton(
              key: Key('photo-remove-$index'),
              icon: Icons.close,
              tooltip: 'Hapus foto',
              onPressed: isBusy ? null : () => onRemove(index),
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: FilledButton.tonalIcon(
              key: Key('photo-blur-$index'),
              onPressed: isBusy ? null : () => onBlur(index),
              icon: Icon(
                photo.blurred ? Icons.check_circle : Icons.blur_on,
                size: 16,
              ),
              label: Text(
                photo.blurred ? 'Sudah diblur' : 'Samarkan',
                style: const TextStyle(fontSize: 11),
              ),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.white.withValues(alpha: 0.92),
                foregroundColor: _green,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        key: key,
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.borderRadius});

  final Color color;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()..addRRect(borderRadius.toRRect(rect.deflate(1)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 7).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}
