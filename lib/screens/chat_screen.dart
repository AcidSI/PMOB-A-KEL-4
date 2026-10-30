import 'package:flutter/material.dart';

import '../models/item.dart';

class ChatScreen extends StatelessWidget {
  final Item item;

  const ChatScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Pelapor')),
      body: Center(
        child: Text('Chat untuk laporan ${item.nameItem}'),
      ),
    );
  }
}
