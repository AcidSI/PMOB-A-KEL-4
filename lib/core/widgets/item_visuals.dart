import 'package:flutter/material.dart';

import 'package:find_it/features/report/models/report.dart';

// Artwork dan badge status dipakai konsisten di kartu serta halaman detail.
class ItemArtwork extends StatelessWidget {
  final Item item;
  final double size;
  const ItemArtwork({super.key, required this.item, required this.size});

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
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  color: const Color(0xFF94A3B8),
                  size: size * 0.38,
                ),
                SizedBox(height: size * 0.04),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Belum ada foto',
                      style: TextStyle(
                        color: const Color(0xFF64748B),
                        fontSize: size < 100 ? 8 : 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

