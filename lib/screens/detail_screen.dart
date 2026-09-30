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
  // Nilai non-null dari form dicatat setelah route mengembalikan hasil.
  String? _note;

  Future<void> _openNoteForm() async {
    final result = await Navigator.pushNamed<String>(
      context,
      AppRoutes.noteForm,
    );
    if (!mounted || result == null) return;
    setState(() => _note = result);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catatan berhasil disimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final statusColor = item.isFound
        ? const Color(0xFF059669)
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
            item.title,
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
            item.timeAgo,
            style: const TextStyle(
              color: Color(0x99595858),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Divider(height: 32),
          Text(_note == null ? 'Belum ada catatan.' : 'Catatan: $_note'),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _openNoteForm,
            icon: const Icon(Icons.edit_note),
            label: const Text('Tulis Catatan'),
          ),
        ],
      ),
    );
  }
}