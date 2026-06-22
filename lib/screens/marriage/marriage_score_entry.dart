import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../constants/app_strings.dart';
import '../../models/marriage_round_meta.dart';
import '../../models/match.dart';
import '../../models/player.dart';
import '../../models/round.dart';
import '../../utils/marriage_score_calculator.dart';

// ─── Design tokens for the sheet ────────────────────────────────────────────
class _MC {
  static const bg         = Color(0xFF1A1035);
  static const card       = Color(0xFF241B4A);
  static const border    = Color(0xFF332B60);
  static const accent    = Color(0xFFB48EFF);
  static const accentSoft = Color(0xFF2D2060);
  static const gold      = Color(0xFFFFD060);
  static const red        = Color(0xFFFF6B8A);
  static const green      = Color(0xFF4FFFB0);
  static const textPri    = Color(0xFFF0ECFF);
  static const textSec    = Color(0xFF9B8FCC);
  static const tiplu      = Color(0xFFFF9D3F);
  static const mal        = Color(0xFF5BBFFF);
  static const marriage   = Color(0xFFFF6B9D);
  static const tunnela    = Color(0xFF7BFF8A);
}

Future<GameRound?> showMarriageScoreEntry({
  required BuildContext context,
  required GameMatch match,
  required int roundNumber,
  GameRound? initialRound,
}) {
  return showModalBottomSheet<GameRound>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MarriageScoreEntrySheet(
      match: match,
      roundNumber: roundNumber,
      initialRound: initialRound,
    ),
  );
}

