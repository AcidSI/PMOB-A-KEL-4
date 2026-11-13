import 'package:flutter/material.dart';

import 'package:find_it/features/report/models/report.dart';

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

Color reportStatusColor(ReportStatus status) {
  return switch (status) {
    ReportStatus.active => const Color(0xFF0A5934),
    ReportStatus.inVerification => const Color(0xFFF8A10A),
    ReportStatus.resolved => const Color(0xFF2563EB),
    ReportStatus.expired => const Color(0xFF64748B),
    ReportStatus.removed => const Color(0xFFB3261E),
  };
}
