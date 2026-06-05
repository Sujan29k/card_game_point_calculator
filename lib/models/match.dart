import 'player.dart';
import 'round.dart';

class GameMatch {
  final String id;
  final String gameType;
  final List<Player> players;
  final List<GameRound> rounds;
  final String? winnerId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;

  /// Score threshold kept for backward compat; not used as win condition for Call Break.
  final int? winningScore;

  /// Number of rounds before game auto-ends. null / 0 = unlimited (manual end).
  final int? roundCount;

  final Map<String, int> bonusConfig;

  const GameMatch({
    required this.id,
    required this.gameType,
    required this.players,
    required this.rounds,
    required this.startTime,
    this.winnerId,
    this.endTime,
    this.isCompleted = false,
    this.winningScore,
    this.roundCount,
    this.bonusConfig = const {},
  });

  GameMatch copyWith({
    String? id,
    String? gameType,
    List<Player>? players,
    List<GameRound>? rounds,
    String? winnerId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    int? winningScore,
    int? roundCount,
    Map<String, int>? bonusConfig,
  }) {
    return GameMatch(
      id: id ?? this.id,
      gameType: gameType ?? this.gameType,
      players: players ?? this.players,
      rounds: rounds ?? this.rounds,
      winnerId: winnerId ?? this.winnerId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      winningScore: winningScore ?? this.winningScore,
      roundCount: roundCount ?? this.roundCount,
      bonusConfig: bonusConfig ?? this.bonusConfig,
    );
  }

  // ─── Score Getters ────────────────────────────────────────────────────────

  /// Regular game scores — excludes contributions from special-win players in
  /// any round where they triggered the 8-bid rule.
  Map<String, int> get cumulativeScores {
    final totals = <String, int>{};
    for (final player in players) {
      totals[player.id] = 0;
    }
    for (final round in rounds) {
      round.scores.forEach((playerId, score) {
        if (!round.specialWinnerIds.contains(playerId)) {
          totals[playerId] = (totals[playerId] ?? 0) + score;
        }
      });
    }
    return totals;
  }

  /// Special-game scores — only the scores from rounds where each player
  /// triggered the 8-bid special-win rule.
  Map<String, int> get specialCumulativeScores {
    final totals = <String, int>{};
    for (final player in players) {
      totals[player.id] = 0;
    }
    for (final round in rounds) {
      for (final winnerId in round.specialWinnerIds) {
        final score = round.scores[winnerId] ?? 0;
        totals[winnerId] = (totals[winnerId] ?? 0) + score;
      }
    }
    return totals;
  }

  /// Players whose regular cumulative score is ≥ 200 tenths (= 20.0 points).
  /// Reaching 20+ earns "Double Money" status for that player.
  Set<String> get doubleMoneyPlayerIds {
    return cumulativeScores.entries
        .where((e) => e.value >= 200)
        .map((e) => e.key)
        .toSet();
  }

  bool get hasSpecialRounds => rounds.any((r) => r.hasSpecialWinner);

  // ─── Serialisation ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameType': gameType,
      'players': players.map((p) => p.toJson()).toList(),
      'rounds': rounds.map((r) => r.toJson()).toList(),
      'winnerId': winnerId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isCompleted': isCompleted,
      'winningScore': winningScore,
      'roundCount': roundCount,
      'bonusConfig': bonusConfig,
    };
  }

  factory GameMatch.fromJson(Map<String, dynamic> json) {
    return GameMatch(
      id: json['id'] as String,
      gameType: json['gameType'] as String,
      players: (json['players'] as List<dynamic>? ?? [])
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
      rounds: (json['rounds'] as List<dynamic>? ?? [])
          .map((e) => GameRound.fromJson(e as Map<String, dynamic>))
          .toList(),
      winnerId: json['winnerId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      winningScore: (json['winningScore'] as num?)?.toInt(),
      roundCount: (json['roundCount'] as num?)?.toInt(),
      bonusConfig: (json['bonusConfig'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
    );
  }
}
