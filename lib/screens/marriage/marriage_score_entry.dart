import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../constants/app_strings.dart';
import '../../models/match.dart';
import '../../models/player.dart';
import '../../models/round.dart';
import '../../utils/score_calculator.dart';

Future<GameRound?> showMarriageScoreEntry({
  required BuildContext context,
  required GameMatch match,
  required int roundNumber,
  GameRound? initialRound,
}) {
  return showModalBottomSheet<GameRound>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _MarriageScoreEntrySheet(
      match: match,
      roundNumber: roundNumber,
      initialRound: initialRound,
    ),
  );
}

class _MarriageScoreEntrySheet extends StatefulWidget {
  final GameMatch match;
  final int roundNumber;
  final GameRound? initialRound;

  const _MarriageScoreEntrySheet({
    required this.match,
    required this.roundNumber,
    this.initialRound,
  });

  @override
  State<_MarriageScoreEntrySheet> createState() =>
      _MarriageScoreEntrySheetState();
}

class _MarriageScoreEntrySheetState extends State<_MarriageScoreEntrySheet> {
  late Map<String, TextEditingController> _pointsControllers;
  late Map<String, bool> _hasMaal;
  late Map<String, bool> _hasSeen;
  late Map<String, bool> _isMarriage;

  @override
  void initState() {
    super.initState();
    _pointsControllers = {};
    _hasMaal = {};
    _hasSeen = {};
    _isMarriage = {};
    for (final player in widget.match.players) {
      _pointsControllers[player.id] = TextEditingController(
        text: (widget.initialRound?.scores[player.id] ?? 0).toString(),
      );
      _hasMaal[player.id] = widget.initialRound?.bids['maal_${player.id}'] == 1;
      _hasSeen[player.id] = widget.initialRound?.bids['seen_${player.id}'] == 1;
      _isMarriage[player.id] =
          widget.initialRound?.bids['marriage_${player.id}'] == 1;
    }
  }

  @override
  void dispose() {
    for (final controller in _pointsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${AppStrings.round} ${widget.roundNumber}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.match.players
                          .map(_buildPlayerRow)
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerRow(Player player) {
    final pointsController = _pointsControllers[player.id]!;
    final maal = _hasMaal[player.id] ?? false;
    final seen = _hasSeen[player.id] ?? false;
    final marriage = _isMarriage[player.id] ?? false;
    final points = int.tryParse(pointsController.text) ?? 0;
    final total = ScoreCalculator.marriageScore(
      points: points,
      hasMaal: maal,
      hasSeen: seen,
      isMarriage: marriage,
      bonusConfig: widget.match.bonusConfig,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(player.name, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: AppStrings.points),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                _CheckboxChip(
                  label: AppStrings.maal,
                  value: maal,
                  onChanged: (value) =>
                      setState(() => _hasMaal[player.id] = value),
                ),
                _CheckboxChip(
                  label: AppStrings.seen,
                  value: seen,
                  onChanged: (value) =>
                      setState(() => _hasSeen[player.id] = value),
                ),
                _CheckboxChip(
                  label: AppStrings.marriage,
                  value: marriage,
                  onChanged: (value) =>
                      setState(() => _isMarriage[player.id] = value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${AppStrings.points}: $total'),
          ],
        ),
      ),
    );
  }

  void _save() {
    final uuid = const Uuid();
    final scores = <String, int>{};
    final bids = <String, int>{};
    for (final player in widget.match.players) {
      final points = int.tryParse(_pointsControllers[player.id]!.text) ?? 0;
      final maal = _hasMaal[player.id] ?? false;
      final seen = _hasSeen[player.id] ?? false;
      final marriage = _isMarriage[player.id] ?? false;
      scores[player.id] = ScoreCalculator.marriageScore(
        points: points,
        hasMaal: maal,
        hasSeen: seen,
        isMarriage: marriage,
        bonusConfig: widget.match.bonusConfig,
      );
      bids['maal_${player.id}'] = maal ? 1 : 0;
      bids['seen_${player.id}'] = seen ? 1 : 0;
      bids['marriage_${player.id}'] = marriage ? 1 : 0;
    }
    final round = GameRound(
      id: widget.initialRound?.id ?? uuid.v4(),
      roundNumber: widget.roundNumber,
      scores: scores,
      bids: bids,
      timestamp: DateTime.now(),
      isEdited: widget.initialRound != null,
    );
    Navigator.pop(context, round);
  }
}

class _CheckboxChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckboxChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
    );
  }
}
