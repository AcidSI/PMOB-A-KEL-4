import 'package:flutter/material.dart';

import '../models/item.dart';

// Artwork dan badge status dipakai konsisten di kartu serta halaman detail.
class ItemArtwork extends StatelessWidget {
  final Item item;
  final double size;
  const ItemArtwork({super.key, required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.id) {
      '1' => (Icons.headphones, const Color(0xFFB9D3E4)),
      '2' => (Icons.local_drink, const Color(0xFF9CC96D)),
      _ => (Icons.account_balance_wallet, const Color(0xFFB8895B)),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: size * 0.58),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 9),
      ),
    );
  }
}