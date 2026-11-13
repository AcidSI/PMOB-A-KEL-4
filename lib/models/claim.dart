enum ClaimStatus { pending, approved, rejected, cancelled }

class Claim {
  final String id;
  final String matchId;
  final String foundItemId;
  final String claimantId;
  final String answers;
  final String reason;
  final String evidence;
  final String? claimantWhatsapp;
  final bool claimantSharesContact;
  final DateTime createdAt;
  ClaimStatus status;
  bool ownerSharesContact;
  bool claimantConfirmedResolution;
  bool ownerConfirmedResolution;
  DateTime? decidedAt;

  Claim({
    required this.id,
    required this.matchId,
    required this.foundItemId,
    required this.claimantId,
    required this.answers,
    required this.reason,
    required this.evidence,
    required this.claimantWhatsapp,
    required this.claimantSharesContact,
    required this.createdAt,
    this.status = ClaimStatus.pending,
    this.ownerSharesContact = false,
    this.claimantConfirmedResolution = false,
    this.ownerConfirmedResolution = false,
    this.decidedAt,
  });
}

class ClaimComment {
  final String id;
  final String claimId;
  final String senderId;
  final String message;
  final DateTime createdAt;

  const ClaimComment({
    required this.id,
    required this.claimId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });
}

class ModuleNotification {
  final String id;
  final String recipientId;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;

  ModuleNotification({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });
}
