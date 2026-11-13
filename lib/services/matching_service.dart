import 'dart:math' as math;

import '../models/claim.dart';
import '../models/item.dart';
import '../models/match.dart';

class MatchingService {
  MatchingService({required this.items});

  static const double notificationThreshold = 60;
  static const double highMatchThreshold = 80;
  static const int maxCandidatesPerReport = 5;
  static const int maxActiveClaims = 3;
  static const Duration claimSuspension = Duration(days: 7);
  static const List<String> categories = [
    'Dompet & Kartu',
    'Tas & Ransel',
    'Elektronik',
    'Kunci & Kendaraan',
    'Dokumen & Perlengkapan Kuliah',
    'Pakaian & Aksesori',
    'Botol & Perlengkapan Makan',
    'Perlengkapan Ibadah',
    'Perlengkapan Olahraga',
    'Lainnya',
  ];

  final List<Item> items;
  final List<ItemMatch> matches = [];
  final List<Claim> claims = [];
  final List<ClaimComment> comments = [];
  final List<ModuleNotification> notifications = [];
  final Map<String, DateTime> _suspendedUntil = {};
  int _nextId = 0;

  List<ItemMatch> get visibleMatches =>
      matches.where((match) => match.status != MatchStatus.dismissed).toList()
        ..sort((a, b) => b.score.compareTo(a.score));

