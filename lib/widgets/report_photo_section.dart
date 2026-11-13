import 'package:flutter/material.dart';

import 'package:find_it/domain/report_rules.dart';
import 'package:find_it/models/report_photo_entry.dart';
import 'package:find_it/widgets/report/report_theme.dart';

/// Grid foto laporan: maksimal 3 foto + petak tambah (kamera/galeri),
/// tombol hapus, dan tombol samarkan per foto.
///
/// [dark] dipakai untuk laporan Found (kartu hijau tua di atas form).
/// [statusText] menampilkan hasil cek foto kamera, mis. "Diambil 2 menit
/// lalu · 40 m dari titik laporan".
class ReportPhotoSection extends StatelessWidget {
  const ReportPhotoSection({
    super.key,
    required this.photos,
    required this.isFound,
    required this.isBusy,
    required this.onAdd,
    required this.onRemove,
    required this.onBlur,
    this.onAddFromGallery,
    this.dark = false,
    this.statusText,
  });

  final List<ReportPhotoEntry> photos;
  final bool isFound;
  final bool isBusy;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onBlur;

  /// Cadangan galeri untuk laporan Found (kamera tidak tersedia / barang
  /// sudah dititipkan). Null = tautan tidak ditampilkan.
  final VoidCallback? onAddFromGallery;
  final bool dark;
  final String? statusText;

  Color get _muted => dark ? ReportColors.onDeepMuted : ReportColors.muted;

  @override
  Widget build(BuildContext context) {
    final canAdd = photos.length < ReportRules.maxPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < photos.length; i++) _thumbnail(i),
            if (canAdd) _addTile(),
          ],
        ),
        if (statusText != null) ...[
          const SizedBox(height: 10),
          Container(
            key: const Key('report-photo-status'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: dark ? ReportColors.greenDeepField : ReportColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: dark ? ReportColors.limeText : ReportColors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? const Color(0xFFD6EFDB) : ReportColors.body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          isFound
              ? 'Wajib minimal 1 foto langsung dari kamera, maks. '
                    '${ReportRules.maxPhotos}. Metadata lokasi dihapus otomatis.'
              : 'Opsional, maks. ${ReportRules.maxPhotos} foto. Metadata '
                    'lokasi foto dihapus otomatis.',
          style: TextStyle(fontSize: 12, color: _muted),
        ),
        if (isFound && canAdd && onAddFromGallery != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('report-photo-gallery-fallback'),
              onPressed: isBusy ? null : onAddFromGallery,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: const Text('Pakai foto dari galeri'),
              style: TextButton.styleFrom(
                foregroundColor: dark
                    ? ReportColors.limeText
                    : ReportColors.green,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  Widget _addTile() {
    final color = dark ? Colors.white : ReportColors.green;
    return Material(
      color: dark ? ReportColors.greenDeepField : ReportColors.surfaceSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: dark ? ReportColors.lime : ReportColors.green,
          width: 1.5,
        ),
      ),
      child: InkWell(
        key: const Key('report-photo-add'),
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onTap: isBusy ? null : onAdd,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBusy)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(
                isFound ? Icons.photo_camera_outlined : Icons.image_outlined,
                color: color,
              ),
            const SizedBox(height: 6),
            Text(
              isBusy
                  ? 'Memproses'
                  : isFound
                  ? 'Kamera'
                  : 'Galeri',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(int index) {
    final photo = photos[index];
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(photo.bytes, fit: BoxFit.cover),
          if (photo.isUnverified)
            const Positioned(
              top: 6,
              left: 6,
              child: _Badge(label: 'Galeri', color: Color(0xFFB45309)),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: _roundButton(
              key: Key('photo-remove-$index'),
              icon: Icons.close,
              tooltip: 'Hapus foto',
              onTap: isBusy ? null : () => onRemove(index),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Material(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                key: Key('photo-blur-$index'),
                borderRadius: BorderRadius.circular(999),
                onTap: isBusy ? null : () => onBlur(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        photo.blurred ? Icons.check : Icons.blur_on,
                        size: 12,
                        color: ReportColors.green,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        photo.blurred ? 'Diblur' : 'Samarkan',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ReportColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        key: key,
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
