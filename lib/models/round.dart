import 'marriage_round_meta.dart';

class GameRound {
  final String id;
  final int roundNumber;
  final Map<String, int> scores;
  final Map<String, int> bids;
  final DateTime timestamp;
  final bool isEdited;

  /// Player IDs who won a round with bid >= 8 (Call Break special win).
  /// Their score for this round is counted in the Special Game, not the Regular Game.
  final List<String> specialWinnerIds;

  /// Per-player Marriage combination metadata for this deal.
  /// Null for non-Marriage rounds.
  final Map<String, MarriageRoundMeta>? marriageMeta;

  const GameRound({
    required this.id,
    required this.roundNumber,
    required this.scores,
    required this.bids,
    required this.timestamp,
    this.isEdited = false,
    this.specialWinnerIds = const [],
    this.marriageMeta,
  });

  bool get hasSpecialWinner => specialWinnerIds.isNotEmpty;

  GameRound copyWith({
    String? id,
    int? roundNumber,
    Map<String, int>? scores,
    Map<String, int>? bids,
    DateTime? timestamp,
    bool? isEdited,
    List<String>? specialWinnerIds,
    Map<String, MarriageRoundMeta>? marriageMeta,
  }) {
    return GameRound(
      id: id ?? this.id,
      roundNumber: roundNumber ?? this.roundNumber,
      scores: scores ?? this.scores,
      bids: bids ?? this.bids,
      timestamp: timestamp ?? this.timestamp,
      isEdited: isEdited ?? this.isEdited,
      specialWinnerIds: specialWinnerIds ?? this.specialWinnerIds,
      marriageMeta: marriageMeta ?? this.marriageMeta,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roundNumber': roundNumber,
      'scores': scores,
      'bids': bids,
      'timestamp': timestamp.toIso8601String(),
      'isEdited': isEdited,
      'specialWinnerIds': specialWinnerIds,
      if (marriageMeta != null)
        'marriageMeta': marriageMeta!.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
    };
  }

  factory GameRound.fromJson(Map<String, dynamic> json) {
    final rawMeta = json['marriageMeta'] as Map<String, dynamic>?;
    return GameRound(
      id: json['id'] as String,
      roundNumber: (json['roundNumber'] as num).toInt(),
      scores: (json['scores'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      bids: (json['bids'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isEdited: json['isEdited'] as bool? ?? false,
      specialWinnerIds: (json['specialWinnerIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      marriageMeta: rawMeta?.map(
        (k, v) => MapEntry(
          k,
          MarriageRoundMeta.fromJson(v as Map<String, dynamic>),
        ),
      ),
    );
  }
}