  List<Claim> claimsForOwner(String ownerId) =>
      claims
          .where((claim) => _foundItem(claim.foundItemId)?.ownerId == ownerId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Claim> claimsForUser(String userId) =>
      claims.where((claim) => claim.claimantId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<ClaimComment> commentsFor(String claimId) =>
      comments.where((comment) => comment.claimId == claimId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<ModuleNotification> notificationsFor(String userId) =>
      notifications
          .where((notification) => notification.recipientId == userId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Item? itemById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  ItemMatch? matchById(String id) {
    for (final match in matches) {
      if (match.id == id) return match;
    }
    return null;
  }

  Claim? claimById(String id) {
    for (final claim in claims) {
      if (claim.id == id) return claim;
    }
    return null;
  }

  void addReport(Item item, {DateTime? now}) {
    if (items.any((existing) => existing.id == item.id)) {
      throw StateError('Laporan dengan ID yang sama sudah tersedia.');
    }
    items.insert(0, item);
    refreshMatches(now: now);
  }

  void refreshMatches({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final previous = {for (final match in matches) match.id: match};
    final candidates = <ItemMatch>[];
    final acceptedMatches = <ItemMatch>[];
    final candidateCounts = <String, int>{};

    final lostItems = items.where(
      (item) => !item.isFound && item.status == ReportStatus.active,
    );
    final foundItems = items.where(
      (item) => item.isFound && item.status == ReportStatus.active,
    );

    for (final lost in lostItems) {
      for (final found in foundItems) {
        if (lost.id == found.id) continue;
        final multiplier = _categoryMultiplier(lost, found);
        final lostDate = lost.eventDate;
        final foundDate = found.eventDate;
        if (multiplier == null || lostDate == null || foundDate == null) {
          continue;
        }
        if (foundDate.isBefore(lostDate.subtract(const Duration(days: 1)))) {
          continue;
        }

        final text = _textSimilarity(lost, found);
        final location = _locationScore(lost, found);
        final time = _timeScore(lostDate, foundDate);
        final score =
            ((text * .4) + (location * .35) + (time * .25)) * multiplier;
        if (score < notificationThreshold) continue;

        final id = '${lost.id}::${found.id}';
        final old = previous[id];
        final match = ItemMatch(
          id: id,
          lostItemId: lost.id,
          foundItemId: found.id,
          textScore: text,
          locationScore: location,
          timeScore: time,
          categoryMultiplier: multiplier,
          score: score.clamp(0, 100).toDouble(),
          status: old?.status ?? MatchStatus.suggested,
        );
        candidates.add(match);
      }
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    for (final match in candidates) {
      final lostCount = candidateCounts[match.lostItemId] ?? 0;
      final foundCount = candidateCounts[match.foundItemId] ?? 0;
      if (lostCount >= maxCandidatesPerReport ||
          foundCount >= maxCandidatesPerReport) {
        continue;
      }
      candidateCounts[match.lostItemId] = lostCount + 1;
      candidateCounts[match.foundItemId] = foundCount + 1;

      if (!previous.containsKey(match.id)) {
        _notifyMatchOwners(match, currentTime);
      }
      match.status = _statusForMatch(match, previous[match.id]);
      acceptedMatches.add(match);
    }
    for (final previousMatch in matches) {
      final hasOpenClaim = claims.any(
        (claim) =>
            claim.matchId == previousMatch.id &&
            (claim.status == ClaimStatus.pending ||
                claim.status == ClaimStatus.approved),
      );
      if (hasOpenClaim &&
          !acceptedMatches.any((match) => match.id == previousMatch.id)) {
        acceptedMatches.add(previousMatch);
      }
    }
    matches
      ..clear()
      ..addAll(acceptedMatches);
  }

  void markViewed(String matchId) {
    final match = matchById(matchId);
    if (match != null && match.status == MatchStatus.suggested) {
      match.status = MatchStatus.viewed;
    }
  }

  void dismissMatch(String matchId, String userId) {
    final match = matchById(matchId);
    if (match == null) throw StateError('Kecocokan tidak ditemukan.');
    if (!_isParticipant(match, userId)) {
      throw StateError('Anda tidak berhak mengabaikan kecocokan ini.');
    }
    if (match.status == MatchStatus.claimed) {
      throw StateError('Kecocokan dengan klaim aktif tidak dapat diabaikan.');
    }
    match.status = MatchStatus.dismissed;
  }

  Claim submitClaim({
    required String matchId,
    required String claimantId,
    required bool emailVerified,
    required String answers,
    required String reason,
    required String evidence,
    required String? claimantWhatsapp,
    required bool claimantSharesContact,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final match = matchById(matchId);
    if (match == null || match.status == MatchStatus.dismissed) {
      throw StateError('Kecocokan tidak tersedia untuk diklaim.');
    }
    final found = _foundItem(match.foundItemId);
    if (found == null || found.status != ReportStatus.active) {
      throw StateError('Laporan barang temuan tidak lagi aktif.');
    }
    final lost = itemById(match.lostItemId);
    if (lost == null || lost.status != ReportStatus.active) {
      throw StateError('Laporan kehilangan tidak lagi aktif untuk diklaim.');
    }
    if (found.ownerId == claimantId) {
      throw StateError('Anda tidak dapat mengklaim laporan milik sendiri.');
    }
    if (!emailVerified) {
      throw StateError(
        'Klaim hanya tersedia untuk email kampus terverifikasi.',
      );
    }
    final suspension = _suspendedUntil[claimantId];
    if (suspension != null && currentTime.isBefore(suspension)) {
      throw StateError(
        'Hak klaim ditangguhkan hingga ${_dateLabel(suspension)}.',
      );
    }
    final activeClaims = claims.where(
      (claim) =>
          claim.claimantId == claimantId &&
          (claim.status == ClaimStatus.pending ||
              claim.status == ClaimStatus.approved &&
                  _foundItem(claim.foundItemId)?.status !=
                      ReportStatus.resolved),
    );
    if (activeClaims.length >= maxActiveClaims) {
      throw StateError('Maksimal 3 klaim aktif dapat dimiliki sekaligus.');
    }
    final priorClaim = claims.any(
      (claim) =>
          claim.foundItemId == found.id &&
          claim.claimantId == claimantId &&
          claim.status != ClaimStatus.cancelled,
    );
    if (priorClaim) {
      throw StateError('Anda sudah pernah mengajukan klaim untuk laporan ini.');
    }
    if (found.verificationDetails.isNotEmpty && answers.trim().isEmpty) {
      throw StateError('Jawaban detail pembeda wajib diisi.');
    }
    if (reason.trim().isEmpty) {
      throw StateError('Alasan atau bukti kepemilikan wajib diisi.');
    }

    final claim = Claim(
      id: _id('claim'),
      matchId: matchId,
      foundItemId: found.id,
      claimantId: claimantId,
      answers: answers.trim(),
      reason: reason.trim(),
      evidence: evidence.trim(),
      claimantWhatsapp: _optional(claimantWhatsapp),
      claimantSharesContact: claimantSharesContact,
      createdAt: currentTime,
    );
    claims.add(claim);
    match.status = MatchStatus.claimed;
    found.status = ReportStatus.inVerification;
    lost.status = ReportStatus.inVerification;
    _addNotification(
      found.ownerId,
      'Klaim baru',
      'Ada klaim baru untuk ${found.nameItem}.',
      currentTime,
    );
    return claim;
  }

  ClaimComment addComment({
    required String claimId,
    required String senderId,
    required String message,
    DateTime? now,
  }) {
    final claim = claimById(claimId);
    if (claim == null) throw StateError('Klaim tidak ditemukan.');
    final found = _foundItem(claim.foundItemId);
    if (found == null ||
        (senderId != claim.claimantId && senderId != found.ownerId)) {
      throw StateError('Hanya pihak yang terlibat yang dapat berkomentar.');
    }
    if (claim.status == ClaimStatus.rejected ||
        claim.status == ClaimStatus.cancelled) {
      throw StateError('Komentar tidak dapat ditambahkan ke klaim tertutup.');
    }
    if (message.trim().isEmpty) {
      throw StateError('Komentar tidak boleh kosong.');
    }
    final comment = ClaimComment(
      id: _id('comment'),
      claimId: claimId,
      senderId: senderId,
      message: message.trim(),
      createdAt: now ?? DateTime.now(),
    );
    comments.add(comment);
    _addNotification(
      senderId == claim.claimantId ? found.ownerId : claim.claimantId,
      'Komentar klaim',
      'Ada komentar baru terkait ${found.nameItem}.',
      comment.createdAt,
    );
    return comment;
  }

  void decideClaim({
    required String claimId,
    required String ownerId,
    required bool approve,
    required bool ownerSharesContact,
    DateTime? now,
  }) {
    final claim = claimById(claimId);
    if (claim == null) throw StateError('Klaim tidak ditemukan.');
    final found = _foundItem(claim.foundItemId);
    if (found?.ownerId != ownerId) {
      throw StateError('Hanya pemilik laporan temuan yang dapat memutuskan.');
    }
    if (claim.status != ClaimStatus.pending) {
      throw StateError('Klaim ini sudah diputuskan.');
    }
    if (approve &&
        claims.any(
          (other) =>
              other.id != claim.id &&
              other.foundItemId == claim.foundItemId &&
              other.status == ClaimStatus.approved,
        )) {
      throw StateError('Laporan ini sudah memiliki klaim yang disetujui.');
    }
    final currentTime = now ?? DateTime.now();
    claim.status = approve ? ClaimStatus.approved : ClaimStatus.rejected;
    claim.decidedAt = currentTime;
    claim.ownerSharesContact = approve && ownerSharesContact;
    if (!approve) {
      final match = matchById(claim.matchId);
      if (match != null) match.status = MatchStatus.viewed;
      final recentRejections = claims.where(
        (entry) =>
            entry.claimantId == claim.claimantId &&
            entry.status == ClaimStatus.rejected &&
            entry.decidedAt != null &&
            !entry.decidedAt!.isBefore(
              currentTime.subtract(const Duration(days: 7)),
            ),
      );
      if (recentRejections.length >= 3) {
        _suspendedUntil[claim.claimantId] = currentTime.add(claimSuspension);
      }
      _restoreFoundStatusIfNoOpenClaims(found!);
    } else {
      _addNotification(
        claim.claimantId,
        'Klaim disetujui',
        'Pemilik menyetujui klaim ${found!.nameItem}.',
        currentTime,
      );
    }
  }

  void cancelClaim({
    required String claimId,
    required String claimantId,
    DateTime? now,
  }) {
    final claim = claimById(claimId);
    if (claim == null || claim.claimantId != claimantId) {
      throw StateError('Hanya pengklaim yang dapat membatalkan klaim ini.');
    }
    if (claim.status != ClaimStatus.pending) {
      throw StateError('Hanya klaim yang menunggu yang dapat dibatalkan.');
    }
    claim.status = ClaimStatus.cancelled;
    claim.decidedAt = now ?? DateTime.now();
    final found = _foundItem(claim.foundItemId);
    if (found != null) _restoreFoundStatusIfNoOpenClaims(found);
    final match = matchById(claim.matchId);
    if (match != null) match.status = MatchStatus.viewed;
  }

  void confirmResolution({
    required String claimId,
    required String userId,
    DateTime? now,
  }) {
    final claim = claimById(claimId);
    if (claim == null || claim.status != ClaimStatus.approved) {
      throw StateError(
        'Klaim harus disetujui sebelum barang dinyatakan selesai.',
      );
    }
    final found = _foundItem(claim.foundItemId);
    final lost = itemById(matchById(claim.matchId)?.lostItemId ?? '');
    if (found == null || lost == null) {
      throw StateError('Laporan pasangan klaim tidak ditemukan.');
    }
    if (userId == claim.claimantId) {
      claim.claimantConfirmedResolution = true;
    } else if (userId == found.ownerId) {
      claim.ownerConfirmedResolution = true;
    } else {
      throw StateError(
        'Hanya kedua pihak yang dapat mengonfirmasi serah terima.',
      );
    }
    if (claim.claimantConfirmedResolution && claim.ownerConfirmedResolution) {
      found.status = ReportStatus.resolved;
      lost.status = ReportStatus.resolved;
      _addNotification(
        claim.claimantId,
        'Laporan selesai',
        '${found.nameItem} telah dikonfirmasi diterima oleh kedua pihak.',
        now ?? DateTime.now(),
      );
      _addNotification(
        found.ownerId,
        'Laporan selesai',
        '${found.nameItem} telah dikonfirmasi diterima oleh kedua pihak.',
        now ?? DateTime.now(),
      );
    }
  }

  void markNotificationRead(String notificationId) {
    for (final notification in notifications) {
      if (notification.id == notificationId) notification.isRead = true;
    }
  }

  Item? _foundItem(String id) {
    final item = itemById(id);
    return item?.isFound == true ? item : null;
  }

  bool _isParticipant(ItemMatch match, String userId) =>
      itemById(match.lostItemId)?.ownerId == userId ||
      itemById(match.foundItemId)?.ownerId == userId;

  double? _categoryMultiplier(Item lost, Item found) {
    final lostCategories = _categoriesFor(lost);
    final foundCategories = _categoriesFor(found);
    if (lostCategories.contains('Lainnya') ||
        foundCategories.contains('Lainnya')) {
      return .7;
    }
    if (lostCategories.any(foundCategories.contains)) return 1;

    const related = {
      'Dompet & Kartu|Tas & Ransel',
      'Dompet & Kartu|Dokumen & Perlengkapan Kuliah',
      'Elektronik|Tas & Ransel',
      'Elektronik|Dokumen & Perlengkapan Kuliah',
      'Kunci & Kendaraan|Pakaian & Aksesori',
      'Botol & Perlengkapan Makan|Tas & Ransel',
      'Perlengkapan Ibadah|Tas & Ransel',
      'Perlengkapan Olahraga|Pakaian & Aksesori',
    };
    for (final left in lostCategories) {
      for (final right in foundCategories) {
        final pair = [left, right]..sort();
        if (related.contains('${pair[0]}|${pair[1]}')) return .8;
      }
    }
    return null;
  }

  Set<String> _categoriesFor(Item item) => {
    item.category,
    if (item.category2 != null && item.category2!.trim().isNotEmpty)
      item.category2!,
  };

  double _textSimilarity(Item lost, Item found) {
    final name = _stringSimilarity(lost.nameItem, found.nameItem);
    final description = _stringSimilarity(lost.description, found.description);
    var score = (name * .65) + (description * .35);
    if (_sameOptional(lost.color, found.color)) score += 5;
    if (_sameOptional(lost.brand, found.brand)) score += 5;
    return score.clamp(0, 100).toDouble();
  }

  double _locationScore(Item lost, Item found) {
    double? score;
    if (lost.latitude != null &&
        lost.longitude != null &&
        found.latitude != null &&
        found.longitude != null) {
      final distance = _distanceInMeters(
        lost.latitude!,
        lost.longitude!,
        found.latitude!,
        found.longitude!,
      );
      score = distance <= 200
          ? 100
          : distance >= 1000
          ? 0
          : (1000 - distance) * 100 / 800;
    }
    if (_normalize(lost.location) == _normalize(found.location)) {
      score = (score ?? 0).clamp(70, 100).toDouble();
    }
    return score ?? 0;
  }

  double _timeScore(DateTime lost, DateTime found) {
    final hours = lost.difference(found).inHours.abs().toDouble();
    if (hours <= 24) return 100;
    if (hours >= 168) return 0;
    return (168 - hours) * 100 / 144;
  }

  double _stringSimilarity(String left, String right) {
    final a = _normalize(left);
    final b = _normalize(right);
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 100;
    final aGrams = _trigrams(a);
    final bGrams = _trigrams(b);
    final overlap = aGrams.intersection(bGrams).length;
    if (overlap == 0) return 0;
    return 200 * overlap / (aGrams.length + bGrams.length);
  }

  Set<String> _trigrams(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ');
    if (compact.length < 3) return {compact};
    return {
      for (var index = 0; index <= compact.length - 3; index++)
        compact.substring(index, index + 3),
    };
  }

  double _distanceInMeters(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadius = 6371000.0;
    final lat1 = _radians(latitude1);
    final lat2 = _radians(latitude2);
    final deltaLat = _radians(latitude2 - latitude1);
    final deltaLng = _radians(longitude2 - longitude1);
    final haversine =
        math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLng / 2), 2);
    return earthRadius * 2 * math.asin(math.sqrt(haversine.clamp(0, 1)));
  }

  double _radians(double value) => value * 3.141592653589793 / 180;

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  bool _sameOptional(String? left, String? right) =>
      left != null &&
      right != null &&
      left.trim().isNotEmpty &&
      _normalize(left) == _normalize(right);

  MatchStatus _statusForMatch(ItemMatch match, ItemMatch? old) {
    if (old?.status == MatchStatus.dismissed ||
        old?.status == MatchStatus.claimed) {
      return old!.status;
    }
    return old?.status ?? MatchStatus.suggested;
  }

  void _notifyMatchOwners(ItemMatch match, DateTime createdAt) {
    final lost = itemById(match.lostItemId);
    final found = itemById(match.foundItemId);
    final ownerIds = {
      lost?.ownerId,
      found?.ownerId,
    }.whereType<String>().where((ownerId) => ownerId.isNotEmpty);
    for (final ownerId in ownerIds) {
      _addNotification(
        ownerId,
        'Potensi kecocokan ${match.score.toStringAsFixed(0)}%',
        'Ada laporan pasangan baru yang mungkin cocok.',
        createdAt,
      );
    }
  }

  void _addNotification(
    String? recipientId,
    String title,
    String message,
    DateTime createdAt,
  ) {
    if (recipientId == null || recipientId.isEmpty) return;
    notifications.add(
      ModuleNotification(
        id: _id('notification'),
        recipientId: recipientId,
        title: title,
        message: message,
        createdAt: createdAt,
      ),
    );
  }

  void _restoreFoundStatusIfNoOpenClaims(Item found) {
    final hasOpenClaim = claims.any(
      (claim) =>
          claim.foundItemId == found.id &&
          (claim.status == ClaimStatus.pending ||
              claim.status == ClaimStatus.approved),
    );
    if (!hasOpenClaim && found.status == ReportStatus.inVerification) {
      found.status = ReportStatus.active;
    }
    if (!hasOpenClaim) {
      for (final match in matches.where(
        (entry) => entry.foundItemId == found.id,
      )) {
        final lost = itemById(match.lostItemId);
        final hasOtherOpenClaim = claims.any((claim) {
          if (claim.status != ClaimStatus.pending &&
              claim.status != ClaimStatus.approved) {
            return false;
          }
          return matchById(claim.matchId)?.lostItemId == lost?.id;
        });
        if (lost?.status == ReportStatus.inVerification && !hasOtherOpenClaim) {
          lost!.status = ReportStatus.active;
        }
      }
    }
  }

  String _id(String prefix) => '$prefix-${++_nextId}';
  String? _optional(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

  String _dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}