// ─── Main sheet ──────────────────────────────────────────────────────────────

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
  late Map<String, MarriageRoundMeta> _meta;
  late String _winnerId;
  bool _dubleeWin = false;

  @override
  void initState() {
    super.initState();
    _winnerId = widget.match.players.first.id;
    _meta = {};
    for (final p in widget.match.players) {
      final existing = widget.initialRound?.marriageMeta?[p.id];
      _meta[p.id] = existing ?? const MarriageRoundMeta(seenJoker: true);
    }
    if (widget.initialRound?.marriageMeta != null) {
      // restore winner from meta
      final winnerEntry = _meta.entries
          .where((e) => e.value.isWinner)
          .firstOrNull;
      if (winnerEntry != null) _winnerId = winnerEntry.key;
      _dubleeWin = _meta[_winnerId]?.dubleeWin ?? false;
    }
  }

  Map<String, int> get _payments {
    // Build meta with current winner + dublee flags applied
    final resolved = _meta.map((pid, m) => MapEntry(
          pid,
          m.copyWith(
            isWinner: pid == _winnerId,
            dubleeWin: pid == _winnerId && _dubleeWin,
          ),
        ));
    return MarriageScoreCalculator.computeNetPayments(
      allMeta: resolved,
      winnerId: _winnerId,
    );
  }

  void _updateMeta(String playerId, MarriageRoundMeta updated) {
    setState(() => _meta[playerId] = updated);
  }

  void _save() {
    const uuid = Uuid();
    final resolved = _meta.map((pid, m) => MapEntry(
          pid,
          m.copyWith(
            isWinner: pid == _winnerId,
            dubleeWin: pid == _winnerId && _dubleeWin,
          ),
        ));
    final payments = MarriageScoreCalculator.computeNetPayments(
      allMeta: resolved,
      winnerId: _winnerId,
    );
    final round = GameRound(
      id: widget.initialRound?.id ?? uuid.v4(),
      roundNumber: widget.roundNumber,
      scores: payments,
      bids: const {},
      timestamp: DateTime.now(),
      isEdited: widget.initialRound != null,
      marriageMeta: resolved,
    );
    Navigator.pop(context, round);
  }

  @override
  Widget build(BuildContext context) {
    final payments = _payments;
    return Container(
      decoration: const BoxDecoration(
        color: _MC.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  _buildWinnerRow(),
                  const SizedBox(height: 12),
                  ...widget.match.players.map((p) => _PlayerCard(
                        player: p,
                        meta: _meta[p.id]!,
                        isWinner: p.id == _winnerId,
                        payment: payments[p.id] ?? 0,
                        onChanged: (m) => _updateMeta(p.id, m),
                      )),
                  _buildSummaryBar(payments),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHandle() => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: _MC.textSec.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Row(
          children: [
            const Text('💍', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Round ${widget.roundNumber} — Score Entry',
                  style: const TextStyle(
                    color: _MC.textPri,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'Marriage Card Game',
                  style: TextStyle(color: _MC.textSec, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildWinnerRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _MC.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _MC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: _MC.gold, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Who ended this deal?',
                style: TextStyle(
                  color: _MC.textPri,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: widget.match.players.map((p) {
              final selected = p.id == _winnerId;
              return GestureDetector(
                onTap: () => setState(() => _winnerId = p.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? _MC.gold : _MC.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? _MC.gold
                          : _MC.border,
                    ),
                  ),
                  child: Text(
                    p.name,
                    style: TextStyle(
                      color: selected ? _MC.bg : _MC.textSec,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _dubleeWin = !_dubleeWin),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _dubleeWin ? _MC.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _dubleeWin ? _MC.accent : _MC.textSec,
                    ),
                  ),
                  child: _dubleeWin
                      ? const Icon(Icons.check,
                          size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Winner ended with 8 Dublees (+5 pts penalty)',
                  style: TextStyle(color: _MC.textSec, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(Map<String, int> payments) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _MC.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _MC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.balance_rounded, color: _MC.accent, size: 14),
              SizedBox(width: 6),
              Text(
                'Net Payments Preview',
                style: TextStyle(
                  color: _MC.textPri,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.match.players.map((p) {
            final pay = payments[p.id] ?? 0;
            final isWinner = p.id == _winnerId;
            final color = pay > 0
                ? _MC.red
                : pay < 0
                    ? _MC.green
                    : _MC.textSec;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  if (isWinner)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Text('👑',
                          style: TextStyle(fontSize: 11)),
                    ),
                  Text(
                    p.name,
                    style: const TextStyle(
                        color: _MC.textSec, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    pay > 0
                        ? 'Pays ${pay} pts'
                        : pay < 0
                            ? 'Gets ${pay.abs()} pts'
                            : 'Even',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActions() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _MC.textSec,
                  side: const BorderSide(color: _MC.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(AppStrings.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _MC.accent,
                  foregroundColor: _MC.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _save,
                child: const Text(
                  'Save Round',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
}

// ─── Per-player card ─────────────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  final Player player;
  final MarriageRoundMeta meta;
  final bool isWinner;
  final int payment;
  final ValueChanged<MarriageRoundMeta> onChanged;

  const _PlayerCard({
    required this.player,
    required this.meta,
    required this.isWinner,
    required this.payment,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cardPts = MarriageScoreCalculator.cardPoints(meta);
    final payColor = payment > 0 ? _MC.red : payment < 0 ? _MC.green : _MC.textSec;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _MC.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWinner
              ? _MC.gold.withValues(alpha: 0.6)
              : _MC.border,
          width: isWinner ? 1.5 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: isWinner
                ? _MC.gold.withValues(alpha: 0.15)
                : _MC.accentSoft,
            child: Text(
              player.name.isEmpty ? '?' : player.name[0].toUpperCase(),
              style: TextStyle(
                color: isWinner ? _MC.gold : _MC.accent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  player.name,
                  style: const TextStyle(
                    color: _MC.textPri,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isWinner)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Text('👑', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              Text(
                '$cardPts card pts',
                style: const TextStyle(color: _MC.textSec, fontSize: 11),
              ),
              const SizedBox(width: 10),
              Text(
                payment > 0
                    ? '↑ pays $payment'
                    : payment < 0
                        ? '↓ gets ${payment.abs()}'
                        : 'even',
                style: TextStyle(
                  color: payColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          children: [
            // Seen Joker toggle
            _ToggleRow(
              label: 'Seen Joker (tiplu)',
              sublabel: 'Pay 3 pts if seen · 10 if not',
              value: meta.seenJoker,
              activeColor: _MC.accent,
              onChanged: (v) => onChanged(meta.copyWith(seenJoker: v)),
            ),
            const SizedBox(height: 10),
            const _SectionLabel('TIPLU (wild card)'),
            _StepRow(
              label: 'Tiplu count',
              sublabel: 'Single=3pts · Double=7pts',
              color: _MC.tiplu,
              value: meta.tipluCount,
              max: 2,
              onChanged: (v) => onChanged(meta.copyWith(tipluCount: v)),
            ),

            const SizedBox(height: 10),
            const _SectionLabel('MAL  (poplu / jhiplu)'),
            _StepRow(
              label: 'Single mal',
              sublabel: '2 pts each',
              color: _MC.mal,
              value: meta.malSingle,
              max: 6,
              onChanged: (v) => onChanged(meta.copyWith(malSingle: v)),
            ),
            _StepRow(
              label: 'Double mal',
              sublabel: '5 pts each pair',
              color: _MC.mal,
              value: meta.malDouble,
              max: 3,
              onChanged: (v) => onChanged(meta.copyWith(malDouble: v)),
            ),
            _StepRow(
              label: 'Triple mal',
              sublabel: '10 pts each triple',
              color: _MC.mal,
              value: meta.malTriple,
              max: 2,
              onChanged: (v) => onChanged(meta.copyWith(malTriple: v)),
            ),
            _StepRow(
              label: 'Mal tunnela',
              sublabel: '20 pts each (3 identical)',
              color: _MC.mal,
              value: meta.malTunnela,
              max: 2,
              onChanged: (v) => onChanged(meta.copyWith(malTunnela: v)),
            ),

            const SizedBox(height: 10),
            const _SectionLabel('MARRIAGE  (jhiplu + tiplu + poplu)'),
            _StepRow(
              label: 'Single marriage',
              sublabel: '10 pts',
              color: _MC.marriage,
              value: meta.marriageSingle,
              max: 2,
              onChanged: (v) => onChanged(meta.copyWith(marriageSingle: v)),
            ),
            _StepRow(
              label: 'Double marriage',
              sublabel: '30 pts each',
              color: _MC.marriage,
              value: meta.marriageDouble,
              max: 1,
              onChanged: (v) => onChanged(meta.copyWith(marriageDouble: v)),
            ),

            const SizedBox(height: 10),
            const _SectionLabel('TUNNELAS  (exposed at deal)'),
            _StepRow(
              label: 'Normal card tunnela',
              sublabel: '5 pts each',
              color: _MC.tunnela,
              value: meta.tunnelaNormal,
              max: 8,
              onChanged: (v) => onChanged(meta.copyWith(tunnelaNormal: v)),
            ),
            _StepRow(
              label: 'Ordinary joker tunnela',
              sublabel: '10 pts each',
              color: _MC.tunnela,
              value: meta.tunnelaOrdinaryJoker,
              max: 4,
              onChanged: (v) =>
                  onChanged(meta.copyWith(tunnelaOrdinaryJoker: v)),
            ),

            const SizedBox(height: 8),
            // Card pts summary
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _MC.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate_rounded,
                      color: _MC.accent, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      MarriageScoreCalculator.breakdownLabel(meta),
                      style: const TextStyle(
                          color: _MC.textSec, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: _MC.textSec,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: _MC.textPri, fontSize: 13)),
                Text(sublabel,
                    style: const TextStyle(
                        color: _MC.textSec, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: activeColor,
            inactiveTrackColor: _MC.border,
            onChanged: onChanged,
          ),
        ],
      );
}

class _StepRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _StepRow({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: value > 0 ? color : _MC.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        color: value > 0 ? _MC.textPri : _MC.textSec,
                        fontSize: 12,
                        fontWeight: value > 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                      )),
                  Text(sublabel,
                      style: const TextStyle(
                          color: _MC.textSec, fontSize: 10)),
                ],
              ),
            ),
            _MiniStepper(
              value: value,
              max: max,
              color: color,
              onChanged: onChanged,
            ),
          ],
        ),
      );
}

class _MiniStepper extends StatelessWidget {
  final int value;
  final int max;
  final Color color;
  final ValueChanged<int> onChanged;

  const _MiniStepper({
    required this.value,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: Icons.remove,
            active: value > 0,
            color: color,
            onTap: () => onChanged(value - 1),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: value > 0 ? color : _MC.textSec,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add,
            active: value < max,
            color: color,
            onTap: () => onChanged(value + 1),
          ),
        ],
      );
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _StepBtn({
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: active ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? color : _MC.border,
          ),
        ),
      );
}
