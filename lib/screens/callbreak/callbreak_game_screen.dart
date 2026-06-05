import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/match.dart';
import '../../providers/match_provider.dart';
import '../../utils/score_calculator.dart';
import '../../widgets/confirm_dialog.dart';
import 'callbreak_score_entry.dart';

class CallBreakGameScreen extends StatefulWidget {
  const CallBreakGameScreen({super.key});

  @override
  State<CallBreakGameScreen> createState() => _CallBreakGameScreenState();
}

class _CallBreakGameScreenState extends State<CallBreakGameScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchProvider>();
    final match = provider.currentMatch;

    if (match == null) return _EmptyMatchScaffold();

    // How many total rounds are planned (0 or null = unlimited)
    final targetRounds = match.roundCount ?? 0;
    final playedRounds = match.rounds.length;

    // Label: show "Round X / Y" when a target is set, else just "Round X"
    final roundLabel = targetRounds > 0
        ? 'Round $playedRounds / $targetRounds'
        : 'Round $playedRounds';

    return Scaffold(
      appBar: AppBar(
        title: Text('${AppStrings.callbreakTitle}  ·  $roundLabel'),
        actions: [
          TextButton(
            onPressed: () => _endGame(context, provider),
            child: const Text(AppStrings.endGame),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addRound(context, match, provider),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addRound),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
          child: _RoundsTable(
            match: match,
            onEdit: (i) => _editRound(context, match, provider, i),
            onDelete: (i) => _deleteRound(context, provider, i),
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
    final round = await showCallBreakScoreEntry(
      context: context,
      match: match,
      roundNumber: match.rounds.length + 1,
    );
    if (round == null) return;
    provider.addRound(round);
    // No auto-end: player ends the game manually via the End Game button.
  }

  Future<void> _editRound(
    BuildContext context,
    GameMatch match,
    MatchProvider provider,
    int index,
  ) async {
    final existing = match.rounds[index];
    final round = await showCallBreakScoreEntry(
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

  Future<void> _endGame(
    BuildContext context,
    MatchProvider provider,
  ) async {
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

// ─── Rounds Table ─────────────────────────────────────────────────────────────
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
    final totals  = match.cumulativeScores;
    final highest = totals.values.isEmpty ? 0 : totals.values.reduce((a, b) => a > b ? a : b);
    final lowest  = totals.values.isEmpty ? 0 : totals.values.reduce((a, b) => a < b ? a : b);

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
                    final round  = match.rounds[index];
                    final isEven = index % 2 == 0;
                    return InkWell(
                      onLongPress: () => onDelete(index),
                      child: Container(
                        color: isEven
                            ? Theme.of(context).colorScheme.surface
                            : Theme.of(context).colorScheme.surfaceContainerLowest,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 56,
                              child: Text('${round.roundNumber}'),
                            ),
                            ...match.players.map((player) {
                              final score     = round.scores[player.id] ?? 0;
                              final scoreText = ScoreCalculator.formatScore(score, isTenths: true);
                              final color     = score >= 0 ? AppColors.positive : AppColors.negative;
                              return Expanded(
                                child: Text(
                                  scoreText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: color),
                                ),
                              );
                            }),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
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
          totals:    totals,
          playerIds: match.players.map((p) => p.id).toList(),
          highest:   highest,
          lowest:    lowest,
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
          ...playerIds.map((id) {
            final score     = totals[id] ?? 0;
            final scoreText = ScoreCalculator.formatScore(score, isTenths: true);
            Color? color;
            if (score == highest) color = Colors.green.shade700;
            if (score == lowest)  color = Colors.red.shade700;
            return Expanded(
              child: Text(
                scoreText,
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
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppStrings.emptyRounds,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
}

class _EmptyMatchScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.callbreakTitle)),
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
                    AppRoutes.callbreakSetup,
                  ),
                  child: const Text(AppStrings.startMatch),
                ),
              ],
            ),
          ),
        ),
      );
}