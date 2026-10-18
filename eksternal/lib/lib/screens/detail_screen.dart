import 'package:flutter/material.dart';

import '../models/item.dart';
import '../routes/app_routes.dart';
import '../widgets/item_visuals.dart';

class DetailScreen extends StatefulWidget {
  final Item item;
  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Future<void> _deleteReport() async {
    try {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Hapus laporan?'),
          content: const Text('Laporan ini akan dihapus dari daftar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );
      if (!mounted || shouldDelete != true) return;
      Navigator.pop<String>(context, widget.item.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Laporan gagal dihapus: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final statusColor = item.isFound
        ? const Color(0xFF045436)
        : const Color(0xFFEF4444);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Detail Item',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Center(
            child: ItemArtwork(item: item, size: 277),
          ),
          const SizedBox(height: 28),
          Text(
            item.nameItem,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Text(
            item.subtitle,
            style: const TextStyle(color: Color(0xFF595858), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(color: Color(0xFF045436), fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.location,
                  style: const TextStyle(color: Color(0xFF045436), fontSize: 12),
                ),
              ),
              StatusPill(
                label: item.isFound ? 'Ditemukan' : 'Kehilangan',
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            item.description,
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(
            'Waktu kejadian: ${item.eventDateLabel}',
            style: const TextStyle(
              color: Color(0x99595858),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Divider(height: 32),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed<void>(
              context,
              AppRoutes.chat,
              arguments: item,
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Chat Pelapor'),
          ),
          if (item.isOwner) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _deleteReport,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus Laporan'),
            ),
          ],
        ],
      ),
    );
  }
}