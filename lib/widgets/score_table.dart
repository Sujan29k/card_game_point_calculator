import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/match.dart';
import '../utils/score_calculator.dart';

class ScoreTable extends StatelessWidget {
  final GameMatch match;

  const ScoreTable({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final isTenths = match.gameType == AppStrings.gameTypeCallbreak;
    final totals = match.cumulativeScores;
    final highest = totals.values.isEmpty
        ? 0
        : totals.values.reduce((a, b) => a > b ? a : b);
    final lowest = totals.values.isEmpty
        ? 0
        : totals.values.reduce((a, b) => a < b ? a : b);
    final leaderId = totals.isEmpty
        ? null
        : totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return Column(
      children: [
        _HeaderRow(
          names: match.players.map((p) => p.name).toList(),
          leaderIndex: leaderId == null
              ? null
              : match.players.indexWhere((p) => p.id == leaderId),
        ),
        const Divider(height: 1),
        _RoundsList(match: match, isTenths: isTenths, leaderId: leaderId),
        const Divider(height: 1),
        _TotalsRow(
          totals: totals,
          names: match.players.map((p) => p.name).toList(),
          isTenths: isTenths,
          highest: highest,
          lowest: lowest,
          playerIds: match.players.map((p) => p.id).toList(),
          leaderId: leaderId,
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final List<String> names;
  final int? leaderIndex;

  const _HeaderRow({required this.names, required this.leaderIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          const SizedBox(width: 56, child: Text(AppStrings.numberSymbol)),
          ...List.generate(names.length, (index) {
            final highlight = leaderIndex == index;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: highlight ? AppColors.gold.withValues(alpha: 0.2) : null,
                child: Text(
                  names[index],
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _RoundsList extends StatelessWidget {
  final GameMatch match;
  final bool isTenths;
  final String? leaderId;

  const _RoundsList({
    required this.match,
    required this.isTenths,
    required this.leaderId,
  });

  @override
  Widget build(BuildContext context) {
    if (match.rounds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          AppStrings.noRoundsShort,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      children: List.generate(match.rounds.length, (index) {
        final round = match.rounds[index];
        final isEven = index % 2 == 0;
        return Container(
          color: isEven
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surfaceContainerLowest,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            children: [
              SizedBox(width: 56, child: Text('${round.roundNumber}')),
              ...match.players.map((player) {
                final score = round.scores[player.id] ?? 0;
                final scoreText = ScoreCalculator.formatScore(
                  score,
                  isTenths: isTenths,
                );
                final color = score >= 0
                    ? AppColors.positive
                    : AppColors.negative;
                final highlight = leaderId == player.id;
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    color: highlight ? AppColors.gold.withValues(alpha: 0.1) : null,
                    child: Text(
                      scoreText,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: color),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 40),
            ],
          ),
        );
      }),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final Map<String, int> totals;
  final List<String> names;
  final List<String> playerIds;
  final bool isTenths;
  final int highest;
  final int lowest;
  final String? leaderId;

  const _TotalsRow({
    required this.totals,
    required this.names,
    required this.playerIds,
    required this.isTenths,
    required this.highest,
    required this.lowest,
    required this.leaderId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        children: [
          const SizedBox(width: 56, child: Text(AppStrings.total)),
          ...List.generate(names.length, (index) {
            final playerId = playerIds[index];
            final score = totals[playerId] ?? 0;
            final scoreText = ScoreCalculator.formatScore(
              score,
              isTenths: isTenths,
            );
            Color? color;
            if (score == highest) {
              color = Colors.green.shade700;
            } else if (score == lowest) {
              color = Colors.red.shade700;
            }
            final highlight = leaderId == playerId;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                color: highlight ? AppColors.gold.withValues(alpha: 0.2) : null,
                child: Text(
                  scoreText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
