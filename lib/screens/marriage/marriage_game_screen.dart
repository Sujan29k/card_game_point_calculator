import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/match.dart';
import '../../providers/match_provider.dart';
import '../../widgets/add_round_fab_location.dart';
import '../../widgets/confirm_dialog.dart';
import 'marriage_score_entry.dart';

class MarriageGameScreen extends StatefulWidget {
  const MarriageGameScreen({super.key});

  @override
  State<MarriageGameScreen> createState() => _MarriageGameScreenState();
}

class _MarriageGameScreenState extends State<MarriageGameScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchProvider>();
    final match = provider.currentMatch;
    if (match == null) {
      return _EmptyMatchScaffold();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppStrings.marriageTitle} ${AppStrings.separator} ${match.rounds.length + 1}',
        ),
        actions: [
          TextButton(
            onPressed: () => _endGame(context, provider),
            child: const Text(AppStrings.endGame),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addRound(context, match, provider),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addRound),
      ),
      floatingActionButtonLocation: const AddRoundFabLocation(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _RoundsTable(
            match: match,
            onEdit: (index) => _editRound(context, match, provider, index),
            onDelete: (index) => _deleteRound(context, provider, index),
          ),
        ),
      ),
    );
  }

  Future<void> _addRound(
    BuildContext context,
    GameMatch match,
    MatchProvider provider,
  ) async {
    final round = await showMarriageScoreEntry(
      context: context,
      match: match,
      roundNumber: match.rounds.length + 1,
    );
    if (round == null) return;
    provider.addRound(round);
  }

  Future<void> _editRound(
    BuildContext context,
    GameMatch match,
    MatchProvider provider,
    int index,
  ) async {
    final existing = match.rounds[index];
    final round = await showMarriageScoreEntry(
      context: context,
      match: match,
      roundNumber: existing.roundNumber,
      initialRound: existing,
    );
    if (round == null) return;
    provider.editRound(index, round);
  }

  Future<void> _deleteRound(
    BuildContext context,
    MatchProvider provider,
    int index,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: AppStrings.deleteRound,
      message: AppStrings.confirmDeleteRound,
      confirmText: AppStrings.delete,
    );
    if (!confirmed) return;
    provider.deleteRound(index);
  }

  Future<void> _endGame(BuildContext context, MatchProvider provider) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: AppStrings.endGame,
      message: AppStrings.confirmEndGame,
      confirmText: AppStrings.endGame,
    );
    if (!confirmed) return;
    provider.endMatch();
    if (!context.mounted) return;
    Navigator.popUntil(
      context,
      (route) => route.settings.name == AppRoutes.home,
    );
  }
}

class _RoundsTable extends StatelessWidget {
  final GameMatch match;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  const _RoundsTable({
    required this.match,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final totals = match.cumulativeScores;
    final highest = totals.values.isEmpty
        ? 0
        : totals.values.reduce((a, b) => a > b ? a : b);
    final lowest = totals.values.isEmpty
        ? 0
        : totals.values.reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        _HeaderRow(names: match.players.map((p) => p.name).toList()),
        const Divider(height: 1),
        Expanded(
          child: match.rounds.isEmpty
              ? _EmptyRounds()
              : ListView.builder(
                  itemCount: match.rounds.length,
                  itemBuilder: (context, index) {
                    final round = match.rounds[index];
                    final isEven = index % 2 == 0;
                    return InkWell(
                      onLongPress: () => onDelete(index),
                      child: Container(
                        color: isEven
                            ? Theme.of(context).colorScheme.surface
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLowest,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 56,
                              child: Text('${round.roundNumber}'),
                            ),
                            ...match.players.map((player) {
                              final score = round.scores[player.id] ?? 0;
                              final color = score >= 0
                                  ? AppColors.positive
                                  : AppColors.negative;
                              return Expanded(
                                child: Text(
                                  score.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: color),
                                ),
                              );
                            }),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => onEdit(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        _TotalsRow(
          totals: totals,
          playerIds: match.players.map((p) => p.id).toList(),
          highest: highest,
          lowest: lowest,
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final List<String> names;

  const _HeaderRow({required this.names});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          const SizedBox(width: 56, child: Text(AppStrings.numberSymbol)),
          ...names.map(
            (name) => Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final Map<String, int> totals;
  final List<String> playerIds;
  final int highest;
  final int lowest;

  const _TotalsRow({
    required this.totals,
    required this.playerIds,
    required this.highest,
    required this.lowest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        children: [
          const SizedBox(width: 56, child: Text(AppStrings.total)),
          ...playerIds.map((playerId) {
            final score = totals[playerId] ?? 0;
            Color? color;
            if (score == highest) {
              color = Colors.green.shade700;
            } else if (score == lowest) {
              color = Colors.red.shade700;
            }
            return Expanded(
              child: Text(
                score.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
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

class _EmptyRounds extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          AppStrings.emptyRounds,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _EmptyMatchScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.marriageTitle)),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox, size: 48),
              const SizedBox(height: 12),
              const Text(AppStrings.noActiveMatch),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.marriageSetup,
                ),
                child: const Text(AppStrings.startMatch),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
