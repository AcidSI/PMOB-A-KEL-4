import 'package:flutter/material.dart';

import 'package:find_it/models/item.dart' as map;

// Artwork dan badge status dipakai konsisten di kartu serta halaman detail.
class LegacyItemArtwork extends StatelessWidget {
  final map.Item item;
  final double size;

  const LegacyItemArtwork({super.key, required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: item.imageData != null
          ? Image.memory(item.imageData!, fit: BoxFit.cover)
          : item.assetPath != null
          ? Image.asset(item.assetPath!, fit: BoxFit.cover)
          : Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: const Color(0xFF94A3B8),
                size: size * 0.38,
              ),
            ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final BorderRadius borderRadius;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 9),
      ),
    );
  }
}

Color legacyReportStatusColor(map.ReportStatus status) {
  return switch (status) {
    map.ReportStatus.active => const Color(0xFF0A5934),
    map.ReportStatus.inVerification => const Color(0xFFF8A10A),
    map.ReportStatus.resolved => const Color(0xFF2563EB),
    map.ReportStatus.expired => const Color(0xFF64748B),
    map.ReportStatus.removed => const Color(0xFFB3261E),
  };
}

