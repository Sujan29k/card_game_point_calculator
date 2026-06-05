import 'match.dart';

class Statistics {
  final int totalMatches;
  final Map<String, int> winsPerPlayer;
  final String mostFrequentWinner;
  final int highestScore;
  final double averageScore;

  const Statistics({
    required this.totalMatches,
    required this.winsPerPlayer,
    required this.mostFrequentWinner,
    required this.highestScore,
    required this.averageScore,
  });

  factory Statistics.fromMatches(List<GameMatch> matches) {
    final completed = matches.where((m) => m.isCompleted).toList();
    final winsMap = <String, int>{};
    int highest = 0;
    double totalScoreSum = 0;
    int scoreCount = 0;

    for (final match in completed) {
      if (match.winnerId != null) {
        winsMap[match.winnerId!] = (winsMap[match.winnerId!] ?? 0) + 1;
      }
      for (final round in match.rounds) {
        for (final score in round.scores.values) {
          if (score > highest) {
            highest = score;
          }
          totalScoreSum += score;
          scoreCount += 1;
        }
      }
    }

    String mostFrequent = '';
    int topWins = 0;
    winsMap.forEach((playerId, wins) {
      if (wins > topWins) {
        topWins = wins;
        mostFrequent = playerId;
      }
    });

    final avg = scoreCount == 0 ? 0.0 : totalScoreSum / scoreCount;

    return Statistics(
      totalMatches: completed.length,
      winsPerPlayer: winsMap,
      mostFrequentWinner: mostFrequent,
      highestScore: highest,
      averageScore: avg.toDouble(),
    );
  }
}
