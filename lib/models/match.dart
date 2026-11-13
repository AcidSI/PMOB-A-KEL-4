enum MatchStatus { suggested, viewed, dismissed, claimed }

class ItemMatch {
  final String id;
  final String lostItemId;
  final String foundItemId;
  final double textScore;
  final double locationScore;
  final double timeScore;
  final double categoryMultiplier;
  final double score;
  MatchStatus status;

  ItemMatch({
    required this.id,
    required this.lostItemId,
    required this.foundItemId,
    required this.textScore,
    required this.locationScore,
    required this.timeScore,
    required this.categoryMultiplier,
    required this.score,
    this.status = MatchStatus.suggested,
  });
}
