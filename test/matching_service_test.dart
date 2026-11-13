import 'package:flutter_test/flutter_test.dart';
import 'package:find_it/models/claim.dart';
import 'package:find_it/models/item.dart';
import 'package:find_it/models/match.dart';
import 'package:find_it/services/matching_service.dart';

void main() {
  const claimantId = 'user:claimant@student.unand.ac.id';
  const ownerId = 'user:owner@student.unand.ac.id';
  final eventDate = DateTime(2026, 10, 10, 10);

  MatchingService serviceWithPair({
    String lostCategory = 'Elektronik',
    String foundCategory = 'Elektronik',
    DateTime? lostDate,
    DateTime? foundDate,
    String lostId = 'lost',
    String foundId = 'found',
  }) {
    final service = MatchingService(
      items: [
        Item(
          id: lostId,
          nameItem: 'Laptop ASUS',
          subtitle: 'Laptop hilang',
          description: 'Laptop silver dengan stiker khusus.',
          location: 'Perpustakaan Pusat',
          isFound: false,
          category: lostCategory,
          eventDate: lostDate ?? eventDate,
          ownerId: claimantId,
          color: 'Silver',
          brand: 'ASUS',
        ),
        Item(
          id: foundId,
          nameItem: 'Laptop ASUS',
          subtitle: 'Laptop ditemukan',
          description: 'Laptop silver dengan stiker khusus.',
          location: 'Perpustakaan Pusat',
          isFound: true,
          category: foundCategory,
          eventDate: foundDate ?? eventDate,
          ownerId: ownerId,
          verificationDetails: const ['Stiker dekat engsel kiri.'],
          whatsapp: '08123456789',
        ),
      ],
    );
    service.refreshMatches(now: eventDate);
    return service;
  }

  test('matching applies exact thresholds and excludes invalid pairs', () {
    final service = serviceWithPair();
    expect(service.visibleMatches, hasLength(1));
    expect(service.visibleMatches.single.score, closeTo(89.5, .001));

    final related = serviceWithPair(
      lostCategory: 'Elektronik',
      foundCategory: 'Tas & Ransel',
    );
    expect(related.visibleMatches.single.categoryMultiplier, .8);
    expect(related.visibleMatches.single.score, closeTo(71.6, .001));

    final otherCategory = serviceWithPair(
      lostCategory: 'Lainnya',
      foundCategory: 'Elektronik',
    );
    expect(otherCategory.visibleMatches.single.categoryMultiplier, .7);
    expect(otherCategory.visibleMatches.single.score, closeTo(62.65, .001));

    final unrelated = serviceWithPair(
      lostCategory: 'Perlengkapan Ibadah',
      foundCategory: 'Elektronik',
    );
    expect(unrelated.matches, isEmpty);

    final tooEarly = serviceWithPair(
      lostDate: eventDate,
      foundDate: eventDate.subtract(const Duration(days: 2)),
    );
    expect(tooEarly.matches, isEmpty);

    final fourDaysApart = serviceWithPair(
      foundDate: eventDate.add(const Duration(days: 4)),
    );
    expect(fourDaysApart.visibleMatches.single.timeScore, closeTo(50, .1));
    final sevenDaysApart = serviceWithPair(
      foundDate: eventDate.add(const Duration(days: 7)),
    );
    expect(sevenDaysApart.visibleMatches.single.timeScore, 0);

    final inactive = serviceWithPair();
    inactive.items.first.status = ReportStatus.resolved;
    inactive.refreshMatches(now: eventDate);
    expect(inactive.visibleMatches, isEmpty);
  });

  test('Haversine location score declines linearly after 200 meters', () {
    MatchingService atDistance(double meters) {
      final service = MatchingService(
        items: [
          Item(
            id: 'lost-distance',
            nameItem: 'Dompet biru',
            subtitle: 'Hilang',
            description: 'Dompet biru dengan gantungan',
            location: 'Area A',
            isFound: false,
            category: 'Dompet & Kartu',
            eventDate: eventDate,
            latitude: 0,
            longitude: 0,
          ),
          Item(
            id: 'found-distance',
            nameItem: 'Dompet biru',
            subtitle: 'Ditemukan',
            description: 'Dompet biru dengan gantungan',
            location: 'Area B',
            isFound: true,
            category: 'Dompet & Kartu',
            eventDate: eventDate,
            latitude: 0,
            longitude: meters / 111195,
          ),
        ],
      )..refreshMatches(now: eventDate);
      return service;
    }

    expect(atDistance(100).visibleMatches.single.locationScore, 100);
    expect(atDistance(600).visibleMatches.single.locationScore, closeTo(50, 1));
    expect(atDistance(1200).visibleMatches.single.locationScore, 0);
  });

  test('claim requires verified user and moves report into verification', () {
    final service = serviceWithPair();
    final match = service.visibleMatches.single;
    expect(
      () => service.submitClaim(
        matchId: match.id,
        claimantId: claimantId,
        emailVerified: false,
        answers: 'Stiker dekat engsel kiri',
        reason: 'Laptop saya hilang setelah kelas.',
        evidence: '',
        claimantWhatsapp: null,
        claimantSharesContact: false,
        now: eventDate,
      ),
      throwsA(isA<StateError>()),
    );

    final claim = service.submitClaim(
      matchId: match.id,
      claimantId: claimantId,
      emailVerified: true,
      answers: 'Stiker dekat engsel kiri',
      reason: 'Laptop saya hilang setelah kelas.',
      evidence: 'Bukti pembelian tersedia.',
      claimantWhatsapp: '08987654321',
      claimantSharesContact: true,
      now: eventDate,
    );
    expect(claim.status, ClaimStatus.pending);
    expect(service.items.last.status, ReportStatus.inVerification);
    expect(service.notificationsFor(ownerId), isNotEmpty);
    expect(
      () => service.submitClaim(
        matchId: match.id,
        claimantId: claimantId,
        emailVerified: true,
        answers: 'Jawaban kedua',
        reason: 'Mencoba ulang',
        evidence: '',
        claimantWhatsapp: null,
        claimantSharesContact: false,
        now: eventDate,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('comments, approval, contact consent and two-party resolution work', () {
    final service = serviceWithPair();
    final match = service.visibleMatches.single;
    final claim = service.submitClaim(
      matchId: match.id,
      claimantId: claimantId,
      emailVerified: true,
      answers: 'Stiker dekat engsel kiri',
      reason: 'Laptop saya hilang.',
      evidence: 'Serial number cocok.',
      claimantWhatsapp: '08987654321',
      claimantSharesContact: true,
      now: eventDate,
    );

    final comment = service.addComment(
      claimId: claim.id,
      senderId: claimantId,
      message: 'Saya dapat menunjukkan bukti pembelian.',
      now: eventDate,
    );
    expect(service.commentsFor(claim.id), [comment]);
    expect(
      () => service.addComment(
        claimId: claim.id,
        senderId: 'stranger',
        message: 'Komentar tidak berwenang',
        now: eventDate,
      ),
      throwsA(isA<StateError>()),
    );

    service.decideClaim(
      claimId: claim.id,
      ownerId: ownerId,
      approve: true,
      ownerSharesContact: true,
      now: eventDate,
    );
    expect(claim.status, ClaimStatus.approved);
    expect(claim.ownerSharesContact, isTrue);

    service.confirmResolution(claimId: claim.id, userId: claimantId);
    expect(service.items.first.status, ReportStatus.inVerification);
    service.confirmResolution(claimId: claim.id, userId: ownerId);
    expect(
      service.items.map((item) => item.status),
      everyElement(ReportStatus.resolved),
    );
  });

  test('cancelled claim reopens report and dismissed match is hidden', () {
    final service = serviceWithPair();
    final match = service.visibleMatches.single;
    final claim = service.submitClaim(
      matchId: match.id,
      claimantId: claimantId,
      emailVerified: true,
      answers: 'Stiker dekat engsel kiri',
      reason: 'Laptop saya.',
      evidence: '',
      claimantWhatsapp: null,
      claimantSharesContact: false,
    );
    service.cancelClaim(claimId: claim.id, claimantId: claimantId);
    expect(service.items.last.status, ReportStatus.active);
    expect(match.status, MatchStatus.viewed);

    service.dismissMatch(match.id, claimantId);
    expect(service.visibleMatches, isEmpty);
  });

  test('three rejections suspend new claims for seven days', () {
    final items = <Item>[];
    for (var index = 0; index < 4; index++) {
      final pairDate = eventDate.add(Duration(days: index * 10));
      items.addAll([
        Item(
          id: 'lost-$index',
          nameItem: 'Laptop $index',
          subtitle: 'Hilang',
          description: 'Laptop silver nomor $index',
          location: 'Gedung $index',
          isFound: false,
          category: 'Elektronik',
          eventDate: pairDate,
          ownerId: claimantId,
        ),
        Item(
          id: 'found-$index',
          nameItem: 'Laptop $index',
          subtitle: 'Ditemukan',
          description: 'Laptop silver nomor $index',
          location: 'Gedung $index',
          isFound: true,
          category: 'Elektronik',
          eventDate: pairDate,
          ownerId: ownerId,
          verificationDetails: const ['Ciri rahasia.'],
        ),
      ]);
    }
    final service = MatchingService(items: items)
      ..refreshMatches(now: eventDate);
    final matches = service.visibleMatches
        .where((match) => match.score >= MatchingService.notificationThreshold)
        .toList();
    expect(matches, hasLength(4));

    for (var index = 0; index < 3; index++) {
      final claim = service.submitClaim(
        matchId: matches[index].id,
        claimantId: claimantId,
        emailVerified: true,
        answers: 'Jawaban',
        reason: 'Klaim $index',
        evidence: '',
        claimantWhatsapp: null,
        claimantSharesContact: false,
        now: eventDate,
      );
      service.decideClaim(
        claimId: claim.id,
        ownerId: ownerId,
        approve: false,
        ownerSharesContact: false,
        now: eventDate.add(Duration(hours: index)),
      );
    }

    expect(
      () => service.submitClaim(
        matchId: matches[3].id,
        claimantId: claimantId,
        emailVerified: true,
        answers: 'Jawaban',
        reason: 'Klaim keempat',
        evidence: '',
        claimantWhatsapp: null,
        claimantSharesContact: false,
        now: eventDate.add(const Duration(hours: 4)),
      ),
      throwsA(isA<StateError>()),
    );
  });
}
