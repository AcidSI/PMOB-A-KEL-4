import 'dart:async';

import 'package:flutter/material.dart';

import '../models/claim.dart';
import '../models/item.dart';
import '../models/match.dart';
import '../services/app_session.dart';
import '../services/matching_service.dart';
import 'claim_screens.dart';

class MatchingScreen extends StatefulWidget {
  final MatchingService service;

  const MatchingScreen({super.key, required this.service});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  String get _userId => AppSession.userId ?? '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    widget.service.refreshMatches();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      widget.service.refreshMatches();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _openClaim(Claim claim) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            ClaimReviewScreen(service: widget.service, claimId: claim.id),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openMatch(ItemMatch match) async {
    Claim? existingClaim;
    for (final claim in widget.service.claims) {
      if (claim.matchId == match.id &&
          claim.claimantId == _userId &&
          claim.status != ClaimStatus.cancelled) {
        existingClaim = claim;
        break;
      }
    }
    if (existingClaim != null) {
      await _openClaim(existingClaim);
      return;
    }

    widget.service.markViewed(match.id);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            ClaimSubmissionScreen(service: widget.service, matchId: match.id),
      ),
    );
    if (mounted) setState(() {});
  }

  void _dismiss(ItemMatch match) {
    try {
      widget.service.dismissMatch(match.id, _userId);
      setState(() {});
    } on StateError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Matching & Klaim'),
          actions: [
            IconButton(
              tooltip: 'Perbarui kecocokan',
              onPressed: () {
                widget.service.refreshMatches();
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Kecocokan'),
              Tab(text: 'Klaim masuk'),
              Tab(text: 'Notifikasi'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMatches(),
            _buildIncomingClaims(),
            _buildNotifications(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatches() {
    final matches = widget.service.visibleMatches;
    if (matches.isEmpty) {
      return const _EmptySection(
        icon: Icons.search_off,
        message:
            'Belum ada potensi kecocokan. Hasil baru dihitung saat laporan '
            'dibuat atau diperbarui.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        widget.service.refreshMatches();
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoBanner(
            icon: Icons.info_outline,
            message:
                'Kecocokan adalah kandidat, bukan bukti kepemilikan. '
                'Verifikasi tetap dilakukan oleh pemilik laporan.',
          ),
          const SizedBox(height: 12),
          for (final match in matches) _matchCard(match),
        ],
      ),
    );
  }

  Widget _matchCard(ItemMatch match) {
    final lost = widget.service.itemById(match.lostItemId);
    final found = widget.service.itemById(match.foundItemId);
    if (lost == null || found == null) return const SizedBox.shrink();
    final canDismiss = lost.ownerId == _userId || found.ownerId == _userId;
    final ownClaim = widget.service.claims.where(
      (claim) =>
          claim.matchId == match.id &&
          claim.claimantId == _userId &&
          claim.status != ClaimStatus.cancelled,
    );
    final hasOwnClaim = ownClaim.isNotEmpty;
    final isClaimed = match.status == MatchStatus.claimed;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${match.score.toStringAsFixed(0)}% cocok',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: match.score >= MatchingService.highMatchThreshold
                          ? const Color(0xFF045436)
                          : const Color(0xFFB45309),
                    ),
                  ),
                ),
                if (match.score >= MatchingService.highMatchThreshold)
                  const Chip(label: Text('Kecocokan tinggi')),
              ],
            ),
            Text('Hilang: ${lost.nameItem} · ${lost.location}'),
            const SizedBox(height: 4),
            Text('Ditemukan: ${found.nameItem} · ${found.location}'),
            const SizedBox(height: 12),
            _ScoreBar(label: 'Teks', score: match.textScore),
            _ScoreBar(label: 'Lokasi', score: match.locationScore),
            _ScoreBar(label: 'Waktu', score: match.timeScore),
            Text(
              'Pengali kategori ×${match.categoryMultiplier.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilledButton.icon(
                  onPressed:
                      found.ownerId == _userId || isClaimed && !hasOwnClaim
                      ? null
                      : () => _openMatch(match),
                  icon: Icon(
                    hasOwnClaim
                        ? Icons.forum_outlined
                        : Icons.assignment_outlined,
                  ),
                  label: Text(
                    hasOwnClaim
                        ? 'Buka klaim'
                        : isClaimed
                        ? 'Klaim sedang ditinjau'
                        : 'Ajukan klaim',
                  ),
                ),
                if (match.status != MatchStatus.claimed && canDismiss)
                  OutlinedButton.icon(
                    onPressed: () => _dismiss(match),
                    icon: const Icon(Icons.close),
                    label: const Text('Abaikan'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingClaims() {
    final claims = widget.service.claimsForOwner(_userId);
    if (claims.isEmpty) {
      return const _EmptySection(
        icon: Icons.inbox_outlined,
        message: 'Belum ada klaim pada laporan milik Anda.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final claim in claims)
          Builder(
            builder: (context) {
              final item = widget.service.itemById(claim.foundItemId);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: Text(item?.nameItem ?? 'Laporan barang'),
                  subtitle: Text(_claimStatusLabel(claim)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openClaim(claim),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildNotifications() {
    final notifications = widget.service.notificationsFor(_userId);
    if (notifications.isEmpty) {
      return const _EmptySection(
        icon: Icons.notifications_none,
        message: 'Notifikasi kecocokan dan klaim akan muncul di sini.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final notification in notifications)
          Card(
            child: ListTile(
              leading: Icon(
                notification.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active_outlined,
                color: notification.isRead
                    ? Colors.grey
                    : Theme.of(context).colorScheme.primary,
              ),
              title: Text(notification.title),
              subtitle: Text(notification.message),
              onTap: () {
                widget.service.markNotificationRead(notification.id);
                setState(() {});
              },
            ),
          ),
      ],
    );
  }

  String _claimStatusLabel(Claim claim) {
    final found = widget.service.itemById(claim.foundItemId);
    if (claim.status == ClaimStatus.approved &&
        found?.status == ReportStatus.resolved) {
      return 'Selesai';
    }
    return switch (claim.status) {
      ClaimStatus.pending => 'Menunggu verifikasi',
      ClaimStatus.approved => 'Disetujui · menunggu serah terima',
      ClaimStatus.rejected => 'Ditolak',
      ClaimStatus.cancelled => 'Dibatalkan',
    };
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double score;

  const _ScoreBar({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 56, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${score.toStringAsFixed(0)}%',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InfoBanner({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3EE),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF045436)),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptySection({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: Colors.black38),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
