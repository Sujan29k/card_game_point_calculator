import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/match.dart';
import '../../models/player.dart';
import '../../models/round.dart';
import '../../utils/score_calculator.dart';

Future<GameRound?> showCallBreakScoreEntry({
  required BuildContext context,
  required GameMatch match,
  required int roundNumber,
  GameRound? initialRound,
}) {
  return showModalBottomSheet<GameRound>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CallBreakScoreEntrySheet(
      match: match,
      roundNumber: roundNumber,
      initialRound: initialRound,
    ),
  );
}

// ─── Bottom Sheet ────────────────────────────────────────────────────────────

class _CallBreakScoreEntrySheet extends StatefulWidget {
  final GameMatch match;
  final int roundNumber;
  final GameRound? initialRound;

  const _CallBreakScoreEntrySheet({
    required this.match,
    required this.roundNumber,
    this.initialRound,
  });

  @override
  State<_CallBreakScoreEntrySheet> createState() =>
      _CallBreakScoreEntrySheetState();
}

class _CallBreakScoreEntrySheetState
    extends State<_CallBreakScoreEntrySheet> {
  late Map<String, int> _bids;
  late Map<String, int> _tricks;

  @override
  void initState() {
    super.initState();
    _bids = {};
    _tricks = {};
    for (final player in widget.match.players) {
      _bids[player.id] = widget.initialRound?.bids[player.id] ?? 1;
      _tricks[player.id] = _initialTricks(player.id);
    }
  }

  int _initialTricks(String playerId) {
    final stored = widget.initialRound?.scores[playerId];
    if (stored == null) return 0;
    final bid = _bids[playerId] ?? 1;
    if (stored < 0) return 0;
    // reverse: stored = bid×10 + (tricks − bid) → tricks = stored − bid×10 + bid
    return (stored - bid * 10) + bid;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildTitle(context),
            _buildTableHeader(context),
            const Divider(height: 1),
            ...widget.match.players.map((p) => _buildPlayerRow(context, p)),
            const Divider(height: 1),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildTitle(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              '${AppStrings.round} ${widget.roundNumber}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              'Bid 1–${ScoreCalculator.maxBid}  ·  Tricks 0–${ScoreCalculator.maxTricks}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );

  Widget _buildTableHeader(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            const Expanded(
              flex: 3,
              child: Text(
                'Player',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            _hCell('Bid'),
            _hCell('Tricks'),
            _hCell('Score', right: true),
          ],
        ),
      );

  Widget _hCell(String label, {bool right = false}) => SizedBox(
        width: 84,
        child: Text(
          label,
          textAlign: right ? TextAlign.right : TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );

  Widget _buildPlayerRow(BuildContext context, Player player) {
    final bid = _bids[player.id] ?? 1;
    final tricks = _tricks[player.id] ?? 0;
    final score = ScoreCalculator.callBreakScore(bid: bid, tricks: tricks);
    final isSpecial = ScoreCalculator.isSpecialWin(bid: bid, tricks: tricks);

    return Container(
      color: isSpecial ? AppColors.gold.withValues(alpha: 0.12) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Player name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (isSpecial)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('⭐', style: TextStyle(fontSize: 13)),
                  ),
                Expanded(
                  child: Text(
                    player.name,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSpecial ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                ),
              ],
            ),
          ),
          // Bid stepper
          _Stepper(
            value: bid,
            min: 1,
            max: ScoreCalculator.maxBid,
            onChanged: (v) => setState(() => _bids[player.id] = v),
          ),
          // Tricks stepper
          _Stepper(
            value: tricks,
            min: 0,
            max: ScoreCalculator.maxTricks,
            onChanged: (v) => setState(() => _tricks[player.id] = v),
          ),
          // Score preview
          SizedBox(
            width: 52,
            child: Text(
              ScoreCalculator.formatScore(score, isTenths: true),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSpecial
                    ? Colors.amber.shade700
                    : score >= 0
                        ? AppColors.positive
                        : AppColors.negative,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(AppStrings.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _save,
                child: const Text(AppStrings.save),
              ),
            ),
          ],
        ),
      );

  void _save() {
    final scores = <String, int>{};
    final specialWinnerIds = <String>[];
    for (final player in widget.match.players) {
      final bid = _bids[player.id] ?? 1;
      final tricks = _tricks[player.id] ?? 0;
      scores[player.id] =
          ScoreCalculator.callBreakScore(bid: bid, tricks: tricks);
      if (ScoreCalculator.isSpecialWin(bid: bid, tricks: tricks)) {
        specialWinnerIds.add(player.id);
      }
    }
    final round = GameRound(
      id: widget.initialRound?.id ?? const Uuid().v4(),
      roundNumber: widget.roundNumber,
      scores: scores,
      bids: Map<String, int>.from(_bids),
      timestamp: DateTime.now(),
      isEdited: widget.initialRound != null,
      specialWinnerIds: specialWinnerIds,
    );
    Navigator.pop(context, round);
  }
}

// ─── Stepper Widget ──────────────────────────────────────────────────────────

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Btn(
            icon: Icons.remove,
            active: value > min,
            onTap: () => onChanged(value - 1),
          ),
          SizedBox(
            width: 26,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          _Btn(
            icon: Icons.add,
            active: value < max,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Btn({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: active ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(
          icon,
          size: 17,
          color: active
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).disabledColor,
        ),
      ),
    );
  }
}
