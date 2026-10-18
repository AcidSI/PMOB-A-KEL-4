import 'package:flutter/material.dart';

// Fallback untuk route tak dikenal atau argumen detail yang salah tipe.
class NotFoundScreen extends StatelessWidget {
  final String? routeName;
  const NotFoundScreen({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Halaman Tidak Ditemukan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 64),
              const SizedBox(height: 8),
              Text('Route ${routeName ?? 'tidak dikenal'} tidak tersedia.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}