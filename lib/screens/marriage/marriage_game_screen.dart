import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
import '../../models/match.dart';
import '../../models/player.dart';
import '../../providers/match_provider.dart';
import '../../utils/marriage_score_calculator.dart';
import '../../widgets/add_round_fab_location.dart';
import '../../widgets/confirm_dialog.dart';
import 'marriage_score_entry.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF0F0B1E);
  static const surface   = Color(0xFF1A1535);
  static const card      = Color(0xFF1E1945);
  static const border    = Color(0xFF332B60);
  static const accent    = Color(0xFFB48EFF);
  static const gold      = Color(0xFFFFD060);
  static const red       = Color(0xFFFF6B8A);
  static const green     = Color(0xFF4FFFB0);
  static const textPri   = Color(0xFFF0ECFF);
  static const textSec   = Color(0xFF9B8FCC);
}

class MarriageGameScreen extends StatefulWidget {
  const MarriageGameScreen({super.key});

  @override
  State<MarriageGameScreen> createState() => _MarriageGameScreenState();
}

class _MarriageGameScreenState extends State<MarriageGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchProvider>();
    final match = provider.currentMatch;
    if (match == null) return _EmptyMatchScaffold();

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(context, match, provider),
      floatingActionButton: _buildFab(context, match, provider),
      floatingActionButtonLocation: const AddRoundFabLocation(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _LeaderBanner(match: match),
              Expanded(
                child: _RoundsTable(
                  match: match,
                  onEdit: (i) => _editRound(context, match, provider, i),
                  onDelete: (i) => _deleteRound(context, provider, i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, GameMatch match, MatchProvider provider) {
    return AppBar(
      backgroundColor: _C.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💍', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            'Marriage  •  Deal ${match.rounds.length + 1}',
            style: const TextStyle(
              color: _C.textPri,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _endGame(context, provider),
          child: const Text(
            'End Game',
            style: TextStyle(color: _C.red, fontWeight: FontWeight.w700),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.border),
      ),
    );
  }

  Widget _buildFab(
      BuildContext context, GameMatch match, MatchProvider provider) {
    return FloatingActionButton.extended(
      onPressed: () => _addRound(context, match, provider),
      backgroundColor: _C.accent,
      foregroundColor: _C.bg,
      icon: const Text('💍', style: TextStyle(fontSize: 16)),
      label: const Text(
        'New Deal',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      elevation: 4,
    );
  }

  Future<void> _addRound(
      BuildContext context, GameMatch match, MatchProvider provider) async {
    final round = await showMarriageScoreEntry(
      context: context,
      match: match,
      roundNumber: match.rounds.length + 1,
    );
    if (round == null) return;
    provider.addRound(round);
  }

  Future<void> _editRound(BuildContext context, GameMatch match,
      MatchProvider provider, int index) async {
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
      BuildContext context, MatchProvider provider, int index) async {
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
        context, (route) => route.settings.name == AppRoutes.home);
  }
}

// ─── Leader Banner ────────────────────────────────────────────────────────────

class _LeaderBanner extends StatelessWidget {
  final GameMatch match;
  const _LeaderBanner({required this.match});

  @override
  Widget build(BuildContext context) {
    if (match.rounds.isEmpty) return const SizedBox.shrink();
    final totals = match.cumulativeScores;
    // For Marriage, the LOWEST net payment total = best (paid out least)
    final sorted = [...match.players]..sort((a, b) =>
        (totals[a.id] ?? 0).compareTo(totals[b.id] ?? 0));
    final leader = sorted.first;
    final leaderScore = totals[leader.id] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _C.gold.withValues(alpha: 0.08),
            _C.accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Text('👑', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leader.name,
                  style: const TextStyle(
                    color: _C.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Least net payments · ${match.rounds.length} deal${match.rounds.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: _C.textSec, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '$leaderScore pts',
            style: const TextStyle(
              color: _C.gold,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
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
    final totals = match.cumulativeScores;
    final lowest = totals.values.isEmpty
        ? 0
        : totals.values.reduce((a, b) => a < b ? a : b);
    final highest = totals.values.isEmpty
        ? 0
        : totals.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        const SizedBox(height: 10),
        _HeaderRow(players: match.players),
        Expanded(
          child: match.rounds.isEmpty
              ? _EmptyRounds()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: match.rounds.length,
                  itemBuilder: (context, index) {
                    final round = match.rounds[index];
                    final isEven = index % 2 == 0;

                    // Detect winner for this round from marriageMeta
                    String? roundWinnerId;
                    if (round.marriageMeta != null) {
                      final entry = round.marriageMeta!.entries
                          .where((e) => e.value.isWinner)
                          .firstOrNull;
                      roundWinnerId = entry?.key;
                    }

                    return Dismissible(
                      key: ValueKey(round.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: _C.red.withValues(alpha: 0.2),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_rounded,
                            color: _C.red, size: 22),
                      ),
                      confirmDismiss: (_) async {
                        onDelete(index);
                        return false;
                      },
                      child: Material(
                        color: isEven
                            ? _C.surface
                            : _C.card.withValues(alpha: 0.6),
                        child: InkWell(
                          onTap: () => onEdit(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            child: Row(
                              children: [
                                // Round number
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${round.roundNumber}',
                                    style: const TextStyle(
                                        color: _C.textSec, fontSize: 13),
                                  ),
                                ),
                                // Scores per player
                                ...match.players.map((player) {
                                  final score =
                                      round.scores[player.id] ?? 0;
                                  final isWinner =
                                      player.id == roundWinnerId;
                                  final color = score > 0
                                      ? _C.red
                                      : score < 0
                                          ? _C.green
                                          : _C.textSec;
                                  return Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (isWinner)
                                          const Text('👑',
                                              style: TextStyle(fontSize: 9)),
                                        Text(
                                          MarriageScoreCalculator
                                              .formatPayment(score),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                // Edit icon
                                const SizedBox(
                                  width: 28,
                                  child: Icon(Icons.edit_rounded,
                                      size: 14, color: _C.textSec),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(height: 1, color: _C.border),
        _TotalsRow(
          match: match,
          totals: totals,
          lowest: lowest,
          highest: highest,
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final List<Player> players;
  const _HeaderRow({required this.players});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.surface,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 36,
            child: Text('#',
                style: TextStyle(color: _C.textSec, fontSize: 12)),
          ),
          ...players.map(
            (p) => Expanded(
              child: Text(
                p.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _C.textPri,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final GameMatch match;
  final Map<String, int> totals;
  final int lowest;
  final int highest;

  const _TotalsRow({
    required this.match,
    required this.totals,
    required this.lowest,
    required this.highest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.surface,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 36,
            child: Text('∑',
                style: TextStyle(
                    color: _C.accent, fontWeight: FontWeight.w700)),
          ),
          ...match.players.map((p) {
            final score = totals[p.id] ?? 0;
            Color color = _C.textPri;
            String suffix = '';
            if (score == lowest && lowest != highest) {
              color = _C.green;
              suffix = ' 👑';
            } else if (score == highest && lowest != highest) {
              color = _C.red;
            }
            return Expanded(
              child: Text(
                '$score$suffix',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            );
          }),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _EmptyRounds extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💍', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text(
            'No deals yet',
            style: TextStyle(
                color: _C.textPri,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "New Deal" to enter the first deal\'s scores',
            style: TextStyle(
                color: _C.textSec.withValues(alpha: 0.8), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyMatchScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface,
        title: const Text('Marriage',
            style: TextStyle(color: _C.textPri)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💍', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'No active match',
              style: TextStyle(
                  color: _C.textPri,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a new Marriage game to begin',
              style: TextStyle(color: _C.textSec, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _C.accent),
              onPressed: () => Navigator.pushReplacementNamed(
                  context, AppRoutes.marriageSetup),
              child: const Text('Start Game',
                  style: TextStyle(color: _C.bg)),
            ),
          ],
        ),
      ),
    );
  }
}
