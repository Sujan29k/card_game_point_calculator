import 'package:flutter/material.dart';

import '../../constants/app_strings.dart';
import '../../models/match.dart';
import '../../utils/date_formatter.dart';
import '../../utils/score_calculator.dart';
import '../../widgets/score_table.dart';

class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final match = ModalRoute.of(context)!.settings.arguments as GameMatch?;
    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.details)),
        body: const Center(child: Text(AppStrings.noActiveMatch)),
      );
    }
    final isTenths = match.gameType == AppStrings.gameTypeCallbreak;
    final winner = match.players
        .firstWhere(
          (p) => p.id == match.winnerId,
          orElse: () => match.players.first,
        )
        .name;
    final duration = match.endTime == null
        ? null
        : DateFormatter.formatDuration(
            match.endTime!.difference(match.startTime),
          );

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.details)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              match.gameType == AppStrings.gameTypeCallbreak
                  ? AppStrings.callbreakTitle
                  : AppStrings.marriageTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('${AppStrings.winner}: $winner'),
            if (duration != null) Text('${AppStrings.duration}: $duration'),
            const SizedBox(height: 16),
            ScoreTable(match: match),
            const SizedBox(height: 16),
            Text(
              AppStrings.rounds,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...match.rounds.map((round) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppStrings.round} ${round.roundNumber}'),
                      const SizedBox(height: 6),
                      ...match.players.map((player) {
                        final score = round.scores[player.id] ?? 0;
                        final formatted = ScoreCalculator.formatScore(
                          score,
                          isTenths: isTenths,
                        );
                        return Text('${player.name}: $formatted');
                      }),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
