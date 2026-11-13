import 'package:flutter/material.dart';

import '../models/claim.dart';
import '../services/app_session.dart';
import '../services/matching_service.dart';

class ClaimSubmissionScreen extends StatefulWidget {
  final MatchingService service;
  final String matchId;

  const ClaimSubmissionScreen({
    super.key,
    required this.service,
    required this.matchId,
  });

  @override
  State<ClaimSubmissionScreen> createState() => _ClaimSubmissionScreenState();
}

class _ClaimSubmissionScreenState extends State<ClaimSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _answersController = TextEditingController();
  final _reasonController = TextEditingController();
  final _evidenceController = TextEditingController();
  final _whatsappController = TextEditingController();
  bool _shareContact = false;
  String? _errorMessage;

  @override
  void dispose() {
    _answersController.dispose();
    _reasonController.dispose();
    _evidenceController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      widget.service.submitClaim(
        matchId: widget.matchId,
        claimantId: AppSession.userId ?? '',
        emailVerified: AppSession.emailVerified,
        answers: _answersController.text,
        reason: _reasonController.text,
        evidence: _evidenceController.text,
        claimantWhatsapp: _whatsappController.text,
        claimantSharesContact: _shareContact,
      );
      Navigator.pop(context);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (error) {
      setState(() => _errorMessage = 'Klaim gagal dikirim: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.service.matchById(widget.matchId);
    final found = match == null
        ? null
        : widget.service.itemById(match.foundItemId);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Klaim')),
      body: found == null
          ? const Center(child: Text('Laporan tidak ditemukan.'))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    found.nameItem,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text('Ditemukan di ${found.location}'),
                  const SizedBox(height: 16),
                  const _NoticeCard(
                    text:
                        'Jangan menuliskan nomor identitas atau data sensitif. '
                        'Jawaban dan bukti menjadi jejak verifikasi dan tidak '
                        'dapat diedit atau dihapus setelah dikirim.',
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Jawaban detail pembeda rahasia',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 7),
                  TextFormField(
                    key: const Key('claim-answers'),
                    controller: _answersController,
                    minLines: 2,
                    maxLines: 4,
                    validator: (value) =>
                        found.verificationDetails.isNotEmpty &&
                            (value == null || value.trim().isEmpty)
                        ? 'Jawaban detail pembeda wajib diisi'
                        : null,
                    decoration: const InputDecoration(
                      hintText: 'Jelaskan ciri khusus yang tidak tercantum di laporan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Alasan kepemilikan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 7),
                  TextFormField(
                    key: const Key('claim-reason'),
                    controller: _reasonController,
                    minLines: 2,
                    maxLines: 4,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Alasan kepemilikan wajib diisi'
                        : null,
                    decoration: const InputDecoration(
                      hintText: 'Jelaskan mengapa barang ini milik Anda',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Bukti pendukung (opsional)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 7),
                  TextFormField(
                    key: const Key('claim-evidence'),
                    controller: _evidenceController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Jelaskan bukti yang dapat ditunjukkan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('claim-whatsapp'),
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp (opsional)',
                      helperText: 'Hanya dibuka jika klaim disetujui dan kedua pihak setuju.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _shareContact,
                    onChanged: (value) =>
                        setState(() => _shareContact = value ?? false),
                    title: const Text(
                      'Saya setuju membagikan nomor setelah disetujui',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      key: const Key('claim-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton(
                    key: const Key('submit-claim'),
                    onPressed: _submit,
                    child: const Text('Kirim Klaim'),
                  ),
                ],
              ),
            ),
    );
  }
}

class ClaimReviewScreen extends StatefulWidget {
  final MatchingService service;
  final String claimId;

  const ClaimReviewScreen({
    super.key,
    required this.service,
    required this.claimId,
  });

  @override
  State<ClaimReviewScreen> createState() => _ClaimReviewScreenState();
}

class _ClaimReviewScreenState extends State<ClaimReviewScreen> {
  final _commentController = TextEditingController();
  bool _ownerSharesContact = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _decide(bool approve) {
    try {
      widget.service.decideClaim(
        claimId: widget.claimId,
        ownerId: AppSession.userId ?? '',
        approve: approve,
        ownerSharesContact: _ownerSharesContact,
      );
      setState(() => _errorMessage = null);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  void _sendComment() {
    try {
      widget.service.addComment(
        claimId: widget.claimId,
        senderId: AppSession.userId ?? '',
        message: _commentController.text,
      );
      _commentController.clear();
      setState(() => _errorMessage = null);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  void _cancelClaim(Claim claim) {
    try {
      widget.service.cancelClaim(
        claimId: claim.id,
        claimantId: AppSession.userId ?? '',
      );
      setState(() => _errorMessage = null);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  void _confirmResolution(Claim claim) {
    try {
      widget.service.confirmResolution(
        claimId: claim.id,
        userId: AppSession.userId ?? '',
      );
      setState(() => _errorMessage = null);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final claim = widget.service.claimById(widget.claimId);
    final found = claim == null
        ? null
        : widget.service.itemById(claim.foundItemId);
    final match = claim == null
        ? null
        : widget.service.matchById(claim.matchId);
    final lost = match == null
        ? null
        : widget.service.itemById(match.lostItemId);
    if (claim == null || found == null || lost == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Klaim')),
        body: const Center(child: Text('Klaim tidak ditemukan.')),
      );
    }
    final userId = AppSession.userId ?? '';
    final isOwner = userId == found.ownerId;
    final isClaimant = userId == claim.claimantId;
    final canDiscuss = isOwner || isClaimant;
    final contactReleased =
        claim.status == ClaimStatus.approved &&
        claim.ownerSharesContact &&
        claim.claimantSharesContact;
    final bothConfirmed =
        claim.claimantConfirmedResolution && claim.ownerConfirmedResolution;

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Klaim')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(found.nameItem, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Pasangan laporan hilang: ${lost.nameItem}'),
          const SizedBox(height: 10),
          Chip(label: Text(_statusLabel(claim.status))),
          if (claim.status == ClaimStatus.pending && isOwner) ...[
            const SizedBox(height: 8),
            const _NoticeCard(
              text:
                  'Detail pembeda tersimpan privat dan hanya ditampilkan '
                  'kepada pemilik laporan saat verifikasi klaim.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Detail pembeda rahasia milik laporan:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            for (final detail in found.verificationDetails)
              ListTile(
                dense: true,
                leading: const Icon(Icons.lock_outline),
                title: Text(detail),
              ),
          ],
          _DataSection(
            title: 'Jawaban pengklaim',
            value: claim.answers.isEmpty ? 'Tidak diisi' : claim.answers,
          ),
          _DataSection(title: 'Alasan kepemilikan', value: claim.reason),
          _DataSection(
            title: 'Bukti pendukung',
            value: claim.evidence.isEmpty
                ? 'Tidak ada bukti tambahan'
                : claim.evidence,
          ),
          const SizedBox(height: 8),
          const _NoticeCard(
            text:
                'Temui pihak lain di area kampus yang ramai. Untuk HP, dompet, '
                'dan dokumen, pertimbangkan penitipan di pos keamanan agar '
                'petugas dapat membantu verifikasi identitas.',
          ),
          if (claim.status == ClaimStatus.pending && isOwner) ...[
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _ownerSharesContact,
              onChanged: (value) =>
                  setState(() => _ownerSharesContact = value ?? false),
              title: const Text(
                'Saya setuju membagikan WhatsApp setelah disetujui',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decide(false),
                    child: const Text('Tolak klaim'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _decide(true),
                    child: const Text('Setujui klaim'),
                  ),
                ),
              ],
            ),
          ],
          if (claim.status == ClaimStatus.pending && isClaimant)
            OutlinedButton(
              onPressed: () => _cancelClaim(claim),
              child: const Text('Batalkan klaim'),
            ),
          if (claim.status == ClaimStatus.approved) ...[
            const SizedBox(height: 12),
            _ContactPanel(
              showContacts: contactReleased,
              ownerWhatsapp: found.whatsapp,
              claimantWhatsapp: claim.claimantWhatsapp,
              ownerAgreed: claim.ownerSharesContact,
              claimantAgreed: claim.claimantSharesContact,
            ),
            const SizedBox(height: 12),
            Text(
              bothConfirmed
                  ? 'Serah terima telah dikonfirmasi kedua pihak. Laporan selesai.'
                  : 'Konfirmasi hanya setelah barang benar-benar diserahkan. '
                        'Status selesai setelah kedua pihak mengonfirmasi.',
            ),
            const SizedBox(height: 8),
            if ((isClaimant && !claim.claimantConfirmedResolution) ||
                (isOwner && !claim.ownerConfirmedResolution))
              FilledButton.icon(
                onPressed: () => _confirmResolution(claim),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Konfirmasi barang diserahkan'),
              ),
            Text(
              'Konfirmasi pengklaim: '
              '${claim.claimantConfirmedResolution ? 'Ya' : 'Belum'} · '
              'pemilik: ${claim.ownerConfirmedResolution ? 'Ya' : 'Belum'}',
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const Divider(height: 30),
          Text(
            'Komentar verifikasi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (widget.service.commentsFor(claim.id).isEmpty)
            const Text('Belum ada komentar.')
          else
            for (final comment in widget.service.commentsFor(claim.id))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.person_outline, size: 18),
                ),
                title: Text(
                  comment.senderId == claim.claimantId
                      ? 'Pengklaim'
                      : 'Pemilik laporan',
                ),
                subtitle: Text(comment.message),
              ),
          if (canDiscuss &&
              claim.status != ClaimStatus.rejected &&
              claim.status != ClaimStatus.cancelled) ...[
            const SizedBox(height: 8),
            TextField(
              key: const Key('claim-comment'),
              controller: _commentController,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tulis pertanyaan atau kesepakatan titik temu',
                suffixIcon: IconButton(
                  tooltip: 'Kirim komentar',
                  onPressed: _sendComment,
                  icon: const Icon(Icons.send),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Komentar tidak dapat diedit atau dihapus setelah dikirim.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}

class _DataSection extends StatelessWidget {
  final String title;
  final String value;

  const _DataSection({required this.title, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value),
      ],
    ),
  );
}

class _ContactPanel extends StatelessWidget {
  final bool showContacts;
  final String? ownerWhatsapp;
  final String? claimantWhatsapp;
  final bool ownerAgreed;
  final bool claimantAgreed;

  const _ContactPanel({
    required this.showContacts,
    required this.ownerWhatsapp,
    required this.claimantWhatsapp,
    required this.ownerAgreed,
    required this.claimantAgreed,
  });

  @override
  Widget build(BuildContext context) {
    if (!ownerAgreed || !claimantAgreed) {
      return _NoticeCard(
        text:
            'Nomor WhatsApp belum dibuka karena persetujuan kedua pihak '
            'belum lengkap (pemilik: ${ownerAgreed ? 'setuju' : 'belum'}, '
            'pengklaim: ${claimantAgreed ? 'setuju' : 'belum'}).',
      );
    }
    if (!showContacts) {
      return const _NoticeCard(
        text: 'Kontak hanya tersedia setelah klaim disetujui.',
      );
    }
    return _NoticeCard(
      text:
          'Kontak telah disetujui kedua pihak.\n'
          'WhatsApp pemilik: ${ownerWhatsapp ?? 'Belum ditambahkan'}\n'
          'WhatsApp pengklaim: ${claimantWhatsapp ?? 'Belum ditambahkan'}',
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final String text;

  const _NoticeCard({required this.text});

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
        const Icon(Icons.info_outline, size: 20, color: Color(0xFF045436)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

String _statusLabel(ClaimStatus status) => switch (status) {
  ClaimStatus.pending => 'Menunggu keputusan pemilik',
  ClaimStatus.approved => 'Disetujui · serah terima',
  ClaimStatus.rejected => 'Ditolak',
  ClaimStatus.cancelled => 'Dibatalkan',
};
